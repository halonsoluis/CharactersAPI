//
//  PublicationCollection.swift
//  Marvel
//
//  Created by Hugo Alonso on 08/12/2020.
//

import Foundation
import UIKit
import CharactersAPI

extension MarvelPublication {
    var isPresentable: Bool {
        thumbnail != nil
    }
}

final class PublicationCollection: UIViewController, UICollectionViewDataSource {
    lazy var sectionName: UILabel = createSection()
    lazy var collection: UICollectionView = createCollection()

    let characterId: Int
    let section: MarvelPublication.Kind
    let loadImageHandler: (URL, String, UIImageView, @escaping ((Error?) -> Void)) -> Void
    let feedDataProvider: PublicationFeedDataProvider

    init(characterId: Int, section: MarvelPublication.Kind, loadImageHandler: @escaping (URL, String, UIImageView, @escaping ((Error?) -> Void)) -> Void, feedDataProvider: PublicationFeedDataProvider) {
        self.characterId = characterId
        self.section = section
        self.loadImageHandler = loadImageHandler
        self.feedDataProvider = feedDataProvider

        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        setupUI()
        feedDataProvider.onItemsChangeCallback = newItemsReceived
        feedDataProvider.perform(action: .loadFromStart(characterId: characterId, type: section))
    }

    func newItemsReceived() {
        //Update data
        let presentableItems = feedDataProvider.items.filter { $0.isPresentable }.isEmpty
        view.isHidden = presentableItems

        collection.reloadData()
    }

    func setupUI() {
        view.backgroundColor = .black

        view.addSubview(sectionName)
        view.addSubview(collection)

        sectionName.translatesAutoresizingMaskIntoConstraints = false
        collection.translatesAutoresizingMaskIntoConstraints = false

        sectionName.snp.makeConstraints { make in
            make.top.equalToSuperview().inset(4)
            make.width.equalToSuperview()
            make.centerX.equalToSuperview()
        }

        collection.snp.makeConstraints { make in
            make.top.equalTo(sectionName.snp.bottom).offset(8)
            make.width.equalToSuperview()
            make.centerX.equalToSuperview()
            make.bottom.equalToSuperview().inset(4)
            make.height.equalTo(PublicationCell.cellSize)
        }
    }

    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        guard let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "PublicationCell", for: indexPath) as? PublicationCell
        else { return UICollectionViewCell()}

        let crossReference = feedDataProvider.items[indexPath.row]

        cell.nameLabel.text = crossReference.title

        cell.image.image = nil
        feedDataProvider.perform(action: .setHeroImage(index: indexPath.row, on: cell.image))

        return cell
    }

    func numberOfSections(in collectionView: UICollectionView) -> Int {
        return 1
    }

    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return feedDataProvider.items.count
    }

    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        print("selected \(indexPath.row)")
    }
}

// MARK: Initialisers
extension PublicationCollection {
    private func createSection() -> UILabel {
        let sectionName = UILabel()

        sectionName.textColor = .red
        sectionName.font = UIFont.boldSystemFont(ofSize: 17)
        sectionName.text = section.rawValue
        sectionName.textAlignment = .justified

        return sectionName
    }

    private func createCollection() -> UICollectionView {
        let collection = UICollectionView(
            frame: CGRect(origin: CGPoint(x: 0, y: 0), size: CGSize(width: view.bounds.width, height: 400)),
            collectionViewLayout: createBasicListLayout()
        )
        collection.allowsMultipleSelection = false
        collection.register(PublicationCell.self, forCellWithReuseIdentifier: "PublicationCell")
        collection.dataSource = self

        return collection
    }

    func createBasicListLayout() -> UICollectionViewLayout {
        let itemSize = NSCollectionLayoutSize(widthDimension: .fractionalWidth(0.3), heightDimension: .fractionalHeight(0.9))
        let item = NSCollectionLayoutItem(layoutSize: itemSize)

        let groupSize = NSCollectionLayoutSize(widthDimension: .fractionalWidth(1.0), heightDimension: .fractionalHeight(1.0))
        let group = NSCollectionLayoutGroup.horizontal(layoutSize: groupSize, subitems: [item])

        let section = NSCollectionLayoutSection(group: group)

        section.orthogonalScrollingBehavior = .continuousGroupLeadingBoundary

        let layout = UICollectionViewCompositionalLayout(section: section)
        return layout
    }

}