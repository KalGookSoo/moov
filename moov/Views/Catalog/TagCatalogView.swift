//
//  TagCatalogView.swift
//  moov
//

import SwiftUI
import SwiftData

/// 사용자 정의 태그 카탈로그 관리. UC-08, FR-12.
///
/// 태그 삭제는 종목과 달리 사용 이력 스냅샷이 없다(docs/data-model.md 설계 원칙 4).
/// 이미 블록에 사용 중인 태그를 삭제하면 해당 블록에서 태그만 제거되고 블록/기록은 유지된다.
struct TagCatalogView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \Tag.name) private var tags: [Tag]

    @State private var isAddingTag = false
    @State private var tagToEdit: Tag?

    var body: some View {
        Group {
            if tags.isEmpty {
                ContentUnavailableView {
                    Label("등록된 태그가 없어요", systemImage: "tag")
                } description: {
                    Text("웜업/본운동/보조운동처럼 블록을 구분할 태그를 추가해보세요.")
                } actions: {
                    Button("태그 추가") { isAddingTag = true }
                        .buttonStyle(.borderedProminent)
                }
            } else {
                List {
                    ForEach(tags) { tag in
                        Button {
                            tagToEdit = tag
                        } label: {
                            TagRow(tag: tag)
                        }
                        .buttonStyle(.plain)
                    }
                    .onDelete(perform: deleteTags)
                }
            }
        }
        .navigationTitle("태그 카탈로그")
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button {
                    isAddingTag = true
                } label: {
                    Label("태그 추가", systemImage: "plus")
                }
            }
        }
        .sheet(isPresented: $isAddingTag) {
            NavigationStack {
                TagFormView(tag: nil)
            }
        }
        .sheet(item: $tagToEdit) { tag in
            NavigationStack {
                TagFormView(tag: tag)
            }
        }
    }

    private func deleteTags(at offsets: IndexSet) {
        for index in offsets {
            modelContext.delete(tags[index])
        }
    }
}

private struct TagRow: View {
    let tag: Tag

    var body: some View {
        HStack(spacing: 8) {
            Circle()
                .fill(tag.colorHex.flatMap(Color.init(hex:)) ?? Color.secondary)
                .frame(width: 12, height: 12)
            Text(tag.name)
        }
        .padding(.vertical, 2)
    }
}

#Preview {
    NavigationStack {
        TagCatalogView()
    }
    .modelContainer(for: WorkoutSession.self, inMemory: true)
}
