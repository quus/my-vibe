---
name: mv-sprint-run
description: 스크럼 마스터로서 Sprint 전체를 완결-기반(No Time Boxing)으로 오케스트레이션 — Pre-flight → Plan → PO 리뷰 → Architect 리뷰 → QA TDD Red → Dev TDD Green → 독립 Verifier 게이트 → PO 데모 Accept → 회고. 할당된 모든 Feature가 Verifier PASS를 받을 때까지 루프하며, 자기보고 PASS·Time Box 종료를 구조적으로 차단. mv-sprint-plan(계획만)과 달리 실행·검증까지 자동화. Trigger when user says "스프린트 실행", "sprint run", "스프린트 시작해", "sprint 진행", "스프린트 돌려".
---

# mv-sprint-run — Completion-Driven Sprint Execution (v2.1)

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

---

## 1. Triggers
- "스프린트 실행", "sprint run", "스프린트 시작해", "sprint 진행", "스프린트 돌려"

## 2. 핵심 원칙 (v2.0)

1. **완결 기반 구동 (No Time Boxing)**
   - Sprint는 "2주" 같은 시간으로 끝나지 않는다.
   - 할당된 모든 Feature가 **Verifier PASS**를 받을 때까지 스크럼 마스터가 루프를 반복한다.
   - 미완 Feature가 1개라도 있으면 Sprint는 종료되지 않는다 (DoD 위반 시 자동 재진입).

2. **자기보고 PASS 절대 금지**
   - Developer가 "테스트 통과"라고 말해도 그것은 *주장*일 뿐이다.
   - 독립 **Verifier 에이전트**가 DoD 각 항목을 *증거*(실행 로그, 스크린샷, 명령 출력)로 확인해야 한다.
   - Verifier가 FAIL한 항목은 Developer에게 반려 → 재작업 → 재검증 (PASS까지 반복).

3. **검증은 "쉬운 것"이 아니라 "DoD 전부"**
   - 백엔드 테스트만 GREEN인 것으로 완료 판정 금지.
   - Frontend 테스트 실제 실행, E2E 데모, 빌드/기동 가능 여부까지 모두 증거화.

4. **UI는 화면으로 검증한다 (curl 금지) ★ v2.1**
   - curl·API 테스트·유닛-mock은 *API 계약과 로직*만 본다. **화면에서만 터지는 결함**
     (객체를 React 자식으로 렌더, CSS 미적용, 무한 리다이렉트, 빈 테이블, 깨진 컬럼, 콘솔 에러)은
     절대 잡지 못한다 — curl 200 ≠ 화면 정상.
   - 모든 **UI Story는 Playwright로 실 브라우저에서 화면을 띄워** 검증한다:
     로그인 → 해당 화면 이동 → **실제 렌더 + 콘솔/페이지 에러 0 + 실데이터 표시 + 스크린샷**.
   - **mock 데이터로만 통과 금지**: 컴포넌트 테스트의 mock은 실데이터 형태(중첩 객체/null/한글/빈배열)를
     가린다. UI Story는 **실 API/DB 데이터로 1회 이상 화면 렌더**를 확인한다.

---

## 3. 소환되는 서브 에이전트 (역할 명확화)

