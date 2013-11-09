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

- (void)viewDidLoad
{
    [super viewDidLoad];
    dispatcher = [[PdDispatcher alloc] init];
    [PdBase setDelegate:dispatcher];
    patch = [PdBase openFile:@"sinepiano.pd" path:[[NSBundle mainBundle] resourcePath]];
    if (!patch) {
        NSLog(@"Failed to open patch");
    }
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
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

@end
