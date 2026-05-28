---
name: mv-sprint-run
description: 스크럼 마스터로서 Sprint 전체 사이클을 원스톱 오케스트레이션 — Sprint Plan 작성 → PO 리뷰 → Architect 리뷰 → QA TDD Red → Developer TDD Green → Refactor → 검증/커밋 → 회고. mv-sprint-plan(계획만)과 달리 *실행까지* 자동화. Trigger when user says "스프린트 실행", "sprint run", "스프린트 시작해", "sprint 진행", "스프린트 돌려".
---

# mv-sprint-run — Automated Sprint Execution (Plan → Dev → Retro)

> 스크럼 마스터가 Sprint 전체 사이클을 오케스트레이션한다.
> Sprint Plan 작성 → PO 리뷰 → Architect 리뷰 → QA TDD Red → Developer TDD Green → Refactor → 회고.
> 2회 Sprint 실전 경험(Sprint 1: 31SP/7S, Sprint 2: 29SP/8S)에서 도출된 최적화된 프로세스.

## 1. Triggers
- "스프린트 실행"
- "sprint run"
- "스프린트 시작해"
- "sprint 진행"
- "스프린트 돌려"

## 2. Inputs
- `JIRA_PROJECT_KEY` (env)
- `./FEATURES.md` (백로그)
- `./ARCHITECTURE.md` (아키텍처)
- `./PLAN-candidate.md` (우선순위 — 없으면 `mv-backlog-prioritize` 먼저)
- `./sprints/sprint-N-retro.md` (이전 Sprint 회고 — 있으면 교훈 반영)
- Sprint 번호 (인자 또는 자동 감지)

## 3. 전제 조건 자동 검증 (Sprint 시작 전)

```
Step 0 — Pre-flight Check
```
자동 검증 항목 (하나라도 실패 시 사람에게 알림 후 대기):
- [ ] `.env` 파일 존재 + Jira 연결 확인
- [ ] `FEATURES.md` 존재
- [ ] `ARCHITECTURE.md` 존재
- [ ] 이전 Sprint 테스트 전체 GREEN (회귀 확인)
- [ ] Frontend `node_modules/` 존재 (없으면 `npm install` 실행)
- [ ] 이전 Sprint retro의 "시도할 것(Try)" 항목을 현재 Sprint에 반영했는지 체크

## 4. Procedure (7-Step)

### Step 1 — Sprint Plan 작성 (Scrum Master)

**입력**: PLAN-candidate.md, 이전 Sprint retro, 팀 velocity
**출력**: `sprints/sprint-N-plan.md`

규칙:
- 이전 Sprint velocity 기반 SP 계획 (첫 Sprint: 30SP 가정)
- Jira Key는 `jira/stories/*.md` 파일에서 **자동 추출** (수동 입력 금지)
- SP 합계 자동 계산 + 검증
- Sprint Goal은 측정 가능한 문장 (데모 가능해야 함)
- 의존성 그래프 Mermaid 포함
- Sprint Review 데모 시나리오 포함
- "의도적 제외" 목록 포함

**Jira Key 자동 매핑 방법**:
```bash
# Feature ID → Jira Key 매핑 추출
for f in jira/stories/F-0XX-*.md; do
  grep -m1 "Jira Key" "$f" | sed 's/.*`\(ERP-[0-9]*\)`.*/\1/'
done
```

### Step 2 — PO 리뷰 (Product Owner Agent)

**에이전트**: `analyst` (opus)
**입력**: sprint-N-plan.md, FEATURES.md, 이전 retro
**출력**: Accept / Accept with Conditions / Reject + 점수표

평가 기준 (7개, 각 1-5점):
1. Sprint Goal 명확성
2. 비즈니스 가치
3. 범위 적절성 (velocity 대비)
4. 의존성 관리
5. 리스크 완화
6. Definition of Done
7. 이전 Sprint 교훈 반영

**리뷰 루프**:
- Accept → Step 3으로
- Accept with Conditions → Scrum Master가 수정 → PO 재검토 (최대 2회)
- Reject → Sprint 범위 재구성

**병렬화 기준**:
- 범위 변경 < 20% (이전 Sprint 대비) → PO + Architect 병렬 실행
- 범위 변경 ≥ 20% → PO 먼저 확정 → Architect 순차

