//
//  CSAudioController.m
//  CloudSynth
//
//  Created by Brio on 25/08/2013.
//  Copyright (c) 2013 Brio. All rights reserved.
//


#import "CSAudioController.h"

#define Check(expr) do { OSStatus err = (expr); if (err) { NSLog(@"error %d from %s", (int)err, #expr); exit(1); } } while (0)
#define NSCheck(expr) do { NSError *err = nil; if (!(expr)) { NSLog(@"error from %s: %@", #expr, err);  exit(1); } } while (0)

extern NSString * const kTransportStateChangedNotificiation;

//Use Category to hide private listener method used by c callback
@interface CSAudioController (Private)
-(void)audioUnitPropertyChangedListener:(void *) inObject unit:(AudioUnit) inUnit propID:(AudioUnitPropertyID) inID scope:(AudioUnitScope) inScope element:(AudioUnitElement) inElement;

-(OSStatus)sendMusicDeviceMIDIEvent:(UInt32) inStatus data1:(UInt32) inData1 data2:(UInt32) inData2 offsetSampleFrame:(UInt32) inOffsetSampleFrame;
@end

//Callback for audio units bouncing from c to objective c
void AudioUnitPropertyChangeDispatcher(void *inRefCon, AudioUnit inUnit, AudioUnitPropertyID inID, AudioUnitScope inScope, AudioUnitElement inElement)
{
	CSAudioController *SELF = (__bridge CSAudioController *)inRefCon;
    [SELF audioUnitPropertyChangedListener:inRefCon unit:inUnit propID:inID scope:inScope element:inElement];
}

@implementation CSAudioController
{
    bool                inForeground;
	HostCallbackInfo    *callBackInfo;
    AudioUnit           _audioUnitForPublishing;
}

- (id)init
{
    if (self = [super init]) {
        // Do any additional setup after loading the view, typically from a nib.
		self.playing   = NO;
        self.recording = NO;
        UIApplicationState appstate = [UIApplication sharedApplication].applicationState;
		inForeground = (appstate != UIApplicationStateBackground);
    }
    return self;
}

- (PdAudioStatus)configureInterAppAudioWithSampleRate:(int)sampleRate
                                       numberChannels:(int)numChannels
{
    AVAudioSession *session = [AVAudioSession sharedInstance];
    NSError *err;
    PdAudioStatus status = PdAudioOK;
    if(![session setPreferredSampleRate: sampleRate error: &err])
    {
        NSLog(@"unable to set AVAudioSession preferred sample rate:%@", err.localizedDescription);
        status = PdAudioPropertyChanged;
    }
    if(![session setCategory: AVAudioSessionCategoryPlayback withOptions: AVAudioSessionCategoryOptionMixWithOthers error:  &err])
    {
        NSLog(@"unable to set AVAudioSession category:%@", err.localizedDescription);
        return PdAudioError;
    }
    if(![session setActive: YES error:  &err])
    {
        NSLog(@"unable to activate AVAudioSession:%@", err.localizedDescription);
        return PdAudioError;
    };
    
    if (![session setPreferredOutputNumberOfChannels:numChannels error:&err]) {
        NSLog(@"unable to set preferred Output Number Of Channels:%@", err.localizedDescription);
        status = PdAudioPropertyChanged;
    }
    
    [self configureAudioUnitWithNumberChannels:numChannels inputEnabled:NO];
    return status;
}

- (PdAudioStatus)configureAudioUnitWithNumberChannels:(int)numChannels inputEnabled:(BOOL)inputEnabled {
    PdAudioStatus status;
    status = [self.audioUnit configureWithSampleRate:self.sampleRate
                                      numberChannels:numChannels
                                        inputEnabled:inputEnabled] ? PdAudioError : PdAudioOK;
    
    [self connectAndPublishOutputAudioUnit:self.audioUnit.audioUnit];
    return status;
}

#pragma mark - Publishing methods AudioUnites

-(void) connectAndPublishOutputAudioUnit:(AudioUnit)outputUnit {
	[[NSNotificationCenter defaultCenter] addObserver: self
                                             selector: @selector(appHasGoneInBackground)
                                                 name: UIApplicationDidEnterBackgroundNotification
                                               object: nil];
    
    [[NSNotificationCenter defaultCenter] addObserver: self
                                             selector: @selector(appHasGoneForeground)
                                                 name: UIApplicationWillEnterForegroundNotification
                                               object: nil];
    
    [self addAudioUnitPropertyListener];
    
    _audioUnitForPublishing = outputUnit;
    
    //If media services get reset republish output node
    [[NSNotificationCenter defaultCenter] addObserverForName:AVAudioSessionMediaServicesWereResetNotification
                                                      object: nil
                                                       queue: nil
                                                  usingBlock: ^(NSNotification *note) {
                                                      NSLog(@"******** AVAudioSessionMediaServicesWereResetNotification ********");
                                                      //Throw away entire engine and rebuild like starting the app from scratch
                                                  }];
}

