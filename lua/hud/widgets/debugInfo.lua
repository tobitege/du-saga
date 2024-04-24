Widgets.debugInfo = Widget:new{class='debugInfo'}
function Widgets.debugInfo:build()
	local s, ts, rnd = {}, tostring, round2
	gC, cD, agD, ap = globals, cData, aggData, AutoPilot
s[#s+1] = 'DEBUG'
s[#s+1] = 'Last Dist = '..ts(gC.lastProjectedDistance)
s[#s+1] = 'Proj Dist = '..ts(projectedDistance(ap.target))
s[#s+1] = 'T Dist = '..ts(vector.dist(ap.target,cD.position))
s[#s+1] = ''
s[#s+1] = 'Target Loc = '..ts(ap.targetLoc)
s[#s+1] = 'Target Alt = '..ts(ap.targetAltitude)
s[#s+1] = 'Target Atmo = '..ts(rnd(ap.targetBody.atmoRadius - ap.targetBody.radius,2))
s[#s+1] = 'Target Angle = ' .. getTargetAngle()
s[#s+1] = 'Aim Target = ' .. gC.aimTarget
s[#s+1] = 'SpcVector = '..ts(spcVector)
s[#s+1] = 'AP Mode = '..ts(gC.apMode)
s[#s+1] = 'BrakeCtrl = '..ts(brakeCtrl)
s[#s+1] = 'SpeedCtrl =' ..ts(SpdControl)
s[#s+1] = 'Brake Trig = '..ts(gC.brakeTrigger)
s[#s+1] = ''
s[#s+1] = 'TAV.x = ' ..ts(targetAngularVelocity.x)
s[#s+1] = 'TAV.y = ' ..ts(targetAngularVelocity.y)
s[#s+1] = 'TAV.z = ' ..ts(targetAngularVelocity.z)
s[#s+1] = 'up = ' ..ts(inputs.up)
s[#s+1] = 'down = ' ..ts(inputs.down)
s[#s+1] = 'left = ' ..ts(inputs.left)
s[#s+1] = 'right = ' ..ts(inputs.right)
s[#s+1] = ''
s[#s+1] = 'Samebody = '..ts(sameBody)
s[#s+1] = 'Vel World Angle = ' .. getVelocityWorldAngle()
s[#s+1] = 'Vel to T Angle = ' .. getVelocityTargetAngle()
s[#s+1] = 'Spc to T Angle = ' .. getSpaceVelocityTargetAngle()
s[#s+1] = 'World T Angle = ' .. getTargetWorldAngle()
s[#s+1] = 'Target Altitude = '..ts(gC.holdAltitude)
s[#s+1] = ''
s[#s+1] = 'Atmo (%) = ' .. rnd(cD.atmoDensity*100,2)
s[#s+1] = 'Target Pitch = '..ts(rnd(gC.targetPitch))
s[#s+1] = 'Speed = '..ts(rnd(cD.constructSpeed), 0.01)
s[#s+1] = 'Max S = '..ts(rnd(cD.maxSpeed * 3.6), 0.01)
s[#s+1] = 'Vert Speed = '..ts(rnd(cD.vertSpeed), 0.01)
s[#s+1] = 'Forward Speed = '..ts(rnd(cD.forwardSpeed), 0.01)
s[#s+1] = 'Lateral Speed = '..ts(rnd(cD.lateralSpeed), 0.01)
s[#s+1] = ''
s[#s+1] = 'Burn Spd = '..ts(rnd(cD.burnSpeed * 3.6))
s[#s+1] = ''
s[#s+1] = 'Gravity = '..ts(rnd(cD.G,2))
s[#s+1] = 'Altitude = '..ts(rnd(cD.altitude,2))
s[#s+1] = 'ClosestBody = '..ts(cD.body.name)
s[#s+1] = 'TargetBody = '..ts(ap.targetBody.name)
s[#s+1] = 'Atmo Top = '..ts(rnd(cD.body.atmoRadius-cD.body.radius,2))
s[#s+1] = ''
s[#s+1] = 'Orbit Speed = '..ts(rnd(cD.orbitFocus.orbitSpeed * 3.6,2))
s[#s+1] = 'Target Orbit = '..ts(rnd(gC.targetOrbitAlt,2))
s[#s+1] = 'Orbit Status = '..ts(gC.inOrbit)
s[#s+1] = 'Apoapsis = '..ts(cD.orbitalParameters.apoapsis.altitude)
s[#s+1] = 'Periapsis = '..ts(cD.orbitalParameters.periapsis.altitude)
s[#s+1] = 'T to Periapsis = '..ts(cD.orbitalParameters.timeToPeriapsis)
s[#s+1] = 'T to Apoapsis = '..ts(cD.orbitalParameters.timeToApoapsis)
s[#s+1] = 'Hold = '..tonumber(orbitHold())
s[#s+1] = ''
s[#s+1] = 'Agg Alt = '..ts(agD.aggAltitude)
s[#s+1] = 'Agg Target = '..ts(agD.aggTarget)
s[#s+1] = 'Agg Str = '..ts(agD.aggStrength)

	self.rowCount = #s
	return table.concat(s, '<br>')
end