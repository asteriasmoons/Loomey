//
//  RediumEPUBReaderView.swift
//  Lumey
//

import SwiftUI
import SwiftData
import UIKit
import WebKit
import ReadiumShared
import ReadiumStreamer
import ReadiumNavigator

typealias ReadiumLink = ReadiumShared.Link

struct ReadiumEPUBReaderView: UIViewControllerRepresentable {
    let fileURL: URL
    let bookID: UUID
    let onClose: () -> Void
    let onProgressChanged: ((String) -> Void)?
    @AppStorage("lumey.reader.lastLocationJSON") private var storedLocationJSON: String = ""
    let initialLocationJSON: String?
    @Environment(\.modelContext) private var modelContext

    func makeCoordinator() -> Coordinator {
        Coordinator(
            fileURL: fileURL,
            bookID: bookID,
            modelContext: modelContext,
            onClose: onClose,
            onProgressChanged: onProgressChanged,
            initialLocationJSON: initialLocationJSON ?? storedLocationJSON
        )
    }

    func makeUIViewController(context: Context) -> UINavigationController {
        let themeBackground = context.coordinator.resolvedThemeBackground()

        let loadingController = ReadiumLoadingViewController(backgroundColor: themeBackground)

        let navigationController = UINavigationController()
        navigationController.viewControllers = [loadingController]
        navigationController.view.backgroundColor = themeBackground

        navigationController.setNavigationBarHidden(true, animated: false)

        loadingController.loadViewIfNeeded()

        DispatchQueue.main.async {
            Task { @MainActor in
                await Task.yield()

                await context.coordinator.openPublication(
                    in: navigationController,
                    loadingController: loadingController
                )
            }
        }

        return navigationController
    }

    func updateUIViewController(_ uiViewController: UINavigationController, context: Context) {}

    final class Coordinator: NSObject {
        private let fileURL: URL
        private let bookID: UUID
        private let modelContext: ModelContext
        private let onClose: () -> Void
        private let onProgressChanged: ((String) -> Void)?
        private let initialLocationJSON: String?

        private let httpClient = DefaultHTTPClient()
        private lazy var assetRetriever = AssetRetriever(httpClient: httpClient)
        private lazy var publicationOpener = PublicationOpener(
            parser: DefaultPublicationParser(
                httpClient: httpClient,
                assetRetriever: assetRetriever,
                pdfFactory: DefaultPDFDocumentFactory()
            )
        )

        private var securityScopedAccess = false
        private var navigatorDelegate: ReadiumNavigatorDelegateBridge?
        private weak var chromeController: ReadiumReaderChromeViewController?

        init(
            fileURL: URL,
            bookID: UUID,
            modelContext: ModelContext,
            onClose: @escaping () -> Void,
            onProgressChanged: ((String) -> Void)?,
            initialLocationJSON: String?
        ) {
            self.fileURL = fileURL
            self.bookID = bookID
            self.modelContext = modelContext
            self.onClose = onClose
            self.onProgressChanged = onProgressChanged
            self.initialLocationJSON = initialLocationJSON
        }

        deinit {
            if securityScopedAccess {
                fileURL.stopAccessingSecurityScopedResource()
            }
        }

        func resolvedThemeBackground() -> UIColor {
            let descriptor = FetchDescriptor<ReaderSettings>()
            let settings = (try? modelContext.fetch(descriptor))?.first
            return (settings?.theme ?? .cocoa).backgroundColor
        }

        @MainActor
        func openPublication(
            in navigationController: UINavigationController,
            loadingController: ReadiumLoadingViewController
        ) async {
            let overallStart = CFAbsoluteTimeGetCurrent()
            print("[EPUB Reader] Starting open for:", fileURL.lastPathComponent)

            securityScopedAccess = fileURL.startAccessingSecurityScopedResource()

            guard let readiumFileURL = fileURL.fileURL else {
                loadingController.showError("Lumey could not read this EPUB file URL.")
                return
            }

            let retrieveStart = CFAbsoluteTimeGetCurrent()
            let assetResult = await assetRetriever.retrieve(url: readiumFileURL)
            print("[EPUB Reader] Asset retrieval took", String(format: "%.2f", CFAbsoluteTimeGetCurrent() - retrieveStart), "seconds")

            switch assetResult {
            case .success(let asset):
                let publicationStart = CFAbsoluteTimeGetCurrent()
                let publicationResult = await publicationOpener.open(
                    asset: asset,
                    allowUserInteraction: true,
                    sender: loadingController
                )
                print("[EPUB Reader] Publication open took", String(format: "%.2f", CFAbsoluteTimeGetCurrent() - publicationStart), "seconds")

                switch publicationResult {
                case .success(let publication):
                    print("[EPUB Reader] Publication ready after", String(format: "%.2f", CFAbsoluteTimeGetCurrent() - overallStart), "seconds")

                    let navigatorStart = CFAbsoluteTimeGetCurrent()
                    await showNavigator(
                        publication: publication,
                        in: navigationController,
                        loadingController: loadingController
                    )
                    print("[EPUB Reader] Navigator setup took", String(format: "%.2f", CFAbsoluteTimeGetCurrent() - navigatorStart), "seconds")
                    print("[EPUB Reader] Total reader setup time", String(format: "%.2f", CFAbsoluteTimeGetCurrent() - overallStart), "seconds")

                case .failure(let error):
                    loadingController.showError("Lumey could not open this EPUB.\n\n\(String(describing: error))")
                }

            case .failure(let error):
                loadingController.showError("Lumey could not load this EPUB.\n\n\(String(describing: error))")
            }
        }

