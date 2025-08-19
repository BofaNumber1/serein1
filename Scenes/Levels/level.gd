extends Node3D

@onready var player_camera: Camera3D = $ThirdPersonCamera/CameraPivot/CameraArm/SpringArm3D/Camera3D
@onready var audio_player: AudioStreamPlayer = $AudioStreamPlayer
@onready var cutscene_camera: Camera3D = $Camera3D
@onready var cutscene_anim: AnimationPlayer = $Camera3D/AnimationPlayer
@onready var player_camera_root: Node3D = $ThirdPersonCamera

func _ready() -> void:
	# Disable player camera control
	player_camera_root.set_process(false)
	player_camera_root.set_process_input(false)

	# Activate cutscene camera
	cutscene_camera.make_current()
	cutscene_anim.play("camera intro")

	# Play audio + fade
	audio_player.volume_db = -15
	audio_player.play()

	var tween = create_tween()
	tween.tween_property(audio_player, "volume_db", -80.0, 3.0).set_delay(15.0)

	# Connect signal for when the cutscene ends
	cutscene_anim.animation_finished.connect(_on_cutscene_end)


func _on_cutscene_end(anim_name: StringName) -> void:
	if anim_name == "camera intro":
		# Re-enable player camera control
		player_camera_root.set_process(true)
		player_camera_root.set_process_input(true)

		# Switch back to player camera
		player_camera.make_current()
