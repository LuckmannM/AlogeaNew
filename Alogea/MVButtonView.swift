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
        if UIDevice().userInterfaceIdiom == .pad {
            label.font = UIFont.boldSystemFont(ofSize: 58)
        } else {
            label.font = UIFont.boldSystemFont(ofSize: 40)
        }
        label.textColor = ColorScheme.sharedInstance().darkBlue
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
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)

    }
    
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        
        print("starting MV Button View init...")

        print("...ending MV Button View init")
        
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
            y: frame.height * 0.28, //frame.height / 2 - scoreLabel.frame.height / 2
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
            options.append(contentsOf: MedicationController.sharedInstance().asRequiredMedNames)
        } else  if pickerView.isEqual(eventTimePicker) {
            options = eventTimePickerOptions
        } else {
            options = MedicationController.sharedInstance().asRequiredMedNames
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
        
        if pickerView.isEqual(eventSelectionPicker){
            if row == 1 {
                resolvePicker(picker: pickerView)
                controller.requestDiaryEntryWindow(frame: touchWheel.frame.insetBy(dx: -20, dy: -20))
            } else {
                resolvePicker(picker: pickerView)
                EventsDataController.sharedInstance().newEvent(ofType: medicineEvent, withName: MedicationController.sharedInstance().asRequiredMedNames[row - 2], withDate: Date(), vas: -1, note: nil, duration: nil) // consider setting duration to the duration of med effect; this requires MedicationController function extracting the correct drug and returning the duration
                
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
        /*
        case .medEventPickerType:
            if (MedicationController.sharedInstance().asRequiredMedsFRC.fetchedObjects?.count ?? 0) > 0 {
                medicineEventPicker = {
                    let pV = UIPickerView()
                    pV.frame = bounds.insetBy(dx: 15, dy: 15)
                    pV.delegate  = self
                    pV.dataSource = self
                    return pV
                }()
                addSubview(medicineEventPicker)
            }
         */
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
            controller.finaliseScoreEvent(amendTime: time )
        }
        
    }
    
}
