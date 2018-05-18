//
//  SearchPhotosCollectionViewController.swift
//  FlickrViewer
//
//  Created by Hank Wang on 2018/5/5.
//  Copyright © 2018 hanksudo. All rights reserved.
//

import UIKit
import SDWebImage

private let reuseIdentifier = "Cell"
private let ImageViewTag = 1

class SearchPhotosCollectionViewController: UICollectionViewController {

    var photos = [[String: AnyObject]]()
    typealias functionBlock1 = () -> ()//不带参数
    var timer: Timer?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        collectionView?.register(SearchPhotosCollectionViewCell.self, forCellWithReuseIdentifier: "cell")
        
        let minimumInterItemSpacing: CGFloat = 3
        let minimumLineSpacing: CGFloat = 3
        let numberOfColumns: CGFloat = 3
        
        let width = ((collectionView?.frame.width)! - minimumInterItemSpacing - minimumLineSpacing) / numberOfColumns
        
        let layout = collectionViewLayout as! UICollectionViewFlowLayout
        layout.minimumInteritemSpacing = minimumInterItemSpacing
        layout.minimumLineSpacing = minimumLineSpacing
        
        layout.itemSize = CGSize(width: width, height: width)
        
        for i in 0...1000 {
            if i == 0 {
                fetchFlickrApi()
            } else {
                let deadlineTime = DispatchTime.now() + .seconds(i + 2)
                DispatchQueue.main.asyncAfter(deadline: deadlineTime) {
                    self.fetchFlickrApi()
                }
            }
        }
    }

    func fetchFlickrApi() -> Void {
        // Your code with delay
        let array = ["food", "taiwan", "sport", "music", "movie"]
        let randomIndex = Int(arc4random_uniform(UInt32(array.count)))
        let searchText = array[randomIndex]
        
        FlickrAPI.searchPhotos(text: searchText) { (photosArray, error) in
            self.photos = photosArray
            DispatchQueue.main.async {
                self.collectionView?.reloadData()
            }
            
            for j in 0...self.photos.count - 1 {
                let photoDict = self.photos[j]
                
                if let imageUrlString = photoDict["url_m"] as? String
                {
                    if let url = URL(string: imageUrlString) {
                        if (SDImageCache.shared().diskImageDataExists(withKey: imageUrlString)) {
                            CustomPhotoAlbum.sharedInstance.save(image: SDImageCache.shared().imageFromCache(forKey: imageUrlString)!)
                            print("has cache")
                        } else {
                            let data = try? Data(contentsOf: url) //make sure your image in this url does exist, otherwise unwrap in a if let check / try-catch
                            CustomPhotoAlbum.sharedInstance.save(image: UIImage(data: data!)!)
                            print("no cache")
                        }
                    }
                }
            }
        }
    }

    override func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return photos.count
    }

    override func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: reuseIdentifier, for: indexPath) as! SearchPhotosCollectionViewCell
      
        let photoDict = photos[(indexPath as NSIndexPath).row]
        
        if let imageUrlString = photoDict["url_m"] as? String
        {
            cell.imageView.sd_setImage(with: URL(string: imageUrlString), placeholderImage: UIImage(named: "placeholder.png"))
        }
        
        return cell
    }
}

let imageCache = NSCache<NSString, UIImage>()

class MyImageView: UIImageView {
    
    var task: URLSessionDataTask?
    
    func loadFromURL(_ urlString: String) {
        self.clearTask()
        
        if let cachedImage = imageCache.object(forKey: urlString as NSString) {
            DispatchQueue.main.async {
                self.image = cachedImage
            }
            return
        }
        
        guard let url = URL(string: urlString) else {
            return
        }
        
        task = URLSession.shared.dataTask(with: url, completionHandler: { (data, response, error) in
            guard let statusCode = (response as? HTTPURLResponse)?.statusCode, statusCode >= 200 && statusCode <= 299 else {
                return
            }
            
            guard (error == nil) else {
                return
            }
            
            let imageToCache = UIImage(data: data!)
            imageCache.setObject(imageToCache!, forKey: urlString as NSString)
            
            DispatchQueue.main.async {
                self.image = imageToCache
                self.clearTask()
            }
        })
        task!.resume()
    }
    
    func clearTask() {
        if self.task != nil {
            self.task!.cancel()
            self.task = nil
        }
    }
}
