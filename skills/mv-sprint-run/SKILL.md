---
name: mv-sprint-run
description: 스크럼 마스터로서 Sprint 전체를 완결-기반(No Time Boxing)으로 오케스트레이션 — Plan MD 로드→Jira 반영 → QA Red(UI는 화면 기준 상세 케이스) → Dev Green → 독립 Verifier 게이트(UI는 Playwright 실 브라우저, curl 금지) → PO 데모 Accept → 회고. 모든 Feature가 Verifier PASS받을 때까지 루프. v3.0 병렬 클러스터는 worktree 격리·single-migration-owner·clean-gate-after-all·import both·time cap. Trigger when user says "스프린트 실행", "sprint run", "스프린트 시작해", "sprint 진행", "스프린트 돌려".
---

# mv-sprint-run — Completion-Driven Sprint Execution (v2.1 + v3.0)

> 스크럼 마스터가 Sprint 전체를 오케스트레이션하되,
> **할당된 Feature의 개발이 완결(검증 통과)될 때까지** 중단 없이 구동한다.
> Time Boxing을 하지 않고, Definition of Done을 **독립 Verifier**가 증거로 확인해야만 종료한다.
>
> **v2.0 변경 사유**: v1.x 실전에서 스크럼 마스터가 Developer의 *자기 보고*("147 tests GREEN")만 믿고
> Frontend 미통합·docker-compose 부재·E2E 미검증 상태로 Sprint를 "100% 완료" 종료한 사고 발생.
> 근본 원인 = **Verifier 게이트 부재 + 시간 기반 종료**. 이를 v2.0에서 구조적으로 차단한다.
>
> **v2.1 변경 사유 (UI는 화면으로 검증)**: v2.0 게이트가 있었음에도, QA·Verifier가 UI를 **curl/유닛-mock**으로만
> 검증해 *화면에서만 터지는* 결함이 사용자 테스트에서 발견됨 (예: 임포트 데이터의 `{role_level}` 객체를
> React 자식으로 렌더 → "Minified React error #31"로 인력 화면 전체 크래시. curl·API 테스트·mock 유닛테스트는
> 전부 GREEN이었음). 근본 원인 = **UI를 실제로 그려보지 않음 + mock이 실데이터 형태를 가림**.
> v2.1은 **UI Story를 Playwright로 실 브라우저 화면을 띄워(육안/콘솔에러/실데이터) 검증**하고,
> **테스트 케이스를 화면 기준으로 상세하게 구성**하도록 강제한다.
>
> **v3.0 변경 사유 (병렬 클러스터 격리)**: 한 스프린트를 3~4 클러스터로 병렬 실행하면 빠르나 공유 워크트리/test DB에서
> 충돌이 반복됨(P1·P2·P5·P6·P7). v3.0은 worktree 격리·single-migration-owner·clean-gate-after-all로 해소(§8).

---

## 1. Triggers
- "스프린트 실행", "sprint run", "스프린트 시작해", "sprint 진행", "스프린트 돌려"

## 2. 핵심 원칙

1. **완결 기반 구동 (No Time Boxing)** — 할당된 모든 Feature가 **Verifier PASS**를 받을 때까지 루프. 미완 1개라도 있으면 종료 불가.
2. **자기보고 PASS 절대 금지** — 독립 **Verifier 에이전트**(`verifier`, my-vibe 번들)가 DoD 각 항목을 *증거*로 확인. FAIL은 반려→재작업→재검증.
3. **검증은 DoD 전부** — 백엔드 테스트만 GREEN으로 완료 금지. Frontend 테스트·E2E·기동까지 증거화.
4. **UI는 화면으로 검증 (curl 금지) ★ v2.1** — curl 200 ≠ 화면 정상. 모든 UI Story는 `mv-ui-verify`(Playwright)로 실 브라우저 렌더 + 콘솔에러 0 + 실데이터 + 스크린샷. mock 데이터만으로 통과 금지.

---

## 3. 소환되는 서브 에이전트 (역할 명확화)

