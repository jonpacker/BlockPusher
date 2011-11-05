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
- (BOOL) findContiguousViewsFromPoint:(CGPoint)point movingRight:(BOOL)right {
  UIView* baseView = [self findDraggableContainingPoint:point];
  _targetView = baseView;
  
  if (!baseView) return NO;
  
  // first, find all the contiguous views to the right of our base
  _contiguousViews = [[NSMutableArray alloc] init];
  UIView* contiguousView = baseView;
  CGPoint contiguousPoint;
  do {
    contiguousPoint = contiguousView.frame.origin;
    if (right) {
      [_contiguousViews addObject:contiguousView];
      contiguousPoint.x += draggableViewWidth + draggableViewPadding;
    } else {
      [_contiguousViews insertObject:contiguousView atIndex:0];
      contiguousPoint.x -= draggableViewWidth + draggableViewPadding;
    }
  } while ((contiguousView = [self findDraggableContainingPoint:contiguousPoint]));
  
  baseView = [_contiguousViews objectAtIndex:0];
  
  // our rightmost contiguous view will be last in the array, so we find the subview that is closest to it.
  NSArray* subviews = self.view.subviews;
  UIView* closestView = nil;
  UIView* edgeCongiguousView = right ? [_contiguousViews lastObject] : [_contiguousViews objectAtIndex:0];
  CGFloat qualifyingX = right 
                          ? edgeCongiguousView.frame.origin.x + edgeCongiguousView.frame.size.width 
                            + draggableViewPadding
                          : edgeCongiguousView.frame.origin.x - draggableViewPadding;
  for (UIView* view in subviews) {
    if ((right && view.frame.origin.x < qualifyingX) || (!right && view.frame.origin.x > qualifyingX)) continue;
    
    if (!closestView || 
        (right && view.frame.origin.x < closestView.frame.origin.x) ||
        (!right && view.frame.origin.x > closestView.frame.origin.x)) {
      closestView = view;
    }
  }
  
  if (closestView && right) _nextCollisionPoint = closestView.frame.origin.x - draggableViewPadding;
  else if (closestView) _nextCollisionPoint = closestView.frame.origin.x + closestView.frame.size.width 
                                            + draggableViewPadding;
  else _nextCollisionPoint = -1;
  
  if (right) {
    _contiguousSetSize = qualifyingX - baseView.frame.origin.x;  
  } else {
    UIView* lastView = [_contiguousViews lastObject];
    _contiguousSetSize = lastView.frame.origin.x + lastView.frame.size.width - qualifyingX;
  }
  
  [self redistributeContiguousBlock];
  
  return YES;
}

- (void) panGestureRecognizerPerformedAction:(UIPanGestureRecognizer *)panGestureRecognizer {
  CGPoint point = [panGestureRecognizer locationInView:self.view];
  
  if (panGestureRecognizer.state == UIGestureRecognizerStateBegan) {
    _isCurrentlyPanning = [self findContiguousViewsFromPoint:point movingRight:YES];
    _currentlyPanningRight = YES;
    _previousHorizontalTranslation = 0;
  } else if (panGestureRecognizer.state == UIGestureRecognizerStateEnded) {
    _isCurrentlyPanning = NO;
    [_contiguousViews release];
    _contiguousViews = nil;
  } else if (panGestureRecognizer.state == UIGestureRecognizerStateChanged && _isCurrentlyPanning) {
    CGFloat horizontalTranslation = [panGestureRecognizer translationInView:self.view].x;
    CGFloat effectiveTranslation = horizontalTranslation - _previousHorizontalTranslation;
    UIView* baseView = [_contiguousViews objectAtIndex:0];
    
    if ((_currentlyPanningRight  && horizontalTranslation < _previousHorizontalTranslation) ||
        (!_currentlyPanningRight && horizontalTranslation > _previousHorizontalTranslation)) {
      _currentlyPanningRight = !_currentlyPanningRight;
      [self findContiguousViewsFromPoint:_targetView.frame.origin movingRight:_currentlyPanningRight];
    }
    
    if (_nextCollisionPoint > 0) {
      BOOL hasCollided = _currentlyPanningRight
      ? baseView.frame.origin.x + _contiguousSetSize + effectiveTranslation >= _nextCollisionPoint
      : baseView.frame.origin.x - draggableViewPadding + effectiveTranslation <= _nextCollisionPoint;
      
      if (hasCollided) {
        [self findContiguousViewsFromPoint:_targetView.frame.origin movingRight:_currentlyPanningRight];
      }
    }
    
    CGFloat rightBound = self.view.frame.size.width - draggableViewPadding;
    CGFloat leftBound = draggableViewPadding;
    
    if ((_currentlyPanningRight && baseView.frame.origin.x + _contiguousSetSize + effectiveTranslation < rightBound) ||
        (!_currentlyPanningRight && baseView.frame.origin.x + effectiveTranslation > leftBound)) {
      for (UIView* view in _contiguousViews) {
        CGRect newFrame = view.frame;
        newFrame.origin.x += effectiveTranslation;
        view.frame = newFrame;
      }
    }
      
    _previousHorizontalTranslation = horizontalTranslation;
  }
}

@end
