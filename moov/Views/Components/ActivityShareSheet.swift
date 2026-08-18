//
//  ActivityShareSheet.swift
//  moov
//

import SwiftUI
import UIKit

/// 시스템 공유 시트(UIActivityViewController) 래퍼. FR-17.
struct ActivityShareSheet: UIViewControllerRepresentable {
    let items: [Any]

    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: items, applicationActivities: nil)
    }

    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}
