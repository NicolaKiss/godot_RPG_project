extends ProgressBar

func _on_player_update_health_ui(current_health):
	# Update the variable with the clamped value
	current_health = clamp(current_health, 0, 100) 
	# Directly assign the updated health to the progress bar's value property
	value = current_health
