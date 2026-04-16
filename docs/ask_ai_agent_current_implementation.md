# Ask AI Agent: Current Implementation

This document describes the current Ask AI implementation in this repository.

It is a code handoff document, not a product spec.

It covers:
- architecture
- relevant files
- data flow
- socket flow
- LiveKit voice flow
- native audio routing
- UI structure
- current lifecycle behavior
- known risk areas

## 1. High-Level Architecture

The Ask AI feature is split into three main parts:

1. `AskAiBloc`
   - owns topic list
   - owns message history
   - owns current topic
   - deduplicates incoming messages

2. `VoiceCallNotifier`
   - owns LiveKit room lifecycle
   - owns mic permission request
   - owns mic enable and disable
   - owns assistant speech detection
   - owns voice state machine
   - owns native speaker routing calls

3. `VoiceAgentPage`
   - coordinates the page lifecycle
   - creates the socket connection
   - sends text messages
   - receives live messages
   - coordinates waiting state, initial sync, timer-based sync, and teardown

Current ownership boundary:
- `AskAiBloc` handles topics and messages only
- `VoiceCallNotifier` handles voice only
- `VoiceAgentPage` stitches socket, UI, bloc, and notifier together

## 2. Main Files

### 2.1 Page and state

- `lib/features/ask_ai/presentation/pages/voice_agent_page.dart`
- `lib/features/ask_ai/state/voice_call_notifier.dart`
- `lib/features/ask_ai/presentation/bloc/ask_ai_bloc/ask_ai_bloc.dart`
- `lib/features/ask_ai/presentation/bloc/ask_ai_bloc/ask_ai_event.dart`
- `lib/features/ask_ai/presentation/bloc/ask_ai_bloc/ask_ai_state.dart`

### 2.2 Data layer

- `lib/features/ask_ai/data/datasources/ai_chat_remote_data_source.dart`
- `lib/features/ask_ai/data/models/ai_chat_message_model.dart`
- `lib/features/ask_ai/data/models/ai_chat_topic_model.dart`
- `lib/features/ask_ai/data/models/livekit_token_model.dart`

### 2.3 Widget layer

- `lib/features/ask_ai/presentation/widgets/ask_ai_conversation_content.dart`
- `lib/features/ask_ai/presentation/widgets/ask_ai_messages_panel.dart`
- `lib/features/ask_ai/presentation/widgets/ask_ai_messages_list.dart`
- `lib/features/ask_ai/presentation/widgets/ask_ai_animated_message_item.dart`
- `lib/features/ask_ai/presentation/widgets/ai_chat_message_bubble.dart`
- `lib/features/ask_ai/presentation/widgets/ask_ai_typing_indicator.dart`
- `lib/features/ask_ai/presentation/widgets/ask_ai_text_message_composer.dart`
- `lib/features/ask_ai/presentation/widgets/ask_ai_voice_controls.dart`
- `lib/features/ask_ai/presentation/widgets/ask_ai_microphone_button.dart`
- `lib/features/ask_ai/presentation/widgets/ask_ai_control_icon_button.dart`
- `lib/features/ask_ai/presentation/widgets/ask_ai_voice_agent_section.dart`
- `lib/features/ask_ai/widgets/voice_orb.dart`
- `lib/features/ask_ai/presentation/widgets/ask_ai_page_app_bar.dart`
- `lib/features/ask_ai/presentation/widgets/ai_chat_topic_card.dart`

### 2.4 Navigation

- `lib/features/ask_ai/presentation/pages/ask_ai_topics_page.dart`
- `lib/router.dart`

### 2.5 Native audio routing bridge

- `lib/core/services/voice_agent_audio_route_service.dart`
- `ios/Runner/AppDelegate.swift`
- `android/app/src/main/kotlin/com/example/ustadia_user_app/MainActivity.kt`

## 3. Data and API Layer

`AiChatRemoteDataSource` uses Dio and currently exposes three REST calls.

### 3.1 Fetch topics

Method:
- `fetchTopics({required int page, required int limit})`

Endpoint:
- `GET /student/ai-chat/topics`

Query params:
- `page`
- `limit`

### 3.2 Fetch messages

Method:
- `fetchMessages({required String topicId, required int page, required int limit})`

Endpoint:
- `GET /student/ai-chat/topics/{topicId}/messages`

