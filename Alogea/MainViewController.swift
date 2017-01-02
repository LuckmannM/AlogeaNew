//
//  ViewController.swift
//  Alogea
//
//  Created by Michael Luckmann on 02/10/2016.
//  Copyright © 2016 AppToolFactory. All rights reserved.
//

import UIKit
import MessageUI

class MainViewController: UIViewController {

    @IBOutlet weak var touchWheel: TouchWheelView!
    @IBOutlet weak var graphContainerView: GraphContainerView!
    @IBOutlet weak var floatingMenuView: FloatingMenuView!
    @IBOutlet weak var displayTimeSegmentedController: UISegmentedControl!
    
    var colorScheme = ColorScheme.sharedInstance()
    
    // MARK: - TextEntryWindow properties
    var textEntryWindow = UIView()
    var textEntryController:MVButtonController!
    var textView: UITextView!
    var liftTextViewForKeyBoard: CGFloat?
    var observer: NotificationCenter!
    var originalEntryWindowRect: CGRect!
    var textViewFrameInPortrait: CGRect!
    
    var eventsDataController = EventsDataController.sharedInstance()
    var eventPicker: UIPickerView!
    var eventPickerTitles: [String] {
        var array = ["Cancel", "Event"]
        
        if eventsDataController.nonScoreEventTypes.count > 0 {
            array = ["Cancel"]
            for type in eventsDataController.nonScoreEventTypes {
                array.append(type)
            }
        }
        return array
    }
    let placeHolderText = "Dictate or type your diary entry here"
    var eventPickerSelection: Int!
    
    var iPadLandScapeStart = false
    var iPadRotationFromLSStart = false
    

    // MARK: - core functions
    
    override func viewDidLoad() {
        super.viewDidLoad()
        /*
        Problem: iPad in LandScape mode has the same IB dimension wRhR as in portrait mode
        it is therefore not possible - like with iPhone - to add a 0 height IB constraint for touchWheel for landScape orientation this (zeroHeightConstraint) needs to be manually toggled with touchWheel aspectRationConstraint depending on orientation if launched in ls orientation (not in portrait), the buttonView is not resized properly when orientation is changed to portrait this requires a manual call to mainButtonController.sizeViews AFTER the rotation is complete doing this in the viewWillTransition function doesn't work as the rotated frame sizes of touchWheel are only available after rotation is complete at which time viewDidLayoutSubviews is called; in this function the manual call to sizeViews is done with the then updated touchWheel innerRect parameters but should only be called once; if calling initially after launch the inits aren't all complete resulting in crash due to nil value
         */
        if UIDevice().userInterfaceIdiom == .pad && view.frame.size.width > view.frame.size.height {
            iPadLandScapeStart = true
        }
        toggleTabBar(size: view.frame.size)
        displayTimeSegmentedController.selectedSegmentIndex = UISegmentedControlNoSegment
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
        
    }
    
    override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        
        // at the end of this function the view.frames are still the pre-rotation ones
        // the new frames are only available in viewDidLayoutSubviews
        
        toggleTabBar(size: size)
        
        if UIDevice().userInterfaceIdiom == .pad {
            if size.width > size.height {
                touchWheel.switchConstraints(forLandScape: true)
            } else {
                touchWheel.switchConstraints(forLandScape: false)
                if iPadLandScapeStart {
                    iPadLandScapeStart = false
                    iPadRotationFromLSStart = true
                }
            }
       }
    }
    
    override func viewDidLayoutSubviews() {
        
        // this function is called on completion of individual subView layout display
        // as well as after viewWillTransition, with the then rotated view.frame parameters
        if iPadRotationFromLSStart {
            iPadRotationFromLSStart = false
            touchWheel.mainButtonController.sizeViews(rect: touchWheel.innerRect)
        }
    }
    
    func toggleTabBar(size: CGSize) {
        
        if let tabBar = self.tabBarController?.tabBar {
            if size.width > size.height {
                tabBar.isHidden = true
                // *** is this required? self.hidesBottomBarWhenPushed = true
            } else {
                tabBar.isHidden = false
            }
        }
        
    }
    
    @IBAction func displayTimeSelection(_ sender: UISegmentedControl) {
        
        switch sender.selectedSegmentIndex {
            
        case 0:
            graphContainerView.graphView.helper.changeDisplayedInterval(toInterval: 24 * 3600)
        case 1:
            graphContainerView.graphView.helper.changeDisplayedInterval(toInterval: 7 * 24 * 3600)
        case 2:
            graphContainerView.graphView.helper.changeDisplayedInterval(toInterval: 30 * 24 * 3600)
        default:
            graphContainerView.graphView.helper.changeDisplayedInterval(toInterval: 365 * 24 * 3600)
        }
        
    }

}

extension MainViewController: UITextViewDelegate {
    
