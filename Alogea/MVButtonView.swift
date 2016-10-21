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
    var roundButton: UIButton!
    var colorScheme: ColorScheme!
    weak var touchWheel: TouchWheelView!
    weak var controller: MVButtonController!
    var diaryEntryTypePicker: UIPickerView!
    var eventTimePicker: UIPickerView!
    
    var diaryEntryTypeTitles = ["Cancel","Diary entry","Medication"]
    
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
        
        diaryEntryTypePicker = {
            let pV = UIPickerView()
            pV.frame = CGRect.zero
            pV.delegate  = self
            pV.dataSource = self
            pV.isUserInteractionEnabled = false
            pV.isHidden = true
            return pV
        }()
        addSubview(diaryEntryTypePicker)
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
        roundButton.isHidden = false
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
            return 0
        }
    }
    
    func numberOfComponents(in pickerView: UIPickerView) -> Int {
        return 1
    }
    
    func pickerView(_ pickerView: UIPickerView, rowHeightForComponent component: Int) -> CGFloat {
        return frame.height / 5
    }
    
    func pickerView(_ pickerView: UIPickerView, viewForRow row: Int, forComponent component: Int, reusing view: UIView?) -> UIView {
        
        var title: UILabel!
        if view == nil {
            title = UILabel()
        } else {
            title = view as! UILabel
        }
        title.textAlignment = .center

        if pickerView.isEqual(diaryEntryTypePicker) {
            
            let fontAttribute = UIFont(name: "AvenirNext-UltraLight", size: 38)! // fronName must be valid or crash
            title.attributedText = NSAttributedString(
                string: diaryEntryTypeTitles[row],
                attributes: [
                    NSFontAttributeName: fontAttribute,
                    NSForegroundColorAttributeName: UIColor.white,
                ]
            )
            return title
        } else {
            
            title.text = "not set"
            return title
        }
    }
    
    func pickerView(_ pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
        
        if row == 0 {
            //cancel
            resolvePicker(picker: pickerView)
        } else if row == 1 {
            resolvePicker(picker: pickerView)
//            showDiaryEntryWindow(frame: touchWheel.bounds)
            controller.requestDiaryEntryWindow(frame: touchWheel.frame)
        } else {
            // medication event
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
                pV.isUserInteractionEnabled = false
                pV.isHidden = true
                return pV
            }()
            addSubview(diaryEntryTypePicker)
//            diaryEntryTypePicker.frame = bounds.insetBy(dx: 15, dy: 15)
            diaryEntryTypePicker.isHidden = false
            diaryEntryTypePicker.isUserInteractionEnabled = true
            
        case .eventTimePicker:
            
            eventTimePicker = {
                let pV = UIPickerView()
                pV.frame = bounds.insetBy(dx: 15, dy: 15)
                pV.delegate  = self
                pV.dataSource = self
                pV.isUserInteractionEnabled = false
                pV.isHidden = true
                return pV
            }()
            addSubview(eventTimePicker)
            
//            diaryEntryTypePicker.frame = bounds.insetBy(dx: 15, dy: 15)
            eventTimePicker.isHidden = false
            eventTimePicker.isUserInteractionEnabled = true
        default:
            print("no pickerView")
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
