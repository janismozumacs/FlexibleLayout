//
//  AnyWidget.swift
//  FlexibleLayout
//
//  Created by Janis Mozumacs on 27/07/2025.
//
import SwiftUI

// MARK: - type eraser for dashboard widget
// this helps to wrap concrete widget view models for display
public struct AnyWidget: FlexibleElementDisplay {
    
    // unique string for view model logic
    var widgetId: String { widget.widgetId }
    
    // unique string, when this changes, widget is bound to reload
    public var id: String { widget.id }
    
    // convenience for making widget view
    var makeView: AnyView { widget.makeView }
    
    // widget display model
    var widget: DashboardWidgetDisplay
    
    // widget sizing type
    public var sizing: FlexibleElementSizing
    
    var ignoreSidePaddingForRow: Bool { widget.ignoreSidePaddingForRow }
    
    init?<Widget: DashboardWidgetDisplay>(_ widget: Widget?) {
        guard let widget = widget else { return nil }
        self.widget = widget
        self.sizing = .widget(type: widget.size)
        
        if widget.ignoreSidePaddingForRow == true {
            self.sizing = .widget(type: .largeIgnoresSidePaddings)
        }
    }
    
    static public func == (lhs: AnyWidget, rhs: AnyWidget) -> Bool {
        return lhs.id == rhs.id
    }
    
    public func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
    
    @MainActor
    func calculateWidth(for availableWidth: CGFloat) -> CGFloat? {
        if UIDevice.current.userInterfaceIdiom == .pad {
            switch widget.size {
            case .small:
                return availableWidth / 4
            case .medium, .smallPhoneMediumPad:
                return availableWidth / 2
            case .large:
                return availableWidth
            case .largeIgnoresSidePaddings:
                return availableWidth
            }
        } else {
            switch widget.size {
            case .small, .smallPhoneMediumPad:
                return availableWidth / 2
            case .medium:
                return availableWidth
            case .large:
                return availableWidth
            case .largeIgnoresSidePaddings:
                return availableWidth
            }
        }
    }
}

extension AnyWidget: Reorderable {
    
    typealias OrderElement = String
    
    var orderElement: OrderElement { widgetId }
}
