//
//  SessionFormView.swift
//  moov
//

import SwiftUI
import SwiftData

/// 세션 작성/수정. session이 nil이면 새 세션을 생성한다. UC-01, FR-01.
struct SessionFormView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    @Bindable private var session: WorkoutSession
    private let isNew: Bool

    @State private var isAddingConditionNote = false
    @State private var conditionNoteToEdit: ConditionNote?

    init(session: WorkoutSession?) {
        let resolved = session ?? WorkoutSession(date: .now)
        _session = Bindable(wrappedValue: resolved)
        isNew = session == nil
    }

    var body: some View {
        Form {
            Section("날짜") {
                DatePicker("날짜", selection: $session.date, displayedComponents: .date)
                    .labelsHidden()
            }

            Section {
                if session.parts.isEmpty {
                    ContentUnavailableView {
                        Label("파트가 없어요", systemImage: "list.bullet.rectangle")
                    } description: {
                        Text("웜업, 본운동, 보조운동처럼 수행 단위를 하나 이상 추가해야 저장할 수 있어요.")
                    } actions: {
                        Button("파트 추가") { addPart() }
                            .buttonStyle(.borderedProminent)
                    }
                } else {
                    ForEach(sortedParts) { part in
                        NavigationLink {
                            PartFormView(part: part)
                        } label: {
                            PartRow(part: part)
                        }
                    }
                    .onDelete(perform: deleteParts)

                    Button {
                        addPart()
                    } label: {
                        Label("파트 추가", systemImage: "plus")
                    }
                }
            } header: {
                Text("파트")
            }

            Section("컨디션 메모") {
                if session.conditionNotes.isEmpty {
                    ContentUnavailableView {
                        Label("컨디션 메모가 없어요", systemImage: "heart.text.square")
                    } description: {
                        Text("통증이나 컨디션이 있다면 메모로 남겨보세요.")
                    } actions: {
                        Button("메모 추가") { isAddingConditionNote = true }
                    }
                } else {
                    ForEach(session.conditionNotes) { note in
                        Button {
                            conditionNoteToEdit = note
                        } label: {
                            ConditionNoteRow(note: note)
                        }
                        .buttonStyle(.plain)
                    }
                    .onDelete(perform: deleteConditionNotes)

                    Button {
                        isAddingConditionNote = true
                    } label: {
                        Label("메모 추가", systemImage: "plus")
                    }
                }
            }

            Section("노트") {
                TextField("메모 (선택)", text: notesBinding, axis: .vertical)
                    .lineLimit(3...6)
            }
        }
        .navigationTitle(isNew ? "세션 기록" : "세션 수정")
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button("취소") { cancel() }
            }
            ToolbarItem(placement: .confirmationAction) {
                Button("저장") { dismiss() }
                    .disabled(session.parts.isEmpty)
            }
        }
        .onAppear {
            if isNew {
                modelContext.insert(session)
            }
        }
        .sheet(isPresented: $isAddingConditionNote) {
            NavigationStack {
                ConditionNoteFormView(note: nil, session: session)
            }
        }
        .sheet(item: $conditionNoteToEdit) { note in
            NavigationStack {
                ConditionNoteFormView(note: note, session: nil)
            }
        }
    }

    private var sortedParts: [WorkoutPart] {
        session.parts.sorted { $0.order < $1.order }
    }

    private var notesBinding: Binding<String> {
        Binding(
            get: { session.notes ?? "" },
            set: { session.notes = $0.isEmpty ? nil : $0 }
        )
    }

    private func addPart() {
        let newPart = WorkoutPart(order: session.parts.count, format: .emom)
        modelContext.insert(newPart)
        session.parts.append(newPart)
    }

    private func deleteParts(at offsets: IndexSet) {
        let parts = sortedParts
        for index in offsets {
            modelContext.delete(parts[index])
        }
    }

    private func cancel() {
        if isNew {
            modelContext.delete(session)
        }
        dismiss()
    }

    private func deleteConditionNotes(at offsets: IndexSet) {
        for index in offsets {
            modelContext.delete(session.conditionNotes[index])
        }
    }
}

private struct PartRow: View {
    let part: WorkoutPart

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(part.format.displayName)
                .font(.headline)
            Text(summary)
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
        .padding(.vertical, 2)
    }

    private var summary: String {
        var pieces: [String] = []
        pieces.append(part.blocks.isEmpty ? "블록 없음" : "블록 \(part.blocks.count)개")
        if part.result != nil {
            pieces.append("결과 입력됨")
        }
        return pieces.joined(separator: " · ")
    }
}

private struct ConditionNoteRow: View {
    let note: ConditionNote

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                if let bodyPart = note.bodyPart {
                    Text(bodyPart)
                        .font(.headline)
                }
                if let painLevel = note.painLevel {
                    Text("강도 \(painLevel)/10")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            Text(note.memo)
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .lineLimit(2)
        }
        .padding(.vertical, 2)
    }
}

#Preview {
    NavigationStack {
        SessionFormView(session: nil)
    }
    .modelContainer(for: WorkoutSession.self, inMemory: true)
}
