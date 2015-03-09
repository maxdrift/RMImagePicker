//
//  RMAssetCell.swift
//  iSafariClient
//
//  Created by Riccardo Massari on 22/01/15.
//  Copyright (c) 2015 Riccardo Massari. All rights reserved.
//

import UIKit

class RMAssetCell: UICollectionViewCell {
    lazy var imageView = UIImageView()
    lazy var overlayView = UIImageView()
    override var selected: Bool {
        didSet {
            if selected {
                self.overlayView.image = UIImage(named: "tick_selected")
            } else {
                self.overlayView.image = UIImage(named: "tick_deselected")
            }
        }
    }

    override init(frame: CGRect) {
        super.init(frame: frame)
        self.imageView.frame = self.bounds
        self.contentView.addSubview(self.imageView)
        self.overlayView.frame = self.bounds
        self.contentView.addSubview(self.overlayView)
    }

    required init(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }

    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }
}
