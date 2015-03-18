//
//  RMAssetCollectionPicker.swift
//  RMImagePicker
//
//  Created by Riccardo Massari on 25/01/15.
//  Copyright (c) 2015 Riccardo Massari. All rights reserved.
//

import UIKit
import AssetsLibrary
import Photos

let reuseIdentifier = "assetCellId"
let AssetsPerRowPort = CGFloat(4.0)
let AssetsPerRowLand = CGFloat(7.0)
let AssetsSpacing = CGFloat(1.0)
let AssetsInset = CGFloat(9.0)
var AssetGridThumbnailSize: CGSize!

extension NSIndexSet {
    func rm_indexPathsFromIndexesWithSection(section: Int) -> [NSIndexPath] {
        var indexPaths: [NSIndexPath] = []
        self.enumerateIndexesUsingBlock { (idx, stop) -> Void in
            indexPaths.append(NSIndexPath(forItem: idx, inSection: section))
        }
        return indexPaths
    }
}

extension UICollectionView {
    func rm_indexPathsForElementsInRect(rect: CGRect) -> [NSIndexPath] {
        let allLayoutAttributes = self.collectionViewLayout.layoutAttributesForElementsInRect(rect)
        var indexPaths: [NSIndexPath] = []
        for layoutAttributes in allLayoutAttributes! {
            indexPaths.append(layoutAttributes.indexPath)
        }
        return indexPaths
    }
}


class RMAssetCollectionPicker: UICollectionViewController, PHPhotoLibraryChangeObserver, UICollectionViewDelegateFlowLayout {
    var previousPreheatRect: CGRect?
    var alreadyScrolled = false
    var assetsParent: RMAssetSelectionDelegate?
    var imageManager: PHCachingImageManager!
    var assetsFetchResult: PHFetchResult!
    var assetCollection: PHAssetCollection!
    var baseNavigationTitle = ""
    var selectedAssetsNumber: Int! {
        didSet {
            self.updateNavigationTitle()
        }
    }

    convenience override init() {
        let layout = UICollectionViewFlowLayout()
        layout.scrollDirection = UICollectionViewScrollDirection.Vertical
        layout.minimumInteritemSpacing = AssetsSpacing
        layout.minimumLineSpacing = AssetsSpacing
        layout.sectionInset = UIEdgeInsets(top: AssetsInset, left: 0, bottom: AssetsInset, right: 0)
        self.init(collectionViewLayout: layout)
    }

    override init(collectionViewLayout layout: UICollectionViewLayout!) {
        super.init(collectionViewLayout: layout)
        self.imageManager = PHCachingImageManager()
        self.resetCachedAssets()
        PHPhotoLibrary.sharedPhotoLibrary().registerChangeObserver(self)
    }

    required init(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        // Register cell classes
        self.collectionView!.registerClass(RMAssetCell.self, forCellWithReuseIdentifier: reuseIdentifier)
        self.collectionView?.alwaysBounceVertical = true
        self.collectionView?.allowsMultipleSelection = true

        let scale = UIScreen.mainScreen().scale
        let cellSize = (self.collectionViewLayout as UICollectionViewFlowLayout).itemSize
        AssetGridThumbnailSize = CGSize(width: cellSize.width * scale, height: cellSize.height * scale)

        let doneButtonItem = UIBarButtonItem(
            barButtonSystemItem: UIBarButtonSystemItem.Done,
            target: self,
            action: "doneAction:"
        )
        self.navigationItem.rightBarButtonItem = doneButtonItem
        self.baseNavigationTitle = self.assetCollection.localizedTitle
        self.selectedAssetsNumber = 0

        self.navigationController?.setToolbarHidden(false, animated: true)
        let toolbar = self.navigationController?.toolbar
        let flexibleItem = UIBarButtonItem(
            barButtonSystemItem: UIBarButtonSystemItem.FlexibleSpace,
            target: self,
            action: nil
        )
        let selectAllItem = UIBarButtonItem(
            title: NSLocalizedString("Select all", comment: ""),
            style: UIBarButtonItemStyle.Bordered,
            target: self,
            action: "selectAllAction:"
        )
        let deselectAllItem = UIBarButtonItem(
            title: NSLocalizedString("Deselect all", comment: ""),
            style: UIBarButtonItemStyle.Bordered,
            target: self,
            action: "deselectAllAction:"
        )
        self.toolbarItems = [selectAllItem, flexibleItem, flexibleItem, deselectAllItem]

    }