        @MainActor
        private func showNavigator(
            publication: Publication,
            in navigationController: UINavigationController,
            loadingController: ReadiumLoadingViewController
        ) async {
            do {
                loadingController.showLoading(
                    title: "Opening Reader",
                    subtitle: "Laying out the book..."
                )

                await Task.yield()

                let initialLocation = initialLocationJSON.flatMap { try? Locator(jsonString: $0) }
                let navigatorCreationStart = CFAbsoluteTimeGetCurrent()

                var config = EPUBNavigatorViewController.Configuration()
                config.editingActions = EditingAction.defaultActions + [
                    EditingAction(title: "Highlight", action: #selector(ReadiumReaderChromeViewController.highlightSelection(_:))),
                    EditingAction(title: "Quote", action: #selector(ReadiumReaderChromeViewController.quoteSelection(_:))),
                    EditingAction(title: "Add Note", action: #selector(ReadiumReaderChromeViewController.addNoteToSelection(_:)))
                ]
                config.fontFamilyDeclarations = bundledReaderFontDeclarations()
                if usesIPadReaderLayout {
                    config.readiumCSSRSProperties = iPadReadiumCSSProperties()
                }

                let navigator = try EPUBNavigatorViewController(
                    publication: publication,
                    initialLocation: initialLocation,
                    config: config
                )
                print("[EPUB Reader] Navigator creation took", String(format: "%.2f", CFAbsoluteTimeGetCurrent() - navigatorCreationStart), "seconds")

                let delegateBridge = ReadiumNavigatorDelegateBridge(
                    onClose: onClose,
                    onProgressChanged: onProgressChanged,
                    initialLocationJSON: initialLocationJSON
                )

                navigatorDelegate = delegateBridge
                navigator.delegate = delegateBridge

                let chromeController = ReadiumReaderChromeViewController(
                    navigator: navigator,
                    publication: publication,
                    bookID: bookID,
                    modelContext: modelContext,
                    onClose: onClose
                )
                self.chromeController = chromeController
                delegateBridge.onReadingLocationChanged = { [weak chromeController] locator in
                    chromeController?.updateLocationLabel(for: locator)
                    chromeController?.hideReaderLoadingOverlay()
                    chromeController?.updateBookmarkIndicator()
                }
                delegateBridge.onBookmarkRequested = { [weak chromeController] locator in
                    chromeController?.storeBookmark(locator)
                }

                let presentationStart = CFAbsoluteTimeGetCurrent()
                navigationController.setViewControllers([chromeController], animated: true)
                print("[EPUB Reader] Reader presentation took", String(format: "%.2f", CFAbsoluteTimeGetCurrent() - presentationStart), "seconds")

                Task { @MainActor in
                    await Task.yield()
                    chromeController.applyAllHighlightDecorations()
                }

                // Fallback: dismiss the overlay after 2s if locationDidChange hasn't fired yet
                Task { @MainActor in
                    try? await Task.sleep(nanoseconds: 2_000_000_000)
                    chromeController.hideReaderLoadingOverlay()
                }
            } catch {
                loadingController.showError("Lumey could not start the EPUB reader.\n\n\(error.localizedDescription)")
            }
        }

        private func bundledReaderFontDeclarations() -> [AnyHTMLFontFamilyDeclaration] {
            [
                bundledReaderFontDeclaration(fontFamily: "Hachi Maru Pop", resourceName: "HachiMaruPop-Regular"),
                bundledReaderFontDeclaration(fontFamily: "Montserrat", resourceName: "Montserrat-Regular"),
                bundledReaderFontDeclaration(fontFamily: "Quicksand", resourceName: "Quicksand-Regular")
            ].compactMap { $0 }
        }

        private func bundledReaderFontDeclaration(
            fontFamily: String,
            resourceName: String
        ) -> AnyHTMLFontFamilyDeclaration? {
            guard
                let url = Bundle.main.url(forResource: resourceName, withExtension: "ttf"),
                let fileURL = FileURL(url: url)
            else {
                return nil
            }

            return CSSFontFamilyDeclaration(
                fontFamily: FontFamily(rawValue: fontFamily),
                fontFaces: [
                    CSSFontFace(
                        file: fileURL,
                        style: .normal,
                        weight: .standard(.normal)
                    )
                ]
            ).eraseToAnyHTMLFontFamilyDeclaration()
        }

        private var usesIPadReaderLayout: Bool {
            UIDevice.current.userInterfaceIdiom == .pad
        }

        private func iPadReadiumCSSProperties() -> CSSRSProperties {
            CSSRSProperties(
                colCount: .one,
                colGap: CSSPxLength(0),
                pageGutter: CSSPxLength(28),
                maxLineLength: CSSRemLength(200)
            )
        }
    }
}

@MainActor
final class ReadiumNavigatorDelegateBridge: NSObject, EPUBNavigatorDelegate {
    private let onClose: () -> Void
    private let onProgressChanged: ((String) -> Void)?
    private let initialLocationJSON: String?
    var onReadingLocationChanged: ((Locator) -> Void)?
    var onBookmarkRequested: ((Locator) -> Void)?

    init(
        onClose: @escaping () -> Void,
        onProgressChanged: ((String) -> Void)?,
        initialLocationJSON: String?
    ) {
        self.onClose = onClose
        self.onProgressChanged = onProgressChanged
        self.initialLocationJSON = initialLocationJSON
    }

    func navigator(_ navigator: Navigator, locationDidChange locator: Locator) {
        if let jsonString = try? locator.jsonString() {
            UserDefaults.standard.set(jsonString, forKey: "lumey.reader.lastLocationJSON")
            onProgressChanged?(jsonString)
        }

        onReadingLocationChanged?(locator)
    }

    func navigator(_ navigator: Navigator, didJumpTo locator: Locator) {
        if let jsonString = try? locator.jsonString() {
            UserDefaults.standard.set(jsonString, forKey: "lumey.reader.lastLocationJSON")
            onProgressChanged?(jsonString)
        }

        onReadingLocationChanged?(locator)
    }

    func navigator(_ navigator: Navigator, presentError error: NavigatorError) {
        print("Readium navigator error: \(error)")
    }

    func navigator(_ navigator: Navigator, didFailToLoadResourceAt href: RelativeURL, withError error: ReadError) {
        print("Readium failed to load resource at \(href): \(error)")
    }
}

final class ReadiumReaderChromeViewController: UIViewController {
    private let navigator: EPUBNavigatorViewController
    private let publication: Publication
    private let bookID: UUID
    private let modelContext: ModelContext
    private let onClose: () -> Void

    private let topBar = UIView()
    private let bottomBar = UIView()
    private let locationLabel = UILabel()
    private let readerLoadingOverlay = UIView()
    private let readerLoadingSpinner = UIActivityIndicatorView(style: .large)
    private let readerLoadingTitle = UILabel()
    private let readerLoadingSubtitle = UILabel()
    private var barsAreHidden = false
    private let topGradientLayer = CAGradientLayer()
    private let bottomGradientLayer = CAGradientLayer()
    private var cachedPositions: [Locator] = []
    private var effectiveTotalPages: Int = 0
    private var displayedPage: Int = 1
    private var previousTotalProgression: Double?
    private let bookmarkIndicator: UIImageView = {
        let imageView = UIImageView(image: UIImage(named: "bookmark")?.withRenderingMode(.alwaysTemplate))
        imageView.tintColor = .white
        imageView.contentMode = .scaleAspectFit
        imageView.translatesAutoresizingMaskIntoConstraints = false
        imageView.isHidden = true
        imageView.alpha = 0
        imageView.layer.shadowColor = UIColor.black.cgColor
        imageView.layer.shadowOpacity = 0.34
        imageView.layer.shadowRadius = 5
        imageView.layer.shadowOffset = CGSize(width: 0, height: 2)
        return imageView
    }()

    private var currentSettings: ReaderSettings?
    
    init(
        navigator: EPUBNavigatorViewController,
        publication: Publication,
        bookID: UUID,
        modelContext: ModelContext,
        onClose: @escaping () -> Void
    ) {
        self.navigator = navigator
        self.publication = publication
        self.bookID = bookID
        self.modelContext = modelContext
        self.onClose = onClose
        super.init(nibName: nil, bundle: nil)
        
        loadOrCreateSettings()
    }

    required init?(coder: NSCoder) {
        nil
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        // Use theme color immediately — never hardcoded black
        let themeColor = currentSettings?.theme.backgroundColor ?? UIColor(red: 0.0078, green: 0.0118, blue: 0.0157, alpha: 1.0)
        view.backgroundColor = themeColor

        buildTopBar()
        buildBottomBar()

        // Build and show the overlay FIRST, before the WebView is in the hierarchy.
        // This ensures the overlay is composited on screen before WKWebView's
        // black blank state is ever visible.
        buildReaderLoadingOverlay()

        addChild(navigator)
        // Insert navigator BELOW the overlay so the overlay always wins visually
        view.insertSubview(navigator.view, belowSubview: readerLoadingOverlay)
        // Keep the WebView completely hidden until it has actually rendered.
        // This prevents WKWebView's blank black surface from leaking through
        // during the navigation push transition (~1.5s WebContent launch).
        navigator.view.isHidden = true
        navigator.view.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            navigator.view.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            navigator.view.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            navigator.view.topAnchor.constraint(equalTo: topBar.bottomAnchor),
            navigator.view.bottomAnchor.constraint(equalTo: bottomBar.topAnchor)
        ])
        navigator.didMove(toParent: self)
        view.bringSubviewToFront(topBar)
        view.bringSubviewToFront(bottomBar)
        view.bringSubviewToFront(bookmarkIndicator)
        view.bringSubviewToFront(readerLoadingOverlay)

        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(toggleBars))
        tapGesture.cancelsTouchesInView = false
        navigator.view.addGestureRecognizer(tapGesture)
        
        applyInitialSettings()
        
