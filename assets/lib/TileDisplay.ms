import "importUtil"
ensureImport ["Display", "color"]

TileDisplay = new Display
TileDisplay.mode = displayMode.tile

TileDisplay.tileSet = null          // Image to draw tiles from
TileDisplay.tileSetTileSize = 64    // pixels, size of each tile *within* tileSet
TileDisplay.cellSize = 64           // pixels, size of each cell on screen
TileDisplay.overlap = 0             // pixels of overlap between adjacent cells
TileDisplay.oddRowOffset = 0        // fraction of cellSize; 0.5 for hex rows
TileDisplay.oddColOffset = 0        // fraction of cellSize; 0.5 for hex columns
TileDisplay.scrollX = 0
TileDisplay.scrollY = 0

TileDisplay._cols = 0
TileDisplay._rows = 0
TileDisplay._idx = null     // grid[row][col] -> tile index, or null (empty)
TileDisplay._tint = null    // grid[row][col] -> color, or null (no tint)
TileDisplay._xform = null   // grid[row][col] -> transform 0-7

TileDisplay.Make = function
	td = new TileDisplay
	td.setExtent 10, 10
	return td
end function

// Resize the grid.  This is the explicit stand-in for Mini Micro's
// "assigning to .extent resizes the grid" trick, which relies on
// native property interception we don't have available here.
TileDisplay.setExtent = function(columns, rows)
	self._cols = columns
	self._rows = rows
	self._idx = list.init2D(rows, columns, null)
	self._tint = list.init2D(rows, columns, null)
	self._xform = list.init2D(rows, columns, 0)
end function

TileDisplay.extent = function
	return [self._cols, self._rows]
end function

TileDisplay.clear = function(toIndex=null)
	for row in range(0, self._rows - 1)
		for col in range(0, self._cols - 1)
			self._idx[row][col] = toIndex
			self._tint[row][col] = null
			self._xform[row][col] = 0
		end for
	end for
end function

TileDisplay.cell = function(x, y)
	return self._idx[y][x]
end function

TileDisplay.setCell = function(x, y, idx)
	self._idx[y][x] = idx
end function

TileDisplay.cellTint = function(x, y)
	return self._tint[y][x]
end function

TileDisplay.setCellTint = function(x, y, c)
	self._tint[y][x] = c
end function

TileDisplay.cellTransform = function(x, y)
	return self._xform[y][x]
end function

TileDisplay.setCellTransform = function(x, y, t)
	self._xform[y][x] = t
end function

// Internal: source rect into tileSet for a given tile index.
// Tile-set indexing is top-left to bottom-right -- the one
// documented exception to Mini Micro's usual bottom-up convention.
TileDisplay._srcRectFor = function(idx)
	tilesPerRow = floor(self.tileSet.width / self.tileSetTileSize)
	col = idx % tilesPerRow
	row = floor(idx / tilesPerRow)
	s = self.tileSetTileSize
	return [col * s, row * s, s, s]
end function

TileDisplay._tileGeometry = function(x, y, idx)
	srcRect = self._srcRectFor(idx)
	t = self._xform[y][x]
	flipH = t >= 4
	rotation = (t % 4) * 90
	if flipH then srcRect = [srcRect[0], srcRect[1], -srcRect[2], srcRect[3]]

	spacing = self.cellSize - self.overlap
	ox = self.oddColOffset * self.cellSize * (y % 2)
	oy = self.oddRowOffset * self.cellSize * (x % 2)
	worldX = x * spacing + ox - self.scrollX
	worldY = y * spacing + oy - self.scrollY

	screenX = worldX + self.cellSize * 0.5
	screenY = raylib.GetScreenHeight - worldY - self.cellSize * 0.5
	destRect = [screenX, screenY, self.cellSize, self.cellSize]
	origin = [self.cellSize * 0.5, self.cellSize * 0.5]
	return {"srcRect": srcRect, "destRect": destRect, "origin": origin, "rotation": rotation}
end function

