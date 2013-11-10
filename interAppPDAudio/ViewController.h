//
//  ViewController.h
//  interAppPDAudio
//
//  Created by Brio on 09/11/2013.
//  Copyright (c) 2013 Brio. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "PdDispatcher.h"
#import "CSAudioController.h"

@interface ViewController : UIViewController <PdListener, CSAudioControllerMIDIDelegate> {
    PdDispatcher *dispatcher;
    void *patch;
}

@property (strong, nonatomic, readonly) CSAudioController *audioController;

@end
