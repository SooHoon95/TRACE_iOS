# AR 보물찾기 워킹 스켈레톤 (Plan 1/5) Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** 한 대의 iPhone에서 로컬(목) 데이터만으로 "지도 핀 → 따뜻/차가움 접근 → 카메라 AR 리몰 → 현장인증 획득 → 그 자리서 흔적 0초 남기기" 전체 코어 루프가 끝까지 동작한다.

**Architecture:** 순수 로직(거리/따뜻함 계산, 헌트 상태머신, 희귀도, 저장소)은 별도 Swift Package `TraceCore`로 분리해 `swift test`로 빠르게 TDD한다. ARKit/CoreLocation/카메라처럼 하드웨어 의존 셸은 `TraceHunt` iOS 앱에서 SwiftUI로 조립하고 시뮬레이터/실기기 수동검증한다. 백엔드 없음(in-memory 저장소) — 멀티유저는 Plan 2에서.

**Tech Stack:** Swift 5.9+, SwiftUI, ARKit(2D 빌보드), CoreLocation, MapKit, XCTest, Swift Package Manager.

## Global Constraints

- 최소 타깃: **iOS 16.0** (ARKit 평면감지·MapKit SwiftUI API 기준)
- 순수 로직은 **반드시 `TraceCore` 패키지 안**에 둔다. UIKit/SwiftUI/ARKit import 금지(테스트 가능성 유지).
- AR 표현은 **2D 빌보드만** (3D 공간앵커는 P2, 본 플랜 범위 밖).
- 리몰 잠금해제 반경: **15m** (`WarmthCalculator.revealRadiusMeters`).
- 흔적 스팟 스냅 반경: **20m** (이 안에 남기면 같은 스팟에 stack).
- 모든 타입은 `Sendable`, 모델은 `Codable` (Plan 2 백엔드 직렬화 대비).
- 좌표는 프로젝트 공용 `Coordinate`만 사용(코어에서 `CLLocationCoordinate2D` 직접 의존 금지).
- 커밋 메시지: Conventional Commits (`feat:`, `test:`, `chore:`).

---

### Task 0: 프로젝트 스캐폴딩 (TraceCore 패키지 + 앱 + git)

**Files:**
- Create: `TraceCore/Package.swift`
- Create: `TraceCore/Sources/TraceCore/TraceCore.swift` (빈 마커 파일)
- Create: `TraceCore/Tests/TraceCoreTests/SmokeTests.swift`
- Create: `.gitignore`

**Interfaces:**
- Consumes: 없음
- Produces: `TraceCore` 라이브러리 타깃 (이후 모든 로직 타스크가 여기에 파일 추가), `swift test` 실행 가능 상태

- [ ] **Step 1: git 저장소 초기화**

```bash
cd /Users/choesuhun/Desktop/Code/jeju-trip
git init
printf ".DS_Store\n.build/\nDerivedData/\nxcuserdata/\n*.xcuserstate\n" > .gitignore
```

- [ ] **Step 2: TraceCore 패키지 생성**

`TraceCore/Package.swift`:

```swift
// swift-tools-version:5.9
import PackageDescription

let package = Package(
    name: "TraceCore",
    platforms: [.iOS(.v16), .macOS(.v13)],
    products: [
        .library(name: "TraceCore", targets: ["TraceCore"]),
    ],
    targets: [
        .target(name: "TraceCore"),
        .testTarget(name: "TraceCoreTests", dependencies: ["TraceCore"]),
    ]
)
```

`TraceCore/Sources/TraceCore/TraceCore.swift`:

```swift
// TraceCore — 순수 도메인 로직. UIKit/SwiftUI/ARKit import 금지.
public enum TraceCore {
    public static let version = "0.1.0"
}
```

- [ ] **Step 3: 스모크 테스트 작성**

`TraceCore/Tests/TraceCoreTests/SmokeTests.swift`:

```swift
import XCTest
@testable import TraceCore

final class SmokeTests: XCTestCase {
    func testVersionExists() {
        XCTAssertEqual(TraceCore.version, "0.1.0")
    }
}
```

- [ ] **Step 4: 테스트 실행해 통과 확인**

Run: `cd TraceCore && swift test`
Expected: PASS — `Test Suite 'SmokeTests' passed`, 1 test 통과

- [ ] **Step 5: 커밋**

```bash
cd /Users/choesuhun/Desktop/Code/jeju-trip
git add .gitignore TraceCore
git commit -m "chore: scaffold TraceCore swift package + git"
```

---

### Task 1: 도메인 모델 (Coordinate, VibeTag, Trace, Spot)

**Files:**
- Create: `TraceCore/Sources/TraceCore/Coordinate.swift`
- Create: `TraceCore/Sources/TraceCore/VibeTag.swift`
- Create: `TraceCore/Sources/TraceCore/Trace.swift`
- Create: `TraceCore/Sources/TraceCore/Spot.swift`
- Test: `TraceCore/Tests/TraceCoreTests/ModelTests.swift`

**Interfaces:**
- Consumes: 없음
- Produces:
  - `Coordinate(latitude: Double, longitude: Double)` — Equatable/Codable/Sendable
  - `VibeTag` enum: `.calm .lively .scenic .foodie .adventure .hidden`
  - `Trace(id: UUID, creatorID: UUID, photoRef: String, note: String, vibe: VibeTag, coordinate: Coordinate, createdAt: Date, collectCount: Int)` — `collectCount`는 `private(set)`, `mutating func incrementCollect()`
  - `Spot(id: UUID, coordinate: Coordinate, traces: [Trace])` — 계산속성 `heat: Int { traces.count }`

- [ ] **Step 1: 실패하는 테스트 작성**

`TraceCore/Tests/TraceCoreTests/ModelTests.swift`:

