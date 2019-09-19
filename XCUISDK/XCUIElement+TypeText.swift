//
//  Keyplane.swift
//  WikipediaUITests
//
//  Created by steven on 08.06.19.
//  Copyright © 2019 Wikimedia Foundation. All rights reserved.
//

import Foundation
import XCTest

func Type(_ text: String, in textField: UIElement, in app: XCUIApplication = App(), tap returnKeyLabel: String? = nil, asserts: Asserts? = nil) {
    performStep("type text \"\(text)\" in \(textField.description)",
        in: app,
        on: textField,
        switchToNewState: { textField in
            let keyboard = app.keyboards.element(boundBy: 0)
            
            let typingAction = {
                text.type(in: app)
                if let label = returnKeyLabel {
                    keyboard.buttons[label].tap()
                }
            }
            if keyboard.isVisible() {
                typingAction()
                return
            } else {
                // maybe the text field has no focus yet? Try to tap it!
                textField.tap()
                if waitForElementToHaveFocus(textField) {
                    typingAction()
                    return
                } else {
                    failBecauseKeyboardNotVisible(textToType: text)
                }
            }
    }) {
        asserts?()
    }
}

extension String {
    func type(in app: XCUIApplication) {
        let keyboard = app.keyboards.element(boundBy: 0)
        guard keyboard.isVisible() else {
            failBecauseKeyboardNotVisible(textToType: self)
            return
        }
        self.forEach { $0.tap(on: keyboard) }
    }
}

func failBecauseKeyboardNotVisible(textToType: String) {
    XCTFail("""
        Cannot type \"\(textToType)\" because there is no keyboard visible on screen.
        Check the Simulator's keyboard options in Simulator menu: Hardware -> Keyboard
        Or reset the Simulator in Simulator menu: Hardware -> Erase All Content and Settings
    """)
}

func waitForElementToHaveFocus(_ element: XCUIElement) -> Bool {
    let p = NSPredicate(format: "exists == true && hasKeyboardFocus == true")
    let expectation = XCTNSPredicateExpectation(predicate: p,
                                                object: element)
    
    let result = XCTWaiter().wait(for: [expectation], timeout: 5)
    return result == .completed
}

typealias Keyboard = XCUIElement

extension Character {
    func tap(on keyboard: Keyboard) {
        //        let character = character == "&" ? "ampersand" : "\(character)"
        let key = keyboard.keys[self.keyboardLabel(for: keyboard)]
        var keyExists = key.exists
        var keyplaneSequence = keyplaneSequnce(toGetTo: self, startingAt: currentKeyplane(for: keyboard))
        while keyExists == false, keyplaneSequence.isEmpty == false {
            let switchToKeyplane = keyplaneSequence.removeFirst()
            guard let switchKey = currentKeyplane(for: keyboard).switchKeys.filter({$0.switchesTo == switchToKeyplane}).first else {
                XCTFail("""
                        Cannot find character \(self) on keyboard.
                        because we cannot switch to keyplane \(switchToKeyplane).
                        """)
                return
            }
            _ = switchKey.tap(keyboard, switchKey.switchesTo)
            keyExists = key.exists
        }
        key.tap()
    }
    
    func keyboardLabel(for keyboard: XCUIElement) -> String {
        switch self {
        case " " where keyboard.keys["space"].isVisible():
            return "space"
        case " " where keyboard.keys["Leerzeichen"].isVisible():
            return "Leerzeichen"
        case "&": return "ampersand"
        default: return "\(self)"
        }
    }
}

private struct Keyplane: Equatable, CustomStringConvertible {
    enum Style: Hashable {
        case letter, numeric, symbols
        
        func switchButtonId() -> String {
            switch self {
            case .letter: return "shift"
            case .numeric: return "more"
            case .symbols: return "shift"
            }
        }
    }
    struct SwitchKey {
        let switchesTo: Keyplane.Style
        let tap: (_ keyboard: Keyboard, _ switchTo: Keyplane.Style)->()
    }
    let style: Keyplane.Style
    let switchKeys: [SwitchKey]
    public static func == (lhs: Keyplane, rhs: Keyplane) -> Bool {
        return lhs.style == rhs.style
    }
    var description: String {
        return "\(style)"
    }
}

private let keyplanes: [Keyplane] = [
    Keyplane(style: .letter, switchKeys: [
        Keyplane.SwitchKey(switchesTo: .letter, tap: { (keyboard, switchTo) in
            keyboard.buttons[switchTo.switchButtonId()].tap()
        }),
        Keyplane.SwitchKey(switchesTo: .numeric, tap: { (keyboard, switchTo) in
            keyboard.keys[switchTo.switchButtonId()].tap()
        })
        ]),
    Keyplane(style: .numeric, switchKeys: [
        Keyplane.SwitchKey(switchesTo: .letter, tap: { (keyboard, switchTo) in
            keyboard.keys[switchTo.switchButtonId()].tap()
        }),
        Keyplane.SwitchKey(switchesTo: .symbols, tap: { (keyboard, switchTo) in
            keyboard.buttons[switchTo.switchButtonId()].tap()
        })
        ]),
    Keyplane(style: .symbols, switchKeys: [
        Keyplane.SwitchKey(switchesTo: .letter, tap: { (keyboard, switchTo) in
            keyboard.keys[switchTo.switchButtonId()].tap()
        }),
        Keyplane.SwitchKey(switchesTo: .numeric, tap: { (keyboard, switchTo) in
            keyboard.buttons[switchTo.switchButtonId()].tap()
        })
        ])
]

private func keyplaneSequnce(toGetTo char: Character, startingAt currentKeyplane: Keyplane) -> [Keyplane.Style] {
    switch (CharType.type(for: char), currentKeyplane.style) {
    case (.letter, _):
        return [.letter, .letter]
    case (.number, .numeric):
        return [Keyplane.Style]()
    case (.number, .letter):
        return [.numeric]
    case (.number, .symbols):
        return [.numeric]
    case (.symbol, .symbols):
        return [Keyplane.Style]()
    case (.symbol, .letter):
        return [.numeric, .symbols]
    case (.symbol, .numeric):
        return [.symbols]
    }
}

enum CharType {
    case letter, number, symbol
    static func type(for char: Character) -> CharType {
        if char.isLetter {
            return .letter
        } else if char.isNumber {
            return .number
        } else {
            return .symbol
        }
    }
}

private func currentKeyplane(for keyboard: Keyboard) -> Keyplane {
    let keyplane = { (type: Keyplane.Style) -> Keyplane in
        return keyplanes.filter{$0.style == type}.first!
    }
    if keyboard.keys["A"].exists {
        return keyplane(.letter)
    } else if keyboard.keys["a"].exists {
        return keyplane(.letter)
    } else if keyboard.keys["1"].exists {
        return keyplane(.numeric)
    } else {
        return keyplane(.symbols)
    }
}
