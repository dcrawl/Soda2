// tests/runAll.ms -- runs each module's self-tests in dependency order.
// Not a new testing convention, just a sequencer for the existing one.
modules = [
	// Tier 1
	"Image", "Sound", "key", "mouse",
	// Tier 2 (cluster -- order within this tier matters less)
	"Display", "PixelDisplay", "SpriteDisplay", "SolidColorDisplay", "TileDisplay",
	// Tier 3
	"button", "textField", "listBox", "animatedCharacter", "spriteSheet", "ttFonts", "bmfFonts",
]

for m in modules
	print "=== " + m + " ==="
	run m
end for