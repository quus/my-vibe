---
name: mv-tdd-redgen
description: Jira에서 가장 우선순위 높은 미닫힘 Story 1개를 픽업해 AC별 실패 테스트(RED)를 생성·실행해 실패를 확인. Trigger when user says "다음 스토리 테스트", "tdd red", "실패 테스트 만들어", "story → tests", "AC 테스트 생성".
---

# mv-tdd-redgen — Jira Story → Failing Tests (RED)

> **vibecode_base 방법론 Phase 4 IMPL의 RED 단계** 자동화.
> 참조: `~/workspace/vibecode_base/docs/10-tdd-cycle.md` §2

## 1. Triggers
- "다음 스토리 테스트 만들어"
- "tdd red"
- "AC를 테스트로"
- "story → tests"
- "실패 테스트 생성"

## 2. Inputs
- 옵션 A: Jira Story Key 명시 (예: `PROJ-101`)
- 옵션 B: 자동 픽업 — `status=Ready AND assignee=currentUser()` 중 priority 최상위 1개

## 3. Procedure

### Step A — Pick & Fetch
1. Jira에서 Story 1건 선택(위 규칙).
2. Status: `Ready` → `In Progress` 전환.
3. 본문·AC·§4 Test Plan 표를 로컬 `./jira/stories/<KEY>.md`로 동기화(있으면 덮어쓰기).

### Step B — AC 검증
- AC가 *자동 테스트 가능한* Given/When/Then 형식인지.
- §4 Test Plan 표가 채워졌는지.
- 미충족 시 *RED 진행 중단*하고 사람에게 "Story §4 보강 필요" 알림.

### Step C — Test Generation (`test-engineer`, sonnet)
프롬프트:
```
Story <KEY>의 §4 Test Plan의 *RED 우선순위 1번부터 모두*에 대해
실패하는 테스트를 작성하라.
규칙:
- 공개 인터페이스만 호출. private/내부 모킹 금지.
- 외부 의존(시간/네트워크/랜덤)은 인터페이스 경계에서만 모킹.
- 각 테스트의 docstring/주석에 "AC: <KEY>#AC<N>" 키 명시.
- 한 테스트당 한 가지 동작.
- 파일 위치: ARCHITECTURE.md의 컨테이너 경계에 맞춰.
출력: 변경된 파일 목록 + 마지막 테스트 실행 출력 20줄.
구현 코드는 절대 만들지 말 것.
```

### Step D — 실행 & 검증
1. 프로젝트의 표준 테스트 명령(`npm test` / `pytest -q` / `go test ./...`) 실행.
2. *생성된 테스트만 실패*하고 *기존 테스트는 모두 통과*해야.
3. 그렇지 않으면 — 기존 회귀 → 즉시 알리고 사람 개입.

### Step E — 추적성 기록
- Jira Story에 댓글: *"RED tests created: tests/dashboard.spec.ts (AC1~AC4), all failing as expected. Branch: <branch-name>"*
- `./tdd-log/<KEY>.md`에 RED 출력 기록.

## 4. Output
- 신규 또는 갱신된 테스트 파일들 (구현 0줄)
- 실패 출력 캡처 `./tdd-log/<KEY>-red.txt`
- Jira 댓글 + Status `In Progress`

## 5. Guardrails
- **구현 코드 작성 금지.** RED 단계는 *테스트만*.
- **기존 테스트 회귀 발생 시 중단**. 모르는 사이드 이펙트를 만들지 말 것.
- **모킹 한계**: 자기 모듈의 인터페이스에만. 라이브러리 내부 모킹 금지.
- AC 1개에 테스트 1개 이상. 0개면 *그 AC를 보강*하라.

## 6. Cost & Time
- 토큰: ~12k (Story 1개 · sonnet)
- 시간: 3~10분

## 7. Chains
- 선행: `mv-backlog-prioritize`(Ready 후보가 있어야), `mv-arch-from-jira`(영향 컨테이너 안내)
- 후행: `mv-tdd-impl` (GREEN+REFACTOR)

## 8. When NOT to use
- Story의 AC가 *행동*이 아닌 *기능 명사*("필터가 있다") — 먼저 SPEC 보강.
- 다음 Story가 이전 Story의 산출물에 의존하는데 이전 Story가 *Done* 아님 — 의존 해결 먼저.

## 9. References
- `~/workspace/vibecode_base/docs/10-tdd-cycle.md`
- Kent Beck — Test-Driven Development by Example
