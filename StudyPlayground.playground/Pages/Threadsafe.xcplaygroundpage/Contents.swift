//: [Previous](@previous)

import Foundation

// Not Threadsafe

class Changable {
	var value: Int {
		get {
			storedValue
		}
		set {
			storedValue = newValue
		}
	}
	
	private var storedValue: Int
	
	init(value: Int) {
		self.storedValue = value
	}
}

print("Not threadsafe:\n")

let instance = Changable(value: 10)
DispatchQueue.concurrentPerform(iterations: 2) { index in
	for _ in 1...10 {
		instance.value += 1
		print(instance.value)
	}
}

// Not Threadsafe v2

class Changable2 {
	var value: Int {
		get {
			storedValue
		}
		set {
			storedValue = newValue
		}
		_modify {
			yield &storedValue
		}
	}
	
	private var storedValue: Int
	
	init(value: Int) {
		self.storedValue = value
	}
}

print("Not threadsafe v2:\n")

let instance0 = Changable(value: 10)
DispatchQueue.concurrentPerform(iterations: 10) { index in
	for _ in 1...10 {
		instance0.value += 1
		print(instance0.value)
	}
}

// Lock
print("\nLock:\n")

class LockWrapper<Value> {
	var value: Value {
		get {
			lock.lock()
			defer { lock.unlock() }
			return storedValue
		}
		_modify {
			lock.lock()
			print("Before \(storedValue)")
			defer {
				print("After \(storedValue)")
				lock.unlock()
			}
			yield &storedValue
		}
	}
	
	private var storedValue: Value
	private let lock = NSLock()
	
	init(value: Value) {
		self.storedValue = value
	}
}

let instance1 = LockWrapper<Int>(value: 10)
DispatchQueue.concurrentPerform(iterations: 2) { index in
	for _ in 1...10 {
		instance1.value += 1
		print("\(instance1.value)")
	}
}

// Semaphore

class SemaphoreWrapper<Value> {
	var value: Value {
		get {
			semaphore.wait()
			defer { semaphore.signal() }
			return storedValue
		}
		_modify {
			semaphore.wait()
			print("Before \(storedValue)")
			defer {
				print("After \(storedValue)")
				semaphore.signal()
			}
			yield &storedValue
		}
	}
	
	private var storedValue: Value
	private let semaphore = DispatchSemaphore(value: 1)
	
	init(value: Value) {
		self.storedValue = value
	}
}

print("\nDispatch Semaphore:\n")

let instance2 = SemaphoreWrapper<Int>(value: 10)
DispatchQueue.concurrentPerform(iterations: 2) { index in
	for _ in 1...10 {
		instance2.value += 1
		print(instance2.value)
	}
}


// OperationQueue
print("\nOperation Queue:\n")

class ChangableOperation {
	var value: Int {
		get {
			return storedValue
		}
		set {
			storedValue = newValue
		}
	}
	
	private var storedValue: Int
	
	init(value: Int) {
		self.storedValue = value
	}
}

let instance3 = ChangableOperation(value: 10)
let queue3: OperationQueue = {
	let queue = OperationQueue()
	queue.maxConcurrentOperationCount = 1
	return queue
}()

DispatchQueue.concurrentPerform(iterations: 2) { index in
	for _ in 1...10 {
		queue3.waitUntilAllOperationsAreFinished()
		queue3.addOperation {
			instance3.value += 1
			print(instance3.value)
		}
	}
}
queue3.waitUntilAllOperationsAreFinished()

// Operation Queue v.2

class OperationWrapper<Value> {
	private(set) var value: Value {
		get {
			return storedValue
		}
		_modify {
			yield &storedValue
		}
	}
	
	private var storedValue: Value
	private let operationQueue = OperationQueue()
	
	init(value: Value) {
		self.storedValue = value
		operationQueue.maxConcurrentOperationCount = 1
	}
	
	func write<Block>(block: @escaping (inout Value) -> Block) {
		operationQueue.addOperation { [weak self] in
			guard let self else { return }
			block(&self.value)
		}
	}
}

print("\nOperation Queue (v.2):\n")

let inst = OperationWrapper<Int>(value: 10)
DispatchQueue.concurrentPerform(iterations: 2) { index in
	for _ in 1...10 {
		inst.write {
			$0 += 1
			print($0)
		}
	}
}

// Dispatch queue

class ChangableDispatch {
	var value: Int {
		get {
			var value: Int = 0
			queue.sync {
				value = self.storedValue
			}
			return value
		}
		set {
			queue.async(flags: .barrier) {
				self.storedValue = newValue
			}
		}
		_modify {
			yield &storedValue
		}
	}
	
	private var storedValue: Int
	private let queue = DispatchQueue(label: "queue_concurent", attributes: .concurrent)
	
	init(value: Int) {
		self.storedValue = value
	}
}

print("\nDispatch Queue:\n")

let instance4 = ChangableDispatch(value: 10)
DispatchQueue.concurrentPerform(iterations: 2) { index in
	for _ in 1...10 {
		instance4.value += 1
		DispatchQueue.global().sync {
			print(instance4.value)
		}
	}
}

//: [Next](@next)
