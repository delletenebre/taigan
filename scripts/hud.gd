extends Control
signal pause_requested
signal bark_requested
signal restart_requested
signal resume_requested
signal timer_skip_requested

func _ready() -> void:
	$WolfTimer/Skip.pressed.connect(func(): timer_skip_requested.emit())
	$Pause.pressed.connect(func(): pause_requested.emit())
	$Bark.pressed.connect(func(): bark_requested.emit())
	$Overlay/Card/Resume.pressed.connect(func(): resume_requested.emit())
	$Overlay/Card/Restart.pressed.connect(func(): restart_requested.emit())

func update_values(count: int, total: int, seconds: float, cooldown: float, lost: int) -> void:
	$SheepCount/Text.text = "%d/%d" % [count, total]
	$WolfTimer/Text.text = "%02d:%02d" % [int(ceil(seconds)) / 60, int(ceil(seconds)) % 60]
	$WolfTimer.modulate = Color("e6ada0") if seconds <= 10 else Color.WHITE
	$Bark.disabled = cooldown > 0
	$Bark.text = "%.1f" % cooldown if cooldown > 0 else "Гав!"
	$Goal/Text.text = "Собери всю отару" if lost == 0 else "В загон: %d  ·  Унесено: %d" % [count, lost]

func bump_count() -> void:
	var tween := create_tween()
	tween.tween_property($SheepCount, "scale", Vector2(1.08, 1.08), 0.12)
	tween.tween_property($SheepCount, "scale", Vector2.ONE, 0.2)

func show_pause(value: bool) -> void:
	$Overlay.visible = value
	$Overlay/Card/Title.text = "Привал"
	$Overlay/Card/Description.text = "Веди тайгана касанием или WASD.\nОбходи овец сзади и гони к мосту.\nДвойной тап или пробел — лай.\nПодбеги к волку, чтобы отбить овцу."
	$Overlay/Card/Resume.show()

func show_result(count: int, total: int, lost: int) -> void:
	$Overlay.show()
	$Overlay/Card/Resume.hide()
	$Overlay/Card/Title.text = "Вся отара дома!" if lost == 0 else "Выпас окончен"
	$Overlay/Card/Description.text = "В безопасности %d из %d овец.\n%s" % [count, total, "Тайган заслужил отдых." if lost == 0 else "Попробуй собрать всех до прихода волков."]
