//
//  MapViewController.h
//  MapKitFun
//
//  Created by Brandon Alexander on 8/24/10.
//  Copyright 2010 Kudzu Interactive. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <MapKit/MapKit.h>

@interface MapViewController : UIViewController<MKMapViewDelegate, CLLocationManagerDelegate> {
	MKMapView *mapView;
	CLLocationManager *locationManager;
	UIBarButtonItem *centroidButton;
	NSMutableArray *sortedAnnotations;
	
	MKPointAnnotation *centroidAnnotation;
	MKPolygon *overlayPolygon;
}

@property (retain, nonatomic) IBOutlet MKMapView *mapView;
@property (retain, nonatomic) IBOutlet UIBarButtonItem *centroidButton;

-(IBAction)findCentroid:(id)sender;

@end
