# DevLog Spec Format

`Designer Result`를 사용자가 승인한 뒤, Planner가 비단순 설계 또는 구현 작업마다 이 디렉터리에 Spec을 작성한다. 이슈 기반 작업은 `<issue-number>-<short-topic>.md`, 이슈 없는 사용자 요청은 `user-<YYYYMMDD>-<short-topic>.md` 형식을 사용한다.

## Responsibility

- `Design Brief`는 Planner가 요청, 현재 상태, 범위, 제외 범위, 알려진 제약을 Designer에게 전달하는 입력이다.
- `Designer Result`는 Designer가 제약, 대안, 변경 경계, 수용 기준, 검증, 최소 커밋 단위를 분석한 승인 대기 결과다.
- Spec은 사용자가 승인한 `Designer Result`를 영속화한 구현·검토·검증의 공통 기준이다.
- `Task Packet`은 승인된 Spec 경로와 수용 기준을 참조하고, 현재 작업의 역할 배정과 실행 권한을 전달한다.

## Required format

```md
# <Spec title>

- Source:
- Approved Designer Result:
- User approval:

## Constraints

-

## Alternatives and decision

-

## Changed boundaries

-

## Acceptance criteria

- [ ]

## Verification

- Command:
- Evidence:

## Minimum commit units

1.

## Execution constraints

- app or Simulator execution:
- External writes:
- CI or PR actions:
```

## Change control

- 구현 중 요구 사항 또는 범위가 바뀌면 Spec을 수정하고 사용자 재승인을 받은 뒤에만 `Task Packet`과 구현을 갱신한다.
- Spec은 동작과 수용 기준, 금지된 실행을 기록한다. `Task Packet`은 역할별 현재 작업 권한과 실제 검증 명령을 별도로 기록한다.
