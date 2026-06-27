import SwiftUI

/// Navigation intents a coordinator can act on. Ported from Mercury's Router.
public enum NavigationEvent<Route: Hashable> {
  case push(Route)
  case pop
  case popTo(Route)
  case popToRoot
  case presentFullScreen(Route)
  case dismissFullScreen
}
