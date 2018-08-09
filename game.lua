
local composer = require( "composer" )

local scene = composer.newScene()

system.activate( "multitouch" )

local widget = require("widget")
local jslib = require( "Joystick")		--call joystick file
local physics = require( "physics" )
physics.start()
physics.setGravity( 0, 0 )
physics.setDrawMode("normal")

local sheetOptions =
{
    frames =
    {
        {   
            x = 0,
            y = 0,
            width = 102,
            height = 85
        },
        {   
            x = 0,
            y = 85,
            width = 90,
            height = 83
        },
        {   
            x = 0,
            y = 168,
            width = 100,
            height = 97
        },
        {   
            x = 0,
            y = 265,
            width = 98,
            height = 79
        },
        {   
            x = 98,
            y = 265,
            width = 14,
            height = 40
        },
    }
}
local objectSheet = graphics.newImageSheet( "gameSprites.png", sheetOptions )

local lives = 3
local score = 0
local died = false

local alienTable = {}

local ship
local gameLoopTimer
local livesText
local scoreText

local backGroup
local mainGroup
local uiGroup

local explosionSound
local fireSound
local musicTrack

local difficultyScale = 2000
local attackSpeed = 1000
local movementSpeed = 4
local movementTime
local upgrade1Text
local upgrade2Text

local movement = jslib.new( 25, 50 )
	movement.x = 100
	movement.y = display.contentHeight - 200

local shooting = jslib.new( 25,50 )
	shooting.x = display.contentWidth - 100
	shooting.y = display.contentHeight - 200

local playerEXP = 0
local playerLVL = 1

local function updateText()
	livesText.text = "Lives: " .. lives
	scoreText.text = "Score: " .. score
end


local function spawnEnemy()

	local alienChoice = math.random(3)
	local newEnemy = display.newImageRect( mainGroup, objectSheet, alienChoice, 102, 85 )
	table.insert( alienTable, newEnemy )
	physics.addBody( newEnemy, "dynamic", { radius=40, bounce=0.8 } )
	newEnemy.myName = "alien"

	local whereFrom = math.random( 3 )

	if ( whereFrom == 1 ) then
		newEnemy.x = -60
		newEnemy.y = math.random( 500 )
		newEnemy:setLinearVelocity( math.random( 40,120 ), math.random( 20,60 ) )
	elseif ( whereFrom == 2 ) then
		newEnemy.x = math.random( display.contentWidth )
		newEnemy.y = -60
		newEnemy:setLinearVelocity( math.random( -40,40 ), math.random( 40,120 ) )
	elseif ( whereFrom == 3 ) then
		newEnemy.x = display.contentWidth + 60
		newEnemy.y = math.random( 500 )
		newEnemy:setLinearVelocity( math.random( -120,-40 ), math.random( 20,60 ) )
	end

end

local function gameLoop()
	spawnEnemy()

	for i = #alienTable, 1, -1 do
		local currentEnemey = alienTable[i]

		if ( currentEnemey.x < -100 or
			 currentEnemey.x > display.contentWidth + 100 or
			 currentEnemey.y < -100 or
			 currentEnemey.y > display.contentHeight + 100 )
		then
			display.remove( currentEnemey )
			table.remove( alienTable, i )
		end
	end
	timer.performWithDelay(difficultyScale, gameLoop, 1)
end


local function restoreShip()

	ship.isBodyActive = false
	ship:setLinearVelocity( 0, 0 )
	ship.x = display.contentCenterX
	ship.y = display.contentHeight - 100

	transition.to( ship, { alpha=1, time=4000,
		onComplete = function()
			ship.isBodyActive = true
			died = false
		end
	} )
end

local function endGame()
	composer.setVariable( "finalScore", score )
	composer.removeScene( "highscores" )
	composer.gotoScene( "highscores", { time=800, effect="crossFade" } )
end