```swift
import XCTest
@testable import TraceCore

final class ModelTests: XCTestCase {
    func testTraceCollectCountIncrements() {
        var t = Trace(id: UUID(), creatorID: UUID(), photoRef: "p.jpg",
                      note: "야경 미쳤음", vibe: .scenic,
                      coordinate: Coordinate(latitude: 33.45, longitude: 126.56),
                      createdAt: Date(timeIntervalSince1970: 0), collectCount: 0)
        t.incrementCollect()
        t.incrementCollect()
        XCTAssertEqual(t.collectCount, 2)
    }

    func testSpotHeatEqualsTraceCount() {
        let c = Coordinate(latitude: 33.45, longitude: 126.56)
        let spot = Spot(id: UUID(), coordinate: c, traces: [
            sampleTrace(at: c), sampleTrace(at: c), sampleTrace(at: c)
        ])
        XCTAssertEqual(spot.heat, 3)
    }

    func testCoordinateCodableRoundTrip() throws {
        let c = Coordinate(latitude: 33.45, longitude: 126.56)
        let data = try JSONEncoder().encode(c)
        let decoded = try JSONDecoder().decode(Coordinate.self, from: data)
        XCTAssertEqual(c, decoded)
    }

    private func sampleTrace(at c: Coordinate) -> Trace {
        Trace(id: UUID(), creatorID: UUID(), photoRef: "p.jpg", note: "",
              vibe: .calm, coordinate: c, createdAt: Date(timeIntervalSince1970: 0),
              collectCount: 0)
    }
}
```

- [ ] **Step 2: 테스트 실행해 실패 확인**

Run: `cd TraceCore && swift test --filter ModelTests`
Expected: FAIL — `cannot find 'Trace' in scope` 등 컴파일 에러

- [ ] **Step 3: 모델 구현**

`Coordinate.swift`:

```swift
import Foundation

public struct Coordinate: Equatable, Codable, Sendable {
    public let latitude: Double
    public let longitude: Double
    public init(latitude: Double, longitude: Double) {
        self.latitude = latitude
        self.longitude = longitude
    }
}
```

`VibeTag.swift`:

```swift
public enum VibeTag: String, CaseIterable, Codable, Sendable {
    case calm, lively, scenic, foodie, adventure, hidden
}
```

`Trace.swift`:

```swift
import Foundation

public struct Trace: Identifiable, Equatable, Codable, Sendable {
    public let id: UUID
    public let creatorID: UUID
    public let photoRef: String
    public let note: String
    public let vibe: VibeTag
    public let coordinate: Coordinate
    public let createdAt: Date
    public private(set) var collectCount: Int

    public init(id: UUID, creatorID: UUID, photoRef: String, note: String,
                vibe: VibeTag, coordinate: Coordinate, createdAt: Date,
                collectCount: Int) {
        self.id = id; self.creatorID = creatorID; self.photoRef = photoRef
        self.note = note; self.vibe = vibe; self.coordinate = coordinate
        self.createdAt = createdAt; self.collectCount = collectCount
    }

    public mutating func incrementCollect() { collectCount += 1 }
}
```

`Spot.swift`:

```swift
import Foundation

public struct Spot: Identifiable, Equatable, Sendable {
    public let id: UUID
    public let coordinate: Coordinate
    public var traces: [Trace]
    public var heat: Int { traces.count }

    public init(id: UUID, coordinate: Coordinate, traces: [Trace]) {
        self.id = id; self.coordinate = coordinate; self.traces = traces
    }
}
```

- [ ] **Step 4: 테스트 실행해 통과 확인**

Run: `cd TraceCore && swift test --filter ModelTests`
Expected: PASS — 3 tests 통과

- [ ] **Step 5: 커밋**

```bash
git add TraceCore/Sources/TraceCore TraceCore/Tests
git commit -m "feat: add core domain models (Coordinate, VibeTag, Trace, Spot)"
```

---

### Task 2: WarmthCalculator (거리 → 따뜻/차가움 + 리몰 게이트)

**Files:**
- Create: `TraceCore/Sources/TraceCore/WarmthCalculator.swift`
- Test: `TraceCore/Tests/TraceCoreTests/WarmthCalculatorTests.swift`

**Interfaces:**
- Consumes: `Coordinate` (Task 1)
- Produces:
  - `enum Warmth: Int { case cold, cool, warm, hot }`
  - `WarmthCalculator()` with: `distanceMeters(from: Coordinate, to: Coordinate) -> Double`, `warmth(distanceMeters: Double) -> Warmth`, `canReveal(distanceMeters: Double) -> Bool`, `static let revealRadiusMeters: Double = 15`

- [ ] **Step 1: 실패하는 테스트 작성**

`TraceCore/Tests/TraceCoreTests/WarmthCalculatorTests.swift`:

```swift
import XCTest
@testable import TraceCore

final class WarmthCalculatorTests: XCTestCase {
    let calc = WarmthCalculator()

    func testWarmthBuckets() {
        XCTAssertEqual(calc.warmth(distanceMeters: 800), .cold)
        XCTAssertEqual(calc.warmth(distanceMeters: 300), .cool)
        XCTAssertEqual(calc.warmth(distanceMeters: 50), .warm)
        XCTAssertEqual(calc.warmth(distanceMeters: 5), .hot)
    }

    func testRevealGateAt15Meters() {
        XCTAssertFalse(calc.canReveal(distanceMeters: 15.0)) // 경계 미포함
        XCTAssertTrue(calc.canReveal(distanceMeters: 14.9))
    }

    func testHaversineKnownDistance() {
        // 약 111m 떨어진 두 점 (위도 0.001도 ≈ 111m)
        let a = Coordinate(latitude: 33.4500, longitude: 126.5600)
        let b = Coordinate(latitude: 33.4510, longitude: 126.5600)
        let d = calc.distanceMeters(from: a, to: b)
        XCTAssertEqual(d, 111, accuracy: 2)
    }
}
```

- [ ] **Step 2: 테스트 실행해 실패 확인**

Run: `cd TraceCore && swift test --filter WarmthCalculatorTests`
Expected: FAIL — `cannot find 'WarmthCalculator' in scope`

- [ ] **Step 3: 구현**

`WarmthCalculator.swift`:

