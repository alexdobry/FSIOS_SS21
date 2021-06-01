# Lecture 6: Animation

## Property Observers
- Sind "richtige" Variablen und werden auch im Memory abgelegt
- Ermöglichen es Code auszuführen, wenn sich eine Variable **ändert** (Property Observer):
```swift
var isFaceUp: Bool {
    willSet {
        if newValue {
            startUsingBonusTime()
        } else {
            stopUsingBonusTime()
        }
    }
    didSet {
        println("chaning isFaceUp from \(oldValue) to \(isFaceUp)")
    }
}
```

Verwendung:
```swift
func a() {
    self.isFaceUp = true // startUsingBonusTime() wird implizit aufgerufen
}

func b() {
    self.isFaceUp = false // stopUsingBonusTime() wird implizit aufgerufen
}

func c() {
    self.isFaceUp = true // startUsingBonusTime() wird implizit aufgerufen
}
```

Alternative:
```swift
func a() {
    self.isFaceUp = true
    startUsingBonusTime() // explizit aufufen
}

func b() {
    self.isFaceUp = false
    stopUsingBonusTime() // explizit aufufen
}

func c() {
    self.isFaceUp = true
    startUsingBonusTime() // explizit aufufen
}
```

## Computed Properties
- Werden nicht in Memory gespeichert
- Sind quasi getter und setter, die aber die Syntax einer Variable haben:
```swift
var indexOfFaceUpCard: Int? {
    get {
        cards.indices.filter { cards[$0].isFaceUp }.only
    }
    set {
        cards.indices.forEach { i in
            cards[i].isFaceUp = i == newValue
        }
    }
}
```

Verwendung:
```swift
self.indexOfFaceUpCard = 5 // set Block
if let indexOfFaceUpCard = self.indexOfFaceUpCard { // get Block

}
print(self.indexOfFaceUpCard) // get Block
```

Äquivalente Methode:
```swift
func setIndexOfFaceUpCard(_ value: Int?) {
    cards.indices.forEach { i in
        cards[i].isFaceUp = i == value
    }
}

func getIndexOfFaceUpCard(): Int? {
    return cards.indices.filter { cards[$0].isFaceUp }.only
}
```

Verwendung:
```swift
self.setIndexOfFaceUpCard(5)
if let indexOfFaceUpCard = self.getIndexOfFaceUpCard() {

}
print(self.getIndexOfFaceUpCard())
```

# @State
- SwiftUI bemerkt, wenn sich ein var verändert, und leitet dann die minimal notwendigsten Schritte ein, um diese View auszuwechseln
    + wenn `isFaceUp` sich ändert, wird eine **neue** CardView gerendert
- Da eine View immer neu gerendet werden kann, darf eine View kein State haben, weil dieser immer wieder verworfen wird
- Eine View ist also immer **Read Only** und damit Zustandslos
    + Valider "State" sind alle Properties, die über den Konstruktur gesetzt werden, weil diese eben jedes mal gesetzt werden

Beispiel:
```swift
struct CardView: View {
    
    // Wird immer wieder neu gesetzt, wenn die Card neu gerendet wird (Konstruktor). Kann auch ein let sein
    var card: MemoryGame<String>.Card 
    
    // Computed var. Nicht in Memory, sprich kein State. Quasi eine get Methode, die die aktuelle View zurückgibt.
    var body: some View { 
        // Wird abhängig vom Konstruktorargument neu gerendet
        if card.isFaceUp || !card.isMatched {
            ZStack { ... }
        }
    }
}
```

- Manchmal benötigt eine View aber **temporären State**. Richtiger State ist aber im Model! Beipsiele für temporären State:
    + Edit Mode. View sammelt Änderungen für einen großen Intent
    + Alert. View weiß, dass der Alert angezeigt wird und wartet, bis eine var namens alert auf false gesetzt wird.
    + Animation. Eine View speichert seinen Endzustand und animiert dort hin
- Mit `@State` können wir einer View State geben:
```swift
@State private var tmp: Int
```
- Änderungen an eine `@State` war bewirkt, dass sich die View neu zeichnet!
- Damit das mit @State funktioniert, wird die Variable im Heap abgelegt wird. Die View bekommt den Pointer zur var, wenn die View neu erzeugt wird.
- Dieser State ist aber nur lokal für eine View. Wenn der State für mehrere Views gelten soll, wird ein ViewModel mit `@ObservedObject` verwendet
    + Beispiel MemoryGame: Wenn eine Card isFaceUp nur als lokalen `@State` hat, kann das MemoryGame nicht berechnen, ob es ein Match gibt oder nicht. Diese Logik darf nicht lokal sein, sondern muss vom Model aus in die View rein: Model -> ViewModel -> View

Counter Demo: state.playground

# Animation
- Eine Animation ist eine Bewegung einer View von einem State zu einem anderen State
- Die View hat *schon den Endstate*. Die Animation zeigt nur den Übergang an
- Eine Animation hat das Ziel die die UX zu verbessern
- Animationen funktionieren nur mit Views, die in einem Container sind und bereits angezeigt werden (CTAAOS - Containers that are already on-screen)
- Was kann animiert werden?:
    + appearance and disappearance
    + Änderungen der Argumente von `ViewModifier` (opacity, rotation, frame)
    + Änderungen der Argumente der Erzeugung von `Shapes`
