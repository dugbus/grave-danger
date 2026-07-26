class_name GDCodexSessionOptions
extends RefCounted

## Parses the command-line contract shared by directed playtests and replay inspection.

enum SessionMode {
    Disabled,
    DirectedTest,
    Replay,
    ListRecordings,
    Feedback,
}

enum LogChannel {
    Summary,
    Metadata,
    Feedback,
    Position,
    Input,
    Camera,
    Buttons,
    Drift,
}

const DEFAULT_LOG_CHANNELS: Array[LogChannel] = [
    LogChannel.Summary,
    LogChannel.Metadata,
    LogChannel.Feedback,
    LogChannel.Position,
    LogChannel.Input,
    LogChannel.Buttons,
]
const ALL_LOG_CHANNELS: Array[LogChannel] = [
    LogChannel.Summary,
    LogChannel.Metadata,
    LogChannel.Feedback,
    LogChannel.Position,
    LogChannel.Input,
    LogChannel.Camera,
    LogChannel.Buttons,
    LogChannel.Drift,
]
const LOG_CHANNEL_NAMES: Dictionary = {
    LogChannel.Summary: "summary",
    LogChannel.Metadata: "metadata",
    LogChannel.Feedback: "feedback",
    LogChannel.Position: "position",
    LogChannel.Input: "input",
    LogChannel.Camera: "camera",
    LogChannel.Buttons: "buttons",
    LogChannel.Drift: "drift",
}
const DEFAULT_SAMPLE_SECONDS := 0.5
const DEFAULT_PLAYBACK_SPEED := 1.0
const DEFAULT_FEEDBACK_BEFORE_SECONDS := 2.0
const DEFAULT_FEEDBACK_AFTER_SECONDS := 3.0


static func parse(arguments: PackedStringArray) -> Dictionary:
    var options := {
        "mode": SessionMode.Disabled,
        "instruction": "",
        "level": "",
        "log_channels": DEFAULT_LOG_CHANNELS.duplicate(),
        "log_file": "",
        "sample_seconds": DEFAULT_SAMPLE_SECONDS,
        "playback_speed": DEFAULT_PLAYBACK_SPEED,
        "feedback_before_seconds": DEFAULT_FEEDBACK_BEFORE_SECONDS,
        "feedback_after_seconds": DEFAULT_FEEDBACK_AFTER_SECONDS,
        "feedback_report": "latest",
        "report_button": "square",
        "text_button": "disabled",
        "visual": false,
        "confirmed": false,
        "help": false,
        "errors": [] as Array[String],
    }
    var index := 0
    while index < arguments.size():
        var argument := arguments[index]
        if argument == "--codex-replay":
            options["mode"] = SessionMode.Replay
        elif argument == "--codex-list-recordings":
            options["mode"] = SessionMode.ListRecordings
        elif argument == "--codex-new-feedback":
            options["mode"] = SessionMode.Feedback
        elif argument.begins_with("--codex-feedback-report="):
            options["feedback_report"] = argument.trim_prefix("--codex-feedback-report=")
        elif argument == "--codex-feedback-report":
            index = _read_next_value(arguments, index, "feedback_report", options)
        elif argument == "--codex-visual":
            options["visual"] = true
        elif argument == "--codex-confirmed":
            options["confirmed"] = true
        elif argument == "--codex-help":
            options["help"] = true
        elif argument.begins_with("--codex-test="):
            options["mode"] = SessionMode.DirectedTest
            options["instruction"] = argument.trim_prefix("--codex-test=")
        elif argument == "--codex-test":
            index = _read_next_value(arguments, index, "instruction", options)
            options["mode"] = SessionMode.DirectedTest
        elif argument.begins_with("--codex-level="):
            options["level"] = argument.trim_prefix("--codex-level=")
        elif argument == "--codex-level":
            index = _read_next_value(arguments, index, "level", options)
        elif argument.begins_with("--codex-report-button="):
            options["report_button"] = argument.trim_prefix("--codex-report-button=")
        elif argument == "--codex-report-button":
            index = _read_next_value(arguments, index, "report_button", options)
        elif argument.begins_with("--codex-text-button="):
            options["text_button"] = argument.trim_prefix("--codex-text-button=")
        elif argument == "--codex-text-button":
            index = _read_next_value(arguments, index, "text_button", options)
        elif argument.begins_with("--codex-logs="):
            _set_log_channels(argument.trim_prefix("--codex-logs="), options)
        elif argument == "--codex-logs":
            index = _read_log_channels(arguments, index, options)
        elif argument.begins_with("--codex-log-file="):
            options["log_file"] = argument.trim_prefix("--codex-log-file=")
        elif argument == "--codex-log-file":
            index = _read_next_value(arguments, index, "log_file", options)
        elif argument.begins_with("--codex-sample-seconds="):
            _set_positive_float(
                argument.trim_prefix("--codex-sample-seconds="),
                "sample_seconds",
                options
            )
        elif argument == "--codex-sample-seconds":
            index = _read_positive_float(arguments, index, "sample_seconds", options)
        elif argument.begins_with("--codex-speed="):
            _set_positive_float(
                argument.trim_prefix("--codex-speed="),
                "playback_speed",
                options
            )
        elif argument == "--codex-speed":
            index = _read_positive_float(arguments, index, "playback_speed", options)
        elif argument.begins_with("--codex-feedback-before="):
            _set_non_negative_float(
                argument.trim_prefix("--codex-feedback-before="),
                "feedback_before_seconds",
                options
            )
        elif argument == "--codex-feedback-before":
            index = _read_non_negative_float(
                arguments,
                index,
                "feedback_before_seconds",
                options
            )
        elif argument.begins_with("--codex-feedback-after="):
            _set_non_negative_float(
                argument.trim_prefix("--codex-feedback-after="),
                "feedback_after_seconds",
                options
            )
        elif argument == "--codex-feedback-after":
            index = _read_non_negative_float(
                arguments,
                index,
                "feedback_after_seconds",
                options
            )
        index += 1

    if int(options["mode"]) == SessionMode.DirectedTest \
            and String(options["instruction"]).strip_edges().is_empty():
        _get_errors(options).append("--codex-test requires a visible instruction.")
    return options