```swift
import Foundation

public enum Warmth: Int, Equatable, Sendable {
    case cold, cool, warm, hot
}

public struct WarmthCalculator: Sendable {
    public static let revealRadiusMeters: Double = 15
    public init() {}

    public func distanceMeters(from: Coordinate, to: Coordinate) -> Double {
        let r = 6_371_000.0
        let dLat = (to.latitude - from.latitude) * .pi / 180
        let dLon = (to.longitude - from.longitude) * .pi / 180
        let lat1 = from.latitude * .pi / 180
        let lat2 = to.latitude * .pi / 180
        let a = sin(dLat/2) * sin(dLat/2)
              + cos(lat1) * cos(lat2) * sin(dLon/2) * sin(dLon/2)
        return r * 2 * atan2(sqrt(a), sqrt(1 - a))
    }

    public func warmth(distanceMeters d: Double) -> Warmth {
        switch d {
        case ..<15: return .hot
        case ..<100: return .warm
        case ..<500: return .cool
        default: return .cold
        }
    }

    public func canReveal(distanceMeters d: Double) -> Bool {
        d < Self.revealRadiusMeters
    }
}
```

- [ ] **Step 4: 테스트 실행해 통과 확인**

Run: `cd TraceCore && swift test --filter WarmthCalculatorTests`
Expected: PASS — 3 tests 통과

- [ ] **Step 5: 커밋**

```bash
git add TraceCore/Sources/TraceCore/WarmthCalculator.swift TraceCore/Tests/TraceCoreTests/WarmthCalculatorTests.swift
git commit -m "feat: add WarmthCalculator (haversine + warmth buckets + reveal gate)"
```

---

### Task 3: HuntStateMachine (헌트 동선 상태 전이)

**Files:**
- Create: `TraceCore/Sources/TraceCore/HuntStateMachine.swift`
- Test: `TraceCore/Tests/TraceCoreTests/HuntStateMachineTests.swift`

**Interfaces:**
- Consumes: `WarmthCalculator` (Task 2)
- Produces:
  - `enum HuntState { case approaching, revealable, revealed, captured, traceLeft }`
  - `enum HuntEvent { case distanceUpdated(Double), revealTapped, captured, traceLeft }`
  - `HuntStateMachine()` with `var state: HuntState` (`private(set)`, 초기 `.approaching`) + `mutating func handle(_ event: HuntEvent)`

- [ ] **Step 1: 실패하는 테스트 작성**

`TraceCore/Tests/TraceCoreTests/HuntStateMachineTests.swift`:

```swift
import XCTest
@testable import TraceCore

final class HuntStateMachineTests: XCTestCase {
    func testStartsApproaching() {
        XCTAssertEqual(HuntStateMachine().state, .approaching)
    }

    func testFarKeepsApproaching_NearUnlocksReveal() {
        var m = HuntStateMachine()
        m.handle(.distanceUpdated(50))
        XCTAssertEqual(m.state, .approaching)
        m.handle(.distanceUpdated(10))
        XCTAssertEqual(m.state, .revealable)
    }

    func testMovingAwayRelocksReveal() {
        var m = HuntStateMachine()
        m.handle(.distanceUpdated(10))
        XCTAssertEqual(m.state, .revealable)
        m.handle(.distanceUpdated(80))
        XCTAssertEqual(m.state, .approaching)
    }

    func testRevealTapIgnoredWhenNotRevealable() {
        var m = HuntStateMachine()
        m.handle(.revealTapped)
        XCTAssertEqual(m.state, .approaching)
    }

    func testHappyPathToTraceLeft() {
        var m = HuntStateMachine()
        m.handle(.distanceUpdated(8))
        m.handle(.revealTapped)
        XCTAssertEqual(m.state, .revealed)
        m.handle(.captured)
        XCTAssertEqual(m.state, .captured)
        m.handle(.traceLeft)
        XCTAssertEqual(m.state, .traceLeft)
    }
}
```

- [ ] **Step 2: 테스트 실행해 실패 확인**

Run: `cd TraceCore && swift test --filter HuntStateMachineTests`
Expected: FAIL — `cannot find 'HuntStateMachine' in scope`

- [ ] **Step 3: 구현**

`HuntStateMachine.swift`:

```swift
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
```

- [ ] **Step 4: 테스트 실행해 통과 확인**

Run: `cd TraceCore && swift test --filter HuntStateMachineTests`
Expected: PASS — 5 tests 통과

- [ ] **Step 5: 커밋**

```bash
git add TraceCore/Sources/TraceCore/HuntStateMachine.swift TraceCore/Tests/TraceCoreTests/HuntStateMachineTests.swift
git commit -m "feat: add HuntStateMachine (approach->reveal->capture->leave)"
```

---

### Task 4: Rarity (희귀도 — 100명 중 N명)

**Files:**
- Create: `TraceCore/Sources/TraceCore/Rarity.swift`
- Test: `TraceCore/Tests/TraceCoreTests/RarityTests.swift`

**Interfaces:**
- Consumes: 없음
- Produces:
  - `enum RarityTier: String { case common, uncommon, rare, legendary }`
  - `Rarity()` with `ownershipPercent(owners: Int, population: Int) -> Int`, `tier(owners: Int, population: Int) -> RarityTier`

- [ ] **Step 1: 실패하는 테스트 작성**

`TraceCore/Tests/TraceCoreTests/RarityTests.swift`:

```swift
import XCTest
@testable import TraceCore

final class RarityTests: XCTestCase {
    let r = Rarity()

    func testOwnershipPercentRounds() {
        XCTAssertEqual(r.ownershipPercent(owners: 3, population: 100), 3)
        XCTAssertEqual(r.ownershipPercent(owners: 1, population: 3), 33)
    }

    func testZeroPopulationIsSafe() {
        XCTAssertEqual(r.ownershipPercent(owners: 5, population: 0), 0)
    }

    func testTiers() {
        XCTAssertEqual(r.tier(owners: 1, population: 100), .legendary) // 1%
        XCTAssertEqual(r.tier(owners: 3, population: 100), .rare)      // 3%
        XCTAssertEqual(r.tier(owners: 20, population: 100), .uncommon) // 20%
        XCTAssertEqual(r.tier(owners: 60, population: 100), .common)   // 60%
    }
}
```

- [ ] **Step 2: 테스트 실행해 실패 확인**

Run: `cd TraceCore && swift test --filter RarityTests`
Expected: FAIL — `cannot find 'Rarity' in scope`

- [ ] **Step 3: 구현**

