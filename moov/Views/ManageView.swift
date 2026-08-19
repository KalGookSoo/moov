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
    @State private var isImportingBackup = false
    @State private var pendingBackupPayload: BackupPayload?
    @State private var isPresentingMergeConfirmation = false
    @State private var backupImportResultMessage: String?
    @State private var backupImportErrorMessage: String?

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

                Section("백업") {
                    Button {
                        exportWorkouts()
                    } label: {
                        Label("데이터 내보내기", systemImage: "square.and.arrow.up")
                    }

                    Button {
                        isImportingBackup = true
                    } label: {
                        Label("백업에서 복원", systemImage: "arrow.counterclockwise")
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
        .fileImporter(isPresented: $isImportingBackup, allowedContentTypes: [.json]) { result in
            switch result {
            case .success(let url):
                loadBackup(from: url)
            case .failure(let error):
                backupImportErrorMessage = error.localizedDescription
            }
        }
        .confirmationDialog(
            "기존 데이터가 있습니다",
            isPresented: $isPresentingMergeConfirmation,
            titleVisibility: .visible
        ) {
            Button("병합") { performBackupImport(strategy: .merge) }
            Button("교체", role: .destructive) { performBackupImport(strategy: .replace) }
            Button("취소", role: .cancel) { pendingBackupPayload = nil }
        } message: {
            Text("병합하면 기존 데이터에 백업 내용이 추가되고, 교체하면 기존 데이터를 모두 지운 뒤 백업 내용으로 되살립니다.")
        }
        .alert("복원 완료", isPresented: backupImportSuccessBinding) {
            Button("확인") {}
        } message: {
            Text(backupImportResultMessage ?? "")
        }
        .alert("복원 실패", isPresented: backupImportErrorBinding) {
            Button("확인") {}
        } message: {
            Text(backupImportErrorMessage ?? "")
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

    private var backupImportSuccessBinding: Binding<Bool> {
        Binding(
            get: { backupImportResultMessage != nil },
            set: { if !$0 { backupImportResultMessage = nil } }
        )
    }

    private var backupImportErrorBinding: Binding<Bool> {
        Binding(
            get: { backupImportErrorMessage != nil },
            set: { if !$0 { backupImportErrorMessage = nil } }
        )
    }

    private func loadBackup(from url: URL) {
        guard url.startAccessingSecurityScopedResource() else {
            backupImportErrorMessage = "파일에 접근할 수 없습니다."
            return
        }
        defer { url.stopAccessingSecurityScopedResource() }

        do {
            let data = try Data(contentsOf: url)
            let decoder = JSONDecoder()
            decoder.dateDecodingStrategy = .iso8601
            let payload = try decoder.decode(BackupPayload.self, from: data)

            if try BackupImporter.hasExistingData(using: modelContext) {
                pendingBackupPayload = payload
                isPresentingMergeConfirmation = true
            } else {
                let count = try BackupImporter.apply(payload, strategy: .merge, using: modelContext)
                backupImportResultMessage = "세션 \(count)개를 복원했습니다."
            }
        } catch {
            backupImportErrorMessage = BackupImportError.invalidFile.localizedDescription
        }
    }

    private func performBackupImport(strategy: BackupImportStrategy) {
        guard let payload = pendingBackupPayload else { return }
        pendingBackupPayload = nil

        do {
            let count = try BackupImporter.apply(payload, strategy: strategy, using: modelContext)
            backupImportResultMessage = "세션 \(count)개를 복원했습니다."
        } catch {
            backupImportErrorMessage = error.localizedDescription
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
            let recordCount = payload.personalRecords?.count ?? 0
            if recordCount > 0 {
                importResultMessage = "세션 \(count)개, PR \(recordCount)개를 가져왔습니다."
            } else {
                importResultMessage = "\(count)개 세션을 가져왔습니다."
            }
        } catch {
            importErrorMessage = error.localizedDescription
        }
    }
}

#Preview {
    ManageView()
        .modelContainer(for: WorkoutSession.self, inMemory: true)
}
