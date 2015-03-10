//
//  RMAlbumPickerController.swift
//  iSafariClient
//
//  Created by Riccardo Massari on 19/01/15.
//  Copyright (c) 2015 Riccardo Massari. All rights reserved.
//

import UIKit
import Photos

let albumCellIdentifier = "albumCellId"
let assetsInPosterImage: Int = 3
let albumRowHeigth = CGFloat(86.5)


protocol RMAssetSelectionDelegate {
    func selectedAssets(assets: [PHAsset])
    func cancelImagePicker()
}

class RMAlbumPickerController: UITableViewController, RMAssetSelectionDelegate {
    var assetsParent: RMAssetSelectionDelegate?
    lazy var imageManager = PHCachingImageManager.defaultManager()
    var collectionsFetchResult: PHFetchResult!
    var posterImages: [UIImage] = []

    override func viewDidLoad() {
        super.viewDidLoad()

        self.tableView.registerClass(UITableViewCell.self, forCellReuseIdentifier: albumCellIdentifier)
        self.tableView.separatorStyle = UITableViewCellSeparatorStyle.SingleLine

        self.navigationItem.title = NSLocalizedString("Photos", comment: "")
        let cancelButton = UIBarButtonItem(
            barButtonSystemItem: .Cancel,
            target: self,
            action: "cancelImagePicker")
        self.navigationItem.rightBarButtonItem = cancelButton

        let phFetchOptions = PHFetchOptions()
        phFetchOptions.predicate = NSPredicate(format: "estimatedAssetCount > 0")
        self.collectionsFetchResult = PHAssetCollection.fetchAssetCollectionsWithType(PHAssetCollectionType.Album, subtype: PHAssetCollectionSubtype.Any, options: phFetchOptions)

    }

    func cancelImagePicker() {
        self.assetsParent?.cancelImagePicker()
    }

    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        self.navigationController?.setToolbarHidden(true, animated: true)
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    // MARK: - Table view data source

    override func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        // Return the number of sections.
        return 1
    }

    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        // Return the number of rows in the section.
        return 1 + self.collectionsFetchResult.count
    }

    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier(albumCellIdentifier, forIndexPath: indexPath) as UITableViewCell

        // Increment the cell's tag
        let currentTag = cell.tag + 1
        cell.tag = currentTag

        // Configure the cell...
        var localizedTitle: String
        var assets: PHFetchResult
        if indexPath.row == 0 {
            assets = PHAsset.fetchAssetsWithOptions(nil)
            localizedTitle = NSLocalizedString("Camera Roll", comment: "")
        } else {
            let collection: PHAssetCollection! = self.collectionsFetchResult[indexPath.row - 1] as PHAssetCollection
            assets = PHAsset.fetchKeyAssetsInAssetCollection(collection, options: nil)
            localizedTitle = collection.localizedTitle
        }
        let requestOptions = PHImageRequestOptions()
        requestOptions.synchronous = true
        var keyImages: [UIImage] = []
        assets.enumerateObjectsUsingBlock({ (asset, idx, stop) -> Void in
            if idx > 1 {
                stop.memory = true
            }
            self.imageManager.requestImageForAsset(
                asset as PHAsset,
                targetSize: CGSizeMake(70, 70),
                contentMode: PHImageContentMode.AspectFit,
                options: requestOptions,
                resultHandler: { (image, info) -> Void in
                    keyImages.append(image)
            })
        })
        //  Only update the thumbnail if the cell tag hasn't changed. Otherwise, the cell has been re-used.
        if (cell.tag == currentTag) {
            cell.imageView!.image = self.mergeImages(keyImages, toImageWithSize: CGSizeMake(69.5, 73.5), andOffset: 2)
        }
        cell.textLabel?.text = localizedTitle
        cell.accessoryType = UITableViewCellAccessoryType.DisclosureIndicator

        return cell
    }

    override func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        let picker = RMAssetCollectionPicker()
        picker.assetsParent = self

        let phFetchOptions = PHFetchOptions()
        phFetchOptions.predicate = NSPredicate(format: "mediaType = %i", PHAssetMediaType.Image.rawValue)
        if indexPath.row == 0 {
            phFetchOptions.sortDescriptors = [NSSortDescriptor(key: "creationDate", ascending: true)]
            picker.assetsFetchResult = PHAsset.fetchAssetsWithOptions(phFetchOptions)
        } else {
            let collection: PHAssetCollection! = self.collectionsFetchResult[indexPath.row - 1] as PHAssetCollection
            picker.assetsFetchResult = PHAsset.fetchAssetsInAssetCollection(collection, options: phFetchOptions)
            picker.assetsCollection = collection
        }

        self.navigationController?.pushViewController(picker, animated: true)
    }

    override func tableView(tableView: UITableView, heightForRowAtIndexPath indexPath: NSIndexPath) -> CGFloat {
        return albumRowHeigth
    }

// MARK: - RMAssetSelectionDelegate

    func selectedAssets(assets: [PHAsset]) {
        self.assetsParent?.selectedAssets(assets)
    }

// MARK: - Utility

    func mergeImages(images: [UIImage!], toImageWithSize size: CGSize, andOffset offset: CGFloat) -> UIImage! {
        UIGraphicsBeginImageContextWithOptions(size, false, 2.0)

        var idxDec: CGFloat = CGFloat(images.count - 1)
        var idxInc: CGFloat = 0
        for img in images.reverse() {
            let newOrigin = CGPoint(x: idxDec * offset, y: idxInc * offset + 0.5)
            let newWidth = size.width - (offset * 2 * idxDec) - 0.5
            let newSize = CGSize(
                width: newWidth,
                height: newWidth
            )
            let rect = CGRect(origin: newOrigin, size: newSize)
            img.drawInRect(rect)

            let context = UIGraphicsGetCurrentContext();
            CGContextSetShouldAntialias(context, false)
            CGContextSetStrokeColorWithColor(context, UIColor.whiteColor().CGColor)
            CGContextStrokeRectWithWidth(context, rect, 0.5)
            CGContextSetShouldAntialias(context, true)
            idxInc++
            idxDec--
        }

        let mergedImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()

        return mergedImage
    }

}
