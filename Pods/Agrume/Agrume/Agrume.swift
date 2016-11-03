//
//  Agrume.swift
//  Agrume
//

import UIKit

public protocol AgrumeDataSource {
	
  /// The number of images contained in the data source
	var numberOfImages: Int { get }
  
  /// Return the image for the passed in index
  ///
  /// - Parameter index: The index (collection view item) being displayed
  /// - Parameter completion: The completion that returns the image to be shown at the index
	func image(forIndex index: Int, completion: (UIImage?) -> Void)

}

public protocol ProfilePhotosActions {
    func likesCount() -> Int
    func isLiked() -> Bool
    func isFavorite() -> Bool
    func favorite(favorite: Bool)
    func isBlocked() -> Bool
    func block(block: Bool) -> Void
    func reportSpam() -> Void
    func reportAbuse() -> Void
}

public final class Agrume: UIViewController {

  fileprivate static let transitionAnimationDuration: TimeInterval = 0.2
  fileprivate static let initialScalingToExpandFrom: CGFloat = 0.6
  fileprivate static let maxScalingForExpandingOffscreen: CGFloat = 1.25
  fileprivate static let reuseIdentifier = "reuseIdentifier"
    
  fileprivate var images: [UIImage]!
  fileprivate var imageUrls: [URL]!
  private var startIndex: Int?
  private let backgroundBlurStyle: UIBlurEffectStyle
  fileprivate let dataSource: AgrumeDataSource?
    
   public let delegate: ProfilePhotosActions?

    
    
  public typealias DownloadCompletion = (_ image: UIImage?) -> Void
    
  public var didDismiss: (() -> Void)?
  public var didScroll: ((_ index: Int) -> Void)?
  public var download: ((_ url: URL, _ completion: @escaping DownloadCompletion) -> Void)?
  public var statusBarStyle: UIStatusBarStyle? {
    didSet {
      setNeedsStatusBarAppearanceUpdate()
    }
  }

  /// Initialize with a single image
  ///
  /// - Parameter image: The image to present
  /// - Parameter backgroundBlurStyle: The UIBlurEffectStyle to apply to the background when presenting
  public convenience init(image: UIImage, backgroundBlurStyle: UIBlurEffectStyle? = .dark) {
      self.init(image: image, imageUrl: nil, backgroundBlurStyle: backgroundBlurStyle)
  }

  /// Initialize with a single image url
  ///
  /// - Parameter imageUrl: The image url to present
  /// - Parameter backgroundBlurStyle: The UIBlurEffectStyle to apply to the background when presenting
  public convenience init(imageUrl: URL, backgroundBlurStyle: UIBlurEffectStyle? = .dark) {
      self.init(image: nil, imageUrl: imageUrl, backgroundBlurStyle: backgroundBlurStyle)
  }

  /// Initialize with a data source
  ///
  /// - Parameter dataSource: The `AgrumeDataSource` to use
  /// - Parameter startIndex: The optional start index when showing multiple images
  /// - Parameter backgroundBlurStyle: The UIBlurEffectStyle to apply to the background when presenting
	public convenience init(dataSource: AgrumeDataSource, startIndex: Int? = nil,
	                        backgroundBlurStyle: UIBlurEffectStyle? = .dark) {
		self.init(image: nil, images: nil, dataSource: dataSource, startIndex: startIndex,
		          backgroundBlurStyle: backgroundBlurStyle)
	}
	
  /// Initialize with an array of images
  ///
  /// - Parameter images: The images to present
  /// - Parameter startIndex: The optional start index when showing multiple images
  /// - Parameter backgroundBlurStyle: The UIBlurEffectStyle to apply to the background when presenting
  public convenience init(images: [UIImage], startIndex: Int? = nil, backgroundBlurStyle: UIBlurEffectStyle? = .dark) {
      self.init(image: nil, images: images, startIndex: startIndex, backgroundBlurStyle: backgroundBlurStyle)
  }

