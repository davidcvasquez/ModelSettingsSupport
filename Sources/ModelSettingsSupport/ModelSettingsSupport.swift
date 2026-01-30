//===----------------------------------------------------------------------===//
//
// This source file is part of the ModelSettingsSupport open source project
//
// Copyright (c) 2026 David C. Vasquez and the ModelSettingsSupport project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See the project's LICENSE.txt for license information
//
//===----------------------------------------------------------------------===//

import CompactUUID

public protocol StaticIdentifiable<ID> {

    /// A type representing the stable identity of the type.
    associatedtype ID : Hashable

    /// The stable identity of the type.
    static var id: Self.ID { get }
}

public protocol ModelSettingPropertiesContainer: StaticIdentifiable {
    static var __name: String { get }
    static var __modelSettingProperties: [ModelSettingProperty] { get }
}

@attached(member, names: named(id), named(__name), named(__modelSettingProperties))
@attached(extension, conformances: ModelSettingPropertiesContainer)
public macro ModelSettingProperties(_ id: UUIDBase58) = #externalMacro(
    module: "ModelSettingsSupportMacros",
    type: "ModelSettingPropertiesMacro"
)

@attached(peer)
public macro ModelSettingID(_ id: UUIDBase58) = #externalMacro(
    module: "ModelSettingsSupportMacros",
    type: "ModelSettingIDMacro"
)

public struct ModelSettingProperty {
    public let id: UUIDBase58
    public let name: String
    public let valueSource: PropertyValueSource
    public let access: PropertyAccessKind
    public let valueKind: PropertyValueKind

    public init(id: UUIDBase58, name: String, valueSource: PropertyValueSource, access: PropertyAccessKind, valueKind: PropertyValueKind) {
        self.id = id
        self.name = name
        self.valueSource = valueSource
        self.access = access
        self.valueKind = valueKind
    }
}

public enum PropertyValueSource: String { case stored, computed }
public enum PropertyAccessKind: String { case readOnly, readWrite }

public enum PropertyValueKind: CustomStringConvertible {
    case bool
    case int
    case float
    case cgFloat
    case ndFloat
    case angle
    case ndAngle
    case cgPoint
    case ndPoint
    case ndPolarPoint
    case cgVector
    case ndVector
    case cgSize
    case ndSize
    case cgRect
    case ndRect
    case color
    case cgColor
    case text
    case other(String)

    public var description: String {
        switch self {
        case .bool: return "bool"
        case .int: return "int"
        case .float: return "float"
        case .cgFloat: return "cgFloat"
        case .ndFloat: return "ndFloat"
        case .angle: return "angle"
        case .ndAngle: return "ndAngle"
        case .cgPoint: return "cgPoint"
        case .ndPoint: return "ndPoint"
        case .ndPolarPoint: return "ndPolarPoint"
        case .cgVector: return "cgVector"
        case .ndVector: return "ndVector"
        case .cgSize: return "cgSize"
        case .ndSize: return "ndSize"
        case .cgRect: return "cgRect"
        case .ndRect: return "ndRect"
        case .color: return "color"
        case .cgColor: return "cgColor"
        case .text: return "text"
        case .other(let s): return "other(\(s))"
        }
    }
}
