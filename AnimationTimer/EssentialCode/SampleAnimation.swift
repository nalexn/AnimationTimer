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
        let path = UIBezierPath()
        let sec: CGFloat = 4 // full revolution in seconds
        let twoPi: CGFloat = 2 * .pi
        let angle1 = twoPi * CGFloat(timestamp - startTime) / sec
        let angle2 = angle1 + twoPi / 3
        let angle3 = angle2 + twoPi / 3
        let angle4 = angle1 + twoPi
        let revRatio = angle1 / twoPi
        let progress = revRatio - floor(revRatio)
        let factor = 1 - abs(2 * progress - 1)
        let angle12 = angle1 * (1 - factor) + angle2 * factor
        let angle23 = angle2 * (1 - factor) + angle3 * factor
        let angle34 = angle3 * (1 - factor) + angle4 * factor
        path.move(to: size.point(angle: angle1))
        path.addQuadCurve(to: size.point(angle: angle2), controlPoint: size.point(angle: angle12))
        path.addQuadCurve(to: size.point(angle: angle3), controlPoint: size.point(angle: angle23))
        path.addQuadCurve(to: size.point(angle: angle4), controlPoint: size.point(angle: angle34))
        path.close()
        return path
    }
}

private extension CGSize {
    func point(angle: CGFloat) -> CGPoint {
        let x: CGFloat = (1 + cos(angle)) / 2
        let y: CGFloat = (1 - sin(angle)) / 2
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
