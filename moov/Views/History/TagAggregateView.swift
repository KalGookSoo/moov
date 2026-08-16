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
        TagWeeklyAggregator.matchingEntries(blocks: allBlocks, tag: tag)
    }

    private var weeklyBuckets: [WeeklyBucket] {
        TagWeeklyAggregator.aggregate(blocks: allBlocks, tag: tag)
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
