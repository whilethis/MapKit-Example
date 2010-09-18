//
//  MapViewController.m
//  MapKitFun
//
//  Created by Brandon Alexander on 8/24/10.
//  Copyright 2010 Kudzu Interactive. All rights reserved.
//

#import <MapKit/MapKit.h>
#import <MapKit/MKPolygonView.h>
#import <MapKit/MKPolygon.h>
#import "MapViewController.h"
#import "SFTouchView.h"
#import "SFCentroidAnnotation.h"

@interface MapViewController(PrivateMethods)
-(void) addRegion;
@end


@implementation MapViewController
@synthesize mapView, centroidButton;

/*
 // The designated initializer.  Override if you create the controller programmatically and want to perform customization that is not appropriate for viewDidLoad.
- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil {
    if ((self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil])) {
        // Custom initialization
    }
    return self;
}
*/


// Implement viewDidLoad to do additional setup after loading the view, typically from a nib.
- (void)viewDidLoad {
    [super viewDidLoad];

	locationManager = [[CLLocationManager alloc] init];
	locationManager.delegate = self;
	
	[locationManager startUpdatingLocation];
	
	CGRect viewRect = [self.mapView frame];
	overlay = [[SFTouchView alloc] initWithFrame:viewRect];
	overlay.delegate = self;
	overlay.multipleTouchEnabled = NO;
	overlay.userInteractionEnabled = YES;
	
	UILongPressGestureRecognizer *gestureRecognizer = 
	[[UILongPressGestureRecognizer alloc] initWithTarget:self action:@selector(handleLongPress:)];
	
	[mapView addGestureRecognizer:gestureRecognizer];
	[gestureRecognizer release];
}


/*
// Override to allow orientations other than the default portrait orientation.
- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
    // Return YES for supported orientations
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}
*/

#pragma mark -
#pragma mark CLLocationManager Methods
- (void)locationManager:(CLLocationManager *)manager didUpdateToLocation:(CLLocation *)newLocation fromLocation:(CLLocation *)oldLocation {
	MKCoordinateRegion region = MKCoordinateRegionMake(newLocation.coordinate, MKCoordinateSpanMake(0.05, 0.05));
	[mapView setRegion:region];
	
	[manager stopUpdatingLocation];
	
	MKPointAnnotation *userLocation = [[MKPointAnnotation alloc] init];
	userLocation.coordinate = newLocation.coordinate;
	
	[mapView addAnnotation:userLocation];
	[userLocation release];
}

#pragma mark -
#pragma mark MKMapViewDelegate Methods
- (MKAnnotationView *)mapView:(MKMapView *)mapView viewForAnnotation:(id <MKAnnotation>)annotation {
	MKPinAnnotationView *annotationView = [[[MKPinAnnotationView alloc] initWithAnnotation:annotation reuseIdentifier:@""] autorelease];
	
	annotationView.animatesDrop = YES;
	annotationView.canShowCallout = NO;
	annotationView.draggable = YES;
	
	if([annotation isKindOfClass:[SFCentroidAnnotation class]]) {
		annotationView.canShowCallout = YES;
		annotationView.draggable = NO;
	}
	
	return annotationView;
}

- (MKOverlayView *)mapView:(MKMapView *)mapView viewForOverlay:(id <MKOverlay>)mapOverlay {
	MKPolygonView *polygonView = [[[MKPolygonView alloc] initWithPolygon:(MKPolygon *)mapOverlay] autorelease];
	
	polygonView.fillColor = [[UIColor cyanColor] colorWithAlphaComponent:0.2];
	polygonView.strokeColor = [[UIColor blueColor] colorWithAlphaComponent:0.7];
	polygonView.lineWidth = 3;
	
	return polygonView;
}

#pragma mark -
#pragma mark SFTouchViewDelegate Methods
-(void)view:(SFTouchView *)view touchDidEnd:(UITouch *)touch {
	NSLog(@"Touch: %@", [touch description]);
	CGPoint touchLocation = [touch locationInView:mapView];
	CLLocationCoordinate2D coordinate = [mapView convertPoint:touchLocation toCoordinateFromView:mapView];
	
	MKPointAnnotation *newAnnotation = [[MKPointAnnotation alloc] init];
	newAnnotation.coordinate = coordinate;
	
	[mapView addAnnotation:newAnnotation];
	[newAnnotation release];
}

-(void)handleLongPress:(UILongPressGestureRecognizer *)gestureRecognizer {
	if (gestureRecognizer.state == UIGestureRecognizerStateEnded) {
		CGPoint touchLocation = [gestureRecognizer locationInView:mapView];
		CLLocationCoordinate2D coordinate = [mapView convertPoint:touchLocation toCoordinateFromView:mapView];
		
		MKPointAnnotation *newAnnotation = [[MKPointAnnotation alloc] init];
		newAnnotation.coordinate = coordinate;
		
		[mapView addAnnotation:newAnnotation];
		[newAnnotation release];
	}
}

#pragma mark -
#pragma mark Actions Received
-(IBAction)findCentroid:(id)sender {
	CLLocationDegrees latAverage = 0.0;
	CLLocationDegrees longAverage = 0.0;
	
	MKPointAnnotation *annotation;
	for(annotation in [mapView annotations]) {
		latAverage += [annotation coordinate].latitude;
		longAverage += [annotation coordinate].longitude;
	}
	
	latAverage /= [[mapView annotations] count];
	longAverage /= [[mapView annotations] count];
	
	if(centroidAnnotation) {
		[mapView removeAnnotation:centroidAnnotation];
		[centroidAnnotation release];
		centroidAnnotation = nil;
	}
	[self addRegion];
	
	centroidAnnotation = [[SFCentroidAnnotation alloc] init];
	centroidAnnotation.coordinate = CLLocationCoordinate2DMake(latAverage, longAverage);
	
	[mapView addAnnotation:centroidAnnotation];
}

-(void) addRegion {
	CLLocationCoordinate2D points[[mapView.annotations count]];
	
	for(int i = 0; i < [mapView.annotations count]; i++) {
		points[i] = [[mapView.annotations objectAtIndex:i] coordinate];
	}
	
	if(overlayPolygon) {
		[mapView removeOverlay:overlayPolygon];
		[overlayPolygon release];
		overlayPolygon = nil;
	}
	
	overlayPolygon = [[MKPolygon polygonWithCoordinates:points count:[mapView.annotations count]] retain];
	
	[mapView addOverlay:overlayPolygon];
}

-(IBAction)startEdit:(id)sender {
	UIBarButtonItem *button = (UIBarButtonItem *)sender;
	if ([[button title] isEqualToString:@"Done"]) {
		[button setStyle:UIBarButtonItemStyleBordered];
		[button setTitle:@"Edit"];
		
		[centroidButton setEnabled:YES];
		[overlay removeFromSuperview];
	} else {
		[button setStyle:UIBarButtonItemStyleDone];
		[button setTitle:@"Done"];
		
		[centroidButton setEnabled:NO];
		[self.view addSubview:overlay];
	}
	
}

#pragma mark -
#pragma mark Memory Management

- (void)didReceiveMemoryWarning {
    // Releases the view if it doesn't have a superview.
    [super didReceiveMemoryWarning];
    
    // Release any cached data, images, etc that aren't in use.
}

- (void)viewDidUnload {
    [super viewDidUnload];
    // Release any retained subviews of the main view.
    // e.g. self.myOutlet = nil;
}


- (void)dealloc {
    [super dealloc];
}


@end
