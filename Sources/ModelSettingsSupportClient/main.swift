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

import CoreGraphics
import Collections
import CompactUUID
import ModelSettingsSupport

// Placeholders until NDGeometry package is available.
public typealias NDFloat = CGFloat
public typealias NDPoint = CGPoint
public typealias NDVector = CGVector
public typealias NDSize = CGSize
public typealias NDRect = CGRect

public extension UUIDBase58 {
    static let testSettings: UUIDBase58 = "5x9F8TcKRSosJzw9Ue9Rux"
    static let testSettingCustomFloatID: UUIDBase58 = "w7JYs2KuWtVXuqxYA5Ta3X"
    static let testSettingIsEnabledID: UUIDBase58 = "c8HeNprhppcfYwyTs7K7Di"
    static let testSettingPositionID: UUIDBase58 = "8rzzMozsCz8vuevUMGMcCM"
    static let testSettingAnotherPositionID: UUIDBase58 = "9taAshWYzrvW5VRQR6mRMZ"
    static let testSettingMagnitudeID: UUIDBase58 = "YX5kseueaSGpx187yDDqp"
}

func registerSettings(
    for containerType: (some ModelSettingPropertiesContainer).Type
) {
    print("Registered ModelSettingPropertiesContainer (name: \(containerType.__name)), (id: \(containerType.id)): \(containerType.__modelSettingProperties)")
}

@ModelSettingProperties(.testSettings)
public struct TestSettings {
    @ModelSettingID(.testSettingCustomFloatID)
    public var customFloat: NDFloat

    @ModelSettingID("c8HeNprhppcfYwyTs7K7Di")
    public let isEnabled: Bool

    // No ModelSettingID => should be ignored by macro
    public var ignored: Int

    @ModelSettingID(.testSettingPositionID)
    public let position: CGPoint

    @ModelSettingID(.testSettingAnotherPositionID)
    public let anotherPosition: NDPoint

    // Should appear as computed readOnly
    @ModelSettingID(.testSettingMagnitudeID)
    public var magnitude: NDFloat { abs(customFloat) }
}

func printModelSettingProperties() {
    print("Generated __modelSettingProperties count:",
          TestSettings.__modelSettingProperties.count)
    for p in TestSettings.__modelSettingProperties {
        print("""
        - key: \(p.key)
        - id: \(p.value.id)
          name: \(p.value.name)
          valueSource: \(p.value.valueSource)
          access: \(p.value.access)
          valueKind: \(p.value.valueKind)
          mapEntry: \(p.value.mapEntry)
        """)
    }
}

registerSettings(for: TestSettings.self)
printModelSettingProperties()
