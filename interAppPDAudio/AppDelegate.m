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
    return YES;
}
							
- (void)applicationWillResignActive:(UIApplication *)application
{
    // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
    // Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
}

- (void)applicationDidEnterBackground:(UIApplication *)application
{
    /* Note: we are NOT deactivating the AVAudioSession when the app is in the background,
     * as this would make it impossible to use the node while the host is in the foreground.
     * instead we are sending notifications, so that CSAudioController can decide what to do.
     */

    [[NSNotificationCenter defaultCenter] postNotificationName:@"enterBackground" object:nil];
}

- (void)applicationWillEnterForeground:(UIApplication *)application
{
    /* Note: we are NOT deactivating the AVAudioSession when the app is in the background,
     * as this would make it impossible to use the node while the host is in the foreground.
     * instead we are sending notifications, so that CSAudioController can decide what to do.
     */

    [[NSNotificationCenter defaultCenter] postNotificationName:@"enterForeground" object:nil];
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
