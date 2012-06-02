//
//  MainViewController.m
//  WhatDidSheSay
//
//  Created by Max Weisel on 3/10/12.
//  Copyright (c) 2012 RelativeWave. All rights reserved.
//

#import "MainViewController.h"
#import "DictationClass.h"
#import <Parse/Parse.h>
#import "AppDelegate.h"
#include <sys/socket.h>
#include <sys/sysctl.h>
#include <net/if.h>
#include <net/if_dl.h>

NSString *rrr(NSString *string) { // rot13
	const char *_string = [string cStringUsingEncoding:NSASCIIStringEncoding];
	int stringLength = [string length];
	char newString[stringLength+1];
	
	int x;
	for( x=0; x<stringLength; x++ ) {
		unsigned int aCharacter = _string[x];
		
		if( 0x40 < aCharacter && aCharacter < 0x5B ) // A - Z
			newString[x] = (((aCharacter - 0x41) + 0x0D) % 0x1A) + 0x41;
		else if( 0x60 < aCharacter && aCharacter < 0x7B ) // a-z
			newString[x] = (((aCharacter - 0x61) + 0x0D) % 0x1A) + 0x61;
		else  // Not an alpha character
			newString[x] = aCharacter;
	}
	
	newString[x] = '\0';
	
	NSString *rotString = [NSString stringWithCString:newString encoding:NSASCIIStringEncoding];
	return rotString;
}

@implementation MainViewController

@synthesize dictationOn;
@synthesize dictationButtonFlashing;
@synthesize dictationButtonTimer;
@synthesize audioLevelTimer;
@synthesize lastSound;
@synthesize removeSpinnerTimer;
@synthesize spinner;
@synthesize displayImage;
@synthesize currentLocation;

- (id)init {
    if ((self = [super init]) != nil) {
        self.tabBarItem.image = [UIImage imageNamed:@"Woman.png"];
        self.title = @"WDSS";
        
        textField = [[UITextField alloc] initWithFrame:CGRectMake(0.0f, -100.0f, 100.0f, 20.0f)]; // Offscreen
        [textField addTarget:self action:@selector(textFieldEditingChanged:) forControlEvents:UIControlEventEditingChanged];
        textField.inputView = [[[UIView alloc] initWithFrame:CGRectZero] autorelease];
        
        textDisplay = [[UITextView alloc] initWithFrame:CGRectMake(10.0f, 0.0f, 300.0f, 120.0f)];
        textDisplay.backgroundColor = [UIColor clearColor];
        textDisplay.textColor = [UIColor whiteColor];
        textDisplay.font = [UIFont fontWithName:@"Marker Felt" size:28.0f];
        textDisplay.textAlignment = UITextAlignmentCenter;
        textDisplay.returnKeyType = UIReturnKeyGo;
        textDisplay.delegate = self;
        textDisplay.editable = NO;
        
        dictationButton = [[UIButton buttonWithType:UIButtonTypeCustom] retain];
        [dictationButton setImage:[UIImage imageNamed:@"DButton.png"] forState:UIControlStateNormal];
        [dictationButton setImage:[UIImage imageNamed:@"DButtonPressed.png"] forState:UIControlStateHighlighted];
        [dictationButton addTarget:self action:@selector(dictation) forControlEvents:UIControlEventTouchUpInside];
        
        keyboardButton = [[UIButton buttonWithType:UIButtonTypeCustom] retain];
        [keyboardButton setImage:[UIImage imageNamed:@"KButton.png"] forState:UIControlStateNormal];
        [keyboardButton setImage:[UIImage imageNamed:@"KButtonPressed.png"] forState:UIControlStateHighlighted];
        [keyboardButton addTarget:self action:@selector(keyboard) forControlEvents:UIControlEventTouchUpInside];
        
        twss = [[TWSS alloc] init];

        NSURL *pathURL = [NSURL fileURLWithPath:[[NSBundle mainBundle] pathForResource:@"twss" ofType:@"wav"]];
        AudioServicesCreateSystemSoundID((CFURLRef) pathURL, &audioEffect);
        
        locationManager = [[CLLocationManager alloc] init];
        locationManager.delegate = self;
        locationManager.desiredAccuracy = kCLLocationAccuracyNearestTenMeters;
        [locationManager startUpdatingLocation];
        
        self.currentLocation = nil;
        
        size_t size;
        sysctlbyname("hw.machine", NULL, &size, NULL, 0);
        char *answer = malloc(size);
        sysctlbyname("hw.machine", answer, &size, NULL, 0);
        NSString *results = [NSString stringWithCString:answer encoding: NSUTF8StringEncoding];
        free(answer);
        
        supportsDict = [results hasPrefix:@"iPhone4"] || [results hasPrefix:@"iPad3"]; // iPhone 4S or iPad3
    }
    return self;
}

