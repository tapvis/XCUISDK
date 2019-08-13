# XCUISDK

The XCUISDK is an SDK that sits on top of Apple's [XCTest Framework](https://developer.apple.com/documentation/xctest) to simplify the creation of [automated User Interface Tests](https://developer.apple.com/documentation/xctest/user_interface_tests) for iOS apps. The goal of XCUISDK is to give testers and developers a simple way to create automated UI tests that run on different devices and in different languages without the need to know all the details of the [XCUITest API](https://developer.apple.com/documentation/xctest/user_interface_tests). 

XCUISDK is an essential part of [tapvis](https://tapvis.com). tapvis is an iOS UI automation tool that simplifies the creation of automated UI tests for iOS apps. [tapvis](https://tapvis.com) is a ***"Record & Generate" tool*** : testers and developers record a test right inside an iOS app. tapvis generates ready-to-run test code that links against this SDK.

This SDK is open source so that even if you started creating your tests with tapvis and decided to not use it anymore, you are still in full control of your UI tests.



## Installation

### Clone

Clone this repository on your Mac and drag'n'drop the ```XCUISDK``` folder into Xcode and add it to your UITest target.

### Copy from tapvis

tapvis ships with the XCUISDK. Open ```~/Library/Application Support/tapvis``` in Finder (press ```cmd + shift + G``` and paste  ```~/Library/Application Support/tapvis``` to open the tapvis folder). Drag'n'drop the ```XCUISDK``` folder into Xcode and add it to your UITest target.

## Usage

The XCUISDK sits on top of Apple's [XCTest Framework](https://developer.apple.com/documentation/xctest). You can still use the plain [XCUITest API](https://developer.apple.com/documentation/xctest/user_interface_tests). What the XCUISDK is doing better than the XCUITest API, is that it automatically searches for an UI element if it cannot find one immediately. Assume you are creating a test that taps on a cell in a table view. If this cell is not visible during test execution because you are running the test on a smaller device (e.g. iPhone 5S), XCUISDK will start scrolling to search for the element automatically.

### UIElement

XCUISDK is not working directly with an ```XCUIElement```. Instead it uses a wrapper around ```XCUIElement```. This wrapper is called ```UIElement```:

```swift
struct UIElement {
    let name: String
    let candidateElements: [XCUIElement]
    
    init(name: String, candidateElements: [XCUIElement]) {
        self.name = name
        self.candidateElements = candidateElements
    }
}
```

You assign it a name (for better error reporting) and a array of ```candidate elements```. Candidate elements is an array of XCUIElements that are used to locate an element on screen. If an element cannot be found, the XCUISDK tries to find the other candidate elements until one is visible, or none is visible which leads to a failing test.

See the following example of a function that returns an instance of ```UIElement```:

```swift
private func _Skip_button() -> UIElement {
  	let elementById    = app.buttons["Skip_btn_intro"]		
    let elementByLabel = app.buttons["Skip"]
    let elementByPath  = app
    										 .windows.element(boundBy: 0)
										     .buttons.element(boundBy: 0)
    return UIElement(name: "Skip_button", 
        								 candidateElements: [elementById, elementByLabel, elementByPath])
}
```

The app that is supposed to be tested contains a button that is used to skip a screen. This button can be referenced in three different ways: 

1. by accessibility ID
2. by accessibility label
3. by a path through the UI. 

The XCUISDK tries to find the button in this order. If the button cannot be found by ID, the label is tried. If it cannot be found by the label, the path is tried.

If you use tapvis to record a test, tapvis will generate this function every UI element that you interact with during your test.

### Tap

Use the ```Tap``` function to tap on a UI element. If the UI element is not visible on screen, this method will automatically scroll to the element.

```
Tap(on: _Skip_button(), in: app)
```





### Swipe

If you want to swipe on a UI element, use the ```Swipe``` function.

```swift
Swipe(.down, .aBit, on: _UIWindow_0(), in: app)
```

You can swipe up, down, left, and right. You can swipe a bit and a lot. Try it out!

### Type Text

In contrast to [ ```XCUIElement's type text```](https://developer.apple.com/documentation/xctest/xcuielement/1500968-typetext) , the ```Type``` function interacts with every key of the keyboard when typing a text and not just putting the text into the UI element (e.g. a text field). We added this function because apps behave differently if a text is entered character by character. For instance, your app might start searching directly after the first character is entered by the user.

```swift
Type("test", in: _UISearchBarTextField_1(), in: app, tap: "Search")
```

Make sure that the iOS Simulator is not connected to the hardware keyboard (the keyboard on your Mac) and that the software keyboard (the keyboard in the Simulator) is visible. You can control both settings in the Simulator's menu: ```Hardware -> Keyboard -> ...```



# To Do

The XCUISDK is far from being finished. We extend it constantly as [tapvis](https://tapvis.com) progresses in its development. 

```
- [x] Tap with automatic scroll to element
- [x] Type text on keyboard
- [x] Swipe in different directions with configurable distance
- [ ] Interact with pickers
- [ ] Interact with sliders
- [ ] ...
```