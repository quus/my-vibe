---
name: mv-verify-merge
description: Story 단위 변경에 대해 전체 테스트 + AC↔테스트 매핑 + Verifier 증거를 수집하고 트렁크에 머지(또는 PR 머지). 실패 시 Jira에 새 태스크 등록. Trigger when user says "verify and merge", "검증 후 머지", "DoD 점검", "AC 매핑 검증", "evidence pass".
---

# mv-verify-merge — Final Verification & Merge

> **vibecode_base 방법론 Phase 5 VERIFY**의 최종 게이트.
> *증거 없는 머지는 없다.* 자기보고 PASS 금지.
> 참조: `~/workspace/vibecode_base/docs/05-quality-gates.md`, `docs/06-checklists.md`

## 1. Triggers
- "verify and merge"
- "검증 후 머지"
- "DoD 점검"
- "AC 매핑 검증"
- "evidence pass"

## 2. Inputs
- 옵션 A: PR 번호 (`gh pr view <N>`)
- 옵션 B: branch + Jira Story Key
- 머지 모드: `pr-merge`(GitHub PR 머지) / `fast-forward`(직접 트렁크 머지, 권장 안 함)

## 3. Procedure

### Step A — Sync & Rebase
```bash
git fetch origin
git checkout <branch>
git rebase origin/main          # 충돌 시 → 사람에게 알리고 중단
```

### Step B — 전체 게이트 (L1~L3)
순서대로 실행, 어느 하나 실패 시 *FAIL 보고 후 중단*.

```bash
# L1: 자동
<format-check>
<lint>
<typecheck>
# L2: 단위
<unit-test>
# L3: 통합·E2E (스모크 레벨)
<integration>
<e2e-smoke>     # 시간 ≤ 5분 부분집합
```

각 단계의 출력을 `./verify/<KEY>/L<N>.log`에 저장.

### Step C — AC ↔ 테스트 매핑 점검 (`verifier`, sonnet/opus)
- Story `jira/stories/<KEY>.md`의 §3 AC와 §4 Test Plan을 로드.
- 코드베이스에서 *AC 키 주석*(`AC: <KEY>#AC<N>`) 그렙.
- 각 AC가 *최소 1개* 테스트에 매핑되는지 확인.
- 누락 시 *FAIL*. 누락된 AC 목록 출력.

### Step D — Verifier 평결 (`verifier`)
프롬프트:
```
당신은 verifier. ./verify/<KEY>/L*.log 와 AC 매핑 결과를 읽고
다음 4가지로 평결하라:
  - L1/L2/L3 결과 요약
  - AC × 테스트 표 (AC 키별 ✅/❌ + 테스트 이름)
  - 발견된 위험·새 태스크 후보
  - 최종: PASS / FAIL / PASS_WITH_NOTES
출력: ./verify/<KEY>/verdict.md (자동 첨부용)
```

### Step E — 평결별 분기

#### PASS
1. `gh pr merge <N> --squash --delete-branch` (또는 정책에 맞는 머지 전략).
2. Jira Story Status → `Done`, comment with `verdict.md` 요약 + 머지 SHA.
3. `git worktree remove ../wt-<KEY>` (있는 경우).
4. 종료.

#### PASS_WITH_NOTES
1. PASS와 동일하게 머지.
2. Notes 항목을 Jira에 *별도 Tech Story*로 자동 등록 (라벨 `follow-up`).
3. 사람에게 follow-up 우선순위 결정 요청.

#### FAIL
1. **머지하지 않음.**
2. `verdict.md`를 PR 코멘트로 게시.
3. Jira Story → 상태 그대로(`In Review`), comment with FAIL 사유.
4. *수정 작업*은 `mv-tdd-redgen`/`mv-tdd-impl`로 회귀.
5. 3회 연속 FAIL 시 → SPEC 의심, 사람 개입 요청.

## 4. Output
- `./verify/<KEY>/L1.log`, `L2.log`, `L3.log`, `verdict.md`
- 머지 결과 또는 FAIL 보고
- Jira Story 상태/코멘트 갱신
- (PASS_WITH_NOTES) 신규 follow-up Tech Story

## 5. Guardrails
- **자기보고 PASS 금지.** Verifier가 *명시적 평결* 없으면 머지 금지.
- **AC 매핑 누락 = FAIL.** 커버리지 80%여도 AC 1개 미매핑이면 FAIL.
- **회귀 발견 시 머지 금지.** main 보호.
- **force-push·main 직접 push 금지.** PR 머지만.
- **머지 전략은 팀 합의.** squash/rebase/merge 중 *프로젝트 설정 따름*.

## 6. Cost & Time
- 토큰: ~20k (verifier sonnet) ~ ~45k (opus, 대형 PR)
- 시간: 5~20분 (테스트 실행 시간 포함)

## 7. Chains
- 선행: `mv-pr-review` (블로커 0 + 사람 승인 후 권장)
- 후행: `mv-release` (마일스톤/Epic 끝)

## 8. When NOT to use
- 테스트가 *없거나* AC 매핑이 *전혀 안 된* PR — `mv-tdd-redgen`으로 회귀.
- 비-기능 변경(문서·CI 설정)으로 코드 테스트가 무의미 — 별도 절차.

## 9. References
- `~/workspace/vibecode_base/docs/05-quality-gates.md`
- `~/workspace/vibecode_base/docs/06-checklists.md` PR 제출 전 10항목
