//
//  AppDelegate.h
//  WhatDidSheSay
//
//  Created by Max Weisel on 3/10/12.
//  Copyright (c) 2012 RelativeWave. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface AppDelegate : UIResponder <UIApplicationDelegate> {
    UITabBarController *tabBarController;
}

@property (strong, nonatomic) UIWindow *window;

@end

NSString *localIdentifier();
