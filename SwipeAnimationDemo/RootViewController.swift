//
//  RootViewController.swift
//  SwipeAnimationDemo
//
//  Created by Eugenia Sakuda on 5/11/17.
//  Copyright © 2017 Eugenia Sakuda. All rights reserved.
//

import UIKit

class RootViewController: UIViewController {

    @IBOutlet var panGestureRecognizer: UIPanGestureRecognizer!
    
    @IBOutlet weak var rightArrowView: UIView!
    @IBOutlet weak var leftArrowView: UIView!
    
    fileprivate var _pageViewController: UIPageViewController?
    fileprivate var _monthsViewModel: MonthsViewModel? = .none

    fileprivate var _originRightArrowViewPosition: CGRect!
    fileprivate var _originLeftArrowViewPosition: CGRect!
    
    fileprivate var _viewBeingAnimated: UIView?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        initializeViewModel()
        loadPageViewController()
        setArrowsViewStyle()
        initializeGestures()
    }

    func initializeViewModel() {
        _monthsViewModel = MonthsViewModel()
    }
}

extension RootViewController {
    
    internal func loadPageViewController() {
        _pageViewController = UIPageViewController(transitionStyle: .scroll, navigationOrientation: .horizontal, options: .none)
        _pageViewController!.delegate = self
        
        let startingViewController: DataViewController = viewControllerAtIndex(0)!
        let viewControllers = [startingViewController]
        _pageViewController!.setViewControllers(viewControllers, direction: .forward, animated: false, completion: .none)
        
        _pageViewController!.dataSource = self
        
        addChildViewController(_pageViewController!)
        view.addSubview(_pageViewController!.view)
        
        // Set the page view controller's bounds using an inset rect so that self's view is visible around the edges of the pages.
        var pageViewRect = view.bounds
        if UIDevice.current.userInterfaceIdiom == .pad {
            pageViewRect = pageViewRect.insetBy(dx: 40.0, dy: 40.0)
        }
        _pageViewController!.view.frame = pageViewRect
        _pageViewController!.didMove(toParentViewController: self)
    }
    
    internal func setArrowsViewStyle() {
        rightArrowView.layer.cornerRadius = rightArrowView.frame.height / 2
        rightArrowView.layer.borderColor = UIColor.white.cgColor
        rightArrowView.layer.borderWidth = 2.0
        view.bringSubview(toFront: rightArrowView)
        
        leftArrowView.layer.cornerRadius = rightArrowView.frame.height / 2
        leftArrowView.layer.borderColor = UIColor.white.cgColor
        leftArrowView.layer.borderWidth = 2.0
        view.bringSubview(toFront: leftArrowView)
        
        _originRightArrowViewPosition = rightArrowView.frame
        _originLeftArrowViewPosition = leftArrowView.frame
    }
    
    internal func initializeGestures() {
        panGestureRecognizer.addTarget(self, action: #selector(handleDragGesture(gesture:)))
    }
}

extension RootViewController: UIPageViewControllerDelegate, UIPageViewControllerDataSource {
    
    func pageViewController(_ pageViewController: UIPageViewController, viewControllerBefore viewController: UIViewController) -> UIViewController? {
        return .none
    }
    
    func pageViewController(_ pageViewController: UIPageViewController, viewControllerAfter viewController: UIViewController) -> UIViewController? {
        return .none
    }
}

fileprivate extension RootViewController {
    
    func viewControllerAtIndex(_ index: UInt) -> DataViewController? {
        
        guard let month = _monthsViewModel?.element(at: UInt(index)) else { return .none }
        
        // Create a new view controller and pass suitable data.
        
        let dataViewController = storyboard?.instantiateViewController(withIdentifier: "DataViewController") as! DataViewController
        dataViewController.dataObject = month
        return dataViewController
    }
    
    func indexOfViewController(_ viewController: DataViewController) -> UInt? {
        // Return the index of the given data view controller.
        // For simplicity, this implementation uses a static array of model objects and the view controller stores the model object; you can therefore use the model object to identify the index.
        return _monthsViewModel?.index(of: viewController.dataObject)
    }
}

extension RootViewController {
    
    internal func handleDragGesture(gesture: UIPanGestureRecognizer) {
        switch gesture.state {
        case .began:
            guard rightArrowView.layer.animationKeys() == nil else { return }
            _viewBeingAnimated = .none
        case .changed:
            // TODO: verify code style
            let xTranslation = gesture.translation(in: gesture.view).x
            if _viewBeingAnimated == .none {
                _viewBeingAnimated = xTranslation < 0 ? rightArrowView : leftArrowView
            }
            handleDragForArrow(with: xTranslation)
        case .ended:
            guard rightArrowView.layer.animationKeys() == nil else { return }
            if (_originRightArrowViewPosition.size != rightArrowView.frame.size) {
                rightArrowView.restaureSize(upTo: _originRightArrowViewPosition, completionHandler: .none)
            }
            if (_originLeftArrowViewPosition.size != leftArrowView.frame.size) {
                leftArrowView.restaureSize(upTo: _originLeftArrowViewPosition, completionHandler: .none)
            }
            _viewBeingAnimated = .none
        default: break
        }
    }
    
}

fileprivate extension RootViewController {
    
    fileprivate func handleDragForArrow(with xTranslation: CGFloat) {
        guard let viewBeingAnimated = _viewBeingAnimated else { return }
        let frame = viewBeingAnimated == rightArrowView ? _originRightArrowViewPosition : _originLeftArrowViewPosition
        let complementaryView = viewBeingAnimated == rightArrowView ? leftArrowView : rightArrowView
        _ = viewBeingAnimated.updateAnimation(with: xTranslation, to: frame!, with: complementaryView!) { [unowned self] _ in
            let currentIndex = Int((self._monthsViewModel?.index(of: (self._pageViewController?.viewControllers?[0] as! DataViewController).dataObject))!)
            let index = UInt(currentIndex + (viewBeingAnimated == self.rightArrowView ? 1 : -1))
            let nextController = self.viewControllerAtIndex(index)!
            self._pageViewController?.setViewControllers([nextController], direction: .forward, animated: false, completion: nil)
            complementaryView!.alpha = 1.0
            self._viewBeingAnimated!.frame = self._originRightArrowViewPosition
            self._viewBeingAnimated!.fadeInAnimation(toShow: true)
        }
    }
}

