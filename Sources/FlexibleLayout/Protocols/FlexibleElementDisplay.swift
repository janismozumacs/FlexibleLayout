//
//  FlexibleElementDisplay.swift
//  FlexibleLayout
//
//  Created by Janis Mozumacs on 27/02/2025.
//

import Foundation

// This protocol represents an element that can be displayed in the flexible layout.
// It requires a unique identifier and a sizing strategy.
public protocol FlexibleElementDisplay: Hashable {
    // A unique identifier for the element.
    var id: String { get }
    // The sizing strategy for the element, determining how its width is calculated.
    var sizing: FlexibleElementSizing { get }
}

// Provide a default implementation for the sizing property.
// If a type conforming to FlexibleElementDisplay doesn't specify its own sizing,
// it will default to using dynamicWidth.
extension FlexibleElementDisplay {
    var sizing: FlexibleElementSizing { .dynamicWidth }
}

// New enum definitions for flexible element sizing.
public enum FlexibleElementSizing: Hashable {
    // The element's width is determined dynamically based on its intrinsic content size.
    case dynamicWidth
    // For widget elements, a widget sizing is provided.
    case widget(type: WidgetSizing)
}

public enum WidgetSizing {
    case small // half width on iPhone, 1/4 width on iPad
    case medium // full width on iPhone, 1/2 width on iPad
    case large // full width on both iPhone and iPad
    case smallPhoneMediumPad // half width on iPhone and halp wifht on iPad
    case largeIgnoresSidePaddings  // full width, ignores side padding entirely
}
