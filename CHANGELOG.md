# Changelog

All notable changes to **my-vibe** will be documented in this file.
Format: [Keep a Changelog](https://keepachangelog.com/en/1.1.0/). Versioning: [SemVer](https://semver.org/).

## [1.2.0] — 2026-05-29

### Added (Sprint 7~13 실측 페인 기반 배치)
- **신규 스킬 4개** (13 → 17종):
  - `mv-ui-verify` (🟥 P4) — 빠른 UI 게이트: Playwright 웜 세션(storageState) 재사용 +
    screen-smoke/full-e2e 2티어 + 헬스 대기. 검증 신뢰도 유지하며 속도 ↑.
  - `mv-data-import` (🟧) — Excel/CSV → 도메인 멱등 import: 헤더검증·PII마스킹·자연키 upsert·
    `--target both`(erp+test, P6)·`--dry-run`·매칭률 리포트·감사로그 우회.
  - `mv-hygiene` (🟧 P3) — 경계 위생: stale 프로세스(20분+) kill·데모행 정리·컨테이너 헬스 대기.
  - `mv-feature-from-excel` (🟨) — 미활용 데이터 컬럼 → 기능 후보 역발굴 → FEATURES.md.
- **신규 에이전트 `agents/verifier.md`** (🟨) — 독립 검증 전용. `tools: Read, Bash, Glob, Grep`로
  **Write/Edit 비활성**(이해상충 차단). mv-sprint-run Step 6 게이트가 소환. UI는 Playwright(curl 금지).
  → 전용 에이전트 vendoring 예외: *도구 제약(검증 독립성)* 이 하드 요구라 OMC 위임 대신 번들.

### Changed
- **`mv-sprint-run` v2.0 → v2.1 + v3.0**:
  - v2.1: **UI는 Playwright 실 브라우저로 검증(curl 금지)** — `{role_level}` 객체를 React 자식으로 렌더해
    React #31 화면 크래시(curl·API·mock 전부 GREEN이었음) 사고 방지. QA는 화면 기준 상세 테스트케이스 작성.
  - v3.0(병렬 클러스터): worktree per cluster(P1·P2) · single-migration-owner(P5) ·
    clean-gate-after-all + mv-hygiene(P7) · import both(P6) · agent time cap(P3) ·
    UI는 mv-ui-verify(P4) · Verifier 전용 에이전트.
- INDEX 카탈로그 17종 + verifier 에이전트, README 역할표 갱신.

### Note
- plugin.json/marketplace.json 설명 갱신, minor bump(신규 스킬·에이전트). agents/ 디렉터리 신설.
- 마켓플레이스 설치 시 `agents/verifier` 자동 등록. 로컬 install.sh는 skills만(agents는 마켓플레이스 경로).
- Tarball: `my-vibe-1.2.0.tgz` (skills 17 + agents/ + .mcp.json + hooks/ 포함).

## [1.1.1] — 2026-05-28

### Changed
- **`mv-sprint-run` 최신 inbox본(21:51) 반영·발행**:
  - inbox 요청서가 다시 갱신(187→248줄)됨 — 패키지 본문을 그 상위집합으로 정리
    (요청서 마커 제거, §8 When NOT to use / §9 Chains / §10 References 보강).
  - v1.1.0까지는 작업트리에만 있고 미발행 상태였던 변경을 정식 릴리스로 커밋.
- inbox 반영 검증 완료: `mv-sprint-plan`(v1.0.9 발행, §6 기준 4/4) + `mv-sprint-run`(이번 발행).

### Note
- 콘텐츠 변경만(스킬 수 13 유지, MCP/hooks 변경 없음). patch bump.
- Tarball: `my-vibe-1.1.1.tgz` (SHA256 갱신).

## [1.1.0] — 2026-05-28

### Added
- **`.mcp.json` — Jira + GitHub MCP 서버 번들 (B)**:
  - `atlassian`: `uvx mcp-atlassian`, `.env`의 `JIRA_BASE_URL`/`JIRA_EMAIL`/`JIRA_API_TOKEN`을
    `${VAR}`로 주입(비밀 커밋 안 됨).
  - `github`: remote `https://api.githubcopilot.com/mcp/` (http), `Bearer ${GITHUB_TOKEN}`.
  - MCP 활성 시 스킬이 REST 수동 호출 대신 MCP 도구 우선 사용, 미설정 시 REST 폴백.
- **`hooks/hooks.json` — 안전 가드 훅 (C)**:
  - `PreToolUse(Bash)` → `guard-secrets.sh`: `git add/commit`이 `.env`·`credentials.*`·`*.pem`·
    `id_rsa` 등 비밀 파일을 staging하면 **deny**. (테스트: .env/credentials.json 차단, 일반 소스 허용)
  - `PostToolUse(Write|Edit)` → `env-gitignore-check.sh`: `.env` 작성 시 `.gitignore` 미포함이면
    **비차단 경고**.
- README §3에 "번들 구성요소 — MCP & Hooks" 표 추가, 권장 도구에 `uv/uvx` 명시.

### Changed
- INDEX 흐름도 v2.0 정합성 수정: `mv-sprint-plan`은 *리뷰용 MD만 생성(Jira 미기록)* → 사람 Sign-off
  → `mv-sprint-run`이 *MD 로드 → Jira 반영 → 실행(Verifier 게이트)*. 이전의 "plan이 Jira Sprint 생성"
  표기 제거(inbox 요청서 §6 검증 기준 충족).

### Verification (inbox 반영 확인)
- `inbox/mv-sprint-plan.md`(v2.0 요청서) 검증 기준 5항목 — 패키지 충족 확인 (협업 4멤버·회고→Feature·
  Jira 미기록 Guardrail·run Step1 MD로드·INDEX 흐름도 갱신).
- `inbox/mv-sprint-run.md`(v2.0) — 패키지 본문과 일치(완결-기반 + Verifier 게이트 + Step1 MD로드).

### Note
- 설치 경로: 마켓플레이스 설치 시 `.mcp.json`·`hooks/` 자동 적용. 로컬 `install.sh`(심볼릭 링크)는
  skills만 설치 → MCP/hooks가 필요하면 마켓플레이스 설치 사용.
- minor 버전 bump(1.0.x → 1.1.0): 새 플러그인 구성요소(MCP·hooks) 추가.
- Tarball: `my-vibe-1.1.0.tgz` (.mcp.json + hooks/ 포함, SHA256 갱신).

## [1.0.9] — 2026-05-28

### Added
- **OMC 의존성 명시 문서화** (README §3 "필수 동반 플러그인" + INDEX §4):
  - my-vibe는 전용 서브에이전트를 *vendoring하지 않고* OMC 역할 에이전트(`oh-my-claudecode:*`)를
    호출한다는 설계 의도를 명문화.
  - 근거: 전용 에이전트로 복제하면 frozen 스냅샷이 되어 OMC 프롬프트·모델 라우팅 개선을
    못 받음. my-vibe는 *워크플로*만 정의하고 *역할 수행*은 OMC에 위임해 업데이트 자동 상속.
  - 14종 OMC 에이전트 → 사용 스킬 매핑 표, 정식 ID(`oh-my-claudecode:<agent>`), 미설치 폴백 명시.

### Changed
- **`mv-sprint-plan` v2.0 (협업 계획)**: 스크럼 마스터 단독이 아니라 PO·Architect·QA·Developer(+Critic)
  서브에이전트 협업으로 계획. 직전 회고 Improve/Try를 신규 Feature/Story로 변환. 산출물은
  *사람 리뷰용 sprint-plan MD* — **Jira에 쓰지 않음**(반영은 mv-sprint-run으로 이관).
- **`mv-sprint-run` 역할 재정의**: 계획을 직접 세우지 않고 `mv-sprint-plan`의 승인된 MD를 *읽어*
  Jira 반영(신규 Story upsert + Sprint Active) 후 QA Red→Dev Green→Verifier 게이트 실행.
  계획(plan)과 실행(run)의 책임 분리 명확화.
- velocity는 **Verifier PASS 기준 SP**만 사용(과대보고 차단) — 양 스킬 공통.

### Note
- 카탈로그 13종 유지. plugin.json은 공식 7필드만 유지(의존성은 plugin.json이 아닌 README/INDEX 문서화).
- Tarball: `my-vibe-1.0.9.tgz` (SHA256 갱신).

## [1.0.8] — 2026-05-28

### Changed
- **`mv-sprint-run` v1.x → v2.0 (완결-기반 + 독립 Verifier 게이트)**:
  - **No Time Boxing** — Sprint는 시간이 아니라 *할당된 모든 Feature가 Verifier PASS + PO 데모 Accept*를
    받을 때 종료. 미완이 1개라도 있으면 Step 5~6 루프 계속.
  - **Step 6 Verification Gate 신규 강제** — Developer 자기보고를 신뢰하지 않고 독립 `verifier`가
    DoD 전 항목을 *증거*(pytest/npm test 로그, coverage, 린트, 앱 기동, E2E)로 확인. FAIL 시 반려·재작업.
  - **6역할 분리** — Scrum Master / PO(`analyst`) / Architect / QA(`executor`·`test-engineer`) /
    Developer(`deep-executor`) / **Verifier(`verifier`)**. Developer는 자기 코드 검증 금지(이해상충).
  - **Frontend 실행 증거 필수** — "컴포넌트만 작성" Done 금지. npm test 실행 불가 시 FAIL.
  - **데모는 종료 전 Sprint 내에서**(Step 7) — 종료 후 갭 발견 사고 방지.
  - 8-Step 절차 + 완결 루프 의사코드 포함.

### Why
- v1.x 실전에서 스크럼 마스터가 Developer 자기보고("147 tests GREEN")만 믿고 Frontend 미통합·
  docker-compose 부재·E2E 미검증 상태로 Sprint를 "100% 완료" 오종료한 사고. 근본 원인인
  *Verifier 게이트 부재 + 시간 기반 종료*를 v2.0에서 구조적으로 차단.

### Note
- 카탈로그 수는 13종 유지(스킬 추가가 아니라 기존 `mv-sprint-run` 명세 개정).
- frontmatter는 v2.0 설명으로 갱신(완결-기반·Verifier 게이트 반영).
- Tarball: `my-vibe-1.0.8.tgz` (SHA256 갱신).

## [1.0.7] — 2026-05-28

### Added
- 신규 스킬 **`mv-sprint-run`** (다른 에이전트 기여, 2회 실전 스프린트에서 도출):
  - 스크럼 마스터 오케스트레이터 — Step 0 Pre-flight → Plan → PO 리뷰 → Architect 리뷰
    → QA TDD Red → Developer TDD Green → Refactor → 검증/커밋 → 회고 (7-Step + Step 0/5.5).
  - 서브에이전트 구성: PO=`analyst`, Architect=`architect`, QA=`executor`, Dev=`deep-executor`.
  - 병렬화 규칙(범위 변경 <20% 시 PO+Architect 병렬), QA+Dev 통합 옵션(단순 스프린트).
  - Jira Key 자동 추출, SP 합계 자동 검증, NotImplementedError 금지(assert 기반 Red),
    FEATURES.md Status 갱신 강제, Frontend 테스트 검증 강제.
- INDEX 카탈로그 12종 → **13종** (#12 = mv-sprint-run, phase=Sprint 전체).

### Changed
- INDEX 흐름 다이어그램에 *★ 한 번에 — /mv-sprint-run* 오케스트레이터 분기 추가.
- 체이닝 매트릭스 하단에 mv-sprint-run 오케스트레이터 설명 추가 (선행: upsert→prioritize→arch).
- `mv-sprint-plan`(계획만) vs `mv-sprint-run`(실행까지) 역할 구분 명시.
- 받은 원본 파일에 YAML frontmatter(name/description/triggers) 추가 — 자동 등록 가능하게.
- Tarball: `my-vibe-1.0.7.tgz` (SHA256 갱신).

### Housekeeping
- `inbox/`를 `.gitignore`에 추가 (수신 스킬 staging 폴더 — 배포물에서 제외).
- 잘못된 위치의 flat 파일 `~/.claude/skills/mv-sprint-run.md` 제거, 디렉터리 심볼릭 링크로 교정.

## [1.0.6] — 2026-05-27

### Changed
- `mv-setup` 재실행 UX 개선 — **엔터-유지 원칙**:
  - 기존 `.env`의 모든 값을 자동으로 로드 → 각 입력 프롬프트의 *기본값*으로 노출
    (시크릿은 `****ABCD` 형식으로 마지막 4자만).
  - 빈 입력(엔터만) → *기존 값 그대로 유지*. 새 값을 명시한 필드만 교체.
  - 검증 실패(형식 오류) 시 *재입력 루프* — 기존 값은 보존.
  - 입력 단계에서는 검증 안 함 — Step C에서 *최종 일괄 검증*.
- `setup-report.md`에 *Changed fields* / *Unchanged fields* 섹션 분리 — 무엇이 바뀌었는지 한눈에.

### Why
- 일부 필드만 갱신하려고 전체 12+ 항목을 다시 입력하는 부담 제거.
- 토큰 같은 시크릿을 *불필요하게 다시 노출*시키지 않음(엔터 한 번 = 안전 유지).
- 형식 오류로 한 필드가 막혀도 다른 정상 항목들을 잃지 않음.

## [1.0.5] — 2026-05-27

### Added
- 신규 스킬 **`mv-setup`** (Phase: setup, *모든 mv-* 스킬의 전제 조건*):
  - Jira 연결정보 4종(JIRA_BASE_URL · JIRA_EMAIL · JIRA_API_TOKEN · JIRA_PROJECT_KEY) 대화형 수집.
  - GitHub 인증 3가지 옵션 (SSH 권장 / PAT / gh CLI) + GITHUB_REPO.
  - 실시간 검증: `curl /rest/api/3/myself`로 Jira, `ssh -T` 또는 `curl /user`로 GitHub.
  - `.env` (chmod 600, gitignored) + `.env.example` (committed) + `.gitignore` 항목 자동 갱신.
  - `./setup-report.md` 생성 — 통과/실패 항목 + 다음 단계 안내.
  - 멱등 — 재실행 시 기존 값 백업(`.env.bak.<ts>`) + 변경 항목만 갱신.

### Changed
- INDEX 카탈로그: 11종 → **12종**. `mv-setup`을 `#0`(phase=setup)으로 표 맨 위에 배치.
- 표준 흐름 다이어그램에 *처음 1회 mv-setup* 단계 추가.
- 체이닝 매트릭스에 setup 열/행 추가: `mv-setup` → `mv-feature-upsert`로 연결.
- Tarball: `my-vibe-1.0.5.tgz` (SHA256 갱신).

### Security
- 토큰 *마스킹* 정책 명시: 모든 출력에서 마지막 4자만 노출.
- `.env` 쓰기 전 `.gitignore` 사전 확인 게이트.

## [1.0.4] — 2026-05-27

### Added
- 신규 스킬 **`mv-sprint-plan`** (Phase 0.7):
  - 전체 백로그 + FEATURES.md를 읽어 응집도(같은 Epic·컴포넌트·의존성·Persona·Theme) 기반 클러스터링.
  - 직전 3 스프린트 velocity × 0.85 buffer로 용량 계산.
  - Greedy + WIP-aware 선택 알고리즘 → 데모 가능한 클러스터만 포함.
  - Jira Sprint(Future 상태) 생성 + Story 할당 + `./sprints/<id>.md` 생성.
  - 사람 사인오프 게이트 전까지 Sprint 활성화 금지.
- INDEX 카탈로그 10종 → **11종**. Phase 순서 0a → 0d → 0.5 → **0.7** → 4 → 5 → post-5 → 회귀 → 학습.

### Changed
- 체이닝 매트릭스에 `mv-sprint-plan` 행/열 추가:
  - `mv-backlog-prioritize` → `mv-sprint-plan` (Story 점수가 입력)
  - `mv-arch-from-jira` → `mv-sprint-plan` (컴포넌트 경계가 응집도 입력)
  - `mv-sprint-plan` → `mv-tdd-redgen` (스프린트 내 Story가 차례로 픽업)
  - `mv-sprint-retro` → `mv-sprint-plan` (velocity 피드백)
- Tarball: `my-vibe-1.0.4.tgz` (SHA256 갱신).

## [1.0.3] — 2026-05-27

### Fixed
- `.claude-plugin/plugin.json` 매니페스트 스키마 위반 해결:
  - `repository`: 객체(`{type, url}`) → **문자열** (Claude Code는 문자열만 허용).
  - 사용자 정의 `skills[]` 배열 **제거** (Claude Code는 `skills/` 디렉터리를 *자동 탐색*).
  - 보수적 검증 회피용으로 `displayName`, `keywords`, `engines`, `methodology`, `requirements` 같은 *비표준 필드 모두 제거*.
- 결과: `/plugin install my-vibe@my-vibe` 시 *"Validation errors: repository ... / skills ..."* 에러 해결.

### Changed
- 매니페스트는 최소 7개 공식 필드만 유지: `name`, `description`, `version`, `author`, `homepage`, `repository`, `license`.
- Tarball: `my-vibe-1.0.3.tgz` (SHA256 갱신).

## [1.0.2] — 2026-05-27

### Fixed
- `.claude-plugin/marketplace.json` `plugins[].source` 스키마 수정:
  - ❌ `"type": "git"` → ✅ `"source": "github"` (Claude Code가 지원하지 않는 키 값이었음)
  - 설치 시 *"This plugin uses a source type your Claude Code version does not support"* 에러 해결.

### Changed
- Tarball: `my-vibe-1.0.2.tgz` (SHA256 갱신).

## [1.0.1] — 2026-05-27

### Added
- `.claude-plugin/plugin.json` — Claude Code 마켓플레이스 호환 매니페스트 위치.
- `.claude-plugin/marketplace.json` — 단일 플러그인 카탈로그 정의.
- README §2.1에 *마켓플레이스 설치* 안내 추가:
  - `/plugin marketplace add quus/my-vibe`
  - `/plugin install my-vibe@my-vibe`

### Changed
- `plugin.json`을 루트에서 `.claude-plugin/` 아래로 이동. version 1.0.1로 bump.
- 배포용 tarball: `my-vibe-1.0.1.tgz` (SHA256 갱신).

### Notes
- 기존 `install.sh` 심볼릭 링크 설치는 *대안 경로*로 유지(오프라인/포크 사용 케이스).

## [1.0.0] — 2026-05-27

### Added
- 초기 패키지 v1.0.0. 10개 mv-* 스킬과 인덱스 문서 1개:
  - `mv-feature-upsert` — Requirements MD → Epic/Story → Jira upsert
  - `mv-backlog-prioritize` — MoSCoW / RICE / WSJF 점수화 및 랭킹
  - `mv-arch-from-jira` — Jira → C4 + ADR + Tech Story
  - `mv-tdd-redgen` — 다음 Story → AC별 실패 테스트
  - `mv-tdd-impl` — git worktree에서 GREEN + REFACTOR
  - `mv-pr-review` — 5-lane 병렬 리뷰
  - `mv-verify-merge` — 전체 게이트 + AC↔테스트 매핑 + 머지
  - `mv-release` — 태그·CHANGELOG·카나리·롤백
  - `mv-incident-to-test` — 운영 버그 → 재현 RED → 픽스 → 영구 회귀
  - `mv-sprint-retro` — 지표·ADR 델타·다음 용량 보정
- `install.sh` / `uninstall.sh` — symlink 기반 설치/제거
- `plugin.json` 매니페스트
- `README.md` 사용 안내
- 배포용 tarball (`dist/my-vibe-1.0.0.tgz`) + SHA256

### References
- Based on methodology: [vibecode_base](../vibecode_base/) (Phase 0 → 0.5 → 1~5 + TDD)
