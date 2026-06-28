// This really should be handled within the Engine so that ref counting can determine unloading
// Possibly be able to pin and unpin assets so that even when ref count == 0, it wont unload 
// until unpinned or forced to unload.

import "importUtil"
ensureImport ["Atlas"]

// Asset Caching Singleton
// Do not use with "new" operator
Assets = {}
Assets.loadImageHandler = @file.loadImage
Assets.loadSoundHandler = @file.loadSound
Assets.images = {}
Assets.sounds = {}
Assets.atlases = {}

Assets.loadAtlas = function(imagePath, jsonPath)
	key = imagePath + "|" + jsonPath
	a = self.atlases.get(key)
	if a then return a
	a = Atlas.Make(imagePath, jsonPath)
	self.atlases[key] = a
	return a
end function

Assets.clearAll = function
  self.images = {}
  self.sounds = {}
  self.atlases = {}
end function

Assets.clearImage = function(path)
  self.images.remove path
end function

Assets.clearSound = function(path)
  self.sounds.remove path
end function

Assets.unloadAll = function
  for path in self.images.indexes
    raylib.UnloadImage self.images[path]
  end for
  for path in self.sounds.indexes
    raylib.UnloadSound self.sounds[path]
  end for
  self.clearAll
end function

// Only works in Raylib-miniscript (file is protected in Mini Micro)
// File Overrides
file.loadImage = function(path)
  i = Assets.images.get(path)
  if i then return i
  i = Assets.loadImageHandler(path)
  Assets.images[path] = i
  return i
end function

file.loadSound = function(path)
  i = Assets.sounds.get(path)
  if i then return i
  i = Assets.loadSoundHandler(path)
  Assets.sounds[path] = i
  return i
end function

if locals == globals then
  // Test Assets

else
  return Assets
end if