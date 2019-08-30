//
//  Screenshot.swift
//  UIKitCatalogUITests
//
//  Created by steven on 15.08.19.
//  Copyright © 2019 Apple. All rights reserved.
//

import Foundation
import XCTest
import UIKit

func highlight(_ element: XCUIElement?, on screenshot: UIImage, in activity: XCTActivity, withId id: String) {
    var modifiedScreenshot = screenshot
    if let element = element, let highlightedScreenshot = highlight(rect: element.frame, in: screenshot) {
        modifiedScreenshot = highlightedScreenshot
    }
    let fullScreenshotAttachment = XCTAttachment(image: modifiedScreenshot)
    fullScreenshotAttachment.name = id
    fullScreenshotAttachment.lifetime = .keepAlways
    activity.add(fullScreenshotAttachment)
}

func highlight(rect: CGRect, in screenshot: UIImage) -> UIImage? {
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
