//
//  TagAggregateView.swift
//  moov
//

import SwiftUI
import SwiftData
import Charts

/// 특정 태그가 부여된 블록의 주별 볼륨/빈도 집계 추이. UC-03, FR-13.
struct TagAggregateView: View {
    let tag: Tag
    @Query private var allBlocks: [ExerciseBlock]

    private var entries: [(date: Date, block: ExerciseBlock)] {
        allBlocks
            .compactMap { block in
                guard block.tags.contains(where: { $0.id == tag.id }),
                      let date = block.part?.session?.date else { return nil }
                return (date, block)
            }
            .sorted { $0.date < $1.date }
    }

    private var weeklyBuckets: [WeeklyBucket] {
        let calendar = Calendar.current
        var buckets: [Date: (volume: Int, frequency: Int)] = [:]

        for entry in entries {
            let weekStart = calendar.dateInterval(of: .weekOfYear, for: entry.date)?.start ?? entry.date
            let reps = entry.block.reps ?? 0
            let sets = entry.block.sets ?? 1
            var bucket = buckets[weekStart] ?? (volume: 0, frequency: 0)
            bucket.volume += reps * sets
            bucket.frequency += 1
            buckets[weekStart] = bucket
        }

        return buckets
            .map { WeeklyBucket(weekStart: $0.key, volume: $0.value.volume, frequency: $0.value.frequency) }
            .sorted { $0.weekStart < $1.weekStart }
    }

    var body: some View {
        Group {
            if entries.isEmpty {
                ContentUnavailableView {
                    Label("기록이 없어요", systemImage: "chart.bar")
                } description: {
                    Text("\"\(tag.name)\" 태그가 부여된 블록을 기록하면 여기에 추이가 표시돼요.")
                }
            } else {
                List {
                    if weeklyBuckets.count >= 2 {
                        Section("주별 볼륨 추이") {
                            VolumeTrendChart(buckets: weeklyBuckets)
                                .frame(height: 220)
                                .listRowInsets(EdgeInsets())
                                .padding()
                        }
                    }

                    Section("주별 요약") {
                        ForEach(weeklyBuckets) { bucket in
                            HStack {
                                Text(bucket.weekStart, format: .dateTime.month().day())
                                Spacer()
                                Text("볼륨 \(bucket.volume) · \(bucket.frequency)회")
                                    .foregroundStyle(.secondary)
                            }
                        }
                    }
                }
            }
        }
        .navigationTitle(tag.name)
    }
}

private struct WeeklyBucket: Identifiable {
    let weekStart: Date
    let volume: Int
    let frequency: Int

    var id: Date { weekStart }
}

private struct VolumeTrendChart: View {
    let buckets: [WeeklyBucket]

    var body: some View {
        Chart(buckets) { bucket in
            BarMark(
                x: .value("주", bucket.weekStart, unit: .weekOfYear),
                y: .value("볼륨", bucket.volume)
            )
        }
    }
}

#Preview {
    NavigationStack {
        TagAggregateView(tag: Tag(name: "컨디셔닝"))
    }
    .modelContainer(for: WorkoutSession.self, inMemory: true)
}
