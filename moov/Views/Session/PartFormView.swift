//
//  PartFormView.swift
//  moov
//

import SwiftUI
import SwiftData

/// 파트 편집 (포맷/타임캡/블록/결과). UC-01, FR-02, FR-03, FR-04.
struct PartFormView: View {
    @Environment(\.modelContext) private var modelContext
    @Bindable var part: WorkoutPart

    @State private var isAddingBlock = false
    @State private var blockToEdit: ExerciseBlock?

    var body: some View {
        Form {
            Section("포맷") {
                Picker("포맷", selection: $part.format) {
                    ForEach(WorkoutFormat.allCases, id: \.self) { format in
                        Text(format.displayName).tag(format)
                    }
                }

                Toggle("타임캡 설정", isOn: timeCapEnabledBinding)
                if part.timeCapSeconds != nil {
                    Stepper("타임캡 \(timeCapMinutes)분", value: timeCapMinutesBinding, in: 1...180)
                }
            }

            Section("블록") {
                if part.blocks.isEmpty {
                    ContentUnavailableView {
                        Label("블록이 없어요", systemImage: "dumbbell")
                    } description: {
                        Text("종목을 추가해 이 파트에서 수행할 운동을 기록해보세요.")
                    } actions: {
                        Button("블록 추가") { isAddingBlock = true }
                            .buttonStyle(.borderedProminent)
                    }
                } else {
                    ForEach(sortedBlocks) { block in
                        Button {
                            blockToEdit = block
                        } label: {
                            BlockRow(block: block)
                        }
                        .buttonStyle(.plain)
                    }
                    .onDelete(perform: deleteBlocks)

                    Button {
                        isAddingBlock = true
                    } label: {
                        Label("블록 추가", systemImage: "plus")
                    }
                }
            }

            Section("결과") {
                ResultEditorView(part: part)
            }
        }
        .navigationTitle(part.format.displayName)
        .navigationBarTitleDisplayMode(.inline)
        .sheet(isPresented: $isAddingBlock) {
            NavigationStack {
                BlockFormView(block: nil, part: part)
            }
        }
        .sheet(item: $blockToEdit) { block in
            NavigationStack {
                BlockFormView(block: block, part: nil)
            }
        }
    }

    private var sortedBlocks: [ExerciseBlock] {
        part.blocks.sorted { $0.order < $1.order }
    }

    private var timeCapEnabledBinding: Binding<Bool> {
        Binding(
            get: { part.timeCapSeconds != nil },
            set: { enabled in
                part.timeCapSeconds = enabled ? (part.timeCapSeconds ?? 600) : nil
            }
        )
    }

    private var timeCapMinutes: Int {
        (part.timeCapSeconds ?? 600) / 60
    }

    private var timeCapMinutesBinding: Binding<Int> {
        Binding(
            get: { (part.timeCapSeconds ?? 600) / 60 },
            set: { part.timeCapSeconds = $0 * 60 }
        )
    }

    private func deleteBlocks(at offsets: IndexSet) {
        let blocks = sortedBlocks
        for index in offsets {
            modelContext.delete(blocks[index])
        }
    }
}

private struct BlockRow: View {
    let block: ExerciseBlock

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(block.exercise?.name ?? block.exerciseName)
                .font(.headline)
            Text(detail)
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
        .padding(.vertical, 2)
    }

    private var detail: String {
        var pieces: [String] = []
        if let weight = block.weight {
            let unit = block.weightUnit?.displayName ?? ""
            pieces.append("\(weight.formatted())\(unit)")
        }
        if let reps = block.reps { pieces.append("\(reps)회") }
        if let sets = block.sets { pieces.append("\(sets)세트") }
        if !block.tags.isEmpty {
            pieces.append(block.tags.map(\.name).joined(separator: ", "))
        }
        return pieces.isEmpty ? "세부 정보 없음" : pieces.joined(separator: " · ")
    }
}

/// 파트의 결과(WorkoutResult)를 kind에 맞는 필드로 입력한다. FR-04.
private struct ResultEditorView: View {
    @Environment(\.modelContext) private var modelContext
    @Bindable var part: WorkoutPart

    var body: some View {
        Group {
            Toggle("결과 입력", isOn: hasResultBinding)

            if let result = part.result {
                Picker("결과 유형", selection: kindBinding) {
                    ForEach(ResultKind.allCases, id: \.self) { kind in
                        Text(kind.displayName).tag(kind)
                    }
                }

                switch result.kind {
                case .time:
                    TextField("완료 시간(초)", value: timeSecondsBinding, format: .number)
                        .keyboardType(.numberPad)
                case .roundsAndReps:
                    Stepper("완료 라운드 \(result.rounds ?? 0)", value: roundsBinding, in: 0...99)
                    Stepper("추가 렙 \(result.extraReps ?? 0)", value: extraRepsBinding, in: 0...999)
                case .passFail:
                    Toggle("성공", isOn: isCompletedBinding)
                case .maxWeight:
                    TextField("최대 중량", value: maxWeightBinding, format: .number)
                        .keyboardType(.decimalPad)
                }

                TextField("보충 설명 (선택)", text: completionNoteBinding, axis: .vertical)
                    .lineLimit(2...4)
            }
        }
    }

    private var hasResultBinding: Binding<Bool> {
        Binding(
            get: { part.result != nil },
            set: { enabled in
                if enabled {
                    let result = WorkoutResult(kind: .suggested(for: part.format))
                    modelContext.insert(result)
                    part.result = result
                } else if let existing = part.result {
                    part.result = nil
                    modelContext.delete(existing)
                }
            }
        )
    }

    private var kindBinding: Binding<ResultKind> {
        Binding(
            get: { part.result?.kind ?? .suggested(for: part.format) },
            set: { part.result?.kind = $0 }
        )
    }

    private var timeSecondsBinding: Binding<Int> {
        Binding(
            get: { part.result?.timeSeconds ?? 0 },
            set: { part.result?.timeSeconds = $0 }
        )
    }

    private var roundsBinding: Binding<Int> {
        Binding(
            get: { part.result?.rounds ?? 0 },
            set: { part.result?.rounds = $0 }
        )
    }

    private var extraRepsBinding: Binding<Int> {
        Binding(
            get: { part.result?.extraReps ?? 0 },
            set: { part.result?.extraReps = $0 }
        )
    }

    private var isCompletedBinding: Binding<Bool> {
        Binding(
            get: { part.result?.isCompleted ?? false },
            set: { part.result?.isCompleted = $0 }
        )
    }

    private var maxWeightBinding: Binding<Double> {
        Binding(
            get: { part.result?.maxWeight ?? 0 },
            set: { part.result?.maxWeight = $0 }
        )
    }

    private var completionNoteBinding: Binding<String> {
        Binding(
            get: { part.result?.completionNote ?? "" },
            set: { part.result?.completionNote = $0.isEmpty ? nil : $0 }
        )
    }
}

#Preview {
    NavigationStack {
        PartFormView(part: WorkoutPart(order: 0, format: .amrap))
    }
    .modelContainer(for: WorkoutSession.self, inMemory: true)
}
