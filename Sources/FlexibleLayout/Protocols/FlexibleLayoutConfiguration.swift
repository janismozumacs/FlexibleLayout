//
//  FlexibleLayoutConfiguration.swift
//  FlexibleLayout
//
//  Created by Janis Mozumacs on 27/02/2025.
//

import SwiftUI

// This protocol defines the configuration for a flexible layout.
// It specifies the spacing and alignment options for laying out views.
public protocol FlexibleLayoutConfiguration {
    // The horizontal padding applied to the entire layout.
    var sidePadding: CGFloat { get }
    
    // The horizontal spacing between individual items.
    var spacingHorizontal: CGFloat { get }
    
    // The vertical spacing between individual items.
    var spacingVertical: CGFloat { get }
    
    // The horizontal alignment for each row of items.
    var rowHorizontalAlignment: HorizontalAlignment { get }
    
    // The vertical alignment for each row of items.
    var rowVerticalAlignment: VerticalAlignment { get }
}

// This struct provides a default configuration for the flexible layout,
// conforming to the FlexibleLayoutConfiguration protocol.
public struct FlexibleLayoutDefaultConfiguration: FlexibleLayoutConfiguration {
    // Set a default side padding of 16 points.
    public var sidePadding: CGFloat { 16.0 }
    
    // Set a default horizontal spacing of 16 points between items.
    public var spacingHorizontal: CGFloat { 16.0 }
    
    // Set a default vertical spacing of 16 points between items.
    public var spacingVertical: CGFloat { 16.0 }
    
    // Default horizontal alignment for rows is centered.
    public var rowHorizontalAlignment: HorizontalAlignment { .leading }
    
    // Default vertical alignment for rows is centered.
    public var rowVerticalAlignment: VerticalAlignment { .center }
}