`Rarity.swift`:

```swift
import Foundation

public enum RarityTier: String, Equatable, Sendable {
    case common, uncommon, rare, legendary
}

public struct Rarity: Sendable {
    public init() {}

    public func ownershipPercent(owners: Int, population: Int) -> Int {
        guard population > 0 else { return 0 }
        return Int((Double(owners) / Double(population) * 100).rounded())
    }

    public func tier(owners: Int, population: Int) -> RarityTier {
        switch ownershipPercent(owners: owners, population: population) {
        case ..<2: return .legendary
        case ..<10: return .rare
        case ..<33: return .uncommon
        default: return .common
        }
    }
}
```

- [ ] **Step 4: 테스트 실행해 통과 확인**

Run: `cd TraceCore && swift test --filter RarityTests`
Expected: PASS — 3 tests 통과

- [ ] **Step 5: 커밋**

```bash
git add TraceCore/Sources/TraceCore/Rarity.swift TraceCore/Tests/TraceCoreTests/RarityTests.swift
git commit -m "feat: add Rarity (ownership percent + tiers)"
```

---

### Task 5: TraceRepository + InMemory 구현 (스팟 스택·heat·수집)

**Files:**
- Create: `TraceCore/Sources/TraceCore/TraceRepository.swift`
- Create: `TraceCore/Sources/TraceCore/InMemoryTraceRepository.swift`
- Test: `TraceCore/Tests/TraceCoreTests/InMemoryTraceRepositoryTests.swift`

**Interfaces:**
- Consumes: `Coordinate`, `Trace`, `Spot` (Task 1), `WarmthCalculator` (Task 2)
- Produces:
  - `protocol TraceRepository`: `func spots() -> [Spot]`; `func nearbySpots(to: Coordinate, withinMeters: Double) -> [Spot]`; `func leaveTrace(_ trace: Trace)`; `func collect(traceID: UUID, by userID: UUID)`; `func collected(by userID: UUID) -> [Trace]`
  - `final class InMemoryTraceRepository: TraceRepository` — `init(seed: [Trace] = [])`; 스냅 반경 상수 `snapRadiusMeters = 20`

- [ ] **Step 1: 실패하는 테스트 작성**

`TraceCore/Tests/TraceCoreTests/InMemoryTraceRepositoryTests.swift`:

```swift
import XCTest
@testable import TraceCore

final class InMemoryTraceRepositoryTests: XCTestCase {
    let here = Coordinate(latitude: 33.4500, longitude: 126.5600)

    func makeTrace(at c: Coordinate, creator: UUID = UUID()) -> Trace {
        Trace(id: UUID(), creatorID: creator, photoRef: "p.jpg", note: "",
              vibe: .calm, coordinate: c, createdAt: Date(timeIntervalSince1970: 0),
              collectCount: 0)
    }

    func testTwoNearbyTracesStackIntoOneSpot() {
        let repo = InMemoryTraceRepository()
        repo.leaveTrace(makeTrace(at: here))
        // ~11m 떨어진 위치(스냅 반경 20m 이내) → 같은 스팟
        repo.leaveTrace(makeTrace(at: Coordinate(latitude: 33.4501, longitude: 126.5600)))
        XCTAssertEqual(repo.spots().count, 1)
        XCTAssertEqual(repo.spots().first?.heat, 2)
    }

    func testFarTraceMakesNewSpot() {
        let repo = InMemoryTraceRepository()
        repo.leaveTrace(makeTrace(at: here))
        // ~111m 떨어진 위치 → 별도 스팟
        repo.leaveTrace(makeTrace(at: Coordinate(latitude: 33.4510, longitude: 126.5600)))
        XCTAssertEqual(repo.spots().count, 2)
    }

    func testNearbySpotsFiltersByDistance() {
        let repo = InMemoryTraceRepository()
        repo.leaveTrace(makeTrace(at: here))
        repo.leaveTrace(makeTrace(at: Coordinate(latitude: 33.5000, longitude: 126.5600)))
        let near = repo.nearbySpots(to: here, withinMeters: 100)
        XCTAssertEqual(near.count, 1)
    }

    func testCollectIncrementsCountAndRecordsOwnership() {
        let repo = InMemoryTraceRepository()
        let t = makeTrace(at: here)
        repo.leaveTrace(t)
        let user = UUID()
        repo.collect(traceID: t.id, by: user)
        XCTAssertEqual(repo.collected(by: user).count, 1)
        XCTAssertEqual(repo.spots().first?.traces.first?.collectCount, 1)
    }
}
```

- [ ] **Step 2: 테스트 실행해 실패 확인**

Run: `cd TraceCore && swift test --filter InMemoryTraceRepositoryTests`
Expected: FAIL — `cannot find 'InMemoryTraceRepository' in scope`

- [ ] **Step 3: 구현**

`TraceRepository.swift`:

```swift
import Foundation

public protocol TraceRepository: AnyObject {
    func spots() -> [Spot]
    func nearbySpots(to coordinate: Coordinate, withinMeters: Double) -> [Spot]
    func leaveTrace(_ trace: Trace)
    func collect(traceID: UUID, by userID: UUID)
    func collected(by userID: UUID) -> [Trace]
}
```

`InMemoryTraceRepository.swift`:

```swift
import Foundation

public final class InMemoryTraceRepository: TraceRepository {
    public let snapRadiusMeters: Double = 20
    private let calc = WarmthCalculator()
    private var store: [Spot] = []
    private var ownership: [UUID: Set<UUID>] = [:] // userID -> traceIDs

    public init(seed: [Trace] = []) {
        for t in seed { leaveTrace(t) }
    }

    public func spots() -> [Spot] { store }

    public func nearbySpots(to coordinate: Coordinate, withinMeters: Double) -> [Spot] {
        store.filter {
            calc.distanceMeters(from: coordinate, to: $0.coordinate) <= withinMeters
        }
    }

    public func leaveTrace(_ trace: Trace) {
        if let idx = store.firstIndex(where: {
            calc.distanceMeters(from: $0.coordinate, to: trace.coordinate) <= snapRadiusMeters
        }) {
            store[idx].traces.append(trace)
        } else {
            store.append(Spot(id: UUID(), coordinate: trace.coordinate, traces: [trace]))
        }
    }

    public func collect(traceID: UUID, by userID: UUID) {
        for s in store.indices {
            if let t = store[s].traces.firstIndex(where: { $0.id == traceID }) {
                store[s].traces[t].incrementCollect()
                ownership[userID, default: []].insert(traceID)
                return
            }
        }
    }

    public func collected(by userID: UUID) -> [Trace] {
        let ids = ownership[userID] ?? []
        return store.flatMap { $0.traces }.filter { ids.contains($0.id) }
    }
}
```

