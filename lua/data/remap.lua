 function remapBeforeInit()
    tonumber = _G['tonumber']
    tostring = _G['tostring']
    type = _G['type']

    table = _G['table']
    table.concat = table['concat']
    table.insert = table['insert']
    table.remove = table['remove']
    table.sort = table['sort']

    math = _G['math']
    math.max = math['max']
    math.min = math['min']
    math.abs = math['abs']
    math.sin = math['sin']
    math.cos = math['cos']
    math.tan = math['tan']
    math.asin = math['asin']
    math.acos = math['acos']
    math.atan = math['atan']
    math.atan2 = math['atan2']
    math.ceil = math['ceil']
    math.floor = math['floor']
    math.exp = math['exp']
    math.fmod = math['fmod']
    math.deg = math['deg']
    math.rad = math['rad']
    math.huge = math['huge']
    math.log = math['log']
    math.pi = math['pi']
    math.pow = math['pow']
    math.random = math['random']
    math.sqrt = math['sqrt']

    utils = _G['utils']
    utils.round = utils['round']
    utils.sign = utils['sign']
    utils.clamp = utils['clamp']
    utils.smoothstep = utils['smoothstep']
    utils.map = utils['map']

    if constants == nil then
        constants = {}
        constants.epsilon = _G['constants']['epsilon']
        constants.rad2deg = _G['constants']['rad2deg']
        constants.deg2rad = _G['constants']['deg2rad']
    end

    axisCommandId = _G['axisCommandId']
    axisCommandId.longitudinal = axisCommandId['longitudinal']
    axisCommandId.lateral = axisCommandId['lateral']
    axisCommandId.vertical = axisCommandId['vertical']

    axisCommands = 'axisCommands'

    axisCommandType = _G['axisCommandType']
    axisCommandType.byTargetSpeed = axisCommandType['byTargetSpeed']
    axisCommandType.byThrottle = axisCommandType['byThrottle']

    player.getWorldPosition = player['getWorldPosition']
    player.isSeated = player['isSeated']
    player.isFrozen = player['isFrozen']
    player.freeze = player['freeze']
    player.getWorldVelocity = player['getWorldVelocity']

    system.print = system['print']
    system.playSound = system['playSound']
    system.stopSound = system['stopSound']
    system.isPlayingSound = system['isPlayingSound']
    system.showHelper = system['showHelper']
    system.createWidget = system['createWidget']
    system.createWidgetPanel = system['createWidgetPanel']
    system.createData = system['createData']
    system.updateData = system['updateData']
    system.addDataToWidget = system['addDataToWidget']
    system.removeDataFromWidget = system['removeDataFromWidget']
    system.destroyWidget = system['destroyWidget']
    system.destroyWidgetPanel = system['destroyWidgetPanel']
    system.getControlDeviceForwardInput = system['getControlDeviceForwardInput']
    system.getControlDeviceYawInput = system['getControlDeviceYawInput']
    system.getControlDeviceLeftRightInput = system['getControlDeviceLeftRightInput']
    system.getArkTime = system['getArkTime']
    system.getActionKeyName = system['getActionKeyName']
    system.getMouseWheel = system['getMouseWheel']
    system.getMouseDeltaX = system['getMouseDeltaX']
    system.getMouseDeltaY = system['getMouseDeltaY']
    system.getMousePosX = system['getMousePosX']
    system.getMousePosY = system['getMousePosY']
    system.getScreenWidth = system['getScreenWidth']
    system.getScreenHeight = system['getScreenHeight']
    system.getThrottleInputFromMouseWheel = system['getThrottleInputFromMouseWheel']
    system.showScreen = system['showScreen']
    system.setScreen = system['setScreen']
    system.lockView = system['lockView']
    system.freeze = system['freeze']
    system.setWaypoint = system['setWaypoint']
    system.getCameraWorldForward = system['getCameraWorldForward']

    library.getPointOnScreen = library['getPointOnScreen']

    Navigator = _G['Navigator']
    Navigator.toggleBoosters = Navigator['toggleBoosters']
    Navigator.update = Navigator['update']
    Navigator.setEngineTorqueCommand = Navigator['setEngineTorqueCommand']
    Navigator.setEngineForceCommand = Navigator['setEngineForceCommand']
    Navigator.setBoosterCommand = Navigator['setBoosterCommand']
    Navigator.control = unit
    unit.isRemoteControlled = unit['isRemoteControlled']
    unit.isAnyLandingGearExtended = unit['isAnyLandingGearExtended']
    unit.deployLandingGears = unit['deployLandingGears']
    unit.retractLandingGears = unit['retractLandingGears']
    unit.isAnyHeadlightSwitchedOn = unit['isAnyHeadlightSwitchedOn']
    unit.switchOnHeadlights = unit['switchOnHeadlights']
    unit.switchOffHeadlights = unit['switchOffHeadlights']
    unit.getControlMode = unit['getControlMode']
    unit.cancelCurrentControlMasterMode = unit['cancelCurrentControlMasterMode']
    unit.getAtmosphereDensity = unit['getAtmosphereDensity']
    unit.getWidgetData = unit['getWidgetData']
    unit.setEngineThrust = unit['setEngineThrust']
    unit.getThrottle = unit['getThrottle']
    unit.setTimer = unit['setTimer']
    unit.hideWidget = unit['hideWidget']
    unit.showWidget = unit['showWidget']
    unit.setAxisCommandValue = unit['setAxisCommandValue']

    AxisCommandManager = _G['AxisCommandManager']
    AxisCommandManager.activateGroundEngineAltitudeStabilization = AxisCommandManager['activateGroundEngineAltitudeStabilization']
    AxisCommandManager.deactivateGroundEngineAltitudeStabilization = AxisCommandManager['deactivateGroundEngineAltitudeStabilization']
    AxisCommandManager.updateTargetGroundAltitudeFromActionStart = AxisCommandManager['updateTargetGroundAltitudeFromActionStart']
    AxisCommandManager.updateTargetGroundAltitudeFromActionLoop = AxisCommandManager['updateTargetGroundAltitudeFromActionLoop']
    AxisCommandManager.setupCustomTargetSpeedRanges = AxisCommandManager['setupCustomTargetSpeedRanges']
    AxisCommandManager.getTargetSpeed = AxisCommandManager['getTargetSpeed']
    AxisCommandManager.setTargetGroundAltitude = AxisCommandManager['setTargetGroundAltitude']
    AxisCommandManager.getTargetGroundAltitude = AxisCommandManager['getTargetGroundAltitude']
    AxisCommandManager.getAxisCommandType = AxisCommandManager['getAxisCommandType']
    AxisCommandManager.composeAxisAccelerationFromTargetSpeed = AxisCommandManager['composeAxisAccelerationFromTargetSpeed']
    AxisCommandManager.composeAxisAccelerationFromThrottle = AxisCommandManager['composeAxisAccelerationFromThrottle']
    AxisCommandManager.getCurrentToTargetDeltaSpeed = AxisCommandManager['getCurrentToTargetDeltaSpeed']
    AxisCommandManager.getTargetSpeedCurrentStep = AxisCommandManager['getTargetSpeedCurrentStep']
    AxisCommandManager.updateCommandFromActionStart = AxisCommandManager['updateCommandFromActionStart']
    AxisCommandManager.updateCommandFromActionLoop = AxisCommandManager['updateCommandFromActionLoop']
    AxisCommandManager.updateCommandFromActionStop = AxisCommandManager['updateCommandFromActionStop']
    AxisCommandManager.setTargetSpeedCommand = AxisCommandManager['setTargetSpeedCommand']
    AxisCommandManager.setThrottleCommand = AxisCommandManager['setThrottleCommand']
    AxisCommandManager.getThrottleCommand = AxisCommandManager['getThrottleCommand']
    AxisCommandManager.resetCommand = AxisCommandManager['resetCommand']

