---
name: mv-sprint-retro
description: 스프린트 종료 시 Jira에서 Story 완료율·점수 추정 vs 실제·블로커·ADR 변경을 모아 회고 마크다운을 생성하고 다음 스프린트 용량/PLAN.md를 보정. Trigger when user says "스프린트 회고", "sprint retro", "velocity 분석", "회고", "다음 스프린트 용량".
---

# mv-sprint-retro — Sprint Retrospective & Velocity Calibration

> **vibecode_base 방법론의 학습 루프**.
> Story Points 추정/실제 차이를 다음 PLAN에 *수치적으로* 반영. 인상비평 아닌 데이터 기반.
> 참조: `~/workspace/vibecode_base/docs/07-product-planning.md`, `docs/06-checklists.md` §7

## 1. Triggers
- "스프린트 회고"
- "sprint retro"
- "velocity 분석"
- "다음 스프린트 용량"
- "PLAN 보정"

## 2. Inputs
- 스프린트 식별자 (예: `S-2026.05-2`) 또는 `current` / `last`
- `JIRA_PROJECT_KEY`
- 옵션: 이전 스프린트 retro (`./retro/<previous>.md`) — 추세 비교용

## 3. Procedure

### Step A — 데이터 수집 (`product-analyst`, sonnet)
JQL: `project = <KEY> AND sprint = "<sprint-id>"`
모으는 데이터:
1. Story 목록 + 상태 (Done/Carried-over/Removed)
2. Story Points 추정(시작 시) vs 실제 작업일(머지 SHA 시간 차이 또는 IN_PROGRESS→DONE 전이)
3. 댓글에서 *블로커 키워드*("blocked by", "waiting on") 추출
4. 머지된 PR 통계(파일 수, LOC, 리뷰 라운드, FAIL 횟수)
5. `adr/` 디렉터리의 *이번 스프린트 동안 추가/변경된 ADR* 수와 제목
6. `mv-incident-to-test`로 처리된 사고 수와 Sev

### Step B — 지표 계산
- **Completion rate** = Done / (Planned)
- **Velocity** = Done Story Points 합
- **Estimate accuracy** = median(|actual_days - SP×day_per_SP|/SP) — 낮을수록 추정 잘함
- **Carry-over rate** = Carried / Planned
- **Cycle time** (median): In Progress → Done까지 시간
- **PR rounds** (median): 머지까지 리뷰 라운드 수
- **Defect escape**: 같은 스프린트 머지 후 *다음 스프린트에 hotfix 발생한 Story 수*

### Step C — 회고 노트 작성 (`writer`, sonnet)
파일: `./retro/<sprint-id>.md`

구조:
```markdown
# Retro — <Sprint>

## TL;DR
3줄 요약. Velocity X, Completion Y%, Top blocker Z.

## Metrics
| 지표 | 이번 | 지난 | 추세 |
| Velocity | 38 | 32 | ▲ |
| Completion | 86% | 72% | ▲ |
| Estimate error | 18% | 24% | ▼ (개선) |
...

## What went well
- ...
- ...

## What didn't
- ...
- ...

## Blockers (Jira 댓글 기반)
| Issue | Blocker | Resolution | Days lost |

## ADR Delta
- 추가됨: ADR-012, ADR-013
- Supersede: ADR-008 → ADR-014
- 미반영(ARCHITECTURE.md 갱신 필요): …

## Action Items (다음 스프린트)
| AI | 책임 | 기한 |
- AI1: …

## Next Sprint Capacity (계산 근거)
- 가용 인-주: 2.0
- 5일/주 × 0.8(버퍼) = 8 인-일/주 → 16 인-일
- 환산 SP (1 SP ≈ 0.5d) → ~32 SP
- 안정 Velocity 기반 권장: **30 SP**
```

### Step D — PLAN.md 자동 보정 (옵션)
- 다음 스프린트 PLAN의 §3 Capacity 칸에 권장 SP 자동 채움.
- Carry-over Story를 우선 배치.
- *적용 전 사람 확인* 요청.

### Step E — Jira 정리
- 스프린트 *Close*. 미완 Story는 다음 스프린트로 이동(라벨 `carried-over`).
- `current` 라벨을 다음 스프린트로 옮김.
- 회고 노트 링크를 스프린트 종료 댓글로.

## 4. Output
- `./retro/<sprint-id>.md` (구조화된 회고)
- 보정된 `./PLAN.md` 후보(사람 확인 필요)
- Jira 스프린트 종료 + 캐리오버 처리
- (선택) 팀 채널에 TL;DR 공유 메시지

## 5. Guardrails
- **개인 비난 금지.** 데이터·시스템 관점만.
- **자동 PLAN 덮어쓰기 금지.** 보정안은 *제안*.
- **이상치 1건이 통계 왜곡 시** 명시(예: 사고 1건이 cycle time 평균을 2배로).
- **개인 데이터(이름·시간 등)**는 회고에서 *최소화*. 시스템 관점.

## 6. Cost & Time
- 토큰: ~20k (분석 sonnet + writer sonnet)
- 시간: 10분(자동) + 팀 회고 미팅 30분

## 7. Chains
- 선행: `mv-verify-merge` (스프린트 동안 머지된 Story들)
- 후행: 다음 사이클의 `mv-backlog-prioritize` 입력으로

## 8. When NOT to use
- 진행 중인 스프린트 — 데이터 미완. 종료 후.
- 스프린트 운영 안 하는 칸반 — *주간/월간 회고*로 트리거 키워드 바꿔 사용.

## 9. References
- `~/workspace/vibecode_base/docs/07-product-planning.md`
- Esther Derby & Diana Larsen — *Agile Retrospectives*
- DORA — Four Keys (deploy freq, lead time, MTTR, change fail rate)