- Wie stoßt man eine Animation an?:
    + Implizit, also automatisch, wenn sich der modifier einer view ändert, wird die Änderung animiert: `.animation(Animation)`
    + Explicit, indem wir selber Änderungen in einem Codeblock durchführen: `withAnimation(Animation) {}`. In der Closure wird z.B. ein Intent gemacht (Methode vom ViewModel aufgerufen). Dessen Änderungen sollen animiert werden (Karte umdrehen)

## Implizit
Alle Änderungen der `ViewModifier` Argumente werden immer animiert.

Beispiel:
Jedes mal, wenn sich `scary` oder `upsideDown` ändern, werden die Änderungen von `opacity` oder `rotation` animiert:
```swift
Text("👻")
    .opacity(scary ? 1 : 0)
    .rotationEffect(Angle.degrees(upsideDown ? 180 : 0))
    .animation(Animation.easeInOut)
    // oder: .animation(.linear(duration: 2))
```
**Achtung:** `.animation` auf einem Container propagiert die Animation auf alle Views im Container, wie `.font`.

## Animation struct
Konguration der Animation
- Dauer (in Sekunden)
- Delay (in Sekunden)
- Diverse Repeats
- Speed up
- Kurven
    + linear: konsistent über die gesamte Zeit
    + easeInOut: start slow, mid speed, end slow
    + spring: "soft landing (bounce)" am ende

## Explizit
- Tatsächlich der übliche Weg, um mehrere Views *harmonisch* (gleiche duration, curve, timing, etc..) zu animieren.
- Eine Block mit einer Animationseinstellung (duration, curve) für mehrere Views:
```swift
withAnimation(.linear(duration: 2)) {
    // e.g. intent call
}
```
- `withAnimation` ist ein imperativer Aufruf, weshalb dieser nur an Stellen stehen kann, wo SwiftUI uns erlaubt, imperativen Code zu schreiben, z.B.: `onTapGesture`
- **Achtung**: Explizite Animationen überschreiben keine Implizite Animations

## Transitions
- Transitions beschreiben die Animation vom Ankommen/Weggehen von Views (CTAAOS)
- Transition ist ein Pair von `ViewModifier`: einer für vorher und einer für nachher. Der Übergang wird dann animiert.
- Beispiel für zwei Transitions `.scale` und `.identity`:
```swift
ZStack {
    if isFaceUp {
        RoundedRectangle() // default transition is .opacity
        Text("👻").transition(.scale)
    } else {
        RoundedRectangle(cornerRadius: 10).transition(.identity)
    }
}
```

Wie funktioniert das?
- Wenn isFaceUp auf true gesetzt wird, 
    + wird RoundedRectangle() von opacity 0 auf 1 gesetzt und damit eingeblendet,
    + wird Text von frame 0 auf frame $fullSize gesetzt und damit vergrößert,
    + wird RoundedRectangle(cornerRadius: 10) direkt verschwinden
-  Wenn isFaceUp auf false gesetzt wird, 
    + wird RoundedRectangle() von opacity 1 auf 0 gesetzt und damit ausgeblendet,
    + wird Text von frame $fullSize auf frame 0 gesetzt und damit verkleinert,
    + wird RoundedRectangle(cornerRadius: 10) direkt verschwinden

Technisch gesehen:
- `.scale`: Transition von `frame = 0` zu `frame = $fullSize`, also ein Zoom in and out
- Default Transition: `.opacity`, Tranistion von `opacity = 0.0` zu `opacity = 1.0`, also ein fade in und out
- `.identity`: Keine Transition. Wird direkt angezeigt

Wann Transitions?
- **Übrigens**: if/else in ViewBuildern fügen Views hinzu und entfernen diese. Das ist ein guter Platz für Transitions. Hier wird immer die default Transition genommen
- `ForEach` fügt auch Views hinzu oder entfernt diese. Hier kann man auch Animieren
- `.transition` ist nur die Beschreibung der Transition. Man muss noch eine Explizite Animation verwenden, keine Implizite! Die Änderung von `isFaceUp` muss in `withAnimation` gewrapped werden.
- Man kann über den Aufruf `.transition(.opacity.animation(.linear(seconds: 20)))` die Parameter der Transition überschreiben. Das ist aber keine implizite Animation!
- **Achtung**: Transitions werden meist mit explizit Animations benutzt, da explizit Animations an eine Gruppe von Views angewendet werden, die ggf. kommen und gehen. Implizit Animations sind isoliert und haben nichts mit anderen Views zu tun

## Problematik mit Transitions
- Animationen funktioniert nur mit Views auf dem Screen (CTAAOS)
- Aber was ist, wenn man das "spawnen" der View animieren möchte, und nicht möchte, dass die Views vorher sichtbar sind?
- In der `.onAppear {}` Closure der Container View kann man dem ViewModel mitteilen, dass jetzt z.B. die Karten gedealt werden können. Das stößt den Prozess an, dass die View die Karten zeichnet. Den Call zum ViewModel macht man natürlich in einem `withAnimation` Call.

## Eigene Animationen
- Wenn man ein eigenes `Shape` oder `ViewModifier` hat, muss man das Protocol `Animatable` implementieren, und ein `animatableData: VectorArithmetic` bereitstellen.
- `VectorArithmetic` ist mein Float, Double oder CGFloat
- Gibt auch Strukturen wie `AnimatablePair`
