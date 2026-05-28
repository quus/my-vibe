---
name: mv-sprint-plan
description: 스크럼 마스터가 PO·Architect·QA·Developer 서브에이전트와 함께 협업으로 다음 스프린트를 계획. 백로그 + 직전 회고 개선사항을 Feature/User Story로 리스트업하고, 응집도·우선순위·velocity 기반으로 묶어 사람 리뷰용 sprint-plan MD를 생성. Jira 반영은 mv-sprint-run이 담당. Trigger when user says "스프린트 계획", "sprint plan", "다음 스프린트", "스프린트 구성", "스프린트 짜", "넥스트 스프린트".
---

# mv-sprint-plan — Collaborative Sprint Planning (v2.0)

> **Sprint Planning은 스크럼 마스터 혼자가 아니라 팀 전체가 하는 회의다.**
> PO·Architect·QA·Developer 서브에이전트를 소환해 함께 계획하고, 스크럼 마스터가 종합한다.
> 산출물은 *사람 리뷰용 sprint-plan MD* — Jira 반영과 개발 착수는 `mv-sprint-run`이 담당.
>
> **v2.0 변경 사유**: v1.x에서 스크럼 마스터가 *혼자* 클러스터링·선택을 수행 → 기술적 실현 가능성(앱 셸 누락),
> 테스트 가능성, 실제 공수 검증이 빠진 채 계획이 확정되는 문제 발생. v2.0은 전 멤버 협업으로 이를 차단.

## 1. Triggers
- "스프린트 계획", "sprint plan", "다음 스프린트", "스프린트 구성", "스프린트 짜", "넥스트 스프린트"

## 2. 핵심 원칙 (v2.0)

1. **협업 계획 (Team Planning, not Solo)**
   - 스크럼 마스터는 *촉진자(facilitator)*이지 단독 결정자가 아니다.
   - PO(가치)·Architect(실현가능성)·QA(검증가능성)·Developer(공수)가 각자 관점으로 기여한다.

2. **회고 개선사항 → Feature 반영**
   - 직전 Sprint 회고의 *Improve/Try* 항목을 **이번 Sprint의 신규 Feature/Tech Story로 변환**한다.
   - 회고가 행동으로 이어지지 않으면 같은 실수가 반복된다 (v1.x 교훈).

3. **계획의 산출물 = 리뷰용 MD (Jira 아님)**
   - mv-sprint-plan은 Jira에 쓰지 않는다. *사람이 리뷰할 MD*만 만든다.
   - 사람 승인 후 `mv-sprint-run`이 MD를 읽어 Jira에 반영하고 개발을 시작한다.

## 3. 참여 서브 에이전트 (역할)

| 에이전트 | subagent_type | 모델 | Sprint Planning 기여 |
|---|---|---|---|
| **Scrum Master** | (본체 facilitator) | opus | 회의 진행, 입력 종합, 용량 계산, 최종 MD 작성 |
| **Product Owner** | `analyst` | opus | Feature/Story 후보 선정, 비즈니스 우선순위, 데모 가능성, **회고 개선→Feature 변환 주도** |
| **Architect** | `architect` | opus/sonnet | 응집도 클러스터링, 의존성·선행조건(앱 셸 등) 식별, 기술 실현가능성 |
| **QA Engineer** | `test-engineer`/`executor` | sonnet | Story 테스트 가능성 평가, DoD 검증가능성, 테스트 공수 |
| **Developer** | `deep-executor`/`executor` | sonnet | SP 추정 검증, 구현 순서, 기술 리스크 |
| **Critic** (선택) | `critic` | opus | 계획 도전 — 과욕/응집도 약함/의존성 순환 지적 |

## 4. Procedure (협업 8-Step)

### Step A — Pre-gather (Scrum Master)
- 백로그 fetch: `project = <KEY> AND sprint is EMPTY AND statusCategory != Done`
- `./sprints/snapshot-<date>.json` 저장
- **직전 Sprint 회고 로드**: `./sprints/sprint-<N-1>-retro.md`의 Improve/Try 추출
- **Carryover 식별**: 직전 Sprint에서 Verifier PASS 못 받은(미완) Story
- velocity 계산용 직전 3 Sprint 실측치 수집 (**Verifier PASS 기준 SP만**)

### Step B — 회고 개선사항 → Feature 변환 (Product Owner + Scrum Master)
직전 회고의 Improve/Try 항목을 *실행 가능한 Feature/Tech Story*로 변환:

| 회고 항목 (예) | 변환된 Feature/Story |
|---|---|
| "Frontend 테스트 미실행" | Tech Story: npm 환경 + CI 테스트 게이트 |
| "switch_env 버그" | Bug Story: 대상 .env 파일 로드 수정 |
| "앱 셸 부재" | Story: 프론트엔드 진입점 (선행) |

→ 변환된 항목은 이번 Sprint 후보 백로그에 **신규 추가**.

### Step C — 팀 병렬 입력 (PO + Architect + QA + Developer 동시 소환)
4개 에이전트를 **병렬**로 소환해 각자 관점 수집:

- **PO**: "비즈니스 가치 순으로 이번 Sprint에 꼭 들어가야 할 Feature/Story는? 데모 가능한가?"
- **Architect**: "응집도 클러스터는? 선행조건(앱 셸/인프라)이 빠진 Story는? 실현 가능한가?"
- **QA**: "각 Story가 테스트 가능한가? DoD를 증거로 검증할 수 있는가? 테스트 공수는?"
- **Developer**: "SP 추정이 맞는가? 구현 순서는? 숨은 기술 리스크는?"

