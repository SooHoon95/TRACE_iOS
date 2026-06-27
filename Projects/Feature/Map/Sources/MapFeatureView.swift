import SwiftUI
import UIComponent
import Domain

public struct MapFeatureView: View {
  public init() {}

  public var body: some View {
    VStack(spacing: 12) {
      Text("Map")
        .traceType(.displayLG)
        .foregroundStyle(TraceColor.textPrimary)
      Text("TRACE · Map feature")
        .traceType(.bodyMD)
        .foregroundStyle(TraceColor.char600)
    }
    .frame(maxWidth: .infinity, maxHeight: .infinity)
    .background(TraceColor.paper50)
  }
}
