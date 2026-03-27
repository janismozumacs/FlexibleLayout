//
//  FlexibleLayout.swift
//  FlexibleLayout
//
//  Created by Janis Mozumacs on 27/02/2025.
//

import SwiftUI

struct FlexibleElementPreference {
    var sizing: FlexibleElementSizing
    
    init(item: any FlexibleElementDisplay) {
        self.sizing = item.sizing
    }
}

public struct FlexibleLayout<Data: RandomAccessCollection,
                             Content: View>: View where Data.Element: FlexibleElementDisplay {

    private let data: Data
    private let configuration: FlexibleLayoutConfiguration
    private let idealCountInRow: Int?
    private let content: (Data.Element) -> Content

    public init(data: Data,
                configuration: FlexibleLayoutConfiguration,
                idealCountInRow: Int? = nil,
                content: @escaping (Data.Element) -> Content) {
        self.data = data
        self.configuration = configuration
        self.idealCountInRow = idealCountInRow
        self.content = content
    }

    public var body: some View {
        FlexibleLayoutImplementation(
            itemPreference: data.map({ .init(item: $0) }),
            configuration: configuration,
            idealCountInRow: idealCountInRow
        ) {
            ForEach(data, id: \.id) { item in
                if item.sizing == .dynamicWidth {
                    content(item)
                } else {
                    content(item)
                        .frame(maxWidth: .infinity)
                }
                
            }
        }
    }
}
