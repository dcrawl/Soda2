import "importUtil"
ensureImport ["qa", "listUtil", "mapUtil"]

// Method Reference acts like a funcRef but keeps track of the object so that "self" works
globals.MethRef = {}
MethRef.methodName = ""
MethRef.object = null

MethRef.Make = function(obj, methodName)
  qa.assert obj isa map, "MethRef: Invalid object"
  qa.assert methodName isa string, "MethRef: Invalid Method Name"

  mr = new MethRef
  mr.object = obj
  mr.methodName = methodName
  return mr
end function

MethRef.invoke = function(args=null)
  if self.object != null and self.object.get(self.methodName) isa funcRef then
    if args != null then
      self.object[self.methodName](args)
    else
      self.object[self.methodName]
    end if
  end if
  return null
end function

// Validates that the MethRef can be invoked.
MethRef.canInvoke = function
  if self.object == null then return false
  return self.object.get(self.methodName) isa funcRef
end function

globals.Listener = {}
Listener.meth =  null
Listener.decay = false

Listener.Make = function(o, m)
	qa.assert (o == null and m isa funcRef) or (o != null and m isa string), "Listener.Create: Invalid Listener definition."

	l = new Listener
  if o == null then l.meth = @m  else l.meth = MethRef.Make(o, m)
	return l
end function

// Listeners set to decay will be removed after their next invoke
Listener.setDecay = function(d)
	qa.assert d == true or d == false, "Listener.setDecay: decay must be a boolean"

	self.decay = d
	return self
end function

Listener.isValid = function
  if @self.meth isa funcRef then return true
  if self.meth isa MethRef then return self.meth.canInvoke
  return false
end function

Listener.isOwner = function(owner)
 	if @self.meth isa funcRef then return false
	if self.meth isa MethRef then return refEquals(self.meth.object, owner)
	return false
end function

Listener.invoke = function(data=null)
 	if @self.meth isa funcRef then 
		self.meth data
		return
	end if
  if self.meth isa MethRef then 
		self.meth.invoke data
		return
	end if
end function

// This is a singleton.  Do not use with the "new" operator.
Events = {}
Events.signals = {} // dictionary of signalName -> array of listeners

// Registers an object to call its method when a signal is sent
Events.on = function(signalName, listener)
	qa.assert listener isa Listener, "Events.on: listener must be a Listener object"
	qa.assert signalName isa string and signalName.len > 0, "Events.on: signalName must be a non-empty string"


	if not self.signals.hasIndex(signalName) then self.signals[signalName] = []
	self.signals[signalName].push listener
end function

Events.off = function(signalName, listener)
	qa.assert listener isa Listener, "Events.off: listener must be a Listener object"
	qa.assert signalName isa string and signalName.len > 0, "Events.off: signalName must be a non-empty string"

	if not self.signals.hasIndex(signalName) then return 
	for i in range(self.signals[signalName].len - 1, 0, -1)
		if refEquals(self.signals[signalName][i], listener) then self.signals[signalName].remove i
	end for
end function

// Scans all signals and removes any that belong to the Owner
Events.offAllFor = function(owner)
	for signalName in self.signals.indexes
		if not self.signals.hasIndex(signalName) then continue 
		for i in range(self.signals[signalName].len - 1, 0, -1)
			l = self.signals[signalName][i]
			if l.isOwner(owner) then self.signals[signalName].remove i
		end for
	end for
end function

Events._isAlive = function(a)
	return not a.decay
end function

Events.emit = function(signalName, data = null)
	qa.assert signalName isa string and signalName.len > 0, "Events.emit: signalName must be a non-empty string"

	// Check if signal has any listeners
	if not self.signals.hasIndex(signalName) then 
		// Possible incorrect Signal Name being called
			raylib.TraceLog(raylib.LOG_DEBUG, "Events.emit: Missing signal name '" + signalName + "'")
		return 
	end if

	// Call each listener's method with the provided data
	// Iterate over shallow copy of list incase a listener changes the current list of signals.
	for l in self.signals[signalName][:]
		// Check if listener is still valid
		if l.isValid then l.invoke data else l.setDecay true // Decay listener if it is no longer valid
	end for

	// Remove decayed Listeners -- .filtered mutates in place
	self.signals[signalName].filtered @self._isAlive
end function

Events.once = function(signalName, listener)
	qa.assert listener isa Listener, "Events.once: listener must be a Listener object"
	qa.assert signalName isa string and signalName.len > 0, "Events.once: signalName must be a non-empty string"

	listener.setDecay true
	self.on signalName, listener
end function

if locals == globals then 
	testFunc = function
		print "Test function was called"
	end function

	testObj = {}
	testObj.lastData = null
	testObj.testFunc = function
		print "Test Object Method was called"
	end function
	testObj.dataReceiver = function(d)
			self.lastData = d
	end function

	decayCount = 0
	decayFunc = function(data)
			outer.decayCount = decayCount + 1
			print "once listener called with: " + data
	end function

	listener = Listener.Make(null, @testFunc)
	Events.on "test", listener
	Events.emit "test"
	Events.off "test", listener
	Events.emit "test"

	listener = Listener.Make(testObj, "testFunc")
	Events.on "test", listener
	Events.emit "test"
	Events.offAllFor testObj
	Events.emit "test"

	// Test once / decay
	Events.once "once_test", Listener.Make(null, @decayFunc)
	Events.emit "once_test", "Decay Fire Once"   // should fire, decayCount = 1
	Events.emit "once_test", "Decay Fire Twice"   // should NOT fire
	qa.assert decayCount == 1, "once listener fired more than once"

	// Test data passing with MethRef
	dl = Listener.Make(testObj, "dataReceiver")
	Events.on "data_test", dl
	Events.emit "data_test", 42
	qa.assert testObj.lastData == 42, "data not passed to MethRef listener"
	Events.off "data_test", dl
else
	return Events
end if