  /// Initialize with an array of image urls
  ///
  /// - Parameter imageUrls: The image urls to present
  /// - Parameter startIndex: The optional start index when showing multiple images
  /// - Parameter backgroundBlurStyle: The UIBlurEffectStyle to apply to the background when presenting
    public convenience init(imageUrls: [URL], startIndex: Int? = nil, backgroundBlurStyle: UIBlurEffectStyle? = .dark, delegate: ProfilePhotosActions?) {
        self.init(image: nil, imageUrls: imageUrls, startIndex: startIndex, backgroundBlurStyle: backgroundBlurStyle, delegate: delegate)
  }

	private init(image: UIImage? = nil, imageUrl: URL? = nil, images: [UIImage]? = nil,
	             dataSource: AgrumeDataSource? = nil, imageUrls: [URL]? = nil, startIndex: Int? = nil,
	             backgroundBlurStyle: UIBlurEffectStyle? = .dark, delegate: ProfilePhotosActions? = nil) {
    assert(backgroundBlurStyle != nil)
    self.images = images
    if let image = image {
      self.images = [image]
    }
    self.imageUrls = imageUrls
    if let imageURL = imageUrl {
      self.imageUrls = [imageURL]
    }
        self.delegate = delegate
		self.dataSource = dataSource
    self.startIndex = startIndex
    self.backgroundBlurStyle = backgroundBlurStyle!
    super.init(nibName: nil, bundle: nil)
    
    UIDevice.current.beginGeneratingDeviceOrientationNotifications()
    NotificationCenter.default.addObserver(self, selector: #selector(orientationDidChange),
                                           name: .UIDeviceOrientationDidChange, object: nil)
  }

  deinit {
    downloadTask?.cancel()
    UIDevice.current.endGeneratingDeviceOrientationNotifications()
    NotificationCenter.default.removeObserver(self)
  }

  required public init?(coder aDecoder: NSCoder) {
    fatalError("Not implemented")
  }

  private func frameForCurrentDeviceOrientation() -> CGRect {
    let bounds = view.bounds
    if UIDeviceOrientationIsLandscape(currentDeviceOrientation()) {
      if bounds.width / bounds.height > bounds.height / bounds.width {
        return bounds
      } else {
        return CGRect(origin: bounds.origin, size: CGSize(width: bounds.height, height: bounds.width))
      }
    }
    return bounds
  }

  private func currentDeviceOrientation() -> UIDeviceOrientation {
    return UIDevice.current.orientation
  }

  private var backgroundSnapshot: UIImage!
  private var backgroundImageView: UIImageView!
  fileprivate var _blurView: UIVisualEffectView?
  private var blurView: UIVisualEffectView {
    if _blurView == nil {
      let blurView = UIVisualEffectView(effect: UIBlurEffect(style: self.backgroundBlurStyle))
      blurView.frame = self.view.frame
      blurView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
      _blurView = blurView
    }
    return _blurView!
  }
    
  //MARK: - Collection view
  fileprivate var _collectionView: UICollectionView?
  fileprivate var collectionView: UICollectionView {
    if _collectionView == nil {
        
      let point = CGPoint.init(x: self.view.frame.origin.x, y: self.view.frame.origin.y + 75)
      let size = CGSize.init(width: self.view.frame.size.width, height: self.view.frame.size.height - 150)
        
      let layout = UICollectionViewFlowLayout()
      layout.minimumInteritemSpacing = 0
      layout.minimumLineSpacing = 0
      layout.scrollDirection = .horizontal
      layout.itemSize = size
        
      let collectionView = UICollectionView(frame: CGRect.init(origin: point, size: size), collectionViewLayout: layout)
      collectionView.register(AgrumeCell.self, forCellWithReuseIdentifier: Agrume.reuseIdentifier)
      collectionView.dataSource = self
      collectionView.delegate = self
      collectionView.isPagingEnabled = true
      collectionView.backgroundColor = .clear
      collectionView.delaysContentTouches = false
      collectionView.showsHorizontalScrollIndicator = false
      _collectionView = collectionView
    }
    return _collectionView!
  }
  fileprivate var _spinner: UIActivityIndicatorView?
  fileprivate var spinner: UIActivityIndicatorView {
    if _spinner == nil {
      let activityIndicatorStyle: UIActivityIndicatorViewStyle = self.backgroundBlurStyle == .dark ? .whiteLarge : .gray
      let spinner = UIActivityIndicatorView(activityIndicatorStyle: activityIndicatorStyle)
      spinner.center = self.view.center
      spinner.startAnimating()
      spinner.alpha = 0
      _spinner = spinner
    }
    return _spinner!
  }
    //MARK: - Close button
    fileprivate var _closeButton: UIButton?
    fileprivate var closeButton: UIButton {
        if _closeButton == nil {
            let button = UIButton.init()
            button.addTarget(self, action: "dismiss", for: .touchUpInside)
            let frame = CGRect.init(x: 12, y: 12+20, width: 40, height: 40) //20 points for status bar
            button.frame = frame
            button.backgroundColor = UIColor.white
            _closeButton = button
        }
        return _closeButton!
    }
    
