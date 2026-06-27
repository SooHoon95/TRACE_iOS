import SwiftUI
import Combine

/// Drives a stack-based navigation tree from `NavigationEvent`s. Ported from Mercury's Router.
///
/// Holds both a root `NavigationStack` path and a presented full-screen path, so a single
/// coordinator covers push/pop and modal full-screen flows. Views send events through
/// `eventSubject` (or call the convenience methods); the coordinator mutates the published stacks.
@MainActor
public final class NavigationCoordinator<Route: Hashable>: ObservableObject {
  
  @Published public var rootStack: [Route] = []
  @Published public var isFullScreenPresented: Bool = false
  @Published public var fullScreenRoute: Route? = nil
  @Published public var fullScreenStack: [Route] = []
  
  /// Public so child views (or a `ViewFactory`) can `send(...)` events without holding the whole coordinator.
  public let eventSubject = PassthroughSubject<NavigationEvent<Route>, Never>()
  private var cancellables = Set<AnyCancellable>()
  
  public init() {
    eventSubject
      .receive(on: DispatchQueue.main)
      .sink { [weak self] event in
        self?.handle(event: event)
      }
      .store(in: &cancellables)
  }
  
  // MARK: - Public Navigation API
  
  public func push(_ route: Route) { eventSubject.send(.push(route)) }
  public func pop() { eventSubject.send(.pop) }
  public func popToRoot() { eventSubject.send(.popToRoot) }
  public func popTo(_ route: Route) { eventSubject.send(.popTo(route)) }
  public func presentFullScreen(_ route: Route) { eventSubject.send(.presentFullScreen(route)) }
  public func dismissFullScreen() { eventSubject.send(.dismissFullScreen) }
  
  // MARK: - Internal
  
  private func handle(event: NavigationEvent<Route>) {
    switch event {
    case .push(let route):
      if isFullScreenPresented {
        fullScreenStack.append(route)
      } else {
        rootStack.append(route)
      }
      
    case .pop:
      if isFullScreenPresented {
        if !fullScreenStack.isEmpty {
          _ = fullScreenStack.popLast()
        } else {
          // 정책: 풀스크린 루트에서 pop이면 닫기
          isFullScreenPresented = false
          fullScreenRoute = nil
          fullScreenStack.removeAll()
        }
      } else {
        _ = rootStack.popLast()
      }
      
    case .popToRoot:
      if isFullScreenPresented {
        fullScreenStack.removeAll()
        isFullScreenPresented = false
        fullScreenRoute = nil
      }
      rootStack.removeAll()
      
    case .popTo(let route):
      if isFullScreenPresented {
        if let idx = fullScreenStack.lastIndex(of: route) {
          fullScreenStack = Array(fullScreenStack.prefix(idx + 1))
        }
      } else {
        if let idx = rootStack.lastIndex(of: route) {
          rootStack = Array(rootStack.prefix(idx + 1))
        }
      }
      
    case .presentFullScreen(let route):
      guard !isFullScreenPresented else { return }
      isFullScreenPresented = true
      fullScreenRoute = route
      fullScreenStack.removeAll()
      
    case .dismissFullScreen:
      guard isFullScreenPresented else { return }
      isFullScreenPresented = false
      fullScreenRoute = nil
      fullScreenStack.removeAll()
    }
  }
}
