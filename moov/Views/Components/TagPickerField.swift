//
//  TagPickerField.swift
//  moov
//

import SwiftUI
import SwiftData

/// 태그 검색형 다중 선택 UI. 검색어로 후보를 좁혀 여러 태그를 선택하고, 선택된 태그는
/// 칩(chip)으로 표시한다. 일치하는 태그가 없으면 그 자리에서 새 태그를 추가한다. FR-19.
struct TagPickerField: View {
    @Binding var selection: Set<Tag>

    private var sortedSelection: [Tag] {
        selection.sorted { $0.name < $1.name }
    }

    var body: some View {
        NavigationLink {
            TagPickerListView(selection: $selection)
        } label: {
            VStack(alignment: .leading, spacing: 8) {
                Text("태그")
                if sortedSelection.isEmpty {
                    Text("선택 안 함")
                        .foregroundStyle(.secondary)
                } else {
                    FlowLayout(spacing: 6) {
                        ForEach(sortedSelection) { tag in
                            TagChip(name: tag.name)
                        }
                    }
                }
            }
        }
    }
}

private struct TagPickerListView: View {
    @Environment(\.modelContext) private var modelContext
    @Binding var selection: Set<Tag>

    @Query(sort: \Tag.name) private var allTags: [Tag]
    @State private var searchText = ""

    private var trimmedSearchText: String {
        searchText.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private var filteredTags: [Tag] {
        guard !searchText.isEmpty else { return allTags }
        return allTags.filter { $0.name.localizedCaseInsensitiveContains(searchText) }
    }

    private var hasExactMatch: Bool {
        allTags.contains { $0.name.localizedCaseInsensitiveCompare(trimmedSearchText) == .orderedSame }
    }

    var body: some View {
        List {
            ForEach(filteredTags) { tag in
                Button {
                    toggle(tag)
                } label: {
                    HStack {
                        Text(tag.name)
                        Spacer()
                        if selection.contains(tag) {
                            Image(systemName: "checkmark")
                                .foregroundStyle(.tint)
                        }
                    }
                }
                .foregroundStyle(.primary)
            }

            if !trimmedSearchText.isEmpty, !hasExactMatch {
                Button {
                    addTag()
                } label: {
                    Label("'\(trimmedSearchText)' 새 태그로 추가", systemImage: "plus.circle")
                }
            }
        }
        .searchable(text: $searchText, prompt: "태그 검색")
        .navigationTitle("태그 선택")
        .navigationBarTitleDisplayMode(.inline)
        .overlay {
            if allTags.isEmpty {
                ContentUnavailableView {
                    Label("태그가 없어요", systemImage: "tag")
                } description: {
                    Text("검색창에 태그명을 입력해 새로 추가해보세요.")
                }
                .allowsHitTesting(false)
            }
        }
    }

    private func toggle(_ tag: Tag) {
        if selection.contains(tag) {
            selection.remove(tag)
        } else {
            selection.insert(tag)
        }
    }

    private func addTag() {
        guard !trimmedSearchText.isEmpty else { return }
        let tag = Tag(name: trimmedSearchText)
        modelContext.insert(tag)
        selection.insert(tag)
        searchText = ""
    }
}
