width = 800
height = 480

-- if (display.
application = {
	content = {
		width   = 480,
		height  = 1024, 
		scale   = "letterBox",
    xAlign  = "center",
    yAlign  = "center",
		fps     = 30,
    imageSuffix = {
		  -- ["@2x"] = 3,
		}
	},

    --[[
    -- Push notifications

    notification =
    {
        iphone =
        {
            types =
            {
                "badge", "sound", "alert", "newsstand"
            }
        }
    }
    --]]    
}
