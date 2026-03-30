package uz.ustadia.user

import android.content.Context
import android.media.AudioDeviceCallback
import android.media.AudioDeviceInfo
import android.media.AudioManager
import android.os.Build
import android.os.Bundle
import android.os.Handler
import android.os.Looper
import android.util.Log
import androidx.activity.enableEdgeToEdge
import io.flutter.embedding.android.FlutterFragmentActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterFragmentActivity() {
  lateinit var voiceAgentAudioRouteController: VoiceAgentAudioRouteController

  override fun onCreate(savedInstanceState: Bundle?) {
    enableEdgeToEdge()
    super.onCreate(savedInstanceState)
    voiceAgentAudioRouteController = VoiceAgentAudioRouteController(this)
  }

  override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
    super.configureFlutterEngine(flutterEngine)
    MethodChannel(flutterEngine.dartExecutor.binaryMessenger, VoiceAgentAudioRouteController.channelName)
        .setMethodCallHandler { call, result ->
          handleAudioRouteMethodCall(call, result)
        }
  }

  fun handleAudioRouteMethodCall(call: MethodCall, result: MethodChannel.Result) {
    val reason = call.argument<String>("reason") ?: "unknown"
    when (call.method) {
      "startVoiceAgentSession" -> result.success(voiceAgentAudioRouteController.startVoiceAgentSession(reason))
      "enterVoiceAgentPlaybackMode" -> result.success(voiceAgentAudioRouteController.enterPlaybackMode(reason))
      "enterVoiceAgentCaptureMode" -> result.success(voiceAgentAudioRouteController.enterCaptureMode(reason))
      "stopVoiceAgentSession" -> result.success(voiceAgentAudioRouteController.stopVoiceAgentSession(reason))
      else -> result.notImplemented()
    }
  }

  override fun onDestroy() {
    voiceAgentAudioRouteController.stopVoiceAgentSession("activity_destroyed")
    super.onDestroy()
  }
}

enum class VoiceAgentRouteMode {
  playback,
  capture,
}

class VoiceAgentAudioRouteController(context: Context) {
  companion object {
    const val channelName = "uz.ustadia.user/audio_route"
    const val tag = "VoiceAgentAudioRoute"
  }

  val applicationContext: Context = context.applicationContext
  val audioManager: AudioManager =
      applicationContext.getSystemService(Context.AUDIO_SERVICE) as AudioManager
  val mainHandler = Handler(Looper.getMainLooper())

  var sessionStarted = false
  var callbackRegistered = false
  var currentRouteMode = VoiceAgentRouteMode.playback
  var previousAudioMode = AudioManager.MODE_NORMAL
  var previousSpeakerphoneState = false

  val audioDeviceCallback =
      object : AudioDeviceCallback() {
        override fun onAudioDevicesAdded(addedDevices: Array<out AudioDeviceInfo>) {
          logAudioRoute("devices_added")
          if (sessionStarted) {
            applyCurrentRoute("devices_added")
          }
        }

        override fun onAudioDevicesRemoved(removedDevices: Array<out AudioDeviceInfo>) {
          logAudioRoute("devices_removed")
          if (sessionStarted) {
            applyCurrentRoute("devices_removed")
          }
        }
      }

  fun startVoiceAgentSession(reason: String): Map<String, Any> {
    if (!sessionStarted) {
      previousAudioMode = audioManager.mode
      previousSpeakerphoneState = audioManager.isSpeakerphoneOn
      sessionStarted = true
      registerAudioDeviceCallback()
    }
    currentRouteMode = VoiceAgentRouteMode.playback
    applyCurrentRoute("start:$reason")
    return collectRouteSnapshot("start:$reason")
  }

  fun enterPlaybackMode(reason: String): Map<String, Any> {
    if (!sessionStarted) {
      return startVoiceAgentSession(reason)
    }
    currentRouteMode = VoiceAgentRouteMode.playback
    applyCurrentRoute("playback:$reason")
    return collectRouteSnapshot("playback:$reason")
  }

