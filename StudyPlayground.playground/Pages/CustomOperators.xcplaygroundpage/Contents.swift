import Foundation

//
// Only assigns value from Optional<T> if value exists.
//

infix operator =?

public func =?<T>(lhs: inout T, rhs: Optional<T>) {
	lhs = rhs ?? lhs
}

// Examples

var t: Int = 2
var e: Int = 7
var g: Int? = nil

t =? g
print(t)

t =? e
print(t)

class Plant {
	let flowers: Int
	
	init(flowers: Int) {
		self.flowers = flowers
	}
}

var rose = Plant(flowers: 5)
var sunflower = Plant(flowers: 1)
var lemongrass: Plant? = nil

rose =? lemongrass
print(rose.flowers)

rose =? sunflower
print(rose.flowers)

//
// Safe index-based value retrieval from collections.
//

extension Collection {
	subscript(safe index: Index) -> Element? {
		((self.startIndex...self.endIndex) ~= index) ? self[index] : nil
	}
}

// Allows using both [safe:] and =? for mutating.
extension MutableCollection {
	subscript(safe index: Index) -> Element? {
		get {
			((self.startIndex...self.endIndex) ~= index) ? self[index] : nil
		}
		mutating set {
			if (self.startIndex...self.endIndex) ~= index, let newValue {
				self[index] = newValue
			}
		}
	}
}

// Example

var array = [4, 7, 8]
let t2: Int? = 5

print(array[safe: 5])

array[safe: 2] =? t2
print(array)

array[safe: 10] =? 3
print(array)

