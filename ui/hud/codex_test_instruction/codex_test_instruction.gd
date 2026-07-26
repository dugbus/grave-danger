class_name GDCodexTestInstruction
extends CanvasLayer

## Presents an explicit Codex-directed playtest request without affecting ordinary runs.

@onready var instruction_label := get_node(
    ^"Layout/InstructionPanel/Margin/Content/Instruction"
) as Label


func _ready() -> void:
    visible = false


func show_instruction(instruction: String) -> void:
    var concise_instruction := instruction.strip_edges()
    if concise_instruction.is_empty():
        visible = false
        return
    instruction_label.text = concise_instruction
    visible = true

