//
//  ViewController.swift
//  Alogea
//
//  Created by mikeMBP on 02/10/2016.
//  Copyright © 2016 AppToolFactory. All rights reserved.
//

import UIKit

class MainViewController: UIViewController {

    @IBOutlet weak var touchWheel: TouchWheelView!
    
    var colorScheme = ColorScheme.sharedInstance()
    
    // TextEntryWindow properties
    var textEntryWindow = UIView()
    var textEntryController:MVButtonController!
    var textView: UITextView!
    var liftTextViewForKeyBoard: CGFloat?
    var observer: NotificationCenter!
    var originalEntryWindowRect: CGRect!
    var textViewFrameInPortrait: CGRect!
    
    var eventPicker: UIPickerView!
    let eventPickerTitles = ["Cancel","Treatment","Fall","Holiday","New..."]
    let placeHolderText = "Dictate or type your diary entry here"
    var eventPickerSelection: Int!

    // MARK: - core functions
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
}

extension MainViewController: UITextViewDelegate {
    
    func showDiaryEntryWindow(frame: CGRect) {
        
        textEntryWindow.frame = frame
        originalEntryWindowRect = textEntryWindow.frame
        textEntryWindow.backgroundColor = UIColor(colorLiteralRed: 248/255, green: 248/255, blue: 245/255, alpha: 0.8)
        view.addSubview(textEntryWindow)
        
        observer = NotificationCenter.default
        
        observer.addObserver(self, selector: #selector(keyBoardAppeared(notification:)), name: Notification.Name.UIKeyboardWillShow, object: nil)
        
        eventPicker = {
            let pV = UIPickerView(frame: CGRect(x: 5, y: 5, width: textEntryWindow.frame.width - 10, height: 60))
            pV.backgroundColor = colorScheme.darkBlue
            pV.delegate = self
            return pV
        }()
        textEntryWindow.addSubview(eventPicker)
        eventPickerSelection = 0
        
        textView = {
            let tV = UITextView()
            tV.frame = CGRect(
                x: 5,
                y: eventPicker.frame.maxY,
                width: textEntryWindow.frame.width - 10,
                height: textEntryWindow.frame.height - eventPicker.frame.height - 10
            )
            tV.backgroundColor = UIColor.clear
            tV.text = placeHolderText
            tV.font = UIFont(name: "AvenirNext-UltraLight", size: 22)
            tV.textColor = UIColor.black
            tV.delegate = self
            // place cursor at the beginning and delete placeholder text when typing
            return tV
        }()
        textViewFrameInPortrait = textView.frame
        textView.selectedRange = NSMakeRange(0, 0)
        textEntryWindow.addSubview(textView)
        
        addDoneButtonToKeyboard(sender: textView)
        textView.becomeFirstResponder()
    }
    
    func keyBoardAppeared(notification: Notification) {
        // a notification for this function is also sent when the device rotates while the keyBoard is shown!!
        
        if let keyBoardInfo = notification.userInfo {
            let adjustedKeyBoardRect = view.convert((keyBoardInfo[UIKeyboardFrameEndUserInfoKey] as! NSValue).cgRectValue, from: self.view)
            let keyBoardTopBorder = adjustedKeyBoardRect.minY
            
            if view.frame.width >= view.frame.height {
                textEntryWindow.frame = CGRect(x: 5, y: 5, width: view.frame.width - 10, height: view.frame.height - adjustedKeyBoardRect.size.height)
                eventPicker.isHidden = true
                eventPicker.isUserInteractionEnabled = false
                textView.frame = textEntryWindow.bounds.insetBy(dx: 5, dy: 5)
                textView.font = UIFont(name: "AvenirNext-UltraLight", size: 28)
            }
            else {
                textEntryWindow.frame = originalEntryWindowRect
                eventPicker.isHidden = false
                eventPicker.isUserInteractionEnabled = true
                textView.frame = textViewFrameInPortrait
                textView.font = UIFont(name: "AvenirNext-UltraLight", size: 20)
                
                slideUpTextEntryView(keyBoardTop: keyBoardTopBorder)
            }
        }
    }
    
    func slideUpTextEntryView(keyBoardTop: CGFloat) {
        
        liftTextViewForKeyBoard = -(self.textEntryWindow.frame.maxY - keyBoardTop)
        self.textEntryWindow.frame = self.textEntryWindow.frame.offsetBy(dx: 0, dy: self.liftTextViewForKeyBoard!)
        
    }

    func textViewDidChange(_ textView: UITextView) {
        
        if textView.text.contains(placeHolderText)  {
            // replaces placeholder text
            let index = textView.text.index(after: textView.text.startIndex)
            let lastChar = textView.text.substring(to: index)
            textView.text = lastChar
        }
    }

    func endedTextEntry() {
        
        textView.resignFirstResponder()
        
        let text = textView.text ?? ""
        textEntryController = touchWheel.mainButtonController
        
        if eventPickerSelection != 0 {
            textEntryController.receiveDiaryText(text: text, eventType: eventPickerTitles[eventPickerSelection])
        }
        
        UIView.animate(withDuration: 0.4, animations: {
            self.textEntryWindow.frame = self.textEntryWindow.frame.offsetBy(dx: 0, dy: -self.liftTextViewForKeyBoard!)
            
            }, completion: { (value: Bool) in
                
                UIView.animate(withDuration: 0.3, animations: {
                    self.textEntryWindow.alpha = 0.0
                    
                    }, completion: { (value: Bool) in
                        self.eventPicker.removeFromSuperview()
                        self.textView.removeFromSuperview()
                        self.textEntryWindow.removeFromSuperview()
                })
        })
        
        NotificationCenter.default.removeObserver(observer)
    }


    
}

extension MainViewController: UIPickerViewDelegate, UIPickerViewDataSource {
    
    func pickerView(_ pickerView: UIPickerView, viewForRow row: Int, forComponent component: Int, reusing view: UIView?) -> UIView {
        
        var title: UILabel!
        
        if view == nil {
            title = UILabel()
        } else {
            title = view as! UILabel
        }
        title.textAlignment = .center
        title.backgroundColor = colorScheme.darkBlue
        
        title.attributedText = NSAttributedString(
            string: "New event: " + eventPickerTitles[row],
            attributes: [
                NSFontAttributeName: UIFont(name: "AvenirNext-Regular", size: 20)!,
                NSForegroundColorAttributeName: UIColor.white,
                ]
        )
        return title
    }
    
    
    func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        
        return eventPickerTitles.count
    }
    
    func numberOfComponents(in pickerView: UIPickerView) -> Int {
        return 1
    }
    
    func pickerView(_ pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
        
        eventPickerSelection = row
    }
    
}

extension MainViewController {
    
    func addDoneButtonToKeyboard (sender: UITextView) {
        
        let doneButton = UIBarButtonItem(barButtonSystemItem: .done, target: self, action: #selector(endedTextEntry))
        let space = UIBarButtonItem(barButtonSystemItem: .flexibleSpace, target: nil, action: nil)
        let toolbar = UIToolbar()
        toolbar.frame.size.height = 44
        doneButton.width = self.view.frame.width * 1/3
        var items = [UIBarButtonItem]()
        items.append(space)
        items.append(doneButton)
        
        toolbar.items = items
        
        sender.inputAccessoryView = toolbar
    }
}