        Task { @MainActor in
            let positionsResult = await publication.positions()

            switch positionsResult {
            case .success(let positions):
                cachedPositions = positions

                // Readium positions are content-based (~1024 bytes each).
                // A visual page on iPhone fits less content than on iPad,
                // so iPhone has more visual pages and iPad has fewer.
                let isIPad = UIDevice.current.userInterfaceIdiom == .pad
                let multiplier: Double = isIPad ? 0.65 : 1.7
                effectiveTotalPages = max(1, Int(round(Double(positions.count) * multiplier)))

                if let locator = navigator.currentLocation {
                    updateLocationLabel(for: locator)
                }

                updateBookmarkIndicator()

            case .failure:
                cachedPositions = []
                updateBookmarkIndicator()
            }
        }
    }
    private func buildReaderLoadingOverlay() {
        readerLoadingOverlay.translatesAutoresizingMaskIntoConstraints = false
        readerLoadingOverlay.backgroundColor = currentSettings?.theme.backgroundColor ?? UIColor(lumeyHex: "#020304")
        readerLoadingOverlay.isUserInteractionEnabled = true

        readerLoadingSpinner.translatesAutoresizingMaskIntoConstraints = false
        readerLoadingSpinner.color = currentSettings?.theme.textColor ?? .white
        readerLoadingSpinner.startAnimating()

        readerLoadingTitle.translatesAutoresizingMaskIntoConstraints = false
        readerLoadingTitle.text = "Opening Reader"
        readerLoadingTitle.textColor = currentSettings?.theme.textColor ?? .white
        readerLoadingTitle.font = UIFont.rounded(size: 24, weight: .black)
        readerLoadingTitle.textAlignment = .center

        readerLoadingSubtitle.translatesAutoresizingMaskIntoConstraints = false
        readerLoadingSubtitle.text = "Laying out the book..."
        readerLoadingSubtitle.textColor = (currentSettings?.theme.textColor ?? .white).withAlphaComponent(0.58)
        readerLoadingSubtitle.font = UIFont.rounded(size: 14, weight: .semibold)
        readerLoadingSubtitle.textAlignment = .center

        let stack = UIStackView(arrangedSubviews: [
            readerLoadingSpinner,
            readerLoadingTitle,
            readerLoadingSubtitle
        ])
        stack.axis = .vertical
        stack.alignment = .center
        stack.spacing = 14
        stack.translatesAutoresizingMaskIntoConstraints = false

        view.addSubview(readerLoadingOverlay)
        readerLoadingOverlay.addSubview(stack)

        NSLayoutConstraint.activate([
            readerLoadingOverlay.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            readerLoadingOverlay.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            readerLoadingOverlay.topAnchor.constraint(equalTo: view.topAnchor),
            readerLoadingOverlay.bottomAnchor.constraint(equalTo: view.bottomAnchor),

            stack.leadingAnchor.constraint(greaterThanOrEqualTo: readerLoadingOverlay.leadingAnchor, constant: 28),
            stack.trailingAnchor.constraint(lessThanOrEqualTo: readerLoadingOverlay.trailingAnchor, constant: -28),
            stack.centerXAnchor.constraint(equalTo: readerLoadingOverlay.centerXAnchor),
            stack.centerYAnchor.constraint(equalTo: readerLoadingOverlay.centerYAnchor)
        ])
    }

    func hideReaderLoadingOverlay() {
        guard !readerLoadingOverlay.isHidden else { return }

        // Unhide the navigator now that WKWebView has painted
        navigator.view.isHidden = false

        UIView.animate(withDuration: 0.22, animations: {
            self.readerLoadingOverlay.alpha = 0
        }) { _ in
            self.readerLoadingSpinner.stopAnimating()
            self.readerLoadingOverlay.isHidden = true
        }
    }


    func updateLocationLabel(_ text: String) {
        locationLabel.text = text
    }
    
    func updateLocationLabel(for locator: Locator) {
        guard effectiveTotalPages > 0 else {
            locationLabel.text = "Reading"
            return
        }

        guard let totalProg = locator.locations.totalProgression else {
            locationLabel.text = "\(displayedPage) OF \(effectiveTotalPages)"
            return
        }

        if let prev = previousTotalProgression {
            let delta = totalProg - prev
            // Threshold: anything beyond ~3 pages' worth of progression is
            // a chapter jump (TOC tap, bookmark tap), not a swipe.
            let jumpThreshold = 3.0 / Double(effectiveTotalPages)

            if abs(delta) <= jumpThreshold {
                // Normal page turn — increment or decrement by exactly 1
                if delta > 0.0001 {
                    displayedPage += 1
                } else if delta < -0.0001 {
                    displayedPage -= 1
                }
            } else {
                // Chapter jump — estimate page from progression
                displayedPage = max(1, Int(totalProg * Double(effectiveTotalPages)) + 1)
            }
        } else {
            // First load — estimate page from progression
            displayedPage = max(1, Int(totalProg * Double(effectiveTotalPages)) + 1)
        }

        // Keep in bounds, but if the counter goes past the estimate,
        // grow the total rather than clamping (avoids stuck page at end)
        displayedPage = max(1, displayedPage)
        if displayedPage > effectiveTotalPages {
            effectiveTotalPages = displayedPage
        }

        previousTotalProgression = totalProg
        locationLabel.text = "\(displayedPage) OF \(effectiveTotalPages)"
    }

    func storeBookmark(_ locator: Locator) {
        guard let locatorJSON = try? locator.jsonString() else {
            showToast("Could not save bookmark")
            return
        }

        let progression = locator.locations.progression ?? 0

        let bookmark = EPUBBookmark(
            bookID: bookID,
            title: locator.title ?? "Bookmark",
            chapterTitle: locator.title ?? "",
            locatorJSON: locatorJSON,
            href: String(describing: locator.href),
            progression: progression,
            pageNumber: displayedPage,
            totalPages: effectiveTotalPages
        )

        modelContext.insert(bookmark)

        do {
            try modelContext.save()
            ReadingXPService.awardEPUBBookmark(bookmark, modelContext: modelContext)
            showToast("Bookmark saved")
            updateBookmarkIndicator()
        } catch {
            showToast("Could not save bookmark")
        }
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        topGradientLayer.frame = topBar.bounds
        bottomGradientLayer.frame = bottomBar.bounds
    }

