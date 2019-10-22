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
    var relativeOrigin: CGPoint? { get }
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
    
    init(_ type: XCUIElement.ElementType, at index: Int) {
        self.type   = type
        self.path   = Identity.Path(query: App().descendants(matching: type), index: index)
        self.id     = nil
        self.labels = nil
    }
    
    init(_ type: XCUIElement.ElementType, id: String? = nil, labels: [String]? = nil, path: Path? = nil) {
        self.type = type
        self.id = id
        self.labels = labels
        self.path = path
    }
    
    //MARK: -
    
    struct Path {
        let query: XCUIElementQuery?
        let index: Int
        
        func resolve() -> XCUIElement? {
            guard let query = query else {
                return nil
            }
            if index >= 0 && index < query.count {
                return query.element(boundBy: index)
            }
            return nil
        }
    }
}

let kWaitForElementExistenceTimeoutSec: TimeInterval = 0

extension UIElement {
    
    var description: String {
        return String(describing: type(of: self)) +
               " '" +
               (self.identity.labels?.joined(separator: ",") ?? "") +
               "'"
    }
    
    var scrollContainer: UIElement {
        return AppWindow()
    }
    
    var scrollAxis: ScrollAxis {
        return .vertical
    }
    
    var relativeOrigin: CGPoint? {
        return nil
    }
    
    /// Tries to locate the UIElement on screen.
    ///
    /// Tries to locate an element with the following strategy:
    /// 1. search with the element's accessibility Id
    /// 2. search with the element's accessibility label
    /// 3. search with the element's origin
    /// 4. search for an XCUIElement with the elements path through the UI
    ///
    /// If an XCUIElement can be located, it is checked if it is visible.
    /// If it is not visible, nil is returned.
    func locate(in app: XCUIApplication = App()) -> XCUIElement? {
        //1. try to locate the element by id
        if let element = elementById(in: app) {
            return element
        }
        
        //2. try to locate the element by its labels
        if let element = elementByLabels(in: app) {
            return element
        }
        
        if self.scrollContainer.identity.type != .window {
            if let element = elementByPath(in: app) {
                return element
            }
//            return elementByOrigin(in: app)
            return nil
        } else {
            if let element = elementByOrigin(in: app) {
                return element
            }
            return elementByPath(in: app)
        }
    }
    
    /// This method searches for a matching element by using the relativeOrigin.
    /// The origin of a match must be within a range of +/- 25% of the relativeOrigin.
    /// These 25% is a heuristic which we found to work in a lot of cases.
    /// We call these 25% the 'tolerance range'.
    private func elementByOrigin(in app: XCUIApplication) -> XCUIElement? {
        guard let relativeOrigin = self.relativeOrigin else {
            return nil
        }
        let toleranceRange = self.toleranceRange()
        
        let xMin = max(relativeOrigin.x - toleranceRange, 0)
        let xMax = min(relativeOrigin.x + toleranceRange, 1.0)
        let yMin = max(relativeOrigin.y - toleranceRange, 0)
        let yMax = min(relativeOrigin.y + toleranceRange, 1.0)
        
        let elementsWithOriginInRange = app.descendants(matching: self.identity.type)
            .matching(NSPredicate(block: { (obj, bindings) -> Bool in
                guard let element = obj as? XCUIElementAttributes else {
                    return false
                }
                let relativeX = element.frame.origin.x / app.frame.width
                let relativeY = element.frame.origin.y / app.frame.height
                return relativeX >= xMin && relativeX <= xMax &&
                    relativeY >= yMin && relativeY <= yMax
            }))
        if elementsWithOriginInRange.count > 0 {
            if elementsWithOriginInRange.count > 1 {
                print("""
                    🚨 found multiple elements with type \(identity.type) and origin within tolerance range.
                    Returning the first one.
                    """)
            }
            let element = elementsWithOriginInRange.element(boundBy: 0)
            _ = element.waitForExistence(timeout: kWaitForElementExistenceTimeoutSec)
            if element.isVisible() {
                return element
            }
            
            print("""
                🚨 found an element with type \(identity.type) and origin in tolerance range. But it's not visible.
                """)
            return nil
        }
        return nil
    }
    
    private func toleranceRange() -> CGFloat {
        switch XCUIDevice.currentDeviceModel() {
        case .iPhone4_4s:       return 0.1
        case .iPhone5_5c_5s_SE: return 0.1
        case .iPhone6_6s_7_8:   return 0.05
        default:                return 0.05
        }
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
            if element.isVisible() {
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
            var elementsByLabel = app
                                    .descendants(matching: identity.type)
                                    .matching(NSPredicate(format: "label == %@", label))
            if elementsByLabel.count == 0 {
                elementsByLabel = app
                                    .descendants(matching: identity.type)
                                    .matching(NSPredicate(format: "label CONTAINS %@", label))
            }
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
                if element.isVisible() {
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
        return Identity(.staticText, id: id, labels: labels, path: path)
    }
}
