//
//  ViewController.swift
//  AnimationTimer
//
//  Created by Alexey on 26.03.2022.
//

import UIKit

final class ViewController: UIViewController {

    override func loadView() {
        let stackView = UIStackView(frame: .zero)
        stackView.translatesAutoresizingMaskIntoConstraints = false
        stackView.axis = .vertical
        stackView.alignment = .center
        stackView.distribution = .equalSpacing
        stackView.isLayoutMarginsRelativeArrangement = true
        stackView.layoutMargins = UIEdgeInsets(top: 10, left: 10, bottom: 10, right: 10)
        stackView.backgroundColor = .systemBackground
        self.view = stackView
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        guard let stackView = self.view as? UIStackView else { return }
        stackView.addArrangedSubview(AnimationCell(Timer.DisplayLink.self, name: "CADisplayLink"))
        stackView.addArrangedSubview(AnimationCell(Timer.DispatchSourceTimer.self, name: "DispatchSourceTimer"))
    }
    
    override func willTransition(to newCollection: UITraitCollection, with coordinator: UIViewControllerTransitionCoordinator) {
        super.willTransition(to: newCollection, with: coordinator)
        guard let stackView = self.view as? UIStackView else { return }
        stackView.axis = UIDevice.current.orientation.isLandscape ? .horizontal : .vertical
    }
}

final class AnimationCell: UIStackView {
    
    init<T>(_ timerType: T.Type, name: String) where T: AnimationTimer {
        super.init(frame: .zero)
        translatesAutoresizingMaskIntoConstraints = false
        axis = .vertical
        alignment = .center
        distribution = .fill
        let animation = SampleAnimation<T>()
        let title = UILabel()
        title.translatesAutoresizingMaskIntoConstraints = false
        title.font = UIFont.monospacedSystemFont(ofSize: 14, weight: .light)
        title.textColor = .secondaryLabel
        title.text = name
        addArrangedSubview(animation)
        addArrangedSubview(title)
        layoutIfNeeded()
        animation.startAnimating()
    }
    
    required init(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
