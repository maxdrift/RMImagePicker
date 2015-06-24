//
//  ImagesViewController.swift
//  RMImagePickerExample
//
//  Created by Riccardo Massari on 10/03/15.
//  Copyright (c) 2015 Riccardo Massari. All rights reserved.
//

import UIKit
import Photos
import RMImagePicker

let reuseIdentifier = "imageCellId"
let cellSize = CGSize(width: 132, height: 132)
let cellImageViewTag = 1

class ImagesViewController: UICollectionViewController, RMImagePickerControllerDelegate {
    var popoverController: UIPopoverController!
    lazy var imageManager = PHImageManager.defaultManager()
    var assets: [PHAsset] = []

    override func viewDidLoad() {
        super.viewDidLoad()
        self.collectionView?.alwaysBounceVertical = true
        let addImagesButton = UIBarButtonItem(barButtonSystemItem: UIBarButtonSystemItem.Add, target: self, action: "pickImages:")
        self.navigationItem.rightBarButtonItem = addImagesButton
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
    }
    */

    // MARK: UICollectionViewDataSource

    override func numberOfSectionsInCollectionView(collectionView: UICollectionView) -> Int {
        return 1
    }


    override func collectionView(collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return self.assets.count
    }

    override func collectionView(collectionView: UICollectionView, cellForItemAtIndexPath indexPath: NSIndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCellWithReuseIdentifier(reuseIdentifier, forIndexPath: indexPath) as! UICollectionViewCell

        // Configure the cell
        let asset = self.assets[indexPath.item]
        self.imageManager.requestImageForAsset(
            asset,
            targetSize: cellSize,
            contentMode: PHImageContentMode.AspectFit,
            options: nil,
            resultHandler: { (image, info) -> Void in
                let imageView = cell.viewWithTag(cellImageViewTag) as! UIImageView
                imageView.image = image
        })
        return cell
    }

    // MARK: - Actions

    func pickImages(sender: AnyObject) {
        let imagePicker = RMImagePickerController()
        imagePicker.pickerDelegate = self
        if UIDevice.currentDevice().userInterfaceIdiom == UIUserInterfaceIdiom.Pad {
            self.popoverController = UIPopoverController(contentViewController: imagePicker)
            self.popoverController.presentPopoverFromBarButtonItem(
                self.navigationItem.rightBarButtonItem!,
                permittedArrowDirections: UIPopoverArrowDirection.Any,
                animated: true)
        } else {
            self.presentViewController(imagePicker, animated: true, completion: nil)
        }
    }

    // MARK: - RMImagePickerControllerDelegate

    func rmImagePickerController(picker: RMImagePickerController, didFinishPickingAssets assets: [PHAsset]) {
        self.assets = assets
        self.dismissPickerPopover()
        self.collectionView?.performBatchUpdates({
            let nos = self.collectionView?.numberOfSections()
            self.collectionView!.reloadSections(
                NSIndexSet(indexesInRange: NSMakeRange(0, nos!))
            )
            }, completion: nil)
    }

    func rmImagePickerControllerDidCancel(picker: RMImagePickerController) {
        self.dismissPickerPopover()
    }

    // MARK: - Utility

    func dismissPickerPopover() {
        if UIDevice.currentDevice().userInterfaceIdiom == UIUserInterfaceIdiom.Pad {
            self.popoverController?.dismissPopoverAnimated(true)
        } else {
            self.dismissViewControllerAnimated(true, completion: nil)
        }
    }
    
}
