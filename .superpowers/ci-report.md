# iOS CI implementation report

Date: 2026-10-27. Scope: configuration and documentation for plan-11, a
technical prerequisite of plan-1. No application or UI-test code changed.

## Current status

CI configuration is prepared and statically checked. A public repository and
an actual successful GitHub-hosted Mac run are **not verified** by this report.
There is no run URL, macOS execution result, or completed-test count yet.
plan-11 and plan-1 remain blocked; plan-2 has not started. The controller owns
GitHub visibility, push, dispatch, and independent review. This implementation
agent performed no GitHub API mutations, push, paid action, or deployment.

## Implementation

- `.github/workflows/ios-ci.yml`: push to main, all pull requests, manual
  workflow_dispatch; read-only contents permission, no persisted checkout
  credentials, concurrency cancellation, 30-minute job timeout.
- Cost guard: the entire macOS job has
  `if: github.event.repository.private == false`. Private repository events
  skip the job before allocation. Standard `macos-15`, no larger runner.
- Explicit `DEVELOPER_DIR=/Applications/Xcode_16.4.app/Contents/Developer`.
  Records macOS, architecture, Xcode, Swift, SDKs, commit SHA and simulator
  inventory. Selects an available iPhone on an available iOS runtime of the
  same major version as the simulator SDK (minimum iOS 17), preferring the
  newest runtime and iPhone 16. Fails clearly if none is available. Boots the
  selected UDID and waits with `simctl bootstatus -b`.
- Unsigned Debug build-for-testing, existing UI tests via
  test-without-building with parallel testing disabled, then unsigned Release
  simulator build. Each command uses `set -euo pipefail` and tee for logs.
- Xcode 16 `xcresulttool get test-results summary` JSON must contain
  `passedTests > 0` and `failedTests == 0`; missing/invalid summary fails the
  job. No fabricated count or static test substitute.
- Always uploads `build/ci/` (logs, versions, simulator JSON, destination,
  summary, build/test xcresult bundles) with 7-day retention. No DerivedData
  artifact or dependency cache. Files produced before failures are retained.
- README, plan-1, plan-11, vibe index, roadmap record usage and unverified
  status; product plan order is preserved.

## Upstream evidence

Retrieved official Git refs with `git ls-remote` on 2026-10-27:

- `https://github.com/actions/checkout.git refs/tags/v6`:
  `d23441a48e516b6c34aea4fa41551a30e30af803`.
- `https://github.com/actions/upload-artifact.git refs/tags/v6`:
  `b7c566a772e6b6bfb58ed0dc250532a479d7789f`.

Both exact-commit action.yml files were downloaded from the official raw
repositories; inspected inputs match workflow usage, runtime is node24.
The workflow pins those full SHAs.

Official runner inventory:
<https://github.com/actions/runner-images/blob/main/images/macos/macos-15-Readme.md>,
retrieved successfully, Image Version `20260824.0482.1`. Lists Xcode 16.4
(`16F6`) at the selected path, iOS Simulator SDK 18.5 and installed iOS
18.5/18.6 iPhone devices. This documents availability in the image inventory;
the actual job must still record its own runner and tools.

The summary command and integer field names were cross-checked against
xcresultparser's XCSummary model at commit
`95ca65d0bd56250ccd16331f5b0480a1a2c0c5e9`:
<https://github.com/a7ex/xcresultparser/blob/95ca65d0bd56250ccd16331f5b0480a1a2c0c5e9/Sources/xcresultparser/Models/XCResultToolModels/XCSummary.swift>.
This is format corroboration, not execution evidence; the cloud run remains
the required check of the installed tool.

## Checks performed

1. Downloaded official actionlint 1.7.12 Linux amd64 release and its published
   checksums from `rhysd/actionlint`. Verified archive SHA256
   `8aca8db96f1b94770f1b0d72b6dddcb1ebb8123cb3712530b08cc387b349a3d8`
   before extracting/running it.
2. `/tmp/againstrobot-actionlint/actionlint -color .github/workflows/ios-ci.yml`:
   exit 0, no findings. This validates Actions structure and expressions;
   shellcheck is not installed, so no shellcheck result is claimed.
3. Parsed YAML with PyYAML 6.0.3; ran `bash -n` over every run step and Python
   `compile` over both embedded Python scripts: all exit 0. Syntax only;
   no mocked simulator or artificial app/configuration tests added.
4. `git diff --check`: exit 0.
5. Attempted the existing project test command in this Linux environment:

   ```sh
   xcodebuild -project AgainstRobot.xcodeproj -scheme AgainstRobot \
     -configuration Debug \
     -destination 'platform=iOS Simulator,name=iPhone 16,OS=18.0' \
     -derivedDataPath build/DerivedData \
     -resultBundlePath build/SmokeTests.xcresult CODE_SIGNING_ALLOWED=NO test
   ```

   Exit 127: `xcodebuild: command not found`. No iOS build or test ran.
   This is neither RED nor GREEN evidence.

Read the requested Superpowers instructions from
`/tmp/againstrobot-superpowers/skills/test-driven-development/SKILL.md` and
`/tmp/againstrobot-superpowers/skills/verification-before-completion/SKILL.md`.
The user-authorized scope is CI configuration/docs and existing real UI tests;
no artificial configuration tests or production behavior were introduced.

## Remaining acceptance evidence

Verify public visibility; push reviewed configuration and run iOS CI; inspect
logs and artifacts; record run URL, checked SHA, actual tools/destination,
nonzero passing UI-test count, successful Debug and Release builds. Resolve
any real Xcode/simulator failure and repeat the run before closing plan-11 or
plan-1. Missing tools, permissions, stale runner software, or unavailable
runtime must be reported as actual failures, never inferred successes.
