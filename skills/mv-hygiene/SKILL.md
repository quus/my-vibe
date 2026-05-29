---
name: mv-hygiene
description: 스프린트 경계 위생 가드 — stale pytest/playwright/node 프로세스(20분+) 강제 종료, 데모/고아 시드 행 정리(운영+테스트 DB), 컨테이너 /health 200 폴링(타이밍 race 차단). 멀티에이전트 병렬 실행의 잔존 오염을 막음. Trigger when user says "위생 점검", "hygiene", "스프린트 정리", "stale 정리", "경계 정리".
---

# mv-hygiene — Sprint Boundary Hygiene Guard

> 멀티에이전트 병렬 실행에서 **장시간 잔존 에이전트**(2~2.7h deep-executor)와 **데모/검증 시드 행 잔존**,
> **stale pytest/playwright 프로세스**가 다음 스프린트를 오염시킴(페인 P2·P3).
> `scripts/sprint_hygiene.sh`로 해결한 것을 스킬로 일반화한다.

## 1. Triggers
- "위생 점검", "hygiene", "스프린트 정리", "stale 정리", "경계 정리"
- `mv-sprint-run`이 스프린트 착수 전 + 클린 게이트 전 자동 호출

## 2. 수행 항목
1. **stale 프로세스 강제 종료**: pytest/playwright/node-e2e 중 `etimes>1200`(20분) 프로세스 kill.
   현재 셸/부모는 제외. 종료 PID·나이 출력.
2. **데모/고아 행 정리**: 운영+테스트 DB에서 데모 시드(`[DEMO]`/데모/검증/크론 패턴, employee_id `DEMO-%`) 제거
   (프로젝트의 `seed_demo --clear` 등). 기준 카운트 복원 검증(예 INTERNAL=121).
3. **컨테이너 헬스 대기**: 재빌드 직후 `/health` 200을 60s 폴링(타이밍 race 차단).
4. **결과 요약**: CLEAN/DIRTY + 무엇을 정리했는지.

## 3. Procedure
- `mv-hygiene [--kill-age 1200] [--expected-internal 121] [--health-url ...]`
- idempotent·safe. CI/스프린트 boundary hook으로 등록 권장.

## 4. Guardrails
- **현재 에이전트/셸 자기 종료 금지**.
- **운영 데이터 삭제는 명시적 데모 패턴만** — 실데이터 보호.
- **카운트 복원 실패 시 DIRTY 보고** (자동 강제 삭제 금지).

## 5. Cost & Time
- 토큰: ~3k. 시간: 1~2분(헬스 폴링 포함).

## 6. Chains
- 호출처: `mv-sprint-run` v3.0 — 스프린트 착수 전 + clean-gate-after-all 직전.
- 보완: `mv-ui-verify`(헬스 대기 공유), `mv-data-import`(적재 후 카운트 검증).

## 7. 근거 (실측)
- Sprint 9 A+B 에이전트 2.7h 잔존 → Sprint 11 게이트 오염(exit 144, 10-fail).
- Sprint 10/11에서 데모 시드 잔존으로 INTERNAL 121→122/123, 수동 정리 반복.
- `scripts/sprint_hygiene.sh` + `verify_container.sh` 헬스대기로 해소 입증(Sprint 12).

## 8. References
- `~/workspace/vibecode_base/docs/05-quality-gates.md`
- `man ps` (etimes), docker compose healthcheck
