extends SceneTree

const UI_FONT: Font = preload("res://assets/fonts/DreadboundChinese.ttf")
const REQUIRED_TEXT := "终末回廊行者整备终端废弃疗养院潮没末班线阈值司仪坚守者武装师共鸣者缝合校准鸣师高架慢线淹没快线北站台南站台深水"

func _init() -> void:
	for character in REQUIRED_TEXT:
		assert(UI_FONT.has_char(character.unicode_at(0)), "UI font is missing: %s" % character)
	print("Chinese font coverage test passed")
	quit()