- (void)publishOutputAudioUnit
{
    AudioComponentDescription desc = { kAudioUnitType_RemoteInstrument,'iasp','brio',0,0 };
    OSStatus result = AudioOutputUnitPublish(&desc, CFSTR("interAppPDAudio"), 0, _audioUnitForPublishing);
    if (result != noErr)
        NSLog(@"AudioOutputUnitPublish instrument result: %d", (int)result);
    
    AudioComponentDescription desc2 = { kAudioUnitType_RemoteGenerator,'iasp','brio',0,0 };
    result = AudioOutputUnitPublish(&desc2, CFSTR("interAppPDAudio"), 0, _audioUnitForPublishing);
    if (result != noErr)
        NSLog(@"AudioOutputUnitPublish generator result: %d", (int)result);
    [self setupMidiCallBacks:&_audioUnitForPublishing userData:(__bridge void *)(self)];
}

-(void) addAudioUnitPropertyListener {
    Check(AudioUnitAddPropertyListener(self.audioUnit.audioUnit,
                                       kAudioUnitProperty_IsInterAppConnected,
                                       AudioUnitPropertyChangeDispatcher,
                                       (__bridge  void*) self));
    Check(AudioUnitAddPropertyListener(self.audioUnit.audioUnit,
                                       kAudioOutputUnitProperty_HostTransportState,
                                       AudioUnitPropertyChangeDispatcher,
                                       (__bridge  void*) self));
}

#pragma mark Private methods

-(void) audioUnitPropertyChangedListener:(void *)inObject
                                    unit:(AudioUnit )inUnit
                                  propID:(AudioUnitPropertyID) inID
                                   scope:( AudioUnitScope )inScope
                                 element:(AudioUnitElement )inElement {
    
    NSLog(@"****** audio property changed notification received ******\r");
    
    if (inID == kAudioUnitProperty_IsInterAppConnected) {
        [self isHostConnected];
        [self postUpdateStateNotification];
    } else if (inID == kAudioOutputUnitProperty_HostTransportState) {
        [self updateStatefromTransportCallBack];
        [self postUpdateStateNotification];
    }
}

-(void) postUpdateStateNotification {
    dispatch_async(dispatch_get_main_queue(), ^{
        [[NSNotificationCenter defaultCenter] postNotificationName:kTransportStateChangedNotificiation object:self];
    });
}

-(OSStatus) sendMusicDeviceMIDIEvent:(UInt32)inStatus data1:(UInt32)inData1 data2:(UInt32)inData2 offsetSampleFrame:(UInt32)inOffsetSampleFrame {
	return MusicDeviceMIDIEvent(self.audioUnit.audioUnit, inStatus, inData1, inData2, inOffsetSampleFrame);
}

#pragma mark - faked

-(void) checkStartStopGraph {
    if (self.connected || inForeground ) // stay active if either connected or in foreground
        [super setActive:YES];
    else if(!inForeground)              // deactivate if just in background
        [super setActive:NO];
}


#pragma mark CAUITransportEngine Protocol- Required methods

- (BOOL) canPlay   { return [self isHostConnected];}
- (BOOL) canRewind { return [self isHostConnected];}
- (BOOL) canRecord { return self.audioUnit.audioUnit != nil && ![self isHostPlaying]; }

- (BOOL) isHostPlaying   { return self.playing; }
- (BOOL) isHostRecording { return self.recording; }
- (BOOL) isHostConnected {
    if (self.audioUnit.audioUnit)
    {
        UInt32 connect;
        UInt32 dataSize = sizeof(UInt32);
        Check(AudioUnitGetProperty(self.audioUnit.audioUnit, kAudioUnitProperty_IsInterAppConnected, kAudioUnitScope_Global, 0, &connect, &dataSize));
        if (connect != self.connected) {
            self.connected = connect;
            
            if (self.connected) //Transition is from not connected to connected
            {
                [self checkStartStopGraph];
                //Get the appropriate callback info
                [self getHostCallBackInfo];
                [self getAudioUnitIcon];
                NSLog(@"InterAppAudio Connecting");
            }
            else //Transition is from connected to not connected;
            {
                [self checkStartStopGraph];
                NSLog(@"InterAppAudio Disconnceting");
                [self checkStartStopGraph];
            }
        }
    }
    return self.connected;
}

