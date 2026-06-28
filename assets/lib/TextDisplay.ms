import "importUtil"
ensureImport ["Display", "ttFonts", "listUtil"]

globals.TextDisplayCell = {}
TextDisplayCell.character = ""
TextDisplayCell.color = color.aqua
TextDisplayCell.backColor = color.clear
TextDisplayCell.inverse = false

TextDisplayCell.Make = function(c,b,i=false)
  c = new TextDisplayCell
  c.color = c
  c.backColor = b
  c.inverse = i
  return c
end function

TextDisplay = new Display
TextDisplay.mode = displayMode.text
TextDisplay.charW = 8
TextDisplay.charH = 8
TextDisplay.charRect = {"x":0, "y":0, "width":TextDisplay.charW, "height":TextDisplay.charH}
TextDisplay.padX = 1
TextDisplay.padY = 2
TextDisplay.gridW = floor(raylib.GetScreenWidth / (TextDisplay.charW + TextDisplay.padX))
TextDisplay.gridH = floor(raylib.GetScreenHeight / (TextDisplay.charH + TextDisplay.padY))
TextDisplay.offsetX = floor((raylib.GetScreenWidth - ((TextDisplay.charW + TextDisplay.padX) * TextDisplay.gridW)) / 2)
TextDisplay.offsetY = floor((raylib.GetScreenHeight - ((TextDisplay.charH + TextDisplay.padY) * TextDisplay.gridH)) / 2)
TextDisplay.grid = list.init2D(TextDisplay.gridH, TextDisplay.gridW)
TextDisplay.fontImage = raylib.LoadTexture("assets/lib/font/TextUI.png")

TextDisplay.color	= color.aqua      // get or set the text color (used on subsequent TextDisplay.print)
TextDisplay.backColor = color.clear	// get or set the background color (used on subsequent TextDisplay.print)
TextDisplay.column = 0	            // get/set the cursor column, 0-67 (where subsequent TextDisplay.print begins)
TextDisplay.row	   = 0              // get or set the cursor row, 0-25 (used on subsequent TextDisplay.print)
TextDisplay.inverse	= true          // when true, subsequent printing swaps text and background color
TextDisplay.delimiter	= char(13)    // get/set the extra character output after every TextDisplay.print)

// Resizes the text grid to fit the font
TextDisplay.setFont = function(path)
  self.fontImage = raylib.LoadTexture(path)
end function

// get the character at the given column and row
TextDisplay.cell = function(x, y)
  self.grid[y][x].character
end function

// store character k into the given column and row
TextDisplay.setCell = function(x, y, k)
  self.grid[y][x].character = k
end function

// get the text color at the given column and row
TextDisplay.cellColor = function(x, y)
  return self.grid[y][x].color
end function

// set the text color at the given column and row to c
TextDisplay.setCellColor = function(x, y, c)
  self.grid[y][x].color = c
end function

// get the background color at the given column and row
TextDisplay.cellBackColor = function(x, y)
  return self.grid[y][x].backColor
end function

// set the background color at the given column and row to c
TextDisplay.setCellBackColor = function(x, y, c)
  self.grid[y][x].backColor = c
end function

// print string s (followed by the delimiter)
TextDisplay.print = function(s, d="")
end function

// Clears and resets TextDisplay
TextDisplay.clear = function
  for rows in range(self.gridH - 1)
    for cols in range(self.gridW - 1)
      self.grid[rows][cols] = new TextDisplayCell
    end for
  end for
end function        

// Draw text grid
TextDisplay.render = function
  for rows in range(self.gridH - 1)
    for cols in range(self.gridW - 1)
      cell = self.grid[rows][cols]
      
    end for
  end for
end function


return TextDisplay