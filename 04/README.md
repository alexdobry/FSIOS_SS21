# Lecture 4: Grid UI and Optionals

## protocol extensions und generics
```swift
// Array+Identifiable.swift

import Foundation

extension Array where Element: Identifiable {
    func firstIndex(of element: Element) -> Int? {
        for index in self.indices {
            if self[index].id == element.id { // Element ist Identifiable. Deshalb kann auf id zugegriffen werden
                return index
            }
        }
        
        return nil
    }
}

```
protocol-extension.playground

## Grid

### Vorab
- generics (Item und ItemView)
- init
- @escaping Closure
- retain cycles

```swift
import SwiftUI

struct Grid<Item, ItemView>: View {
    
    private var items: [Item]
    private var viewForItem: (Item) -> ItemView
    
    init(_ items: [Item], viewForItem: @escaping (Item) -> ItemView) {
        self.items = items
        self.viewForItem = viewForItem
    }
    
    var body: some View {
        ForEach(items) { item in 
            viewForItem(item)
        }
    }
}
```

### Problem
```swift
// public struct ForEach<Data, ID, Content>
// where Data : RandomAccessCollection, Data.Element : Identifiable
// where Content : View
```

### Lösung
Item muss Itentifiable und ItemView muss eine View sein
```swift
import SwiftUI

struct Grid<Item, ItemView>: View where Item: Itentifiable, ItemView: View {
    
    private var items: [Item]
    private var viewForItem: (Item) -> ItemView
    
    init(_ items: [Item], viewForItem: @escaping (Item) -> ItemView) {
        self.items = items
        self.viewForItem = viewForItem
    }
    
    var body: some View {
        ForEach(items) { item in 
            viewForItem(item)
        }
    }
}
```

### Aufgabe einer ContainerView
Angebotenen Space nehmen und an die Child-Views verteilen. `GeometryReader`:
```swift
struct Grid<Item, ItemView>: View where Item: Identifiable, ItemView: View {
    // ...
    var body: some View {
        GeometryReader { geometry in
            body(for: GridLayout(itemCount: items.count, in: geometry.size)) // Teile eigenen space (geometry.size) gleichmäßig auf alle Kinder auf (items.count)
        }
    }
    
    private func body(for layout: GridLayout) -> some View {
        ForEach(items) { item in
            viewForItem(item)
                .frame(width: layout.itemSize.width, height: layout.itemSize.height) // Jedes Kind bekommt den aufgeteilten Space
                .position(layout.location(ofItemAt: items.firstIndex(of: item)!)) // Position (center) setzen, weil jedes Kind versetzt ist (Grid)
        }
    }
}

```

### Group
- Nur ViewBuilder unterstützen das Gruppieren meherer Views und if/elses
- `Group` ist eine View, die ein ViewBuilder akzeptiert und nichts mit der View macht (kein Layouting etc.)
- Wenn man z.B. ein if/else verwenden möchte, dann `Group`:
```swift
func body(...) -> some View {
    let index: Int? = items.firstIndex(...)
    return Group { 
        if index != nil {
            viewForItem(...)
        }
        // ViewBuilder kann mit if/else umgehen und setzt hier eine EmptyView o.ä. ein
    } 
}
```
- Ohne `Group`:
```swift
func body(...) -> some View {
    let index: Int? = items.firstIndex(...)
    if index != nil {
        return viewForItem(...)
    } else {
        return EmptyView()
    }
}
```

## Enum
enum.playground

### Optional ist ein Enum
```swift
enum Optional<T> {
    case none
    case some(T)
}
```
syntax sugar bei Int?:
- none: nil
- some: Int literal

### Optionals "öffnen"
if let:
```swift
func add3(value: Int?) -> Int? {
    if let value = value {
        return value + 3
    }
    return nil
}
```
guard let:
```swift
func add3(value: Int?) -> Int? {
    guard let value = value else {
        return nil
    }
    return value + 3
}
```
map:
```swift
func add3(value: Int?) -> Int? {
    value.map { $0 + 3 }
}
```
optional chaining:
```swift
extension Int {
    func add3() -> Int {
        self + 3
    }
}

func add3(value: Int?) -> Int? {
    value?.add3()
}
```
force unwrap:
```swift
func add3(value: Int?) -> Int? {
    value! + 3
}
```
if checks:
```swift
func add3(value: Int?) -> Int? {
    if value != nil {
        value! + 3
    }
    
    return nil
}
```
get or else (nil coalescing)
```swift
func add3(value: Int?) -> Int {
    value?.add3() ?? -1
}
```
