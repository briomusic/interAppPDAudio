//
//  CSAudioController.h
//  CloudSynth
//
//  Created by Brio on 25/08/2013.
//  Copyright (c) 2013 Brio. All rights reserved.
//

#import "PdAudioController.h"
#import "CAUITransportView.h"

@protocol CSAudioControllerMIDIDelegate <NSObject>

-(void)receiveMidiWithStatus:(UInt32)status data:(UInt32)data;

@end


@interface CSAudioController : PdAudioController <CAUITransportEngine>

#pragma mark properties
@property (strong, nonatomic) UIImage *audioUnitIcon;

@property (nonatomic) bool playing;
@property (nonatomic) bool recording;
@property (nonatomic) bool connected;
@property (nonatomic) Float64 playTime;

@property (nonatomic, assign) id <CSAudioControllerMIDIDelegate> delegate;

- (PdAudioStatus)configureInterAppAudioWithSampleRate:(int)sampleRate
                                       numberChannels:(int)numChannels;

- (void)publishOutputAudioUnit;

@end
