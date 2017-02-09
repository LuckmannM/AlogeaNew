//
//  MVButtonView.swift
//  Alogea
//
//  Created by mikeMBP on 16/10/2016.
//  Copyright © 2016 AppToolFactory. All rights reserved.
//

import UIKit

enum ButtonViewPickers {
    case eventSelectionPickerType
    case eventTimePickerType
    // case medEventPickerType
    // case medsPickerType
}

class MVButtonView: UIView, UIPickerViewDataSource, UIPickerViewDelegate {


    var scoreLabel: UILabel = {
        let label = UILabel()
        label.text = "0.0"
        label.numberOfLines = 0
        label.font = UIFont(name: "AvenirNext-Medium", size: 24 * (UIApplication.shared.delegate as! AppDelegate).deviceBasedSizeFactor.width)!
        label.textColor = ColorScheme.sharedInstance().pearlWhite
        label.textAlignment = .center
        label.isHidden = true
        return label
    }()

    var roundButton: MVButton!
    var colorScheme: ColorScheme!
    weak var touchWheel: TouchWheelView!
    weak var controller: MVButtonController!
    var eventSelectionPicker: UIPickerView!
    var eventTimePicker: UIPickerView!
    var medicineEventPicker: UIPickerView!
    var eventTimeTimer: Timer!
    
    var diaryEventTypeTitles = ["Cancel","Diary entry"] // individual prn meds added in pickerView delegate functions
    var eventTimePickerOptions = ["Cancel", "Now", "30 minutes ago","1 hour ago", "2 hours ago", "4 hours ago"]
    var eventTimeIntervals: [TimeInterval] = [0,0,30*60,60*60,120*60,240*60]
    
    var buttonColor: UIColor! // also used in TouchWheel to exclude touch inside roundButton
    
    // MARK: - Core class functions

    convenience init(frame: CGRect, controller: MVButtonController) {
        self.init(frame: frame)
        self.controller = controller
        self.touchWheel = controller.touchWheel
        self.backgroundColor = UIColor.clear
        colorScheme = ColorScheme.sharedInstance()
        addSubview(scoreLabel)
        
        roundButton = MVButton(frame: CGRect.zero, controller: controller)
        addSubview(roundButton)
        
        buttonColor = colorScheme.duskBlue
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)

    }
    
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        
    }

    override func draw(_ rect: CGRect) {

        let buttonCircle = UIBezierPath(ovalIn: bounds.insetBy(dx: 1, dy: 1))
        buttonColor.setFill()
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
        let scoreName = GraphViewHelper.sharedInstance().selectedScore
        let score = numberFormatter.string(from: scoreNumber)
        scoreLabel.text = scoreName + "\n" + score!
        
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
        
        if pickerView.isEqual(eventSelectionPicker) {
            return diaryEventTypeTitles.count + MedicationController.sharedInstance().asRequiredMedNames.count
        } else if pickerView.isEqual(eventTimePicker){
            return eventTimePickerOptions.count
        } else {
            // medicine event
            return (MedicationController.sharedInstance().asRequiredMedsFRC.fetchedObjects?.count ?? 0)
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
        
        if pickerView.isEqual(eventSelectionPicker) {
            options = diaryEventTypeTitles
            for (name, _) in MedicationController.sharedInstance().asRequiredMedNames {
                options.append(name)
            }
        } else  if pickerView.isEqual(eventTimePicker) {
            options = eventTimePickerOptions
        } else {
            for (name, _) in MedicationController.sharedInstance().asRequiredMedNames {
                options.append(name)
            }
        }
        
        let fontAttribute = UIFont(name: "AvenirNext-Medium", size: 24 * (UIApplication.shared.delegate as! AppDelegate).deviceBasedSizeFactor.width)!
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
        
        if pickerView.isEqual(eventSelectionPicker){
            if row == 1 {
                resolvePicker(picker: pickerView)
                controller.requestDiaryEntryWindow(frame: touchWheel.frame.insetBy(dx: -20, dy: -20))
            } else {
                resolvePicker(picker: pickerView)
                let (name, duration) = MedicationController.sharedInstance().asRequiredMedNames[row - 2]
                EventsDataController.sharedInstance().newEvent(ofType: medicineEvent, withName: name, withDate: Date(), vas: -1, note: nil, duration: duration, buttonView: self)
            }
        } else if pickerView.isEqual(eventTimePicker) {
            
            if eventTimeTimer.isValid {
                eventTimeTimer.invalidate()
            }
            eventTimeSelected()
        }
    }
    
    func showPicker(pickerType: ButtonViewPickers) {
        
        roundButton.isUserInteractionEnabled = false
        roundButton.isHidden = true
        
        switch pickerType {
        case .eventSelectionPickerType:
            
            eventSelectionPicker = {
                let pV = UIPickerView()
                pV.frame = bounds.insetBy(dx: 15, dy: 15)
                pV.delegate  = self
                pV.dataSource = self
                return pV
            }()
            addSubview(eventSelectionPicker)
            
        case .eventTimePickerType:
            
            roundButton.enlargeButtonView(withTap: false)
            
            eventTimePicker = {
                let pV = UIPickerView()
                pV.frame = bounds.insetBy(dx: 15, dy: 15)
                pV.delegate  = self
                pV.dataSource = self
                return pV
            }()
            addSubview(eventTimePicker)
            eventTimePicker.selectRow(1, inComponent: 0, animated: false)
          
            eventTimeTimer = Timer.scheduledTimer(timeInterval: 2, target: self, selector: #selector(eventTimeSelected), userInfo: nil, repeats: false)
        }
    
    }
    
    func resolvePicker(picker: UIPickerView) {
        picker.isHidden = true
        picker.isUserInteractionEnabled = false
        roundButton.isHidden = false
        roundButton.isUserInteractionEnabled = true
        UIView.animate(withDuration: 0.1, animations: {
            self.controller.sizeViews(rect: self.touchWheel.innerRect)
        })
        picker.removeFromSuperview()
    }
    
    func eventTimeSelected() {
        let time = eventTimeIntervals[eventTimePicker.selectedRow(inComponent: 0)]
        resolvePicker(picker: self.eventTimePicker)
        if eventTimePicker.selectedRow(inComponent: 0) != 0 {
            eventsDataController.save(withTimeAmendment: -time)
        } else {
            eventsDataController.deleteCurrentEvent()
        }
        
    }
    
}
