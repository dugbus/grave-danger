extends "res://tests/test_case.gd"

const EXPORT_PRESETS_PATH := "res://export_presets.cfg"
const TEST_EXCLUDE_FILTER := "tests/*,*_test.gd,screenshots/*"

enum TargetPreset {
	Web,
	MacosAppleSilicon,
	WindowsDesktop64,
	IosArm64,
}


func run(_tree: SceneTree) -> void:
	var presets := ConfigFile.new()
	expect_equal(
		presets.load(EXPORT_PRESETS_PATH),
		OK,
		"The shared export preset configuration loads."
	)
	_expect_macos_preset(presets)
	_expect_windows_preset(presets)
	_expect_ios_preset(presets)


func _expect_macos_preset(presets: ConfigFile) -> void:
	var section := _preset_section(TargetPreset.MacosAppleSilicon)
	expect_equal(
		presets.get_value("runnable_presets", "macOS", ""),
		"macOS Apple Silicon",
		"The Apple Silicon preset is the runnable macOS target."
	)
	expect_equal(
		presets.get_value(section, "name", ""),
		"macOS Apple Silicon",
		"The Apple Silicon build has a stable preset name."
	)
	expect_equal(
		presets.get_value("%s.options" % section, "binary_format/architecture", ""),
		"universal",
		"The macOS build uses Godot's Universal 2 template containing the ARM64 slice."
	)
	_expect_shared_native_settings(presets, section, "builds/GraveDanger-macOS.zip")


func _expect_windows_preset(presets: ConfigFile) -> void:
	var section := _preset_section(TargetPreset.WindowsDesktop64)
	expect_equal(
		presets.get_value("runnable_presets", "Windows Desktop", ""),
		"Windows x86_64",
		"The 64-bit preset is the runnable Windows target."
	)
	expect_equal(
		presets.get_value(section, "platform", ""),
		"Windows Desktop",
		"The Windows build targets Godot's desktop exporter."
	)
	expect_equal(
		presets.get_value("%s.options" % section, "binary_format/architecture", ""),
		"x86_64",
		"The Windows build targets 64-bit Intel and AMD processors."
	)
	_expect_shared_native_settings(
		presets,
		section,
		"builds/GraveDanger-Windows-x86_64.exe"
	)


func _expect_ios_preset(presets: ConfigFile) -> void:
	var section := _preset_section(TargetPreset.IosArm64)
	expect_equal(
		presets.get_value("runnable_presets", "iOS", ""),
		"iOS ARM64",
		"The ARM64 preset is the runnable iOS target."
	)
	expect_equal(
		presets.get_value(section, "platform", ""),
		"iOS",
		"The mobile build targets Godot's iOS exporter."
	)
	expect_equal(
		presets.get_value("%s.options" % section, "architectures/arm64", false),
		true,
		"The iOS build enables the required ARM64 architecture."
	)
	expect(
		not String(
			presets.get_value(
				"%s.options" % section,
				"application/bundle_identifier",
				""
			)
		).is_empty(),
		"The iOS build has a valid-form bundle identifier ready for local signing."
	)
	_expect_shared_native_settings(presets, section, "builds/GraveDanger-iOS.zip")


func _expect_shared_native_settings(
	presets: ConfigFile,
	section: String,
	expected_path: String
) -> void:
	expect_equal(
		presets.get_value(section, "exclude_filter", ""),
		TEST_EXCLUDE_FILTER,
		"Test scripts and resolution screenshots are excluded from the native build."
	)
	expect_equal(
		presets.get_value(section, "export_path", ""),
		expected_path,
		"The native preset has a repository-local ignored build destination."
	)


func _preset_section(preset: TargetPreset) -> String:
	return "preset.%d" % preset
