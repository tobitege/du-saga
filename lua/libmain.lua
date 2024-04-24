ship = {}

abs, atan, rad, floor, format, sub, acos, sqrt = math.abs, math.atan, math.rad, math.floor, string.format, string.sub, math.acos, math.sqrt
cos, sin, deg, ceil, max, clamp, sign, round = math.cos, math.sin, math.deg, math.ceil, math.max, utils.clamp, utils.sign, utils.round

function round2(num, numDecimalPlaces)
    -- Basic error handling
    if type(num) ~= "number" then
        P"round2: The first argument (num) must be a number."
        error("The first argument (num) must be a number.")
    end
    if numDecimalPlaces and (type(numDecimalPlaces) ~= "number" or numDecimalPlaces < 0) then
        error("The second argument (numDecimalPlaces) must be a non-negative number.")
    end
    local mult = 10^(numDecimalPlaces or 0)
    if num >= 0 then
        return floor(num * mult + 0.5) / mult
    end
    return ceil(num * mult - 0.5) / mult
end
require('dkjson')

require('events/keyboard')
require('events/system_flush')
require('events/system_input')
require('events/system_update')
require('events/timer_apu')
require('events/timer_fuel')
require('events/unit_start')
require('behaviour/kinematics')
require('behaviour/autopilot')
require('behaviour/electronics')
require('behaviour/ship_maneuver')
require('behaviour/ship')
require('data/aggData')
require('data/config')
require('data/configDatabankMap')
require('data/coroutine')
require('data/constructData')
require('data/eventSystem')
require('data/playerData')
require('data/radar')
require('data/routeDatabase')
require('data/tankData')
require('data/warpData')

require('helpers/common')
require('helpers/solar_system')
require('helpers/table')
require('helpers/vector_math')

require('hud/hud')

require('lib/serialize')
require('lib/SVG')