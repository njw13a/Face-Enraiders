local Joystick = {}

function Joystick.new( innerRadius, outerRadius )
    local stage = display.getCurrentStage()
    
    local joyGroup = display.newGroup()
    
    local bgJoystick = display.newCircle( joyGroup, 0,0, outerRadius )
    bgJoystick:setFillColor( .2,.2,.2 )
    bgJoystick.alpha = .5
    
    local posX = 0
    local posY = 0

    local radToDeg = 180/math.pi
    local degToRad = math.pi/180
    local joystick = display.newCircle( joyGroup, 0,0, innerRadius )
    joystick:setFillColor( .8,.8,.8 )
    joystick.alpha = .5

    -- for easy reference later:
    joyGroup.joystick = joystick
    
    -- where should joystick motion be stopped?
    local stopRadius = outerRadius - innerRadius
    
    -- return a direction identifier, angle, distance
    local directionId = 0
    local angle = 0
    local distance = 0
    function joyGroup.getX()
        return joystick.x
    end
    function joyGroup.getY()
        return joystick.y
    end
    function joyGroup.getDirection()
    	return directionId
    end
    function joyGroup:getAngle()
    	return angle
    end
    function joyGroup:getDistance()
    	return distance/stopRadius
    end
    
    function joystick:touch(event)
        local phase = event.phase
        if( (phase=='began') or (phase=="moved") ) then
        	if( phase == 'began' ) then
            	stage:setFocus(event.target, event.id)
            end
            local parent = self.parent
            posX, posY = parent:contentToLocal(event.x, event.y)
            angle = (math.atan2( posX, posY )*radToDeg)-90
            if( angle < 0 ) then
            	angle = 360 + angle
            end

			-- could expand to include more directions (e.g. 45-deg)
			if( (angle>=45) and (angle<135) ) then
				directionId = 2
			elseif( (angle>=135) and (angle<225) ) then
				directionId = 3
			elseif( (angle>=225) and (angle<315) ) then
				directionId = 4
			else
				directionId = 1
			end
			
			-- could emit "direction" events here
			--Runtime:dispatchEvent( {name='direction',directionId=directionId } )
            
            distance = math.sqrt((posX*posX)+(posY*posY))
            
            if( distance >= stopRadius ) then
                distance = stopRadius
                local radAngle = angle*degToRad
                self.x = distance*math.cos(radAngle)
                self.y = -distance*math.sin(radAngle)
            else
                self.x = posX
                self.y = posY
            end
            
        else
            self.x = 0
			self.y = 0
            stage:setFocus(nil, event.id)
            
            directionId = 0
            angle = 0
            distance = 0
        end
        return true
    end
    
    function joyGroup:activate()
        self:addEventListener("touch", self.joystick )
        self.directionId = 0
        self.angle = 0
        self.distance = 0
    end
    function joyGroup:deactivate()
        self:removeEventListener("touch", self.joystick )
        self.directionId = 0
        self.angle = 0
        self.distance = 0
    end

    return( joyGroup )
end

return Joystick


-- sample main.lua code:
--local jslib = require( "simpleJoystick" )
--
--local js = jslib.new( 100, 200 )
--js.x = display.contentWidth/2
--js.y = display.contentHeight/2
--
--function catchTimer( e )
--	print( "  joystick info: "
--		.. " dir=" .. js:getDirection()
--		.. " angle=" .. js:getAngle()
--		.. " dist="..js:getDistance() )
--	return true
--end
--
--js:activate()
--timer.performWithDelay( 500, catchTimer, -1 )