| 에이전트 | subagent_type | 모델 | 책임 (Responsibility) | 산출물(증거) |
|---|---|---|---|---|
| **Scrum Master** | (본체 오케스트레이터) | opus | 전체 루프 제어, 에이전트 소환/반려, 게이트 판정, 커밋 | sprint state |
| **Product Owner** | `analyst` | opus | Sprint Plan 검토(7기준 점수), 비즈니스 가치 판정, **Sprint Review 데모 Accept** | PO 판정서 |
| **Architect** | `architect` | opus(첫)/sonnet(이후) | 신규/수정 파일 식별, ADR-Story 정합성, 기술 결정 | arch-review.md |
| **QA Engineer** | `test-engineer`/`executor` | sonnet | AC별 **실패 테스트(Red)** 작성, 경계/네거티브 케이스. **UI Story는 화면 기준 상세 테스트케이스 + Playwright E2E 시나리오** 작성 | 테스트 파일 + UI 테스트케이스 |
| **Developer** | `deep-executor` | opus | 최소 코드로 Green, Refactor, 의존성 순서 구현 | 구현 코드 |
| **Verifier** | `qa-tester`(UI)/`verifier`(로직) | sonnet(소)/opus(대) | **DoD 각 항목 독립 검증**, 증거 수집, PASS/FAIL 평결. **UI는 Playwright로 실 브라우저 화면 검증(curl 금지)** | verify/*.log + 스크린샷 + 평결서 |

> 각 에이전트는 **자신의 역할만** 수행한다. Developer는 자기 코드를 검증하지 않는다(이해상충).
> Verifier는 코드를 작성하지 않는다(독립성). 이 분리가 v1.x 사고의 핵심 방지책.
> **UI Story 검증은 반드시 실 브라우저(Playwright)로 화면을 보고 한다 — curl/API 응답만으로 UI Done 판정 금지(v2.1).**

### 에이전트 모드 선택
- **단순 Sprint** (기존 패턴 확장): QA+Developer 통합 가능. 단, **Verifier는 항상 분리**.
- **복잡 Sprint** (신규 도메인/아키텍처 변경): QA·Developer·Verifier 모두 분리.

---

## 4. Procedure (8-Step, 완결까지 루프)

### Step 0 — Pre-flight Check (Scrum Master)
시작 전 자동 검증 (하나라도 실패 시 사람에게 알림 후 대기):
- [ ] `.env` + Jira 연결 확인
- [ ] `FEATURES.md`, `ARCHITECTURE.md` 존재
- [ ] 이전 Sprint 전체 테스트 GREEN (회귀 확인)
- [ ] **Frontend 빌드 환경 확인**: `node_modules` 존재 + `npm test` 1회 실행 가능 (없으면 `npm install`)
- [ ] 이전 retro의 Try 항목 반영 여부
- [ ] **이전 Sprint carryover(미완 Feature) 우선 편입**

### Step 1 — Sprint Plan MD 로드 + Jira 반영 (Scrum Master, 사람 승인 후)
> **mv-sprint-run은 계획을 직접 세우지 않는다.** `mv-sprint-plan`이 협업으로 만든 MD를 *읽어* 실행한다.

1. **Plan MD 로드**: `./sprints/sprint-<N>-plan.md`를 읽는다. 없으면 `mv-sprint-plan` 먼저 실행하라고 사람에게 안내 후 중단.
2. **사람 리뷰 게이트 확인**: MD의 Sign-off(제품/엔지니어링 승인) 체크 확인. 미승인이면 중단하고 승인 요청.
3. **신규 Story Jira 등록**: MD의 신규 Story(`F-NEW-*` 등 회고/carryover 생성분)를 `mv-feature-upsert` 로직으로 Jira에 멱등 등록. 등록된 Jira Key를 MD와 Story 파일에 회신.
4. **Sprint 구성**: 선택된 Story의 Jira `Sprint` 필드를 이번 Sprint로 설정, Jira Sprint를 Future→Active.
5. **검증**: 모든 배정 Story가 Jira에 존재하고 Sprint에 할당됐는지 확인.

> **이 단계(Jira 반영)가 끝나야만 Step 4(QA Red) 개발 착수.** Jira 미반영 상태로 개발 시작 금지.

### Step 2~3 — (mv-sprint-plan에서 이미 완료)
PO 7기준 리뷰와 Architect 리뷰는 **`mv-sprint-plan` 협업 계획 단계에서 수행**된다.
mv-sprint-run은 그 결과(승인된 MD + arch-review)를 *입력으로 신뢰*한다.
단, Step 1에서 신규 Story가 추가됐거나 범위가 바뀌면 Architect 재검토를 1회 소환한다.

### Step 4 — QA TDD Red (QA Engineer)
- AC당 ≥1 테스트, 네거티브/경계 포함
- **Red 패턴**: `NotImplementedError` 금지 → `assert result == expected`로 *의미있는 실패*
- **Frontend 테스트도 실제 작성 + 실행 가능하게** (스텁/모킹 포함)

#### ★ v2.1 — UI Story는 화면 기준으로 상세 테스트케이스 작성
UI/화면이 있는 Story는 **컴포넌트 단위 테스트 + 화면(E2E) 테스트케이스**를 함께 만든다.
화면 테스트케이스는 *화면별 → 요소별 → 상태별*로 빠짐없이 분해한다:

```
[화면 테스트케이스 템플릿 — UI Story마다]
화면: <경로> (예: /resources 인력 목록)
사전조건: 로그인 상태(역할: <role>), 실 데이터 N건 존재

요소/영역별 검증:
  □ 페이지 진입: URL 도달, 콘솔/페이지 에러 0, 무한 리다이렉트 없음
  □ 레이아웃/스타일: CSS 적용됨(빈 스타일 아님), 사이드바/헤더 렌더
  □ 데이터 영역(표/카드): 실데이터 행 ≥1 렌더, 각 컬럼 값 정상(객체/[object Object]/undefined 금지)
  □ 컬럼/필드별: <컬럼명>마다 기대 포맷(badge/날짜/숫자/'—' placeholder)
  □ 상호작용: 검색·필터·정렬·페이지네이션·행 클릭 동작
  □ 폼(있으면): 입력·검증 에러·제출 성공/실패 토스트

상태별 검증 (각각 화면으로 확인):
  □ 로딩(skeleton)  □ 빈 상태(empty)  □ 에러 상태  □ 정상(실데이터)
  □ 엣지: null/빈배열/중첩객체/긴 한글/특수문자(SG&A 등)/대량건수

각 케이스 = Given(화면/데이터) → When(동작) → Then(보이는 결과) + 스크린샷
```

- **실데이터 형태로 검증**: mock은 실 API/DB가 주는 형태(중첩 객체, null, 한글, 빈배열)와 다를 수 있다.
  최소 1개 케이스는 **실 API/DB 응답 형태**(또는 임포트된 실데이터)로 화면 렌더를 검증한다.
- QA는 이 테스트케이스를 `sprints/sprint-<N>-ui-testcases.md`로 산출하고, 가능한 것은 Playwright 스크립트로 자동화한다.

### Step 5 — Developer TDD Green + Refactor (Developer)
- 최소 코드로 Green → Refactor
- 매 Story 후 전체 테스트 실행(회귀 확인)
- 테스트 파일 수정 금지

### Step 6 — **Verification Gate (Verifier) ★ 신규 강제 게이트**

스크럼 마스터는 Developer 완료 보고를 **신뢰하지 않는다.** 독립 Verifier를 소환한다.

Verifier는 Sprint DoD의 **모든 항목**을 증거로 확인:

```
[검증 체크리스트 — 각 항목 증거 필수]
□ 백엔드 테스트 GREEN     → 실제 pytest 실행 로그 첨부
□ Frontend 테스트 GREEN   → 실제 npm test 실행 로그 첨부 (실행 불가 시 FAIL)
□ 커버리지 ≥ 목표          → coverage 리포트 출력
□ 린트/타입 0 에러         → ruff/mypy/eslint 실행 로그
□ 앱 기동 가능             → 서버/프론트 실제 기동 확인 (docker compose 또는 dev server)
□ 컨테이너 산출물 검증     → 서빙 CSS 컴파일됨(@tailwind 0, 번들>10KB), 엔드포인트 라이브
□ ★ UI 화면 검증(Playwright) → 로그인 후 실 브라우저로 해당 화면 렌더 확인:
                              · 콘솔/페이지 에러 0 (React #31 등 렌더 크래시 없음)
                              · 실데이터 행 ≥1 표시 (mock 아님), 각 컬럼 값 정상
                              · 화면 테스트케이스(Step 4) 각 상태(로딩/빈/에러/정상/엣지) 통과
                              · 스크린샷 첨부.  **curl 200만으로 UI PASS 금지**
□ E2E 시나리오 동작        → Playwright 실행 결과 (정상/엣지/회귀 시나리오)
□ FEATURES.md Status 갱신  → 완료 Story가 Done인지 확인
□ 회귀 없음                → 이전 Sprint 테스트 포함 전체 GREEN
```

> **curl의 한계 (v2.1)**: curl은 HTTP 상태/JSON만 본다. 화면 렌더링·JS 실행·콘솔 에러를
> 보지 못하므로 **UI Story를 curl로 검증하면 안 된다**. UI 항목은 반드시 `qa-tester`가
> Playwright로 실 브라우저 화면을 띄워 검증한다. curl은 API(백엔드) Story 검증에만 사용한다.

**게이트 판정**:
- **모든 항목 PASS** → Step 7 진행 가능
- **하나라도 FAIL** → 해당 Story를 Developer에게 반려 (Status: In Progress 유지)
  → Step 5로 되돌아가 재작업 → 재검증
  → **PASS할 때까지 루프 (Time Box 없음)**

> Verifier는 "증거 없는 PASS"를 거부한다. "테스트 통과했다고 들었다"는 FAIL 처리.
> **UI는 "스크린샷·콘솔에러 0·실데이터 렌더" 증거 없으면 FAIL (curl 200은 증거 아님).**

### Step 7 — Sprint Review 데모 (Product Owner Accept)
- 스크럼 마스터가 Sprint Goal 데모 시나리오를 **실제 실행**
- PO가 사용자 관점에서 Accept/Reject
- **PO Reject 시 → Step 5로 (미충족 부분 재작업)**
- PO Accept 기록을 남겨야 종료 가능

### Step 8 — 종료 + 커밋 + 회고 (Scrum Master)
종료 전제 (모두 충족해야 종료):
- [ ] 할당된 **모든 Feature** Verifier PASS
- [ ] PO 데모 Accept
- [ ] FEATURES.md Status = Done (완료분)
- [ ] 전체 테스트(누적) GREEN + 커버리지 목표

충족 시: 커밋·push·`sprints/sprint-N-retro.md` 작성.
**미충족 시: 종료하지 않고 Step 5~6 루프 계속.**

---

## 5. 완결 루프 의사코드

```
while (미완 Feature 존재):
    for story in sprint_backlog:
        if story.status != "Verified":
            QA.write_red_tests(story)         # Step 4
            Developer.implement_green(story)  # Step 5
            verdict = Verifier.verify(story)  # Step 6 — 독립 검증
            if verdict == PASS:
                story.status = "Verified"
            else:
                story.status = "In Progress"  # 반려, 루프 계속
    # 모든 story Verified 시:
    if PO.demo_accept(sprint):                # Step 7
        break
    # else 루프 계속

finalize_sprint()  # Step 8 — 여기 도달 = 진짜 완결
```

**핵심**: 종료 조건은 "시간 경과"가 아니라 "모든 Feature가 Verified + PO Accept". 시간이 얼마가 걸리든 스크럼 마스터는 루프를 계속한다.

---

## 6. Guardrails (v2.0 강화)

- **Verifier 게이트 우회 금지** — Developer 자기보고로 종료 절대 불가.
- **Time Box로 종료 금지** — 미완 Feature 있으면 무조건 루프 계속.
- **Frontend "컴포넌트만 작성" → Done 금지** — 실제 기동/테스트 실행 증거 필수.
- **★ UI Story를 curl로만 검증 금지 (v2.1)** — 반드시 Playwright로 실 브라우저 화면을 띄워 렌더·콘솔에러·실데이터 확인.
- **★ mock 데이터로만 통과 금지 (v2.1)** — UI Story는 실 API/DB 데이터로 화면 렌더 1회 이상 확인(mock이 실결함 가림).
- **Jira Key 수동 입력 금지** — 자동 추출.
- **앱 셸 없는 UI Story 금지** — 진입점 선행 Story 강제.
- **데모는 종료 전, Sprint 안에서** — 종료 후 데모로 갭 발견되는 사고 방지.
- **FEATURES.md Status 갱신 강제** — 완료 시 Done.

---

## 7. v1.x → v2.1 변경 요약

| 항목 | v1.x (사고 발생) | v2.0 / v2.1 (수정) |
|---|---|---|
| 종료 기준 | 시간(2주) + 자기보고 | **모든 Feature Verifier PASS + PO Accept** |
| Verifier | 없음 | **독립 게이트 강제 (Step 6)** |
| Frontend 검증 | 생략(npm 미설치) | **실행 증거 필수, 불가 시 FAIL** |
| 데모 시점 | 종료 후 | **종료 전 Sprint 내 (Step 7)** |
| 미완 Feature | "100% 완료" 오보고 | **루프 계속, 종료 불가** |
| 에이전트 역할 | 모호(Dev가 검증 겸함) | **6역할 분리, 검증 독립** |
| **UI 검증 (v2.1)** | curl/API/mock만 → 화면 크래시 미적발 | **Playwright 실 브라우저 화면 검증 + 실데이터 렌더 + 화면 기준 상세 테스트케이스** |

---

## 8. When NOT to use
- 스토리 < 3개: 직접 TDD가 빠르다.
- 아키텍처 미수립: `mv-arch-from-jira` 먼저.
- 백로그 미정리: `mv-backlog-prioritize` 먼저.

## 9. Chains
- 선행: `mv-feature-upsert` → `mv-backlog-prioritize` → `mv-arch-from-jira` (→ 선택적으로 `mv-sprint-plan`)
- 내장: Plan · PO · Architect · QA · Developer · **Verifier** · Retro 를 한 루프에서 호출.
- 반복: Sprint N → Sprint N+1 (velocity·carryover 자동 이월).

## 10. References
- v1.x 사고 기록: 본 프로젝트 Sprint 1~2 (Backend Done, Frontend 미통합 상태로 오종료)
- **v2.1 사고 기록: Sprint 5 — 임포트 `{role_level}` 객체를 React 자식으로 렌더 → React #31 화면 크래시.
  curl·API 테스트·mock 유닛테스트 전부 GREEN이었으나 실 브라우저에서만 발견. → UI는 Playwright 화면 검증 강제.**
- my-vibe 가드레일: "자기보고 PASS 금지 — Verifier 평결 없이 진행 없음", "UI는 curl 아닌 화면으로 검증"
- `~/workspace/vibecode_base/docs/05-quality-gates.md` (Verifier 증거 기반 완료)
- 선행 스킬: mv-feature-upsert → mv-backlog-prioritize → mv-arch-from-jira
