//
//  DictationClass.h
//  WhatDidSheSay
//
//  Created by Max Weisel on 1/18/12.
//  Copyright (c) 2012 RelativeWave. All rights reserved.
//

#import <Foundation/Foundation.h>

// This is a bullshit class I use to represent UIDictationController
@interface DictationClass : NSObject {
    
}

+ (id)sharedInstance;

- (void)startDictation;
- (void)stopDictation;
- (float)normalizedAudioLevel;

@end
