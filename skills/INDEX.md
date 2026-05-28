# vibecode_base Skill Suite — `mv-*` 13종

> vibecode_base 방법론(`/home/kwshim/workspace/vibecode_base/`)의 *전 과정*을 자동화하는 13개 Skill 묶음.
> 모든 스킬은 한국어·영어 트리거 모두 지원하며, 결과를 *파일과 Jira 양쪽*에 남겨 추적성을 보장.

---

## 1. 한 줄 카탈로그

| # | Skill | Phase | 역할 |
|---|---|---|---|
| 0 | `mv-setup` | setup | Jira·GitHub 연결정보 대화형 수집·검증·`.env` 생성 (전제 조건) |
| 1 | `mv-feature-upsert` | 0a-0c | Requirements MD → Epic/Story 자동 확장 → Jira upsert |
| 2 | `mv-backlog-prioritize` | 0d | MoSCoW/RICE/WSJF로 백로그 우선순위·랭크·라벨 |
| 3 | `mv-arch-from-jira` | 0.5 | Jira → C4 ARCHITECTURE.md + ADR + Tech Story |
| 4 | `mv-sprint-plan` | 0.7 | 응집도 + velocity 기반 스프린트 구성 + Jira Sprint 생성 |
| 5 | `mv-tdd-redgen` | 4 RED | 다음 Story → AC별 실패 테스트 생성 |
| 6 | `mv-tdd-impl` | 4 GREEN+REFACTOR | Worktree에서 컨벤션·아키 지키며 구현 |
| 7 | `mv-pr-review` | 5 | 5-레인 병렬 리뷰 (style/quality/api/security/perf) |
| 8 | `mv-verify-merge` | 5 | 전체 게이트 + AC 매핑 + 머지 |
| 9 | `mv-release` | post-5 | 태그·스모크·카나리·롤백 + Jira Epic Done |
| 10 | `mv-incident-to-test` | 회귀 방지 | 프로덕션 버그 → 재현 RED → 픽스 → 영구 회귀 |
| 11 | `mv-sprint-retro` | 학습 루프 | 스프린트 지표·ADR 델타·다음 용량 보정 |
| 12 | `mv-sprint-run` | Sprint 전체 | **완결-기반**(No Time Box) 오케스트레이션 — Plan→PO→Arch→QA Red→Dev Green→**독립 Verifier 게이트**→PO 데모 Accept→Retro. 모든 Feature Verifier PASS까지 루프 (v2.0) |

---

## 2. 표준 흐름 — 12단계

```
(처음 1회)
/mv-setup → .env + 연결 검증 + setup-report.md
  │
  ▼
요구 텍스트
  │
  │ /mv-feature-upsert
  ▼
FEATURES.md + jira/{epics,stories}/*.md ──▶ Jira
  │
  │ /mv-backlog-prioritize
  ▼
점수·랭크·라벨 갱신 + PLAN-candidate.md
  │
  │ /mv-arch-from-jira
  ▼
ARCHITECTURE.md + adr/*.md + Jira Tech Stories
  │
  │ /mv-sprint-plan (스프린트 시작 시점마다)
  ▼
응집도 클러스터 → Jira Sprint(Future) + ./sprints/<id>.md
  │
  ▼ (Story 1개씩 반복)
  ┌───────────────────────────────────────────┐
  │ /mv-tdd-redgen   → 실패 테스트            │
  │ /mv-tdd-impl     → 통과 코드 (worktree)   │
  │ /mv-pr-review    → 5-레인 리뷰            │
  │ /mv-verify-merge → 증거 PASS + 머지        │
  └───────────────────────────────────────────┘

  ★ 또는 한 번에 — /mv-sprint-run (완결-기반 오케스트레이터, v2.0):
    Pre-flight → Plan → PO 리뷰 → Architect 리뷰 → QA Red → Dev Green
        → ★독립 Verifier 게이트(DoD 증거 확인) → PO 데모 Accept → 회고
    Time Box 없음 — 모든 Feature가 Verifier PASS + PO Accept 받을 때까지 루프.
    자기보고 PASS·시간 종료를 구조적으로 차단(v1.x 오종료 사고 방지).
  │
  │ (Epic 단위 묶음)
  │ /mv-release
  ▼
배포된 버전 + 롤백 플랜
  │
  ├─ 프로덕션 버그 발생 → /mv-incident-to-test
  │
  └─ 스프린트 종료 → /mv-sprint-retro → 다음 사이클 PLAN 보정
```

