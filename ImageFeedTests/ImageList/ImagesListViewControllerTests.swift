import XCTest
@testable import ImageFeed

final class ImagesListViewControllerTests: XCTestCase {

    private var sut: TestableImagesListViewController!
    private var presenterSpy: ImagesListPresenterSpy!

    override func setUp() {
        super.setUp()
        sut = TestableImagesListViewController()
        presenterSpy = ImagesListPresenterSpy()
        sut.configure(presenter: presenterSpy)
    }

    override func tearDown() {
        sut = nil
        presenterSpy = nil
        super.tearDown()
    }

    func testViewDidLoadSetsTableViewDelegatesAndNotifiesPresenter() {
        sut.loadViewIfNeeded()

        XCTAssertTrue(presenterSpy.viewDidLoadCalled, "Presenter should be notified on viewDidLoad.")
        XCTAssertTrue(sut.tableViewSpy.dataSource === sut)
        XCTAssertTrue(sut.tableViewSpy.delegate === sut)
    }

    func testNumberOfRowsReturnsPresenterCount() {
        presenterSpy.imagesCount = 3
        sut.loadViewIfNeeded()

        let rows = sut.tableView(sut.tableViewSpy, numberOfRowsInSection: 0)
        XCTAssertEqual(rows, 3)
    }

    func testCellForRowRequestsConfigurationFromPresenter() {
        presenterSpy.imagesCount = 1
        sut.loadViewIfNeeded()

        let indexPath = IndexPath(row: 0, section: 0)
        let cellSpy = ImagesListCellSpy(style: .default, reuseIdentifier: ImagesListCell.reuseIdentifier)
        sut.tableViewSpy.cellProvider = { _ in cellSpy }

        _ = sut.tableView(sut.tableViewSpy, cellForRowAt: indexPath)

        XCTAssertEqual(presenterSpy.configureCallCount, 1)
        XCTAssertEqual(presenterSpy.lastConfigureIndexPath, indexPath)
        XCTAssertTrue(presenterSpy.lastConfigureDelegate === sut)
    }

    func testWillDisplayCellNotifiesPresenter() {
        sut.loadViewIfNeeded()
        let indexPath = IndexPath(row: 0, section: 0)

        sut.tableView(sut.tableViewSpy, willDisplay: UITableViewCell(), forRowAt: indexPath)

        XCTAssertEqual(presenterSpy.lastWillDisplayIndexPath, indexPath)
    }

    func testHeightForRowUsesPresenterValue() {
        presenterSpy.heightForRowStub = 256
        sut.loadViewIfNeeded()
        let indexPath = IndexPath(row: 0, section: 0)

        let height = sut.tableView(sut.tableViewSpy, heightForRowAt: indexPath)

        XCTAssertEqual(height, 256)
        XCTAssertEqual(presenterSpy.lastHeightRequestIndexPath, indexPath)
    }

    func testImagesListCellDidTapLikeDelegatesToPresenter() {
        sut.loadViewIfNeeded()
        let indexPath = IndexPath(row: 0, section: 0)
        let cell = ImagesListCellSpy(style: .default, reuseIdentifier: nil)
        sut.tableViewSpy.store(cell: cell, at: indexPath)

        sut.imagesListCellDidTapLike(cell)

        XCTAssertEqual(presenterSpy.lastDidTapLikeIndexPath, indexPath)
    }

    func testPrepareForSegueSetsImageURLFromPresenter() {
        sut.loadViewIfNeeded()
        let destination = SingleImageViewControllerStub()
        let segue = UIStoryboardSegue(identifier: "ShowSingleImage", source: sut, destination: destination) {}
        let expectedURL = URL(string: "https://example.com/photo")!
        presenterSpy.imageURLStub = expectedURL
        let indexPath = IndexPath(row: 2, section: 0)

        sut.prepare(for: segue, sender: indexPath)

        XCTAssertEqual(destination.imageURL, expectedURL)
        XCTAssertEqual(presenterSpy.lastImageURLRequestIndexPath, indexPath)
    }

    func testApplyUpdatesWithSmallerCountReloadData() {
        sut.loadViewIfNeeded()

        sut.applyUpdates(oldCount: 5, newCount: 2)

        XCTAssertTrue(sut.tableViewSpy.reloadDataCalled)
    }

    func testApplyUpdatesWithGrowingCountInsertsRows() {
        sut.loadViewIfNeeded()

        sut.applyUpdates(oldCount: 1, newCount: 3)

        XCTAssertEqual(sut.tableViewSpy.insertedIndexPaths, [IndexPath(row: 1, section: 0), IndexPath(row: 2, section: 0)])
    }

    func testApplyLikeUpdateUpdatesVisibleCell() {
        sut.loadViewIfNeeded()
        let cell = ImagesListCellSpy(style: .default, reuseIdentifier: nil)
        sut.tableViewSpy.store(cell: cell, at: IndexPath(row: 0, section: 0))

        sut.applyLikeUpdate(at: 0, isLiked: true)

        XCTAssertEqual(cell.isLikedValues.last, true)
    }

