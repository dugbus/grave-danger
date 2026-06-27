extends SceneTree


const LOCKED_PASSAGE_TESTS := preload("res://tests/test_locked_passages.gd")


func _initialize() -> void:
	_run.call_deferred()


func _run() -> void:
	var suite := LOCKED_PASSAGE_TESTS.new()
	root.add_child(suite)
	var failure_count: int = await suite.run()
	suite.queue_free()
	await process_frame
	await process_frame
	await process_frame

	if failure_count > 0:
		quit(1)
	else:
		quit()
