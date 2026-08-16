//
//  TemplateFormView.swift
//  moov
//

import SwiftUI
import SwiftData

/// 템플릿 작성/수정. template이 nil이면 새 템플릿을 생성한다. UC-06, FR-09.
struct TemplateFormView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    @Bindable private var template: WorkoutTemplate
    private let isNew: Bool

    init(template: WorkoutTemplate?) {
        let resolved = template ?? WorkoutTemplate(name: "")
        _template = Bindable(wrappedValue: resolved)
        isNew = template == nil
    }

    var body: some View {
        Form {
            Section("이름") {
                TextField("템플릿 이름", text: $template.name)
            }

            Section {
                if template.templateParts.isEmpty {
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
                            TemplatePartFormView(part: part)
                        } label: {
                            TemplatePartRow(part: part)
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
        }
        .navigationTitle(isNew ? "템플릿 추가" : "템플릿 수정")
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button("취소") { cancel() }
            }
            ToolbarItem(placement: .confirmationAction) {
                Button("저장") { dismiss() }
                    .disabled(trimmedName.isEmpty || template.templateParts.isEmpty)
            }
        }
        .onAppear {
            if isNew {
                modelContext.insert(template)
            }
        }
    }

    private var trimmedName: String {
        template.name.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private var sortedParts: [TemplatePart] {
        template.templateParts.sorted { $0.order < $1.order }
    }

    private func addPart() {
        let newPart = TemplatePart(order: template.templateParts.count, format: .emom)
        modelContext.insert(newPart)
        template.templateParts.append(newPart)
    }

    private func deleteParts(at offsets: IndexSet) {
        let parts = sortedParts
        for index in offsets {
            modelContext.delete(parts[index])
        }
    }

    private func cancel() {
        if isNew {
            modelContext.delete(template)
        }
        dismiss()
    }
}

private struct TemplatePartRow: View {
    let part: TemplatePart

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(part.format.displayName)
                .font(.headline)
            Text(part.blocks.isEmpty ? "블록 없음" : "블록 \(part.blocks.count)개")
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
        .padding(.vertical, 2)
    }
}

#Preview {
    NavigationStack {
        TemplateFormView(template: nil)
    }
    .modelContainer(for: WorkoutSession.self, inMemory: true)
}
