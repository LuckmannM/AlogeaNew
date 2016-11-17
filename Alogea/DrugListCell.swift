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
    @IBOutlet weak var otherInfoLabel: UILabel!
    @IBOutlet weak var ratingButton: UIButton!
    @IBOutlet weak var doseLabel: UILabel!
    
    var notRatedImage: UIImage!
    var goodRatingImages: [UIImage]!
    var moderateRatingImages:[UIImage]!
    var minimalRatingImages:[UIImage]!
    var noEffectRatingImages: [UIImage]!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
    }
    
    //
    //    override func setSelected(selected: Bool, animated: Bool) {
    //        super.setSelected(selected, animated: animated)
    //
    //        // Configure the view for the selected state
    //    }
    
    override func prepareForReuse() {
        nameLabel.text = ""
        doseLabel.text = ""
        ratingButton.setImage(UIImage(named: "3Gray"), for: .normal)
        ratingButton.setImage(UIImage(named: "3Gray"), for: .disabled)
        ratingButton.titleLabel?.text = ""
        ratingButton.isEnabled = true
        ratingButton.backgroundColor = UIColor.clear
    }
    
    
    func ratingImageForButton(effect: String, sideEffects: String){
        
        var imageToReturn: UIImage!
        
        switch effect {
        case "in evaluation":
            imageToReturn = UIImage(named: "3Gray")
        case "good":
            if sideEffects == "none" {
                imageToReturn = UIImage(named: "3Yellow")
            } else if sideEffects == "moderate" {
                imageToReturn = UIImage(named: "3Orange")
            } else {
                imageToReturn = UIImage(named: "3Red")
            }
        case "moderate":
            if sideEffects == "none" {
                imageToReturn = UIImage(named: "2Yellow")
            } else if sideEffects == "moderate" {
                imageToReturn = UIImage(named: "2Orange")
            } else {
                imageToReturn = UIImage(named: "2Red")
            }
        case "minimal":
            if sideEffects == "none" {
                imageToReturn = UIImage(named: "1Yellow")
            } else if sideEffects == "moderate" {
                imageToReturn = UIImage(named: "1Orange")
            } else {
                imageToReturn = UIImage(named: "1Red")
            }
        case "none":
            imageToReturn = UIImage(named: "3CircleX")
        default:
            imageToReturn = UIImage(named: "3Gray")
        }
        // ratingButton.frame = CGRect(x: ratingButton.frame.maxX - imageToReturn.size.width, y: ratingButton.frame.origin.y, width: imageToReturn.size.width, height: imageToReturn.size.height)
        ratingButton.setImage(imageToReturn, for: .normal)
        ratingButton.setBackgroundImage(imageToReturn, for: .normal)
        ratingButton.sizeToFit()
        
        }

}
