# Lecture 3: Reactive UI + Protocols + Layout

## Recap MVVM
Datenfluss:
- Model -> ViewModel -> View
- View -> ViewModel -> Model -> ViewModel -> View

## Struct
- Structs werden kopiert, wenn sie verändert werden
```swift
func choose(card: Card) { 
    card.isFaceUp = !card.isFaceUp
}
```
- `card` wurde kopiert und hat keine Referenz zu `cards: Array<Card>`
- Die korrespondierendes Karte in `cards` finden, und diese *in place* ändern:
```swift
func choose(card: Card) { 
    let index = self.index(of: card)
    cards[index].isFaceUp = !cards[index].isFaceUp 
}
```
- Geht nicht, weil `MemoryGame` ein struct und damit immutable ist. Explizit `mutating func` schreiben.
- Mutability muss explizit angegeben werden. Vorteile
    + value types
    + Swift (und SwiftUI) kann tracken, wann eine Änderung passiert, weil `copy on write`

## Reactive UI
- ViewModel muss auf Änderungen im Model achten
    + Bei einem struct als Model weiß Swift immer, wenn sich das struct ändert, weil das ein value type ist (siehe oben)
- ViewModel muss ein `ObservableObject` werden (class only):
```swift
class EmojiGame: ObservableObject {
    @Published private var game: MemoryGame<String>
}
```
- Wenn das ViewModel eine Änderung bemerkt, **published das ViewModel**, dass sich etwas geändert hat (automatisch durch `@Published`)
- `@Published` ist ein sog. Property Wrapper, der jedes mal `objectWillChange.send()` aufruft, wenn die Property sich ändern wird.

- Wenn das ViewModel in der View `objectWillChange.send()` aufruft, soll die View neu gezeichnet werden.
- **View subscribed** das ViewModel und wird benachrichtigt, wenn ein publish erfolgt ist
    + View bekommt vom ViewModel das neue Model mitgeteilt
    + View rendert neu -> bleibt immer in sync mit Model
```swift
struct EmojiMemoryGameView: View {
    @ObservedObject var emojiGame: EmojiGame
}
```
- SwiftUI ist sehr effizient wenn es um re-rendering geht. SwiftUI bemerkt, was sich geändert hat, und ersetzt diese eine Element

## Protocol
- Wie ein Interface
- Protocol Extensions
- Protocols and Generics
- SwiftUI verwendet sehr viele Protocols und Generics

## Enum
- Disjunkter Typ (Summen-Typ)
- Assoziierte Werte

## Layout
- Wie es funktioniert:
    + 1. Container Views bieten space an
    + 2. Views wählen nehmen den space (most common), oder wollen mehr oder weniger
    + 3. Container Views positionieren die Views dann auf grundlage des spaces
- Container Views
    + HStack, VStack, ZStack: teilen ihren space an die subviews aus
    + ForEach: leitet das layouting an seine Container View weiter
    + Modifieres (z.B. .padding): Modifizieren die View, indem Sie layouten

```swift
HStack {
    ForEach(cards) { card in
        CardView(card).aspectRatio(2/3, contentMode: .fit)
    }
}
.foregroundColor(.orange)
.padding(10)
```
- Die erste View ist die View, die durch `.padding(10)` zurückgegeben wird.
- Padding<View> zieht 10pt von seinem space ab, und gibt das die ForegroundColor<View> weiter
- ForegroundColor<View> nimmt nicht am layouting teil und gibt den space an HStack weiter
- HStack teilt den space x-10 gleichmäßig für alle subviews auf, die aus ForEach (AspectRadio<View>)kommen
- AspectRadio<View> setzt seine width / height entsprechend mit aspectRadio von 2/3. Der restliche space wird an CardView gegeben.
- CardView nimmt den space so an

Custom Views
- Custom Views nehmen per se den gesamten space an, der ihnen angeboten wird
- Das sieht aber nicht immer gut aus. Sie sollten sich dem angebotenen space anpassen
- z.B. font size propotional zum angebotenen space
- Dafür Views in `GeometryReader { geometry: GeomertyProxy in }` wrappen
- Dadurch bekommt man lesenden Zugriff auf die Geometry wo man drin ist:
    + size: die angebotene CGSize
    + frame: das CGRect wo wir im jeweiligen CoordinateSpace sind
    + safeAreaInsets: angebotener space inkludiert nicht die safe area. safeAreaInsets beinhaltet die Maße der safe area
