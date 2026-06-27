import Cocoa
import FlutterMacOS
import FoundationModels

/// macOS plugin exposing Apple's on-device Foundation Model to Flutter:
/// MethodChannel (availability/respond) + EventChannel (streamResponse →
/// cumulative snapshots; the Dart side diffs them). FoundationModels logic is
/// type-checked via swiftc and `@available`-guarded (macOS 26).
public class HellohqAppleAiPlugin: NSObject, FlutterPlugin {
  static let methodChannelName = "hellohq_apple_ai"
  static let eventChannelName = "hellohq_apple_ai/stream"

  public static func register(with registrar: FlutterPluginRegistrar) {
    let messenger = registrar.messenger
    let channel = FlutterMethodChannel(name: methodChannelName, binaryMessenger: messenger)
    registrar.addMethodCallDelegate(HellohqAppleAiPlugin(), channel: channel)
    FlutterEventChannel(name: eventChannelName, binaryMessenger: messenger)
      .setStreamHandler(AppleFoundationModelsStreamHandler())
  }

  public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
    switch call.method {
    case "availability":
      result(Self.availabilityName())
    case "respond":
      let args = call.arguments as? [String: Any]
      let prompt = args?["prompt"] as? String ?? ""
      let instructions = args?["instructions"] as? String
      guard #available(macOS 26.0, *) else {
        result(FlutterError(code: "unavailable",
                            message: "The on-device model requires macOS 26 or later.",
                            details: nil))
        return
      }
      Task {
        do {
          let session = instructions == nil
            ? LanguageModelSession()
            : LanguageModelSession(instructions: instructions!)
          let response = try await session.respond(to: prompt)
          result(response.content)
        } catch {
          result(FlutterError(code: "respond_failed",
                              message: error.localizedDescription, details: nil))
        }
      }
    default:
      result(FlutterMethodNotImplemented)
    }
  }

  static func availabilityName() -> String {
    guard #available(macOS 26.0, *) else { return "unavailableUnknown" }
    switch SystemLanguageModel.default.availability {
    case .available:
      return "available"
    case .unavailable(let reason):
      switch reason {
      case .deviceNotEligible: return "deviceNotEligible"
      case .appleIntelligenceNotEnabled: return "appleIntelligenceNotEnabled"
      case .modelNotReady: return "modelNotReady"
      @unknown default: return "unavailableUnknown"
      }
    @unknown default:
      return "unavailableUnknown"
    }
  }
}

final class AppleFoundationModelsStreamHandler: NSObject, FlutterStreamHandler {
  private var task: Task<Void, Never>?

  func onListen(withArguments arguments: Any?,
                eventSink events: @escaping FlutterEventSink) -> FlutterError? {
    let args = arguments as? [String: Any]
    let prompt = args?["prompt"] as? String ?? ""
    guard #available(macOS 26.0, *) else {
      events(FlutterError(code: "unavailable",
                          message: "The on-device model requires macOS 26 or later.",
                          details: nil))
      return nil
    }
    task = Task {
      do {
        let session = LanguageModelSession()
        for try await partial in session.streamResponse(to: prompt) {
          if Task.isCancelled { return }
          events(String(describing: partial.content))
        }
        events(FlutterEndOfEventStream)
      } catch {
        events(FlutterError(code: "stream_failed",
                            message: error.localizedDescription, details: nil))
      }
    }
    return nil
  }

  func onCancel(withArguments arguments: Any?) -> FlutterError? {
    task?.cancel()
    task = nil
    return nil
  }
}
