//
//  FlexibleLayout.swift
//  FlexibleLayout
//
//  Created by Janis Mozumacs on 27/02/2025.
//

import SwiftUI

// MARK: - Flexible Layout Result

/// This struct computes the layout by grouping subviews into rows and
/// calculating the total size used by a scroll view.
@available(iOS 16, *)
internal struct FlexibleLayoutResult {
    let totalSize: CGSize         // The overall size of the layout (used as scroll content size).
    let rows: [Row]               // Rows in the layout.

    struct Row {
        let indices: [Int]          // The indices of subviews in this row.
        let offsets: [CGFloat]      // X-offsets for each subview in the row.
        let frame: CGRect           // The frame of the row.
        let subviewSizes: [CGSize]  // The sizes for each subview in the row.
        let isFullWidth: Bool       // Indicates if this row is a full-width row.
    }

    /// Initializes the layout result.
    /// - Parameters:
    ///   - availableWidth: The total available width (typically the container's width).
    ///   - subviews: The collection of subviews to layout.
    ///   - configuration: Layout configuration containing paddings, spacing, and row alignments.
    ///   - itemPreference: The array of element sizing preferences (using FlexibleElementSizing).
    ///   - idealCountInRow: Optional ideal count of items per row.
    init(availableWidth: CGFloat,
         subviews: LayoutSubviews,
         configuration: FlexibleLayoutConfiguration,
         itemPreference: [FlexibleElementPreference],
         idealCountInRow: Int?,
         isIpad: Bool) {
        let result = Self.calculateLayout(availableWidth: availableWidth,
                                          subviews: subviews,
                                          configuration: configuration,
                                          itemPreference: itemPreference,
                                          idealCountInRow: idealCountInRow,
                                          isIpad: isIpad)
        self.totalSize = result.totalSize
        self.rows = result.rows
    }

    /// Computes the layout (rows and overall size) based on the available width, subviews,
    /// configuration, sizing preferences, and an optional ideal count per row.
    private static func calculateLayout(availableWidth: CGFloat,
                                        subviews: LayoutSubviews,
                                        configuration: FlexibleLayoutConfiguration,
                                        itemPreference: [FlexibleElementPreference],
                                        idealCountInRow: Int?,
                                        isIpad: Bool) -> (totalSize: CGSize, rows: [Row]) {
        var rows: [Row] = []
        // Trackers for normal (non-full-width) rows.
        var currentIndices: [Int] = []
        var currentOffsets: [CGFloat] = []
        var currentSizes: [CGSize] = []
        var currentRowWidth: CGFloat = 0      // Accumulated width of items (excluding the left padding) in current row.
        var currentRowHeight: CGFloat = 0     // Maximum height in the current row.
        var totalHeight: CGFloat = 0          // Accumulated height of all rows.

        // Helper closure that returns the inter-item spacing (always returns configuration.spacingHorizontal).
        // The left side padding is applied only once when the first element is added.
        func interItemSpacing() -> CGFloat {
            return configuration.spacingHorizontal
        }

        // Finalize the current normal row, create a row object, and reset trackers.
        func finalizeRow() {
            guard !currentIndices.isEmpty else { return }
            // For normal rows, add right side padding.
            let rowWidth = currentRowWidth + configuration.sidePadding
            let rowFrame = CGRect(x: 0, y: totalHeight, width: rowWidth, height: currentRowHeight)
            rows.append(Row(indices: currentIndices,
                            offsets: currentOffsets,
                            frame: rowFrame,
                            subviewSizes: currentSizes,
                            isFullWidth: false))
            totalHeight += currentRowHeight + configuration.spacingVertical

            // Reset trackers for the next row.
            currentIndices = []
            currentOffsets = []
            currentSizes = []
            currentRowWidth = 0
            currentRowHeight = 0
        }

        // Helper function to compute the desired widget width for a given widget sizing.
        // This function accounts for side paddings and inter-item spacing.
        func desiredWidth(for widgetSizing: WidgetSizing) -> CGFloat {
            switch widgetSizing {
            case .small:
                // iPad: 4 per row; iPhone: 2 per row.
                if isIpad {
                    return (availableWidth - 2 * configuration.sidePadding - 3 * configuration.spacingHorizontal) / 4
                } else {
                    return (availableWidth - 2 * configuration.sidePadding - configuration.spacingHorizontal) / 2
                }
            case .medium:
                // iPad: 2 per row; iPhone: 1 per row.
                if isIpad {
                    return (availableWidth - 2 * configuration.sidePadding - configuration.spacingHorizontal) / 2
                } else {
                    return availableWidth - 2 * configuration.sidePadding
                }
            case .large:
                // Always full width with side paddings.
                return availableWidth - 2 * configuration.sidePadding
            case .largeIgnoresSidePaddings:
                // Full available width.
                return availableWidth
            case .smallPhoneMediumPad:
                // iPad: 2 per row; iPhone: 2 per row.
                return (availableWidth - 2 * configuration.sidePadding - configuration.spacingHorizontal) / 2
            }
        }

        // Process each subview in the given collection.
        for index in subviews.indices {
            // Get the sizing preference for the current subview.
            let sizingCase = itemPreference[index].sizing
            var elementSize: CGSize = .zero

            switch sizingCase {
            case .dynamicWidth:
                // For dynamic width, remove both left and right side paddings.
                let contentWidth = availableWidth - 2 * configuration.sidePadding
                elementSize = subviews[index].sizeThatFits(ProposedViewSize(width: contentWidth, height: nil))
            case .widget(let widgetSizing):
                // Handle full-width widget that ignores side paddings separately.
                if widgetSizing == .largeIgnoresSidePaddings {
                    if !currentIndices.isEmpty { finalizeRow() }
                    elementSize = subviews[index].sizeThatFits(ProposedViewSize(width: availableWidth, height: nil))
                    let rowFrame = CGRect(x: 0, y: totalHeight, width: availableWidth, height: elementSize.height)
                    rows.append(Row(indices: [index],
                                    offsets: [0],
                                    frame: rowFrame,
                                    subviewSizes: [elementSize],
                                    isFullWidth: true))
                    totalHeight += elementSize.height + configuration.spacingVertical
                    continue
                } else {
                    let desiredW = desiredWidth(for: widgetSizing)
                    elementSize = subviews[index].sizeThatFits(ProposedViewSize(width: desiredW, height: nil))
                }
            }

            // Calculate extra width required for this element.
            // Note: The left side padding is applied only once at the beginning of the row.
            let extraWidth: CGFloat
            if currentIndices.isEmpty {
                // For the first element, extraWidth is just its width.
                extraWidth = elementSize.width
            } else {
                extraWidth = configuration.spacingHorizontal + elementSize.width
            }

            // If adding this element would exceed available width (including right side padding),
            // finalize the current row.
            if !currentIndices.isEmpty,
               currentRowWidth + extraWidth + configuration.sidePadding > availableWidth ||
                (idealCountInRow != nil && currentIndices.count >= idealCountInRow!) {
                finalizeRow()
            }

            // Determine the x-offset for the element.
            let offset: CGFloat
            if currentIndices.isEmpty {
                // For the first element, its x-offset is the left side padding.
                offset = configuration.sidePadding
                currentRowWidth = elementSize.width
            } else {
                // For subsequent elements, offset = left side padding + currentRowWidth + spacing.
                offset = configuration.sidePadding + currentRowWidth + configuration.spacingHorizontal
                currentRowWidth += configuration.spacingHorizontal + elementSize.width
            }
            currentOffsets.append(offset)
            currentSizes.append(elementSize)
            currentIndices.append(index)

            // Update the row height to be the maximum height in the row.
            currentRowHeight = max(currentRowHeight, elementSize.height)
        }

        // Finalize any remaining normal row.
        finalizeRow()

        return (CGSize(width: availableWidth, height: totalHeight), rows)
    }
}

