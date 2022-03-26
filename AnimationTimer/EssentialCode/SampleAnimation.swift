//
//  SampleAnimation.swift
//  AnimationTimer
//
//  Created by Alexey on 26.03.2022.
//

import UIKit

final class SampleAnimation<T>: UIView where T: AnimationTimer {
    
    private var timer: T!
    private var startTime: CFTimeInterval = 0
    private let shapeLayer = CAShapeLayer()
    
    init() {
        super.init(frame: .zero)
        translatesAutoresizingMaskIntoConstraints = false
        guard let gradient = self.layer as? CAGradientLayer else { fatalError() }
        gradient.colors = [UIColor.red.cgColor, UIColor.blue.cgColor]
        gradient.startPoint = CGPoint(x: 1, y: 0)
        gradient.endPoint = CGPoint(x: 0, y: 1)
        gradient.mask = shapeLayer
        let size = self.intrinsicContentSize
        timer = T.init(onTimer: { [weak self] tick in
            guard let self = self else { return }
            self.shapeLayer.path = tick
                .shapePath(size: size, startTime: self.startTime).cgPath
        })
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override class var layerClass: AnyClass { CAGradientLayer.self }
    
    override var intrinsicContentSize: CGSize {
        CGSize(width: 100, height: 100)
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        shapeLayer.frame = bounds
    }
    
    func startAnimating() {
        startTime = CACurrentMediaTime()
        timer.start()
    }
    
    func stopAnimating() {
        timer.stop()
    }
    
    override func layoutSublayers(of layer: CALayer) {
        syncMain {
            super.layoutSublayers(of: layer)
        }
    }
    
    override func didMoveToSuperview() {
        super.didMoveToSuperview()
        if superview == nil {
            stopAnimating()
        }
    }
    
    deinit { stopAnimating() }
}

private extension Timer.Tick {
    func shapePath(size: CGSize, startTime: CFTimeInterval) -> UIBezierPath {
        let sec: CGFloat = 2 // full revolution in seconds
        let twoPi: CGFloat = 2 * .pi
        let angle = twoPi * CGFloat(timestamp - startTime) / sec
        
        let revRatio = angle / twoPi
        let progress = revRatio - floor(revRatio)

        let circleRadius = size.width * 0.1
        let mainRadius = min(size.width, size.height) * 0.5 - circleRadius
        let path = UIBezierPath()
        
        distribution(progress: progress, count: 8)
            .map { $0 * twoPi - 0.5 * .pi }
            .map { CGPoint(x: size.width * 0.5 + mainRadius * cos($0),
                           y: size.height * 0.5 + mainRadius * sin($0)) }
            .map { UIBezierPath(arcCenter: $0, radius: circleRadius, startAngle: 0, endAngle: twoPi, clockwise: false) }
            .forEach { path.append($0) }
        return path
    }
    
    private func distribution(progress: CGFloat, count: Int) -> [CGFloat] {
        let _max = progress * 2
        let step = 1 / CGFloat(count)
        var positions: [CGFloat] = []
        var current = _max
        for _ in 0 ..< count {
            positions.append(max(0, min(1, current)))
            current -= step
        }
        return positions
    }
}

private extension CGSize {
    func point(angle: CGFloat) -> CGPoint {
        let x: CGFloat = (1 + cos(angle)) / 2
        let y: CGFloat = (1 + sin(angle)) / 2
        return CGPoint(x: x * width, y: y * height)
    }
}

func syncMain<T>(_ closure: () -> T) -> T {
    if Thread.isMainThread {
        return closure()
    } else {
        return DispatchQueue.main.sync(execute: closure)
    }
}