### Step 3 — Architect 리뷰 (Architect Agent)

**에이전트**: `architect` (Sprint 1은 opus, Sprint 2+는 sonnet)
**입력**: sprint-N-plan.md, ARCHITECTURE.md, ADR/, Story 파일들
**출력**: `sprints/sprint-N-arch-review.md`

검토 항목:
1. 신규 파일/모듈 목록 (구체적 경로)
2. 기존 코드 수정 필요 사항
3. ADR-Story 정합성 검증 (키워드 매칭)
4. ARCHITECTURE.md 수정 필요 여부
5. 기술 결정 사항 확정

**ADR-Story 자동 정합성 체크**:
- Story AC에서 기술 키워드 추출 (Cookie, JWT, RBAC 등)
- 해당 키워드와 관련된 ADR이 존재하는지 확인
- 불일치 시 WARN 레벨로 리포트

### Step 4 — QA TDD Red (QA Agent)

**에이전트 선택 기준**:
- 단순 Sprint (기존 패턴 확장): QA+Dev 통합 에이전트 → Step 4+5 병합
- 복잡 Sprint (신규 도메인/아키텍처 변경): QA 분리 → Step 4→5 순차

**에이전트**: `executor` (sonnet) 또는 통합 시 `deep-executor` (opus)
**입력**: Story 파일들 (AC + Test Plan), Architect Review, 기존 코드
**출력**: 테스트 파일들 + 스텁

**개선된 Red 패턴** (NotImplementedError 금지):
```python
# BAD (Sprint 1 방식): 미구현 에러를 기대
def test_login_redirect():
    with pytest.raises(NotImplementedError):
        service.login_redirect("/dashboard")

# GOOD (개선 방식): 의미있는 실패
def test_login_redirect_returns_authorize_url():
    result = service.login_redirect("/dashboard")
    assert result.status_code == 302  # stub returns None → AssertionError
    assert "authorize" in result.headers["location"]
```

스텁은 `return None` 또는 빈 객체를 반환하여 assertion이 의미있게 실패하도록 작성.

**테스트 작성 규칙**:
- 각 Story AC → 최소 1 테스트 (AC 번호 주석 필수)
- Negative 테스트 포함 (AC에서 요구)
- 경계 조건 테스트 추가 (AC에 없더라도)
- Story당 최소 4 테스트

### Step 5 — Developer TDD Green (Developer Agent)

**에이전트**: `deep-executor` (opus)
**입력**: Red 테스트 파일들, Architect Review, 기존 코드
**출력**: 구현 코드

규칙:
- 테스트를 통과시키는 **최소 코드** 작성
- 테스트 파일 수정 금지 (assertion 값만 의미 없으면 조정)
- Story 순서대로 구현 (의존성 체인 따라)
- 매 Story 구현 후 전체 테스트 실행 (회귀 확인)

### Step 5.5 — Refactor (신규 단계)

**Green 통과 후**:
- 중복 코드 제거
- 네이밍 개선
- 불필요한 import 정리
- 타입 힌트 보강
- 테스트 재실행하여 회귀 없음 확인

### Step 6 — 검증 + 커밋 (Scrum Master)

자동 검증 체크리스트:
```
[ ] 전체 테스트 GREEN (Sprint 1 + ... + Sprint N 누적)
[ ] 커버리지 ≥ 80% (서비스 레이어 ≥ 90% 권장)
[ ] 린트/타입 에러 0건
[ ] FEATURES.md Status 업데이트 (완료 Story → Done)
[ ] Jira Story Status 갱신 (Funnel → Done) — 선택
[ ] Frontend 테스트도 GREEN 확인 (npm test)
```

커밋 메시지 형식:
```
feat: Sprint N 완료 — <Sprint Goal 요약>

## 완료 Story
- F-xxx-xx: <제목> (N SP)
...

## TDD
- X tests GREEN, Y% coverage

Co-Authored-By: Claude Opus 4.7 (1M context) <noreply@anthropic.com>
```

### Step 7 — 회고 + 종료 보고 (Scrum Master)

**출력**: `sprints/sprint-N-retro.md`

