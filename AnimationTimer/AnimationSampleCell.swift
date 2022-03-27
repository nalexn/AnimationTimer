//
//  AnimationSampleCell.swift
//  AnimationTimer
//
//  Copyright © 2022 Alexey Naumov. MIT License
//

import UIKit

final class AnimationSampleCell: UICollectionViewCell {
    private weak var content: UIView?
    
    override func prepareForReuse() {
        super.prepareForReuse()
        content?.removeFromSuperview()
    }
    
    func setup(sample: SampleView.Sample) {
        let view = sample.createView()
        content = view
        contentView.addSubview(view)
        view.bindEdgesToSuperView()
    }
}

// MARK: - SampleView

final class SampleView: UIStackView {
    
    init<T>(_ timerType: T.Type, mainThread: Bool, name: String) where T: AnimationTimer {
        super.init(frame: .zero)
        translatesAutoresizingMaskIntoConstraints = false
        axis = .vertical
        alignment = .center
        distribution = .fill
        let animation = AnimationView<T>(mainThread: mainThread)
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

// MARK: - Toggle

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

// MARK: - Layout helpers

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
