//
//  RichTextEditorModel.swift
//  Performance Archery
//
//  Created by Luke Myers on 06/04/2026.
//

import SwiftUI

@Observable
class RichTextEditorModel {
    var text: AttributedString
    var selection: AttributedTextSelection
    var currentFontSize: CGFloat
    var currentDesign: Font.Design
    
    init(text: AttributedString = "", fontSize: CGFloat = 17.0, design: Font.Design = .default) {
        self.text = text
        self.selection = AttributedTextSelection()
        self.currentFontSize = fontSize
        self.currentDesign = design
    }
    
    func isBold(context: SwiftUI.Font.Context) -> Bool {
        let attrs = selection.typingAttributes(in: text)
        guard let font = attrs.font else { return false }
        return font.resolve(in: context).isBold
    }
    
    func isItalic(context: SwiftUI.Font.Context) -> Bool {
        let attrs = selection.typingAttributes(in: text)
        guard let font = attrs.font else { return false }
        return font.resolve(in: context).isItalic
    }
    
    var isUnderlined: Bool {
        let attrs = selection.typingAttributes(in: text)
        return attrs.underlineStyle != nil
    }
    
    func toggleBold(context: SwiftUI.Font.Context) {
        text.transformAttributes(in: &selection) { container in
            let font = container.font ?? .system(size: currentFontSize, design: currentDesign)
            let resolved = font.resolve(in: context)
            
            container.font = buildFont(
                size: currentFontSize,
                design: currentDesign,
                isBold: !resolved.isBold,
                isItalic: resolved.isItalic
            )
        }
    }
    
    func toggleItalic(context: SwiftUI.Font.Context) {
        text.transformAttributes(in: &selection) { container in
            let font = container.font ?? .system(size: currentFontSize, design: currentDesign)
            let resolved = font.resolve(in: context)
            
            container.font = buildFont(
                size: currentFontSize,
                design: currentDesign,
                isBold: resolved.isBold,
                isItalic: !resolved.isItalic
            )
        }
    }
    
    func toggleUnderline() {
        text.transformAttributes(in: &selection) { container in
            container.underlineStyle = container.underlineStyle == nil ? .single : nil
        }
    }
    
    private func setFontSize(to size: CGFloat, context: SwiftUI.Font.Context) {
        text.transformAttributes(in: &selection) { container in
            let font = container.font ?? .system(size: currentFontSize, design: currentDesign)
            let resolved = font.resolve(in: context)
            
            container.font = buildFont(
                size: size,
                design: currentDesign,
                isBold: resolved.isBold,
                isItalic: resolved.isItalic
            )
        }
    }
    
    func setDesign(_ design: Font.Design, context: SwiftUI.Font.Context) {
        currentDesign = design
        text.transformAttributes(in: &selection) { container in
            let font = container.font ?? .system(size: currentFontSize, design: currentDesign)
            let resolved = font.resolve(in: context)
            
            container.font = buildFont(
                size: currentFontSize,
                design: design,
                isBold: resolved.isBold,
                isItalic: resolved.isItalic
            )
        }
    }
    
    private func buildFont(size: CGFloat, design: Font.Design, isBold: Bool, isItalic: Bool) -> Font {
        var newFont: Font = .system(size: size, design: design)
        if isBold { newFont = newFont.bold() }
        if isItalic { newFont = newFont.italic() }
        return newFont
    }
    
    func selectionSupportsItalic(context: SwiftUI.Font.Context) -> Bool {
        let attrs = selection.typingAttributes(in: text)
        let currentFont = attrs.font ?? .system(size: currentFontSize, design: currentDesign)
        
        let italicTestFont = currentFont.italic(true)
        
        return italicTestFont.resolve(in: context).isItalic
    }
    
    enum TextStyle {
        case title, heading, subheading, body
    }

    func setTextStyle(_ style: TextStyle, context: SwiftUI.Font.Context) {
        let size: CGFloat
        let bold: Bool
        
        switch style {
        case .title: (size, bold) = (28, true)
        case .heading: (size, bold) = (22, true)
        case .subheading: (size, bold) = (19, true)
        case .body: (size, bold) = (17, false)
        }
        
        currentFontSize = size
        text.transformAttributes(in: &selection) { container in
            let font = container.font ?? .system(size: currentFontSize, design: currentDesign)
            let resolved = font.resolve(in: context)
            
            container.font = buildFont(
                size: size,
                design: currentDesign,
                isBold: bold,
                isItalic: resolved.isItalic
            )
        }
    }
}
