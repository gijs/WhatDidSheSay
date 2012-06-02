//
//  MapAnnotation.m
//  WhatDidSheSay
//
//  Created by Max Weisel on 3/11/12.
//  Copyright (c) 2012 RelativeWave. All rights reserved.
//

#import "MapAnnotation.h"

@implementation MapAnnotation

@synthesize coordinate;
@synthesize title;

- (id)initWithCoordinate:(CLLocationCoordinate2D)coordinate_ title:(NSString *)title_ {
    if ((self = [super init]) != nil) {
        coordinate = coordinate_;
        title = [title_ copy];
    }
    return self;
}

- (void)dealloc {
    [title release];
    [super dealloc];
}

@end
