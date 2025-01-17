--[==[
    Utility functions for example block game
    Copyright (C) 2021 Lilla Oshisaure

    This program is free software: you can redistribute it and/or modify
    it under the terms of the GNU Affero General Public License as published
    by the Free Software Foundation, either version 3 of the License, or
    (at your option) any later version.

    This program is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
    GNU Affero General Public License for more details.

    You should have received a copy of the GNU Affero General Public License
    along with this program.  If not, see <https://www.gnu.org/licenses/>.
]==]

function NADA() end

function Deepcopy(orig)
    local orig_type = type(orig)
    local copy
    if orig_type == 'table' then
        copy = {}
        for orig_key, orig_value in next, orig, nil do
            copy[Deepcopy(orig_key)] = Deepcopy(orig_value)
        end
        setmetatable(copy, Deepcopy(getmetatable(orig)))
    else -- number, string, boolean, etc
        copy = orig
    end
    return copy
end

function HSA(h, s, a)
	-- find a colour from hue and saturation
	h = (h%360)/60
	local i, f, g, t
	i, f = math.modf(h)
	g = 1-f -- for descending gradients
	t = 1-s -- min colour intensity based on saturation
	f, g = s*f+t, s*g+t -- apply saturation to the gradient values
		if i == 0 then return {1, f, t, a}
	elseif i == 1 then return {g, 1, t, a}
	elseif i == 2 then return {t, 1, f, a}
	elseif i == 3 then return {t, g, 1, a}
	elseif i == 4 then return {f, t, 1, a}
	elseif i == 5 then return {1, t, g, a}
	else return {1, 1, 1, a}
	end
end

function HSVA(h, s, v, a)
	-- apply value to the hue/saturation colour
	local c = HSA(h, s, a or 1)
	for i = 1, 3 do c[i] = c[i]*v end
	return c
end

function CheckKeyInput(input)
	return input and love.keyboard.isDown(input)
end

function CheckPadInput(pad, input)
    if input == "<none>" or not pad or not pad:isGamepad() then return false end
    local dz = tonumber(Config.pad_deadzone)/100
	local lastchr = input:sub(-1,-1)
	if lastchr == "+" then
		-- bound to axis up
		return  pad:getGamepadAxis(input:sub(1, -2)) >= dz
	elseif lastchr == "-" then
		-- bound to axis down
		return -pad:getGamepadAxis(input:sub(1, -2)) >= dz
	else
		-- bound to button
		return  pad:isGamepadDown(input)
	end
end

function FormatTime(s)
    local sec, cen = math.modf(math.max(0,s))
    local sec, min = sec % 60, math.floor(sec/60)
    return string.format("%02d\'%02d\"%02d", min, sec, math.floor(cen*100))
end

function nBool(b) return b and 1 or 0 end

function AvgArrays(base, ...)
	local arg = {...}
	local a = Deepcopy(base)
	for n, arr in ipairs(arg) do
		for k, v in pairs(arr) do
			a[k] = a[k] + v
		end
	end
	for k, v in pairs(a) do
		a[k] = v/(#arg + 1)
	end
	return a
end

function Interpolate(fun, t, min, max)
	if not (min and max) then min, max = 0, 1 end
	t = (t-min)/(max-min)
	return fun(t)
end

function SwayFormula(t)
	local amplitude = tonumber(Config.sway_amplitude)/18
	local resttime = 1/tonumber(Config.sway_speed)
	local bounciness = tonumber(Config.sway_bounciness)
	return amplitude * math.exp(-0.5/resttime*t) * math.cos(0.5/resttime*t*(bounciness*bounciness-1)^0.5)
end

local e = math.log(2, 20)
local c = 2^(-1-math.log(3, 20))
-- These values were worked out so that the formula below is in the form F(x) = c*x^e with F(60) = 1 and F(1200) = 2
-- 60 rows/second being softdrop speed and 1200 rows/second being the speed cap on the input (20G with 1G = 1 row/frame@60FPS)
-- Note to future me: don't question them. I worked them out so they work.
function ImpactFormula(speed) return c*speed^e end

function SetBGM(id)
    for k, t in pairs(BGM) do
        if k == id then
            t:play()
        else
            t:stop()
        end
    end
end

function SetBGMVolume(v)
    for k, t in pairs(BGM) do
        if k == 4 then
            t:setVolume(v*0.6)
        else
            t:setVolume(v)
        end
    end
end

function UpdateShadersUniforms(dt)
    local time = os.clock()
    pcall(function() ShaderRainbow:send("time", time) end)
    for _, v in pairs(ShaderBG) do
        pcall(function() v:send("time", time) end)
        pcall(function() v:send("dt", dt)     end)
    end
end

local buffercanvas = love.graphics.newCanvas()
function DrawBlurred(drawable, ...)
    local _c = love.graphics.getCanvas()
    local r, g, b, a = love.graphics.getColor()
    love.graphics.setCanvas(buffercanvas)
    love.graphics.clear(0,0,0,1)
    
    love.graphics.setShader(ShaderBlur)
    love.graphics.setBlendMode("add")
    ShaderBlur:send("Spread", 10)
    ShaderBlur:send("Direction", {0,1})
    love.graphics.draw(drawable, ...)
    
    love.graphics.setCanvas(_c)
    love.graphics.setColor(1,1,1,1)
    ShaderBlur:send("Direction", {1,0})
    love.graphics.push()
    love.graphics.origin()
    love.graphics.draw(buffercanvas)
    
    love.graphics.pop()
    love.graphics.setShader()
    love.graphics.setBlendMode("alpha")
    love.graphics.setColor(r, g, b, a)
end

function RenderBGShader(id)
    id = id or "menu"
    
    local _c = love.graphics.getCanvas()
    local r, g, b, a = love.graphics.getColor()
    love.graphics.push()
    love.graphics.origin()
    
    love.graphics.setCanvas(CanvasBGprev)
    love.graphics.setShader(ShaderBG[id])
    love.graphics.draw(CanvasBG)
    love.graphics.setShader()
    love.graphics.setCanvas(CanvasBG)
    love.graphics.draw(CanvasBGprev)
    
    love.graphics.pop()
    love.graphics.setCanvas(_c)
    love.graphics.setColor(r, g, b, a)
end