Query params:
- `page`
- `limit`

### 3.3 Fetch LiveKit token

Method:
- `fetchLivekitToken({required String topicId})`

Endpoint:
- `POST /student/ai-chat/livekit/token`

Payload:
```json
{
  "topicId": "<topicId>"
}
```

## 4. Data Models

### 4.1 `AiChatTopicModel`

Fields:
- `id`
- `title`
- `description`
- `duration`

### 4.2 `AiChatMessageModel`

Fields:
- `id`
- `topicId`
- `userId`
- `role`
- `content`
- `createdAt`
- `isFinished`

Special behavior:
- if backend message `id` is missing, a synthetic id is generated from:
  - `topicId`
  - `userId`
  - `role`
  - `created_at`
  - `content`

### 4.3 `LivekitTokenModel`

Fields:
- `url`
- `token`
- `roomName`
- `participantIdentity`
- `sttEnabled`
- `ttsEnabled`
- `metadata`

## 5. AskAiBloc

### 5.1 Responsibilities

`AskAiBloc` is intentionally narrow.

It handles:
- loading topics
- opening a topic
- loading messages
- receiving a message from the socket path
- merging and deduplicating messages

It does not handle:
- LiveKit
- microphone
- speaker routing
- room events
- socket creation

### 5.2 Events

Current events:
- `AskAiTopicsRequested`
- `AskAiTopicOpened`
- `AskAiMessagesRequested`
- `AskAiMessageReceived`

### 5.3 State

Current state fields:
- `topicsStatus`
- `messagesStatus`
- `topics`
- `messages`
- `currentTopic`
- `errorMessage`
- `userId`

### 5.4 Message merge logic

Messages are deduplicated in two phases:

1. by direct `id`
2. by semantic key

Semantic key format:
```text
topicId|userId|role|createdAtSecond|trimmedContent
```

This exists because:
- the same message can arrive via socket and later via REST
- those two versions may not have the same id

## 6. Ask AI Navigation

### 6.1 Topic page

Route entry:
- `/home/ask-ai`

Screen:
- `AskAiTopicsPage`

Behavior:
- dispatches `AskAiTopicsRequested` on first frame
- renders topic cards
- opens voice page with selected topic

### 6.2 Voice page

Route:
- `/home/ask-ai/ask-ai-voice-agent`

Screen:
- `VoiceAgentPage(topic: ...)`

In `AskAiTopicsPage`, there is a push guard:
- `isOpeningVoiceAgent`

Purpose:
- avoids pushing multiple voice pages if the user taps rapidly

## 7. VoiceAgentPage Runtime Flow

### 7.1 What the page owns

`VoiceAgentPage` owns:
- `socket`
- message input controller
- page timers
- pagination state
- waiting state
- topic duration timer
- startup sequencing
- shutdown sequencing

It also creates:
- `VoiceCallNotifier`

### 7.2 Startup behavior

Current `initState()` flow:

1. add page as `WidgetsBindingObserver`
2. create `VoiceCallNotifier`
3. attach notifier listener
4. in first post-frame callback:
   - dispatch `AskAiTopicOpened`
   - start duration timer if topic has time limit
   - call `schedulePageStartup()`

Current startup sequencing:
- socket startup uses `Future.microtask`
- voice startup uses a delayed timer

Current constant:
- `voiceStartupDelay = 450ms`

Current startup goal:
- start page UI immediately
- connect socket first
- connect voice slightly later

### 7.3 Socket connection

Socket namespace:
- `"$baseUrl/ai-chat"`

Socket config:
- transport: `websocket`
- path: `/socket.io`
- extra headers:
  - `Authorization: Bearer <token>`

Socket creation guard:
- if `socket != null`, do nothing

Important socket events:
- `connect`
- `disconnect`
- `connect_error`
- `ai_chat_connected`
- `ai_chat_error`
- `newMessage`

### 7.4 Text message send flow

`sendTextMessage()`:

1. takes text from `messageController`
2. trims it
3. disables microphone if currently enabled
4. if socket is not connected, attempts socket connect and returns
5. emits `sendMessage`

Payload:
```json
{
  "topicId": "<topicId>",
  "transcript": "<typed text>",
  "language": "<current locale code>"
}
```

