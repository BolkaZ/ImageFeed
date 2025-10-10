import Foundation
import UIKit

class SingleImageViewController: UIViewController {
    var image: UIImage? {
        didSet {
            guard isViewLoaded else { return }
            imageView.image = image
        }
    }
    
    @IBOutlet var scrollView: UIScrollView!
    @IBOutlet var imageView: UIImageView!
    
    @IBAction private func didTapBackButton() {
        dismiss(animated: true, completion: nil)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        guard let image else { return }
        imageView.image = image
        imageView.frame.size = image.size 
        
        scrollView.delegate = self
        
        scrollView.minimumZoomScale = 0.1
        scrollView.maximumZoomScale = 1.25
    }
}

extension SingleImageViewController: UIScrollViewDelegate {
    func viewForZooming(in scrollView: UIScrollView) -> UIView? {
        return imageView
    }
}
