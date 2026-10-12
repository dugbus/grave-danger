extends "res://tests/test_case.gd"

const SUBJECT := preload("res://player/player_gait_settings.gd")
const SETTINGS := preload("res://player/player_gait_settings.tres")


# Flow: Cadence tracks distance, remains partition independent, and uses wrapping contacts.
func run(_tree: SceneTree) -> void:
	expect_script_contract(SUBJECT, "res://player/player_gait_settings.gd")
	var settings := SUBJECT.new()
	expect_equal(settings.playback_speed(0.0, 0.1, 1.0, false), 0.0, "A blocked body cannot advance its walk.")
	expect_equal(settings.playback_speed(1.0, 0.0, 1.0, false), 0.0, "Zero-duration samples cannot divide by zero.")
	var normal := settings.playback_speed(0.25, 1.0, 1.0, false)
	var slow := settings.playback_speed(0.125, 1.0, 1.0, false)
	expect(is_equal_approx(normal, slow * 2.0), "Half the actual travel produces half the cadence.")
	expect(
		is_equal_approx(settings.playback_speed(0.25, 1.0, 2.0, false), normal * 2.0),
		"Clip length scales playback without changing stride distance."
	)
	expect(
		is_equal_approx(settings.playback_speed(0.025, 0.1, 1.0, false), normal),
		"Splitting travel into smaller frames preserves cadence."
	)
	expect(
		SETTINGS.is_contact(0.4, true) and not SETTINGS.is_contact(0.1, true),
		"Left stance and swing have separate contact states."
	)
	expect(
		SETTINGS.is_contact(0.95, false) and SETTINGS.is_contact(0.1, false),
		"Right stance continues across the clip loop."
	)
	expect(not SETTINGS.is_contact(0.5, false), "Right swing releases its contact.")

	var capped := settings.playback_speed(50.0, 0.1, 2.0, false)
	expect(
		is_equal_approx(capped, settings.maximum_cycles_per_second * 2.0),
		"Excess travel cannot spin the imported clip faster than the complete-cycle cap."
	)
	expect(
		is_equal_approx(settings.contact_scale(5.0), 0.2),
		"Original top speed compresses stance instead of reducing gameplay speed."
	)
	expect_equal(settings.contact_scale(0.25), 1.0, "Slow travel keeps the authored stance windows.")
	expect(
		settings.is_contact(0.4, true, 0.2) and not settings.is_contact(0.5, true, 0.2),
		"Fast movement keeps touchdown but lifts the foot earlier."
	)
	expect(
		settings.get_transfer_height(0.5, 0.2) > 0.0,
		"Compressed stance extends the airborne transfer instead of stretching a grounded leg."
	)
	var first_gap_midpoint := (settings.left_contact_end + settings.right_contact_start) * 0.5
	var second_gap_midpoint := (settings.right_contact_end + settings.left_contact_start) * 0.5
	expect(
		is_equal_approx(settings.get_transfer_height(first_gap_midpoint), settings.transfer_height),
		"Left push-off lifts the character between contacts."
	)
	expect(
		is_equal_approx(settings.get_transfer_height(second_gap_midpoint), settings.transfer_height),
		"Right push-off produces the same lift on the next alternating step."
	)
	for contact_phase in [
		settings.left_contact_start, settings.left_contact_end, settings.right_contact_start, settings.right_contact_end
	]:
		expect(
			absf(settings.get_transfer_height(contact_phase)) < 0.000001,
			"Push-off and landing endpoints have no vertical snap."
		)
	expect(
		settings.get_transfer_height(0.5) == 0.0 and settings.get_transfer_height(0.0) == 0.0,
		"Lift stays zero while either foot supports the body, including across the loop."
	)
	settings.transfer_height = 0.0
	expect_equal(
		settings.get_transfer_height(first_gap_midpoint),
		0.0,
		"Editors can disable the airborne transfer without changing cadence."
	)

	for scale in [1.0, 0.2]:
		var start := settings.left_contact_start
		var duration := (settings.left_contact_end - start) * (scale as float)
		expect_equal(
			settings.contact_weight(start, true, scale),
			0.0,
			"Foot planting starts without an instantaneous correction."
		)
		expect(
			is_equal_approx(settings.contact_weight(start + duration * 0.125, true, scale), 0.5),
			"Landing eases through partial influence even at full travel speed."
		)
		expect(
			is_equal_approx(settings.contact_weight(start + duration * 0.5, true, scale), 1.0),
			"The middle of each contact retains firm foot planting."
		)
		expect(
			settings.contact_weight(start + duration * 0.999, true, scale) < 0.001,
			"Lift-off smoothly releases the foot into authored motion."
		)
	expect(
		is_equal_approx(settings.contact_weight(0.02, false), 1.0),
		"Right-foot planting remains smooth across the clip loop."
	)
