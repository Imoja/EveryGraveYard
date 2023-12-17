extends CanvasLayer


# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	$Yards.text = str("YARDS: ") + str(get_parent().stats_yards)
	$Stamina.text = str("STAMINA: ") + str(get_parent().stats_stamina)
	$Fitness.text = str("FTINESS: ") + str(get_parent().stats_fitness)
	$Delta.text = str("POS_DELTA: ") + str(get_parent().pos_delta)
	$FOV.text = str("FOV: ") + str(get_parent().camera.fov)
