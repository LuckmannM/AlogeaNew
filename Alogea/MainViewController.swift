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
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
//    func showDiaryEntryWindow() {
//        
//        let diaryEntryWindow = UIView(frame: touchWheel.bounds)
//        
//        diaryEntryWindow.backgroundColor = UIColor(colorLiteralRed: 248/255, green: 248/255, blue: 245/255, alpha: 0.8)
//        diaryEntryWindow.frame = CGRect(origin: CGPoint(x: 0, y: touchWheel.frame.maxY), size: touchWheel.frame.size)
//        
//        let textView: UITextView = {
//            let tV = UITextView()
//            tV.frame = diaryEntryWindow.bounds.insetBy(dx: 5, dy: 30)
//            tV.backgroundColor = UIColor.clear
//            tV.text = "Enter your diary text here"
//            tV.font = UIFont(name: "AvenirNext-UltraLight", size: 22)
//            tV.textColor = UIColor.black
//            return tV
//        }()
//        diaryEntryWindow.addSubview(textView)
//        mainViewController.view.addSubview(diaryEntryWindow)
//        
//        UIView.animate(withDuration: 0.5, animations: {
//            diaryEntryWindow.frame = self.touchWheel.frame.offsetBy(dx: 0, dy: -200)
//        })
//        
//        textView.becomeFirstResponder()
//        textView.frame.offsetBy(dx: 0, dy: -200)
//    }

}
