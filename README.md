# FlexibleLayout

A SwiftUI layout engine for building adaptive, flow-based interfaces. Supports dynamic-width items and fixed widget sizing that adapts between iPhone and iPad.

## Requirements

- iOS 16+
- Swift 6.0+

## Installation

### Swift Package Manager

Add the dependency in your `Package.swift`:

```swift
dependencies: [
    .package(url: "https://github.com/janismozumacs/FlexibleLayout.git", from: "2.0.0")
]
```

Or in Xcode: **File > Add Package Dependencies** and enter the repository URL.

## Usage

### Dynamic Width Items

Items that size based on their content:

```swift
import FlexibleLayout

struct Tag: FlexibleElementDisplay {
    let id: String
    let text: String
}

let tags = [
    Tag(id: "1", text: "SwiftUI"),
    Tag(id: "2", text: "Layout"),
    Tag(id: "3", text: "Flexible"),
]

ScrollView {
    FlexibleLayout(data: tags,
                   configuration: FlexibleLayoutDefaultConfiguration()) { tag in
        Text(tag.text)
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(Color.blue.opacity(0.2))
            .cornerRadius(8)
    }
}
```

### Widget-Based Dashboard

Use `DashboardWidgetDisplay` and `AnyWidget` for fixed-size widgets that adapt to device:

```swift
struct MyWidget: DashboardWidgetDisplay {
    let widgetId: String
    let title: String
    let size: WidgetSizing

    var makeView: AnyView {
        AnyView(
            Text(title)
                .padding()
                .frame(maxWidth: .infinity, minHeight: 120)
                .background(Color.blue)
                .cornerRadius(12)
        )
    }
}

let widgets: [AnyWidget] = [
    MyWidget(widgetId: "1", title: "Revenue", size: .medium),
    MyWidget(widgetId: "2", title: "Users", size: .medium),
    MyWidget(widgetId: "3", title: "Orders", size: .medium),
].compactMap { AnyWidget($0) }

ScrollView {
    FlexibleLayout(data: widgets,
                   configuration: FlexibleLayoutDefaultConfiguration()) { widget in
        widget.makeView
    }
}
```

### Widget Sizing

| Size | iPhone | iPad |
|------|--------|------|
| `.small` | 2 per row | 4 per row |
| `.medium` | Full width | 2 per row |
| `.large` | Full width | Full width |
| `.smallPhoneMediumPad` | 2 per row | 2 per row |
| `.largeIgnoresSidePaddings` | Full width, no padding | Full width, no padding |

### Custom Configuration

Conform to `FlexibleLayoutConfiguration` to customize spacing and alignment:

```swift
struct MyConfig: FlexibleLayoutConfiguration {
    var sidePadding: CGFloat { 20 }
    var spacingHorizontal: CGFloat { 12 }
    var spacingVertical: CGFloat { 12 }
    var rowHorizontalAlignment: HorizontalAlignment { .leading }
    var rowVerticalAlignment: VerticalAlignment { .center }
}
```

## License

MIT
