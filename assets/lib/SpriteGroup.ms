import "importUtil"
ensureImport ["qa"]

SpriteGroup = {}
SpriteGroup.children = null
SpriteGroup.x = 0
SpriteGroup.y = 0

SpriteGroup.Make = function
	g = new SpriteGroup
	g.children = []
	return g
end function

SpriteGroup.add = function(sprite)
	self.children.push sprite
	return sprite   // handy for chaining: btn = group.add(Button.Make(...))
end function

SpriteGroup.remove = function(sprite)
	idx = self.children.indexOf(sprite)
	if idx != null then self.children.remove idx
end function

// Drawn exactly like a Sprite -- this is what makes it slot into
// SpriteDisplay.sprites without SpriteDisplay needing to know it exists.
SpriteGroup.draw = function(offsetX=0, offsetY=0)
	for child in self.children
		child.draw offsetX + self.x, offsetY + self.y
	end for
end function

// Coarse combined bounds -- union of children's worldBounds.
// Useful as a broad-phase prune before testing every child individually.
SpriteGroup.worldBounds = function
	result = null
	for child in self.children
		wb = child.worldBounds
		if wb == null then continue
		if result == null then
			result = wb
		else
			// expand result to include wb -- left as an exercise, or
			// just skip combining and return null if precision isn't needed yet
		end if
	end for
	return result
end function

return SpriteGroup