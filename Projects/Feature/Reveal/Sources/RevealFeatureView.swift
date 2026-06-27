import SwiftUI
import UIComponent
import Domain

public struct RevealFeatureView: View {
  public init() {}

  public var body: some View {
    VStack(spacing: 12) {
      Text("Reveal")
        .traceType(.displayLG)
        .foregroundStyle(TraceColor.textPrimary)
      Text("TRACE · Reveal feature")
        .traceType(.bodyMD)
        .foregroundStyle(TraceColor.char600)
    }
    .frame(maxWidth: .infinity, maxHeight: .infinity)
    .background(TraceColor.paper50)
  }
}
