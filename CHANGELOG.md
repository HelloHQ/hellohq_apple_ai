## 0.0.1

Initial release.

* `AppleFoundationModelsClient` over Apple's `FoundationModels` framework
  (macOS/iOS), with `availability()`, one-shot `respond()`, and `stream()`.
* `AppleFoundationModelsAvailability` states + `AppleFoundationModelsException`.
* Streaming diffs Apple's cumulative `streamResponse` snapshots into incremental
  text deltas (`appleFoundationModelsIncrementalDelta`).
* Native Swift `@available(macOS 26 / iOS 26)`-guarded; auto-registers (no host
  `Runner`/`pbxproj` edits).