// MARK: - Flexible Layout Implementation

/// This is your custom layout implementation.
@available(iOS 16, *)
internal struct FlexibleLayoutImplementation: Layout {
    typealias Cache = FlexibleLayoutCache

    let itemPreference: [FlexibleElementPreference]
    let configuration: FlexibleLayoutConfiguration
    let isIpad: Bool
    
    // Row alignments are now provided from configuration.
    var idealCountInRow: Int?

    func sizeThatFits(proposal: ProposedViewSize,
                      subviews: Subviews,
                      cache: inout Cache) -> CGSize {
        guard !subviews.isEmpty else { return .zero }
        cache.validate(forProposedContainer: proposal) {
            prepareLayout(subviews, inContainer: proposal, cache: &$0)
        }
        return cache.layoutResult?.totalSize ?? .zero
    }
    
    func placeSubviews(in bounds: CGRect,
                       proposal: ProposedViewSize,
                       subviews: Subviews,
                       cache: inout Cache) {
        guard let layoutResult = cache.layoutResult else { return }
        
        // Place each row using the alignments provided in configuration.
        for row in layoutResult.rows {
            let rowXOffset = (bounds.width - row.frame.width) * configuration.rowHorizontalAlignment.percent
            for (rowElementIndex, subviewIndex) in row.indices.enumerated() {
                let subview = subviews[subviewIndex]
                let subviewSize = row.subviewSizes[rowElementIndex]
                let xPos = rowXOffset + row.frame.minX + row.offsets[rowElementIndex] + bounds.minX
                let yPos = row.frame.minY + (row.frame.height - subviewSize.height) * configuration.rowVerticalAlignment.percent + bounds.minY
                subview.place(
                    at: CGPoint(x: xPos, y: yPos),
                    proposal: ProposedViewSize(width: subviewSize.width, height: subviewSize.height)
                )
            }
        }
    }
    
    func makeCache(subviews: Subviews) -> Cache {
        return FlexibleLayoutCache()
    }
    
    func updateCache(_ cache: inout Cache, subviews: Subviews) {
        cache.shouldReset = true
    }
    
    func prepareLayout(_ subviews: Subviews,
                       inContainer proposal: ProposedViewSize,
                       cache: inout Cache) {
        let availableWidth = proposal.replacingUnspecifiedDimensions().width
        let layoutResult = FlexibleLayoutResult(
            availableWidth: availableWidth,
            subviews: subviews,
            configuration: configuration,
            itemPreference: itemPreference,
            idealCountInRow: idealCountInRow,
            isIpad: isIpad
        )
        cache.layoutResult = layoutResult
    }
}

// MARK: - Alignment Extensions

private extension HorizontalAlignment {
    var percent: Double {
        switch self {
        case .leading: return 0
        case .trailing: return 1
        default: return 0.5
        }
    }
}

private extension VerticalAlignment {
    var percent: Double {
        switch self {
        case .top: return 0
        case .bottom: return 1
        default: return 0.5
        }
    }
}
