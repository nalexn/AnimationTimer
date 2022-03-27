//
//  TimerProtocol.swift
//  Timers
//
//  Created by Alexey on 26.03.2022.
//

import QuartzCore
import UIKit.UIScreen

protocol AnimationTimer {
    
    func start()
    func stop()
    
    var isRunning: Bool { get }
    
    init(mainThread: Bool, onTimer: @escaping (Timer.Tick) -> Void)
}

struct Timer { } // Just a namespace

extension Timer {
    struct Tick {
        let index: Int
        let startTime: TimeInterval
        let timestamp: TimeInterval
        let frameDiration: TimeInterval
        
        init(last: Tick?) {
            self.index = last.flatMap({ $0.index + 1 }) ?? 0
            let timestamp = CACurrentMediaTime()
            self.startTime = last?.startTime ?? timestamp
            self.timestamp = timestamp
            self.frameDiration = last.flatMap({ timestamp - $0.timestamp }) ?? 0
        }
    }
}

// MARK: - NSTimer

extension Timer {
    final class NSTimer: AnimationTimer {
        
        private var thread: Thread?
        private var timer: Foundation.Timer?
        private let onTimer: (Tick) -> Void
        private var last: Tick?
        private let mainThread: Bool
        
        init(mainThread: Bool, onTimer: @escaping (Tick) -> Void) {
            self.onTimer = onTimer
            self.mainThread = mainThread
        }
        
        deinit {
            stop()
        }
        
        func start() {
            stop()
            let maxFPS = UIScreen.main.maximumFramesPerSecond
            let timeInterval = 1 / TimeInterval(maxFPS)
            let timer = Foundation.Timer(timeInterval: timeInterval, repeats: true) { [weak self] _ in
                let tick = Tick(last: self?.last)
                self?.last = tick
                autoreleasepool {
                    CATransaction.begin()
                    self?.onTimer(tick)
                    CATransaction.commit()
                }
            }
            self.timer = timer
            if mainThread {
                RunLoop.current.add(timer, forMode: .common)
            } else {
                thread = .startedWithRunLoop {
                    RunLoop.current.add(timer, forMode: .common)
                }
            }
        }
        
        func stop() {
            timer?.invalidate()
            timer = nil
            thread?.cancel()
            thread = nil
        }
        
        var isRunning: Bool {
            return timer != nil
        }
    }
}

// MARK: - DisplayLink

extension Timer {
    final class DisplayLink: AnimationTimer {
        
        private var thread: Thread?
        private let timer: CADisplayLink
        private weak var target: Target?
        
        init(mainThread: Bool, onTimer: @escaping (Tick) -> Void) {
            let target = Target(onTimer: onTimer)
            self.target = target
            let timer = CADisplayLink(target: target, selector: #selector(Target.tick(_:)))
            self.timer = timer
            timer.isPaused = true
            if mainThread {
                timer.add(to: .current, forMode: .common)
            } else {
                thread = .startedWithRunLoop {
                    timer.add(to: .current, forMode: .common)
                }
            }
        }
        
        deinit {
            timer.invalidate()
            thread?.cancel()
            thread = nil
        }
        
        func start() {
            target?.last = nil
            timer.isPaused = false
        }
        
        func stop() {
            timer.isPaused = true
        }
        
        var isRunning: Bool {
            return !timer.isPaused
        }
        
        fileprivate final class Target {
            
            let onTimer: (Tick) -> Void
            var last: Tick?
            
            init(onTimer: @escaping (Tick) -> Void) {
                self.onTimer = onTimer
            }
            
            @objc fileprivate func tick(_ link: CADisplayLink) {
                let tick = Tick(last: last)
                self.last = tick
                autoreleasepool {
                    CATransaction.begin()
                    onTimer(tick)
                    CATransaction.commit()
                }
            }
        }
    }
}

// MARK: - DispatchSourceTimer

extension Timer {
    final class DispatchSourceTimer: AnimationTimer {
        
        private let queue: DispatchQueue
        private let timer: Dispatch.DispatchSourceTimer
        private(set) var isRunning: Bool = false
        private var last: Tick?
        
        init(mainThread: Bool, onTimer: @escaping (Tick) -> Void) {
            queue = mainThread ? .main : DispatchQueue(
            label: "animation.timer", qos: .userInteractive)
            timer = DispatchSource.makeTimerSource(flags: [.strict], queue: queue)
            let maxFPS = UIScreen.main.maximumFramesPerSecond
            let timeInterval = 1 / TimeInterval(maxFPS)
            timer.schedule(deadline: .now(), repeating: timeInterval)
            timer.setEventHandler(handler: { [weak self] in
                let tick = Tick(last: self?.last)
                self?.last = tick
                autoreleasepool {
                    CATransaction.begin()
                    onTimer(tick)
                    CATransaction.commit()
                }
            })
        }
        
        deinit {
            timer.setEventHandler {}
            timer.cancel()
            // https://forums.developer.apple.com/thread/15902
            start()
        }
        
        func start() {
            guard !isRunning else { return }
            isRunning = true
            last = Tick(last: nil)
            timer.resume()
        }
        
        func stop() {
            guard isRunning else { return }
            isRunning = false
            timer.suspend()
        }
    }
}

private extension Thread {
    static func startedWithRunLoop(_ creation: @escaping () -> Void) -> Thread {
        let thread = Thread(block: {
            creation()
            while true {
                RunLoop.current.run(until: Date())
            }
        })
        thread.start()
        return thread
    }
}
