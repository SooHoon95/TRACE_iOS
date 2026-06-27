import SwiftUI
import UIComponent
import Domain

public struct HuntFeatureView: View {
  public init() {}

  public var body: some View {
    VStack(spacing: 12) {
      Text("Hunt")
        .traceType(.displayLG)
        .foregroundStyle(TraceColor.textPrimary)
      Text("TRACE · Hunt feature")
        .traceType(.bodyMD)
        .foregroundStyle(TraceColor.char600)
    }
    .frame(maxWidth: .infinity, maxHeight: .infinity)
    .background(TraceColor.paper50)
  }
}
