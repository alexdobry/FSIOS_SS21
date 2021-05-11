import UIKit

enum Ordersize {
    case large
    case small
}

enum FastFoodMenuItem {
    case hamburger(numberOfPatties: Int)
    case fries(size: Ordersize)
    case drink(String, ml: Int)
    case cookie
}

let burger: FastFoodMenuItem = .hamburger(numberOfPatties: 2)
let fries: FastFoodMenuItem = .fries(size: .large)
let coke: FastFoodMenuItem = .drink("Coke", ml: 500)
let cookie: FastFoodMenuItem = .cookie

func price(for menuItem: FastFoodMenuItem) -> Double {
    switch menuItem {
    case .hamburger(let numberOfPatties):
        return Double(numberOfPatties) * 3.99
    case .fries(let size):
        return size == .small ? 2.99 : 1.99
    case .drink(_, let ml):
        return Double(ml) / 10 * 0.05
    case .cookie:
        return 1.99
    }
}
