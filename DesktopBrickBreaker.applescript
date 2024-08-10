use AppleScript version "2.4"
use scripting additions
use framework "Foundation"
use framework "AppKit"

-- Path/Names
set BALL_NAME to "!!!!"
set PADDLE_1_NAME to " "
set PADDLE_2_NAME to "  "
set PADDLE_3_NAME to "   "

-- Screen size
set MONITOR_WIDTH to 1920
set MONITOR_HEIGHT to 1080
set LAPTOP_WIDTH to 1536
set LAPTOP_HEIGHT to 960
set SCREEN_WIDTH to LAPTOP_WIDTH
set SCREEN_HEIGHT to LAPTOP_HEIGHT

-- Game config
set DEFAULT_STEP_SIZE to 10
set DELAY_TIME to 0.01
set HIT_SPEED_MULT to 1.05
set MAKE_OBJECTS to true
set OBJ_PER_LEVEL to 10

-- Game state
set gameover to false
set curLevel to 0
set curObjRemaining to 0
set curStepSize to DEFAULT_STEP_SIZE

-- Helper funcs
on getFolder(name)
	tell application "Finder"
		set folderPath to (path to desktop folder as text) & name
		if not (exists folder folderPath) then
			make new folder at (path to desktop folder) with properties {name: name}
		end if
		set result to folder folderPath
		return result
	end tell
end getFolder

set paddle1 to getFolder(PADDLE_1_NAME)
set paddle2 to getFolder(PADDLE_2_NAME)
set paddle3 to getFolder(PADDLE_3_NAME)
set ball to getFolder(BALL_NAME)


tell application "Finder"
-- If not in MAKE_OBJECTS mode, get desktop items and their coords now
	global desktopItems
	set desktopItems to {}
	if not MAKE_OBJECTS then
		repeat with anItem in desktop
			set itemInfo to {position: desktop position of anItem, name: name of anItem}
			if not name of anItem is PADDLE_1_NAME and not name of anItem is PADDLE_2_NAME and not name of anItem is PADDLE_3_NAME and not name of anItem is BALL_NAME then
				set end of desktopItems to itemInfo
			end if 
		end repeat
	end if 

	-- ball coords
	set x to SCREEN_WIDTH / 2
    set y to SCREEN_HEIGHT - 100
  	set xDirection to 1
  	set yDirection to -1
		
   	repeat while not gameover
		-- create objects for new level
		if MAKE_OBJECTS and curObjRemaining is 0 then
			set curLevel to curlevel + 1
			set x to SCREEN_WIDTH / 2
    		set y to SCREEN_HEIGHT - 100
			repeat with i from 1 to curLevel
			    repeat with j from 1 to OBJ_PER_LEVEL
        			set folderName to (i as text) & "," & (j as text)
					set folderPath to (path to desktop folder as text) & folderName
					if not exists folder folderPath then
            			set newFolder to make new folder at (path to desktop folder) with properties {name: folderName}
					end if
            		set newFolder to folder folderPath
					set objX to j * (SCREEN_WIDTH/OBJ_PER_LEVEL) - 100
					set objY to i * (SCREEN_HEIGHT / 6)
            		set desktop position of newFolder to {objX, objY}
    			end repeat
			end repeat
			set curObjRemaining to (curLevel * OBJ_PER_LEVEL)
			-- get desktop items and their coords
			set desktopItems to {}
			repeat with anItem in desktop
		    	set itemInfo to {position: desktop position of anItem, name: name of anItem}
				if not name of anItem is PADDLE_1_NAME and not name of anItem is PADDLE_2_NAME and not name of anItem is PADDLE_3_NAME and not name of anItem is BALL_NAME then
					set end of desktopItems to itemInfo
				end if 
	    	end repeat
		end if

  		set x to x + (curStepSize * xDirection)
  		set y to y + (curStepSize * yDirection)

		-- Move paddle with the mouse's X
		set mLoc to current application's NSEvent's mouseLocation()
		set msX to x of mLoc
		set msY to y of mLoc
  		set desktop position of paddle1 to {msX - 50, SCREEN_HEIGHT - 50}
  		set desktop position of paddle2 to {msX, SCREEN_HEIGHT - 50}
  		set desktop position of paddle3 to {msX + 50, SCREEN_HEIGHT - 50}
		set padX to msX
		set padY to SCREEN_HEIGHT - 25

		-- Check for out of bounds
		if y > SCREEN_HEIGHT then
			set gameover to true
			beep
		end if 

		-- Check for collision with paddle
		set isPadColX to ((x - padX) < 120) and ((x - padX) > -120)
		set isPadColY to ((y - padY) < 50) and ((y - padY) > -50)
		if isPadColX and isPadColY then
  			set yDirection to -yDirection
			set y to y + (curStepSize * 2 * yDirection)
			
			-- Adjust xDirection based on where the ball hits the paddle
			set hitPos to (x - padX)
			set xDirection to xDirection + (hitPos / 100)
			
			set curStepSize to curStepSize * HIT_SPEED_MULT
		end if

		-- Collision detection with other desktop items
		repeat with obj in desktopItems
			set objName to name of obj
			set objPosition to position of obj
			set objX to item 1 of objPosition
			set objY to item 2 of objPosition
			
			set isObjColX to ((x - objX) < 50) and ((x - objX) > -50)
			set isObjColY to ((y - objY) < 50) and ((y - objY) > -50)
			
			if isObjColX and isObjColY then
			-- Move the object to the ball folder
			    set ballFolderPath to (path to desktop folder as text) & BALL_NAME & ":"

			    if exists file objName of desktop then
			        if exists file objName of folder ballFolderPath then
			            -- Delete the file if it exists in the ball folder
			            delete file objName of folder ballFolderPath
			        end if
			        -- Adjust xDirection based on where the ball hits the object
			        set hitPos to (x - objX)
			        set xDirection to xDirection + (hitPos / 50)
			        -- Bounce the ball off the object
			        set xDirection to -xDirection
			        set yDirection to -yDirection
			        set x to x + (curStepSize * 2 * xDirection)
			        set y to y + (curStepSize * 2 * yDirection)
			        move file objName of desktop to folder ballFolderPath
					set curObjRemaining to curObjRemaining - 1
			    else if exists folder objName of desktop then
			        if exists folder objName of folder ballFolderPath then
			            -- Delete the folder if it exists in the ball folder
			            delete folder objName of folder ballFolderPath
			        end if
			        -- Adjust xDirection based on where the ball hits the object
			        set hitPos to (x - objX)
			        set xDirection to xDirection + (hitPos / 50)
			        -- Bounce the ball off the object
			        set xDirection to -xDirection
			        set yDirection to -yDirection
			        set x to x + (curStepSize * 2 * xDirection)
			        set y to y + (curStepSize * 2 * yDirection)
			        move folder objName of desktop to folder ballFolderPath
					set curObjRemaining to curObjRemaining - 1
			    end if
			end if
		end repeat
		
  		if x > SCREEN_WIDTH or x < 0 then
  			set xDirection to -xDirection
  		end if
  		if y > SCREEN_HEIGHT or y < 0 then
  			set yDirection to -yDirection
  		end if
		
  		set desktop position of ball to {x, y}
  		delay DELAY_TIME
  	end repeat
end tell
