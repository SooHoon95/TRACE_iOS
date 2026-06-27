//
//  Project.swift
//  TraceManifests
//

import ProjectDescription
import ProjectDescriptionHelpers

let project = Project.framework(
  name: "Home",
  platform: .iOS,
  dependencies: [
    .appFoundation,
    .uiComponent,
    .domain,
    .router,
    // 홈의 "너도 남겨" → 순간 남기기 플로우
    .feature(target: "LeaveTrace")
  ],
  testDependencies: []
)
