//
//  RMAssetCell.swift
//  RMImagePicker
//
//  Created by Riccardo Massari on 22/01/15.
//  Copyright (c) 2015 Riccardo Massari. All rights reserved.
//

import UIKit

let SelectedOverlayImg = UIImage(
    named: "tick_selected",
    inBundle: NSBundle(forClass: RMImagePickerController.self),
    compatibleWithTraitCollection: nil)
let DeselectedOverlayImg = UIImage(
    named: "tick_deselected",
    inBundle: NSBundle(forClass: RMImagePickerController.self),
    compatibleWithTraitCollection: nil)

class RMAssetCell: UICollectionViewCell {
    lazy var imageView = UIImageView()
    lazy var overlayView = UIImageView()
    override var selected: Bool {
        didSet {
            if selected {
                self.overlayView.image = SelectedOverlayImg
            } else {
                self.overlayView.image = DeselectedOverlayImg
            }
        }
    }

    override init(frame: CGRect) {
        super.init(frame: frame)
        self.imageView.frame = self.bounds
        self.imageView.contentMode = .ScaleAspectFill
        self.imageView.clipsToBounds = true
        self.contentView.addSubview(self.imageView)
        self.overlayView.frame = self.bounds
        self.contentView.addSubview(self.overlayView)
    }

    required init(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
}
