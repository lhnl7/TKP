import SwiftUI
import UIKit

struct ContentView: UIViewControllerRepresentable {
    func makeUIViewController(context: Context) -> UIViewController {
        return PlayerViewController()
    }
    func updateUIViewController(_ uiViewController: UIViewController, context: Context) {}
}