- (void)locationManager:(CLLocationManager *)manager didUpdateToLocation:(CLLocation *)newLocation fromLocation:(CLLocation *)oldLocation {
    self.currentLocation = newLocation;
}

- (void)setDisplayImage:(UIImageView *)displayImage_ {
    [displayImage removeFromSuperview];
    [displayImage release];
    displayImage = [displayImage_ retain];
    if (displayImage != nil)
        [self.view insertSubview:displayImage belowSubview:dictationButton];
}

- (void)dictation {
    self.dictationOn = !dictationOn;
}

- (void)displaySpinner:(BOOL)display {
    if (display) {
        if (spinner == nil) {
            spinner = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleWhiteLarge];
            spinner.frame = CGRectMake((self.view.bounds.size.width-spinner.frame.size.width)/2.0f, (self.view.bounds.size.height-spinner.frame.size.height)/2.0f - 50.0f, spinner.frame.size.width, spinner.frame.size.height);
            [spinner startAnimating];
            [self.view addSubview:spinner];
        }
    } else {
        [spinner removeFromSuperview];
        [spinner stopAnimating];
        self.spinner = nil;
    }
}

- (void)setRemoveSpinnerTimer:(NSTimer *)removeSpinnerTimer_ {
    if (removeSpinnerTimer_ == removeSpinnerTimer)
        return;
    
    [removeSpinnerTimer invalidate];
    [removeSpinnerTimer release];
    removeSpinnerTimer = [removeSpinnerTimer_ retain];
}

- (void)setAudioLevelTimer:(NSTimer *)audioLevelTimer_ {
    if (audioLevelTimer_ == audioLevelTimer)
        return;
    
    [audioLevelTimer invalidate];
    [audioLevelTimer release];
    audioLevelTimer = [audioLevelTimer_ retain];
}

- (void)checkAudioLevel {
    float audioLevel = [(DictationClass *)[NSClassFromString(rrr(@"HVQvpgngvbaPbagebyyre")) sharedInstance] normalizedAudioLevel];
    if (audioLevel > 0.4f)
        self.lastSound = [NSDate date];
    
    if([[NSDate date] timeIntervalSinceDate:self.lastSound] > 1.4f)
        self.dictationOn = NO;
}

- (void)startAudioCheck {
    self.audioLevelTimer = [NSTimer scheduledTimerWithTimeInterval:0.1f target:self selector:@selector(checkAudioLevel) userInfo:nil repeats:YES];
    self.lastSound = [NSDate date];
}

