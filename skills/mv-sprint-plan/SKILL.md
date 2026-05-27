---
name: mv-sprint-plan
description: Jira 백로그 전체와 FEATURES.md를 읽어 응집도(같은 Epic·컴포넌트·의존성)와 우선순위로 묶고, 직전 스프린트 속도(velocity) 기반 용량 안에서 다음 스프린트를 구성. Jira Sprint 생성과 Story 할당까지. Trigger when user says "스프린트 계획", "sprint plan", "다음 스프린트", "스프린트 구성", "스프린트 짜", "넥스트 스프린트".
---

# mv-sprint-plan — Cohesive Sprint Planning

> *우선순위 점수가 매겨진 백로그를 받아, **응집도 높은 묶음**만 골라 한 스프린트로 구성한다.*
> 흩어진 작업을 모으는 게 아니라 *함께 가야 가치를 만드는* 작업을 모은다.
> 참조: `~/workspace/vibecode_base/docs/07-product-planning.md`

## 1. Triggers (한국어 + 영어)
- "다음 스프린트 짜줘"
- "sprint plan"
- "스프린트 구성"
- "next sprint"
- "스프린트 계획 수립"

## 2. Inputs
- `JIRA_PROJECT_KEY` (env)
- `JIRA_BOARD_ID` (env, 또는 자동 탐색)
- 스프린트 기간 (기본 2주)
- 팀 용량:
  - 자동: 직전 3개 스프린트의 *평균 velocity* (Jira 또는 `./retro/*.md`)
  - 수동: `--capacity-sp <N>` 또는 `--capacity-days <N>`
- 선택: 스프린트 시작일(기본: 다음 영업일), 스프린트 이름(`S-YYYY.MM-N` 자동 채번)

## 3. Procedure

### Step A — Fetch
JQL: `project = <KEY> AND sprint is EMPTY AND status in (Ready, Funnel) AND statusCategory != Done`
- 가져오는 필드: summary, parent Epic, components, labels, priority 점수, Story Points, blocked-by, persona, theme
- 스냅샷 저장: `./sprints/snapshot-<date>.json`

### Step B — 응집도 클러스터링 (`planner`, opus 1회)
Story들을 *함께 가야 하는* 단위로 묶는다. 가중 점수:

| 신호 | 가중치 | 설명 |
|---|---|---|
| 같은 Parent Epic | 0.40 | 가장 강한 신호 — 동일 비즈니스 결과 |
| 공유 Component | 0.25 | ARCHITECTURE.md의 같은 컨테이너/모듈 |
| 의존 그래프 인접 | 0.20 | blocked-by 체인 1-hop 이내 |
| 같은 Persona | 0.10 | 동일 사용자 흐름 |
| 같은 Theme/Label | 0.05 | 부가 신호 |

클러스터링:
- 단순 그래프 군집화(connected components → 가중 그래프에서 0.5 이상 엣지로 연결된 노드).
- 각 클러스터는 *demo-able outcome*을 가져야 — 데모 1줄이 안 나오면 클러스터 분할.

### Step C — 용량 계산
```
last_3_velocity_avg = mean([retro_S(N-1).done_sp, retro_S(N-2).done_sp, retro_S(N-3).done_sp])
capacity_sp = round(last_3_velocity_avg × 0.85)   # 15% 버퍼
```
이전 데이터가 없으면 manual 입력 강제. 첫 스프린트는 *팀 자기 평가*로 시작(보통 15~25 SP).

### Step D — 선택 알고리즘 (Greedy + WIP-aware)
1. 클러스터를 `(avg_priority × avg_cohesion)` 내림차순 정렬.
2. 위에서부터 순회하며:
   - 클러스터 합계 SP ≤ 남은 용량 → *전체* 포함.
   - 초과 → 클러스터를 *쪼개지 마라* (응집도 깨짐). 다음 클러스터로.
3. WIP 룰:
   - 한 Epic에 *동시 진행* Story ≤ 5
   - 한 사람당 SP ≤ team_avg × 1.2
4. 의존성 검증:
   - 선택된 Story의 `blocked-by`가 *이번 스프린트 내 또는 이미 Done* 이어야.
   - 이 조건 위반 시 → 그 Story를 *클러스터에서 제외*하고 사람 알림.

### Step E — Critical Path & Demo
- 선택된 Story들로 *마일스톤 데모* 시나리오 1개 작성:
  - "스프린트 끝에 사용자가 X를 할 수 있다"
- Critical path 표시: 의존성을 따라가는 가장 긴 체인. 지연 시 데모 실패.

