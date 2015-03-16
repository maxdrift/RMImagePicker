//
//  RMAlbumCell.swift
//  RMImagePicker
//
//  Created by Riccardo Massari on 15/03/15.
//  Copyright (c) 2015 Riccardo Massari. All rights reserved.
//

import UIKit
import Photos

class RMAlbumCell: UITableViewCell {
    @IBOutlet weak var title: UILabel!
    @IBOutlet weak var count: UILabel!
    @IBOutlet weak var poster1: UIImageView!
    @IBOutlet weak var poster2: UIImageView!
    @IBOutlet weak var poster3: UIImageView!
    var posterImgs: [UIImageView] = []

    override func awakeFromNib() {
        super.awakeFromNib()
        self.posterImgs = [poster1, poster2, poster3]
        for iv in self.posterImgs {
            iv.layer.borderColor = UIColor.whiteColor().CGColor
            iv.layer.borderWidth = 0.5
        }
    }

    override func setSelected(selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
    }

}
