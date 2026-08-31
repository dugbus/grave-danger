extends "res://tests/test_case.gd"

const SUBJECT := preload("res://placeables/kill-boundary-2/kill_boundary_2_damage.gd")
const SUBJECT_PATH := "res://placeables/kill-boundary-2/kill_boundary_2_damage.gd"


class VulnerableBody:
	extends Node3D
	var last_amount := 0.0
	var fire_death := false

	func apply_kill_boundary_damage(amount: float, causes_fire_death: bool) -> void:
		last_amount = amount
		fire_death = causes_fire_death


func run(_tree: SceneTree) -> void:
	expect_script_contract(SUBJECT, SUBJECT_PATH)
	var damage := GDKillBoundary2Damage.new()
	var body := VulnerableBody.new()
	damage.render_effect = GDKillBoundary2Settings.RenderEffect.Ghost
	damage._apply_damage_to_body(body, 5.0)
	expect(
		is_equal_approx(body.last_amount, 5.0) and not body.fire_death,
		"Ghost boundaries apply non-fire kill-boundary damage."
	)
	damage.render_effect = GDKillBoundary2Settings.RenderEffect.None
	damage._apply_damage_to_body(body, 3.0)
	expect(not body.fire_death, "Invisible boundaries retain lethal non-fire damage.")
	damage.render_effect = GDKillBoundary2Settings.RenderEffect.Flame
	damage._apply_damage_to_body(body, 7.0)
	expect(
		is_equal_approx(body.last_amount, 7.0) and body.fire_death,
		"Flame boundaries alone request a flame-style death."
	)
	var settings := GDKillBoundary2Settings.new()
	var geometry := GDKillBoundary2Geometry.new()
	damage.configure(settings, geometry)
	var first_shape := damage.segments[0].get_node(^"CollisionShape3D") as CollisionShape3D
	var second_shape := damage.segments[1].get_node(^"CollisionShape3D") as CollisionShape3D
	expect(
		first_shape.shape != second_shape.shape,
		"Each lethal segment owns its independently resizable collision shape."
	)
	body.free()
	damage.free()
	geometry.free()
