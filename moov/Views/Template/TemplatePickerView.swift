//
//  TemplatePickerView.swift
//  moov
//

import SwiftUI
import SwiftData

/// 세션 작성 중 템플릿을 선택해 불러올 때 쓰는 목록. UC-06, FR-09.
struct TemplatePickerView: View {
    @Environment(\.dismiss) private var dismiss
    @Query(sort: \WorkoutTemplate.name) private var templates: [WorkoutTemplate]

    let onSelect: (WorkoutTemplate) -> Void

    var body: some View {
        Group {
            if templates.isEmpty {
                ContentUnavailableView {
                    Label("저장된 템플릿이 없어요", systemImage: "doc.on.doc")
                } description: {
                    Text("관리 탭에서 템플릿을 먼저 만들어보세요.")
                }
            } else {
                List(templates) { template in
                    Button {
                        onSelect(template)
                        dismiss()
                    } label: {
                        VStack(alignment: .leading, spacing: 4) {
                            Text(template.name)
                                .font(.headline)
                            Text("파트 \(template.templateParts.count)개")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                        .padding(.vertical, 2)
                    }
                    .buttonStyle(.plain)
                }
            }
        }
        .navigationTitle("템플릿 불러오기")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button("취소") { dismiss() }
            }
        }
    }
}

#Preview {
    NavigationStack {
        TemplatePickerView { _ in }
    }
    .modelContainer(for: WorkoutSession.self, inMemory: true)
}