---

## 3. Chaining Matrix

| 선행 ↓ → 후행 | setup | upsert | prio | arch | plan | red | impl | review | verify | release | incident | retro |
|---|---|---|---|---|---|---|---|---|---|---|---|---|
| `mv-setup` | — | ✅ | — | — | — | — | — | — | — | — | — | — |
| `mv-feature-upsert` | — | — | ✅ | ✅ | — | — | — | — | — | — | — | — |
| `mv-backlog-prioritize` | — | — | — | ✅ | ✅ | ✅ | — | — | — | — | — | — |
| `mv-arch-from-jira` | — | — | — | — | ✅ | ✅ | ✅ | — | — | — | — | — |
| `mv-sprint-plan` | — | — | — | — | — | ✅ | — | — | — | — | — | — |
| `mv-tdd-redgen` | — | — | — | — | — | — | ✅ | — | — | — | — | — |
| `mv-tdd-impl` | — | — | — | — | — | — | — | ✅ | ✅ | — | — | — |
| `mv-pr-review` | — | — | — | — | — | — | — | — | ✅ | — | — | — |
| `mv-verify-merge` | — | — | — | — | — | — | — | — | — | ✅ | — | — |
| `mv-release` | — | — | — | — | — | — | — | — | — | — | — | ✅ |
| `mv-incident-to-test` | — | — | — | — | — | — | — | ✅ | ✅ | ✅ | — | — |
| `mv-sprint-retro` | — | — | — | — | ✅ | — | — | — | — | — | — | — |

✅ = 직후 일반적인 다음 스킬.

> **`mv-sprint-run`은 오케스트레이터** — 위 매트릭스의 *plan → (red→impl→review→verify) → retro* 구간을
> 스크럼 마스터 본체가 PO·Architect·QA·Developer 서브에이전트를 호출하며 한 번에 수행한다.
> 개별 스킬을 손으로 체이닝하는 대신 `/mv-sprint-run` 한 줄로 스프린트 전체를 돌릴 때 사용.
> 선행: `mv-feature-upsert` → `mv-backlog-prioritize` → `mv-arch-from-jira`.

---

## 4. 공통 전제 (모든 스킬)

### 필수 동반 플러그인 — oh-my-claudecode (OMC)
오케스트레이션 스킬은 OMC 역할 에이전트(`oh-my-claudecode:analyst·architect·executor·
deep-executor·verifier·test-engineer·critic·*-reviewer·debugger·writer·product-analyst`)를
**호출**한다(전용 에이전트 vendoring 안 함 — frozen 방지, OMC 업데이트 자동 상속).
미설치 시 오케스트레이션 품질 저하. 상세 매핑·폴백은 README §3 "필수 동반 플러그인" 참조.

### 환경 변수
```
JIRA_BASE_URL=https://<org>.atlassian.net
JIRA_EMAIL=<user>
JIRA_API_TOKEN=<token-from-1Password>   # 절대 코드에 하드코딩 금지
JIRA_PROJECT_KEY=<KEY>
```

### 방법론 문서 위치
- `~/workspace/vibecode_base/METHODOLOGY.md`
- `~/workspace/vibecode_base/docs/01..10-*.md`
- `~/workspace/vibecode_base/templates/*.template`

