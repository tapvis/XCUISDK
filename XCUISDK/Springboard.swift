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
    
    //MARK: Page Object Definitions
    
    struct DeleteAppButton: UIElement {
        var description: String {
            return "DeleteAppButton"
        }
        var identity: UIElementIdentity {
            return UIElementIdentity(type: .button, labels: ["Delete", "Löschen"])
        }
    }
    
    struct DoneButton: UIElement {
        var description: String {
            return "DeleteAppButton"
        }
        var identity: UIElementIdentity {
            return UIElementIdentity(type: .button, labels: ["Done", "Fertig"])
        }
    }
}
