//
//  ViewController.swift
//  RMImagePickerExample
//
//  Created by Riccardo Massari on 09/03/15.
//  Copyright (c) 2015 Riccardo Massari. All rights reserved.
//

import UIKit
import Photos
import RMImagePicker

class ViewController: UIViewController, RMImagePickerControllerDelegate {
    var imagePicker: RMImagePickerController?

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
    }

    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)
        self.imagePicker = RMImagePickerController()
        self.imagePicker?.pickerDelegate = self
        self.presentViewController(self.imagePicker!, animated: true, completion: nil)
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    func rmImagePickerController(picker: RMImagePickerController, didFinishPickingAssets assets: [PHAsset]) {
        println("Done!")
    }

    func rmImagePickerControllerDidCancel(picker: RMImagePickerController) {
        println("Cancel!")
    }
    
}
