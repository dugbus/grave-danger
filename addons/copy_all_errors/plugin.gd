@tool
extends EditorPlugin

## Adds a Copy All button to the debugger Errors panel.
## Pressing it formats all errors and warnings and copies them to the system clipboard.

var _copy_button: Button = null
var _error_tree: Tree = null
var _hbox: HBoxContainer = null
var _setup_timer: Timer = null
var _retry_count := 0
const _MAX_RETRIES := 20


func _enter_tree() -> void:
	# The editor UI may not be ready yet, so delay the lookup with a timer.
	_setup_timer = Timer.new()
	_setup_timer.wait_time = 0.5
	_setup_timer.one_shot = true
	_setup_timer.timeout.connect(_try_setup)
	add_child(_setup_timer)
	_setup_timer.start()


func _exit_tree() -> void:
	if is_instance_valid(_copy_button):
		_copy_button.queue_free()
	_copy_button = null
	_error_tree = null
	_hbox = null
	_cleanup_timer()


# ------------------ Setup ------------------


func _try_setup() -> void:
	var base := EditorInterface.get_base_control()
	if not base:
		_schedule_retry()
		return

	var result := _find_error_panel(base)
	if result.is_empty():
		_schedule_retry()
		return

	_error_tree = result["tree"]
	_hbox = result["hbox"]
	_inject_copy_button()
	_cleanup_timer()


func _schedule_retry() -> void:
	_retry_count += 1
	if _retry_count < _MAX_RETRIES and is_instance_valid(_setup_timer):
		_setup_timer.start()
	else:
		push_warning("[CopyAllErrors] Could not find the debugger Errors panel. Plugin setup failed.")
		_cleanup_timer()


func _cleanup_timer() -> void:
	if is_instance_valid(_setup_timer):
		_setup_timer.queue_free()
		_setup_timer = null


# ------------------ Find Errors Panel ------------------


func _find_error_panel(node: Node) -> Dictionary:
	# Expected structure, from Godot's script_editor_debugger.cpp:
	# VBoxContainer ("Errors" / localized equivalent)
	#   - HBoxContainer
	#     - Button ("Expand All" / localized equivalent)
	#     - Button ("Collapse All" / localized equivalent)
	#     - Control (spacer)
	#     - Button ("Clear" / localized equivalent)
	#   - Tree (error_tree, 2 columns)
	if node is VBoxContainer:
		var tree: Tree = null
		var hbox: HBoxContainer = null
		var has_expand_btn := false

		for child in node.get_children():
			if child is HBoxContainer and not has_expand_btn:
				for btn in child.get_children():
					if btn is Button and btn.text in ["Expand All", "全部展开"]:
						has_expand_btn = true
						hbox = child
						break
			elif child is Tree and tree == null:
				tree = child

		if has_expand_btn and tree != null and hbox != null:
			return {"tree": tree, "hbox": hbox}

	for child in node.get_children():
		var result := _find_error_panel(child)
		if not result.is_empty():
			return result
	return {}


# ------------------ Inject Button ------------------


func _inject_copy_button() -> void:
	_copy_button = Button.new()
	_copy_button.text = "Copy All"
	_copy_button.tooltip_text = "Copy all errors and warnings to the clipboard"
	_copy_button.pressed.connect(_on_copy_all_pressed)

	# Prefer an existing editor copy icon when one is available.
	var theme := EditorInterface.get_editor_theme()
	if theme:
		for icon_name in ["ActionCopy", "CopyNodePath", "Duplicate"]:
			if theme.has_icon(icon_name, "EditorIcons"):
				_copy_button.icon = theme.get_icon(icon_name, "EditorIcons")
				break

	# Insert after the Collapse All button.
	var insert_idx := _hbox.get_child_count()
	for i in _hbox.get_child_count():
		var child := _hbox.get_child(i)
		if child is Button and child.text in ["Collapse All", "全部折叠"]:
			insert_idx = i + 1
			break

	_hbox.add_child(_copy_button)
	if insert_idx < _hbox.get_child_count():
		_hbox.move_child(_copy_button, insert_idx)

	print("[CopyAllErrors] Plugin ready. Copy All button added to the Errors panel.")


# ------------------ Copy Logic ------------------


func _on_copy_all_pressed() -> void:
	if not is_instance_valid(_error_tree):
		push_warning("[CopyAllErrors] Error list control is invalid.")
		return

	var root := _error_tree.get_root()
	if not root or not root.get_first_child():
		_flash_button("Nothing to copy")
		return

	var entries: PackedStringArray = []
	var count := 0
	var item := root.get_first_child()

	while item:
		entries.append(_format_error_item(item))
		count += 1
		item = item.get_next()

	var output := "\n\n".join(entries).strip_edges()
	DisplayServer.clipboard_set(output)
	print("[CopyAllErrors] Copied %d messages to the clipboard." % count)
	_flash_button("Copied %d!" % count)


func _flash_button(msg: String) -> void:
	if not is_instance_valid(_copy_button):
		return
	var original_text := _copy_button.text
	_copy_button.text = msg
	get_tree().create_timer(1.5).timeout.connect(func():
		if is_instance_valid(_copy_button):
			_copy_button.text = original_text
	)


# ------------------ Formatting ------------------


func _format_error_item(item: TreeItem) -> String:
	var parts: PackedStringArray = []

	# Message type: W = warning, E = error.
	var type_char := _get_type_char(item)

	# Main line: "W 0:00:01:633   GDScript::reload: ..."
	var time_str: String = item.get_text(0).strip_edges()
	var msg_str: String = item.get_text(1).strip_edges()
	parts.append("%s %s   %s" % [type_char, time_str, msg_str])

	# Detail lines, such as "  <GDScript Error> UNUSED_VARIABLE".
	var child := item.get_first_child()
	while child:
		var c0: String = child.get_text(0).strip_edges()
		var c1: String = child.get_text(1).strip_edges()
		if c0 or c1:
			var line := "  "
			if c0 and c1:
				line += c0 + " " + c1
			elif c0:
				line += c0
			else:
				line += c1
			parts.append(line)
		child = child.get_next()

	return "\n".join(parts)


func _get_type_char(item: TreeItem) -> String:
	# Prefer TreeItem metadata when available. Godot stores values such as
	# "warning", "error", and "cycled_error" here.
	var meta = item.get_metadata(0)
	if meta is String:
		if meta == "warning":
			return "W"
		if meta in ["error", "cycled_error"]:
			return "E"

	# If metadata is unavailable, infer the type from child text.
	var child := item.get_first_child()
	while child:
		var combined := (child.get_text(0) + " " + child.get_text(1)).to_upper()
		if "WARNING" in combined or "WARN" in combined:
			return "W"
		child = child.get_next()

	# Conservative fallback: warning.
	return "W"
