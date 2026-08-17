//
//  VersionInfoView.swift
//  moov
//

import SwiftUI

/// 버전 정보 화면 — 마케팅 버전/빌드 번호 표시. UC-10, FR-16.
struct VersionInfoView: View {
    private var marketingVersion: String {
        Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0"
    }

    private var buildNumber: String {
        Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "1"
    }

    var body: some View {
        List {
            LabeledContent("버전", value: marketingVersion)
            LabeledContent("빌드", value: buildNumber)
        }
        .navigationTitle("버전 정보")
    }
}

#Preview {
    NavigationStack {
        VersionInfoView()
    }
}
