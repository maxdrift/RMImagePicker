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
let albumRowHeigth = CGFloat(173)


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

        let cellNib = UINib(nibName: "RMAlbumCell", bundle: NSBundle(forClass: RMAlbumPickerController.self))
        self.tableView.registerNib(cellNib, forCellReuseIdentifier: albumCellIdentifier)
        self.tableView.separatorStyle = UITableViewCellSeparatorStyle.None

        self.navigationItem.title = NSLocalizedString("Albums", comment: "")
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
        var cell: RMAlbumCell!
        if let reCell = tableView.dequeueReusableCellWithIdentifier(albumCellIdentifier, forIndexPath: indexPath) as? RMAlbumCell {
            cell = reCell
        } else {
            cell = NSBundle(forClass: RMAlbumPickerController.self).loadNibNamed("RMAlbumCell", owner: self, options: nil)[0] as RMAlbumCell
        }

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
        let scale = UIScreen.mainScreen().scale
        let imageWidth = cell.poster1.bounds.width * scale
        let imageHeight = cell.poster1.bounds.height * scale
        for (idx, poster) in enumerate(cell.posterImgs) {
            if idx < keyAssets.count {
                self.imageManager.requestImageForAsset(
                    keyAssets[idx] as PHAsset,
                    targetSize: CGSizeMake(imageWidth, imageHeight),
                    contentMode: .AspectFill,
                    options: nil,
                    resultHandler: { (image, info) -> Void in
                        if (cell.tag == currentTag) {
                            poster.image = image
                        }
                })
            } else {
                if (cell.tag == currentTag) {
                    poster.image = nil
                }
            }
        }
        if (cell.tag == currentTag) {
            cell.title.text = collection.localizedTitle
            cell.count.text = "\(assetsCount)"
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
        return albumRowHeigth / UIScreen.mainScreen().scale
    }

    // MARK: - RMAssetSelectionDelegate
    
    func selectedAssets(assets: [PHAsset]) {
        self.assetsParent?.selectedAssets(assets)
    }
    
}
