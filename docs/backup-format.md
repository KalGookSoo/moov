# 백업 파일 포맷

관리 탭의 "데이터 내보내기"(FR-17)가 생성하고, "데이터 가져오기"(FR-18)가 되읽는
왕복 전용 JSON 포맷이다. 전체 엔티티를 ID 기반으로 직렬화해 관계를 그대로 복원할 수 있다.

이 포맷은 [import-format.md](./import-format.md)(FR-22, 사용자가 직접 작성하는 이름 기반
포맷)와는 다르다 — 이쪽은 앱이 스스로 생성/소비하는 백업용이라 종목/태그를 ID로 참조한다.

## 최상위 구조

```json
{
  "version": 1,
  "exportedAt": "2026-08-18T06:38:07Z",
  "exercises": [ /* BackupExercise */ ],
  "tags": [ /* BackupTag */ ],
  "sessions": [ /* BackupSession */ ],
  "personalRecords": [ /* BackupPersonalRecord */ ],
  "templates": [ /* BackupTemplate */ ]
}
```

날짜/시각은 ISO 8601(`yyyy-MM-dd'T'HH:mm:ssZ`)로 인코딩된다.

## 카탈로그

- **BackupExercise**: `id`, `name`, `category?`, `defaultWeightUnit?`(`lb`/`kg`)
- **BackupTag**: `id`, `name`, `colorHex?`

## BackupSession → BackupPart → BackupGroup → BackupBlock

세션은 `WorkoutSession → WorkoutPart → BlockGroup → ExerciseBlock` 구조를 그대로 따른다
([FR-20](./functional-spec.md) 참고 — 그룹의 블록 수가 스트레이트 세트/서킷을 구분).

- **BackupSession**: `id`, `date`, `notes?`, `conditionNotes`(`id`/`bodyPart?`/`painLevel?`/`memo`), `parts`
- **BackupPart**: `id`, `order`, `format`(`WorkoutFormat` rawValue), `timeCapSeconds?`, `result?`, `groups`
- **BackupResult**: `kind`(`ResultKind` rawValue), `timeSeconds?`, `rounds?`, `extraReps?`, `isCompleted?`, `maxWeight?`, `completionNote?`
- **BackupGroup**: `id`, `order`, `rounds`, `blocks`
- **BackupBlock**: `id`, `order`, `exerciseId?`, `exerciseName`, `weight?`, `weightUnit?`, `reps?`, `repsUnit?`([FR-21](./functional-spec.md)), `restSeconds?`, `tagIds`

`exerciseId`가 카탈로그의 `exercises` 배열에 없을 수도 있다(원본 종목이 삭제된 경우) —
이때도 `exerciseName` 스냅샷은 남아 있다.

## BackupPersonalRecord

`id`, `exerciseId?`, `exerciseName`, `weight`, `weightUnit`, `date`

## BackupTemplate

`WorkoutTemplate → TemplatePart → TemplateBlockGroup → TemplateBlock` 구조를 그대로
`BackupTemplate → BackupTemplatePart → BackupTemplateGroup → BackupTemplateBlock`로
직렬화한다(필드 구성은 세션 쪽과 동일하되 `result`가 없다).

## 가져오기(FR-18) 동작

`BackupImporter`가 이 포맷을 읽어 다음과 같이 반영한다.

- **종목/태그**: `exerciseId`/`tagIds`로 기존 카탈로그를 먼저 찾고, 없으면 이름(대소문자 무시)으로
  재매칭한다. 그래도 없으면 백업의 `id`를 그대로 써서 새로 만든다.
- **세션/PR/템플릿**: 병합(merge) 모드에서는 같은 `id`가 이미 존재하면 건너뛰어
  같은 백업을 실수로 두 번 가져와도 중복이 생기지 않는다. 교체(replace) 모드에서는
  가져오기 전에 기존 데이터를 모두 지운다.
- 블록/그룹/파트/PR의 `id`는 항상 백업 값 그대로 복원한다.
