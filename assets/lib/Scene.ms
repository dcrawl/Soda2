import "importUtil"
ensureImport ["qa", "Events"]

// A Scene is one layer of game state/UI on the scene stack.
// Override enter/exit/pause/resume/update as needed; any left null
// are simply skipped.
//   enter   -- called once, when first pushed
//   exit    -- called once, when popped for good
//   pause   -- called when something else is pushed on top of this one
//   resume  -- called when this scene becomes the top again
//   update  -- called once per frame while this scene is active
globals.Scene = {}
Scene.name = "Scene"
Scene.blocksUpdate = true   // if true, scenes below this stop ticking while it's on top
Scene._ownedSlots = null   // lazily becomes a list of [slotNum, sprite] pairs

Scene.enter = null
Scene.exit = null
Scene.pause = null
Scene.resume = null
Scene.update = null

Scene.Make = function(name="Scene")
	s = new Scene
	s.name = name
	return s
end function

// Call a lifecycle hook only if the scene actually defines one.
_callIfDefined = function(scene, methodName)
	m = scene.get(methodName)
	if m isa funcRef then scene[methodName]
end function


globals.SceneManager = {}
SceneManager.stack = []

SceneManager.top = function
	if self.stack.len == 0 then return null
	return self.stack[-1]
end function

// Push a scene on top.  Pauses the previous top (if any), then enters
// the new one.  Use this for transient overlays (dialogs, pause menus)
// where what's underneath should keep existing, just stop ticking.
SceneManager.push = function(scene)
	qa.assert scene isa Scene, "SceneManager.push: scene must be a Scene"
	prevTop = self.top
	if prevTop != null then _callIfDefined prevTop, "pause"
	self.stack.push scene
	_callIfDefined scene, "enter"
end function

// Pop the top scene.  Exits it, cleans up anything it registered with
// Events, then resumes whatever's now on top.
SceneManager.pop = function
	if self.stack.len == 0 then return
	scene = self.stack.pop
	_callIfDefined scene, "exit"
	Events.offAllFor scene
	newTop = self.top
	if newTop != null then _callIfDefined newTop, "resume"
end function

// Replace the entire stack with a single new scene -- for hard scene
// changes (main menu -> gameplay), as opposed to push/pop for overlays.
SceneManager.replace = function(scene)
	while self.stack.len > 0
		self.pop
	end while
	self.push scene
end function

// Called once per frame.  Walks the stack top-down, updating each
// scene, stopping at the first one that blocks propagation.
SceneManager.update = function
	for i in range(self.stack.len - 1, 0, -1)
		scene = self.stack[i]
		_callIfDefined scene, "update"
		if scene.blocksUpdate then break
	end for
end function

// Add a sprite to a Display slot, and remember that this scene owns
// it, so it's cleaned up automatically on pop/replace (not on pause --
// see above, paused scenes are supposed to stay visible).
Scene.addSprite = function(slotNum, sprite)
	if self._ownedSlots == null then self._ownedSlots = []
	display(slotNum).sprites.push sprite
	self._ownedSlots.push [slotNum, sprite]
end function

Scene._removeOwnedSprites = function
	if self._ownedSlots == null then return
	for pair in self._ownedSlots
		sprites = display(pair[0]).sprites
		idx = sprites.indexOf(pair[1])
		if idx != null then sprites.remove idx
	end for
	self._ownedSlots = []
end function


if locals == globals then
	import "Events"

	log = []
	makeLoggingScene = function(name, blocks=true)
		s = Scene.Make(name)
		s.blocksUpdate = blocks
		s.enter  = function(); outer.log.push self.name + ".enter"; end function
		s.exit   = function(); outer.log.push self.name + ".exit"; end function
		s.pause  = function(); outer.log.push self.name + ".pause"; end function
		s.resume = function(); outer.log.push self.name + ".resume"; end function
		s.update = function(); outer.log.push self.name + ".update"; end function
		return s
	end function

	print "Test 1: push pauses previous top, enters new one"
	game = makeLoggingScene("game")
	SceneManager.push game
	qa.assert log == ["game.enter"], "expected only game.enter"

	log = []
	dialog = makeLoggingScene("dialog")
	SceneManager.push dialog
	qa.assert log == ["game.pause", "dialog.enter"], "push should pause prior top first"

	print "Test 2: update only reaches blocking scene's top"
	log = []
	SceneManager.update
	qa.assert log == ["dialog.update"], "blocksUpdate should stop propagation at dialog"

	print "Test 3: pop exits and resumes prior top"
	log = []
	SceneManager.pop
	qa.assert log == ["dialog.exit", "game.resume"], "pop should exit dialog, resume game"

	log = []
	SceneManager.update
	qa.assert log == ["game.update"], "game should tick again once it's the only scene"

	print "Test 4: non-blocking scene lets update propagate"
	log = []
	hud = makeLoggingScene("hud", false)
	SceneManager.push hud
	log = []
	SceneManager.update
	qa.assert log == ["hud.update", "game.update"], "non-blocking scene should let update reach game"

	SceneManager.pop
	SceneManager.pop

	print "All Scene tests passed!"
else
	return Scene
end if