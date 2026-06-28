import "importUtil"
ensureImport ["mapUtil", "listUtil", "Events"]

globals.InputAction = {}
InputAction.enabled = false
InputAction.changeListener = null
InputAction.keyInput = null
InputAction.triggerState = "pressed"  // "pressed", "held", or "released"
InputAction.heldDelay = 0.3          // seconds before "pressed" transitions to "held"
InputAction._wasDown = false
InputAction._holdTime = 0
InputAction._state = "up"            // internal: "up", "pressed", "down", "held", "released"

InputAction.Make = function(name, keyInput, triggerState="pressed", heldDelay=0.3)
  a = new InputAction
  a.name = name
  a.keyInput = keyInput
  a.triggerState = triggerState
  a.heldDelay = heldDelay
  a._wasDown = false
  a._holdTime = 0
  a._state = "up"
  a.enabled = false
  a.changeListener = Listener.Make(a, "changeKeyInput")
  a.enable
  return a
end function

InputAction.enable = function
  if self.enabled then return
  self.enabled = true
  Events.on "ActionChange_" + self.name, self.changeListener
end function

InputAction.disable = function
  if not self.enabled then return
  self.enabled = false
  Events.offAllFor self
end function

InputAction.changeKeyInput = function(keyInput)
  self.keyInput = keyInput
end function

// Called each frame by InputContext.testActions to advance state machine.
InputAction.update = function
  isDown = key.pressed(self.keyInput)

  if isDown and not self._wasDown then
    self._state = "pressed"
    self._holdTime = 0
  else if isDown then
    self._holdTime = self._holdTime + raylib.GetFrameTime
    if self._holdTime >= self.heldDelay then
      self._state = "held"
    else
      self._state = "down"
    end if
  else if not isDown and self._wasDown then
    self._state = "released"
  else
    self._state = "up"
  end if

  self._wasDown = isDown
end function

InputAction.isActive = function
  return self._state == self.triggerState
end function


globals.InputContext = {}
InputContext.actions = null

InputContext.Make = function
  c = new InputContext
  c.actions = {}
  return c
end function

InputContext.addAction = function(name, action)
  if self.actions == null then self.actions = {}
  self.actions[name] = action
end function

InputContext.removeAction = function(name)
  if self.actions isa map then self.actions.remove name
end function

// Updates each action then emits its signal if active.
InputContext.testActions = function
  for name in self.actions.indexes
    action = self.actions[name]
    action.update
    if action.isActive then Events.emit name
  end for
end function


Input = {}
Input.contexts = {}
Input.activeContexts = []

Input.reset = function
  self.contexts = {}
  self.activeContexts = []
end function

Input.addContext = function(name)
  if self.contexts.get(name) == null then
    c = InputContext.Make
    self.contexts[name] = c
    return c
  end if
end function

Input.getContext = function(name)
  return self.contexts.get(name)
end function

Input.enableContext = function(name)
  c = self.contexts.get(name)
  if c == null then return
  if not self.activeContexts.contains(c) then self.activeContexts.push c
end function

Input.disableContext = function(name)
  c = self.contexts.get(name)
  if c != null then self.activeContexts.removeVal c
end function

// Checks all enabled context actions and emits signals for active ones.
Input.update = function
  for context in self.activeContexts
    context.testActions
  end for
end function

if locals == globals then
  // Mock key.pressed and raylib.GetFrameTime so tests run without hardware
  globals._testKeyDown = false
  globals._testFrameTime = 0.1
  key.pressed = function(k); return _testKeyDown; end function
  raylib.GetFrameTime = function; return _testFrameTime; end function

  // Step an action N frames with key in the given state
  stepAction = function(action, isDown, frames=1)
    globals._testKeyDown = isDown
    for i in range(1, frames)
      action.update
    end for
  end function

  // ---- InputAction state machine ----

  print "Test 1: 'pressed' fires on first frame only"
  a = InputAction.Make("t1", "space", "pressed", 0.3)
  stepAction a, false
  qa.assert not a.isActive, "inactive when key is up"
  stepAction a, true          // frame 1: "pressed"
  qa.assert a.isActive, "active on first press"
  stepAction a, true          // frame 2: "down" (not yet held)
  qa.assert not a.isActive, "inactive on second held frame"

  print "Test 2: 'held' fires after heldDelay"
  a = InputAction.Make("t2", "space", "held", 0.3)
  stepAction a, true          // "pressed" (0s elapsed)
  qa.assert not a.isActive, "held should not fire on first press"
  stepAction a, true          // "down" (0.1s)
  stepAction a, true          // "down" (0.2s)
  stepAction a, true          // "held" (0.3s)
  qa.assert a.isActive, "held should fire after heldDelay"
  stepAction a, true          // "held" continues
  qa.assert a.isActive, "held should continue while key is held"

  print "Test 3: 'released' fires on key-up frame only"
  a = InputAction.Make("t3", "space", "released")
  stepAction a, true
  qa.assert not a.isActive, "released should not fire while key is down"
  stepAction a, false         // "released"
  qa.assert a.isActive, "released should fire on key-up frame"
  stepAction a, false         // "up"
  qa.assert not a.isActive, "released should not persist past key-up frame"

  // ---- changeKeyInput via event ----

  print "Test 4: changeKeyInput via ActionChange event"
  a = InputAction.Make("rebind", "space", "pressed")
  Events.emit "ActionChange_rebind", "enter"
  qa.assert a.keyInput == "enter", "keyInput should update via ActionChange event"

  // ---- enable / disable ----

  print "Test 5: enable and disable"
  a = InputAction.Make("t5", "space", "pressed")
  a.disable
  qa.assert not a.enabled, "action should be disabled"
  a.enable
  qa.assert a.enabled, "action should re-enable"

  // ---- InputContext ----

  print "Test 6: InputContext add / removeAction"
  ctx = InputContext.Make
  a = InputAction.Make("jump", "space", "pressed")
  ctx.addAction "jump", a
  qa.assert ctx.actions.hasIndex("jump"), "addAction should store the action"
  ctx.removeAction "jump"
  qa.assert not ctx.actions.hasIndex("jump"), "removeAction should delete it"

  print "Test 7: testActions emits signal for active action"
  ctx = InputContext.Make
  a = InputAction.Make("fire", "space", "pressed")
  ctx.addAction "fire", a
  fired = false
  _setFired = function(d); outer.fired = true; end function
  fireL = Listener.Make(null, @_setFired)
  Events.on "fire", fireL
  globals._testKeyDown = true
  ctx.testActions
  qa.assert fired, "testActions should emit signal when action is active"
  Events.off "fire", fireL

  // ---- Input manager ----

  print "Test 8: Input context management"
  Input.reset
  ctx = Input.addContext("gameplay")
  qa.assert ctx != null, "addContext should return the new context"
  qa.assert Input.getContext("gameplay") != null, "getContext should find it"

  a = InputAction.Make("dash", "space", "pressed")
  ctx.addAction "dash", a
  dashFired = false
  _setDashFired = function(d); outer.dashFired = true; end function
  dashL = Listener.Make(null, @_setDashFired)
  Events.on "dash", dashL

  Input.enableContext "gameplay"
  globals._testKeyDown = true
  Input.update
  qa.assert dashFired, "update should propagate through enabled contexts"

  Input.disableContext "gameplay"
  dashFired = false
  a._wasDown = false; a._state = "up"   // reset so it can fire again
  Input.update
  qa.assert not dashFired, "disabled context should not fire"
  Events.off "dash", dashL

  print "All Input tests passed!"
else
  return Input
end if
