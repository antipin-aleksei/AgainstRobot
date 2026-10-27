# First hosted CI failure: toggle interaction

Date: 2026-10-27. Candidate fix only; hosted verification and independent
review remain required. plan-1 and plan-11 stay blocked; plan-2 has not started.

## RED evidence and investigation

Run: https://github.com/antipin-aleksei/AgainstRobot/actions/runs/40522104503
Source revision: `62f66a8`. Debug build-for-testing passed. Of two UI tests,
`testHomeOpensEveryPlaceholder` passed and
`testMockModeStartsEnabledAndCanBeSwitched` failed at line 38: after its first
tap the switch value remained `1`, expected `0`. Test command exited 65.
Release build was not reached. This is real simulator RED evidence, not a
Linux simulation of XCTest.

Downloaded artifact `ios-diagnostics-40522104503-1` (ID `12742128643`).
Inspected the runner/application logs embedded in `SmokeTests.xcresult`:

- The app exposes two accessibility switches: an outer labeled switch with
  identifier `mockModeToggle`, and an unnamed nested switch. The outer switch
  also contains the label's StaticText. The identifier query returns only the
  outer switch. Application PID 8623 logs both switches during the failed test
  at 14:38:34.869.
- XCTest at 14:38:35.057 computes a hit point for the identified outer switch
  with frame `{{20.0, 508.7}, {353.0, 44.0}}`: this is the full list row.
- At 14:38:35.081 the computed hit point is `{196.5, 530.7}`. The event log
  records touch down/up there. The synthesized-event binary plist independently
  records x=196.5, y=530.6666666666666 in a 393x852 window.
- The app uses the standard SwiftUI Toggle bound directly to the root
  `@State` configuration. There is no custom gesture or setter to investigate.

Hypothesis: `toggle.tap()` targets the accessibility wrapper's row center,
rather than its nested switch control, so the synthesized interaction does
not change state. The artifact establishes the wrapper hierarchy and actual
tap location. It does not prove that tapping the nested switch resolves the
failure; the next hosted run must test that hypothesis. Timing alone is not
established as the cause, so no sleeps, retries, or extra waits were added.

Relevant embedded payloads after zstd decompression:

- Application log: `data.0~aHsegRsVoiu1cGX83jUA198n-LyKoTTbFHpNCuDrQzF6ZDABPthP7sRXKWhVI8wqh1-AZhoifIwNXJTPqu0oPA==`
- XCTest runner log: `data.0~leRXLtVn5PbCln_VS9KTdNWfNCVLBhrQvyReblx8OT6roAH5XhbjIvdoqbQPiYY1knXw9iztE1BQASJRbkJTKA==`
- Synthesized event plist: `data.0~wly5cBp6cFV9YXEWP-hXjeDY6t-CQV4zuywV3DgTAQ6AgZFIYhyVEb66OWa90U_xoS6xt3jeCe5vkRj18sGBdQ==`

## Minimal candidate change

Only the UI test changes: use `toggle.switches.firstMatch` for both taps.
Continue reading the identified wrapper's value and retain every assertion
for default-on, off/on transitions, and both offline status messages.
No assertions were removed or weakened; no app UI or workflow changed.

The existing test catches a missing state update, incorrect default, and
incorrect status rendering. Targeting the nested control makes that behavior
test exercise the actual switch instead of its wrapper's row center.

## Commands and verification limits

Artifact retrieval (exit 0):

```sh
gh api repos/antipin-aleksei/AgainstRobot/actions/runs/40522104503/artifacts --jq '.artifacts[] | {id,name,size_in_bytes}'
gh run download 40522104503 --repo antipin-aleksei/AgainstRobot --name ios-diagnostics-40522104503-1 --dir /tmp/againstrobot-red-artifact
```

Read-only decoding of artifact payloads in `/tmp` (exit 0; Python's installed
`zstandard` library was used, no xcresult tooling was claimed):

```sh
python3 - <<'PY'
from pathlib import Path
import io
import zstandard
out = Path('/tmp/againstrobot-red-decoded')
out.mkdir(exist_ok=True)
for source in Path('/tmp/againstrobot-red-artifact/SmokeTests.xcresult/Data').glob('data*'):
    payload = source.read_bytes()
    if payload.startswith(bytes.fromhex('28b52ffd')):
        payload = zstandard.ZstdDecompressor().stream_reader(io.BytesIO(payload)).read()
    (out / source.name).write_bytes(payload)
PY
```

`git diff --check`: exit 0. Inspected the complete test diff; all six existing
assertions and the navigation test remain intact.

Attempted the full project test command locally:

```sh
xcodebuild -project AgainstRobot.xcodeproj -scheme AgainstRobot \
  -configuration Debug -destination 'platform=iOS Simulator,name=iPhone 16' \
  -derivedDataPath build/DerivedData \
  -resultBundlePath build/SmokeTests.xcresult CODE_SIGNING_ALLOWED=NO test
```

Exit 127: `xcodebuild: command not found`. This Linux environment cannot compile
or execute XCTest. No local GREEN, successful fix, or completed plan is
claimed. The controller must push the candidate, run the existing full hosted
workflow, inspect both tests and Debug/Release build results, and obtain an
independent review before closing the validation blockers.

Instructions read: Superpowers systematic-debugging, test-driven-development
(including writing-good-tests), and verification-before-completion from
`/tmp/againstrobot-superpowers/skills/`. No subagents/worktrees were created;
this implementation agent performed no push or remote mutation.

## Hosted verification

GREEN: [run 40526374430](https://github.com/antipin-aleksei/AgainstRobot/actions/runs/40526374430), SHA `72464f27732462acb32d86cb7c034447df7d1755`,
completed success: Debug and Release builds, 2 tests passed/0 failed;
independent review found no issues. Plan acceptance recorded in vibe/plans/plan-11.md.
