# Lecture 7: Data Flow (Property Wrappers and Publishers)

# Property Wrappers
- Grundsätzlich ein Struct
- @-Annotation gibt nur *syntaktischen Zucker* (syntactic sugar), um ein solches Struct zu erzeugen und zu benutzen
- Beispiele für Property Wrappers:
    + @State: variable lebt im Heap, trotz Definition im Struct
    + @Published: published Änderungen des Structs
    + @ObservedObject: View zeichnet sich neu, wenn ein published entdeckt wurde (smart)

## Anatomie von Published (Desugar)
Grundsätzliche Struktur:
```swift
struct Published<Value> {
    var wrappedValue: Value
    var projectedValue: Publisher<Value, Never>
}
```
Wenn etwas als @Published deklariert ist:
```swift
@Published var emojiArt: EmojiArt = EmojiArt()
```
Wird es vom Compiler übersetzt zu:
```swift
struct Published {
    var wrappedValue: EmojiArt
    var projectedValue: Publisher<EmojiArt, Never>
}
```

### Generierte Variablen
Der Publisher selbst (Wrapper):
```swift
struct Published {
    // ...
    var _emojiArt: Published = Published(wrappedValue: EmojiArt())
}
```

WrappedValue ist der eigentliche (gewrappte) Wert im Publisher. Diesen verwenden wir sehr häufig:
```swift
struct Published {
    // ...
    var emojiArt: EmojiArt {
        get { _emojiArt.wrappedValue }
        set { _emojiArt.wrappedValue = newValue }
    }
}
```

