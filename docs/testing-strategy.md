# moov 테스트 전략

`moovTests`(유닛)/`moovUITests`(UI)가 Xcode 템플릿 상태 그대로 비어 있던 것을 채우기 위한 계획이다. architecture.md의 "미해결 사항"을 해소한다.

## 현재 상태 진단

architecture.md는 애초에 "집계·계산이 필요한 화면은 별도 타입으로 분리해 유닛 테스트 대상으로 삼는다"는 원칙을 세워뒀다. 하지만 실제 구현(히스토리, PR 화면)에서는 이 계산 로직을 View 구조체 안의 `private` 계산 프로퍼티로 그대로 넣어, 지금은 이 원칙과 어긋나 있다. 즉 아래 로직들이 **현재는 View를 인스턴스화하지 않고는 테스트할 수 없다**:

| 로직 | 현재 위치 |
|---|---|
| PR 갱신 여부(누적 최댓값 기준) 판정 | `PersonalRecordHistoryView.timeline` (private) |
| 태그별 주간 볼륨/빈도 집계 | `TagAggregateView.weeklyBuckets` (private) |
| 종목별 기록 정렬/매칭 | `ExerciseHistoryView.entries` (private) |

`String+Version.swift`의 버전 비교만 이미 순수 함수라 바로 테스트 가능하다.

## 유닛 테스트 (`moovTests`, Swift Testing)

**선행 작업**: 위 세 계산 로직을 View 밖의 독립 타입/함수로 추출한다. SwiftData `@Model` 인스턴스를 파라미터로 받는 순수 함수 형태면 충분하며, `@Observable` ViewModel까지는 필요 없다(계산 결과를 뷰가 바로 읽기만 하면 되므로).

- `PRTimelineEntry`/`PRTimelineCalculator` — `[PersonalRecord]` → 갱신 여부가 표시된 타임라인
- `WeeklyAggregation` — `[ExerciseBlock]` + 기준 태그 → 주별 (볼륨, 빈도) 집계
- `ExerciseHistoryEntry` — `[ExerciseBlock]` → 세션 날짜 기준 정렬된 항목

추출 후 우선순위:

1. `String.isVersion(greaterThan:)` — 상위/동일/하위/빈 문자열 비교
2. PR 타임라인 계산 — 여러 기록 중 어느 시점이 "갱신"으로 표시되는지 (오름차순 입력에서도 최댓값 갱신 시점만 true)
3. 태그 주간 집계 — 같은 주/다른 주에 걸친 기록의 볼륨(세트×렙 합)·빈도 합산
4. 종목/태그 삭제 시 `exerciseName` 스냅샷 유지 — 인메모리 `ModelContainer`로 Exercise 삭제 후 기존 `ExerciseBlock.exerciseName`이 남아있는지 확인 (SwiftData 통합 테스트)
5. `WorkoutTemplate` → 세션 적용 복사 로직(`SessionFormView.applyTemplate`) — 파트/블록 수, 태그가 올바르게 복사되는지, 삭제된 종목을 참조하는 블록은 건너뛰는지

4, 5번은 SwiftData 모델을 직접 다루는 통합 테스트 성격이라 `ModelContainer(for:, isStoredInMemoryOnly: true)`를 매 테스트마다 새로 만드는 공통 헬퍼가 필요하다.

## UI 테스트 (`moovUITests`, XCTest)

전체 화면 조합을 다 훑지 않고, 회귀가 가장 아플 핵심 플로우만 커버한다.

1. 최초 실행 → 온보딩 자동 표시 → 마지막 페이지에서 "시작하기" → 메인 탭 진입
2. 세션 생성 → 파트 추가 → 블록 추가(종목 즉석 추가 포함) → 저장 → 목록에 반영
3. PR 등록 → 기존 PR보다 낮은 값 입력 → 경고 다이얼로그 → 확정 저장

## 컨벤션

- 유닛 테스트는 Xcode가 이미 스캐폴딩한 대로 **Swift Testing**(`import Testing`, `@Test`, `#expect`)을 쓴다. XCTest로 되돌리지 않는다.
- UI 테스트는 템플릿대로 XCTest 유지(Swift Testing은 아직 UI 테스트 공식 지원 전).
- 인메모리 `ModelContainer` 생성 헬퍼를 `moovTests` 내 공용 파일로 두어 테스트마다 중복 작성하지 않는다.

## 다음 단계

이 문서대로 진행하려면 먼저 위 "선행 작업"(계산 로직 추출)을 해야 한다. 진행할까요?
