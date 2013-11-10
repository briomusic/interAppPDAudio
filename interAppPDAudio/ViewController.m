//
//  ViewController.m
//  interAppPDAudio
//
//  Created by Brio on 09/11/2013.
//  Copyright (c) 2013 Brio. All rights reserved.
//

#import "ViewController.h"

@interface ViewController ()

@end

@implementation ViewController
{
    IBOutlet CAUITransportView	*transportView;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    // Modified version of the boilerplate initialisation code for libPD
    
    // instead of the standard PDAudioController we initialise our _audioController with a custom subclass CSAudioController
    
    _audioController = [[CSAudioController alloc] init];
    
    
    // CSAudioController has an additional coniguration method for inter-app audio:
    
    if ([self.audioController configureInterAppAudioWithSampleRate:44100 numberChannels:2] == PdAudioError)
        NSLog(@"Failed to initialize audio components");
    else
        NSLog(@"Did initialize audio components");
    
    
    // publish our node's existence to potential hosts:
    
    [self.audioController publishOutputAudioUnit];
    
    
    // some boilerplate PD initialisation, not IAA related
    
    [self.audioController setActive:YES];

    dispatcher = [[PdDispatcher alloc] init];
    [PdBase setDelegate:dispatcher];
    patch = [PdBase openFile:@"sinepiano.pd" path:[[NSBundle mainBundle] resourcePath]];
    if (!patch)
        NSLog(@"Failed to open patch");
    
    
    // connect our transportView to CSAudiocontroller:
    // this allows for remote controlling the host transport
    // and also for convenient switching between node and host app via app icons.
    
    transportView.engine = self.audioController;
    
    
    // make ourselves the MIDI delegate of CSAudiocontroller to receive MIDI messages from the host:
    
    self.audioController.delegate = self;
}

- (IBAction)playNote:(UIButton *)sender
{
    float note = [sender.titleLabel.text floatValue];
    NSLog(@"playing note:%g", note);
    [self playPiano:note];
}

-(void)playPiano:(float)note {
    [PdBase sendFloat:note+72 toReceiver:@"midinote"];
    [PdBase sendBangToReceiver:@"trigger"];
}

#pragma mark - MIDI delegate

-(void)receiveMidiWithStatus:(UInt32)status data:(UInt32)data
{
    NSLog(@"received midi status:%u data:%u", (unsigned int)status, (unsigned int)data);
    [self playPiano:(float)data - 48];
}

@end
