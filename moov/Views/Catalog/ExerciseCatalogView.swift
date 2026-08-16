//
//  ExerciseCatalogView.swift
//  moov
//

import SwiftUI
import SwiftData

/// 사용자 정의 운동 종목 카탈로그 관리. UC-07, FR-11.
struct ExerciseCatalogView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \Exercise.name) private var exercises: [Exercise]

    @State private var isAddingExercise = false
    @State private var exerciseToEdit: Exercise?
    @State private var exerciseToDelete: Exercise?
    @State private var deleteUsageCount = 0

    var body: some View {
        Group {
            if exercises.isEmpty {
                ContentUnavailableView {
                    Label("등록된 종목이 없어요", systemImage: "figure.run")
                } description: {
                    Text("자주 사용하는 운동 종목을 추가해보세요.")
                } actions: {
                    Button("종목 추가") { isAddingExercise = true }
                        .buttonStyle(.borderedProminent)
                }
            } else {
                List {
                    ForEach(exercises) { exercise in
                        Button {
                            exerciseToEdit = exercise
                        } label: {
                            ExerciseRow(exercise: exercise)
                        }
                        .buttonStyle(.plain)
                        .swipeActions {
                            Button("삭제", role: .destructive) {
                                requestDelete(exercise)
                            }
                        }
                    }
                }
            }
        }
        .navigationTitle("종목 카탈로그")
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button {
                    isAddingExercise = true
                } label: {
                    Label("종목 추가", systemImage: "plus")
                }
            }
        }
        .sheet(isPresented: $isAddingExercise) {
            NavigationStack {
                ExerciseFormView(exercise: nil)
            }
        }
        .sheet(item: $exerciseToEdit) { exercise in
            NavigationStack {
                ExerciseFormView(exercise: exercise)
            }
        }
        .confirmationDialog(
            exerciseToDelete?.name ?? "",
            isPresented: isDeletePresentedBinding,
            titleVisibility: .visible
        ) {
            Button("삭제", role: .destructive) { confirmDelete() }
            Button("취소", role: .cancel) { exerciseToDelete = nil }
        } message: {
            Text(deleteConfirmationMessage)
        }
    }

    private var isDeletePresentedBinding: Binding<Bool> {
        Binding(
            get: { exerciseToDelete != nil },
            set: { if !$0 { exerciseToDelete = nil } }
        )
    }

    private var deleteConfirmationMessage: String {
        if deleteUsageCount > 0 {
            "이미 \(deleteUsageCount)개 기록에 사용 중입니다. 삭제해도 과거 기록의 종목명은 유지됩니다."
        } else {
            "이 종목을 삭제할까요?"
        }
    }

    private func requestDelete(_ exercise: Exercise) {
        deleteUsageCount = usageCount(for: exercise)
        exerciseToDelete = exercise
    }

    private func usageCount(for exercise: Exercise) -> Int {
        let targetID = exercise.id
        let predicate = #Predicate<ExerciseBlock> { block in
            block.exercise?.id == targetID
        }
        let descriptor = FetchDescriptor(predicate: predicate)
        return (try? modelContext.fetchCount(descriptor)) ?? 0
    }

    private func confirmDelete() {
        guard let exercise = exerciseToDelete else { return }
        modelContext.delete(exercise)
        exerciseToDelete = nil
    }
}

private struct ExerciseRow: View {
    let exercise: Exercise

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(exercise.name)
                .font(.headline)
            if let detail {
                Text(detail)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(.vertical, 2)
    }

    private var detail: String? {
        var pieces: [String] = []
        if let category = exercise.category { pieces.append(category) }
        if let unit = exercise.defaultWeightUnit { pieces.append("기본 단위 \(unit.displayName)") }
        return pieces.isEmpty ? nil : pieces.joined(separator: " · ")
    }
}

#Preview {
    NavigationStack {
        ExerciseCatalogView()
    }
    .modelContainer(for: WorkoutSession.self, inMemory: true)
}
