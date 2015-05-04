//
//  SVSwipeCollectionViewCell.swift
//  SavoryApp
//
//  Created by PJ Dillon on 2/25/15.
//  Copyright (c) 2015 SavoryLabs. All rights reserved.
//

import UIKit

public enum SVSwipeableViewMode {
    case None
    case LeaveVisible
    case SnapBack
}

public protocol SVSwipeableViewDelegate {
    func buildLeadingView(container:UIView) -> SVSwipeableViewMode
    func buildTrailingView(container:UIView) -> SVSwipeableViewMode
}

private enum SVSwipeableViewState {
    case Idle
    case ShowingView
}

public class SVSwipeableView: NSObject, UIGestureRecognizerDelegate {
    internal var panGestureRecognizer: UIPanGestureRecognizer?

    internal var containerView: UIView
    internal var leftSlideViewContainer: UIView?
    internal var rightSlideViewContainer: UIView?

    internal var contentConstraint: NSLayoutConstraint
    
    internal var currentMode: SVSwipeableViewMode = .None
    internal var enableLeading: Bool = false
    internal var enableTrailing: Bool = false

    public var delegate: SVSwipeableViewDelegate?

    init(container:UIView, contentView:UIView, moveConstraint:NSLayoutConstraint) {
        containerView = container
        contentConstraint = moveConstraint
        super.init()
        panGestureRecognizer = UIPanGestureRecognizer(target: self, action: Selector("handlePanGesture:"))
        container.addGestureRecognizer(panGestureRecognizer!)
        panGestureRecognizer?.delegate = self
    }
    
    private var dragState: SVSwipeableViewState = .Idle

    internal func handlePanGesture (gesture: UIPanGestureRecognizer) {
        let state: UIGestureRecognizerState = gesture.state
        let translation: CGPoint = gesture.translationInView(containerView)
        var percentage: CGFloat = self.percentOfOffset(contentConstraint.constant, width: containerView.bounds.width)
        var isLeadingSide: Bool = false
        var slideView: UIView
        
        if (state == UIGestureRecognizerState.Began || state == UIGestureRecognizerState.Changed) {
            if (percentage > 0) {
                slideView = self.leftSlideViewContainer!
                isLeadingSide = true
            } else {
                percentage = -percentage
                slideView = self.rightSlideViewContainer!
            }
            switch (dragState) {
            case .Idle:
                NSLog("idle %f", percentage.native)
                if delegate != nil {
                    clearView(self.leftSlideViewContainer!)
                    clearView(self.rightSlideViewContainer!)
                    self.currentMode = delegate!.buildLeadingView(self.leftSlideViewContainer!)
                    self.currentMode = delegate!.buildTrailingView(self.rightSlideViewContainer!)
                }
                dragState = .ShowingView
                break;
            case .ShowingView:
                break;
            }
        }
    }

    internal func clearView (view: UIView) {
        let views : [AnyObject] = view.subviews
        for (var i: Int = views.count - 1; i >= 0; i--) {
            views[i].removeFromSuperview()
        }
    }

    // MARK: UIGestureRecognizerDelegate
    public func gestureRecognizerShouldBegin(gestureRecognizer: UIGestureRecognizer) -> Bool {
        if gestureRecognizer.isKindOfClass(UIPanGestureRecognizer) {
            var g : UIPanGestureRecognizer = gestureRecognizer as! UIPanGestureRecognizer
            var velocity: CGPoint = g.velocityInView(containerView)
            let xComponent: Float = Float(velocity.x)
            let yComponent: Float = Float(velocity.y)
            if (fabsf(Float(xComponent)) > fabsf(yComponent)) {
                if (xComponent < 0 && enableTrailing || xComponent > 0 && enableLeading) {
                    return true
                }
            }
        }
        return false
    }

    // MARK: Percentage functions
    internal func percentOfOffset(offset:CGFloat, width:CGFloat) -> CGFloat {
        var percent = offset / width;
        
        if percent < -1.0 {
            percent = -1.0
        } else if percent > 1.0 {
            percent = 1.0
        }
        return percent * 100
    }
}