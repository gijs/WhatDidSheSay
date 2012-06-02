//
//  TWSS.h
//  WhatDidSheSay
//
//  Created by Max Weisel on 1/17/12.
//  Copyright (c) 2012 Develoe LLC. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface TWSS : NSObject {
    int numberOfWordsInNgram;
    float threshold;
    int trainingSize;
    NSMutableArray *positiveData;
    NSMutableArray *negativeData;
    NSDictionary *probabilities;
}

- (BOOL)isTWSS:(NSString *)string;

@end
