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

import SwiftSyntax
import SwiftSyntaxBuilder
import SwiftSyntaxMacros
import SwiftSyntaxMacrosTestSupport
import XCTest

// Macro implementations build for the host, so the corresponding module is not available when cross-compiling. Cross-compiled tests may still make use of the macro itself in end-to-end tests.
#if canImport(ModelSettingsSupportMacros)
import ModelSettingsSupportMacros

let testMacros: [String: Macro.Type] = [
    "ModelSettingProperties": ModelSettingPropertiesMacro.self,
]
#endif

final class ModelSettingsSupportTests: XCTestCase {
    func testMacro() throws {
        #if canImport(ModelSettingsSupportMacros)
        assertMacroExpansion(
            """
            @ModelSettingProperties("5x9F8TcKRSosJzw9Ue9Rux")
            public struct TestSettings {
                @ModelSettingID("c8HeNprhppcfYwyTs7K7Di")
                public let isEnabled: Bool
            }
            """,
            expandedSource: """
            public struct TestSettings {
                @ModelSettingID("c8HeNprhppcfYwyTs7K7Di")
                public let isEnabled: Bool

                public static let id: UUIDBase58 = "5x9F8TcKRSosJzw9Ue9Rux"
            
                public static let __name: String = "TestSettings"

                public static let __modelSettingProperties: [ModelSettingProperty] = [
                    .init(
                        id: "c8HeNprhppcfYwyTs7K7Di",
                        name: "isEnabled",
                        valueSource: .stored,
                        access: .readOnly,
                        valueKind: .bool
                    )
                ]
            }

            extension TestSettings: ModelSettingPropertiesContainer {
            }
            """,
            macros: testMacros
        )
        #else
        throw XCTSkip("macros are only supported when running tests for the host platform")
        #endif
    }
}