6. clears input
7. removes focus
8. starts local waiting state

### 7.5 Incoming message flow

On `newMessage`:

1. payload is converted to `AiChatMessageModel`
2. topic mismatch is ignored
3. message is pushed into bloc via `AskAiMessageReceived`
4. if assistant message arrives while waiting:
   - waiting state is cleared
5. if user message arrives and page was not waiting:
   - waiting state starts
6. if `message.isFinished == true`:
   - mic is disabled

### 7.6 Waiting state

Page-local field:
- `waitingForAssistantResponse`

This is not stored in bloc or notifier.

It starts when:
- text message is sent
- spoken turn is stopped and speech was detected
- user message arrives via socket and page is not already waiting

It stops when:
- assistant message arrives
- assistant starts speaking
- timeout fires

Current timeout:
- `assistantResponseTimeout = 10s`

Timeout handler behavior:
- clears waiting state
- requests latest messages from REST

### 7.7 Initial assistant message sync

The page has retry logic because the first assistant reply may not be present in REST immediately.

Fields:
- `initialAssistantSyncCompleted`
- `initialAssistantSyncAttempts`
- `maxInitialAssistantSyncAttempts = 12`

Methods:
- `scheduleInitialMessagesSync()`
- `syncLatestMessages()`

Behavior:
- if no assistant message exists in current list, page retries REST fetch

### 7.8 Assistant turn sync

When assistant speaking ends:
- page schedules another message fetch after `900ms`

Purpose:
- backend may save assistant text later than audio playback start/end

### 7.9 Teardown behavior

On close:
- page calls `beginClosing()`
- cancels timers
- removes notifier listener
- schedules background shutdown

Background shutdown:
- stores current socket reference
- nulls socket
- waits `shutdownDelay = 420ms`
- disposes socket
- disposes notifier

Current close goal:
- pop page immediately
- avoid heavy teardown work during the pop itself

## 8. VoiceCallNotifier

### 8.1 Responsibilities

`VoiceCallNotifier` owns:
- LiveKit room
- LiveKit room listeners
- microphone permission
- connect and disconnect
- app pause and resume voice behavior
- mic enable and disable
- assistant visualizer
- speech detection
- voice UI state
- audio-route service calls

### 8.2 Voice state

Enum:
- `connecting`
- `listening`
- `thinking`
- `speaking`
- `error`

This is heuristic UI state.
It is not a fully authoritative server turn state.

### 8.3 Connect flow

`connect()` currently does:

1. guard against:
   - disposed notifier
   - already connecting
   - already connected
   - disconnect already in progress
2. request microphone permission with `permission_handler`
3. if denied:
   - set `errorMessage`
   - set voice state to `error`
   - notify
4. increment `connectAttemptId`
5. mark `isConnecting = true`
6. call native audio route:
   - `VoiceAgentAudioRouteService.startSession(reason: 'before_livekit_connect')`
7. fetch LiveKit token from backend
8. create `Room`
9. attach room listeners
10. connect to LiveKit room
11. set `room = nextRoom`
12. disable local microphone
13. wait `300ms`
14. apply capture mode:
   - `VoiceAgentAudioRouteService.enterCaptureMode(...)`
   - `room.setSpeakerOn(true, forceSpeakerOutput: true)`
15. update local flags
16. switch to `VoiceUiState.listening`

### 8.4 Disconnect flow

`disconnect()` is serialized through:
- `disconnectOperation`

`disconnectInternal()`:
- invalidates old connect attempts
- cancels timers
- disposes assistant visualizer
- disposes LiveKit event listener
- disables mic
- disconnects room
- stops native audio session
- disposes room
- resets notifier state

### 8.5 App lifecycle

On pause:
- notifier disconnects fully

On resume:
- if already connected:
  - reapplies audio mode
  - re-forces speaker through LiveKit room

### 8.6 Microphone flow

Important fields:
- `micEnabled`
- `isMicrophoneTransitioning`
- `userTurnHasSpeech`
- `userSpeaking`
- `localSpeaking`
- `localAudioLevel`

Current mic behavior:
- does not republish/unpublish local track every turn
- only calls `room.localParticipant.setMicrophoneEnabled(true/false)`

### 8.7 Assistant speech detection

Assistant speaking is inferred from the remote audio visualizer.