### Step D — 응집도 클러스터링 (Architect 주도, Scrum Master 종합)
가중 점수로 *함께 가야 하는* Story 묶기:

| 신호 | 가중치 |
|---|---|
| 같은 Parent Epic | 0.40 |
| 공유 Component | 0.25 |
| 의존 그래프 인접 (blocked-by 1-hop) | 0.20 |
| 같은 Persona | 0.10 |
| 같은 Theme/Label | 0.05 |

- 0.5 이상 엣지로 연결된 노드를 한 클러스터로.
- 각 클러스터는 *demo-able outcome* 필수.

### Step E — 용량 + 선택 (Scrum Master + Developer)
```
velocity_avg = mean(직전 3 Sprint의 Verifier-PASS SP)   # 과대보고 금지
capacity_sp = round(velocity_avg × 0.85)                  # 15% 버퍼
```
- Greedy 선택: `(우선순위 × 응집도)` 내림차순, 클러스터 단위로 용량까지.
- WIP 룰: Epic당 동시 진행 ≤ 5, 의존성(blocked-by) 충족 검증.
- Developer가 SP 추정을 *재검증* (혼자 추정 금지).

### Step F — Critic 도전 (선택, 권장)
Critic 에이전트가 계획에 도전:
- 용량 대비 과욕인가? 응집도 < 0.5 묶음이 있나? 의존성 순환은?
- 회고 개선사항이 실제로 반영됐나?
→ 지적사항 반영하여 조정.

### Step G — sprint-plan MD 생성 (Scrum Master)
`./sprints/sprint-<N>-plan.md` 생성 — **이번 Sprint의 Feature/User Story 전체 리스트 포함**:

```markdown
# Sprint <N> Plan — <theme>

## Goal (한 줄, 데모 가능)
이 스프린트가 끝나면 사용자는 …

## 팀 합의 (참여 에이전트 의견 요약)
- PO: …  | Architect: …  | QA: …  | Developer: …

## 회고 반영 (직전 Sprint 개선사항 → 신규 항목)
| 회고 항목 | 변환된 Story | SP |

## Sprint Backlog (User Story / Feature 리스트)
### Cluster 1 — <이름> (응집도 0.NN)
| Order | Story ID | Story | Persona | SP | 의존성 | 완료기준(검증 증거) |
| 1 | F-NNN-NN / F-NEW-NN | ... | P1 | 3 | — | ... |

### Cluster 2 — ...

## 신규 Story (회고/carryover에서 생성, Jira 미등록)
| 임시 ID | 제목 | SP | 출처 |
| F-NEW-01 | 프론트엔드 앱 셸 | 5 | 회고: 앱 셸 부재 |

## Capacity
- velocity 평균(Verifier PASS): X SP | 가용(버퍼 15%): Y SP | 배정: Z SP

## Critical Path
## Demo Plan (종료 전 Sprint 내 실행)
## Risks
## Definition of Done (Verifier 증거 항목)
## Excluded (다음 Sprint 후보)

## 사람 리뷰 게이트
- [ ] 제품(PO) 승인: ___
- [ ] 엔지니어링(Architect) 승인: ___
> 승인 후 `/mv-sprint-run`이 이 MD를 읽어 Jira 반영 + 개발 시작.
```

### Step H — 사람 리뷰 (Jira 반영 금지)
- MD를 사람에게 제시. **mv-sprint-plan은 여기서 멈춘다.**
- Jira Sprint 생성/Story 등록/신규 Story upsert는 **`mv-sprint-run`이 사람 승인 후 수행.**

## 5. Output
- `./sprints/sprint-<N>-plan.md` (Feature/Story 리스트 + 팀 합의 + 회고 반영)
- `./sprints/snapshot-<date>.json`
- **Jira 변경 없음** (mv-sprint-run으로 이관)

## 6. Guardrails
- **스크럼 마스터 단독 계획 금지** — 4개 멤버 에이전트 입력 필수.
- **회고 개선사항 누락 금지** — 직전 retro Improve/Try가 Feature로 반영됐는지 확인.
- **응집도 < 0.5 묶음 거부**.
- **데모 가능한 결과 없으면 거부**.
- **mv-sprint-plan은 Jira에 쓰지 않음** — 산출물은 리뷰용 MD뿐.
- **velocity는 Verifier PASS 기준** — 과대보고 SP 사용 금지.

## 7. Chains
- 선행: `mv-backlog-prioritize` (점수화), `mv-sprint-retro` (velocity + 개선사항)
- 후행: **`mv-sprint-run`** — sprint-plan MD를 읽어 Jira 반영 후 개발 실행

## 8. When NOT to use
- 칸반(no-sprint) 운영 — 상시 백로그 우선순위 의존.
- Story < 5 — 사람이 직접 결정.

## 9. Cost & Time
- 토큰: ~50k (4 멤버 병렬 + 종합 + Critic)
- 시간: 10분 자동 + 15~30분 사람 검토

## 10. References
- Mike Cohn — *Agile Estimating and Planning*
- Atlassian — Sprint Planning
- `~/workspace/vibecode_base/docs/07-product-planning.md`
