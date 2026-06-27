import ProjectDescription
import ProjectDescriptionHelpers

let project = Project.app(
  name: "TraceApp",
  destinations: [.iPhone],
  platform: .iOS,
  dependencies: [
    .appFoundation,
    .uiComponent,
    .networking,
    .router,
    .domain,
    .infrastructure,
    .feature(target: "MainTab"),
    .feature(target: "Map"),
    .feature(target: "LeaveTrace"),
    .feature(target: "Collection"),
    .feature(target: "Identity"),
    .feature(target: "Onboard")
  ],
  testDependencies: []
)
