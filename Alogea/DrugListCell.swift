//
//  DrugListCell.swift
//  Alogea
//
//  Created by mikeMBP on 10/11/2016.
//  Copyright © 2016 AppToolFactory. All rights reserved.
//

import UIKit

class DrugListCell: UITableViewCell {
    
    @IBOutlet weak var nameLabel: UILabel!
    @IBOutlet weak var startDateLabel: UILabel!
    @IBOutlet weak var otherInfoLabel: UILabel!
    @IBOutlet weak var ratingButton: UIButton!
    
    var notRatedImage: UIImage!
    var goodRatingImages: [UIImage]!
    var moderateRatingImages:[UIImage]!
    var minimalRatingImages:[UIImage]!
    var noEffectRatingImages: [UIImage]!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
        loadRatingImages()
    }
    
    //
    //    override func setSelected(selected: Bool, animated: Bool) {
    //        super.setSelected(selected, animated: animated)
    //
    //        // Configure the view for the selected state
    //    }
    
    override func prepareForReuse() {
        nameLabel.text = ""
        startDateLabel.text = ""
        ratingButton.setImage(notRatedImage, for: .normal)
        ratingButton.setImage(notRatedImage, for: .disabled)
        ratingButton.titleLabel?.text = ""
        ratingButton.isEnabled = true
    }
    
    
    func loadRatingImages() {
        
        let redStar = UIImage(named: "RedStar")
        let greyStar = UIImage(named: "GreyStar")
        let yellowStar = UIImage(named: "YellowStar")
        let orangeStar = UIImage(named: "OrangeStar")
        let redCircle = UIImage(named: "RedCircle")
        let emptyStar = UIImage(named: "EmptyStar")
        
        var threeImageFrame: CGRect!
        //        var twoImageFrame: CGRect!
        var oneImageFrame: CGRect!
        var containerImage: UIImage!
        
        if redStar != nil {
            oneImageFrame = CGRect(origin: CGPoint(x: 0,y: 0), size: redStar!.size)
            threeImageFrame = CGRect(x: 0, y: 0, width: redStar!.size.width * 3, height: redStar!.size.height)
            //            twoImageFrame = CGRect(x: 0, y: 0, width: redStar!.size.width * 2, height: redStar!.size.height)
        }
        
        // not rated Image
        UIGraphicsBeginImageContext(threeImageFrame.size)
        for _ in 0 ..< 3 {
            greyStar!.draw(in: oneImageFrame)
            oneImageFrame.offsetBy(dx: oneImageFrame.width, dy: 0)
        }
        notRatedImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        
        // good rating - no side effects
        goodRatingImages = [UIImage]()
        oneImageFrame = CGRect(origin: CGPoint(x: 0,y: 0), size: redStar!.size)
        
        UIGraphicsBeginImageContext(threeImageFrame.size)
        for _ in 0 ..< 3 {
            yellowStar!.draw(in: oneImageFrame)
            oneImageFrame.offsetBy(dx: oneImageFrame.width, dy: 0)
        }
        containerImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        goodRatingImages.append(containerImage)
        
        // good rating - moderate effects
        oneImageFrame = CGRect(origin: CGPoint(x: 0,y: 0), size: redStar!.size)
        UIGraphicsBeginImageContext(threeImageFrame.size)
        for _ in 0 ..< 3 {
            orangeStar!.draw(in: oneImageFrame)
            oneImageFrame.offsetBy(dx: oneImageFrame.width, dy: 0)
        }
        containerImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        goodRatingImages.append(containerImage)
        
        // good rating - strong effects
        oneImageFrame = CGRect(origin: CGPoint(x: 0,y: 0), size: redStar!.size)
        UIGraphicsBeginImageContext(threeImageFrame.size)
        for _ in 0 ..< 3  {
            redStar!.draw(in: oneImageFrame)
            oneImageFrame.offsetBy(dx: oneImageFrame.width, dy: 0)
        }
        containerImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        goodRatingImages.append(containerImage)
        
        
        // moderate rating - no side effects
        moderateRatingImages = [UIImage]()
        oneImageFrame = CGRect(origin: CGPoint(x: 0,y: 0), size: redStar!.size)
        
        UIGraphicsBeginImageContext(threeImageFrame.size)
        emptyStar?.draw(in: oneImageFrame)
        for _ in 0 ..< 2 {
            oneImageFrame.offsetBy(dx: oneImageFrame.width, dy: 0)
            yellowStar!.draw(in: oneImageFrame)
        }
        containerImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        moderateRatingImages.append(containerImage)
        
        // moderate rating - moderate effects
        oneImageFrame = CGRect(origin: CGPoint(x: 0,y: 0), size: redStar!.size)
        UIGraphicsBeginImageContext(threeImageFrame.size)
        emptyStar?.draw(in: oneImageFrame)
        for _ in 0 ..< 2 {
            oneImageFrame.offsetBy(dx: oneImageFrame.width, dy: 0)
            orangeStar!.draw(in: oneImageFrame)
        }
        containerImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        moderateRatingImages.append(containerImage)
        
        // moderate rating - strong effects
        oneImageFrame = CGRect(origin: CGPoint(x: 0,y: 0), size: redStar!.size)
        UIGraphicsBeginImageContext(threeImageFrame.size)
        emptyStar?.draw(in: oneImageFrame)
        for _ in 0 ..< 2 {
            oneImageFrame.offsetBy(dx: oneImageFrame.width, dy: 0)
            redStar!.draw(in: oneImageFrame)
        }
        containerImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        moderateRatingImages.append(containerImage)
        
        // minimal rating - no side effects
        minimalRatingImages = [UIImage]()
        oneImageFrame = CGRect(origin: CGPoint(x: 0,y: 0), size: redStar!.size)
        UIGraphicsBeginImageContext(threeImageFrame.size)
        for _ in 0 ..< 2{
            emptyStar!.draw(in: oneImageFrame)
            oneImageFrame.offsetBy(dx: oneImageFrame.width, dy: 0)
        }
        yellowStar?.draw(in: oneImageFrame)
        containerImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        minimalRatingImages.append(containerImage)
        
        // minimal rating - moderate effects
        oneImageFrame = CGRect(origin: CGPoint(x: 0,y: 0), size: redStar!.size)
        UIGraphicsBeginImageContext(threeImageFrame.size)
        for _ in 0 ..< 2 {
            emptyStar!.draw(in: oneImageFrame)
            oneImageFrame.offsetBy(dx: oneImageFrame.width, dy: 0)
        }
        orangeStar?.draw(in: oneImageFrame)
        containerImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        minimalRatingImages.append(containerImage)
        
        // minimal rating - strong effects
        oneImageFrame = CGRect(origin: CGPoint(x: 0,y: 0), size: redStar!.size)
        UIGraphicsBeginImageContext(threeImageFrame.size)
        for _ in 0 ..< 2 {
            emptyStar!.draw(in: oneImageFrame)
            oneImageFrame.offsetBy(dx: oneImageFrame.width, dy: 0)
        }
        redStar?.draw(in: oneImageFrame)
        containerImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        minimalRatingImages.append(containerImage)
        
        // no effect rating
        noEffectRatingImages = [UIImage]()
        oneImageFrame = CGRect(origin: CGPoint(x: 0,y: 0), size: redStar!.size)
        UIGraphicsBeginImageContext(threeImageFrame.size)
        for _ in 0 ..< 2 {
            emptyStar!.draw(in: oneImageFrame)
            oneImageFrame.offsetBy(dx: oneImageFrame.width, dy: 0)
        }
        redCircle?.draw(in: oneImageFrame)
        containerImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        noEffectRatingImages.append(containerImage)
        
        
        
    }
    
    func ratingImageForButton(effect: String, sideEffects: String){
        
        var imageToReturn: UIImage!
        
        switch effect {
        case "in evaluation":
            imageToReturn = notRatedImage
        case "good":
            if sideEffects == "none" {
                imageToReturn = goodRatingImages[0]
            } else if sideEffects == "moderate" {
                imageToReturn = goodRatingImages[1]
            } else {
                imageToReturn = goodRatingImages[2]
            }
        case "moderate":
            if sideEffects == "none" {
                imageToReturn = moderateRatingImages[0]
            } else if sideEffects == "moderate" {
                imageToReturn = moderateRatingImages[1]
            } else {
                imageToReturn = moderateRatingImages[2]
            }
        case "minimal":
            if sideEffects == "none" {
                imageToReturn = minimalRatingImages[0]
            } else if sideEffects == "moderate" {
                imageToReturn = minimalRatingImages[1]
            } else {
                imageToReturn = minimalRatingImages[2]
            }
        case "none":
            imageToReturn = noEffectRatingImages[0]
        default:
            imageToReturn = notRatedImage
        }
        //        ratingButton.frame = CGRect(x: ratingButton.frame.maxX - imageToReturn.size.width, y: ratingButton.frame.origin.y, width: imageToReturn.size.width, height: imageToReturn.size.height)
        ratingButton.setImage(imageToReturn, for: .normal)
        ratingButton.setBackgroundImage(imageToReturn, for: .normal)
        ratingButton.setNeedsLayout()
        
        }

}
