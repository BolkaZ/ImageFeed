import UIKit

class ImagesListViewController: UIViewController {
    private let showSingleImageIdentifier = "ShowSingleImage"
    
    @IBOutlet private var tableView: UITableView!
    
    private var presenter: ImagesListPresenterProtocol?
    
    // MARK: - Configuration
    func configure(presenter: ImagesListPresenterProtocol) {
        self.presenter = presenter
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()

        tableView.dataSource = self
        tableView.delegate = self
        tableView.rowHeight = UITableView.automaticDimension
        tableView.estimatedRowHeight = 200
        tableView.contentInset = UIEdgeInsets(top: 12, left: 0, bottom: 12, right: 0)

        if presenter == nil {
            presenter = ImagesListPresenter(view: self)
        }
        presenter?.viewDidLoad()
    }

    // MARK: - Segue
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == showSingleImageIdentifier {
            guard
                let vc = segue.destination as? SingleImageViewController,
                let indexPath = sender as? IndexPath
            else {
                assertionFailure("Invalid segue destination")
                return
            }
            vc.imageURL = presenter?.imageURL(for: indexPath)
        } else {
            super.prepare(for: segue, sender: sender)
        }
    }
}

// MARK: - UITableViewDataSource
extension ImagesListViewController: UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        presenter?.imagesCount ?? 0
    }

    func tableView(_ tableView: UITableView,
                   cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(
            withIdentifier: ImagesListCell.reuseIdentifier,
            for: indexPath
        ) as? ImagesListCell else {
            return UITableViewCell()
        }

        presenter?.configure(cell: cell, at: indexPath, delegate: self)
        return cell
    }
}

// MARK: - UITableViewDelegate
extension ImagesListViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        performSegue(withIdentifier: showSingleImageIdentifier, sender: indexPath)
    }

    func tableView(_ tableView: UITableView,
                   willDisplay cell: UITableViewCell,
                   forRowAt indexPath: IndexPath) {
        presenter?.willDisplayCell(at: indexPath)
    }

    func tableView(_ tableView: UITableView,
                   heightForRowAt indexPath: IndexPath) -> CGFloat {
        presenter?.heightForRow(at: indexPath, tableWidth: tableView.bounds.width)
        ?? UITableView.automaticDimension
    }
}

// MARK: - ImagesListCellDelegate
extension ImagesListViewController: ImagesListCellDelegate {
    func imagesListCellDidTapLike(_ cell: ImagesListCell) {
        guard let indexPath = tableView.indexPath(for: cell),
              tableView.cellForRow(at: indexPath) != nil else { return }

        presenter?.didTapLike(at: indexPath)
    }
}

// MARK: - ImagesListView

extension ImagesListViewController: ImagesListView {
    func applyUpdates(oldCount: Int, newCount: Int) {
        if newCount < oldCount {
            tableView.reloadData()
            return
        }
        guard newCount > oldCount else { return }
        let toInsert = (oldCount..<newCount).map { IndexPath(row: $0, section: 0) }
        tableView.performBatchUpdates({
            tableView.insertRows(at: toInsert, with: .automatic)
        })
    }

    func applyLikeUpdate(at index: Int, isLiked: Bool) {
        let indexPath = IndexPath(row: index, section: 0)
        if let cell = tableView.cellForRow(at: indexPath) as? ImagesListCell {
            cell.setIsLiked(isLiked)
        }
    }

    func setLikeButtonEnabled(_ isEnabled: Bool, at index: Int) {
        let indexPath = IndexPath(row: index, section: 0)
        if let cell = tableView.cellForRow(at: indexPath) as? ImagesListCell {
            cell.setLikeButtonEnabled(isEnabled)
        }
    }

    func showBlockingProgress() {
        UIBlockingProgressHUD.show()
    }

    func hideBlockingProgress() {
        UIBlockingProgressHUD.dismiss()
    }

    func showLikeError() {
        let alert = UIAlertController(
            title: "Не удалось поставить лайк",
            message: "Повторите попытку позже.",
            preferredStyle: .alert
        )
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        present(alert, animated: true)
    }
}
