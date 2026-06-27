//
//  Project.swift
//  TraceManifests
//

import ProjectDescription
import ProjectDescriptionHelpers

let project = Project.framework(
  name: "Infrastructure",
  platform: .iOS,
  dependencies: [
    .appFoundation,
    .domain
  ],
  testDependencies: [

  ]
)
