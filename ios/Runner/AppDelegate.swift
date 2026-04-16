import AVFoundation
import Flutter
import FirebaseCore
import FirebaseMessaging
import UIKit
import UserNotifications

@main
@objc class AppDelegate: FlutterAppDelegate {
  let voiceAgentAudioRouteController = VoiceAgentAudioRouteController()
  let voiceAgentAudioRouteQueue = DispatchQueue(
    label: "uz.ustadia.user.audio_route",
    qos: .userInitiated
  )

  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    if FirebaseApp.app() == nil {
      FirebaseApp.configure()
    }
    UNUserNotificationCenter.current().delegate = self
    application.registerForRemoteNotifications()
    GeneratedPluginRegistrant.register(with: self)
    if let registrar = registrar(forPlugin: "VoiceAgentAudioRouteController") {
      let channel = FlutterMethodChannel(
        name: VoiceAgentAudioRouteController.channelName,
        binaryMessenger: registrar.messenger()
      )
      channel.setMethodCallHandler { [weak self] call, result in
        self?.handleAudioRouteMethodCall(call: call, result: result)
      }
    }
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

  func handleAudioRouteMethodCall(call: FlutterMethodCall, result: FlutterResult) {
    let arguments = call.arguments as? [String: Any]
    let reason = arguments?["reason"] as? String ?? "unknown"

    voiceAgentAudioRouteQueue.async { [weak self] in
      guard let self else { return }
      let response: Any
      switch call.method {
      case "startVoiceAgentSession":
        response = self.voiceAgentAudioRouteController.startVoiceAgentSession(reason: reason)
      case "enterVoiceAgentPlaybackMode":
        response = self.voiceAgentAudioRouteController.enterPlaybackMode(reason: reason)
      case "enterVoiceAgentCaptureMode":
        response = self.voiceAgentAudioRouteController.enterCaptureMode(reason: reason)
      case "stopVoiceAgentSession":
        response = self.voiceAgentAudioRouteController.stopVoiceAgentSession(reason: reason)
      default:
        DispatchQueue.main.async {
          result(FlutterMethodNotImplemented)
        }
        return
      }
      DispatchQueue.main.async {
        result(response)
      }
    }
  }

  override func application(
    _ application: UIApplication,
    didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data
  ) {
    Messaging.messaging().apnsToken = deviceToken
    super.application(application, didRegisterForRemoteNotificationsWithDeviceToken: deviceToken)
  }

  override func application(
    _ application: UIApplication,
    didFailToRegisterForRemoteNotificationsWithError error: Error
  ) {
    print("APNs registration failed: \(error.localizedDescription)")
    super.application(application, didFailToRegisterForRemoteNotificationsWithError: error)
  }
}

enum VoiceAgentRouteMode {
  case playback
  case capture
}

final class VoiceAgentAudioRouteController {
  static let channelName = "uz.ustadia.user/audio_route"

  let audioSession = AVAudioSession.sharedInstance()
  var sessionStarted = false
  var currentRouteMode = VoiceAgentRouteMode.playback
  var previousCategory: AVAudioSession.Category?
  var previousMode: AVAudioSession.Mode?
  var previousOptions: AVAudioSession.CategoryOptions = []
  var observersRegistered = false

  func startVoiceAgentSession(reason: String) -> [String: Any] {
    if !sessionStarted {
      previousCategory = audioSession.category
      previousMode = audioSession.mode
      previousOptions = audioSession.categoryOptions
      sessionStarted = true
      registerObservers()
    }
    currentRouteMode = .playback
    applyCurrentRoute(reason: "start:\(reason)")
    return collectRouteSnapshot(reason: "start:\(reason)")
  }

  func enterPlaybackMode(reason: String) -> [String: Any] {
    if !sessionStarted {
      return startVoiceAgentSession(reason: reason)
    }
    currentRouteMode = .playback
    applyCurrentRoute(reason: "playback:\(reason)")
    return collectRouteSnapshot(reason: "playback:\(reason)")
  }

  func enterCaptureMode(reason: String) -> [String: Any] {
    if !sessionStarted {
      _ = startVoiceAgentSession(reason: reason)
    }
    currentRouteMode = .capture
    applyCurrentRoute(reason: "capture:\(reason)")
    return collectRouteSnapshot(reason: "capture:\(reason)")
  }

  func stopVoiceAgentSession(reason: String) -> [String: Any] {
    let snapshot = collectRouteSnapshot(reason: "stop:\(reason):before_restore")
    do {
      try audioSession.overrideOutputAudioPort(.none)
      if let previousCategory, let previousMode {
        try audioSession.setCategory(previousCategory, mode: previousMode, options: previousOptions)
      }
      try audioSession.setActive(false, options: [.notifyOthersOnDeactivation])
    } catch {
      NSLog("[VoiceAgentAudioRoute] failed to restore session: \(error.localizedDescription)")
    }
    unregisterObservers()
    sessionStarted = false
    NSLog("[VoiceAgentAudioRoute] session stopped: \(snapshot)")
    return snapshot
  }

