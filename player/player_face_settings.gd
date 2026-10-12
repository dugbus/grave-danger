class_name GDPlayerFaceSettings
extends Resource

## Mouth blood source measured from the head bone in forward-facing rest coordinates.
@export var mouth_offset := Vector3(0.0, 0.055, 0.19)
## Nose blood source measured from the head bone in forward-facing rest coordinates.
@export var nose_offset := Vector3(0.0, 0.1, 0.192)
## Left-eye blood source measured from the head bone in forward-facing rest coordinates.
@export var left_eye_offset := Vector3(0.065, 0.14, 0.185)
## Right-eye blood source measured from the head bone in forward-facing rest coordinates.
@export var right_eye_offset := Vector3(-0.065, 0.14, 0.185)
## Centre of the persistent blood mark on the face, independent of the spray sources.
@export var splatter_offset := Vector3(-0.07, 0.11, 0.18)
## Width of the persistent facial blood mark in metres.
@export_range(0.05, 2.0, 0.01, "suffix:m") var splatter_diameter := 0.26
