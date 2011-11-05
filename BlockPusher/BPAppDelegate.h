//
//  BPAppDelegate.h
//  BlockPusher
//
//  Created by Jon Packer on 5/11/11.
//  Copyright (c) 2011 Creative Intersection. All rights reserved.
//

#import <UIKit/UIKit.h>

@class BPViewController;

@interface BPAppDelegate : UIResponder <UIApplicationDelegate>

@property (strong, nonatomic) UIWindow *window;

@property (strong, nonatomic) BPViewController *viewController;

@end
