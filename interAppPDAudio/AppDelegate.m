//
//  AppDelegate.m
//  interAppPDAudio
//
//  Created by Brio on 09/11/2013.
//  Copyright (c) 2013 Brio. All rights reserved.
//

#import "AppDelegate.h"


@implementation AppDelegate

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
    /* Modified version of the boilerplate initialisation code for libPD 
     * Note: we are NOT deactivating the AVAudioSession when the app is in the background,
     * as this would make it impossible to use the node while the host is in the foreground.
     * instead we are sending notifications, so that CSAudioController can decide what to do.
     */
    
    // instead of the standard PDAudioController we initialise our property with our custom subclass CSAudioController
    _audioController = [[CSAudioController alloc] init];
    
    // CSAudioController has an additional coniguration method for inter-app audio:
    if ([self.audioController configureInterAppAudioWithSampleRate:44100 numberChannels:2] == PdAudioError) {
        NSLog(@"Failed to initialize audio components");
    } else {
        NSLog(@"Did initialize audio components");
    }
    
    // this method publishes our node's existence to potential hosts.
    [self.audioController publishOutputAudioUnit];
    
    [self.audioController setActive:YES];
    return YES;
}
							
- (void)applicationWillResignActive:(UIApplication *)application
{
    // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
    // Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
}

- (void)applicationDidEnterBackground:(UIApplication *)application
{
    [[NSNotificationCenter defaultCenter] postNotificationName:@"enterBackground" object:nil];
    // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
    // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
}

- (void)applicationWillEnterForeground:(UIApplication *)application
{
    [[NSNotificationCenter defaultCenter] postNotificationName:@"enterForeground" object:nil];
    // Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.
}

- (void)applicationDidBecomeActive:(UIApplication *)application
{
    // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
}

- (void)applicationWillTerminate:(UIApplication *)application
{
    // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
}

@end
