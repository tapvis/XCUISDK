//
//  XCUISDKUITests.swift
//  XCUISDKUITests
//
//  Created by steven on 22.10.19.
//  Copyright © 2019 Quantosparks. All rights reserved.
//

import XCTest
@testable import XCUISDK

class XCUISDKUITests: XCTestCase {

    override func setUp() {
        AppId = "org.wikimedia.wikipedia"
        continueAfterFailure = false
        XCUIApplication(bundleIdentifier: AppId).launch()
    }

    func testExample() {
        Tap(on: Button(["Skip"]))
        Tap(on: Button(["Settings"]))
        Tap(on: Cell(["About the app"]))
        Tap(on: Button(["Settings"]))
        Tap(on: Cell(["Log in"]))
    }

    struct SearchTextfield: UIElement {
        var identity: Identity {
            return Identity(.searchField, at: 0)
        }
    }
}
