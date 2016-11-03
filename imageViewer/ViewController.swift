//
//  ViewController.swift
//  imageViewer
//
//  Created by Timur Piriev on 11/3/16.
//  Copyright © 2016 Timur Piriev. All rights reserved.
//

import Agrume
import UIKit
import NYTPhotoViewer


class ViewController: UIViewController, NYTPhotosViewControllerDelegate {

    var images: [URL] = []
    var photos: [Model] = []
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.images.append(NSURL(string:"https://pixabay.com/static/uploads/photo/2016/10/14/19/21/river-1740973_1280.jpg")! as URL)
        self.images.append(NSURL(string:"https://pixabay.com/static/uploads/photo/2011/01/17/17/40/raven-4590_1280.jpg")! as URL)
        self.images.append(NSURL(string:"https://pixabay.com/static/uploads/photo/2016/03/05/19/32/affair-1238432_1280.jpg")! as URL)
        
        for item in self.images {
            let nyphoto = Model.init(url: item)
            photos.append(nyphoto)
        }
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    @IBAction func openImageAgrum(_ sender: AnyObject) {
        let agrum = Agrume(imageUrls: self.images, startIndex: 0, backgroundBlurStyle: .dark)
        agrum.showFrom(self)
    }
    
    
    //NYTPhoto  DELEGATE
    
    @IBAction func openPictures(_ sender: AnyObject) {
        let photoViewer = NYTPhotosViewController(photos: self.photos)
        photoViewer.delegate = self
        present(photoViewer, animated: true, completion: nil)
    }
    
    func photosViewController(_ photosViewController: NYTPhotosViewController, didNavigateTo photo: NYTPhoto, at photoIndex: UInt) {
        let iv = UIImageView()
        iv.kf.setImage(with: self.photos[0].url, placeholder: nil, options: nil, progressBlock: nil, completionHandler: {[weak self] (image, error, cacheType, imageUrl) in
            self?.photos[0].image = image
        })
        
    }
}

