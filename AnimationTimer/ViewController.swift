//
//  ViewController.swift
//  AnimationTimer
//
//  Copyright © 2022 Alexey Naumov. MIT License
//

import UIKit

final class ViewController: UIViewController {
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let layout = UICollectionViewFlowLayout()
        layout.sectionInset = UIEdgeInsets(top: 10, left: 10, bottom: 10, right: 10)
        let screenWidth = UIScreen.main.bounds.width
        layout.itemSize = CGSize(width: min(200, screenWidth * 0.5 - 20), height: 130)
        layout.minimumLineSpacing = 50
        let collectionView = UICollectionView(frame: .zero, collectionViewLayout: layout)
        collectionView.translatesAutoresizingMaskIntoConstraints = false
        collectionView.register(AnimationSampleCell.self, forCellWithReuseIdentifier: "cell")
        collectionView.backgroundColor = .systemBackground
        collectionView.dataSource = self
        collectionView.translatesAutoresizingMaskIntoConstraints = false
        let stackView = UIStackView(frame: .zero)
        stackView.translatesAutoresizingMaskIntoConstraints = false
        stackView.axis = .vertical
        stackView.distribution = .fill
        stackView.alignment = .center
        stackView.addArrangedSubview(collectionView)
        NSLayoutConstraint.activate([
            collectionView.widthAnchor.constraint(equalTo: stackView.widthAnchor)
        ])
        view.addSubview(stackView)
        stackView.bindEdgesToSuperView()
        
        let mainThreadBlocker = Timer.NSTimer(mainThread: true) { tick in
            if tick.index % 10 == 0 {
                usleep(150000)
            }
        }
        
        let toggleView = MainThreadBlockerToggle(frame: .zero)
        toggleView.toggle = { block in
            if block {
                mainThreadBlocker.start()
            } else {
                mainThreadBlocker.stop()
            }
        }
        stackView.addArrangedSubview(toggleView)
    }
}

extension ViewController: UICollectionViewDataSource {
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return SampleView.Sample.allCases.count
    }

    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let sample = SampleView.Sample.allCases[indexPath.row]
        let view = collectionView.dequeueReusableCell(withReuseIdentifier: "cell", for: indexPath) as! AnimationSampleCell
        view.setup(sample: sample)
        return view
    }
}
