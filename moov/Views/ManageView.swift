//
//  ManageView.swift
//  moov
//

import SwiftUI
import SwiftData
import UniformTypeIdentifiers

/// "관리" 탭 — 템플릿/종목 카탈로그/태그 카탈로그 진입점. docs/information-architecture.md.
struct ManageView: View {
    @Environment(\.modelContext) private var modelContext

    @State private var isShowingOnboarding = false
    @State private var isShowingReleaseNotes = false
    @State private var isImportingWorkouts = false
    @State private var importResultMessage: String?
    @State private var importErrorMessage: String?
    @State private var isPresentingExportSheet = false
    @State private var exportFileURL: URL?
    @State private var exportErrorMessage: String?

    var body: some View {
        NavigationStack {
            List {
                NavigationLink {
                    TemplateListView()
                } label: {
                    Label("템플릿", systemImage: "doc.on.doc")
                }

                NavigationLink {
                    ExerciseCatalogView()
                } label: {
                    Label("종목 카탈로그", systemImage: "figure.run")
                }

                NavigationLink {
                    TagCatalogView()
                } label: {
                    Label("태그 카탈로그", systemImage: "tag")
                }

                Section("내보내기") {
                    Button {
                        exportWorkouts()
                    } label: {
                        Label("데이터 내보내기", systemImage: "square.and.arrow.up")
                    }
                }

                Section("가져오기") {
                    Button {
                        isImportingWorkouts = true
                    } label: {
                        Label("운동 기록 가져오기", systemImage: "square.and.arrow.down")
                    }
                }

                Section("도움말") {
                    Button {
                        isShowingOnboarding = true
                    } label: {
                        Label("온보딩 다시 보기", systemImage: "questionmark.circle")
                    }

                    Button {
                        isShowingReleaseNotes = true
                    } label: {
                        Label("업데이트 노트", systemImage: "sparkles")
                    }

                    NavigationLink {
                        VersionInfoView()
                    } label: {
                        Label("버전 정보", systemImage: "info.circle")
                    }
                }
            }
            .navigationTitle("관리")
        }
        .fullScreenCover(isPresented: $isShowingOnboarding) {
            GuidePagerView(pages: OnboardingContent.pages, finishButtonTitle: "닫기", showsSkip: false) {
                isShowingOnboarding = false
            }
        }
        .fullScreenCover(isPresented: $isShowingReleaseNotes) {
            GuidePagerView(
                pages: ReleaseNotesContent.notes.flatMap(\.pages),
                finishButtonTitle: "닫기",
                showsSkip: false
            ) {
                isShowingReleaseNotes = false
            }
        }
        .fileImporter(isPresented: $isImportingWorkouts, allowedContentTypes: [.json]) { result in
            switch result {
            case .success(let url):
                importWorkouts(from: url)
            case .failure(let error):
                importErrorMessage = error.localizedDescription
            }
        }
        .alert("가져오기 완료", isPresented: importSuccessBinding) {
            Button("확인") {}
        } message: {
            Text(importResultMessage ?? "")
        }
        .alert("가져오기 실패", isPresented: importErrorBinding) {
            Button("확인") {}
        } message: {
            Text(importErrorMessage ?? "")
        }
        .sheet(isPresented: $isPresentingExportSheet) {
            if let exportFileURL {
                ActivityShareSheet(items: [exportFileURL])
            }
        }
        .alert("내보내기 실패", isPresented: exportErrorBinding) {
            Button("확인") {}
        } message: {
            Text(exportErrorMessage ?? "")
        }
    }

    private var importSuccessBinding: Binding<Bool> {
        Binding(
            get: { importResultMessage != nil },
            set: { if !$0 { importResultMessage = nil } }
        )
    }

    private var importErrorBinding: Binding<Bool> {
        Binding(
            get: { importErrorMessage != nil },
            set: { if !$0 { importErrorMessage = nil } }
        )
    }

    private var exportErrorBinding: Binding<Bool> {
        Binding(
            get: { exportErrorMessage != nil },
            set: { if !$0 { exportErrorMessage = nil } }
        )
    }

    private func exportWorkouts() {
        do {
            let data = try BackupExporter.makeBackupData(using: modelContext)
            let formatter = DateFormatter()
            formatter.dateFormat = "yyyy-MM-dd-HHmmss"
            let filename = "moov-backup-\(formatter.string(from: .now)).json"
            let url = FileManager.default.temporaryDirectory.appendingPathComponent(filename)
            try data.write(to: url, options: .atomic)
            exportFileURL = url
            isPresentingExportSheet = true
        } catch {
            exportErrorMessage = error.localizedDescription
        }
    }

    private func importWorkouts(from url: URL) {
        guard url.startAccessingSecurityScopedResource() else {
            importErrorMessage = "파일에 접근할 수 없습니다."
            return
        }
        defer { url.stopAccessingSecurityScopedResource() }

        do {
            let data = try Data(contentsOf: url)
            let payload = try JSONDecoder().decode(WorkoutImportPayload.self, from: data)
            let count = try WorkoutImporter.apply(payload, using: modelContext)
            importResultMessage = "\(count)개 세션을 가져왔습니다."
        } catch {
            importErrorMessage = error.localizedDescription
        }
    }
}

#Preview {
    ManageView()
        .modelContainer(for: WorkoutSession.self, inMemory: true)
}
