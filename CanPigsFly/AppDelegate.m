//
//  AppDelegate.m
//  CanPigsFly
//
//  Created by Ryan Ackermann on 3/3/14.
//  Copyright (c) 2014 Ryan Ackermann. All rights reserved.
//

#import "AppDelegate.h"

@import AVFoundation;

@implementation AppDelegate

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    return YES;
}

- (void)applicationWillResignActive:(UIApplication *)application {
    [[AVAudioSession sharedInstance] setActive:NO error:nil];
}

- (void)applicationDidEnterBackground:(UIApplication *)application {
    [[AVAudioSession sharedInstance] setActive:NO error:nil];
}

- (void)applicationWillEnterForeground:(UIApplication *)application {
    [[AVAudioSession sharedInstance] setActive:YES error:nil];
}

@end