    func testSetLikeButtonEnabledUpdatesCellState() {
        sut.loadViewIfNeeded()
        let cell = ImagesListCellSpy(style: .default, reuseIdentifier: nil)
        sut.tableViewSpy.store(cell: cell, at: IndexPath(row: 0, section: 0))

        sut.setLikeButtonEnabled(false, at: 0)

        XCTAssertEqual(cell.likeButtonEnabledValues.last, false)
    }

    func testShowLikeErrorPresentsAlert() {
        sut.loadViewIfNeeded()

        sut.showLikeError()

        XCTAssertTrue(sut.presentedController is UIAlertController)
    }
}

// MARK: - Test Doubles

private final class TestableImagesListViewController: ImagesListViewController {
    let tableViewSpy = TableViewSpy()
    private(set) var presentedController: UIViewController?

    override func loadView() {
        view = UIView()
        view.backgroundColor = .systemBackground

        tableViewSpy.frame = view.bounds
        view.addSubview(tableViewSpy)
        setValue(tableViewSpy, forKey: "tableView")
    }

    override func present(_ viewControllerToPresent: UIViewController, animated flag: Bool, completion: (() -> Void)? = nil) {
        presentedController = viewControllerToPresent
        completion?()
    }
}

private final class TableViewSpy: UITableView {
    var reloadDataCalled = false
    var insertedIndexPaths: [IndexPath] = []
    var storedCells: [IndexPath: UITableViewCell] = [:]
    var cellProvider: ((IndexPath) -> UITableViewCell)?

    override func reloadData() {
        reloadDataCalled = true
    }

    override func performBatchUpdates(_ updates: (() -> Void)?, completion: ((Bool) -> Void)? = nil) {
        updates?()
        completion?(true)
    }

    override func insertRows(at indexPaths: [IndexPath], with animation: UITableView.RowAnimation) {
        insertedIndexPaths.append(contentsOf: indexPaths)
    }

    override func dequeueReusableCell(withIdentifier identifier: String, for indexPath: IndexPath) -> UITableViewCell {
        cellProvider?(indexPath) ?? UITableViewCell(style: .default, reuseIdentifier: identifier)
    }

    override func cellForRow(at indexPath: IndexPath) -> UITableViewCell? {
        storedCells[indexPath]
    }

    override func indexPath(for cell: UITableViewCell) -> IndexPath? {
        storedCells.first(where: { $0.value === cell })?.key
    }

    func store(cell: UITableViewCell, at indexPath: IndexPath) {
        storedCells[indexPath] = cell
    }
}

final class ImagesListPresenterSpy: ImagesListPresenterProtocol {
    var imagesCount = 0
    private(set) var viewDidLoadCalled = false
    private(set) var configureCallCount = 0
    private(set) var lastConfigureIndexPath: IndexPath?
    private(set) var lastConfigureDelegate: ImagesListCellDelegate?
    private(set) var lastWillDisplayIndexPath: IndexPath?
    private(set) var lastHeightRequestIndexPath: IndexPath?
    private(set) var lastDidTapLikeIndexPath: IndexPath?
    private(set) var lastImageURLRequestIndexPath: IndexPath?

    var imageURLStub: URL?
    var heightForRowStub: CGFloat = 44

    func viewDidLoad() {
        viewDidLoadCalled = true
    }

    func configure(cell: ImagesListCell, at indexPath: IndexPath, delegate: ImagesListCellDelegate) {
        configureCallCount += 1
        lastConfigureIndexPath = indexPath
        lastConfigureDelegate = delegate
    }

    func heightForRow(at indexPath: IndexPath, tableWidth: CGFloat) -> CGFloat {
        lastHeightRequestIndexPath = indexPath
        return heightForRowStub
    }

    func didSelectRow(at indexPath: IndexPath) {
        // no-op
    }

    func imageURL(for indexPath: IndexPath) -> URL? {
        lastImageURLRequestIndexPath = indexPath
        return imageURLStub
    }

    func willDisplayCell(at indexPath: IndexPath) {
        lastWillDisplayIndexPath = indexPath
    }

    func didTapLike(at indexPath: IndexPath) {
        lastDidTapLikeIndexPath = indexPath
    }
}

private final class ImagesListCellSpy: ImagesListCell {
    private(set) var isLikedValues: [Bool] = []
    private(set) var likeButtonEnabledValues: [Bool] = []

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
    }

    override func setIsLiked(_ isLiked: Bool) {
        isLikedValues.append(isLiked)
    }

    override func setLikeButtonEnabled(_ enabled: Bool) {
        likeButtonEnabledValues.append(enabled)
    }
}

private final class SingleImageViewControllerStub: SingleImageViewController {
    override init(nibName nibNameOrNil: String?, bundle nibBundleOrNil: Bundle?) {
        super.init(nibName: nibNameOrNil, bundle: nibBundleOrNil)
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
    }
}