- (void)processText:(NSString *)text {
    self.removeSpinnerTimer = nil; // Don't remove the spinner.
    [self displaySpinner:YES];
    
    if ([[text stringByReplacingOccurrencesOfString:@" " withString:@""] isEqualToString:@""]) {
        [self displaySpinner:NO];
        return;
    }
    
    BOOL sheSaidIt = [twss isTWSS:text];
    
    CGRect diFrame;
    
    if (sheSaidIt) {
        UIImageView *displayImage_ = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"twss.png"]];
        diFrame = displayImage_.frame;
        diFrame.origin = CGPointMake((self.view.bounds.size.width-diFrame.size.width)/2.0f, (self.view.bounds.size.height-diFrame.size.height)/2.0f + 70.0f);
        displayImage_.frame = diFrame;
        self.displayImage = displayImage_;
        [displayImage_ release];
        
        AudioServicesPlaySystemSound(audioEffect);
        
        NSLog(@"That's what she said");
    } else {
        UIImageView *displayImage_ = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"PokerFace.png"]];
        diFrame = displayImage_.frame;
        diFrame.origin = CGPointMake((self.view.bounds.size.width-diFrame.size.width)/2.0f, (self.view.bounds.size.height-diFrame.size.height)/2.0f + 70.0f);
        displayImage_.frame = diFrame;
        self.displayImage = displayImage_;
        [displayImage_ release];
        
        NSLog(@"not what she said");
    }
    
    // Post to parse
    if (currentLocation != nil) {
        PFObject *object = [PFObject objectWithClassName:(sheSaidIt)?@"TWSS":@"TNWSS"];
        [object setObject:[[text copy] autorelease] forKey:@"text"];
        [object setObject:[PFGeoPoint geoPointWithLatitude:currentLocation.coordinate.latitude longitude:currentLocation.coordinate.longitude] forKey:@"point"];
        [object setObject:localIdentifier() forKey:@"localIdentifier"];
        [object saveInBackground];
    }
    
    [self displaySpinner:NO];
}

- (void)textFieldEditingChanged:(UITextField *)textField_ {
    if (textField_ != textField || [textField.text isEqualToString:@""])
        return;
    
    if (textField.isFirstResponder) {
        textDisplay.text = textField.text;
        [self processText:textField.text];
        textField.text = @"";
    }
}

- (void)setDictationOn:(BOOL)dictationOn_ {
    if (dictationOn_ && !supportsDict) {
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Error" message:@"Dictation is either disabled or not supported on this device." delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil];
        [alert show];
        [alert release];
        return;
    }
    
    if (dictationOn_) {
        [textField becomeFirstResponder];
        self.dictationButtonFlashing = YES;
        textDisplay.text = @"";
        self.displayImage = nil;
    } else {
        self.dictationButtonFlashing = NO;
    }
    
    if (dictationOn_ == dictationOn)
        return;
    
    if (dictationOn_) {
        [(DictationClass *)[NSClassFromString(rrr(@"HVQvpgngvbaPbagebyyre")) sharedInstance] startDictation];
        [NSTimer scheduledTimerWithTimeInterval:2.0f target:self selector:@selector(startAudioCheck) userInfo:nil repeats:NO];
    } else {
        [(DictationClass *)[NSClassFromString(rrr(@"HVQvpgngvbaPbagebyyre")) sharedInstance] stopDictation];
        [self displaySpinner:YES];
        self.removeSpinnerTimer = [NSTimer scheduledTimerWithTimeInterval:10.0f target:self selector:@selector(removeSpinnerTimerFire) userInfo:nil repeats:NO]; // Remove the spinner if dictation doesn't give us any text. If it does, this timer will be invalidated before firing.
        self.audioLevelTimer = nil;
    }
    
    dictationOn = dictationOn_;
}

- (void)removeSpinnerTimerFire {
    [self displaySpinner:NO];
}

- (void)cancelDictation {
    if (!dictationOn)
        return;
    
    self.dictationOn = NO;
    [self displaySpinner:NO];
}

- (void)setDictationButtonState:(ButtonState)buttonState; {
    switch (buttonState) {
        case kButtonStateNormal:
            [dictationButton setImage:[UIImage imageNamed:@"DButton.png"] forState:UIControlStateNormal];
            [dictationButton setImage:[UIImage imageNamed:@"DButtonPressed.png"] forState:UIControlStateHighlighted];
            break;
        case kButtonStateGlowing:
            [dictationButton setImage:[UIImage imageNamed:@"DButtonGlow.png"] forState:UIControlStateNormal];
            [dictationButton setImage:[UIImage imageNamed:@"DButtonGlowPressed"] forState:UIControlStateHighlighted];
            break;
        default:
            break;
    }
    
    dictationButtonState = buttonState;
}

- (void)toggleButtonState {
    [self setDictationButtonState:!dictationButtonState];
}

