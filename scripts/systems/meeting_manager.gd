extends Node
## Owns Hall of Witness meeting state and the canned-speech pool (M5).
## Autoloaded as MeetingManager. Mirrors TerritoryManager's shape: pending-
## state setter/getter, defensive resource cache, weighted picker with
## last-played exclusion, and per-resolution effect firing.
##
## Two slug taxonomies flow through this manager:
##   - "meeting type" — the week-day-level slug routed from week_view to
##     meeting_hall. &"sunday_meeting" runs PT + LS back-to-back;
##     &"tuesday_meeting" runs Midweek alone.
##   - "talk type" — the individual-speech-level slug used for the speech
##     pool, speaker mapping, and effect deltas. &"public_talk",
##     &"lighthouse_study", &"midweek_training".
##
## Per M5 Phase 1 decisions:
##  - D: Speaker is a separate resource type (not a Householder rebrand)
##  - A: per-talk resolve within the same meeting_hall scene
##  - C: Conviction + Standing-Elders fire per-talk; Energy fires once on
##       meeting complete-or-skip
##  - E: skip fires inline on click
##  - F: last-played state is a Dictionary[StringName, StringName] here
##  - G: this autoload owns the state, not PlayerState

const SPEAKER_PATHS: Dictionary = {
	&"elder_coordinator": "res://data/speakers/elder_coordinator.tres",
	&"elder_strict":      "res://data/speakers/elder_strict.tres",
}

const FALLBACK_SPEAKER: StringName = &"elder_coordinator"

# Talk type → speaker slug. Coordinator delivers Public Talk + Midweek;
# Strict Elder delivers Lighthouse Study (Phase 1.5 Q5 lock).
const TALK_TYPE_TO_SPEAKER: Dictionary = {
	&"public_talk":      &"elder_coordinator",
	&"lighthouse_study": &"elder_strict",
	&"midweek_training": &"elder_coordinator",
}

# Speech pool per talk type — M5.3 expanded each pool to 3 speeches authored
# by the dialogue subagent. Slugs match .dtl basenames; full paths derived
# via get_speech_path below. pick_speech_for applies last-played exclusion
# so consecutive same-type meetings don't repeat verbatim.
const TALK_TYPE_TO_SPEECH_POOL: Dictionary = {
	&"public_talk":      [&"coordinator_pt_v1", &"coordinator_pt_v2", &"coordinator_pt_v3"],
	&"lighthouse_study": [&"strict_ls_v1",      &"strict_ls_v2",      &"strict_ls_v3"],
	&"midweek_training": [&"coordinator_mw_v1", &"coordinator_mw_v2", &"coordinator_mw_v3"],
}

# Per-talk effects fired on talk_completed (Phase 1.5 Q6).
const TALK_EFFECTS: Dictionary = {
	&"public_talk":      {"conviction": 2, "standing_elders": 1},
	&"lighthouse_study": {"conviction": 1, "standing_elders": 1},
	&"midweek_training": {"conviction": 2, "standing_elders": 2},
}

# Meeting type → ordered list of talk types it contains. meeting_hall.gd
# iterates this to run talks in sequence (per Decision A).
const MEETING_TYPE_TO_TALKS: Dictionary = {
	&"sunday_meeting":  [&"public_talk", &"lighthouse_study"],
	&"tuesday_meeting": [&"midweek_training"],
}

# Songs sung between talks. v1 ships one placeholder original; CLAUDE.md
# legal guardrails forbid lifting real Kingdom Melodies. Future work expands
# the pool and can promote Song to a Resource type — see docs/BACKLOG.md.
const SONGS: Dictionary = {
	&"song_47_placeholder": {
		"number": 47,
		"title": "Faithful in the Hall",
		"opening_lines": "Brothers gather, sisters meet,\nSongbooks open at our seat.\nThrough the days that close us in,\nFaithful still, we sing again.",
	},
}

# Talk type → song slug that plays just before the talk. Sunday's cadence is
# PT → song → LS, matching the real Sunday-meeting flow. Absent key means
# no song before that talk.
const SONGS_BEFORE_TALK: Dictionary = {
	&"lighthouse_study": &"song_47_placeholder",
}

const MEETING_DAY_ENERGY_COST: int = 1
const SKIP_DOUBT_DELTA: int = 1
const SKIP_STANDING_DELTA: int = -2

