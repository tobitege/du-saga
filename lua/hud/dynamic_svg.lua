function dynamicSVG()
	local umap, uround = utils.map, utils.round
	local gCache, cD = globals, cData
	local conSpd, maxSpd = 0,0
	local speedFill = 0
	local rColor, gColor, bColor = 150, 150, 150
	local curThrottle = cD.curThrottle
	local maxThrottle, throttleFill = 100, 0
	local curAlt, maxAlt = 0, 0
	local altFill = 0
	local tMode = 'Travel'
	local trgtDistance = ''

	if cD.position ~= nil and AutoPilot.target ~= nil then
		trgtDistance = printDistance((uround(vector.dist(AutoPilot.target,cD.position))), true)
	end

	if cD.constructSpeed ~= nil then
		conSpd = uround(cD.speedKph)
		if cD.inAtmo then
			maxSpd = math.ceil(uround(cD.burnSpeedKph))
		else
			maxSpd = math.ceil(uround(cD.maxSpeed*3.6))
		end
		if conSpd ~= 0 and maxSpd ~= 0 then
			speedFill = clamp(conSpd/maxSpd*200,0,200)
			rColor = uround(umap(clamp(speedFill,170,200),170,200,150,255))
			gColor = uround(umap(clamp(speedFill,170,200),170,200,150,40))
			bColor = uround(umap(clamp(speedFill,170,200),170,200,150,0))
		end
		if controlMode() == 'travel' then
			throttleFill = 200*(abs(curThrottle)/100)
		else
			if conSpd <= 1000 then
				maxThrottle = 1000
			elseif conSpd <= 5000 then
				maxThrottle = 5000
			elseif conSpd <= 10000 then
				maxThrottle = 10000
			elseif conSpd <= 20000 then
				maxThrottle = 20000
			else
				maxThrottle = 30000
			end
			curThrottle = curThrottle/100
			throttleFill = clamp(abs(curThrottle)/maxThrottle*200,0,200)
		end
		if cD.body then
			curAlt, maxAlt = getAltitude(), 200000
			if cD.body and cD.inAtmo then
				maxAlt = uround(cD.body.atmoAltitude)
				altFill = clamp(curAlt/maxAlt*200,0,200)
			elseif cD.body and cD.body.hasAtmosphere and gCache.collision ~= nil and curAlt <= maxAlt then
				altFill = clamp(((curAlt-cD.body.atmoAltitude)/maxAlt)*200,0,200)
			elseif curAlt <= maxAlt then
				altFill = clamp((curAlt/maxAlt)*200,0,200)
			end
		end
		tMode = controlMode()
	end

	local fnt = 'Bank' -- for all below svg's
	HUD.dynamicSVG = {
		targetReticle2 = [[
<svg viewBox="-77.91 -57.847 135.41 86.458">
<text style="fill: rgb(204, 204, 204); font-family:SegoeUI,sans-serif; font-size: 30px; paint-order: fill; stroke: rgb(0, 0, 0); stroke-width: 2px; white-space: pre;" transform="matrix(0.955784, 0, 0, 1.03899, -3.444869, 2.252162)" x="-77.91" y="-30.551">]]..trgtDistance..[[</text>
<path style="fill: none; stroke: rgb(204, 204, 204);" d="M -77.91 -22.808 L 0.342 -22.808 L 57.5 28.611"/>
</svg>]],
		speedBar = [[
<svg viewBox="-29 -24 72 240" >
<rect width="5" height="200" style="fill: rgb(255, 255, 255); fill-opacity: 0; paint-order: stroke; stroke: rgb(94, 94, 94);" transform="matrix(-1, 0, 0, -1, 0, 0)" x="-5" y="-200" bx:origin="0 0"/>
<rect width="5" height="]]..speedFill..[[" style="stroke: rgb(255, 0, 0); stroke-opacity: 0; fill: rgb(]]..tonumber(rColor)..[[, ]]..tonumber(gColor)..[[, ]]..tonumber(bColor)..[[);" transform="matrix(-1, 0, 0, -1, 0, 0)" x="-5" y="-200" bx:origin="0 0"/>
<text style="white-space: pre; fill: rgb(200, 200, 200); font-family:]]..fnt..[[, sans-serif; font-size:11px; paint-order: fill; stroke: rgb(0, 0, 0); stroke-width: 2px; text-anchor: middle;" x="1.4" y="-2.6" transform="matrix(1.1, 0, 0, 1, 1, 0)">]]..conSpd..[[</text>
<text style="fill: rgb(200, 200, 200); font-family:]]..fnt..[[, sans-serif; font-size: 14px; paint-order: fill; stroke: rgb(0, 0, 0); stroke-width: 2px; white-space: pre;" transform="matrix(0, -1, 1, 0, -102, 9.5)" x="-100" y="100">Speed</text>
<text style="fill: rgb(200, 200, 200); font-family:]]..fnt..[[, sans-serif; font-size: 10px; paint-order: fill; stroke: rgb(0, 0, 0); stroke-width: 1px; white-space: pre;" x="6" y="5.5">]]..maxSpd..[[</text>
</svg>]],
		throttleBar = [[
<svg viewBox="-29 -24 72 240">
<rect width="5" height="200" style="fill: rgb(255, 255, 255); fill-opacity: 0; paint-order: stroke; stroke: rgb(94, 94, 94);" transform="matrix(-1, 0, 0, -1, 0, 0)" x="-5" y="-200" bx:origin="0 0"/>
<rect width="5" height="]]..throttleFill..[[" style="stroke: rgb(255, 0, 0); stroke-opacity: 0; fill: rgb(150, 150, 150);" transform="matrix(-1, 0, 0, -1, 0, 0)" x="-5" y="-200" bx:origin="0 0"/>
<text style="white-space: pre; fill: rgb(200, 200, 200); font-family:]]..fnt..[[, sans-serif; font-size: 12px; paint-order: fill; stroke: rgb(0, 0, 0); stroke-width: 2px; text-anchor: middle;" x="1.4" y="-2.6" transform="matrix(1.1, 0, 0, 1, 1, 0)">]]..uround(curThrottle)..[[</text>
<text style="fill: rgb(200, 200, 200); font-family:]]..fnt..[[, sans-serif; font-size: 14px; paint-order: fill; stroke: rgb(0, 0, 0); stroke-width: 2px; white-space: pre;" transform="matrix(0, -1, 1, 0, -102, 9.5)" x="-100" y="100">]]..tMode..[[</text>
<text style="fill: rgb(200, 200, 200); font-family:]]..fnt..[[, sans-serif; font-size: 10px; paint-order: fill; stroke: rgb(0, 0, 0); stroke-width: 1px; white-space: pre;" x="6" y="5.5">]]..maxThrottle..[[</text>
</svg>]],
		altitudeBar = [[
<svg viewBox="-29 -24 90 240">
<rect width="5" height="200" style="fill: rgb(255, 255, 255); fill-opacity: 0; paint-order: stroke; stroke: rgb(94, 94, 94);" transform="matrix(-1, 0, 0, -1, 0, 0)" x="-5" y="-200" bx:origin="0 0"/>
<rect width="5" height="]]..altFill..[[" style="stroke: rgb(255, 0, 0); stroke-opacity: 0; fill: rgb(150, 150, 150);" transform="matrix(-1, 0, 0, -1, 0, 0)" x="-5" y="-200" bx:origin="0 0"/>
<text style="white-space: pre; fill: rgb(200, 200, 200); font-family:]]..fnt..[[, sans-serif; font-size: 12px; paint-order: fill; stroke: rgb(0, 0, 0); stroke-width: 2px; text-anchor: middle;" x="8" y="-2.6" transform="matrix(1.1, 0, 0, 1, 1, 0)">]]..curAlt..[[</text>
<text style="fill: rgb(200, 200, 200); font-family:]]..fnt..[[, sans-serif; font-size: 14px; paint-order: fill; stroke: rgb(0, 0, 0); stroke-width: 2px; white-space: pre;" transform="matrix(0, -1, 1, 0, -102, 9.5)" x="-100" y="100">Altitude</text>
<text style="fill: rgb(200, 200, 200); font-family:]]..fnt..[[, sans-serif; font-size: 10px; paint-order: fill; stroke: rgb(0, 0, 0); stroke-width: 1px; white-space: pre;" x="8" y="8.5">]]..maxAlt..[[</text>
</svg>]]
	}
end