- (void)setDictationButtonTimer:(NSTimer *)dictationButtonTimer_ {
    if (dictationButtonTimer_ == dictationButtonTimer)
        return;
    
    [dictationButtonTimer invalidate];
    [dictationButtonTimer release];
    dictationButtonTimer = [dictationButtonTimer_ retain];
}

- (void)setDictationButtonFlashing:(BOOL)dictationButtonFlashing_ {
    if (dictationButtonFlashing_) {
        self.dictationButtonTimer = [NSTimer scheduledTimerWithTimeInterval:0.6f target:self selector:@selector(toggleButtonState) userInfo:nil repeats:YES];
        [self setDictationButtonState:kButtonStateGlowing];
    } else {
        self.dictationButtonTimer = nil;
        [self setDictationButtonState:kButtonStateNormal];
    }
    dictationButtonFlashing = dictationButtonFlashing_;
}

- (void)keyboard {
    [self cancelDictation];
    textDisplay.editable = YES;
    textDisplay.text = @"";
    [textDisplay becomeFirstResponder];
    self.displayImage = nil;
}

- (void)textViewDidEndEditing:(UITextView *)textView {
    textView.editable = NO;
}

- (BOOL)textView:(UITextView *)textView shouldChangeTextInRange:(NSRange)range replacementText:(NSString *)text {
    if ([text rangeOfString:@"\n"].location != NSNotFound) {
        //textView.text = @"";
        [textView resignFirstResponder];
        [self processText:textView.text];
    }
    return YES;
}

- (void)about {
    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"What Did She Say?" message:@"Created by Max Weisel\nwww.MaxWeisel.com\n\nGraphics by Otis Blank\n\nInspired by Daniel Rapp's twss.js" delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil];
    [alert show];
    [alert release];
}

- (void)viewDidLoad {
    [super viewDidLoad];
    [self.view addSubview:[[[UIImageView alloc] initWithImage:[UIImage imageNamed:@"Default.png"]] autorelease]];
    
    UIButton *infoButton = [UIButton buttonWithType:UIButtonTypeInfoLight];
    infoButton.frame = CGRectMake(self.view.frame.size.width - infoButton.frame.size.width - 12.0f, 12.0f, infoButton.frame.size.width, infoButton.frame.size.height);
    [infoButton addTarget:self action:@selector(about) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:infoButton];
    
    if ([[[NSUserDefaults standardUserDefaults] objectForKey:@"p1"] boolValue] && supportsDict) {
        dictationButton.frame = CGRectMake(10.0f, 320.0f, 149.0f, 87.0f);
        [self.view addSubview:dictationButton];
        
        keyboardButton.frame = CGRectMake(self.view.bounds.size.width - 149.0f - 10.0f, 320.0f, 149.0f, 87.0f);
        [self.view addSubview:keyboardButton];
    } else {
        keyboardButton.frame = CGRectMake((self.view.bounds.size.width - 149.0f)/2.0f, 320.0f, 149.0f, 87.0f);
        [self.view addSubview:keyboardButton];
    }
    
    CGRect textFrame = textDisplay.frame;
    textFrame.origin.y = (self.view.bounds.size.height-textFrame.size.height)/2.0f - 40.0f;
    textDisplay.frame = textFrame;
    [self.view addSubview:textDisplay];
    
    [self.view addSubview:textField];
    [textField becomeFirstResponder];
}

- (void)dealloc {
    [self cancelDictation];
    [dictationButton removeFromSuperview];
    [dictationButton release];
    
    [self displaySpinner:NO];
    self.spinner = nil;
    self.removeSpinnerTimer = nil;
    
    [textField removeFromSuperview];
    [textField release];
    [textDisplay removeFromSuperview];
    [textDisplay release];
    
    [twss release];
    
    AudioServicesDisposeSystemSoundID(audioEffect);
    
    [displayImage removeFromSuperview];
    self.displayImage = nil;
    
    [locationManager stopUpdatingLocation];
    [locationManager release];
    
    [super dealloc];
}

@end