### Step F — `./sprints/<sprint-id>.md` 생성
구조:
```markdown
# Sprint <id> — <theme>

## Goal (한 줄)
이 스프린트가 끝나면 사용자는 …

## Window
시작 YYYY-MM-DD · 종료 YYYY-MM-DD · <N>일

## Capacity
- 직전 velocity 평균: X SP
- 버퍼 15% 차감: 가용 Y SP
- 배정: Z SP (잔여 Y−Z SP)

## Selected Clusters
### Cluster 1 — <Epic 또는 묶음 이름> (응집도 0.78)
| Order | Story | Persona | SP | Owner |
| 1 | PROJ-101 ... | 사장님 | 3 | @alice |

### Cluster 2 — ...

## Critical Path
PROJ-101 → PROJ-103 → PROJ-110  (총 9 SP)

## Demo Plan
- 데모 시나리오: …
- 환경: staging

## Risks
| Risk | Mitigation |

## Excluded (다음 스프린트 후보)
- 클러스터 N: 우선순위는 높았으나 용량 초과
- Story X: blocked-by 미해결
```

### Step G — Jira Sync (멱등)
1. Sprint 생성 (또는 활성 sprint가 있으면 *추가 모드*인지 확인).
2. 선택된 Story들의 `Sprint` 필드를 새 스프린트로 설정.
3. Sprint start/end date 설정.
4. 모든 선택 Story 댓글: `"Selected for Sprint <id> by mv-sprint-plan: cluster=<name>, cohesion=<n>"`
5. Sprint 자체를 *Future*로 둠 — 사람이 *Start Sprint* 누르기 전까지 활성화 안 됨.

### Step H — 사람 사인오프 게이트
- `./sprints/<sprint-id>.md` 마지막에 Sign-off 표 추가:
  ```
  - 제품: ___ ✅ YYYY-MM-DD
  - 엔지니어링: ___ ✅ YYYY-MM-DD
  ```
- 사인오프 전 *Jira sprint 활성화 금지*.

## 4. Output
- `./sprints/<sprint-id>.md`
- `./sprints/snapshot-<date>.json`
- Jira: 새 Sprint(Future 상태) + Story 할당
- (옵션) `PLAN.md` 갱신 — 이번 스프린트 행 추가

## 5. Guardrails
- **응집도 < 0.5 묶음 거부** — 흩어진 작업을 한 스프린트에 욱여넣지 말 것.
- **데모 가능한 결과 없으면 거부** — 가시성 없는 스프린트는 무의미.
- **용량 초과 ≥ 10% 시 자동 중단** — 사람 결정 요청.
- **Won't 항목 자동 제외**.
- **WIP 초과 시 클러스터 일부만 선택**해서 다음 스프린트로 이월.
- **자동 Sprint Start 금지** — Future 상태로만 생성. Activate는 사람이.

## 6. Cost & Time
- 토큰: ~15k (opus, 응집도 분석 1회)
- 시간: 5분 자동 + 15~30분 팀 검토

## 7. Chains
- 선행: `mv-backlog-prioritize` (Story들이 점수화되어야), `mv-sprint-retro` (velocity 제공)
- 후행: `mv-tdd-redgen` (스프린트의 Story를 순차 픽업)

## 8. When NOT to use
- 칸반(no-sprint) 운영 — 대신 *상시 백로그 우선순위*에 의존.
- 스프린트 *진행 중*에 추가 — 이번 스프린트에 끼우려면 *1-in 1-out* 룰을 PM과 합의 후 직접 처리.
- Story 개수가 < 5 — 사람이 5분에 결정 가능.

## 9. 안티패턴

| 안티패턴 | 결과 |
|---|---|
| "용량 빈자리에 아무 Story나 채우기" | 응집도 0, 데모 불가능 |
| "고우선 Story만 모으기"(응집도 무시) | 5개 Epic이 동시 진행되어 컨텍스트 스위칭 폭증 |
| Sprint 자동 활성화 | 사람 검토 누락 → 잘못된 묶음으로 실행 |
| velocity 1회 데이터로 추정 | 노이즈 큼 — 최소 3개 스프린트 평균 |

## 10. References
- Mike Cohn — *Agile Estimating and Planning*
- Atlassian — [How to plan a sprint](https://www.atlassian.com/agile/scrum/sprint-planning)
- DORA — Four Keys (velocity는 핵심 지표 아님, *deploy frequency*와 *lead time*이 더 중요)
- `~/workspace/vibecode_base/docs/07-product-planning.md`
