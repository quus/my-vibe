---
name: vc-tdd-impl
description: Git worktree에서 격리된 환경으로 TDD GREEN→REFACTOR를 진행. ARCHITECTURE.md의 컴포넌트 경계와 코딩 컨벤션을 지키며 최소 코드로 실패 테스트를 통과시킨 뒤 정리. Trigger when user says "tdd green", "구현 시작", "worktree 구현", "impl story", "GREEN 단계".
---

# vc-tdd-impl — Worktree-Based TDD Implementation (GREEN + REFACTOR)

> **vibecode_base 방법론 Phase 4 IMPL의 GREEN/REFACTOR 단계** 자동화. RED 테스트가 이미 존재해야 시작.
> 참조: `~/workspace/vibecode_base/docs/10-tdd-cycle.md` §3·§4

## 1. Triggers
- "tdd green 진행"
- "구현 시작"
- "worktree 만들고 구현"
- "impl story PROJ-101"
- "GREEN 단계"

## 2. Preconditions
- 해당 Story의 RED 테스트가 *존재하고 실패*하는 상태(보통 `vc-tdd-redgen` 직후).
- `./ARCHITECTURE.md` 와 `./docs/coding-conventions.md`(또는 동등) 존재.

## 3. Inputs
- Jira Story Key (예: `PROJ-101`)
- 옵션: 기준 브랜치(기본 `main`), worktree 위치(기본 `../wt-<KEY>`)

## 4. Procedure

### Step A — Worktree 생성
```bash
git fetch origin
BRANCH="feature/<KEY>-<slug>"
git worktree add ../wt-<KEY> -b "$BRANCH" origin/main
cd ../wt-<KEY>
<install: pnpm i | uv sync | go mod download>
```

### Step B — 컨벤션·아키텍처 컨텍스트 로드
- `./ARCHITECTURE.md` 의 §4 Components 표에서 *영향 받는 컴포넌트* 확인.
- `./docs/coding-conventions.md` 의 핵심 규칙 5개를 메모.
- Story `Architecture Touchpoints` 메타와 일치하는지 점검.

### Step C — GREEN (`executor`, sonnet)
프롬프트:
```
당신은 executor(sonnet).
목표: ./tests/... 의 RED 테스트를 통과시켜라. 다른 변경 금지.
입력: ./jira/stories/<KEY>.md, ./ARCHITECTURE.md, ./docs/coding-conventions.md
규칙:
- 테스트 코드는 *읽기만*, 수정 금지.
- 새 모듈은 ARCHITECTURE의 컴포넌트 경계 안에 둔다.
- 함수 ≤ 20줄, 인자 ≤ 3개, 주석은 *왜*만.
- 외부 의존성 추가 시 — *멈추고* 사람에게 확인.
- 통과 후 *전체 테스트*를 돌려 회귀 0 확인.
출력: 변경 파일 목록 + 마지막 테스트 출력 요약 (pass/fail 카운트).
설명·정당화 금지.
```

### Step D — REFACTOR (`quality-reviewer`, sonnet)
프롬프트:
```
당신은 quality-reviewer(sonnet).
방금 GREEN 코드를 정리하라.
규칙:
- 테스트 파일은 *읽기만*. 수정 금지.
- 외부 동작 변경 금지 — 전체 테스트가 여전히 그린이어야.
- ./docs/coding-conventions.md 위반 제거.
- 중복 3회 이상이면 추출. 책임 혼합(I/O+계산)이면 분리.
출력: 정리한 항목 5개 이내(짧게).
```

### Step E — 다음 AC로
RED 테스트가 아직 더 있으면 *C·D를 다시*. 모든 AC GREEN 시 종료.

### Step F — 커밋 & PR 후보
```bash
git add -A
git commit -m "<KEY>: <story title> (GREEN+REFACTOR)

- AC1..N 모두 통과
- 영향: <containers>
- ADR: <NNN-…> 참조 (있다면)

Co-Authored-By: Claude Sonnet 4.6 <noreply@anthropic.com>"
git push -u origin "$BRANCH"
```

Jira 댓글: 브랜치명·커밋 SHA·통과 테스트 수.

### Step G — Worktree 정리 (옵션)
PR 머지 후:
```bash
cd <원래 경로>
git worktree remove ../wt-<KEY>
git branch -d "$BRANCH"
```

## 5. Output
- worktree 경로 (활성 브랜치)
- 변경된 코드(테스트 무수정), 회귀 0
- 커밋 1개 (또는 단위별 분할)
- Jira 댓글 + 브랜치 push

## 6. Guardrails
- **테스트 수정 금지.** RED가 잘못이라 판단되면 *멈추고* 사람에게 보고 → `vc-tdd-redgen` 재실행.
- **새 의존성·새 외부 시스템은 멈추고 확인.** ADR 없이 묻어가지 말 것.
- **한 AC 사이클 2시간 또는 5턴 초과 시 정지.** Story가 너무 큼 → 분할.
- **worktree 격리 보존**. 본 레포에서 직접 작업 금지.

## 7. Cost & Time (Story 5 SP)
- 토큰: ~30k (sonnet)
- 시간: 30분~2시간 (AC 수에 따름)

## 8. Chains
- 선행: `vc-tdd-redgen` (RED 테스트 필요)
- 후행: `vc-pr-review` → `vc-verify-merge`

## 9. When NOT to use
- RED 테스트가 없거나 통과 중인 상태 — `vc-tdd-redgen` 먼저.
- 빌드 자체가 안 됨 — `oh-my-claudecode:build-fix` 또는 `build-fixer`로 선행.

## 10. References
- `~/workspace/vibecode_base/docs/10-tdd-cycle.md`
- `~/workspace/vibecode_base/docs/03-coding-conventions.md`
- Git worktree docs — `git help worktree`
