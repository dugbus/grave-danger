extends "res://tests/test_case.gd"

const SESSION_OPTIONS := preload("res://game/codex_session_options.gd")


func run(_tree: SceneTree) -> void:
	_test_directed_test_options()
	_test_replay_log_options()
	_test_invalid_log_options()
	_test_feedback_window_options()


func _test_directed_test_options() -> void:
	var options := SESSION_OPTIONS.parse(PackedStringArray([
		"--codex-test",
		"Walk through the exit gate.",
		"--codex-level",
		"vampire_boss",
		"--codex-confirmed",
	]))
	expect(
		int(options.get("mode", SESSION_OPTIONS.SessionMode.Disabled)) \
			== SESSION_OPTIONS.SessionMode.DirectedTest \
			and String(options.get("instruction", "")) == "Walk through the exit gate." \
			and String(options.get("level", "")) == "vampire_boss" \
			and bool(options.get("confirmed", false)) \
			and String(options.get("report_button", "")) == "square" \
			and String(options.get("text_button", "")) == "disabled",
		"Directed tests preserve their instruction, level, confirmation, and safe buttons."
	)


func _test_replay_log_options() -> void:
	var options := SESSION_OPTIONS.parse(PackedStringArray([
		"--codex-replay",
		"--codex-level",
		"latest",
		"--codex-logs",
		"summary,position,buttons",
		"--codex-sample-seconds",
		"0.25",
	]))
	expect(
		int(options.get("mode", SESSION_OPTIONS.SessionMode.Disabled)) \
			== SESSION_OPTIONS.SessionMode.Replay \
			and is_equal_approx(float(options.get("sample_seconds", 0.0)), 0.25) \
			and SESSION_OPTIONS.has_log_channel(
				options,
				SESSION_OPTIONS.LogChannel.Position
			) \
			and not SESSION_OPTIONS.has_log_channel(
				options,
				SESSION_OPTIONS.LogChannel.Camera
			),
		"Replay options select only the requested logging channels."
	)


func _test_invalid_log_options() -> void:
	var options := SESSION_OPTIONS.parse(PackedStringArray([
		"--codex-replay",
		"--codex-logs",
		"summary,omniscience",
	]))
	expect(
		not (options.get("errors", []) as Array).is_empty(),
		"Replay options reject unknown logging channels."
	)


func _test_feedback_window_options() -> void:
	var options := SESSION_OPTIONS.parse(PackedStringArray([
		"--codex-new-feedback",
		"--codex-logs",
		"feedback,position",
		"--codex-feedback-before",
		"1.5",
		"--codex-feedback-after",
		"2.5",
	]))
	expect(
		int(options.get("mode", SESSION_OPTIONS.SessionMode.Disabled)) \
			== SESSION_OPTIONS.SessionMode.Feedback \
			and SESSION_OPTIONS.has_log_channel(
				options,
				SESSION_OPTIONS.LogChannel.Feedback
			) \
			and is_equal_approx(
				float(options.get("feedback_before_seconds", 0.0)),
				1.5
			) \
			and is_equal_approx(
				float(options.get("feedback_after_seconds", 0.0)),
				2.5
			),
		"Feedback options retain their bounded diagnostic window."
	)
