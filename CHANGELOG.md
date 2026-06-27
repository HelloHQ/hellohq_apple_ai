## 0.1.0

* `stream()` now honors `instructions` (system prompt), matching `respond()` —
  the native EventChannel handler builds the session with instructions on both
  macOS and iOS.
* Example app rewritten as an on-device verification harness (availability +
  prompt + Respond + Stream), for verifying on real Apple Intelligence hardware.

## 0.0.1

Initial release.

* `AppleFoundationModelsClient` over Apple's `FoundationModels` framework
  (macOS/iOS), with `availability()`, one-shot `respond()`, and `stream()`.
* `AppleFoundationModelsAvailability` states + `AppleFoundationModelsException`.
* Streaming diffs Apple's cumulative `streamResponse` snapshots into incremental
  text deltas (`appleFoundationModelsIncrementalDelta`).
* Native Swift `@available(macOS 26 / iOS 26)`-guarded; auto-registers (no host
  `Runner`/`pbxproj` edits).
