//
//  AnimationView.swift
//  AnimationTimer
//
//  Copyright © 2022 Alexey Naumov. MIT License
//

import UIKit

private extension Timer.Tick.AnimationParams {
    struct Constants {
        static var fullRevolutionInSeconds: CGFloat { 2 }
        static var circleRadiusProportion: CGFloat { 0.07 }
        static var numberOfCircles: Int { 12 }
        static var gradient: [UIColor] { [.red, .blue] }
    }
}

final class AnimationView<T>: UIView where T: AnimationTimer {
    
    private var timer: T!
    private let shapeLayer = CAShapeLayer()
    
    init(mainThread: Bool) {
        super.init(frame: .zero)
        translatesAutoresizingMaskIntoConstraints = false
        guard let gradient = self.layer as? CAGradientLayer else { fatalError() }
        gradient.colors = Timer.Tick.AnimationParams.Constants.gradient.map { $0.cgColor }
        gradient.mask = shapeLayer
        let size = self.intrinsicContentSize
        timer = T(mainThread: mainThread) { [weak self] tick in
            guard let self = self else { return }
            let params = Timer.Tick.AnimationParams(tick: tick, size: size)
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

// MARK: - AnimationParams calculation

private extension Timer.Tick {
    struct AnimationParams {
        let shapePath: UIBezierPath
        let gradientStart: CGPoint
        let gradientEnd: CGPoint
    }
}

private extension Timer.Tick.AnimationParams {
    
    init(tick: Timer.Tick, size: CGSize) {
        typealias Constants = Timer.Tick.AnimationParams.Constants
        
        let twoPi: CGFloat = 2 * .pi
        let angle = twoPi * CGFloat(tick.timestamp - tick.startTime) / Constants.fullRevolutionInSeconds
        
        let revRatio = angle / twoPi
        let revProgress = revRatio - floor(revRatio)

        let circleRadius = size.width * Constants.circleRadiusProportion
        let revRadius = min(size.width, size.height) * 0.5 - circleRadius
        let path = UIBezierPath()
        
        Self.distribution(progress: revProgress, count: Constants.numberOfCircles)
            .map { $0 * twoPi - 0.5 * .pi }
            .map { CGPoint(x: size.width * 0.5 + revRadius * cos($0),
                           y: size.height * 0.5 + revRadius * sin($0)) }
            .map { UIBezierPath(arcCenter: $0, radius: circleRadius, startAngle: 0, endAngle: twoPi, clockwise: false) }
            .forEach { path.append($0) }
        let gradientAngle = angle - .pi * 0.5
        let gradientStart = CGPoint(x: sin(gradientAngle), y: cos(gradientAngle))
        let gradientEnd = CGPoint(x: sin(gradientAngle + .pi), y: cos(gradientAngle + .pi))
        self.init(shapePath: path, gradientStart: gradientStart, gradientEnd: gradientEnd)
    }
    
    private static func distribution(progress: CGFloat, count: Int) -> [CGFloat] {
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
