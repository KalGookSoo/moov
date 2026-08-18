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

    @State private var groupForNewBlock: TemplateBlockGroup?
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

            if part.groups.isEmpty {
                Section("그룹") {
                    ContentUnavailableView {
                        Label("그룹이 없어요", systemImage: "dumbbell")
                    } description: {
                        Text("종목을 그룹으로 묶고, 몇 라운드 반복할지 정해보세요. 그룹에 종목이 1개면 스트레이트 세트, 2개 이상이면 서킷이 됩니다.")
                    } actions: {
                        Button("그룹 추가") { addGroup() }
                            .buttonStyle(.borderedProminent)
                    }
                }
            } else {
                ForEach(sortedGroups) { group in
                    TemplateGroupSection(
                        group: group,
                        onAddBlock: { groupForNewBlock = group },
                        onEditBlock: { blockToEdit = $0 },
                        onDeleteGroup: { deleteGroup(group) }
                    )
                }

                Section {
                    Button {
                        addGroup()
                    } label: {
                        Label("그룹 추가", systemImage: "plus")
                    }
                }
            }
        }
        .navigationTitle(part.format.displayName)
        .navigationBarTitleDisplayMode(.inline)
        .sheet(item: $groupForNewBlock) { group in
            NavigationStack {
                TemplateBlockFormView(block: nil, group: group)
            }
        }
        .sheet(item: $blockToEdit) { block in
            NavigationStack {
                TemplateBlockFormView(block: block, group: nil)
            }
        }
    }

    private var sortedGroups: [TemplateBlockGroup] {
        part.groups.sorted { $0.order < $1.order }
    }

    private func addGroup() {
        let newGroup = TemplateBlockGroup(order: part.groups.count)
        modelContext.insert(newGroup)
        part.groups.append(newGroup)
    }

    private func deleteGroup(_ group: TemplateBlockGroup) {
        modelContext.delete(group)
    }
}

private struct TemplateGroupSection: View {
    @Environment(\.modelContext) private var modelContext
    @Bindable var group: TemplateBlockGroup
    let onAddBlock: () -> Void
    let onEditBlock: (TemplateBlock) -> Void
    let onDeleteGroup: () -> Void

    private var sortedBlocks: [TemplateBlock] {
        group.blocks.sorted { $0.order < $1.order }
    }

    var body: some View {
        Section {
            Stepper("라운드 수 \(group.rounds)", value: $group.rounds, in: 1...99)

            ForEach(sortedBlocks) { block in
                Button {
                    onEditBlock(block)
                } label: {
                    TemplateBlockRow(block: block)
                }
                .buttonStyle(.plain)
            }
            .onDelete(perform: deleteBlocks)

            Button {
                onAddBlock()
            } label: {
                Label("종목 추가", systemImage: "plus")
            }

            Button(role: .destructive) {
                onDeleteGroup()
            } label: {
                Text("그룹 삭제")
            }
        } header: {
            Text(sortedBlocks.count > 1 ? "서킷 그룹" : "그룹")
        } footer: {
            if sortedBlocks.count > 1 {
                Text("\(sortedBlocks.count)개 종목을 번갈아 \(group.rounds)라운드 수행합니다.")
            }
        }
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
        if let reps = block.reps { pieces.append("\(reps)\(block.repsUnit?.displayName ?? RepsUnit.count.displayName)") }
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
