import UIKit

protocol ImagesListView: AnyObject {
    func applyUpdates(oldCount: Int, newCount: Int)
    func applyLikeUpdate(at index: Int, isLiked: Bool)
    func setLikeButtonEnabled(_ isEnabled: Bool, at index: Int)
    func showBlockingProgress()
    func hideBlockingProgress()
    func showLikeError()
}

protocol ImagesListPresenterProtocol: AnyObject {
    var imagesCount: Int { get }
    func viewDidLoad()
    func configure(cell: ImagesListCell, at indexPath: IndexPath, delegate: ImagesListCellDelegate)
    func heightForRow(at indexPath: IndexPath, tableWidth: CGFloat) -> CGFloat
    func didSelectRow(at indexPath: IndexPath)
    func imageURL(for indexPath: IndexPath) -> URL?
    func willDisplayCell(at indexPath: IndexPath)
    func didTapLike(at indexPath: IndexPath)
}

final class ImagesListPresenter: ImagesListPresenterProtocol {

    private weak var view: ImagesListView?
    private let imagesListService: ImagesListService
    private let notificationCenter: NotificationCenter

    private var photos: [Photo] = []
    private var imageServiceObserver: NSObjectProtocol?

    private lazy var dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .long
        formatter.timeStyle = .none
        return formatter
    }()

    init(view: ImagesListView,
         imagesListService: ImagesListService = .shared,
         notificationCenter: NotificationCenter = .default) {
        self.view = view
        self.imagesListService = imagesListService
        self.notificationCenter = notificationCenter
    }

    deinit {
        if let observer = imageServiceObserver {
            notificationCenter.removeObserver(observer)
        }
    }

    // MARK: - Lifecycle

    func viewDidLoad() {
        photos = imagesListService.photos
        observeServiceUpdates()
        fetchNextPage()
    }

    // MARK: - Public API

    var imagesCount: Int {
        photos.count
    }

    func configure(cell: ImagesListCell, at indexPath: IndexPath, delegate: ImagesListCellDelegate) {
        guard photos.indices.contains(indexPath.row) else { return }
        let photo = photos[indexPath.row]
        cell.delegate = delegate
        cell.configure(with: photo, dateFormatter: dateFormatter)
    }

    func heightForRow(at indexPath: IndexPath, tableWidth: CGFloat) -> CGFloat {
        guard photos.indices.contains(indexPath.row) else { return UITableView.automaticDimension }
        let photo = photos[indexPath.row]
        let insets = UIEdgeInsets(top: 4, left: 16, bottom: 4, right: 16)
        let imageViewWidth = tableWidth - insets.left - insets.right
        let scale = imageViewWidth / max(photo.size.width, 1)
        return photo.size.height * scale + insets.top + insets.bottom
    }

    func didSelectRow(at indexPath: IndexPath) {
        // no-op; selection handled via segue
    }

    func imageURL(for indexPath: IndexPath) -> URL? {
        guard photos.indices.contains(indexPath.row) else { return nil }
        return URL(string: photos[indexPath.row].fullImageURL)
    }

    func willDisplayCell(at indexPath: IndexPath) {
        guard indexPath.row + 1 == photos.count else { return }
        fetchNextPage()
    }

    func didTapLike(at indexPath: IndexPath) {
        guard photos.indices.contains(indexPath.row) else { return }
        let photo = photos[indexPath.row]
        let newLike = !photo.isLiked

        view?.showBlockingProgress()
        view?.setLikeButtonEnabled(false, at: indexPath.row)

        imagesListService.changeLike(photoId: photo.id, isLike: newLike) { [weak self] result in
            guard let self else { return }
            DispatchQueue.main.async {
                switch result {
                case .success:
                    break
                case .failure:
                    self.view?.hideBlockingProgress()
                    self.view?.setLikeButtonEnabled(true, at: indexPath.row)
                    self.view?.applyLikeUpdate(at: indexPath.row, isLiked: photo.isLiked)
                    self.view?.showLikeError()
                }
            }
        }
    }

    // MARK: - Private

    private func fetchNextPage() {
        imagesListService.fetchPhotosNextPage()
    }

    private func observeServiceUpdates() {
        imageServiceObserver = notificationCenter.addObserver(
            forName: ImagesListService.didChangeNotification,
            object: imagesListService,
            queue: .main
        ) { [weak self] note in
            self?.handleServiceUpdate(note)
        }
    }

    private func handleServiceUpdate(_ note: Notification) {
        if let updatedIndex = note.userInfo?["updatedIndex"] as? Int {
            photos = imagesListService.photos
            guard photos.indices.contains(updatedIndex) else { return }
            view?.applyLikeUpdate(at: updatedIndex, isLiked: photos[updatedIndex].isLiked)
            view?.setLikeButtonEnabled(true, at: updatedIndex)
            view?.hideBlockingProgress()
            return
        }

        let oldCount = photos.count
        photos = imagesListService.photos
        view?.applyUpdates(oldCount: oldCount, newCount: photos.count)
    }
}

