import SwiftUI
import Clerk

@main
struct DevilsPlanApp: App {
  @State private var clerk = Clerk.shared

  var body: some Scene {
    WindowGroup {
      ZStack {
        if clerk.isLoaded {
          ContentView()
        } else {
          ProgressView()
        }
      }
      .environment(clerk)
      .task {
        clerk.configure(publishableKey: "pk_test_c2hpbmluZy1tYXJ0aW4tNjIuY2xlcmsuYWNjb3VudHMuZGV2JA")
        try? await clerk.load()
      }
    }
  }
}