-(void) gotoHost {
    if (self.audioUnit.audioUnit) {
        CFURLRef instrumentUrl;
        UInt32 dataSize = sizeof(instrumentUrl);
        OSStatus result = AudioUnitGetProperty(self.audioUnit.audioUnit, kAudioUnitProperty_PeerURL, kAudioUnitScope_Global, 0, &instrumentUrl, &dataSize);
        if (result == noErr)
            [[UIApplication sharedApplication] openURL:(__bridge NSURL*)instrumentUrl];
    }
}

-(void) getHostCallBackInfo {
    if (self.connected) {
        if (callBackInfo)
            free(callBackInfo);
        UInt32 dataSize = sizeof(HostCallbackInfo);
        callBackInfo = (HostCallbackInfo*) malloc(dataSize);
        OSStatus result = AudioUnitGetProperty(self.audioUnit.audioUnit, kAudioUnitProperty_HostCallbacks, kAudioUnitScope_Global, 0, callBackInfo, &dataSize);
        if (result != noErr) {
            NSLog(@"Error occured fetching kAudioUnitProperty_HostCallbacks : %d", (int)result);
            free(callBackInfo);
            callBackInfo = NULL;
        }
    }
}

-(void) togglePlay {
    [self sendStateToRemoteHost:kAudioUnitRemoteControlEvent_TogglePlayPause];
    [[NSNotificationCenter defaultCenter] postNotificationName:kTransportStateChangedNotificiation object:self];
}

-(void) toggleRecord {
    [self sendStateToRemoteHost:kAudioUnitRemoteControlEvent_ToggleRecord];
    [[NSNotificationCenter defaultCenter] postNotificationName:kTransportStateChangedNotificiation object:self];
}

-(void) rewind {
    [self sendStateToRemoteHost:kAudioUnitRemoteControlEvent_Rewind];
    [[NSNotificationCenter defaultCenter] postNotificationName:kTransportStateChangedNotificiation object:self];
}

-(void) sendStateToRemoteHost:(AudioUnitRemoteControlEvent)state {
    if (self.audioUnit.audioUnit) {
        UInt32 controlEvent = state;
        UInt32 dataSize = sizeof(controlEvent);
        Check(AudioUnitSetProperty(self.audioUnit.audioUnit, kAudioOutputUnitProperty_RemoteControlToHost, kAudioUnitScope_Global, 0, &controlEvent, dataSize));
    }
}

//Fetch the host's icon via AudioOutputUnitGetHostIcon, draw that in the view
-(UIImage *) getAudioUnitIcon {
    if (self.audioUnit.audioUnit)
        self.audioUnitIcon = [CSAudioController scaleImage:AudioOutputUnitGetHostIcon(self.audioUnit.audioUnit, 114) toSize:CGSizeMake(41, 41)];
    
	return self.audioUnitIcon;
}

-(NSString *) getPlayTimeString {
    if (!self.recording) {
        [self updateStatefromTransportCallBack];
        return nil;
//        return formattedTimeStringForFrameCount(self.playTime, [(AVAudioSession*)[AVAudioSession sharedInstance] sampleRate], NO);
    }
    return @"00:00";
}

#pragma mark - MIDI response

-(void) setupMidiCallBacks:(AudioUnit*)output userData:(void*)inUserData {
    AudioOutputUnitMIDICallbacks callBackStruct;
    callBackStruct.userData = inUserData;
    callBackStruct.MIDIEventProc = MIDIEventProcCallBack;
    callBackStruct.MIDISysExProc = NULL;
    Check(AudioUnitSetProperty (*output,
                                kAudioOutputUnitProperty_MIDICallbacks,
                                kAudioUnitScope_Global,
                                0,
                                &callBackStruct,
                                sizeof(callBackStruct)));
}

void MIDIEventProcCallBack(void *userData, UInt32 inStatus, UInt32 inData1, UInt32 inData2, UInt32 inOffsetSampleFrame){
    CSAudioController *SELF = (__bridge CSAudioController*)userData;
    [SELF sendMusicDeviceMIDIEvent:inStatus data1:inData1 data2:inData2 offsetSampleFrame:inOffsetSampleFrame];
    [SELF.delegate receiveMidiWithStatus:inStatus data:inData1];
}


#pragma mark Application State Handling methods

-(void) appHasGoneInBackground {
    inForeground = NO;
    [self checkStartStopGraph];
}

