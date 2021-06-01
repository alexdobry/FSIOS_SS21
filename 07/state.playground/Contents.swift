import SwiftUI
import PlaygroundSupport

// https://www.pointfree.co/collections/swiftui/state-management/ep65-swiftui-and-state-management-part-1
// https://www.pointfree.co/collections/swiftui/state-management/ep66-swiftui-and-state-management-part-2

struct ContentView: View {
    
    @ObservedObject var counter: CounterViewModel
    
    var body: some View {
        NavigationView {
            List {
                NavigationLink(destination: CounterView(counter: counter)) {
                    Text("Counter demo")
                }
            }
            .navigationTitle("State management")
        }
    }
}

class CounterViewModel: ObservableObject {
    @Published var count = 0
}

// model -> Viewmodel -> view -> viewModel -> model

struct CounterView: View {
    
    @ObservedObject var counter: CounterViewModel
    
    @State var isModelPresented: Bool = false
    
    var body: some View {
        VStack {
            HStack {
                Button(action: {
                    counter.count -= 1
                }) {
                    Text("-")
                }
                Text("\(counter.count)")
                Button(action: {
                    counter.count += 1
                }) {
                    Text("+")
                }
            }
            Button("Is this prime?", action: {
                isModelPresented = true
            })
        }
        .font(.title)
        .navigationTitle("Counter demo")
        .sheet(isPresented: $isModelPresented) {
            IsPrimeModalView(count: counter.count)
        }
    }
}

private func isPrime(_ p: Int) -> Bool {
    if p <= 1 { return false }
    if p <= 3 { return true }
    for i in 2...Int(sqrtf(Float(p))) {
        if p % i == 0 { return false }
    }
    return true
}

struct IsPrimeModalView: View {
    var count: Int
    
    var body: some View {
        VStack {
            if isPrime(count) {
                Text("\(count) is prime 🎉")
            } else {
                Text("\(count) is not prime :(")
            }
        }
    }
}

PlaygroundPage.current.liveView = UIHostingController(rootView: ContentView(counter: CounterViewModel()))
