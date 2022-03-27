//
//  AnimationView.swift
//  AnimationTimer
//
//  Created by Alexey on 26.03.2022.
//

import UIKit

final class AnimationView<T>: UIView where T: AnimationTimer {
    
    private var timer: T!
    private let shapeLayer = CAShapeLayer()
    
    init(mainThread: Bool) {
        super.init(frame: .zero)
        translatesAutoresizingMaskIntoConstraints = false
        guard let gradient = self.layer as? CAGradientLayer else { fatalError() }
        gradient.colors = [UIColor.red.cgColor, UIColor.blue.cgColor]
        gradient.mask = shapeLayer
        let size = self.intrinsicContentSize
        timer = T(mainThread: mainThread) { [weak self] tick in
            guard let self = self else { return }
            let params = tick.animationParams(size: size)
            self.shapeLayer.path = params.shapePath.cgPath
            gradient.startPoint = params.gradientStart
            gradient.endPoint = params.gradientEnd
        }
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
        timer.start()
    }
    
    func stopAnimating() {
        timer.stop()
    }
    
    override func layoutSublayers(of layer: CALayer) {
        if Thread.isMainThread {
            super.layoutSublayers(of: layer)
        } else {
            DispatchQueue.main.sync {
                super.layoutSublayers(of: layer)
            }
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
    
    struct AnimationParams {
        let shapePath: UIBezierPath
        let gradientStart: CGPoint
        let gradientEnd: CGPoint
    }
    
    func animationParams(size: CGSize) -> AnimationParams {
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
        let gradientAngle = angle - .pi * 0.5
        let gradientStart = CGPoint(x: sin(gradientAngle), y: cos(gradientAngle))
        let gradientEnd = CGPoint(x: sin(gradientAngle + .pi), y: cos(gradientAngle + .pi))
        return AnimationParams(shapePath: path, gradientStart: gradientStart, gradientEnd: gradientEnd)
    }
    
    private func distribution(progress: CGFloat, count: Int) -> [CGFloat] {
        let _max = progress * 2
        let step = 1 / CGFloat(count - 1)
        var positions: [CGFloat] = []
        var current = _max
        for _ in 0 ..< count {
            positions.append(max(0, min(1, current)))
            current -= step
        }
        return positions
    }
}