- [ ] **Step 4: 테스트 실행해 통과 확인**

Run: `cd TraceCore && swift test --filter InMemoryTraceRepositoryTests`
Expected: PASS — 4 tests 통과

- [ ] **Step 5: 전체 코어 테스트 + 커밋**

```bash
cd TraceCore && swift test
# Expected: 모든 테스트 PASS (Model 3 + Warmth 3 + Hunt 5 + Rarity 3 + Repo 4 + Smoke 1)
git add TraceCore/Sources/TraceCore TraceCore/Tests
git commit -m "feat: add TraceRepository + in-memory impl (spot stacking, heat, collect)"
```

---

### Task 6: iOS 앱 셸 + 시드 데이터 + 지도 (수동검증)

> 여기부터는 하드웨어/UI 의존이라 단위테스트 대신 시뮬레이터 수동검증을 쓴다. 빌드 성공 + 명시된 화면 동작이 통과 기준.

**Files:**
- Create: Xcode iOS App 프로젝트 `TraceHunt` (Interface: SwiftUI, min iOS 16, TraceCore 로컬 패키지 의존)
- Create: `TraceHunt/Shared/MockData.swift`
- Create: `TraceHunt/Features/Map/MapViewModel.swift`
- Create: `TraceHunt/Features/Map/MapView.swift`
- Modify: `TraceHunt/TraceHuntApp.swift`

**Interfaces:**
- Consumes: `InMemoryTraceRepository`, `Spot`, `Coordinate` (TraceCore)
- Produces: `MapViewModel(repo: TraceRepository)` with `@Published var spots: [Spot]`, `func refresh()`; 앱 진입점이 `MapView`를 띄움

- [ ] **Step 1: Xcode 프로젝트 생성 + TraceCore 의존 연결**

Xcode → New Project → iOS App, Product Name `TraceHunt`, Interface SwiftUI, 저장 위치 `/Users/choesuhun/Desktop/Code/jeju-trip/`. 그다음 File → Add Package Dependencies → Add Local → `TraceCore` 폴더 선택 → `TraceHunt` 타깃에 `TraceCore` 라이브러리 추가.

- [ ] **Step 2: 시드 목 데이터 작성**

`TraceHunt/Shared/MockData.swift`:

```swift
import Foundation
import TraceCore

enum MockData {
    // 제주시청 인근 가짜 좌표들 (시뮬레이터 커스텀 위치와 맞춰 테스트)
    static let base = Coordinate(latitude: 33.4996, longitude: 126.5312)

    static func repository() -> InMemoryTraceRepository {
        let creator = UUID()
        let seed = [
            Trace(id: UUID(), creatorID: creator, photoRef: "seed1", note: "여기 커피 굿",
                  vibe: .foodie, coordinate: base, createdAt: Date(), collectCount: 4),
            Trace(id: UUID(), creatorID: creator, photoRef: "seed2", note: "노을 명당",
                  vibe: .scenic,
                  coordinate: Coordinate(latitude: 33.5006, longitude: 126.5312),
                  createdAt: Date(), collectCount: 1),
        ]
        return InMemoryTraceRepository(seed: seed)
    }
}
```

- [ ] **Step 3: MapViewModel 작성**

`TraceHunt/Features/Map/MapViewModel.swift`:

```swift
import Foundation
import TraceCore

@MainActor
final class MapViewModel: ObservableObject {
    @Published private(set) var spots: [Spot] = []
    let repo: TraceRepository

    init(repo: TraceRepository) {
        self.repo = repo
        refresh()
    }

    func refresh() { spots = repo.spots() }
}
```

- [ ] **Step 4: MapView 작성 (핀 + heat 라벨)**

`TraceHunt/Features/Map/MapView.swift`:

```swift
import SwiftUI
import MapKit
import TraceCore

struct MapView: View {
    @StateObject var vm: MapViewModel
    @State private var region = MKCoordinateRegion(
        center: CLLocationCoordinate2D(latitude: MockData.base.latitude,
                                       longitude: MockData.base.longitude),
        span: MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01))

    var body: some View {
        Map(coordinateRegion: $region, annotationItems: vm.spots) { spot in
            MapAnnotation(coordinate: CLLocationCoordinate2D(
                latitude: spot.coordinate.latitude,
                longitude: spot.coordinate.longitude)) {
                VStack(spacing: 2) {
                    Image(systemName: "mappin.circle.fill")
                        .font(.system(size: 28 + CGFloat(min(spot.heat, 5)) * 4))
                        .foregroundStyle(.orange)
                    Text("\(spot.heat)").font(.caption2).bold()
                }
            }
        }
        .ignoresSafeArea()
        .onAppear { vm.refresh() }
    }
}
```

`TraceHunt/TraceHuntApp.swift`:

```swift
import SwiftUI

@main
struct TraceHuntApp: App {
    @StateObject private var mapVM = MapViewModel(repo: MockData.repository())
    var body: some Scene {
        WindowGroup { MapView(vm: mapVM) }
    }
}
```

- [ ] **Step 5: 빌드 + 수동검증 + 커밋**

Run: `xcodebuild -scheme TraceHunt -destination 'platform=iOS Simulator,name=iPhone 15' build`
Expected: `BUILD SUCCEEDED`
수동검증: 시뮬레이터 실행 → 제주 지도에 핀 2개, heat 라벨(`4` 위치 핀이 더 큼) 보임.

```bash
git add TraceHunt
git commit -m "feat: app shell + map with seeded spots (heat-scaled pins)"
```

---

### Task 7: 따뜻/차가움 헌트 화면 (위치 → 상태머신 연동, 수동검증)

