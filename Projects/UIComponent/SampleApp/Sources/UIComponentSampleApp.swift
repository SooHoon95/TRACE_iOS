import SwiftUI
import UIComponent

/// Design-system showcase. Run this scheme to browse the TRACE v2 component catalog
/// and the example screens (with bundled Pretendard fonts) in the simulator.
@main
struct UIComponentSampleApp: App {
    init() { TraceFonts.registerAll() }

    var body: some Scene {
        WindowGroup {
            SampleRootView()
        }
    }
}

/// Screen switcher: the component catalog plus each composed example screen.
private struct SampleRootView: View {
    var body: some View {
        NavigationStack {
            List {
                Section("디자인 시스템") {
                    NavigationLink("컴포넌트 카탈로그") {
                        DesignSystemCatalog()
                            .navigationTitle("카탈로그")
                            .navigationBarTitleDisplayMode(.inline)
                    }
                }
                Section("예시 화면") {
                    ForEach(TraceExampleScreen.allCases) { screen in
                        NavigationLink(screen.title) {
                            screen.view
                                .navigationTitle(screen.title)
                                .navigationBarTitleDisplayMode(.inline)
                        }
                    }
                }
            }
            .navigationTitle("TRACE v2")
        }
    }
}