    override func didRotateFromInterfaceOrientation(fromInterfaceOrientation: UIInterfaceOrientation) {
        let invContext = self.collectionViewLayout.invalidationContextForBoundsChange(self.collectionView!.bounds)
        self.collectionViewLayout.invalidateLayoutWithContext(invContext)
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        if !self.alreadyScrolled {
            self.collectionView?.scrollToItemAtIndexPath(NSIndexPath(forItem: self.assetsFetchResult.count - 1, inSection: 0), atScrollPosition: .Top, animated: false)
            self.alreadyScrolled = true
        }
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)
        self.updateCachedAssets()
    }

    override func viewDidDisappear(animated: Bool) {
        PHPhotoLibrary.sharedPhotoLibrary().unregisterChangeObserver(self)
        super.viewDidDisappear(animated)
    }

    // MARK: - UICollectionViewDataSource

    override func numberOfSectionsInCollectionView(collectionView: UICollectionView) -> Int {
        return 1
    }


    override func collectionView(collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return self.assetsFetchResult.count
    }

    override func collectionView(collectionView: UICollectionView, cellForItemAtIndexPath indexPath: NSIndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCellWithReuseIdentifier(reuseIdentifier, forIndexPath: indexPath) as RMAssetCell

        // Increment the cell's tag
        let currentTag = cell.tag + 1
        cell.tag = currentTag

        let asset: PHAsset! = self.assetsFetchResult[indexPath.item] as PHAsset
        self.imageManager.requestImageForAsset(
            asset,
            targetSize: AssetGridThumbnailSize,
            contentMode: PHImageContentMode.AspectFill,
            options: nil,
            resultHandler: { (result, info) in
                if (cell.tag == currentTag) {
                    cell.imageView.image = result
                    if cell.selected {
                        cell.overlayView.image = SelectedOverlayImg
                    } else {
                        cell.overlayView.image = DeselectedOverlayImg
                    }
                }
            }
        )
        return cell
    }

    override func collectionView(collectionView: UICollectionView, didSelectItemAtIndexPath indexPath: NSIndexPath) {
        self.selectedAssetsNumber! += 1
    }

    override func collectionView(collectionView: UICollectionView, didDeselectItemAtIndexPath indexPath: NSIndexPath) {
        self.selectedAssetsNumber! -= 1
    }

    // MARK: - PHPhotoLibraryChangeObserver

    func photoLibraryDidChange(changeInstance: PHChange!) {
        // Call might come on any background queue. Re-dispatch to the main queue to handle it.
        dispatch_async(dispatch_get_main_queue(), { () -> Void in
            // check if there are changes to the assets (insertions, deletions, updates)
            if let collectionChanges = changeInstance.changeDetailsForFetchResult(self.assetsFetchResult) {
                // get the new fetch result
                self.assetsFetchResult = collectionChanges.fetchResultAfterChanges
                if let collectionView = self.collectionView {
                    if (!collectionChanges.hasIncrementalChanges || collectionChanges.hasMoves) {
                        // we need to reload all if the incremental diffs are not available
                        collectionView.reloadData()
                    } else {
                        // if we have incremental diffs, tell the collection view to animate insertions and deletions
                        self.collectionView?.performBatchUpdates({ () -> Void in
                            if let removedIndexes = collectionChanges.removedIndexes {
                                collectionView.deleteItemsAtIndexPaths(removedIndexes.rm_indexPathsFromIndexesWithSection(0))
                            }
                            if let insertedIndexes = collectionChanges.insertedIndexes {
                                collectionView.insertItemsAtIndexPaths(insertedIndexes.rm_indexPathsFromIndexesWithSection(0))
                            }
                            if let changedIndexes = collectionChanges.changedIndexes {
                                collectionView.reloadItemsAtIndexPaths(changedIndexes.rm_indexPathsFromIndexesWithSection(0))
                            }
                            }, completion: nil)
                    }
                }
                self.resetCachedAssets()
            }
        })
    }

    // MARK: - UIScrollViewDelegate

    override func scrollViewDidScroll(scrollView: UIScrollView) {
        self.updateCachedAssets()
    }

    // MARK: - Asset Caching

    func resetCachedAssets() {
        self.imageManager.stopCachingImagesForAllAssets()
        self.previousPreheatRect = CGRectZero
    }

    func updateCachedAssets() {

        if (self.isViewLoaded() && self.view.window != nil) {
            // The preheat window is twice the height of the visible rect
            var preheatRect = self.collectionView!.bounds
            preheatRect = CGRectInset(
                preheatRect,
                0.0,
                -0.5 * CGRectGetHeight(preheatRect)
            )
            // If scrolled by a "reasonable" amount...
            let delta = abs(CGRectGetMidY(preheatRect) - CGRectGetMidY(self.previousPreheatRect!))
            if delta > CGRectGetHeight(self.collectionView!.bounds) / 3.0 {
                // Compute the assets to start caching and to stop caching.
                var addedIndexPaths: [NSIndexPath]  = []
                var removedIndexPaths: [NSIndexPath] = []

                self.computeDifferenceBetweenRect(self.previousPreheatRect!, andRect: preheatRect, removedHandler: { (removedRect) -> Void in
                    let indexPaths = self.collectionView!.rm_indexPathsForElementsInRect(removedRect)
                    removedIndexPaths.extend(indexPaths)
                    }, addedHandler: { (addedRect) -> Void in
                        let indexPaths = self.collectionView!.rm_indexPathsForElementsInRect(addedRect)
                        addedIndexPaths.extend(indexPaths)
                })

                let assetsToStartCaching = self.assetsAtIndexPaths(addedIndexPaths)
                let assetsToStopCaching = self.assetsAtIndexPaths(removedIndexPaths)

                self.imageManager.startCachingImagesForAssets(
                    assetsToStartCaching,
                    targetSize: AssetGridThumbnailSize,
                    contentMode: PHImageContentMode.AspectFill,
                    options: nil)
                self.imageManager.stopCachingImagesForAssets(
                    assetsToStopCaching,
                    targetSize: AssetGridThumbnailSize,
                    contentMode: PHImageContentMode.AspectFill,
                    options: nil)
                self.previousPreheatRect = preheatRect
            }
        }
    }

    func computeDifferenceBetweenRect(oldRect: CGRect, andRect newRect: CGRect, removedHandler: ((removedRect: CGRect) -> Void)!, addedHandler: ((addedRect: CGRect) -> Void)!) {
        if CGRectIntersectsRect(newRect, oldRect) {
            let oldMaxY = CGRectGetMaxY(oldRect)
            let oldMinY = CGRectGetMinY(oldRect)
            let newMaxY = CGRectGetMaxY(newRect)
            let newMinY = CGRectGetMinY(newRect)
            if newMaxY > oldMaxY {
                let rectToAdd = CGRectMake(newRect.origin.x, oldMaxY, newRect.size.width, (newMaxY - oldMaxY))
                addedHandler(addedRect: rectToAdd)
            }
            if oldMinY > newMinY {
                let rectToAdd = CGRectMake(newRect.origin.x, newMinY, newRect.size.width, (oldMinY - newMinY))
                addedHandler(addedRect: rectToAdd)
            }
            if newMaxY < oldMaxY {
                let rectToRemove = CGRectMake(newRect.origin.x, newMaxY, newRect.size.width, (oldMaxY - newMaxY))
                removedHandler(removedRect: rectToRemove)
            }
            if oldMinY < newMinY {
                let rectToRemove = CGRectMake(newRect.origin.x, oldMinY, newRect.size.width, (newMinY - oldMinY))
                removedHandler(removedRect: rectToRemove)
            }
        } else {
            addedHandler(addedRect: newRect)
            removedHandler(removedRect: oldRect)
        }
    }

    func assetsAtIndexPaths(indexPaths: [NSIndexPath]) -> [PHAsset] {
        var assets: [PHAsset] = []
        for indexPath in indexPaths {
            assets.append(self.assetsFetchResult[indexPath.item] as PHAsset)
        }
        return assets
    }

    // MARK: - UICollectionViewDelegateFlowLayout

    func collectionView(collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAtIndexPath indexPath: NSIndexPath) -> CGSize {
        let orientation = UIApplication.sharedApplication().statusBarOrientation
        let assetsPerRow = self.assetsPerRowFromOrientation(orientation)
        let itemSize = ((collectionView.bounds.width - (AssetsSpacing * (assetsPerRow - 1))) / assetsPerRow)
        return CGSize(width: itemSize, height: itemSize)
    }

    // MARK: - Actions

    func selectAllAction(sender: AnyObject) {
        for i in 0..<self.assetsFetchResult.count {
            self.collectionView?.selectItemAtIndexPath(NSIndexPath(forItem: i, inSection: 0), animated: true, scrollPosition: UICollectionViewScrollPosition.None)
        }
        self.selectedAssetsNumber = self.assetsFetchResult.count
    }

    func deselectAllAction(sender: AnyObject) {
        for i in 0..<self.assetsFetchResult.count {
            self.collectionView?.deselectItemAtIndexPath(NSIndexPath(forItem: i, inSection: 0), animated: true)
        }
        self.selectedAssetsNumber = 0
    }

    func doneAction(sender: AnyObject) {
        var selectedAssets: [PHAsset] = []
        for ip in self.collectionView!.indexPathsForSelectedItems() {
            selectedAssets.append(self.assetsFetchResult[ip.item] as PHAsset)
        }
        assetsParent?.selectedAssets(selectedAssets)
    }
    
    // MARK: - Utility
    
    func updateNavigationTitle() {
        self.navigationItem.title = self.baseNavigationTitle + " (\(self.selectedAssetsNumber))"
    }

    func assetsPerRowFromOrientation(orientation: UIInterfaceOrientation) -> CGFloat {
        var assetsPerRow: CGFloat
        switch orientation {
        case .Unknown, .Portrait, .PortraitUpsideDown:
            assetsPerRow = AssetsPerRowPort
        case .LandscapeLeft, .LandscapeRight:
            assetsPerRow = AssetsPerRowLand
        }
        return assetsPerRow
    }

}