# 6 seats with one pinned neighbor identity each (Phase 1 proposed default).
# Neighbor slugs feed SOCIAL_MOMENT_OPTIONS below so the social moment varies
# with seat choice.
const SEAT_NEIGHBORS: Dictionary = {
	&"front_left":   &"service_partner",
	&"front_right":  &"sister_who_talks",
	&"middle_left":  &"strict_elder_wife",
	&"middle_right": &"lonely_elderly",
	&"back_left":    &"parent_in_truth",
	&"back_right":   &"sit_alone",
}

# Per-neighbor social moment: prompt text + 2 short choices. Each choice
# carries a Standing delta (Phase 1 default ±1) into one of three standing
# tracks. Placeholder copy authored inline; M5.3 / M5.4 dialogue subagent
# passes rewrite to authentic voice per cast.md.
const SOCIAL_MOMENT_OPTIONS: Dictionary = {
	&"service_partner": {
		"prompt": "Your service partner slides over to make room. \"Saved you a spot. Long week, huh?\"",
		"choices": [
			{"label": "\"Yeah. Glad to be here.\"", "standing_type": &"congregation", "standing_delta": 1},
			{"label": "Half-smile and reach for the songbook.", "standing_type": &"congregation", "standing_delta": 0},
		],
	},
	&"sister_who_talks": {
		"prompt": "She leans in before you've even set your bag down. \"Oh — I just want to say, did you hear about Brother Phillips? Such a sweet brother, but —\"",
		"choices": [
			{"label": "\"What's going on with him?\"", "standing_type": &"congregation", "standing_delta": 1},
			{"label": "\"Maybe after the meeting, sister.\"", "standing_type": &"congregation", "standing_delta": 0},
		],
	},
	&"strict_elder_wife": {
		"prompt": "The Strict Elder's wife sits straight-backed in the seat beside you, songbook already open. She doesn't turn her head.",
		"choices": [
			{"label": "\"Good morning, Sister Whitcomb.\"", "standing_type": &"elders", "standing_delta": 1},
			{"label": "Open your own songbook and let her be.", "standing_type": &"elders", "standing_delta": 0},
		],
	},
	&"lonely_elderly": {
		"prompt": "The elderly sister beside you is thumbing through her songbook, lost. \"Now what number was it again, dear?\"",
		"choices": [
			{"label": "\"Song 47 — here, let me show you.\"", "standing_type": &"congregation", "standing_delta": 1},
			{"label": "Smile, find your own page.", "standing_type": &"congregation", "standing_delta": 0},
		],
	},
	&"parent_in_truth": {
		"prompt": "Your parent in the Truth catches your eye from down the row. They mouth \"we love you\" and tap the seat between them — but it's already taken.",
		"choices": [
			{"label": "Smile back and mouth \"love you too.\"", "standing_type": &"family", "standing_delta": 1},
			{"label": "Nod once and face the platform.", "standing_type": &"family", "standing_delta": 0},
		],
	},
	&"sit_alone": {
		"prompt": "The back row is mostly empty. You can hear the air handler running, and someone's cough two rows up.",
		"choices": [
			{"label": "Settle in. Breathe.", "standing_type": &"congregation", "standing_delta": 0},
			{"label": "Glance forward — see who came.", "standing_type": &"congregation", "standing_delta": 0},
		],
	},
}

const _MEETING_DTL_DIR: String = "res://data/dialogues/meetings/"

var pending_meeting_type: StringName = &""
var _speaker_cache: Dictionary = {}
var _last_played_per_type: Dictionary = {}


func _ready() -> void:
	_speaker_cache = _load_speaker_cache()


# --- Pending-meeting handoff (mirrors TerritoryManager pending pattern) ---

func set_pending_meeting(meeting_type: StringName) -> void:
	pending_meeting_type = meeting_type


func get_pending_meeting() -> StringName:
	return pending_meeting_type


func clear_pending_meeting() -> void:
	pending_meeting_type = &""


# --- Speech pool picker ------------------------------------------------------

func pick_speech_for(talk_type: StringName) -> StringName:
	# Weighted-pool pick with last-played exclusion. v1 pools have only 1
	# entry each, so exclusion is a no-op until M5.3 expands the pool — but
	# the mechanism is wired now so the M5.3 swap is content-only.
	var pool: Array = TALK_TYPE_TO_SPEECH_POOL.get(talk_type, [])
	if pool.is_empty():
		push_warning("[MeetingManager] No speech pool for talk type %s" % talk_type)
		return &""
	var last: StringName = _last_played_per_type.get(talk_type, &"")
	var candidates: Array = pool.duplicate()
	if pool.size() > 1 and last != &"":
		candidates.erase(last)
	var pick: StringName = candidates[randi() % candidates.size()]
	_last_played_per_type[talk_type] = pick
	return pick