Path:
- remote audio track subscribed
- `attachAssistantAudioVisualizer(track)`
- visualizer emits level values
- level updates `agentAudioLevel`
- if above threshold, assistant lock refreshes

Relevant fields:
- `assistantSpeaking`
- `assistantAudioLocked`
- `agentAudioPlaying`
- `agentAudioLevel`

Current thresholds:
- `assistantVisualizerThreshold = 0.08`
- `levelNotifyThreshold = 0.035`

Lock behavior:
- speaking refresh sets a timer
- after `1400ms` without refresh, assistant speaking is released

### 8.8 User speech detection

User speaking comes from:
- `ActiveSpeakersChangedEvent`

Relevant fields:
- `userSpeaking`
- `localSpeaking`
- `localAudioLevel`
- `userTurnHasSpeech`

Threshold:
- `assistantSpeakingThreshold = 0.01`

### 8.9 Room listeners

Main LiveKit events used:
- `RoomConnectedEvent`
- `RoomDisconnectedEvent`
- `ParticipantConnectedEvent`
- `ParticipantDisconnectedEvent`
- `TrackSubscribedEvent`
- `TrackUnsubscribedEvent`
- `LocalTrackPublishedEvent`
- `ActiveSpeakersChangedEvent`

Important behavior:
- `TrackSubscribedEvent` with `RemoteAudioTrack`:
  - stops local mic
  - stores assistant participant identity
  - starts remote track playback
  - attaches visualizer

### 8.10 Current risk in notifier

The notifier is still the heaviest part of the feature because it combines:
- network connect
- native audio setup
- room events
- high-frequency audio-level updates

Even after optimization, this remains the main performance hotspot.

## 9. Voice UI Composition

Current screen composition:

- app bar
- message list panel
- voice orb section on top
- bottom controls

Bottom controls switch between:
- voice mode controls
- text composer

### 9.1 Voice section

`AskAiVoiceAgentSection` shows:
- equalizer bars
- `VoiceOrb`
- status text

Inputs:
- notifier
- current `VoiceUiState`
- resolved status text

### 9.2 Voice orb

`VoiceOrb` is a stateful animated widget.

It reacts to:
- `voiceUiState`
- `assistantLevel`
- `userLevel`
- `assistantSpeaking`
- `userSpeaking`

Animation speed changes per state:
- connecting
- listening
- thinking
- speaking
- error

### 9.3 Messages

`AskAiMessagesPanel` renders:
- loading view
- error view
- `AskAiMessagesList`
- overlay typing indicator

`AskAiMessagesList`:
- uses `ListView(reverse: true)`
- reverses messages for chat layout
- shows pagination loader

`AskAiAnimatedMessageItem`:
- animates each message with fade + slide
- replays animation if content changes

`AiChatMessageBubble`:
- user messages are green
- assistant messages are dark translucent bubbles in current dark theme

### 9.4 Text composer

`AskAiTextMessageComposer`:
- left mic icon switches back to voice mode
- center expandable text field
- right send button

### 9.5 Voice controls

`AskAiVoiceControls`:
- center mic/stop button
- right keyboard button

## 10. Native Audio Route Service

Flutter bridge:
- `VoiceAgentAudioRouteService`

Method channel:
- `uz.ustadia.user/audio_route`

Methods:
- `startVoiceAgentSession`
- `enterVoiceAgentPlaybackMode`
- `enterVoiceAgentCaptureMode`
- `stopVoiceAgentSession`

Current Dart behavior:
- all native calls are awaited from Dart
- debug logs print returned native snapshots

## 11. iOS Native Audio Routing

Location:
- `ios/Runner/AppDelegate.swift`

### 11.1 Bridge behavior

The Flutter method calls are handled in `AppDelegate`.

Important current change:
- method calls are dispatched to a dedicated serial `DispatchQueue`
- result is returned back on main queue

Purpose:
- reduce Flutter-thread stalls caused by native audio routing work

### 11.2 Controller behavior

`VoiceAgentAudioRouteController` owns:
- one `AVAudioSession`
- route mode
- previous session snapshot for restore
- observer registration for route change / interruption / media reset

Current routing behavior:
- playback and capture both resolve to `configureCaptureRoute()`
- this keeps one stable speaker-capable session

