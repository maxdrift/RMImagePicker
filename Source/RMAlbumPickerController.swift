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
let albumRowHeigth = CGFloat(70.0)


protocol RMAssetSelectionDelegate {
    func selectedAssets(assets: [PHAsset])
    func cancelImagePicker()
}

class RMAlbumPickerController: UITableViewController, RMAssetSelectionDelegate {
    var assetsParent: RMAssetSelectionDelegate?
    lazy var imageManager = PHCachingImageManager.defaultManager()
    var collectionsFetchResult: PHFetchResult!
    var keyAssets: [[UIImage]] = []

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

        // Configure the cell...
        var localizedTitle: String
        if indexPath.row == 0 {
            localizedTitle = NSLocalizedString("Camera Roll", comment: "")
        } else {
            let collection: PHAssetCollection! = self.collectionsFetchResult[indexPath.row - 1] as PHAssetCollection
            localizedTitle = collection.localizedTitle
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
        UIGraphicsBeginImageContext(size)
        var idxDec: CGFloat = CGFloat(images.count)
        var idxInc: CGFloat = 0
        for img in images.reverse() {
            let newOrigin = CGPoint(x: idxDec * offset, y: idxInc * offset)
            let newWidth = size.width - (offset * 2 * idxDec)
            let newSize = CGSize(
                width: newWidth,
                height: newWidth
            )
            img.drawInRect(CGRect(origin: newOrigin, size: newSize))
            idxInc++
            idxDec--
        }

        let mergedImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()

        return mergedImage
    }
    
}
