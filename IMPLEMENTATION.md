# RoboSanta Interactive Speech System – Implementation Reference

## Purpose
This document is an information pack for future contributors (human or AI) explaining how the interactive RoboSanta experience currently works: speech generation, filesystem queueing, interaction coordination, and figurine motion/idle behaviours. It reflects the code as implemented, not a backlog of work.

---

## System at a Glance
- **SantaSpeaker**: Generates conversation sets (start/middle*/end WAVs) into a filesystem queue.
- **SpeechQueueManager**: Maintains the queue, exposes counts, consumes the oldest set, moves completed sets to `DONE`, and restores orphaned `.inprogress` folders.
- **InteractionCoordinator**: Orchestrates everything at runtime: watches queue counts, tracks person detection, drives the interaction state machine, plays audio, and commands idle behaviours on the StateMachine.
- **StateMachine**: Owns all servo control, tracking, gestures, and publishes detection updates. Idle modes include patrol (when queue has content) and minimal idle (when empty) with subtle motion.
- **AudioPlayer**: Async WAV playback with completion/interruption signalling.
- **RuntimeCoordinator**: Wires together detection source, StateMachine, and interactive mode at app start.

---

## Filesystem Queue (SpeechQueue)
- **Location**: `~/RoboSanta/SpeechQueue` (configurable via `SpeechQueueConfiguration`).
- **Structure**: Timestamp-named folders (`YYYYMMDDHHMMSS`) containing `start.wav`, optional `middleN.wav` files, and `end.wav`.
- **Lifecycle**:
  - Generation writes a new timestamp folder.
  - `consumeOldest()` renames the folder to `.inprogress` to avoid reuse.
  - Completion moves the folder to `DONE/<id>` (suffix removed).
  - Startup cleanup restores or removes orphaned `.inprogress` folders.
- **Logging**: Queue scans log count changes; consume/complete/release/discard/cleanup are logged.

---

## Interaction Flow (InteractionCoordinator)
- **States**: `idle` (minimal idle, queue empty), `patrolling` (queue has content), `personDetected`, `greeting`, `conversing`, `farewell`, `personLost`.
- **Engagement rules**:
  - Pre-greeting: requires detection for a minimum duration; face angle not required.
  - Post-greeting: continues only if the person is present and roughly looking (lenient yaw tolerance, default 25°) or recently looked.
  - Middle phrases: finish the current phrase even if the person is lost; skip remaining phrases if no recent look or loss flagged.
  - Farewell: played if person is present or recently lost; otherwise skipped.
- **Detection handling**: Subscribes to `StateMachine.detectionPublisher`; tracks yaw and “recent look” timestamps with lenient tolerance.
- **Queue coupling**: When queue empties, switch to minimal idle; when queue has content, switch to patrol. State transitions are logged with reasons.
- **Loss during speech**: If lost mid-phrase, mark a pending stop and finish the phrase before bailing.

---

## StateMachine Behaviour Highlights
- **Contexts**: `tracking`, `search` (idle), `manual`.
- **Idle modes**:
  - **Patrol**: Sweeps between extremes with jitter and rate limits.
  - **Minimal idle**: Anchors to the current heading when entered; then gently drifts toward center with head/body sway (livelier defaults) and subtle occasional hand wiggles (±0.05 range, 1–3s pauses) when hands are down.
- **Detection publishing**: Emits `DetectionUpdate` (personDetected, relativeOffset, faceYaw, timestamp, trackingDuration) on visibility changes.
- **Left-hand autopilot**: Arms on detection (except when in minimal idle). Waving uses configured speeds, cycles, and cooldowns; cooldown is suppressed while queue is empty/minimal idle.
- **Loss handling**: On person lost, clears focus, starts hand cooldown if needed, shortens patrol pause before resuming sweep.
- **Stall guards**: Head/body stall guards thaw when commanded back toward center and reset on context changes.

---

## Audio & Conversation Playback
- **AudioPlayer**: Async AVAudioPlayer wrapper with states (idle/playing/completed/interrupted), `play`, `stop`, `waitForCompletion`, and volume support.
- **Playback flow**:
  - Greeting: play `start.wav`; if not attentive after greeting, go directly to farewell.
  - Middle phrases: each preceded by an engagement check; complete the current phrase before stopping on loss.
  - Farewell: played when appropriate; skipped if the person has been gone beyond the farewell skip window.
- **Logging**: State transitions, post-greeting engagement details, mid-phrase skips, loss deferrals, and queue moves are logged.

---

## Speech Generation (SantaSpeaker)
- **Loop**: Scans queue; pauses when at max; generates when below min.
- **Set types**: Pepp talk (start+end), greeting (start+middle+end), quiz (start+multiple middles+end), joke (start+middles+end). Prompts remain Swedish.
- **TTS**: Posts to local TTS server, downloads WAVs, saves into the set folder. Cleans up failed generations.
- **Logging**: Set preparation, interaction type, success/failure, and refreshed queue size.

---

## Configuration Defaults (key ones)
- **Queue**: max 500, min 5, generation throttle 0s (continuous), DONE retention 50.
- **Engagement**: yaw tolerance 5° (strict), post-greeting tolerance 35° (lenient), detection duration 1s, farewell skip threshold 3s, look-away timeout 2s, post-conversation cooldown 4s.
- **Motion**: head rate cap 250 deg/s, body rate cap 50 deg/s, patrol pause after loss 1.0-2.0s range, minimal idle sway ~6° amplitude, period ~7s, body not locked.
- **Gestures**: left-hand wave cycles 2, wave speed 500, raise 200, lower 120, pause at top 0.75s, min cooldown 4s (tunable).

---

## Operational Notes
- **Queue hygiene**: Empty queue = minimal idle; `.inprogress` folders are for in-use sets only. Orphan cleanup runs on startup.
- **Detection always on**: Face detection and yaw continue in all states; minimal idle ignores tracking for motion but keeps publishing for coordinator decisions.
- **Logging**: Console logs cover queue counts, state transitions, patrol/idle commands, engagement decisions, phrase skips, and TTS generation.
- **No hardware tweaks in Phidget22**: All motion tuning lives in `StateMachine` and `StateMachineSettings`.

---

## Troubleshooting Pointers
- **No playback**: Check queue has sets; ensure engagement after greeting (lenient yaw tolerance and “recent look” log lines). Verify TTS server running.
- **Keeps waving in idle**: Minimal idle blocks left-hand autopilot arming; ensure queue is empty and minimal idle is active.
- **Abrupt snaps on idle entry**: Minimal idle now anchors to the current heading and drifts; patrol state is only re-initialized when entering patrol.
- **Orphaned sets**: `.inprogress` folders are auto-restored on startup; DONE pruning runs in the background.

---

## Key Files (for future reference)
- `RoboSantaApp/SantaSpeaker.swift` – generation loop and TTS output.
- `RoboSantaApp/SpeechQueue/` – queue config, manager, conversation set validation.
- `RoboSantaApp/Coordination/InteractionCoordinator.swift` – interaction orchestration and engagement logic.
- `RoboSantaApp/Audio/AudioPlayer.swift` – WAV playback.
- `RoboSantaApp/Figurine/StateMachine.swift` & `StateMachineSettings.swift` – motion control, idle behaviours, detection publisher, autopilot.
- `RoboSantaApp/Detection/DetectionRouter.swift` – routes detection frames to StateMachine events.
- `App.swift` & `RuntimeCoordinator.swift` – startup wiring for interactive mode.
