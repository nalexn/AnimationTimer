//
//  ViewController.swift
//  AnimationTimer
//
//  Created by Alexey on 26.03.2022.
//

import UIKit

extension AnimationSampleView {
    enum Sample: CaseIterable {
        case nsTimerMain
        case nsTimerBG
        case displayLinkMain
        case displayLinkBG
        case dispatchSourceTimerMain
        case dispatchSourceTimerBG
    }
}

extension AnimationSampleView.Sample {
    func createView() -> UIView {
        switch self {
        case .nsTimerMain:
            return AnimationSampleView(Timer.NSTimer.self, mainThread: true, name: "NSTimer (Main)")
        case .nsTimerBG:
            return AnimationSampleView(Timer.NSTimer.self, mainThread: false, name: "NSTimer (BG)")
        case .displayLinkMain:
            return AnimationSampleView(Timer.DisplayLink.self, mainThread: true, name: "CADisplayLink (Main)")
        case .displayLinkBG:
            return AnimationSampleView(Timer.DisplayLink.self, mainThread: false, name: "CADisplayLink (BG)")
        case .dispatchSourceTimerMain:
            return AnimationSampleView(Timer.DispatchSourceTimer.self, mainThread: true, name: "DispatchSource (Main)")
        case .dispatchSourceTimerBG:
            return AnimationSampleView(Timer.DispatchSourceTimer.self, mainThread: false, name: "DispatchSource (BG)")
        }
    }
}

final class ViewController: UIViewController {
    
    private let mainThreadBlocker = Timer.NSTimer(mainThread: true) { tick in
        if tick.index % 500 == 0 {
            usleep(300000)
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let layout = UICollectionViewFlowLayout()
        layout.sectionInset = UIEdgeInsets(top: 10, left: 10, bottom: 10, right: 10)
        let screenWidth = UIScreen.main.bounds.width
        layout.itemSize = CGSize(width: min(200, screenWidth * 0.5 - 20), height: 130)
        layout.minimumLineSpacing = 50
        let collectionView = UICollectionView(frame: .zero, collectionViewLayout: layout)
        collectionView.translatesAutoresizingMaskIntoConstraints = false
        collectionView.register(AnimationCell.self, forCellWithReuseIdentifier: "cell")
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
        
        let toggleView = MainThreadBlockerToggle(frame: .zero)
        toggleView.toggle = { [weak self] block in
            if block {
                self?.mainThreadBlocker.start()
            } else {
                self?.mainThreadBlocker.stop()
            }
        }
        stackView.addArrangedSubview(toggleView)
    }
}

final class AnimationSampleView: UIStackView {
    
    init<T>(_ timerType: T.Type, mainThread: Bool, name: String) where T: AnimationTimer {
        super.init(frame: .zero)
        translatesAutoresizingMaskIntoConstraints = false
        axis = .vertical
        alignment = .center
        distribution = .fill
        let animation = SampleAnimation<T>(mainThread: mainThread)
        let title = UILabel()
        title.translatesAutoresizingMaskIntoConstraints = false
        title.font = UIFont.monospacedSystemFont(ofSize: 14, weight: .light)
        title.textColor = .secondaryLabel
        title.text = name
        title.adjustsFontSizeToFitWidth = true
        title.minimumScaleFactor = 0.8
        addArrangedSubview(animation)
        addArrangedSubview(title)
        layoutIfNeeded()
        animation.startAnimating()
    }
    
    required init(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

final class AnimationCell: UICollectionViewCell {
    private var content: UIView?
    
    override func prepareForReuse() {
        super.prepareForReuse()
        content?.removeFromSuperview()
        content = nil
    }
    
    func setup(sample: AnimationSampleView.Sample) {
        let view = sample.createView()
        content = view
        contentView.addSubview(view)
        view.bindEdgesToSuperView()
    }
}

extension ViewController: UICollectionViewDataSource {
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return AnimationSampleView.Sample.allCases.count
    }

    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let sample = AnimationSampleView.Sample.allCases[indexPath.row]
        let view = collectionView.dequeueReusableCell(withReuseIdentifier: "cell", for: indexPath) as! AnimationCell
        view.setup(sample: sample)
        return view
    }
}

extension UIView {
    func bindEdgesToSuperView() {
        guard let superview = self.superview else { return }
        NSLayoutConstraint.activate([
            leftAnchor.constraint(equalTo:  superview.leftAnchor),
            rightAnchor.constraint(equalTo:  superview.rightAnchor),
            topAnchor.constraint(equalTo:  superview.topAnchor),
            bottomAnchor.constraint(equalTo:  superview.bottomAnchor)
        ])
    }
}

final class MainThreadBlockerToggle: UIStackView {
    
    var toggle: (Bool) -> Void = { _ in }
    
    override init(frame: CGRect) {
        super.init(frame: .zero)
        translatesAutoresizingMaskIntoConstraints = false
        axis = .horizontal
        distribution = .fill
        alignment = .fill
        spacing = 8
        layoutMargins = UIEdgeInsets(top: 8, left: 0, bottom: 8, right: 0)
        isLayoutMarginsRelativeArrangement = true
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.font = UIFont.monospacedSystemFont(ofSize: 14, weight: .bold)
        label.textColor = .secondaryLabel
        label.text = "Make main thread busy"
        let toggle = UISwitch(frame: .zero)
        toggle.translatesAutoresizingMaskIntoConstraints = false
        toggle.isOn = false
        toggle.addTarget(self, action: #selector(onToggle(_:)), for: .valueChanged)
        addArrangedSubview(label)
        addArrangedSubview(toggle)
    }
    
    required init(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    @objc private func onToggle(_ control: UISwitch) {
        self.toggle(control.isOn)
    }
}