**Files:**
- Create: `TraceHunt/Features/Hunt/LocationProvider.swift`
- Create: `TraceHunt/Features/Hunt/HuntViewModel.swift`
- Create: `TraceHunt/Features/Hunt/WarmthView.swift`
- Modify: `TraceHunt/Features/Map/MapView.swift` (핀 탭 → 헌트 화면 push)
- Modify: `TraceHunt/Info.plist` (위치 권한 문구)

**Interfaces:**
- Consumes: `WarmthCalculator`, `HuntStateMachine`, `Warmth`, `Coordinate`, `Spot` (TraceCore)
- Produces: `HuntViewModel(target: Spot)` with `@Published var warmth: Warmth`, `@Published var state: HuntState`, `@Published var distance: Double`, `func update(userLocation: Coordinate)`, `func tapReveal()`; `LocationProvider` (`@Published var coordinate: Coordinate?`)

- [ ] **Step 1: 위치 권한 문구 추가**

`TraceHunt/Info.plist`에 키 추가: `NSLocationWhenInUseUsageDescription` = `보물 위치까지 거리(따뜻/차가움)를 알려주려면 위치가 필요해요.`

- [ ] **Step 2: LocationProvider 작성**

`TraceHunt/Features/Hunt/LocationProvider.swift`:

```swift
import Foundation
import CoreLocation
import TraceCore

@MainActor
final class LocationProvider: NSObject, ObservableObject, CLLocationManagerDelegate {
    @Published var coordinate: Coordinate?
    private let manager = CLLocationManager()

    override init() {
        super.init()
        manager.delegate = self
        manager.desiredAccuracy = kCLLocationAccuracyBest
    }
    func start() {
        manager.requestWhenInUseAuthorization()
        manager.startUpdatingLocation()
    }
    nonisolated func locationManager(_ m: CLLocationManager, didUpdateLocations locs: [CLLocation]) {
        guard let l = locs.last else { return }
        Task { @MainActor in
            coordinate = Coordinate(latitude: l.coordinate.latitude,
                                    longitude: l.coordinate.longitude)
        }
    }
}
```

- [ ] **Step 3: HuntViewModel 작성 (코어 로직 연결)**

`TraceHunt/Features/Hunt/HuntViewModel.swift`:

```swift
import Foundation
import TraceCore

@MainActor
final class HuntViewModel: ObservableObject {
    @Published private(set) var warmth: Warmth = .cold
    @Published private(set) var distance: Double = .infinity
    @Published private(set) var state: HuntState = .approaching

    let target: Spot
    private let calc = WarmthCalculator()
    private var machine = HuntStateMachine()

    init(target: Spot) { self.target = target }

    func update(userLocation: Coordinate) {
        distance = calc.distanceMeters(from: userLocation, to: target.coordinate)
        warmth = calc.warmth(distanceMeters: distance)
        machine.handle(.distanceUpdated(distance))
        state = machine.state
    }
    func tapReveal() { machine.handle(.revealTapped); state = machine.state }
    var canReveal: Bool { state == .revealable }
}
```

- [ ] **Step 4: WarmthView 작성**

`TraceHunt/Features/Hunt/WarmthView.swift`:

```swift
import SwiftUI
import TraceCore

struct WarmthView: View {
    @StateObject var vm: HuntViewModel
    @StateObject private var loc = LocationProvider()
    var onReveal: () -> Void

    private var label: String {
        switch vm.warmth {
        case .cold: return "❄️ 차가워요"
        case .cool: return "🌥️ 미지근"
        case .warm: return "🔥 따뜻해요"
        case .hot: return "🌋 바로 여기!"
        }
    }
    var body: some View {
        VStack(spacing: 24) {
            Text(label).font(.largeTitle).bold()
            Text(vm.distance.isFinite ? "\(Int(vm.distance))m" : "—").foregroundStyle(.secondary)
            Button("📷 보물 꺼내기") { vm.tapReveal(); onReveal() }
                .buttonStyle(.borderedProminent)
                .disabled(!vm.canReveal)
        }
        .padding()
        .onAppear { loc.start() }
        .onReceive(loc.$coordinate.compactMap { $0 }) { vm.update(userLocation: $0) }
    }
}
```

- [ ] **Step 5: 지도 핀 → 헌트 화면 연결 + 빌드 + 수동검증 + 커밋**

`MapView.swift`의 핀에 `NavigationLink`/`.sheet`로 탭 시 `WarmthView(vm: HuntViewModel(target: spot))` 띄우기 (앱 루트를 `NavigationStack`으로 감싼다).

Run: `xcodebuild -scheme TraceHunt -destination 'platform=iOS Simulator,name=iPhone 15' build`
Expected: `BUILD SUCCEEDED`
수동검증: 시뮬레이터 Features → Location → Custom Location을 타깃 핀 근처(33.4996/126.5312)로 설정 → 핀 탭 → "🌋 바로 여기!" + "📷 보물 꺼내기" 활성화. 위치를 멀리(33.6/126.5) 주면 "❄️ 차가워요" + 버튼 비활성.

```bash
git add TraceHunt
git commit -m "feat: warmth hunt screen wired to location + HuntStateMachine"
```

---

### Task 8: AR 리몰 (2D 빌보드, 수동검증)

**Files:**
- Create: `TraceHunt/Features/Reveal/ARRevealView.swift`
- Modify: `TraceHunt/Features/Hunt/WarmthView.swift` (`onReveal` → ARRevealView 풀스크린)
- Modify: `TraceHunt/Info.plist` (카메라 권한 문구)

**Interfaces:**
- Consumes: `Spot` (보여줄 스택된 흔적들), `Trace`
- Produces: `ARRevealView(spot: Spot, onCaptured: () -> Void)`

- [ ] **Step 1: 카메라 권한 문구 추가**

`Info.plist`: `NSCameraUsageDescription` = `보물을 AR로 보고 현장 인증 사진을 찍으려면 카메라가 필요해요.`

- [ ] **Step 2: ARRevealView 작성 (ARKit + 2D 빌보드)**

`TraceHunt/Features/Reveal/ARRevealView.swift`:

```swift
import SwiftUI
import ARKit
import SceneKit
import TraceCore

struct ARRevealView: UIViewRepresentable {
    let spot: Spot
    func makeUIView(context: Context) -> ARSCNView {
        let view = ARSCNView()
        let config = ARWorldTrackingConfiguration()
        config.planeDetection = [.horizontal]
        view.session.run(config)
        // 스택된 흔적 수만큼 2D 빌보드(텍스트 플레인)를 카메라 앞 반원에 배치
        for (i, trace) in spot.traces.enumerated() {
            let plane = SCNPlane(width: 0.18, height: 0.12)
            plane.firstMaterial?.diffuse.contents = UIColor.systemOrange
            plane.firstMaterial?.isDoubleSided = true
            let node = SCNNode(geometry: plane)
            let angle = Float(i) * 0.5 - Float(spot.traces.count - 1) * 0.25
            node.position = SCNVector3(sin(angle) * 0.4, 0, -0.6 - cos(angle) * 0.1)
            node.constraints = [SCNBillboardConstraint()] // 항상 카메라 향함
            let text = SCNText(string: trace.note.isEmpty ? "✨흔적" : trace.note, extrusionDepth: 0)
            text.font = .systemFont(ofSize: 6)
            let t = SCNNode(geometry: text); t.scale = SCNVector3(0.01, 0.01, 0.01)
            t.position = SCNVector3(-0.07, -0.02, 0.01)
            node.addChildNode(t)
            view.scene.rootNode.addChildNode(node)
        }
        return view
    }
    func updateUIView(_ uiView: ARSCNView, context: Context) {}
}

struct RevealScreen: View {
    let spot: Spot
    var onCaptured: () -> Void
    var body: some View {
        ZStack(alignment: .bottom) {
            ARRevealView(spot: spot).ignoresSafeArea()
            Button("📸 현장 인증하고 획득") { onCaptured() }
                .buttonStyle(.borderedProminent).padding(.bottom, 40)
        }
    }
}
```

- [ ] **Step 3: WarmthView에서 리몰 연결**

`WarmthView`의 `onReveal`을 `.fullScreenCover`로 `RevealScreen(spot: vm.target)` 띄우도록 수정.

- [ ] **Step 4: 빌드 + 실기기 수동검증**

> ⚠️ ARKit은 시뮬레이터에서 카메라가 안 돌아간다. **실기기 필수.**

Run: `xcodebuild -scheme TraceHunt -destination 'generic/platform=iOS' build`
Expected: `BUILD SUCCEEDED`
수동검증(실기기): 헌트 화면에서 "보물 꺼내기" → 카메라 뷰에 주황 빌보드(흔적 노트 텍스트)가 공중에 떠 보이고, 폰을 돌려도 항상 정면을 향함(billboard).

- [ ] **Step 5: 커밋**

```bash
git add TraceHunt
git commit -m "feat: AR reveal with 2D billboards for stacked traces"
```

---

### Task 9: 현장 인증 캡처 → 도감 획득 (수동검증)

**Files:**
- Create: `TraceHunt/Features/Capture/CaptureService.swift`
- Modify: `TraceHunt/Features/Reveal/ARRevealView.swift` (`onCaptured`에서 스냅샷 + repo.collect)
- Create: `TraceHunt/Features/Collection/CollectionView.swift`
- Modify: `TraceHunt/TraceHuntApp.swift` (탭 or 도감 진입)

**Interfaces:**
- Consumes: `TraceRepository.collect(traceID:by:)`, `collected(by:)`, `ARSCNView.snapshot()`
- Produces: `CaptureService.saveSnapshot(_ image: UIImage) -> String` (로컬 파일 경로 반환); `CollectionView(repo:userID:)`

- [ ] **Step 1: CaptureService 작성 (스냅샷 로컬 저장)**

`TraceHunt/Features/Capture/CaptureService.swift`:

```swift
import UIKit

enum CaptureService {
    static func saveSnapshot(_ image: UIImage) -> String {
        let name = UUID().uuidString + ".jpg"
        let url = FileManager.default.temporaryDirectory.appendingPathComponent(name)
        if let data = image.jpegData(compressionQuality: 0.6) { try? data.write(to: url) }
        return url.path
    }
}
```

- [ ] **Step 2: 리몰 화면 캡처 → 획득 연결**

`RevealScreen`에서 "현장 인증하고 획득" 탭 시: `ARSCNView.snapshot()` → `CaptureService.saveSnapshot` → `repo.collect(traceID: spot.traces.first!.id, by: currentUserID)` 호출 후 `onCaptured()`로 화면 닫고 토스트. (repo·userID는 상위에서 주입.)

- [ ] **Step 3: CollectionView(도감) 작성**

`TraceHunt/Features/Collection/CollectionView.swift`:

```swift
import SwiftUI
import TraceCore

struct CollectionView: View {
    let repo: TraceRepository
    let userID: UUID
    @State private var items: [Trace] = []
    var body: some View {
        List(items) { t in
            HStack {
                Text(t.vibe.rawValue.capitalized)
                Spacer()
                Text(t.note.isEmpty ? "✨" : t.note).foregroundStyle(.secondary)
            }
        }
        .navigationTitle("내 도감 (\(items.count))")
        .onAppear { items = repo.collected(by: userID) }
    }
}
```

- [ ] **Step 4: 빌드 + 실기기 수동검증**

Run: `xcodebuild -scheme TraceHunt -destination 'generic/platform=iOS' build`
Expected: `BUILD SUCCEEDED`
수동검증(실기기): 리몰 → "현장 인증하고 획득" → 도감 화면 진입 시 방금 획득한 흔적 1개가 리스트에 보임.

- [ ] **Step 5: 커밋**

```bash
git add TraceHunt
git commit -m "feat: capture snapshot -> collect into 도감"
```

---

### Task 10: 흔적 0초 남기기 (그 자리서, 수동검증)

**Files:**
- Create: `TraceHunt/Features/LeaveTrace/LeaveTraceView.swift`
- Modify: `TraceHunt/Features/Reveal/ARRevealView.swift` (획득 직후 LeaveTrace 시트 자동 띄움 — relay 넛지)