local function upgrade()

	upgrade1 = display.newCircle( display.contentCenterX - 200,display.contentHeight - 200, 50)
	upgrade1Text = display.newText( "Speed+", display.contentCenterX-200, display.contentHeight - 200, native.systemFont, 20)
	upgrade1Text:setFillColor(0,0,0)
	upgrade1.myName = "Speed"
	upgrade2 = display.newCircle( display.contentCenterX + 200,display.contentHeight - 200, 50)
	upgrade2Text = display.newText( "Attack+", display.contentCenterX+200, display.contentHeight - 200, native.systemFont, 20)
	upgrade2Text:setFillColor(0,0,0)
	upgrade2.myName = "Attack"
	upgrade1:setFillColor(0,1,0)
	upgrade2:setFillColor(1,0,0)

	physics.addBody(upgrade1, "static", {radius = 50})
	physics.addBody(upgrade2, "static", {radius = 50})

	upgrade1:setLinearVelocity(0,100)
	upgrade2:setLinearVelocity(0,100)

end


local function onCollision( event )

	if ( event.phase == "began" ) then

		local obj1 = event.object1
		local obj2 = event.object2

		if ( ( obj1.myName == "ship" and obj2.myName == "Speed" ) or
			 ( obj1.myName == "Speed" and obj2.myName == "ship" ) )
		then
			display.remove(upgrade1Text)
			display.remove(upgrade2Text)
			display.remove( upgrade1)
			display.remove( upgrade2)
			movementSpeed = movementSpeed + 1

		elseif ( ( obj1.myName == "ship" and obj2.myName == "Attack" ) or
			 ( obj1.myName == "Attack" and obj2.myName == "ship" ) )
		then
			display.remove(upgrade1Text)
			display.remove(upgrade2Text)
			display.remove( upgrade1 )
			display.remove( upgrade2 )
			attackSpeed = attackSpeed * .75
			print (attackSpeed)


		elseif ( ( obj1.myName == "laser" and obj2.myName == "alien" ) or
			 ( obj1.myName == "alien" and obj2.myName == "laser" ) )
		then
			display.remove( obj1 )
            display.remove( obj2 )

			audio.play( explosionSound )

			for i = #alienTable, 1, -1 do
				if ( alienTable[i] == obj1 or alienTable[i] == obj2 ) then
					table.remove( alienTable, i )
					break
				end
			end

			-- Handle Game Scaling
			score = score + 100
			playerEXP = playerEXP + 100
			scoreText.text = "Score: " .. score
			if (score == 1000) then
				difficultyScale = 1500
				timer.performWithDelay(1, upgrade) 
			end
			if (score == 5000) then
				difficultyScale = 1000
				timer.performWithDelay(1, upgrade)
			end
			if (playerEXP == 10000) then
				playerEXP = 0
				difficultyScale = difficultyScale / 2
				timer.performWithDelay(1, upgrade)
			end

		elseif ( ( obj1.myName == "ship" and obj2.myName == "alien" ) or
				 ( obj1.myName == "alien" and obj2.myName == "ship" ) )
		then
			if ( died == false ) then
				died = true

				audio.play( explosionSound )

				lives = lives - 1
				livesText.text = "Lives: " .. lives

				if ( lives == 0 ) then
					timer.cancel(movementTime)
					display.remove( ship )
					timer.performWithDelay( 2000, endGame )
				else
					ship.alpha = 0
					timer.performWithDelay( 1000, restoreShip )
				end
			end
		end
	end
end