    private func buildTopBar() {
        topBar.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(topBar)
        
        let theme = currentSettings?.theme ?? .cocoa

        topBar.backgroundColor = theme.chromeBackgroundColor
        topBar.layer.borderColor = theme.chromeBorderColor.cgColor
        topBar.layer.borderWidth = 1

        let titleLabel = UILabel()
        titleLabel.text = publication.metadata.title ?? "Reader"
        titleLabel.textColor = currentSettings?.theme.chromeTextColor ?? .white
        titleLabel.font = UIFont.rounded(size: 16, weight: .black)
        titleLabel.numberOfLines = 1

        let menuButton = readerButton(assetName: "dotswavy", action: #selector(showReaderMenu(_:)))
        menuButton.showsMenuAsPrimaryAction = true
        menuButton.menu = buildReaderContextMenu()

        let headerStack = UIStackView(arrangedSubviews: [titleLabel, menuButton])
        headerStack.axis = .horizontal
        headerStack.alignment = .center
        headerStack.spacing = 12
        headerStack.translatesAutoresizingMaskIntoConstraints = false
        topBar.addSubview(headerStack)

        view.addSubview(bookmarkIndicator)

        NSLayoutConstraint.activate([
            topBar.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            topBar.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            topBar.topAnchor.constraint(equalTo: view.topAnchor),

            headerStack.leadingAnchor.constraint(equalTo: topBar.leadingAnchor, constant: 18),
            headerStack.trailingAnchor.constraint(equalTo: topBar.trailingAnchor, constant: -18),
            headerStack.bottomAnchor.constraint(equalTo: topBar.bottomAnchor, constant: -12),
            headerStack.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 10),

            titleLabel.heightAnchor.constraint(greaterThanOrEqualToConstant: 38),

            bookmarkIndicator.topAnchor.constraint(equalTo: topBar.bottomAnchor, constant: 12),
            bookmarkIndicator.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -18),
            bookmarkIndicator.widthAnchor.constraint(equalToConstant: 18),
            bookmarkIndicator.heightAnchor.constraint(equalToConstant: 28)
        ])
    }

    private func buildReaderContextMenu() -> UIMenu {
        let contentsAction = UIAction(
            title: "Contents",
            image: UIImage(named: "sparklybook")?.withRenderingMode(.alwaysTemplate)
        ) { [weak self] _ in
            self?.showContents()
        }

        let addBookmarkAction = UIAction(
            title: "Add Bookmark",
            image: UIImage(named: "starmark")?.withRenderingMode(.alwaysTemplate)
        ) { [weak self] _ in
            self?.addBookmarkWithTitle()
        }

        let bookmarksAction = UIAction(
            title: "Bookmarks",
            image: UIImage(named: "bookmark")?.withRenderingMode(.alwaysTemplate)
        ) { [weak self] _ in
            self?.showBookmarks()
        }

        let notesQuotesAction = UIAction(
            title: "Notes & Quotes",
            image: UIImage(named: "linespencil")?.withRenderingMode(.alwaysTemplate)
        ) { [weak self] _ in
            self?.showNotesAndQuotes()
        }

        let settingsAction = UIAction(
            title: "Settings",
            image: UIImage(named: "togglesettings")?.withRenderingMode(.alwaysTemplate)
        ) { [weak self] _ in
            self?.showSettings()
        }

        let closeAction = UIAction(
            title: "Close Reader",
            image: UIImage(named: "xmarkwavy")?.withRenderingMode(.alwaysTemplate),
            attributes: .destructive
        ) { [weak self] _ in
            self?.closeReader()
        }

        return UIMenu(children: [
            contentsAction,
            addBookmarkAction,
            bookmarksAction,
            notesQuotesAction,
            settingsAction,
            closeAction
        ])
    }

    @objc private func showReaderMenu(_ sender: UIButton) {
        // Menu is shown automatically via showsMenuAsPrimaryAction
    }
    
    @objc private func showBookmarks() {
        let descriptor = FetchDescriptor<EPUBBookmark>(
            predicate: #Predicate { bookmark in
                bookmark.bookID == bookID && bookmark.deletedAt == nil
            },
            sortBy: [SortDescriptor(\.createdAt, order: .reverse)]
        )

        let savedBookmarks = (try? modelContext.fetch(descriptor)) ?? []

        guard !savedBookmarks.isEmpty else {
            showToast("No bookmarks yet")
            return
        }

        let sheet = ReadiumBookmarksViewController(
            bookmarks: savedBookmarks,
            theme: currentSettings?.theme ?? .cocoa,
            onSelect: { [weak self] bookmark in
                self?.dismiss(animated: true) {
                    Task { @MainActor in
                        guard let locator = try? Locator(jsonString: bookmark.locatorJSON) else { return }
                        try? await self?.navigator.go(to: locator)
                    }
                }
            },
            onDelete: { [weak self] bookmark in
                bookmark.deletedAt = Date()
                bookmark.updatedAt = Date()
                try? self?.modelContext.save()
                self?.updateBookmarkIndicator()
            }
        )

        let nav = UINavigationController(rootViewController: sheet)
        configureAdaptivePresentation(for: nav, detents: [.medium(), .large()])

        present(nav, animated: true)
    }

    private func buildBottomBar() {
        bottomBar.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(bottomBar)
        
        let theme = currentSettings?.theme ?? .cocoa

        bottomBar.backgroundColor = theme.chromeBackgroundColor
        bottomBar.layer.borderColor = theme.chromeBorderColor.cgColor
        bottomBar.layer.borderWidth = 1

        locationLabel.text = "Reading"
        locationLabel.textColor = (currentSettings?.theme.chromeTextColor ?? .white).withAlphaComponent(0.82)
        locationLabel.font = .systemFont(ofSize: 13, weight: .black)
        locationLabel.textAlignment = .center
        locationLabel.translatesAutoresizingMaskIntoConstraints = false
        bottomBar.addSubview(locationLabel)

        NSLayoutConstraint.activate([
            bottomBar.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            bottomBar.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            bottomBar.bottomAnchor.constraint(equalTo: view.bottomAnchor),

            locationLabel.leadingAnchor.constraint(equalTo: bottomBar.leadingAnchor, constant: 18),
            locationLabel.trailingAnchor.constraint(equalTo: bottomBar.trailingAnchor, constant: -18),
            locationLabel.topAnchor.constraint(equalTo: bottomBar.topAnchor, constant: 12),
            locationLabel.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -12)
        ])
    }

    private func readerButton(assetName: String, action: Selector) -> UIButton {
        let button = LumeyGradientIconButton(assetName: assetName)
        button.setIconColor(currentSettings?.theme.chromeTextColor ?? .white)
        button.backgroundColor = .clear
        button.layer.cornerRadius = 0
        button.layer.borderWidth = 0
        button.layer.borderColor = UIColor.clear.cgColor
        button.translatesAutoresizingMaskIntoConstraints = false
        button.addTarget(self, action: action, for: .touchUpInside)
        button.adjustsImageWhenHighlighted = false
        button.showsMenuAsPrimaryAction = false
        button.configurationUpdateHandler = { button in
            button.alpha = button.isHighlighted ? 0.7 : 1.0
        }
        NSLayoutConstraint.activate([
            button.widthAnchor.constraint(equalToConstant: 34),
            button.heightAnchor.constraint(equalToConstant: 34)
        ])
        return button
    }

    @objc private func closeReader() {
        onClose()
    }

    @objc private func showContents() {
        Task { @MainActor in
            let tocResult = await publication.tableOfContents()

            switch tocResult {
            case .success(let links):
                let sheet = ReadiumTableOfContentsViewController(
                    links: links,
                    publication: self.publication,
                    theme: self.currentSettings?.theme ?? .cocoa,
                    onSelect: { [weak self] link in
                        self?.dismiss(animated: true) {
                            Task { @MainActor in
                                try? await self?.navigator.go(to: link)
                            }
                        }
                    }
                )

                let nav = UINavigationController(rootViewController: sheet)
                configureAdaptivePresentation(for: nav, detents: [.medium(), .large()])

                present(nav, animated: true)

            case .failure(let error):
                let alert = UIAlertController(
                    title: "Contents Error",
                    message: "Lumey could not load the table of contents.\n\n\(error)",
                    preferredStyle: .alert
                )
                alert.addAction(UIAlertAction(title: "Done", style: .cancel))
                present(alert, animated: true)
            }
        }
    }

    @objc private func addBookmarkWithTitle() {
        guard let locator = navigator.currentLocation else {
            showToast("No reading location yet")
            return
        }

        let theme = currentSettings?.theme ?? .cocoa
        let alert = UIAlertController(
            title: "Name Your Bookmark",
            message: locator.title ?? "Current page",
            preferredStyle: .alert
        )
        alert.view.tintColor = UIColor(red: 0.0118, green: 0.8588, blue: 0.9882, alpha: 1.0)
        alert.addTextField { field in
            field.placeholder = "Bookmark title (optional)"
            field.autocapitalizationType = .sentences
        }
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        alert.addAction(UIAlertAction(title: "Save", style: .default) { [weak self] _ in
            let customTitle = alert.textFields?.first?.text?.trimmingCharacters(in: .whitespacesAndNewlines)
            let title = (customTitle?.isEmpty == false) ? customTitle! : (locator.title ?? "Bookmark")
            self?.storeBookmarkWith(title: title, locator: locator)
        })
        present(alert, animated: true)
    }

    private func storeBookmarkWith(title: String, locator: Locator) {
        guard let locatorJSON = try? locator.jsonString() else {
            showToast("Could not save bookmark")
            return
        }

        let progression = locator.locations.progression ?? 0

        let bookmark = EPUBBookmark(
            bookID: bookID,
            title: title,
            chapterTitle: locator.title ?? "",
            locatorJSON: locatorJSON,
            href: String(describing: locator.href),
            progression: progression,
            pageNumber: displayedPage,
            totalPages: effectiveTotalPages
        )

        modelContext.insert(bookmark)

        do {
            try modelContext.save()
            ReadingXPService.awardEPUBBookmark(bookmark, modelContext: modelContext)
            showToast("Bookmark saved")
            updateBookmarkIndicator()
        } catch {
            showToast("Could not save bookmark")
        }
    }

    func updateBookmarkIndicator() {
        guard let locator = navigator.currentLocation else {
            setBookmarkIndicatorVisible(false)
            return
        }

        let currentHref = normalizedHref(locator.href)
        let currentProgression = locator.locations.progression ?? 0
        let currentPageNumber = displayedPage

        let descriptor = FetchDescriptor<EPUBBookmark>(
            predicate: #Predicate { bookmark in
                bookmark.bookID == bookID && bookmark.deletedAt == nil
            }
        )

        let bookmarks = (try? modelContext.fetch(descriptor)) ?? []

        let hasBookmark = bookmarks.contains { bm in
            let bookmarkHref = normalizedHref(bm.href)
            guard bookmarkHref == currentHref else { return false }

            if bm.pageNumber > 0 {
                return bm.pageNumber == currentPageNumber
            }

            return abs(bm.progression - currentProgression) < 0.02
        }

        setBookmarkIndicatorVisible(hasBookmark)
    }

    private func setBookmarkIndicatorVisible(_ isVisible: Bool) {
        if isVisible {
            bookmarkIndicator.isHidden = false
        }

        UIView.animate(withDuration: 0.18) {
            self.bookmarkIndicator.alpha = isVisible ? 1 : 0
        } completion: { _ in
            self.bookmarkIndicator.isHidden = !isVisible
        }
    }

    private func normalizedHref(_ href: Any) -> String {
        let value = String(describing: href)
        return value.components(separatedBy: "#").first ?? value
    }

    private func showNotesAndQuotes() {
        let descriptor = FetchDescriptor<EPUBHighlight>(
            predicate: #Predicate { highlight in
                highlight.bookID == bookID && highlight.deletedAt == nil
            },
            sortBy: [SortDescriptor(\.createdAt, order: .reverse)]
        )

        let highlights = (try? modelContext.fetch(descriptor)) ?? []

        let sheet = EPUBNotesQuotesViewController(
            highlights: highlights,
            theme: currentSettings?.theme ?? .cocoa,
            onSelect: { [weak self] highlight in
                self?.dismiss(animated: true) {
                    Task { @MainActor in
                        guard let locator = try? Locator(jsonString: highlight.locatorJSON) else { return }
                        try? await self?.navigator.go(to: locator)
                    }
                }
            },
            onDelete: { [weak self] highlight in
                highlight.deletedAt = Date()
                highlight.updatedAt = Date()
                try? self?.modelContext.save()
            }
        )

        let nav = UINavigationController(rootViewController: sheet)
        configureAdaptivePresentation(for: nav, detents: [.medium(), .large()])
        present(nav, animated: true)
    }

    @objc private func showSettings() {
        guard let settings = currentSettings else { return }
        
        let settingsVC = ReaderSettingsViewController(
            settings: settings,
            modelContext: modelContext,
            onPreferencesChanged: { [weak self] updatedSettings in
                self?.applySettings(updatedSettings)
            }
        )
        
        let nav = UINavigationController(rootViewController: settingsVC)
        configureAdaptivePresentation(for: nav, detents: [.medium(), .large()])

        present(nav, animated: true)
    }

    private func configureAdaptivePresentation(
        for controller: UIViewController,
        detents: [UISheetPresentationController.Detent]
    ) {
        if traitCollection.horizontalSizeClass == .regular {
            controller.modalPresentationStyle = .fullScreen
            return
        }

        controller.modalPresentationStyle = .pageSheet

        if let presentation = controller.sheetPresentationController {
            presentation.detents = detents
            presentation.prefersGrabberVisible = true
            presentation.preferredCornerRadius = 28
        }
    }
    
    private func loadOrCreateSettings() {
        let descriptor = FetchDescriptor<ReaderSettings>()
        let existing = (try? modelContext.fetch(descriptor))?.first
        
        if let existing {
            currentSettings = existing
        } else {
            let newSettings = ReaderSettings()
            modelContext.insert(newSettings)
            try? modelContext.save()
            currentSettings = newSettings
        }
    }
    
    func applySettings(_ settings: ReaderSettings) {
        currentSettings = settings

        DispatchQueue.main.async {
            self.navigator.submitPreferences(settings.buildPreferences(isIPadLayout: self.usesIPadReaderLayout))
        }

        applyChromeTheme(settings.theme, animated: true)
    }
    
    func applyInitialSettings() {
        guard let settings = currentSettings else { return }

        DispatchQueue.main.async {
            self.navigator.submitPreferences(settings.buildPreferences(isIPadLayout: self.usesIPadReaderLayout))
        }

        applyChromeTheme(settings.theme, animated: false)
    }

    override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        super.viewWillTransition(to: size, with: coordinator)

        coordinator.animate(alongsideTransition: nil) { [weak self] _ in
            guard let self, let settings = self.currentSettings else { return }
            self.navigator.submitPreferences(settings.buildPreferences(isIPadLayout: self.usesIPadReaderLayout(for: size)))
        }
    }

    private var usesIPadReaderLayout: Bool {
        usesIPadReaderLayout(for: view.bounds.size)
    }

    private func usesIPadReaderLayout(for size: CGSize) -> Bool {
        traitCollection.userInterfaceIdiom == .pad || max(size.width, size.height) >= 900
    }
    
    private func chromeBackgroundHex(for theme: ReaderTheme) -> UIColor {
        theme.chromeBackgroundColor
    }

    private func chromeTextHex(for theme: ReaderTheme) -> UIColor {
        theme.chromeTextColor
    }

    private func chromeBorderHex(for theme: ReaderTheme) -> UIColor {
        theme.chromeBorderColor
    }
    
    private func applyChromeTheme(_ theme: ReaderTheme, animated: Bool) {
        print("THEME =", theme)
        let backgroundColor = chromeBackgroundHex(for: theme)
        let textColor = chromeTextHex(for: theme)
        let borderColor = chromeBorderHex(for: theme)

        let changes = {
            self.topBar.backgroundColor = backgroundColor
            self.topBar.layer.borderColor = borderColor.cgColor

            self.bottomBar.backgroundColor = backgroundColor
            self.bottomBar.layer.borderColor = borderColor.cgColor

            self.view.backgroundColor = backgroundColor
            self.locationLabel.textColor = textColor.withAlphaComponent(0.82)

            self.readerLoadingOverlay.backgroundColor = backgroundColor
            self.readerLoadingSpinner.color = textColor
            self.readerLoadingTitle.textColor = textColor
            self.readerLoadingSubtitle.textColor = textColor.withAlphaComponent(0.58)

            if let headerStack = self.topBar.subviews.compactMap({ $0 as? UIStackView }).first,
               let titleLabel = headerStack.arrangedSubviews.compactMap({ $0 as? UILabel }).first {
                titleLabel.textColor = textColor
                headerStack.arrangedSubviews.compactMap { $0 as? UIButton }.forEach { button in
                    button.tintColor = textColor
                    (button as? LumeyGradientIconButton)?.setIconColor(textColor)
                }
            }
        }

        if animated {
            UIView.animate(withDuration: 0.25, animations: changes)
        } else {
            changes()
        }
    }

    @objc private func toggleBars() {
        barsAreHidden.toggle()

        UIView.animate(withDuration: 0.22) {
            self.topBar.alpha = self.barsAreHidden ? 0 : 1
            self.bottomBar.alpha = self.barsAreHidden ? 0 : 1
        }
    }

    // MARK: - Text Selection Menu Actions (Readium EditingAction selectors)

    @objc func highlightSelection(_ sender: Any?) {
        openAnnotationSheet(mode: .highlight)
    }

    @objc func quoteSelection(_ sender: Any?) {
        openAnnotationSheet(mode: .quote)
    }

    @objc func addNoteToSelection(_ sender: Any?) {
        openAnnotationSheet(mode: .note)
    }

    private enum AnnotationMode { case highlight, quote, note }

    private func openAnnotationSheet(mode: AnnotationMode) {
        print("[Reader] openAnnotationSheet called, mode: \(mode)")
        getSelectedTextAndLocator { [weak self] text, locator in
            print("[Reader] getSelectedTextAndLocator returned — text: '\(text.prefix(30))', locator: \(locator != nil)")
            guard let self else {
                print("[Reader] self is nil, aborting")
                return
            }
            let theme = self.currentSettings?.theme ?? .cocoa

            let sheet = EPUBHighlightMenuViewController(
                selectedText: text,
                theme: theme,
                initialMode: mode == .note ? .note : (mode == .quote ? .quote : .highlight),
                onHighlight: { [weak self] color in
                    print("[Reader] onHighlight callback fired — color: \(color)")
                    self?.dismiss(animated: true) {
                        print("[Reader] onHighlight dismiss completed, saving...")
                        self?.saveHighlightDirect(text: text, locator: locator, color: color, isQuote: false, note: "")
                    }
                },
                onQuote: { [weak self] color in
                    print("[Reader] onQuote callback fired — color: \(color)")
                    self?.dismiss(animated: true) {
                        print("[Reader] onQuote dismiss completed, saving...")
                        self?.saveHighlightDirect(text: text, locator: locator, color: color, isQuote: true, note: "")
                    }
                },
                onNote: { [weak self] color, noteText in
                    print("[Reader] onNote callback fired — color: \(color), note: '\(noteText.prefix(30))'")
                    self?.dismiss(animated: true) {
                        print("[Reader] onNote dismiss completed, saving...")
                        self?.saveHighlightDirect(text: text, locator: locator, color: color, isQuote: false, note: noteText)
                    }
                }
            )

            let nav = UINavigationController(rootViewController: sheet)
            self.configureAdaptivePresentation(for: nav, detents: [.medium()])
            print("[Reader] Presenting annotation sheet now")
            self.present(nav, animated: true)
        }
    }

    private func getSelectedTextAndLocator(completion: @escaping (String, Locator?) -> Void) {
        // Use Readium's selection API for a proper text-range locator
        if let selection = navigator.currentSelection {
            let text = selection.locator.text.highlight ?? ""
            print("[Reader] Got selection from navigator.currentSelection — text: '\(text.prefix(50))'")
            completion(text, selection.locator)
            return
        }

        print("[Reader] navigator.currentSelection is nil, falling back to JS")

        func findWebView(in view: UIView) -> WKWebView? {
            if let webView = view as? WKWebView { return webView }
            for subview in view.subviews {
                if let found = findWebView(in: subview) { return found }
            }
            return nil
        }

        guard let webView = findWebView(in: navigator.view) else {
            print("[Reader] WKWebView NOT found in navigator view hierarchy")
            completion("", navigator.currentLocation)
            return
        }

        print("[Reader] WKWebView found, evaluating JS")

        webView.evaluateJavaScript("window.getSelection().toString()") { [weak self] result, error in
            if let error {
                print("[Reader] JS error: \(error)")
            }
            let text = (result as? String)?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
            print("[Reader] JS returned text: '\(text.prefix(50))'")
            completion(text, self?.navigator.currentLocation)
        }
    }

    private func saveHighlightDirect(text: String, locator: Locator?, color: HighlightColor, isQuote: Bool, note: String) {
        print("[Reader] saveHighlightDirect — text: '\(text.prefix(30))', color: \(color), isQuote: \(isQuote), note: '\(note.prefix(20))'")
        guard let locator, let locatorJSON = try? locator.jsonString() else {
            print("[Reader] saveHighlightDirect FAILED — locator nil or JSON failed")
            showToast("Could not save")
            return
        }

        let progression = locator.locations.progression ?? 0

        let highlight = EPUBHighlight(
            bookID: bookID,
            highlightedText: text,
            note: note,
            chapterTitle: locator.title ?? "",
            pageNumber: displayedPage,
            totalPages: effectiveTotalPages,
            locatorJSON: locatorJSON,
            href: String(describing: locator.href),
            progression: progression,
            highlightColor: color,
            isQuote: isQuote
        )

        modelContext.insert(highlight)

        do {
            try modelContext.save()
            ReadingXPService.awardEPUBHighlight(highlight, modelContext: modelContext)
            print("[Reader] Highlight saved successfully — id: \(highlight.id)")

            applyAllHighlightDecorations()

            let label = isQuote ? "Quote saved" : (note.isEmpty ? "Highlighted" : "Note saved")
            showToast(label)
        } catch {
            print("[Reader] Highlight save failed:", error)
            showToast("Could not save")
        }
    }

    // MARK: - Readium Decorations

    func applyAllHighlightDecorations() {
        let descriptor = FetchDescriptor<EPUBHighlight>(
            predicate: #Predicate { highlight in
                highlight.bookID == bookID && highlight.deletedAt == nil
            }
        )

        let highlights = (try? modelContext.fetch(descriptor)) ?? []
        print("[Reader] Applying \(highlights.count) highlight decorations")

        var decorations: [Decoration] = []

        for highlight in highlights {
            guard let locator = try? Locator(jsonString: highlight.locatorJSON) else {
                print("[Reader] Skipping highlight \(highlight.id) — bad locator JSON")
                continue
            }

            let tintColor = UIColor(lumeyHex: highlight.highlightColor.hex)

            let decoration = Decoration(
                id: highlight.id.uuidString,
                locator: locator,
                style: .highlight(tint: tintColor, isActive: false)
            )
            decorations.append(decoration)
        }

        print("[Reader] Built \(decorations.count) decorations, applying to navigator")
        navigator.apply(decorations: decorations, in: "highlights")
    }

    private func showToast(_ text: String) {
        let label = UILabel()
        label.text = text
        label.textColor = .white
        label.font = .systemFont(ofSize: 13, weight: .black)
        label.textAlignment = .center
        label.backgroundColor = UIColor.black.withAlphaComponent(0.72)
        label.layer.cornerRadius = 14
        label.clipsToBounds = true
        label.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(label)

        NSLayoutConstraint.activate([
            label.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            label.bottomAnchor.constraint(equalTo: bottomBar.topAnchor, constant: -14),
            label.widthAnchor.constraint(greaterThanOrEqualToConstant: 160),
            label.heightAnchor.constraint(equalToConstant: 42)
        ])

        UIView.animate(withDuration: 0.22, delay: 1.05, options: []) {
            label.alpha = 0
        } completion: { _ in
            label.removeFromSuperview()
        }
    }
}

