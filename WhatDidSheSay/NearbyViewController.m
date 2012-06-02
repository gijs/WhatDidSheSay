//
//  NearbyViewController.m
//  WhatDidSheSay
//
//  Created by Max Weisel on 3/10/12.
//  Copyright (c) 2012 RelativeWave. All rights reserved.
//

#import "NearbyViewController.h"
#import <Parse/Parse.h>
#import "AppDelegate.h"
#import "MapAnnotation.h"

@implementation NearbyViewController

@synthesize locationTrackOn;

- (id)init {
    if ((self = [super init]) != nil) {
        self.tabBarItem.image = [UIImage imageNamed:@"Earth.png"];
        self.title = @"Nearby";
        
        mapView = [[MKMapView alloc] init];
        mapView.showsUserLocation = YES;
        mapView.userTrackingMode = MKUserTrackingModeNone;
        mapView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
        mapView.delegate = self;
        
        self.navigationItem.leftBarButtonItem = [[[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"Arrow.png"] style:UIBarButtonItemStylePlain target:self action:@selector(locate)] autorelease];
        self.navigationItem.rightBarButtonItem = [[[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemRefresh target:self action:@selector(refresh)] autorelease];
        
        locationTrackOn = NO;
        
        self.locationTrackOn = YES;
    }
    return self;
}

- (void)locate {
    self.locationTrackOn = !locationTrackOn;
}

- (void)mapView:(MKMapView *)mapView didChangeUserTrackingMode:(MKUserTrackingMode)mode animated:(BOOL)animated {
    if (mode == MKUserTrackingModeNone) {
        self.navigationItem.leftBarButtonItem.style = UIBarButtonItemStylePlain;
        locationTrackOn = NO;
    } else {
        self.navigationItem.leftBarButtonItem.style = UIBarButtonItemStyleDone;
        locationTrackOn = YES;
    }
}

- (void)setLocationTrackOn:(BOOL)locationTrackOn_ {
    locationTrackOn = locationTrackOn_;
    if (locationTrackOn_) {
        mapView.userTrackingMode = MKUserTrackingModeNone;
        [mapView setUserTrackingMode:MKUserTrackingModeFollow animated:YES];
    } else {
        mapView.userTrackingMode = MKUserTrackingModeNone;
    }
}

- (void)displayObjects:(NSArray *)objects {
    [objects retain];
    
    if (objects.count == 0) {
        [objects release];
        return;
    }
    
    CLLocationCoordinate2D southWest = mapView.userLocation.coordinate;
    CLLocationCoordinate2D northEast = southWest;
    
    NSMutableArray *annotations = [[NSMutableArray alloc] initWithCapacity:objects.count];
    for (PFObject *object in objects) {
        PFGeoPoint *point = [object objectForKey:@"point"];
        if (point != nil) {
            southWest.latitude = MIN(southWest.latitude, point.latitude);
            southWest.longitude = MIN(southWest.longitude, point.longitude);
            
            northEast.latitude = MAX(northEast.latitude, point.latitude);
            northEast.longitude = MAX(northEast.longitude, point.longitude);
            
            MapAnnotation *annotation = [[MapAnnotation alloc] initWithCoordinate:CLLocationCoordinate2DMake(point.latitude, point.longitude) title:[object objectForKey:@"text"]];
            [annotations addObject:annotation];
        }
    }
    [mapView addAnnotations:annotations];
    [annotations release];
    
    CLLocation *locSouthWest = [[CLLocation alloc] initWithLatitude:southWest.latitude longitude:southWest.longitude];
    CLLocation *locNorthEast = [[CLLocation alloc] initWithLatitude:northEast.latitude longitude:northEast.longitude];
    
    CLLocationDistance meters = [locSouthWest distanceFromLocation:locNorthEast];
    MKCoordinateRegion region;
    region.center.latitude = (southWest.latitude + northEast.latitude) / 2.0;
    region.center.longitude = (southWest.longitude + northEast.longitude) / 2.0;
    region.span.latitudeDelta = meters / 111319.5;
    region.span.longitudeDelta = 0.0;
    [mapView setRegion:[mapView regionThatFits:region] animated:YES];
    [locSouthWest release];
    [locNorthEast release];
    
    [objects release];
}

- (MKAnnotationView *)mapView:(MKMapView *)mapView_ viewForAnnotation:(id <MKAnnotation>)annotation_ {
    if(annotation_.coordinate.latitude == mapView.userLocation.location.coordinate.latitude && annotation_.coordinate.longitude == mapView.userLocation.location.coordinate.longitude)
        return nil;
    
    MKPinAnnotationView *pin = (MKPinAnnotationView *)[mapView dequeueReusableAnnotationViewWithIdentifier:@"PinAnnotation"];
    if (pin == nil) {
        pin = [[[MKPinAnnotationView alloc] initWithAnnotation:annotation_ reuseIdentifier:@"PinAnnotation"] autorelease];
    } else {
        pin.annotation = annotation_;
    }
    
    pin.canShowCallout = YES;
    pin.animatesDrop = YES;
    return pin;
}

- (void)addAnnotationsAtPoint:(CLLocationCoordinate2D)coordinate withinKilometers:(double)k {
    [mapView removeAnnotations:mapView.annotations];
    PFGeoPoint *location = [PFGeoPoint geoPointWithLatitude:coordinate.latitude longitude:coordinate.longitude];
    PFQuery *query = [PFQuery queryWithClassName:@"TWSS"];
    [query whereKey:@"point" nearGeoPoint:location withinKilometers:k];
    //[query whereKey:@"localIdentifier" notEqualTo:localIdentifier()]; // Don't show TWSS's that came from this device.
    query.limit = [NSNumber numberWithInt:100];
    [query findObjectsInBackgroundWithBlock:^(NSArray *objects, NSError *error) {
        if (!error) {
            // The find succeeded.
            [self performSelectorOnMainThread:@selector(displayObjects:) withObject:[[objects retain] autorelease] waitUntilDone:NO];
        } else {
            // Log details of the failure
            NSLog(@"Error: %@ %@", error, [error userInfo]);
        }
    }];
}

- (void)refresh {
    [self addAnnotationsAtPoint:mapView.centerCoordinate withinKilometers:mapView.region.span.latitudeDelta*111.3195];
}

- (void)viewDidLoad {
    [super viewDidLoad];
    mapView.frame = self.view.bounds;
    [self.view addSubview:mapView];
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    [self addAnnotationsAtPoint:mapView.userLocation.coordinate withinKilometers:200];
}

- (void)dealloc {
    [mapView release];
    [super dealloc];
}

@end