Current session config:
- category: `.playAndRecord`
- mode: `.videoChat`
- options:
  - `.defaultToSpeaker`
  - `.allowBluetooth`
  - `.allowBluetoothA2DP`
  - `.allowAirPlay`

If no external route exists:
- output is overridden to `.speaker`

## 12. Android Native Audio Routing

Location:
- `android/app/src/main/kotlin/com/example/ustadia_user_app/MainActivity.kt`

### 12.1 Bridge behavior

Important current change:
- method calls are handled on a dedicated single-thread `ExecutorService`
- result is posted back to main thread through `Handler(Looper.getMainLooper())`

Purpose:
- reduce Flutter-thread stalls from audio routing work

### 12.2 Controller behavior

`VoiceAgentAudioRouteController` owns:
- `AudioManager`
- previous audio mode
- previous speaker state
- audio device callback

Current route behavior:
- playback and capture both resolve to `applyCaptureRoute()`
- this keeps a stable communication route instead of flipping modes repeatedly

Current route config:
- `AudioManager.MODE_IN_COMMUNICATION`
- built-in speaker communication device when available
- `isSpeakerphoneOn = true` if no external output route is connected

## 13. Current Page Status Logic

Status text is derived in `voice_agent_page.dart`.

Current logic priority:
1. error
2. connecting
3. socket disconnected
4. assistant speaking
5. waiting for assistant response
6. user actively speaking
7. mic enabled
8. not connected
9. idle

Current status texts include:
- `Connecting to agent...`
- `Connecting messages...`
- `Speaking`
- `Thinking...`
- `Listening...`
- `Speak now`
- `Tap microphone`

## 14. Current Performance Strategy

The current implementation already tries to reduce freezes by:
- not unpublishing mic track every turn
- delaying voice startup after page open
- closing socket and notifier in background after pop
- moving native audio route work onto native worker queues
- thresholding assistant audio notifications
- avoiding some redundant rebuilds

## 15. Current Known Problems / Risk Areas

These are the main unstable parts of the current implementation.

### 15.1 Voice page can still feel heavier than a normal page

Reason:
- LiveKit connect/disconnect is still expensive
- native audio session work is still expensive
- message/socket/voice are still tightly coupled inside one page

### 15.2 Voice startup and teardown are still timer-based

Current page relies on:
- `Future.microtask` for socket
- delayed timer for voice startup
- delayed timer for background shutdown

This works pragmatically, but it is not a formal lifecycle state machine.

### 15.3 Voice and chat are coordinated in several places

State is currently split across:
- `VoiceAgentPage`
- `VoiceCallNotifier`
- `AskAiBloc`
- socket callbacks

That makes debugging race conditions harder.

### 15.4 First assistant message persistence may lag behind voice playback

This is why the page still contains:
- initial assistant sync retry
- post-assistant-turn sync

## 16. Suggested Reading Order For Another Engineer

If another engineer or model needs to debug or rewrite this feature, read in this order:

1. `lib/features/ask_ai/presentation/pages/voice_agent_page.dart`
2. `lib/features/ask_ai/state/voice_call_notifier.dart`
3. `lib/features/ask_ai/presentation/bloc/ask_ai_bloc/ask_ai_bloc.dart`
4. `lib/features/ask_ai/data/datasources/ai_chat_remote_data_source.dart`
5. `lib/core/services/voice_agent_audio_route_service.dart`
6. `ios/Runner/AppDelegate.swift`
7. `android/app/src/main/kotlin/com/example/ustadia_user_app/MainActivity.kt`
8. widget files only after the runtime flow is understood

## 17. What Should Be Preserved

These design boundaries should be kept unless there is a deliberate rewrite:

- `AskAiBloc` handles topics and messages only
- `VoiceCallNotifier` handles LiveKit and voice state
- socket sends typed messages with `sendMessage`
- bloc deduplicates messages with semantic keys
- native route service forces speaker-capable audio routing
- voice page has a duplicate-open guard from topics page

## 18. Short Summary

The current Ask AI implementation is a hybrid of:
- REST history
- socket-based live messaging
- LiveKit voice transport
- native speaker-routing code

Text mode is comparatively simple.

Voice mode is complex because page lifecycle, LiveKit, microphone state, waiting state, message sync, and native audio routing all interact in real time.
