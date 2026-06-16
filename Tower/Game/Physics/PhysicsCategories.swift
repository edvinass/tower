import Foundation

enum PhysicsCategory {
    static let none: UInt32 = 0
    static let block: UInt32 = 0x1 << 0
    static let platform: UInt32 = 0x1 << 1
    static let ground: UInt32 = 0x1 << 2
}
