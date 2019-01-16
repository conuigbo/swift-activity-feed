//
//  UIImage+Extensions.swift
//  GetStreamActivityFeed
//
//  Created by Alexey Bukhtin on 16/01/2019.
//  Copyright © 2019 Stream.io Inc. All rights reserved.
//

import UIKit

// MARK: - Modes

extension UIImage {
    /// The image always draw the original image, without treating it as a template
    public var original: UIImage {
        return withRenderingMode(.alwaysOriginal)
    }
    
    /// The image always draw the image as a template image, ignoring its color information
    public var template: UIImage {
        return withRenderingMode(.alwaysTemplate)
    }
}

// MARK: - Edit

extension UIImage {
    
    /// The rounded image with the half of height for the corner radius.
    public var rounded: UIImage {
        return rounded(with: size.height / 2)
    }
    
    /// Make an image rounded.
    ///
    /// - Parameter radius: the radius of each corner oval. Values larger than half the images width or height are clamped
    ///                     appropriately to half the width or height.
    /// - Returns: the rounded image.
    public func rounded(with radius: CGFloat) -> UIImage {
        guard size != .zero, radius > 0, (radius < size.height || radius < size.width) else {
            return self
        }
        
        UIGraphicsBeginImageContextWithOptions(size, false, 0.0)
        defer { UIGraphicsEndImageContext() }
        
        if let context = UIGraphicsGetCurrentContext() {
            context.interpolationQuality = .high
        }
        
        let rect = CGRect(origin: .zero, size: size)
        UIBezierPath(roundedRect: rect, cornerRadius: radius).addClip()
        draw(in: rect)
        
        return UIGraphicsGetImageFromCurrentImageContext() ?? self
    }
    
    /// Resize an image as square.
    ///
    /// - Parameter width: a width of the square.
    /// - Returns: a squared image.
    public func square(with width: CGFloat = 0) -> UIImage {
        guard size.width > 0, (width > 0 || size.width != size.height) else {
            return self
        }
        
        var resizeWidth = width
        
        if width < 1 {
            resizeWidth = min(size.width, size.height)
        }
        
        return resize(with: CGSize(width: resizeWidth, height: resizeWidth))
    }
    
    /// Resize an image.
    ///
    /// - Parameters:
    ///     - size: a size of the resized image.
    ///     - crop: a crop mode for the resized image. Default: scaleAspectFill.
    /// - Returns: a squared image.
    public func resize(with size: CGSize, crop: UIView.ContentMode = .scaleAspectFill) -> UIImage {
        guard size != .zero, self.size != size, self.size.width > 0, self.size.height > 0 else {
            return self
        }
        
        let widthRatio = size.width  / self.size.width
        let heightRatio = size.height / self.size.height
        var origin = CGPoint.zero
        var newSize = size
        
        if widthRatio != heightRatio {
            let scalingFactor = crop == .scaleAspectFill ?  max(widthRatio, heightRatio) : min(widthRatio, heightRatio)
            newSize = CGSize(width: self.size.width  * scalingFactor, height: self.size.height * scalingFactor)
            origin = CGPoint(x: (size.width - newSize.width)  / 2, y: (size.height - newSize.height) / 2)
        }
        
        let cropRect = CGRect(x: origin.x, y: origin.y, width: newSize.width, height: newSize.height)
        
        UIGraphicsBeginImageContextWithOptions(size, false, 0.0)
        defer { UIGraphicsEndImageContext() }
        draw(in: cropRect)
        
        return UIGraphicsGetImageFromCurrentImageContext() ?? self
    }
    
    /// Make a transparent image.
    ///
    /// - Parameter alpha: The desired opacity of the image, specified as a value between 0.0 and 1.0.
    ///                    A value of 0.0 renders the image totally transparent while 1.0 renders it fully opaque.
    ///                    Values larger than 1.0 are interpreted as 1.0.
    /// - Returns: the transparented image.
    public func transparent(alpha: CGFloat) -> UIImage {
        guard alpha >= 0, alpha <= 1 else {
            return self
        }
        
        UIGraphicsBeginImageContextWithOptions(size, false, 0.0)
        defer { UIGraphicsEndImageContext() }
        draw(in: CGRect(origin: .zero, size: size), blendMode: .normal, alpha: alpha)
        
        return UIGraphicsGetImageFromCurrentImageContext() ?? self
    }
}
