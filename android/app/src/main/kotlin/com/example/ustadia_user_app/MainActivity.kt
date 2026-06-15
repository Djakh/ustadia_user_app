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
import java.util.concurrent.ExecutorService
import java.util.concurrent.Executors

class MainActivity : FlutterFragmentActivity() {
  lateinit var voiceAgentAudioRouteController: VoiceAgentAudioRouteController
  val audioRouteExecutor: ExecutorService = Executors.newSingleThreadExecutor()
  val mainHandler = Handler(Looper.getMainLooper())

  override fun onCreate(savedInstanceState: Bundle?) {
    enableEdgeToEdge()
    super.onCreate(savedInstanceState)
    voiceAgentAudioRouteController = VoiceAgentAudioRouteController(this)
  }

  override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
    super.configureFlutterEngine(flutterEngine)
    val channel =
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, VoiceAgentAudioRouteController.channelName)
    voiceAgentAudioRouteController.methodChannel = channel
    channel.setMethodCallHandler { call, result ->
      handleAudioRouteMethodCall(call, result)
    }
  }

  fun handleAudioRouteMethodCall(call: MethodCall, result: MethodChannel.Result) {
    val reason = call.argument<String>("reason") ?: "unknown"
    val outputMode = VoiceAgentOutputMode.from(call.argument<String>("outputMode"))
    audioRouteExecutor.execute {
      val response: Any? =
          when (call.method) {
            "startVoiceAgentSession" -> voiceAgentAudioRouteController.startVoiceAgentSession(outputMode, reason)
            "enterVoiceAgentPlaybackMode" -> voiceAgentAudioRouteController.applyOutputMode(VoiceAgentOutputMode.speaker, "legacy_playback:$reason")
            "enterVoiceAgentCaptureMode" -> voiceAgentAudioRouteController.applyOutputMode(VoiceAgentOutputMode.speaker, "legacy_capture:$reason")
            "applyVoiceAgentOutputMode" -> voiceAgentAudioRouteController.applyOutputMode(outputMode, reason)
            "stopVoiceAgentSession" -> voiceAgentAudioRouteController.stopVoiceAgentSession(reason)
            else -> null
          }
      mainHandler.post {
        if (response == null) {
          result.notImplemented()
        } else {
          result.success(response)
        }
      }
    }
  }

  override fun onDestroy() {
    voiceAgentAudioRouteController.stopVoiceAgentSession("activity_destroyed")
    audioRouteExecutor.shutdown()
    super.onDestroy()
  }
}

enum class VoiceAgentOutputMode {
  speaker,
  phone;

  companion object {
    fun from(value: String?): VoiceAgentOutputMode {
      return values().firstOrNull { it.name == value } ?: speaker
    }
  }
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
  var currentOutputMode = VoiceAgentOutputMode.speaker
  var previousAudioMode = AudioManager.MODE_NORMAL
  var previousSpeakerphoneState = false
  var methodChannel: MethodChannel? = null

  val audioDeviceCallback =
      object : AudioDeviceCallback() {
        override fun onAudioDevicesAdded(addedDevices: Array<out AudioDeviceInfo>) {
          logAudioRoute("devices_added")
          if (sessionStarted) {
            applyCurrentRoute("devices_added")
            notifyFlutterRouteChanged("devices_added")
          }
        }

        override fun onAudioDevicesRemoved(removedDevices: Array<out AudioDeviceInfo>) {
          logAudioRoute("devices_removed")
          if (sessionStarted) {
            applyCurrentRoute("devices_removed")
            notifyFlutterRouteChanged("devices_removed")
          }
        }
      }

  fun startVoiceAgentSession(
      outputMode: VoiceAgentOutputMode = VoiceAgentOutputMode.speaker,
      reason: String
  ): Map<String, Any> {
    if (!sessionStarted) {
      previousAudioMode = audioManager.mode
      previousSpeakerphoneState = audioManager.isSpeakerphoneOn
      sessionStarted = true
      registerAudioDeviceCallback()
    }
    currentOutputMode = outputMode
    applyCurrentRoute("start:$reason")
    return collectRouteSnapshot("start:$reason")
  }

  fun applyOutputMode(outputMode: VoiceAgentOutputMode, reason: String): Map<String, Any> {
    if (!sessionStarted) {
      return startVoiceAgentSession(outputMode, reason)
    }
    currentOutputMode = outputMode
    applyCurrentRoute("output:${outputMode.name}:$reason")
    return collectRouteSnapshot("output:${outputMode.name}:$reason")
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
    applyOutputRoute(currentOutputMode, reason)
  }

  fun applyOutputRoute(outputMode: VoiceAgentOutputMode, reason: String) {
    val externalOutputConnected = hasExternalOutputRoute()
    if (audioManager.mode != AudioManager.MODE_IN_COMMUNICATION) {
      audioManager.mode = AudioManager.MODE_IN_COMMUNICATION
    }

    if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
      if (externalOutputConnected) {
        val externalDevice = preferredExternalCommunicationDevice()
        if (externalDevice != null) {
          audioManager.setCommunicationDevice(externalDevice)
        } else {
          audioManager.clearCommunicationDevice()
        }
      } else {
        val deviceType =
            if (outputMode == VoiceAgentOutputMode.speaker) {
              AudioDeviceInfo.TYPE_BUILTIN_SPEAKER
            } else {
              AudioDeviceInfo.TYPE_BUILTIN_EARPIECE
            }
        val outputDevice = audioManager.availableCommunicationDevices.firstOrNull { it.type == deviceType }
        if (outputDevice != null) {
          audioManager.setCommunicationDevice(outputDevice)
        } else {
          audioManager.clearCommunicationDevice()
        }
      }
    }

    val shouldUseSpeakerphone =
        !externalOutputConnected && outputMode == VoiceAgentOutputMode.speaker
    if (audioManager.isSpeakerphoneOn != shouldUseSpeakerphone) {
      audioManager.isSpeakerphoneOn = shouldUseSpeakerphone
    }
    if (shouldUseSpeakerphone) {
      @Suppress("DEPRECATION")
      audioManager.isBluetoothScoOn = false
      @Suppress("DEPRECATION")
      audioManager.stopBluetoothSco()
    }

    logAudioRoute(reason)
  }

  fun preferredExternalCommunicationDevice(): AudioDeviceInfo? {
    if (Build.VERSION.SDK_INT < Build.VERSION_CODES.S) return null
    val preferredTypes =
        listOf(
            AudioDeviceInfo.TYPE_BLUETOOTH_SCO,
            AudioDeviceInfo.TYPE_BLE_HEADSET,
            AudioDeviceInfo.TYPE_WIRED_HEADSET,
            AudioDeviceInfo.TYPE_USB_HEADSET,
            AudioDeviceInfo.TYPE_WIRED_HEADPHONES,
            AudioDeviceInfo.TYPE_USB_DEVICE,
            AudioDeviceInfo.TYPE_BLUETOOTH_A2DP,
            AudioDeviceInfo.TYPE_BLE_SPEAKER)
    for (type in preferredTypes) {
      val device = audioManager.availableCommunicationDevices.firstOrNull { it.type == type }
      if (device != null) return device
    }
    return null
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

  fun notifyFlutterRouteChanged(reason: String) {
    val snapshot = collectRouteSnapshot(reason)
    mainHandler.post {
      methodChannel?.invokeMethod("voiceAgentAudioRouteChanged", snapshot)
    }
  }

  fun collectRouteSnapshot(reason: String): Map<String, Any> {
    val snapshot = mutableMapOf<String, Any>()
    snapshot["reason"] = reason
    snapshot["outputMode"] = currentOutputMode.name
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
