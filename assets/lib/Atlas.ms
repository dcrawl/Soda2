import "importUtil"
ensureImport ["json", "Assets"]

Atlas = {}
Atlas.image = null
Atlas.frames = null   // name -> [x, y, w, h]

Atlas.Make = function(imagePath, jsonPath)
	a = new Atlas
	a.image = Assets.loadImage(imagePath)   // shared, cache-deduped
	data = json.parse(file.readLines(jsonPath).join(char(10)))
	a.frames = {}
	for kv in data.frames
		f = kv.value.frame
		a.frames[kv.key] = [f.x, f.y, f.w, f.h]
	end for
	return a
end function

// For a one-off sprite (a UI icon, say).
Atlas.makeSprite = function(frameName)
	sp = new Sprite
	sp.image = self.image
	sp.srcRect = self.frames.get(frameName)
	sp.addBounds
	return sp
end function

// For animation: re-skin an *existing* sprite to a different frame,
// rather than allocating a new Sprite every tick.
Atlas.setFrame = function(sprite, frameName)
	sprite.image = self.image
	sprite.srcRect = self.frames.get(frameName)
end function

return Atlas