final class ReadiumLoadingViewController: UIViewController {
    private let titleLabel = UILabel()
    private let subtitleLabel = UILabel()
    private let spinner = UIActivityIndicatorView(style: .large)
    private let initialBackgroundColor: UIColor

    init(backgroundColor: UIColor = UIColor(red: 0.0078, green: 0.0118, blue: 0.0157, alpha: 1.0)) {
        self.initialBackgroundColor = backgroundColor
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        self.initialBackgroundColor = UIColor(red: 0.0078, green: 0.0118, blue: 0.0157, alpha: 1.0)
        super.init(coder: coder)
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        view.backgroundColor = initialBackgroundColor

        let isLight = initialBackgroundColor.isLight
        let labelColor: UIColor = isLight ? UIColor(red: 0.07, green: 0.07, blue: 0.07, alpha: 1) : .white
        spinner.color = labelColor
        spinner.startAnimating()

        titleLabel.text = "Opening Reader"
        titleLabel.textColor = labelColor
        titleLabel.font = .systemFont(ofSize: 24, weight: .black)
        titleLabel.textAlignment = .center
        titleLabel.numberOfLines = 0

        subtitleLabel.text = "Preparing your EPUB..."
        subtitleLabel.textColor = labelColor.withAlphaComponent(0.58)
        subtitleLabel.font = .systemFont(ofSize: 14, weight: .semibold)
        subtitleLabel.textAlignment = .center
        subtitleLabel.numberOfLines = 0

        let stack = UIStackView(arrangedSubviews: [
            spinner,
            titleLabel,
            subtitleLabel
        ])

        stack.axis = .vertical
        stack.alignment = .center
        stack.spacing = 14
        stack.translatesAutoresizingMaskIntoConstraints = false

        view.addSubview(stack)

        NSLayoutConstraint.activate([
            stack.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 28),
            stack.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -28),
            stack.centerYAnchor.constraint(equalTo: view.centerYAnchor)
        ])
    }
    
    func showLoading(title: String, subtitle: String) {
        loadViewIfNeeded()

        view.backgroundColor = UIColor(
            red: 0.0078,
            green: 0.0118,
            blue: 0.0157,
            alpha: 1.0
        )

        titleLabel.text = title
        subtitleLabel.text = subtitle
        titleLabel.isHidden = false
        subtitleLabel.isHidden = false
        spinner.isHidden = false
        spinner.startAnimating()
    }

    func hideLoadingUI() {
        spinner.stopAnimating()
        spinner.isHidden = true
        titleLabel.isHidden = true
        subtitleLabel.isHidden = true
        view.backgroundColor = UIColor(
            red: 0.0078,
            green: 0.0118,
            blue: 0.0157,
            alpha: 1.0
        )
    }

    func showError(_ message: String) {
        spinner.stopAnimating()
        spinner.isHidden = true
        titleLabel.isHidden = false
        subtitleLabel.isHidden = false

        titleLabel.text = "Reader Error"
        subtitleLabel.text = message
    }
}

