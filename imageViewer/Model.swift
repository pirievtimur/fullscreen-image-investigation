//
//  Model.swift
//  imageViewer
//
//  Created by Timur Piriev on 11/3/16.
//  Copyright © 2016 Timur Piriev. All rights reserved.
//

import Foundation
import UIKit
import NYTPhotoViewer
import Kingfisher

class Model: NSObject, NYTPhoto
{
    var image: UIImage?
    var imageView: UIImageView?
    var imageData: Data?
    var placeholderImage: UIImage?
    var attributedCaptionTitle: NSAttributedString?
    var attributedCaptionSummary: NSAttributedString?
    var attributedCaptionCredit: NSAttributedString?
    var url: URL?
    
    init(url: URL)
    {
        super.init()
        self.url = url
    }
    
    func loadImage() -> Void {
        
    }
    
}
