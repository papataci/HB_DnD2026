extends ColorRect

const FADE_DURATION := 0.5

func fade_out(duration: float = FADE_DURATION) -> Tween:
	var tween := create_tween()
	tween.tween_property(self, "color:a", 1.0, duration)
	return tween

func fade_in(duration: float = FADE_DURATION) -> Tween:
	var tween := create_tween()
	tween.tween_property(self, "color:a", 0.0, duration)
	return tween
