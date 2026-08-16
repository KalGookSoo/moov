//
//  TagFormView.swift
//  moov
//

import SwiftUI
import SwiftData

/// 태그 추가/수정. tag가 nil이면 새 태그를 생성한다. UC-08, FR-12.
struct TagFormView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    let tag: Tag?

    @State private var name = ""
    @State private var colorHex: String?

    private var isNew: Bool { tag == nil }
    private var trimmedName: String { name.trimmingCharacters(in: .whitespacesAndNewlines) }

    private static let presetColors = [
        "FF3B30", "FF9500", "FFCC00", "34C759", "007AFF", "5856D6", "AF52DE", "8E8E93",
    ]

    var body: some View {
        Form {
            Section("이름") {
                TextField("태그명", text: $name)
            }

            Section("색상 (선택)") {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 12) {
                        ForEach(Self.presetColors, id: \.self) { hex in
                            swatch(for: hex)
                        }
                    }
                    .padding(.vertical, 4)
                }
            }
        }
        .navigationTitle(isNew ? "태그 추가" : "태그 수정")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button("취소") { dismiss() }
            }
            ToolbarItem(placement: .confirmationAction) {
                Button("저장") { save() }
                    .disabled(trimmedName.isEmpty)
            }
        }
        .onAppear { loadExistingValues() }
    }

    private func swatch(for hex: String) -> some View {
        Circle()
            .fill(Color(hex: hex) ?? .gray)
            .frame(width: 32, height: 32)
            .overlay {
                if colorHex == hex {
                    Image(systemName: "checkmark")
                        .foregroundStyle(.white)
                        .font(.caption.bold())
                }
            }
            .onTapGesture {
                colorHex = (colorHex == hex) ? nil : hex
            }
    }

    private func loadExistingValues() {
        guard let tag else { return }
        name = tag.name
        colorHex = tag.colorHex
    }

    private func save() {
        guard !trimmedName.isEmpty else { return }

        if let tag {
            tag.name = trimmedName
            tag.colorHex = colorHex
        } else {
            let newTag = Tag(name: trimmedName, colorHex: colorHex)
            modelContext.insert(newTag)
        }
        dismiss()
    }
}

#Preview {
    NavigationStack {
        TagFormView(tag: nil)
    }
    .modelContainer(for: WorkoutSession.self, inMemory: true)
}
