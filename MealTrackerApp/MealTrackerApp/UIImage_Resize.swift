//
//  UIImage_Resize.swift
//  MealTrackerApp
//
//  Created by Thrinai Batchu on 8/4/25.
//

import UIKit

extension UIImage {
    func resized(to size: CGSize, compressionQuality: CGFloat) -> Data? {
        let format = UIGraphicsImageRendererFormat.default()
        format.scale = 1
        let renderer = UIGraphicsImageRenderer(size: size, format: format)
        let resized = renderer.image { _ in
            self.draw(in: CGRect(origin: .zero, size: size))
        }
        return resized.jpegData(compressionQuality: compressionQuality)
    }
}
