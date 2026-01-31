# ModelSettingsSupport

[![Swift](https://github.com/davidcvasquez/ModelSettingsSupport/actions/workflows/swift.yml/badge.svg)](https://github.com/davidcvasquez/ModelSettingsSupport/actions/workflows/swift.yml) [![codecov](https://codecov.io/gh/davidcvasquez/ModelSettingsSupport/graph/badge.svg?token=XB7T7FXO8B)](https://codecov.io/gh/davidcvasquez/ModelSettingsSupport)

Swift macros to generate type ID, name, and properties for model settings, suitable for registration as a `ModelSettingPropertiesContainer` and subsequent reference for UI layouts.

## Details

`ModelSettingsSupport` is built around two macros\:

- `@ModelSettingProperties`
- `@ModelSettingID`

## Usage

```Swift
public extension UUIDBase58 {
    static let testSettings: UUIDBase58 = "5x9F8TcKRSosJzw9Ue9Rux"
    static let testSettingCustomFloatID: UUIDBase58 = "w7JYs2KuWtVXuqxYA5Ta3X"
}

@ModelSettingProperties(.testSettings)
public struct TestSettings {
    @ModelSettingID(.testSettingCustomFloatID)
    public var customFloat: NDFloat
```

## Minting ID values

Use `UUIDBase58` as the format for CompactUUID.

We recommend using the `xcCompactUUID` Xcode Source Editor extension to mint new IDs directly in the source code editor.

You can also use the `compactuuid` command line interface (CLI) tool to generate these IDs with the default format.

## Registration

Once a type has the @ModelSettingProperties and @ModelSettingID macros applied, conforming types can be registered as follows\:

```Swift
func registerSettings(
    for containerType: any ModelSettingPropertiesContainer.Type
) {
    print("Registered ModelSettingPropertiesContainer (name: \(containerType.__name)), (id: \(containerType.id)): \(containerType.__modelSettingProperties)")
}
```

Registrars of types can then access the type ID, name, and properties using the synthesized static members on the type\:

```Swift
public protocol StaticIdentifiable<ID> {

    /// A type representing the stable identity of the type.
    associatedtype ID : Hashable

    /// The stable identity of the type.
    static var id: Self.ID { get }
}

public protocol ModelSettingPropertiesContainer: StaticIdentifiable {
    static var __name: String { get }
    static var __modelSettingProperties: OrderedDictionary<UUIDBase58, ModelSettingProperty<TestSettings>> { get }
}

public struct ModelSettingProperty {
    public let id: UUIDBase58
    public let name: String
    public let valueSource: PropertyValueSource
    public let access: PropertyAccessKind
    public let valueKind: PropertyValueKind
    public let mapEntry: PartialKeyPath<ModelSettingPropertiesType>

    public init(
        id: UUIDBase58,
        name: String,
        valueSource: PropertyValueSource,
        access: PropertyAccessKind,
        valueKind: PropertyValueKind,
        mapEntry: PartialKeyPath<ModelSettingPropertiesType>
    ) {
        self.id = id
        self.name = name
        self.valueSource = valueSource
        self.access = access
        self.valueKind = valueKind
        self.mapEntry = mapEntry
    }
}

public enum PropertyValueSource: String {
    case stored
    case computed
}

public enum PropertyAccessKind: String {
    case readOnly
    case readWrite
}

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
    // ...
}
```

## Supported Versions

The minimum Swift version supported by ModelSettingsSupport is 5.9.
