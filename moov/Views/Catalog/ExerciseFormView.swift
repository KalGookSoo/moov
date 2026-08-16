//
//  ExerciseFormView.swift
//  moov
//

import SwiftUI
import SwiftData

/// 종목 추가/수정. exercise가 nil이면 새 종목을 생성한다. UC-07, FR-11.
struct ExerciseFormView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    let exercise: Exercise?

    @State private var name = ""
    @State private var category = ""
    @State private var hasDefaultUnit = false
    @State private var defaultWeightUnit: WeightUnit = .lb

    private var isNew: Bool { exercise == nil }
    private var trimmedName: String { name.trimmingCharacters(in: .whitespacesAndNewlines) }

    var body: some View {
        Form {
            Section("이름") {
                TextField("종목명", text: $name)
            }

            Section("카테고리 (선택)") {
                TextField("예: 웨이트리프팅, 체조, 컨디셔닝", text: $category)
            }

            Section("기본 무게 단위 (선택)") {
                Toggle("기본 단위 지정", isOn: $hasDefaultUnit)
                if hasDefaultUnit {
                    Picker("단위", selection: $defaultWeightUnit) {
                        ForEach(WeightUnit.allCases, id: \.self) { unit in
                            Text(unit.displayName).tag(unit)
                        }
                    }
                    .pickerStyle(.segmented)
                }
            }
        }
        .navigationTitle(isNew ? "종목 추가" : "종목 수정")
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

    private func loadExistingValues() {
        guard let exercise else { return }
        name = exercise.name
        category = exercise.category ?? ""
        if let unit = exercise.defaultWeightUnit {
            hasDefaultUnit = true
            defaultWeightUnit = unit
        }
    }

    private func save() {
        guard !trimmedName.isEmpty else { return }
        let trimmedCategory = category.trimmingCharacters(in: .whitespacesAndNewlines)
        let unit: WeightUnit? = hasDefaultUnit ? defaultWeightUnit : nil

        if let exercise {
            exercise.name = trimmedName
            exercise.category = trimmedCategory.isEmpty ? nil : trimmedCategory
            exercise.defaultWeightUnit = unit
        } else {
            let newExercise = Exercise(
                name: trimmedName,
                category: trimmedCategory.isEmpty ? nil : trimmedCategory,
                defaultWeightUnit: unit
            )
            modelContext.insert(newExercise)
        }
        dismiss()
    }
}

#Preview {
    NavigationStack {
        ExerciseFormView(exercise: nil)
    }
    .modelContainer(for: WorkoutSession.self, inMemory: true)
}
