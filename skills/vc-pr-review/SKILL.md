---
name: vc-pr-review
description: 변경 브랜치/PR에 대해 5-레인(style/quality/api/security/performance) 병렬 리뷰를 돌려 심각도 매겨진 코멘트를 PR에 게시. Trigger when user says "리뷰 돌려", "pr review", "5-lane review", "변경분 리뷰", "코드 리뷰 자동".
---

# vc-pr-review — 5-Lane Parallel PR Review

> **vibecode_base 방법론 Phase 5 VERIFY의 사람 리뷰 보조**. 5개 리뷰 에이전트가 *병렬*로 같은 변경분을 본다.
> 참조: `~/workspace/vibecode_base/docs/05-quality-gates.md` §4

## 1. Triggers
- "리뷰 돌려줘"
- "pr review"
- "5-lane review"
- "변경분 리뷰"
- "코드 리뷰 자동"

## 2. Inputs
- 옵션 A: GitHub PR 번호 (예: `gh pr view 123`)
- 옵션 B: branch 이름 (origin 기준 diff)
- 옵션 C: 로컬 worktree (HEAD vs main)

## 3. Procedure

### Step A — Diff 수집
```bash
gh pr diff <N> > /tmp/review.diff      # PR
# 또는
git diff origin/main...HEAD > /tmp/review.diff  # branch/worktree
```
Diff 사이즈 점검: > 1,000 LOC면 PR 분할 권고(리뷰 표면 과대).

### Step B — 컨텍스트 로딩
- `./ARCHITECTURE.md` (컨테이너 경계·NFR)
- `./docs/coding-conventions.md`
- 해당 Story의 `jira/stories/<KEY>.md` (AC, Architecture Touchpoints)

### Step C — 5-Lane 병렬 리뷰

5개 에이전트를 *동시에* Task로 띄운다(`run_in_background`).

| Lane | Agent | Model | 보는 것 |
|---|---|---|---|
| Style | `style-reviewer` | haiku | 포맷, 네이밍, 컨벤션 |
| Quality | `quality-reviewer` | sonnet | 로직, 안티패턴, 가독성 |
| API | `api-reviewer` | sonnet | 계약, 버전 호환 |
| Security | `security-reviewer` | sonnet | OWASP, 인증/인가, 비밀 |
| Performance | `performance-reviewer` | sonnet | 핫스팟, 복잡도 |

각 에이전트 프롬프트:
```
입력: /tmp/review.diff, ./ARCHITECTURE.md, ./docs/coding-conventions.md
임무: 위 레인 관점에서만 review. 다른 레인 영역 침범 금지.
출력 (JSON):
  [
    { "severity": "blocker|major|minor|nit",
      "file": "...", "line": N,
      "title": "...", "rationale": "...",
      "suggestion": "..." (선택) }
  ]
```

### Step D — 집계 & 중복 제거
- 같은 file:line에 여러 레인 코멘트 → 하나로 머지(레인 라벨로 표기).
- Severity 매핑: `blocker → 🛑`, `major → ⚠️`, `minor → 💬`, `nit → 🪶`.
- 의견 충돌(예: Performance vs Quality) → 사람 결정 항목으로 분리.

### Step E — PR에 게시
```bash
gh pr review <N> --comment --body-file /tmp/review-summary.md
# 라인별 코멘트는:
gh api repos/<O>/<R>/pulls/<N>/comments -F body=... -F path=... -F line=...
```

요약 상단에:
- 총 코멘트 수 (severity 별)
- AC 일치 점검(Story §4 Test Plan과 매칭 누락 여부)
- *Blocker 0 + Major ≤ 3* 이면 `vc-verify-merge`로 진행 가능 표시.

## 4. Output
- `./review/<PR-or-branch>-summary.md` (집계 보고)
- PR에 라인별 코멘트 N개 + 상단 요약
- Jira 댓글(해당 Story 키 있을 시): "5-lane review: B=0 M=2 m=7"

## 5. Guardrails
- **레인 영역 침범 금지**. 각 에이전트는 자기 레인 코멘트만.
- **자동 머지 금지**. 이 스킬은 *코멘트만*. 머지 결정은 사람 + `vc-verify-merge`.
- **AI 리뷰는 자문**. 사람 1명 이상 승인 의무 유지.
- **민감 변경**(보안/스키마/배포 설정)은 *추가* 사람 리뷰어 자동 멘션.

## 6. Cost & Time (1,000 LOC PR)
- 토큰: ~40k (sonnet × 4 + haiku × 1, 병렬)
- 시간: 3~6분(병렬), 직렬 시 15~25분

## 7. Chains
- 선행: `vc-tdd-impl` (변경 브랜치 푸시 후)
- 후행: `vc-verify-merge`

## 8. When NOT to use
- Diff < 30 LOC — 사람 1명이 더 빠름.
- 비-코드 변경(문서·이미지) — 다른 스킬 또는 사람.

## 9. References
- `~/workspace/vibecode_base/docs/05-quality-gates.md`
- OWASP Top 10
- Google Engineering Practices — Code Review
