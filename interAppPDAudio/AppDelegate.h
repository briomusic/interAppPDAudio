//
//  AppDelegate.h
//  interAppPDAudio
//
//  Created by Brio on 09/11/2013.
//  Copyright (c) 2013 Brio. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "CSAudioController.h"


@interface AppDelegate : UIResponder <UIApplicationDelegate>

@property (strong, nonatomic) UIWindow *window;
@property (strong, nonatomic, readonly) CSAudioController *audioController;

@end
