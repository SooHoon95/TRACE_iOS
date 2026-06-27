import SwiftUI
import UIComponent
import Domain

public struct MainTabFeatureView: View {
  public init() {}

  public var body: some View {
    VStack(spacing: 12) {
      Text("MainTab")
        .traceType(.displayLG)
        .foregroundStyle(TraceColor.textPrimary)
      Text("TRACE · MainTab feature")
        .traceType(.bodyMD)
        .foregroundStyle(TraceColor.char600)
    }
    .frame(maxWidth: .infinity, maxHeight: .infinity)
    .background(TraceColor.paper50)
  }
}
