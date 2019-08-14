//
//  XCUIElement+Swipe.swift
//  WikipediaUITests
//
//  Created by steven on 08.06.19.
//  Copyright © 2019 Wikimedia Foundation. All rights reserved.
//

import Foundation
import XCTest

enum SwipeDirection: String {
    case up, down, left, right
}

enum SwipeDistance: String {
    case aBit, aLot
    
    func value() -> CGFloat {
        switch self {
        case .aBit: return 35
        case .aLot: return 200
        }
    }
}

extension XCUIElement {
    func swipe(_ direction: SwipeDirection, _ distance: SwipeDistance) {
        let pressDuration: TimeInterval = 0.05
        let startPoint = coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.5))
        var endPoint = startPoint
        
        switch direction {
        case .up:
            endPoint = startPoint.withOffset(CGVector(dx: 0, dy: -distance.value()))
        case .down:
            endPoint = startPoint.withOffset(CGVector(dx: 0, dy: distance.value()))
        case .left:
            endPoint = startPoint.withOffset(CGVector(dx: -distance.value(), dy: 0))
        case .right:
            endPoint = startPoint.withOffset(CGVector(dx: distance.value(), dy: 0))
        }
        
        startPoint.press(forDuration: pressDuration, thenDragTo: endPoint)
    }
}
