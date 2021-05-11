import UIKit

protocol Pretty {
    func pretty() -> String
    func prettyPrint()
}

extension Pretty {
    func prettyPrint() {
        print(pretty())
    }
}

struct Person {
    let name: String
    let age: Int
}

extension Person: Pretty {
    func pretty() -> String {
        "\(name) ist \(age) Jaher alt."
    }
}

Person(name: "Alex", age: 31).pretty()
Person(name: "Maja", age: 30).prettyPrint()


extension Array: Pretty where Element: Pretty {
    func pretty() -> String {
        var s = ""
        for elem in self {
            s += "\(elem.pretty())\n"
        }
        return String(s.dropLast())
    }
}

let people = [
    Person(name: "Alex", age: 31),
    Person(name: "Maja", age: 30)
]

people.pretty()
people.prettyPrint()

let strings = ["Hi", "Yo"]
