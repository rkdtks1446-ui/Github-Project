# StudyFlow Kanban Backlog

스프린트 운영을 위한 StudyFlow 학기 프로젝트 이슈와 칸반 보드입니다.

## 보드 상태

`Backlog` → `To Do` → `In Progress` → `Review` → `Done`

각 이슈는 작고 검증 가능한 완료 조건을 가지며, 진행 상태는 라벨 대신 GitHub Project의 Status 필드에서 관리합니다.

## 마일스톤

- **M1 · Foundation & Planning**: 요구사항, 설계, 기반 구조
- **M2 · StudyFlow MVP & Validation**: 주간 계획, 복습, 현황 대시보드, 테스트 및 검증

## 라벨 체계

- 유형: `type: feature`, `type: bug`, `type: chore`
- 우선순위: `priority: P0`, `priority: P1`, `priority: P2`
- 영역: `area: discovery`, `area: design`, `area: frontend`, `area: backend`, `area: testing`, `area: release`
- 크기/포인트: `size: XS` = 1, `size: S` = 2, `size: M` = 3, `size: L` = 5 points. 이슈마다 하나를 지정합니다.

## Issue forms

- [Bug report](.github/ISSUE_TEMPLATE/bug.yml)
- [Feature request](.github/ISSUE_TEMPLATE/feature.yml)
- [UTF-8 backlog seed](data/backlog-seed.json)
- [Idempotent GitHub sync script](scripts/seed-backlog.ps1)

The sync script uses the cached Git Credential Manager credential and never prints the token. Run it from a PowerShell session after cloning this repository to recreate or repair labels, milestones, and seeded issues.

## 운영 지표

- **Cycle Time**: `In Progress` 진입부터 `Done`까지의 경과 시간. GitHub Project Status 변경 이력에서 주간 중앙값을 확인합니다.
- **Velocity**: 스프린트 종료 시 Done으로 이동한 이슈의 `size:*` 포인트 합계. 완료 포인트를 팀의 실제 반복 처리량으로 기록합니다.
- **Burndown**: 스프린트 시작 시점의 To Do/In Progress 포인트에서 매일 완료분을 차감해 이상적인 잔여량과 비교합니다. 실제 팀 용량을 확인하기 전에는 샘플 수치를 만들지 않습니다.

실제 이슈·마일스톤·프로젝트 보드는 저장소 [Issues](https://github.com/rkdtks1446-ui/Gitgub-Project/issues), [Milestones](https://github.com/rkdtks1446-ui/Gitgub-Project/milestones), [Projects](https://github.com/rkdtks1446-ui/Gitgub-Project/projects)에서 확인합니다.