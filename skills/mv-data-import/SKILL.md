---
name: mv-data-import
description: Excel/CSV 스냅샷을 도메인 테이블로 적재하는 표준 import 패턴 — 헤더 검증, 자연키 멱등 upsert, 값 정규화, PII-safe 로깅, erp+erp_test 동시 적재, --dry-run, 매칭률 리포트, 감사로그 우회. Trigger when user says "데이터 임포트", "엑셀 임포트", "data import", "시트 적재", "스냅샷 import".
---

# mv-data-import — Excel/CSV → Domain Import (Standardized)

> Sprint 5~13에서 엑셀 탭을 도메인 테이블로 import하는 작업을 **매번 손으로** 작성
> (personnel/projects/allocations/opportunities/customers/dashboard/schedules/budgets = 8회+).
> 패턴이 동일하므로 재사용 스킬로 표준화한다.

## 1. Triggers
- "데이터 임포트", "엑셀 임포트", "data import", "시트 적재", "스냅샷 import"

## 2. 표준 패턴 (매 import 공통)
1. **헤더 검증**: REQUIRED_COLUMNS 일치 확인 후 진행, 불일치 시 FATAL 중단(헤더 행이 멀티-row일 수 있음 — 헤더 행 번호 명시).
2. **멱등 upsert**: 자연키(사번/WBS/OPP-ID/name) `ON CONFLICT DO UPDATE`. 2회 실행 시 행수 불변.
3. **값 정규화**: `strip() or None`, 날짜/불리언/금액 파싱, `#REF!`·범위초과(예 2026-06-31)·숨김행 방어.
4. **PII-safe 로깅**: 실명/사번/연락처/고객담당자 **로그 금지**(마스킹), 집계 카운트만 stdout.
5. **erp + erp_test 둘 다 적재**(페인 P6): `--target both|erp|test`(기본 both). test DB만 적재해 운영 0행 되는 사고 방지.
6. **--dry-run**: 쓰기 없이 파싱·검증·카운트만.
7. **매칭률 리포트**: FK 매칭(예 사번↔resource, WBS↔project) matched/unmatched 카운트.
8. **감사로그 우회**: 직접 DB 세션(서비스 레이어 우회) 또는 dirty-check로 import가 audit 오염 안 하게.

## 3. Procedure
- `mv-data-import <xlsx> <tab> --entity <name> [--key col] [--target both] [--dry-run]`
- 또는 도메인별 `import_<entity>.py` 생성 시 이 템플릿을 따르도록 `dependency-expert`/`executor`에 주입.
- 산출: import 스크립트 + 카운트/매칭률 리포트 + (선택) `verify_import` 체크.

## 4. Guardrails
- **PII 절대 git/로그 노출 금지** — 소스 파일 gitignore, 로그 마스킹.
- **멱등 보장** — 2회 실행 행수 불변 테스트 필수.
- **erp+test 동시 적재 기본** — 한쪽만 적재 금지(P6).
- **헤더 불일치 시 진행 금지**.

## 5. Cost & Time
- 토큰: ~12k (스크립트 생성 · executor/dependency-expert 위임). 시간: import당 5~15분.

## 6. Chains
- 선행: `mv-feature-from-excel`(소스 인벤토리), `mv-arch-from-jira`(테이블 스키마)
- 호출처: `mv-sprint-run` 데이터 적재 Story, 또는 단독 운영 데이터 마이그레이션

## 7. 근거 (실측)
- 8회+ 반복 작성(personnel 121 / projects 114 / allocations 50 / opportunities 2006 / customers 1202 / schedules 27 / budgets 747).
- Sprint 12 예산이 test DB만 적재돼 erp 0행 → 스크럼 마스터 수동 재적재(P6).

## 8. References
- `~/workspace/vibecode_base/docs/03-coding-conventions.md` (경계 검증·멱등)
- openpyxl / SQLAlchemy `ON CONFLICT` (upsert)