-- create()
function scene:create( event )

	local sceneGroup = self.view

	backGroup = display.newGroup()
	sceneGroup:insert( backGroup )

	mainGroup = display.newGroup()
	sceneGroup:insert( mainGroup )

	uiGroup = display.newGroup()
	sceneGroup:insert( uiGroup )


	local background = display.newImage( backGroup, "background.png" )
	background.x = display.contentCenterX
	background.y = display.contentCenterY
	
	ship = display.newImageRect( mainGroup, objectSheet, 4, 98, 79 )
	ship.x = display.contentCenterX
	ship.y = display.contentHeight - 200
	physics.addBody( ship, { radius=30 } )
	ship.myName = "ship"

	ship.playerScale = 0

	--upgrade()


	function catchTimer( e )
		yDir = movement:getY() * movementSpeed
		xDir = movement:getX() * movementSpeed

		ship:setLinearVelocity(xDir,yDir)
		return true
	end

	function shootTimer(e)
		yShoot = 0
		xShoot = 0

		--shoot right

		if (shooting:getDirection() == 1) then
			audio.play( fireSound )

			local newLaser = display.newImageRect( mainGroup, objectSheet, 5, 14, 40 )
			physics.addBody( newLaser, "dynamic", { isSensor=true } )
			newLaser.isBullet = true
			newLaser.myName = "laser"

			newLaser.x = ship.x
			newLaser.y = ship.y
			newLaser:toBack()

			laserX = shooting:getX() * 15
			laserY = shooting:getY() * 15

			newLaser:setLinearVelocity(laserX,laserY)

			newLaser.rotation = (360 - shooting.getAngle()) + 90



		end--]]

		--shoot down

		if (shooting:getDirection() == 4) then
			audio.play( fireSound )

			local newLaser = display.newImageRect( mainGroup, objectSheet, 5, 14, 40 )
			physics.addBody( newLaser, "dynamic", { isSensor=true } )
			newLaser.isBullet = true
			newLaser.myName = "laser"

			newLaser.x = ship.x
			newLaser.y = ship.y
			newLaser:toBack()

			laserX = shooting:getX() * 15
			laserY = shooting:getY() * 15

			newLaser:setLinearVelocity(laserX,laserY)

			newLaser.rotation = (360 - shooting.getAngle()) + 90

		end--]]

		--shoot left

		if (shooting:getDirection() == 3) then
			audio.play( fireSound )

			local newLaser = display.newImageRect( mainGroup, objectSheet, 5, 14, 40 )
			physics.addBody( newLaser, "dynamic", { isSensor=true } )
			newLaser.isBullet = true
			newLaser.myName = "laser"

			newLaser.x = ship.x
			newLaser.y = ship.y
			newLaser:toBack()

			laserX = shooting:getX() * 15
			laserY = shooting:getY() * 15

			newLaser:setLinearVelocity(laserX,laserY)

			newLaser.rotation = (360 - shooting.getAngle()) + 90

		end--]]

		--shoot up

		if (shooting:getDirection() == 2) then
			audio.play( fireSound )

			local newLaser = display.newImageRect( mainGroup, objectSheet, 5, 14, 40 )
			physics.addBody( newLaser, "dynamic", { isSensor=true } )
			newLaser.isBullet = true
			newLaser.myName = "laser"

			newLaser.x = ship.x
			newLaser.y = ship.y
			newLaser:toBack()

			laserX = shooting:getX() * 15
			laserY = shooting:getY() * 15

			newLaser:setLinearVelocity(laserX,laserY)

			newLaser.rotation = (360 - shooting.getAngle()) + 90

		end
		timer.performWithDelay(attackSpeed, shootTimer, 1)
	end

	function shipRotation(e)
		if (shooting.getAngle() == 0) then 
			ship.rotation = 0
		else 
			ship.rotation = (360 - shooting.getAngle()) + 90
		end
		return true
	end


	livesText = display.newText( uiGroup, "Lives: " .. lives, 200, 150, native.systemFont, 36 )
	scoreText = display.newText( uiGroup, "Score: " .. score, 400, 150, native.systemFont, 36 )
	

	explosionSound = audio.loadSound( "audio/explosion.wav" )
	fireSound = audio.loadSound( "audio/fire.wav" )
	musicTrack = audio.loadStream( "audio/gameMusic.mp3" )
	movement:activate()
	shooting:activate()
	movementTime = timer.performWithDelay( 100, catchTimer, -1 )
	timer.performWithDelay( attackSpeed, shootTimer, 1 )
	timer.performWithDelay( 1, shipRotation, -1)
end


-- show()
function scene:show( event )

	local sceneGroup = self.view
	local phase = event.phase

	if ( phase == "will" ) then

	elseif ( phase == "did" ) then

		physics.start()
		Runtime:addEventListener( "collision", onCollision )
		gameLoopTimer = timer.performWithDelay( difficultyScale, gameLoop, 1 )

		audio.play( musicTrack, { channel=1, loops=-1 } )
	end
end


-- hide()
function scene:hide( event )

	local sceneGroup = self.view
	local phase = event.phase

	if ( phase == "will" ) then

		timer.cancel( gameLoopTimer )

	elseif ( phase == "did" ) then

		Runtime:removeEventListener( "collision", onCollision )
		physics.pause()

		audio.stop( 1 )
	end
end


-- destroy()
function scene:destroy( event )

	local sceneGroup = self.view

	audio.dispose( explosionSound )
	audio.dispose( fireSound )
	audio.dispose( musicTrack )
end


scene:addEventListener( "create", scene )
scene:addEventListener( "show", scene )
scene:addEventListener( "hide", scene )
scene:addEventListener( "destroy", scene )


return scene
