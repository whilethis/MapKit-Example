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
#import "SFCentroidAnnotation.h"

NSInteger AnnotationSortFunction(id annotation1, id annotation2, void *context) {
	SFCentroidAnnotation *referencePoint = (SFCentroidAnnotation *)context;
	
	double x1 = ([annotation1 coordinate].longitude - [referencePoint coordinate].longitude);
	double x2 = ([annotation2 coordinate].longitude - [referencePoint coordinate].longitude);
	
	double y1 = ([annotation1 coordinate].latitude - [referencePoint coordinate].latitude);
	double y2 = ([annotation2 coordinate].latitude - [referencePoint coordinate].latitude);
	
	double angle1 = atan2(y1, x1) * 180 / M_PI;
	double angle2 = atan2(y2, x2) * 180 / M_PI;

	if(angle1 < -90) {
		angle1 = fabs(angle1) + 90;
	} else if (angle1 < 0) {
		angle1 += 360;
	}
	
	if(angle2 < -90) {
		angle2 = fabs(angle2) + 90;
	} else if (angle2 < 0) {
		angle2 += 360;
	}
	
	if (angle1 < angle2) {
		return NSOrderedAscending;
	} else {
		return NSOrderedDescending;
	}

	
	return NSOrderedSame;
}

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
	
	//Using the location manager to get around the quirk in the simulator
	locationManager = [[CLLocationManager alloc] init];
	locationManager.delegate = self;
	
	[locationManager startUpdatingLocation];
	
	UILongPressGestureRecognizer *gestureRecognizer = 
	[[UILongPressGestureRecognizer alloc] initWithTarget:self action:@selector(handleLongPress:)];
	[gestureRecognizer setMinimumPressDuration:0.25];
	
	//MKMapView is configured in the nib
	[mapView addGestureRecognizer:gestureRecognizer];
	[gestureRecognizer release];
	
	sortedAnnotations = [[NSMutableArray alloc] init];
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
	[sortedAnnotations addObject:userLocation];
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
	
	polygonView.fillColor = [[UIColor blueColor] colorWithAlphaComponent:0.2];
	polygonView.strokeColor = [[UIColor blueColor] colorWithAlphaComponent:0.7];
	polygonView.lineWidth = 3;
	
	return polygonView;
}

- (void)mapView:(MKMapView *)mapView annotationView:(MKAnnotationView *)view didChangeDragState:(MKAnnotationViewDragState)newState fromOldState:(MKAnnotationViewDragState)oldState {
	if(newState == MKAnnotationViewDragStateEnding) {
		[self findCentroid:nil];
	}
}

#pragma mark -
#pragma mark UIGestureRecognizer Handlers
-(void)handleLongPress:(UILongPressGestureRecognizer *)gestureRecognizer {
	if (gestureRecognizer.state == UIGestureRecognizerStateEnded) {
		CGPoint touchLocation = [gestureRecognizer locationInView:mapView];
		CLLocationCoordinate2D coordinate = [mapView convertPoint:touchLocation toCoordinateFromView:mapView];
		
		MKPointAnnotation *newAnnotation = [[MKPointAnnotation alloc] init];
		newAnnotation.coordinate = coordinate;
		
		[mapView addAnnotation:newAnnotation];
		[sortedAnnotations addObject:newAnnotation];
		[newAnnotation release];
		
		if(centroidAnnotation != nil) {
			[self findCentroid:nil];
		}
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
	centroidAnnotation = [[SFCentroidAnnotation alloc] init];
	centroidAnnotation.coordinate = CLLocationCoordinate2DMake(latAverage, longAverage);
	
	[mapView addAnnotation:centroidAnnotation];

	[self addRegion];
}

-(void) addRegion {
	if(centroidAnnotation == nil) {
		return;
	}
	
	CLLocationCoordinate2D points[[sortedAnnotations count]];
	
	//Sort the non-centroid annotations
	[sortedAnnotations sortUsingFunction:AnnotationSortFunction context:centroidAnnotation];
	
	for(int i = 0; i < [sortedAnnotations count]; i++) {
		points[i] = [[sortedAnnotations objectAtIndex:i] coordinate];
	}
	
	if(overlayPolygon) {
		[mapView removeOverlay:overlayPolygon];
		[overlayPolygon release];
		overlayPolygon = nil;
	}
	
	overlayPolygon = [[MKPolygon polygonWithCoordinates:points count:[sortedAnnotations count]] retain];
	
	[mapView addOverlay:overlayPolygon];
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
