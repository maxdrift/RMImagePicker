//
//  RMImagePickerController.swift
//  RMImagePicker
//
//  Created by Riccardo Massari on 19/01/15.
//  Copyright (c) 2015 Riccardo Massari. All rights reserved.
//

import UIKit
import Photos

public protocol RMImagePickerControllerDelegate: UINavigationControllerDelegate {
    func rmImagePickerController(picker: RMImagePickerController, didFinishPickingAssets assets: [PHAsset])
    func rmImagePickerControllerDidCancel(picker: RMImagePickerController)
}

public class RMImagePickerController: UINavigationController, RMAssetSelectionDelegate {
    public var pickerDelegate: RMImagePickerControllerDelegate?
    var albumController: RMAlbumPickerController?

    override init(rootViewController: UIViewController) {
        super.init(rootViewController: rootViewController)
    }

    public override convenience init() {
        var albumController = RMAlbumPickerController()
        self.init(rootViewController: albumController)
        albumController.assetsParent = self
    }

    override init(nibName nibNameOrNil: String?, bundle nibBundleOrNil: NSBundle?) {
        super.init(nibName: nibNameOrNil, bundle: nibBundleOrNil)
    }

    required public init(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }

    override public func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
    }

    override public func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

// MARK: - Actions

    func cancelImagePicker() {
        if let d = self.pickerDelegate {
            d.rmImagePickerControllerDidCancel(self)
        }
    }

// MARK: - Asset Selection Delegate

    func selectedAssets(assets: [PHAsset]) {
        if let d = self.pickerDelegate {
            d.rmImagePickerController(self, didFinishPickingAssets: assets)
        } else {
            self.popToRootViewControllerAnimated(false)
        }
    }

}
