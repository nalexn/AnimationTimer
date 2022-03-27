//
//  Samples.swift
//  AnimationTimer
//
//  Copyright © 2022 Alexey Naumov. MIT License
//

import UIKit

extension SampleView {
    enum Sample: CaseIterable {
        case nsTimerMain
        case nsTimerBG
        case displayLinkMain
        case displayLinkBG
        case dispatchSourceTimerMain
        case dispatchSourceTimerBG
    }
}

extension SampleView.Sample {
    func createView() -> UIView {
        switch self {
        case .nsTimerMain:
            return SampleView(Timer.NSTimer.self, mainThread: true, name: "NSTimer (Main)")
        case .nsTimerBG:
            return SampleView(Timer.NSTimer.self, mainThread: false, name: "NSTimer (BG)")
        case .displayLinkMain:
            return SampleView(Timer.DisplayLink.self, mainThread: true, name: "CADisplayLink (Main)")
        case .displayLinkBG:
            return SampleView(Timer.DisplayLink.self, mainThread: false, name: "CADisplayLink (BG)")
        case .dispatchSourceTimerMain:
            return SampleView(Timer.DispatchSourceTimer.self, mainThread: true, name: "DispatchSource (Main)")
        case .dispatchSourceTimerBG:
            return SampleView(Timer.DispatchSourceTimer.self, mainThread: false, name: "DispatchSource (BG)")
        }
    }
}
