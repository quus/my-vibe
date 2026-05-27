---
name: mv-release
description: 마일스톤 또는 Epic 단위로 릴리스를 컷팅 — 태그·CHANGELOG·스테이징 배포·스모크·카나리·롤백 플랜 기록 + Jira Epic을 Done으로 전환. Trigger when user says "릴리스 시작", "cut release", "vc release", "배포 파이프라인", "tag and deploy", "릴리스 노트".
---

# mv-release — Release Pipeline (Epic/Milestone)

> **vibecode_base 방법론 Phase 5 이후**: 머지된 Story들을 사용자에게 *실제로* 보낸다.
> 단순 배포가 아니라 *증거가 기록되는* 릴리스.
> 참조: `~/workspace/vibecode_base/docs/05-quality-gates.md` §7 Release Gate

## 1. Triggers
- "릴리스 시작"
- "cut release"
- "vc release"
- "배포 파이프라인"
- "tag and deploy"
- "릴리스 노트 생성"

## 2. Inputs
- 옵션 A: Jira Epic Key (예: `PROJ-50`)
- 옵션 B: Milestone 이름 (PLAN.md의 `M1` 등)
- 옵션 C: 명시적 커밋 범위 (`from..to`)
- 릴리스 종류: `major | minor | patch | hotfix`
- 대상 환경: `staging | canary | production`

## 3. Procedure

### Step A — 사전 점검
1. main 브랜치 그린 확인 (`gh run list --branch main --limit 5`).
2. 포함될 Story 전부 Status=`Done` 확인. 미닫힘 있으면 *중단*.
3. ADR 누락 점검 — 새 결정이 있는데 ADR 없으면 *중단*.

### Step B — 버전 결정 (SemVer)
```
이전 버전(예: 1.4.2) + 변경 분석
  - Breaking change in API → major (2.0.0)
  - Backward-compatible 기능 추가 → minor (1.5.0)
  - 버그 픽스만 → patch (1.4.3)
  - hotfix는 별도 브랜치 → patch (1.4.3 → 1.4.4)
```
모델이 자동 추정 + 사람 1줄 확인.

### Step C — CHANGELOG & Release Notes (`writer`, haiku)
- Conventional Commits 머지 기록 분석 → `feat:`, `fix:`, `breaking:` 분류.
- 두 가지 출력:
  - `CHANGELOG.md` (개발자용, 상세) — feat/fix/internal/breaking 섹션.
  - `release-notes/<version>.md` (사용자용, 친절) — "무엇이 바뀌었나" 사람 말로.
- 각 항목 끝에 Jira Story Key 링크.

### Step D — Tag & Build
```bash
git tag -a v<version> -m "Release v<version>"
git push origin v<version>
# CI가 빌드·아티팩트 생성 트리거
```

### Step E — Staging 배포 + 스모크
1. CI/CD로 staging 배포 (`gh workflow run deploy-staging.yml -f version=v<version>`).
2. 헬스체크 응답 200.
3. 스모크 테스트 스위트 실행 (5분 이내) → 그린 확인.
4. 실패 시 *진행 중단*, rollback 자동 실행.

### Step F — 카나리 (Production)
- 트래픽 1% → 5% → 25% → 100% (각 단계 N분 모니터링).
- 모니터링 임계값(p95, 에러율, RPS) 자동 점검.
- 임계 초과 시 자동 롤백 + 알림.

### Step G — 롤백 플랜 기록
- *모든 릴리스에* 롤백 절차 1페이지 기록 (`release-notes/<version>-rollback.md`).
  - 이전 안정 버전 태그
  - 마이그레이션 역적용 명령(있다면)
  - 트래픽 즉시 차단 절차
  - 책임자(on-call)

### Step H — Jira 정리 & 공지
- Epic Status → `Done`. 자식 Story 모두 `Released` 라벨.
- 알림(Slack/팀즈) — release-notes 링크.
- README/문서의 *최신 버전 배지* 자동 갱신.

## 4. Output
- 새 Git tag (예: `v1.5.0`)
- `CHANGELOG.md` 갱신 + `release-notes/<version>.md` 신규
- 배포 완료 (staging→canary→prod) + 스모크 통과 증거
- `release-notes/<version>-rollback.md`
- Jira Epic Done + 알림 메시지

## 5. Guardrails
- **빨간 main 위에서 릴리스 금지.**
- **롤백 플랜 없이는 prod 배포 안 됨.**
- **카나리 임계 초과 시 사람 결정 없이 자동 롤백.** 모델 판단으로 강행 금지.
- **major 버전 변경**은 사람 1명 추가 승인 의무.
- **hotfix**는 별도 브랜치(`release/x.y`)에서, main에 cherry-pick.

## 6. Cost & Time
- 토큰: ~15k (writer + verifier)
- 시간: 30분~2시간 (배포·카나리 모니터링 포함)

## 7. Chains
- 선행: `mv-verify-merge` (해당 Story 머지 완료)
- 후행: `mv-sprint-retro` (필요 시)

## 8. When NOT to use
- 1 Story만 머지한 일상 패치 — 일반 CI/CD로 충분.
- 인프라/스키마 큰 변경 — *전용 ADR + 사람 주도* 릴리스.

## 9. References
- SemVer 2.0 — semver.org
- Conventional Commits — conventionalcommits.org
- Charity Majors — Why I Love Boring Deploys
- `~/workspace/vibecode_base/docs/05-quality-gates.md` §7