final class ReadiumTableOfContentsViewController: UIViewController, UITableViewDataSource, UITableViewDelegate {
    private let links: [ReadiumLink]
    private let flattenedLinks: [(link: ReadiumLink, level: Int)]
    private let publication: Publication
    private let theme: ReaderTheme
    private let onSelect: (ReadiumLink) -> Void

    private let tableView = UITableView(frame: .zero, style: .plain)

    init(links: [ReadiumLink], publication: Publication, theme: ReaderTheme, onSelect: @escaping (ReadiumLink) -> Void) {
        self.links = links
        self.publication = publication
        self.theme = theme
        self.flattenedLinks = Self.flatten(links: links)
        self.onSelect = onSelect
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        nil
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = theme.chromeBackgroundColor
        title = nil
        navigationController?.setNavigationBarHidden(true, animated: false)

        let titleLabel = UILabel()
        titleLabel.text = "Contents"
        titleLabel.textColor = theme.chromeTextColor
        titleLabel.font = UIFont.rounded(size: 24, weight: .black)
        titleLabel.translatesAutoresizingMaskIntoConstraints = false

        let closeButton = navIconButton(
            assetName: "xmarkwavy",
            action: #selector(closeSheet)
        )

        view.addSubview(titleLabel)
        view.addSubview(closeButton)

        NSLayoutConstraint.activate([
            titleLabel.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 16),
            titleLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 22),
            titleLabel.heightAnchor.constraint(equalToConstant: 44),

            closeButton.centerYAnchor.constraint(equalTo: titleLabel.centerYAnchor),
            closeButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -28)
        ])

        tableView.translatesAutoresizingMaskIntoConstraints = false
        tableView.backgroundColor = .clear
        tableView.separatorStyle = .none
        tableView.dataSource = self
        tableView.delegate = self
        tableView.register(ReadiumTOCCell.self, forCellReuseIdentifier: ReadiumTOCCell.reuseID)
        tableView.rowHeight = UITableView.automaticDimension
        tableView.estimatedRowHeight = 115 // 120

        view.addSubview(tableView)

        NSLayoutConstraint.activate([
            tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            tableView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 76),
            tableView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        flattenedLinks.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: ReadiumTOCCell.reuseID, for: indexPath) as! ReadiumTOCCell
        let item = flattenedLinks[indexPath.row]
        cell.configure(title: item.link.title ?? "Untitled Section", level: item.level)
        return cell
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        onSelect(flattenedLinks[indexPath.row].link)
    }
    
    private func navIconButton(assetName: String, action: Selector) -> UIButton {
        let button = LumeyGradientIconButton(assetName: assetName)
        button.backgroundColor = .clear
        button.addTarget(self, action: action, for: .touchUpInside)

        NSLayoutConstraint.activate([
            button.widthAnchor.constraint(equalToConstant: 22),
            button.heightAnchor.constraint(equalToConstant: 22)
        ])
        return button
    }

    @objc private func closeSheet() {
        dismiss(animated: true)
    }

    private static func flatten(links: [ReadiumLink], level: Int = 0) -> [(link: ReadiumLink, level: Int)] {
        links.flatMap { link in
            [(link, level)] + flatten(links: link.children, level: level + 1)
        }
    }
}

