---
name: vc-incident-to-test
description: 운영 버그 보고를 받아 Jira Bug Story 생성 → 재현 실패 테스트(RED) → 최소 픽스(GREEN) → 회귀 테스트 영구 보존 → 핫픽스 PR + 릴리스 브랜치 백포트. Trigger when user says "버그 픽스", "incident", "프로덕션 버그", "regression test", "hotfix", "사고 대응".
---

# vc-incident-to-test — Incident → Reproducible Test → Hotfix

> **vibecode_base 방법론의 사고 대응 + 회귀 방지 사이클**.
> 핵심 원칙: *모든 버그는 RED로 시작한다.* 픽스를 먼저 짜면 회귀가 따라온다.
> 참조: `~/workspace/vibecode_base/docs/05-quality-gates.md` §6, `docs/06-checklists.md` §9

## 1. Triggers
- "프로덕션 버그 잡아"
- "incident report"
- "hotfix"
- "regression test 추가"
- "사고 대응"
- "v1.4.2에서 X가 깨졌어"

## 2. Inputs
- 버그 보고 텍스트(필수). 다음이 있으면 더 정확:
  - 재현 절차
  - 환경(브라우저/OS/버전)
  - 로그/스택트레이스
  - 영향 사용자 수
- 발견된 버전(release tag, 가능하면)
- 심각도: `Sev1 / Sev2 / Sev3 / Sev4` (사람 지정)

## 3. Procedure

### Step A — Jira Bug Story 생성
- Issue Type: `Bug`
- 필드:
  - Severity: 위 입력 그대로
  - Affected Version, Found-in Build
  - 영향 추정(사용자/매출/데이터)
- 라벨: `incident`, `regression-target`
- *Sev1/Sev2*면 즉시 *온콜 멘션* + 상태 `In Progress`.

### Step B — 재현 (`debugger`, sonnet)
프롬프트:
```
당신은 debugger(sonnet).
입력: 버그 보고, 관련 로그, 영향 코드 경로 탐색 결과.
임무: 버그를 *재현*하는 최소 단위 테스트를 작성. 픽스 코드는 만들지 마라.
규칙:
- 공개 인터페이스 호출.
- 테스트 이름: `regression: <KEY> - <한 줄 요약>`
- 테스트 위치: tests/regression/<KEY>-*.spec.*
- 외부 의존(시간/네트워크)은 인터페이스로 격리.
- 테스트 작성 후 실행 → *반드시 실패* 확인. 통과하면 *재현 실패*로 보고.
출력: 테스트 파일, 실행 출력(20줄), 재현 가능/불가 판단.
```

재현 불가 시:
- "정보 부족" 라벨 + Jira에 추가 질문 댓글(스택트레이스/스텝).
- 종료. 사람이 추가 정보 제공 후 재시도.

### Step C — Hotfix 브랜치 생성
SemVer 정책:
- Sev1/Sev2: 직접 `release/<x.y>` 브랜치에서 `hotfix/<KEY>-<slug>` 분기.
- Sev3/Sev4: 일반 feature 브랜치에서 다음 정기 릴리스 포함.

```bash
git fetch origin
git checkout -b hotfix/<KEY>-<slug> origin/release/<x.y>   # 또는 origin/main
```

### Step D — GREEN (최소 픽스, `executor`, sonnet)
- 테스트 코드 수정 금지.
- 가장 작은 변경으로 통과시킴.
- 인접 리팩토링 금지(REFACTOR는 별도 PR).
- 전체 테스트 그린 확인.

### Step E — 회귀 테스트 영구 보존
- 작성된 regression 테스트를 **반드시 main에도 동일하게 머지**(hotfix와 별개 cherry-pick).
- 테스트 docstring/주석에 *영구 보존* 표시:
  ```
  // REGRESSION: PROJ-Bug-123 — 사용자 검색이 한글 자모 분리 시 빈 결과
  // 영구 보존 (재현/회귀 방지). 삭제 금지.
  ```
- 5분 내 검색되도록 `tests/regression/` 인덱스 갱신.

### Step F — 핫픽스 릴리스
- `vc-release` 호출 with `--hotfix` 옵션.
- 별도 release notes: *"보안/안정성 패치 — <KEY>"*.
- 카나리 단계 *짧게*(5분), 신속 배포.

### Step G — 백포트
- 영향 받는 다른 릴리스 라인이 있다면 cherry-pick:
  - `git cherry-pick <sha> -X theirs` (충돌 최소화)
- 각 백포트마다 별도 PR + 테스트 그린 확인.

### Step H — 포스트모템 (Sev1/Sev2)
- `incidents/<YYYY-MM-DD>-<KEY>.md` 생성:
  - 타임라인(발견→대응→해결)
  - 근본 원인 5 Whys
  - 재발 방지책 → 새 Jira Tech Story로 등록.
  - 알람·관측성 갭 → 별도 Story.

## 4. Output
- Jira Bug Story (+ 알람)
- `tests/regression/<KEY>-*.spec.*` (영구 보존)
- 핫픽스 PR + 머지 + 새 릴리스 태그(Sev1/Sev2)
- 백포트 PR들(있다면)
- (Sev1/Sev2) 포스트모템 문서

## 5. Guardrails
- **재현 테스트 없이 픽스 금지.** RED를 먼저.
- **회귀 테스트 삭제 영구 금지.** 변경 필요 시 *새 테스트로 supersede*.
- **Sev1/Sev2 작업 중 다른 큰 작업 금지.** 집중.
- **`--no-verify` 또는 hook skip 금지.** 핫픽스라도 게이트 우회 금지.
- **PII 포함 로그를 PR/이슈에 첨부 금지.** 마스킹 후 첨부.

## 6. Cost & Time
- 토큰: ~15k (debugger + executor sonnet)
- 시간: Sev1 ≤ 2시간 목표, Sev3 정기 릴리스 사이클.

## 7. Chains
- 선행: 운영 알람·고객 보고
- 후행: `vc-release --hotfix`, 필요 시 `vc-sprint-retro`

## 8. When NOT to use
- 재현 정보가 *전혀* 없는 모호한 보고 — 정보 수집 먼저.
- 의도된 동작 변경 요청 — 버그가 아닌 *Story*로 처리(`vc-feature-upsert`).

## 9. References
- `~/workspace/vibecode_base/docs/05-quality-gates.md` §6 회귀 방지
- Google SRE — Postmortem Culture
- Charity Majors — Observability Engineering
