//
//  SFTouchView.m
//  MapKitFun
//
//  Created by Brandon Alexander on 8/27/10.
//  Copyright 2010 Kudzu Interactive. All rights reserved.
//

#import "SFTouchView.h"


@implementation SFTouchView
@synthesize delegate;

- (id)initWithFrame:(CGRect)frame {
    if ((self = [super initWithFrame:frame])) {
        // Initialization code
    }
    return self;
}

/*
// Only override drawRect: if you perform custom drawing.
// An empty implementation adversely affects performance during animation.
- (void)drawRect:(CGRect)rect {
    // Drawing code
}
*/

-(void) touchesEnded:(NSSet *)touches withEvent:(UIEvent *)event {
	NSLog(@"Touch ended");
	UITouch *touch = (UITouch *)[touches anyObject];
	
	[delegate view:self touchDidEnd:touch];
}

- (void)dealloc {
    [super dealloc];
}


@end
