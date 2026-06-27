import SwiftUI
import Domain
import Home

@main
struct HomeSampleApp: App {
  var body: some Scene {
    WindowGroup {
      HomeView(store: Demo.store(), user: .demo)
    }
  }
}