final class ReadiumBookmarksViewController: UIViewController, UITableViewDataSource, UITableViewDelegate {
    private var bookmarks: [EPUBBookmark]
    private let theme: ReaderTheme
    private let onSelect: (EPUBBookmark) -> Void
    private let onDelete: (EPUBBookmark) -> Void

    private let tableView = UITableView(frame: .zero, style: .plain)

    init(
        bookmarks: [EPUBBookmark],
        theme: ReaderTheme,
        onSelect: @escaping (EPUBBookmark) -> Void,
        onDelete: @escaping (EPUBBookmark) -> Void
    ) {
        self.bookmarks = bookmarks
        self.theme = theme
        self.onSelect = onSelect
        self.onDelete = onDelete
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        nil
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        view.backgroundColor = theme.chromeBackgroundColor
        title = nil
        navigationController?.setNavigationBarHidden(true, animated: false)

        let titleLabel = UILabel()
        titleLabel.text = "Bookmarks"
        titleLabel.textColor = theme.chromeTextColor
        titleLabel.font = UIFont.rounded(size: 24, weight: .black)
        titleLabel.translatesAutoresizingMaskIntoConstraints = false

        let closeButton = navIconButton(
            assetName: "xmarkwavy",
            action: #selector(closeSheet)
        )

        view.addSubview(titleLabel)
        view.addSubview(closeButton)

        NSLayoutConstraint.activate([
            titleLabel.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 16),
            titleLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 22),
            titleLabel.heightAnchor.constraint(equalToConstant: 36),

            closeButton.centerYAnchor.constraint(equalTo: titleLabel.centerYAnchor),
            closeButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -22)
        ])

        tableView.translatesAutoresizingMaskIntoConstraints = false
        tableView.backgroundColor = .clear
        tableView.separatorStyle = .none
        tableView.dataSource = self
        tableView.delegate = self
        tableView.register(ReadiumBookmarkCell.self, forCellReuseIdentifier: ReadiumBookmarkCell.reuseID)
        tableView.rowHeight = UITableView.automaticDimension
        tableView.estimatedRowHeight = 96

        view.addSubview(tableView)

        NSLayoutConstraint.activate([
            tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            tableView.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 16),
            tableView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        bookmarks.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: ReadiumBookmarkCell.reuseID, for: indexPath) as! ReadiumBookmarkCell
        cell.configure(bookmark: bookmarks[indexPath.row], number: indexPath.row + 1)
        return cell
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        onSelect(bookmarks[indexPath.row])
    }

    func tableView(_ tableView: UITableView, trailingSwipeActionsConfigurationForRowAt indexPath: IndexPath) -> UISwipeActionsConfiguration? {
        let deleteAction = UIContextualAction(style: .destructive, title: "Delete") { [weak self] _, _, completion in
            guard let self else {
                completion(false)
                return
            }

            let bookmark = bookmarks[indexPath.row]
            onDelete(bookmark)
            bookmarks.remove(at: indexPath.row)
            tableView.deleteRows(at: [indexPath], with: .automatic)
            completion(true)
        }

        return UISwipeActionsConfiguration(actions: [deleteAction])
    }

    private func navIconButton(assetName: String, action: Selector) -> UIButton {
        let button = LumeyGradientIconButton(assetName: assetName)
        button.backgroundColor = .clear
        button.addTarget(self, action: action, for: .touchUpInside)

        NSLayoutConstraint.activate([
            button.widthAnchor.constraint(equalToConstant: 22),
            button.heightAnchor.constraint(equalToConstant: 22)
        ])

        return button
    }

    @objc private func closeSheet() {
        dismiss(animated: true)
    }
}

final class ReadiumBookmarkCell: UITableViewCell {
    static let reuseID = "ReadiumBookmarkCell"

    private let cardView = UIView()
    private let iconView = LumeyGradientIconImageView(assetName: "starmark")
    private let titleLabel = UILabel()
    private let subtitleLabel = UILabel()
    private let chevronImageView = LumeyGradientIconImageView(assetName: "chevright")

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)

        backgroundColor = .clear
        selectionStyle = .none
        contentView.backgroundColor = .clear

        cardView.translatesAutoresizingMaskIntoConstraints = false
        cardView.backgroundColor = UIColor.white.withAlphaComponent(0.055)
        cardView.layer.cornerRadius = 18
        cardView.layer.borderWidth = 1
        cardView.layer.borderColor = UIColor.white.withAlphaComponent(0.10).cgColor

        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        titleLabel.textColor = .white
        titleLabel.font = UIFont.rounded(size: 15, weight: .black)
        titleLabel.numberOfLines = 2

        subtitleLabel.translatesAutoresizingMaskIntoConstraints = false
        subtitleLabel.textColor = UIColor.white.withAlphaComponent(0.62)
        subtitleLabel.font = UIFont.rounded(size: 12, weight: .semibold)
        subtitleLabel.numberOfLines = 1

        let textStack = UIStackView(arrangedSubviews: [titleLabel, subtitleLabel])
        textStack.axis = .vertical
        textStack.spacing = 4
        textStack.alignment = .leading
        textStack.translatesAutoresizingMaskIntoConstraints = false

        contentView.addSubview(cardView)
        cardView.addSubview(iconView)
        cardView.addSubview(textStack)
        cardView.addSubview(chevronImageView)

        NSLayoutConstraint.activate([
            cardView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 18),
            cardView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -18),
            cardView.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 7),
            cardView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -7),

            iconView.leadingAnchor.constraint(equalTo: cardView.leadingAnchor, constant: 16),
            iconView.centerYAnchor.constraint(equalTo: cardView.centerYAnchor),
            iconView.widthAnchor.constraint(equalToConstant: 18),
            iconView.heightAnchor.constraint(equalToConstant: 18),

            textStack.leadingAnchor.constraint(equalTo: iconView.trailingAnchor, constant: 12),
            textStack.topAnchor.constraint(equalTo: cardView.topAnchor, constant: 16),
            textStack.bottomAnchor.constraint(equalTo: cardView.bottomAnchor, constant: -16),
            textStack.trailingAnchor.constraint(equalTo: chevronImageView.leadingAnchor, constant: -12),

            chevronImageView.centerYAnchor.constraint(equalTo: cardView.centerYAnchor),
            chevronImageView.trailingAnchor.constraint(equalTo: cardView.trailingAnchor, constant: -16),
            chevronImageView.widthAnchor.constraint(equalToConstant: 10),
            chevronImageView.heightAnchor.constraint(equalToConstant: 14)
        ])
    }

    required init?(coder: NSCoder) {
        nil
    }

    func configure(bookmark: EPUBBookmark, number: Int) {
        titleLabel.text = bookmark.title.isEmpty ? "Bookmark \(number)" : bookmark.title

        if bookmark.pageNumber > 0 && bookmark.totalPages > 0 {
            subtitleLabel.text = "Page \(bookmark.pageNumber) of \(bookmark.totalPages)"
        } else {
            let percent = Int((bookmark.progression * 100).rounded())
            subtitleLabel.text = "Saved at \(percent)%"
        }
    }
}

