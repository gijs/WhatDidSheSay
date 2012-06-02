//
//  AppDelegate.m
//  WhatDidSheSay
//
//  Created by Max Weisel on 3/10/12.
//  Copyright (c) 2012 RelativeWave. All rights reserved.
//

#import "AppDelegate.h"
#import "MainViewController.h"
#import "NearbyViewController.h"
#import <Parse/Parse.h>

NSString *localIdentifier(void);
NSString *localIdentifier(void) {
    NSString *ident = [[NSUserDefaults standardUserDefaults] objectForKey:@"localIdentifier"];
    if (!ident) {
        CFUUIDRef uuidRef = CFUUIDCreate(NULL);
        CFStringRef uuidStringRef = CFUUIDCreateString(NULL, uuidRef);
        CFRelease(uuidRef);
        ident = [NSString stringWithString:(NSString *)uuidStringRef];
        CFRelease(uuidStringRef);
        [[NSUserDefaults standardUserDefaults] setObject:ident forKey:@"localIdentifier"];
        [[NSUserDefaults standardUserDefaults] synchronize];
    }
    return ident;
}

@implementation AppDelegate

@synthesize window = _window;

- (void)dealloc
{
    [tabBarController.view removeFromSuperview];
    [tabBarController release];
    [_window release];
    [super dealloc];
}

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
    NSNumber *p1 = [[NSUserDefaults standardUserDefaults] objectForKey:@"p1"];
    if (p1 == nil || [p1 boolValue] == NO) {
        p1 = [NSNumber numberWithBool:[[NSDate date] timeIntervalSinceDate:[NSDate dateWithTimeIntervalSince1970:1337133713]] > 0.0f];
        [[NSUserDefaults standardUserDefaults] setObject:p1 forKey:@"p1"];
        [[NSUserDefaults standardUserDefaults] synchronize];
    }
    
    [Parse setApplicationId:@"zUIHy5rrpw70qzvVVGmdpRGYty6PEOJtBbOWKFSB" 
                  clientKey:@"gdCfQpqkkioUF2x0KlOCt3s5s9iOEfIsPY6uJfvm"];
    
    self.window = [[[UIWindow alloc] initWithFrame:[[UIScreen mainScreen] bounds]] autorelease];
    
    tabBarController = [[UITabBarController alloc] init];
    
    MainViewController *mainViewController = [[MainViewController alloc] init];
    NearbyViewController *nearbyViewController = [[NearbyViewController alloc] init];
    
    tabBarController.viewControllers = [NSArray arrayWithObjects:
                                        mainViewController, 
                                        [[[UINavigationController alloc] initWithRootViewController:nearbyViewController] autorelease], 
                                        nil];
    
    [mainViewController release];
    [nearbyViewController release];
    
    [self.window addSubview:tabBarController.view];
    
    self.window.backgroundColor = [UIColor blackColor];
    [self.window makeKeyAndVisible];
    return YES;
}

- (void)applicationWillResignActive:(UIApplication *)application
{
    /*
     Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
     Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
     */
}

- (void)applicationDidEnterBackground:(UIApplication *)application
{
    /*
     Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later. 
     If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
     */
}

- (void)applicationWillEnterForeground:(UIApplication *)application
{
    /*
     Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.
     */
}

- (void)applicationDidBecomeActive:(UIApplication *)application
{
    /*
     Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
     */
}

- (void)applicationWillTerminate:(UIApplication *)application
{
    /*
     Called when the application is about to terminate.
     Save data if appropriate.
     See also applicationDidEnterBackground:.
     */
}

@end
