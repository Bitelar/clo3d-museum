import SwiftUI

@main
struct CLO3DMuseumApp: App {
    var body: some Scene {
        WindowGroup {
            ARScannerView()
                .ignoresSafeArea()
        }
    }
}
