# TRACE — iOS

실제 장소가 시간캡슐이 되는 여행 앱. 장소에 사진 '순간'을 남기면(claiming) 그 장소의 '모두의 순간' 전시에 즉시 합류한다.

- **Stack:** Swift · SwiftUI · Tuist 멀티모듈 클린아키텍처 · iOS 17+
- **Design:** 자체 디자인 시스템(Pretendard), claude.ai/design → 코드
- **Backend(예정):** Supabase(인증·DB) + Cloudflare R2(사진). 현재는 인메모리 목업.

## Getting started

```bash
./Scripts/bootstrap.sh      # 로컬 secrets 생성 + 툴체인 + tuist generate
open TRACE.xcworkspace
```

수동으로 하려면:

```bash
cp XCConfigs/Sensitive.xcconfig.example XCConfigs/Sensitive.xcconfig
mise install
mise exec -- tuist generate --no-open
```

## Build & test

```bash
mise exec -- tuist generate --no-open
xcodebuild test  -workspace TRACE.xcworkspace -scheme Domain   -destination 'platform=iOS Simulator,name=iPhone 17 Pro'
xcodebuild build -workspace TRACE.xcworkspace -scheme TraceApp -destination 'platform=iOS Simulator,name=iPhone 17 Pro'
```

## Secrets

민감 정보는 git에 올리지 않는다. `XCConfigs/Sensitive.xcconfig`(git-ignored)에만 로컬로 두고,
구조는 `XCConfigs/Sensitive.xcconfig.example`(커밋됨)을 참고. 실제 키는 절대 커밋 금지.

## Architecture

```
AppFoundation → Domain(모델·로직·프로토콜) → Network / Infrastructure
UIComponent(디자인 시스템) · Router(Coordinator 네비)
Feature/{MainTab·Map·LeaveTrace·Collection·Identity·Onboard·…}
TraceApp(조립 루트)
```

- Domain은 UI/SDK 무관 순수 Swift. 백엔드 SDK는 Infrastructure/Network에만.
- 화면 네비게이션은 `Router`의 Coordinator 패턴 (`NavigationCoordinator` + `ViewFactory` + `CoordinatedRootView`).
