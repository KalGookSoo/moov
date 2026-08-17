//
//  ExercisePickerField.swift
//  moov
//

import SwiftUI
import SwiftData

/// 종목 검색형 선택 UI. 검색어로 후보를 좁혀 종목을 선택하고, 일치하는 종목이 없으면
/// 그 자리에서 새 종목을 추가한다. FR-19.
struct ExercisePickerField: View {
    @Binding var selection: Exercise?

    var body: some View {
        NavigationLink {
            ExercisePickerListView(selection: $selection)
        } label: {
            LabeledContent("종목", value: selection?.name ?? "선택 안 함")
        }
    }
}

private struct ExercisePickerListView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @Binding var selection: Exercise?

    @Query(sort: \Exercise.name) private var exercises: [Exercise]
    @State private var searchText = ""

    private var trimmedSearchText: String {
        searchText.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private var filteredExercises: [Exercise] {
        guard !searchText.isEmpty else { return exercises }
        return exercises.filter { $0.name.localizedCaseInsensitiveContains(searchText) }
    }

    private var hasExactMatch: Bool {
        exercises.contains { $0.name.localizedCaseInsensitiveCompare(trimmedSearchText) == .orderedSame }
    }

    var body: some View {
        List {
            ForEach(filteredExercises) { exercise in
                Button {
                    selection = exercise
                    dismiss()
                } label: {
                    HStack {
                        Text(exercise.name)
                        Spacer()
                        if selection == exercise {
                            Image(systemName: "checkmark")
                                .foregroundStyle(.tint)
                        }
                    }
                }
                .foregroundStyle(.primary)
            }

            if !trimmedSearchText.isEmpty, !hasExactMatch {
                Button {
                    addExercise()
                } label: {
                    Label("'\(trimmedSearchText)' 새 종목으로 추가", systemImage: "plus.circle")
                }
            }
        }
        .searchable(text: $searchText, prompt: "종목 검색")
        .navigationTitle("종목 선택")
        .navigationBarTitleDisplayMode(.inline)
        .overlay {
            if exercises.isEmpty {
                ContentUnavailableView {
                    Label("등록된 종목이 없어요", systemImage: "figure.run")
                } description: {
                    Text("검색창에 종목명을 입력해 새로 추가해보세요.")
                }
                .allowsHitTesting(false)
            }
        }
    }

    private func addExercise() {
        guard !trimmedSearchText.isEmpty else { return }
        let exercise = Exercise(name: trimmedSearchText)
        modelContext.insert(exercise)
        selection = exercise
        dismiss()
    }
}
