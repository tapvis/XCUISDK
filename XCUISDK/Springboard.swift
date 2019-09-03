//
//  Springboard.swift
//  WikipediaUITests
//
//  Created by steven on 04.06.19.
//  Copyright © 2019 Wikimedia Foundation. All rights reserved.
//

import XCTest

class Springboard {
    
    //MARK: Page Objects
    private static let deleteAppButton = DeleteAppButton()
    private static let doneButton = DoneButton()
    
    //MARK: -
    
    private class func springboard() -> XCUIApplication {
        return XCUIApplication(bundleIdentifier: "com.apple.springboard")
    }
    
    class func terminateAndDeleteApp(_ app: XCUIApplication = App(), withName appDisplayName: String) {
        app.terminate()
        
        let icons = springboard().icons.matching(NSPredicate(format: "label == %@", appDisplayName))
        for index in 0..<icons.count {
            let icon = icons.element(boundBy: index)
            
            if !(icon.exists && icon.isHittable) {
                search(icon, direction: .left, maxSwipes: 5)
            }
            if !(icon.exists && icon.isHittable) {
                search(icon, direction: .right, maxSwipes: 10)
            }
            
            if icon.exists && icon.isHittable {
                // Force delete the app from the springboard
                let iconFrame = icon.frame
                let springboardFrame = springboard().frame
                icon.press(forDuration: 1.3)
                
                // Tap the little "X" button at approximately where it is. The X is not exposed directly
                springboard().coordinate(withNormalizedOffset: CGVector(dx: (iconFrame.minX + 3) / springboardFrame.maxX, dy: (iconFrame.minY + 3) / springboardFrame.maxY)).tap()
                sleep(1)
                if let deleteAppButton = deleteAppButton.locate(in: springboard()) {
                    deleteAppButton.tap()
                }
            }
        }
        if let doneButton = doneButton.locate(in: springboard()) {
            if doneButton.waitForExistence(timeout: 1) {
                doneButton.tap()
            }
        } else {
            XCUIDevice.shared.press(.home)
        }
    }
    
    private class func search(_ element: XCUIElement, direction: SwipeDirection, maxSwipes: Int = 5) {
        var nrOfSwipes = 0
        while nrOfSwipes < maxSwipes && !(element.exists && element.isHittable) {
            switch direction {
            case .left: springboard().windows.element(boundBy: 0).swipeLeft()
            default: springboard().windows.element(boundBy: 0).swipeRight()
            }
            nrOfSwipes = nrOfSwipes + 1
        }
    }
    
    //MARK: Page Object Definitions
    
    struct DeleteAppButton: UIElement {
        var description: String {
            return "DeleteAppButton"
        }
        var identity: Identity {
            return Identity(.button, labels: ["Delete", "Löschen"])
        }
    }
    
    struct DoneButton: UIElement {
        var description: String {
            return "DoneAppButton"
        }
        var identity: Identity {
            return Identity(.button, labels: ["Done", "Fertig"])
        }
    }
}
