//
//  UIElement.swift
//  UIKitCatalogUITests
//
//  Created by steven on 14.08.19.
//  Copyright © 2019 Apple. All rights reserved.
//

import Foundation
import XCTest

enum ScrollAxis {
    case horizontal, vertical
}

protocol UIElement {
    var description: String { get }
    var identity: Identity { get }
    var scrollContainer: UIElement { get }
    var scrollAxis: ScrollAxis { get }
}

/// This struct can be used to desribe the
/// identity of an UI element
struct Identity {
    
    let type: XCUIElement.ElementType
    
    /// A unique ID for an UI element.
    /// This id must be unique for one screen of
    /// the app under test. "One screen" means all
    /// UI elements that are accessible at one moment
    /// in time.
    /// This means that this id must not be unique across
    /// space and time. 🌍
    let id: String?
    
    /// A UI element can have as many labels
    /// as the app under test has supported languages
    ///
    ///For instance a button can have an english and a german label:
    ///
    /// ```labels = ["Done", "FERTIG!"]```
    let labels: [String]?
    
    /// The path that you need to take through the UI
    /// to locate an UI element. Note, that it is best
    /// if you rely soly on id in your tests because
    /// the patch can break easily - resulting in tests
    /// that fail because an UI element cannot be located
    /// and because of a bug in the app under test.
    let path: Path?
    
    init(_ type: XCUIElement.ElementType, id: String? = nil, labels: [String]? = nil, path: Path? = nil) {
        self.type = type
        self.id = id
        self.labels = labels
        self.path = path
    }
    
    //MARK: -
    
    struct Path {
        let query: XCUIElementQuery
        let index: Int
        
        func resolve() -> XCUIElement? {
            if index >= 0 && index < query.count {
                return query.element(boundBy: index)
            }
            return nil
        }
    }
}

let kWaitForElementExistenceTimeoutSec: TimeInterval = 0

extension UIElement {
    
    var scrollContainer: UIElement {
        return AppWindow()
    }
    
    var scrollAxis: ScrollAxis {
        return  .vertical
    }
    
    /// Tries to locate the UIElement on screen.
    ///
    /// Tries to locate an element with the following strategy:
    /// 1. search for an XCUIElement with the elements accessibility Id
    /// 2. search for an XCUIElement with the elements accessibility label
    /// 3. search for an XCUIElement with the elements path through the UI
    ///
    /// If an XCUIElement can be located, it is checked if it is visible.
    /// If it is not visible, nil is returned.
    func locate(in app: XCUIApplication) -> XCUIElement? {
        //1. try to locate the element by id
        if let element = elementById(in: app) {
            return element
        }
        
        //2. try to locate the element by its labels
        if let element = elementByLabels(in: app) {
            return element
        }
        
        //3. try to locate the element by its path
        return elementByPath(in: app)
    }
    
    private func elementById(in app: XCUIApplication) -> XCUIElement? {
        guard let id = identity.id else {
            return nil
        }
        let elementsById = app
                            .descendants(matching: identity.type)
                            .matching(NSPredicate(format: "identifier == %@", id))
        if elementsById.count > 0 {
            if elementsById.count > 1 {
                //TODO: can we put such logs in the testreport?
                print("""
                    🚨 found multiple elements with type \(identity.type) and id \(id).
                    Returning the first one.
                    """)
            }
            
            let element = elementsById.element(boundBy: 0)
            _ = element.waitForExistence(timeout: kWaitForElementExistenceTimeoutSec)
            if element.exists && element.isHittable {
                return element
            }
            
            print("""
                🚨 found an element with type \(identity.type) and id \(id). But it's not visible.
                """)
            return nil
        }
        return nil
    }
    
    private func elementByLabels(in app: XCUIApplication) -> XCUIElement? {
        guard let labels = identity.labels else {
            return nil
        }
        for label in labels {
            let elementsByLabel = app
                                    .descendants(matching: identity.type)
                                    .matching(NSPredicate(format: "label == %@", label))
            if elementsByLabel.count > 0 {
                if elementsByLabel.count > 1 {
                    //TODO: can we put such logs in the testreport?
                    print("""
                        🚨 found multiple elements with type \(identity.type) and label \(label).
                        Returning the first one.
                        """)
                }
                let element = elementsByLabel.element(boundBy: 0)
                _ = element.waitForExistence(timeout: kWaitForElementExistenceTimeoutSec)
                if element.exists && element.isHittable {
                    return element
                } else {
                    print("""
                        🚨 found an element with type \(identity.type) and label \(label). But it's not visible.
                        """)
                }
            }
        }
        return nil
    }
    
    private func elementByPath(in app: XCUIApplication) -> XCUIElement? {
        guard let element = identity.path?.resolve(), element.exists, element.isHittable else {
            return nil
        }
        return element
    }
}


struct AppWindow: UIElement {
    var description: String {
        return "The app's main window"
    }
    var identity: Identity {
        return Identity(.window,
                        path: Identity.Path(query: App().windows, index: 0))
    }
}

typealias T = Text

struct Text: UIElement {
    internal let labels: [String]
    internal let scrollContainer: UIElement
    internal let scrollAxis: ScrollAxis
    internal let id: String?
    internal let path: Identity.Path?
    
    init(id: String? = nil,
         _ labels: [String],
        path: Identity.Path? = nil,
        scrollContainer: UIElement = AppWindow(),
        scrollAxis: ScrollAxis = .vertical)
    {
        self.id = id
        self.labels = labels
        self.path = path
        self.scrollContainer = scrollContainer
        self.scrollAxis = scrollAxis
    }
    
    var description: String {
        return "\(labels)"
    }
    var identity: Identity {
        return Identity(.staticText, labels: labels)
    }
}
