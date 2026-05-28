# Changelog

All notable changes to **my-vibe** will be documented in this file.
Format: [Keep a Changelog](https://keepachangelog.com/en/1.1.0/). Versioning: [SemVer](https://semver.org/).

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
