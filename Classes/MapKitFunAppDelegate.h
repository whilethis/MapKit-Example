//
//  MapKitFunAppDelegate.h
//  MapKitFun
//
//  Created by Brandon Alexander on 8/24/10.
//  Copyright Kudzu Interactive 2010. All rights reserved.
//

#import <UIKit/UIKit.h>
@class MapViewController;
@interface MapKitFunAppDelegate : NSObject <UIApplicationDelegate> {
    UIWindow *window;
	MapViewController *mainViewController;
}

@property (nonatomic, retain) IBOutlet UIWindow *window;
@property (nonatomic, retain) IBOutlet MapViewController *mainViewController;

@end

