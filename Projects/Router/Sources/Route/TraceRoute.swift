import Foundation

/// The app's screen vocabulary — every push/present target in TRACE P0.
/// Mirrors Mercury's `FeatureRoute`: Router owns the route vocabulary; the concrete
/// `ViewFactory` (in TraceApp) maps each case to a Feature view. Payloads are value types only.
public enum TraceRoute: Hashable {
  // Tab roots
  case home
  case map
  case collection      // 도감
  case profile         // 나
  
  // Pushed details
  case exhibition(placeID: UUID)     // 장소 전시
  case momentDetail(momentID: UUID)  // 순간 상세
  case settings                      // 설정
  
  // Full-screen flows
  case leaveMoment(placeID: UUID?)   // 순간 남기기 (claim modal)
  case login
  case onboarding
}
