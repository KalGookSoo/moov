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

    @Query(sort: \Exercise.name) private var exercises: [Exercise]
    @Query(sort: \Tag.name) private var allTags: [Tag]

    @State private var selectedExercise: Exercise?
    @State private var weight: Double?
    @State private var weightUnit: WeightUnit = .lb
    @State private var reps: Int?
    @State private var sets: Int?
    @State private var restSeconds: Int?
    @State private var selectedTags: Set<Tag> = []

    @State private var isAddingExercise = false
    @State private var newExerciseName = ""
    @State private var isAddingTag = false
    @State private var newTagName = ""

    private var isNew: Bool { block == nil }

    var body: some View {
        Form {
            Section("종목") {
                if exercises.isEmpty {
                    ContentUnavailableView {
                        Label("등록된 종목이 없어요", systemImage: "figure.run")
                    } description: {
                        Text("사용할 운동 종목을 먼저 추가해주세요.")
                    } actions: {
                        Button("종목 추가") { isAddingExercise = true }
                            .buttonStyle(.borderedProminent)
                    }
                } else {
                    Picker("종목", selection: $selectedExercise) {
                        Text("선택 안 함").tag(Exercise?.none)
                        ForEach(exercises) { exercise in
                            Text(exercise.name).tag(Optional(exercise))
                        }
                    }
                    Button("새 종목 추가") { isAddingExercise = true }
                }
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
                if allTags.isEmpty {
                    ContentUnavailableView {
                        Label("태그가 없어요", systemImage: "tag")
                    } description: {
                        Text("웜업/본운동/보조운동처럼 이 블록을 구분할 태그를 추가해보세요.")
                    } actions: {
                        Button("태그 추가") { isAddingTag = true }
                            .buttonStyle(.borderedProminent)
                    }
                } else {
                    ForEach(allTags) { tag in
                        Toggle(tag.name, isOn: tagBinding(tag))
                    }
                    Button("새 태그 추가") { isAddingTag = true }
                }
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
        .alert("새 종목 추가", isPresented: $isAddingExercise) {
            TextField("종목명", text: $newExerciseName)
            Button("추가") { addExercise() }
            Button("취소", role: .cancel) { newExerciseName = "" }
        } message: {
            Text("카테고리나 기본 무게 단위는 나중에 추가할 수 있어요.")
        }
        .alert("새 태그 추가", isPresented: $isAddingTag) {
            TextField("태그명", text: $newTagName)
            Button("추가") { addTag() }
            Button("취소", role: .cancel) { newTagName = "" }
        }
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

    private func tagBinding(_ tag: Tag) -> Binding<Bool> {
        Binding(
            get: { selectedTags.contains(tag) },
            set: { isOn in
                if isOn {
                    selectedTags.insert(tag)
                } else {
                    selectedTags.remove(tag)
                }
            }
        )
    }

    private func addExercise() {
        let trimmed = newExerciseName.trimmingCharacters(in: .whitespacesAndNewlines)
        newExerciseName = ""
        guard !trimmed.isEmpty else { return }
        let exercise = Exercise(name: trimmed)
        modelContext.insert(exercise)
        selectedExercise = exercise
    }

    private func addTag() {
        let trimmed = newTagName.trimmingCharacters(in: .whitespacesAndNewlines)
        newTagName = ""
        guard !trimmed.isEmpty else { return }
        let tag = Tag(name: trimmed)
        modelContext.insert(tag)
        selectedTags.insert(tag)
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
