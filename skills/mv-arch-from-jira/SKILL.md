---
name: mv-arch-from-jira
description: Jira의 모든 Epic/Story를 읽고 C4 모델 기반 ARCHITECTURE.md와 ADR을 생성, 발견된 아키텍처 작업(테스트 인프라, OTel, 마이그레이션 등)을 Jira Tech Story로 추가. Trigger when user says "아키텍처 수립", "architecture from jira", "C4 작성", "ADR 생성", "기술 백로그".
---

# mv-arch-from-jira — Architecture from Jira

> **vibecode_base 방법론 Phase 0.5** 자동화. Story에서 *공통 컴포넌트와 기술 부채*를 추출해 아키텍처와 Tech Story로 분리.
> 참조: `~/workspace/vibecode_base/docs/09-architecture.md`

## 1. Triggers
- "아키텍처 수립해줘"
- "architecture from jira"
- "C4 다이어그램 그려"
- "ADR 생성"
- "기술 백로그 추출"

## 2. Inputs
- `JIRA_PROJECT_KEY`
- 기존 `./ARCHITECTURE.md` (있으면 *증분 갱신*, 없으면 신규 작성)
- 기존 `./adr/` (있으면 다음 ADR 번호부터 이어붙임)

## 3. Procedure

### Step A — Fetch & Cluster
JQL: `project = <KEY> AND issuetype in (Epic, Story, Feature) AND statusCategory != Done`
- 모든 Issue의 summary·description·labels·components를 모은다.
- **클러스터링**(`architect`, opus 1회):
  - Story 텍스트에서 *데이터 엔티티*·*외부 시스템*·*공통 동사(검색/알림/결제…)* 추출.
  - 클러스터 → *컨테이너 후보* 매핑(웹앱·API·워커·DB·큐·캐시).

### Step B — NFR 우선순위 결정
- Epic의 §9 NFR을 종합 → 빈도·강도로 상위 3개 자동 추천.
- 사람에게 *질문 1개*: "Performance/Scalability/Availability/Security/Reliability/Maintainability/Observability/Cost 중 상위 3개를 확정해 주세요" — 응답 대기.

### Step C — ARCHITECTURE.md 작성 (`architect` + `critic`, opus 각 1회)
- 템플릿: `~/workspace/vibecode_base/templates/ARCHITECTURE.md.template`
- C4 L1~L3을 Mermaid로 작성 (PNG 금지).
- §8 Key Decisions 표에 *최소 5개 결정 후보* 식별.

### Step D — ADR 초안 생성
- §8 후보 각각을 별도 `./adr/NNN-<slug>.md`로 생성(템플릿 `ADR.md.template`).
- 상태는 모두 `Proposed`. 사람 사인오프 전까지 `Accepted` 금지.

### Step E — Tech Story 자동 추가 (Jira upsert)
아키텍처가 *요구하는 기술 작업*을 Jira에 Story type=`Tech`로 등록:
- "Set up testcontainers infra"
- "Add OpenTelemetry baseline"
- "Migrate sessions table to JWT refresh model"
- "Create shared design tokens package"

각 Tech Story에:
- Parent Epic: 가장 가까운 사용자 Epic 또는 새 `Tech Foundations` Epic.
- 외부 ID: `vibecode-tech-<adr-NNN>` (멱등 보장).
- 라벨: `type:tech`, `arch:<container>`, `adr:NNN`.
- AC: "ADR-NNN의 결정을 코드로 구현, 통합 테스트로 검증".

### Step F — Validation
- 컨테이너 그래프에 *순환 의존*이 없는가? 있으면 `critic`이 도전 → 사람 결정.
- 상위 3 NFR이 *측정 가능*한가? 각 §6 NFR 행에 측정 방법이 있는가?

## 4. Output
- `./ARCHITECTURE.md` (신규 또는 갱신)
- `./adr/NNN-*.md` (Proposed 상태)
- `./jira/tech-stories/*.md` + 실제 Jira Tech Story (upsert)
- `./architecture-report.md`: 식별된 컨테이너/엔티티, NFR 충돌, ADR 후보 요약

## 5. Guardrails
- **다이어그램은 Mermaid 텍스트만**. 이진 이미지 거부.
- ADR은 모두 `Proposed`로 시작. 자동 `Accepted` 금지.
- 기존 ADR `Accepted` 항목은 *수정 금지* — 변경 필요 시 *새 ADR로 supersede*.
- Tech Story 중복 방지: 외부 ID로 upsert.
- NFR 추천이 사용자 응답 없이는 *진행하지 않음*(중요 결정).

## 6. Cost & Time (Epic 5개 · Story 40개)
- 토큰: ~60k (Step A·C·D는 opus, E는 sonnet)
- 시간: 10분(자동) + 사람 검토·NFR 확정 30~60분

## 7. When NOT to use
- 코드베이스 없는 상태(아직 아키텍처 그릴 거리 없음) — `mv-feature-upsert` 먼저.
- Story 수 < 10 — 사람 1시간이 빠르다.

## 8. Chains
- 선행: `mv-feature-upsert`, `mv-backlog-prioritize`
- 후행: `mv-tdd-redgen` (Story 1개씩 진행)

## 9. References
- `~/workspace/vibecode_base/docs/09-architecture.md`
- `~/workspace/vibecode_base/templates/ARCHITECTURE.md.template`
- Simon Brown — The C4 model
- Michael Nygard — Architecture Decision Records