    func showDiaryEntryWindow(frame: CGRect) {
        
        textEntryWindow.frame = frame
        originalEntryWindowRect = textEntryWindow.frame
        textEntryWindow.backgroundColor = UIColor(colorLiteralRed: 248/255, green: 248/255, blue: 245/255, alpha: 0.9)
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
        eventPicker.selectRow(1, inComponent: 0, animated: false)
        eventPickerSelection = 1
        
        let arrowView = UIImageView(image: UIImage(named: "UpDownArrows"))
        arrowView.frame = CGRect(x: 15, y: 15, width: 17, height: 40)
        arrowView.alpha = 0.8
        let arrowView2 = UIImageView(image: UIImage(named: "UpDownArrows"))
        arrowView2.frame = arrowView.frame.offsetBy(dx: eventPicker.frame.width - 10 - arrowView2.frame.width, dy: 0)
        arrowView2.alpha = 0.8
        
        textEntryWindow.addSubview(arrowView)
        textEntryWindow.addSubview(arrowView2)

        
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
    
    // MARK: - exporting / printing
    
    @IBAction func exportDialog(sender: UIButton) {
        
        //floatingMenuView.isHidden = true // hide floatingView so it's not visible in the 'screenShot' pdf image
        floatingMenuView.slideIn()
        let pdfFile = PrintPageRenderer.pdfFromView(fromView: graphContainerView, name: "ScoreGraph")
        //floatingMenuView.isHidden = false
        
        let expoController = UIActivityViewController(activityItems: [pdfFile], applicationActivities: nil)
        
        if UIDevice().userInterfaceIdiom == .pad {
            let popUpController = expoController.popoverPresentationController
            popUpController?.permittedArrowDirections = .unknown
            popUpController?.sourceView = self.floatingMenuView
            popUpController?.sourceRect = self.view.frame
        }
        
        self.present(expoController, animated: true, completion: nil)
        
    }

    /*
    func export(sender: UIButton) {
        
        floatingMenuView.isHidden = true // hide flaotingView so it's not visible in the 'screenShot' pdf image
        let pdfFile = PrintPageRenderer.pdfFromView(fromView: graphContainerView, name: "ScoreGraph")
        floatingMenuView.isHidden = false
        
        let exportDialog = UIAlertController(title: "Export options", message: nil, preferredStyle: .actionSheet)
        
        let printAction = UIAlertAction(title: "Print", style: UIAlertActionStyle.default, handler: { (exportDialog)
            -> Void in
            
            PrintPageRenderer.printDialog(file: pdfFile, inView: self.view)
            
        })
        
        exportDialog.addAction(printAction)
        
        if MFMailComposeViewController.canSendMail() {
            
            let emailAction = UIAlertAction(title: "Email", style: .default, handler: { (exportDialog)
                -> Void in
                
                self.exportToEmailAction(file: pdfFile)
                
            })
            
            exportDialog.addAction(emailAction)
            
        }
        
        let cancelAction = UIAlertAction(title: "Cancel", style: .default, handler: { (exportDialog)
            -> Void in
            
            return
            
        })
        
        exportDialog.addAction(cancelAction)
        
        if UIDevice().userInterfaceIdiom == .pad {
            let popUpController = exportDialog.popoverPresentationController
            popUpController!.permittedArrowDirections = .up
            popUpController?.sourceView = sender
            popUpController?.sourceRect = sender.bounds
        }
        
        self.present(exportDialog, animated: true, completion: nil)
        
    }
     */
   
    func exportToEmailAction(file: NSURL) {
        
        if let attachmentData = NSData.init(contentsOf: file as URL) {
            let emailer = MFMailComposeViewController()
            emailer.mailComposeDelegate = self
            emailer.setSubject("ScoreGraph")
            emailer.addAttachmentData(attachmentData as Data, mimeType: "application/pdf", fileName: "ScoreGraph.pdf")
            
            self.present(emailer, animated: true, completion: nil)
        }
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
            string: eventPickerTitles[row],
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

extension MainViewController: MFMailComposeViewControllerDelegate {
    
    private func mailComposeController(controller: MFMailComposeViewController, didFinishWithResult result: MFMailComposeResult, error: NSError?) {
        
        //        switch result {
        //        case MFMailComposeResultCancelled:
        //            print("email cancelled")
        //        case MFMailComposeResultSent:
        //            print("email sent")
        //        case MFMailComposeResultSaved:
        //            print("email saved")
        //        default:
        //            print("email result default")
        //        }
        
        self.dismiss(animated: true, completion: nil)
        
    }
}

extension MainViewController: UIPrintInteractionControllerDelegate {
    
    //    func printInteractionControllerParentViewController(printInteractionController: UIPrintInteractionController) -> UIViewController {
    //        print("printINteractionController parentController = \()")
    //    }
    
    
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
