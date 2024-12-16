extends AnimationPlayer

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass
	
func play_animation_trump():
	play("Animation1")
	
func play_animation_xi():
	play("XiAnimation1")

func play_animation_kim():
	play("KimAnimation1")

func play_animation_putin():
	play("PutinAnimation1")

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass
