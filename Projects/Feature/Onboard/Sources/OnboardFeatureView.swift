import SwiftUI
import UIComponent
import Domain

public struct OnboardFeatureView: View {
  public init() {}

  public var body: some View {
    VStack(spacing: 12) {
      Text("Onboard")
        .traceType(.displayLG)
        .foregroundStyle(TraceColor.textPrimary)
      Text("TRACE · Onboard feature")
        .traceType(.bodyMD)
        .foregroundStyle(TraceColor.char600)
    }
    .frame(maxWidth: .infinity, maxHeight: .infinity)
    .background(TraceColor.paper50)
  }
}
