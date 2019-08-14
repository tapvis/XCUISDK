//
//  XCUIElement+Step.swift
//  WikipediaUITests
//
//  Created by steven on 08.06.19.
//  Copyright © 2019 Wikimedia Foundation. All rights reserved.
//

import Foundation
import XCTest

struct UIElement {
    let name: String
    let candidateElements: [XCUIElement]
    
    init(name: String, candidateElements: [XCUIElement]) {
        self.name = name
        self.candidateElements = candidateElements
    }
}

typealias Asserts = ()->()

// MARK: - Interactions

func Tap(taps: Int = 1, touches: Int = 1, on element: UIElement, in app: XCUIApplication, asserts: (Asserts)? = nil) {
    performStep("tap on \(element.name)",
                in: app,
                candidateElements: element.candidateElements,
                switchToNewState: { element in
                    element.tap(withNumberOfTaps: taps, numberOfTouches: touches)
                }) {
                    asserts?()
                }
}

func Type(_ text: String, in textField: UIElement, in app: XCUIApplication, tap returnKeyLabel: String? = nil, asserts: Asserts? = nil) {
    performStep("type text \"\(text)\" in \(textField.name)",
                in: app,
                candidateElements: textField.candidateElements,
                switchToNewState: { element in
                    let keyboard = app.keyboards.element(boundBy: 0)
                    guard keyboard.exists else {
                        XCTFail("""
                            Cannot type \(text) because there is no keyboard visible on screen.
                            Check the Simulator's keyboard options in menu:
                            Hardware -> Keyboard
                            """)
                        return
                    }
                    text.type(in: app)
                    if let label = returnKeyLabel {
                        keyboard.buttons[label].tap()
                    }
                }) {
                    asserts?()
                }
}

func Swipe(_ direction: SwipeDirection, _ distance: SwipeDistance, on element: UIElement, in app: XCUIApplication, asserts: Asserts? = nil) {
    performStep("swipe \(direction.rawValue) \(distance.rawValue) on \(element.name)",
                in: app,
                candidateElements: element.candidateElements,
                switchToNewState: { element in
                    element.swipe(direction, distance)
                }) {
                    asserts?()
                }
}

// MARK: - Assertions

func Assert(_ element: UIElement, in app: XCUIApplication, equals expectedLabel: String) {
    performAssert("\(element.name)'s label equals \"\(expectedLabel)\"",
                 in: app,
                 candidateElements: element.candidateElements) { (xcuiElement) in
        XCTAssertEqual(xcuiElement.label,
                       expectedLabel,
                       "\(element.name)'s label has an unexpected label")
    }
}

//MARK: - hot sauce 🌶🌶🌶🌶

private func performStep(_ description: String, in app: XCUIApplication, candidateElements elements: [XCUIElement], switchToNewState: ((XCUIElement) -> Void)? = nil, asserts: Asserts? = nil) {
    _ = XCTContext.runActivity(named: "Step: " + description) { activity in
        let elementFound = searchForElement(in: elements, in: app) { firstFoundElement in
            let screenshot = XCUIScreen.main.screenshot().image
            highlight(firstFoundElement, on: screenshot, in: activity, withId: description)
            switchToNewState?(firstFoundElement)
            usleep(500000)
            asserts?()
        }
        if elementFound == false {
            XCTFail("Cannot perform \(description) because no matching UI element is visible")
        }
    }
}

private func window(of app: XCUIApplication) -> UIElement {
    return UIElement(name: "app window", candidateElements: [app.windows.firstMatch])
}

private func performAssert(_ description: String, in app: XCUIApplication, candidateElements elements: [XCUIElement], assert: (XCUIElement) -> Void) {
    _ = XCTContext.runActivity(named: "Asserting: " + description) { activity in
        let elementFound = searchForElement(in: elements, in: app) { firstVisibleElement in
            let labelAttachement = XCTAttachment(string: firstVisibleElement.label)
            labelAttachement.name = "ActualLabel: "
            labelAttachement.lifetime = .keepAlways
            activity.add(labelAttachement)
            assert(firstVisibleElement)
        }
        if elementFound == false {
            XCTFail("Cannot assert \(description) because element to assert is not visible")
        }
    }
}

/// returns true if an element was found, false otherwise
private func searchForElement(in elements: [XCUIElement], in app: XCUIApplication, andDo uiElementInteraction: (XCUIElement)->()) -> Bool {
    
    var searchNavigations: [NavigationStrategy] = [
        NoNavigation(),
        CautiosSwiping(.up, in: app, inContextOf: nil)
    ]
    var uiElementInteractionExecuted = false
    
    while let nav = searchNavigations.first, uiElementInteractionExecuted == false, nav.canBeApplied() {
        nav.apply {
            let executed = execute(uiElementInteraction, onFirstMatchIn: elements, in: app)
            switch executed {
            case true:
                uiElementInteractionExecuted = true
                return .stop
            case false:
                uiElementInteractionExecuted = false
                return .continue
            }
        }
        if !searchNavigations.isEmpty {
            searchNavigations.removeFirst()
        }
    }
    return uiElementInteractionExecuted
}

private func execute(_ block: (XCUIElement)->(), onFirstMatchIn elements: [XCUIElement], in app: XCUIApplication) -> Bool {
    var candidateElements = elements
    var visible = false
    while let element = candidateElements.first, visible == false {
        let exists = element.waitForExistence(timeout: 3)
        visible = exists && element.isHittable
        if visible {
            block(element)
            return true
        } else {
            if !candidateElements.isEmpty {
                candidateElements.removeFirst()
            }
        }
    }
    return false
}

private func highlight(_ element: XCUIElement?, on screenshot: UIImage, in activity: XCTActivity, withId id: String) {
    var modifiedScreenshot = screenshot
    if let element = element, let highlightedScreenshot = highlight(rect: element.frame, in: screenshot) {
        modifiedScreenshot = highlightedScreenshot
    }
    let fullScreenshotAttachment = XCTAttachment(image: modifiedScreenshot)
    fullScreenshotAttachment.name = id
    fullScreenshotAttachment.lifetime = .keepAlways
    activity.add(fullScreenshotAttachment)
}

private func highlight(rect: CGRect, in screenshot: UIImage) -> UIImage? {
    let renderer = UIGraphicsImageRenderer(size: screenshot.size)
    let img = renderer.image { ctx in
        let rectangle = CGRect(origin: rect.origin, size: rect.size)
        screenshot.draw(at: CGPoint.zero)
        ctx.cgContext.setFillColor(UIColor.clear.cgColor)
        ctx.cgContext.setStrokeColor(UIColor.green.cgColor)
        ctx.cgContext.setLineWidth(10)
        ctx.cgContext.setLineDash(phase: 1, lengths: [2, 3])
        ctx.cgContext.addRect(rectangle)
        ctx.cgContext.drawPath(using: .stroke)
    }
    return img
}
