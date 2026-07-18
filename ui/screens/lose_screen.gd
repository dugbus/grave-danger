class_name GDLoseScreen
extends GDResultScreen

## Compatibility script for callers that instantiate a loss result directly.


func _init() -> void:
	outcome = ResultOutcome.Lose
