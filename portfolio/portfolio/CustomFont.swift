//
//  CustomFont.swift
//  portfolio
//
//  Created by Andre Pham on 11/5/21.
//

import UIKit

class CustomFont: UIFont {
    
    // MARK: - Properties
    
    // Default sizes and weights for large subtitle
    static let LARGE_SUBTITLE_SIZE = 26.0
    static let LARGE_SUBTITLE_STYLE: TextStyle = .body
    static let LARGE_SUBTITLE_WEIGHT: Weight = .bold
    
    // Default sizes and weights for large subtitle detail
    static let LARGE_DETAIL_SUBTITLE_SIZE = 17.0
    static let LARGE_DETAIL_SUBTITLE_STYLE: TextStyle = .body
    static let LARGE_DETAIL_SUBTITLE_WEIGHT: Weight = .bold
    
    // Default sizes and weights for small subtitle
    static let SMALL_SUBTITLE_SIZE = 17.0
    static let SMALL_SUBTITLE_STYLE: TextStyle = .body
    static let SMALL_SUBTITLE_WEIGHT: Weight = .bold
    
    // Default sizes and weights for body
    static let BODY_SIZE = 16.0
    static let BODY_STYLE: TextStyle = .body
    static let BODY_WEIGHT: Weight = .regular
    
    // MARK: - Methods

    // SOURCE: https://mackarous.com/dev/2018/12/4/dynamic-type-at-any-font-weight#font-weight
    // AUTHOR: Andrew Mackarous - https://mackarous.com
    /// Assigns a font to a text field
    static func setFont(size: Double, style: TextStyle, weight: Weight) -> UIFont {
        let metrics = UIFontMetrics(forTextStyle: style)
        let font = UIFont.systemFont(ofSize: CGFloat(size), weight: weight)
        return metrics.scaledFont(for: font)
    }
    
    /// Assigns a font to a text field with the parameters to make a subtitle font
    static func setLargeSubtitleFont() -> UIFont {
        return self.setFont(size: self.LARGE_SUBTITLE_SIZE, style: self.LARGE_SUBTITLE_STYLE, weight: self.LARGE_SUBTITLE_WEIGHT)
    }
    
    /// Assigns a font to a text field with the parameters to make a subtitle font
    static func setSmallSubtitleFont() -> UIFont {
        return self.setFont(size: self.SMALL_SUBTITLE_SIZE, style: self.SMALL_SUBTITLE_STYLE, weight: self.SMALL_SUBTITLE_WEIGHT)
    }
    
    static func setLargeSubtitleDetailFont() -> UIFont {
        return self.setFont(size: self.LARGE_DETAIL_SUBTITLE_SIZE, style: LARGE_DETAIL_SUBTITLE_STYLE, weight: LARGE_DETAIL_SUBTITLE_WEIGHT).italic
    }
    
    /// Assigns a font to a text field with the parameters to make a body font
    static func setBodyFont() -> UIFont {
        return self.setFont(size: self.BODY_SIZE, style: self.BODY_STYLE, weight: self.BODY_WEIGHT)
    }
    
}

// CLEAN UP THIS IMPLEMENTATION LATER
// https://stackoverflow.com/questions/4713236/how-do-i-set-bold-and-italic-on-uilabel-of-iphone-ipad
// Maksymilian Wojakowski

extension UIFont {
    
    var bold: UIFont {
        return with(.traitBold)
    }

    var italic: UIFont {
        return with(.traitItalic)
    }

    var boldItalic: UIFont {
        return with([.traitBold, .traitItalic])
    }

    func with(_ traits: UIFontDescriptor.SymbolicTraits...) -> UIFont {
        guard let descriptor = self.fontDescriptor.withSymbolicTraits(UIFontDescriptor.SymbolicTraits(traits).union(self.fontDescriptor.symbolicTraits)) else {
            return self
        }
        return UIFont(descriptor: descriptor, size: 0)
    }

    func without(_ traits: UIFontDescriptor.SymbolicTraits...) -> UIFont {
        guard let descriptor = self.fontDescriptor.withSymbolicTraits(self.fontDescriptor.symbolicTraits.subtracting(UIFontDescriptor.SymbolicTraits(traits))) else {
            return self
        }
        return UIFont(descriptor: descriptor, size: 0)
    }
    
}
