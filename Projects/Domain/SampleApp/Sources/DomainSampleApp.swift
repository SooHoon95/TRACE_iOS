import SwiftUI
import Domain

@main
struct DomainSampleApp: App {
  var body: some Scene {
    WindowGroup {
      VStack {
        Text("Domain SampleApp \(TraceCore.version)")
      }
    }
  }
}
