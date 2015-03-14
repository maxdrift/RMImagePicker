//
//  RMAlbumPickerController.swift
//  RMImagePicker
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

class UITableViewDetailCell: UITableViewCell {
    override init(style: UITableViewCellStyle, reuseIdentifier: String?) {
        super.init(style: .Subtitle, reuseIdentifier: reuseIdentifier)
    }

    required init(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
}

class RMAlbumPickerController: UITableViewController, RMAssetSelectionDelegate {
    var assetsParent: RMAssetSelectionDelegate?
    lazy var imageManager = PHCachingImageManager.defaultManager()
    var allCollections: [PHAssetCollection] = []

    override func viewDidLoad() {
        super.viewDidLoad()

        self.tableView.registerClass(UITableViewDetailCell.self, forCellReuseIdentifier: albumCellIdentifier)
        self.tableView.separatorStyle = UITableViewCellSeparatorStyle.None

        self.navigationItem.title = NSLocalizedString("Photos", comment: "")
        let cancelButton = UIBarButtonItem(
            barButtonSystemItem: .Cancel,
            target: self,
            action: "cancelImagePicker")
        self.navigationItem.rightBarButtonItem = cancelButton

        let phFetchOptions = PHFetchOptions()
        phFetchOptions.predicate = NSPredicate(format: "estimatedAssetCount > 0")
        PHAssetCollection.fetchAssetCollectionsWithType(
            .SmartAlbum,
            subtype: .SmartAlbumUserLibrary,
            options: nil
            ).enumerateObjectsUsingBlock { (collection, idx, _) -> Void in
                self.allCollections.append(collection as PHAssetCollection)
        }
        PHAssetCollection.fetchAssetCollectionsWithType(
            .Album,
            subtype: .Any,
            options: phFetchOptions
            ).enumerateObjectsUsingBlock { (collection, idx, _) -> Void in
                self.allCollections.append(collection as PHAssetCollection)
        }
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
        return self.allCollections.count
    }

    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier(albumCellIdentifier, forIndexPath: indexPath) as UITableViewCell

        // Increment the cell's tag
        let currentTag = cell.tag + 1
        cell.tag = currentTag

        // Configure the cell...
        let collection = self.allCollections[indexPath.row]
        var assetsCount: Int
        var keyAssets: PHFetchResult!
        if collection.assetCollectionType == .SmartAlbum {
            let fetchOptions = PHFetchOptions()
            fetchOptions.sortDescriptors = [NSSortDescriptor(key: "creationDate", ascending: false)]
            keyAssets = PHAsset.fetchAssetsInAssetCollection(collection, options: fetchOptions)
            assetsCount = keyAssets.count
        } else {
            keyAssets = PHAsset.fetchKeyAssetsInAssetCollection(collection, options: nil)
            assetsCount = collection.estimatedAssetCount
        }
        let requestOptions = PHImageRequestOptions()
        requestOptions.synchronous = true
        let enumOptions = NSEnumerationOptions.Reverse
        var keyImages: [UIImage] = []
        keyAssets.enumerateObjectsUsingBlock({ (asset, idx, stop) -> Void in
            if idx > 1 {
                stop.memory = true
            }
            let cropSideLength = min(asset.pixelWidth, asset.pixelHeight)
            let newOrigin = CGPoint(
                x: (asset.pixelWidth - cropSideLength) / 2,
                y: (asset.pixelHeight - cropSideLength) / 2
            )
            let square = CGRectMake(newOrigin.x, newOrigin.y, CGFloat(cropSideLength), CGFloat(cropSideLength))
            let cropRect = CGRectApplyAffineTransform(
                square,
                CGAffineTransformMakeScale(
                    1.0 / CGFloat(asset.pixelWidth),
                    1.0 / CGFloat(asset.pixelHeight))
            )
            requestOptions.resizeMode = .Exact
            requestOptions.normalizedCropRect = cropRect

            self.imageManager.requestImageForAsset(
                asset as PHAsset,
                targetSize: CGSizeMake(139, 139),
                contentMode: .AspectFill,
                options: requestOptions,
                resultHandler: { (image, info) -> Void in
                    keyImages.append(image)
            })
        })
        //  Only update the thumbnail if the cell tag hasn't changed. Otherwise, the cell has been re-used.
        if (cell.tag == currentTag) {
            cell.textLabel?.text = collection.localizedTitle
            cell.detailTextLabel?.text = "\(assetsCount)"
            cell.imageView!.image = self.mergeImages(
                keyImages,
                toImageWithSize: CGSizeMake(69.5, 73.5),
                andOffset: 2
            )
            cell.accessoryType = .DisclosureIndicator
        }

        return cell
    }

    override func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        let phFetchOptions = PHFetchOptions()
        phFetchOptions.predicate = NSPredicate(format: "mediaType = %i", PHAssetMediaType.Image.rawValue)
        let collection = self.allCollections[indexPath.row]
        let assets = PHAsset.fetchAssetsInAssetCollection(collection, options: phFetchOptions)
        if assets.count > 0 {
            let picker = RMAssetCollectionPicker()
            picker.assetsParent = self

            picker.assetsFetchResult = assets
            picker.assetCollection = collection

            self.navigationController?.pushViewController(picker, animated: true)
        } else {
            let placeholderVC = UIViewController(
                nibName: "RMPlaceholderView",
                bundle: NSBundle(forClass: RMAlbumPickerController.self)
            )
            self.navigationController?.pushViewController(placeholderVC, animated: true)
        }
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
        UIGraphicsBeginImageContextWithOptions(size, false, 0.0)
        let context = UIGraphicsGetCurrentContext()

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