static func get_log_channel_name(channel: LogChannel) -> String:
    return String(LOG_CHANNEL_NAMES.get(channel, "unknown"))


static func has_log_channel(options: Dictionary, channel: LogChannel) -> bool:
    var channels := options.get("log_channels", []) as Array
    return channels.has(channel)


static func _read_next_value(
    arguments: PackedStringArray,
    index: int,
    key: String,
    options: Dictionary
) -> int:
    if index + 1 >= arguments.size():
        _get_errors(options).append("--codex-%s requires a value." % key.replace("_", "-"))
        return index
    options[key] = arguments[index + 1]
    return index + 1


static func _read_log_channels(
    arguments: PackedStringArray,
    index: int,
    options: Dictionary
) -> int:
    if index + 1 >= arguments.size():
        _get_errors(options).append("--codex-logs requires a comma-separated value.")
        return index
    _set_log_channels(arguments[index + 1], options)
    return index + 1


static func _set_log_channels(raw_channels: String, options: Dictionary) -> void:
    var normalized := raw_channels.strip_edges().to_lower()
    if normalized == "all":
        options["log_channels"] = ALL_LOG_CHANNELS.duplicate()
        return
    if normalized == "none":
        options["log_channels"] = [] as Array[LogChannel]
        return

    var channels: Array[LogChannel] = []
    for raw_name in normalized.split(",", false):
        var channel_name := raw_name.strip_edges()
        var matched := false
        for channel: LogChannel in ALL_LOG_CHANNELS:
            if get_log_channel_name(channel) != channel_name:
                continue
            if not channels.has(channel):
                channels.append(channel)
            matched = true
            break
        if not matched:
            _get_errors(options).append(
                "Unknown Codex replay log channel '%s'." % channel_name
            )
    options["log_channels"] = channels


static func _read_positive_float(
    arguments: PackedStringArray,
    index: int,
    key: String,
    options: Dictionary
) -> int:
    if index + 1 >= arguments.size():
        _get_errors(options).append("--codex-%s requires a value." % key.replace("_", "-"))
        return index
    _set_positive_float(arguments[index + 1], key, options)
    return index + 1


static func _set_positive_float(raw_value: String, key: String, options: Dictionary) -> void:
    if not raw_value.is_valid_float() or raw_value.to_float() <= 0.0:
        _get_errors(options).append(
            "--codex-%s must be greater than zero." % key.replace("_", "-")
        )
        return
    options[key] = raw_value.to_float()


static func _read_non_negative_float(
    arguments: PackedStringArray,
    index: int,
    key: String,
    options: Dictionary
) -> int:
    if index + 1 >= arguments.size():
        _get_errors(options).append("--codex-%s requires a value." % key.replace("_", "-"))
        return index
    _set_non_negative_float(arguments[index + 1], key, options)
    return index + 1


static func _set_non_negative_float(
    raw_value: String,
    key: String,
    options: Dictionary
) -> void:
    if not raw_value.is_valid_float() or raw_value.to_float() < 0.0:
        _get_errors(options).append(
            "--codex-%s must be zero or greater." % key.replace("_", "-")
        )
        return
    options[key] = raw_value.to_float()


static func _get_errors(options: Dictionary) -> Array[String]:
    return options.get("errors", []) as Array[String]
