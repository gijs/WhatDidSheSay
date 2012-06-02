//
//  NearbyViewController.h
//  WhatDidSheSay
//
//  Created by Max Weisel on 3/10/12.
//  Copyright (c) 2012 RelativeWave. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <MapKit/MapKit.h>

@interface NearbyViewController : UIViewController <MKMapViewDelegate> {
    MKMapView *mapView;
    BOOL locationTrackOn;
}

@property (nonatomic, assign) BOOL locationTrackOn;

@end