TileDisplay.render = function
	if self.tileSet == null then return
	for y in range(0, self._rows - 1)
		for x in range(0, self._cols - 1)
			idx = self._idx[y][x]
			if idx == null then continue
			g = self._tileGeometry(x, y, idx)
			tint = self._tint[y][x]
			if tint == null then tint = color.white
			raylib.DrawTexturePro self.tileSet.texture, g.srcRect, g.destRect, g.origin, g.rotation, tint
		end for
	end for
end function

if locals == globals then
	print "== Pure logic tests (no rendering needed) =="

	print "setExtent allocates a grid of the right shape"
	td = TileDisplay.Make
	td.setExtent 5, 3
	ext = td.extent
	qa.assert ext[0] == 5 and ext[1] == 3, "extent should report [5,3]"
	qa.assert td.cell(4, 2) == null, "new grid should be empty"

	print "setCell / cell round-trip"
	td.setCell 2, 1, 7
	qa.assert td.cell(2, 1) == 7, "setCell then cell should return 7"
	qa.assert td.cell(0, 0) == null, "untouched cells should remain null"

	print "clear with a fill index sets every cell"
	td.clear 9
	qa.assert td.cell(0, 0) == 9 and td.cell(4, 2) == 9, "clear(9) should fill the whole grid"

	print "setCellTint / cellTint round-trip"
	td.setCellTint 1, 1, color.red
	qa.assert td.cellTint(1, 1) == color.red, "tint should round-trip"
	qa.assert td.cellTint(0, 0) == null, "untouched cells have no tint"

	print "setCellTransform / cellTransform round-trip, full 0-7 range"
	for t in range(0, 7)
		td.setCellTransform 0, 0, t
		qa.assert td.cellTransform(0, 0) == t, "transform " + t + " should round-trip"
	end for

	print "_srcRectFor indexes left-to-right, top-to-bottom"
	td.tileSet = {"width": 256}   // fake stand-in, just needs .width
	td.tileSetTileSize = 64
	r0 = td._srcRectFor(0)
	r1 = td._srcRectFor(1)
	r4 = td._srcRectFor(4)   // second row, since 256/64 = 4 tiles per row
	qa.assert r0 == [0, 0, 64, 64], "tile 0 should be top-left"
	qa.assert r1 == [64, 0, 64, 64], "tile 1 should be next column, same row"
	qa.assert r4 == [0, 64, 64, 64], "tile 4 should wrap to the next row"

	print "_tileGeometry: rotation values 0-3 don't flip, 4-7 do"
	td.cellSize = 64
	td.overlap = 0
	td.setCell 0, 0, 0
	for t in range(0, 7)
		td.setCellTransform 0, 0, t
		g = td._tileGeometry(0, 0, 0)
		expectedRotation = (t % 4) * 90
		qa.assert g.rotation == expectedRotation, "transform " + t + " rotation should be " + expectedRotation
		expectedFlip = t >= 4
		actualFlip = g.srcRect[2] < 0
		qa.assert actualFlip == expectedFlip, "transform " + t + " flip mismatch"
	end for

	print "All pure-logic tests passed!"
	print ""
	print "== Visual tests (need a human to look) =="
	print "Run testVisualTransforms() and confirm by eye:"
	print "  - flip direction matches the documented convention (4-7 mirror, then rotate)"
	print "  - overlap actually overlaps adjacent cells rather than gapping them"
	print "  - oddRowOffset/oddColOffset at 0.5 produces a believable hex stagger"
else
	return TileDisplay
end if

// Visual confirmation harness -- not asserted automatically, by design.
// Lays out all 8 transforms of the same tile side by side so a flipped
// or mis-rotated tile is immediately obvious by eye.
testVisualTransforms = function
	import "soda"
	td = TileDisplay.Make
	td.tileSet = file.loadImage("/path/to/some/asymmetric_tile.png")
	td.tileSetTileSize = 64
	td.cellSize = 64
	td.setExtent 8, 1
	for t in range(0, 7)
		td.setCell t, 0, 0
		td.setCellTransform t, 0, t
	end for
	display(4).setMode displayMode.tile
	display(4).Make = td   // however install ends up wired
	while not key.pressed("escape")
		yield; soda.update
	end while
end function