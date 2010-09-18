//
//  SFTouchView.h
//  MapKitFun
//
//  Created by Brandon Alexander on 8/27/10.
//  Copyright 2010 Kudzu Interactive. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <MapKit/MapKit.h>

@class SFTouchView;

@protocol SFTouchViewDelegate

-(void)view:(SFTouchView *)view touchDidEnd:(UITouch *)touch;

@end


@interface SFTouchView : UIView {
	id<SFTouchViewDelegate> delegate;
}

@property (assign) id<SFTouchViewDelegate> delegate;

@end