**Interfaces:**
- Consumes: `TraceRepository.leaveTrace(_:)`, `VibeTag`, `Coordinate`, `CaptureService`
- Produces: `LeaveTraceView(coordinate: Coordinate, photoRef: String, repo: TraceRepository, userID: UUID, onDone: () -> Void)`

- [ ] **Step 1: LeaveTraceView 작성 (사진은 방금 캡처본 재사용 + 한마디 + vibe 1탭)**

`TraceHunt/Features/LeaveTrace/LeaveTraceView.swift`:

```swift
import SwiftUI
import TraceCore

struct LeaveTraceView: View {
    let coordinate: Coordinate
    let photoRef: String
    let repo: TraceRepository
    let userID: UUID
    var onDone: () -> Void

    @State private var note: String = ""
    @State private var vibe: VibeTag = .scenic

    var body: some View {
        VStack(spacing: 16) {
            Text("여기 흔적 남기기").font(.title2).bold()
            Text("방금 찍은 사진이 그대로 쓰여요").font(.caption).foregroundStyle(.secondary)
            TextField("한마디 (선택)", text: $note).textFieldStyle(.roundedBorder)
            Picker("vibe", selection: $vibe) {
                ForEach(VibeTag.allCases, id: \.self) { Text($0.rawValue).tag($0) }
            }.pickerStyle(.segmented)
            Button("남기기") {
                let t = Trace(id: UUID(), creatorID: userID, photoRef: photoRef,
                              note: note, vibe: vibe, coordinate: coordinate,
                              createdAt: Date(), collectCount: 0)
                repo.leaveTrace(t)
                onDone()
            }.buttonStyle(.borderedProminent)
        }.padding()
    }
}
```

- [ ] **Step 2: 획득 직후 자동 띄우기 (relay 넛지)**

획득(`onCaptured`) 완료 직후 `LeaveTraceView`를 `.sheet`로 자동 표시. 헤더 카피: "여기 N명이 남겼어. 너도?" (`spot.heat` 사용). → 찾기와 남기기가 한 동선.

- [ ] **Step 3: 빌드 + 실기기 수동검증 (전체 루프)**

Run: `xcodebuild -scheme TraceHunt -destination 'generic/platform=iOS' build`
Expected: `BUILD SUCCEEDED`
수동검증(실기기): 핀 탭 → 따뜻해짐 → 보물 꺼내기(AR) → 현장 인증 획득 → **자동으로 흔적 남기기 시트** → vibe 고르고 "남기기" → 지도로 돌아오면 그 스팟 heat가 +1.

- [ ] **Step 4: 커밋**

```bash
git add TraceHunt
git commit -m "feat: leave-trace sheet auto-prompted after capture (relay nudge)"
```

---

### Task 11: 엔드투엔드 통합 + 실기기 검수 + 코어 회귀

**Files:**
- Modify: `TraceHunt/TraceHuntApp.swift` (repo·userID 단일 소스로 주입, 지도/도감 탭 구성)

**Interfaces:**
- Consumes: 모든 이전 타스크
- Produces: 단일 `InMemoryTraceRepository` 인스턴스를 지도/헌트/도감/남기기가 공유

- [ ] **Step 1: 단일 repo·userID 주입**

`TraceHuntApp`에서 `let repo = MockData.repository()`, `let userID = UUID()`를 한 번 만들어 `TabView`(지도 / 도감)와 하위 화면에 전달. 남긴 흔적이 도감·지도·heat에 일관 반영되는지 단일 소스 보장.

- [ ] **Step 2: 코어 회귀 테스트**

Run: `cd TraceCore && swift test`
Expected: 전체 PASS (Smoke 1 + Model 3 + Warmth 3 + Hunt 5 + Rarity 3 + Repo 4 = 19 tests)

- [ ] **Step 3: 앱 빌드**

Run: `xcodebuild -scheme TraceHunt -destination 'generic/platform=iOS' build`
Expected: `BUILD SUCCEEDED`

- [ ] **Step 4: 실기기 엔드투엔드 검수 체크리스트**

- [ ] 지도에 시드 핀 2개 + heat 라벨
- [ ] 핀 근처 가면 따뜻/멀면 차가움, <15m에서만 "보물 꺼내기" 활성
- [ ] AR 리몰: 빌보드 흔적 보임
- [ ] 현장 인증 → 도감에 획득 추가
- [ ] 획득 직후 흔적 남기기 시트 자동 + "N명이 남겼어. 너도?"
- [ ] 남기면 그 스팟 heat +1 (지도 즉시 반영)

- [ ] **Step 5: 커밋 + 태그**

```bash
git add TraceHunt
git commit -m "feat: wire single repo/user across map/hunt/collection/leave (e2e skeleton)"
git tag plan1-walking-skeleton
```

---

## Self-Review (작성자 체크)

**1. 스펙 커버리지 (디자인 §3 코어 동선 기준):** 발견(Task6 지도/heat) · 접근 따뜻/차가움(Task7) · 리몰 2D 빌보드(Task8) · 현장인증 획득(Task9) · 그 자리서 0초 남기기+relay 넛지(Task10) · ④→⑤ 한 동선(Task10 Step2) 모두 타스크 존재. cold-start 시딩/안전/정체성 합성/멀티유저는 **의도적으로 Plan 2~4로 분리**(범위 밖, 본 플랜 상단 분해표에 명시).

**2. 플레이스홀더 스캔:** 로직 타스크(1~5)는 실제 코드·테스트 전량 포함. UI 타스크(6~11)는 ARKit/카메라/GPS 의존이라 단위테스트 대신 빌드+수동검증으로 명시(가짜 테스트 회피). "TODO/적절히 처리" 류 없음.

**3. 타입 일관성:** `Coordinate`, `Trace(... collectCount:)`, `incrementCollect()`, `Spot.heat`, `WarmthCalculator.canReveal/revealRadiusMeters(15)`, `HuntState`, `TraceRepository.{spots,nearbySpots,leaveTrace,collect,collected}`, `snapRadiusMeters(20)` — 정의 타스크와 소비 타스크 시그니처 일치 확인.

**해결한 갭:** 없음(범위 분리 외).