포함 항목:
1. Sprint 결과 요약 (계획 vs 실제)
2. 잘된 점 (Keep) — 3~5개
3. 개선할 점 (Improve) — 3~5개
4. 시도할 것 (Try) — 2~3개
5. Sprint N+1 예고
6. 누적 메트릭 (velocity 추세, 테스트 수, 커버리지)
7. Phase 진행률

## 5. 에이전트 구성

| 역할 | 에이전트 타입 | 모델 | 호출 시점 |
|---|---|---|---|
| Scrum Master | 본체 (orchestrator) | opus | 전체 |
| Product Owner | `analyst` | opus | Step 2 |
| Architect | `architect` | opus(첫Sprint)/sonnet(이후) | Step 3 |
| QA | `executor` | sonnet | Step 4 |
| Developer | `deep-executor` | opus | Step 5 |

**병렬 실행 규칙**:
- Step 2 + Step 3: 병렬 가능 (범위 변경 < 20% 시)
- Step 4 + Step 5: 통합 가능 (단순 Sprint 시)
- Step 6: 항상 순차 (검증 후 커밋)

## 6. Guardrails

- **Jira Key 수동 입력 금지**: Story 파일에서 자동 추출
- **SP 합계 자동 검증**: Plan 작성 시 산술 오류 방지
- **이전 Sprint 테스트 회귀 금지**: 매 Step 5 후 전체 테스트 실행
- **Frontend 테스트 미검증 방지**: npm test 실행 가능하지 않으면 Sprint 시작 전 해결
- **FEATURES.md Status 갱신 강제**: Sprint 완료 시 Done으로 업데이트
- **Red 테스트는 의미있는 실패**: NotImplementedError 금지, assert 기반 실패
- **Refactor 단계 건너뛰기 금지**: Green 후 반드시 리팩터링 검토

## 7. Cost & Time (8 Story / 30 SP 기준)

| 단계 | 토큰 | 시간 |
|---|---|---|
| Step 0 Pre-flight | ~2k | 1분 |
| Step 1 Sprint Plan | ~5k | 2분 |
| Step 2 PO Review | ~15k (opus) | 3분 |
| Step 3 Architect Review | ~20k | 4분 |
| Step 4 QA Red | ~25k | 5분 |
| Step 5 Developer Green | ~30k | 8분 |
| Step 5.5 Refactor | ~5k | 2분 |
| Step 6 Verify + Commit | ~3k | 1분 |
| Step 7 Retro | ~5k | 2분 |
| **합계** | **~110k** | **~28분** |

## 8. When NOT to use
- 스토리 < 3개: 직접 TDD가 빠르다
- 아키텍처 미수립: `mv-arch-from-jira` 먼저
- 백로그 미정리: `mv-backlog-prioritize` 먼저

## 9. Chains
- 선행: `mv-feature-upsert` → `mv-backlog-prioritize` → `mv-arch-from-jira`
- 후행: `mv-sprint-retro` (자동 포함), `mv-verify-merge`
- 반복: Sprint N → Sprint N+1 (velocity 자동 이월)

## 10. 프로세스 개선 이력

| 버전 | 변경 | 근거 |
|---|---|---|
| v1.0 | Sprint 1 실행 | 초기 프로세스 수립 |
| v1.1 | PO+Architect 병렬화 | Sprint 2에서 에이전트 33% 감소 확인 |
| v1.2 | QA+Dev 통합 옵션 | 단순 Sprint에서 효율 향상 확인 |
| v1.3 | Jira Key 자동 매핑 | 3회 연속 수동 오류 발생 |
| v1.4 | Red 패턴 개선 | NotImplementedError → assert 기반 실패 |
| v1.5 | Refactor 단계 추가 | QA+Dev 회고에서 누락 지적 |
| v1.6 | FEATURES.md Status 갱신 | PO 회고에서 추적 불가 지적 |
| v1.7 | Frontend 테스트 강제 | 2 Sprint 미검증 방치 문제 |

## 11. References
- Sprint 1 Plan/Retro: `sprints/sprint-1-*.md`
- Sprint 2 Plan/Retro: `sprints/sprint-2-*.md`
- vibecode_base TDD: `~/workspace/vibecode_base/docs/`
- Scrum Guide 2020