  func applyCurrentRoute(reason: String) {
    configureCaptureRoute(reason: reason)
  }

  func configurePlaybackRoute(reason: String) {
    configureCaptureRoute(reason: reason)
  }

  func configureCaptureRoute(reason: String) {
    do {
      try audioSession.setCategory(
        .playAndRecord,
        mode: .videoChat,
        options: [.defaultToSpeaker, .allowBluetooth, .allowBluetoothA2DP, .allowAirPlay]
      )
      try audioSession.setActive(true)
      if hasExternalOutputRoute() {
        try audioSession.overrideOutputAudioPort(.none)
      } else {
        try audioSession.overrideOutputAudioPort(.speaker)
      }
    } catch {
      NSLog("[VoiceAgentAudioRoute] configure capture failed for \(reason): \(error.localizedDescription)")
    }
    logAudioRoute(reason: reason)
  }

  func registerObservers() {
    if observersRegistered { return }
    let center = NotificationCenter.default
    center.addObserver(
      self,
      selector: #selector(handleRouteChangeNotification(_:)),
      name: AVAudioSession.routeChangeNotification,
      object: audioSession
    )
    center.addObserver(
      self,
      selector: #selector(handleInterruptionNotification(_:)),
      name: AVAudioSession.interruptionNotification,
      object: audioSession
    )
    center.addObserver(
      self,
      selector: #selector(handleMediaServicesResetNotification(_:)),
      name: AVAudioSession.mediaServicesWereResetNotification,
      object: audioSession
    )
    observersRegistered = true
  }

  func unregisterObservers() {
    if !observersRegistered { return }
    NotificationCenter.default.removeObserver(self)
    observersRegistered = false
  }

  @objc func handleRouteChangeNotification(_ notification: Notification) {
    let reasonValue = notification.userInfo?[AVAudioSessionRouteChangeReasonKey] as? UInt ?? 0
    let reason = routeChangeReasonName(reasonValue)
    logAudioRoute(reason: "route_change:\(reason)")
    if sessionStarted {
      applyCurrentRoute(reason: "route_change:\(reason)")
    }
  }

  @objc func handleInterruptionNotification(_ notification: Notification) {
    let typeValue = notification.userInfo?[AVAudioSessionInterruptionTypeKey] as? UInt ?? 0
    let type = AVAudioSession.InterruptionType(rawValue: typeValue) ?? .began
    NSLog("[VoiceAgentAudioRoute] interruption: \(type.rawValue)")
    if sessionStarted && type == .ended {
      applyCurrentRoute(reason: "interruption_ended")
    }
  }

  @objc func handleMediaServicesResetNotification(_ notification: Notification) {
    NSLog("[VoiceAgentAudioRoute] media services reset")
    if sessionStarted {
      applyCurrentRoute(reason: "media_services_reset")
    }
  }

  func hasExternalOutputRoute() -> Bool {
    audioSession.currentRoute.outputs.contains(where: { output in
      switch output.portType {
      case .headphones, .bluetoothA2DP, .bluetoothLE, .bluetoothHFP, .airPlay, .carAudio, .usbAudio:
        return true
      default:
        return false
      }
    })
  }

  func collectRouteSnapshot(reason: String) -> [String: Any] {
    [
      "reason": reason,
      "routeMode": currentRouteMode == .capture ? "capture" : "playback",
      "category": audioSession.category.rawValue,
      "mode": audioSession.mode.rawValue,
      "currentOutputs": audioSession.currentRoute.outputs.map(describePort),
      "currentInputs": audioSession.currentRoute.inputs.map(describePort),
      "externalOutputConnected": hasExternalOutputRoute()
    ]
  }

  func describePort(_ port: AVAudioSessionPortDescription) -> String {
    "\(port.portType.rawValue):\(port.portName)"
  }

  func routeChangeReasonName(_ reasonValue: UInt) -> String {
    guard let reason = AVAudioSession.RouteChangeReason(rawValue: reasonValue) else {
      return "unknown_\(reasonValue)"
    }
    switch reason {
    case .unknown:
      return "unknown"
    case .newDeviceAvailable:
      return "new_device_available"
    case .oldDeviceUnavailable:
      return "old_device_unavailable"
    case .categoryChange:
      return "category_change"
    case .override:
      return "override"
    case .wakeFromSleep:
      return "wake_from_sleep"
    case .noSuitableRouteForCategory:
      return "no_suitable_route"
    case .routeConfigurationChange:
      return "route_configuration_change"
    @unknown default:
      return "future_\(reasonValue)"
    }
  }

  func logAudioRoute(reason: String) {
    NSLog("[VoiceAgentAudioRoute] \(collectRouteSnapshot(reason: reason))")
  }
}
