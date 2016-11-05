//
//  ViewController.swift
//  imageViewer
//
//  Created by Timur Piriev on 11/3/16.
//  Copyright © 2016 Timur Piriev. All rights reserved.
//

import Agrume
import UIKit
import MWPhotoBrowser



class ViewController: UIViewController, MWPhotoBrowserDelegate {


    var imagesURLS: [NSURL] = []
    var photoBrowserArr: [MWPhoto] = []
    var agrumeURLs: [URL] = []
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        
        
        
        self.imagesURLS.append(NSURL(string:"https://pixabay.com/static/uploads/photo/2016/09/11/10/02/auto-1661009_1280.jpg")!)
        self.imagesURLS.append(NSURL(string: "https://pixabay.com/static/uploads/photo/2016/02/13/13/11/cuba-1197800_1280.jpg")!)
        self.imagesURLS.append(NSURL(string:"https://pixabay.com/static/uploads/photo/2016/07/23/15/48/oldtimer-1537007_1280.jpg")!)
        self.imagesURLS.append(NSURL(string:"https://pixabay.com/static/uploads/photo/2016/11/02/13/17/moor-1791392_1280.jpg")!)
        self.imagesURLS.append(NSURL(string:"https://pixabay.com/static/uploads/photo/2015/10/25/10/34/autumn-1005587_1280.jpg")!)
        self.imagesURLS.append(NSURL(string:"https://pixabay.com/static/uploads/photo/2016/07/07/22/43/rise-1503340_1280.jpg")!)
        self.imagesURLS.append(NSURL(string:"https://pixabay.com/static/uploads/photo/2016/10/12/23/23/mining-excavator-1736293_1280.jpg")!)
        self.imagesURLS.append(NSURL(string:"https://pixabay.com/static/uploads/photo/2016/08/29/23/19/zingst-1629451_1280.jpg")!)
        self.imagesURLS.append(NSURL(string:"https://pixabay.com/static/uploads/photo/2016/10/15/12/01/dog-1742295_1280.jpg")!)
        self.imagesURLS.append(NSURL(string:"https://pixabay.com/static/uploads/photo/2016/10/13/01/04/nuts-1736520_1280.jpg")!)
        self.imagesURLS.append(NSURL(string:"https://pixabay.com/static/uploads/photo/2016/09/21/04/46/barley-field-1684052_1280.jpg")!)
        
        for item in imagesURLS {
            agrumeURLs.append(item as URL)
            let browserImage = MWPhoto.init(url: item as URL)
            photoBrowserArr.append(browserImage!)
        }
        
        
}

    //PHOTO BROWSER
    @IBAction func photoBrowser(_ sender: AnyObject) {
        let browser = MWPhotoBrowser(delegate: self)
        
        // Set options
        browser?.displayActionButton = true // Show action button to allow sharing, copying, etc (defaults to YES) ++
        browser?.displayNavArrows = false // Whether to display left and right nav arrows on toolbar (defaults to NO)
        browser?.displaySelectionButtons = false // Whether selection buttons are shown on each image (defaults to NO)
        browser?.zoomPhotosToFill = true // Images that almost fill the screen will be initially zoomed to fill (defaults to YES)
        browser?.alwaysShowControls = true // Allows to control whether the bars and controls are always visible or whether they fade away to show the photo full (defaults to NO)
        browser?.enableGrid = true // Whether to allow the viewing of all the photo thumbnails on a grid (defaults to YES)
        browser?.startOnGrid = false // Whether to start on the grid of thumbnails instead of the first photo (defaults to NO)
        
        // Optionally set the current visible photo before displaying
        //browser.setCurrentPhotoIndex(1)
        
        self.navigationController?.pushViewController(browser!, animated: true)
        //present(browser!, animated: true, completion: nil)
    }
    
    
    func photoBrowser(_ photoBrowser: MWPhotoBrowser!, photoAt index: UInt) -> MWPhotoProtocol! {
        if Int(index) < self.photoBrowserArr.count {
            return photoBrowserArr[Int(index)] as MWPhoto
        }
        
        return nil
    }
    
    public func numberOfPhotos(in photoBrowser: MWPhotoBrowser!) -> UInt {
        return UInt(self.photoBrowserArr.count)
    }
    
    func photoBrowser(_ photoBrowser: MWPhotoBrowser!, actionButtonPressedForPhotoAt index: UInt) {
        self.showMenu(userId: index)
    }
    
    //alerts
    func showMenu(userId: UInt) -> Void {
        let alertView = UIAlertController.init(title: "USERNAME", message: "DO SOME ACTIONS", preferredStyle: .actionSheet)
        let favoriteAction = UIAlertAction.init(title: "Favorite", style: .default, handler: nil)
        let blockAction = UIAlertAction.init(title: "Block", style: .default, handler: nil)
        let reportAction = UIAlertAction.init(title: "Report", style: .default, handler: {(UIAlertAction) in
            self.reportActionMenu(userId: userId)
        })
        let cancel = UIAlertAction.init(title: "Cancel", style: UIAlertActionStyle.cancel, handler: nil)
        
        alertView.addAction(favoriteAction)
        alertView.addAction(blockAction)
        alertView.addAction(reportAction)
        alertView.addAction(cancel)
        
        present(alertView, animated: true, completion: nil)
    }
    
    func reportActionMenu(userId: UInt) -> Void {
        let report1 = UIAlertAction.init(title: "ДРЫЩ", style: .default, handler: nil)
        let report2 = UIAlertAction.init(title: "СОТКУ НЕ ЖМЕТ", style: .default, handler: nil)
        let report3 = UIAlertAction.init(title: "РАЗБРАСЫВАЕТ БЛИНЫ", style: .default, handler: nil)
        let alertView = UIAlertController.init(title: "Report screen", message: "Choose type of report", preferredStyle: .actionSheet)
        let cancel = UIAlertAction.init(title: "Cancel", style: UIAlertActionStyle.cancel, handler: nil)
        
        alertView.addAction(report1)
        alertView.addAction(report2)
        alertView.addAction(report3)
        alertView.addAction(cancel)
        
        present(alertView, animated: true, completion: nil)
    }
    
    //DELEGATE METHODS
//    func likesCount() -> UInt {
//        return 1
//    }
//    func isLiked() -> Bool {
//        return true
//    }
//    func isFavorite() -> Bool {
//        return true
//    }
//    func favorite(favorite: Bool) {
//        
//    }
//    func isBlocked() -> Bool {
//        return true
//    }
//    func block(_ block: Bool) -> Void {
//        
//    }
//    func reportSpam() -> Void {
//        
//    }
//    func reportAbuse() -> Void {
//        
//    }
    
    //AGRUM
    
    @IBAction func openImageAgrum(_ sender: AnyObject) {
//        let agrum = Agrume(imageUrls: self.agrumeURLs, startIndex: 0, backgroundBlurStyle: .dark, delegate: self)
//        agrum.showFrom(self)
    }
    
    //MAILIMAGEVIEW
    
    @IBAction func MailImageView(_ sender: AnyObject) {
    }

}

