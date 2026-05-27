# Changelog

All notable changes to **my-vibe** will be documented in this file.
Format: [Keep a Changelog](https://keepachangelog.com/en/1.1.0/). Versioning: [SemVer](https://semver.org/).

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