func get_speech_path(speech_slug: StringName) -> String:
	return "%s%s.dtl" % [_MEETING_DTL_DIR, speech_slug]


# --- Speaker resolution ------------------------------------------------------

func get_speaker_for(talk_type: StringName) -> Speaker:
	var speaker_slug: StringName = TALK_TYPE_TO_SPEAKER.get(talk_type, FALLBACK_SPEAKER)
	return _speaker_cache.get(speaker_slug, _speaker_cache.get(FALLBACK_SPEAKER))


func _load_speaker_cache() -> Dictionary:
	var cache: Dictionary = {}
	for slug in SPEAKER_PATHS:
		var path: String = SPEAKER_PATHS[slug]
		if not ResourceLoader.exists(path):
			push_warning("[MeetingManager] Speaker .tres missing at %s; slug %s will fall back." % [path, slug])
			continue
		var resource: Resource = load(path)
		if resource == null:
			push_warning("[MeetingManager] Speaker .tres at %s failed to load; slug %s will fall back." % [path, slug])
			continue
		cache[slug] = resource
	if not cache.has(FALLBACK_SPEAKER):
		# Last-ditch: build a minimal in-code Speaker so meeting_hall renders
		# something rather than crashing on missing-resource access.
		var minimal: Speaker = Speaker.new()
		minimal.id = FALLBACK_SPEAKER
		minimal.display_name = "Elder"
		minimal.character_name = "Coordinator of Elders"
		minimal.voice_profile_ref = "§ 4.1"
		cache[FALLBACK_SPEAKER] = minimal
	return cache


# --- Resolution: per-talk + per-meeting effects ------------------------------

func resolve_talk_completed(talk_type: StringName, speech_slug: StringName) -> void:
	# Per Decision C: Conviction + Standing-Elders fire per-talk (about what
	# was said). Energy fires once at meeting-complete in
	# resolve_meeting_completed below.
	var effects: Dictionary = TALK_EFFECTS.get(talk_type, {})
	var conviction_delta: int = int(effects.get("conviction", 0))
	var standing_delta: int = int(effects.get("standing_elders", 0))
	if conviction_delta != 0:
		ResourceManager.add_conviction(conviction_delta)
	if standing_delta != 0:
		ResourceManager.add_standing_elders(standing_delta)
	SignalBus.talk_completed.emit(talk_type, speech_slug)


func resolve_meeting_completed(meeting_type: StringName) -> void:
	# Per-meeting Energy cost. Sunday's two talks share one Energy hit
	# (Phase 1.5 Q6). Note: ResourceManager._on_day_advanced refills Energy
	# to max on every phase change, so this -1 only persists during the
	# meeting-day phase — known v1 limitation per the plan.
	if MEETING_DAY_ENERGY_COST != 0:
		ResourceManager.add_energy(-MEETING_DAY_ENERGY_COST)
	SignalBus.meeting_attended.emit(meeting_type)
	clear_pending_meeting()


func resolve_meeting_skipped(meeting_type: StringName) -> void:
	# Per Decision E: skip fires inline on click. Standing-Elders penalty +
	# doubt nudge. No Conviction change (Phase 1.5 Q7 — Conviction reflects
	# faith, not behavior).
	if SKIP_STANDING_DELTA != 0:
		ResourceManager.add_standing_elders(SKIP_STANDING_DELTA)
	if SKIP_DOUBT_DELTA != 0:
		DoubtMeter.apply(SKIP_DOUBT_DELTA, &"meeting_skipped")
	SignalBus.meeting_skipped.emit(meeting_type)
	clear_pending_meeting()


# --- Helpers used by week_view + meeting_hall --------------------------------

func meeting_type_for_phase(phase: int) -> StringName:
	if phase == TimeManager.Phase.SUNDAY:
		return &"sunday_meeting"
	if phase == TimeManager.Phase.TUESDAY:
		return &"tuesday_meeting"
	return &""


func talks_for_meeting(meeting_type: StringName) -> Array:
	return MEETING_TYPE_TO_TALKS.get(meeting_type, [])


func song_before_talk(talk_type: StringName) -> StringName:
	return SONGS_BEFORE_TALK.get(talk_type, &"")


func get_song(song_slug: StringName) -> Dictionary:
	return SONGS.get(song_slug, {})


func is_meeting_day(phase: int) -> bool:
	return phase == TimeManager.Phase.SUNDAY or phase == TimeManager.Phase.TUESDAY
