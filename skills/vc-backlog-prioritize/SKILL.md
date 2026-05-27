---
name: vc-backlog-prioritize
description: Jira 백로그(미닫힘 항목)를 읽어 MoSCoW/RICE/WSJF로 점수화하고 우선순위·랭크·라벨을 갱신, PLAN 후보 마크다운 생성. Trigger when user says "백로그 우선순위", "prioritize backlog", "jira priority", "랭킹", "RICE", "WSJF".
---

# vc-backlog-prioritize — Jira Backlog Prioritization

> **vibecode_base 방법론 Phase 0d (PLAN의 입력)** 자동화.
> 참조: `~/workspace/vibecode_base/docs/07-product-planning.md`

## 1. Triggers
- "백로그 우선순위 매겨줘"
- "jira prioritize"
- "RICE 점수로 정리"
- "rerank backlog"
- "PLAN 후보 만들어"

## 2. Inputs
- `JIRA_PROJECT_KEY` (env 또는 인자)
- 점수 모델 (택1, 기본 `MoSCoW`):
  - `MoSCoW` — Must/Should/Could/Won't (label로 매핑)
  - `RICE` — Reach × Impact × Confidence / Effort (custom field 또는 댓글)
  - `WSJF` — (Business Value + Time Criticality + Risk Reduction) / Job Size
- `./prioritization.config.yaml` (선택) — 모델 가중치·임계값

## 3. Procedure

### Step A — Fetch
JQL: `project = <KEY> AND statusCategory != Done`
- 필드: summary, type, status, story points, priority, labels, custom fields(business value, time criticality...), components, due date.
- 결과를 `./jira/snapshot-<date>.json`로 저장(감사 추적).

### Step B — Score (`product-analyst`, sonnet)
입력 데이터로 모델별 점수 계산:
- **MoSCoW**: AC 키워드·고객 가치 평가 → enum 할당. Must ≤ 40% 강제 분포.
- **RICE**: Reach·Impact·Confidence는 모델 추정 + 사람 검토 후보, Effort는 Story Points.
- **WSJF**: 1·3·5·8·13 Fibonacci 스케일로 각 컴포넌트.

신뢰도 < 60% 항목은 `needs-pm-review` 라벨 자동 부착.

### Step C — Rank
점수 내림차순 정렬. 동점 시 의존성 그래프상 *블로커가 적은 것* 우선.
- 순위 1~10: `Ready` 후보
- 11~30: `Funnel`
- 31+: `Backlog` (보류)

### Step D — Jira Update (idempotent)
- Priority field 또는 label `priority:<rank>` 갱신.
- 점수 산출 근거를 Jira 댓글로 1줄: *"RICE 9.2 = (1000×3×0.7)/228, by vc-backlog-prioritize"*
- Status 전환은 *제안만* — 실제 전환은 사람.

### Step E — PLAN 후보 출력
`./PLAN-candidate.md` 생성:
- 상위 20개 Story 표(랭크·점수·근거)
- 의존성 그래프(Mermaid)
- 마일스톤 묶음 *제안* (팀 용량 K 인-주 입력 시)
- `vc-arch-from-jira` 또는 사람 PLAN 작성으로 이어짐

## 4. Output
- `./jira/snapshot-<date>.json` (감사용 스냅샷)
- `./PLAN-candidate.md` (사람이 확정해 `PLAN.md`로 옮김)
- Jira 항목의 priority/label 갱신
- 변경 요약: created/updated/skipped 카운트

## 5. Guardrails
- **자동 Status 전환 금지** — 제안만.
- **Won't 항목 점수화 금지** — 다음 사이클에서 재평가.
- **신뢰도 낮은 점수는 라벨로 표시** — PM 검토 후 확정.
- 점수 모델 변경 시 *과거 댓글 보존* (감사 추적).

## 6. Cost & Time (200 Story 기준)
- 토큰: ~25k (sonnet 단발)
- 시간: 3분(자동) + 사람 검토 30분

## 7. When NOT to use
- 백로그 < 10개 — 사람이 5분에 끝낸다.
- 점수 모델을 합의하지 않은 팀 — 결과의 신뢰도 0.

## 8. Next Step
점수가 매겨진 백로그를 받아 `vc-arch-from-jira`로 아키텍처 결정 → 그다음 `vc-tdd-redgen`.

## 9. References
- `~/workspace/vibecode_base/docs/07-product-planning.md`
- Mountain Goat — MoSCoW Prioritization
- Sean McBride — RICE: simple prioritization (Intercom)
- SAFe — WSJF (Weighted Shortest Job First)
