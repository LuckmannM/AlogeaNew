//
//  MVButtonController.swift
//  Alogea
//
//  Created by mikeMBP on 16/10/2016.
//  Copyright © 2016 AppToolFactory. All rights reserved.
//
// This class provides the 'organising class' for the MVButtonView, including initialising and providing the sizing/positioning of MVButtonView
// This controller adds the MVButtonView (with it's subViews) as subView to TouchWheelView. TouchViewWheel is an IB UIView object
// it is itself initialised by the TouchWheelView receiving from it the frame, wheelWidth and margins; the sizeButtonView func is called from TWV.draw
// it is the Delegate of touchWheel receiving the scoreValue and passing it to buttonView to display
// varButtonView contains the scoreLabel and initiates the MVButton itself based on position and size it received from it's controller


import Foundation
import UIKit
import CoreData

class MVButtonController: TouchWheelDelegate, MVButtonDelegate {
    
    var buttonView: MVButtonView!
    var eventsDataController: EventsDataController!
    weak var roundButton: MVButton!
    weak var touchWheel: TouchWheelView!
    weak var mainViewController: MainViewController!
    
    init(viewRect: CGRect, touchWheel: TouchWheelView, mainViewController: MainViewController) {
        print("init MVButtonController")
        
        self.touchWheel = touchWheel
        touchWheel.delegate = self
        buttonView = MVButtonView(frame: viewRect, controller: self)
        roundButton = buttonView.roundButton
        touchWheel.addSubview(buttonView)
        self.mainViewController = mainViewController
        self.eventsDataController = EventsDataController.sharedInstance()
        print("finished init MVButtonController")
    }
    
    func sizeViews(rect: CGRect) {
        buttonView.frame = rect
        roundButton.frame = buttonView.bounds
        
        buttonView.setNeedsDisplay()
        roundButton.setNeedsDisplay()
    }
    
    func passOnTouchWheelScore(score: Double,ended: Bool = false) {
        
        buttonView.displayScore(score: score)
        
        if ended {
            buttonView.hideScore()
            eventsDataController.newEvent(ofType: "Score Event", withName: GraphViewHelper.sharedInstance().selectedScore ,withDate: Date(), vas: score, buttonView: buttonView)
        }
    }
        
    func mvButtonTapped(sender: MVButton) {
        buttonView.showPicker(pickerType: ButtonViewPickers.eventSelectionPickerType)
    }
    
    // MARK: - diaryEntryWindow
    
    func requestDiaryEntryWindow(frame: CGRect) {
        mainViewController.showDiaryEntryWindow(frame: frame)
    }
}
