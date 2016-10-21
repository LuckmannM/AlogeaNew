//
//  MVButtonView.swift
//  Alogea
//
//  Created by mikeMBP on 16/10/2016.
//  Copyright © 2016 AppToolFactory. All rights reserved.
//

import UIKit

enum ButtonViewPickers {
    case diaryEntryTypePicker
    case eventTimePicker
}

class MVButtonView: UIView, UIPickerViewDataSource, UIPickerViewDelegate {


    var scoreLabel: UILabel!
    var roundButton: MVButton!
    var colorScheme: ColorScheme!
    weak var touchWheel: TouchWheelView!
    weak var controller: MVButtonController!
    var diaryEntryTypePicker: UIPickerView!
    var eventTimePicker: UIPickerView!
    
    var diaryEntryTypeTitles = ["Cancel","Diary entry","Medication"]
    var eventTimePickerOptions = ["Cancel", "Now", "30 minutes ago","1 hour ago", "2 hours ago", "4 hours ago"]
    
    // MARK: - Core class functions

    convenience init(frame: CGRect, controller: MVButtonController) {
        self.init(frame: frame)
        self.controller = controller
        self.touchWheel = controller.touchWheel
        self.backgroundColor = UIColor.clear
        colorScheme = ColorScheme.sharedInstance()
        scoreLabel = {
            let label = UILabel()
            label.text = "0.0"
            label.font = UIFont.boldSystemFont(ofSize: 64)
            label.textColor = colorScheme.darkBlue
            label.isHidden = true
            return label
        }()
        addSubview(scoreLabel)
        
        roundButton = MVButton(frame: CGRect.zero, controller: controller)
        addSubview(roundButton)
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
    }
    
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        
    }

    override func draw(_ rect: CGRect) {

        let buttonCircle = UIBezierPath(ovalIn: bounds.insetBy(dx: 1, dy: 1))
        colorScheme.seaGreen.setFill()
        buttonCircle.fill()
        
        colorScheme.darkBlue.setStroke()
        buttonCircle.lineWidth = 1
        buttonCircle.stroke()
    }
    
    func displayScore(score: Double) {
        let scoreNumber = NSNumber(value: score)
        let numberFormatter: NumberFormatter = {
            let formatter = NumberFormatter()
            formatter.minimumFractionDigits = 1
            formatter.maximumFractionDigits = 1
            formatter.minimumIntegerDigits = 1
            return formatter
        }()
        
        scoreLabel.text = numberFormatter.string(from: scoreNumber)
        centerScoreLabel()
        roundButton.isHidden = true
        scoreLabel.isHidden = false
    }
    
    func hideScore() {
        scoreLabel.text = "0.0"
        scoreLabel.isHidden = true
    }
    
    func centerScoreLabel() {
        scoreLabel.sizeToFit()
        scoreLabel.frame = CGRect(
            x: frame.width / 2 - scoreLabel.frame.width / 2,
            y: frame.height / 2 - scoreLabel.frame.height / 2,
            width: scoreLabel.frame.width,
            height: scoreLabel.frame.height
        )
    }

    // MARK: - PickerView functions
    
    func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        
        if pickerView.isEqual(diaryEntryTypePicker) {
            return diaryEntryTypeTitles.count
        } else {
            return eventTimePickerOptions.count
        }
    }
    
    func numberOfComponents(in pickerView: UIPickerView) -> Int {
        return 1
    }
    
    func pickerView(_ pickerView: UIPickerView, rowHeightForComponent component: Int) -> CGFloat {
        return frame.height / 5
    }
    
    func pickerView(_ pickerView: UIPickerView, viewForRow row: Int, forComponent component: Int, reusing view: UIView?) -> UIView {
        
        var options = [String]()
        
        var title: UILabel!
        if view == nil {
            title = UILabel()
        } else {
            title = view as! UILabel
        }
        title.textAlignment = .center
        
        if pickerView.isEqual(diaryEntryTypePicker) {
            options = diaryEntryTypeTitles
        } else  if pickerView.isEqual(eventTimePicker) {
            options = eventTimePickerOptions
        }
        
        let fontAttribute = UIFont(name: "AvenirNext-Medium", size: 32)! // fronName must be valid or crash
        title.attributedText = NSAttributedString(
            string: options[row],
            attributes: [
                NSFontAttributeName: fontAttribute,
                NSForegroundColorAttributeName: UIColor.white,
            ]
        )
        return title
    }
    
    func pickerView(_ pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
        
        if row == 0 {
            //cancel
            resolvePicker(picker: pickerView)
            return
        }
        
        if pickerView.isEqual(diaryEntryTypePicker) {
            if row == 1 {
                resolvePicker(picker: pickerView)
                controller.requestDiaryEntryWindow(frame: touchWheel.frame)
            } else {
                // medication event
            }
        } else if pickerView.isEqual(eventTimePicker) {
            resolvePicker(picker: pickerView)
            
            var timeInterval: TimeInterval = 0
            switch row {
            case 1:
                print("now")
                timeInterval = 0
            case 2:
                print("30 min ago")
                timeInterval = 30*60
            case 3:
                print("60 min ago")
                timeInterval = 60*60
            case 3:
                print("120 min ago")
                timeInterval = 120*60
            case 3:
                print("240 min ago")
                timeInterval = 240*60
           default:
                print("now")
            }
            
            controller.finaliseScoreEvent(amendTime: timeInterval)
        }
    }
    
    func showPicker(pickerType: ButtonViewPickers) {
        
        roundButton.isUserInteractionEnabled = false
        roundButton.isHidden = true
        
        switch pickerType {
        case .diaryEntryTypePicker:
            
            diaryEntryTypePicker = {
                let pV = UIPickerView()
                pV.frame = bounds.insetBy(dx: 15, dy: 15)
                pV.delegate  = self
                pV.dataSource = self
                return pV
            }()
            addSubview(diaryEntryTypePicker)
//            diaryEntryTypePicker.frame = bounds.insetBy(dx: 15, dy: 15)
//            diaryEntryTypePicker.isHidden = false
//            diaryEntryTypePicker.isUserInteractionEnabled = true
            
        case .eventTimePicker:
            
            roundButton.enlargeButtonView(withTap: false)
            
            eventTimePicker = {
                let pV = UIPickerView()
                pV.frame = bounds.insetBy(dx: 15, dy: 15)
                pV.delegate  = self
                pV.dataSource = self
                return pV
            }()
            addSubview(eventTimePicker)
          
            // start timer here to automatically chose 'now' after 1 second of inaction or so
        }
    }
    
    func resolvePicker(picker: UIPickerView) {
        picker.isHidden = true
        picker.isUserInteractionEnabled = false
        roundButton.isHidden = false
        roundButton.isUserInteractionEnabled = true
        UIView.animate(withDuration: 0.1, animations: {
            self.controller.sizeButtonViews(rect: self.touchWheel.frame, touchWheelWidth: self.touchWheel.lineWidth, margins: self.touchWheel.margin)
        })
        picker.removeFromSuperview()
    }
    
}