-(void) appHasGoneForeground {
    inForeground = YES;
    [self isHostConnected];
    [self checkStartStopGraph];
    [self updateStatefromTransportCallBack];
}

-(void) updateStatefromTransportCallBack{
    if ([self isHostConnected] && inForeground) {
        if (!callBackInfo)
            [self getHostCallBackInfo];
        if (callBackInfo) {
            Boolean isPlaying  = self.playing;
            Boolean isRecording = self.recording;
            Float64 outCurrentSampleInTimeLine = 0;
            void * hostUserData = callBackInfo->hostUserData;
            OSStatus result =  callBackInfo->transportStateProc2( hostUserData,
                                                                 &isPlaying,
                                                                 &isRecording, NULL,
                                                                 &outCurrentSampleInTimeLine,
                                                                 NULL, NULL, NULL);
            if (result == noErr) {
                self.playing = isPlaying;
                self.recording = isRecording;
                self.playTime = outCurrentSampleInTimeLine;
            } else 
                NSLog(@"Error occured fetching callBackInfo->transportStateProc2 : %d", (int)result);
        }
    }
}
                           
+(UIImage*)scaleImage:(UIImage*)image toSize:(CGSize)newSize
{
    UIGraphicsBeginImageContextWithOptions(newSize, NO, 0.0);
    [image drawInRect:CGRectMake(0, 0, newSize.width, newSize.height)];
    UIImage *newImage = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    
    return newImage;
}


@end

#pragma mark Utility functions

NSString *formattedTimeStringForFrameCount(UInt64 inFrameCount, Float64 inSampleRate, BOOL inShowMilliseconds) {
	UInt32 hours		= 0;
	UInt32 minutes		= 0;
	UInt32 seconds		= 0;
	UInt32 milliseconds = 0;
    
	// calculate pieces
	if ((inFrameCount != 0) && (inSampleRate != 0)) {
		Float64 absoluteSeconds = (Float64)inFrameCount / inSampleRate;
		UInt64 absoluteIntSeconds = (UInt64) absoluteSeconds;
		
		milliseconds = (UInt32)(round((absoluteSeconds - (Float64)(absoluteIntSeconds)) * 1000.0));
        
		hours = absoluteIntSeconds / 3600;
		absoluteIntSeconds -= (hours * 3600);
		minutes = absoluteIntSeconds / 60;
		absoluteIntSeconds -= (minutes * 60);
		seconds = absoluteIntSeconds;
	}
	
	NSString *retString;
	// construct strings
	
	NSString *hoursString	= nil;
	NSString *minutesString	= nil;
	NSString *secondsString	= nil;
	
	if (hours > 0) {
		hoursString = [NSString stringWithFormat:@"%2d", (unsigned int)hours];
	}
	
	if (minutes == 0) {
		minutesString = @"00";
	} else if (minutes < 10) {
		minutesString = [NSString stringWithFormat:@"0%d", (unsigned int)minutes];
	} else {
		minutesString = [NSString stringWithFormat:@"%d", (unsigned int)minutes];
	}
	
	if (seconds == 0) {
		secondsString = @"00";
	} else if (seconds < 10) {
		secondsString = [NSString stringWithFormat:@"0%d", (unsigned int)seconds];
	} else {
		secondsString = [NSString stringWithFormat:@"%d", (unsigned int)seconds];
	}
	
	if (!inShowMilliseconds) {
		if (hoursString) {
			retString = [NSString stringWithFormat:@"%@:%@:%@", hoursString, minutesString, secondsString];
		} else {
			retString = [NSString stringWithFormat:@"%@:%@", minutesString, secondsString];
		}
	}
	
	if (inShowMilliseconds) {
		NSString *millisecondsString;
		
		if (milliseconds == 0) {
			millisecondsString = @"000";
		} else if (milliseconds < 10) {
			millisecondsString = [NSString stringWithFormat:@"00%d", (unsigned int)milliseconds];
		} else if (milliseconds < 100) {
			millisecondsString = [NSString stringWithFormat:@"0%d", (unsigned int)milliseconds];
		} else {
			millisecondsString = [NSString stringWithFormat:@"%d", (unsigned int)milliseconds];
		}
		
		if (hoursString) {
			retString = [NSString stringWithFormat:@"%@:%@:%@.%@", hoursString, minutesString, secondsString, millisecondsString];
		} else {
			retString = [NSString stringWithFormat:@"%@:%@.%@", minutesString, secondsString, millisecondsString];
		}
	}
	
	return retString;
}