    //MARK: - Submenu button
    fileprivate var _menuButton: UIButton?
    fileprivate var menuButton: UIButton {
        if _menuButton == nil {
            let button = UIButton.init()
            button.addTarget(self, action: "showMenu", for: .touchUpInside)
            let frame = CGRect.init(x: self.view.frame.size.width - 12 - 40, y: 12+20, width: 40, height: 40) //20 points for status bar
            button.frame = frame
            button.backgroundColor = UIColor.white
            _menuButton = button
        }
        return _menuButton!
    }
    
    //MARK: - Like button
    fileprivate var _likeButton: UIButton?
    fileprivate var likeButton: UIButton {
        if _likeButton == nil {
            let button = UIButton.init()
            button.addTarget(self, action: "dismiss", for: .touchUpInside)
            let frame = CGRect.init(x: 0, y: 0, width: 40, height: 40) //20 points for status bar
            button.frame = frame
            button.backgroundColor = UIColor.red
            _likeButton = button
        }
        return _likeButton!
    }
    
    //MARK: - Likes label
    fileprivate var _countLikesLabel: UILabel?
    fileprivate var countLikesLabel: UILabel {
        if _countLikesLabel == nil {
            let frame = CGRect.init(x: 45, y: 0, width: 60, height: 40)
            let label = UILabel(frame: frame)
            label.font = UIFont.boldSystemFont(ofSize: 13)
            label.textColor = UIColor.white
            label.text = "Int likes"
            _countLikesLabel = label
        }
        return _countLikesLabel!
    }
    
    //MARK: - Like button and label container
    fileprivate var _likesContainer: UIView?
    fileprivate var likesContainer: UIView {
        if _likesContainer == nil {
            let frame = CGRect(x: self.view.frame.width/2 - 52, y: self.view.frame.height - 75, width: 105, height: 40)
            let view = UIView.init(frame: frame)
            _likesContainer = view
        }
        return _likesContainer!
    }

  //MARK: - Submenu methods
    func showMenu() -> Void {
        let alertView = UIAlertController.init(title: "USERNAME", message: "DO SOME ACTIONS", preferredStyle: .actionSheet)
        let favoriteAction = UIAlertAction.init(title: "Favorite", style: .default, handler: nil)
        let blockAction = UIAlertAction.init(title: "Block", style: .default, handler: nil)
        let reportAction = UIAlertAction.init(title: "Report", style: .default, handler: nil)
        let cancel = UIAlertAction.init(title: "Cancel", style: UIAlertActionStyle.cancel, handler: nil)
        
        alertView.addAction(favoriteAction)
        alertView.addAction(blockAction)
        alertView.addAction(reportAction)
        alertView.addAction(cancel)
        
        present(alertView, animated: true, completion: nil)
    }
    
  fileprivate var downloadTask: URLSessionDataTask?
    
  override public func viewDidLoad() {
    super.viewDidLoad()
    view.autoresizingMask = [.flexibleHeight, .flexibleWidth]
  }
    
  private var lastUsedOrientation: UIDeviceOrientation?

