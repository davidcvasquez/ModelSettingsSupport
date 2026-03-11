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

import NDGeometry
import CoreGraphics

/// Keypath helper functions for model setting properties.
nonisolated public extension ModelSettingProperty {
    /// Forms a full read-only keypath for the given property ValueType from the given ContextType.
    @inlinable
    func withPath<ContextType, ValueType, Result>(
        from base: KeyPath<ContextType, ModelSettingPropertiesType>,
        as value: ValueType.Type = ValueType.self,
        _ body: (KeyPath<ContextType, ValueType>) -> Result
    ) -> Result? {
        guard let local = self.mapEntry as? KeyPath<ModelSettingPropertiesType, ValueType> else { return nil }
        let full = base.appending(path: local)
        return body(full)
    }

    /// Forms a full writable keypath for the given property ValueType from the given ContextType.
    @inlinable
    func withWritablePath<ContextType, ValueType, Result>(
        from base: WritableKeyPath<ContextType, ModelSettingPropertiesType>,
        as value: ValueType.Type = ValueType.self,
        _ body: (WritableKeyPath<ContextType, ValueType>) -> Result
    ) -> Result? {
        guard let local = self.mapEntry as? WritableKeyPath<ModelSettingPropertiesType, ValueType> else { return nil }
        let full = base.appending(path: local)
        return body(full)
    }

    /// Forms a full writable keypath for the given property PointType from the given ContextType.
    @inlinable
    func withWritablePointPath<ContextType, PointType, Result>(
        from base: WritableKeyPath<ContextType, ModelSettingPropertiesType>,
        as point: PointType.Type = PointType.self,
        _ body: (
            WritableKeyPath<ContextType, PointType.Scalar>,
            WritableKeyPath<ContextType, PointType.Scalar>
        ) -> Result
    ) -> Result?
    where PointType: WritablePoint
    {
        guard let localPointKP =
            self.mapEntry as? WritableKeyPath<ModelSettingPropertiesType, PointType>
        else { return nil }

        let fullSizeKP = base.appending(path: localPointKP)
        let xKP  = fullSizeKP.appending(path: PointType.xKeyPath)
        let yKP = fullSizeKP.appending(path: PointType.yKeyPath)
        return body(xKP, yKP)
    }

    /// Forms a full writable keypath for the given property SizeType from the given ContextType.
    @inlinable
    func withWritableSizePath<ContextType, SizeType, Result>(
        from base: WritableKeyPath<ContextType, ModelSettingPropertiesType>,
        as size: SizeType.Type = SizeType.self,
        _ body: (
            WritableKeyPath<ContextType, SizeType.Scalar>,
            WritableKeyPath<ContextType, SizeType.Scalar>
        ) -> Result
    ) -> Result?
    where SizeType: WritableSize
    {
        guard let localSizeKP =
            self.mapEntry as? WritableKeyPath<ModelSettingPropertiesType, SizeType>
        else { return nil }

        let fullSizeKP = base.appending(path: localSizeKP)
        let widthKP  = fullSizeKP.appending(path: SizeType.widthKeyPath)
        let heightKP = fullSizeKP.appending(path: SizeType.heightKeyPath)
        return body(widthKP, heightKP)
    }
}

/// A protocol for accessing the writable keypaths for the properties of a point type with the associated Scalar type.
nonisolated public protocol WritablePoint {
    associatedtype Scalar

    static var xKeyPath: WritableKeyPath<Self, Scalar> { get }
    static var yKeyPath: WritableKeyPath<Self, Scalar> { get }
}

nonisolated extension CGPoint: WritablePoint {
    public typealias Scalar = CGFloat

    public static var xKeyPath: WritableKeyPath<CGPoint, Scalar> {
        \.x
    }

    public static var yKeyPath: WritableKeyPath<CGPoint, Scalar> {
        \.y
    }
}

nonisolated extension NDPoint: WritablePoint {
    public typealias Scalar = NDFloat

    public static var xKeyPath: WritableKeyPath<NDPoint, Scalar> {
        \.x
    }

    public static var yKeyPath: WritableKeyPath<NDPoint, Scalar> {
        \.y
    }
}

/// A protocol for accessing the writable keypaths for the properties of a size type with the associated Scalar type.
nonisolated public protocol WritableSize {
    associatedtype Scalar

    static var widthKeyPath: WritableKeyPath<Self, Scalar> { get }
    static var heightKeyPath: WritableKeyPath<Self, Scalar> { get }
}

nonisolated extension CGSize: WritableSize {
    public typealias Scalar = CGFloat

    public static var widthKeyPath: WritableKeyPath<CGSize, Scalar> {
        \.width
    }

    public static var heightKeyPath: WritableKeyPath<CGSize, Scalar> {
        \.height
    }
}

nonisolated extension NDSize: WritableSize {
    public typealias Scalar = NDFloat

    public static var widthKeyPath: WritableKeyPath<NDSize, Scalar> {
        \.width
    }

    public static var heightKeyPath: WritableKeyPath<NDSize, Scalar> {
        \.height
    }
}

///-------------------------------------------------------------------------------------------------
/// EOF
///-------------------------------------------------------------------------------------------------
