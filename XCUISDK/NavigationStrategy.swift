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
        var timesSwiped = 0
        while shouldStop() == false,  timesSwiped < times {
            Swipe(direction, distance, on: container)
            timesSwiped = timesSwiped + 1
            let command = uiElementInteraction()
            switch command {
            case .stop: return
            case .continue: continue
            }
        }
    }
    
    private func shouldStop() -> Bool {
        switch direction {
        case .up:    return isAtBottomOf(container)
        case .down:  return isAtTopOf(container)
        case .left:  return isAtBottomOf(container)
        case .right: return isAtTopOf(container)
        }
    }
    
    private func isAtBottomOf(_ container: UIElement) -> Bool {
        guard let containerElement = self.containerElement else {
            return false
        }
        switch containerElement.elementType {
        case .table, .collectionView:
            if let lastCell = containerElement.cells.allElementsBoundByIndex.last {
                return lastCell.isVisible()
            } else {
                return false
            }
        default: return false
        }
    }
    
    private func isAtTopOf(_ container: UIElement) -> Bool {
        guard let containerElement = container.locate(in: App()) else {
            return false
        }
        switch containerElement.elementType {
        case .table, .collectionView:
            if let lastCell = containerElement.cells.allElementsBoundByIndex.first {
                return lastCell.isVisible()
            } else {
                return false
            }
        default: return false
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