  public override func viewWillAppear(_ animated: Bool) {
    lastUsedOrientation = currentDeviceOrientation()
  }

  fileprivate func deviceOrientationFromStatusBarOrientation() -> UIDeviceOrientation {
    return UIDeviceOrientation(rawValue: UIApplication.shared.statusBarOrientation.rawValue)!
  }

  fileprivate var initialOrientation: UIDeviceOrientation!

  public func showFrom(_ viewController: UIViewController, backgroundSnapshotVC: UIViewController? = nil) {
    backgroundSnapshot = (backgroundSnapshotVC ?? viewControllerForSnapshot(fromViewController: viewController))?.view.snapshot()
    view.frame = frameForCurrentDeviceOrientation()
    view.isUserInteractionEnabled = false
    addSubviews()
    initialOrientation = deviceOrientationFromStatusBarOrientation()
    updateLayoutsForCurrentOrientation()
    showFrom(viewController)
  }
  
  private func addSubviews() {
    view.addSubview(closeButton)
    view.addSubview(menuButton)
    likesContainer.addSubview(likeButton)
    likesContainer.addSubview(countLikesLabel)
    view.addSubview(likesContainer)
    view.addSubview(collectionView)
    if let index = startIndex {
      collectionView.scrollToItem(at: IndexPath(row: index, section: 0), at: [], animated: false)
    }
    view.addSubview(spinner)
  }
  
  private func showFrom(_ viewController: UIViewController) {
    DispatchQueue.main.async {
      self.collectionView.alpha = 0
        let point = CGPoint.init(x: self.view.frame.origin.x, y: self.view.frame.origin.y + 75)
        let size = CGSize.init(width: self.view.frame.size.width, height: self.view.frame.size.height - 150)
      self.collectionView.frame = CGRect.init(origin: point, size: size)
      let scaling = Agrume.initialScalingToExpandFrom
      self.collectionView.transform = CGAffineTransform(scaleX: scaling, y: scaling)
      
      viewController.present(self, animated: false) {
        UIView.animate(withDuration: Agrume.transitionAnimationDuration,
                       delay: 0,
                       options: .beginFromCurrentState,
                       animations: { [weak self] in
                        self?.collectionView.alpha = 1
                        self?.collectionView.transform = .identity
          }, completion: { [weak self] _ in
            self?.view.isUserInteractionEnabled = true
          })
      }
    }
  }

  fileprivate func viewControllerForSnapshot(fromViewController viewController: UIViewController) -> UIViewController? {
    var presentingVC = viewController.view.window?.rootViewController
    while presentingVC?.presentedViewController != nil {
      presentingVC = presentingVC?.presentedViewController
    }
    return presentingVC
  }

  public func dismiss() {
    self.dismissAfterFlick()
  }

  public func showImage(atIndex index : Int) {
    collectionView.scrollToItem(at: IndexPath(row: index, section: 0), at: [], animated: true)
  }

	public func reload() {
		DispatchQueue.main.async {
			self.collectionView.reloadData()
		}
	}

  // MARK: Rotation

  @objc private func orientationDidChange() {
    let orientation = currentDeviceOrientation()
    guard let lastOrientation = lastUsedOrientation else { return }
    let landscapeToLandscape = UIDeviceOrientationIsLandscape(orientation) && UIDeviceOrientationIsLandscape(lastOrientation)
    let portraitToPortrait = UIDeviceOrientationIsPortrait(orientation) && UIDeviceOrientationIsPortrait(lastOrientation)
    guard (landscapeToLandscape || portraitToPortrait) && orientation != lastUsedOrientation else { return }
    lastUsedOrientation = orientation
    UIView.animate(withDuration: 0.6) { [weak self] in
      self?.updateLayoutsForCurrentOrientation()
    }
  }

