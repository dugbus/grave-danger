class_name GDPlayerFeedbackSettings
extends Resource

## Shared controller configuration for player-authored Codex feedback markers.

enum FeedbackButton {
    Disabled = -1,
    FaceBottom = JOY_BUTTON_A,
    FaceRight = JOY_BUTTON_B,
    FaceLeft = JOY_BUTTON_X,
    FaceTop = JOY_BUTTON_Y,
}

## Controller button that pauses play and opens feedback for the current moment.
@export var report_button := FeedbackButton.FaceLeft
## Optional controller shortcut that reopens the newest feedback note.
@export var text_button := FeedbackButton.Disabled
## Minimum time between accepted presses of the same feedback button.
@export_range(0.1, 2.0, 0.05) var debounce_seconds := 0.5
## Maximum number of characters retained in one written feedback marker.
@export_range(20, 500, 1) var maximum_note_characters := 200
## Time after a report marker in which an enabled text shortcut can reopen the note field.
@export_range(1.0, 10.0, 0.5) var note_offer_seconds := 5.0
## Repository folder where unresolved feedback reports are written for commits.
@export_dir var repository_report_directory := "res://feedback/reports"
## Repository folder retaining recently resolved reports until the size cap prunes them.
@export_dir var repository_archive_directory := "res://feedback/archive"
## Maximum active and archived feedback reports retained in the working repository.
@export_range(1, 100, 1) var maximum_repository_reports := 20
## Maximum combined playback storage retained in the working repository, in MiB.
@export_range(1.0, 100.0, 1.0) var maximum_repository_mebibytes := 25.0
## Maximum size of a single committed playback before it is omitted, in MiB.
@export_range(1.0, 25.0, 1.0) var maximum_playback_mebibytes := 5.0


static func get_button_from_name(
    button_name: String,
    fallback: FeedbackButton
) -> FeedbackButton:
    match button_name.strip_edges().to_lower():
        "cross", "a", "bottom":
            return FeedbackButton.FaceBottom
        "circle", "b", "right":
            return FeedbackButton.FaceRight
        "square", "x", "left":
            return FeedbackButton.FaceLeft
        "triangle", "y", "top":
            return FeedbackButton.FaceTop
        "disabled", "none":
            return FeedbackButton.Disabled
        _:
            return fallback
