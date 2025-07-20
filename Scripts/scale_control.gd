extends OptionButton


func _on_item_selected(index: int) -> void:
	var options = [100, 75, 50, 25]
	var value = options[index]
	print(options[index])
	get_tree().root.scaling_3d_scale = value
