# Saga 4.1-beta

## Latest update: 4.1.6.1 - 2025-08-28

- Add the possibility to load a custom atlas. Thanks to @leniver !
Cherry-picked from: https://github.com/The-Third-Verse/SagaHUD/commit/37a4d3518d247b2e7162ee18f57be38a2b8569a6

## Introduction

This is customized version of the lua-based flight script for the game Dual Universe
called *Saga* by Sagacious and others.

Base version was "4.0 Alpha", the last official release made available by the author(s).
Additional code (for VTOL'ing) is from ShadowTemplar's Horizon flight system.

Big thanks to Wolfe Labs (Matt) for the awesome tool [DU-LuaC](https://github.com/wolfe-labs/DU-LuaC)
this project uses to package all source files into a "ready-to-install" JSON file for DU.

A ready-to-install version is in the "out\release" folder (Saga.json)!
The "development" folder contains the full-size (uncompressed) code and is not usable due to its size!  
Only the Saga.json file in the "**out\release**" sub-folder works!  
This version should also work on GFN as it does not require any 3rd party files.  

Join the [DU Open Source Initiative](https://discord.gg/jJdutszhB5) Discord server for support and feedback,
where a channel for "saga-autopilot" exists, where I may be able to assist.  

Find the SETUP section at the end of this documentation!

## Changes

- Added new "**Maneuver**" mode (toggle: *ALT+9*) especially aimed at VTOL-capable constructs ("platformers"), like "AWP", "vSpeeder", "Bug" etc.  
It generally works for any ship, depending on pilot's talents and installed ground engines,
such as hover engines and/or vertical boosters.  
By design it automatically holds the current altitude unless changed by user input (up/down),
prohibits roll and pitch (always levels out) and does **NOT** automatically follow
terrain like a standard DU hovercraft/speeder!

- See further down below for added new chat commands

- The normal flight mode is now named "Standard" and should behave just like the original.

- Added a new, **dynamic landing mode** which works both in atmosphere as well as in
near-body space to e.g. land on below space station (when manually triggered by G key).  
Warning: it has only been tested on space stations where a planetary body with gravity was
nearby that defines the perpendicular orientation of the construct!
If used outside any gravity well, manual piloting is required to land the ship.

  *Note:* landing will always (except when Autopilot is active) temporarily switch to *landing* mode,
  which basically is the Maneuver mode with special height management.
  If landing was initiated with Standard flight mode, it will return to that mode once landed.  
Notice: having landed via a remote controller will automatically turn off the remote.

  If an antigravity-generator (AGG) is active *and* its base altitude is below the current altitude, it will try to *land* down into the AGG's altitude.  
  Note: the AGG should **not** be made to move its target altitude during this time!

- Added a **docking widget** toggle /dock as chat command to allow to visually set the preferred **docking mode**.

- Added a '*/dockingMode x*' chat command to specifiy the preferred **docking mode** (1,2 or 3).

- More options are now stored within the databank, like the last set flight mode,
a changed default hover height or the last set docking mode.  
See also the "Edit LUA parameters" menu in game.

- With the HUD's main menu open, the cursor keys will no longer move the ship!

- Some settings' status in the top HUD widgets are now colored,
e.g. green for enabled/on or orange for disabled/off/inactive.

- New hotkeys ALT+6 and ALT+7 to select previous or next route. A currently selected
route's name or any other target is now being displayed in the top info widget.

- New hotkeys ALT++Shit+6 to activate the "Base" and ALT+Shift+7 to set
the current as the Base location. Also added accompanying chat commands "/setbase" and "/clearbase"

- Added more user input validations for chat parameters when numbers are involved.

- The original "core stress" info bar at the top is now hidden by default and can
be toggled via the "/core" command in LUA chat. This was a performance drain as
it was called with every frame, even inside safe zone/atmo.

- For more precise landing, the newly added **/agl** chat command allows to
specify the "*above ground level*" distance when landed to compensate for the
ground detection element's distance (which is usually not at the flat bottom of the ship).  

  When landed, notice the "**Ground**" value in the 2nd top-left info widget.
If it shows a value greater 0, use that value with this command in LUA chat,
e.g. "**/agl 1.23**" to specify 1.23 meters as vertical offset.  
From then on the "Ground" value should display 0.
This command can be repeated at any time for further adjustments.

- Exceptions to this are the new landing mode and that it will no longer automatically
change AGG altitude during Autopilot!
Back in beta, when AGG's were for some time "bugged" and allowed super fast
altitude changes, this might have worked. But piloting in/out of atmosphere happens
way too fast now for AGG's to keep up with ships' altitude changes.

- It is **highly recommended to link a telemeter** to the chair/remote so that
the ground detection range basically more than doubles to **100m**, compared
to max. ~40-45 meters (depending on talents even less!) with just hovers/boosters.  

- Cosmetic changes: moved Parking Mode/Brake text hints up; moved altitude/speed bars
a little further apart; added brake, brake lock indicators as well as "Moving"
and "Vertical" notifications during Maneuver flight operations.

- Warp info widget slightly changed, added some status colors.

- Fixed */goto* command which tried to fix 0/planet center altitude (if ::pos was copied from Map),
but assigned it to the wrong variable instead of the AP's target altitude.

- Fixed display of AGG status.

- Fixed status display of "Burn protection": it was previously only shown
as true if it was actually safety throttling, which was misleading.

- To make room for new code, I had to decide to remove some minor features. (*sadtrombone*)  
Things like sounds support, the "/debug" command and its display, the extra help screen,
the AR planets/moons dispay as well as the safe-zone "skull" displays are now gone.  
Sorry, not sorry.

- Several performance improvements and code-reduction measures.

## Maneuver mode

- This mode works both in atmosphere as well as in space, like to traverse across space stations.
- Maneuver mode does NOT allow to Autopilot via routes!
This is on the todo-list to e.g. allow for routes across mining tiles like
YFS flight script allows (by Yoari of SVEA).

- **Automatic landing** (hotkey G) will allow up to 300km/h vertical speed and
dynamically adjust deceleration as soon as 1km altitude or ground is detected.  
See chat commands on how to configure the vertical landing speeds!

- **Auto-altitude hold mode**:

  This mode can be toggled by either double-tapping **ALT+W** key and/or double-clicking
the **middle mouse button**. Tapping the CTRL key will immediately cancel the mode and brake till standstill.  
In atmosphere it will stay below burn speed. During flight the pilot can still
use the usual keys for yawing left/right, but also change the altitude with C/SPACE
keys at any time. The script will limit vertical movements automatically.  
A well balanced construct should be able to hold the altitude within a meter
even across several kilometers and different altitudes.  
Caveat: for ground-only constructs, like hovercrafts, this mode might not work
as expected as at some speed the ship might gain altitude! Also keep in mind,
that this mode does NOT follow terrain!

- **/up** *xxx* and **/down** *xxx* 

  *xxx* is the required distance in meters (positive = up, negative = down).
This will move the ship (if VTOL capable) in the given vertical direction
with high precision and dynamic de-/acceleration adjustments.  
The Hud's target marker will indicate the location (look up or down to see it).  
This works both in atmosphere as well as in near-planet space, e.g. around space stations.  
There needs to be some planetary body of influence for altitude reference and alignment!

- **/goto ::pos{...}**

  This LUA chat command now also works in Maneuver mode.
  - Step 1: Altitude adjustment  
  First the construct will move vertically to a calculated altitude, either a set travel
  altitude (/travelAlt) or one that is at least 50m above the target. The travel altitude here
  is a separate setting apart from what the default Autopilot uses (15% of atmo).  
  If the current altitude is already higher than the calculated one, the current altitude is kept.
  - Step 2: Alignment  
  Once the desired altitude is reached, it will align horizontally onto the target within 3 decimals
  precision in a smooth and precise yaw movement (to prevent overshoot).
  - Step 3: Traversal  
  The construct will then move towards the target location with altitude-holding. During flight
  the altitude can be adjusted via ALT+C/Spacebar, but note that it will change altitude
  in a measured speed.
  Once the target is close, the speed is automatically reduced to come to a stop vertically
  above the target.
  - Step 4: Automatic landing  
  The final part of the trip is then the dynamic landing, taking into account the configured
  speed limits for low and high altitude. 
  
  During the whole process, a "Travel" hint will be shown on the hud at top-center location.  
  To abort the flight at any time, just tap the CTRL key, as usual. If the ship is VTOL capable,
  if shall come to a stop quite fast. With any other ship the pilot shall press the G key to
  perform a landing - unless they can get flying fast enough to get enough lift.

- **/go**

  Similar to above /goto command, but a current target marker will be used as the destination.  
This marker can be set by /setBase (e.g. landed at home base), Alt+Shift+6 to activate
a stored base location or by activating an AP route in the menu.  
This command will do a traversal at least 50m above the destination and not use the
travel altitude as the /goto command does.

- **ALT 8**

  This hotkey now toggles **forward** dampening (in Standard mode it is named "Rotation damp.").  
  By default this option is on for the Maneuver mode and if changed only valid for the current flight.  
  If *active*, it will counter any forward movement and slow back down to 0 km/h.  
  When *off*, it will leave the construct's forward movement untouched, so it'll only be slowed down by air friction and any change in direction (yaw), as per standard DU flight mechanics.  
  Of course keeping CTRL pressed will engage braking as usual.

## Commands list (LUA chat)

### New chat commands

Ssee further down for full list. The **PERM** keyword indicates if the
setting (if it's a toggle) is permanently remembered if a databank is linked.

| Command | Description |
|---|---|
| /agl *xxx* | Sets the above-ground-level distance when landed. This compensates the Ground value by the ground detection element distance. Use the displayed "**Ground**" value from the top info widget. *PERM* |
| /core | Toggles the display of the core stress info bar. Originally this was always on, but it poses a performance drain as it was called with every frame, even inside safe zone/atmo. Default: OFF. *PERM* |
| /current | Outputs in LUA chat the current position as world and local *::pos{}* strings. |
| /dock | Toggles the display of the docking info widget. *PERM* |
| /dockingMode *{1, 2, 3}* | Sets the preferred docking mode. Default: 1. *PERM* |

#### **MANEUVER mode commands**

**Warning**: any movement commands in this section should only be attempted with actually **VTOL**-capable constructs!
With hybrid VTOL's one can even transition from ground to space, but DO NOT try to use this script as an elevator script,
or travel to other planets! For that use the Standard flight mode!  
Also, not every VTOL capable ship will have the same capabilities, thus at a certain point they
won't be able to raise altitude, but rather sink slowly. For smaller constructs, that may even happen
below 1km on Alioth, thus not all ships are good AGG companion ships!  
*No script can fix missing upward thrust!* :)

| Command | Description |
|---|---|
| /setBase | Sets the current position as the home base location (databank).<br>Caveat: the target marker can be changed by other commands or by initiating landing mode! |
| /clearBase | Clears the stored base location. |
| /goAlt *xxx* | Move vertically to the specified absolute altitude. |
| /go | Traverses to current target marker (see Maneuver mode section). Optional 2nd parameter can be a travel altitude. |
| /goto *::pos{}* | Maneuver mode only: like /go command, but traverses to a specified ::pos. |
| /landSpeedHigh *xxx* | Sets the maximum landing speed when above 1 km altitude (in km/h).<br>Default: 200. *PERM* |
| /landSpeedLow *xxx* | Sets the maximum landing speed when below 1 km altitude (in km/h) but above ground detection.<br> Default: 100. *PERM* |
| /vertical *xxx* | Moves the construct vertically *xxx* meters relative to the current altitude, i.e. up = positive or down = negative distance possible. Numeric value from -200000 to 200000 allowed.<br> Examples:<br> /vertical 1000<br> /vertical -123 |

#### Renamed chat commands

| Original | New |
|---|---|
| `/menu` | was: `/mainMenu` |
| `/hover` | was: `/setHover` |

#### Removed chat commands

| Command |
|---|
| `/debug` |

| Command | Description | Usage Sample (commands not case sensitive) |
|--------------|-------------|-------------------------------------------|
| /menu | Toggle the main menu on and off | /menu |
| /scale | Set the hud scale in percent | /scale 100 |
| /addpos | Add a pos to current route | /addpos ::pos{0,2,35.3951,104.1187,285.5413} |
| /goto | Set target to temp point | /goto ::pos{0,2,35.3951,104.1187,285.5413} |
| /setMaxSpaceSpeed /setMSP | Set Max Space Speed in km/h | /setMSP 20000 |
| /setMaxPitch /setMP | Set Max Pitch Degree | /setMP 45 |
| /setMaxRoll /setMR | Set Max Roll Degree | /setMR 35 |
| /landSpeedHigh | Max landing speed when above 1 km altitude in km/h | /landSpeedHigh 200 |
| | Limit landing speed from high altitude down to 1 km at which the Low speed limit takes over. | |
| /landSpeedLow | Max landing speed from 1 km altitude downward in km/h | /landSpeedLow 100 |
| | Limit landing speed from 1 km down to ground detection altitude (Telemeter recommended!). | |
| /shield | Enable or disable auto shield management | /shield |
| /space | Toggle if ship is space capable | /space |
| /hover | Set hover height in meters when out of parking mode (G key) | /hover 20 |
| /atp | Enable or disable atmo Auto throttle protection. Prevents accelerating past atmo burn speed (only Standard flight mode) | /atp |
| /alt /altitude | Set specific altitude for Alt Hold mode. Standard flight mode only! | /alt 2500 |
| /orbitAlt | Set TargetOrbitAlt | /orbitAlt 10000 |
| /freeze | Freeze player for remote controller use | /freeze |
| /agg | Toggle AGG on/off | /agg |
| /aggAlt | Set AGG altitude | /aggAlt 5000 |
| /agl | Set above ground level in meters. Use "Ground" value when landed as this depends on the linked element that provides ground detection, like a telemeter or any ground engine | /agl 1.2 |
| /convert | Converts a ::pos to world coords | /convert ::pos{0,2,35.3951,104.1187,285.5413} |
| /current | Outputs current pos in world/local ::pos | /current |
| /dockingMode | Sets docking mode (1,2 or 3) | /dockingMode 2 |
| /alt | Move straight up to given altitude (meters) | /alt 2345 |
| /core | Toggles display of core stress info on/off | /core |
| /dock | Toggles display of docking info on/off | /dock |
| /unit | Toggles unit widget on/off | /unit |
| /radar | Toggle Radar Widget on/off | /radar |
| /radarbox | Toggle display of radar hud boxes | /radarbox |

## LUA parameters

Below list contains most, if not all, Lua parameters, mainly from the original script.
These are mostly only relevant for the Standard flight mode!  
Some may be stored also in a linked databank, others must be re-set whenever the script is installed again.

| Variable | Description |
|----------|-------------|
| spaceCapableOverride = false | (Space Capable Ship Override) true/false (average ships do not need this) is your ship space capable with a gyro?<br>Space capability is auto detected from rear facing engines. If you use a gyro to get to space, the auto detection may not work, so set this to true if the ship says your not space capable when using AP, when you really are. |
| hoverHeight = 40 | (Hover Height) 0-50 default hover height to goto when unlocking parking mode (G key) |
| throttleBurnProtection = true | (Auto Throttle Burn Protection) true/false takes over the throttle/braking when you are going to exceed your ships burn speed in atmo. (only when already in atmo, it does not prevent you from coming in to atmo too fast if manually transitioning from space to atmo) |
| maxPitch = 35 | (Max Pitch) set between 5-80, 35 is default. |
| maxRoll = 45 | (Max Roll) set between 5-80, 45 is default. |
| wingStallAngle = 35 | (Wing Stall Angle) 25-60. what angle do a majority of your wings stall? 25-60. Ailerons 30, Wings 55, Stabilizers 70. Set slightly below the stall angle of your main lift source. or split the difference if a mix. if you notice your ship "skids" in atmo, your wings are stalling, reduce this number. |
| shieldManage = true | (Auto Shield Management) true/false , let the ship handle shield control on off/resistance management/venting. |
| maxSpaceSpeed = 0 | (Max Space Speed) in km/h (max speed you want to go in space, not ships' capable max speed) 0 for ships max capable speed, or if your selected speed exceeds ships capability, ships max speed will be used. |
| radarOn = false | (Radar Widget) true/false if radar attached, start with radar widget open (toggle widget with /radar command) |
| pitchSpeedFactor = 0.8 | This factor will increase/decrease the player input along the pitch axis (higher value may be unstable)<br>Valid values: Superior or equal to 0.01 |
| yawSpeedFactor =  1 | This factor will increase/decrease the player input along the yaw axis (higher value may be unstable)<br>Valid values: Superior or equal to 0.01 |
| rollSpeedFactor = 1.5 | This factor will increase/decrease the player input along the roll axis<br>(higher value may be unstable)<br>Valid values: Superior or equal to 0.01 |
| brakeSpeedFactor = 3 | When braking, this factor will increase the brake force by brakeSpeedFactor * velocity<br>Valid values: Superior or equal to 0.01 |
| brakeFlatFactor = 1 | When braking, this factor will increase the brake force by a flat brakeFlatFactor * velocity direction><br>(higher value may be unstable)<br>Valid values: Superior or equal to 0.01 |
| autoRoll = true | [Only in atmosphere]<br>When the pilot stops rolling,  flight model will try to get back to horizontal (no roll) |
| autoRollFactor = 2 | [Only in atmosphere]<br>When autoRoll is engaged, this factor will increase to strength of the roll back to 0<br>Valid values: Superior or equal to 0.01 |
| turnAssist = true | [Only in atmosphere]<br>When the pilot is rolling, the flight model will try to add yaw and pitch to make the construct turn better<br>The flight model will start by adding more yaw the more horizontal the construct is and more pitch the more vertical it is |
| turnAssistFactor = 2 | [Only in atmosphere]<br>This factor will increase/decrease the turnAssist effect<br>(higher value may be unstable)<br>Valid values: Superior or equal to 0.01 |
| torqueFactor = 2 | Force factor applied to reach rotationSpeed<br>(higher value may be unstable)<br>Valid values: Superior or equal to 0.01 |
| atmoTankHandling = 5 | (Atmospheric Fuel Tank Handling) 0-5-- Skill level of person who deployed tanks, or highest talents applied to construct with reapply Talents. |
| spaceTankHandling = 5 | (Space Fuel Tank Handling) 0-5<br>Skill level of person who deployed tanks, or highest talents applied to construct with reapply Talents. |
| rocketTankHandling = 0 | (Rocket Fuel Tank Handling) 0-5<br>Skill level of person who deployed tanks, or highest talents applied to construct with reapply Talents. |
| fuelTankOptimization = 5 | Mining and Inventory > Stock Control >(Fuel Tank Optimization) 0-5<br>Skill level of person who deployed tanks, or highest talents applied to construct with reapply Talents. |
| containerOptimization = 5 | Mining and Inventory > Stock Control >(Container Optimization) 0-5<br>Skill level of person who deployed tanks, or highest talents applied to construct with reapply Talents. |
| boostModeOverride = 'off' | (Engine Throttle Mode Override) 'off' , 'all' , 'hybrid' , 'primary' if using Engine tags(see instructions), default engine control mode when activating control unit. |
| aimStrength = 0.3 | Aim Strength 0.05 to ~3 (no real limit but beyond these values has less/no effect or may cause problems) if your ship often swings past where it's trying to aim and wobbles back and forth, reduce this. if you want it to snap at a point faster/stronger(smaller nimble ships) increase it. |
| coreWidget = false | Show Core info panel. Only needed for PvP (FPS impact!) |
| agl = 0 | Above ground landed (in m): Ground distance when landed |
| dockingMode = 1 | Docking mode (1 = manual, 2 = Automatic, 3 = Owner) |
| dockWidget = true | Show docking widget (toggle with /dock command) |
| maxLandingSpeedHigh = 200 | Max vertical landing speed above 1 km altitude (default: 200) |
| maxLandingSpeedLow = 100 | Max vertical landing speed below 1 km altitude (default: 100) |

## Setup

### Required elements

- 1 pilot chair or remote controller, 1 or 2 databanks
- a telemeter is highly recommended (up to 100m ground detection)
- a dynamic construct - NOT an elevator!

#### Setup

- Deploy the piloting element
- Link the following elements to the chair/remote:
  - core
  - databank
  - telemeter
  - at least one hover engine and/or vertical booster
  - warp drive, anti-gravity generator, radar (if exists)
- Install onto the remote controller the "saga.json" script from
the "out\release" folder.

Installation means: open the above mentioned .json file in an UTF8-capable
viewer/editor, copy its full content to the clipboard and in-game right
click the piloting chair/remote controller to get the "Advanced" menu.
Then click the menu item "Paste Lua configuration from clipboard"
to have the script installed on it.

## Credits

Credits go to the original authors of Saga, Horizon and Default++.

Thanks to Matt (**Wolfram** ingame) for [DU-LuaC](https://github.com/wolfe-labs/DU-LuaC)