| 에이전트 | subagent_type | 모델 | 책임 | 산출물(증거) |
|---|---|---|---|---|
| **Scrum Master** | (본체 오케스트레이터) | opus | 루프 제어, 소환/반려, 게이트 판정, 커밋 | sprint state |
| **Product Owner** | `analyst` | opus | Plan 검토·비즈니스 가치, **Sprint Review 데모 Accept** | PO 판정서 |
| **Architect** | `architect` | opus/sonnet | 신규/수정 파일, ADR-Story 정합성, 기술 결정 | arch-review.md |
| **QA Engineer** | `test-engineer`/`executor` | sonnet | AC별 실패 테스트(Red). **UI Story는 화면 기준 상세 케이스 + Playwright 시나리오** | 테스트 + UI 테스트케이스 |
| **Developer** | `deep-executor` | opus | 최소 코드 Green, Refactor, 의존성 순서 | 구현 코드 |
| **Verifier** | **`verifier`**(my-vibe 번들; UI는 Playwright) | sonnet/opus | **DoD 독립 검증**, 증거 수집, PASS/FAIL. **UI는 실 브라우저(curl 금지)** | verify/*.log + 스크린샷 + 평결서 |

> 각 에이전트는 자기 역할만. Developer는 자기 코드 검증 안 함(이해상충). Verifier는 코드 작성 안 함(독립성, Write/Edit 비활성).
> **UI Story 검증은 반드시 실 브라우저(Playwright)로 — curl/API 응답만으로 UI Done 판정 금지(v2.1).**

### 에이전트 모드 선택
- **단순 Sprint**: QA+Developer 통합 가능. 단, **Verifier는 항상 분리**.
- **복잡 Sprint**: QA·Developer·Verifier 모두 분리.

---

## 4. Procedure (8-Step, 완결까지 루프)

### Step 0 — Pre-flight Check (Scrum Master)
- [ ] `.env` + Jira 연결 · `FEATURES.md`/`ARCHITECTURE.md` 존재
- [ ] 이전 Sprint 전체 테스트 GREEN(회귀) · Frontend `node_modules` + `npm test` 1회 가능
- [ ] 이전 retro Try 반영 · **이전 Sprint carryover(미완 Feature) 우선 편입**
- [ ] **`mv-hygiene` 호출** — stale 프로세스 kill + 데모행 정리 + 컨테이너 헬스 대기

### Step 1 — Sprint Plan MD 로드 + Jira 반영 (Scrum Master, 사람 승인 후)
> **계획을 직접 세우지 않는다.** `mv-sprint-plan`이 협업으로 만든 MD를 *읽어* 실행한다.
1. **Plan MD 로드**: `./sprints/sprint-<N>-plan.md`. 없으면 `mv-sprint-plan` 먼저 안내 후 중단.
2. **사람 리뷰 게이트 확인**: MD Sign-off(제품/엔지니어링) 확인. 미승인 시 중단·요청.
3. **신규 Story Jira 등록**: MD 신규 Story(F-NEW-*)를 `mv-feature-upsert`로 멱등 등록, Key 회신.
4. **Sprint 구성**: 선택 Story의 Jira Sprint 필드 설정, Future→Active.
5. **검증**: 모든 배정 Story가 Jira에 존재·할당.
> **Jira 반영 완료 후에만 Step 4 개발 착수.**

### Step 2~3 — (mv-sprint-plan에서 이미 완료)
PO 7기준·Architect 리뷰는 `mv-sprint-plan` 협업 단계에서 수행됨. mv-sprint-run은 승인된 MD + arch-review를 *입력으로 신뢰*. Step 1에서 신규 Story 추가/범위 변경 시 Architect 재검토 1회 소환.

### Step 4 — QA TDD Red (QA Engineer)
- AC당 ≥1 테스트, 네거티브/경계. **Red 패턴**: `NotImplementedError` 금지 → `assert`로 의미있는 실패. Frontend 테스트 실제 실행 가능하게.

#### ★ v2.1 — UI Story는 화면 기준으로 상세 테스트케이스 작성
UI 화면 Story는 *화면별 → 요소별 → 상태별*로 빠짐없이 분해:
```
화면: <경로>  사전조건: 로그인(역할 <role>), 실데이터 N건
요소/영역: □진입(URL·콘솔에러0·리다이렉트없음) □레이아웃/CSS □데이터영역(실데이터 행≥1, 객체/[object Object]/undefined 금지)
          □컬럼/필드 포맷 □상호작용(검색·필터·정렬·페이지네이션·행클릭) □폼(입력·검증·토스트)
상태별:   □로딩 □빈 □에러 □정상(실데이터) □엣지(null/빈배열/중첩객체/긴 한글/특수문자/대량)
각 케이스 = Given(화면/데이터) → When(동작) → Then(보이는 결과) + 스크린샷
```
- 최소 1 케이스는 **실 API/DB 데이터**로 화면 렌더 검증(mock이 실결함 가림).
- 산출: `sprints/sprint-<N>-ui-testcases.md` + 가능한 것은 Playwright 자동화(`mv-ui-verify`).

### Step 5 — Developer TDD Green + Refactor (Developer)
- 최소 코드 Green → Refactor. 매 Story 후 전체 테스트(회귀). 테스트 파일 수정 금지.

### Step 6 — Verification Gate (Verifier) ★ 강제 게이트
스크럼 마스터는 Developer 보고를 신뢰하지 않고 독립 `verifier`를 소환. DoD 전 항목을 증거로 확인:
```
□ 백엔드 GREEN(pytest 로그)  □ 프론트 GREEN(npm test 로그)  □ 커버리지 ≥목표
□ ruff/타입 0  □ alembic 단일 head + clean  □ 앱 기동 + 컨테이너 산출물(@tailwind 0, 번들>10KB, 엔드포인트 라이브)
□ ★ UI 화면(mv-ui-verify/Playwright): 로그인 후 실 브라우저 렌더 + 콘솔/페이지 에러 0 + 실데이터 행≥1
   + 화면 테스트케이스 각 상태(로딩/빈/에러/정상/엣지) 통과 + 스크린샷. **curl 200만으로 UI PASS 금지**
□ E2E 시나리오(Playwright)  □ FEATURES.md Status=Done  □ 회귀 0(이전 스프린트 포함)
□ 데이터(import 있으면): 멱등/매칭률, erp+test 둘 다 적재
```
> **curl 한계**: HTTP/JSON만 본다. 화면 렌더·JS·콘솔에러 못 봄 → UI는 `verifier`가 Playwright로. curl은 API Story에만.

**게이트 판정**: 모든 항목 PASS → Step 7 / 하나라도 FAIL → Developer 반려(Status In Progress) → Step 5 재작업 → 재검증 → **PASS까지 루프(Time Box 없음)**.
> 증거 없는 PASS 거부. UI는 "스크린샷·콘솔에러 0·실데이터 렌더" 증거 없으면 FAIL.

### Step 7 — Sprint Review 데모 (Product Owner Accept)
- 스크럼 마스터가 Sprint Goal 데모를 **실제 실행** → PO가 사용자 관점 Accept/Reject. Reject → Step 5. Accept 기록 남겨야 종료 가능.

### Step 8 — 종료 + 커밋 + 회고 (Scrum Master)
종료 전제(모두 충족): 모든 Feature Verifier PASS · PO 데모 Accept · FEATURES.md Done · 전체 테스트 GREEN + 커버리지.
충족 시 커밋·push·`sprints/sprint-N-retro.md`. **미충족 시 종료하지 않고 Step 5~6 루프.**

---

## 5. 완결 루프 의사코드
```
while (미완 Feature 존재):
    for story in sprint_backlog:
        if story.status != "Verified":
            QA.write_red_tests(story)         # Step 4 (UI는 화면 케이스)
            Developer.implement_green(story)  # Step 5
            verdict = Verifier.verify(story)  # Step 6 — 독립 검증(UI는 Playwright)
            story.status = "Verified" if verdict == PASS else "In Progress"
    if all(Verified) and PO.demo_accept(sprint):   # Step 7
        break
finalize_sprint()  # Step 8 — 진짜 완결
```

---

## 6. Guardrails
- **Verifier 게이트 우회 금지** · **Time Box 종료 금지** · **Frontend "컴포넌트만" Done 금지**.
- **★ UI를 curl로만 검증 금지(v2.1)** — Playwright 실 브라우저 렌더·콘솔에러·실데이터.
- **★ mock만으로 통과 금지(v2.1)** — UI는 실 API/DB로 화면 렌더 1회 이상.
- **Jira Key 수동 입력 금지** · **앱 셸 없는 UI Story 금지** · **데모는 종료 전 Sprint 내** · **FEATURES.md Status 갱신 강제**.

---

## 7. v1.x → v2.1 변경 요약
| 항목 | v1.x | v2.0 / v2.1 |
|---|---|---|
| 종료 기준 | 시간 + 자기보고 | **모든 Feature Verifier PASS + PO Accept** |
| Verifier | 없음 | **독립 게이트 강제(Step 6) + 전용 `verifier` 에이전트** |
| Frontend | 생략 | **실행 증거 필수, 불가 시 FAIL** |
| 데모 | 종료 후 | **종료 전 Sprint 내** |
| UI 검증(v2.1) | curl/API/mock | **Playwright 실 브라우저 + 실데이터 + 화면 상세 케이스** |

---

## 8. v3.0 — 병렬 클러스터 오케스트레이션 + 워크트리 격리

한 스프린트를 3~4 클러스터로 병렬 실행할 때(P1·P2·P5·P6·P7 해소):

- **8.1 git worktree per cluster (P1·P2) ★핵심**: 각 클러스터를 독립 worktree+브랜치(`git worktree add ../wt-clusterX -b sprintN-clusterX`)에서 실행 → reset 상호 revert·빌드차단·파일 revert 0. 완료 후 스크럼 마스터가 **순차 머지** → 머지 후 단독 클린 게이트. (Agent 도구 `isolation: "worktree"` 활용.)
- **8.2 single-migration-owner (P5)**: 한 스프린트에 migration은 **1 클러스터만** 생성(다른 클러스터가 쓸 테이블도 미리). 나머지는 read/write만 → alembic 다중-head 0. 마이그레이션 클러스터를 Wave 1, 의존 클러스터를 Wave 2.
- **8.3 clean-gate-after-all (P7)**: 통합 게이트는 **전 클러스터 완료 + 머지 후 단독 1회**. 에이전트 실행 중 게이트 금지(test DB 경합). 게이트 전 `mv-hygiene` 호출.
- **8.4 import both (P6)**: 클러스터 데이터 import는 `mv-data-import --target both`(erp+erp_test).
- **8.5 agent time cap (P3)**: 장시간 에이전트(deep-executor) 실행 상한(30~45분) + 경계에서 `mv-hygiene`로 잔존 강제 종료.
- **8.6 UI 검증은 mv-ui-verify (P4)**: 클러스터 UI는 screen-smoke(웜 세션), 종료에 full-e2e. 재빌드 스프린트당 1회.
- **8.7 Verifier 전용 에이전트**: Step 6 게이트는 my-vibe 번들 `verifier`로(analyst/qa-tester 겸용 분리).

> v3.0 = worktree 격리 + single-migration-owner + clean-gate-after-all(+mv-hygiene) + import both + time cap + mv-ui-verify + verifier 전용. Sprint 7~13에서 수동 적용해 효과 입증.

---

## 9. Chains
- 선행: `mv-feature-upsert` → `mv-backlog-prioritize` → `mv-arch-from-jira` → `mv-sprint-plan`(승인된 MD)
- 내장 호출: `mv-hygiene`(경계·게이트 전), `mv-ui-verify`(UI 검증), `mv-data-import`(적재), `verifier`(게이트)
- 반복: Sprint N → N+1 (velocity·carryover 자동 이월)

## 10. References
- v1.x 사고: Sprint 1~2 (Backend Done, Frontend 미통합 오종료)
- v2.1 사고: Sprint 5 — 임포트 `{role_level}` 객체를 React 자식으로 렌더 → React #31 화면 크래시. curl·API·mock 전부 GREEN이었으나 실 브라우저에서만 발견.
- v3.0 근거: Sprint 7~13 병렬 운영 — 공유 워크트리/test DB 충돌(reflog 3회 revert, deadlock/10-fail, alembic 다중-head, 예산 erp 0행).
- `~/workspace/vibecode_base/docs/05-quality-gates.md`, `docs/10-tdd-cycle.md`
