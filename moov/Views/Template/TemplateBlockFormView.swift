//
//  TemplateBlockFormView.swift
//  moov
//

import SwiftUI
import SwiftData

/// 템플릿 블록 편집. block이 nil이면(part가 반드시 전달됨) 새 블록을 생성한다. UC-06, FR-09.
struct TemplateBlockFormView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    let block: TemplateBlock?
    let part: TemplatePart?

    @State private var selectedExercise: Exercise?
    @State private var weight: Double?
    @State private var weightUnit: WeightUnit = .lb
    @State private var reps: Int?
    @State private var sets: Int? = 1
    @State private var restSeconds: Int?
    @State private var selectedTags: Set<Tag> = []

    private var isNew: Bool { block == nil }

    var body: some View {
        Form {
            Section("종목") {
                ExercisePickerField(selection: $selectedExercise)
            }

            Section("무게 / 반복") {
                HStack {
                    TextField("무게", value: $weight, format: .number)
                        .keyboardType(.decimalPad)
                    Picker("단위", selection: $weightUnit) {
                        ForEach(WeightUnit.allCases, id: \.self) { unit in
                            Text(unit.displayName).tag(unit)
                        }
                    }
                    .pickerStyle(.segmented)
                    .frame(width: 120)
                }
                TextField("반복수", value: $reps, format: .number)
                    .keyboardType(.numberPad)
                TextField("세트수", value: $sets, format: .number)
                    .keyboardType(.numberPad)
                TextField("휴식시간(초)", value: $restSeconds, format: .number)
                    .keyboardType(.numberPad)
            }

            Section("태그") {
                TagPickerField(selection: $selectedTags)
            }
        }
        .navigationTitle(isNew ? "블록 추가" : "블록 수정")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button("취소") { dismiss() }
            }
            ToolbarItem(placement: .confirmationAction) {
                Button("저장") { save() }
                    .disabled(selectedExercise == nil)
            }
        }
        .onAppear { loadExistingValues() }
    }

    private func loadExistingValues() {
        guard let block else { return }
        selectedExercise = block.exercise
        weight = block.weight
        weightUnit = block.weightUnit ?? .lb
        reps = block.reps
        sets = block.sets
        restSeconds = block.restSeconds
        selectedTags = Set(block.tags)
    }

    private func save() {
        guard let selectedExercise else { return }

        if let block {
            block.exercise = selectedExercise
            block.exerciseName = selectedExercise.name
            block.weight = weight
            block.weightUnit = weightUnit
            block.reps = reps
            block.sets = sets
            block.restSeconds = restSeconds
            block.tags = Array(selectedTags)
        } else if let part {
            let newBlock = TemplateBlock(
                order: part.blocks.count,
                exercise: selectedExercise,
                weight: weight,
                weightUnit: weightUnit,
                reps: reps,
                sets: sets,
                restSeconds: restSeconds,
                tags: Array(selectedTags)
            )
            modelContext.insert(newBlock)
            part.blocks.append(newBlock)
        }

        dismiss()
    }
}

#Preview {
    NavigationStack {
        TemplateBlockFormView(block: nil, part: TemplatePart(order: 0, format: .amrap))
    }
    .modelContainer(for: WorkoutSession.self, inMemory: true)
}
