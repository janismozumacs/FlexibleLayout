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
         idealCountInRow: Int?) {
        let result = Self.calculateLayout(availableWidth: availableWidth,
                                           subviews: subviews,
                                           configuration: configuration,
                                           itemPreference: itemPreference,
                                           idealCountInRow: idealCountInRow)
        self.totalSize = result.totalSize
        self.rows = result.rows
    }

    /// Computes the layout (rows and overall size) based on the available width, subviews,
    /// configuration, sizing preferences, and an optional ideal count per row.
    private static func calculateLayout(availableWidth: CGFloat,
                                        subviews: LayoutSubviews,
                                        configuration: FlexibleLayoutConfiguration,
                                        itemPreference: [FlexibleElementPreference],
                                        idealCountInRow: Int?) -> (totalSize: CGSize, rows: [Row]) {
        var rows: [Row] = []
        // Trackers for normal (non-full-width) rows.
        var currentIndices: [Int] = []
        var currentOffsets: [CGFloat] = []
        var currentSizes: [CGSize] = []
        var currentRowWidth: CGFloat = 0      // Accumulated width of items (plus spacing) in current row.
        var currentRowHeight: CGFloat = 0     // Maximum height in the current row.
        var totalHeight: CGFloat = 0          // Accumulated height of all rows.

        // Helper closure that returns the spacing before adding a new subview.
        // If it's the first subview in the row, use left side padding; otherwise, horizontal spacing.
        func spacingBefore() -> CGFloat {
            return currentIndices.isEmpty ? configuration.sidePadding : configuration.spacingHorizontal
        }

        // Finalize the current normal row, create a row object, and reset trackers.
        func finalizeRow() {
            guard !currentIndices.isEmpty else { return }
            // For normal rows, add right side padding to complete the row width.
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
            let isIpad = getIsIpad()
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
                    // Finalize any pending normal row before processing a full-width element.
                    if !currentIndices.isEmpty { finalizeRow() }
                    // Compute size using full available width.
                    elementSize = subviews[index].sizeThatFits(ProposedViewSize(width: availableWidth, height: nil))
                    // Create a row exclusively for this full-width widget.
                    let rowFrame = CGRect(x: 0, y: totalHeight, width: availableWidth, height: elementSize.height)
                    // Full-width rows have no side paddings, so x-offset is 0.
                    rows.append(Row(indices: [index],
                                    offsets: [0],
                                    frame: rowFrame,
                                    subviewSizes: [elementSize],
                                    isFullWidth: true))
                    totalHeight += elementSize.height + configuration.spacingVertical
                    continue  // Move to the next subview.
                } else {
                    // For small, medium, or large widgets that use side paddings,
                    // compute the desired width using our helper function.
                    let desiredW = desiredWidth(for: widgetSizing)
                    elementSize = subviews[index].sizeThatFits(ProposedViewSize(width: desiredW, height: nil))
                }
            }

            // Calculate extra width required for this element, including the spacing before it.
            let extraWidth = elementSize.width + spacingBefore()

            // If adding this element would exceed available width (including right side padding),
            // finalize the current row.
            if !currentIndices.isEmpty,
               currentRowWidth + extraWidth + configuration.sidePadding > availableWidth ||
                (idealCountInRow != nil && currentIndices.count >= idealCountInRow!) {
                finalizeRow()
            }

            // Determine the x-offset for the element.
            // For the first element in a normal row, the offset is the left side padding.
            let offset: CGFloat = currentIndices.isEmpty ? configuration.sidePadding : (currentRowWidth + spacingBefore())
            currentOffsets.append(offset)
            currentSizes.append(elementSize)
            currentIndices.append(index)

            // Update the cumulative row width with the element's width and the spacing used.
            currentRowWidth += elementSize.width + spacingBefore()
            // Update the row height to be the maximum height in the row.
            currentRowHeight = max(currentRowHeight, elementSize.height)
        }

        // Finalize any remaining normal row after processing all subviews.
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
    
    // Removed separate alignment properties;
    // row alignments are now provided from configuration.
    
    var idealCountInRow: Int?

    func sizeThatFits(proposal: ProposedViewSize,
                      subviews: Subviews,
                      cache: inout Cache) -> CGSize {
        guard !subviews.isEmpty else { return .zero }
        // Validate or update cache before laying out.
        cache.validate(forProposedContainer: proposal) {
            prepareLayout(subviews, inContainer: proposal, cache: &$0)
        }
        // Return the calculated total size.
        return cache.layoutResult?.totalSize ?? .zero
    }
    
    func placeSubviews(in bounds: CGRect,
                       proposal: ProposedViewSize,
                       subviews: Subviews,
                       cache: inout Cache) {
        guard let layoutResult = cache.layoutResult else { return }
        
        // Place each row based on the row alignments provided in configuration.
        for row in layoutResult.rows {
            // Compute horizontal offset for the row based on configuration.rowHorizontalAlignment.
            let rowXOffset = (bounds.width - row.frame.width) * configuration.rowHorizontalAlignment.percent
            // For vertical alignment within the row, use configuration.rowVerticalAlignment.
            for (rowElementIndex, subviewIndex) in row.indices.enumerated() {
                let subview = subviews[subviewIndex]
                let subviewSize = row.subviewSizes[rowElementIndex]
                // x-position is computed by adding the rowXOffset and the subview's offset within the row.
                let xPos = rowXOffset + row.frame.minX + row.offsets[rowElementIndex] + bounds.minX
                // y-position aligns the subview vertically within the row according to configuration.rowVerticalAlignment.
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
        // Compute available width from the proposal.
        let availableWidth = proposal.replacingUnspecifiedDimensions().width
        let layoutResult = FlexibleLayoutResult(
            availableWidth: availableWidth,
            subviews: subviews,
            configuration: configuration,
            itemPreference: itemPreference,
            idealCountInRow: idealCountInRow
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

private func getIsIpad() -> Bool {
    return DispatchQueue.main.sync {
        UIDevice.current.userInterfaceIdiom == .pad
    }
}
