# my-vibe — Claude Code SDLC Skill Suite

> **요구사항 → Jira → 아키텍처 → TDD → 리뷰 → 머지 → 릴리스 → 회고**까지,
> 소프트웨어 개발의 *전 과정*을 자동화하는 10개 mv-* 스킬 패키지.
> [vibecode_base 방법론](../vibecode_base/) 위에 동작합니다.

[![Version](https://img.shields.io/badge/version-1.1.0-blue.svg)](./CHANGELOG.md)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](./LICENSE)
[![Skills](https://img.shields.io/badge/skills-13-green.svg)](./skills/INDEX.md)

---

## 1. 무엇을 해주나

| 단계 | 스킬 | 트리거 예시 |
|---|---|---|
| 초기 설정 | `mv-setup` | "초기 설정", "credentials", "jira 연결" |
| 백로그 | `mv-feature-upsert` | "기능 등록", "feature upsert" |
| 우선순위 | `mv-backlog-prioritize` | "백로그 우선순위", "RICE" |
| 아키텍처 | `mv-arch-from-jira` | "아키텍처 수립", "C4 작성" |
| 스프린트 계획 | `mv-sprint-plan` | "스프린트 계획", "다음 스프린트" |
| RED | `mv-tdd-redgen` | "tdd red", "실패 테스트" |
| GREEN/REFACTOR | `mv-tdd-impl` | "구현 시작", "worktree 구현" |
| 리뷰 | `mv-pr-review` | "리뷰 돌려", "5-lane review" |
| 검증·머지 | `mv-verify-merge` | "검증 후 머지", "DoD 점검" |
| 릴리스 | `mv-release` | "릴리스 시작", "cut release" |
| 사고 | `mv-incident-to-test` | "incident", "hotfix" |
| 회고 | `mv-sprint-retro` | "스프린트 회고", "velocity" |
| 스프린트 실행(전체) | `mv-sprint-run` | "스프린트 실행", "sprint run", "스프린트 돌려" |

전체 흐름 다이어그램 + 체이닝 매트릭스: [`skills/INDEX.md`](./skills/INDEX.md).

---

## 2. 설치

### 2.1 Claude Code 마켓플레이스 (권장)

Claude Code 세션에서:
```
/plugin marketplace add quus/my-vibe
/plugin install my-vibe@my-vibe
```

특정 태그를 고정하려면:
```
/plugin marketplace add https://github.com/quus/my-vibe.git#v1.0.3
```

마켓플레이스를 팀 표준으로 두려면 `.claude/settings.json`에:
```json
{
  "extraKnownMarketplaces": {
    "my-vibe": {
      "source": { "source": "github", "repo": "quus/my-vibe" }
    }
  },
  "enabledPlugins": { "my-vibe@my-vibe": true }
}
```

### 2.2 로컬 설치 — install.sh (오프라인/포크/개발자 본인)

```bash
git clone https://github.com/quus/my-vibe.git
cd my-vibe
./install.sh
```

`install.sh`는 기본적으로 `~/.claude/skills/`에 **심볼릭 링크**를 만듭니다. 패키지 디렉터리를 옮기지 않는 이상 갱신은 `git pull`만으로 반영됩니다.

옵션:
- `./install.sh --copy` — 심볼릭 링크 대신 *복사* (네트워크 드라이브에 둘 때)
- `./install.sh --prefix /custom/path` — 다른 경로에 설치
- `./install.sh --uninstall` — 즉시 제거

### 2.3 Tarball 설치 (배포 산출물 / 에어갭)

```bash
tar -xzf my-vibe-1.0.3.tgz
cd my-vibe-1.0.3
./install.sh
```

`dist/SHA256SUMS`로 무결성 확인:
```bash
sha256sum -c dist/SHA256SUMS
```

### 2.4 검증
```bash
ls ~/.claude/skills/ | grep '^mv-'
# mv-arch-from-jira  mv-backlog-prioritize ... (10개)
```

Claude Code 세션을 다시 시작하면 트리거 키워드로 자동 매칭됩니다.

---

## 3. 사전 준비

### 환경 변수 (필수)
```bash
export JIRA_BASE_URL="https://<org>.atlassian.net"
export JIRA_EMAIL="<user>@example.com"
export JIRA_API_TOKEN="<token>"          # 1Password/Vault에서 주입
export JIRA_PROJECT_KEY="<KEY>"
```

> 보안: `JIRA_API_TOKEN`은 **git-tracked 파일에 두지 마세요.**
> 권장: 1Password CLI, `direnv`, 또는 shell의 `~/.zshenv`/`~/.bashrc`.

### 필수 동반 플러그인 — oh-my-claudecode (OMC)

my-vibe의 오케스트레이션 스킬은 **전용 서브에이전트를 자체 정의하지 않고**, OMC가 제공하는
역할 서브에이전트(`oh-my-claudecode:*`)를 *호출*합니다. 이는 **의도된 설계**입니다 —
역할 에이전트를 vendoring(복제)하면 frozen 스냅샷이 되어 OMC의 프롬프트·모델 라우팅 개선을
받지 못하기 때문입니다. my-vibe는 *워크플로(언제·무엇을·어떤 순서)*만 정의하고,
*개별 역할 수행*은 OMC 에이전트에 위임해 업데이트를 자동 상속합니다.

**필수 — 미설치 시 오케스트레이션 스킬이 동작하지 않음**:
```
/plugin marketplace add anthropics/claude-code   # 또는 OMC 배포처
/plugin install oh-my-claudecode
```

**의존하는 OMC 에이전트 → 사용 스킬**:

| OMC 에이전트 | 역할 | 사용하는 my-vibe 스킬 |
|---|---|---|
| `analyst` | PO / 요구분석 | sprint-plan·sprint-run(PO), arch-from-jira, feature-upsert |
| `architect` | 아키텍처 | arch-from-jira, sprint-plan, sprint-run |
| `executor` | QA/구현 | tdd-impl, sprint-plan·sprint-run(QA), feature-upsert(sync) |
| `deep-executor` | Developer | sprint-run(Dev), tdd-impl(복잡) |
| `verifier` | 독립 검증 | verify-merge, sprint-run(Verifier 게이트) |
| `test-engineer` | 테스트 설계 | tdd-redgen, sprint-plan·sprint-run(QA) |
| `critic` | 계획 도전 | arch-from-jira, sprint-plan |
| `quality/style/api/security/performance-reviewer` | 5-레인 리뷰 | pr-review |
| `debugger` | 원인 분석 | incident-to-test |
| `writer` | 문서 | release, sprint-retro |
| `product-analyst` | 지표 분석 | backlog-prioritize, sprint-retro |

> 호출 시 정식 ID는 `oh-my-claudecode:<agent>`. SKILL.md에는 가독성을 위해 짧은 이름으로 표기.
> **OMC 버전 호환**: my-vibe는 OMC의 위 에이전트 *역할 계약*에만 의존하며 내부 구현은 의존하지 않음.
> OMC가 에이전트를 추가/개선하면 my-vibe 변경 없이 자동 반영됨.

**OMC 미설치 폴백**: 오케스트레이션 스킬(sprint-run/plan, arch-from-jira 등)은 OMC가 없으면
역할 에이전트 대신 *기본 Task 서브에이전트(general-purpose)* 로 동작 시도하나, 역할별 시스템
프롬프트가 빠져 품질이 저하됩니다. 단일 스킬(tdd-redgen 등)은 본체에서 직접 수행 가능.

### 번들 구성요소 — MCP 서버 & Hooks (플러그인 설치 시 자동 활성)

my-vibe는 워크플로 스킬뿐 아니라 **MCP 서버 선언(`.mcp.json`)** 과 **라이프사이클 훅(`hooks/hooks.json`)** 을 함께 번들합니다. (마켓플레이스로 설치 시 자동 적용. 심볼릭 링크 `install.sh`는 skills만 설치하므로 MCP/hooks는 마켓플레이스 설치 경로에서 동작.)

**`.mcp.json` — Jira + GitHub MCP** (`.env`의 변수를 `${VAR}`로 주입, 비밀은 커밋 안 됨):
| 서버 | 구현 | 인증 | 사용 스킬 |
|---|---|---|---|
| `atlassian` | `uvx mcp-atlassian` | `JIRA_URL`/`JIRA_USERNAME`/`JIRA_API_TOKEN` (.env) | feature-upsert · backlog-prioritize · arch-from-jira · sprint-* · verify-merge |
| `github` | remote `api.githubcopilot.com/mcp` (http) | `Bearer ${GITHUB_TOKEN}` | pr-review · verify-merge · release |

> MCP가 활성이면 각 스킬이 REST 수동 호출 대신 MCP 도구를 우선 사용. 미설정/실패 시 기존 REST 폴백.
> 엔드포인트·패키지는 환경에 맞게 `.mcp.json`에서 교체 가능 (예: Atlassian 공식 remote SSE, GitHub 로컬 서버).
> SSH 인증만 쓰고 `GITHUB_TOKEN`이 없으면 git 작업은 SSH로 동작하되 GitHub *MCP 도구*는 비활성.

**`hooks/hooks.json` — 안전 가드 훅**:
| 이벤트 | 매처 | 동작 |
|---|---|---|
| PreToolUse | `Bash` | `guard-secrets.sh` — `git add/commit`이 `.env`·`credentials`·`*.pem` 등 비밀 파일을 staging하면 **deny** |
| PostToolUse | `Write\|Edit` | `env-gitignore-check.sh` — `.env` 작성 시 `.gitignore` 미포함이면 **경고**(비차단) |

### 권장 도구
- **GitHub CLI** (`gh`) — `mv-pr-review`, `mv-verify-merge`, `mv-release`가 사용.
- **git ≥ 2.5** — worktree(`mv-tdd-impl`)에 필요.
- **uv/uvx** — `.mcp.json`의 `mcp-atlassian` 실행에 필요(미설치 시 atlassian MCP 비활성, REST 폴백).

### 방법론 문서
스킬들은 [`vibecode_base/`](../vibecode_base/)의 방법론을 참조합니다. 같이 클론하시면:
```bash
git clone https://github.com/kwshim/vibecode_base.git ~/workspace/vibecode_base
```

---

## 4. 빠른 시작

새 제품:
```
1. /mv-feature-upsert      ← input.md 또는 FEATURES.md
2. /mv-backlog-prioritize
3. /mv-arch-from-jira
4. (Story 1개씩 반복)
   /mv-tdd-redgen → /mv-tdd-impl → /mv-pr-review → /mv-verify-merge
5. /mv-release             ← Epic/마일스톤 끝
6. /mv-sprint-retro        ← 스프린트 끝
```

운영 사고:
```
/mv-incident-to-test → /mv-release --hotfix → 다음 /mv-sprint-retro 반영
```

---

## 5. 안전 가드 (공통)

- **자기보고 PASS 금지** — Verifier 평결 없이 머지 없음.
- **사람 사인오프 지점** — NFR 확정·major 릴리스·자동 우선순위 적용·핫픽스.
- **비밀 git 커밋 차단** — pre-commit hook 권장.
- **Won't 항목은 Jira에 만들지 않음** — FEATURES.md 기록만.
- **worktree 격리 권장** — 본 레포 직접 작업 지양.

---

## 6. 비용 모델 (참고)

| 사이클 | 토큰(추정) | 시간 |
|---|---|---|
| Day 0 (1~3번) | ~130k | 2~3h + 사람 검토 |
| Story 1개 (4~7번) | ~60k | 1~3h |
| 릴리스 (8번) | ~15k | 30분~2h |
| 사고 (9번) | ~15k | Sev1: ≤2h |
| 회고 (10번) | ~20k | 자동 10분 + 미팅 30분 |

기준 모델: Sonnet 4.6 메인, Opus 4.7는 아키텍처·분석 단발만.

---

## 7. 한계

- **사용자 인터뷰·디스커버리** — 사람이 해야 함. 결과를 `input.md`로 1번에 넘기면 동작.
- **데이터 마이그레이션 설계** — 큰 스키마 변경은 ADR + 사람 주도 릴리스.
- **이해관계자 합의** — 우선순위 *제안*은 자동, 결정은 사람.
- **창의적 UX 디자인** — `frontend-design` 또는 `oh-my-claudecode:frontend-ui-ux`.
- **사내 정책·규제 해석** — 보안/법무 자문 필요.

---

## 8. 트러블슈팅

| 증상 | 진단 | 처방 |
|---|---|---|
| 스킬이 트리거 안 됨 | 트리거 키워드 불일치 | `Skill` 도구로 명시 호출 (`mv-<name>`) |
| Jira 403/401 | 토큰/권한 | `JIRA_API_TOKEN` 재확인 |
| MCP 미발견 | 미설치 | REST 폴백 자동, 또는 `/oh-my-claudecode:mcp-setup` |
| 토큰 초과 | 컨텍스트 누적 | `/clear` 후 worktree로 격리 |
| install.sh 권한 거부 | 실행권한 누락 | `chmod +x install.sh` |

---

## 9. 라이선스 & 기여

- MIT — [`LICENSE`](./LICENSE)
- Issues/PR 환영. 새 스킬 추가 시 `plugin.json` `skills[]` 갱신 + `CHANGELOG.md`.

## 10. 관련 자료

- 방법론: [`vibecode_base/METHODOLOGY.md`](../vibecode_base/METHODOLOGY.md)
- TDD 사이클: [`vibecode_base/docs/10-tdd-cycle.md`](../vibecode_base/docs/10-tdd-cycle.md)
- 자동 확장: [`vibecode_base/docs/08-feature-expansion.md`](../vibecode_base/docs/08-feature-expansion.md)
- Claude Code 공식: [code.claude.com/docs](https://code.claude.com/docs/en/)
