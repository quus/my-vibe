# Changelog

All notable changes to **my-vibe** will be documented in this file.
Format: [Keep a Changelog](https://keepachangelog.com/en/1.1.0/). Versioning: [SemVer](https://semver.org/).

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
