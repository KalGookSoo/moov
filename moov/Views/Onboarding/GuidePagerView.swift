//
//  GuidePagerView.swift
//  moov
//

import SwiftUI

/// 온보딩(FR-14)과 업데이트 안내(FR-15)가 공유하는 페이지 넘김 컴포넌트.
struct GuidePagerView: View {
    let pages: [OnboardingPage]
    var finishButtonTitle: String = "시작하기"
    var showsSkip: Bool = true
    let onFinish: () -> Void

    @State private var currentIndex = 0

    private var isLastPage: Bool { currentIndex >= pages.count - 1 }

    var body: some View {
        VStack(spacing: 0) {
            if showsSkip {
                HStack {
                    Spacer()
                    Button("건너뛰기") { onFinish() }
                        .opacity(isLastPage ? 0 : 1)
                        .disabled(isLastPage)
                }
                .padding()
            }

            TabView(selection: $currentIndex) {
                ForEach(Array(pages.enumerated()), id: \.offset) { index, page in
                    GuidePageContentView(page: page)
                        .tag(index)
                }
            }
            .tabViewStyle(.page(indexDisplayMode: pages.count > 1 ? .always : .never))

            Button {
                if isLastPage {
                    onFinish()
                } else {
                    withAnimation { currentIndex += 1 }
                }
            } label: {
                Text(isLastPage ? finishButtonTitle : "다음")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)
            .padding()
        }
        .onAppear {
            // 콘텐츠가 비어 있으면(예: 대기 중인 업데이트 노트가 없음) 빈 화면 대신 즉시 종료한다.
            if pages.isEmpty { onFinish() }
        }
    }
}

private struct GuidePageContentView: View {
    let page: OnboardingPage

    var body: some View {
        VStack(spacing: 20) {
            Spacer()
            Image(systemName: page.systemImage)
                .font(.system(size: 72))
                .foregroundStyle(.tint)
            Text(page.title)
                .font(.title.bold())
            Text(page.description)
                .font(.body)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)
            Spacer()
            Spacer()
        }
    }
}

#Preview {
    GuidePagerView(pages: OnboardingContent.pages) {}
}
