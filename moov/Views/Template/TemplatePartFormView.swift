//
//  TemplatePartFormView.swift
//  moov
//

import SwiftUI
import SwiftData

/// 템플릿 파트 편집 (포맷/블록). 실제 세션의 PartFormView와 달리 결과(WorkoutResult) 개념이 없다. UC-06, FR-09.
struct TemplatePartFormView: View {
    @Environment(\.modelContext) private var modelContext
    @Bindable var part: TemplatePart

    @State private var isAddingBlock = false
    @State private var blockToEdit: TemplateBlock?

    var body: some View {
        Form {
            Section("포맷") {
                Picker("포맷", selection: $part.format) {
                    ForEach(WorkoutFormat.allCases, id: \.self) { format in
                        Text(format.displayName).tag(format)
                    }
                }
            }

            Section("블록") {
                if part.blocks.isEmpty {
                    ContentUnavailableView {
                        Label("블록이 없어요", systemImage: "dumbbell")
                    } description: {
                        Text("종목을 추가해 이 파트에서 수행할 운동을 구성해보세요.")
                    } actions: {
                        Button("블록 추가") { isAddingBlock = true }
                            .buttonStyle(.borderedProminent)
                    }
                } else {
                    ForEach(sortedBlocks) { block in
                        Button {
                            blockToEdit = block
                        } label: {
                            TemplateBlockRow(block: block)
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
        }
        .navigationTitle(part.format.displayName)
        .navigationBarTitleDisplayMode(.inline)
        .sheet(isPresented: $isAddingBlock) {
            NavigationStack {
                TemplateBlockFormView(block: nil, part: part)
            }
        }
        .sheet(item: $blockToEdit) { block in
            NavigationStack {
                TemplateBlockFormView(block: block, part: nil)
            }
        }
    }

    private var sortedBlocks: [TemplateBlock] {
        part.blocks.sorted { $0.order < $1.order }
    }

    private func deleteBlocks(at offsets: IndexSet) {
        let blocks = sortedBlocks
        for index in offsets {
            modelContext.delete(blocks[index])
        }
    }
}

private struct TemplateBlockRow: View {
    let block: TemplateBlock

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

#Preview {
    NavigationStack {
        TemplatePartFormView(part: TemplatePart(order: 0, format: .amrap))
    }
    .modelContainer(for: WorkoutSession.self, inMemory: true)
}
