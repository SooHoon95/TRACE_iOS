//
//  View+Extension.swift
//  UIComponent
//

import SwiftUI

public extension View {
  /// Conditionally applies a transform to the view.
  @ViewBuilder
  func applyIf<Content: View>(_ condition: Bool, transform: (Self) -> Content) -> some View {
    if condition {
      transform(self)
    } else {
      self
    }
  }
}
