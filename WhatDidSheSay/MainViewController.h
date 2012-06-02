//
//  MainViewController.h
//  WhatDidSheSay
//
//  Created by Max Weisel on 3/10/12.
//  Copyright (c) 2012 RelativeWave. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "TWSS.h"
#import <AudioToolbox/AudioToolbox.h>
#import <CoreLocation/CoreLocation.h>

typedef enum {
    kButtonStateNormal,
    kButtonStateGlowing
} ButtonState;

@interface MainViewController : UIViewController <UITextViewDelegate, CLLocationManagerDelegate> {
    UITextField *textField;
    UITextView *textDisplay;
    
    UIButton *dictationButton;
    UIButton *keyboardButton;
    
    BOOL dictationOn;
    ButtonState dictationButtonState;
    BOOL dictationButtonFlashing;
    NSTimer *dictationButtonTimer;
    
    NSTimer *audioLevelTimer;
    NSDate *lastSound;
    
    TWSS *twss;
    
    NSTimer *removeSpinnerTimer;
    UIActivityIndicatorView *spinner;
    
    UIImageView *displayImage;
    
    SystemSoundID audioEffect;
    
    CLLocationManager *locationManager;
    CLLocation *currentLocation;
    
    BOOL supportsDict;
}

@property (nonatomic, assign) BOOL dictationOn;
@property (nonatomic, assign) BOOL dictationButtonFlashing;
@property (nonatomic, retain) NSTimer *dictationButtonTimer;
@property (nonatomic, retain) NSTimer *audioLevelTimer;
@property (nonatomic, retain) NSDate *lastSound;
@property (nonatomic, retain) NSTimer *removeSpinnerTimer;
@property (nonatomic, retain) UIActivityIndicatorView *spinner;
@property (nonatomic, retain) UIImageView *displayImage;
@property (nonatomic, retain) CLLocation *currentLocation;

@end

NSString *rrr(NSString *string);
