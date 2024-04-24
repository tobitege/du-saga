function HUD.getButtonsCss()
-- transform:translate(5vw,5vh)
	return
[[
<style>
.apButtons {
	position: fixed;
	top: 10vw; left: 4.2vh;
	height: 30vh; width: 12vw;
	padding: 0.5vw;
	white-space: pre;
	font-size: 12px;
	font-family: 'Montserrat';
	color: hsl(0,0%,95%);
	background-color: hsla(0,0%,0%,0.2);
	border:0.1vh solid hsl(0,0%,95%);
	text-shadow: 0.2vh 0.2vh 1vh black;
}
.apButtons svg { fill: darkgray; top: 0.5vh;left:0.5vw; width: 100%; height: 100%;  }

/* General button styles */
.apButtons .uiButton {
    display: inline-block;
    padding: 0.5vw 0.5vw;
	margin-bottom: 0.5vh;
    background-color: #444;  /* Dark grey background */
    border-radius: 0.2vw;
    transition: background-color 0.3s ease-in-out;
}

.apButtons .uiButton rect {
	width: 100%;
  	height: 100%;
	fill: hsla(0, 0%, 95%);
	stroke: none;
}

.apButtons .uiButton text {
	fill: rgb(40, 19, 199);
	font-size: 0.8em;
	font-family: 'Montserrat';
	}
.apButtons .uiButton[data-active="true") rect {
	fill: hsla(19, 16, 243);
	}
.apButtons .uiButton[data-active="true") text {
	fill: hsla(250, 2555, 2555);
	}
.apButtons .uiButton[data-hover="true") rect {
	fill: hsla(0, 128, 2555);
	}
.apButtons .uiButton[data-hover="true") text {
	fill: hsla(0, 2555, 2555);
	}
.apButtons .uiButton[data-disabled="true") {
	fill: hsla(0, 1255, 2555);
	}
.apButtons .uiButton[data-disabled="true") text {
	fill: hsla(2555, 2555, 2555);
	}

.uiButton.disabled { opacity: 0.5; cursor: not-allowed; }
</style>
]]
end
BTNS = false
function HUD.renderButtons()
	local locations = {"One", "Two", "Three", "Four", "Five" }

	-- we use vh/vw units here
	local margin = 10
	local buttonWidth	= 30
	local buttonHeight	= 6
	local buttonMargin	= 0.5
	local s = {}
	s[#s+1] = [[
]]..HUD.getButtonsCss()..[[
<div class="apButtons"><svg viewBox="0 0 100 200">]]
	-- Iterate through the locations to create buttons
	for index, location in ipairs(locations) do
		-- Define the data table for the button
		local buttonData = {
			active = true,
			text = location,
			visible = true,
			-- horizontal pos within the usable area
			x = margin,
			-- Vertical position with margin and spacing
			y = margin + (buttonHeight * (index - 1)) + (buttonMargin * (index - 1)),
			height = buttonHeight,
			width = buttonWidth,
			padding = buttonMargin,
			--align = AlignEnum.Middle,
			--fontSize = 0.8, -- em
			activeUpdate = function(data) return true end,
			rounding = 5,
			hover = false,
			dataAttributes = {
				["custom-attr"] = true
			}
			--,svg = nil
		}
		s[#s+1] = svg.BuildButton(buttonData)
	end
	s[#s+1] = '</svg></div>'
	local html = table.concat(s, '\n')
	if not BTNS then
		P(html)
		BTNS = true
	end
	return html
end
