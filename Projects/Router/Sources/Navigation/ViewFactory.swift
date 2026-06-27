import SwiftUI
import Combine

/// Maps a `Route` to its screen. Ported from Mercury's Router.
///
/// `makeView` receives the coordinator's event stream so the produced view can drive further
/// navigation (`navigationStream.send(.push(...))`). The concrete factory lives in the
/// composition root (it imports every Feature module); Router stays feature-agnostic.
public protocol ViewFactory {
  associatedtype ScreenRoute: Hashable
  associatedtype ViewType: View
  
  @ViewBuilder
  func makeView(_ route: ScreenRoute,
                navigationStream: PassthroughSubject<NavigationEvent<ScreenRoute>, Never>) -> ViewType
}
