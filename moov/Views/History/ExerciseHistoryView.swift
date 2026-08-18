//
//  ExerciseHistoryView.swift
//  moov
//

import SwiftUI
import SwiftData
import Charts

/// 특정 종목의 시간순 기록 추이. 종목 매칭은 Exercise 카탈로그 참조 기준(FR-11)이라
/// 표기 차이로 인한 기록 누락이 없다. UC-03, FR-06.
struct ExerciseHistoryView: View {
    let exercise: Exercise
    @Query private var blocks: [ExerciseBlock]

    init(exercise: Exercise) {
        self.exercise = exercise
        let targetID = exercise.id
        _blocks = Query(filter: #Predicate<ExerciseBlock> { $0.exercise?.id == targetID })
    }

    private var entries: [(date: Date, block: ExerciseBlock)] {
        ExerciseHistoryCalculator.makeEntries(from: blocks)
    }

    private var weightPointCount: Int {
        entries.reduce(into: 0) { count, entry in
            if entry.block.weight != nil { count += 1 }
        }
    }

    var body: some View {
        Group {
            if entries.isEmpty {
                ContentUnavailableView {
                    Label("기록이 없어요", systemImage: "chart.xyaxis.line")
                } description: {
                    Text("\(exercise.name)을(를) 블록으로 기록하면 여기에 추이가 표시돼요.")
                }
            } else {
                List {
                    if weightPointCount >= 2 {
                        Section("무게 추이") {
                            WeightTrendChart(entries: entries)
                                .frame(height: 220)
                                .listRowInsets(EdgeInsets())
                                .padding()
                        }
                    }

                    Section("기록") {
                        ForEach(entries, id: \.block.id) { entry in
                            HistoryRow(date: entry.date, block: entry.block)
                        }
                    }
                }
            }
        }
        .navigationTitle(exercise.name)
    }
}

private struct WeightTrendChart: View {
    let entries: [(date: Date, block: ExerciseBlock)]

    var body: some View {
        Chart {
            ForEach(entries, id: \.block.id) { entry in
                if let weight = entry.block.weight {
                    LineMark(
                        x: .value("날짜", entry.date, unit: .day),
                        y: .value("무게", weight)
                    )
                    PointMark(
                        x: .value("날짜", entry.date, unit: .day),
                        y: .value("무게", weight)
                    )
                }
            }
        }
    }
}

private struct HistoryRow: View {
    let date: Date
    let block: ExerciseBlock

    var body: some View {
        HStack {
            Text(date, format: .dateTime.year().month().day())
            Spacer()
            Text(detail)
                .foregroundStyle(.secondary)
        }
    }

    private var detail: String {
        var pieces: [String] = []
        if let weight = block.weight {
            pieces.append("\(weight.formatted())\(block.weightUnit?.displayName ?? "")")
        }
        if let reps = block.reps { pieces.append("\(reps)회") }
        if let group = block.group {
            if group.blocks.count > 1 {
                pieces.append("\(group.rounds)라운드")
            } else if group.rounds > 1 {
                pieces.append("\(group.rounds)세트")
            }
        }
        return pieces.isEmpty ? "-" : pieces.joined(separator: " · ")
    }
}

#Preview {
    NavigationStack {
        ExerciseHistoryView(exercise: Exercise(name: "Back Squat"))
    }
    .modelContainer(for: WorkoutSession.self, inMemory: true)
}
