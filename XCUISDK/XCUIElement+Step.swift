//
//  XCUIElement+Step.swift
//  WikipediaUITests
//
//  Created by steven on 08.06.19.
//  Copyright © 2019 Wikimedia Foundation. All rights reserved.
//

import Foundation
import XCTest

var AppId = ""

func App() -> XCUIApplication {
    guard AppId != "" else {
        fatalError("You must set AppId in your tests!")
    }
    return XCUIApplication(bundleIdentifier: AppId)
}

typealias Asserts = ()->()

// MARK: - Interactions

func TapOnCellText(_ text: UIElement,
                    in app: XCUIApplication = App(),
                    asserts: (Asserts)? = nil) {
    
    performStep("Search for cell with text '\(text.description)' in \(text.scrollContainer.description)",
        in: app,
        on: text.scrollContainer,
        switchToNewState: { scrollContainer in
            performStep("tap on '\(text.description)' in \(scrollContainer.description)",
                in: app,
                on: text,
                switchToNewState: { text in
                    text.tap(withNumberOfTaps: 1, numberOfTouches: 1)
            }) {
                asserts?()
            }
    }) {
        asserts?()
    }
}

func Tap(taps: Int = 1, touches: Int = 1, on element: UIElement, in app: XCUIApplication = App(), asserts: (Asserts)? = nil) {
    performStep("tap on \(element.description)",
                in: app,
                on: element,
                switchToNewState: { element in
                    element.tap(withNumberOfTaps: taps, numberOfTouches: touches)
                }) {
                    asserts?()
                }
}

// MARK: - Assertions

func Assert(_ element: UIElement, in app: XCUIApplication = App(), equals expectedLabel: String) {
    performAssert("\(element.description)'s label equals \"\(expectedLabel)\"",
                 in: app,
                 on: element) { (xcuiElement) in
        XCTAssertEqual(xcuiElement.label,
                       expectedLabel,
                       "\(element.description)'s label has an unexpected label")
    }
}

//MARK: - hot sauce 🌶🌶🌶🌶

func performStep(_ description: String,
                 in app: XCUIApplication,
                 on element: UIElement,
                 switchToNewState: ((XCUIElement) -> Void)? = nil,
                 asserts: Asserts? = nil)
{
    _ = XCTContext.runActivity(named: "Step: " + description) { activity in
        let elementFound = search(for: element, in: app) { firstFoundElement in
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

func performAssert(_ description: String, in app: XCUIApplication, on element: UIElement, assert: (XCUIElement) -> Void) {
    _ = XCTContext.runActivity(named: "Asserting: " + description) { activity in
        let elementFound = search(for: element, in: app) { firstVisibleElement in
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
private func search(for element: UIElement, in app: XCUIApplication, andDo uiElementInteraction: (XCUIElement)->()) -> Bool {
    
    //TODO: make navigation strategy dependent on context (e.g. in tableView or pageControl)
    
    
    
    var searchNavigations: [NavigationStrategy] = [
        NoNavigation(),
        Wait()
    ]
    searchNavigations.append(contentsOf: swipeNavigations(for: element))
    
    var uiElementInteractionExecuted = false
    
    while let nav = searchNavigations.first, uiElementInteractionExecuted == false, nav.canBeApplied() {
        nav.apply {
            if let xcUIElement = element.locate(in: app) {
                uiElementInteraction(xcUIElement)
                uiElementInteractionExecuted = true
                return .stop
            } else {
                return .continue
            }
        }
        if !searchNavigations.isEmpty {
            searchNavigations.removeFirst()
        }
    }
    return uiElementInteractionExecuted
}

private func swipeNavigations(for element: UIElement) -> [NavigationStrategy] {
    switch element.scrollAxis {
    case .vertical: return [Swiping(.up, .aBit, times: 5, in: element.scrollContainer, inContextOf: nil),
                            Swiping(.down, .aBit, times: 10, in: element.scrollContainer, inContextOf: nil)]
    case .horizontal: return [Swiping(.left, .aBit, times: 5, in: element.scrollContainer, inContextOf: nil),
                              Swiping(.right, .aBit, times: 10, in: element.scrollContainer, inContextOf: nil)]
    }
}

extension XCUIElementQuery {
    /// Returns a query for all descendants of type `XCUIElement.ElementType.staticText`
    /// whose label matches any label in `labels`
    ///
    /// This method is useful if you want to refer to a cell by one of its contained
    /// labels.
    ///
    /// - Parameter labels: the labels to check for
    func labeled(with labels: [String]) -> XCUIElementQuery? {
        let query = self.containing(NSPredicate(format: "elementType = %d AND label in %@",
                                    XCUIElement.ElementType.staticText.rawValue,
                                    labels))
        if query.count > 0 {
            return query
        }
        return nil
    }
}
