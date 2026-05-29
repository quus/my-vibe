---
name: mv-ui-verify
description: 빠른 UI 검증 게이트 — Playwright 실 브라우저로 화면 렌더·콘솔에러 0·실데이터를 검증하되, 웜 세션(storageState 재사용)·컨테이너 재빌드 최소화·시나리오 병렬·screen-smoke/full-e2e 2티어로 속도를 끌어올림. api 헬스 대기 내장. Trigger when user says "ui 검증", "ui verify", "화면 검증", "playwright 게이트", "스크린 스모크".
---

# mv-ui-verify — Fast UI Verification Gate

> v2.1에서 "UI는 Playwright 실 브라우저로 검증"을 강제했으나, 클러스터마다 컨테이너 재빌드 +
> KeyCloak 로그인 + 3시나리오로 **검증이 수 분씩** 걸리고 api-restart 타이밍 race(exit 144, HTTP 000)가
> 반복됨(페인 P4). mv-ui-verify는 **같은 검증 신뢰도를 유지하면서 속도를 끌어올리는 표준 게이트**다.

## 1. Triggers
- "ui 검증", "ui verify", "화면 검증", "playwright 게이트", "스크린 스모크"
- `mv-sprint-run` 내부에서 UI Story 검증 시 자동 호출

## 2. 핵심 원칙 (속도 ↑, 신뢰도 유지)
1. **웜 세션 재사용 (가장 큰 절감)**: KeyCloak 로그인을 1회만 수행해 `storageState`(쿠키/스토리지)를 저장,
   이후 모든 시나리오는 storageState를 주입해 **로그인 스킵**. (로그인 왕복이 시간의 대부분)
2. **컨테이너 재빌드 최소화**: 클러스터마다 재빌드 금지. 프론트 변경은 **vite dev server(:13000 프록시)**
   또는 스프린트당 1회 통합 재빌드에서만 검증. 백엔드 API는 이미 떠 있는 컨테이너 사용.
3. **시나리오 병렬**: Playwright `workers>1`로 화면 시나리오 병렬 실행.
4. **2-티어 분리**:
   - **screen-smoke**(클러스터 단위, 빠름): 로그인(웜) → 화면 진입 → 렌더 + **콘솔/페이지 에러 0** +
     핵심 셀 `typeof` 단언(객체-as-child 방지) + 스크린샷. 30초 목표.
   - **full-e2e**(스프린트 종료 1회): 인증 3시나리오(정상/stale-cookie/토큰만료) + 핵심 플로우.
5. **api 헬스 대기 내장**: 검증 전 `/health` 200을 최대 60s 폴링(타이밍 race P4 차단).

## 3. Procedure
1. `ensure_warm_session()` — storageState 없으면 1회 로그인해 `frontend/.auth/state.json` 생성(gitignore). 만료 시 갱신.
2. `screen_smoke(path, asserts)` — storageState 주입한 context로 path 진입, 콘솔에러 0 + 렌더 + 스크린샷(`frontend/screenshots/`).
3. `full_e2e()` — 인증 3시나리오(웜 세션 미사용, 실제 로그인 플로우 검증) + 지정 플로우.
4. 결과: PASS/FAIL + 스크린샷 경로 + 콘솔에러 수. FAIL 시 게이트 차단.

## 4. 구현 메모
- Playwright `browserContext.storageState()` / `newContext({storageState})`.
- 기존 `frontend/scripts/verify-*.mjs`를 이 패턴으로 리팩터(로그인 헬퍼 공유).
- 컨테이너 헬스 대기는 `scripts/verify_container.sh`에 이미 반영(재사용).

## 5. Guardrails
- **웜 세션이 인증 회귀 검증을 대체하지 않음** — full-e2e의 인증 3시나리오는 반드시 실제 로그인으로.
- **screen-smoke도 실데이터** — mock 금지(v2.1 원칙 유지).
- **콘솔에러 0 기준 유지** (React #31 등 차단).
- **curl 200은 UI 증거 아님** — 화면 렌더·콘솔에러·스크린샷이 증거.

## 6. Cost & Time
- screen-smoke: 화면당 ~30초 (웜 세션). full-e2e: 스프린트당 1회 수 분.
- 토큰: ~8k (스크립트 생성·결과 해석).

## 7. Chains
- 선행: `mv-tdd-impl` / `mv-sprint-run` Step 5 (구현 완료 후)
- 호출처: `mv-sprint-run` Step 6 Verifier 게이트의 UI 항목, `mv-verify-merge`(UI 변경 포함 시)

## 8. 근거 (실측)
- Sprint 7~13 매 클러스터가 컨테이너 재빌드 + 로그인 + e2e로 검증 → 클러스터당 수 분, 스프린트당 누적 큼.
- api-restart 직후 verify → HTTP 000 / e2e Scenario1 FAIL (S10·11). 헬스대기로 해소했으나 표준화 필요.

## 9. References
- Playwright — [Authentication / storageState](https://playwright.dev/docs/auth)
- `~/workspace/vibecode_base/docs/05-quality-gates.md` (UI 증거 기반 검증)
