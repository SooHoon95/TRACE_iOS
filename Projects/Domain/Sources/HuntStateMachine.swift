public enum HuntState: Equatable, Sendable {
    case approaching, revealable, revealed, captured, traceLeft
}

public enum HuntEvent: Equatable, Sendable {
    case distanceUpdated(Double)
    case revealTapped
    case captured
    case traceLeft
}

public struct HuntStateMachine: Sendable {
    public private(set) var state: HuntState = .approaching
    private let calc = WarmthCalculator()
    public init() {}

    public mutating func handle(_ event: HuntEvent) {
        switch (state, event) {
        case (.approaching, .distanceUpdated(let d)),
             (.revealable, .distanceUpdated(let d)):
            state = calc.canReveal(distanceMeters: d) ? .revealable : .approaching
        case (.revealable, .revealTapped):
            state = .revealed
        case (.revealed, .captured):
            state = .captured
        case (.captured, .traceLeft):
            state = .traceLeft
        default:
            break // 그 외 전이는 무시
        }
    }
}
