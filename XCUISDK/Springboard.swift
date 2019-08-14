//
//  Springboard.swift
//  WikipediaUITests
//
//  Created by steven on 04.06.19.
//  Copyright © 2019 Wikimedia Foundation. All rights reserved.
//

import XCTest

class Springboard {
    static let springboard = app()
    
    //MARK: Page Objects
    private static let deleteAppButton = DeleteAppButton()
    private static let doneButton = DoneButton()
    
    //MARK: -
    
    private class func app() -> XCUIApplication {
        return XCUIApplication(bundleIdentifier: "com.apple.springboard")
    }
    
    class func terminateAndDeleteApp(_ app: XCUIApplication, withName appDisplayName: String) {
        app.terminate()
        
        let icons = springboard.icons.matching(NSPredicate(format: "label == %@", appDisplayName))
        for index in 0..<icons.count {
            let icon = icons.element(boundBy: index)
            if icon.exists && icon.isHittable {
                // Force delete the app from the springboard
                let iconFrame = icon.frame
                let springboardFrame = springboard.frame
                icon.press(forDuration: 1.3)
                
                // Tap the little "X" button at approximately where it is. The X is not exposed directly
                springboard.coordinate(withNormalizedOffset: CGVector(dx: (iconFrame.minX + 3) / springboardFrame.maxX, dy: (iconFrame.minY + 3) / springboardFrame.maxY)).tap()
                sleep(1)
                if let deleteAppButton = deleteAppButton.locator.locate() {
                    deleteAppButton.tap()
                }
                
            }
        }
        if let doneButton = doneButton.locator.locate() {
            if doneButton.waitForExistence(timeout: 1) {
                doneButton.tap()
            }
        } else {
            XCUIDevice.shared.press(.home)
        }
    }
    
    //MARK: Page Object Definitions
    
    private struct DeleteAppButton {
        let locator: ButtonLocator
        init() {
            locator = ButtonLocator(labels: ["Delete", "Löschen"], app: app())
        }
    }
    
    private struct DoneButton {
        let locator: ButtonLocator
        init() {
            locator = ButtonLocator(labels: ["Done", "Fertig"], app: app())
        }
    }
    
    struct ButtonLocator {
        let labels: [String]
        let app: XCUIApplication
        
        func locate() -> XCUIElement? {
            for label in labels {
                let button = app.buttons[label]
                if button.exists && button.isHittable {
                    return button
                }
            }
            return nil
        }
    }
}
