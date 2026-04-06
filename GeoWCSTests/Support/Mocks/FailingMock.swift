import Foundation

enum FailingMock {
    static func notImplemented(_ function: StaticString = #function) -> Never {
        fatalError("Mock method not implemented: \(function)")
    }
}