final class ReadiumTOCCell: UITableViewCell {
    static let reuseID = "ReadiumTOCCell"

    private let cardView = UIView()
    private let titleLabel = UILabel()
    private let chevronImageView = LumeyGradientIconImageView(assetName: "chevright")
    private var leadingConstraint: NSLayoutConstraint?

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)

        backgroundColor = .clear
        selectionStyle = .none
        contentView.backgroundColor = .clear

        cardView.translatesAutoresizingMaskIntoConstraints = false
        cardView.backgroundColor = UIColor.white.withAlphaComponent(0.055)
        cardView.layer.cornerRadius = 18
        cardView.layer.borderWidth = 1
        cardView.layer.borderColor = UIColor.white.withAlphaComponent(0.10).cgColor

        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        titleLabel.textColor = .white
        titleLabel.font = UIFont.rounded(size: 16, weight: .black)
        titleLabel.numberOfLines = 0
        titleLabel.lineBreakMode = .byWordWrapping

        chevronImageView.translatesAutoresizingMaskIntoConstraints = false
        chevronImageView.contentMode = .scaleAspectFit

        contentView.addSubview(cardView)
        cardView.addSubview(titleLabel)
        cardView.addSubview(chevronImageView)

        leadingConstraint = titleLabel.leadingAnchor.constraint(equalTo: cardView.leadingAnchor, constant: 16)

        NSLayoutConstraint.activate([
            cardView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 18),
            cardView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -18),
            cardView.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 7),
            cardView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -7),

            titleLabel.topAnchor.constraint(equalTo: cardView.topAnchor, constant: 18),
            titleLabel.bottomAnchor.constraint(equalTo: cardView.bottomAnchor, constant: -18),
            titleLabel.trailingAnchor.constraint(equalTo: chevronImageView.leadingAnchor, constant: -10),
            leadingConstraint!,

            chevronImageView.centerYAnchor.constraint(equalTo: cardView.centerYAnchor),
            chevronImageView.trailingAnchor.constraint(equalTo: cardView.trailingAnchor, constant: -16),
            chevronImageView.widthAnchor.constraint(equalToConstant: 10),
            chevronImageView.heightAnchor.constraint(equalToConstant: 14)
        ])
    }

    required init?(coder: NSCoder) {
        nil
    }

    func configure(title: String, level: Int) {
        titleLabel.text = title
        leadingConstraint?.constant = CGFloat(16 + (level * 18))
    }
}

extension UIFont {
    static func rounded(size: CGFloat, weight: UIFont.Weight) -> UIFont {
        let systemFont = UIFont.systemFont(ofSize: size, weight: weight)
        let descriptor = systemFont.fontDescriptor.withDesign(.rounded) ?? systemFont.fontDescriptor
        return UIFont(descriptor: descriptor, size: size)
    }
}


final class LumeyGradientIconButton: UIButton {
    private let iconImageView = UIImageView()
    private let gradientLayer = CAGradientLayer()
    private let maskImageView = UIImageView()

    init(assetName: String) {
        super.init(frame: .zero)

        backgroundColor = .clear
        tintColor = .clear
        layer.cornerRadius = 0
        layer.borderWidth = 0
        layer.borderColor = UIColor.clear.cgColor
        translatesAutoresizingMaskIntoConstraints = false

        iconImageView.image = UIImage(named: assetName)?.withRenderingMode(.alwaysTemplate)
        iconImageView.tintColor = .white
        iconImageView.contentMode = .scaleAspectFit
        iconImageView.translatesAutoresizingMaskIntoConstraints = false
        iconImageView.alpha = 0
        addSubview(iconImageView)

        gradientLayer.colors = [
            UIColor(red: 0.0118, green: 0.8588, blue: 0.9882, alpha: 1.0).cgColor,
            UIColor(red: 0.4902, green: 0.0980, blue: 0.9686, alpha: 1.0).cgColor
        ]
        gradientLayer.startPoint = CGPoint(x: 0, y: 0)
        gradientLayer.endPoint = CGPoint(x: 1, y: 1)
        layer.addSublayer(gradientLayer)

        maskImageView.image = iconImageView.image
        maskImageView.contentMode = .scaleAspectFit
        gradientLayer.mask = maskImageView.layer

        NSLayoutConstraint.activate([
            iconImageView.centerXAnchor.constraint(equalTo: centerXAnchor),
            iconImageView.centerYAnchor.constraint(equalTo: centerYAnchor),
            iconImageView.widthAnchor.constraint(equalTo: widthAnchor, multiplier: 0.72),
            iconImageView.heightAnchor.constraint(equalTo: heightAnchor, multiplier: 0.72)
        ])
    }

    required init?(coder: NSCoder) {
        nil
    }

    func setIconColor(_ color: UIColor) {
        gradientLayer.colors = [color.cgColor, color.cgColor]
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        gradientLayer.frame = bounds
        maskImageView.frame = bounds.insetBy(dx: bounds.width * 0.14, dy: bounds.height * 0.14)
    }
}

final class LumeyGradientIconImageView: UIImageView {
    private let gradientLayer = CAGradientLayer()
    private let maskImageView = UIImageView()

    init(assetName: String) {
        super.init(frame: .zero)

        image = UIImage(named: assetName)?.withRenderingMode(.alwaysTemplate)
        tintColor = .white
        contentMode = .scaleAspectFit
        alpha = 0
        translatesAutoresizingMaskIntoConstraints = false

        gradientLayer.colors = [
            UIColor(red: 0.0118, green: 0.8588, blue: 0.9882, alpha: 1.0).cgColor,
            UIColor(red: 0.4902, green: 0.0980, blue: 0.9686, alpha: 1.0).cgColor
        ]
        gradientLayer.startPoint = CGPoint(x: 0, y: 0)
        gradientLayer.endPoint = CGPoint(x: 1, y: 1)

        maskImageView.image = image
        maskImageView.contentMode = .scaleAspectFit
        gradientLayer.mask = maskImageView.layer
    }

    required init?(coder: NSCoder) {
        nil
    }

    override func didMoveToSuperview() {
        super.didMoveToSuperview()
        superview?.layer.addSublayer(gradientLayer)
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        guard let superview else { return }
        gradientLayer.frame = convert(bounds, to: superview)
        maskImageView.frame = bounds
    }
}

extension UIColor {
    var isLight: Bool {
        var white: CGFloat = 0
        getWhite(&white, alpha: nil)
        return white > 0.5
    }

    convenience init(lumeyHex hex: String) {
        var cleaned = hex.trimmingCharacters(in: .whitespacesAndNewlines)
        cleaned = cleaned.replacingOccurrences(of: "#", with: "")

        var rgb: UInt64 = 0
        Scanner(string: cleaned).scanHexInt64(&rgb)

        let red = CGFloat((rgb >> 16) & 0xFF) / 255.0
        let green = CGFloat((rgb >> 8) & 0xFF) / 255.0
        let blue = CGFloat(rgb & 0xFF) / 255.0

        self.init(red: red, green: green, blue: blue, alpha: 1.0)
    }
}
