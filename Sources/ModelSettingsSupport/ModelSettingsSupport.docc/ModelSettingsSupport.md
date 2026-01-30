# ``ModelSettingsSupport``

Macros to generate type ID, name, and properties for model settings, suitable for registration as a `ModelSettingPropertiesContainer` and subsequent reference for UI layouts.

## Overview

`ModelSettingsSupport` is built around two macros:

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

## Topics

### Essentials

Once a type has the @ModelSettingProperties and @ModelSettingID macros applied, conforming types can be registered as follows\:

```Swift
func registerSettings(
    for containerType: any ModelSettingPropertiesContainer.Type
) {
    print("Registered ModelSettingPropertiesContainer (name: \(containerType.__name)), (id: \(containerType.id)): \(containerType.__modelSettingProperties)")
}
```
