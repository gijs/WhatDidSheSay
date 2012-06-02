//
//  DictationClass.m
//  WhatDidSheSay
//
//  Created by Max Weisel on 1/18/12.
//  Copyright (c) 2012 RelativeWave. All rights reserved.
//

#import "DictationClass.h"

// Nothing in this class should ever actually be called.
@implementation DictationClass

+ (id)sharedInstance {
    return nil;
}

- (void)startDictation {
    NSLog(@"%@", [@"l" stringByAppendingString:@"ol"]);
}

- (void)stopDictation {
    NSLog(@"%@", [@"ro" stringByAppendingString:@"fl"]);
}

- (float)normalizedAudioLevel {
    return 0.5f;
}

@end
