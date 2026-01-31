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

import SwiftCompilerPlugin
import SwiftSyntax
import SwiftSyntaxBuilder
import SwiftSyntaxMacros
import SwiftDiagnostics

import Foundation
import Collections
import CompactUUID

@main
struct ModelSettingsSupportPlugin: CompilerPlugin {
    let providingMacros: [Macro.Type] = [
        ModelSettingIDMacro.self,
        ModelSettingPropertiesMacro.self,
    ]
}

public struct ModelSettingIDMacro: PeerMacro {
    public static func expansion(
        of node: AttributeSyntax,
        providingPeersOf decl: some DeclSyntaxProtocol,
        in context: some MacroExpansionContext
    ) throws -> [DeclSyntax] {
        // Intentionally generates nothing.
        return []
    }
}

public struct ModelSettingPropertiesMacro: MemberMacro {

    public static func expansion(
        of node: AttributeSyntax,
        providingMembersOf decl: some DeclGroupSyntax,
        conformingTo protocols: [TypeSyntax],
        in context: some MacroExpansionContext
    ) throws -> [DeclSyntax] {

        guard let structDecl = decl.as(StructDeclSyntax.self) else {
            return []
        }

        guard let idExpr = containerIDExprText(from: node) else {
            context.diagnose(Diagnostic(node: Syntax(node), message: MissingContainerIDMessage()))
            return []
        }

        let properties = collectModelSettingProperties(from: structDecl, in: context)

        let typeName = structDecl.name.text

        let itemsSource = properties.map { property in
            """
            \(property.id) : .init(
                id: \(property.id),
                name: "\(property.name)",
                valueSource: .\(property.valueSource),
                access: .\(property.access),
                valueKind: \(valueKindExpr(property.valueKind)),
                mapEntry: \\.\(property.name)
            )
            """
        }.joined(separator: ",\n")

        let idDecl =
        """
        public static let id: UUIDBase58 = \(idExpr)
        """

        let nameDecl =
        """
        public static let __name: String = "\(typeName)"
        """

        let source =
        """
        public static let __modelSettingProperties: OrderedDictionary<UUIDBase58, ModelSettingProperty<\(typeName)>> = [
        \(itemsSource.isEmpty ? "" : "    ")\(itemsSource.replacingOccurrences(of: "\n", with: "\n    "))
        ]
        """

        return [
            DeclSyntax(stringLiteral: idDecl),
            DeclSyntax(stringLiteral: nameDecl),
            DeclSyntax(stringLiteral: source)
        ]
    }
}

extension ModelSettingPropertiesMacro: ExtensionMacro {

    public static func expansion(
        of node: AttributeSyntax,
        attachedTo decl: some DeclGroupSyntax,
        providingExtensionsOf type: some TypeSyntaxProtocol,
        conformingTo protocols: [TypeSyntax],
        in context: some MacroExpansionContext
    ) throws -> [ExtensionDeclSyntax] {

        // Generate: extension <Type>: ModelSettingPropertiesContainer {}
        // We can hardcode the protocol name since the macro declaration specified it.
        let ext: ExtensionDeclSyntax = try ExtensionDeclSyntax(
            """
            extension \(type): ModelSettingPropertiesContainer {}
            """
        )
        return [ext]
    }
}

private struct _ModelSettingProperty {
    let id: UUIDBase58
    let name: String
    let valueSource: _ValueSource         // "stored" / "computed"
    let access: _AccessKind
    let valueKind: _ValueKind
}

private enum _ValueSource {
    case stored
    case computed
}

private enum _AccessKind {
    case readOnly
    case readWrite
}

private enum _ValueKind {
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
}