end

function remapAfterInit()
	construct.getName = construct['getName']
	construct.getWorldPosition = construct['getWorldPosition']
    
    construct.getForward = construct['getForward']
    construct.getUp = construct['getUp']
    construct.getRight = construct['getRight']

    construct.getWorldForward = construct['getWorldForward']
    construct.getWorldUp = construct['getWorldUp']
    construct.getWorldRight = construct['getWorldRight']

    construct.getMaxThrustAlongAxis = construct['getMaxThrustAlongAxis']

	construct.getWorldAngularVelocity = construct['getWorldAngularVelocity']
	construct.getWorldVelocity = construct['getWorldVelocity']
	construct.getWorldAirFrictionAngularAcceleration = construct['getWorldAirFrictionAngularAcceleration']
	construct.getFrictionBurnSpeed = construct['getFrictionBurnSpeed']
	construct.getWorldAcceleration = construct['getWorldAcceleration']
	construct.getVelocity = construct['getVelocity']
	construct.getMaxBrake = construct['getMaxBrake']
	construct.getCurrentBrake = construct['getCurrentBrake']
	construct.getMaxSpeed = construct['getMaxSpeed']
	construct.getMass = construct['getMass']
    construct.getTotalMass = construct['getTotalMass']
	construct.getPvPTimer = construct['getPvPTimer']
	construct.isInPvPZone = construct['isInPvPZone']

	links.core.getWorldVertical = links.core['getWorldVertical']
	links.core.getAltitude = links.core['getAltitude']
	links.core.getElementNameById = links.core['getElementNameById']
    links.core.getElementDisplayNameById = links.core['getElementDisplayNameById']
	links.core.getElementTypeById = links.core['getElementTypeById']
	links.core.getElementMassById = links.core['getElementMassById']
	links.core.getElementMaxHitPointsById = links.core['getElementMaxHitPointsById']
	links.core.getElementIdList = links.core['getElementIdList']
    links.core.getGravityIntensity = links.core['getGravityIntensity']
    links.core.getCoreStress = links.core['getCoreStress']
    links.core.getCoreStressRatio = links.core['getCoreStressRatio']
    links.core.getMaxCoreStress = links.core['getMaxCoreStress']
	links.core.g = links.core['g']


    if links.shield ~= nil then
        links.shield.isActive = links.shield['isActive']
        links.shield.getShieldHitpoints = links.shield['getShieldHitpoints']
        links.shield.getMaxShieldHitpoints = links.shield['getMaxShieldHitpoints']
        links.shield.startVenting = links.shield['startVenting']
        links.shield.stopVenting = links.shield['stopVenting']
        links.shield.isVenting = links.shield['isVenting']
        links.shield.getVentingCooldown = links.shield['getVentingCooldown']
        links.shield.getVentingMaxCooldown = links.shield['getVentingMaxCooldown']
        links.shield.getResistances = links.shield['getResistances']
        links.shield.setResistances = links.shield['setResistances']
        links.shield.getResistancesCooldown = links.shield['getResistancesCooldown']
        links.shield.getResistancesMaxCooldown = links.shield['getResistancesMaxCooldown']
        links.shield.getResistancesPool = links.shield['getResistancesPool']
        links.shield.getResistancesRemaining = links.shield['getResistancesRemaining']
        links.shield.getStressRatio = links.shield['getStressRatio']
        links.shield.getStressRatioRaw = links.shield['getStressRatioRaw']
        links.shield.getStressHitpoints = links.shield['getStressHitpoints']
        links.shield.getStressHitpointsRaw = links.shield['getStressHitpointsRaw']
    end

    if links.antigrav ~= nil then
        links.antigrav.activate = links.antigrav['activate']
        links.antigrav.deactivate = links.antigrav['deactivate']
        links.antigrav.toggle = links.antigrav['toggle']
        links.antigrav.getBaseAltitude = links.antigrav['getBaseAltitude']
        links.antigrav.getTargetAltitude = links.antigrav['getTargetAltitude']
        links.antigrav.setTargetAltitude = links.antigrav['setTargetAltitude']
        links.antigrav.getFieldStrength = links.antigrav['getFieldStrength']
        links.antigrav.getFieldPower = links.antigrav['getFieldPower']
        links.antigrav.getPulsorCount = links.antigrav['getPulsorCount']
        links.antigrav.getCompensationRate = links.antigrav['getCompensationRate']
        links.antigrav.isActive = links.antigrav['isActive']
    end

    if links.warpdrive ~= nil then
        links.warpdrive.activateWarp = links.warpdrive['activateWarp']
        links.warpdrive.getStatus = links.warpdrive['getStatus']
        links.warpdrive.getDistance = links.warpdrive['getDistance']
        links.warpdrive.getDestinationName = links.warpdrive['getDestinationName']
        links.warpdrive.getAvailableWarpCells = links.warpdrive['getAvailableWarpCells']
        links.warpdrive.getRequiredWarpCells = links.warpdrive['getRequiredWarpCells']
    end

    if links.databanks ~= nil then
        for i,databank in ipairs(links.databanks) do
            databank.clear = databank['clear']
            databank.clearValue = databank['clearValue']
            databank.getNbKeys = databank['getNbKeys']
            databank.hasKey = databank['hasKey']
            databank.getKeyList = databank['getKeyList']
            databank.setStringValue = databank['setStringValue']
            databank.getStringValue = databank['getStringValue']
            databank.setIntValue = databank['setIntValue']
            databank.getIntValue = databank['getIntValue']
            databank.setFloatValue = databank['setFloatValue']
            databank.getFloatValue = databank['getFloatValue']
        end
    end

    if links.radars ~= nil then
        for i,radar in ipairs(links.radars) do
            radar.getOperationalState = radar['getOperationalState']
            radar.getWidgetDataId = radar['getWidgetDataId']
            radar.getRange = radar['getRange']
            radar.getIdentifyRanges = radar['getIdentifyRanges']
            radar.getConstructIds = radar['getConstructIds']
            radar.getIdentifiedConstructIds = radar['getIdentifiedConstructIds']
            radar.getSortMethod = radar['getSortMethod']
            radar.setSortMethod = radar['setSortMethod']
            radar.getTargetId = radar['getTargetId']
            radar.getConstructCoreSize = radar['getConstructCoreSize']
            radar.getConstructDistance = radar['getConstructDistance']
            radar.isConstructAbandoned = radar['isConstructAbandoned']
            radar.getThreatRateFrom = radar['getThreatRateFrom']
            radar.hasMatchingTransponder = radar['hasMatchingTransponder']
            radar.getConstructName = radar['getConstructName']
            radar.getConstructSize = radar['getConstructSize']
            radar.getConstructKind = radar['getConstructKind']
            radar.getConstructs = radar['getConstructs']
        end
    end

    --links.engine.getThrust = links.engine['getThrust']

    Nav.axisCommandManager = Nav['axisCommandManager']
end