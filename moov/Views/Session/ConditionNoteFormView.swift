//
//  ConditionNoteFormView.swift
//  moov
//

import SwiftUI
import SwiftData

/// 컨디션/부상 메모 작성. note가 nil이면(session이 반드시 전달됨) 새 메모를 생성한다. UC-05, FR-08.
struct ConditionNoteFormView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    let note: ConditionNote?
    let session: WorkoutSession?

    @State private var bodyPart: String = ""
    @State private var painLevel: Int?
    @State private var memo: String = ""

    private var isNew: Bool { note == nil }
    private var trimmedMemo: String { memo.trimmingCharacters(in: .whitespacesAndNewlines) }

    var body: some View {
        Form {
            Section("부위 (선택)") {
                TextField("예: 어깨, 무릎", text: $bodyPart)
            }

            Section("통증 강도 (선택)") {
                Toggle("통증 강도 기록", isOn: painLevelEnabledBinding)
                if painLevel != nil {
                    Stepper("강도 \(painLevel ?? 5) / 10", value: painLevelBinding, in: 1...10)
                }
            }

            Section("메모") {
                TextField("컨디션이나 통증 상태를 기록해보세요", text: $memo, axis: .vertical)
                    .lineLimit(3...8)
            }
        }
        .navigationTitle(isNew ? "컨디션 메모 추가" : "컨디션 메모 수정")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button("취소") { dismiss() }
            }
            ToolbarItem(placement: .confirmationAction) {
                Button("저장") { save() }
                    .disabled(trimmedMemo.isEmpty)
            }
        }
        .onAppear { loadExistingValues() }
    }

    private var painLevelEnabledBinding: Binding<Bool> {
        Binding(
            get: { painLevel != nil },
            set: { enabled in painLevel = enabled ? (painLevel ?? 5) : nil }
        )
    }

    private var painLevelBinding: Binding<Int> {
        Binding(
            get: { painLevel ?? 5 },
            set: { painLevel = $0 }
        )
    }

    private func loadExistingValues() {
        guard let note else { return }
        bodyPart = note.bodyPart ?? ""
        painLevel = note.painLevel
        memo = note.memo
    }

    private func save() {
        guard !trimmedMemo.isEmpty else { return }
        let trimmedBodyPart = bodyPart.trimmingCharacters(in: .whitespacesAndNewlines)

        if let note {
            note.bodyPart = trimmedBodyPart.isEmpty ? nil : trimmedBodyPart
            note.painLevel = painLevel
            note.memo = trimmedMemo
        } else if let session {
            let newNote = ConditionNote(
                bodyPart: trimmedBodyPart.isEmpty ? nil : trimmedBodyPart,
                painLevel: painLevel,
                memo: trimmedMemo
            )
            modelContext.insert(newNote)
            session.conditionNotes.append(newNote)
        }

        dismiss()
    }
}

#Preview {
    NavigationStack {
        ConditionNoteFormView(note: nil, session: WorkoutSession(date: .now))
    }
    .modelContainer(for: WorkoutSession.self, inMemory: true)
}
