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

class RMAlbumPickerController: UITableViewController, RMAssetSelectionDelegate, UIAlertViewDelegate, PHPhotoLibraryChangeObserver {
    var assetsParent: RMAssetSelectionDelegate?
    lazy var imageManager = PHCachingImageManager.defaultManager()
    var allCollections: [PHFetchResult] = []

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

        PHPhotoLibrary.sharedPhotoLibrary().registerChangeObserver(self)

        self.checkPhotoAuth()

        let phFetchOptions = PHFetchOptions()
        phFetchOptions.predicate = NSPredicate(format: "estimatedAssetCount > 0")
        self.allCollections.append(
            PHAssetCollection.fetchAssetCollectionsWithType(
                .SmartAlbum,
                subtype: .SmartAlbumUserLibrary,
                options: nil
            )
        )
        self.allCollections.append(
            PHAssetCollection.fetchAssetCollectionsWithType(
                .Album,
                subtype: .Any,
                options: phFetchOptions
            )
        )
    }

    func cancelImagePicker() {
        self.assetsParent?.cancelImagePicker()
    }

    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        self.navigationController?.setToolbarHidden(true, animated: true)
    }

    override func viewDidDisappear(animated: Bool) {
        PHPhotoLibrary.sharedPhotoLibrary().unregisterChangeObserver(self)
        super.viewDidDisappear(animated)
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    // MARK: - Table view data source

    override func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        // Return the number of sections.
        return self.allCollections.count
    }

    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        // Return the number of rows in the section.
        return self.allCollections[section].count
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
        let collection = self.allCollections[indexPath.section][indexPath.row] as PHAssetCollection
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
        let collection = self.allCollections[indexPath.section][indexPath.row] as PHAssetCollection
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

    // MARK: - PHPhotoLibraryChangeObserver

    func photoLibraryDidChange(changeInstance: PHChange!) {
        // Call might come on any background queue. Re-dispatch to the main queue to handle it.
        dispatch_async(dispatch_get_main_queue(), { () -> Void in
            // check if there are changes to the assets (insertions, deletions, updates)
            for (idx, fetchResult) in enumerate(self.allCollections) {
                if let collectionChanges = changeInstance.changeDetailsForFetchResult(fetchResult) {
                    // get the new fetch result
                    self.allCollections[idx] = collectionChanges.fetchResultAfterChanges
                    if let tableView = self.tableView {
                        if (!collectionChanges.hasIncrementalChanges || collectionChanges.hasMoves) {
                            // we need to reload all if the incremental diffs are not available
                            tableView.reloadData()
                        } else {
                            // if we have incremental diffs, tell the collection view to animate insertions and deletions
                            self.tableView.beginUpdates()
                            if let removedIndexes = collectionChanges.removedIndexes {
                                tableView.deleteRowsAtIndexPaths(removedIndexes.rm_indexPathsFromIndexesWithSection(idx), withRowAnimation: .Automatic)
                            }
                            if let insertedIndexes = collectionChanges.insertedIndexes {
                                tableView.insertRowsAtIndexPaths(insertedIndexes.rm_indexPathsFromIndexesWithSection(idx), withRowAnimation: .Automatic)
                            }
                            if let changedIndexes = collectionChanges.changedIndexes {
                                tableView.reloadRowsAtIndexPaths(changedIndexes.rm_indexPathsFromIndexesWithSection(idx), withRowAnimation: .Automatic)
                            }
                            self.tableView.endUpdates()
                        }
                    }
                }
            }
        })
    }

    // MARK: - RMAssetSelectionDelegate
    
    func selectedAssets(assets: [PHAsset]) {
        self.assetsParent?.selectedAssets(assets)
    }

    // MARK: - UIAlertViewDelegate

    func alertView(alertView: UIAlertView, clickedButtonAtIndex buttonIndex: Int) {
        if buttonIndex == 1 {
            UIApplication.sharedApplication().openURL(NSURL(string: UIApplicationOpenSettingsURLString)!)
        }
        self.cancelImagePicker()
    }

    // MARK: - Utility

    func checkPhotoAuth() {
        PHPhotoLibrary.requestAuthorization { (status) -> Void in
            switch status {
            case .Restricted:
                dispatch_async(dispatch_get_main_queue(), { () -> Void in
                    let photoAuthAlert = UIAlertView(
                        title: NSLocalizedString("Access restricted", comment: "to the photo library"),
                        message: NSLocalizedString("This application needs access to your photo library but it seems that you're not authorized to grant this permission.  Please contact someone who has higher privileges on the device.", comment: ""),
                        delegate: self,
                        cancelButtonTitle: NSLocalizedString("OK", comment: "")
                    )
                    photoAuthAlert.show()
                })
            case .Denied:
                dispatch_async(dispatch_get_main_queue(), { () -> Void in
                    let photoAuthAlert = UIAlertView(
                        title: NSLocalizedString("Please allow access", comment: "to the photo library"),
                        message: NSLocalizedString("This application needs access to your photo library. Please go to Settings > Privacy > Photos and switch this application to ON", comment: ""),
                        delegate: self,
                        cancelButtonTitle: NSLocalizedString("OK", comment: ""),
                        otherButtonTitles: NSLocalizedString("Settings", comment: "")
                    )
                    photoAuthAlert.show()
                })
            default:
                break
            }
        }
    }

}
