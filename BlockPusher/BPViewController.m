//
//  BPViewController.m
//  BlockPusher
//
//  Created by Jon Packer on 5/11/11.
//  Copyright (c) 2011 Jon Packer. All rights reserved.
//

#import "BPViewController.h"
#import <QuartzCore/QuartzCore.h>

static const CGFloat draggableViewWidth = 40;
static const CGFloat draggableViewHeight = 80;
static const CGFloat draggableViewYOffset = 5;
static const CGFloat draggableViewPadding = 2;

#define RAND_0_1 (float)rand()/(float)RAND_MAX

@implementation BPViewController

- (void) loadView {
  [super loadView];
  
  int i = 0;
  CGFloat offset = draggableViewPadding;
  
  // Create 10 dummy views for dragging
  while (++i <= 10) {
    
    UIView* draggableView = [[UIView alloc] initWithFrame:CGRectMake(offset, draggableViewYOffset, draggableViewWidth, 
                                                                     draggableViewHeight)];
    offset += draggableViewWidth + draggableViewPadding;
    draggableView.backgroundColor = [UIColor colorWithRed:RAND_0_1 green:RAND_0_1 blue:RAND_0_1 alpha:1];
    draggableView.layer.cornerRadius = 5.0f;
    
    [self.view addSubview:draggableView];
    [draggableView release];
    
  }
  
}

- (void) viewDidLoad {
  [super viewDidLoad];
  
  SEL action = @selector(panGestureRecognizerPerformedAction:);
  UIPanGestureRecognizer* panGestureRecognizer = [[UIPanGestureRecognizer alloc] initWithTarget:self action:action];
  
  [self.view addGestureRecognizer:panGestureRecognizer];
  [panGestureRecognizer release];
}

- (void) redistributeContiguousBlock {
  NSEnumerator* enumerator = [_contiguousViews objectEnumerator];
  UIView* previousView = [enumerator nextObject];
  UIView* currentView = nil;
  
  while ((currentView = [enumerator nextObject])) {
    currentView.frame = CGRectMake(previousView.frame.origin.x + draggableViewWidth + draggableViewPadding, 
                                   previousView.frame.origin.y, draggableViewWidth, draggableViewHeight);
    previousView = currentView;
  }
}
  

// Finds the draggable view containing the given point, or returns nil if no draggable contains it.
- (UIView *) findDraggableContainingPoint:(CGPoint)point {
  if (point.y > draggableViewYOffset + draggableViewHeight || point.y < draggableViewYOffset) return nil;
  
  NSArray* subviews = self.view.subviews;
  
  for (UIView* view in subviews) {
    if (point.x < view.frame.origin.x
    ||  point.x > view.frame.origin.x + view.frame.size.width) continue;
    
    return view;
  }
  
  return nil;
}

// Sets ivar _contiguousViews to the current contiguous views inclusively to the right of the draggable containing
// the point. If no draggable contains the point, this returns false. Also calculates _nextCollisionPoint.
- (BOOL) findContiguousViewsFromPoint:(CGPoint)point {
  UIView* baseView = [self findDraggableContainingPoint:point];
  
  if (!baseView) return NO;
  
  // first, find all the contiguous views to the right of our base
  _contiguousViews = [[NSMutableArray alloc] init];
  UIView* contiguousView = baseView;
  CGPoint contiguousPoint;
  do {
    [_contiguousViews addObject:contiguousView];
    contiguousPoint = contiguousView.frame.origin;
    contiguousPoint.x += draggableViewWidth + draggableViewPadding;
  } while ((contiguousView = [self findDraggableContainingPoint:contiguousPoint]));
  
  // our rightmost contiguous view will be last in the array, so we find the subview that is closest the right of it.
  NSArray* subviews = self.view.subviews;
  UIView* closestRightView = nil;
  UIView* rightmostCongiguousView = [_contiguousViews lastObject];
  CGFloat qualifyingX = rightmostCongiguousView.frame.origin.x + rightmostCongiguousView.frame.size.width 
                      + draggableViewPadding;
  for (UIView* view in subviews) {
    if (view.frame.origin.x < qualifyingX) continue;
    
    if (!closestRightView || view.frame.origin.x < closestRightView.frame.origin.x) {
      closestRightView = view;
    }
  }
  
  _nextCollisionPoint = closestRightView ? closestRightView.frame.origin.x - draggableViewPadding : -1;
  _contiguousSetSize = qualifyingX - baseView.frame.origin.x;
  
  [self redistributeContiguousBlock];
  
  return YES;
}

- (void) panGestureRecognizerPerformedAction:(UIPanGestureRecognizer *)panGestureRecognizer {
  CGPoint point = [panGestureRecognizer locationInView:self.view];
  
  if (panGestureRecognizer.state == UIGestureRecognizerStateBegan) {
    _isCurrentlyPanning = [self findContiguousViewsFromPoint:point];
    _previousHorizontalTranslation = 0;
  } else if (panGestureRecognizer.state == UIGestureRecognizerStateEnded) {
    _isCurrentlyPanning = NO;
    [_contiguousViews release];
    _contiguousViews = nil;
  } else if (panGestureRecognizer.state == UIGestureRecognizerStateChanged && _isCurrentlyPanning) {
    CGFloat horizontalTranslation = [panGestureRecognizer translationInView:self.view].x;
    CGFloat effectiveTranslation = horizontalTranslation - _previousHorizontalTranslation;
    
    for (UIView* view in _contiguousViews) {
      CGRect newFrame = view.frame;
      newFrame.origin.x += effectiveTranslation;
      view.frame = newFrame;
    }
    
    if (_nextCollisionPoint > 0) {
      UIView* baseView = [_contiguousViews objectAtIndex:0];
      if (baseView.frame.origin.x + _contiguousSetSize >= _nextCollisionPoint) {
        [self findContiguousViewsFromPoint:baseView.frame.origin];
      }
    }
    
    _previousHorizontalTranslation = horizontalTranslation;
  }
}

@end
