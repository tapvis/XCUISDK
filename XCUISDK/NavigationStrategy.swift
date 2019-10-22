//
//  SearchStrategy.swift
//  WikipediaUITests
//
//  Created by steven on 22.07.19.
//  Copyright © 2019 Wikimedia Foundation. All rights reserved.
//

import Foundation
import XCTest

enum NavigationCommand {
    case stop, `continue`
}

protocol NavigationStrategy {
    /// Wether this strategy can be applied or not.
    /// Implement this method if your strategy cannot
    /// be applied under all circumstances. E.g. a strategy
    /// might only be applicable if a scroll view is visible.
    func canBeApplied() -> Bool
    
    func apply(uiElementInteraction: () -> NavigationCommand)
}


//MARK: -

extension NavigationStrategy {
    func canBeApplied() -> Bool {
        return true
    }
}

//MARK: -

struct Swiping: NavigationStrategy {
    private let container: UIElement
    
    /// just storing this for performance reasons
    /// because it is costly to call container.locate()
    private let containerElement: XCUIElement?
    private let direction: SwipeDirection
    private let distance: SwipeDistance
    private let times: Int
   
    init(_ direction: SwipeDirection, _ distance: SwipeDistance, times: Int = 3, in container: UIElement, inContextOf context: XCUIElement?) {
        self.direction = direction
        self.container = container
        self.containerElement = container.locate(in: App())
        self.times = times
        self.distance = distance
    }
    
    func apply(uiElementInteraction: () -> NavigationCommand) {
        guard let containerElement = containerElement else {
            return
        }
        var switchedToNewState = true
        var timesSwiped = 0
        var previousScreenshot = containerElement.screenshot().image
        while switchedToNewState == true,  timesSwiped < times {
            Swipe(direction, distance, on: container)
            let currentScreenshot = containerElement.screenshot().image
            switchedToNewState = previousScreenshot.pngData() != currentScreenshot.pngData()
            previousScreenshot = currentScreenshot
            timesSwiped = timesSwiped + 1
            let command = uiElementInteraction()
            switch command {
            case .stop: return
            case .continue: continue
            }
        }
    }
}

struct NoNavigation: NavigationStrategy {
    func apply(uiElementInteraction: () -> NavigationCommand) {
        _ = uiElementInteraction()
    }
}

struct Wait: NavigationStrategy {
    func apply(uiElementInteraction: () -> NavigationCommand) {
        sleep(2)
        _ = uiElementInteraction()
    }
}
