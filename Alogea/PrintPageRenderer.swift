//
//  PrintPageRenderer.swift
//  Alogea
//
//  Created by mikeMBP on 09/11/2016.
//  Copyright © 2016 AppToolFactory. All rights reserved.
//

import UIKit
import CoreText
import Foundation

class PrintPageRenderer: UIPrintPageRenderer {
    
    
    static func generatePDFFile() -> String {
        
        let path = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true) as NSArray
        let documentDirectory = path.object(at: 0)
        return (documentDirectory as AnyObject).appendingPathComponent("MedicinesList.pdf" as String)
        
    }
    
    class func createPDF(fromText: NSMutableAttributedString) -> NSURL {
        
        let framesetter = CTFramesetterCreateWithAttributedString(fromText)
        let pdfFile = generatePDFFile()
        
        // page size will be 612 x 792 or 8.5' x 11'
        UIGraphicsBeginPDFContextToFile(pdfFile, CGRect.zero, nil)
        var currentRange = CFRangeMake(0, 0)
        var currentPage = 0
        var done = false
        let pdfPageSizePortrait = CGRect(x: 0, y: 0, width: 612, height: 792)
        
        repeat {
            UIGraphicsBeginPDFPageWithInfo(pdfPageSizePortrait, nil)
            currentPage += 1
            currentRange = renderPage(pageNumber: currentPage, textRange: currentRange, frameSetter: framesetter)
            
            if currentRange.location == CFAttributedStringGetLength(fromText) {
                done = true
            }
            
        } while (!done)
        
        UIGraphicsEndPDFContext()
        
        
        return NSURL(fileURLWithPath: pdfFile)
        
    }
    
    class func pdfFromView(fromView: UIView, name: String) -> NSURL {
        
        let path = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true) as NSArray
        let documentDirectory = path.object(at: 0)
        let fileName: String = name + ".pdf"
        let pdfFile = (documentDirectory as! String).appending("/" + fileName)
        
        let printInfo = UIPrintInfo(dictionary: nil)
        printInfo.outputType = UIPrintInfoOutputType.general
        
        // scale to fit page
        var scale:CGFloat = 1.0
        var scaleWidth: CGFloat = 1.0, scaleHeight: CGFloat = 1.0
        
        let paperSize = findPaperSize()
        let printablePaperSize = CGSize(width: paperSize.width - 144, height: paperSize.height - 144)
        
        if fromView.frame.width > printablePaperSize.width || fromView.frame.height > printablePaperSize.width {
            scaleWidth = printablePaperSize.width / fromView.frame.width
            scaleHeight = printablePaperSize.width / fromView.frame.height
        }
        scale = scaleHeight > scaleWidth ? scaleWidth : scaleHeight
        let leftInset = (paperSize.width - fromView.frame.width * scale) / 2

        let pdfPaperRect = CGRect(x: 0, y: 0, width: paperSize.width, height: paperSize.height)
        
        if UIGraphicsBeginPDFContextToFile(pdfFile, pdfPaperRect, nil) {
            UIGraphicsBeginPDFPage()
            if let pdfContext = UIGraphicsGetCurrentContext() {

                pdfContext.scaleBy(x: scale, y: scale)
                pdfContext.translateBy(x: leftInset, y: 72)

                fromView.layer.render(in: pdfContext)
            }
            UIGraphicsEndPDFContext()
        }
        
        return NSURL(fileURLWithPath: pdfFile)
        
    }
    
    // only this function is used in Alogea
    class func renderAsImage(view: UIView) -> Data? {
        
        UIGraphicsBeginImageContext(view.frame.size)
        guard let imageContext = UIGraphicsGetCurrentContext()  else {
            ErrorManager.sharedInstance().errorMessage(message: "PrintPageRenderer Error 1", errorInfo:"error in converting graphView to PNG image")
            return nil
        }
        view.layer.render(in: imageContext)
        let image = UIGraphicsGetImageFromCurrentImageContext()
        
        UIGraphicsEndImageContext()
       
        return UIImagePNGRepresentation(image!)
    }

    
    static func findPaperSize() -> CGSize {
        
        // US Letter dimensions are 11 x 8.5" @ 72ppi = 792x612 points, with margins 72 each side = 648x468 printable area
        // A4 dimensions are 11.69 x 8.25" @ 72 ppi = 841.68 x 594 points, with margins = 697.68 x 450 printable area
        // USL used in US and Canada
        
        let standardPDFSize = CGSize(width: 612, height: 792)
        
        return standardPDFSize
    }
    
    
    class func printDialog(file: NSURL, inView: UIView?) {
        
        if UIPrintInteractionController.canPrint(file as URL) {
            let printInfo = UIPrintInfo(dictionary: nil)
            printInfo.jobName = file.lastPathComponent!
            printInfo.orientation = UIPrintInfoOrientation.portrait
            printInfo.outputType = UIPrintInfoOutputType.general
            
            let printController = UIPrintInteractionController.shared
            printController.printInfo = printInfo
            printController.showsNumberOfCopies = false
            printController.printingItem = file
            
            if UIDevice().userInterfaceIdiom == .pad {
                
                printController.present(from: inView!.frame, in: inView!, animated: true, completionHandler: nil)
                
            } else {
                
                printController.present(animated: true, completionHandler: nil)
            }
        }
        else {
            ErrorManager.sharedInstance().errorMessage(message: "PrintPageRenderer Error 2", errorInfo:"can't print file")
        }
    }
    
    
    static func renderPage(pageNumber: Int, textRange: CFRange, frameSetter: CTFramesetter) -> CFRange {
        
        var currentRange = textRange
        let currentContext = UIGraphicsGetCurrentContext()
        let frameRect = CGRect(x: 72, y: 72, width: 468, height: 648)
        let framePath = CGMutablePath()
        framePath.addRect(frameRect)
        let frameRef = CTFramesetterCreateFrame(frameSetter, textRange, framePath, nil)
        currentContext!.translateBy(x: 0, y: 792)
        currentContext!.scaleBy(x: 1.0, y: -1.0)
        CTFrameDraw(frameRef, currentContext!)
        currentRange = CTFrameGetVisibleStringRange(frameRef)
        currentRange.location += currentRange.length
        currentRange.length = 0
        
        return currentRange
    }
    
    
    
}

extension PrintPageRenderer: UIPrintInteractionControllerDelegate {
    
}
