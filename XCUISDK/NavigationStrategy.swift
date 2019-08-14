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
    
    func window(for app: XCUIApplication) -> UIElement {
        return UIElement(name: "app window", candidateElements: [app.windows.firstMatch])
    }
}

//MARK: -

struct CautiosSwiping: NavigationStrategy {
    private let app: XCUIApplication
    private let direction: SwipeDirection
   
    init(_ direction: SwipeDirection, in app: XCUIApplication, inContextOf context: XCUIElement?) {
        self.direction = direction
        self.app = app
    }
    
    func apply(uiElementInteraction: () -> NavigationCommand) {
        for _ in 0..<5 {
            Swipe(.up, .aBit, on: window(for: app), in: app)
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