private func valueKindExpr(_ k: _ValueKind) -> String {
    switch k {
    case .bool:          return ".bool"
    case .int:           return ".int"
    case .float:         return ".float"
    case .cgFloat:       return ".cgFloat"
    case .angle:         return ".angle"
    case .ndAngle:       return ".ndAngle"
    case .ndFloat:       return ".ndFloat"
    case .cgPoint:       return ".cgPoint"
    case .ndPoint:       return ".ndPoint"
    case .ndPolarPoint:  return ".ndPolarPoint"
    case .cgVector:      return ".cgVector"
    case .ndVector:      return ".ndVector"
    case .cgSize:        return ".cgSize"
    case .ndSize:        return ".ndSize"
    case .cgRect:        return ".cgRect"
    case .ndRect:        return ".ndRect"
    case .color:         return ".color"
    case .cgColor:       return ".cgColor"
    case .text:          return ".text"
    case .other(let t):
        let escaped = t.replacingOccurrences(of: #"\"#, with: #"\\\"#)
        return #".other("\#(escaped)")"#
    }
}

private func containerIDExprText(from node: AttributeSyntax) -> String? {
    // Expect @ModelSettingProperties(<expr>)
    guard
        let args = node.arguments?.as(LabeledExprListSyntax.self),
        let first = args.first
    else { return nil }

    return first.expression.description
        .trimmingCharacters(in: .whitespacesAndNewlines)
}

private struct MissingContainerIDMessage: DiagnosticMessage {
    var message: String { "@ModelSettingProperties requires an ID argument, e.g. @ModelSettingProperties(.myTypeID)" }
    var diagnosticID: MessageID { .init(domain: "ModelSettingsSupport", id: "missing-container-id") }
    var severity: DiagnosticSeverity { .error }
}

// MARK: - Collecting

private func collectModelSettingProperties(
    from structDecl: StructDeclSyntax,
    in context: some MacroExpansionContext
) -> [_ModelSettingProperty] {
    var result: [_ModelSettingProperty] = []

    // Keep the first syntax location we saw each ID at
    var firstUseByID: [String: Syntax] = [:]

    for memberItem in structDecl.memberBlock.members {
        guard let varDecl = memberItem.decl.as(VariableDeclSyntax.self) else { continue }

        // Skip static/class properties
        if isStatic(varDecl) { continue }

        // IMPORTANT: only include properties that have @ModelSettingID("...")
        guard let (idExprText, idKey, idAttrSyntax) = modelSettingID(from: varDecl, in: context) else {
            context.diagnose(
                Diagnostic(
                    node: Syntax(structDecl),
                    message: SimpleNoteMessage(message: "modelSettingID failed.")
                )
            )
            continue
        }

        let isLet = (varDecl.bindingSpecifier.tokenKind == .keyword(.let))

        // Duplicate detection
        if let firstSyntax = firstUseByID[idKey] {
            // Error on the duplicate
            context.diagnose(
                Diagnostic(node: Syntax(idAttrSyntax),
                           message: DuplicateSettingIDMessage(id: idKey))
            )
            // Note on the first one
            context.diagnose(
                Diagnostic(node: firstSyntax,
                           message: FirstSettingIDHereNote())
            )

            // You can either skip adding the duplicate property, or still add it.
            // Skipping is usually better to avoid cascaded errors.
            continue
        } else {
            firstUseByID[idKey] = Syntax(idAttrSyntax)
        }

        for binding in varDecl.bindings {
            guard let ident = binding.pattern.as(IdentifierPatternSyntax.self) else { continue }
            let name = ident.identifier.text

            let accessorSpecifiers = accessorSpecifiers(in: binding.accessorBlock)

            let hasGet = accessorSpecifiers.contains("get")
            let hasSet = accessorSpecifiers.contains("set")
            let hasObserversOnly = !accessorSpecifiers.isEmpty && !hasGet && !hasSet

            let storage: _ValueSource
            if binding.accessorBlock == nil || hasObserversOnly {
                storage = .stored
            } else {
                storage = .computed
            }

            let access: _AccessKind
            switch storage {
            case .stored:
                access = isLet ? .readOnly : .readWrite
            default:
                access = hasSet ? .readWrite : .readOnly
            }

            let spelledType = spelledTypeName(from: binding)
            let kind = classifyValueKind(spelledType)

            result.append(.init(
                id: idExprText,
                name: name,
                valueSource: storage,
                access: access,
                valueKind: kind
            ))
        }
    }

    return result
}

private struct SimpleNoteMessage: DiagnosticMessage {
    let message: String

    var diagnosticID: MessageID {
        .init(domain: "ModelSettingsSupport", id: "note")
    }

    var severity: DiagnosticSeverity {
        .note
    }
}

private struct DuplicateSettingIDMessage: DiagnosticMessage {
    let id: String
    var message: String { #"Duplicate @ModelSettingID("\#(id)") used on multiple properties."# }
    var diagnosticID: MessageID { .init(domain: "ModelSettingsSupport", id: "duplicate-setting-id") }
    var severity: DiagnosticSeverity { .error }
}

private struct FirstSettingIDHereNote: DiagnosticMessage {
    var message: String { "First use of this setting ID is here." }
    var diagnosticID: MessageID { .init(domain: "ModelSettingsSupport", id: "duplicate-setting-id-first") }
    var severity: DiagnosticSeverity { .note }
}

private func isStatic(_ varDecl: VariableDeclSyntax) -> Bool {
    let modifiers = varDecl.modifiers
    return modifiers.contains { m in
        let t = m.name.text
        return t == "static" || t == "class"
    }
}

private func accessorSpecifiers(in accessorBlock: AccessorBlockSyntax?) -> Set<String> {
    guard let accessorBlock else { return [] }

    switch accessorBlock.accessors {
    case .getter:
        return ["get"] // `{ expr }`
    case .accessors(let list):
        return Set(list.map { $0.accessorSpecifier.text })
    }
}

private func spelledTypeName(from binding: PatternBindingSyntax) -> String {
    guard let typeAnn = binding.typeAnnotation else { return "Unknown" }

    var t = typeAnn.type.description
        .trimmingCharacters(in: .whitespacesAndNewlines)
        .replacingOccurrences(of: "\n", with: " ")
        .trimmingCharacters(in: .whitespacesAndNewlines)

    if t.hasSuffix("?") {
        t.removeLast()
        return t.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    if t.hasPrefix("Optional<"), t.hasSuffix(">") {
        let inner = t.dropFirst("Optional<".count).dropLast()
        return inner.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    return t
}

private func classifyValueKind(_ spelledType: String) -> _ValueKind {
    let t = spelledType
        .replacingOccurrences(of: "Swift.", with: "")
        .replacingOccurrences(of: "CoreGraphics.", with: "")
        .replacingOccurrences(of: "SwiftUI.", with: "")
        .trimmingCharacters(in: .whitespacesAndNewlines)

    switch t {
    case "Bool":
        return .bool

    case "Int", "Int8", "Int16", "Int32", "Int64",
         "UInt", "UInt8", "UInt16", "UInt32", "UInt64":
        return .int

    case "Float", "Double":
        return .float

    case "CGFloat":
        return .cgFloat

    case "NDFloat":
        return .ndFloat

    case "Angle":
        return .angle

    case "NDAngle":
        return .ndAngle

    case "CGPoint":
        return .cgPoint

    case "NDPoint":
        return .ndPoint

    case "NDPointPolarPoint":
        return .ndPolarPoint

    case "CGVector":
        return .cgVector

    case "NDVector":
        return .ndVector

    case "CGSize":
        return .cgSize

    case "NDSize":
        return .ndSize

    case "CGRect":
        return .cgRect

    case "NDRect":
        return .ndRect

    case "Color":
        return .color

    case "CGColor":
        return .cgColor

    case "String":
        return .text

    default:
        return .other(t)
    }
}

private func modelSettingID(
    from varDecl: VariableDeclSyntax,
    in context: some MacroExpansionContext
) -> (idExprText: String, idKey: String, attr: AttributeSyntax)? {
    let attrs = varDecl.attributes
    if attrs.isEmpty {
        return nil
    }

    for element in attrs {
        guard let a = element.as(AttributeSyntax.self) else {
            context.diagnose(
                Diagnostic(
                    node: Syntax(varDecl),
                    message: SimpleNoteMessage(message: "modelSettingID no element.")
                )
            )
            continue
        }

        // Matches @ModelSettingID(...)
        let name = a.attributeName.description
            .trimmingCharacters(in: .whitespacesAndNewlines)

        guard name == "ModelSettingID" else {
            context.diagnose(
                Diagnostic(
                    node: Syntax(varDecl),
                    message: SimpleNoteMessage(message: "modelSettingID not named.")
                )
            )
            continue
        }

        // SwiftSyntax represents arguments as LabeledExprListSyntax in modern toolchains.
        guard
            let args = a.arguments?.as(LabeledExprListSyntax.self),
            let first = args.first
        else {
            context.diagnose(
                Diagnostic(
                    node: Syntax(varDecl),
                    message: SimpleNoteMessage(message: "modelSettingID not named.")
                )
            )
            return nil
        }

        let expr = first.expression
        let exprText = expr.description.trimmingCharacters(in: .whitespacesAndNewlines)

        let key: String

        if let lit = expr.as(StringLiteralExprSyntax.self) {
            let value = lit.segments.compactMap { seg -> String? in
                seg.as(StringSegmentSyntax.self)?.content.text
            }.joined()
            key = value.isEmpty ? exprText : value
        } else {
            key = exprText
        }

        guard !exprText.isEmpty else { return nil }
        return (exprText, key, a)
    }

    return nil
}
