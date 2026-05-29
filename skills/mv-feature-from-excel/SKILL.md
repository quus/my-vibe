---
name: mv-feature-from-excel
description: 데이터 소스(엑셀/DB)의 미활용 컬럼을 역으로 분석해 기능을 발굴 — 컬럼 인벤토리, 활용/미활용 매핑, 미활용 조합으로 기능 후보 도출(데이터 충분성·난이도·가치·필요 join), FEATURES.md 후보 표 산출. Trigger when user says "엑셀 분석해서 기능", "데이터로 기능 발굴", "feature from excel", "미활용 데이터", "어떤 기능 더".
---

# mv-feature-from-excel — Feature Discovery from Data Source

> Sprint 12에서 "엑셀을 분석해 프로젝트 상태(진행중/종료/예정/지연) 같은 기능을 발굴하라"는 요청을 처리하며,
> **데이터 소스(엑셀/DB)의 미활용 컬럼에서 기능을 역으로 발굴**하는 작업이 가치가 높음을 확인. 재사용 스킬로 표준화.

## 1. Triggers
- "엑셀 분석해서 기능", "데이터로 기능 발굴", "feature from excel", "미활용 데이터", "어떤 기능 더"

## 2. Procedure
1. **소스 인벤토리**: 엑셀 탭/DB 테이블의 컬럼을 스캔(openpyxl/스키마). 날짜·금액·상태·플래그·외래키 후보 식별.
2. **활용/미활용 매핑**: 이미 기능에 쓰인 컬럼 vs 미활용 컬럼 표로.
3. **기능 후보 도출**: 미활용 컬럼 조합으로 가능한 기능 제안
   (예: Start/End→상태, 계획/실적→소진율, 원가 vs 매출→손익, 확률→가중 파이프라인, 자동연장→알림).
4. **각 후보**: 데이터 충분성·구현 난이도·가치(P0/P1/P2)·필요 join 명시.
5. **산출**: FEATURES.md 후보 표 + `mv-sprint-plan` 입력으로 연결.

## 3. Guardrails
- **데이터 충분성 정직 평가** — 컬럼은 있으나 값이 비어있으면(예 D10 매출 NULL) 명시.
- **PII/민감 데이터 노출 정책 확인** — Leadership 전용 등 접근 맥락 반영.
- **추측 금지** — 실제 컬럼/값을 본 뒤 제안.

## 4. Cost & Time
- 토큰: ~10k (소스 스캔 + 후보 도출). 시간: 5~15분.

## 5. Chains
- 후행: `mv-feature-upsert`(후보 → Jira Story), `mv-sprint-plan`(계획 입력)
- 보완: `mv-data-import`(발굴된 컬럼을 실제 적재)

## 6. 근거 (실측)
- resource_mgmt: D8(WBS+Start/End)→프로젝트 상태(사용자 요청), D4/D5(계획/실적)→실행예산,
  D7(win_probability)→가중 파이프라인, D8(자동연장)→계약 알림 — 미활용 탭에서 4+ 기능 발굴(Sprint 12·13).

## 7. References
- `~/workspace/vibecode_base/docs/07-product-planning.md` (기능 발굴 → 백로그)