  public override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
    coordinator.animate(alongsideTransition: { [weak self] _ in
      self?.updateLayoutsForCurrentOrientation()
    }, completion: { [weak self] _ in
      self?.lastUsedOrientation = self?.deviceOrientationFromStatusBarOrientation()
    })
  }

  private func updateLayoutsForCurrentOrientation() {
    let transform = newTransform()

    //backgroundImageView.center = view.center
    //backgroundImageView.transform = transform.concatenating(CGAffineTransform(scaleX: 1, y: 1))

    spinner.center = view.center

    collectionView.performBatchUpdates({ [unowned self] in
      self.collectionView.collectionViewLayout.invalidateLayout()
      self.collectionView.frame = self.view.frame
      let width = self.collectionView.frame.width
      let page = Int((self.collectionView.contentOffset.x + (0.5 * width)) / width)
      let updatedOffset = CGFloat(page) * self.collectionView.frame.width
      self.collectionView.contentOffset = CGPoint(x: updatedOffset, y: self.collectionView.contentOffset.y)
      
      let layout = self.collectionView.collectionViewLayout as! UICollectionViewFlowLayout
      layout.itemSize = self.view.frame.size
      }, completion: { _ in
        for visibleCell in self.collectionView.visibleCells as! [AgrumeCell] {
          visibleCell.updateScrollViewAndImageViewForCurrentMetrics()
        }
    })
  }
  
  private func newTransform() -> CGAffineTransform {
    var transform: CGAffineTransform = .identity
    if initialOrientation == .portrait {
      switch (currentDeviceOrientation()) {
      case .landscapeLeft:
        transform = CGAffineTransform(rotationAngle: CGFloat(M_PI_2))
      case .landscapeRight:
        transform = CGAffineTransform(rotationAngle: CGFloat(-M_PI_2))
      case .portraitUpsideDown:
        transform = CGAffineTransform(rotationAngle: CGFloat(M_PI))
      default:
        break
      }
    } else if initialOrientation == .portraitUpsideDown {
      switch (currentDeviceOrientation()) {
      case .landscapeLeft:
        transform = CGAffineTransform(rotationAngle: CGFloat(-M_PI_2))
      case .landscapeRight:
        transform = CGAffineTransform(rotationAngle: CGFloat(M_PI_2))
      case .portrait:
        transform = CGAffineTransform(rotationAngle: CGFloat(M_PI))
      default:
        break
      }
    } else if initialOrientation == .landscapeLeft {
      switch (currentDeviceOrientation()) {
      case .landscapeRight:
        transform = CGAffineTransform(rotationAngle: CGFloat(M_PI))
      case .portrait:
        transform = CGAffineTransform(rotationAngle: CGFloat(-M_PI_2))
      case .portraitUpsideDown:
        transform = CGAffineTransform(rotationAngle: CGFloat(M_PI_2))
      default:
        break
      }
    } else if initialOrientation == .landscapeRight {
      switch (currentDeviceOrientation()) {
      case .landscapeLeft:
        transform = CGAffineTransform(rotationAngle: CGFloat(M_PI))
      case .portrait:
        transform = CGAffineTransform(rotationAngle: CGFloat(M_PI_2))
      case .portraitUpsideDown:
        transform = CGAffineTransform(rotationAngle: CGFloat(-M_PI_2))
      default:
        break
      }
    }
    return transform
  }

}

extension Agrume: UICollectionViewDataSource {

  public func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
    if let dataSource = dataSource {
      return dataSource.numberOfImages
    }
    if let images = images {
      return !images.isEmpty ? images.count : imageUrls.count
    }
    return imageUrls.count
  }

  public func collectionView(_ collectionView: UICollectionView,
                             cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
    downloadTask?.cancel()

    let cell = collectionView.dequeueReusableCell(withReuseIdentifier: Agrume.reuseIdentifier,
                                                  for: indexPath) as! AgrumeCell
    if let images = images {
      cell.image = images[indexPath.row]
    } else if let imageUrls = imageUrls {
      spinner.alpha = 1
      let completion: DownloadCompletion = { [weak self] image in
        cell.image = image
        self?.spinner.alpha = 0
      }

      if let download = download {
        download(imageUrls[indexPath.row], completion)
      } else if let download = AgrumeServiceLocator.shared.downloadHandler {
        download(imageUrls[indexPath.row], completion)
      } else {
        downloadImage(imageUrls[indexPath.row], completion: completion)
      }
		} else if let dataSource = dataSource {
			spinner.alpha = 1
			let index = indexPath.row
			
      dataSource.image(forIndex: index) { [weak self] image in
        DispatchQueue.main.async {
          if collectionView.indexPathsForVisibleItems.contains(indexPath) {
            cell.image = image
            self?.spinner.alpha = 0
          }
        }
      }
		}
    // Only allow panning if horizontal swiping fails. Horizontal swiping is only active for zoomed in images
    collectionView.panGestureRecognizer.require(toFail: cell.swipeGesture)
    cell.delegate = self
    return cell
  }

  private func downloadImage(_ url: URL, completion: @escaping DownloadCompletion) {
    downloadTask = ImageDownloader.downloadImage(url) { image in
      completion(image)
    }
  }

}

