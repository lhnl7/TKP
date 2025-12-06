import UIKit
import AVKit
import PhotosUI

class VideoCell: UICollectionViewCell {
    static let identifier = "VideoCell"

    var player: AVPlayer?
    var playerLayer: AVPlayerLayer?

    override init(frame: CGRect) {
        super.init(frame: frame)
        backgroundColor = .black
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        playerLayer?.frame = contentView.bounds
    }

    func configure(with url: URL) {
        player?.pause()
        playerLayer?.removeFromSuperlayer()

        let asset = AVAsset(url: url)
        let item = AVPlayerItem(asset: asset)
        player = AVPlayer(playerItem: item)
        playerLayer = AVPlayerLayer(player: player)
        playerLayer?.videoGravity = .resizeAspectFill
        playerLayer?.frame = contentView.bounds

        if let layer = playerLayer {
            contentView.layer.addSublayer(layer)
        }

        player?.play()
        NotificationCenter.default.addObserver(self, selector: #selector(loopVideo(_:)), name: .AVPlayerItemDidPlayToEndTime, object: item)
    }

    @objc func loopVideo(_ notification: Notification) {
        player?.seek(to: .zero)
        player?.play()
    }

    override func prepareForReuse() {
        super.prepareForReuse()
        player?.pause()
        playerLayer?.removeFromSuperlayer()
        player = nil
        playerLayer = nil
        NotificationCenter.default.removeObserver(self)
    }
}

class PlayerViewController: UIViewController, UICollectionViewDelegate, UICollectionViewDataSource {

    var videos: [URL] = []
    var collectionView: UICollectionView!

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .black

        setupCollectionView()
        setupAddButton()
        loadVideosFromDocuments()
    }

    func setupAddButton() {
        let btn = UIButton(type: .system)
        btn.setTitle("选择视频", for: .normal)
        btn.setTitleColor(.white, for: .normal)
        btn.translatesAutoresizingMaskIntoConstraints = false
        btn.addTarget(self, action: #selector(selectVideos), for: .touchUpInside)
        view.addSubview(btn)

        NSLayoutConstraint.activate([
            btn.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
            btn.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 8),
            btn.widthAnchor.constraint(equalToConstant: 90),
            btn.heightAnchor.constraint(equalToConstant: 36)
        ])
    }

    func setupCollectionView() {
        let layout = UICollectionViewFlowLayout()
        layout.scrollDirection = .vertical
        layout.minimumLineSpacing = 0
        layout.itemSize = view.bounds.size

        collectionView = UICollectionView(frame: view.bounds, collectionViewLayout: layout)
        collectionView.isPagingEnabled = true
        collectionView.showsVerticalScrollIndicator = false
        collectionView.backgroundColor = .black

        collectionView.delegate = self
        collectionView.dataSource = self

        collectionView.register(VideoCell.self, forCellWithReuseIdentifier: VideoCell.identifier)
        collectionView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(collectionView)

        NSLayoutConstraint.activate([
            collectionView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            collectionView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            collectionView.topAnchor.constraint(equalTo: view.topAnchor),
            collectionView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
    }

    // MARK: - Video Picker

    @objc func selectVideos() {
        var config = PHPickerConfiguration(photoLibrary: .shared())
        config.selectionLimit = 0
        config.filter = .videos

        let picker = PHPickerViewController(configuration: config)
        picker.delegate = self
        present(picker, animated: true)
    }

    // MARK: - Load videos

    func loadVideosFromDocuments() {
        let manager = FileManager.default
        let docs = manager.urls(for: .documentDirectory, in: .userDomainMask).first!
        let folder = docs.appendingPathComponent("videos")
        if !manager.fileExists(atPath: folder.path) {
            try? manager.createDirectory(at: folder, withIntermediateDirectories: true)
        }
        let contents = (try? manager.contentsOfDirectory(at: folder, includingPropertiesForKeys: nil, options: [])) ?? []
        videos = contents.filter { $0.pathExtension.lowercased() == "mp4" || $0.pathExtension.lowercased() == "mov" }
        DispatchQueue.main.async { [weak self] in
            self?.collectionView.reloadData()
        }
    }

    // MARK: - CollectionView

    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return max(videos.count, 1) // show nothing if empty
    }

    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {

        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: VideoCell.identifier, for: indexPath) as! VideoCell

        if videos.indices.contains(indexPath.row) {
            let url = videos[indexPath.row]
            cell.configure(with: url)
        } else {
            // empty placeholder view
            let label = UILabel(frame: cell.contentView.bounds)
            label.text = "无视频，点击右上角选择视频"
            label.textColor = .white
            label.textAlignment = .center
            label.numberOfLines = 0
            cell.contentView.addSubview(label)
        }

        return cell
    }

    func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
        let visibleIndex = Int(scrollView.contentOffset.y / view.frame.size.height)

        for cell in collectionView.visibleCells {
            if let indexPath = collectionView.indexPath(for: cell),
               indexPath.row != visibleIndex,
               let cell = cell as? VideoCell {
                cell.player?.pause()
            }
        }
    }
}

extension PlayerViewController: PHPickerViewControllerDelegate {
    func picker(_ picker: PHPickerViewController, didFinishPicking results: [PHPickerResult]) {
        dismiss(animated: true)
        let manager = FileManager.default
        let docs = manager.urls(for: .documentDirectory, in: .userDomainMask).first!
        let destFolder = docs.appendingPathComponent("videos")
        if !manager.fileExists(atPath: destFolder.path) {
            try? manager.createDirectory(at: destFolder, withIntermediateDirectories: true)
        }

        for item in results {
            if item.itemProvider.hasItemConformingToTypeIdentifier("public.movie") {
                item.itemProvider.loadFileRepresentation(forTypeIdentifier: "public.movie") { url, error in
                    guard let tempURL = url else { return }
                    let destURL = destFolder.appendingPathComponent(UUID().uuidString + "_" + tempURL.lastPathComponent)
                    try? manager.removeItem(at: destURL)
                    do {
                        try manager.copyItem(at: tempURL, to: destURL)
                        DispatchQueue.main.async {
                            self.videos.append(destURL)
                            self.collectionView.reloadData()
                        }
                    } catch {
                        print("copy error:", error)
                    }
                }
            }
        }
    }
}
