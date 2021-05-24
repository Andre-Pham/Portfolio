//
//  CustomFont.swift
//  portfolio
//
//  Created by Andre Pham on 11/5/21.
//

import UIKit

class CustomFont: UIFont {
    
    // MARK: - Properties
    
    // Default sizes and weights for subtitle
    static let SUBTITLE_SIZE = 25.0
    static let SUBTITLE2_SIZE = 21.0
    static let SUBTITLE_STYLE: TextStyle = .body
    static let SUBTITLE_WEIGHT: Weight = .bold
    
    // Default sizes and weights for subtitle compliment
    static let SUBTITLE_COMPLIMENT_SIZE = 17.0
    static let SUBTITLE_COMPLIMENT_STYLE: TextStyle = .body
    static let SUBTITLE_COMPLIMENT_WEIGHT: Weight = .bold
    
    // Default sizes and weights for body
    static let BODY_SIZE = 16.0
    static let BODY_STYLE: TextStyle = .body
    static let BODY_WEIGHT: Weight = .regular
    
    // Default sizes and weights for detail
    static let DETAIL_SIZE = 12.0
    static let DETAIL_STYLE: TextStyle = .body
    static let DETAIL_WEIGHT: Weight = .light
    
    static let LARGE_SIZE = 50.0
    static let LARGE2_SIZE = 35.0
    static let LARGE_STYLE: TextStyle = .body
    static let LARGE_WEIGHT: Weight = .semibold
    
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
    static func setSubtitleFont() -> UIFont {
        return self.setFont(size: self.SUBTITLE_SIZE, style: self.SUBTITLE_STYLE, weight: self.SUBTITLE_WEIGHT)
    }
    
    static func setSubtitle2Font() -> UIFont {
        return self.setFont(size: self.SUBTITLE2_SIZE, style: self.SUBTITLE_STYLE, weight: self.SUBTITLE_WEIGHT)
    }
    
    static func setSubtitleComplementaryFont() -> UIFont {
        return self.setFont(size: self.SUBTITLE_COMPLIMENT_SIZE, style: SUBTITLE_COMPLIMENT_STYLE, weight: SUBTITLE_COMPLIMENT_WEIGHT).italic
    }
    
    /// Assigns a font to a text field with the parameters to make a body font
    static func setBodyFont() -> UIFont {
        return self.setFont(size: self.BODY_SIZE, style: self.BODY_STYLE, weight: self.BODY_WEIGHT)
    }
    
    static func setItalicBodyFont() -> UIFont {
        return self.setFont(size: self.BODY_SIZE, style: self.BODY_STYLE, weight: self.BODY_WEIGHT).italic
    }
    
    /// Assigns a font to a text field with the parameters to make a detail font, i.e. detail text field in tableview
    static func setDetailFont() -> UIFont {
        return self.setFont(size: self.DETAIL_SIZE, style: self.DETAIL_STYLE, weight: self.DETAIL_WEIGHT)
    }
    
    static func setLargeFont() -> UIFont {
        return self.setFont(size: self.LARGE_SIZE, style: self.LARGE_STYLE, weight: self.LARGE_WEIGHT)
    }
    
    static func setLarge2Font() -> UIFont {
        return self.setFont(size: self.LARGE2_SIZE, style: self.LARGE_STYLE, weight: self.LARGE_WEIGHT)
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
