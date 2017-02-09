//
//  GraphContainerView.swift
//  Alogea
//
//  Created by mikeMBP on 12/10/2016.
//  Copyright © 2016 AppToolFactory. All rights reserved.
//

import UIKit

let labelFontName = "AvenirNext-Regular"

class GraphContainerView: UIView, UIGestureRecognizerDelegate {

    
    @IBOutlet weak var graphView: GraphView!
    @IBOutlet weak var clipView: ClipView!
    
    var eventsController = EventsDataController.sharedInstance()
    var recordTypesController = RecordTypesController.sharedInstance()
    let colorScheme = ColorScheme.sharedInstance()
    var mainViewController: MainViewController!
    var labelTap: UITapGestureRecognizer!
    
    var upperLabel : UILabel = {
        let label = UILabel()
        label.text = "upperLabel"
        label.textAlignment = NSTextAlignment.right
        label.textColor = ColorScheme.sharedInstance().lightGray
        label.font =  UIFont(name: labelFontName, size: 18)
        label.sizeToFit()
        label.isUserInteractionEnabled = true
        return label
    }()

    var centreBottomLabel: UILabel = {
        let label = UILabel()
        label.text = "centreBottomLabel"
        label.textAlignment = NSTextAlignment.right
        label.textColor = ColorScheme.sharedInstance().lightGray
        label.font =  UIFont(name: labelFontName, size: 16)
        label.sizeToFit()
        return label
    }()
    
    let upperLimitLabel:UILabel = {
        let label = UILabel()
        label.text = "10"
        label.textAlignment = NSTextAlignment.right
        label.textColor = UIColor.white
        label.font =  UIFont(name: labelFontName, size: 12)
        label.sizeToFit()
        return label
    }()
    
    let lowerLimitLabel: UILabel = {
        let label = UILabel()
        label.text = "0"
        label.textAlignment = NSTextAlignment.right
        label.textColor = UIColor.white
        label.font =  UIFont(name: labelFontName, size: 12)
        label.sizeToFit()
        return label
    }()
    
    var rotationObserver: NotificationCenter!
    
    var centerBottomText: String {
        
        let dateFormatter: DateFormatter = {
            let formatter = DateFormatter()
            formatter.locale = NSLocale.current
            formatter.timeZone = NSTimeZone.local
            formatter.dateStyle = .short
            return formatter
        }()
        return dateFormatter.string(from: graphView.minDisplayDate) + " - " + dateFormatter.string(from: graphView.maxDisplayDate)
    }

    // Mark: - methods
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
    }
    
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        
        print("starting GraphContainer init...")

        backgroundColor = ColorScheme.sharedInstance().duskBlue
        addSubview(upperLabel)
        addSubview(upperLimitLabel)
        addSubview(lowerLimitLabel)
        addSubview(centreBottomLabel)

        rotationObserver = NotificationCenter.default
        
        rotationObserver.addObserver(self, selector: #selector(deviceRotation(notification:)), name: Notification.Name.UIDeviceOrientationDidChange, object: nil)
        
        labelTap = UITapGestureRecognizer(target: self, action: #selector(graphLabelTap))
        labelTap.delegate = self
        upperLabel.addGestureRecognizer(labelTap)
        
        print("... eding GraphContainer init")
    }

    deinit {
        NotificationCenter.default.removeObserver(rotationObserver)
    }
    
    func updateLabels() {
        
        let numberFormatter: NumberFormatter = {
            let formatter = NumberFormatter()
            formatter.maximumFractionDigits = 0
            return formatter
        }()

        upperLabel.text = graphView.helper.selectedScore
        upperLabel.sizeToFit()
        upperLabel.frame.origin = CGPoint(
            x: clipView.frame.origin.x,
            y: 5
        )
        
        upperLimitLabel.text = numberFormatter.string(from: graphView.helper.maxScore() as NSNumber)
        upperLimitLabel.sizeToFit()
        upperLimitLabel.frame.origin = CGPoint(
            x: self.frame.maxX - upperLimitLabel.frame.width - 5,
            y: clipView.frame.minY - upperLimitLabel.frame.height / 2
        )
    
        lowerLimitLabel.frame.origin = CGPoint(
            x: self.frame.maxX - lowerLimitLabel.frame.width - 5,
            y: clipView.frame.maxY - graphView.helper.timeLineSpace() - upperLimitLabel.frame.height / 2
        )
        
        updateBottomLabel()
    }
    
    override func draw(_ rect: CGRect) {
        // Drawing code
        updateLabels()
    }
    
    
    func updateBottomLabel() {
        centreBottomLabel.text = centerBottomText
        centreBottomLabel.sizeToFit()
        centreBottomLabel.frame.origin = CGPoint(
            x: clipView.frame.maxX - centreBottomLabel.bounds.width,
            y: upperLabel.frame.midY - centreBottomLabel.frame.height / 2
        )
    }
    
    
    func deviceRotation(notification: Notification) {
        
        reloadAllViews()
    }
    
    func graphLabelTap() {
//        print("label tapped")
//        print("label frame = \(upperLabel.frame)")
//        print("gContView frame = \(self.frame)")
//        let rect = upperLabel.frame.offsetBy(dx: 0, dy: 2)
        mainViewController.scoreChangeAction(fromRect: upperLabel.frame, fromView: upperLabel)
    }
    
    func reloadAllViews() {
        
        updateLabels()
        clipView.setNeedsDisplay()
        graphView.setNeedsDisplay()
        self.setNeedsDisplay()
        
    }

}


extension GraphContainerView {
    func renderAsImage() -> UIImage {
        
        var image: UIImage!
        
        UIGraphicsBeginImageContext(bounds.size)
        layer.render(in: UIGraphicsGetCurrentContext()!)
        image = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        
        return image!
    }
    
}

