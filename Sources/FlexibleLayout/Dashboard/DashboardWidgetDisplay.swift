//
//  DashboardWidgetDisplay.swift
//  FlexibleLayout
//
//  Created by Janis Mozumacs on 27/07/2025.
//

import Foundation
import SwiftUI

public protocol DashboardWidgetDisplay {
    var widgetId: String { get }
    var id: String { get }
    var size: WidgetSizing { get }
    var makeView: AnyView { get }
    var ignoreSidePaddingForRow: Bool { get }
}
public extension DashboardWidgetDisplay {
    var makeView: AnyView { AnyView(EmptyView()) }
    var size: WidgetSizing { .medium }
    var ignoreSidePaddingForRow: Bool { false }
    var id: String { widgetId }
    
    func asAnyWidget() -> AnyWidget? {
        return AnyWidget(self)
    }
}
