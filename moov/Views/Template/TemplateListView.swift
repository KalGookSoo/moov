//
//  TemplateListView.swift
//  moov
//

import SwiftUI
import SwiftData

/// 템플릿 목록. "관리" 탭에서 진입한다. UC-06, FR-09.
struct TemplateListView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \WorkoutTemplate.name) private var templates: [WorkoutTemplate]

    @State private var isAddingTemplate = false
    @State private var templateToEdit: WorkoutTemplate?

    var body: some View {
        Group {
            if templates.isEmpty {
                ContentUnavailableView {
                    Label("저장된 템플릿이 없어요", systemImage: "doc.on.doc")
                } description: {
                    Text("자주 쓰는 운동 구성을 템플릿으로 저장해보세요.")
                } actions: {
                    Button("템플릿 추가") { isAddingTemplate = true }
                        .buttonStyle(.borderedProminent)
                }
            } else {
                List {
                    ForEach(templates) { template in
                        Button {
                            templateToEdit = template
                        } label: {
                            TemplateRow(template: template)
                        }
                        .buttonStyle(.plain)
                    }
                    .onDelete(perform: deleteTemplates)
                }
            }
        }
        .navigationTitle("템플릿")
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button {
                    isAddingTemplate = true
                } label: {
                    Label("템플릿 추가", systemImage: "plus")
                }
            }
        }
        .sheet(isPresented: $isAddingTemplate) {
            NavigationStack {
                TemplateFormView(template: nil)
            }
        }
        .sheet(item: $templateToEdit) { template in
            NavigationStack {
                TemplateFormView(template: template)
            }
        }
    }

    private func deleteTemplates(at offsets: IndexSet) {
        for index in offsets {
            modelContext.delete(templates[index])
        }
    }
}

private struct TemplateRow: View {
    let template: WorkoutTemplate

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(template.name)
                .font(.headline)
            Text(summary)
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
        .padding(.vertical, 2)
    }

    private var summary: String {
        if template.templateParts.isEmpty { return "파트 없음" }
        return template.templateParts
            .sorted { $0.order < $1.order }
            .map(\.format.displayName)
            .joined(separator: " · ")
    }
}

#Preview {
    NavigationStack {
        TemplateListView()
    }
    .modelContainer(for: WorkoutSession.self, inMemory: true)
}
