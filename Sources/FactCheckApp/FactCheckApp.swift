import SwiftUI

@main
struct FactCheckApp: App {
    @StateObject private var viewModel = FactCheckViewModel()

    var body: some Scene {
        WindowGroup {
            NavigationStack {
                ContentView(viewModel: viewModel)
            }
        }
    }
}
