//
//  BPViewController.h
//  BlockPusher
//
//  Created by Jon Packer on 5/11/11.
//  Copyright (c) 2011  Jon Packer. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface BPViewController : UIViewController {
 @private
  NSMutableArray* _contiguousViews;
  UIView* _targetView;
  CGFloat _nextCollisionPoint;
  CGFloat _contiguousSetSize;
  CGFloat _previousHorizontalTranslation;
  BOOL _isCurrentlyPanning;
  BOOL _currentlyPanningRight;
}

@end