### 결과 파일 규약 (프로젝트 루트)
```
FEATURES.md              백로그(정형)
PLAN.md / PLAN-candidate.md   실행 계획
ARCHITECTURE.md          C4 + NFR
adr/NNN-*.md             결정 기록
jira/epics/*.md          Epic 1:1 마크다운
jira/stories/*.md        Story 1:1 (AC + Test Plan)
jira/tech-stories/*.md   ARCH에서 파생된 Tech Story
verify/<KEY>/L*.log      검증 증거
review/<PR>-summary.md   리뷰 집계
retro/<sprint>.md        회고
incidents/<date>-<KEY>.md  포스트모템
release-notes/<ver>.md
```

---

## 5. 안전 가드 — 모든 스킬 공통

- **자기보고 PASS 금지** — Verifier 평결 없이 진행 없음.
- **사람 사인오프 필요 지점**: NFR 우선순위 확정, Major/Minor 릴리스, 자동 우선순위 변경 적용, 핫픽스 배포.
- **비밀 토큰 git-tracked 금지** — pre-commit hook으로 차단 권장.
- **워크트리 격리 사용** — 본 레포에서 직접 작업 지양.
- **Won't 항목은 Jira 생성하지 않음** — FEATURES.md에만 남김.

---

## 6. 빠르게 시작 (Day 0)

새 제품:
```
1. /mv-feature-upsert   (input.md 또는 FEATURES.md)
2. /mv-backlog-prioritize
3. /mv-arch-from-jira
4. (반복) /mv-tdd-redgen → /mv-tdd-impl → /mv-pr-review → /mv-verify-merge
5. /mv-release   (Epic 또는 마일스톤 끝)
6. /mv-sprint-retro  (스프린트 끝)
```

운영 중 사고:
```
/mv-incident-to-test  → /mv-release --hotfix → /mv-sprint-retro (다음 회고에 반영)
```

---

## 7. 비용 모델 (참고치)

| 사이클 | 토큰(추정) | 시간 |
|---|---|---|
| Day 0 전체(1~3) | ~130k | 2~3시간 + 사람 검토 |
| Story 1개(4~7) | ~60k | 1~3시간 |
| 릴리스(8) | ~15k | 30분~2시간(배포) |
| 사고 대응(9) | ~15k | 30분~2시간(Sev에 따름) |
| 회고(10) | ~20k | 10분 자동 + 30분 미팅 |

기준: Sonnet 4.6 메인, Opus 4.7는 분석·아키텍처 단발만.

---

## 8. 한계 (이 스킬 묶음이 *못 하는* 것)

- **사용자 인터뷰·디스커버리**: 사람이 해야 한다. 결과를 `input.md`로 가져오면 1번부터 동작.
- **데이터 마이그레이션 설계**: 큰 스키마 변경은 ADR + 사람 주도 릴리스.
- **이해관계자 합의**: 우선순위 *제안*은 자동, 결정은 사람.
- **창의적 UX 디자인**: `frontend-design` 또는 `oh-my-claudecode:frontend-ui-ux` 별도.
- **사내 정책·규제 해석**: 보안/법무 전문가 자문 필요.

이 한계들 안에서 *반복적·기록 가능한* 작업은 모두 자동화된다.

---

## 9. 트러블슈팅

- 스킬이 매칭 안 됨 → 트리거 키워드를 정확히 또는 `/mv-<name>` 명시 호출.
- Jira 권한 에러 → `JIRA_API_TOKEN` 확인, 프로젝트 권한.
- MCP 없음 → REST 모드로 자동 폴백(`Atlassian MCP` 미설치 시).
- 토큰 초과 → 각 스킬 §6 비용 가이드. `/clear` 또는 `mv-tdd-impl`을 worktree 격리로.

---

## 10. 변경 이력

| 날짜 | 변경 |
|---|---|
| 2026-05-27 | v1.0 — 10개 스킬 초안 배포 (mv-feature-upsert ~ mv-sprint-retro) |