ProjectedValue. Abhängig vom Property Wrapper. Bei Published ist das ein Publisher, welcher Änderungen vom WrappedValue (`EmojiArt`) published, und niemals (`Never`) failed. Logisch, weil Published Änderungen publishen möchte:
```swift
struct Published {
    var $emojiArt: Publisher<EmojiArt, Never>
}
```
Wenn man Daten aus dem Netz lädt (z.B. https://pokeapi.co/api/v2/pokemon), bekommt man z.B. ein `Publisher<JSON, Error>`. Bei Erfolg wird ein JSON gepublished, und im Fehlerfall ein Error.

## Warum Property Wrapper?
Wrapper struct kann etwas machen, wenn `wrappedValue` get oder set wird. Siehe Computed Property bei Published. Beispiele:

### @Published
Veröffentlich (published) Änderungen über sein ProjectedValue (`$emojiArt`), wenn WrappedValue gesetzt wird. Ruft außerdem `objektWillChange.send` vom `ObervableObject` auf.

### @State
WrappedValue wird im Heap abgelegt. Invalidiert die View, wenn WrappedValue sich ändert.

- wrappedValue: anything (most certainly a value type)
- projectedValue: a `Binding` to that value in the heap

### @ObservedObject
ViewModels. Invalidiert die View, wenn WrappedValue `objectWillChange.send()` aufruft.

- wrappedValue: anything that implements the `ObservableObject` protocol
- projectedValue: a `Binding` to the vars of the wrappedValue (a ViewModel)

### @Binding
2-Way-Binding zwischen zwei Values. Wenn sich das WrappedValue eines Binding ändert, wird das WrappedValue des anderen Bindings ebenfalls geändert und vice versa. Bei Änderungen vom WrappedValue werden die Views invalidiert. Zudem ist der lesende Zugriff synchronisiert.

- wrappedValue: a value that is bound to something else
- projectedValue: a Binding to self

Bindings ermöglichen eine **single source of truth**. Daten werden von der SSOT gelesen und mit der SSOT synchronisert. So gibt es nicht mehrere duplikate Kopieren von Daten, die im Zweifel vertreut sind, sondern nur eine Quelle (der Wahrheit), woraus sich alle Bedienen.

### @EnvironmentObject
Invalidiert die View, wenn WrappedValue `objectWillChange.send()` aufruft. Gleiches wie `@ObservedObject`?

In der View:
```swift
// @ObservedObject
@ObservedObject var viewModel: ViewModelClass

// @EnvironmentObject
@EnvironmentObject var viewModel: ViewModelClass
```

Die Übergabe des Arguments ist unterschiedlich:
```swift
// @ObservedObject ViewModel
let myView = MyView(viewModel: theViewModel)

// @EnvironmentObject ViewModel
let myView = MyView().environmentObject(theViewModel)
```

Der Unterschied ist, dass @EnvironmentObject das EnvironmentObject an *alle Views in seinem Body automatisch übergibt*. Ähnlich wie `.foregroundColor` auf einem `VStack`, wo die foregroundColor allen Views im Stack gegeben wird.
- Außnahme: Modal Views
- Einschränkung: ein @EnvironmentObject pro ViewModel Typ (nicht 2 unterschiedliche Instanzen eines `ObervableObject`)

## @Environment
Gibt Zugriff auf *Environment Variablen* der App. Diese kommen aus dem struct `EnvironmentValues`.

Beispiel um an das Locale aus EnvironmentValues zu kommen:
```swift
@Environment(\.locale) var locale
@Environment(\.colorScheme) var colorScheme
```
- `\.locale` und `\.colorScheme` sind KeyPaths zum `EnvironmentValues` struct
- In diesem Beispiel ist das `wrappedValue` jeweils vom Typ `Locale` und `ColorScheme`
- ColorScheme ist ein Enum mit dem zwei Werten `.dark` und `.light`
- Auf diese Weise weiß man, ob man aktuell im Dark- oder Lightmode ist, und welche Sprache der User gesetzt hat.

## Publisher
Ein Objekt, dass periodisch Werte vom Typ `Output` oder Fehler vom Typ `Failure`veröffentlich (published).

```swift
struct Publisher<Output, Failure> where Failure: Error
```

Manchmal ist `Failure` vom Typ `Never`. Das bedeutet, dass der Publisher dann niemals einen Fehler published. Never ist der Bottom Type und kann 0 Mal instanziert werden.

Warum ist `Failure` nicht als Error hart kopiert, sondern generisch mit Einschränkung auf `Error`? Damit man seine eigenen Error Typen definieren kann:

```swift
enum PokeAPIError: Error {
    case pokemonNotFound
    case unknownPokemon
    case other
}

Publisher<Pokemon, PokeAPIError>
```

### Was kann mit einem Publisher machen?
- *Subscribe*, um die Werte vom Typ `Output` zu erhalten und diese zu verwenden
- *Transform*, um die Werte aufzubereiten (z.B. mit map: Data -> JSON -> Model)
- *Assign*, um die Werte einem `@Published` zuzuweisen
- sehr vieles Mehr

### Subscribe mit sink (für ViewModels, Models, ...)
Closure(s) werden jedes Mal aufgerufen, wenn es etwas neues gibt:
```swift
cancellable = publisher.sink(
    receiveCompletion: { (result: Completion<Failure>) in ... }, // success or failure
    receiveValue: { value in  }
)
```
Info: Wenn `Failure` vom Typ `Never` ist, gibt es `receiveCompletion` nicht.

### Cancellable (unsubscribe)
- Wird von `.sink` zurückgegeben und ist eine Art "Cookie" der Subscription. 
- Man kann darauf `.cancel()` aufrufen, um nicht mehr zu subscriben (unsubscribe)
- Das wichtigste ist aber, dass es die Subscription durch den Cookie **am leben hält**. Damit die Subscription bestehen bleibt, muss `cancellable` einer Instanzvariable zugewiesen werden:
```swift
class Foo {
    private var cancellable: AnyCancellable?

    init() {
        self.cancellable = publisher.sink(
            receiveCompletion: { (result: Completion<Failure>) in ... },
            receiveValue: { value in  }
        )
    }
}

```

### Subscribe mit onReceive (für Views)
Jedes mal wenn Data aus einem Publisher kommen, soll die View sich automatisch updaten:

```swift
.onReceive(publisher) { value in ... }
```
`onReceive` wird die View automatisch invalideren wenn notwendig.

### Woher bekommen wir einen Publisher?
1. $x vor einer Variable die `@Published` ist
2. `URLSession` (Netzwerkt Client, feuert wenn Daten hinter einer URL zurückkommen)
3. `Timer` (feuert auf Grundlage von Date und Time)
4. `NotificationCenter` (Reaktion auf Systemevents)
5. ...
