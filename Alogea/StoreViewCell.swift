//
//  StoreViewCell.swift
//  Alogea
//
//  Created by mikeMBP on 17/11/2016.
//  Copyright © 2016 AppToolFactory. All rights reserved.
//

import UIKit

class StoreViewCell: UITableViewCell {

    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var priceLabel: UILabel!
    @IBOutlet weak var descriptionLabel: UILabel!
    @IBOutlet weak var buyButton: UIButton!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }
    
    override func prepareForReuse() {
        super.prepareForReuse()
        
        titleLabel.text = ""
        descriptionLabel.text = ""
        priceLabel.text = ""
        // backgroundImage.image = nil
        // productIcon.image = nil
    }


}
