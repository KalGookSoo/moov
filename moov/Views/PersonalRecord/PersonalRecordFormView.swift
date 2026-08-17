//
//  PersonalRecordFormView.swift
//  moov
//

import SwiftUI
import SwiftData

/// PR 등록. append-only 로그이므로 항상 새 기록을 추가한다(수정은 없음). UC-04, FR-07.
struct PersonalRecordFormView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    @Query private var allRecords: [PersonalRecord]

    @State private var selectedExercise: Exercise?
    @State private var weight: Double?
    @State private var weightUnit: WeightUnit = .lb
    @State private var date: Date = .now

    @State private var showLowerThanBestConfirmation = false

    var body: some View {
        Form {
            Section("종목") {
                ExercisePickerField(selection: $selectedExercise)
            }

            Section("중량") {
                HStack {
                    TextField("중량", value: $weight, format: .number)
                        .keyboardType(.decimalPad)
                    Picker("단위", selection: $weightUnit) {
                        ForEach(WeightUnit.allCases, id: \.self) { unit in
                            Text(unit.displayName).tag(unit)
                        }
                    }
                    .pickerStyle(.segmented)
                    .frame(width: 120)
                }
            }

            Section("날짜") {
                DatePicker("날짜", selection: $date, displayedComponents: .date)
                    .labelsHidden()
            }

            if let currentBest {
                Section {
                    Text("현재 PR: \(currentBest.weight.formatted())\(currentBest.weightUnit.displayName)")
                        .foregroundStyle(.secondary)
                }
            }
        }
        .navigationTitle("PR 등록")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button("취소") { dismiss() }
            }
            ToolbarItem(placement: .confirmationAction) {
                Button("저장") { attemptSave() }
                    .disabled(selectedExercise == nil || weight == nil)
            }
        }
        .confirmationDialog(
            "기존 PR보다 낮은 값이에요",
            isPresented: $showLowerThanBestConfirmation,
            titleVisibility: .visible
        ) {
            Button("그래도 저장", role: .destructive) { save() }
            Button("취소", role: .cancel) {}
        } message: {
            Text(lowerThanBestMessage)
        }
    }

    private var currentBest: PersonalRecord? {
        guard let selectedExercise else { return nil }
        return allRecords
            .filter { $0.exerciseName == selectedExercise.name }
            .max { $0.weight < $1.weight }
    }

    private var lowerThanBestMessage: String {
        guard let currentBest else { return "" }
        return "기존 PR은 \(currentBest.weight.formatted())\(currentBest.weightUnit.displayName)입니다. 그래도 저장할까요?"
    }

    private func attemptSave() {
        guard let weight else { return }
        if let currentBest, weight < currentBest.weight {
            showLowerThanBestConfirmation = true
        } else {
            save()
        }
    }

    private func save() {
        guard let selectedExercise, let weight else { return }
        let record = PersonalRecord(exercise: selectedExercise, weight: weight, weightUnit: weightUnit, date: date)
        modelContext.insert(record)
        dismiss()
    }
}

#Preview {
    NavigationStack {
        PersonalRecordFormView()
    }
    .modelContainer(for: WorkoutSession.self, inMemory: true)
}