  fun enterCaptureMode(reason: String): Map<String, Any> {
    if (!sessionStarted) {
      startVoiceAgentSession(reason)
    }
    currentRouteMode = VoiceAgentRouteMode.capture
    applyCurrentRoute("capture:$reason")
    return collectRouteSnapshot("capture:$reason")
  }

  fun stopVoiceAgentSession(reason: String): Map<String, Any> {
    val snapshot = collectRouteSnapshot("stop:$reason:before_restore")
    if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
      audioManager.clearCommunicationDevice()
    }
    audioManager.isSpeakerphoneOn = previousSpeakerphoneState
    audioManager.mode = previousAudioMode
    unregisterAudioDeviceCallback()
    sessionStarted = false
    Log.d(tag, "session stopped: $snapshot")
    return snapshot
  }

  fun registerAudioDeviceCallback() {
    if (callbackRegistered) return
    audioManager.registerAudioDeviceCallback(audioDeviceCallback, mainHandler)
    callbackRegistered = true
  }

  fun unregisterAudioDeviceCallback() {
    if (!callbackRegistered) return
    audioManager.unregisterAudioDeviceCallback(audioDeviceCallback)
    callbackRegistered = false
  }

  fun applyCurrentRoute(reason: String) {
    if (currentRouteMode == VoiceAgentRouteMode.capture) {
      applyCaptureRoute(reason)
      return
    }
    applyPlaybackRoute(reason)
  }

  fun applyPlaybackRoute(reason: String) {
    val externalOutputConnected = hasExternalOutputRoute()
    audioManager.mode = AudioManager.MODE_NORMAL

    if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
      audioManager.clearCommunicationDevice()
    }

    if (!externalOutputConnected) {
      audioManager.isSpeakerphoneOn = true
    }

    logAudioRoute(reason)
  }

  fun applyCaptureRoute(reason: String) {
    val externalOutputConnected = hasExternalOutputRoute()
    audioManager.mode = AudioManager.MODE_IN_COMMUNICATION

    if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
      if (externalOutputConnected) {
        audioManager.clearCommunicationDevice()
      } else {
        val speakerDevice =
            audioManager.availableCommunicationDevices.firstOrNull {
              it.type == AudioDeviceInfo.TYPE_BUILTIN_SPEAKER
            }
        if (speakerDevice != null) {
          audioManager.setCommunicationDevice(speakerDevice)
        } else {
          audioManager.clearCommunicationDevice()
        }
      }
    }

    if (!externalOutputConnected) {
      audioManager.isSpeakerphoneOn = true
      @Suppress("DEPRECATION")
      audioManager.isBluetoothScoOn = false
      @Suppress("DEPRECATION")
      audioManager.stopBluetoothSco()
    }

    logAudioRoute(reason)
  }

  fun hasExternalOutputRoute(): Boolean {
    if (Build.VERSION.SDK_INT < Build.VERSION_CODES.M) {
      return audioManager.isWiredHeadsetOn || audioManager.isBluetoothScoOn || audioManager.isBluetoothA2dpOn
    }
    return audioManager.getDevices(AudioManager.GET_DEVICES_OUTPUTS).any { device ->
      device.type in
          setOf(
              AudioDeviceInfo.TYPE_WIRED_HEADSET,
              AudioDeviceInfo.TYPE_WIRED_HEADPHONES,
              AudioDeviceInfo.TYPE_BLUETOOTH_A2DP,
              AudioDeviceInfo.TYPE_BLUETOOTH_SCO,
              AudioDeviceInfo.TYPE_USB_DEVICE,
              AudioDeviceInfo.TYPE_USB_HEADSET,
              AudioDeviceInfo.TYPE_AUX_LINE,
              AudioDeviceInfo.TYPE_LINE_ANALOG,
              AudioDeviceInfo.TYPE_LINE_DIGITAL,
              AudioDeviceInfo.TYPE_HDMI,
              AudioDeviceInfo.TYPE_HDMI_ARC,
              AudioDeviceInfo.TYPE_BLE_HEADSET,
              AudioDeviceInfo.TYPE_BLE_SPEAKER,
              AudioDeviceInfo.TYPE_BLE_BROADCAST)
    }
  }

  fun logAudioRoute(reason: String) {
    Log.d(tag, "route snapshot: ${collectRouteSnapshot(reason)}")
  }

  fun collectRouteSnapshot(reason: String): Map<String, Any> {
    val snapshot = mutableMapOf<String, Any>()
    snapshot["reason"] = reason
    snapshot["routeMode"] = currentRouteMode.name
    snapshot["audioMode"] = audioModeName(audioManager.mode)
    snapshot["speakerphoneOn"] = audioManager.isSpeakerphoneOn
    snapshot["externalOutputConnected"] = hasExternalOutputRoute()
    if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
      snapshot["communicationDevice"] = audioManager.communicationDevice?.productName?.toString() ?: "none"
      snapshot["availableCommunicationDevices"] =
          audioManager.availableCommunicationDevices.map { describeDevice(it) }
    }
    if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
      snapshot["outputDevices"] =
          audioManager.getDevices(AudioManager.GET_DEVICES_OUTPUTS).map { describeDevice(it) }
    }
    return snapshot
  }

  fun describeDevice(device: AudioDeviceInfo): String {
    val name = device.productName?.toString()?.ifBlank { "unnamed" } ?: "unnamed"
    return "${audioDeviceTypeName(device.type)}:$name"
  }

  fun audioModeName(mode: Int): String {
    return when (mode) {
      AudioManager.MODE_NORMAL -> "MODE_NORMAL"
      AudioManager.MODE_RINGTONE -> "MODE_RINGTONE"
      AudioManager.MODE_IN_CALL -> "MODE_IN_CALL"
      AudioManager.MODE_IN_COMMUNICATION -> "MODE_IN_COMMUNICATION"
      AudioManager.MODE_CALL_SCREENING -> "MODE_CALL_SCREENING"
      AudioManager.MODE_CALL_REDIRECT -> "MODE_CALL_REDIRECT"
      AudioManager.MODE_COMMUNICATION_REDIRECT -> "MODE_COMMUNICATION_REDIRECT"
      else -> "MODE_$mode"
    }
  }

  fun audioDeviceTypeName(type: Int): String {
    return when (type) {
      AudioDeviceInfo.TYPE_BUILTIN_EARPIECE -> "BUILTIN_EARPIECE"
      AudioDeviceInfo.TYPE_BUILTIN_SPEAKER -> "BUILTIN_SPEAKER"
      AudioDeviceInfo.TYPE_WIRED_HEADSET -> "WIRED_HEADSET"
      AudioDeviceInfo.TYPE_WIRED_HEADPHONES -> "WIRED_HEADPHONES"
      AudioDeviceInfo.TYPE_BLUETOOTH_SCO -> "BLUETOOTH_SCO"
      AudioDeviceInfo.TYPE_BLUETOOTH_A2DP -> "BLUETOOTH_A2DP"
      AudioDeviceInfo.TYPE_USB_DEVICE -> "USB_DEVICE"
      AudioDeviceInfo.TYPE_USB_HEADSET -> "USB_HEADSET"
      AudioDeviceInfo.TYPE_HDMI -> "HDMI"
      AudioDeviceInfo.TYPE_HDMI_ARC -> "HDMI_ARC"
      AudioDeviceInfo.TYPE_AUX_LINE -> "AUX_LINE"
      AudioDeviceInfo.TYPE_LINE_ANALOG -> "LINE_ANALOG"
      AudioDeviceInfo.TYPE_LINE_DIGITAL -> "LINE_DIGITAL"
      AudioDeviceInfo.TYPE_BLE_HEADSET -> "BLE_HEADSET"
      AudioDeviceInfo.TYPE_BLE_SPEAKER -> "BLE_SPEAKER"
      AudioDeviceInfo.TYPE_BLE_BROADCAST -> "BLE_BROADCAST"
      else -> "TYPE_$type"
    }
  }
}
