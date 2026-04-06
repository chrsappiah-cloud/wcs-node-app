import Foundation

final class CallSpy {
    private(set) var calls: [String] = []

    func record(_ name: String) {
        calls.append(name)
    }

    func wasCalled(_ name: String) -> Bool {
        calls.contains(name)
    }

    func callCount(for name: String) -> Int {
        calls.filter { $0 == name }.count
    }
}