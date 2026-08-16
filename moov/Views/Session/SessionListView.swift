//
//  SessionListView.swift
//  moov
//

import SwiftUI
import SwiftData

/// 세션 목록. UC-02, FR-05.
struct SessionListView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \WorkoutSession.date, order: .reverse) private var sessions: [WorkoutSession]

    @State private var isPresentingNewSession = false
    @State private var sessionToEdit: WorkoutSession?

    var body: some View {
        NavigationStack {
            Group {
                if sessions.isEmpty {
                    ContentUnavailableView {
                        Label("아직 기록한 세션이 없어요", systemImage: "figure.strengthtraining.traditional")
                    } description: {
                        Text("오늘 운동을 기록하고 시간에 따른 변화를 확인해보세요.")
                    } actions: {
                        Button("세션 기록하기") {
                            isPresentingNewSession = true
                        }
                        .buttonStyle(.borderedProminent)
                    }
                } else {
                    List {
                        ForEach(sessions) { session in
                            Button {
                                sessionToEdit = session
                            } label: {
                                SessionRow(session: session)
                            }
                            .buttonStyle(.plain)
                        }
                        .onDelete(perform: deleteSessions)
                    }
                }
            }
            .navigationTitle("세션")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        isPresentingNewSession = true
                    } label: {
                        Label("세션 추가", systemImage: "plus")
                    }
                }
            }
            .sheet(isPresented: $isPresentingNewSession) {
                NavigationStack {
                    SessionFormView(session: nil)
                }
            }
            .sheet(item: $sessionToEdit) { session in
                NavigationStack {
                    SessionFormView(session: session)
                }
            }
        }
    }

    private func deleteSessions(at offsets: IndexSet) {
        for index in offsets {
            modelContext.delete(sessions[index])
        }
    }
}

private struct SessionRow: View {
    let session: WorkoutSession

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(session.date, format: .dateTime.year().month().day().weekday(.abbreviated))
                .font(.headline)
            if session.parts.isEmpty {
                Text("파트 없음")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            } else {
                Text(partsSummary)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
            }
        }
        .padding(.vertical, 4)
    }

    private var partsSummary: String {
        session.parts
            .sorted { $0.order < $1.order }
            .map(\.format.displayName)
            .joined(separator: " · ")
    }
}

#Preview {
    SessionListView()
        .modelContainer(for: WorkoutSession.self, inMemory: true)
}