extension Agrume: UICollectionViewDelegate {

  public func collectionView(_ collectionView: UICollectionView, willDisplay cell: UICollectionViewCell,
                             forItemAt indexPath: IndexPath) {
    didScroll?(indexPath.row)
		
		if let dataSource = dataSource {
      let collectionViewCount = collectionView.numberOfItems(inSection: 0)
			let dataSourceCount = dataSource.numberOfImages
			
			guard !hasDataSourceCountChanged(dataSourceCount: dataSourceCount, collectionViewCount: collectionViewCount)
        else { return }
			
			if isIndexPathOutOfBounds(indexPath, count: dataSourceCount) {
				showImage(atIndex: dataSourceCount - 1)
				reload()
			} else if isLastElement(atIndexPath: indexPath, count: collectionViewCount - 1) {
				reload()
			}
		}
  }
  
  private func hasDataSourceCountChanged(dataSourceCount: Int, collectionViewCount: Int) -> Bool {
    return collectionViewCount == dataSourceCount
  }
  
  private func isIndexPathOutOfBounds(_ indexPath: IndexPath, count: Int) -> Bool {
    return indexPath.item >= count
  }
  
  private func isLastElement(atIndexPath indexPath: IndexPath, count: Int) -> Bool {
    return indexPath.item == count
  }

}

extension Agrume: AgrumeCellDelegate {
  
  private func dismissCompletion(_ finished: Bool) {
    presentingViewController?.dismiss(animated: false) { [unowned self] in
      self.cleanup()
      self.didDismiss?()
    }
  }
  
  private func cleanup() {
    _blurView = nil
    _collectionView?.removeFromSuperview()
    _collectionView = nil
    _spinner?.removeFromSuperview()
    _spinner = nil
    _closeButton?.removeFromSuperview()
    _closeButton = nil
    _menuButton?.removeFromSuperview()
    _menuButton = nil
    _likeButton?.removeFromSuperview()
    _likeButton = nil
    _countLikesLabel?.removeFromSuperview()
    _countLikesLabel = nil
    _likesContainer?.removeFromSuperview()
    _likesContainer = nil
  }

  func dismissAfterFlick() {
    UIView.animate(withDuration: Agrume.transitionAnimationDuration,
                   delay: 0,
                   options: .beginFromCurrentState,
                   animations: { [unowned self] in
                    self.collectionView.alpha = 0
      }, completion: dismissCompletion)
  }
  
  func dismissAfterTap() {
    view.isUserInteractionEnabled = false
    
    UIView.animate(withDuration: Agrume.transitionAnimationDuration,
                   delay: 0,
                   options: .beginFromCurrentState,
                   animations: { [unowned self] in
                    self.collectionView.alpha = 0
                    let scaling = Agrume.maxScalingForExpandingOffscreen
                    self.collectionView.transform = CGAffineTransform(scaleX: scaling, y: scaling)
      }, completion: dismissCompletion)
  }
}

extension Agrume {
  
  // MARK: Status Bar

  public override var preferredStatusBarStyle:  UIStatusBarStyle {
    return statusBarStyle ?? super.preferredStatusBarStyle
  }
  
}
