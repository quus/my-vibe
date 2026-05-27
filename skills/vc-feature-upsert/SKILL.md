---
name: vc-feature-upsert
description: Requirements MD(또는 bullet 한 줄짜리)를 읽어 Epic/Feature/Story로 자동 확장하고 Jira에 멱등(upsert) 동기화. Trigger when user says "요구 등록", "feature upsert", "기능 등록", "백로그 확장", "jira에 등록".
---

# vc-feature-upsert — Requirements → Jira Upsert

> **vibecode_base 방법론 Phase 0a~0c**를 1회 호출로 실행한다.
> 참조: `~/workspace/vibecode_base/docs/08-feature-expansion.md`

## 1. Triggers (한국어 + 영어)
- "요구사항을 jira에 올려줘"
- "feature upsert"
- "기능 목록 확장해서 등록"
- "feature list를 jira로"
- "backlog upsert"

## 2. Inputs (둘 중 하나는 필수)
- `./input.md` — bullet 한 줄 또는 자유 텍스트 요구사항. **가장 가볍게 시작할 때**.
- `./FEATURES.md` — `templates/FEATURES.md.template` 형식의 정형 백로그. **이미 있으면 이것**.

## 3. Required env
- `JIRA_BASE_URL` (예: `https://acme.atlassian.net`)
- `JIRA_EMAIL`, `JIRA_API_TOKEN` *(절대 코드에 하드코딩 금지)*
- `JIRA_PROJECT_KEY` (예: `SI`)

MCP `mcp__atlassian` 가 활성화되어 있으면 우선 사용. 없으면 REST.

## 4. Procedure (4-Step, idempotent)

### Step A — Normalize
입력이 `input.md`이면 `templates/FEATURES.md.template` 형식으로 정형화.
- bullet 1개 = Feature 1행. ID는 `F-001`부터 자동 채번.
- Theme 최대 5개로 묶기. Priority 미상이면 `Should`. Size 추정(`XL` 금지).
- 결과: `./FEATURES.md` (이미 있으면 *변경분만 머지*, 기존 ID 보존).

### Step B — Theme → Epic 확장 (`analyst`, opus 1회)
- `FEATURES.md`의 Theme N개 → Epic N개.
- 파일: `jira/epics/<theme-slug>.md` (템플릿: `templates/EPIC.md.template`).
- 외부 ID = `vibecode-epic-<theme-slug>`. 같은 ID 존재 시 *업데이트만*.

### Step C — Feature → Story 확장 (`analyst`, opus 1회)
- Feature 1개 → 1~5 Story (≤ 8 Story Points).
- 파일: `jira/stories/<F-NNN>-<NN>-<slug>.md` (템플릿: `templates/STORY.md.template`).
- 외부 ID = `vibecode-story-<F-NNN>-<NN>`.
- **AC와 §4 Test Plan 표 필수 채움**(TDD 진입점).

### Step D — Jira Upsert (멱등)
1. 외부 ID로 기존 Issue 조회 (label `external-id:<id>` 또는 custom field).
2. 없으면 `POST /rest/api/3/issue` — Epic 먼저, Story 후.
3. 있으면 `PUT /rest/api/3/issue/<key>` — 본문/AC/SP/라벨만 갱신. Status는 *건드리지 않음*.
4. 의존성: `addBlockedBy` → Jira `is blocked by` issue link.
5. 생성/갱신된 Key를 각 파일의 메타 `Jira Key:` 에 기입해 *다시 저장*.

## 5. Output
- `./FEATURES.md` (정형화/머지된 백로그)
- `./jira/epics/*.md` (Jira Key 회신됨)
- `./jira/stories/*.md` (Jira Key 회신됨)
- `./jira/sync-report.md` — created N · updated M · skipped K · errors E
- 실제 Jira Epic/Story 생성 또는 업데이트

## 6. Guardrails
- **사람 검토 게이트**: 자동 생성 결과는 모두 `Funnel` 상태로 시작. `Ready` 전환은 사람.
- **하드 실패**: 비밀 토큰이 git-tracked 파일에 들어가면 즉시 중단.
- **Won't 항목**: Jira에 만들지 *않음*. `FEATURES.md`에만 기록.
- **중복 ID**: 외부 ID 충돌 시 *업데이트*로 처리(생성 금지).

## 7. Cost & Time (대략 3 Theme · 12 Feature)
- 토큰: ~42k (Step B opus 8k + Step C opus 25k + sonnet 9k)
- 시간: 2분(자동) + 사람 검토 60~90분

## 8. When NOT to use
- 단일 버그 픽스 또는 1~2개 작은 Story — 직접 Jira UI가 빠르다.
- 백로그가 이미 잘 정리되어 있고 신규 추가 1~3건 — 직접 입력 권장.

## 9. References
- `~/workspace/vibecode_base/docs/08-feature-expansion.md` (전체 절차)
- `~/workspace/vibecode_base/templates/FEATURES.md.template`
- `~/workspace/vibecode_base/templates/EPIC.md.template`
- `~/workspace/vibecode_base/templates/STORY.md.template`
- Jira REST v3 — Issue API
