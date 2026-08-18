# 운동 기록 가져오기(Import) JSON 포맷

관리 탭의 "운동 기록 가져오기"에서 읽는 파일 포맷이다. FR-22 참고.

이 포맷은 [FR-17](./functional-spec.md)/[FR-18](./functional-spec.md)이 정의하는, 앱이 자신의 백업
파일을 되읽는 왕복 전용 포맷과는 다르다 — 이 포맷은 **사용자가 직접 작성해서 새로운
세션을 앱에 처음 들여오는** 용도다.

## 최상위 구조

```json
{
  "sessions": [ /* ImportSession 배열, 1개 이상 */ ]
}
```

## ImportSession

| 필드 | 타입 | 필수 | 설명 |
|---|---|---|---|
| date | String | O | `yyyy-MM-dd` 형식 (예: `"2026-08-18"`) |
| notes | String? | - | 세션 메모 |
| parts | [ImportPart] | O | 1개 이상 |

## ImportPart

| 필드 | 타입 | 필수 | 설명 |
|---|---|---|---|
| format | String | O | `WorkoutFormat` rawValue: `emom`/`amrap`/`forTime`/`interval`/`rounds`/`strength` |
| timeCapSeconds | Int? | - | 타임캡(초) |
| groups | [ImportGroup] | O | 1개 이상 |

## ImportGroup

블록이 1개면 스트레이트 세트, 2개 이상이면 서킷이다 ([FR-20](./functional-spec.md) 참고).

| 필드 | 타입 | 필수 | 설명 |
|---|---|---|---|
| rounds | Int? | - | 반복 라운드 수 (생략 시 1) |
| blocks | [ImportBlock] | O | 1개 이상 |

## ImportBlock

| 필드 | 타입 | 필수 | 설명 |
|---|---|---|---|
| exercise | String | O | 종목명. 카탈로그에 이름이 있으면(대소문자 무시) 재사용, 없으면 새로 생성 |
| weight | Double? | - | 무게 |
| weightUnit | String? | - | `WeightUnit` rawValue: `lb`/`kg` |
| reps | Int? | - | 반복수 |
| repsUnit | String? | - | `RepsUnit` rawValue: `count`(회, 기본값)/`calorie`(cal)/`meter`(m). ([FR-21](./functional-spec.md)) |
| restSeconds | Int? | - | 휴식시간(초) |
| tags | [String]? | - | 태그명 배열. 카탈로그에 이름이 있으면 재사용, 없으면 새로 생성 |

## 검증과 원자성

가져오기 전 전체 파일을 검증한다 — 날짜 형식, `format`/`weightUnit`/`repsUnit` rawValue 유효성,
파트/그룹/블록이 각각 1개 이상 있는지. 하나라도 실패하면 **아무 데이터도 생성되지 않는다**.

## 예시

웜업(RDL 45lb×10회 + Reverse Lunges 45lb×20회, 3라운드)과
WOD(Bar over burpee 20회 + Wallball 20lb×15회 + Deadlift 135lb×20회 + Row 40cal, 3라운드):

```json
{
  "sessions": [
    {
      "date": "2026-08-18",
      "parts": [
        {
          "format": "rounds",
          "groups": [
            {
              "rounds": 3,
              "blocks": [
                { "exercise": "Rumanian Deadlift", "weight": 45, "weightUnit": "lb", "reps": 10, "tags": ["웜업"] },
                { "exercise": "Reverse Lunges", "weight": 45, "weightUnit": "lb", "reps": 20, "tags": ["웜업"] }
              ]
            }
          ]
        },
        {
          "format": "rounds",
          "groups": [
            {
              "rounds": 3,
              "blocks": [
                { "exercise": "Bar over burpee", "reps": 20, "tags": ["본운동"] },
                { "exercise": "Wallball Shot", "weight": 20, "weightUnit": "lb", "reps": 15, "tags": ["본운동"] },
                { "exercise": "Deadlift", "weight": 135, "weightUnit": "lb", "reps": 20, "tags": ["본운동"] },
                { "exercise": "Row", "reps": 40, "repsUnit": "calorie", "tags": ["본운동"] }
              ]
            }
          ]
        }
      ]
    }
  ]
}
```
