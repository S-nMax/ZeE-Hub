function Rayfield()

    --[[

    	Rayfield接口套件
        By 天狼星
        shlex |设计+编程
        iRay|编程
        Max|编程

    ]]

    if debugX then
    	warn('Initialising Rayfield')
    end

    local function getService(name)
        local service = game:GetService(name)
        return if cloneref then cloneref(service) else service
    end

    -- 加载并执行托管在远程URL上的函数。如果请求的URL响应时间过长，则取消请求。
    -- 函数的错误将被捕获并记录到输出中
    local function loadWithTimeout(url: string, timeout: number?): ...any
    	assert(type(url) == "string", "Expected string, got " .. type(url))
    	timeout = timeout or 5
    	local requestCompleted = false
    	local success, result = false, nil

    	local requestThread = task.spawn(function()
    		local fetchSuccess, fetchResult = pcall(game.HttpGet, game, url) -- game:HttpGet(url)
    		-- 如果请求失败，即使fetchSuccess为true，内容也可以为空
    		if not fetchSuccess or #fetchResult == 0 then
    			if #fetchResult == 0 then
    				fetchResult = "空响应" -- 设置错误消息
    			end
    			success, result = false, fetchResult
    			requestCompleted = true
    			return
    		end
    		local content = fetchResult -- 获取内容
    		local execSuccess, execResult = pcall(function()
    			return loadstring(content)()
    		end)
    		success, result = execSuccess, execResult
    		requestCompleted = true
    	end)

    	local timeoutThread = task.delay(timeout, function()
    		if not requestCompleted then
    			warn(`Request for {url} timed out after {timeout} seconds`)
    			task.cancel(requestThread)
    			result = "Request timed out"
    			requestCompleted = true
    		end
    	end)

    	-- 等待完成或超时
    	while not requestCompleted do
    		task.wait()
    	end
    	-- 如果请求完成时超时线程仍在运行，则取消该线程
    	if coroutine.status(timeoutThread) ~= "dead" then
    		task.cancel(timeoutThread)
    	end
    	if not success then
    		warn(`Failed to process {url}: {result}`)
    	end
    	return if success then result else nil
    end

    local requestsDisabled = true --getgenv 和 getgenv().DISABLE_RAYFIELD_REQUESTS
    local InterfaceBuild = '3K3W'
    local Release = "Build 1.672"
    local RayfieldFolder = "Rayfield"
    local ConfigurationFolder = RayfieldFolder.."/Configurations"
    local ConfigurationExtension = ".rfld"
    local settingsTable = {
    	General = {
    		-- 如果需要按顺序执行getSetting(name)
    		rayfieldOpen = {Type = 'bind', Value = 'K', Name = '天狼星开关按键'},
    		-- buildwarnings
    		-- rayfieldprompts

    	},
    	System = {
    		usageAnalytics = {Type = 'toggle', Value = true, Name = '匿名分析'},
    	}
    }

    -- Settings that have been overridden by the developer. These will not be saved to the user's configuration file
    -- Overridden settings always take precedence over settings in the configuration file, and are cleared if the user changes the setting in the UI
    local overriddenSettings: { [string]: any } = {} -- For example, overriddenSettings["System.rayfieldOpen"] = "J"
    local function overrideSetting(category: string, name: string, value: any)
    	overriddenSettings[`{category}.{name}`] = value
    end

    local function getSetting(category: string, name: string): any
    	if overriddenSettings[`{category}.{name}`] ~= nil then
    		return overriddenSettings[`{category}.{name}`]
    	elseif settingsTable[category][name] ~= nil then
    		return settingsTable[category][name].Value
    	end
    end

    -- If requests/analytics have been disabled by developer, set the user-facing setting to false as well
    if requestsDisabled then
    	overrideSetting("System", "usageAnalytics", false)
    end

    local HttpService = getService('HttpService')
    local RunService = getService('RunService')

    -- Environment Check
    local useStudio = RunService:IsStudio() or false

    local settingsCreated = false
    local settingsInitialized = false -- Whether the UI elements in the settings page have been set to the proper values
    local cachedSettings
    --local prompt = useStudio and require(script.Parent.prompt) or loadWithTimeout('https://raw.githubusercontent.com/SiriusSoftwareLtd/Sirius/refs/heads/request/prompt.lua')
    local request = (syn and syn.request) or (fluxus and fluxus.request) or (http and http.request) or http_request or request



    local function loadSettings()
    	local file = nil
	
    	local success, result =	pcall(function()
    		task.spawn(function()
    			if isfolder and isfolder(RayfieldFolder) then
    				if isfile and isfile(RayfieldFolder..'/settings'..ConfigurationExtension) then
    					file = readfile(RayfieldFolder..'/settings'..ConfigurationExtension)
    				end
    			end

    			-- for debug in studio
    			if useStudio then
    				file = [[
    		{"General":{"rayfieldOpen":{"Value":"K","Type":"bind","Name":"Rayfield Keybind","Element":{"HoldToInteract":false,"Ext":true,"Name":"Rayfield Keybind","Set":null,"CallOnChange":true,"Callback":null,"CurrentKeybind":"K"}}},"System":{"usageAnalytics":{"Value":false,"Type":"toggle","Name":"Anonymised Analytics","Element":{"Ext":true,"Name":"Anonymised Analytics","Set":null,"CurrentValue":false,"Callback":null}}}}
    	]]
    			end


    			if file then
    				local success, decodedFile = pcall(function() return HttpService:JSONDecode(file) end)
    				if success then
    					file = decodedFile
    				else
    					file = {}
    				end
    			else
    				file = {}
    			end


    			if not settingsCreated then 
    				cachedSettings = file
    				return
    			end

    			if file ~= {} then
    				for categoryName, settingCategory in pairs(settingsTable) do
    					if file[categoryName] then
    						for settingName, setting in pairs(settingCategory) do
    							if file[categoryName][settingName] then
    								setting.Value = file[categoryName][settingName].Value
    								setting.Element:Set(getSetting(categoryName, settingName))
    							end
    						end
    					end
    				end
    			end
    			settingsInitialized = true
    		end)
    	end)
	
    	if not success then 
    		if writefile then
    			warn('Rayfield had an issue accessing configuration saving capability.')
    		end
    	end
    end

    if debugX then
    	warn('Now Loading Settings Configuration')
    end

    loadSettings()

    if debugX then
    	warn('Settings Loaded')
    end

    --if not cachedSettings or not cachedSettings.System or not cachedSettings.System.usageAnalytics then
    --	local fileFunctionsAvailable = isfile and writefile and readfile

    --	if not fileFunctionsAvailable and not useStudio then
    --		warn('Rayfield Interface Suite | Sirius Analytics:\n\n\nAs you don\'t have file functionality with your executor, we are unable to save whether you want to opt in or out to analytics.\nIf you do not want to take part in anonymised usage statistics, let us know in our Discord at sirius.menu/discord and we will manually opt you out.')
    --		analytics = true	
    --	else
    --		prompt.create(
    --			'Help us improve',
    --	            [[Would you like to allow Sirius to collect usage statistics?

    --<font transparency='0.4'>No data is linked to you or your personal activity.</font>]],
    --			'Continue',
    --			'Cancel',
    --			function(result)
    --				settingsTable.System.usageAnalytics.Value = result
    --				analytics = result
    --			end
    --		)
    --	end

    --	repeat task.wait() until analytics ~= nil
    --end

    if not requestsDisabled then
    	if debugX then
    		warn('Querying Settings for Reporter Information')
    	end
    	local function sendReport()
    		if useStudio then
    			print('Sending Analytics')
    		else
    			if debugX then warn('Reporting Analytics') end
    			task.spawn(function()
    				local success, reporter = pcall(function()
    					return loadstring(game:HttpGet("https://analytics.sirius.menu/v1/reporter", true))()
    				end)
    				if success and reporter then
    					pcall(function()
    						reporter.report("Rayfield", Release, InterfaceBuild)
    					end)
    				else
    					warn("Failed to load or execute the reporter. \nPlease notify Rayfield developers at sirius.menu/discord.")
    				end
    			end)
    			if debugX then warn('Finished Report') end
    		end
    	end
    	if cachedSettings and (#cachedSettings == 0 or (cachedSettings.System and cachedSettings.System.usageAnalytics and cachedSettings.System.usageAnalytics.Value)) then
    		sendReport()
    	elseif not cachedSettings then
    		sendReport()
    	end
    end

    if debugX then
    	warn('Moving on to continue initialisation')
    end

    local RayfieldLibrary = {
    	Flags = {},
    	Theme = {
    		Default = {
    			TextColor = Color3.fromRGB(240, 240, 240),

    			Background = Color3.fromRGB(25, 25, 25),
    			Topbar = Color3.fromRGB(34, 34, 34),
    			Shadow = Color3.fromRGB(20, 20, 20),

    			NotificationBackground = Color3.fromRGB(20, 20, 20),
    			NotificationActionsBackground = Color3.fromRGB(230, 230, 230),

    			TabBackground = Color3.fromRGB(80, 80, 80),
    			TabStroke = Color3.fromRGB(85, 85, 85),
    			TabBackgroundSelected = Color3.fromRGB(210, 210, 210),
    			TabTextColor = Color3.fromRGB(240, 240, 240),
    			SelectedTabTextColor = Color3.fromRGB(50, 50, 50),

    			ElementBackground = Color3.fromRGB(35, 35, 35),
    			ElementBackgroundHover = Color3.fromRGB(40, 40, 40),
    			SecondaryElementBackground = Color3.fromRGB(25, 25, 25),
    			ElementStroke = Color3.fromRGB(50, 50, 50),
    			SecondaryElementStroke = Color3.fromRGB(40, 40, 40),

    			SliderBackground = Color3.fromRGB(50, 138, 220),
    			SliderProgress = Color3.fromRGB(50, 138, 220),
    			SliderStroke = Color3.fromRGB(58, 163, 255),

    			ToggleBackground = Color3.fromRGB(30, 30, 30),
    			ToggleEnabled = Color3.fromRGB(0, 146, 214),
    			ToggleDisabled = Color3.fromRGB(100, 100, 100),
    			ToggleEnabledStroke = Color3.fromRGB(0, 170, 255),
    			ToggleDisabledStroke = Color3.fromRGB(125, 125, 125),
    			ToggleEnabledOuterStroke = Color3.fromRGB(100, 100, 100),
    			ToggleDisabledOuterStroke = Color3.fromRGB(65, 65, 65),

    			DropdownSelected = Color3.fromRGB(40, 40, 40),
    			DropdownUnselected = Color3.fromRGB(30, 30, 30),

    			InputBackground = Color3.fromRGB(30, 30, 30),
    			InputStroke = Color3.fromRGB(65, 65, 65),
    			PlaceholderColor = Color3.fromRGB(178, 178, 178)
    		},

    		Ocean = {
    			TextColor = Color3.fromRGB(230, 240, 240),

    			Background = Color3.fromRGB(20, 30, 30),
    			Topbar = Color3.fromRGB(25, 40, 40),
    			Shadow = Color3.fromRGB(15, 20, 20),

    			NotificationBackground = Color3.fromRGB(25, 35, 35),
    			NotificationActionsBackground = Color3.fromRGB(230, 240, 240),

    			TabBackground = Color3.fromRGB(40, 60, 60),
    			TabStroke = Color3.fromRGB(50, 70, 70),
    			TabBackgroundSelected = Color3.fromRGB(100, 180, 180),
    			TabTextColor = Color3.fromRGB(210, 230, 230),
    			SelectedTabTextColor = Color3.fromRGB(20, 50, 50),

    			ElementBackground = Color3.fromRGB(30, 50, 50),
    			ElementBackgroundHover = Color3.fromRGB(40, 60, 60),
    			SecondaryElementBackground = Color3.fromRGB(30, 45, 45),
    			ElementStroke = Color3.fromRGB(45, 70, 70),
    			SecondaryElementStroke = Color3.fromRGB(40, 65, 65),

    			SliderBackground = Color3.fromRGB(0, 110, 110),
    			SliderProgress = Color3.fromRGB(0, 140, 140),
    			SliderStroke = Color3.fromRGB(0, 160, 160),

    			ToggleBackground = Color3.fromRGB(30, 50, 50),
    			ToggleEnabled = Color3.fromRGB(0, 130, 130),
    			ToggleDisabled = Color3.fromRGB(70, 90, 90),
    			ToggleEnabledStroke = Color3.fromRGB(0, 160, 160),
    			ToggleDisabledStroke = Color3.fromRGB(85, 105, 105),
    			ToggleEnabledOuterStroke = Color3.fromRGB(50, 100, 100),
    			ToggleDisabledOuterStroke = Color3.fromRGB(45, 65, 65),

    			DropdownSelected = Color3.fromRGB(30, 60, 60),
    			DropdownUnselected = Color3.fromRGB(25, 40, 40),

    			InputBackground = Color3.fromRGB(30, 50, 50),
    			InputStroke = Color3.fromRGB(50, 70, 70),
    			PlaceholderColor = Color3.fromRGB(140, 160, 160)
    		},

    		AmberGlow = {
    			TextColor = Color3.fromRGB(255, 245, 230),

    			Background = Color3.fromRGB(45, 30, 20),
    			Topbar = Color3.fromRGB(55, 40, 25),
    			Shadow = Color3.fromRGB(35, 25, 15),

    			NotificationBackground = Color3.fromRGB(50, 35, 25),
    			NotificationActionsBackground = Color3.fromRGB(245, 230, 215),

    			TabBackground = Color3.fromRGB(75, 50, 35),
    			TabStroke = Color3.fromRGB(90, 60, 45),
    			TabBackgroundSelected = Color3.fromRGB(230, 180, 100),
    			TabTextColor = Color3.fromRGB(250, 220, 200),
    			SelectedTabTextColor = Color3.fromRGB(50, 30, 10),

    			ElementBackground = Color3.fromRGB(60, 45, 35),
    			ElementBackgroundHover = Color3.fromRGB(70, 50, 40),
    			SecondaryElementBackground = Color3.fromRGB(55, 40, 30),
    			ElementStroke = Color3.fromRGB(85, 60, 45),
    			SecondaryElementStroke = Color3.fromRGB(75, 50, 35),

    			SliderBackground = Color3.fromRGB(220, 130, 60),
    			SliderProgress = Color3.fromRGB(250, 150, 75),
    			SliderStroke = Color3.fromRGB(255, 170, 85),

    			ToggleBackground = Color3.fromRGB(55, 40, 30),
    			ToggleEnabled = Color3.fromRGB(240, 130, 30),
    			ToggleDisabled = Color3.fromRGB(90, 70, 60),
    			ToggleEnabledStroke = Color3.fromRGB(255, 160, 50),
    			ToggleDisabledStroke = Color3.fromRGB(110, 85, 75),
    			ToggleEnabledOuterStroke = Color3.fromRGB(200, 100, 50),
    			ToggleDisabledOuterStroke = Color3.fromRGB(75, 60, 55),

    			DropdownSelected = Color3.fromRGB(70, 50, 40),
    			DropdownUnselected = Color3.fromRGB(55, 40, 30),

    			InputBackground = Color3.fromRGB(60, 45, 35),
    			InputStroke = Color3.fromRGB(90, 65, 50),
    			PlaceholderColor = Color3.fromRGB(190, 150, 130)
    		},

    		Light = {
    			TextColor = Color3.fromRGB(40, 40, 40),

    			Background = Color3.fromRGB(245, 245, 245),
    			Topbar = Color3.fromRGB(230, 230, 230),
    			Shadow = Color3.fromRGB(200, 200, 200),

    			NotificationBackground = Color3.fromRGB(250, 250, 250),
    			NotificationActionsBackground = Color3.fromRGB(240, 240, 240),

    			TabBackground = Color3.fromRGB(235, 235, 235),
    			TabStroke = Color3.fromRGB(215, 215, 215),
    			TabBackgroundSelected = Color3.fromRGB(255, 255, 255),
    			TabTextColor = Color3.fromRGB(80, 80, 80),
    			SelectedTabTextColor = Color3.fromRGB(0, 0, 0),

    			ElementBackground = Color3.fromRGB(240, 240, 240),
    			ElementBackgroundHover = Color3.fromRGB(225, 225, 225),
    			SecondaryElementBackground = Color3.fromRGB(235, 235, 235),
    			ElementStroke = Color3.fromRGB(210, 210, 210),
    			SecondaryElementStroke = Color3.fromRGB(210, 210, 210),

    			SliderBackground = Color3.fromRGB(150, 180, 220),
    			SliderProgress = Color3.fromRGB(100, 150, 200), 
    			SliderStroke = Color3.fromRGB(120, 170, 220),

    			ToggleBackground = Color3.fromRGB(220, 220, 220),
    			ToggleEnabled = Color3.fromRGB(0, 146, 214),
    			ToggleDisabled = Color3.fromRGB(150, 150, 150),
    			ToggleEnabledStroke = Color3.fromRGB(0, 170, 255),
    			ToggleDisabledStroke = Color3.fromRGB(170, 170, 170),
    			ToggleEnabledOuterStroke = Color3.fromRGB(100, 100, 100),
    			ToggleDisabledOuterStroke = Color3.fromRGB(180, 180, 180),

    			DropdownSelected = Color3.fromRGB(230, 230, 230),
    			DropdownUnselected = Color3.fromRGB(220, 220, 220),

    			InputBackground = Color3.fromRGB(240, 240, 240),
    			InputStroke = Color3.fromRGB(180, 180, 180),
    			PlaceholderColor = Color3.fromRGB(140, 140, 140)
    		},

    		Amethyst = {
    			TextColor = Color3.fromRGB(240, 240, 240),

    			Background = Color3.fromRGB(30, 20, 40),
    			Topbar = Color3.fromRGB(40, 25, 50),
    			Shadow = Color3.fromRGB(20, 15, 30),

    			NotificationBackground = Color3.fromRGB(35, 20, 40),
    			NotificationActionsBackground = Color3.fromRGB(240, 240, 250),

    			TabBackground = Color3.fromRGB(60, 40, 80),
    			TabStroke = Color3.fromRGB(70, 45, 90),
    			TabBackgroundSelected = Color3.fromRGB(180, 140, 200),
    			TabTextColor = Color3.fromRGB(230, 230, 240),
    			SelectedTabTextColor = Color3.fromRGB(50, 20, 50),

    			ElementBackground = Color3.fromRGB(45, 30, 60),
    			ElementBackgroundHover = Color3.fromRGB(50, 35, 70),
    			SecondaryElementBackground = Color3.fromRGB(40, 30, 55),
    			ElementStroke = Color3.fromRGB(70, 50, 85),
    			SecondaryElementStroke = Color3.fromRGB(65, 45, 80),

    			SliderBackground = Color3.fromRGB(100, 60, 150),
    			SliderProgress = Color3.fromRGB(130, 80, 180),
    			SliderStroke = Color3.fromRGB(150, 100, 200),

    			ToggleBackground = Color3.fromRGB(45, 30, 55),
    			ToggleEnabled = Color3.fromRGB(120, 60, 150),
    			ToggleDisabled = Color3.fromRGB(94, 47, 117),
    			ToggleEnabledStroke = Color3.fromRGB(140, 80, 170),
    			ToggleDisabledStroke = Color3.fromRGB(124, 71, 150),
    			ToggleEnabledOuterStroke = Color3.fromRGB(90, 40, 120),
    			ToggleDisabledOuterStroke = Color3.fromRGB(80, 50, 110),

    			DropdownSelected = Color3.fromRGB(50, 35, 70),
    			DropdownUnselected = Color3.fromRGB(35, 25, 50),

    			InputBackground = Color3.fromRGB(45, 30, 60),
    			InputStroke = Color3.fromRGB(80, 50, 110),
    			PlaceholderColor = Color3.fromRGB(178, 150, 200)
    		},

    		Green = {
    			TextColor = Color3.fromRGB(30, 60, 30),

    			Background = Color3.fromRGB(235, 245, 235),
    			Topbar = Color3.fromRGB(210, 230, 210),
    			Shadow = Color3.fromRGB(200, 220, 200),

    			NotificationBackground = Color3.fromRGB(240, 250, 240),
    			NotificationActionsBackground = Color3.fromRGB(220, 235, 220),

    			TabBackground = Color3.fromRGB(215, 235, 215),
    			TabStroke = Color3.fromRGB(190, 210, 190),
    			TabBackgroundSelected = Color3.fromRGB(245, 255, 245),
    			TabTextColor = Color3.fromRGB(50, 80, 50),
    			SelectedTabTextColor = Color3.fromRGB(20, 60, 20),

    			ElementBackground = Color3.fromRGB(225, 240, 225),
    			ElementBackgroundHover = Color3.fromRGB(210, 225, 210),
    			SecondaryElementBackground = Color3.fromRGB(235, 245, 235), 
    			ElementStroke = Color3.fromRGB(180, 200, 180),
    			SecondaryElementStroke = Color3.fromRGB(180, 200, 180),

    			SliderBackground = Color3.fromRGB(90, 160, 90),
    			SliderProgress = Color3.fromRGB(70, 130, 70),
    			SliderStroke = Color3.fromRGB(100, 180, 100),

    			ToggleBackground = Color3.fromRGB(215, 235, 215),
    			ToggleEnabled = Color3.fromRGB(60, 130, 60),
    			ToggleDisabled = Color3.fromRGB(150, 175, 150),
    			ToggleEnabledStroke = Color3.fromRGB(80, 150, 80),
    			ToggleDisabledStroke = Color3.fromRGB(130, 150, 130),
    			ToggleEnabledOuterStroke = Color3.fromRGB(100, 160, 100),
    			ToggleDisabledOuterStroke = Color3.fromRGB(160, 180, 160),

    			DropdownSelected = Color3.fromRGB(225, 240, 225),
    			DropdownUnselected = Color3.fromRGB(210, 225, 210),

    			InputBackground = Color3.fromRGB(235, 245, 235),
    			InputStroke = Color3.fromRGB(180, 200, 180),
    			PlaceholderColor = Color3.fromRGB(120, 140, 120)
    		},

    		Bloom = {
    			TextColor = Color3.fromRGB(60, 40, 50),

    			Background = Color3.fromRGB(255, 240, 245),
    			Topbar = Color3.fromRGB(250, 220, 225),
    			Shadow = Color3.fromRGB(230, 190, 195),

    			NotificationBackground = Color3.fromRGB(255, 235, 240),
    			NotificationActionsBackground = Color3.fromRGB(245, 215, 225),

    			TabBackground = Color3.fromRGB(240, 210, 220),
    			TabStroke = Color3.fromRGB(230, 200, 210),
    			TabBackgroundSelected = Color3.fromRGB(255, 225, 235),
    			TabTextColor = Color3.fromRGB(80, 40, 60),
    			SelectedTabTextColor = Color3.fromRGB(50, 30, 50),

    			ElementBackground = Color3.fromRGB(255, 235, 240),
    			ElementBackgroundHover = Color3.fromRGB(245, 220, 230),
    			SecondaryElementBackground = Color3.fromRGB(255, 235, 240), 
    			ElementStroke = Color3.fromRGB(230, 200, 210),
    			SecondaryElementStroke = Color3.fromRGB(230, 200, 210),

    			SliderBackground = Color3.fromRGB(240, 130, 160),
    			SliderProgress = Color3.fromRGB(250, 160, 180),
    			SliderStroke = Color3.fromRGB(255, 180, 200),

    			ToggleBackground = Color3.fromRGB(240, 210, 220),
    			ToggleEnabled = Color3.fromRGB(255, 140, 170),
    			ToggleDisabled = Color3.fromRGB(200, 180, 185),
    			ToggleEnabledStroke = Color3.fromRGB(250, 160, 190),
    			ToggleDisabledStroke = Color3.fromRGB(210, 180, 190),
    			ToggleEnabledOuterStroke = Color3.fromRGB(220, 160, 180),
    			ToggleDisabledOuterStroke = Color3.fromRGB(190, 170, 180),

    			DropdownSelected = Color3.fromRGB(250, 220, 225),
    			DropdownUnselected = Color3.fromRGB(240, 210, 220),

    			InputBackground = Color3.fromRGB(255, 235, 240),
    			InputStroke = Color3.fromRGB(220, 190, 200),
    			PlaceholderColor = Color3.fromRGB(170, 130, 140)
    		},

    		DarkBlue = {
    			TextColor = Color3.fromRGB(230, 230, 230),

    			Background = Color3.fromRGB(20, 25, 30),
    			Topbar = Color3.fromRGB(30, 35, 40),
    			Shadow = Color3.fromRGB(15, 20, 25),

    			NotificationBackground = Color3.fromRGB(25, 30, 35),
    			NotificationActionsBackground = Color3.fromRGB(45, 50, 55),

    			TabBackground = Color3.fromRGB(35, 40, 45),
    			TabStroke = Color3.fromRGB(45, 50, 60),
    			TabBackgroundSelected = Color3.fromRGB(40, 70, 100),
    			TabTextColor = Color3.fromRGB(200, 200, 200),
    			SelectedTabTextColor = Color3.fromRGB(255, 255, 255),

    			ElementBackground = Color3.fromRGB(30, 35, 40),
    			ElementBackgroundHover = Color3.fromRGB(40, 45, 50),
    			SecondaryElementBackground = Color3.fromRGB(35, 40, 45), 
    			ElementStroke = Color3.fromRGB(45, 50, 60),
    			SecondaryElementStroke = Color3.fromRGB(40, 45, 55),

    			SliderBackground = Color3.fromRGB(0, 90, 180),
    			SliderProgress = Color3.fromRGB(0, 120, 210),
    			SliderStroke = Color3.fromRGB(0, 150, 240),

    			ToggleBackground = Color3.fromRGB(35, 40, 45),
    			ToggleEnabled = Color3.fromRGB(0, 120, 210),
    			ToggleDisabled = Color3.fromRGB(70, 70, 80),
    			ToggleEnabledStroke = Color3.fromRGB(0, 150, 240),
    			ToggleDisabledStroke = Color3.fromRGB(75, 75, 85),
    			ToggleEnabledOuterStroke = Color3.fromRGB(20, 100, 180), 
    			ToggleDisabledOuterStroke = Color3.fromRGB(55, 55, 65),

    			DropdownSelected = Color3.fromRGB(30, 70, 90),
    			DropdownUnselected = Color3.fromRGB(25, 30, 35),

    			InputBackground = Color3.fromRGB(25, 30, 35),
    			InputStroke = Color3.fromRGB(45, 50, 60), 
    			PlaceholderColor = Color3.fromRGB(150, 150, 160)
    		},

    		Serenity = {
    			TextColor = Color3.fromRGB(50, 55, 60),
    			Background = Color3.fromRGB(240, 245, 250),
    			Topbar = Color3.fromRGB(215, 225, 235),
    			Shadow = Color3.fromRGB(200, 210, 220),

    			NotificationBackground = Color3.fromRGB(210, 220, 230),
    			NotificationActionsBackground = Color3.fromRGB(225, 230, 240),

    			TabBackground = Color3.fromRGB(200, 210, 220),
    			TabStroke = Color3.fromRGB(180, 190, 200),
    			TabBackgroundSelected = Color3.fromRGB(175, 185, 200),
    			TabTextColor = Color3.fromRGB(50, 55, 60),
    			SelectedTabTextColor = Color3.fromRGB(30, 35, 40),

    			ElementBackground = Color3.fromRGB(210, 220, 230),
    			ElementBackgroundHover = Color3.fromRGB(220, 230, 240),
    			SecondaryElementBackground = Color3.fromRGB(200, 210, 220),
    			ElementStroke = Color3.fromRGB(190, 200, 210),
    			SecondaryElementStroke = Color3.fromRGB(180, 190, 200),

    			SliderBackground = Color3.fromRGB(200, 220, 235),  -- Lighter shade
    			SliderProgress = Color3.fromRGB(70, 130, 180),
    			SliderStroke = Color3.fromRGB(150, 180, 220),

    			ToggleBackground = Color3.fromRGB(210, 220, 230),
    			ToggleEnabled = Color3.fromRGB(70, 160, 210),
    			ToggleDisabled = Color3.fromRGB(180, 180, 180),
    			ToggleEnabledStroke = Color3.fromRGB(60, 150, 200),
    			ToggleDisabledStroke = Color3.fromRGB(140, 140, 140),
    			ToggleEnabledOuterStroke = Color3.fromRGB(100, 120, 140),
    			ToggleDisabledOuterStroke = Color3.fromRGB(120, 120, 130),

    			DropdownSelected = Color3.fromRGB(220, 230, 240),
    			DropdownUnselected = Color3.fromRGB(200, 210, 220),

    			InputBackground = Color3.fromRGB(220, 230, 240),
    			InputStroke = Color3.fromRGB(180, 190, 200),
    			PlaceholderColor = Color3.fromRGB(150, 150, 150)
    		},
    	}
    }


    -- Services
    local UserInputService = getService("UserInputService")
    local TweenService = getService("TweenService")
    local Players = getService("Players")
    local CoreGui = getService("CoreGui")

    -- Interface Management

    local Rayfield = useStudio and script.Parent:FindFirstChild('Rayfield') or game:GetObjects("rbxassetid://10804731440")[1]
    local buildAttempts = 0
    local correctBuild = false
    local warned
    local globalLoaded
    local rayfieldDestroyed = false -- True when RayfieldLibrary:Destroy() is called

    repeat
    	if Rayfield:FindFirstChild('Build') and Rayfield.Build.Value == InterfaceBuild then
    		correctBuild = true
    		break
    	end

    	correctBuild = false

    	if not warned then
    		warn('Rayfield | Build Mismatch')
    		print('Rayfield may encounter issues as you are running an incompatible interface version ('.. ((Rayfield:FindFirstChild('Build') and Rayfield.Build.Value) or 'No Build') ..').\n\nThis version of Rayfield is intended for interface build '..InterfaceBuild..'.')
    		warned = true
    	end

    	toDestroy, Rayfield = Rayfield, useStudio and script.Parent:FindFirstChild('Rayfield') or game:GetObjects("rbxassetid://10804731440")[1]
    	if toDestroy and not useStudio then toDestroy:Destroy() end

    	buildAttempts = buildAttempts + 1
    until buildAttempts >= 2

    Rayfield.Enabled = false

    if gethui then
    	Rayfield.Parent = gethui()
    elseif syn and syn.protect_gui then 
    	syn.protect_gui(Rayfield)
    	Rayfield.Parent = CoreGui
    elseif not useStudio and CoreGui:FindFirstChild("RobloxGui") then
    	Rayfield.Parent = CoreGui:FindFirstChild("RobloxGui")
    elseif not useStudio then
    	Rayfield.Parent = CoreGui
    end

    if gethui then
    	for _, Interface in ipairs(gethui():GetChildren()) do
    		if Interface.Name == Rayfield.Name and Interface ~= Rayfield then
    			Interface.Enabled = false
    			Interface.Name = "Rayfield-Old"
    		end
    	end
    elseif not useStudio then
    	for _, Interface in ipairs(CoreGui:GetChildren()) do
    		if Interface.Name == Rayfield.Name and Interface ~= Rayfield then
    			Interface.Enabled = false
    			Interface.Name = "Rayfield-Old"
    		end
    	end
    end


    local minSize = Vector2.new(1024, 768)
    local useMobileSizing

    if Rayfield.AbsoluteSize.X < minSize.X and Rayfield.AbsoluteSize.Y < minSize.Y then
    	useMobileSizing = true
    end

    if UserInputService.TouchEnabled then
    	useMobilePrompt = true
    end


    -- Object Variables

    local Main = Rayfield.Main
    local MPrompt = Rayfield:FindFirstChild('Prompt')
    local Topbar = Main.Topbar
    local Elements = Main.Elements
    local LoadingFrame = Main.LoadingFrame
    local TabList = Main.TabList
    local dragBar = Rayfield:FindFirstChild('Drag')
    local dragInteract = dragBar and dragBar.Interact or nil
    local dragBarCosmetic = dragBar and dragBar.Drag or nil

    local dragOffset = 255
    local dragOffsetMobile = 150

    Rayfield.DisplayOrder = 100
    LoadingFrame.Version.Text = Release

    -- Thanks to Latte Softworks for the Lucide integration for Roblox
    local function loadWithTimeout()
    
    return {["48px"]={rewind={16898613699,{48,48},{563,967}},fuel={16898613353,{48,48},{196,967}},["square-arrow-out-up-right"]={16898613777,{48,48},{967,514}},["table-cells-split"]={16898613777,{48,48},{771,955}},gavel={16898613353,{48,48},{967,808}},["dna-off"]={16898613044,{48,48},{453,967}},["refresh-ccw-dot"]={16898613699,{48,48},{869,404}},bean={16898612629,{48,48},{967,906}},["arrow-up-right-from-circle"]={16898612629,{48,48},{563,967}},["table-columns-split"]={16898613777,{48,48},{967,808}},bolt={16898612819,{48,48},{306,820}},["square-asterisk"]={16898613777,{48,48},{710,771}},feather={16898613353,{48,48},{771,98}},["align-horizontal-distribute-center"]={16898612629,{48,48},{771,355}},["align-center"]={16898612629,{48,48},{0,869}},["grip-vertical"]={16898613509,{48,48},{0,869}},["person-standing"]={16898613699,{48,48},{563,771}},["badge-swiss-franc"]={16898612629,{48,48},{771,857}},["between-horizontal-end"]={16898612819,{48,48},{771,306}},["rotate-cw"]={16898613699,{48,48},{869,453}},framer={16898613353,{48,48},{661,967}},["bus-front"]={16898612819,{48,48},{869,612}},["shield-ellipsis"]={16898613777,{48,48},{771,306}},["file-lock-2"]={16898613353,{48,48},{257,918}},["between-vertical-end"]={16898612819,{48,48},{257,820}},["globe-lock"]={16898613509,{48,48},{820,514}},["toggle-left"]={16898613869,{48,48},{869,49}},["concierge-bell"]={16898613044,{48,48},{869,147}},video={16898613869,{48,48},{355,967}},["arrow-left-square"]={16898612629,{48,48},{196,820}},["file-down"]={16898613353,{48,48},{98,820}},["picture-in-picture"]={16898613699,{48,48},{257,869}},["messages-square"]={16898613613,{48,48},{306,869}},grab={16898613509,{48,48},{514,820}},["phone-call"]={16898613699,{48,48},{514,820}},["chevron-up-circle"]={16898612819,{48,48},{820,808}},["server-crash"]={16898613699,{48,48},{918,955}},["heading-3"]={16898613509,{48,48},{869,306}},squircle={16898613777,{48,48},{820,759}},["wifi-off"]={16898613869,{48,48},{918,759}},["sun-medium"]={16898613777,{48,48},{661,967}},ungroup={16898613869,{48,48},{257,967}},["cloud-download"]={16898613044,{48,48},{612,820}},["sigma-square"]={16898613777,{48,48},{869,514}},["folder-plus"]={16898613353,{48,48},{661,918}},["hard-drive-download"]={16898613509,{48,48},{918,0}},["scatter-chart"]={16898613699,{48,48},{196,967}},pointer={16898613699,{48,48},{661,771}},ligature={16898613509,{48,48},{612,967}},["chevrons-up-down"]={16898612819,{48,48},{918,759}},["iteration-cw"]={16898613509,{48,48},{869,147}},["rail-symbol"]={16898613699,{48,48},{967,514}},["square-stack"]={16898613777,{48,48},{453,869}},parentheses={16898613613,{48,48},{869,906}},["book-up-2"]={16898612819,{48,48},{306,869}},flame={16898613353,{48,48},{967,306}},["chevrons-up"]={16898612819,{48,48},{869,808}},["chevron-right-square"]={16898612819,{48,48},{918,710}},["square-mouse-pointer"]={16898613777,{48,48},{869,661}},superscript={16898613777,{48,48},{918,759}},signal={16898613777,{48,48},{918,0}},["file-warning"]={16898613353,{48,48},{967,514}},hexagon={16898613509,{48,48},{967,0}},["navigation-2-off"]={16898613613,{48,48},{918,612}},unlock={16898613869,{48,48},{771,710}},["arrows-up-from-line"]={16898612629,{48,48},{918,404}},["square-gantt-chart"]={16898613777,{48,48},{453,820}},["square-chevron-left"]={16898613777,{48,48},{967,49}},scaling={16898613699,{48,48},{967,661}},["inspection-panel"]={16898613509,{48,48},{563,918}},["arrow-left-from-line"]={16898612629,{48,48},{869,147}},ship={16898613777,{48,48},{771,98}},["ticket-percent"]={16898613869,{48,48},{257,869}},["arrow-right-square"]={16898612629,{48,48},{869,404}},["calendar-clock"]={16898612819,{48,48},{918,98}},x={16898613869,{48,48},{869,906}},voicemail={16898613869,{48,48},{869,710}},presentation={16898613699,{48,48},{771,196}},["tree-palm"]={16898613869,{48,48},{820,612}},popsicle={16898613699,{48,48},{563,869}},["captions-off"]={16898612819,{48,48},{661,869}},["align-vertical-justify-center"]={16898612629,{48,48},{49,869}},theater={16898613869,{48,48},{98,771}},tent={16898613869,{48,48},{49,771}},["repeat-1"]={16898613699,{48,48},{918,612}},stethoscope={16898613777,{48,48},{147,967}},["screen-share-off"]={16898613699,{48,48},{771,906}},["arrow-big-up"]={16898612629,{48,48},{918,306}},["volume-x"]={16898613869,{48,48},{710,869}},["mouse-pointer-click"]={16898613613,{48,48},{771,710}},["square-m"]={16898613777,{48,48},{306,967}},["hard-drive"]={16898613509,{48,48},{820,98}},["package-minus"]={16898613613,{48,48},{771,808}},cloud={16898613044,{48,48},{918,306}},["mouse-pointer-square-dashed"]={16898613613,{48,48},{710,771}},["flip-horizontal"]={16898613353,{48,48},{306,967}},["alert-circle"]={16898612629,{48,48},{869,0}},unplug={16898613869,{48,48},{710,771}},["badge-cent"]={16898612629,{48,48},{612,967}},["check-square-2"]={16898612819,{48,48},{820,759}},["monitor-check"]={16898613613,{48,48},{196,771}},trello={16898613869,{48,48},{612,820}},["paintbrush-2"]={16898613613,{48,48},{967,404}},["bar-chart-horizontal"]={16898612629,{48,48},{710,967}},["book-plus"]={16898612819,{48,48},{771,404}},torus={16898613869,{48,48},{147,771}},["panel-right-close"]={16898613613,{48,48},{453,967}},["heart-handshake"]={16898613509,{48,48},{869,563}},trees={16898613869,{48,48},{661,771}},ham={16898613509,{48,48},{355,771}},text={16898613869,{48,48},{771,98}},["nut-off"]={16898613613,{48,48},{98,967}},["bean-off"]={16898612629,{48,48},{869,955}},rat={16898613699,{48,48},{869,612}},["separator-horizontal"]={16898613699,{48,48},{918,906}},["square-arrow-up-right"]={16898613777,{48,48},{820,661}},["signal-zero"]={16898613777,{48,48},{514,869}},citrus={16898613044,{48,48},{306,820}},["phone-missed"]={16898613699,{48,48},{771,98}},["user-round-check"]={16898613869,{48,48},{869,404}},["battery-medium"]={16898612629,{48,48},{869,906}},["square-minus"]={16898613777,{48,48},{918,612}},hotel={16898613509,{48,48},{98,869}},["folder-output"]={16898613353,{48,48},{771,808}},["ice-cream"]={16898613509,{48,48},{869,355}},menu={16898613613,{48,48},{49,820}},["arrow-up-left-square"]={16898612629,{48,48},{710,820}},lightbulb={16898613509,{48,48},{918,196}},["badge-help"]={16898612629,{48,48},{147,967}},angry={16898612629,{48,48},{257,918}},outdent={16898613613,{48,48},{918,661}},["circle-dot-dashed"]={16898613044,{48,48},{771,514}},speech={16898613777,{48,48},{820,147}},["cake-slice"]={16898612819,{48,48},{661,820}},["git-graph"]={16898613509,{48,48},{0,771}},armchair={16898612629,{48,48},{820,147}},["qr-code"]={16898613699,{48,48},{967,257}},copy={16898613044,{48,48},{918,612}},goal={16898613509,{48,48},{563,771}},["trending-down"]={16898613869,{48,48},{563,869}},haze={16898613509,{48,48},{98,820}},nfc={16898613613,{48,48},{612,918}},["receipt-russian-ruble"]={16898613699,{48,48},{514,967}},disc={16898613044,{48,48},{661,967}},["notebook-tabs"]={16898613613,{48,48},{967,98}},["panels-left-bottom"]={16898613613,{48,48},{820,906}},videotape={16898613869,{48,48},{967,612}},["sun-moon"]={16898613777,{48,48},{967,196}},calendar={16898612819,{48,48},{355,918}},["minus-circle"]={16898613613,{48,48},{869,98}},sunset={16898613777,{48,48},{967,710}},["navigation-2"]={16898613613,{48,48},{869,661}},["message-square-heart"]={16898613613,{48,48},{771,147}},["rectangle-ellipsis"]={16898613699,{48,48},{820,196}},["badge-plus"]={16898612629,{48,48},{918,710}},["indian-rupee"]={16898613509,{48,48},{710,771}},["monitor-dot"]={16898613613,{48,48},{147,820}},delete={16898613044,{48,48},{661,918}},["clipboard-pen-line"]={16898613044,{48,48},{918,0}},["folder-search"]={16898613353,{48,48},{918,196}},["utensils-crossed"]={16898613869,{48,48},{918,147}},dices={16898613044,{48,48},{918,710}},reply={16898613699,{48,48},{612,918}},["flask-round"]={16898613353,{48,48},{404,869}},pause={16898613699,{48,48},{0,771}},shrub={16898613777,{48,48},{306,820}},flag={16898613353,{48,48},{98,918}},underline={16898613869,{48,48},{820,404}},["align-horizontal-distribute-end"]={16898612629,{48,48},{355,771}},newspaper={16898613613,{48,48},{661,869}},table={16898613777,{48,48},{820,955}},["move-vertical"]={16898613613,{48,48},{820,453}},["file-pen-line"]={16898613353,{48,48},{612,820}},["badge-russian-ruble"]={16898612629,{48,48},{820,808}},radius={16898613699,{48,48},{257,967}},["loader-2"]={16898613509,{48,48},{820,857}},pilcrow={16898613699,{48,48},{612,771}},["scan-face"]={16898613699,{48,48},{820,808}},spade={16898613777,{48,48},{514,918}},["book-user"]={16898612819,{48,48},{918,514}},["flip-vertical"]={16898613353,{48,48},{918,612}},["square-arrow-down"]={16898613777,{48,48},{453,771}},["circle-plus"]={16898613044,{48,48},{869,0}},view={16898613869,{48,48},{918,661}},cctv={16898612819,{48,48},{355,967}},["more-horizontal"]={16898613613,{48,48},{257,967}},["file-key-2"]={16898613353,{48,48},{404,771}},["pause-octagon"]={16898613699,{48,48},{771,0}},["circle-arrow-out-down-left"]={16898612819,{48,48},{771,955}},volume={16898613869,{48,48},{661,918}},facebook={16898613353,{48,48},{563,771}},["octagon-alert"]={16898613613,{48,48},{918,404}},["panel-bottom-dashed"]={16898613613,{48,48},{918,710}},["book-a"]={16898612819,{48,48},{820,563}},["align-end-vertical"]={16898612629,{48,48},{820,306}},["user-x-2"]={16898613869,{48,48},{771,759}},chrome={16898612819,{48,48},{820,857}},["receipt-japanese-yen"]={16898613699,{48,48},{612,869}},rabbit={16898613699,{48,48},{869,355}},["scissors-square"]={16898613699,{48,48},{869,808}},["check-square"]={16898612819,{48,48},{771,808}},["train-front-tunnel"]={16898613869,{48,48},{771,404}},["panel-left-dashed"]={16898613613,{48,48},{661,967}},fish={16898613353,{48,48},{869,147}},slack={16898613777,{48,48},{0,918}},sliders={16898613777,{48,48},{404,771}},["message-circle-warning"]={16898613613,{48,48},{771,612}},map={16898613613,{48,48},{306,771}},route={16898613699,{48,48},{404,918}},["arrow-up-left"]={16898612629,{48,48},{661,869}},award={16898612629,{48,48},{918,661}},["message-square-plus"]={16898613613,{48,48},{49,869}},["unfold-horizontal"]={16898613869,{48,48},{355,869}},["area-chart"]={16898612629,{48,48},{869,98}},["music-4"]={16898613613,{48,48},{306,967}},["shield-x"]={16898613777,{48,48},{514,820}},["plane-landing"]={16898613699,{48,48},{771,147}},["disc-3"]={16898613044,{48,48},{771,857}},["columns-4"]={16898613044,{48,48},{710,771}},["archive-x"]={16898612629,{48,48},{967,0}},["square-dashed-kanban"]={16898613777,{48,48},{98,918}},["users-2"]={16898613869,{48,48},{612,918}},["shield-off"]={16898613777,{48,48},{820,514}},compass={16898613044,{48,48},{514,967}},vegan={16898613869,{48,48},{967,355}},["message-circle-plus"]={16898613613,{48,48},{257,869}},["stop-circle"]={16898613777,{48,48},{453,918}},nut={16898613613,{48,48},{967,355}},search={16898613699,{48,48},{918,857}},files={16898613353,{48,48},{771,710}},["send-to-back"]={16898613699,{48,48},{820,955}},["alarm-clock"]={16898612629,{48,48},{257,820}},["shopping-basket"]={16898613777,{48,48},{0,869}},send={16898613699,{48,48},{967,857}},["chevron-left-square"]={16898612819,{48,48},{453,918}},["terminal-square"]={16898613869,{48,48},{0,820}},wifi={16898613869,{48,48},{869,808}},["skip-back"]={16898613777,{48,48},{147,771}},["wrap-text"]={16898613869,{48,48},{869,857}},["file-scan"]={16898613353,{48,48},{820,147}},["message-square-dashed"]={16898613613,{48,48},{918,0}},trophy={16898613869,{48,48},{820,147}},umbrella={16898613869,{48,48},{869,355}},touchpad={16898613869,{48,48},{49,869}},["clipboard-copy"]={16898613044,{48,48},{820,563}},pentagon={16898613699,{48,48},{771,306}},["arrow-up-from-line"]={16898612629,{48,48},{820,710}},["circle-chevron-up"]={16898613044,{48,48},{771,0}},worm={16898613869,{48,48},{918,808}},["lamp-desk"]={16898613509,{48,48},{355,918}},["circle-arrow-up"]={16898612819,{48,48},{967,857}},zap={16898613869,{48,48},{918,906}},boxes={16898612819,{48,48},{196,771}},["swiss-franc"]={16898613777,{48,48},{820,857}},["move-left"]={16898613613,{48,48},{98,918}},["chevron-up"]={16898612819,{48,48},{710,918}},instagram={16898613509,{48,48},{514,967}},["pen-tool"]={16898613699,{48,48},{820,0}},["pencil-ruler"]={16898613699,{48,48},{0,820}},["grid-2x2"]={16898613509,{48,48},{771,98}},["arrow-big-down-dash"]={16898612629,{48,48},{771,196}},["clipboard-edit"]={16898613044,{48,48},{771,612}},mic={16898613613,{48,48},{820,612}},["file-minus-2"]={16898613353,{48,48},{869,563}},gitlab={16898613509,{48,48},{820,257}},["rotate-3d"]={16898613699,{48,48},{147,918}},["spell-check"]={16898613777,{48,48},{196,771}},popcorn={16898613699,{48,48},{612,820}},blocks={16898612819,{48,48},{49,820}},["washing-machine"]={16898613869,{48,48},{918,710}},siren={16898613777,{48,48},{771,147}},["cloud-sun"]={16898613044,{48,48},{0,967}},circle={16898613044,{48,48},{771,355}},["shield-alert"]={16898613777,{48,48},{49,771}},rainbow={16898613699,{48,48},{918,563}},["separator-vertical"]={16898613699,{48,48},{869,955}},ampersands={16898612629,{48,48},{355,820}},["user-search"]={16898613869,{48,48},{918,612}},fence={16898613353,{48,48},{98,771}},["square-user-round"]={16898613777,{48,48},{355,967}},sunrise={16898613777,{48,48},{453,967}},strikethrough={16898613777,{48,48},{869,759}},["calendar-days"]={16898612819,{48,48},{869,147}},["dollar-sign"]={16898613044,{48,48},{820,857}},["message-square-quote"]={16898613613,{48,48},{0,918}},["list-minus"]={16898613509,{48,48},{820,808}},["cloud-hail"]={16898613044,{48,48},{967,0}},upload={16898613869,{48,48},{612,869}},["app-window-mac"]={16898612629,{48,48},{661,771}},ellipsis={16898613353,{48,48},{771,49}},["copy-check"]={16898613044,{48,48},{453,820}},history={16898613509,{48,48},{869,98}},satellite={16898613699,{48,48},{147,967}},["bookmark-plus"]={16898612819,{48,48},{612,820}},["folder-key"]={16898613353,{48,48},{355,967}},["lamp-ceiling"]={16898613509,{48,48},{404,869}},["circle-power"]={16898613044,{48,48},{820,49}},hourglass={16898613509,{48,48},{49,918}},keyboard={16898613509,{48,48},{453,820}},triangle={16898613869,{48,48},{869,98}},["layers-2"]={16898613509,{48,48},{196,869}},["battery-full"]={16898612629,{48,48},{967,808}},["user-minus"]={16898613869,{48,48},{49,967}},["x-octagon"]={16898613869,{48,48},{967,808}},["folder-tree"]={16898613353,{48,48},{967,404}},command={16898613044,{48,48},{563,918}},["badge-dollar-sign"]={16898612629,{48,48},{918,196}},["align-start-vertical"]={16898612629,{48,48},{820,98}},["chevrons-down"]={16898612819,{48,48},{967,196}},["bluetooth-off"]={16898612819,{48,48},{869,257}},cannabis={16898612819,{48,48},{710,820}},book={16898612819,{48,48},{820,612}},hammer={16898613509,{48,48},{306,820}},["circle-minus"]={16898613044,{48,48},{771,306}},["audio-waveform"]={16898612629,{48,48},{967,612}},["moon-star"]={16898613613,{48,48},{355,869}},["arrow-right"]={16898612629,{48,48},{453,820}},sparkle={16898613777,{48,48},{967,0}},wand={16898613869,{48,48},{404,967}},["calendar-minus-2"]={16898612819,{48,48},{147,869}},["copy-minus"]={16898613044,{48,48},{404,869}},["folder-input"]={16898613353,{48,48},{453,869}},["book-image"]={16898612819,{48,48},{771,147}},shirt={16898613777,{48,48},{98,771}},["server-off"]={16898613699,{48,48},{967,955}},["move-up"]={16898613613,{48,48},{869,404}},["plug-2"]={16898613699,{48,48},{869,306}},radio={16898613699,{48,48},{306,918}},brackets={16898612819,{48,48},{98,869}},["calendar-heart"]={16898612819,{48,48},{196,820}},["list-ordered"]={16898613509,{48,48},{710,918}},["mic-off"]={16898613613,{48,48},{918,514}},["arrow-big-left"]={16898612629,{48,48},{98,869}},["square-split-horizontal"]={16898613777,{48,48},{918,404}},["tree-deciduous"]={16898613869,{48,48},{869,563}},["sun-snow"]={16898613777,{48,48},{196,967}},["user-2"]={16898613869,{48,48},{514,967}},["help-circle"]={16898613509,{48,48},{563,869}},["clock-2"]={16898613044,{48,48},{771,404}},["calendar-fold"]={16898612819,{48,48},{820,196}},["fish-off"]={16898613353,{48,48},{967,49}},baby={16898612629,{48,48},{771,808}},leaf={16898613509,{48,48},{918,661}},["fold-vertical"]={16898613353,{48,48},{661,869}},hop={16898613509,{48,48},{196,771}},paperclip={16898613613,{48,48},{918,857}},cigarette={16898612819,{48,48},{967,759}},minus={16898613613,{48,48},{771,196}},["smile-plus"]={16898613777,{48,48},{918,514}},["chevron-right-circle"]={16898612819,{48,48},{967,661}},["star-off"]={16898613777,{48,48},{612,967}},["git-pull-request-closed"]={16898613509,{48,48},{771,514}},["badge-check"]={16898612629,{48,48},{967,147}},["test-tube-2"]={16898613869,{48,48},{771,306}},["kanban-square"]={16898613509,{48,48},{98,918}},["plug-zap"]={16898613699,{48,48},{771,404}},["heading-4"]={16898613509,{48,48},{820,355}},["git-pull-request-create"]={16898613509,{48,48},{820,0}},["replace-all"]={16898613699,{48,48},{771,759}},["receipt-swiss-franc"]={16898613699,{48,48},{967,49}},["square-dashed-bottom-code"]={16898613777,{48,48},{196,820}},["clock-7"]={16898613044,{48,48},{918,514}},["scan-text"]={16898613699,{48,48},{661,967}},["shower-head"]={16898613777,{48,48},{771,355}},["equal-not"]={16898613353,{48,48},{49,771}},["move-down"]={16898613613,{48,48},{196,820}},["ticket-slash"]={16898613869,{48,48},{820,563}},ruler={16898613699,{48,48},{710,869}},["circle-user-round"]={16898613044,{48,48},{0,869}},subscript={16898613777,{48,48},{820,808}},["alarm-minus"]={16898612629,{48,48},{820,514}},["layout-grid"]={16898613509,{48,48},{918,404}},cog={16898613044,{48,48},{918,563}},dog={16898613044,{48,48},{869,808}},swords={16898613777,{48,48},{967,759}},["panel-right-dashed"]={16898613613,{48,48},{967,710}},["ship-wheel"]={16898613777,{48,48},{820,49}},bot={16898612819,{48,48},{869,98}},["trash-2"]={16898613869,{48,48},{257,918}},["chevron-down-square"]={16898612819,{48,48},{918,196}},dot={16898613044,{48,48},{918,808}},["file-symlink"]={16898613353,{48,48},{967,257}},["clipboard-paste"]={16898613044,{48,48},{514,869}},plug={16898613699,{48,48},{404,771}},["book-heart"]={16898612819,{48,48},{820,98}},["circle-parking"]={16898613044,{48,48},{820,514}},["volume-1"]={16898613869,{48,48},{820,759}},["circle-chevron-right"]={16898612819,{48,48},{967,955}},speaker={16898613777,{48,48},{869,98}},timer={16898613869,{48,48},{918,0}},forward={16898613353,{48,48},{771,857}},["file-up"]={16898613353,{48,48},{453,771}},["between-vertical-start"]={16898612819,{48,48},{820,514}},database={16898613044,{48,48},{710,869}},["panel-right"]={16898613613,{48,48},{820,857}},["log-out"]={16898613509,{48,48},{820,955}},["git-branch-plus"]={16898613353,{48,48},{967,857}},["clipboard-minus"]={16898613044,{48,48},{563,820}},["file-text"]={16898613353,{48,48},{869,355}},["arrow-right-circle"]={16898612629,{48,48},{49,967}},["table-rows-split"]={16898613777,{48,48},{869,906}},watch={16898613869,{48,48},{869,759}},["cloud-upload"]={16898613044,{48,48},{967,257}},banknote={16898612629,{48,48},{453,967}},["folder-up"]={16898613353,{48,48},{918,453}},["list-checks"]={16898613509,{48,48},{404,967}},bug={16898612819,{48,48},{257,967}},["circle-chevron-left"]={16898612819,{48,48},{918,955}},["arrow-down"]={16898612629,{48,48},{967,49}},["arrow-up-down"]={16898612629,{48,48},{918,612}},["file-audio"]={16898613353,{48,48},{771,355}},["whole-word"]={16898613869,{48,48},{967,710}},monitor={16898613613,{48,48},{404,820}},["flag-off"]={16898613353,{48,48},{820,196}},["align-right"]={16898612629,{48,48},{918,0}},["circle-stop"]={16898613044,{48,48},{49,820}},infinity={16898613509,{48,48},{661,820}},["arrow-big-down"]={16898612629,{48,48},{196,771}},["circle-parking-off"]={16898613044,{48,48},{257,820}},["calendar-x-2"]={16898612819,{48,48},{453,820}},["user-plus"]={16898613869,{48,48},{918,355}},["move-diagonal-2"]={16898613613,{48,48},{967,49}},["gallery-horizontal-end"]={16898613353,{48,48},{967,710}},["panel-top-dashed"]={16898613613,{48,48},{710,967}},["tram-front"]={16898613869,{48,48},{306,869}},podcast={16898613699,{48,48},{820,612}},["image-minus"]={16898613509,{48,48},{771,453}},["flip-vertical-2"]={16898613353,{48,48},{967,563}},github={16898613509,{48,48},{0,820}},pocket={16898613699,{48,48},{869,563}},printer={16898613699,{48,48},{196,771}},["megaphone-off"]={16898613613,{48,48},{514,820}},["file-bar-chart-2"]={16898613353,{48,48},{869,514}},["arrow-big-right"]={16898612629,{48,48},{0,967}},replace={16898613699,{48,48},{710,820}},["toy-brick"]={16898613869,{48,48},{918,257}},["square-chevron-down"]={16898613777,{48,48},{514,967}},["dice-1"]={16898613044,{48,48},{147,967}},["scan-search"]={16898613699,{48,48},{710,918}},["sticky-note"]={16898613777,{48,48},{918,453}},["shield-check"]={16898613777,{48,48},{820,257}},["hand-metal"]={16898613509,{48,48},{771,612}},["x-circle"]={16898613869,{48,48},{771,955}},["spell-check-2"]={16898613777,{48,48},{771,196}},["minus-square"]={16898613613,{48,48},{820,147}},["box-select"]={16898612819,{48,48},{820,147}},sprout={16898613777,{48,48},{918,306}},waypoints={16898613869,{48,48},{771,857}},["ice-cream-cone"]={16898613509,{48,48},{918,306}},["text-quote"]={16898613869,{48,48},{514,820}},wind={16898613869,{48,48},{820,857}},["layout-panel-left"]={16898613509,{48,48},{453,869}},["circle-percent"]={16898613044,{48,48},{563,771}},["circle-arrow-out-down-right"]={16898612819,{48,48},{967,808}},["square-x"]={16898613777,{48,48},{918,661}},italic={16898613509,{48,48},{967,49}},["step-forward"]={16898613777,{48,48},{196,918}},["a-arrow-down"]={16898612629,{48,48},{771,0}},container={16898613044,{48,48},{967,306}},sticker={16898613777,{48,48},{967,404}},["parking-circle-off"]={16898613613,{48,48},{820,955}},import={16898613509,{48,48},{967,514}},vault={16898613869,{48,48},{98,967}},["square-terminal"]={16898613777,{48,48},{404,918}},["file-music"]={16898613353,{48,48},{771,661}},beef={16898612819,{48,48},{0,771}},["route-off"]={16898613699,{48,48},{453,869}},["timer-reset"]={16898613869,{48,48},{514,869}},["monitor-stop"]={16898613613,{48,48},{820,404}},smile={16898613777,{48,48},{869,563}},["signpost-big"]={16898613777,{48,48},{869,49}},["folder-lock"]={16898613353,{48,48},{967,612}},["square-percent"]={16898613777,{48,48},{661,869}},["navigation-off"]={16898613613,{48,48},{820,710}},["arrow-left"]={16898612629,{48,48},{98,918}},["car-taxi-front"]={16898612819,{48,48},{967,98}},laugh={16898613509,{48,48},{869,196}},["x-square"]={16898613869,{48,48},{918,857}},["step-back"]={16898613777,{48,48},{918,196}},equal={16898613353,{48,48},{0,820}},megaphone={16898613613,{48,48},{869,0}},["calendar-x"]={16898612819,{48,48},{404,869}},egg={16898613353,{48,48},{514,771}},["video-off"]={16898613869,{48,48},{404,918}},["japanese-yen"]={16898613509,{48,48},{820,196}},library={16898613509,{48,48},{710,869}},["file-terminal"]={16898613353,{48,48},{918,306}},quote={16898613699,{48,48},{918,306}},accessibility={16898612629,{48,48},{257,771}},["square-library"]={16898613777,{48,48},{355,918}},salad={16898613699,{48,48},{967,147}},["tally-2"]={16898613869,{48,48},{771,0}},sheet={16898613777,{48,48},{820,0}},["circle-check-big"]={16898612819,{48,48},{918,906}},["map-pinned"]={16898613613,{48,48},{771,306}},["corner-down-left"]={16898613044,{48,48},{771,759}},dribbble={16898613044,{48,48},{918,857}},["pilcrow-square"]={16898613699,{48,48},{771,612}},["lamp-wall-up"]={16898613509,{48,48},{918,612}},["book-dashed"]={16898612819,{48,48},{514,869}},["unfold-vertical"]={16898613869,{48,48},{306,918}},["tree-pine"]={16898613869,{48,48},{771,661}},["receipt-indian-rupee"]={16898613699,{48,48},{661,820}},["check-circle-2"]={16898612819,{48,48},{918,661}},["flask-conical"]={16898613353,{48,48},{453,820}},["package-search"]={16898613613,{48,48},{612,967}},columns={16898613044,{48,48},{661,820}},["folder-sync"]={16898613353,{48,48},{147,967}},fingerprint={16898613353,{48,48},{563,918}},["arrow-up-narrow-wide"]={16898612629,{48,48},{612,918}},frame={16898613353,{48,48},{710,918}},["clock-12"]={16898613044,{48,48},{820,355}},images={16898613509,{48,48},{257,967}},lollipop={16898613509,{48,48},{967,857}},["folder-root"]={16898613353,{48,48},{612,967}},["arrow-left-circle"]={16898612629,{48,48},{918,98}},["lamp-floor"]={16898613509,{48,48},{306,967}},image={16898613509,{48,48},{306,918}},["baggage-claim"]={16898612629,{48,48},{967,196}},bike={16898612819,{48,48},{771,563}},option={16898613613,{48,48},{355,967}},["scroll-text"]={16898613699,{48,48},{967,759}},["toggle-right"]={16898613869,{48,48},{820,98}},["ferris-wheel"]={16898613353,{48,48},{49,820}},["camera-off"]={16898612819,{48,48},{306,967}},["function-square"]={16898613353,{48,48},{453,967}},group={16898613509,{48,48},{820,306}},codesandbox={16898613044,{48,48},{257,967}},["message-circle-question"]={16898613613,{48,48},{869,514}},["tent-tree"]={16898613869,{48,48},{771,49}},["rectangle-horizontal"]={16898613699,{48,48},{196,820}},subtitles={16898613777,{48,48},{771,857}},mail={16898613613,{48,48},{820,0}},["brain-cog"]={16898612819,{48,48},{0,967}},["hand-platter"]={16898613509,{48,48},{612,771}},club={16898613044,{48,48},{771,453}},twitch={16898613869,{48,48},{49,918}},pipette={16898613699,{48,48},{869,49}},user={16898613869,{48,48},{661,869}},["align-vertical-space-around"]={16898612629,{48,48},{869,306}},["test-tubes"]={16898613869,{48,48},{820,514}},wheat={16898613869,{48,48},{453,967}},["axis-3d"]={16898612629,{48,48},{820,759}},folders={16898613353,{48,48},{967,661}},diff={16898613044,{48,48},{869,759}},puzzle={16898613699,{48,48},{49,918}},["package-2"]={16898613613,{48,48},{869,710}},indent={16898613509,{48,48},{771,710}},tangent={16898613869,{48,48},{771,514}},["power-circle"]={16898613699,{48,48},{967,0}},["badge-pound-sterling"]={16898612629,{48,48},{869,759}},["mail-minus"]={16898613509,{48,48},{967,955}},["circle-slash"]={16898613044,{48,48},{98,771}},["app-window"]={16898612629,{48,48},{612,820}},["move-down-right"]={16898613613,{48,48},{820,196}},["parking-square-off"]={16898613613,{48,48},{869,955}},["clipboard-pen"]={16898613044,{48,48},{869,49}},["notepad-text"]={16898613613,{48,48},{147,918}},["signal-low"]={16898613777,{48,48},{612,771}},home={16898613509,{48,48},{820,147}},list={16898613509,{48,48},{869,808}},plus={16898613699,{48,48},{257,918}},["square-arrow-right"]={16898613777,{48,48},{918,563}},["scissors-square-dashed-bottom"]={16898613699,{48,48},{918,759}},["remove-formatting"]={16898613699,{48,48},{967,563}},["bookmark-check"]={16898612819,{48,48},{771,661}},["send-horizontal"]={16898613699,{48,48},{869,906}},["chevrons-left-right"]={16898612819,{48,48},{196,967}},["folder-kanban"]={16898613353,{48,48},{404,918}},["a-arrow-up"]={16898612629,{48,48},{0,771}},["list-restart"]={16898613509,{48,48},{967,196}},["cloud-moon"]={16898613044,{48,48},{820,147}},["book-audio"]={16898612819,{48,48},{771,612}},["vibrate-off"]={16898613869,{48,48},{869,453}},["mail-check"]={16898613509,{48,48},{918,955}},["panel-top-inactive"]={16898613613,{48,48},{967,759}},["file-type-2"]={16898613353,{48,48},{820,404}},["file-code"]={16898613353,{48,48},{869,49}},donut={16898613044,{48,48},{771,906}},["list-todo"]={16898613509,{48,48},{967,453}},dna={16898613044,{48,48},{967,710}},["monitor-down"]={16898613613,{48,48},{98,869}},["cassette-tape"]={16898612819,{48,48},{918,404}},["battery-low"]={16898612629,{48,48},{918,857}},flashlight={16898613353,{48,48},{869,404}},wine={16898613869,{48,48},{710,967}},signpost={16898613777,{48,48},{820,98}},["creative-commons"]={16898613044,{48,48},{147,918}},["globe-2"]={16898613509,{48,48},{257,820}},landmark={16898613509,{48,48},{771,759}},["map-pin"]={16898613613,{48,48},{820,257}},["clipboard-x"]={16898613044,{48,48},{98,820}},loader={16898613509,{48,48},{710,967}},bold={16898612819,{48,48},{355,771}},["dice-2"]={16898613044,{48,48},{967,404}},["file-type"]={16898613353,{48,48},{771,453}},utensils={16898613869,{48,48},{869,196}},beer={16898612819,{48,48},{257,771}},["file-video-2"]={16898613353,{48,48},{404,820}},["chef-hat"]={16898612819,{48,48},{661,918}},rocket={16898613699,{48,48},{918,147}},bird={16898612819,{48,48},{869,0}},["file-x"]={16898613353,{48,48},{869,612}},["move-diagonal"]={16898613613,{48,48},{918,98}},["folder-minus"]={16898613353,{48,48},{918,661}},["door-closed"]={16898613044,{48,48},{710,967}},["bluetooth-connected"]={16898612819,{48,48},{0,869}},["layout-template"]={16898613509,{48,48},{355,967}},["air-vent"]={16898612629,{48,48},{820,0}},["rows-2"]={16898613699,{48,48},{967,612}},["pen-square"]={16898613699,{48,48},{514,771}},["panel-bottom-close"]={16898613613,{48,48},{967,661}},["hand-heart"]={16898613509,{48,48},{869,514}},["file-code-2"]={16898613353,{48,48},{918,0}},["arrow-down-wide-narrow"]={16898612629,{48,48},{563,918}},["clock-10"]={16898613044,{48,48},{918,257}},drumstick={16898613044,{48,48},{869,955}},["disc-2"]={16898613044,{48,48},{820,808}},["skip-forward"]={16898613777,{48,48},{98,820}},skull={16898613777,{48,48},{49,869}},["chevron-left"]={16898612819,{48,48},{404,967}},["split-square-vertical"]={16898613777,{48,48},{49,918}},snowflake={16898613777,{48,48},{771,661}},key={16898613509,{48,48},{869,404}},["clock-11"]={16898613044,{48,48},{869,306}},["sliders-horizontal"]={16898613777,{48,48},{820,355}},["ticket-plus"]={16898613869,{48,48},{869,514}},["square-dashed-bottom"]={16898613777,{48,48},{147,869}},["mic-vocal"]={16898613613,{48,48},{869,563}},["activity-square"]={16898612629,{48,48},{771,514}},["monitor-pause"]={16898613613,{48,48},{0,967}},["book-open-check"]={16898612819,{48,48},{918,257}},projector={16898613699,{48,48},{147,820}},["lasso-select"]={16898613509,{48,48},{967,98}},["folder-open-dot"]={16898613353,{48,48},{869,710}},["align-justify"]={16898612629,{48,48},{563,820}},["log-in"]={16898613509,{48,48},{869,906}},tag={16898613777,{48,48},{967,906}},bus={16898612819,{48,48},{820,661}},["locate-fixed"]={16898613509,{48,48},{967,759}},["bed-single"]={16898612629,{48,48},{967,955}},["dice-4"]={16898613044,{48,48},{453,918}},["file-spreadsheet"]={16898613353,{48,48},{49,918}},["sun-dim"]={16898613777,{48,48},{710,918}},["clipboard-list"]={16898613044,{48,48},{612,771}},gamepad={16898613353,{48,48},{967,759}},["contact-round"]={16898613044,{48,48},{98,918}},["align-horizontal-space-around"]={16898612629,{48,48},{771,612}},["music-2"]={16898613613,{48,48},{404,869}},["hard-hat"]={16898613509,{48,48},{771,147}},["file-badge"]={16898613353,{48,48},{257,869}},["battery-warning"]={16898612629,{48,48},{820,955}},rows={16898613699,{48,48},{820,759}},["arrow-down-from-line"]={16898612629,{48,48},{404,820}},["rows-4"]={16898613699,{48,48},{869,710}},biohazard={16898612819,{48,48},{514,820}},["book-up"]={16898612819,{48,48},{257,918}},["heading-6"]={16898613509,{48,48},{404,771}},["scale-3d"]={16898613699,{48,48},{453,918}},["chevron-down-circle"]={16898612819,{48,48},{967,147}},["mail-x"]={16898613613,{48,48},{514,771}},["square-dashed-mouse-pointer"]={16898613777,{48,48},{49,967}},["user-cog"]={16898613869,{48,48},{147,869}},["satellite-dish"]={16898613699,{48,48},{196,918}},["alarm-clock-minus"]={16898612629,{48,48},{820,257}},pizza={16898613699,{48,48},{820,98}},["pc-case"]={16898613699,{48,48},{257,771}},["move-down-left"]={16898613613,{48,48},{869,147}},school={16898613699,{48,48},{453,967}},orbit={16898613613,{48,48},{967,612}},["file-minus"]={16898613353,{48,48},{820,612}},["rotate-ccw"]={16898613699,{48,48},{967,355}},["align-horizontal-justify-center"]={16898612629,{48,48},{257,869}},["phone-incoming"]={16898613699,{48,48},{820,49}},antenna={16898612629,{48,48},{869,563}},["memory-stick"]={16898613613,{48,48},{771,98}},["scan-eye"]={16898613699,{48,48},{869,759}},["align-center-vertical"]={16898612629,{48,48},{49,820}},["square-check"]={16898613777,{48,48},{563,918}},["align-end-horizontal"]={16898612629,{48,48},{869,257}},["message-square-off"]={16898613613,{48,48},{98,820}},["folder-open"]={16898613353,{48,48},{820,759}},["contact-2"]={16898613044,{48,48},{147,869}},["parking-circle"]={16898613613,{48,48},{967,857}},["menu-square"]={16898613613,{48,48},{98,771}},["hand-coins"]={16898613509,{48,48},{257,869}},["message-circle-code"]={16898613613,{48,48},{869,257}},["arrow-up-wide-narrow"]={16898612629,{48,48},{147,918}},["copy-x"]={16898613044,{48,48},{967,563}},clock={16898613044,{48,48},{771,661}},["file-pen"]={16898613353,{48,48},{563,869}},["git-compare-arrows"]={16898613353,{48,48},{918,955}},["square-arrow-down-right"]={16898613777,{48,48},{771,453}},joystick={16898613509,{48,48},{196,820}},["align-vertical-space-between"]={16898612629,{48,48},{820,355}},["file-pie-chart"]={16898613353,{48,48},{514,918}},gem={16898613353,{48,48},{918,857}},["calendar-plus"]={16898612819,{48,48},{918,355}},["bell-electric"]={16898612819,{48,48},{514,771}},["arrow-down-z-a"]={16898612629,{48,48},{514,967}},bath={16898612629,{48,48},{820,906}},anvil={16898612629,{48,48},{820,612}},["unlink-2"]={16898613869,{48,48},{918,563}},["archive-restore"]={16898612629,{48,48},{514,918}},archive={16898612629,{48,48},{918,49}},["folder-check"]={16898613353,{48,48},{563,967}},["arrow-big-left-dash"]={16898612629,{48,48},{147,820}},["book-key"]={16898612819,{48,48},{147,771}},ribbon={16898613699,{48,48},{967,98}},["package-open"]={16898613613,{48,48},{710,869}},["arrow-down-0-1"]={16898612629,{48,48},{869,355}},["library-big"]={16898613509,{48,48},{820,759}},["file-json"]={16898613353,{48,48},{771,404}},["arrow-down-a-z"]={16898612629,{48,48},{771,453}},["arrow-down-left"]={16898612629,{48,48},{257,967}},["square-scissors"]={16898613777,{48,48},{147,918}},["move-up-left"]={16898613613,{48,48},{967,306}},["arrow-down-up"]={16898612629,{48,48},{612,869}},["folder-heart"]={16898613353,{48,48},{869,453}},["gauge-circle"]={16898613353,{48,48},{820,906}},percent={16898613699,{48,48},{771,563}},["arrow-up-1-0"]={16898612629,{48,48},{355,918}},["arrow-up-a-z"]={16898612629,{48,48},{306,967}},["circle-arrow-right"]={16898612819,{48,48},{820,955}},["panel-bottom-inactive"]={16898613613,{48,48},{869,759}},["arrow-up"]={16898612629,{48,48},{967,355}},asterisk={16898612629,{48,48},{869,453}},["gallery-vertical"]={16898613353,{48,48},{771,906}},["swatch-book"]={16898613777,{48,48},{869,808}},["receipt-cent"]={16898613699,{48,48},{771,710}},["audio-lines"]={16898612629,{48,48},{355,967}},["folder-archive"]={16898613353,{48,48},{612,918}},["folder-symlink"]={16898613353,{48,48},{196,918}},["columns-3"]={16898613044,{48,48},{771,710}},ban={16898612629,{48,48},{196,967}},["message-square-x"]={16898613613,{48,48},{404,771}},["paint-roller"]={16898613613,{48,48},{147,967}},["folder-search-2"]={16898613353,{48,48},{967,147}},fan={16898613353,{48,48},{869,0}},["badge-euro"]={16898612629,{48,48},{196,918}},["badge-info"]={16898612629,{48,48},{918,453}},["building-2"]={16898612819,{48,48},{967,514}},square={16898613777,{48,48},{869,710}},medal={16898613613,{48,48},{563,771}},cake={16898612819,{48,48},{612,869}},["cloud-rain"]={16898613044,{48,48},{147,820}},["maximize-2"]={16898613613,{48,48},{820,514}},shell={16898613777,{48,48},{771,49}},wrench={16898613869,{48,48},{820,906}},badge={16898612629,{48,48},{661,967}},codepen={16898613044,{48,48},{306,918}},["corner-right-down"]={16898613044,{48,48},{563,967}},["flag-triangle-right"]={16898613353,{48,48},{147,869}},network={16898613613,{48,48},{710,820}},["bar-chart-3"]={16898612629,{48,48},{918,759}},bell={16898612819,{48,48},{820,257}},["bar-chart"]={16898612629,{48,48},{967,759}},ratio={16898613699,{48,48},{820,661}},["square-chevron-up"]={16898613777,{48,48},{869,147}},["brick-wall"]={16898612819,{48,48},{918,306}},["user-check"]={16898613869,{48,48},{918,98}},proportions={16898613699,{48,48},{98,869}},["alert-octagon"]={16898612629,{48,48},{820,49}},plane={16898613699,{48,48},{98,820}},["webhook-off"]={16898613869,{48,48},{661,967}},["thermometer-sun"]={16898613869,{48,48},{0,869}},["square-arrow-left"]={16898613777,{48,48},{404,820}},["mouse-pointer"]={16898613613,{48,48},{612,869}},heart={16898613509,{48,48},{661,771}},["test-tube-diagonal"]={16898613869,{48,48},{306,771}},["briefcase-medical"]={16898612819,{48,48},{820,404}},["align-vertical-distribute-start"]={16898612629,{48,48},{98,820}},mailbox={16898613613,{48,48},{771,49}},["bell-off"]={16898612819,{48,48},{771,49}},binary={16898612819,{48,48},{563,771}},["book-open-text"]={16898612819,{48,48},{869,306}},split={16898613777,{48,48},{0,967}},twitter={16898613869,{48,48},{0,967}},calculator={16898612819,{48,48},{563,918}},forklift={16898613353,{48,48},{869,759}},bluetooth={16898612819,{48,48},{771,355}},folder={16898613353,{48,48},{404,967}},["square-kanban"]={16898613777,{48,48},{404,869}},["message-square-diff"]={16898613613,{48,48},{869,49}},["square-sigma"]={16898613777,{48,48},{98,967}},["alarm-plus"]={16898612629,{48,48},{771,563}},star={16898613777,{48,48},{967,147}},["rotate-ccw-square"]={16898613699,{48,48},{98,967}},castle={16898612819,{48,48},{453,869}},["book-down"]={16898612819,{48,48},{918,0}},["file-volume-2"]={16898613353,{48,48},{306,918}},["book-headphones"]={16898612819,{48,48},{869,49}},power={16898613699,{48,48},{820,147}},album={16898612629,{48,48},{514,820}},["book-marked"]={16898612819,{48,48},{49,869}},["book-open"]={16898612819,{48,48},{820,355}},["file-box"]={16898613353,{48,48},{771,612}},["book-text"]={16898612819,{48,48},{404,771}},telescope={16898613869,{48,48},{820,0}},["glass-water"]={16898613509,{48,48},{771,306}},filter={16898613353,{48,48},{612,869}},glasses={16898613509,{48,48},{306,771}},["piggy-bank"]={16898613699,{48,48},{820,563}},["book-type"]={16898612819,{48,48},{355,820}},cuboid={16898613044,{48,48},{355,967}},["cloud-off"]={16898613044,{48,48},{771,196}},["check-check"]={16898612819,{48,48},{967,612}},activity={16898612629,{48,48},{514,771}},axe={16898612629,{48,48},{869,710}},["plane-takeoff"]={16898613699,{48,48},{147,771}},["book-x"]={16898612819,{48,48},{869,563}},["cloud-rain-wind"]={16898613044,{48,48},{196,771}},bookmark={16898612819,{48,48},{514,918}},["zoom-in"]={16898613869,{48,48},{869,955}},["square-pilcrow"]={16898613777,{48,48},{563,967}},["file-axis-3d"]={16898613353,{48,48},{355,771}},["receipt-euro"]={16898613699,{48,48},{710,771}},["brain-circuit"]={16898612819,{48,48},{49,918}},["briefcase-business"]={16898612819,{48,48},{869,355}},["bug-play"]={16898612819,{48,48},{306,918}},["tally-3"]={16898613869,{48,48},{0,771}},["clipboard-type"]={16898613044,{48,48},{147,771}},brush={16898612819,{48,48},{404,820}},["tally-5"]={16898613869,{48,48},{257,771}},["cable-car"]={16898612819,{48,48},{771,710}},cable={16898612819,{48,48},{710,771}},["calendar-check"]={16898612819,{48,48},{967,49}},["user-square-2"]={16898613869,{48,48},{869,661}},["calendar-minus"]={16898612819,{48,48},{98,918}},["calendar-plus-2"]={16898612819,{48,48},{967,306}},linkedin={16898613509,{48,48},{453,918}},["life-buoy"]={16898613509,{48,48},{661,918}},["calendar-search"]={16898612819,{48,48},{820,453}},["circle-chevron-down"]={16898612819,{48,48},{967,906}},["volume-2"]={16898613869,{48,48},{771,808}},["battery-charging"]={16898612629,{48,48},{771,955}},["russian-ruble"]={16898613699,{48,48},{661,918}},["square-arrow-up-left"]={16898613777,{48,48},{869,612}},["earth-lock"]={16898613353,{48,48},{771,0}},footprints={16898613353,{48,48},{918,710}},hash={16898613509,{48,48},{147,771}},building={16898612819,{48,48},{918,563}},ear={16898613044,{48,48},{967,955}},caravan={16898612819,{48,48},{869,196}},carrot={16898612819,{48,48},{196,869}},cherry={16898612819,{48,48},{612,967}},["user-check-2"]={16898613869,{48,48},{967,49}},["shield-plus"]={16898613777,{48,48},{771,563}},moon={16898613613,{48,48},{306,918}},["bell-minus"]={16898612819,{48,48},{820,0}},["image-up"]={16898613509,{48,48},{355,869}},["case-sensitive"]={16898612819,{48,48},{98,967}},drum={16898613044,{48,48},{918,906}},["arrow-up-z-a"]={16898612629,{48,48},{98,967}},sun={16898613777,{48,48},{967,453}},["gantt-chart-square"]={16898613353,{48,48},{918,808}},["align-horizontal-justify-start"]={16898612629,{48,48},{820,563}},["file-key"]={16898613353,{48,48},{355,820}},["monitor-smartphone"]={16898613613,{48,48},{918,306}},["move-3d"]={16898613613,{48,48},{514,967}},["scissors-line-dashed"]={16898613699,{48,48},{967,710}},["text-select"]={16898613869,{48,48},{820,49}},["case-lower"]={16898612819,{48,48},{147,918}},["plus-circle"]={16898613699,{48,48},{355,820}},["ticket-check"]={16898613869,{48,48},{355,771}},pyramid={16898613699,{48,48},{0,967}},["chevron-last"]={16898612819,{48,48},{967,404}},["user-cog-2"]={16898613869,{48,48},{196,820}},["refresh-cw-off"]={16898613699,{48,48},{453,820}},piano={16898613699,{48,48},{771,355}},["picture-in-picture-2"]={16898613699,{48,48},{306,820}},["user-round"]={16898613869,{48,48},{967,563}},["flower-2"]={16898613353,{48,48},{869,661}},["chevron-up-square"]={16898612819,{48,48},{771,857}},["chevrons-left"]={16898612819,{48,48},{967,453}},["chevrons-right-left"]={16898612819,{48,48},{453,967}},car={16898612819,{48,48},{918,147}},["keyboard-music"]={16898613509,{48,48},{820,453}},["star-half"]={16898613777,{48,48},{661,918}},mouse={16898613613,{48,48},{563,918}},lock={16898613509,{48,48},{918,857}},["pencil-line"]={16898613699,{48,48},{49,771}},mails={16898613613,{48,48},{49,771}},film={16898613353,{48,48},{710,771}},tablet={16898613777,{48,48},{918,906}},["circle-arrow-left"]={16898612819,{48,48},{820,906}},pi={16898613699,{48,48},{820,306}},trash={16898613869,{48,48},{918,514}},dock={16898613044,{48,48},{918,759}},["hdmi-port"]={16898613509,{48,48},{49,869}},["circle-arrow-out-up-left"]={16898612819,{48,48},{918,857}},["case-upper"]={16898612819,{48,48},{967,355}},["circle-arrow-out-up-right"]={16898612819,{48,48},{869,906}},tags={16898613777,{48,48},{918,955}},croissant={16898613044,{48,48},{967,355}},["circle-check"]={16898612819,{48,48},{869,955}},bomb={16898612819,{48,48},{257,869}},diameter={16898613044,{48,48},{967,147}},["circle-dashed"]={16898613044,{48,48},{0,771}},["bar-chart-big"]={16898612629,{48,48},{820,857}},["upload-cloud"]={16898613869,{48,48},{661,820}},["code-xml"]={16898613044,{48,48},{404,820}},divide={16898613044,{48,48},{967,453}},grape={16898613509,{48,48},{820,49}},["play-square"]={16898613699,{48,48},{0,918}},["party-popper"]={16898613613,{48,48},{918,955}},["circle-ellipsis"]={16898613044,{48,48},{820,0}},file={16898613353,{48,48},{820,661}},["user-circle-2"]={16898613869,{48,48},{869,147}},truck={16898613869,{48,48},{771,196}},["cloud-sun-rain"]={16898613044,{48,48},{49,918}},["calendar-range"]={16898612819,{48,48},{869,404}},contact={16898613044,{48,48},{49,967}},["zap-off"]={16898613869,{48,48},{967,857}},["square-check-big"]={16898613777,{48,48},{612,869}},["circle-user"]={16898613044,{48,48},{869,257}},["layout-panel-top"]={16898613509,{48,48},{404,918}},["roller-coaster"]={16898613699,{48,48},{196,869}},["laptop-minimal"]={16898613509,{48,48},{612,918}},["table-properties"]={16898613777,{48,48},{918,857}},["clipboard-check"]={16898613044,{48,48},{869,514}},layout={16898613509,{48,48},{967,612}},["indent-decrease"]={16898613509,{48,48},{869,612}},cookie={16898613044,{48,48},{869,404}},["message-square-more"]={16898613613,{48,48},{147,771}},clipboard={16898613044,{48,48},{49,869}},euro={16898613353,{48,48},{771,306}},sparkles={16898613777,{48,48},{918,49}},["heart-off"]={16898613509,{48,48},{820,612}},vibrate={16898613869,{48,48},{453,869}},["clock-3"]={16898613044,{48,48},{404,771}},["move-horizontal"]={16898613613,{48,48},{147,869}},["file-sliders"]={16898613353,{48,48},{98,869}},frown={16898613353,{48,48},{967,196}},["move-up-right"]={16898613613,{48,48},{918,355}},["cup-soda"]={16898613044,{48,48},{967,612}},["stretch-vertical"]={16898613777,{48,48},{918,710}},["refresh-cw"]={16898613699,{48,48},{404,869}},sword={16898613777,{48,48},{710,967}},["cloud-drizzle"]={16898613044,{48,48},{563,869}},["laptop-2"]={16898613509,{48,48},{661,869}},earth={16898613353,{48,48},{0,771}},slice={16898613777,{48,48},{869,306}},["land-plot"]={16898613509,{48,48},{820,710}},milk={16898613613,{48,48},{514,918}},["git-pull-request-draft"]={16898613509,{48,48},{771,49}},crown={16898613044,{48,48},{404,918}},["wallet-2"]={16898613869,{48,48},{967,147}},settings={16898613777,{48,48},{771,257}},["rotate-cw-square"]={16898613699,{48,48},{918,404}},atom={16898612629,{48,48},{404,918}},["package-x"]={16898613613,{48,48},{967,147}},["bed-double"]={16898612629,{48,48},{918,955}},["ice-cream-bowl"]={16898613509,{48,48},{967,257}},["circle-dot"]={16898613044,{48,48},{514,771}},["grip-horizontal"]={16898613509,{48,48},{49,820}},cloudy={16898613044,{48,48},{869,355}},["text-cursor-input"]={16898613869,{48,48},{771,563}},["folder-git-2"]={16898613353,{48,48},{967,355}},["message-square-code"]={16898613613,{48,48},{514,869}},clover={16898613044,{48,48},{820,404}},["arrow-down-narrow-wide"]={16898612629,{48,48},{967,514}},code={16898613044,{48,48},{355,869}},["user-x"]={16898613869,{48,48},{710,820}},coins={16898613044,{48,48},{869,612}},dumbbell={16898613044,{48,48},{967,906}},weight={16898613869,{48,48},{196,967}},["alert-triangle"]={16898612629,{48,48},{771,98}},expand={16898613353,{48,48},{306,771}},scale={16898613699,{48,48},{404,967}},component={16898613044,{48,48},{967,49}},["flashlight-off"]={16898613353,{48,48},{918,355}},["panel-top-open"]={16898613613,{48,48},{918,808}},computer={16898613044,{48,48},{918,98}},construction={16898613044,{48,48},{196,820}},notebook={16898613613,{48,48},{869,196}},["power-square"]={16898613699,{48,48},{869,98}},["copy-slash"]={16898613044,{48,48},{306,967}},["square-menu"]={16898613777,{48,48},{967,563}},["circle-play"]={16898613044,{48,48},{514,820}},wallet={16898613869,{48,48},{147,967}},laptop={16898613509,{48,48},{563,967}},["scan-line"]={16898613699,{48,48},{771,857}},["clock-4"]={16898613044,{48,48},{355,820}},["square-arrow-up"]={16898613777,{48,48},{771,710}},copyright={16898613044,{48,48},{820,710}},["chevron-down"]={16898612819,{48,48},{196,918}},["unlock-keyhole"]={16898613869,{48,48},{820,661}},["clock-1"]={16898613044,{48,48},{0,918}},["align-horizontal-distribute-start"]={16898612629,{48,48},{306,820}},["arrow-down-to-line"]={16898612629,{48,48},{661,820}},["mouse-pointer-2"]={16898613613,{48,48},{820,661}},["refresh-ccw"]={16898613699,{48,48},{820,453}},["venetian-mask"]={16898613869,{48,48},{918,404}},["calendar-check-2"]={16898612819,{48,48},{514,967}},["arrow-down-square"]={16898612629,{48,48},{771,710}},spline={16898613777,{48,48},{147,820}},banana={16898612629,{48,48},{967,453}},["git-pull-request-create-arrow"]={16898613509,{48,48},{514,771}},crosshair={16898613044,{48,48},{453,869}},["list-video"]={16898613509,{48,48},{967,710}},["arrow-right-left"]={16898612629,{48,48},{918,355}},["bar-chart-4"]={16898612629,{48,48},{869,808}},["dice-3"]={16898613044,{48,48},{918,453}},["dice-5"]={16898613044,{48,48},{404,967}},["dice-6"]={16898613044,{48,48},{967,661}},["square-plus"]={16898613777,{48,48},{918,147}},["timer-off"]={16898613869,{48,48},{563,820}},["arrow-big-right-dash"]={16898612629,{48,48},{49,918}},["radio-receiver"]={16898613699,{48,48},{404,820}},shield={16898613777,{48,48},{869,0}},["square-equal"]={16898613777,{48,48},{869,404}},backpack={16898612629,{48,48},{710,869}},download={16898613044,{48,48},{820,906}},["drafting-compass"]={16898613044,{48,48},{771,955}},youtube={16898613869,{48,48},{820,955}},["file-plus-2"]={16898613353,{48,48},{967,0}},["message-circle-more"]={16898613613,{48,48},{355,771}},["arrow-down-right"]={16898612629,{48,48},{820,661}},["loader-circle"]={16898613509,{48,48},{771,906}},receipt={16898613699,{48,48},{869,147}},["egg-off"]={16898613353,{48,48},{771,514}},bitcoin={16898612819,{48,48},{820,49}},["eye-off"]={16898613353,{48,48},{820,514}},factory={16898613353,{48,48},{514,820}},["fast-forward"]={16898613353,{48,48},{820,49}},["image-off"]={16898613509,{48,48},{453,771}},["file-audio-2"]={16898613353,{48,48},{820,306}},braces={16898612819,{48,48},{147,820}},cone={16898613044,{48,48},{820,196}},["wand-sparkles"]={16898613869,{48,48},{453,918}},["square-chevron-right"]={16898613777,{48,48},{918,98}},navigation={16898613613,{48,48},{771,759}},["file-check"]={16898613353,{48,48},{563,820}},["file-cog"]={16898613353,{48,48},{820,98}},["file-diff"]={16898613353,{48,48},{771,147}},["file-digit"]={16898613353,{48,48},{147,771}},["power-off"]={16898613699,{48,48},{918,49}},["align-vertical-distribute-center"]={16898612629,{48,48},{771,147}},["tally-1"]={16898613777,{48,48},{967,955}},ampersand={16898612629,{48,48},{404,771}},["line-chart"]={16898613509,{48,48},{196,918}},["shopping-cart"]={16898613777,{48,48},{869,257}},["align-vertical-justify-end"]={16898612629,{48,48},{0,918}},eraser={16898613353,{48,48},{820,257}},["alarm-smoke"]={16898612629,{48,48},{563,771}},["file-line-chart"]={16898613353,{48,48},{306,869}},["file-input"]={16898613353,{48,48},{869,306}},["clock-8"]={16898613044,{48,48},{869,563}},["server-cog"]={16898613699,{48,48},{967,906}},["cloud-cog"]={16898613044,{48,48},{661,771}},blend={16898612819,{48,48},{771,98}},["search-x"]={16898613699,{48,48},{967,808}},["radio-tower"]={16898613699,{48,48},{355,869}},["list-tree"]={16898613509,{48,48},{453,967}},droplet={16898613044,{48,48},{820,955}},heater={16898613509,{48,48},{612,820}},eye={16898613353,{48,48},{771,563}},battery={16898612629,{48,48},{967,857}},lamp={16898613509,{48,48},{869,661}},["link-2-off"]={16898613509,{48,48},{147,967}},["panel-top"]={16898613613,{48,48},{869,857}},["file-volume"]={16898613353,{48,48},{257,967}},["file-x-2"]={16898613353,{48,48},{918,563}},["circle-equal"]={16898613044,{48,48},{771,49}},["flag-triangle-left"]={16898613353,{48,48},{196,820}},flower={16898613353,{48,48},{820,710}},["fold-horizontal"]={16898613353,{48,48},{710,820}},["folder-closed"]={16898613353,{48,48},{918,147}},["folder-dot"]={16898613353,{48,48},{196,869}},["arrow-up-right"]={16898612629,{48,48},{918,147}},router={16898613699,{48,48},{355,967}},["leafy-green"]={16898613509,{48,48},{869,710}},["message-square-dot"]={16898613613,{48,48},{820,98}},focus={16898613353,{48,48},{771,759}},copyleft={16898613044,{48,48},{869,661}},["folder-x"]={16898613353,{48,48},{453,918}},["form-input"]={16898613353,{48,48},{820,808}},["minimize-2"]={16898613613,{48,48},{967,0}},regex={16898613699,{48,48},{306,967}},["gallery-horizontal"]={16898613353,{48,48},{918,759}},university={16898613869,{48,48},{967,514}},["gallery-vertical-end"]={16898613353,{48,48},{820,857}},["file-image"]={16898613353,{48,48},{918,257}},["at-sign"]={16898612629,{48,48},{453,869}},palette={16898613613,{48,48},{453,918}},["user-plus-2"]={16898613869,{48,48},{967,306}},["gallery-thumbnails"]={16898613353,{48,48},{869,808}},["arrow-down-right-from-circle"]={16898612629,{48,48},{918,563}},cpu={16898613044,{48,48},{196,869}},["split-square-horizontal"]={16898613777,{48,48},{98,869}},["thumbs-down"]={16898613869,{48,48},{820,306}},merge={16898613613,{48,48},{0,869}},ghost={16898613353,{48,48},{869,906}},["git-compare"]={16898613353,{48,48},{967,955}},["git-fork"]={16898613509,{48,48},{771,0}},hospital={16898613509,{48,48},{147,820}},["git-merge"]={16898613509,{48,48},{771,257}},["folder-edit"]={16898613353,{48,48},{98,967}},["thumbs-up"]={16898613869,{48,48},{771,355}},globe={16898613509,{48,48},{771,563}},palmtree={16898613613,{48,48},{404,967}},["bug-off"]={16898612819,{48,48},{355,869}},kanban={16898613509,{48,48},{49,967}},["thermometer-snowflake"]={16898613869,{48,48},{49,820}},apple={16898612629,{48,48},{563,869}},["wine-off"]={16898613869,{48,48},{771,906}},["graduation-cap"]={16898613509,{48,48},{869,0}},["hand-helping"]={16898613509,{48,48},{820,563}},hand={16898613509,{48,48},{563,820}},["square-bottom-dashed-scissors"]={16898613777,{48,48},{661,820}},stamp={16898613777,{48,48},{710,869}},["candy-off"]={16898612819,{48,48},{820,710}},["plug-zap-2"]={16898613699,{48,48},{820,355}},["heading-2"]={16898613509,{48,48},{918,257}},["square-activity"]={16898613777,{48,48},{869,355}},["circle-gauge"]={16898613044,{48,48},{0,820}},["cigarette-off"]={16898612819,{48,48},{710,967}},["arrow-up-0-1"]={16898612629,{48,48},{404,869}},["message-circle"]={16898613613,{48,48},{563,820}},["undo-2"]={16898613869,{48,48},{771,453}},headset={16898613509,{48,48},{257,918}},["heart-crack"]={16898613509,{48,48},{918,514}},["git-branch"]={16898613353,{48,48},{918,906}},shovel={16898613777,{48,48},{820,306}},share={16898613777,{48,48},{514,771}},["wallet-cards"]={16898613869,{48,48},{918,196}},["square-arrow-out-down-right"]={16898613777,{48,48},{306,918}},grip={16898613509,{48,48},{869,257}},["monitor-speaker"]={16898613613,{48,48},{869,355}},save={16898613699,{48,48},{918,453}},["cloud-snow"]={16898613044,{48,48},{98,869}},["file-question"]={16898613353,{48,48},{869,98}},["arrow-big-up-dash"]={16898612629,{48,48},{967,257}},coffee={16898613044,{48,48},{967,514}},["image-down"]={16898613509,{48,48},{820,404}},["beer-off"]={16898612819,{48,48},{771,257}},["file-bar-chart"]={16898613353,{48,48},{820,563}},["bar-chart-2"]={16898612629,{48,48},{967,710}},["lock-keyhole-open"]={16898613509,{48,48},{820,906}},["chevrons-down-up"]={16898612819,{48,48},{661,967}},["clipboard-plus"]={16898613044,{48,48},{820,98}},["monitor-up"]={16898613613,{48,48},{771,453}},["list-end"]={16898613509,{48,48},{918,710}},["square-radical"]={16898613777,{48,48},{196,869}},play={16898613699,{48,48},{918,257}},["chevrons-right"]={16898612819,{48,48},{967,710}},["file-badge-2"]={16898613353,{48,48},{306,820}},["message-square-reply"]={16898613613,{48,48},{918,257}},["corner-down-right"]={16898613044,{48,48},{710,820}},phone={16898613699,{48,48},{0,869}},["arrow-left-to-line"]={16898612629,{48,48},{147,869}},["lamp-wall-down"]={16898613509,{48,48},{967,563}},["link-2"]={16898613509,{48,48},{967,404}},["repeat"]={16898613699,{48,48},{820,710}},["ellipsis-vertical"]={16898613353,{48,48},{820,0}},snail={16898613777,{48,48},{820,612}},["paint-bucket"]={16898613613,{48,48},{196,918}},["square-parking"]={16898613777,{48,48},{771,759}},["align-horizontal-justify-end"]={16898612629,{48,48},{869,514}},lasso={16898613509,{48,48},{918,147}},["align-vertical-distribute-end"]={16898612629,{48,48},{147,771}},soup={16898613777,{48,48},{612,820}},airplay={16898612629,{48,48},{771,49}},["layout-dashboard"]={16898613509,{48,48},{967,355}},["heading-1"]={16898613509,{48,48},{0,918}},["circle-x"]={16898613044,{48,48},{820,306}},["monitor-x"]={16898613613,{48,48},{453,771}},["octagon-pause"]={16898613613,{48,48},{869,453}},["library-square"]={16898613509,{48,48},{771,808}},["square-pen"]={16898613777,{48,48},{710,820}},["heart-pulse"]={16898613509,{48,48},{771,661}},["database-backup"]={16898613044,{48,48},{820,759}},["gantt-chart"]={16898613353,{48,48},{869,857}},octagon={16898613613,{48,48},{404,918}},ticket={16898613869,{48,48},{612,771}},["message-square"]={16898613613,{48,48},{355,820}},["list-filter"]={16898613509,{48,48},{869,759}},["train-front"]={16898613869,{48,48},{404,771}},["spray-can"]={16898613777,{48,48},{967,257}},["list-music"]={16898613509,{48,48},{771,857}},["utility-pole"]={16898613869,{48,48},{196,869}},["list-plus"]={16898613509,{48,48},{661,967}},["screen-share"]={16898613699,{48,48},{710,967}},["file-clock"]={16898613353,{48,48},{514,869}},["list-collapse"]={16898613509,{48,48},{967,661}},gauge={16898613353,{48,48},{771,955}},store={16898613777,{48,48},{404,967}},["circle-arrow-down"]={16898612819,{48,48},{869,857}},["notebook-pen"]={16898613613,{48,48},{563,967}},["egg-fried"]={16898613353,{48,48},{257,771}},["calendar-off"]={16898612819,{48,48},{49,967}},["locate-off"]={16898613509,{48,48},{918,808}},["corner-right-up"]={16898613044,{48,48},{967,98}},locate={16898613509,{48,48},{869,857}},["ticket-x"]={16898613869,{48,48},{771,612}},["user-round-plus"]={16898613869,{48,48},{404,869}},["panel-left-close"]={16898613613,{48,48},{710,918}},["lock-keyhole"]={16898613509,{48,48},{771,955}},["lock-open"]={16898613509,{48,48},{967,808}},["user-round-minus"]={16898613869,{48,48},{453,820}},["m-square"]={16898613509,{48,48},{869,955}},magnet={16898613509,{48,48},{967,906}},["message-square-text"]={16898613613,{48,48},{820,355}},["mail-plus"]={16898613613,{48,48},{0,771}},["mail-search"]={16898613613,{48,48},{257,771}},move={16898613613,{48,48},{453,820}},["play-circle"]={16898613699,{48,48},{49,869}},["git-commit-vertical"]={16898613353,{48,48},{967,906}},slash={16898613777,{48,48},{918,257}},["map-pin-off"]={16898613613,{48,48},{0,820}},aperture={16898612629,{48,48},{771,661}},["image-plus"]={16898613509,{48,48},{404,820}},["message-circle-heart"]={16898613613,{48,48},{771,355}},syringe={16898613777,{48,48},{918,808}},info={16898613509,{48,48},{612,869}},["rows-3"]={16898613699,{48,48},{918,661}},check={16898612819,{48,48},{710,869}},["text-search"]={16898613869,{48,48},{869,0}},["square-slash"]={16898613777,{48,48},{967,355}},sandwich={16898613699,{48,48},{918,196}},["settings-2"]={16898613777,{48,48},{0,771}},["file-stack"]={16898613353,{48,48},{0,967}},["external-link"]={16898613353,{48,48},{257,820}},["ice-cream-2"]={16898613509,{48,48},{0,967}},["file-archive"]={16898613353,{48,48},{869,257}},["signal-high"]={16898613777,{48,48},{771,612}},inbox={16898613509,{48,48},{918,563}},["flip-horizontal-2"]={16898613353,{48,48},{355,918}},["traffic-cone"]={16898613869,{48,48},{820,355}},["file-signature"]={16898613353,{48,48},{147,820}},["align-horizontal-space-between"]={16898612629,{48,48},{612,771}},["message-circle-dashed"]={16898613613,{48,48},{820,306}},maximize={16898613613,{48,48},{771,563}},["database-zap"]={16898613044,{48,48},{771,808}},droplets={16898613044,{48,48},{967,857}},["fish-symbol"]={16898613353,{48,48},{918,98}},["message-circle-off"]={16898613613,{48,48},{306,820}},["wheat-off"]={16898613869,{48,48},{967,453}},["layout-list"]={16898613509,{48,48},{869,453}},["file-search"]={16898613353,{48,48},{196,771}},["download-cloud"]={16898613044,{48,48},{869,857}},["alarm-clock-plus"]={16898612629,{48,48},{306,771}},["circle-dollar-sign"]={16898613044,{48,48},{257,771}},usb={16898613869,{48,48},{563,918}},["arrow-up-square"]={16898612629,{48,48},{869,196}},["receipt-pound-sterling"]={16898613699,{48,48},{563,918}},scan={16898613699,{48,48},{967,196}},["heading-5"]={16898613509,{48,48},{771,404}},undo={16898613869,{48,48},{404,820}},["file-search-2"]={16898613353,{48,48},{771,196}},minimize={16898613613,{48,48},{918,49}},["redo-2"]={16898613699,{48,48},{49,967}},thermometer={16898613869,{48,48},{869,257}},["filter-x"]={16898613353,{48,48},{661,820}},["sliders-vertical"]={16898613777,{48,48},{771,404}},["boom-box"]={16898612819,{48,48},{967,0}},["table-2"]={16898613777,{48,48},{869,857}},["touchpad-off"]={16898613869,{48,48},{98,820}},["diamond-percent"]={16898613044,{48,48},{918,196}},brain={16898612819,{48,48},{967,257}},microwave={16898613613,{48,48},{661,771}},["arrow-down-left-square"]={16898612629,{48,48},{306,918}},["user-round-cog"]={16898613869,{48,48},{820,453}},["octagon-x"]={16898613613,{48,48},{453,869}},languages={16898613509,{48,48},{710,820}},["file-json-2"]={16898613353,{48,48},{820,355}},["alarm-clock-check"]={16898612629,{48,48},{0,820}},guitar={16898613509,{48,48},{771,355}},anchor={16898612629,{48,48},{306,869}},["text-cursor"]={16898613869,{48,48},{563,771}},["search-code"]={16898613699,{48,48},{820,906}},["square-parking-off"]={16898613777,{48,48},{820,710}},["notebook-text"]={16898613613,{48,48},{918,147}},["arrow-right-to-line"]={16898612629,{48,48},{820,453}},["ticket-minus"]={16898613869,{48,48},{306,820}},["tally-4"]={16898613869,{48,48},{771,257}},heading={16898613509,{48,48},{355,820}},wallpaper={16898613869,{48,48},{967,404}},["door-open"]={16898613044,{48,48},{967,759}},["arrow-down-circle"]={16898612629,{48,48},{453,771}},["monitor-play"]={16898613613,{48,48},{967,257}},["key-square"]={16898613509,{48,48},{918,355}},["monitor-off"]={16898613613,{48,48},{49,918}},["pocket-knife"]={16898613699,{48,48},{918,514}},["book-copy"]={16898612819,{48,48},{563,820}},["panel-left-inactive"]={16898613613,{48,48},{967,196}},["car-front"]={16898612819,{48,48},{563,967}},["file-video"]={16898613353,{48,48},{355,869}},["reply-all"]={16898613699,{48,48},{661,869}},["cloud-moon-rain"]={16898613044,{48,48},{869,98}},["zoom-out"]={16898613869,{48,48},{967,906}},["search-slash"]={16898613699,{48,48},{771,955}},["notepad-text-dashed"]={16898613613,{48,48},{196,869}},["circle-alert"]={16898612819,{48,48},{918,808}},briefcase={16898612819,{48,48},{771,453}},["list-start"]={16898613509,{48,48},{196,967}},["more-vertical"]={16898613613,{48,48},{967,514}},["a-large-small"]={16898612629,{48,48},{771,257}},tractor={16898613869,{48,48},{869,306}},waves={16898613869,{48,48},{820,808}},["folder-cog"]={16898613353,{48,48},{869,196}},["code-2"]={16898613044,{48,48},{453,771}},["clock-5"]={16898613044,{48,48},{306,869}},vote={16898613869,{48,48},{612,967}},["shield-question"]={16898613777,{48,48},{563,771}},["arrow-right-from-line"]={16898612629,{48,48},{967,306}},["flame-kindling"]={16898613353,{48,48},{49,967}},["square-power"]={16898613777,{48,48},{869,196}},["circle-help"]={16898613044,{48,48},{820,257}},["bring-to-front"]={16898612819,{48,48},{453,771}},["move-right"]={16898613613,{48,48},{49,967}},figma={16898613353,{48,48},{0,869}},["bell-plus"]={16898612819,{48,48},{49,771}},sailboat={16898613699,{48,48},{612,967}},["hard-drive-upload"]={16898613509,{48,48},{869,49}},["pie-chart"]={16898613699,{48,48},{869,514}},meh={16898613613,{48,48},{820,49}},["mail-warning"]={16898613613,{48,48},{771,514}},["music-3"]={16898613613,{48,48},{355,918}},["pause-circle"]={16898613613,{48,48},{967,955}},["panels-right-bottom"]={16898613613,{48,48},{771,955}},["file-edit"]={16898613353,{48,48},{49,869}},redo={16898613699,{48,48},{918,355}},["file-lock"]={16898613353,{48,48},{918,514}},["square-user"]={16898613777,{48,48},{967,612}},["circle-fading-plus"]={16898613044,{48,48},{49,771}},workflow={16898613869,{48,48},{967,759}},["undo-dot"]={16898613869,{48,48},{453,771}},target={16898613869,{48,48},{514,771}},tablets={16898613777,{48,48},{869,955}},radar={16898613699,{48,48},{820,404}},drama={16898613044,{48,48},{967,808}},["signal-medium"]={16898613777,{48,48},{563,820}},baseline={16898612629,{48,48},{869,857}},martini={16898613613,{48,48},{257,820}},contrast={16898613044,{48,48},{918,355}},pickaxe={16898613699,{48,48},{355,771}},["square-divide"]={16898613777,{48,48},{967,306}},["chevron-left-circle"]={16898612819,{48,48},{918,453}},["book-check"]={16898612819,{48,48},{612,771}},["scan-barcode"]={16898613699,{48,48},{918,710}},["book-lock"]={16898612819,{48,48},{98,820}},["panel-right-inactive"]={16898613613,{48,48},{918,759}},refrigerator={16898613699,{48,48},{355,918}},["divide-circle"]={16898613044,{48,48},{967,196}},["package-plus"]={16898613613,{48,48},{661,918}},["mic-2"]={16898613613,{48,48},{257,918}},["hop-off"]={16898613509,{48,48},{771,196}},warehouse={16898613869,{48,48},{967,661}},["plus-square"]={16898613699,{48,48},{306,869}},["square-arrow-out-up-left"]={16898613777,{48,48},{257,967}},["save-all"]={16898613699,{48,48},{967,404}},candy={16898612819,{48,48},{771,759}},["iteration-ccw"]={16898613509,{48,48},{918,98}},["corner-left-down"]={16898613044,{48,48},{661,869}},paintbrush={16898613613,{48,48},{918,453}},["cloud-lightning"]={16898613044,{48,48},{918,49}},["circle-slash-2"]={16898613044,{48,48},{771,98}},["layers-3"]={16898613509,{48,48},{147,918}},["credit-card"]={16898613044,{48,48},{98,967}},["ear-off"]={16898613044,{48,48},{918,955}},["git-commit-horizontal"]={16898613353,{48,48},{869,955}},["panel-bottom"]={16898613613,{48,48},{771,857}},["square-code"]={16898613777,{48,48},{820,196}},["panel-bottom-open"]={16898613613,{48,48},{820,808}},["kanban-square-dashed"]={16898613509,{48,48},{147,869}},["circle-pause"]={16898613044,{48,48},{771,563}},["panel-top-close"]={16898613613,{48,48},{771,906}},ambulance={16898612629,{48,48},{771,404}},["trending-up"]={16898613869,{48,48},{514,918}},["bookmark-x"]={16898612819,{48,48},{563,869}},["clock-9"]={16898613044,{48,48},{820,612}},pen={16898613699,{48,48},{771,49}},["smartphone-nfc"]={16898613777,{48,48},{306,869}},["candy-cane"]={16898612819,{48,48},{869,661}},unlink={16898613869,{48,48},{869,612}},["parking-meter"]={16898613613,{48,48},{918,906}},["gamepad-2"]={16898613353,{48,48},{710,967}},["user-round-search"]={16898613869,{48,48},{355,918}},["parking-square"]={16898613613,{48,48},{967,906}},["paw-print"]={16898613699,{48,48},{771,257}},["arrow-down-right-square"]={16898612629,{48,48},{869,612}},["square-split-vertical"]={16898613777,{48,48},{869,453}},["circle-off"]={16898613044,{48,48},{306,771}},dessert={16898613044,{48,48},{612,967}},eclipse={16898613353,{48,48},{771,257}},squirrel={16898613777,{48,48},{771,808}},["percent-circle"]={16898613699,{48,48},{306,771}},cylinder={16898613044,{48,48},{869,710}},["badge-japanese-yen"]={16898612629,{48,48},{453,918}},["circle-divide"]={16898613044,{48,48},{771,257}},["receipt-text"]={16898613699,{48,48},{918,98}},["square-pi"]={16898613777,{48,48},{612,918}},["align-center-horizontal"]={16898612629,{48,48},{98,771}},["phone-off"]={16898613699,{48,48},{98,771}},["pi-square"]={16898613699,{48,48},{869,257}},["file-output"]={16898613353,{48,48},{661,771}},["disc-album"]={16898613044,{48,48},{710,918}},["percent-square"]={16898613699,{48,48},{820,514}},clapperboard={16898613044,{48,48},{257,869}},captions={16898612819,{48,48},{612,918}},["wallet-minimal"]={16898613869,{48,48},{196,918}},layers={16898613509,{48,48},{98,967}},["umbrella-off"]={16898613869,{48,48},{918,306}},["badge-alert"]={16898612629,{48,48},{661,918}},["arrow-down-left-from-circle"]={16898612629,{48,48},{355,869}},["folder-pen"]={16898613353,{48,48},{710,869}},cross={16898613044,{48,48},{869,453}},["alarm-check"]={16898612629,{48,48},{49,771}},["chevron-right"]={16898612819,{48,48},{869,759}},pill={16898613699,{48,48},{563,820}},["square-arrow-down-left"]={16898613777,{48,48},{820,404}},["share-2"]={16898613777,{48,48},{771,514}},["arrow-up-from-dot"]={16898612629,{48,48},{869,661}},["pin-off"]={16898613699,{48,48},{514,869}},["align-vertical-justify-start"]={16898612629,{48,48},{918,257}},combine={16898613044,{48,48},{612,869}},["tv-2"]={16898613869,{48,48},{147,820}},mountain={16898613613,{48,48},{869,612}},cast={16898612819,{48,48},{869,453}},["indent-increase"]={16898613509,{48,48},{820,661}},currency={16898613044,{48,48},{918,661}},["shield-ban"]={16898613777,{48,48},{0,820}},["message-circle-reply"]={16898613613,{48,48},{820,563}},["corner-left-up"]={16898613044,{48,48},{612,918}},["triangle-right"]={16898613869,{48,48},{918,49}},["folder-clock"]={16898613353,{48,48},{967,98}},link={16898613509,{48,48},{918,453}},["pound-sterling"]={16898613699,{48,48},{514,918}},type={16898613869,{48,48},{967,257}},webhook={16898613869,{48,48},{967,196}},barcode={16898612629,{48,48},{918,808}},["shopping-bag"]={16898613777,{48,48},{49,820}},bed={16898612819,{48,48},{771,0}},["panel-right-open"]={16898613613,{48,48},{869,808}},["pointer-off"]={16898613699,{48,48},{771,661}},turtle={16898613869,{48,48},{196,771}},camera={16898612819,{48,48},{967,563}},scissors={16898613699,{48,48},{820,857}},["user-minus-2"]={16898613869,{48,48},{98,918}},["git-pull-request"]={16898613509,{48,48},{49,771}},["bluetooth-searching"]={16898612819,{48,48},{820,306}},["arrow-up-to-line"]={16898612629,{48,48},{196,869}},drill={16898613044,{48,48},{869,906}},["file-check-2"]={16898613353,{48,48},{612,771}},["badge-percent"]={16898612629,{48,48},{967,661}},shuffle={16898613777,{48,48},{257,869}},radiation={16898613699,{48,48},{771,453}},radical={16898613699,{48,48},{453,771}},microscope={16898613613,{48,48},{771,661}},["message-circle-x"]={16898613613,{48,48},{612,771}},box={16898612819,{48,48},{771,196}},["align-left"]={16898612629,{48,48},{514,869}},["switch-camera"]={16898613777,{48,48},{771,906}},["file-heart"]={16898613353,{48,48},{0,918}},cat={16898612819,{48,48},{404,918}},space={16898613777,{48,48},{563,869}},["rectangle-vertical"]={16898613699,{48,48},{147,869}},["clipboard-signature"]={16898613044,{48,48},{771,147}},["arrow-up-circle"]={16898612629,{48,48},{967,563}},["corner-up-left"]={16898613044,{48,48},{918,147}},["clock-6"]={16898613044,{48,48},{257,918}},["candlestick-chart"]={16898612819,{48,48},{918,612}},["key-round"]={16898613509,{48,48},{967,306}},headphones={16898613509,{48,48},{306,869}},tv={16898613869,{48,48},{98,869}},["book-minus"]={16898612819,{48,48},{0,918}},["bar-chart-horizontal-big"]={16898612629,{48,48},{771,906}},rss={16898613699,{48,48},{771,808}},["user-round-x"]={16898613869,{48,48},{306,967}},highlighter={16898613509,{48,48},{918,49}},["rocking-chair"]={16898613699,{48,48},{869,196}},["square-arrow-out-down-left"]={16898613777,{48,48},{355,869}},music={16898613613,{48,48},{967,563}},handshake={16898613509,{48,48},{514,869}},["check-circle"]={16898612819,{48,48},{869,710}},tornado={16898613869,{48,48},{771,147}},["copy-plus"]={16898613044,{48,48},{355,918}},["folder-git"]={16898613353,{48,48},{918,404}},["triangle-alert"]={16898613869,{48,48},{967,0}},shrink={16898613777,{48,48},{355,771}},sofa={16898613777,{48,48},{661,771}},["school-2"]={16898613699,{48,48},{967,453}},["search-check"]={16898613699,{48,48},{869,857}},crop={16898613044,{48,48},{918,404}},["columns-2"]={16898613044,{48,48},{820,661}},["mouse-pointer-square"]={16898613613,{48,48},{661,820}},["flask-conical-off"]={16898613353,{48,48},{820,453}},milestone={16898613613,{48,48},{612,820}},["wand-2"]={16898613869,{48,48},{918,453}},["square-dot"]={16898613777,{48,48},{918,355}},["badge-minus"]={16898612629,{48,48},{404,967}},["cloud-fog"]={16898613044,{48,48},{514,918}},["milk-off"]={16898613613,{48,48},{563,869}},bone={16898612819,{48,48},{869,514}},["percent-diamond"]={16898613699,{48,48},{257,820}},["package-check"]={16898613613,{48,48},{820,759}},["chevron-first"]={16898612819,{48,48},{147,967}},pencil={16898613699,{48,48},{820,257}},["shield-minus"]={16898613777,{48,48},{257,820}},["list-x"]={16898613509,{48,48},{918,759}},["stretch-horizontal"]={16898613777,{48,48},{967,661}},["panel-left-open"]={16898613613,{48,48},{196,967}},["corner-up-right"]={16898613044,{48,48},{869,196}},["repeat-2"]={16898613699,{48,48},{869,661}},pin={16898613699,{48,48},{918,0}},["mail-question"]={16898613613,{48,48},{771,257}},gift={16898613353,{48,48},{820,955}},["badge-indian-rupee"]={16898612629,{48,48},{967,404}},smartphone={16898613777,{48,48},{257,918}},["redo-dot"]={16898613699,{48,48},{967,306}},["users-round"]={16898613869,{48,48},{563,967}},["align-start-horizontal"]={16898612629,{48,48},{869,49}},["message-square-warning"]={16898613613,{48,48},{771,404}},["file-plus"]={16898613353,{48,48},{918,49}},["git-pull-request-arrow"]={16898613509,{48,48},{257,771}},webcam={16898613869,{48,48},{710,918}},["arrow-down-to-dot"]={16898612629,{48,48},{710,771}},["bell-dot"]={16898612819,{48,48},{771,514}},["folder-down"]={16898613353,{48,48},{147,918}},church={16898612819,{48,48},{771,906}},["square-play"]={16898613777,{48,48},{967,98}},["badge-x"]={16898612629,{48,48},{710,918}},server={16898613777,{48,48},{771,0}},["phone-forwarded"]={16898613699,{48,48},{869,0}},diamond={16898613044,{48,48},{196,918}},blinds={16898612819,{48,48},{98,771}},["user-square"]={16898613869,{48,48},{820,710}},package={16898613613,{48,48},{918,196}},["alarm-clock-off"]={16898612629,{48,48},{771,306}},["table-cells-merge"]={16898613777,{48,48},{820,906}},["helping-hand"]={16898613509,{48,48},{514,918}},recycle={16898613699,{48,48},{98,918}},["mountain-snow"]={16898613613,{48,48},{918,563}},luggage={16898613509,{48,48},{918,906}},["divide-square"]={16898613044,{48,48},{196,967}},["bot-message-square"]={16898612819,{48,48},{918,49}},["phone-outgoing"]={16898613699,{48,48},{49,820}},["smartphone-charging"]={16898613777,{48,48},{355,820}},["panel-left"]={16898613613,{48,48},{967,453}},["train-track"]={16898613869,{48,48},{355,820}},["bookmark-minus"]={16898612819,{48,48},{661,771}},["tablet-smartphone"]={16898613777,{48,48},{967,857}},["fire-extinguisher"]={16898613353,{48,48},{514,967}},sigma={16898613777,{48,48},{820,563}},["shield-half"]={16898613777,{48,48},{306,771}},terminal={16898613869,{48,48},{820,257}},shapes={16898613777,{48,48},{257,771}},["bell-ring"]={16898612819,{48,48},{0,820}},["tower-control"]={16898613869,{48,48},{0,918}},["arrow-down-1-0"]={16898612629,{48,48},{820,404}},users={16898613869,{48,48},{967,98}},scroll={16898613699,{48,48},{918,808}},["arrow-left-right"]={16898612629,{48,48},{820,196}},["lightbulb-off"]={16898613509,{48,48},{967,147}},["panels-top-left"]={16898613613,{48,48},{967,808}},beaker={16898612629,{48,48},{918,906}},["message-square-share"]={16898613613,{48,48},{869,306}},annoyed={16898612629,{48,48},{918,514}},["test-tube"]={16898613869,{48,48},{257,820}},["user-circle"]={16898613869,{48,48},{820,196}},["cooking-pot"]={16898613044,{48,48},{820,453}},["between-horizontal-start"]={16898612819,{48,48},{306,771}},fullscreen={16898613353,{48,48},{967,453}},["circuit-board"]={16898613044,{48,48},{355,771}},["grid-3x3"]={16898613509,{48,48},{98,771}},["mail-open"]={16898613613,{48,48},{771,0}},["square-function"]={16898613777,{48,48},{820,453}},["arrow-up-left-from-circle"]={16898612629,{48,48},{771,759}},variable={16898613869,{48,48},{147,918}},["arrow-up-right-square"]={16898612629,{48,48},{967,98}},["pen-line"]={16898613699,{48,48},{771,514}}},["256px"]={["align-vertical-distribute-center"]={16898613509,{256,256},{514,0}},["chevron-down"]={16898617411,{256,256},{514,257}},["list-restart"]={16898674572,{256,256},{257,257}},["table-cells-split"]={16898787819,{256,256},{514,0}},gavel={16898672166,{256,256},{514,257}},["dna-off"]={16898669271,{256,256},{514,514}},["refresh-ccw-dot"]={16898733036,{256,256},{257,514}},bean={16898615374,{256,256},{257,0}},["arrow-up-right-from-circle"]={16898614410,{256,256},{514,257}},["table-columns-split"]={16898787819,{256,256},{257,257}},bolt={16898615799,{256,256},{0,514}},heater={16898673271,{256,256},{257,0}},feather={16898669897,{256,256},{0,514}},["align-horizontal-distribute-center"]={16898613044,{256,256},{514,514}},["align-center"]={16898613044,{256,256},{0,514}},["grip-vertical"]={16898672700,{256,256},{514,0}},["person-standing"]={16898731539,{256,256},{257,257}},["badge-swiss-franc"]={16898615022,{256,256},{514,0}},["between-horizontal-end"]={16898615428,{256,256},{514,257}},["rotate-cw"]={16898733415,{256,256},{514,0}},framer={16898671684,{256,256},{514,514}},["bus-front"]={16898616879,{256,256},{0,514}},["shield-ellipsis"]={16898734564,{256,256},{514,0}},["file-lock-2"]={16898670241,{256,256},{0,0}},["between-vertical-end"]={16898615428,{256,256},{514,514}},["globe-lock"]={16898672599,{256,256},{514,0}},tags={16898788033,{256,256},{514,0}},["concierge-bell"]={16898619347,{256,256},{257,0}},["user-square"]={16898790047,{256,256},{514,257}},["arrow-left-square"]={16898614166,{256,256},{257,257}},["file-down"]={16898670072,{256,256},{514,514}},["picture-in-picture"]={16898731683,{256,256},{514,514}},["messages-square"]={16898728402,{256,256},{257,514}},["touchpad-off"]={16898788908,{256,256},{257,0}},["user-round-cog"]={16898789825,{256,256},{257,514}},["chevron-up-circle"]={16898617509,{256,256},{514,257}},["server-crash"]={16898734242,{256,256},{514,514}},["heading-3"]={16898672954,{256,256},{257,514}},squircle={16898736597,{256,256},{0,514}},["wifi-off"]={16898790996,{256,256},{257,514}},["sun-medium"]={16898736967,{256,256},{514,257}},["message-square"]={16898728402,{256,256},{514,257}},["cloud-download"]={16898618763,{256,256},{0,257}},["sigma-square"]={16898734792,{256,256},{257,257}},["folder-plus"]={16898671463,{256,256},{257,0}},["hard-drive-download"]={16898672829,{256,256},{257,514}},["scatter-chart"]={16898733817,{256,256},{257,257}},pointer={16898732061,{256,256},{514,514}},["circle-alert"]={16898617705,{256,256},{514,0}},["chevrons-up-down"]={16898617626,{256,256},{514,257}},["iteration-cw"]={16898673616,{256,256},{0,0}},["rail-symbol"]={16898732665,{256,256},{0,514}},["message-circle-more"]={16898675752,{256,256},{0,257}},parentheses={16898731166,{256,256},{257,514}},["book-up-2"]={16898616524,{256,256},{0,0}},flame={16898670919,{256,256},{0,257}},["chevrons-up"]={16898617626,{256,256},{257,514}},["chevron-right-square"]={16898617509,{256,256},{257,257}},["square-mouse-pointer"]={16898736237,{256,256},{257,0}},superscript={16898787671,{256,256},{514,0}},tag={16898788033,{256,256},{0,257}},["file-warning"]={16898670620,{256,256},{0,257}},hexagon={16898673271,{256,256},{257,257}},["navigation-2-off"]={16898730065,{256,256},{257,0}},["eye-off"]={16898669772,{256,256},{514,514}},["arrows-up-from-line"]={16898614574,{256,256},{0,514}},["square-gantt-chart"]={16898736072,{256,256},{257,257}},["square-chevron-left"]={16898735845,{256,256},{257,0}},scaling={16898733674,{256,256},{0,514}},["inspection-panel"]={16898673523,{256,256},{0,514}},["arrow-left-from-line"]={16898614166,{256,256},{0,257}},["signal-medium"]={16898734792,{256,256},{514,514}},["ticket-percent"]={16898788660,{256,256},{257,514}},["arrow-right-square"]={16898614275,{256,256},{257,0}},["calendar-clock"]={16898616953,{256,256},{0,514}},x={16898791349,{256,256},{257,0}},voicemail={16898790439,{256,256},{514,514}},presentation={16898732262,{256,256},{257,514}},["tree-palm"]={16898789012,{256,256},{0,514}},badge={16898615022,{256,256},{0,514}},["captions-off"]={16898617146,{256,256},{514,514}},["align-vertical-justify-center"]={16898613509,{256,256},{514,257}},theater={16898788479,{256,256},{514,514}},tent={16898788248,{256,256},{257,257}},["repeat-1"]={16898733146,{256,256},{0,514}},stethoscope={16898736776,{256,256},{257,257}},["screen-share-off"]={16898734065,{256,256},{0,257}},["arrow-big-up"]={16898613777,{256,256},{514,514}},["volume-x"]={16898790615,{256,256},{0,257}},["mouse-pointer-click"]={16898729337,{256,256},{0,514}},["square-m"]={16898736072,{256,256},{257,514}},["hard-hat"]={16898672954,{256,256},{257,0}},["package-minus"]={16898730417,{256,256},{257,514}},["iteration-ccw"]={16898673523,{256,256},{514,514}},pipette={16898731819,{256,256},{257,514}},["flip-horizontal"]={16898671019,{256,256},{0,0}},["alert-circle"]={16898613044,{256,256},{0,0}},unplug={16898789644,{256,256},{0,0}},["badge-cent"]={16898614755,{256,256},{514,514}},["check-square-2"]={16898617325,{256,256},{514,514}},["monitor-check"]={16898728878,{256,256},{257,257}},trello={16898789012,{256,256},{514,514}},["paintbrush-2"]={16898730641,{256,256},{514,257}},["bar-chart-horizontal"]={16898615143,{256,256},{514,257}},["book-open-text"]={16898616322,{256,256},{257,257}},["parking-meter"]={16898731301,{256,256},{257,0}},cat={16898617325,{256,256},{514,0}},["heart-handshake"]={16898673115,{256,256},{514,257}},trees={16898789012,{256,256},{257,514}},ham={16898672700,{256,256},{257,514}},text={16898788479,{256,256},{257,514}},["circle-pause"]={16898617944,{256,256},{0,514}},["chevron-up-square"]={16898617509,{256,256},{257,514}},rat={16898732665,{256,256},{257,514}},["separator-horizontal"]={16898734242,{256,256},{0,514}},ambulance={16898613613,{256,256},{0,257}},["signal-zero"]={16898734905,{256,256},{0,0}},citrus={16898618228,{256,256},{0,0}},["phone-missed"]={16898731539,{256,256},{514,514}},["calendar-off"]={16898617053,{256,256},{0,257}},["battery-medium"]={16898615240,{256,256},{0,514}},["square-minus"]={16898736237,{256,256},{0,0}},hotel={16898673358,{256,256},{0,257}},["folder-output"]={16898671263,{256,256},{514,514}},["ice-cream"]={16898673358,{256,256},{257,514}},menu={16898675673,{256,256},{514,257}},["arrow-up-left-square"]={16898614410,{256,256},{514,0}},["image-down"]={16898673358,{256,256},{514,514}},terminal={16898788248,{256,256},{514,257}},angry={16898613613,{256,256},{514,257}},outdent={16898730417,{256,256},{257,257}},["circle-dot-dashed"]={16898617884,{256,256},{514,0}},speech={16898735455,{256,256},{257,0}},["cake-slice"]={16898616953,{256,256},{0,0}},["git-graph"]={16898672316,{256,256},{514,514}},armchair={16898613777,{256,256},{0,0}},["qr-code"]={16898732504,{256,256},{257,257}},copy={16898619423,{256,256},{257,514}},goal={16898672599,{256,256},{0,514}},["trending-down"]={16898789153,{256,256},{0,0}},["creative-commons"]={16898668482,{256,256},{257,0}},nfc={16898730065,{256,256},{257,514}},pickaxe={16898731683,{256,256},{514,257}},car={16898617249,{256,256},{514,0}},["notebook-tabs"]={16898730298,{256,256},{0,0}},ear={16898669689,{256,256},{0,257}},videotape={16898790439,{256,256},{514,257}},["sun-moon"]={16898736967,{256,256},{257,514}},calendar={16898617146,{256,256},{0,0}},["minus-circle"]={16898728878,{256,256},{257,0}},["arrow-down-left-from-circle"]={16898613869,{256,256},{0,514}},gift={16898672316,{256,256},{0,0}},["message-square-heart"]={16898675863,{256,256},{0,514}},["rectangle-ellipsis"]={16898733036,{256,256},{0,0}},["badge-plus"]={16898615022,{256,256},{0,0}},["indian-rupee"]={16898673523,{256,256},{0,257}},["monitor-dot"]={16898728878,{256,256},{0,514}},delete={16898668755,{256,256},{514,257}},["clipboard-pen-line"]={16898618228,{256,256},{514,514}},["folder-search"]={16898671463,{256,256},{257,257}},["utensils-crossed"]={16898790259,{256,256},{257,257}},["arrow-up"]={16898614574,{256,256},{257,257}},["arrow-up-from-dot"]={16898614410,{256,256},{0,0}},["flask-round"]={16898670919,{256,256},{257,514}},pause={16898731301,{256,256},{257,514}},shrub={16898734792,{256,256},{0,257}},flag={16898670919,{256,256},{0,0}},underline={16898789303,{256,256},{514,257}},["align-horizontal-distribute-end"]={16898613353,{256,256},{0,0}},newspaper={16898730065,{256,256},{514,257}},table={16898787819,{256,256},{257,514}},["move-vertical"]={16898729752,{256,256},{257,257}},["file-pen-line"]={16898670241,{256,256},{514,257}},["badge-russian-ruble"]={16898615022,{256,256},{0,257}},radius={16898732665,{256,256},{257,257}},["loader-2"]={16898674684,{256,256},{0,257}},pilcrow={16898731819,{256,256},{514,0}},["corner-left-up"]={16898668288,{256,256},{257,257}},spade={16898735175,{256,256},{514,257}},["folder-cog"]={16898671139,{256,256},{514,0}},["flip-vertical"]={16898671019,{256,256},{0,257}},["square-arrow-down"]={16898735593,{256,256},{257,257}},["circle-plus"]={16898617944,{256,256},{514,514}},view={16898790439,{256,256},{257,514}},cctv={16898617325,{256,256},{257,257}},["more-horizontal"]={16898729337,{256,256},{0,0}},rows={16898733534,{256,256},{257,0}},["pause-octagon"]={16898731301,{256,256},{514,257}},["circle-arrow-left"]={16898617705,{256,256},{0,514}},volume={16898790615,{256,256},{514,0}},facebook={16898669897,{256,256},{257,0}},["octagon-alert"]={16898730298,{256,256},{257,514}},["panel-bottom-dashed"]={16898730821,{256,256},{0,257}},["book-a"]={16898615799,{256,256},{514,514}},["align-end-vertical"]={16898613044,{256,256},{257,514}},["user-x-2"]={16898790047,{256,256},{257,514}},chrome={16898617626,{256,256},{514,514}},["receipt-japanese-yen"]={16898732855,{256,256},{514,0}},rabbit={16898732504,{256,256},{514,257}},["scissors-square"]={16898734065,{256,256},{0,0}},["check-square"]={16898617411,{256,256},{0,0}},["train-front-tunnel"]={16898788908,{256,256},{257,514}},["panel-left-dashed"]={16898730821,{256,256},{257,514}},["dice-4"]={16898669042,{256,256},{0,514}},["message-circle-x"]={16898675752,{256,256},{514,514}},["folder-x"]={16898671684,{256,256},{0,0}},["message-circle-warning"]={16898675752,{256,256},{257,514}},map={16898675359,{256,256},{0,514}},move={16898729752,{256,256},{0,514}},["arrow-up-left"]={16898614410,{256,256},{257,257}},award={16898614755,{256,256},{0,257}},["arrow-down-wide-narrow"]={16898614020,{256,256},{257,514}},["unfold-horizontal"]={16898789451,{256,256},{257,0}},["area-chart"]={16898613699,{256,256},{514,514}},["music-4"]={16898729752,{256,256},{514,514}},["shield-x"]={16898734664,{256,256},{0,0}},["plane-landing"]={16898731919,{256,256},{0,0}},["disc-3"]={16898669271,{256,256},{0,257}},["columns-4"]={16898619182,{256,256},{514,0}},["archive-x"]={16898613699,{256,256},{514,257}},["square-dashed-kanban"]={16898735845,{256,256},{257,514}},["mouse-pointer-2"]={16898729337,{256,256},{257,257}},["shield-off"]={16898734564,{256,256},{514,257}},compass={16898619182,{256,256},{257,514}},vegan={16898790439,{256,256},{0,0}},["message-circle-plus"]={16898675752,{256,256},{257,257}},["stop-circle"]={16898736776,{256,256},{257,514}},nut={16898730298,{256,256},{514,257}},search={16898734242,{256,256},{257,0}},files={16898670620,{256,256},{514,257}},["send-to-back"]={16898734242,{256,256},{514,0}},["alarm-clock"]={16898612819,{256,256},{257,257}},["shopping-basket"]={16898734664,{256,256},{514,257}},send={16898734242,{256,256},{257,257}},["chevron-left-square"]={16898617509,{256,256},{257,0}},["terminal-square"]={16898788248,{256,256},{0,514}},["square-arrow-out-down-left"]={16898735593,{256,256},{514,257}},["skip-back"]={16898734905,{256,256},{0,514}},["zoom-in"]={16898791349,{256,256},{0,514}},["file-scan"]={16898670367,{256,256},{514,0}},["message-square-dashed"]={16898675863,{256,256},{0,257}},trophy={16898789153,{256,256},{0,514}},umbrella={16898789303,{256,256},{0,514}},touchpad={16898788908,{256,256},{0,257}},["clipboard-copy"]={16898618228,{256,256},{514,0}},["map-pin-off"]={16898675359,{256,256},{0,257}},headset={16898673115,{256,256},{257,257}},["circle-chevron-up"]={16898617803,{256,256},{514,514}},["align-vertical-space-between"]={16898613613,{256,256},{257,0}},["lamp-desk"]={16898673794,{256,256},{514,0}},["circle-arrow-up"]={16898617803,{256,256},{0,257}},zap={16898791349,{256,256},{257,257}},["triangle-alert"]={16898789153,{256,256},{0,257}},["swiss-franc"]={16898787671,{256,256},{0,514}},["move-left"]={16898729572,{256,256},{514,514}},["chevron-up"]={16898617509,{256,256},{514,514}},instagram={16898673523,{256,256},{514,257}},["pen-tool"]={16898731419,{256,256},{514,0}},["pencil-ruler"]={16898731419,{256,256},{514,257}},dna={16898669433,{256,256},{0,0}},["arrow-big-down-dash"]={16898613777,{256,256},{257,0}},["clipboard-edit"]={16898618228,{256,256},{257,257}},mic={16898728659,{256,256},{0,257}},["folder-search-2"]={16898671463,{256,256},{514,0}},gitlab={16898672450,{256,256},{514,514}},["rotate-3d"]={16898733317,{256,256},{514,514}},["spell-check"]={16898735455,{256,256},{514,0}},popcorn={16898732262,{256,256},{0,0}},blocks={16898615570,{256,256},{514,514}},["washing-machine"]={16898790791,{256,256},{0,514}},["badge-minus"]={16898614945,{256,256},{257,514}},["cloud-sun"]={16898618899,{256,256},{0,514}},circle={16898618049,{256,256},{257,514}},["shield-alert"]={16898734564,{256,256},{0,0}},rainbow={16898732665,{256,256},{514,257}},["separator-vertical"]={16898734242,{256,256},{514,257}},ampersands={16898613613,{256,256},{257,257}},["user-search"]={16898790047,{256,256},{257,257}},fence={16898669897,{256,256},{514,257}},["square-user-round"]={16898736597,{256,256},{257,0}},sunrise={16898787671,{256,256},{257,0}},strikethrough={16898736967,{256,256},{0,257}},["calendar-days"]={16898616953,{256,256},{514,257}},["dollar-sign"]={16898669433,{256,256},{514,0}},puzzle={16898732504,{256,256},{0,257}},["list-minus"]={16898674572,{256,256},{0,0}},["sun-dim"]={16898736967,{256,256},{0,514}},upload={16898789644,{256,256},{0,257}},["app-window-mac"]={16898613699,{256,256},{0,257}},ellipsis={16898669772,{256,256},{257,0}},["copy-check"]={16898619423,{256,256},{0,257}},history={16898673271,{256,256},{514,257}},satellite={16898733674,{256,256},{0,0}},["bookmark-plus"]={16898616524,{256,256},{257,514}},["folder-key"]={16898671263,{256,256},{514,0}},["lamp-ceiling"]={16898673794,{256,256},{0,257}},["circle-power"]={16898618049,{256,256},{0,0}},hourglass={16898673358,{256,256},{514,0}},["folder-git"]={16898671139,{256,256},{514,514}},bomb={16898615799,{256,256},{514,257}},["layers-2"]={16898673999,{256,256},{514,514}},["battery-full"]={16898615240,{256,256},{514,0}},["user-minus"]={16898789825,{256,256},{514,0}},["x-octagon"]={16898791187,{256,256},{514,514}},["folder-tree"]={16898671463,{256,256},{257,514}},command={16898619182,{256,256},{514,257}},regex={16898733146,{256,256},{514,0}},hand={16898672829,{256,256},{0,514}},["chevrons-down"]={16898617626,{256,256},{257,0}},["bluetooth-off"]={16898615799,{256,256},{257,0}},["music-2"]={16898729752,{256,256},{514,257}},book={16898616524,{256,256},{257,257}},hammer={16898672700,{256,256},{514,514}},["circle-minus"]={16898617944,{256,256},{257,0}},["audio-waveform"]={16898614755,{256,256},{257,0}},["moon-star"]={16898729141,{256,256},{257,514}},["arrow-down-narrow-wide"]={16898613869,{256,256},{514,514}},sparkle={16898735175,{256,256},{257,514}},wand={16898790791,{256,256},{514,0}},["calendar-minus-2"]={16898617053,{256,256},{0,0}},["copy-minus"]={16898619423,{256,256},{514,0}},["folder-input"]={16898671263,{256,256},{257,0}},["book-image"]={16898616080,{256,256},{257,514}},shirt={16898734664,{256,256},{257,257}},["server-off"]={16898734421,{256,256},{0,0}},["move-up"]={16898729752,{256,256},{514,0}},["plug-2"]={16898731919,{256,256},{514,257}},radio={16898732665,{256,256},{514,0}},brackets={16898616650,{256,256},{514,514}},["calendar-heart"]={16898616953,{256,256},{514,514}},["list-ordered"]={16898674572,{256,256},{0,257}},["mic-off"]={16898728659,{256,256},{0,0}},["arrow-big-left"]={16898613777,{256,256},{257,257}},["square-split-horizontal"]={16898736398,{256,256},{514,257}},clover={16898619015,{256,256},{0,0}},["sun-snow"]={16898736967,{256,256},{514,514}},["user-2"]={16898789644,{256,256},{257,257}},["help-circle"]={16898673271,{256,256},{0,257}},["clock-2"]={16898618583,{256,256},{257,0}},["calendar-fold"]={16898616953,{256,256},{257,514}},["fish-off"]={16898670775,{256,256},{514,0}},baby={16898614755,{256,256},{0,514}},leaf={16898674337,{256,256},{0,0}},["fold-vertical"]={16898671019,{256,256},{257,514}},hop={16898673358,{256,256},{0,0}},["phone-incoming"]={16898731539,{256,256},{257,514}},cigarette={16898617705,{256,256},{0,257}},minus={16898728878,{256,256},{514,0}},["smile-plus"]={16898735040,{256,256},{514,514}},["folder-edit"]={16898671139,{256,256},{514,257}},["star-off"]={16898736776,{256,256},{0,0}},["git-pull-request-closed"]={16898672450,{256,256},{0,257}},["badge-check"]={16898614945,{256,256},{0,0}},["test-tube-2"]={16898788248,{256,256},{257,514}},["kanban-square"]={16898673616,{256,256},{257,257}},["plug-zap"]={16898731919,{256,256},{514,514}},["heading-4"]={16898672954,{256,256},{514,514}},["git-pull-request-create"]={16898672450,{256,256},{257,257}},["replace-all"]={16898733146,{256,256},{514,514}},["receipt-swiss-franc"]={16898732855,{256,256},{514,257}},["square-dashed-bottom-code"]={16898735845,{256,256},{0,514}},["clock-7"]={16898618583,{256,256},{514,257}},["scan-text"]={16898733817,{256,256},{0,257}},["shower-head"]={16898734792,{256,256},{0,0}},["equal-not"]={16898669772,{256,256},{0,257}},["sliders-horizontal"]={16898735040,{256,256},{0,257}},["ticket-slash"]={16898788789,{256,256},{0,0}},ruler={16898733534,{256,256},{514,0}},["circle-user-round"]={16898618049,{256,256},{257,257}},["list-filter"]={16898674482,{256,256},{514,514}},["alarm-minus"]={16898612819,{256,256},{0,514}},["egg-off"]={16898669689,{256,256},{257,514}},cog={16898619015,{256,256},{514,514}},dog={16898669433,{256,256},{0,257}},swords={16898787671,{256,256},{514,514}},["panel-right-dashed"]={16898731024,{256,256},{514,0}},["ship-wheel"]={16898734664,{256,256},{0,257}},bot={16898616650,{256,256},{514,0}},["trash-2"]={16898789012,{256,256},{0,257}},["chevron-down-square"]={16898617411,{256,256},{0,514}},["panel-left-open"]={16898731024,{256,256},{0,0}},["file-symlink"]={16898670469,{256,256},{257,0}},["clipboard-paste"]={16898618228,{256,256},{257,514}},["chevron-last"]={16898617411,{256,256},{514,514}},["book-heart"]={16898616080,{256,256},{514,257}},["circle-parking"]={16898617944,{256,256},{257,257}},["panel-left"]={16898731024,{256,256},{257,0}},["message-circle-off"]={16898675752,{256,256},{514,0}},speaker={16898735455,{256,256},{0,0}},timer={16898788789,{256,256},{0,514}},forward={16898671684,{256,256},{514,257}},["file-up"]={16898670469,{256,256},{514,257}},["between-vertical-start"]={16898615570,{256,256},{0,0}},database={16898668755,{256,256},{0,514}},["panel-right"]={16898731024,{256,256},{514,257}},["log-out"]={16898674825,{256,256},{257,257}},["git-branch-plus"]={16898672316,{256,256},{257,0}},["shield-half"]={16898734564,{256,256},{257,257}},["square-dot"]={16898736072,{256,256},{257,0}},["arrow-right-circle"]={16898614166,{256,256},{257,514}},["table-rows-split"]={16898787819,{256,256},{514,257}},watch={16898790791,{256,256},{514,257}},["cloud-upload"]={16898618899,{256,256},{514,257}},["screen-share"]={16898734065,{256,256},{514,0}},drumstick={16898669562,{256,256},{514,514}},["list-checks"]={16898674482,{256,256},{0,514}},bug={16898616879,{256,256},{0,257}},["circle-chevron-left"]={16898617803,{256,256},{514,257}},["arrow-down"]={16898614166,{256,256},{0,0}},["arrow-up-down"]={16898614275,{256,256},{514,514}},["folder-dot"]={16898671139,{256,256},{257,257}},["whole-word"]={16898790996,{256,256},{514,257}},monitor={16898729141,{256,256},{514,257}},["flag-off"]={16898670775,{256,256},{514,257}},["align-right"]={16898613509,{256,256},{0,0}},["circle-stop"]={16898618049,{256,256},{514,0}},infinity={16898673523,{256,256},{514,0}},["arrow-big-down"]={16898613777,{256,256},{0,257}},["circle-parking-off"]={16898617944,{256,256},{514,0}},["calendar-x-2"]={16898617053,{256,256},{257,514}},["user-plus"]={16898789825,{256,256},{0,514}},["move-diagonal-2"]={16898729572,{256,256},{0,257}},["gallery-horizontal-end"]={16898672004,{256,256},{257,257}},["panel-top-dashed"]={16898731024,{256,256},{514,514}},["tram-front"]={16898789012,{256,256},{257,0}},podcast={16898732061,{256,256},{514,257}},["audio-lines"]={16898614755,{256,256},{0,0}},["flip-vertical-2"]={16898671019,{256,256},{257,0}},github={16898672450,{256,256},{257,514}},["rows-2"]={16898733415,{256,256},{257,514}},printer={16898732262,{256,256},{514,514}},["megaphone-off"]={16898675673,{256,256},{257,0}},["file-bar-chart-2"]={16898669984,{256,256},{514,257}},["arrow-big-right"]={16898613777,{256,256},{514,257}},["file-clock"]={16898670072,{256,256},{0,257}},["toy-brick"]={16898788908,{256,256},{257,257}},["square-chevron-down"]={16898735845,{256,256},{0,0}},smartphone={16898735040,{256,256},{257,514}},drill={16898669562,{256,256},{257,257}},["app-window"]={16898613699,{256,256},{514,0}},["shield-check"]={16898734564,{256,256},{0,257}},["hand-metal"]={16898672829,{256,256},{514,0}},["x-circle"]={16898791187,{256,256},{257,514}},["spell-check-2"]={16898735455,{256,256},{0,257}},["minus-square"]={16898728878,{256,256},{0,257}},["box-select"]={16898616650,{256,256},{257,257}},["list-plus"]={16898674572,{256,256},{514,0}},waypoints={16898790791,{256,256},{514,514}},["ice-cream-cone"]={16898673358,{256,256},{514,257}},["copy-slash"]={16898619423,{256,256},{0,514}},wind={16898791187,{256,256},{0,0}},["layout-panel-left"]={16898674182,{256,256},{0,514}},pill={16898731819,{256,256},{257,257}},grip={16898672700,{256,256},{257,257}},["square-x"]={16898736597,{256,256},{514,0}},italic={16898673523,{256,256},{257,514}},["step-forward"]={16898736776,{256,256},{514,0}},["a-arrow-down"]={16898612629,{256,256},{0,0}},container={16898619347,{256,256},{257,514}},sticker={16898736776,{256,256},{0,514}},["parking-circle-off"]={16898731166,{256,256},{514,514}},import={16898673447,{256,256},{514,257}},bird={16898615570,{256,256},{257,257}},["square-terminal"]={16898736597,{256,256},{0,0}},gem={16898672166,{256,256},{257,514}},beef={16898615374,{256,256},{0,514}},["ticket-x"]={16898788789,{256,256},{257,0}},["timer-reset"]={16898788789,{256,256},{257,257}},["monitor-stop"]={16898729141,{256,256},{514,0}},smile={16898735175,{256,256},{0,0}},["signpost-big"]={16898734905,{256,256},{0,257}},cloudy={16898618899,{256,256},{514,514}},["square-percent"]={16898736237,{256,256},{0,514}},["navigation-off"]={16898730065,{256,256},{514,0}},["arrow-left"]={16898614166,{256,256},{514,257}},["car-taxi-front"]={16898617249,{256,256},{0,257}},laugh={16898673999,{256,256},{257,514}},["x-square"]={16898791349,{256,256},{0,0}},["step-back"]={16898736776,{256,256},{0,257}},equal={16898669772,{256,256},{514,0}},megaphone={16898675673,{256,256},{0,257}},["chevron-left"]={16898617509,{256,256},{0,257}},egg={16898669689,{256,256},{514,514}},["video-off"]={16898790439,{256,256},{257,257}},["japanese-yen"]={16898673616,{256,256},{257,0}},library={16898674337,{256,256},{257,257}},["file-terminal"]={16898670469,{256,256},{0,257}},["circle-chevron-down"]={16898617803,{256,256},{0,514}},["bell-off"]={16898615428,{256,256},{0,257}},["square-library"]={16898736072,{256,256},{514,257}},salad={16898733534,{256,256},{514,257}},["tally-2"]={16898788033,{256,256},{0,514}},sheet={16898734421,{256,256},{257,514}},["circle-check-big"]={16898617803,{256,256},{514,0}},["map-pinned"]={16898675359,{256,256},{257,257}},["corner-down-left"]={16898668288,{256,256},{257,0}},dribbble={16898669562,{256,256},{514,0}},["pilcrow-square"]={16898731819,{256,256},{0,257}},["lamp-wall-up"]={16898673794,{256,256},{514,257}},["book-dashed"]={16898616080,{256,256},{514,0}},bluetooth={16898615799,{256,256},{514,0}},["tree-pine"]={16898789012,{256,256},{514,257}},["receipt-indian-rupee"]={16898732855,{256,256},{0,257}},["check-circle-2"]={16898617325,{256,256},{514,257}},["flask-conical"]={16898670919,{256,256},{514,257}},["package-search"]={16898730641,{256,256},{257,0}},columns={16898619182,{256,256},{257,257}},["folder-sync"]={16898671463,{256,256},{514,257}},fingerprint={16898670775,{256,256},{257,0}},["arrow-up-narrow-wide"]={16898614410,{256,256},{0,514}},frame={16898671684,{256,256},{257,514}},["clock-12"]={16898618583,{256,256},{0,0}},images={16898673447,{256,256},{0,514}},lollipop={16898674825,{256,256},{0,514}},["folder-root"]={16898671463,{256,256},{0,257}},["arrow-left-circle"]={16898614166,{256,256},{257,0}},["lamp-floor"]={16898673794,{256,256},{257,257}},image={16898673447,{256,256},{257,257}},["badge-euro"]={16898614945,{256,256},{0,257}},bike={16898615570,{256,256},{257,0}},option={16898730417,{256,256},{0,257}},["scroll-text"]={16898734065,{256,256},{257,257}},["toggle-right"]={16898788789,{256,256},{257,514}},["ferris-wheel"]={16898669897,{256,256},{257,514}},["camera-off"]={16898617146,{256,256},{257,0}},["function-square"]={16898672004,{256,256},{514,0}},group={16898672700,{256,256},{0,514}},codesandbox={16898619015,{256,256},{514,257}},expand={16898669772,{256,256},{514,257}},["tent-tree"]={16898788248,{256,256},{514,0}},settings={16898734421,{256,256},{514,0}},bitcoin={16898615570,{256,256},{0,514}},["thumbs-up"]={16898788660,{256,256},{257,257}},["calendar-search"]={16898617053,{256,256},{514,257}},["hand-platter"]={16898672829,{256,256},{257,257}},["circle-x"]={16898618049,{256,256},{514,257}},["file-diff"]={16898670072,{256,256},{514,257}},["archive-restore"]={16898613699,{256,256},{0,514}},["clock-10"]={16898618392,{256,256},{257,514}},["dice-1"]={16898669042,{256,256},{0,257}},["copy-x"]={16898619423,{256,256},{514,257}},["folder-open-dot"]={16898671263,{256,256},{514,257}},["axis-3d"]={16898614755,{256,256},{257,257}},["arrow-down-1-0"]={16898613869,{256,256},{257,0}},["clipboard-check"]={16898618228,{256,256},{0,257}},["file-x"]={16898670620,{256,256},{257,257}},diff={16898669271,{256,256},{0,0}},dot={16898669433,{256,256},{257,514}},castle={16898617325,{256,256},{0,257}},["power-circle"]={16898732262,{256,256},{514,0}},["fast-forward"]={16898669897,{256,256},{257,257}},["mail-minus"]={16898675156,{256,256},{257,0}},["file-minus-2"]={16898670241,{256,256},{0,257}},paintbrush={16898730641,{256,256},{257,514}},cast={16898617325,{256,256},{257,0}},["parking-square-off"]={16898731301,{256,256},{0,257}},["clipboard-pen"]={16898618392,{256,256},{0,0}},["settings-2"]={16898734421,{256,256},{0,257}},["alarm-clock-off"]={16898612819,{256,256},{0,257}},["ice-cream-2"]={16898673358,{256,256},{257,257}},list={16898674684,{256,256},{257,0}},["file-pie-chart"]={16898670241,{256,256},{514,514}},["square-arrow-right"]={16898735664,{256,256},{257,0}},["scissors-square-dashed-bottom"]={16898733817,{256,256},{514,514}},["remove-formatting"]={16898733146,{256,256},{257,257}},["bookmark-check"]={16898616524,{256,256},{0,514}},cannabis={16898617146,{256,256},{257,514}},["file-plus-2"]={16898670367,{256,256},{0,0}},["bookmark-x"]={16898616524,{256,256},{514,514}},["a-arrow-up"]={16898612629,{256,256},{257,0}},["chevron-right-circle"]={16898617509,{256,256},{514,0}},caravan={16898617249,{256,256},{257,257}},["file-text"]={16898670469,{256,256},{514,0}},["vibrate-off"]={16898790439,{256,256},{0,257}},["mail-check"]={16898675156,{256,256},{0,0}},["square-split-vertical"]={16898736398,{256,256},{257,514}},["file-type-2"]={16898670469,{256,256},{257,257}},["file-code"]={16898670072,{256,256},{257,257}},["file-volume"]={16898670620,{256,256},{257,0}},["flag-triangle-left"]={16898670775,{256,256},{257,514}},["square-equal"]={16898736072,{256,256},{0,257}},["scan-barcode"]={16898733674,{256,256},{514,257}},["cassette-tape"]={16898617325,{256,256},{0,0}},["battery-low"]={16898615240,{256,256},{257,257}},["utility-pole"]={16898790259,{256,256},{514,257}},folder={16898671684,{256,256},{257,0}},signpost={16898734905,{256,256},{514,0}},["file-edit"]={16898670171,{256,256},{0,0}},["globe-2"]={16898672599,{256,256},{0,257}},landmark={16898673999,{256,256},{0,0}},["fish-symbol"]={16898670775,{256,256},{257,257}},["form-input"]={16898671684,{256,256},{0,514}},loader={16898674684,{256,256},{257,257}},bold={16898615799,{256,256},{257,257}},["dice-2"]={16898669042,{256,256},{514,0}},["file-type"]={16898670469,{256,256},{0,514}},["book-user"]={16898616524,{256,256},{0,257}},beer={16898615374,{256,256},{257,514}},["gantt-chart-square"]={16898672166,{256,256},{0,257}},ghost={16898672166,{256,256},{514,514}},globe={16898672599,{256,256},{257,257}},["satellite-dish"]={16898733534,{256,256},{514,514}},binary={16898615570,{256,256},{0,257}},["move-diagonal"]={16898729572,{256,256},{514,0}},["table-cells-merge"]={16898787819,{256,256},{0,257}},["door-closed"]={16898669433,{256,256},{0,514}},["image-minus"]={16898673447,{256,256},{0,0}},utensils={16898790259,{256,256},{0,514}},["paw-print"]={16898731301,{256,256},{514,514}},["bar-chart-4"]={16898615143,{256,256},{514,0}},["book-x"]={16898616524,{256,256},{514,0}},["panel-bottom-close"]={16898730821,{256,256},{257,0}},["hand-heart"]={16898672829,{256,256},{257,0}},["file-code-2"]={16898670072,{256,256},{514,0}},["move-down-left"]={16898729572,{256,256},{257,257}},indent={16898673523,{256,256},{257,0}},joystick={16898673616,{256,256},{0,257}},keyboard={16898673794,{256,256},{257,0}},["toggle-left"]={16898788789,{256,256},{514,257}},skull={16898734905,{256,256},{257,514}},["route-off"]={16898733415,{256,256},{257,257}},["dice-6"]={16898669042,{256,256},{257,514}},lightbulb={16898674337,{256,256},{514,514}},key={16898673616,{256,256},{514,514}},["clock-11"]={16898618392,{256,256},{514,514}},["list-video"]={16898674572,{256,256},{514,514}},["ticket-plus"]={16898788660,{256,256},{514,514}},["square-dashed-bottom"]={16898735845,{256,256},{514,257}},["layout-panel-top"]={16898674182,{256,256},{514,257}},["more-vertical"]={16898729337,{256,256},{257,0}},["monitor-pause"]={16898728878,{256,256},{514,514}},["book-open-check"]={16898616322,{256,256},{514,0}},projector={16898732504,{256,256},{0,0}},["lasso-select"]={16898673999,{256,256},{0,514}},maximize={16898675359,{256,256},{514,514}},["text-quote"]={16898788479,{256,256},{257,257}},["image-up"]={16898673447,{256,256},{514,0}},["message-square-quote"]={16898728402,{256,256},{0,0}},bus={16898616879,{256,256},{514,257}},["square-arrow-down-right"]={16898735593,{256,256},{514,0}},["bed-single"]={16898615374,{256,256},{514,0}},["list-music"]={16898674572,{256,256},{257,0}},["file-spreadsheet"]={16898670367,{256,256},{514,514}},["heart-pulse"]={16898673115,{256,256},{514,514}},["clipboard-list"]={16898618228,{256,256},{0,514}},video={16898790439,{256,256},{0,514}},["contact-round"]={16898619347,{256,256},{0,514}},battery={16898615240,{256,256},{257,514}},microscope={16898728659,{256,256},{514,0}},["message-circle-question"]={16898675752,{256,256},{0,514}},["file-badge"]={16898669984,{256,256},{0,514}},["battery-warning"]={16898615240,{256,256},{514,257}},["git-pull-request"]={16898672450,{256,256},{514,257}},["arrow-down-from-line"]={16898613869,{256,256},{257,257}},briefcase={16898616757,{256,256},{514,257}},biohazard={16898615570,{256,256},{514,0}},moon={16898729141,{256,256},{514,514}},["heading-6"]={16898673115,{256,256},{257,0}},["scale-3d"]={16898733674,{256,256},{514,0}},["chevron-down-circle"]={16898617411,{256,256},{257,257}},["mail-x"]={16898675156,{256,256},{257,514}},["square-dashed-mouse-pointer"]={16898735845,{256,256},{514,514}},["user-cog"]={16898789825,{256,256},{257,0}},["lock-open"]={16898674825,{256,256},{257,0}},["mouse-pointer-square-dashed"]={16898729337,{256,256},{514,257}},pizza={16898731819,{256,256},{514,514}},["pc-case"]={16898731419,{256,256},{0,0}},["arrow-up-wide-narrow"]={16898614574,{256,256},{0,257}},["mouse-pointer"]={16898729337,{256,256},{514,514}},["clock-5"]={16898618583,{256,256},{257,257}},dices={16898669042,{256,256},{514,514}},["rotate-ccw"]={16898733415,{256,256},{257,0}},["align-horizontal-justify-center"]={16898613353,{256,256},{0,257}},mouse={16898729572,{256,256},{0,0}},antenna={16898613613,{256,256},{514,514}},["memory-stick"]={16898675673,{256,256},{257,257}},["scan-eye"]={16898733674,{256,256},{257,514}},["bean-off"]={16898615374,{256,256},{0,0}},["square-check"]={16898735664,{256,256},{514,514}},unlock={16898789451,{256,256},{514,514}},highlighter={16898673271,{256,256},{0,514}},["loader-circle"]={16898674684,{256,256},{514,0}},["hard-drive-upload"]={16898672829,{256,256},{514,514}},["gallery-vertical-end"]={16898672004,{256,256},{257,514}},["menu-square"]={16898675673,{256,256},{0,514}},["hand-coins"]={16898672829,{256,256},{0,0}},["notepad-text"]={16898730298,{256,256},{257,257}},orbit={16898730417,{256,256},{514,0}},["package-open"]={16898730417,{256,256},{514,514}},clock={16898618763,{256,256},{0,0}},["file-pen"]={16898670241,{256,256},{257,514}},["git-compare-arrows"]={16898672316,{256,256},{0,514}},["cloud-sun-rain"]={16898618899,{256,256},{257,257}},["align-horizontal-justify-start"]={16898613353,{256,256},{257,257}},["grid-2x2"]={16898672700,{256,256},{0,0}},percent={16898731539,{256,256},{514,0}},vibrate={16898790439,{256,256},{514,0}},["calendar-plus"]={16898617053,{256,256},{257,257}},brain={16898616757,{256,256},{0,257}},["arrow-down-z-a"]={16898614020,{256,256},{514,514}},bath={16898615240,{256,256},{257,0}},["panel-right-close"]={16898731024,{256,256},{0,257}},["unlink-2"]={16898789451,{256,256},{0,514}},paperclip={16898731166,{256,256},{514,257}},["parking-circle"]={16898731301,{256,256},{0,0}},["folder-check"]={16898671139,{256,256},{0,0}},["parking-square"]={16898731301,{256,256},{514,0}},["book-key"]={16898616080,{256,256},{514,514}},ribbon={16898733317,{256,256},{257,257}},microwave={16898728659,{256,256},{257,257}},["air-vent"]={16898612629,{256,256},{514,257}},["library-big"]={16898674337,{256,256},{0,257}},["file-json"]={16898670171,{256,256},{0,514}},["folder-open"]={16898671263,{256,256},{257,514}},["monitor-off"]={16898728878,{256,256},{257,514}},["square-scissors"]={16898736398,{256,256},{514,0}},["move-up-left"]={16898729752,{256,256},{257,0}},brush={16898616757,{256,256},{514,514}},["folder-heart"]={16898671263,{256,256},{0,0}},hash={16898672954,{256,256},{0,257}},["arrow-up-1-0"]={16898614275,{256,256},{0,514}},["arrow-right"]={16898614275,{256,256},{514,0}},["arrow-up-a-z"]={16898614275,{256,256},{514,257}},["badge-x"]={16898615022,{256,256},{257,257}},["panel-bottom-inactive"]={16898730821,{256,256},{514,0}},["file-video-2"]={16898670469,{256,256},{257,514}},["phone-call"]={16898731539,{256,256},{0,514}},construction={16898619347,{256,256},{514,0}},["swatch-book"]={16898787671,{256,256},{257,257}},["receipt-cent"]={16898732855,{256,256},{0,0}},["badge-pound-sterling"]={16898615022,{256,256},{257,0}},["folder-archive"]={16898671019,{256,256},{514,514}},["folder-symlink"]={16898671463,{256,256},{0,514}},["columns-3"]={16898619182,{256,256},{0,257}},ban={16898615022,{256,256},{257,514}},["message-square-x"]={16898728402,{256,256},{0,514}},["paint-roller"]={16898730641,{256,256},{0,514}},plug={16898732061,{256,256},{0,0}},gamepad={16898672166,{256,256},{257,0}},["book-minus"]={16898616322,{256,256},{0,257}},popsicle={16898732262,{256,256},{257,0}},["building-2"]={16898616879,{256,256},{514,0}},["circle-slash-2"]={16898618049,{256,256},{257,0}},["rectangle-horizontal"]={16898733036,{256,256},{257,0}},cake={16898616953,{256,256},{257,0}},["cloud-rain"]={16898618899,{256,256},{0,257}},["maximize-2"]={16898675359,{256,256},{257,514}},["redo-2"]={16898733036,{256,256},{257,257}},wrench={16898791187,{256,256},{514,257}},["repeat-2"]={16898733146,{256,256},{514,257}},codepen={16898619015,{256,256},{0,514}},reply={16898733317,{256,256},{0,257}},["flag-triangle-right"]={16898670775,{256,256},{514,514}},["rotate-ccw-square"]={16898733415,{256,256},{0,0}},["scan-search"]={16898733817,{256,256},{257,0}},bell={16898615428,{256,256},{0,514}},["grid-3x3"]={16898672700,{256,256},{257,0}},save={16898733674,{256,256},{0,257}},["music-3"]={16898729752,{256,256},{257,514}},focus={16898671019,{256,256},{0,514}},["user-check"]={16898789644,{256,256},{514,257}},proportions={16898732504,{256,256},{257,0}},["alert-octagon"]={16898613044,{256,256},{257,0}},plane={16898731919,{256,256},{0,257}},["webhook-off"]={16898790996,{256,256},{257,0}},carrot={16898617249,{256,256},{0,514}},["square-arrow-left"]={16898735593,{256,256},{0,514}},["file-cog"]={16898670072,{256,256},{0,514}},heart={16898673271,{256,256},{0,0}},["scan-face"]={16898733674,{256,256},{514,514}},["folder-down"]={16898671139,{256,256},{0,514}},["layout-template"]={16898674182,{256,256},{257,514}},mailbox={16898675359,{256,256},{0,0}},home={16898673271,{256,256},{257,514}},["traffic-cone"]={16898788908,{256,256},{514,257}},scissors={16898734065,{256,256},{257,0}},split={16898735455,{256,256},{257,514}},twitter={16898789303,{256,256},{0,257}},["locate-off"]={16898674684,{256,256},{514,257}},forklift={16898671684,{256,256},{257,257}},["square-arrow-out-up-left"]={16898735593,{256,256},{514,514}},component={16898619182,{256,256},{514,514}},["panels-left-bottom"]={16898731166,{256,256},{514,0}},["message-square-diff"]={16898675863,{256,256},{514,0}},["book-marked"]={16898616322,{256,256},{257,0}},["alarm-plus"]={16898612819,{256,256},{514,257}},["bluetooth-connected"]={16898615799,{256,256},{0,0}},unlink={16898789451,{256,256},{514,257}},signal={16898734905,{256,256},{257,0}},slack={16898734905,{256,256},{514,514}},["file-volume-2"]={16898670620,{256,256},{0,0}},["pound-sterling"]={16898732262,{256,256},{0,257}},power={16898732262,{256,256},{514,257}},["skip-forward"]={16898734905,{256,256},{514,257}},["m-square"]={16898674825,{256,256},{257,514}},["git-merge"]={16898672450,{256,256},{0,0}},["file-box"]={16898669984,{256,256},{514,514}},["align-justify"]={16898613353,{256,256},{257,514}},["paint-bucket"]={16898730641,{256,256},{257,257}},wallpaper={16898790791,{256,256},{0,0}},filter={16898670775,{256,256},{0,0}},glasses={16898672599,{256,256},{257,0}},["piggy-bank"]={16898731819,{256,256},{257,0}},["square-play"]={16898736237,{256,256},{514,514}},shell={16898734421,{256,256},{514,514}},["cloud-off"]={16898618899,{256,256},{0,0}},["check-check"]={16898617325,{256,256},{0,514}},activity={16898612629,{256,256},{0,514}},axe={16898614755,{256,256},{514,0}},["plane-takeoff"]={16898731919,{256,256},{257,0}},snowflake={16898735175,{256,256},{0,257}},["cloud-rain-wind"]={16898618899,{256,256},{257,0}},["square-plus"]={16898736398,{256,256},{0,0}},["dice-5"]={16898669042,{256,256},{514,257}},["search-slash"]={16898734065,{256,256},{514,514}},["file-axis-3d"]={16898669984,{256,256},{514,0}},["receipt-euro"]={16898732855,{256,256},{257,0}},["square-radical"]={16898736398,{256,256},{0,257}},["cloud-drizzle"]={16898618763,{256,256},{514,0}},["bug-play"]={16898616879,{256,256},{257,0}},["align-vertical-distribute-start"]={16898613509,{256,256},{0,514}},layout={16898674182,{256,256},{514,514}},["square-stack"]={16898736398,{256,256},{514,514}},["tally-5"]={16898788033,{256,256},{514,514}},squirrel={16898736597,{256,256},{514,257}},["pen-square"]={16898731419,{256,256},{0,257}},["folder-lock"]={16898671263,{256,256},{257,257}},["circle-divide"]={16898617884,{256,256},{257,0}},["case-sensitive"]={16898617249,{256,256},{257,514}},sunset={16898787671,{256,256},{0,257}},linkedin={16898674482,{256,256},{257,257}},["life-buoy"]={16898674337,{256,256},{0,514}},["circle-play"]={16898617944,{256,256},{257,514}},["tally-4"]={16898788033,{256,256},{257,514}},["volume-2"]={16898790615,{256,256},{257,0}},["battery-charging"]={16898615240,{256,256},{0,257}},["russian-ruble"]={16898733534,{256,256},{257,257}},["wallet-minimal"]={16898790615,{256,256},{257,514}},["earth-lock"]={16898669689,{256,256},{514,0}},footprints={16898671684,{256,256},{514,0}},["text-cursor-input"]={16898788479,{256,256},{0,257}},building={16898616879,{256,256},{257,257}},["lock-keyhole-open"]={16898674684,{256,256},{514,514}},twitch={16898789303,{256,256},{257,0}},["thermometer-sun"]={16898788660,{256,256},{257,0}},["switch-camera"]={16898787671,{256,256},{514,257}},club={16898619015,{256,256},{257,0}},["shield-plus"]={16898734564,{256,256},{257,514}},["alarm-check"]={16898612629,{256,256},{514,514}},["bell-minus"]={16898615428,{256,256},{257,0}},["log-in"]={16898674825,{256,256},{514,0}},["bot-message-square"]={16898616650,{256,256},{0,257}},drum={16898669562,{256,256},{257,514}},["arrow-up-z-a"]={16898614574,{256,256},{514,0}},sun={16898787671,{256,256},{0,0}},["layers-3"]={16898674182,{256,256},{0,0}},["zoom-out"]={16898791349,{256,256},{514,257}},["file-key"]={16898670171,{256,256},{257,514}},tractor={16898788908,{256,256},{0,514}},["school-2"]={16898733817,{256,256},{0,514}},["scissors-line-dashed"]={16898733817,{256,256},{257,514}},["text-select"]={16898788479,{256,256},{514,257}},["file-search"]={16898670367,{256,256},{0,514}},["unfold-vertical"]={16898789451,{256,256},{0,257}},["ticket-check"]={16898788660,{256,256},{0,514}},pyramid={16898732504,{256,256},{514,0}},["hard-drive"]={16898672954,{256,256},{0,0}},["user-cog-2"]={16898789825,{256,256},{0,0}},["refresh-cw-off"]={16898733146,{256,256},{0,0}},["external-link"]={16898669772,{256,256},{257,514}},["picture-in-picture-2"]={16898731683,{256,256},{257,514}},["file-x-2"]={16898670620,{256,256},{514,0}},["flower-2"]={16898671019,{256,256},{514,0}},["calendar-x"]={16898617053,{256,256},{514,514}},["user-round-check"]={16898789825,{256,256},{514,257}},["user-round"]={16898790047,{256,256},{514,0}},["link-2-off"]={16898674482,{256,256},{257,0}},["keyboard-music"]={16898673794,{256,256},{0,0}},["star-half"]={16898736597,{256,256},{514,514}},["user-x"]={16898790047,{256,256},{514,514}},["code-xml"]={16898619015,{256,256},{514,0}},["trending-up"]={16898789153,{256,256},{257,0}},mails={16898675359,{256,256},{257,0}},["brain-cog"]={16898616757,{256,256},{257,0}},tablet={16898788033,{256,256},{0,0}},["users-round"]={16898790259,{256,256},{0,257}},pi={16898731683,{256,256},{257,257}},trash={16898789012,{256,256},{514,0}},dock={16898669433,{256,256},{257,0}},["hdmi-port"]={16898672954,{256,256},{257,257}},braces={16898616650,{256,256},{257,514}},["case-upper"]={16898617249,{256,256},{514,514}},["move-3d"]={16898729572,{256,256},{257,0}},wallet={16898790615,{256,256},{514,514}},croissant={16898668482,{256,256},{514,0}},["monitor-speaker"]={16898729141,{256,256},{0,257}},waves={16898790791,{256,256},{257,514}},barcode={16898615143,{256,256},{514,514}},lock={16898674825,{256,256},{0,257}},["wheat-off"]={16898790996,{256,256},{257,257}},bed={16898615374,{256,256},{257,257}},quote={16898732504,{256,256},{0,514}},divide={16898669271,{256,256},{257,514}},grape={16898672599,{256,256},{514,514}},["play-square"]={16898731919,{256,256},{257,257}},["party-popper"]={16898731301,{256,256},{257,257}},["file-video"]={16898670469,{256,256},{514,514}},university={16898789451,{256,256},{257,257}},["user-circle-2"]={16898789644,{256,256},{257,514}},truck={16898789153,{256,256},{514,257}},box={16898616650,{256,256},{0,514}},["calendar-range"]={16898617053,{256,256},{0,514}},subscript={16898736967,{256,256},{514,0}},["zap-off"]={16898791349,{256,256},{514,0}},["square-check-big"]={16898735664,{256,256},{257,514}},["wand-sparkles"]={16898790791,{256,256},{0,257}},["square-chevron-up"]={16898735845,{256,256},{514,0}},["circle-ellipsis"]={16898617884,{256,256},{0,514}},["laptop-minimal"]={16898673999,{256,256},{514,0}},["radio-receiver"]={16898732665,{256,256},{257,0}},sofa={16898735175,{256,256},{514,0}},["square-asterisk"]={16898735664,{256,256},{0,514}},wine={16898791187,{256,256},{0,257}},cookie={16898619423,{256,256},{0,0}},["message-square-more"]={16898675863,{256,256},{514,257}},clapperboard={16898618228,{256,256},{257,0}},euro={16898669772,{256,256},{0,514}},["dice-3"]={16898669042,{256,256},{257,257}},["heart-off"]={16898673115,{256,256},{257,514}},["clipboard-minus"]={16898618228,{256,256},{514,257}},info={16898673523,{256,256},{257,257}},["move-horizontal"]={16898729572,{256,256},{257,514}},["file-sliders"]={16898670367,{256,256},{257,514}},frown={16898672004,{256,256},{0,0}},["cloud-hail"]={16898618763,{256,256},{0,514}},["cup-soda"]={16898668755,{256,256},{0,0}},["cable-car"]={16898616879,{256,256},{257,514}},["lock-keyhole"]={16898674825,{256,256},{0,0}},sword={16898787671,{256,256},{257,514}},play={16898731919,{256,256},{0,514}},["laptop-2"]={16898673999,{256,256},{0,257}},earth={16898669689,{256,256},{257,257}},slice={16898735040,{256,256},{257,0}},["land-plot"]={16898673794,{256,256},{514,514}},milk={16898728659,{256,256},{257,514}},["circle-user"]={16898618049,{256,256},{0,514}},["align-left"]={16898613353,{256,256},{514,514}},["circle-slash"]={16898618049,{256,256},{0,257}},contact={16898619347,{256,256},{514,257}},["rotate-cw-square"]={16898733415,{256,256},{0,257}},atom={16898614574,{256,256},{514,514}},["package-x"]={16898730641,{256,256},{0,257}},["bed-double"]={16898615374,{256,256},{0,257}},anchor={16898613613,{256,256},{0,514}},["circle-dot"]={16898617884,{256,256},{257,257}},["git-commit-horizontal"]={16898672316,{256,256},{514,0}},["git-commit-vertical"]={16898672316,{256,256},{257,257}},["message-circle-code"]={16898675673,{256,256},{514,514}},["folder-git-2"]={16898671139,{256,256},{257,514}},["message-square-code"]={16898675863,{256,256},{257,0}},["mail-plus"]={16898675156,{256,256},{514,0}},["diamond-percent"]={16898669042,{256,256},{0,0}},["message-circle-heart"]={16898675752,{256,256},{257,0}},["arrow-big-left-dash"]={16898613777,{256,256},{514,0}},["circle-arrow-out-down-left"]={16898617705,{256,256},{514,257}},dumbbell={16898669689,{256,256},{0,0}},["file-music"]={16898670241,{256,256},{257,257}},["alert-triangle"]={16898613044,{256,256},{0,257}},["chevrons-right-left"]={16898617626,{256,256},{257,257}},scale={16898733674,{256,256},{257,257}},eraser={16898669772,{256,256},{257,257}},["flashlight-off"]={16898670919,{256,256},{514,0}},["panel-top-open"]={16898731166,{256,256},{257,0}},["cloud-lightning"]={16898618763,{256,256},{514,257}},ungroup={16898789451,{256,256},{514,0}},notebook={16898730298,{256,256},{0,257}},["power-square"]={16898732262,{256,256},{0,514}},sprout={16898735593,{256,256},{0,0}},["square-menu"]={16898736072,{256,256},{514,514}},["mic-vocal"]={16898728659,{256,256},{257,0}},["monitor-smartphone"]={16898729141,{256,256},{257,0}},laptop={16898673999,{256,256},{257,257}},["scan-line"]={16898733817,{256,256},{0,0}},["clock-4"]={16898618583,{256,256},{514,0}},["square-arrow-up"]={16898735664,{256,256},{257,257}},copyright={16898668288,{256,256},{0,0}},["monitor-up"]={16898729141,{256,256},{257,257}},["unlock-keyhole"]={16898789451,{256,256},{257,514}},usb={16898789644,{256,256},{514,0}},rocket={16898733317,{256,256},{0,514}},["arrow-down-to-line"]={16898614020,{256,256},{0,514}},["book-plus"]={16898616322,{256,256},{514,257}},["refresh-ccw"]={16898733036,{256,256},{514,514}},["venetian-mask"]={16898790439,{256,256},{257,0}},["calendar-check-2"]={16898616953,{256,256},{514,0}},["arrow-down-square"]={16898614020,{256,256},{514,0}},spline={16898735455,{256,256},{257,257}},mail={16898675156,{256,256},{514,514}},["git-pull-request-create-arrow"]={16898672450,{256,256},{514,0}},["library-square"]={16898674337,{256,256},{514,0}},["circle-check"]={16898617803,{256,256},{257,257}},["square-arrow-up-right"]={16898735664,{256,256},{514,0}},["book-text"]={16898616322,{256,256},{257,514}},user={16898790259,{256,256},{0,0}},["file-key-2"]={16898670171,{256,256},{514,257}},["gallery-horizontal"]={16898672004,{256,256},{0,514}},["circle-chevron-right"]={16898617803,{256,256},{257,514}},["timer-off"]={16898788789,{256,256},{514,0}},["arrow-big-right-dash"]={16898613777,{256,256},{0,514}},["wallet-2"]={16898790615,{256,256},{0,514}},cloud={16898618899,{256,256},{257,514}},triangle={16898789153,{256,256},{257,257}},backpack={16898614755,{256,256},{514,257}},lamp={16898673794,{256,256},{257,514}},flower={16898671019,{256,256},{257,257}},youtube={16898791349,{256,256},{0,257}},["upload-cloud"]={16898789644,{256,256},{257,0}},lasso={16898673999,{256,256},{514,257}},["arrow-down-right"]={16898614020,{256,256},{0,257}},sailboat={16898733534,{256,256},{0,514}},receipt={16898732855,{256,256},{514,514}},["bell-ring"]={16898615428,{256,256},{257,257}},["heart-crack"]={16898673115,{256,256},{0,514}},["tree-deciduous"]={16898789012,{256,256},{257,257}},["fire-extinguisher"]={16898670775,{256,256},{0,257}},["baggage-claim"]={16898615022,{256,256},{514,257}},["image-off"]={16898673447,{256,256},{257,0}},["arrow-left-to-line"]={16898614166,{256,256},{0,514}},["layout-grid"]={16898674182,{256,256},{514,0}},["pi-square"]={16898731683,{256,256},{514,0}},["clock-3"]={16898618583,{256,256},{0,257}},["square-chevron-right"]={16898735845,{256,256},{0,257}},navigation={16898730065,{256,256},{257,257}},["filter-x"]={16898670620,{256,256},{514,514}},["bar-chart-3"]={16898615143,{256,256},{0,257}},["map-pin"]={16898675359,{256,256},{514,0}},["arrow-down-right-from-circle"]={16898614020,{256,256},{0,0}},["shopping-bag"]={16898734664,{256,256},{0,514}},["chevron-right"]={16898617509,{256,256},{0,514}},["tally-1"]={16898788033,{256,256},{257,257}},ampersand={16898613613,{256,256},{514,0}},["arrow-up-from-line"]={16898614410,{256,256},{257,0}},["shopping-cart"]={16898734664,{256,256},{257,514}},["user-minus-2"]={16898789825,{256,256},{0,257}},vote={16898790615,{256,256},{257,257}},["alarm-smoke"]={16898612819,{256,256},{257,514}},["file-line-chart"]={16898670171,{256,256},{514,514}},["file-input"]={16898670171,{256,256},{514,0}},["clock-8"]={16898618583,{256,256},{257,514}},["server-cog"]={16898734242,{256,256},{257,514}},["cloud-cog"]={16898618763,{256,256},{257,0}},blend={16898615570,{256,256},{514,257}},["search-x"]={16898734242,{256,256},{0,0}},["radio-tower"]={16898732665,{256,256},{0,257}},["list-tree"]={16898674572,{256,256},{257,514}},droplet={16898669562,{256,256},{0,514}},["panel-right-open"]={16898731024,{256,256},{0,514}},eye={16898669897,{256,256},{0,0}},siren={16898734905,{256,256},{257,257}},star={16898736776,{256,256},{257,0}},banana={16898615022,{256,256},{514,514}},["panel-top"]={16898731166,{256,256},{0,257}},donut={16898669433,{256,256},{257,257}},telescope={16898788248,{256,256},{0,257}},["circle-equal"]={16898617884,{256,256},{514,257}},["arrow-up-right"]={16898614410,{256,256},{514,514}},calculator={16898616953,{256,256},{0,257}},magnet={16898674825,{256,256},{514,514}},crown={16898668482,{256,256},{257,514}},subtitles={16898736967,{256,256},{257,257}},["brick-wall"]={16898616757,{256,256},{514,0}},["message-circle-dashed"]={16898675752,{256,256},{0,0}},["leafy-green"]={16898674337,{256,256},{257,0}},["message-square-dot"]={16898675863,{256,256},{257,257}},["arrow-down-a-z"]={16898613869,{256,256},{0,257}},copyleft={16898619423,{256,256},{514,514}},["monitor-play"]={16898729141,{256,256},{0,0}},["text-cursor"]={16898788479,{256,256},{514,0}},["minimize-2"]={16898728659,{256,256},{514,514}},disc={16898669271,{256,256},{257,257}},locate={16898674684,{256,256},{257,514}},cone={16898619347,{256,256},{0,257}},["heading-1"]={16898672954,{256,256},{0,514}},["file-image"]={16898670171,{256,256},{0,257}},sparkles={16898735175,{256,256},{514,514}},palette={16898730641,{256,256},{514,514}},["user-plus-2"]={16898789825,{256,256},{257,257}},["gallery-thumbnails"]={16898672004,{256,256},{514,257}},["book-up"]={16898616524,{256,256},{257,0}},cpu={16898668482,{256,256},{0,0}},["split-square-horizontal"]={16898735455,{256,256},{0,514}},["thumbs-down"]={16898788660,{256,256},{514,0}},merge={16898675673,{256,256},{257,514}},["circle-dashed"]={16898617884,{256,256},{0,0}},["bar-chart-big"]={16898615143,{256,256},{257,257}},["test-tubes"]={16898788479,{256,256},{257,0}},hospital={16898673358,{256,256},{257,0}},haze={16898672954,{256,256},{514,0}},plus={16898732061,{256,256},{514,0}},["align-vertical-space-around"]={16898613613,{256,256},{0,0}},["key-square"]={16898673616,{256,256},{257,514}},palmtree={16898730821,{256,256},{0,0}},["file-audio"]={16898669984,{256,256},{0,257}},kanban={16898673616,{256,256},{0,514}},["sliders-vertical"]={16898735040,{256,256},{514,0}},apple={16898613699,{256,256},{257,257}},["wine-off"]={16898791187,{256,256},{257,0}},["check-circle"]={16898617325,{256,256},{257,514}},cuboid={16898668482,{256,256},{514,514}},["square-code"]={16898735845,{256,256},{257,257}},["bug-off"]={16898616879,{256,256},{0,0}},["circle-arrow-out-up-left"]={16898617705,{256,256},{514,514}},["corner-right-down"]={16898668288,{256,256},{0,514}},["plug-zap-2"]={16898731919,{256,256},{257,514}},["heading-2"]={16898672954,{256,256},{514,257}},["square-activity"]={16898735593,{256,256},{257,0}},["package-plus"]={16898730641,{256,256},{0,0}},["cigarette-off"]={16898617705,{256,256},{257,0}},["align-vertical-justify-start"]={16898613509,{256,256},{514,514}},["power-off"]={16898732262,{256,256},{257,257}},["undo-2"]={16898789303,{256,256},{257,514}},router={16898733415,{256,256},{514,257}},["tower-control"]={16898788908,{256,256},{514,0}},["git-branch"]={16898672316,{256,256},{0,257}},shovel={16898734664,{256,256},{514,514}},share={16898734421,{256,256},{514,257}},["wallet-cards"]={16898790615,{256,256},{514,257}},["square-arrow-out-down-right"]={16898735593,{256,256},{257,514}},["circuit-board"]={16898618049,{256,256},{514,514}},shield={16898734664,{256,256},{257,0}},["bar-chart-2"]={16898615143,{256,256},{257,0}},["cloud-snow"]={16898618899,{256,256},{514,0}},["file-question"]={16898670367,{256,256},{0,257}},["arrow-big-up-dash"]={16898613777,{256,256},{257,514}},["folder-closed"]={16898671139,{256,256},{0,257}},["smartphone-nfc"]={16898735040,{256,256},{514,257}},network={16898730065,{256,256},{0,514}},["file-bar-chart"]={16898669984,{256,256},{257,514}},["user-round-x"]={16898790047,{256,256},{0,257}},["signal-low"]={16898734792,{256,256},{257,514}},["mail-question"]={16898675156,{256,256},{257,257}},["clipboard-plus"]={16898618392,{256,256},{257,0}},["file-minus"]={16898670241,{256,256},{514,0}},["list-end"]={16898674482,{256,256},{257,514}},torus={16898788908,{256,256},{0,0}},["arrow-down-left"]={16898613869,{256,256},{257,514}},["chevrons-right"]={16898617626,{256,256},{0,514}},["file-badge-2"]={16898669984,{256,256},{257,257}},["message-square-reply"]={16898728402,{256,256},{257,0}},["corner-down-right"]={16898668288,{256,256},{0,257}},["gauge-circle"]={16898672166,{256,256},{257,257}},["users-2"]={16898790259,{256,256},{257,0}},["lamp-wall-down"]={16898673794,{256,256},{0,514}},["square-bottom-dashed-scissors"]={16898735664,{256,256},{514,257}},["repeat"]={16898733146,{256,256},{257,514}},["ellipsis-vertical"]={16898669772,{256,256},{0,0}},snail={16898735175,{256,256},{257,0}},check={16898617411,{256,256},{257,0}},["square-parking"]={16898736237,{256,256},{514,0}},["align-horizontal-justify-end"]={16898613353,{256,256},{514,0}},["mail-search"]={16898675156,{256,256},{0,514}},["align-vertical-distribute-end"]={16898613509,{256,256},{257,257}},soup={16898735175,{256,256},{257,257}},airplay={16898612629,{256,256},{257,514}},pentagon={16898731419,{256,256},{514,514}},["rocking-chair"]={16898733317,{256,256},{514,257}},["between-horizontal-start"]={16898615428,{256,256},{257,514}},["monitor-x"]={16898729141,{256,256},{0,514}},["octagon-pause"]={16898730298,{256,256},{514,514}},["square-kanban"]={16898736072,{256,256},{0,514}},["square-pen"]={16898736237,{256,256},{257,257}},["rectangle-vertical"]={16898733036,{256,256},{0,257}},["panels-right-bottom"]={16898731166,{256,256},{257,257}},["gantt-chart"]={16898672166,{256,256},{514,0}},octagon={16898730417,{256,256},{257,0}},ticket={16898788789,{256,256},{0,257}},pocket={16898732061,{256,256},{0,514}},["link-2"]={16898674482,{256,256},{0,257}},["train-front"]={16898788908,{256,256},{514,514}},["spray-can"]={16898735455,{256,256},{514,514}},["arrow-up-0-1"]={16898614275,{256,256},{257,257}},album={16898612819,{256,256},{514,514}},replace={16898733317,{256,256},{0,0}},["move-right"]={16898729752,{256,256},{0,0}},["hand-helping"]={16898672829,{256,256},{0,257}},["list-collapse"]={16898674482,{256,256},{514,257}},gauge={16898672166,{256,256},{0,514}},store={16898736776,{256,256},{514,514}},["circle-arrow-down"]={16898617705,{256,256},{257,257}},["notebook-pen"]={16898730065,{256,256},{514,514}},["egg-fried"]={16898669689,{256,256},{514,257}},ligature={16898674337,{256,256},{514,257}},["sticky-note"]={16898736776,{256,256},{514,257}},["corner-right-up"]={16898668288,{256,256},{514,257}},["badge-help"]={16898614945,{256,256},{514,0}},["panel-top-inactive"]={16898731166,{256,256},{0,0}},["user-round-plus"]={16898790047,{256,256},{0,0}},["panel-left-close"]={16898730821,{256,256},{514,257}},rewind={16898733317,{256,256},{514,0}},fuel={16898672004,{256,256},{257,0}},["divide-circle"]={16898669271,{256,256},{0,514}},["square-arrow-out-up-right"]={16898735664,{256,256},{0,0}},["chevrons-down-up"]={16898617626,{256,256},{0,0}},["message-square-text"]={16898728402,{256,256},{514,0}},["user-round-search"]={16898790047,{256,256},{257,0}},scan={16898733817,{256,256},{514,0}},["monitor-down"]={16898728878,{256,256},{514,257}},["play-circle"]={16898731919,{256,256},{514,0}},["file-digit"]={16898670072,{256,256},{257,514}},slash={16898735040,{256,256},{0,0}},["split-square-vertical"]={16898735455,{256,256},{514,257}},aperture={16898613699,{256,256},{257,0}},["arrow-right-left"]={16898614275,{256,256},{0,0}},["helping-hand"]={16898673271,{256,256},{514,0}},["flask-conical-off"]={16898670919,{256,256},{0,514}},["circle-gauge"]={16898617884,{256,256},{514,514}},crosshair={16898668482,{256,256},{514,257}},["move-down-right"]={16898729572,{256,256},{0,514}},["text-search"]={16898788479,{256,256},{0,514}},["square-slash"]={16898736398,{256,256},{0,514}},sandwich={16898733534,{256,256},{257,514}},factory={16898669897,{256,256},{0,257}},["chef-hat"]={16898617411,{256,256},{0,257}},["arrow-down-to-dot"]={16898614020,{256,256},{257,257}},["image-plus"]={16898673447,{256,256},{0,257}},["file-archive"]={16898669984,{256,256},{0,0}},["signal-high"]={16898734792,{256,256},{514,257}},inbox={16898673447,{256,256},{257,514}},["flip-horizontal-2"]={16898670919,{256,256},{514,514}},["book-type"]={16898616322,{256,256},{514,514}},["file-signature"]={16898670367,{256,256},{514,257}},["align-horizontal-space-between"]={16898613353,{256,256},{514,257}},["bookmark-minus"]={16898616524,{256,256},{514,257}},["calendar-check"]={16898616953,{256,256},{257,257}},["database-zap"]={16898668755,{256,256},{257,257}},droplets={16898669562,{256,256},{514,257}},boxes={16898616650,{256,256},{514,257}},["bell-electric"]={16898615428,{256,256},{0,0}},["bar-chart"]={16898615143,{256,256},{257,514}},["layout-list"]={16898674182,{256,256},{257,257}},link={16898674482,{256,256},{514,0}},["download-cloud"]={16898669433,{256,256},{514,514}},["alarm-clock-plus"]={16898612819,{256,256},{514,0}},["circle-dollar-sign"]={16898617884,{256,256},{0,257}},["activity-square"]={16898612629,{256,256},{257,257}},["arrow-up-square"]={16898614574,{256,256},{0,0}},["receipt-pound-sterling"]={16898732855,{256,256},{257,257}},grab={16898672599,{256,256},{514,257}},["align-center-horizontal"]={16898613044,{256,256},{514,0}},undo={16898789451,{256,256},{0,0}},ratio={16898732665,{256,256},{514,514}},minimize={16898728878,{256,256},{0,0}},["user-square-2"]={16898790047,{256,256},{0,514}},heading={16898673115,{256,256},{0,257}},["panel-top-close"]={16898731024,{256,256},{257,514}},["grip-horizontal"]={16898672700,{256,256},{0,257}},["boom-box"]={16898616650,{256,256},{257,0}},package={16898730641,{256,256},{514,0}},["user-round-minus"]={16898789825,{256,256},{514,514}},["file-audio-2"]={16898669984,{256,256},{257,0}},["align-end-horizontal"]={16898613044,{256,256},{514,257}},mountain={16898729337,{256,256},{514,0}},["arrow-down-left-square"]={16898613869,{256,256},{514,257}},["folder-kanban"]={16898671263,{256,256},{0,257}},["octagon-x"]={16898730417,{256,256},{0,0}},languages={16898673999,{256,256},{257,0}},["file-json-2"]={16898670171,{256,256},{257,257}},["alarm-clock-check"]={16898612819,{256,256},{0,0}},["refresh-cw"]={16898733146,{256,256},{257,0}},medal={16898675673,{256,256},{0,0}},["beer-off"]={16898615374,{256,256},{514,257}},["search-code"]={16898734065,{256,256},{257,514}},["square-parking-off"]={16898736237,{256,256},{0,257}},["notebook-text"]={16898730298,{256,256},{257,0}},["arrow-right-to-line"]={16898614275,{256,256},{0,257}},["ticket-minus"]={16898788660,{256,256},{514,257}},["test-tube-diagonal"]={16898788248,{256,256},{514,514}},["rows-4"]={16898733534,{256,256},{0,0}},["pencil-line"]={16898731419,{256,256},{0,514}},["door-open"]={16898669433,{256,256},{514,257}},["arrow-down-circle"]={16898613869,{256,256},{514,0}},["pen-line"]={16898731419,{256,256},{257,0}},file={16898670620,{256,256},{0,514}},["git-compare"]={16898672316,{256,256},{514,257}},["pocket-knife"]={16898732061,{256,256},{257,257}},["book-copy"]={16898616080,{256,256},{0,257}},["panel-left-inactive"]={16898730821,{256,256},{514,514}},["car-front"]={16898617249,{256,256},{257,0}},["align-start-horizontal"]={16898613509,{256,256},{257,0}},["reply-all"]={16898733317,{256,256},{257,0}},["cloud-moon-rain"]={16898618763,{256,256},{257,514}},["clipboard-type"]={16898618392,{256,256},{514,0}},["contact-2"]={16898619347,{256,256},{257,257}},["list-todo"]={16898674572,{256,256},{514,257}},tablets={16898788033,{256,256},{257,0}},["pie-chart"]={16898731819,{256,256},{0,0}},["list-start"]={16898674572,{256,256},{0,514}},milestone={16898728659,{256,256},{0,514}},["a-large-small"]={16898612629,{256,256},{0,257}},ship={16898734664,{256,256},{514,0}},["percent-circle"]={16898731539,{256,256},{0,0}},radiation={16898732504,{256,256},{514,514}},["code-2"]={16898619015,{256,256},{0,257}},["tablet-smartphone"]={16898787819,{256,256},{514,514}},["phone-forwarded"]={16898731539,{256,256},{514,257}},["gallery-vertical"]={16898672004,{256,256},{514,514}},["arrow-right-from-line"]={16898614166,{256,256},{514,514}},webcam={16898790996,{256,256},{0,0}},["square-power"]={16898736398,{256,256},{257,0}},["circle-help"]={16898617944,{256,256},{0,0}},["bring-to-front"]={16898616757,{256,256},{257,514}},archive={16898613699,{256,256},{257,514}},figma={16898669897,{256,256},{514,514}},school={16898733817,{256,256},{514,257}},download={16898669562,{256,256},{0,0}},piano={16898731683,{256,256},{0,514}},["line-chart"]={16898674482,{256,256},{0,0}},folders={16898671684,{256,256},{0,257}},["mail-warning"]={16898675156,{256,256},{514,257}},vault={16898790259,{256,256},{514,514}},["pause-circle"]={16898731301,{256,256},{0,514}},["mic-2"]={16898728402,{256,256},{514,514}},["chevrons-left-right"]={16898617626,{256,256},{0,257}},redo={16898733036,{256,256},{514,257}},["file-lock"]={16898670241,{256,256},{257,0}},radar={16898732504,{256,256},{257,514}},["circle-fading-plus"]={16898617884,{256,256},{257,514}},workflow={16898791187,{256,256},{514,0}},["undo-dot"]={16898789303,{256,256},{514,514}},target={16898788248,{256,256},{257,0}},["corner-left-down"]={16898668288,{256,256},{514,0}},["indent-increase"]={16898673523,{256,256},{0,0}},drama={16898669562,{256,256},{0,257}},["arrow-down-up"]={16898614020,{256,256},{514,257}},baseline={16898615240,{256,256},{0,0}},martini={16898675359,{256,256},{514,257}},contrast={16898619347,{256,256},{514,514}},["shield-ban"]={16898734564,{256,256},{257,0}},syringe={16898787819,{256,256},{0,0}},["chevron-left-circle"]={16898617509,{256,256},{0,0}},["book-check"]={16898616080,{256,256},{257,0}},["nut-off"]={16898730298,{256,256},{0,514}},["book-lock"]={16898616322,{256,256},{0,0}},["panel-right-inactive"]={16898731024,{256,256},{257,257}},["briefcase-medical"]={16898616757,{256,256},{0,514}},bookmark={16898616650,{256,256},{0,0}},["heading-5"]={16898673115,{256,256},{0,0}},["align-vertical-justify-end"]={16898613509,{256,256},{257,514}},["hop-off"]={16898673271,{256,256},{514,514}},warehouse={16898790791,{256,256},{257,257}},["plus-square"]={16898732061,{256,256},{0,257}},["drafting-compass"]={16898669562,{256,256},{257,0}},["save-all"]={16898733674,{256,256},{257,0}},["plus-circle"]={16898732061,{256,256},{257,0}},["square-sigma"]={16898736398,{256,256},{257,257}},["clipboard-signature"]={16898618392,{256,256},{0,257}},["fold-horizontal"]={16898671019,{256,256},{514,257}},["notepad-text-dashed"]={16898730298,{256,256},{514,0}},["glass-water"]={16898672599,{256,256},{0,0}},["book-headphones"]={16898616080,{256,256},{0,514}},["credit-card"]={16898668482,{256,256},{0,257}},["message-circle"]={16898675863,{256,256},{0,0}},["square-pilcrow"]={16898736237,{256,256},{257,514}},radical={16898732665,{256,256},{0,0}},["tally-3"]={16898788033,{256,256},{514,257}},["panel-bottom-open"]={16898730821,{256,256},{257,257}},["kanban-square-dashed"]={16898673616,{256,256},{514,0}},["book-audio"]={16898616080,{256,256},{0,0}},["file-search-2"]={16898670367,{256,256},{257,257}},["receipt-russian-ruble"]={16898732855,{256,256},{0,514}},["square-arrow-up-left"]={16898735664,{256,256},{0,257}},["locate-fixed"]={16898674684,{256,256},{0,514}},["clock-9"]={16898618583,{256,256},{514,514}},pen={16898731419,{256,256},{257,257}},["navigation-2"]={16898730065,{256,256},{0,257}},["candy-cane"]={16898617146,{256,256},{257,257}},["book-open"]={16898616322,{256,256},{0,514}},["user-check-2"]={16898789644,{256,256},{0,514}},["gamepad-2"]={16898672166,{256,256},{0,0}},["badge-info"]={16898614945,{256,256},{0,514}},wheat={16898790996,{256,256},{0,514}},["roller-coaster"]={16898733317,{256,256},{257,514}},["arrow-down-right-square"]={16898614020,{256,256},{257,0}},["shield-minus"]={16898734564,{256,256},{0,514}},thermometer={16898788660,{256,256},{0,257}},dessert={16898668755,{256,256},{257,514}},eclipse={16898669689,{256,256},{0,514}},church={16898617705,{256,256},{0,0}},combine={16898619182,{256,256},{0,514}},cylinder={16898668755,{256,256},{0,257}},["badge-japanese-yen"]={16898614945,{256,256},{514,257}},["calendar-plus-2"]={16898617053,{256,256},{514,0}},["receipt-text"]={16898732855,{256,256},{257,514}},film={16898670620,{256,256},{257,514}},["book-down"]={16898616080,{256,256},{257,257}},asterisk={16898614574,{256,256},{514,257}},cable={16898616879,{256,256},{514,514}},["file-output"]={16898670241,{256,256},{0,514}},["disc-album"]={16898669271,{256,256},{514,0}},["percent-square"]={16898731539,{256,256},{0,257}},["arrow-down-0-1"]={16898613869,{256,256},{0,0}},captions={16898617249,{256,256},{0,0}},diameter={16898668755,{256,256},{514,514}},bone={16898615799,{256,256},{257,514}},["umbrella-off"]={16898789303,{256,256},{257,257}},["badge-alert"]={16898614755,{256,256},{257,514}},flashlight={16898670919,{256,256},{257,257}},["folder-pen"]={16898671463,{256,256},{0,0}},cross={16898668482,{256,256},{0,514}},["badge-dollar-sign"]={16898614945,{256,256},{257,0}},["ice-cream-bowl"]={16898673358,{256,256},{0,514}},worm={16898791187,{256,256},{257,257}},["square-arrow-down-left"]={16898735593,{256,256},{0,257}},["share-2"]={16898734421,{256,256},{0,514}},["circle-arrow-out-down-right"]={16898617705,{256,256},{257,514}},["ear-off"]={16898669689,{256,256},{257,0}},wifi={16898790996,{256,256},{514,514}},["message-square-off"]={16898675863,{256,256},{257,514}},["tv-2"]={16898789153,{256,256},{514,514}},fish={16898670775,{256,256},{0,514}},sliders={16898735040,{256,256},{257,257}},["stretch-horizontal"]={16898736967,{256,256},{0,0}},currency={16898668755,{256,256},{257,0}},coffee={16898619015,{256,256},{257,514}},["message-circle-reply"]={16898675752,{256,256},{514,257}},route={16898733415,{256,256},{0,514}},["triangle-right"]={16898789153,{256,256},{514,0}},["folder-clock"]={16898671139,{256,256},{257,0}},["circle-off"]={16898617944,{256,256},{0,257}},["message-square-plus"]={16898675863,{256,256},{514,514}},type={16898789303,{256,256},{514,0}},webhook={16898790996,{256,256},{0,257}},["candlestick-chart"]={16898617146,{256,256},{514,0}},phone={16898731683,{256,256},{0,257}},["package-2"]={16898730417,{256,256},{0,514}},["chevrons-left"]={16898617626,{256,256},{514,0}},["pointer-off"]={16898732061,{256,256},{257,514}},turtle={16898789153,{256,256},{257,514}},camera={16898617146,{256,256},{0,257}},["thermometer-snowflake"]={16898788660,{256,256},{0,0}},clipboard={16898618392,{256,256},{0,514}},["send-horizontal"]={16898734242,{256,256},{0,257}},["bluetooth-searching"]={16898615799,{256,256},{0,257}},["arrow-up-to-line"]={16898614574,{256,256},{257,0}},["wrap-text"]={16898791187,{256,256},{0,514}},["file-check-2"]={16898670072,{256,256},{0,0}},["badge-percent"]={16898614945,{256,256},{514,514}},shuffle={16898734792,{256,256},{514,0}},refrigerator={16898733146,{256,256},{0,257}},["rows-3"]={16898733415,{256,256},{514,514}},sigma={16898734792,{256,256},{0,514}},["milk-off"]={16898728659,{256,256},{514,257}},["file-check"]={16898670072,{256,256},{257,0}},["pin-off"]={16898731819,{256,256},{0,514}},["clock-1"]={16898618392,{256,256},{514,257}},["file-heart"]={16898670171,{256,256},{257,0}},beaker={16898615240,{256,256},{514,514}},space={16898735175,{256,256},{0,514}},users={16898790259,{256,256},{514,0}},["shield-question"]={16898734564,{256,256},{514,514}},["arrow-up-circle"]={16898614275,{256,256},{257,514}},["corner-up-left"]={16898668288,{256,256},{257,514}},["clock-6"]={16898618583,{256,256},{0,514}},["layout-dashboard"]={16898674182,{256,256},{0,257}},["key-round"]={16898673616,{256,256},{514,257}},headphones={16898673115,{256,256},{514,0}},tv={16898789303,{256,256},{0,0}},["brain-circuit"]={16898616757,{256,256},{0,0}},["bar-chart-horizontal-big"]={16898615143,{256,256},{0,514}},rss={16898733534,{256,256},{0,257}},["file-stack"]={16898670469,{256,256},{0,0}},["at-sign"]={16898614574,{256,256},{257,514}},code={16898619015,{256,256},{257,257}},["calendar-minus"]={16898617053,{256,256},{257,0}},music={16898730065,{256,256},{0,0}},handshake={16898672829,{256,256},{514,257}},["graduation-cap"]={16898672599,{256,256},{257,514}},tornado={16898788789,{256,256},{514,514}},["copy-plus"]={16898619423,{256,256},{257,257}},stamp={16898736597,{256,256},{257,514}},cherry={16898617411,{256,256},{514,0}},shrink={16898734792,{256,256},{257,0}},["circle-arrow-out-up-right"]={16898617803,{256,256},{0,0}},meh={16898675673,{256,256},{514,0}},["search-check"]={16898734065,{256,256},{514,257}},crop={16898668482,{256,256},{257,257}},["columns-2"]={16898619182,{256,256},{257,0}},["mouse-pointer-square"]={16898729337,{256,256},{257,514}},["indent-decrease"]={16898673447,{256,256},{514,514}},["align-center-vertical"]={16898613044,{256,256},{257,257}},["wand-2"]={16898790791,{256,256},{257,0}},anvil={16898613699,{256,256},{0,0}},["align-start-vertical"]={16898613509,{256,256},{0,257}},["cloud-fog"]={16898618763,{256,256},{257,257}},accessibility={16898612629,{256,256},{514,0}},layers={16898674182,{256,256},{257,0}},["percent-diamond"]={16898731539,{256,256},{257,0}},["package-check"]={16898730417,{256,256},{514,257}},["chevron-first"]={16898617411,{256,256},{257,514}},pencil={16898731419,{256,256},{257,514}},["database-backup"]={16898668755,{256,256},{514,0}},["list-x"]={16898674684,{256,256},{0,0}},shapes={16898734421,{256,256},{257,257}},["move-down"]={16898729572,{256,256},{514,257}},["corner-up-right"]={16898668288,{256,256},{514,514}},computer={16898619347,{256,256},{0,0}},pin={16898731819,{256,256},{514,257}},["phone-off"]={16898731683,{256,256},{0,0}},["clipboard-x"]={16898618392,{256,256},{257,257}},fullscreen={16898672004,{256,256},{0,257}},["align-horizontal-distribute-start"]={16898613353,{256,256},{257,0}},["redo-dot"]={16898733036,{256,256},{0,514}},["cloud-moon"]={16898618763,{256,256},{514,514}},["stretch-vertical"]={16898736967,{256,256},{257,0}},["message-square-warning"]={16898728402,{256,256},{257,257}},["file-plus"]={16898670367,{256,256},{257,0}},["git-pull-request-arrow"]={16898672450,{256,256},{257,0}},guitar={16898672700,{256,256},{514,257}},tangent={16898788248,{256,256},{0,0}},["bell-dot"]={16898615374,{256,256},{514,514}},["panel-bottom"]={16898730821,{256,256},{0,514}},["flame-kindling"]={16898670919,{256,256},{257,0}},["table-2"]={16898787819,{256,256},{257,0}},["align-horizontal-space-around"]={16898613353,{256,256},{0,514}},server={16898734421,{256,256},{257,0}},["briefcase-business"]={16898616757,{256,256},{257,257}},diamond={16898669042,{256,256},{257,0}},blinds={16898615570,{256,256},{257,514}},weight={16898790996,{256,256},{514,0}},candy={16898617146,{256,256},{514,257}},["volume-1"]={16898790615,{256,256},{0,0}},["table-properties"]={16898787819,{256,256},{0,514}},["git-fork"]={16898672316,{256,256},{257,514}},recycle={16898733036,{256,256},{514,0}},["mountain-snow"]={16898729337,{256,256},{0,257}},luggage={16898674825,{256,256},{514,257}},["divide-square"]={16898669271,{256,256},{514,257}},["folder-minus"]={16898671263,{256,256},{0,514}},["phone-outgoing"]={16898731683,{256,256},{257,0}},["smartphone-charging"]={16898735040,{256,256},{0,514}},banknote={16898615143,{256,256},{0,0}},["train-track"]={16898789012,{256,256},{0,0}},["folder-up"]={16898671463,{256,256},{514,514}},["circle-percent"]={16898617944,{256,256},{514,257}},["bell-plus"]={16898615428,{256,256},{514,0}},fan={16898669897,{256,256},{514,0}},["disc-2"]={16898669271,{256,256},{257,0}},["git-pull-request-draft"]={16898672450,{256,256},{0,514}},coins={16898619182,{256,256},{0,0}},["square-divide"]={16898736072,{256,256},{0,0}},scroll={16898734065,{256,256},{0,514}},["circle-arrow-right"]={16898617803,{256,256},{257,0}},["candy-off"]={16898617146,{256,256},{0,514}},["square-pi"]={16898736237,{256,256},{514,257}},["arrow-left-right"]={16898614166,{256,256},{514,0}},["lightbulb-off"]={16898674337,{256,256},{257,514}},["panels-top-left"]={16898731166,{256,256},{0,514}},["move-up-right"]={16898729752,{256,256},{0,257}},["message-square-share"]={16898728402,{256,256},{0,257}},annoyed={16898613613,{256,256},{257,514}},["test-tube"]={16898788479,{256,256},{0,0}},["user-circle"]={16898789644,{256,256},{514,514}},["cooking-pot"]={16898619423,{256,256},{257,0}},["case-lower"]={16898617249,{256,256},{514,257}},["alarm-clock-minus"]={16898612819,{256,256},{257,0}},["square-user"]={16898736597,{256,256},{0,257}},square={16898736597,{256,256},{257,257}},["mail-open"]={16898675156,{256,256},{0,257}},["square-function"]={16898736072,{256,256},{514,0}},["arrow-up-left-from-circle"]={16898614410,{256,256},{0,257}},variable={16898790259,{256,256},{257,514}},["arrow-up-right-square"]={16898614410,{256,256},{257,514}},["badge-indian-rupee"]={16898614945,{256,256},{257,257}}}}

    end

    local Icons = if useStudio then require(script.Parent.icons) else loadWithTimeout()
    -- Variables

    local CFileName = nil
    local CEnabled = false
    local Minimised = false
    local Hidden = false
    local Debounce = false
    local searchOpen = false
    local Notifications = Rayfield.Notifications

    local SelectedTheme = RayfieldLibrary.Theme.Default

    local function ChangeTheme(Theme)
    	if typeof(Theme) == 'string' then
    		SelectedTheme = RayfieldLibrary.Theme[Theme]
    	elseif typeof(Theme) == 'table' then
    		SelectedTheme = Theme
    	end

    	Rayfield.Main.BackgroundColor3 = SelectedTheme.Background
    	Rayfield.Main.Topbar.BackgroundColor3 = SelectedTheme.Topbar
    	Rayfield.Main.Topbar.CornerRepair.BackgroundColor3 = SelectedTheme.Topbar
    	Rayfield.Main.Shadow.Image.ImageColor3 = SelectedTheme.Shadow

    	Rayfield.Main.Topbar.ChangeSize.ImageColor3 = SelectedTheme.TextColor
    	Rayfield.Main.Topbar.Hide.ImageColor3 = SelectedTheme.TextColor
    	Rayfield.Main.Topbar.Search.ImageColor3 = SelectedTheme.TextColor
    	if Topbar:FindFirstChild('Settings') then
    		Rayfield.Main.Topbar.Settings.ImageColor3 = SelectedTheme.TextColor
    		Rayfield.Main.Topbar.Divider.BackgroundColor3 = SelectedTheme.ElementStroke
    	end

    	Main.Search.BackgroundColor3 = SelectedTheme.TextColor
    	Main.Search.Shadow.ImageColor3 = SelectedTheme.TextColor
    	Main.Search.Search.ImageColor3 = SelectedTheme.TextColor
    	Main.Search.Input.PlaceholderColor3 = SelectedTheme.TextColor
    	Main.Search.UIStroke.Color = SelectedTheme.SecondaryElementStroke

    	if Main:FindFirstChild('Notice') then
    		Main.Notice.BackgroundColor3 = SelectedTheme.Background
    	end

    	for _, text in ipairs(Rayfield:GetDescendants()) do
    		if text.Parent.Parent ~= Notifications then
    			if text:IsA('TextLabel') or text:IsA('TextBox') then text.TextColor3 = SelectedTheme.TextColor end
    		end
    	end

    	for _, TabPage in ipairs(Elements:GetChildren()) do
    		for _, Element in ipairs(TabPage:GetChildren()) do
    			if Element.ClassName == "Frame" and Element.Name ~= "Placeholder" and Element.Name ~= "SectionSpacing" and Element.Name ~= "Divider" and Element.Name ~= "SectionTitle" and Element.Name ~= "SearchTitle-fsefsefesfsefesfesfThanks" then
    				Element.BackgroundColor3 = SelectedTheme.ElementBackground
    				Element.UIStroke.Color = SelectedTheme.ElementStroke
    			end
    		end
    	end
    end

    local function getIcon(name : string): {id: number, imageRectSize: Vector2, imageRectOffset: Vector2}
    	if not Icons then
    		warn("Lucide Icons: Cannot use icons as icons library is not loaded")
    		return
    	end
    	name = string.match(string.lower(name), "^%s*(.*)%s*$") :: string
    	local sizedicons = Icons['48px']
    	local r = sizedicons[name]
    	if not r then
    		error(`Lucide Icons: Failed to find icon by the name of "{name}"`, 2)
    	end

    	local rirs = r[2]
    	local riro = r[3]

    	if type(r[1]) ~= "number" or type(rirs) ~= "table" or type(riro) ~= "table" then
    		error("Lucide Icons: Internal error: Invalid auto-generated asset entry")
    	end

    	local irs = Vector2.new(rirs[1], rirs[2])
    	local iro = Vector2.new(riro[1], riro[2])

    	local asset = {
    		id = r[1],
    		imageRectSize = irs,
    		imageRectOffset = iro,
    	}

    	return asset
    end
    -- Converts ID to asset URI. Returns rbxassetid://0 if ID is not a number
    local function getAssetUri(id: any): string
    	local assetUri = "rbxassetid://0" -- Default to empty image
    	if type(id) == "number" then
    		assetUri = "rbxassetid://" .. id
    	elseif type(id) == "string" and not Icons then
    		warn("Rayfield | Cannot use Lucide icons as icons library is not loaded")
    	else
    		warn("Rayfield | The icon argument must either be an icon ID (number) or a Lucide icon name (string)")
    	end
    	return assetUri
    end

    local function makeDraggable(object, dragObject, enableTaptic, tapticOffset)
    	local dragging = false
    	local relative = nil

    	local offset = Vector2.zero
    	local screenGui = object:FindFirstAncestorWhichIsA("ScreenGui")
    	if screenGui and screenGui.IgnoreGuiInset then
    		offset += getService('GuiService'):GetGuiInset()
    	end

    	local function connectFunctions()
    		if dragBar and enableTaptic then
    			dragBar.MouseEnter:Connect(function()
    				if not dragging and not Hidden then
    					TweenService:Create(dragBarCosmetic, TweenInfo.new(0.25, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {BackgroundTransparency = 0.5, Size = UDim2.new(0, 120, 0, 4)}):Play()
    				end
    			end)

    			dragBar.MouseLeave:Connect(function()
    				if not dragging and not Hidden then
    					TweenService:Create(dragBarCosmetic, TweenInfo.new(0.25, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {BackgroundTransparency = 0.7, Size = UDim2.new(0, 100, 0, 4)}):Play()
    				end
    			end)
    		end
    	end

    	connectFunctions()

    	dragObject.InputBegan:Connect(function(input, processed)
    		if processed then return end

    		local inputType = input.UserInputType.Name
    		if inputType == "MouseButton1" or inputType == "Touch" then
    			dragging = true

    			relative = object.AbsolutePosition + object.AbsoluteSize * object.AnchorPoint - UserInputService:GetMouseLocation()
    			if enableTaptic and not Hidden then
    				TweenService:Create(dragBarCosmetic, TweenInfo.new(0.35, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {Size = UDim2.new(0, 110, 0, 4), BackgroundTransparency = 0}):Play()
    			end
    		end
    	end)

    	local inputEnded = UserInputService.InputEnded:Connect(function(input)
    		if not dragging then return end

    		local inputType = input.UserInputType.Name
    		if inputType == "MouseButton1" or inputType == "Touch" then
    			dragging = false

    			connectFunctions()

    			if enableTaptic and not Hidden then
    				TweenService:Create(dragBarCosmetic, TweenInfo.new(0.35, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {Size = UDim2.new(0, 100, 0, 4), BackgroundTransparency = 0.7}):Play()
    			end
    		end
    	end)

    	local renderStepped = RunService.RenderStepped:Connect(function()
    		if dragging and not Hidden then
    			local position = UserInputService:GetMouseLocation() + relative + offset
    			if enableTaptic and tapticOffset then
    				TweenService:Create(object, TweenInfo.new(0.4, Enum.EasingStyle.Exponential, Enum.EasingDirection.Out), {Position = UDim2.fromOffset(position.X, position.Y)}):Play()
    				TweenService:Create(dragObject.Parent, TweenInfo.new(0.05, Enum.EasingStyle.Exponential, Enum.EasingDirection.Out), {Position = UDim2.fromOffset(position.X, position.Y + ((useMobileSizing and tapticOffset[2]) or tapticOffset[1]))}):Play()
    			else
    				if dragBar and tapticOffset then
    					dragBar.Position = UDim2.fromOffset(position.X, position.Y + ((useMobileSizing and tapticOffset[2]) or tapticOffset[1]))
    				end
    				object.Position = UDim2.fromOffset(position.X, position.Y)
    			end
    		end
    	end)

    	object.Destroying:Connect(function()
    		if inputEnded then inputEnded:Disconnect() end
    		if renderStepped then renderStepped:Disconnect() end
    	end)
    end


    local function PackColor(Color)
    	return {R = Color.R * 255, G = Color.G * 255, B = Color.B * 255}
    end    

    local function UnpackColor(Color)
    	return Color3.fromRGB(Color.R, Color.G, Color.B)
    end

    local function LoadConfiguration(Configuration)
    	local success, Data = pcall(function() return HttpService:JSONDecode(Configuration) end)
    	local changed

    	if not success then warn('Rayfield had an issue decoding the configuration file, please try delete the file and reopen Rayfield.') return end

    	-- Iterate through current UI elements' flags
    	for FlagName, Flag in pairs(RayfieldLibrary.Flags) do
    		local FlagValue = Data[FlagName]

    		if (typeof(FlagValue) == 'boolean' and FlagValue == false) or FlagValue then
    			task.spawn(function()
    				if Flag.Type == "ColorPicker" then
    					changed = true
    					Flag:Set(UnpackColor(FlagValue))
    				else
    					if (Flag.CurrentValue or Flag.CurrentKeybind or Flag.CurrentOption or Flag.Color) ~= FlagValue then 
    						changed = true
    						Flag:Set(FlagValue) 	
    					end
    				end
    			end)
    		else
    			warn("Rayfield | Unable to find '"..FlagName.. "' in the save file.")
    			print("The error above may not be an issue if new elements have been added or not been set values.")
    			--RayfieldLibrary:Notify({Title = "Rayfield Flags", Content = "Rayfield was unable to find '"..FlagName.. "' in the save file. Check sirius.menu/discord for help.", Image = 3944688398})
    		end
    	end

    	return changed
    end

    local function SaveConfiguration()
    	if not CEnabled or not globalLoaded then return end

    	if debugX then
    		print('Saving')
    	end

    	local Data = {}
    	for i, v in pairs(RayfieldLibrary.Flags) do
    		if v.Type == "ColorPicker" then
    			Data[i] = PackColor(v.Color)
    		else
    			if typeof(v.CurrentValue) == 'boolean' then
    				if v.CurrentValue == false then
    					Data[i] = false
    				else
    					Data[i] = v.CurrentValue or v.CurrentKeybind or v.CurrentOption or v.Color
    				end
    			else
    				Data[i] = v.CurrentValue or v.CurrentKeybind or v.CurrentOption or v.Color
    			end
    		end
    	end

    	if useStudio then
    		if script.Parent:FindFirstChild('configuration') then script.Parent.configuration:Destroy() end

    		local ScreenGui = Instance.new("ScreenGui")
    		ScreenGui.Parent = script.Parent
    		ScreenGui.Name = 'configuration'

    		local TextBox = Instance.new("TextBox")
    		TextBox.Parent = ScreenGui
    		TextBox.Size = UDim2.new(0, 800, 0, 50)
    		TextBox.AnchorPoint = Vector2.new(0.5, 0)
    		TextBox.Position = UDim2.new(0.5, 0, 0, 30)
    		TextBox.Text = HttpService:JSONEncode(Data)
    		TextBox.ClearTextOnFocus = false
    	end

    	if debugX then
    		warn(HttpService:JSONEncode(Data))
    	end

    	if writefile then
    		writefile(ConfigurationFolder .. "/" .. CFileName .. ConfigurationExtension, tostring(HttpService:JSONEncode(Data)))
    	end
    end

    function RayfieldLibrary:Notify(data) -- action e.g open messages
    	task.spawn(function()

    		-- Notification Object Creation
    		local newNotification = Notifications.Template:Clone()
    		newNotification.Name = data.Title or 'No Title Provided'
    		newNotification.Parent = Notifications
    		newNotification.LayoutOrder = #Notifications:GetChildren()
    		newNotification.Visible = false

    		-- Set Data
    		newNotification.Title.Text = data.Title or "Unknown Title"
    		newNotification.Description.Text = data.Content or "Unknown Content"

    		if data.Image then
    			if typeof(data.Image) == 'string' and Icons then
    				local asset = getIcon(data.Image)

    				newNotification.Icon.Image = 'rbxassetid://'..asset.id
    				newNotification.Icon.ImageRectOffset = asset.imageRectOffset
    				newNotification.Icon.ImageRectSize = asset.imageRectSize
    			else
    				newNotification.Icon.Image = getAssetUri(data.Image)
    			end
    		else
    			newNotification.Icon.Image = "rbxassetid://" .. 0
    		end

    		-- Set initial transparency values

    		newNotification.Title.TextColor3 = SelectedTheme.TextColor
    		newNotification.Description.TextColor3 = SelectedTheme.TextColor
    		newNotification.BackgroundColor3 = SelectedTheme.Background
    		newNotification.UIStroke.Color = SelectedTheme.TextColor
    		newNotification.Icon.ImageColor3 = SelectedTheme.TextColor

    		newNotification.BackgroundTransparency = 1
    		newNotification.Title.TextTransparency = 1
    		newNotification.Description.TextTransparency = 1
    		newNotification.UIStroke.Transparency = 1
    		newNotification.Shadow.ImageTransparency = 1
    		newNotification.Size = UDim2.new(1, 0, 0, 800)
    		newNotification.Icon.ImageTransparency = 1
    		newNotification.Icon.BackgroundTransparency = 1

    		task.wait()

    		newNotification.Visible = true

    		if data.Actions then
    			warn('Rayfield | Not seeing your actions in notifications?')
    			print("Notification Actions are being sunset for now, keep up to date on when they're back in the discord. (sirius.menu/discord)")
    		end

    		-- Calculate textbounds and set initial values
    		local bounds = {newNotification.Title.TextBounds.Y, newNotification.Description.TextBounds.Y}
    		newNotification.Size = UDim2.new(1, -60, 0, -Notifications:FindFirstChild("UIListLayout").Padding.Offset)

    		newNotification.Icon.Size = UDim2.new(0, 32, 0, 32)
    		newNotification.Icon.Position = UDim2.new(0, 20, 0.5, 0)

    		TweenService:Create(newNotification, TweenInfo.new(0.6, Enum.EasingStyle.Exponential), {Size = UDim2.new(1, 0, 0, math.max(bounds[1] + bounds[2] + 31, 60))}):Play()

    		task.wait(0.15)
    		TweenService:Create(newNotification, TweenInfo.new(0.4, Enum.EasingStyle.Exponential), {BackgroundTransparency = 0.45}):Play()
    		TweenService:Create(newNotification.Title, TweenInfo.new(0.3, Enum.EasingStyle.Exponential), {TextTransparency = 0}):Play()

    		task.wait(0.05)

    		TweenService:Create(newNotification.Icon, TweenInfo.new(0.3, Enum.EasingStyle.Exponential), {ImageTransparency = 0}):Play()

    		task.wait(0.05)
    		TweenService:Create(newNotification.Description, TweenInfo.new(0.3, Enum.EasingStyle.Exponential), {TextTransparency = 0.35}):Play()
    		TweenService:Create(newNotification.UIStroke, TweenInfo.new(0.4, Enum.EasingStyle.Exponential), {Transparency = 0.95}):Play()
    		TweenService:Create(newNotification.Shadow, TweenInfo.new(0.3, Enum.EasingStyle.Exponential), {ImageTransparency = 0.82}):Play()

    		local waitDuration = math.min(math.max((#newNotification.Description.Text * 0.1) + 2.5, 3), 10)
    		task.wait(data.Duration or waitDuration)

    		newNotification.Icon.Visible = false
    		TweenService:Create(newNotification, TweenInfo.new(0.4, Enum.EasingStyle.Exponential), {BackgroundTransparency = 1}):Play()
    		TweenService:Create(newNotification.UIStroke, TweenInfo.new(0.4, Enum.EasingStyle.Exponential), {Transparency = 1}):Play()
    		TweenService:Create(newNotification.Shadow, TweenInfo.new(0.3, Enum.EasingStyle.Exponential), {ImageTransparency = 1}):Play()
    		TweenService:Create(newNotification.Title, TweenInfo.new(0.3, Enum.EasingStyle.Exponential), {TextTransparency = 1}):Play()
    		TweenService:Create(newNotification.Description, TweenInfo.new(0.3, Enum.EasingStyle.Exponential), {TextTransparency = 1}):Play()

    		TweenService:Create(newNotification, TweenInfo.new(1, Enum.EasingStyle.Exponential), {Size = UDim2.new(1, -90, 0, 0)}):Play()

    		task.wait(1)

    		TweenService:Create(newNotification, TweenInfo.new(1, Enum.EasingStyle.Exponential), {Size = UDim2.new(1, -90, 0, -Notifications:FindFirstChild("UIListLayout").Padding.Offset)}):Play()

    		newNotification.Visible = false
    		newNotification:Destroy()
    	end)
    end

    local function openSearch()
    	searchOpen = true

    	Main.Search.BackgroundTransparency = 1
    	Main.Search.Shadow.ImageTransparency = 1
    	Main.Search.Input.TextTransparency = 1
    	Main.Search.Search.ImageTransparency = 1
    	Main.Search.UIStroke.Transparency = 1
    	Main.Search.Size = UDim2.new(1, 0, 0, 80)
    	Main.Search.Position = UDim2.new(0.5, 0, 0, 70)

    	Main.Search.Input.Interactable = true

    	Main.Search.Visible = true

    	for _, tabbtn in ipairs(TabList:GetChildren()) do
    		if tabbtn.ClassName == "Frame" and tabbtn.Name ~= "Placeholder" then
    			tabbtn.Interact.Visible = false
    			TweenService:Create(tabbtn, TweenInfo.new(0.3, Enum.EasingStyle.Exponential), {BackgroundTransparency = 1}):Play()
    			TweenService:Create(tabbtn.Title, TweenInfo.new(0.3, Enum.EasingStyle.Exponential), {TextTransparency = 1}):Play()
    			TweenService:Create(tabbtn.Image, TweenInfo.new(0.3, Enum.EasingStyle.Exponential), {ImageTransparency = 1}):Play()
    			TweenService:Create(tabbtn.UIStroke, TweenInfo.new(0.3, Enum.EasingStyle.Exponential), {Transparency = 1}):Play()
    		end
    	end

    	Main.Search.Input:CaptureFocus()
    	TweenService:Create(Main.Search.Shadow, TweenInfo.new(0.05, Enum.EasingStyle.Quint), {ImageTransparency = 0.95}):Play()
    	TweenService:Create(Main.Search, TweenInfo.new(0.3, Enum.EasingStyle.Exponential), {Position = UDim2.new(0.5, 0, 0, 57), BackgroundTransparency = 0.9}):Play()
    	TweenService:Create(Main.Search.UIStroke, TweenInfo.new(0.3, Enum.EasingStyle.Exponential), {Transparency = 0.8}):Play()
    	TweenService:Create(Main.Search.Input, TweenInfo.new(0.3, Enum.EasingStyle.Exponential), {TextTransparency = 0.2}):Play()
    	TweenService:Create(Main.Search.Search, TweenInfo.new(0.3, Enum.EasingStyle.Exponential), {ImageTransparency = 0.5}):Play()
    	TweenService:Create(Main.Search, TweenInfo.new(0.5, Enum.EasingStyle.Exponential), {Size = UDim2.new(1, -35, 0, 35)}):Play()
    end

    local function closeSearch()
    	searchOpen = false

    	TweenService:Create(Main.Search, TweenInfo.new(0.35, Enum.EasingStyle.Quint), {BackgroundTransparency = 1, Size = UDim2.new(1, -55, 0, 30)}):Play()
    	TweenService:Create(Main.Search.Search, TweenInfo.new(0.15, Enum.EasingStyle.Quint), {ImageTransparency = 1}):Play()
    	TweenService:Create(Main.Search.Shadow, TweenInfo.new(0.15, Enum.EasingStyle.Quint), {ImageTransparency = 1}):Play()
    	TweenService:Create(Main.Search.UIStroke, TweenInfo.new(0.15, Enum.EasingStyle.Quint), {Transparency = 1}):Play()
    	TweenService:Create(Main.Search.Input, TweenInfo.new(0.15, Enum.EasingStyle.Quint), {TextTransparency = 1}):Play()

    	for _, tabbtn in ipairs(TabList:GetChildren()) do
    		if tabbtn.ClassName == "Frame" and tabbtn.Name ~= "Placeholder" then
    			tabbtn.Interact.Visible = true
    			if tostring(Elements.UIPageLayout.CurrentPage) == tabbtn.Title.Text then
    				TweenService:Create(tabbtn, TweenInfo.new(0.3, Enum.EasingStyle.Exponential), {BackgroundTransparency = 0}):Play()
    				TweenService:Create(tabbtn.Image, TweenInfo.new(0.3, Enum.EasingStyle.Exponential), {ImageTransparency = 0}):Play()
    				TweenService:Create(tabbtn.Title, TweenInfo.new(0.3, Enum.EasingStyle.Exponential), {TextTransparency = 0}):Play()
    				TweenService:Create(tabbtn.UIStroke, TweenInfo.new(0.3, Enum.EasingStyle.Exponential), {Transparency = 1}):Play()
    			else
    				TweenService:Create(tabbtn, TweenInfo.new(0.3, Enum.EasingStyle.Exponential), {BackgroundTransparency = 0.7}):Play()
    				TweenService:Create(tabbtn.Image, TweenInfo.new(0.3, Enum.EasingStyle.Exponential), {ImageTransparency = 0.2}):Play()
    				TweenService:Create(tabbtn.Title, TweenInfo.new(0.3, Enum.EasingStyle.Exponential), {TextTransparency = 0.2}):Play()
    				TweenService:Create(tabbtn.UIStroke, TweenInfo.new(0.3, Enum.EasingStyle.Exponential), {Transparency = 0.5}):Play()
    			end
    		end
    	end

    	Main.Search.Input.Text = ''
    	Main.Search.Input.Interactable = false
    end

    local function Hide(notify: boolean?)
    	if MPrompt then
    		MPrompt.Title.TextColor3 = Color3.fromRGB(255, 255, 255)
    		MPrompt.Position = UDim2.new(0.5, 0, 0, -50)
    		MPrompt.Size = UDim2.new(0, 40, 0, 10)
    		MPrompt.BackgroundTransparency = 1
    		MPrompt.Title.TextTransparency = 1
    		MPrompt.Visible = true
    	end

    	task.spawn(closeSearch)

    	Debounce = true
    	if notify then
    		if useMobilePrompt then 
    			RayfieldLibrary:Notify({Title = "Interface Hidden", Content = "The interface has been hidden, you can unhide the interface by tapping 'Show Rayfield'.", Duration = 7, Image = 4400697855})
    		else
    			RayfieldLibrary:Notify({Title = "Interface Hidden", Content = `The interface has been hidden, you can unhide the interface by tapping {getSetting("General", "rayfieldOpen")}.`, Duration = 7, Image = 4400697855})
    		end
    	end

    	TweenService:Create(Main, TweenInfo.new(0.5, Enum.EasingStyle.Exponential), {Size = UDim2.new(0, 470, 0, 0)}):Play()
    	TweenService:Create(Main.Topbar, TweenInfo.new(0.5, Enum.EasingStyle.Exponential), {Size = UDim2.new(0, 470, 0, 45)}):Play()
    	TweenService:Create(Main, TweenInfo.new(0.5, Enum.EasingStyle.Exponential), {BackgroundTransparency = 1}):Play()
    	TweenService:Create(Main.Topbar, TweenInfo.new(0.5, Enum.EasingStyle.Exponential), {BackgroundTransparency = 1}):Play()
    	TweenService:Create(Main.Topbar.Divider, TweenInfo.new(0.5, Enum.EasingStyle.Exponential), {BackgroundTransparency = 1}):Play()
    	TweenService:Create(Main.Topbar.CornerRepair, TweenInfo.new(0.3, Enum.EasingStyle.Exponential), {BackgroundTransparency = 1}):Play()
    	TweenService:Create(Main.Topbar.Title, TweenInfo.new(0.5, Enum.EasingStyle.Exponential), {TextTransparency = 1}):Play()
    	TweenService:Create(Main.Shadow.Image, TweenInfo.new(0.5, Enum.EasingStyle.Exponential), {ImageTransparency = 1}):Play()
    	TweenService:Create(Topbar.UIStroke, TweenInfo.new(0.5, Enum.EasingStyle.Exponential), {Transparency = 1}):Play()
    	TweenService:Create(dragBarCosmetic, TweenInfo.new(0.25, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {BackgroundTransparency = 1}):Play()

    	if useMobilePrompt and MPrompt then
    		TweenService:Create(MPrompt, TweenInfo.new(0.5, Enum.EasingStyle.Exponential), {Size = UDim2.new(0, 120, 0, 30), Position = UDim2.new(0.5, 0, 0, 20), BackgroundTransparency = 0.3}):Play()
    		TweenService:Create(MPrompt.Title, TweenInfo.new(0.5, Enum.EasingStyle.Exponential), {TextTransparency = 0.3}):Play()
    	end

    	for _, TopbarButton in ipairs(Topbar:GetChildren()) do
    		if TopbarButton.ClassName == "ImageButton" then
    			TweenService:Create(TopbarButton, TweenInfo.new(0.5, Enum.EasingStyle.Exponential), {ImageTransparency = 1}):Play()
    		end
    	end

    	for _, tabbtn in ipairs(TabList:GetChildren()) do
    		if tabbtn.ClassName == "Frame" and tabbtn.Name ~= "Placeholder" then
    			TweenService:Create(tabbtn, TweenInfo.new(0.3, Enum.EasingStyle.Exponential), {BackgroundTransparency = 1}):Play()
    			TweenService:Create(tabbtn.Title, TweenInfo.new(0.3, Enum.EasingStyle.Exponential), {TextTransparency = 1}):Play()
    			TweenService:Create(tabbtn.Image, TweenInfo.new(0.3, Enum.EasingStyle.Exponential), {ImageTransparency = 1}):Play()
    			TweenService:Create(tabbtn.UIStroke, TweenInfo.new(0.3, Enum.EasingStyle.Exponential), {Transparency = 1}):Play()
    		end
    	end

    	dragInteract.Visible = false

    	for _, tab in ipairs(Elements:GetChildren()) do
    		if tab.Name ~= "Template" and tab.ClassName == "ScrollingFrame" and tab.Name ~= "Placeholder" then
    			for _, element in ipairs(tab:GetChildren()) do
    				if element.ClassName == "Frame" then
    					if element.Name ~= "SectionSpacing" and element.Name ~= "Placeholder" then
    						if element.Name == "SectionTitle" or element.Name == 'SearchTitle-fsefsefesfsefesfesfThanks' then
    							TweenService:Create(element.Title, TweenInfo.new(0.3, Enum.EasingStyle.Exponential), {TextTransparency = 1}):Play()
    						elseif element.Name == 'Divider' then
    							TweenService:Create(element.Divider, TweenInfo.new(0.3, Enum.EasingStyle.Exponential), {BackgroundTransparency = 1}):Play()
    						else
    							TweenService:Create(element, TweenInfo.new(0.3, Enum.EasingStyle.Exponential), {BackgroundTransparency = 1}):Play()
    							TweenService:Create(element.UIStroke, TweenInfo.new(0.3, Enum.EasingStyle.Exponential), {Transparency = 1}):Play()
    							TweenService:Create(element.Title, TweenInfo.new(0.3, Enum.EasingStyle.Exponential), {TextTransparency = 1}):Play()
    						end
    						for _, child in ipairs(element:GetChildren()) do
    							if child.ClassName == "Frame" or child.ClassName == "TextLabel" or child.ClassName == "TextBox" or child.ClassName == "ImageButton" or child.ClassName == "ImageLabel" then
    								child.Visible = false
    							end
    						end
    					end
    				end
    			end
    		end
    	end

    	task.wait(0.5)
    	Main.Visible = false
    	Debounce = false
    end

    local function Maximise()
    	Debounce = true
    	Topbar.ChangeSize.Image = "rbxassetid://"..10137941941

    	TweenService:Create(Topbar.UIStroke, TweenInfo.new(0.5, Enum.EasingStyle.Exponential), {Transparency = 1}):Play()
    	TweenService:Create(Main.Shadow.Image, TweenInfo.new(0.5, Enum.EasingStyle.Exponential), {ImageTransparency = 0.6}):Play()
    	TweenService:Create(Topbar.CornerRepair, TweenInfo.new(0.5, Enum.EasingStyle.Exponential), {BackgroundTransparency = 0}):Play()
    	TweenService:Create(Topbar.Divider, TweenInfo.new(0.5, Enum.EasingStyle.Exponential), {BackgroundTransparency = 0}):Play()
    	TweenService:Create(dragBarCosmetic, TweenInfo.new(0.25, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {BackgroundTransparency = 0.7}):Play()
    	TweenService:Create(Main, TweenInfo.new(0.5, Enum.EasingStyle.Exponential), {Size = useMobileSizing and UDim2.new(0, 500, 0, 275) or UDim2.new(0, 500, 0, 475)}):Play()
    	TweenService:Create(Topbar, TweenInfo.new(0.5, Enum.EasingStyle.Exponential), {Size = UDim2.new(0, 500, 0, 45)}):Play()
    	TabList.Visible = true
    	task.wait(0.2)

    	Elements.Visible = true

    	for _, tab in ipairs(Elements:GetChildren()) do
    		if tab.Name ~= "Template" and tab.ClassName == "ScrollingFrame" and tab.Name ~= "Placeholder" then
    			for _, element in ipairs(tab:GetChildren()) do
    				if element.ClassName == "Frame" then
    					if element.Name ~= "SectionSpacing" and element.Name ~= "Placeholder" then
    						if element.Name == "SectionTitle" or element.Name == 'SearchTitle-fsefsefesfsefesfesfThanks' then
    							TweenService:Create(element.Title, TweenInfo.new(0.3, Enum.EasingStyle.Exponential), {TextTransparency = 0.4}):Play()
    						elseif element.Name == 'Divider' then
    							TweenService:Create(element.Divider, TweenInfo.new(0.3, Enum.EasingStyle.Exponential), {BackgroundTransparency = 0.85}):Play()
    						else
    							TweenService:Create(element, TweenInfo.new(0.3, Enum.EasingStyle.Exponential), {BackgroundTransparency = 0}):Play()
    							TweenService:Create(element.UIStroke, TweenInfo.new(0.3, Enum.EasingStyle.Exponential), {Transparency = 0}):Play()
    							TweenService:Create(element.Title, TweenInfo.new(0.3, Enum.EasingStyle.Exponential), {TextTransparency = 0}):Play()
    						end
    						for _, child in ipairs(element:GetChildren()) do
    							if child.ClassName == "Frame" or child.ClassName == "TextLabel" or child.ClassName == "TextBox" or child.ClassName == "ImageButton" or child.ClassName == "ImageLabel" then
    								child.Visible = true
    							end
    						end
    					end
    				end
    			end
    		end
    	end

    	task.wait(0.1)

    	for _, tabbtn in ipairs(TabList:GetChildren()) do
    		if tabbtn.ClassName == "Frame" and tabbtn.Name ~= "Placeholder" then
    			if tostring(Elements.UIPageLayout.CurrentPage) == tabbtn.Title.Text then
    				TweenService:Create(tabbtn, TweenInfo.new(0.3, Enum.EasingStyle.Exponential), {BackgroundTransparency = 0}):Play()
    				TweenService:Create(tabbtn.Image, TweenInfo.new(0.3, Enum.EasingStyle.Exponential), {ImageTransparency = 0}):Play()
    				TweenService:Create(tabbtn.Title, TweenInfo.new(0.3, Enum.EasingStyle.Exponential), {TextTransparency = 0}):Play()
    				TweenService:Create(tabbtn.UIStroke, TweenInfo.new(0.3, Enum.EasingStyle.Exponential), {Transparency = 1}):Play()
    			else
    				TweenService:Create(tabbtn, TweenInfo.new(0.3, Enum.EasingStyle.Exponential), {BackgroundTransparency = 0.7}):Play()
    				TweenService:Create(tabbtn.Image, TweenInfo.new(0.3, Enum.EasingStyle.Exponential), {ImageTransparency = 0.2}):Play()
    				TweenService:Create(tabbtn.Title, TweenInfo.new(0.3, Enum.EasingStyle.Exponential), {TextTransparency = 0.2}):Play()
    				TweenService:Create(tabbtn.UIStroke, TweenInfo.new(0.3, Enum.EasingStyle.Exponential), {Transparency = 0.5}):Play()
    			end

    		end
    	end

    	task.wait(0.5)
    	Debounce = false
    end


    local function Unhide()
    	Debounce = true
    	Main.Position = UDim2.new(0.5, 0, 0.5, 0)
    	Main.Visible = true
    	TweenService:Create(Main, TweenInfo.new(0.5, Enum.EasingStyle.Exponential), {Size = useMobileSizing and UDim2.new(0, 500, 0, 275) or UDim2.new(0, 500, 0, 475)}):Play()
    	TweenService:Create(Main.Topbar, TweenInfo.new(0.5, Enum.EasingStyle.Exponential), {Size = UDim2.new(0, 500, 0, 45)}):Play()
    	TweenService:Create(Main.Shadow.Image, TweenInfo.new(0.7, Enum.EasingStyle.Exponential), {ImageTransparency = 0.6}):Play()
    	TweenService:Create(Main, TweenInfo.new(0.5, Enum.EasingStyle.Exponential), {BackgroundTransparency = 0}):Play()
    	TweenService:Create(Main.Topbar, TweenInfo.new(0.5, Enum.EasingStyle.Exponential), {BackgroundTransparency = 0}):Play()
    	TweenService:Create(Main.Topbar.Divider, TweenInfo.new(0.5, Enum.EasingStyle.Exponential), {BackgroundTransparency = 0}):Play()
    	TweenService:Create(Main.Topbar.CornerRepair, TweenInfo.new(0.5, Enum.EasingStyle.Exponential), {BackgroundTransparency = 0}):Play()
    	TweenService:Create(Main.Topbar.Title, TweenInfo.new(0.5, Enum.EasingStyle.Exponential), {TextTransparency = 0}):Play()

    	if MPrompt then
    		TweenService:Create(MPrompt, TweenInfo.new(0.5, Enum.EasingStyle.Exponential), {Size = UDim2.new(0, 40, 0, 10), Position = UDim2.new(0.5, 0, 0, -50), BackgroundTransparency = 1}):Play()
    		TweenService:Create(MPrompt.Title, TweenInfo.new(0.5, Enum.EasingStyle.Exponential), {TextTransparency = 1}):Play()

    		task.spawn(function()
    			task.wait(0.5)
    			MPrompt.Visible = false
    		end)
    	end

    	if Minimised then
    		task.spawn(Maximise)
    	end

    	dragBar.Position = useMobileSizing and UDim2.new(0.5, 0, 0.5, dragOffsetMobile) or UDim2.new(0.5, 0, 0.5, dragOffset)

    	dragInteract.Visible = true

    	for _, TopbarButton in ipairs(Topbar:GetChildren()) do
    		if TopbarButton.ClassName == "ImageButton" then
    			if TopbarButton.Name == 'Icon' then
    				TweenService:Create(TopbarButton, TweenInfo.new(0.7, Enum.EasingStyle.Exponential), {ImageTransparency = 0}):Play()
    			else
    				TweenService:Create(TopbarButton, TweenInfo.new(0.7, Enum.EasingStyle.Exponential), {ImageTransparency = 0.8}):Play()
    			end

    		end
    	end

    	for _, tabbtn in ipairs(TabList:GetChildren()) do
    		if tabbtn.ClassName == "Frame" and tabbtn.Name ~= "Placeholder" then
    			if tostring(Elements.UIPageLayout.CurrentPage) == tabbtn.Title.Text then
    				TweenService:Create(tabbtn, TweenInfo.new(0.3, Enum.EasingStyle.Exponential), {BackgroundTransparency = 0}):Play()
    				TweenService:Create(tabbtn.Title, TweenInfo.new(0.3, Enum.EasingStyle.Exponential), {TextTransparency = 0}):Play()
    				TweenService:Create(tabbtn.Image, TweenInfo.new(0.3, Enum.EasingStyle.Exponential), {ImageTransparency = 0}):Play()
    				TweenService:Create(tabbtn.UIStroke, TweenInfo.new(0.3, Enum.EasingStyle.Exponential), {Transparency = 1}):Play()
    			else
    				TweenService:Create(tabbtn, TweenInfo.new(0.3, Enum.EasingStyle.Exponential), {BackgroundTransparency = 0.7}):Play()
    				TweenService:Create(tabbtn.Image, TweenInfo.new(0.3, Enum.EasingStyle.Exponential), {ImageTransparency = 0.2}):Play()
    				TweenService:Create(tabbtn.Title, TweenInfo.new(0.3, Enum.EasingStyle.Exponential), {TextTransparency = 0.2}):Play()
    				TweenService:Create(tabbtn.UIStroke, TweenInfo.new(0.3, Enum.EasingStyle.Exponential), {Transparency = 0.5}):Play()
    			end
    		end
    	end

    	for _, tab in ipairs(Elements:GetChildren()) do
    		if tab.Name ~= "Template" and tab.ClassName == "ScrollingFrame" and tab.Name ~= "Placeholder" then
    			for _, element in ipairs(tab:GetChildren()) do
    				if element.ClassName == "Frame" then
    					if element.Name ~= "SectionSpacing" and element.Name ~= "Placeholder" then
    						if element.Name == "SectionTitle" or element.Name == 'SearchTitle-fsefsefesfsefesfesfThanks' then
    							TweenService:Create(element.Title, TweenInfo.new(0.3, Enum.EasingStyle.Exponential), {TextTransparency = 0.4}):Play()
    						elseif element.Name == 'Divider' then
    							TweenService:Create(element.Divider, TweenInfo.new(0.3, Enum.EasingStyle.Exponential), {BackgroundTransparency = 0.85}):Play()
    						else
    							TweenService:Create(element, TweenInfo.new(0.3, Enum.EasingStyle.Exponential), {BackgroundTransparency = 0}):Play()
    							TweenService:Create(element.UIStroke, TweenInfo.new(0.3, Enum.EasingStyle.Exponential), {Transparency = 0}):Play()
    							TweenService:Create(element.Title, TweenInfo.new(0.3, Enum.EasingStyle.Exponential), {TextTransparency = 0}):Play()
    						end
    						for _, child in ipairs(element:GetChildren()) do
    							if child.ClassName == "Frame" or child.ClassName == "TextLabel" or child.ClassName == "TextBox" or child.ClassName == "ImageButton" or child.ClassName == "ImageLabel" then
    								child.Visible = true
    							end
    						end
    					end
    				end
    			end
    		end
    	end

    	TweenService:Create(dragBarCosmetic, TweenInfo.new(0.25, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {BackgroundTransparency = 0.5}):Play()

    	task.wait(0.5)
    	Minimised = false
    	Debounce = false
    end

    local function Minimise()
    	Debounce = true
    	Topbar.ChangeSize.Image = "rbxassetid://"..11036884234

    	Topbar.UIStroke.Color = SelectedTheme.ElementStroke

    	task.spawn(closeSearch)

    	for _, tabbtn in ipairs(TabList:GetChildren()) do
    		if tabbtn.ClassName == "Frame" and tabbtn.Name ~= "Placeholder" then
    			TweenService:Create(tabbtn, TweenInfo.new(0.3, Enum.EasingStyle.Exponential), {BackgroundTransparency = 1}):Play()
    			TweenService:Create(tabbtn.Image, TweenInfo.new(0.3, Enum.EasingStyle.Exponential), {ImageTransparency = 1}):Play()
    			TweenService:Create(tabbtn.Title, TweenInfo.new(0.3, Enum.EasingStyle.Exponential), {TextTransparency = 1}):Play()
    			TweenService:Create(tabbtn.UIStroke, TweenInfo.new(0.3, Enum.EasingStyle.Exponential), {Transparency = 1}):Play()
    		end
    	end

    	for _, tab in ipairs(Elements:GetChildren()) do
    		if tab.Name ~= "Template" and tab.ClassName == "ScrollingFrame" and tab.Name ~= "Placeholder" then
    			for _, element in ipairs(tab:GetChildren()) do
    				if element.ClassName == "Frame" then
    					if element.Name ~= "SectionSpacing" and element.Name ~= "Placeholder" then
    						if element.Name == "SectionTitle" or element.Name == 'SearchTitle-fsefsefesfsefesfesfThanks' then
    							TweenService:Create(element.Title, TweenInfo.new(0.3, Enum.EasingStyle.Exponential), {TextTransparency = 1}):Play()
    						elseif element.Name == 'Divider' then
    							TweenService:Create(element.Divider, TweenInfo.new(0.3, Enum.EasingStyle.Exponential), {BackgroundTransparency = 1}):Play()
    						else
    							TweenService:Create(element, TweenInfo.new(0.3, Enum.EasingStyle.Exponential), {BackgroundTransparency = 1}):Play()
    							TweenService:Create(element.UIStroke, TweenInfo.new(0.3, Enum.EasingStyle.Exponential), {Transparency = 1}):Play()
    							TweenService:Create(element.Title, TweenInfo.new(0.3, Enum.EasingStyle.Exponential), {TextTransparency = 1}):Play()
    						end
    						for _, child in ipairs(element:GetChildren()) do
    							if child.ClassName == "Frame" or child.ClassName == "TextLabel" or child.ClassName == "TextBox" or child.ClassName == "ImageButton" or child.ClassName == "ImageLabel" then
    								child.Visible = false
    							end
    						end
    					end
    				end
    			end
    		end
    	end

    	TweenService:Create(dragBarCosmetic, TweenInfo.new(0.25, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {BackgroundTransparency = 1}):Play()
    	TweenService:Create(Topbar.UIStroke, TweenInfo.new(0.5, Enum.EasingStyle.Exponential), {Transparency = 0}):Play()
    	TweenService:Create(Main.Shadow.Image, TweenInfo.new(0.5, Enum.EasingStyle.Exponential), {ImageTransparency = 1}):Play()
    	TweenService:Create(Topbar.CornerRepair, TweenInfo.new(0.5, Enum.EasingStyle.Exponential), {BackgroundTransparency = 1}):Play()
    	TweenService:Create(Topbar.Divider, TweenInfo.new(0.5, Enum.EasingStyle.Exponential), {BackgroundTransparency = 1}):Play()
    	TweenService:Create(Main, TweenInfo.new(0.5, Enum.EasingStyle.Exponential), {Size = UDim2.new(0, 495, 0, 45)}):Play()
    	TweenService:Create(Topbar, TweenInfo.new(0.5, Enum.EasingStyle.Exponential), {Size = UDim2.new(0, 495, 0, 45)}):Play()

    	task.wait(0.3)

    	Elements.Visible = false
    	TabList.Visible = false

    	task.wait(0.2)
    	Debounce = false
    end

    local function saveSettings() -- Save settings to config file
    	local encoded
    	local success, err = pcall(function()
    		encoded = HttpService:JSONEncode(settingsTable)
    	end)

    	if success then
    		if useStudio then
    			if script.Parent['get.val'] then
    				script.Parent['get.val'].Value = encoded
    			end
    		end
    		if writefile then
    			writefile(RayfieldFolder..'/settings'..ConfigurationExtension, encoded)
    		end
    	end
    end

    local function updateSetting(category: string, setting: string, value: any)
    	if not settingsInitialized then
    		return
    	end
    	settingsTable[category][setting].Value = value
    	overriddenSettings[`{category}.{setting}`] = nil -- If user changes an overriden setting, remove the override
    	saveSettings()
    end

    local function createSettings(window)
    	if not (writefile and isfile and readfile and isfolder and makefolder) and not useStudio then
    		if Topbar['Settings'] then Topbar.Settings.Visible = false end
    		Topbar['Search'].Position = UDim2.new(1, -75, 0.5, 0)
    		warn('Can\'t create settings as no file-saving functionality is available.')
    		return
    	end

    	local newTab = window:CreateTab('Rayfield Settings', 0, true)

    	if TabList['Rayfield Settings'] then
    		TabList['Rayfield Settings'].LayoutOrder = 1000
    	end

    	if Elements['Rayfield Settings'] then
    		Elements['Rayfield Settings'].LayoutOrder = 1000
    	end

    	-- Create sections and elements
    	for categoryName, settingCategory in pairs(settingsTable) do
    		newTab:CreateSection(categoryName)

    		for settingName, setting in pairs(settingCategory) do
    			if setting.Type == 'input' then
    				setting.Element = newTab:CreateInput({
    					Name = setting.Name,
    					CurrentValue = setting.Value,
    					PlaceholderText = setting.Placeholder,
    					Ext = true,
    					RemoveTextAfterFocusLost = setting.ClearOnFocus,
    					Callback = function(Value)
    						updateSetting(categoryName, settingName, Value)
    					end,
    				})
    			elseif setting.Type == 'toggle' then
    				setting.Element = newTab:CreateToggle({
    					Name = setting.Name,
    					CurrentValue = setting.Value,
    					Ext = true,
    					Callback = function(Value)
    						updateSetting(categoryName, settingName, Value)
    					end,
    				})
    			elseif setting.Type == 'bind' then
    				setting.Element = newTab:CreateKeybind({
    					Name = setting.Name,
    					CurrentKeybind = setting.Value,
    					HoldToInteract = false,
    					Ext = true,
    					CallOnChange = true,
    					Callback = function(Value)
    						updateSetting(categoryName, settingName, Value)
    					end,
    				})
    			end
    		end
    	end

    	settingsCreated = true
    	loadSettings()
    	saveSettings()
    end



    function RayfieldLibrary:CreateWindow(Settings)
    	if Rayfield:FindFirstChild('Loading') then
    		if getgenv and not getgenv().rayfieldCached then
    			Rayfield.Enabled = true
    			Rayfield.Loading.Visible = true

    			task.wait(1.4)
    			Rayfield.Loading.Visible = false
    		end
    	end

    	if getgenv then getgenv().rayfieldCached = true end

    	if not correctBuild and not Settings.DisableBuildWarnings then
    		task.delay(3, 
    			function() 
    				RayfieldLibrary:Notify({Title = 'Build Mismatch', Content = 'Rayfield may encounter issues as you are running an incompatible interface version ('.. ((Rayfield:FindFirstChild('Build') and Rayfield.Build.Value) or 'No Build') ..').\n\nThis version of Rayfield is intended for interface build '..InterfaceBuild..'.\n\nTry rejoining and then run the script twice.', Image = 4335487866, Duration = 15})		
    			end)
    	end

    	if Settings.ToggleUIKeybind then -- Can either be a string or an Enum.KeyCode
    		local keybind = Settings.ToggleUIKeybind
    		if type(keybind) == "string" then
    			keybind = string.upper(keybind)
    			assert(pcall(function()
    				return Enum.KeyCode[keybind]
    			end), "ToggleUIKeybind must be a valid KeyCode")
    			overrideSetting("General", "rayfieldOpen", keybind)
    		elseif typeof(keybind) == "EnumItem" then
    			assert(keybind.EnumType == Enum.KeyCode, "ToggleUIKeybind must be a KeyCode enum")
    			overrideSetting("General", "rayfieldOpen", keybind.Name)
    		else
    			error("ToggleUIKeybind must be a string or KeyCode enum")
    		end
    	end

    	if isfolder and not isfolder(RayfieldFolder) then
    		makefolder(RayfieldFolder)
    	end

    	local Passthrough = false
    	Topbar.Title.Text = Settings.Name

    	Main.Size = UDim2.new(0, 420, 0, 100)
    	Main.Visible = true
    	Main.BackgroundTransparency = 1
    	if Main:FindFirstChild('Notice') then Main.Notice.Visible = false end
    	Main.Shadow.Image.ImageTransparency = 1

    	LoadingFrame.Title.TextTransparency = 1
    	LoadingFrame.Subtitle.TextTransparency = 1

    	LoadingFrame.Version.TextTransparency = 1
    	LoadingFrame.Title.Text = Settings.LoadingTitle or "Rayfield"
    	LoadingFrame.Subtitle.Text = Settings.LoadingSubtitle or "Interface Suite"

    	if Settings.LoadingTitle ~= "Rayfield Interface Suite" then
    		LoadingFrame.Version.Text = "Rayfield UI"
    	end

    	if Settings.Icon and Settings.Icon ~= 0 and Topbar:FindFirstChild('Icon') then
    		Topbar.Icon.Visible = true
    		Topbar.Title.Position = UDim2.new(0, 47, 0.5, 0)

    		if Settings.Icon then
    			if typeof(Settings.Icon) == 'string' and Icons then
    				local asset = getIcon(Settings.Icon)

    				Topbar.Icon.Image = 'rbxassetid://'..asset.id
    				Topbar.Icon.ImageRectOffset = asset.imageRectOffset
    				Topbar.Icon.ImageRectSize = asset.imageRectSize
    			else
    				Topbar.Icon.Image = getAssetUri(Settings.Icon)
    			end
    		else
    			Topbar.Icon.Image = "rbxassetid://" .. 0
    		end
    	end

    	if dragBar then
    		dragBar.Visible = false
    		dragBarCosmetic.BackgroundTransparency = 1
    		dragBar.Visible = true
    	end

    	if Settings.Theme then
    		local success, result = pcall(ChangeTheme, Settings.Theme)
    		if not success then
    			local success, result2 = pcall(ChangeTheme, 'Default')
    			if not success then
    				warn('CRITICAL ERROR - NO DEFAULT THEME')
    				print(result2)
    			end
    			warn('issue rendering theme. no theme on file')
    			print(result)
    		end
    	end

    	Topbar.Visible = false
    	Elements.Visible = false
    	LoadingFrame.Visible = true

    	if not Settings.DisableRayfieldPrompts then
    		task.spawn(function()
    			while true do
    				task.wait(math.random(180, 600))
    				RayfieldLibrary:Notify({
    					Title = "ZeE-Hub",
    					Content = "觉得该脚本好用可以推荐给朋友:D",
    					Duration = 7,
    					Image = 4483362458,
    				})
    			end
    		end)
    	end

    	pcall(function()
    		if not Settings.ConfigurationSaving.FileName then
    			Settings.ConfigurationSaving.FileName = tostring(game.PlaceId)
    		end

    		if Settings.ConfigurationSaving.Enabled == nil then
    			Settings.ConfigurationSaving.Enabled = false
    		end

    		CFileName = Settings.ConfigurationSaving.FileName
    		ConfigurationFolder = Settings.ConfigurationSaving.FolderName or ConfigurationFolder
    		CEnabled = Settings.ConfigurationSaving.Enabled

    		if Settings.ConfigurationSaving.Enabled then
    			if not isfolder(ConfigurationFolder) then
    				makefolder(ConfigurationFolder)
    			end	
    		end
    	end)


    	makeDraggable(Main, Topbar, false, {dragOffset, dragOffsetMobile})
    	if dragBar then dragBar.Position = useMobileSizing and UDim2.new(0.5, 0, 0.5, dragOffsetMobile) or UDim2.new(0.5, 0, 0.5, dragOffset) makeDraggable(Main, dragInteract, true, {dragOffset, dragOffsetMobile}) end

    	for _, TabButton in ipairs(TabList:GetChildren()) do
    		if TabButton.ClassName == "Frame" and TabButton.Name ~= "Placeholder" then
    			TabButton.BackgroundTransparency = 1
    			TabButton.Title.TextTransparency = 1
    			TabButton.Image.ImageTransparency = 1
    			TabButton.UIStroke.Transparency = 1
    		end
    	end

    	if Settings.Discord and Settings.Discord.Enabled and not useStudio then
    		if isfolder and not isfolder(RayfieldFolder.."/Discord Invites") then
    			makefolder(RayfieldFolder.."/Discord Invites")
    		end

    		if isfile and not isfile(RayfieldFolder.."/Discord Invites".."/"..Settings.Discord.Invite..ConfigurationExtension) then
    			if request then
    				pcall(function()
    					request({
    						Url = 'http://127.0.0.1:6463/rpc?v=1',
    						Method = 'POST',
    						Headers = {
    							['Content-Type'] = 'application/json',
    							Origin = 'https://discord.com'
    						},
    						Body = HttpService:JSONEncode({
    							cmd = 'INVITE_BROWSER',
    							nonce = HttpService:GenerateGUID(false),
    							args = {code = Settings.Discord.Invite}
    						})
    					})
    				end)
    			end

    			if Settings.Discord.RememberJoins then -- We do logic this way so if the developer changes this setting, the user still won't be prompted, only new users
    				writefile(RayfieldFolder.."/Discord Invites".."/"..Settings.Discord.Invite..ConfigurationExtension,"Rayfield RememberJoins is true for this invite, this invite will not ask you to join again")
    			end
    		end
    	end

    	if (Settings.KeySystem) then
    		if not Settings.KeySettings then
    			Passthrough = true
    			return
    		end

    		if isfolder and not isfolder(RayfieldFolder.."/Key System") then
    			makefolder(RayfieldFolder.."/Key System")
    		end

    		if typeof(Settings.KeySettings.Key) == "string" then Settings.KeySettings.Key = {Settings.KeySettings.Key} end

    		if Settings.KeySettings.GrabKeyFromSite then
    			for i, Key in ipairs(Settings.KeySettings.Key) do
    				local Success, Response = pcall(function()
    					Settings.KeySettings.Key[i] = tostring(game:HttpGet(Key):gsub("[\n\r]", " "))
    					Settings.KeySettings.Key[i] = string.gsub(Settings.KeySettings.Key[i], " ", "")
    				end)
    				if not Success then
    					print("Rayfield | "..Key.." Error " ..tostring(Response))
    					warn('Check docs.sirius.menu for help with Rayfield specific development.')
    				end
    			end
    		end

    		if not Settings.KeySettings.FileName then
    			Settings.KeySettings.FileName = "No file name specified"
    		end

    		if isfile and isfile(RayfieldFolder.."/Key System".."/"..Settings.KeySettings.FileName..ConfigurationExtension) then
    			for _, MKey in ipairs(Settings.KeySettings.Key) do
    				if string.find(readfile(RayfieldFolder.."/Key System".."/"..Settings.KeySettings.FileName..ConfigurationExtension), MKey) then
    					Passthrough = true
    				end
    			end
    		end

    		if not Passthrough then
    			local AttemptsRemaining = math.random(2, 5)
    			Rayfield.Enabled = false
    			local KeyUI = useStudio and script.Parent:FindFirstChild('Key') or game:GetObjects("rbxassetid://11380036235")[1]

    			KeyUI.Enabled = true

    			if gethui then
    				KeyUI.Parent = gethui()
    			elseif syn and syn.protect_gui then 
    				syn.protect_gui(KeyUI)
    				KeyUI.Parent = CoreGui
    			elseif not useStudio and CoreGui:FindFirstChild("RobloxGui") then
    				KeyUI.Parent = CoreGui:FindFirstChild("RobloxGui")
    			elseif not useStudio then
    				KeyUI.Parent = CoreGui
    			end

    			if gethui then
    				for _, Interface in ipairs(gethui():GetChildren()) do
    					if Interface.Name == KeyUI.Name and Interface ~= KeyUI then
    						Interface.Enabled = false
    						Interface.Name = "KeyUI-Old"
    					end
    				end
    			elseif not useStudio then
    				for _, Interface in ipairs(CoreGui:GetChildren()) do
    					if Interface.Name == KeyUI.Name and Interface ~= KeyUI then
    						Interface.Enabled = false
    						Interface.Name = "KeyUI-Old"
    					end
    				end
    			end

    			local KeyMain = KeyUI.Main
    			KeyMain.Title.Text = Settings.KeySettings.Title or Settings.Name
    			KeyMain.Subtitle.Text = Settings.KeySettings.Subtitle or "Key System"
    			KeyMain.NoteMessage.Text = Settings.KeySettings.Note or "No instructions"

    			KeyMain.Size = UDim2.new(0, 467, 0, 175)
    			KeyMain.BackgroundTransparency = 1
    			KeyMain.Shadow.Image.ImageTransparency = 1
    			KeyMain.Title.TextTransparency = 1
    			KeyMain.Subtitle.TextTransparency = 1
    			KeyMain.KeyNote.TextTransparency = 1
    			KeyMain.Input.BackgroundTransparency = 1
    			KeyMain.Input.UIStroke.Transparency = 1
    			KeyMain.Input.InputBox.TextTransparency = 1
    			KeyMain.NoteTitle.TextTransparency = 1
    			KeyMain.NoteMessage.TextTransparency = 1
    			KeyMain.Hide.ImageTransparency = 1

    			TweenService:Create(KeyMain, TweenInfo.new(0.6, Enum.EasingStyle.Exponential), {BackgroundTransparency = 0}):Play()
    			TweenService:Create(KeyMain, TweenInfo.new(0.6, Enum.EasingStyle.Exponential), {Size = UDim2.new(0, 500, 0, 187)}):Play()
    			TweenService:Create(KeyMain.Shadow.Image, TweenInfo.new(0.5, Enum.EasingStyle.Exponential), {ImageTransparency = 0.5}):Play()
    			task.wait(0.05)
    			TweenService:Create(KeyMain.Title, TweenInfo.new(0.4, Enum.EasingStyle.Exponential), {TextTransparency = 0}):Play()
    			TweenService:Create(KeyMain.Subtitle, TweenInfo.new(0.5, Enum.EasingStyle.Exponential), {TextTransparency = 0}):Play()
    			task.wait(0.05)
    			TweenService:Create(KeyMain.KeyNote, TweenInfo.new(0.5, Enum.EasingStyle.Exponential), {TextTransparency = 0}):Play()
    			TweenService:Create(KeyMain.Input, TweenInfo.new(0.5, Enum.EasingStyle.Exponential), {BackgroundTransparency = 0}):Play()
    			TweenService:Create(KeyMain.Input.UIStroke, TweenInfo.new(0.5, Enum.EasingStyle.Exponential), {Transparency = 0}):Play()
    			TweenService:Create(KeyMain.Input.InputBox, TweenInfo.new(0.5, Enum.EasingStyle.Exponential), {TextTransparency = 0}):Play()
    			task.wait(0.05)
    			TweenService:Create(KeyMain.NoteTitle, TweenInfo.new(0.4, Enum.EasingStyle.Exponential), {TextTransparency = 0}):Play()
    			TweenService:Create(KeyMain.NoteMessage, TweenInfo.new(0.4, Enum.EasingStyle.Exponential), {TextTransparency = 0}):Play()
    			task.wait(0.15)
    			TweenService:Create(KeyMain.Hide, TweenInfo.new(0.4, Enum.EasingStyle.Exponential), {ImageTransparency = 0.3}):Play()


    			KeyUI.Main.Input.InputBox.FocusLost:Connect(function()
    				if #KeyUI.Main.Input.InputBox.Text == 0 then return end
    				local KeyFound = false
    				local FoundKey = ''
    				for _, MKey in ipairs(Settings.KeySettings.Key) do
    					--if string.find(KeyMain.Input.InputBox.Text, MKey) then
    					--	KeyFound = true
    					--	FoundKey = MKey
    					--end


    					-- stricter key check
    					if KeyMain.Input.InputBox.Text == MKey then
    						KeyFound = true
    						FoundKey = MKey
    					end
    				end
    				if KeyFound then 
    					TweenService:Create(KeyMain, TweenInfo.new(0.6, Enum.EasingStyle.Exponential), {BackgroundTransparency = 1}):Play()
    					TweenService:Create(KeyMain, TweenInfo.new(0.6, Enum.EasingStyle.Exponential), {Size = UDim2.new(0, 467, 0, 175)}):Play()
    					TweenService:Create(KeyMain.Shadow.Image, TweenInfo.new(0.5, Enum.EasingStyle.Exponential), {ImageTransparency = 1}):Play()
    					TweenService:Create(KeyMain.Title, TweenInfo.new(0.4, Enum.EasingStyle.Exponential), {TextTransparency = 1}):Play()
    					TweenService:Create(KeyMain.Subtitle, TweenInfo.new(0.5, Enum.EasingStyle.Exponential), {TextTransparency = 1}):Play()
    					TweenService:Create(KeyMain.KeyNote, TweenInfo.new(0.5, Enum.EasingStyle.Exponential), {TextTransparency = 1}):Play()
    					TweenService:Create(KeyMain.Input, TweenInfo.new(0.5, Enum.EasingStyle.Exponential), {BackgroundTransparency = 1}):Play()
    					TweenService:Create(KeyMain.Input.UIStroke, TweenInfo.new(0.5, Enum.EasingStyle.Exponential), {Transparency = 1}):Play()
    					TweenService:Create(KeyMain.Input.InputBox, TweenInfo.new(0.5, Enum.EasingStyle.Exponential), {TextTransparency = 1}):Play()
    					TweenService:Create(KeyMain.NoteTitle, TweenInfo.new(0.4, Enum.EasingStyle.Exponential), {TextTransparency = 1}):Play()
    					TweenService:Create(KeyMain.NoteMessage, TweenInfo.new(0.4, Enum.EasingStyle.Exponential), {TextTransparency = 1}):Play()
    					TweenService:Create(KeyMain.Hide, TweenInfo.new(0.4, Enum.EasingStyle.Exponential), {ImageTransparency = 1}):Play()
    					task.wait(0.51)
    					Passthrough = true
    					KeyMain.Visible = false
    					if Settings.KeySettings.SaveKey then
    						if writefile then
    							writefile(RayfieldFolder.."/Key System".."/"..Settings.KeySettings.FileName..ConfigurationExtension, FoundKey)
    						end
    						RayfieldLibrary:Notify({Title = "Key System", Content = "The key for this script has been saved successfully.", Image = 3605522284})
    					end
    				else
    					if AttemptsRemaining == 0 then
    						TweenService:Create(KeyMain, TweenInfo.new(0.6, Enum.EasingStyle.Exponential), {BackgroundTransparency = 1}):Play()
    						TweenService:Create(KeyMain, TweenInfo.new(0.6, Enum.EasingStyle.Exponential), {Size = UDim2.new(0, 467, 0, 175)}):Play()
    						TweenService:Create(KeyMain.Shadow.Image, TweenInfo.new(0.5, Enum.EasingStyle.Exponential), {ImageTransparency = 1}):Play()
    						TweenService:Create(KeyMain.Title, TweenInfo.new(0.4, Enum.EasingStyle.Exponential), {TextTransparency = 1}):Play()
    						TweenService:Create(KeyMain.Subtitle, TweenInfo.new(0.5, Enum.EasingStyle.Exponential), {TextTransparency = 1}):Play()
    						TweenService:Create(KeyMain.KeyNote, TweenInfo.new(0.5, Enum.EasingStyle.Exponential), {TextTransparency = 1}):Play()
    						TweenService:Create(KeyMain.Input, TweenInfo.new(0.5, Enum.EasingStyle.Exponential), {BackgroundTransparency = 1}):Play()
    						TweenService:Create(KeyMain.Input.UIStroke, TweenInfo.new(0.5, Enum.EasingStyle.Exponential), {Transparency = 1}):Play()
    						TweenService:Create(KeyMain.Input.InputBox, TweenInfo.new(0.5, Enum.EasingStyle.Exponential), {TextTransparency = 1}):Play()
    						TweenService:Create(KeyMain.NoteTitle, TweenInfo.new(0.4, Enum.EasingStyle.Exponential), {TextTransparency = 1}):Play()
    						TweenService:Create(KeyMain.NoteMessage, TweenInfo.new(0.4, Enum.EasingStyle.Exponential), {TextTransparency = 1}):Play()
    						TweenService:Create(KeyMain.Hide, TweenInfo.new(0.4, Enum.EasingStyle.Exponential), {ImageTransparency = 1}):Play()
    						task.wait(0.45)
    						Players.LocalPlayer:Kick("No Attempts Remaining")
    						game:Shutdown()
    					end
    					KeyMain.Input.InputBox.Text = ""
    					AttemptsRemaining = AttemptsRemaining - 1
    					TweenService:Create(KeyMain, TweenInfo.new(0.6, Enum.EasingStyle.Exponential), {Size = UDim2.new(0, 467, 0, 175)}):Play()
    					TweenService:Create(KeyMain, TweenInfo.new(0.4, Enum.EasingStyle.Elastic), {Position = UDim2.new(0.495,0,0.5,0)}):Play()
    					task.wait(0.1)
    					TweenService:Create(KeyMain, TweenInfo.new(0.4, Enum.EasingStyle.Elastic), {Position = UDim2.new(0.505,0,0.5,0)}):Play()
    					task.wait(0.1)
    					TweenService:Create(KeyMain, TweenInfo.new(0.4, Enum.EasingStyle.Exponential), {Position = UDim2.new(0.5,0,0.5,0)}):Play()
    					TweenService:Create(KeyMain, TweenInfo.new(0.6, Enum.EasingStyle.Exponential), {Size = UDim2.new(0, 500, 0, 187)}):Play()
    				end
    			end)

    			KeyMain.Hide.MouseButton1Click:Connect(function()
    				TweenService:Create(KeyMain, TweenInfo.new(0.6, Enum.EasingStyle.Exponential), {BackgroundTransparency = 1}):Play()
    				TweenService:Create(KeyMain, TweenInfo.new(0.6, Enum.EasingStyle.Exponential), {Size = UDim2.new(0, 467, 0, 175)}):Play()
    				TweenService:Create(KeyMain.Shadow.Image, TweenInfo.new(0.5, Enum.EasingStyle.Exponential), {ImageTransparency = 1}):Play()
    				TweenService:Create(KeyMain.Title, TweenInfo.new(0.4, Enum.EasingStyle.Exponential), {TextTransparency = 1}):Play()
    				TweenService:Create(KeyMain.Subtitle, TweenInfo.new(0.5, Enum.EasingStyle.Exponential), {TextTransparency = 1}):Play()
    				TweenService:Create(KeyMain.KeyNote, TweenInfo.new(0.5, Enum.EasingStyle.Exponential), {TextTransparency = 1}):Play()
    				TweenService:Create(KeyMain.Input, TweenInfo.new(0.5, Enum.EasingStyle.Exponential), {BackgroundTransparency = 1}):Play()
    				TweenService:Create(KeyMain.Input.UIStroke, TweenInfo.new(0.5, Enum.EasingStyle.Exponential), {Transparency = 1}):Play()
    				TweenService:Create(KeyMain.Input.InputBox, TweenInfo.new(0.5, Enum.EasingStyle.Exponential), {TextTransparency = 1}):Play()
    				TweenService:Create(KeyMain.NoteTitle, TweenInfo.new(0.4, Enum.EasingStyle.Exponential), {TextTransparency = 1}):Play()
    				TweenService:Create(KeyMain.NoteMessage, TweenInfo.new(0.4, Enum.EasingStyle.Exponential), {TextTransparency = 1}):Play()
    				TweenService:Create(KeyMain.Hide, TweenInfo.new(0.4, Enum.EasingStyle.Exponential), {ImageTransparency = 1}):Play()
    				task.wait(0.51)
    				RayfieldLibrary:Destroy()
    				KeyUI:Destroy()
    			end)
    		else
    			Passthrough = true
    		end
    	end
    	if Settings.KeySystem then
    		repeat task.wait() until Passthrough
    	end

    	Notifications.Template.Visible = false
    	Notifications.Visible = true
    	Rayfield.Enabled = true

    	task.wait(0.5)
    	TweenService:Create(Main, TweenInfo.new(0.7, Enum.EasingStyle.Exponential), {BackgroundTransparency = 0}):Play()
    	TweenService:Create(Main.Shadow.Image, TweenInfo.new(0.7, Enum.EasingStyle.Exponential), {ImageTransparency = 0.6}):Play()
    	task.wait(0.1)
    	TweenService:Create(LoadingFrame.Title, TweenInfo.new(0.7, Enum.EasingStyle.Exponential), {TextTransparency = 0}):Play()
    	task.wait(0.05)
    	TweenService:Create(LoadingFrame.Subtitle, TweenInfo.new(0.7, Enum.EasingStyle.Exponential), {TextTransparency = 0}):Play()
    	task.wait(0.05)
    	TweenService:Create(LoadingFrame.Version, TweenInfo.new(0.7, Enum.EasingStyle.Exponential), {TextTransparency = 0}):Play()


    	Elements.Template.LayoutOrder = 100000
    	Elements.Template.Visible = false

    	Elements.UIPageLayout.FillDirection = Enum.FillDirection.Horizontal
    	TabList.Template.Visible = false

    	-- Tab
    	local FirstTab = false
    	local Window = {}
    	function Window:CreateTab(Name, Image, Ext)
    		local SDone = false
    		local TabButton = TabList.Template:Clone()
    		TabButton.Name = Name
    		TabButton.Title.Text = Name
    		TabButton.Parent = TabList
    		TabButton.Title.TextWrapped = false
    		TabButton.Size = UDim2.new(0, TabButton.Title.TextBounds.X + 30, 0, 30)

    		if Image and Image ~= 0 then
    			if typeof(Image) == 'string' and Icons then
    				local asset = getIcon(Image)

    				TabButton.Image.Image = 'rbxassetid://'..asset.id
    				TabButton.Image.ImageRectOffset = asset.imageRectOffset
    				TabButton.Image.ImageRectSize = asset.imageRectSize
    			else
    				TabButton.Image.Image = getAssetUri(Image)
    			end

    			TabButton.Title.AnchorPoint = Vector2.new(0, 0.5)
    			TabButton.Title.Position = UDim2.new(0, 37, 0.5, 0)
    			TabButton.Image.Visible = true
    			TabButton.Title.TextXAlignment = Enum.TextXAlignment.Left
    			TabButton.Size = UDim2.new(0, TabButton.Title.TextBounds.X + 52, 0, 30)
    		end



    		TabButton.BackgroundTransparency = 1
    		TabButton.Title.TextTransparency = 1
    		TabButton.Image.ImageTransparency = 1
    		TabButton.UIStroke.Transparency = 1

    		TabButton.Visible = not Ext or false

    		-- Create Elements Page
    		local TabPage = Elements.Template:Clone()
    		TabPage.Name = Name
    		TabPage.Visible = true

    		TabPage.LayoutOrder = #Elements:GetChildren() or Ext and 10000

    		for _, TemplateElement in ipairs(TabPage:GetChildren()) do
    			if TemplateElement.ClassName == "Frame" and TemplateElement.Name ~= "Placeholder" then
    				TemplateElement:Destroy()
    			end
    		end

    		TabPage.Parent = Elements
    		if not FirstTab and not Ext then
    			Elements.UIPageLayout.Animated = false
    			Elements.UIPageLayout:JumpTo(TabPage)
    			Elements.UIPageLayout.Animated = true
    		end

    		TabButton.UIStroke.Color = SelectedTheme.TabStroke

    		if Elements.UIPageLayout.CurrentPage == TabPage then
    			TabButton.BackgroundColor3 = SelectedTheme.TabBackgroundSelected
    			TabButton.Image.ImageColor3 = SelectedTheme.SelectedTabTextColor
    			TabButton.Title.TextColor3 = SelectedTheme.SelectedTabTextColor
    		else
    			TabButton.BackgroundColor3 = SelectedTheme.TabBackground
    			TabButton.Image.ImageColor3 = SelectedTheme.TabTextColor
    			TabButton.Title.TextColor3 = SelectedTheme.TabTextColor
    		end


    		-- Animate
    		task.wait(0.1)
    		if FirstTab or Ext then
    			TabButton.BackgroundColor3 = SelectedTheme.TabBackground
    			TabButton.Image.ImageColor3 = SelectedTheme.TabTextColor
    			TabButton.Title.TextColor3 = SelectedTheme.TabTextColor
    			TweenService:Create(TabButton, TweenInfo.new(0.7, Enum.EasingStyle.Exponential), {BackgroundTransparency = 0.7}):Play()
    			TweenService:Create(TabButton.Title, TweenInfo.new(0.7, Enum.EasingStyle.Exponential), {TextTransparency = 0.2}):Play()
    			TweenService:Create(TabButton.Image, TweenInfo.new(0.7, Enum.EasingStyle.Exponential), {ImageTransparency = 0.2}):Play()
    			TweenService:Create(TabButton.UIStroke, TweenInfo.new(0.7, Enum.EasingStyle.Exponential), {Transparency = 0.5}):Play()
    		elseif not Ext then
    			FirstTab = Name
    			TabButton.BackgroundColor3 = SelectedTheme.TabBackgroundSelected
    			TabButton.Image.ImageColor3 = SelectedTheme.SelectedTabTextColor
    			TabButton.Title.TextColor3 = SelectedTheme.SelectedTabTextColor
    			TweenService:Create(TabButton.Image, TweenInfo.new(0.7, Enum.EasingStyle.Exponential), {ImageTransparency = 0}):Play()
    			TweenService:Create(TabButton, TweenInfo.new(0.7, Enum.EasingStyle.Exponential), {BackgroundTransparency = 0}):Play()
    			TweenService:Create(TabButton.Title, TweenInfo.new(0.7, Enum.EasingStyle.Exponential), {TextTransparency = 0}):Play()
    		end


    		TabButton.Interact.MouseButton1Click:Connect(function()
    			if Minimised then return end
    			TweenService:Create(TabButton, TweenInfo.new(0.7, Enum.EasingStyle.Exponential), {BackgroundTransparency = 0}):Play()
    			TweenService:Create(TabButton.UIStroke, TweenInfo.new(0.7, Enum.EasingStyle.Exponential), {Transparency = 1}):Play()
    			TweenService:Create(TabButton.Title, TweenInfo.new(0.7, Enum.EasingStyle.Exponential), {TextTransparency = 0}):Play()
    			TweenService:Create(TabButton.Image, TweenInfo.new(0.7, Enum.EasingStyle.Exponential), {ImageTransparency = 0}):Play()
    			TweenService:Create(TabButton, TweenInfo.new(0.7, Enum.EasingStyle.Exponential), {BackgroundColor3 = SelectedTheme.TabBackgroundSelected}):Play()
    			TweenService:Create(TabButton.Title, TweenInfo.new(0.7, Enum.EasingStyle.Exponential), {TextColor3 = SelectedTheme.SelectedTabTextColor}):Play()
    			TweenService:Create(TabButton.Image, TweenInfo.new(0.7, Enum.EasingStyle.Exponential), {ImageColor3 = SelectedTheme.SelectedTabTextColor}):Play()

    			for _, OtherTabButton in ipairs(TabList:GetChildren()) do
    				if OtherTabButton.Name ~= "Template" and OtherTabButton.ClassName == "Frame" and OtherTabButton ~= TabButton and OtherTabButton.Name ~= "Placeholder" then
    					TweenService:Create(OtherTabButton, TweenInfo.new(0.7, Enum.EasingStyle.Exponential), {BackgroundColor3 = SelectedTheme.TabBackground}):Play()
    					TweenService:Create(OtherTabButton.Title, TweenInfo.new(0.7, Enum.EasingStyle.Exponential), {TextColor3 = SelectedTheme.TabTextColor}):Play()
    					TweenService:Create(OtherTabButton.Image, TweenInfo.new(0.7, Enum.EasingStyle.Exponential), {ImageColor3 = SelectedTheme.TabTextColor}):Play()
    					TweenService:Create(OtherTabButton, TweenInfo.new(0.7, Enum.EasingStyle.Exponential), {BackgroundTransparency = 0.7}):Play()
    					TweenService:Create(OtherTabButton.Title, TweenInfo.new(0.7, Enum.EasingStyle.Exponential), {TextTransparency = 0.2}):Play()
    					TweenService:Create(OtherTabButton.Image, TweenInfo.new(0.7, Enum.EasingStyle.Exponential), {ImageTransparency = 0.2}):Play()
    					TweenService:Create(OtherTabButton.UIStroke, TweenInfo.new(0.7, Enum.EasingStyle.Exponential), {Transparency = 0.5}):Play()
    				end
    			end

    			if Elements.UIPageLayout.CurrentPage ~= TabPage then
    				Elements.UIPageLayout:JumpTo(TabPage)
    			end
    		end)

    		local Tab = {}

    		-- Button
    		function Tab:CreateButton(ButtonSettings)
    			local ButtonValue = {}

    			local Button = Elements.Template.Button:Clone()
    			Button.Name = ButtonSettings.Name
    			Button.Title.Text = ButtonSettings.Name
    			Button.Visible = true
    			Button.Parent = TabPage

    			Button.BackgroundTransparency = 1
    			Button.UIStroke.Transparency = 1
    			Button.Title.TextTransparency = 1

    			TweenService:Create(Button, TweenInfo.new(0.7, Enum.EasingStyle.Exponential), {BackgroundTransparency = 0}):Play()
    			TweenService:Create(Button.UIStroke, TweenInfo.new(0.7, Enum.EasingStyle.Exponential), {Transparency = 0}):Play()
    			TweenService:Create(Button.Title, TweenInfo.new(0.7, Enum.EasingStyle.Exponential), {TextTransparency = 0}):Play()	


    			Button.Interact.MouseButton1Click:Connect(function()
    				local Success, Response = pcall(ButtonSettings.Callback)
    				-- Prevents animation from trying to play if the button's callback called RayfieldLibrary:Destroy()
    				if rayfieldDestroyed then
    					return
    				end
    				if not Success then
    					TweenService:Create(Button, TweenInfo.new(0.6, Enum.EasingStyle.Exponential), {BackgroundColor3 = Color3.fromRGB(85, 0, 0)}):Play()
    					TweenService:Create(Button.ElementIndicator, TweenInfo.new(0.6, Enum.EasingStyle.Exponential), {TextTransparency = 1}):Play()
    					TweenService:Create(Button.UIStroke, TweenInfo.new(0.6, Enum.EasingStyle.Exponential), {Transparency = 1}):Play()
    					Button.Title.Text = "Callback Error"
    					print("Rayfield | "..ButtonSettings.Name.." Callback Error " ..tostring(Response))
    					warn('Check docs.sirius.menu for help with Rayfield specific development.')
    					task.wait(0.5)
    					Button.Title.Text = ButtonSettings.Name
    					TweenService:Create(Button, TweenInfo.new(0.6, Enum.EasingStyle.Exponential), {BackgroundColor3 = SelectedTheme.ElementBackground}):Play()
    					TweenService:Create(Button.ElementIndicator, TweenInfo.new(0.6, Enum.EasingStyle.Exponential), {TextTransparency = 0.9}):Play()
    					TweenService:Create(Button.UIStroke, TweenInfo.new(0.6, Enum.EasingStyle.Exponential), {Transparency = 0}):Play()
    				else
    					if not ButtonSettings.Ext then
    						SaveConfiguration(ButtonSettings.Name..'\n')
    					end
    					TweenService:Create(Button, TweenInfo.new(0.6, Enum.EasingStyle.Exponential), {BackgroundColor3 = SelectedTheme.ElementBackgroundHover}):Play()
    					TweenService:Create(Button.ElementIndicator, TweenInfo.new(0.6, Enum.EasingStyle.Exponential), {TextTransparency = 1}):Play()
    					TweenService:Create(Button.UIStroke, TweenInfo.new(0.6, Enum.EasingStyle.Exponential), {Transparency = 1}):Play()
    					task.wait(0.2)
    					TweenService:Create(Button, TweenInfo.new(0.6, Enum.EasingStyle.Exponential), {BackgroundColor3 = SelectedTheme.ElementBackground}):Play()
    					TweenService:Create(Button.ElementIndicator, TweenInfo.new(0.6, Enum.EasingStyle.Exponential), {TextTransparency = 0.9}):Play()
    					TweenService:Create(Button.UIStroke, TweenInfo.new(0.6, Enum.EasingStyle.Exponential), {Transparency = 0}):Play()
    				end
    			end)

    			Button.MouseEnter:Connect(function()
    				TweenService:Create(Button, TweenInfo.new(0.6, Enum.EasingStyle.Exponential), {BackgroundColor3 = SelectedTheme.ElementBackgroundHover}):Play()
    				TweenService:Create(Button.ElementIndicator, TweenInfo.new(0.6, Enum.EasingStyle.Exponential), {TextTransparency = 0.7}):Play()
    			end)

    			Button.MouseLeave:Connect(function()
    				TweenService:Create(Button, TweenInfo.new(0.6, Enum.EasingStyle.Exponential), {BackgroundColor3 = SelectedTheme.ElementBackground}):Play()
    				TweenService:Create(Button.ElementIndicator, TweenInfo.new(0.6, Enum.EasingStyle.Exponential), {TextTransparency = 0.9}):Play()
    			end)

    			function ButtonValue:Set(NewButton)
    				Button.Title.Text = NewButton
    				Button.Name = NewButton
    			end

    			return ButtonValue
    		end

    		-- ColorPicker
    		function Tab:CreateColorPicker(ColorPickerSettings) -- by Throit
    			ColorPickerSettings.Type = "ColorPicker"
    			local ColorPicker = Elements.Template.ColorPicker:Clone()
    			local Background = ColorPicker.CPBackground
    			local Display = Background.Display
    			local Main = Background.MainCP
    			local Slider = ColorPicker.ColorSlider
    			ColorPicker.ClipsDescendants = true
    			ColorPicker.Name = ColorPickerSettings.Name
    			ColorPicker.Title.Text = ColorPickerSettings.Name
    			ColorPicker.Visible = true
    			ColorPicker.Parent = TabPage
    			ColorPicker.Size = UDim2.new(1, -10, 0, 45)
    			Background.Size = UDim2.new(0, 39, 0, 22)
    			Display.BackgroundTransparency = 0
    			Main.MainPoint.ImageTransparency = 1
    			ColorPicker.Interact.Size = UDim2.new(1, 0, 1, 0)
    			ColorPicker.Interact.Position = UDim2.new(0.5, 0, 0.5, 0)
    			ColorPicker.RGB.Position = UDim2.new(0, 17, 0, 70)
    			ColorPicker.HexInput.Position = UDim2.new(0, 17, 0, 90)
    			Main.ImageTransparency = 1
    			Background.BackgroundTransparency = 1

    			for _, rgbinput in ipairs(ColorPicker.RGB:GetChildren()) do
    				if rgbinput:IsA("Frame") then
    					rgbinput.BackgroundColor3 = SelectedTheme.InputBackground
    					rgbinput.UIStroke.Color = SelectedTheme.InputStroke
    				end
    			end

    			ColorPicker.HexInput.BackgroundColor3 = SelectedTheme.InputBackground
    			ColorPicker.HexInput.UIStroke.Color = SelectedTheme.InputStroke

    			local opened = false 
    			local mouse = Players.LocalPlayer:GetMouse()
    			Main.Image = "http://www.roblox.com/asset/?id=11415645739"
    			local mainDragging = false 
    			local sliderDragging = false 
    			ColorPicker.Interact.MouseButton1Down:Connect(function()
    				task.spawn(function()
    					TweenService:Create(ColorPicker, TweenInfo.new(0.6, Enum.EasingStyle.Exponential), {BackgroundColor3 = SelectedTheme.ElementBackgroundHover}):Play()
    					TweenService:Create(ColorPicker.UIStroke, TweenInfo.new(0.6, Enum.EasingStyle.Exponential), {Transparency = 1}):Play()
    					task.wait(0.2)
    					TweenService:Create(ColorPicker, TweenInfo.new(0.6, Enum.EasingStyle.Exponential), {BackgroundColor3 = SelectedTheme.ElementBackground}):Play()
    					TweenService:Create(ColorPicker.UIStroke, TweenInfo.new(0.6, Enum.EasingStyle.Exponential), {Transparency = 0}):Play()
    				end)

    				if not opened then
    					opened = true 
    					TweenService:Create(Background, TweenInfo.new(0.45, Enum.EasingStyle.Exponential), {Size = UDim2.new(0, 18, 0, 15)}):Play()
    					task.wait(0.1)
    					TweenService:Create(ColorPicker, TweenInfo.new(0.6, Enum.EasingStyle.Exponential), {Size = UDim2.new(1, -10, 0, 120)}):Play()
    					TweenService:Create(Background, TweenInfo.new(0.6, Enum.EasingStyle.Exponential), {Size = UDim2.new(0, 173, 0, 86)}):Play()
    					TweenService:Create(Display, TweenInfo.new(0.6, Enum.EasingStyle.Exponential), {BackgroundTransparency = 1}):Play()
    					TweenService:Create(ColorPicker.Interact, TweenInfo.new(0.6, Enum.EasingStyle.Exponential), {Position = UDim2.new(0.289, 0, 0.5, 0)}):Play()
    					TweenService:Create(ColorPicker.RGB, TweenInfo.new(0.8, Enum.EasingStyle.Exponential), {Position = UDim2.new(0, 17, 0, 40)}):Play()
    					TweenService:Create(ColorPicker.HexInput, TweenInfo.new(0.5, Enum.EasingStyle.Exponential), {Position = UDim2.new(0, 17, 0, 73)}):Play()
    					TweenService:Create(ColorPicker.Interact, TweenInfo.new(0.6, Enum.EasingStyle.Exponential), {Size = UDim2.new(0.574, 0, 1, 0)}):Play()
    					TweenService:Create(Main.MainPoint, TweenInfo.new(0.2, Enum.EasingStyle.Exponential), {ImageTransparency = 0}):Play()
    					TweenService:Create(Main, TweenInfo.new(0.2, Enum.EasingStyle.Exponential), {ImageTransparency = SelectedTheme ~= RayfieldLibrary.Theme.Default and 0.25 or 0.1}):Play()
    					TweenService:Create(Background, TweenInfo.new(0.6, Enum.EasingStyle.Exponential), {BackgroundTransparency = 0}):Play()
    				else
    					opened = false
    					TweenService:Create(ColorPicker, TweenInfo.new(0.6, Enum.EasingStyle.Exponential), {Size = UDim2.new(1, -10, 0, 45)}):Play()
    					TweenService:Create(Background, TweenInfo.new(0.6, Enum.EasingStyle.Exponential), {Size = UDim2.new(0, 39, 0, 22)}):Play()
    					TweenService:Create(ColorPicker.Interact, TweenInfo.new(0.6, Enum.EasingStyle.Exponential), {Size = UDim2.new(1, 0, 1, 0)}):Play()
    					TweenService:Create(ColorPicker.Interact, TweenInfo.new(0.6, Enum.EasingStyle.Exponential), {Position = UDim2.new(0.5, 0, 0.5, 0)}):Play()
    					TweenService:Create(ColorPicker.RGB, TweenInfo.new(0.6, Enum.EasingStyle.Exponential), {Position = UDim2.new(0, 17, 0, 70)}):Play()
    					TweenService:Create(ColorPicker.HexInput, TweenInfo.new(0.5, Enum.EasingStyle.Exponential), {Position = UDim2.new(0, 17, 0, 90)}):Play()
    					TweenService:Create(Display, TweenInfo.new(0.6, Enum.EasingStyle.Exponential), {BackgroundTransparency = 0}):Play()
    					TweenService:Create(Main.MainPoint, TweenInfo.new(0.2, Enum.EasingStyle.Exponential), {ImageTransparency = 1}):Play()
    					TweenService:Create(Main, TweenInfo.new(0.2, Enum.EasingStyle.Exponential), {ImageTransparency = 1}):Play()
    					TweenService:Create(Background, TweenInfo.new(0.6, Enum.EasingStyle.Exponential), {BackgroundTransparency = 1}):Play()
    				end

    			end)

    			UserInputService.InputEnded:Connect(function(input, gameProcessed) if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then 
    					mainDragging = false
    					sliderDragging = false
    				end end)
    			Main.MouseButton1Down:Connect(function()
    				if opened then
    					mainDragging = true 
    				end
    			end)
    			Main.MainPoint.MouseButton1Down:Connect(function()
    				if opened then
    					mainDragging = true 
    				end
    			end)
    			Slider.MouseButton1Down:Connect(function()
    				sliderDragging = true 
    			end)
    			Slider.SliderPoint.MouseButton1Down:Connect(function()
    				sliderDragging = true 
    			end)
    			local h,s,v = ColorPickerSettings.Color:ToHSV()
    			local color = Color3.fromHSV(h,s,v) 
    			local hex = string.format("#%02X%02X%02X",color.R*0xFF,color.G*0xFF,color.B*0xFF)
    			ColorPicker.HexInput.InputBox.Text = hex
    			local function setDisplay()
    				--Main
    				Main.MainPoint.Position = UDim2.new(s,-Main.MainPoint.AbsoluteSize.X/2,1-v,-Main.MainPoint.AbsoluteSize.Y/2)
    				Main.MainPoint.ImageColor3 = Color3.fromHSV(h,s,v)
    				Background.BackgroundColor3 = Color3.fromHSV(h,1,1)
    				Display.BackgroundColor3 = Color3.fromHSV(h,s,v)
    				--Slider 
    				local x = h * Slider.AbsoluteSize.X
    				Slider.SliderPoint.Position = UDim2.new(0,x-Slider.SliderPoint.AbsoluteSize.X/2,0.5,0)
    				Slider.SliderPoint.ImageColor3 = Color3.fromHSV(h,1,1)
    				local color = Color3.fromHSV(h,s,v) 
    				local r,g,b = math.floor((color.R*255)+0.5),math.floor((color.G*255)+0.5),math.floor((color.B*255)+0.5)
    				ColorPicker.RGB.RInput.InputBox.Text = tostring(r)
    				ColorPicker.RGB.GInput.InputBox.Text = tostring(g)
    				ColorPicker.RGB.BInput.InputBox.Text = tostring(b)
    				hex = string.format("#%02X%02X%02X",color.R*0xFF,color.G*0xFF,color.B*0xFF)
    				ColorPicker.HexInput.InputBox.Text = hex
    			end
    			setDisplay()
    			ColorPicker.HexInput.InputBox.FocusLost:Connect(function()
    				if not pcall(function()
    						local r, g, b = string.match(ColorPicker.HexInput.InputBox.Text, "^#?(%w%w)(%w%w)(%w%w)$")
    						local rgbColor = Color3.fromRGB(tonumber(r, 16),tonumber(g, 16), tonumber(b, 16))
    						h,s,v = rgbColor:ToHSV()
    						hex = ColorPicker.HexInput.InputBox.Text
    						setDisplay()
    						ColorPickerSettings.Color = rgbColor
    					end) 
    				then 
    					ColorPicker.HexInput.InputBox.Text = hex 
    				end
    				pcall(function()ColorPickerSettings.Callback(Color3.fromHSV(h,s,v))end)
    				local r,g,b = math.floor((h*255)+0.5),math.floor((s*255)+0.5),math.floor((v*255)+0.5)
    				ColorPickerSettings.Color = Color3.fromRGB(r,g,b)
    				if not ColorPickerSettings.Ext then
    					SaveConfiguration(ColorPickerSettings.Flag..'\n'..tostring(ColorPickerSettings.Color))
    				end
    			end)
    			--RGB
    			local function rgbBoxes(box,toChange)
    				local value = tonumber(box.Text) 
    				local color = Color3.fromHSV(h,s,v) 
    				local oldR,oldG,oldB = math.floor((color.R*255)+0.5),math.floor((color.G*255)+0.5),math.floor((color.B*255)+0.5)
    				local save 
    				if toChange == "R" then save = oldR;oldR = value elseif toChange == "G" then save = oldG;oldG = value else save = oldB;oldB = value end
    				if value then 
    					value = math.clamp(value,0,255)
    					h,s,v = Color3.fromRGB(oldR,oldG,oldB):ToHSV()

    					setDisplay()
    				else 
    					box.Text = tostring(save)
    				end
    				local r,g,b = math.floor((h*255)+0.5),math.floor((s*255)+0.5),math.floor((v*255)+0.5)
    				ColorPickerSettings.Color = Color3.fromRGB(r,g,b)
    				if not ColorPickerSettings.Ext then
    					SaveConfiguration()
    				end
    			end
    			ColorPicker.RGB.RInput.InputBox.FocusLost:connect(function()
    				rgbBoxes(ColorPicker.RGB.RInput.InputBox,"R")
    				pcall(function()ColorPickerSettings.Callback(Color3.fromHSV(h,s,v))end)
    			end)
    			ColorPicker.RGB.GInput.InputBox.FocusLost:connect(function()
    				rgbBoxes(ColorPicker.RGB.GInput.InputBox,"G")
    				pcall(function()ColorPickerSettings.Callback(Color3.fromHSV(h,s,v))end)
    			end)
    			ColorPicker.RGB.BInput.InputBox.FocusLost:connect(function()
    				rgbBoxes(ColorPicker.RGB.BInput.InputBox,"B")
    				pcall(function()ColorPickerSettings.Callback(Color3.fromHSV(h,s,v))end)
    			end)

    			RunService.RenderStepped:connect(function()
    				if mainDragging then 
    					local localX = math.clamp(mouse.X-Main.AbsolutePosition.X,0,Main.AbsoluteSize.X)
    					local localY = math.clamp(mouse.Y-Main.AbsolutePosition.Y,0,Main.AbsoluteSize.Y)
    					Main.MainPoint.Position = UDim2.new(0,localX-Main.MainPoint.AbsoluteSize.X/2,0,localY-Main.MainPoint.AbsoluteSize.Y/2)
    					s = localX / Main.AbsoluteSize.X
    					v = 1 - (localY / Main.AbsoluteSize.Y)
    					Display.BackgroundColor3 = Color3.fromHSV(h,s,v)
    					Main.MainPoint.ImageColor3 = Color3.fromHSV(h,s,v)
    					Background.BackgroundColor3 = Color3.fromHSV(h,1,1)
    					local color = Color3.fromHSV(h,s,v) 
    					local r,g,b = math.floor((color.R*255)+0.5),math.floor((color.G*255)+0.5),math.floor((color.B*255)+0.5)
    					ColorPicker.RGB.RInput.InputBox.Text = tostring(r)
    					ColorPicker.RGB.GInput.InputBox.Text = tostring(g)
    					ColorPicker.RGB.BInput.InputBox.Text = tostring(b)
    					ColorPicker.HexInput.InputBox.Text = string.format("#%02X%02X%02X",color.R*0xFF,color.G*0xFF,color.B*0xFF)
    					pcall(function()ColorPickerSettings.Callback(Color3.fromHSV(h,s,v))end)
    					ColorPickerSettings.Color = Color3.fromRGB(r,g,b)
    					if not ColorPickerSettings.Ext then
    						SaveConfiguration()
    					end
    				end
    				if sliderDragging then 
    					local localX = math.clamp(mouse.X-Slider.AbsolutePosition.X,0,Slider.AbsoluteSize.X)
    					h = localX / Slider.AbsoluteSize.X
    					Display.BackgroundColor3 = Color3.fromHSV(h,s,v)
    					Slider.SliderPoint.Position = UDim2.new(0,localX-Slider.SliderPoint.AbsoluteSize.X/2,0.5,0)
    					Slider.SliderPoint.ImageColor3 = Color3.fromHSV(h,1,1)
    					Background.BackgroundColor3 = Color3.fromHSV(h,1,1)
    					Main.MainPoint.ImageColor3 = Color3.fromHSV(h,s,v)
    					local color = Color3.fromHSV(h,s,v) 
    					local r,g,b = math.floor((color.R*255)+0.5),math.floor((color.G*255)+0.5),math.floor((color.B*255)+0.5)
    					ColorPicker.RGB.RInput.InputBox.Text = tostring(r)
    					ColorPicker.RGB.GInput.InputBox.Text = tostring(g)
    					ColorPicker.RGB.BInput.InputBox.Text = tostring(b)
    					ColorPicker.HexInput.InputBox.Text = string.format("#%02X%02X%02X",color.R*0xFF,color.G*0xFF,color.B*0xFF)
    					pcall(function()ColorPickerSettings.Callback(Color3.fromHSV(h,s,v))end)
    					ColorPickerSettings.Color = Color3.fromRGB(r,g,b)
    					if not ColorPickerSettings.Ext then
    						SaveConfiguration()
    					end
    				end
    			end)

    			if Settings.ConfigurationSaving then
    				if Settings.ConfigurationSaving.Enabled and ColorPickerSettings.Flag then
    					RayfieldLibrary.Flags[ColorPickerSettings.Flag] = ColorPickerSettings
    				end
    			end

    			function ColorPickerSettings:Set(RGBColor)
    				ColorPickerSettings.Color = RGBColor
    				h,s,v = ColorPickerSettings.Color:ToHSV()
    				color = Color3.fromHSV(h,s,v)
    				setDisplay()
    			end

    			ColorPicker.MouseEnter:Connect(function()
    				TweenService:Create(ColorPicker, TweenInfo.new(0.6, Enum.EasingStyle.Exponential), {BackgroundColor3 = SelectedTheme.ElementBackgroundHover}):Play()
    			end)

    			ColorPicker.MouseLeave:Connect(function()
    				TweenService:Create(ColorPicker, TweenInfo.new(0.6, Enum.EasingStyle.Exponential), {BackgroundColor3 = SelectedTheme.ElementBackground}):Play()
    			end)

    			Rayfield.Main:GetPropertyChangedSignal('BackgroundColor3'):Connect(function()
    				for _, rgbinput in ipairs(ColorPicker.RGB:GetChildren()) do
    					if rgbinput:IsA("Frame") then
    						rgbinput.BackgroundColor3 = SelectedTheme.InputBackground
    						rgbinput.UIStroke.Color = SelectedTheme.InputStroke
    					end
    				end

    				ColorPicker.HexInput.BackgroundColor3 = SelectedTheme.InputBackground
    				ColorPicker.HexInput.UIStroke.Color = SelectedTheme.InputStroke
    			end)

    			return ColorPickerSettings
    		end

    		-- Section
    		function Tab:CreateSection(SectionName)

    			local SectionValue = {}

    			if SDone then
    				local SectionSpace = Elements.Template.SectionSpacing:Clone()
    				SectionSpace.Visible = true
    				SectionSpace.Parent = TabPage
    			end

    			local Section = Elements.Template.SectionTitle:Clone()
    			Section.Title.Text = SectionName
    			Section.Visible = true
    			Section.Parent = TabPage

    			Section.Title.TextTransparency = 1
    			TweenService:Create(Section.Title, TweenInfo.new(0.7, Enum.EasingStyle.Exponential), {TextTransparency = 0.4}):Play()

    			function SectionValue:Set(NewSection)
    				Section.Title.Text = NewSection
    			end

    			SDone = true

    			return SectionValue
    		end

    		-- Divider
    		function Tab:CreateDivider()
    			local DividerValue = {}

    			local Divider = Elements.Template.Divider:Clone()
    			Divider.Visible = true
    			Divider.Parent = TabPage

    			Divider.Divider.BackgroundTransparency = 1
    			TweenService:Create(Divider.Divider, TweenInfo.new(0.5, Enum.EasingStyle.Exponential), {BackgroundTransparency = 0.85}):Play()

    			function DividerValue:Set(Value)
    				Divider.Visible = Value
    			end

    			return DividerValue
    		end

    		-- Label
    		function Tab:CreateLabel(LabelText : string, Icon: number, Color : Color3, IgnoreTheme : boolean)
    			local LabelValue = {}

    			local Label = Elements.Template.Label:Clone()
    			Label.Title.Text = LabelText
    			Label.Visible = true
    			Label.Parent = TabPage

    			Label.BackgroundColor3 = Color or SelectedTheme.SecondaryElementBackground
    			Label.UIStroke.Color = Color or SelectedTheme.SecondaryElementStroke

    			if Icon then
    				if typeof(Icon) == 'string' and Icons then
    					local asset = getIcon(Icon)

    					Label.Icon.Image = 'rbxassetid://'..asset.id
    					Label.Icon.ImageRectOffset = asset.imageRectOffset
    					Label.Icon.ImageRectSize = asset.imageRectSize
    				else
    					Label.Icon.Image = getAssetUri(Icon)
    				end
    			else
    				Label.Icon.Image = "rbxassetid://" .. 0
    			end

    			if Icon and Label:FindFirstChild('Icon') then
    				Label.Title.Position = UDim2.new(0, 45, 0.5, 0)
    				Label.Title.Size = UDim2.new(1, -100, 0, 14)

    				if Icon then
    					if typeof(Icon) == 'string' and Icons then
    						local asset = getIcon(Icon)

    						Label.Icon.Image = 'rbxassetid://'..asset.id
    						Label.Icon.ImageRectOffset = asset.imageRectOffset
    						Label.Icon.ImageRectSize = asset.imageRectSize
    					else
    						Label.Icon.Image = getAssetUri(Icon)
    					end
    				else
    					Label.Icon.Image = "rbxassetid://" .. 0
    				end

    				Label.Icon.Visible = true
    			end

    			Label.Icon.ImageTransparency = 1
    			Label.BackgroundTransparency = 1
    			Label.UIStroke.Transparency = 1
    			Label.Title.TextTransparency = 1

    			TweenService:Create(Label, TweenInfo.new(0.7, Enum.EasingStyle.Exponential), {BackgroundTransparency = Color and 0.8 or 0}):Play()
    			TweenService:Create(Label.UIStroke, TweenInfo.new(0.7, Enum.EasingStyle.Exponential), {Transparency = Color and 0.7 or 0}):Play()
    			TweenService:Create(Label.Icon, TweenInfo.new(0.7, Enum.EasingStyle.Exponential), {ImageTransparency = 0.2}):Play()
    			TweenService:Create(Label.Title, TweenInfo.new(0.7, Enum.EasingStyle.Exponential), {TextTransparency = Color and 0.2 or 0}):Play()	

    			function LabelValue:Set(NewLabel, Icon, Color)
    				Label.Title.Text = NewLabel

    				if Color then
    					Label.BackgroundColor3 = Color or SelectedTheme.SecondaryElementBackground
    					Label.UIStroke.Color = Color or SelectedTheme.SecondaryElementStroke
    				end

    				if Icon and Label:FindFirstChild('Icon') then
    					Label.Title.Position = UDim2.new(0, 45, 0.5, 0)
    					Label.Title.Size = UDim2.new(1, -100, 0, 14)

    					if Icon then
    						if typeof(Icon) == 'string' and Icons then
    							local asset = getIcon(Icon)

    							Label.Icon.Image = 'rbxassetid://'..asset.id
    							Label.Icon.ImageRectOffset = asset.imageRectOffset
    							Label.Icon.ImageRectSize = asset.imageRectSize
    						else
    							Label.Icon.Image = getAssetUri(Icon)
    						end
    					else
    						Label.Icon.Image = "rbxassetid://" .. 0
    					end

    					Label.Icon.Visible = true
    				end
    			end

    			Rayfield.Main:GetPropertyChangedSignal('BackgroundColor3'):Connect(function()
    				Label.BackgroundColor3 = IgnoreTheme and (Color or Label.BackgroundColor3) or SelectedTheme.SecondaryElementBackground
    				Label.UIStroke.Color = IgnoreTheme and (Color or Label.BackgroundColor3) or SelectedTheme.SecondaryElementStroke
    			end)

    			return LabelValue
    		end

    		-- Paragraph
    		function Tab:CreateParagraph(ParagraphSettings)
    			local ParagraphValue = {}

    			local Paragraph = Elements.Template.Paragraph:Clone()
    			Paragraph.Title.Text = ParagraphSettings.Title
    			Paragraph.Content.Text = ParagraphSettings.Content
    			Paragraph.Visible = true
    			Paragraph.Parent = TabPage

    			Paragraph.BackgroundTransparency = 1
    			Paragraph.UIStroke.Transparency = 1
    			Paragraph.Title.TextTransparency = 1
    			Paragraph.Content.TextTransparency = 1

    			Paragraph.BackgroundColor3 = SelectedTheme.SecondaryElementBackground
    			Paragraph.UIStroke.Color = SelectedTheme.SecondaryElementStroke

    			TweenService:Create(Paragraph, TweenInfo.new(0.7, Enum.EasingStyle.Exponential), {BackgroundTransparency = 0}):Play()
    			TweenService:Create(Paragraph.UIStroke, TweenInfo.new(0.7, Enum.EasingStyle.Exponential), {Transparency = 0}):Play()
    			TweenService:Create(Paragraph.Title, TweenInfo.new(0.7, Enum.EasingStyle.Exponential), {TextTransparency = 0}):Play()	
    			TweenService:Create(Paragraph.Content, TweenInfo.new(0.7, Enum.EasingStyle.Exponential), {TextTransparency = 0}):Play()	

    			function ParagraphValue:Set(NewParagraphSettings)
    				Paragraph.Title.Text = NewParagraphSettings.Title
    				Paragraph.Content.Text = NewParagraphSettings.Content
    			end

    			Rayfield.Main:GetPropertyChangedSignal('BackgroundColor3'):Connect(function()
    				Paragraph.BackgroundColor3 = SelectedTheme.SecondaryElementBackground
    				Paragraph.UIStroke.Color = SelectedTheme.SecondaryElementStroke
    			end)

    			return ParagraphValue
    		end

    		-- Input
    		function Tab:CreateInput(InputSettings)
    			local Input = Elements.Template.Input:Clone()
    			Input.Name = InputSettings.Name
    			Input.Title.Text = InputSettings.Name
    			Input.Visible = true
    			Input.Parent = TabPage

    			Input.BackgroundTransparency = 1
    			Input.UIStroke.Transparency = 1
    			Input.Title.TextTransparency = 1

    			Input.InputFrame.InputBox.Text = InputSettings.CurrentValue or ''

    			Input.InputFrame.BackgroundColor3 = SelectedTheme.InputBackground
    			Input.InputFrame.UIStroke.Color = SelectedTheme.InputStroke

    			TweenService:Create(Input, TweenInfo.new(0.7, Enum.EasingStyle.Exponential), {BackgroundTransparency = 0}):Play()
    			TweenService:Create(Input.UIStroke, TweenInfo.new(0.7, Enum.EasingStyle.Exponential), {Transparency = 0}):Play()
    			TweenService:Create(Input.Title, TweenInfo.new(0.7, Enum.EasingStyle.Exponential), {TextTransparency = 0}):Play()	

    			Input.InputFrame.InputBox.PlaceholderText = InputSettings.PlaceholderText
    			Input.InputFrame.Size = UDim2.new(0, Input.InputFrame.InputBox.TextBounds.X + 24, 0, 30)

    			Input.InputFrame.InputBox.FocusLost:Connect(function()
    				local Success, Response = pcall(function()
    					InputSettings.Callback(Input.InputFrame.InputBox.Text)
    					InputSettings.CurrentValue = Input.InputFrame.InputBox.Text
    				end)

    				if not Success then
    					TweenService:Create(Input, TweenInfo.new(0.6, Enum.EasingStyle.Exponential), {BackgroundColor3 = Color3.fromRGB(85, 0, 0)}):Play()
    					TweenService:Create(Input.UIStroke, TweenInfo.new(0.6, Enum.EasingStyle.Exponential), {Transparency = 1}):Play()
    					Input.Title.Text = "Callback Error"
    					print("Rayfield | "..InputSettings.Name.." Callback Error " ..tostring(Response))
    					warn('Check docs.sirius.menu for help with Rayfield specific development.')
    					task.wait(0.5)
    					Input.Title.Text = InputSettings.Name
    					TweenService:Create(Input, TweenInfo.new(0.6, Enum.EasingStyle.Exponential), {BackgroundColor3 = SelectedTheme.ElementBackground}):Play()
    					TweenService:Create(Input.UIStroke, TweenInfo.new(0.6, Enum.EasingStyle.Exponential), {Transparency = 0}):Play()
    				end

    				if InputSettings.RemoveTextAfterFocusLost then
    					Input.InputFrame.InputBox.Text = ""
    				end

    				if not InputSettings.Ext then
    					SaveConfiguration()
    				end
    			end)

    			Input.MouseEnter:Connect(function()
    				TweenService:Create(Input, TweenInfo.new(0.6, Enum.EasingStyle.Exponential), {BackgroundColor3 = SelectedTheme.ElementBackgroundHover}):Play()
    			end)

    			Input.MouseLeave:Connect(function()
    				TweenService:Create(Input, TweenInfo.new(0.6, Enum.EasingStyle.Exponential), {BackgroundColor3 = SelectedTheme.ElementBackground}):Play()
    			end)

    			Input.InputFrame.InputBox:GetPropertyChangedSignal("Text"):Connect(function()
    				TweenService:Create(Input.InputFrame, TweenInfo.new(0.55, Enum.EasingStyle.Exponential, Enum.EasingDirection.Out), {Size = UDim2.new(0, Input.InputFrame.InputBox.TextBounds.X + 24, 0, 30)}):Play()
    			end)

    			function InputSettings:Set(text)
    				Input.InputFrame.InputBox.Text = text
    				InputSettings.CurrentValue = text

    				local Success, Response = pcall(function()
    					InputSettings.Callback(text)
    				end)

    				if not InputSettings.Ext then
    					SaveConfiguration()
    				end
    			end

    			if Settings.ConfigurationSaving then
    				if Settings.ConfigurationSaving.Enabled and InputSettings.Flag then
    					RayfieldLibrary.Flags[InputSettings.Flag] = InputSettings
    				end
    			end

    			Rayfield.Main:GetPropertyChangedSignal('BackgroundColor3'):Connect(function()
    				Input.InputFrame.BackgroundColor3 = SelectedTheme.InputBackground
    				Input.InputFrame.UIStroke.Color = SelectedTheme.InputStroke
    			end)

    			return InputSettings
    		end

    		-- Dropdown
    		function Tab:CreateDropdown(DropdownSettings)
    			local Dropdown = Elements.Template.Dropdown:Clone()
    			if string.find(DropdownSettings.Name,"closed") then
    				Dropdown.Name = "Dropdown"
    			else
    				Dropdown.Name = DropdownSettings.Name
    			end
    			Dropdown.Title.Text = DropdownSettings.Name
    			Dropdown.Visible = true
    			Dropdown.Parent = TabPage

    			Dropdown.List.Visible = false
    			if DropdownSettings.CurrentOption then
    				if type(DropdownSettings.CurrentOption) == "string" then
    					DropdownSettings.CurrentOption = {DropdownSettings.CurrentOption}
    				end
    				if not DropdownSettings.MultipleOptions and type(DropdownSettings.CurrentOption) == "table" then
    					DropdownSettings.CurrentOption = {DropdownSettings.CurrentOption[1]}
    				end
    			else
    				DropdownSettings.CurrentOption = {}
    			end

    			if DropdownSettings.MultipleOptions then
    				if DropdownSettings.CurrentOption and type(DropdownSettings.CurrentOption) == "table" then
    					if #DropdownSettings.CurrentOption == 1 then
    						Dropdown.Selected.Text = DropdownSettings.CurrentOption[1]
    					elseif #DropdownSettings.CurrentOption == 0 then
    						Dropdown.Selected.Text = "None"
    					else
    						Dropdown.Selected.Text = "Various"
    					end
    				else
    					DropdownSettings.CurrentOption = {}
    					Dropdown.Selected.Text = "None"
    				end
    			else
    				Dropdown.Selected.Text = DropdownSettings.CurrentOption[1] or "None"
    			end

    			Dropdown.Toggle.ImageColor3 = SelectedTheme.TextColor
    			TweenService:Create(Dropdown, TweenInfo.new(0.4, Enum.EasingStyle.Exponential), {BackgroundColor3 = SelectedTheme.ElementBackground}):Play()

    			Dropdown.BackgroundTransparency = 1
    			Dropdown.UIStroke.Transparency = 1
    			Dropdown.Title.TextTransparency = 1

    			Dropdown.Size = UDim2.new(1, -10, 0, 45)

    			TweenService:Create(Dropdown, TweenInfo.new(0.7, Enum.EasingStyle.Exponential), {BackgroundTransparency = 0}):Play()
    			TweenService:Create(Dropdown.UIStroke, TweenInfo.new(0.7, Enum.EasingStyle.Exponential), {Transparency = 0}):Play()
    			TweenService:Create(Dropdown.Title, TweenInfo.new(0.7, Enum.EasingStyle.Exponential), {TextTransparency = 0}):Play()	

    			for _, ununusedoption in ipairs(Dropdown.List:GetChildren()) do
    				if ununusedoption.ClassName == "Frame" and ununusedoption.Name ~= "Placeholder" then
    					ununusedoption:Destroy()
    				end
    			end

    			Dropdown.Toggle.Rotation = 180

    			Dropdown.Interact.MouseButton1Click:Connect(function()
    				TweenService:Create(Dropdown, TweenInfo.new(0.4, Enum.EasingStyle.Exponential), {BackgroundColor3 = SelectedTheme.ElementBackgroundHover}):Play()
    				TweenService:Create(Dropdown.UIStroke, TweenInfo.new(0.4, Enum.EasingStyle.Exponential), {Transparency = 1}):Play()
    				task.wait(0.1)
    				TweenService:Create(Dropdown, TweenInfo.new(0.4, Enum.EasingStyle.Exponential), {BackgroundColor3 = SelectedTheme.ElementBackground}):Play()
    				TweenService:Create(Dropdown.UIStroke, TweenInfo.new(0.4, Enum.EasingStyle.Exponential), {Transparency = 0}):Play()
    				if Debounce then return end
    				if Dropdown.List.Visible then
    					Debounce = true
    					TweenService:Create(Dropdown, TweenInfo.new(0.5, Enum.EasingStyle.Exponential), {Size = UDim2.new(1, -10, 0, 45)}):Play()
    					for _, DropdownOpt in ipairs(Dropdown.List:GetChildren()) do
    						if DropdownOpt.ClassName == "Frame" and DropdownOpt.Name ~= "Placeholder" then
    							TweenService:Create(DropdownOpt, TweenInfo.new(0.3, Enum.EasingStyle.Exponential), {BackgroundTransparency = 1}):Play()
    							TweenService:Create(DropdownOpt.UIStroke, TweenInfo.new(0.3, Enum.EasingStyle.Exponential), {Transparency = 1}):Play()
    							TweenService:Create(DropdownOpt.Title, TweenInfo.new(0.3, Enum.EasingStyle.Exponential), {TextTransparency = 1}):Play()
    						end
    					end
    					TweenService:Create(Dropdown.List, TweenInfo.new(0.3, Enum.EasingStyle.Exponential), {ScrollBarImageTransparency = 1}):Play()
    					TweenService:Create(Dropdown.Toggle, TweenInfo.new(0.7, Enum.EasingStyle.Exponential), {Rotation = 180}):Play()	
    					task.wait(0.35)
    					Dropdown.List.Visible = false
    					Debounce = false
    				else
    					TweenService:Create(Dropdown, TweenInfo.new(0.5, Enum.EasingStyle.Exponential), {Size = UDim2.new(1, -10, 0, 180)}):Play()
    					Dropdown.List.Visible = true
    					TweenService:Create(Dropdown.List, TweenInfo.new(0.3, Enum.EasingStyle.Exponential), {ScrollBarImageTransparency = 0.7}):Play()
    					TweenService:Create(Dropdown.Toggle, TweenInfo.new(0.7, Enum.EasingStyle.Exponential), {Rotation = 0}):Play()	
    					for _, DropdownOpt in ipairs(Dropdown.List:GetChildren()) do
    						if DropdownOpt.ClassName == "Frame" and DropdownOpt.Name ~= "Placeholder" then
    							if DropdownOpt.Name ~= Dropdown.Selected.Text then
    								TweenService:Create(DropdownOpt.UIStroke, TweenInfo.new(0.3, Enum.EasingStyle.Exponential), {Transparency = 0}):Play()
    							end
    							TweenService:Create(DropdownOpt, TweenInfo.new(0.3, Enum.EasingStyle.Exponential), {BackgroundTransparency = 0}):Play()
    							TweenService:Create(DropdownOpt.Title, TweenInfo.new(0.3, Enum.EasingStyle.Exponential), {TextTransparency = 0}):Play()
    						end
    					end
    				end
    			end)

    			Dropdown.MouseEnter:Connect(function()
    				if not Dropdown.List.Visible then
    					TweenService:Create(Dropdown, TweenInfo.new(0.6, Enum.EasingStyle.Exponential), {BackgroundColor3 = SelectedTheme.ElementBackgroundHover}):Play()
    				end
    			end)

    			Dropdown.MouseLeave:Connect(function()
    				TweenService:Create(Dropdown, TweenInfo.new(0.6, Enum.EasingStyle.Exponential), {BackgroundColor3 = SelectedTheme.ElementBackground}):Play()
    			end)

    			local function SetDropdownOptions()
    				for _, Option in ipairs(DropdownSettings.Options) do
    					local DropdownOption = Elements.Template.Dropdown.List.Template:Clone()
    					DropdownOption.Name = Option
    					DropdownOption.Title.Text = Option
    					DropdownOption.Parent = Dropdown.List
    					DropdownOption.Visible = true

    					DropdownOption.BackgroundTransparency = 1
    					DropdownOption.UIStroke.Transparency = 1
    					DropdownOption.Title.TextTransparency = 1

    					--local Dropdown = Tab:CreateDropdown({
    					--	Name = "Dropdown Example",
    					--	Options = {"Option 1","Option 2"},
    					--	CurrentOption = {"Option 1"},
    					--  MultipleOptions = true,
    					--	Flag = "Dropdown1",
    					--	Callback = function(TableOfOptions)

    					--	end,
    					--})


    					DropdownOption.Interact.ZIndex = 50
    					DropdownOption.Interact.MouseButton1Click:Connect(function()
    						if not DropdownSettings.MultipleOptions and table.find(DropdownSettings.CurrentOption, Option) then 
    							return
    						end

    						if table.find(DropdownSettings.CurrentOption, Option) then
    							table.remove(DropdownSettings.CurrentOption, table.find(DropdownSettings.CurrentOption, Option))
    							if DropdownSettings.MultipleOptions then
    								if #DropdownSettings.CurrentOption == 1 then
    									Dropdown.Selected.Text = DropdownSettings.CurrentOption[1]
    								elseif #DropdownSettings.CurrentOption == 0 then
    									Dropdown.Selected.Text = "None"
    								else
    									Dropdown.Selected.Text = "Various"
    								end
    							else
    								Dropdown.Selected.Text = DropdownSettings.CurrentOption[1]
    							end
    						else
    							if not DropdownSettings.MultipleOptions then
    								table.clear(DropdownSettings.CurrentOption)
    							end
    							table.insert(DropdownSettings.CurrentOption, Option)
    							if DropdownSettings.MultipleOptions then
    								if #DropdownSettings.CurrentOption == 1 then
    									Dropdown.Selected.Text = DropdownSettings.CurrentOption[1]
    								elseif #DropdownSettings.CurrentOption == 0 then
    									Dropdown.Selected.Text = "None"
    								else
    									Dropdown.Selected.Text = "Various"
    								end
    							else
    								Dropdown.Selected.Text = DropdownSettings.CurrentOption[1]
    							end
    							TweenService:Create(DropdownOption.UIStroke, TweenInfo.new(0.3, Enum.EasingStyle.Exponential), {Transparency = 1}):Play()
    							TweenService:Create(DropdownOption, TweenInfo.new(0.3, Enum.EasingStyle.Exponential), {BackgroundColor3 = SelectedTheme.DropdownSelected}):Play()
    							Debounce = true
    						end


    						local Success, Response = pcall(function()
    							DropdownSettings.Callback(DropdownSettings.CurrentOption)
    						end)

    						if not Success then
    							TweenService:Create(Dropdown, TweenInfo.new(0.6, Enum.EasingStyle.Exponential), {BackgroundColor3 = Color3.fromRGB(85, 0, 0)}):Play()
    							TweenService:Create(Dropdown.UIStroke, TweenInfo.new(0.6, Enum.EasingStyle.Exponential), {Transparency = 1}):Play()
    							Dropdown.Title.Text = "Callback Error"
    							print("Rayfield | "..DropdownSettings.Name.." Callback Error " ..tostring(Response))
    							warn('Check docs.sirius.menu for help with Rayfield specific development.')
    							task.wait(0.5)
    							Dropdown.Title.Text = DropdownSettings.Name
    							TweenService:Create(Dropdown, TweenInfo.new(0.6, Enum.EasingStyle.Exponential), {BackgroundColor3 = SelectedTheme.ElementBackground}):Play()
    							TweenService:Create(Dropdown.UIStroke, TweenInfo.new(0.6, Enum.EasingStyle.Exponential), {Transparency = 0}):Play()
    						end

    						for _, droption in ipairs(Dropdown.List:GetChildren()) do
    							if droption.ClassName == "Frame" and droption.Name ~= "Placeholder" and not table.find(DropdownSettings.CurrentOption, droption.Name) then
    								TweenService:Create(droption, TweenInfo.new(0.3, Enum.EasingStyle.Exponential), {BackgroundColor3 = SelectedTheme.DropdownUnselected}):Play()
    							end
    						end
    						if not DropdownSettings.MultipleOptions then
    							task.wait(0.1)
    							TweenService:Create(Dropdown, TweenInfo.new(0.5, Enum.EasingStyle.Exponential), {Size = UDim2.new(1, -10, 0, 45)}):Play()
    							for _, DropdownOpt in ipairs(Dropdown.List:GetChildren()) do
    								if DropdownOpt.ClassName == "Frame" and DropdownOpt.Name ~= "Placeholder" then
    									TweenService:Create(DropdownOpt, TweenInfo.new(0.3, Enum.EasingStyle.Exponential), {BackgroundTransparency = 1}):Play()
    									TweenService:Create(DropdownOpt.UIStroke, TweenInfo.new(0.3, Enum.EasingStyle.Exponential), {Transparency = 1}):Play()
    									TweenService:Create(DropdownOpt.Title, TweenInfo.new(0.3, Enum.EasingStyle.Exponential), {TextTransparency = 1}):Play()
    								end
    							end
    							TweenService:Create(Dropdown.List, TweenInfo.new(0.3, Enum.EasingStyle.Exponential), {ScrollBarImageTransparency = 1}):Play()
    							TweenService:Create(Dropdown.Toggle, TweenInfo.new(0.7, Enum.EasingStyle.Exponential), {Rotation = 180}):Play()	
    							task.wait(0.35)
    							Dropdown.List.Visible = false
    						end
    						Debounce = false
    						if not DropdownSettings.Ext then
    							SaveConfiguration()
    						end
    					end)

    					Rayfield.Main:GetPropertyChangedSignal('BackgroundColor3'):Connect(function()
    						DropdownOption.UIStroke.Color = SelectedTheme.ElementStroke
    					end)
    				end
    			end
    			SetDropdownOptions()

    			for _, droption in ipairs(Dropdown.List:GetChildren()) do
    				if droption.ClassName == "Frame" and droption.Name ~= "Placeholder" then
    					if not table.find(DropdownSettings.CurrentOption, droption.Name) then
    						droption.BackgroundColor3 = SelectedTheme.DropdownUnselected
    					else
    						droption.BackgroundColor3 = SelectedTheme.DropdownSelected
    					end

    					Rayfield.Main:GetPropertyChangedSignal('BackgroundColor3'):Connect(function()
    						if not table.find(DropdownSettings.CurrentOption, droption.Name) then
    							droption.BackgroundColor3 = SelectedTheme.DropdownUnselected
    						else
    							droption.BackgroundColor3 = SelectedTheme.DropdownSelected
    						end
    					end)
    				end
    			end

    			function DropdownSettings:Set(NewOption)
    				DropdownSettings.CurrentOption = NewOption

    				if typeof(DropdownSettings.CurrentOption) == "string" then
    					DropdownSettings.CurrentOption = {DropdownSettings.CurrentOption}
    				end

    				if not DropdownSettings.MultipleOptions then
    					DropdownSettings.CurrentOption = {DropdownSettings.CurrentOption[1]}
    				end

    				if DropdownSettings.MultipleOptions then
    					if #DropdownSettings.CurrentOption == 1 then
    						Dropdown.Selected.Text = DropdownSettings.CurrentOption[1]
    					elseif #DropdownSettings.CurrentOption == 0 then
    						Dropdown.Selected.Text = "None"
    					else
    						Dropdown.Selected.Text = "Various"
    					end
    				else
    					Dropdown.Selected.Text = DropdownSettings.CurrentOption[1]
    				end


    				local Success, Response = pcall(function()
    					DropdownSettings.Callback(NewOption)
    				end)
    				if not Success then
    					TweenService:Create(Dropdown, TweenInfo.new(0.6, Enum.EasingStyle.Exponential), {BackgroundColor3 = Color3.fromRGB(85, 0, 0)}):Play()
    					TweenService:Create(Dropdown.UIStroke, TweenInfo.new(0.6, Enum.EasingStyle.Exponential), {Transparency = 1}):Play()
    					Dropdown.Title.Text = "Callback Error"
    					print("Rayfield | "..DropdownSettings.Name.." Callback Error " ..tostring(Response))
    					warn('Check docs.sirius.menu for help with Rayfield specific development.')
    					task.wait(0.5)
    					Dropdown.Title.Text = DropdownSettings.Name
    					TweenService:Create(Dropdown, TweenInfo.new(0.6, Enum.EasingStyle.Exponential), {BackgroundColor3 = SelectedTheme.ElementBackground}):Play()
    					TweenService:Create(Dropdown.UIStroke, TweenInfo.new(0.6, Enum.EasingStyle.Exponential), {Transparency = 0}):Play()
    				end

    				for _, droption in ipairs(Dropdown.List:GetChildren()) do
    					if droption.ClassName == "Frame" and droption.Name ~= "Placeholder" then
    						if not table.find(DropdownSettings.CurrentOption, droption.Name) then
    							droption.BackgroundColor3 = SelectedTheme.DropdownUnselected
    						else
    							droption.BackgroundColor3 = SelectedTheme.DropdownSelected
    						end
    					end
    				end
    				--SaveConfiguration()
    			end

    			function DropdownSettings:Refresh(optionsTable: table) -- updates a dropdown with new options from optionsTable
    				DropdownSettings.Options = optionsTable
    				for _, option in Dropdown.List:GetChildren() do
    					if option.ClassName == "Frame" and option.Name ~= "Placeholder" then
    						option:Destroy()
    					end
    				end
    				SetDropdownOptions()
    			end

    			if Settings.ConfigurationSaving then
    				if Settings.ConfigurationSaving.Enabled and DropdownSettings.Flag then
    					RayfieldLibrary.Flags[DropdownSettings.Flag] = DropdownSettings
    				end
    			end

    			Rayfield.Main:GetPropertyChangedSignal('BackgroundColor3'):Connect(function()
    				Dropdown.Toggle.ImageColor3 = SelectedTheme.TextColor
    				TweenService:Create(Dropdown, TweenInfo.new(0.4, Enum.EasingStyle.Exponential), {BackgroundColor3 = SelectedTheme.ElementBackground}):Play()
    			end)

    			return DropdownSettings
    		end

    		-- Keybind
    		function Tab:CreateKeybind(KeybindSettings)
    			local CheckingForKey = false
    			local Keybind = Elements.Template.Keybind:Clone()
    			Keybind.Name = KeybindSettings.Name
    			Keybind.Title.Text = KeybindSettings.Name
    			Keybind.Visible = true
    			Keybind.Parent = TabPage

    			Keybind.BackgroundTransparency = 1
    			Keybind.UIStroke.Transparency = 1
    			Keybind.Title.TextTransparency = 1

    			Keybind.KeybindFrame.BackgroundColor3 = SelectedTheme.InputBackground
    			Keybind.KeybindFrame.UIStroke.Color = SelectedTheme.InputStroke

    			TweenService:Create(Keybind, TweenInfo.new(0.7, Enum.EasingStyle.Exponential), {BackgroundTransparency = 0}):Play()
    			TweenService:Create(Keybind.UIStroke, TweenInfo.new(0.7, Enum.EasingStyle.Exponential), {Transparency = 0}):Play()
    			TweenService:Create(Keybind.Title, TweenInfo.new(0.7, Enum.EasingStyle.Exponential), {TextTransparency = 0}):Play()	

    			Keybind.KeybindFrame.KeybindBox.Text = KeybindSettings.CurrentKeybind
    			Keybind.KeybindFrame.Size = UDim2.new(0, Keybind.KeybindFrame.KeybindBox.TextBounds.X + 24, 0, 30)

    			Keybind.KeybindFrame.KeybindBox.Focused:Connect(function()
    				CheckingForKey = true
    				Keybind.KeybindFrame.KeybindBox.Text = ""
    			end)
    			Keybind.KeybindFrame.KeybindBox.FocusLost:Connect(function()
    				CheckingForKey = false
    				if Keybind.KeybindFrame.KeybindBox.Text == nil or Keybind.KeybindFrame.KeybindBox.Text == "" then
    					Keybind.KeybindFrame.KeybindBox.Text = KeybindSettings.CurrentKeybind
    					if not KeybindSettings.Ext then
    						SaveConfiguration()
    					end
    				end
    			end)

    			Keybind.MouseEnter:Connect(function()
    				TweenService:Create(Keybind, TweenInfo.new(0.6, Enum.EasingStyle.Exponential), {BackgroundColor3 = SelectedTheme.ElementBackgroundHover}):Play()
    			end)

    			Keybind.MouseLeave:Connect(function()
    				TweenService:Create(Keybind, TweenInfo.new(0.6, Enum.EasingStyle.Exponential), {BackgroundColor3 = SelectedTheme.ElementBackground}):Play()
    			end)

    			UserInputService.InputBegan:Connect(function(input, processed)
    				if CheckingForKey then
    					if input.KeyCode ~= Enum.KeyCode.Unknown then
    						local SplitMessage = string.split(tostring(input.KeyCode), ".")
    						local NewKeyNoEnum = SplitMessage[3]
    						Keybind.KeybindFrame.KeybindBox.Text = tostring(NewKeyNoEnum)
    						KeybindSettings.CurrentKeybind = tostring(NewKeyNoEnum)
    						Keybind.KeybindFrame.KeybindBox:ReleaseFocus()
    						if not KeybindSettings.Ext then
    							SaveConfiguration()
    						end

    						if KeybindSettings.CallOnChange then
    							KeybindSettings.Callback(tostring(NewKeyNoEnum))
    						end
    					end
    				elseif not KeybindSettings.CallOnChange and KeybindSettings.CurrentKeybind ~= nil and (input.KeyCode == Enum.KeyCode[KeybindSettings.CurrentKeybind] and not processed) then -- Test
    					local Held = true
    					local Connection
    					Connection = input.Changed:Connect(function(prop)
    						if prop == "UserInputState" then
    							Connection:Disconnect()
    							Held = false
    						end
    					end)

    					if not KeybindSettings.HoldToInteract then
    						local Success, Response = pcall(KeybindSettings.Callback)
    						if not Success then
    							TweenService:Create(Keybind, TweenInfo.new(0.6, Enum.EasingStyle.Exponential), {BackgroundColor3 = Color3.fromRGB(85, 0, 0)}):Play()
    							TweenService:Create(Keybind.UIStroke, TweenInfo.new(0.6, Enum.EasingStyle.Exponential), {Transparency = 1}):Play()
    							Keybind.Title.Text = "Callback Error"
    							print("Rayfield | "..KeybindSettings.Name.." Callback Error " ..tostring(Response))
    							warn('Check docs.sirius.menu for help with Rayfield specific development.')
    							task.wait(0.5)
    							Keybind.Title.Text = KeybindSettings.Name
    							TweenService:Create(Keybind, TweenInfo.new(0.6, Enum.EasingStyle.Exponential), {BackgroundColor3 = SelectedTheme.ElementBackground}):Play()
    							TweenService:Create(Keybind.UIStroke, TweenInfo.new(0.6, Enum.EasingStyle.Exponential), {Transparency = 0}):Play()
    						end
    					else
    						task.wait(0.25)
    						if Held then
    							local Loop; Loop = RunService.Stepped:Connect(function()
    								if not Held then
    									KeybindSettings.Callback(false) -- maybe pcall this
    									Loop:Disconnect()
    								else
    									KeybindSettings.Callback(true) -- maybe pcall this
    								end
    							end)
    						end
    					end
    				end
    			end)

    			Keybind.KeybindFrame.KeybindBox:GetPropertyChangedSignal("Text"):Connect(function()
    				TweenService:Create(Keybind.KeybindFrame, TweenInfo.new(0.55, Enum.EasingStyle.Exponential, Enum.EasingDirection.Out), {Size = UDim2.new(0, Keybind.KeybindFrame.KeybindBox.TextBounds.X + 24, 0, 30)}):Play()
    			end)

    			function KeybindSettings:Set(NewKeybind)
    				Keybind.KeybindFrame.KeybindBox.Text = tostring(NewKeybind)
    				KeybindSettings.CurrentKeybind = tostring(NewKeybind)
    				Keybind.KeybindFrame.KeybindBox:ReleaseFocus()
    				if not KeybindSettings.Ext then
    					SaveConfiguration()
    				end

    				if KeybindSettings.CallOnChange then
    					KeybindSettings.Callback(tostring(NewKeybind))
    				end
    			end

    			if Settings.ConfigurationSaving then
    				if Settings.ConfigurationSaving.Enabled and KeybindSettings.Flag then
    					RayfieldLibrary.Flags[KeybindSettings.Flag] = KeybindSettings
    				end
    			end

    			Rayfield.Main:GetPropertyChangedSignal('BackgroundColor3'):Connect(function()
    				Keybind.KeybindFrame.BackgroundColor3 = SelectedTheme.InputBackground
    				Keybind.KeybindFrame.UIStroke.Color = SelectedTheme.InputStroke
    			end)

    			return KeybindSettings
    		end

    		-- Toggle
    		function Tab:CreateToggle(ToggleSettings)
    			local ToggleValue = {}

    			local Toggle = Elements.Template.Toggle:Clone()
    			Toggle.Name = ToggleSettings.Name
    			Toggle.Title.Text = ToggleSettings.Name
    			Toggle.Visible = true
    			Toggle.Parent = TabPage

    			Toggle.BackgroundTransparency = 1
    			Toggle.UIStroke.Transparency = 1
    			Toggle.Title.TextTransparency = 1
    			Toggle.Switch.BackgroundColor3 = SelectedTheme.ToggleBackground

    			if SelectedTheme ~= RayfieldLibrary.Theme.Default then
    				Toggle.Switch.Shadow.Visible = false
    			end

    			TweenService:Create(Toggle, TweenInfo.new(0.7, Enum.EasingStyle.Exponential), {BackgroundTransparency = 0}):Play()
    			TweenService:Create(Toggle.UIStroke, TweenInfo.new(0.7, Enum.EasingStyle.Exponential), {Transparency = 0}):Play()
    			TweenService:Create(Toggle.Title, TweenInfo.new(0.7, Enum.EasingStyle.Exponential), {TextTransparency = 0}):Play()	

    			if ToggleSettings.CurrentValue == true then
    				Toggle.Switch.Indicator.Position = UDim2.new(1, -20, 0.5, 0)
    				Toggle.Switch.Indicator.UIStroke.Color = SelectedTheme.ToggleEnabledStroke
    				Toggle.Switch.Indicator.BackgroundColor3 = SelectedTheme.ToggleEnabled
    				Toggle.Switch.UIStroke.Color = SelectedTheme.ToggleEnabledOuterStroke
    			else
    				Toggle.Switch.Indicator.Position = UDim2.new(1, -40, 0.5, 0)
    				Toggle.Switch.Indicator.UIStroke.Color = SelectedTheme.ToggleDisabledStroke
    				Toggle.Switch.Indicator.BackgroundColor3 = SelectedTheme.ToggleDisabled
    				Toggle.Switch.UIStroke.Color = SelectedTheme.ToggleDisabledOuterStroke
    			end

    			Toggle.MouseEnter:Connect(function()
    				TweenService:Create(Toggle, TweenInfo.new(0.6, Enum.EasingStyle.Exponential), {BackgroundColor3 = SelectedTheme.ElementBackgroundHover}):Play()
    			end)

    			Toggle.MouseLeave:Connect(function()
    				TweenService:Create(Toggle, TweenInfo.new(0.6, Enum.EasingStyle.Exponential), {BackgroundColor3 = SelectedTheme.ElementBackground}):Play()
    			end)

    			Toggle.Interact.MouseButton1Click:Connect(function()
    				if ToggleSettings.CurrentValue == true then
    					ToggleSettings.CurrentValue = false
    					TweenService:Create(Toggle, TweenInfo.new(0.6, Enum.EasingStyle.Exponential), {BackgroundColor3 = SelectedTheme.ElementBackgroundHover}):Play()
    					TweenService:Create(Toggle.UIStroke, TweenInfo.new(0.6, Enum.EasingStyle.Exponential), {Transparency = 1}):Play()
    					TweenService:Create(Toggle.Switch.Indicator, TweenInfo.new(0.45, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), {Position = UDim2.new(1, -40, 0.5, 0)}):Play()
    					TweenService:Create(Toggle.Switch.Indicator.UIStroke, TweenInfo.new(0.55, Enum.EasingStyle.Exponential, Enum.EasingDirection.Out), {Color = SelectedTheme.ToggleDisabledStroke}):Play()
    					TweenService:Create(Toggle.Switch.Indicator, TweenInfo.new(0.8, Enum.EasingStyle.Exponential, Enum.EasingDirection.Out), {BackgroundColor3 = SelectedTheme.ToggleDisabled}):Play()
    					TweenService:Create(Toggle.Switch.UIStroke, TweenInfo.new(0.55, Enum.EasingStyle.Exponential, Enum.EasingDirection.Out), {Color = SelectedTheme.ToggleDisabledOuterStroke}):Play()
    					TweenService:Create(Toggle, TweenInfo.new(0.6, Enum.EasingStyle.Exponential), {BackgroundColor3 = SelectedTheme.ElementBackground}):Play()
    					TweenService:Create(Toggle.UIStroke, TweenInfo.new(0.6, Enum.EasingStyle.Exponential), {Transparency = 0}):Play()	
    				else
    					ToggleSettings.CurrentValue = true
    					TweenService:Create(Toggle, TweenInfo.new(0.6, Enum.EasingStyle.Exponential), {BackgroundColor3 = SelectedTheme.ElementBackgroundHover}):Play()
    					TweenService:Create(Toggle.UIStroke, TweenInfo.new(0.6, Enum.EasingStyle.Exponential), {Transparency = 1}):Play()
    					TweenService:Create(Toggle.Switch.Indicator, TweenInfo.new(0.5, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), {Position = UDim2.new(1, -20, 0.5, 0)}):Play()
    					TweenService:Create(Toggle.Switch.Indicator.UIStroke, TweenInfo.new(0.55, Enum.EasingStyle.Exponential, Enum.EasingDirection.Out), {Color = SelectedTheme.ToggleEnabledStroke}):Play()
    					TweenService:Create(Toggle.Switch.Indicator, TweenInfo.new(0.8, Enum.EasingStyle.Exponential, Enum.EasingDirection.Out), {BackgroundColor3 = SelectedTheme.ToggleEnabled}):Play()
    					TweenService:Create(Toggle.Switch.UIStroke, TweenInfo.new(0.55, Enum.EasingStyle.Exponential, Enum.EasingDirection.Out), {Color = SelectedTheme.ToggleEnabledOuterStroke}):Play()
    					TweenService:Create(Toggle, TweenInfo.new(0.6, Enum.EasingStyle.Exponential), {BackgroundColor3 = SelectedTheme.ElementBackground}):Play()
    					TweenService:Create(Toggle.UIStroke, TweenInfo.new(0.6, Enum.EasingStyle.Exponential), {Transparency = 0}):Play()		
    				end

    				local Success, Response = pcall(function()
    					if debugX then warn('Running toggle \''..ToggleSettings.Name..'\' (Interact)') end

    					ToggleSettings.Callback(ToggleSettings.CurrentValue)
    				end)

    				if not Success then
    					TweenService:Create(Toggle, TweenInfo.new(0.6, Enum.EasingStyle.Exponential), {BackgroundColor3 = Color3.fromRGB(85, 0, 0)}):Play()
    					TweenService:Create(Toggle.UIStroke, TweenInfo.new(0.6, Enum.EasingStyle.Exponential), {Transparency = 1}):Play()
    					Toggle.Title.Text = "Callback Error"
    					print("Rayfield | "..ToggleSettings.Name.." Callback Error " ..tostring(Response))
    					warn('Check docs.sirius.menu for help with Rayfield specific development.')
    					task.wait(0.5)
    					Toggle.Title.Text = ToggleSettings.Name
    					TweenService:Create(Toggle, TweenInfo.new(0.6, Enum.EasingStyle.Exponential), {BackgroundColor3 = SelectedTheme.ElementBackground}):Play()
    					TweenService:Create(Toggle.UIStroke, TweenInfo.new(0.6, Enum.EasingStyle.Exponential), {Transparency = 0}):Play()
    				end

    				if not ToggleSettings.Ext then
    					SaveConfiguration()
    				end
    			end)

    			function ToggleSettings:Set(NewToggleValue)
    				if NewToggleValue == true then
    					ToggleSettings.CurrentValue = true
    					TweenService:Create(Toggle, TweenInfo.new(0.6, Enum.EasingStyle.Exponential), {BackgroundColor3 = SelectedTheme.ElementBackgroundHover}):Play()
    					TweenService:Create(Toggle.UIStroke, TweenInfo.new(0.6, Enum.EasingStyle.Exponential), {Transparency = 1}):Play()
    					TweenService:Create(Toggle.Switch.Indicator, TweenInfo.new(0.5, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), {Position = UDim2.new(1, -20, 0.5, 0)}):Play()
    					TweenService:Create(Toggle.Switch.Indicator, TweenInfo.new(0.4, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), {Size = UDim2.new(0,12,0,12)}):Play()
    					TweenService:Create(Toggle.Switch.Indicator.UIStroke, TweenInfo.new(0.55, Enum.EasingStyle.Exponential, Enum.EasingDirection.Out), {Color = SelectedTheme.ToggleEnabledStroke}):Play()
    					TweenService:Create(Toggle.Switch.Indicator, TweenInfo.new(0.8, Enum.EasingStyle.Exponential, Enum.EasingDirection.Out), {BackgroundColor3 = SelectedTheme.ToggleEnabled}):Play()
    					TweenService:Create(Toggle.Switch.UIStroke, TweenInfo.new(0.55, Enum.EasingStyle.Exponential, Enum.EasingDirection.Out), {Color = SelectedTheme.ToggleEnabledOuterStroke}):Play()
    					TweenService:Create(Toggle.Switch.Indicator, TweenInfo.new(0.45, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), {Size = UDim2.new(0,17,0,17)}):Play()	
    					TweenService:Create(Toggle, TweenInfo.new(0.6, Enum.EasingStyle.Exponential), {BackgroundColor3 = SelectedTheme.ElementBackground}):Play()
    					TweenService:Create(Toggle.UIStroke, TweenInfo.new(0.6, Enum.EasingStyle.Exponential), {Transparency = 0}):Play()	
    				else
    					ToggleSettings.CurrentValue = false
    					TweenService:Create(Toggle, TweenInfo.new(0.6, Enum.EasingStyle.Exponential), {BackgroundColor3 = SelectedTheme.ElementBackgroundHover}):Play()
    					TweenService:Create(Toggle.UIStroke, TweenInfo.new(0.6, Enum.EasingStyle.Exponential), {Transparency = 1}):Play()
    					TweenService:Create(Toggle.Switch.Indicator, TweenInfo.new(0.45, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), {Position = UDim2.new(1, -40, 0.5, 0)}):Play()
    					TweenService:Create(Toggle.Switch.Indicator, TweenInfo.new(0.4, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), {Size = UDim2.new(0,12,0,12)}):Play()
    					TweenService:Create(Toggle.Switch.Indicator.UIStroke, TweenInfo.new(0.55, Enum.EasingStyle.Exponential, Enum.EasingDirection.Out), {Color = SelectedTheme.ToggleDisabledStroke}):Play()
    					TweenService:Create(Toggle.Switch.Indicator, TweenInfo.new(0.8, Enum.EasingStyle.Exponential, Enum.EasingDirection.Out), {BackgroundColor3 = SelectedTheme.ToggleDisabled}):Play()
    					TweenService:Create(Toggle.Switch.UIStroke, TweenInfo.new(0.55, Enum.EasingStyle.Exponential, Enum.EasingDirection.Out), {Color = SelectedTheme.ToggleDisabledOuterStroke}):Play()
    					TweenService:Create(Toggle.Switch.Indicator, TweenInfo.new(0.4, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), {Size = UDim2.new(0,17,0,17)}):Play()
    					TweenService:Create(Toggle, TweenInfo.new(0.6, Enum.EasingStyle.Exponential), {BackgroundColor3 = SelectedTheme.ElementBackground}):Play()
    					TweenService:Create(Toggle.UIStroke, TweenInfo.new(0.6, Enum.EasingStyle.Exponential), {Transparency = 0}):Play()	
    				end

    				local Success, Response = pcall(function()
    					if debugX then warn('Running toggle \''..ToggleSettings.Name..'\' (:Set)') end

    					ToggleSettings.Callback(ToggleSettings.CurrentValue)
    				end)

    				if not Success then
    					TweenService:Create(Toggle, TweenInfo.new(0.6, Enum.EasingStyle.Exponential), {BackgroundColor3 = Color3.fromRGB(85, 0, 0)}):Play()
    					TweenService:Create(Toggle.UIStroke, TweenInfo.new(0.6, Enum.EasingStyle.Exponential), {Transparency = 1}):Play()
    					Toggle.Title.Text = "Callback Error"
    					print("Rayfield | "..ToggleSettings.Name.." Callback Error " ..tostring(Response))
    					warn('Check docs.sirius.menu for help with Rayfield specific development.')
    					task.wait(0.5)
    					Toggle.Title.Text = ToggleSettings.Name
    					TweenService:Create(Toggle, TweenInfo.new(0.6, Enum.EasingStyle.Exponential), {BackgroundColor3 = SelectedTheme.ElementBackground}):Play()
    					TweenService:Create(Toggle.UIStroke, TweenInfo.new(0.6, Enum.EasingStyle.Exponential), {Transparency = 0}):Play()
    				end

    				if not ToggleSettings.Ext then
    					SaveConfiguration()
    				end
    			end

    			if not ToggleSettings.Ext then
    				if Settings.ConfigurationSaving then
    					if Settings.ConfigurationSaving.Enabled and ToggleSettings.Flag then
    						RayfieldLibrary.Flags[ToggleSettings.Flag] = ToggleSettings
    					end
    				end
    			end


    			Rayfield.Main:GetPropertyChangedSignal('BackgroundColor3'):Connect(function()
    				Toggle.Switch.BackgroundColor3 = SelectedTheme.ToggleBackground

    				if SelectedTheme ~= RayfieldLibrary.Theme.Default then
    					Toggle.Switch.Shadow.Visible = false
    				end

    				task.wait()

    				if not ToggleSettings.CurrentValue then
    					Toggle.Switch.Indicator.UIStroke.Color = SelectedTheme.ToggleDisabledStroke
    					Toggle.Switch.Indicator.BackgroundColor3 = SelectedTheme.ToggleDisabled
    					Toggle.Switch.UIStroke.Color = SelectedTheme.ToggleDisabledOuterStroke
    				else
    					Toggle.Switch.Indicator.UIStroke.Color = SelectedTheme.ToggleEnabledStroke
    					Toggle.Switch.Indicator.BackgroundColor3 = SelectedTheme.ToggleEnabled
    					Toggle.Switch.UIStroke.Color = SelectedTheme.ToggleEnabledOuterStroke
    				end
    			end)

    			return ToggleSettings
    		end

    		-- Slider
    		function Tab:CreateSlider(SliderSettings)
    			local SLDragging = false
    			local Slider = Elements.Template.Slider:Clone()
    			Slider.Name = SliderSettings.Name
    			Slider.Title.Text = SliderSettings.Name
    			Slider.Visible = true
    			Slider.Parent = TabPage

    			Slider.BackgroundTransparency = 1
    			Slider.UIStroke.Transparency = 1
    			Slider.Title.TextTransparency = 1

    			if SelectedTheme ~= RayfieldLibrary.Theme.Default then
    				Slider.Main.Shadow.Visible = false
    			end

    			Slider.Main.BackgroundColor3 = SelectedTheme.SliderBackground
    			Slider.Main.UIStroke.Color = SelectedTheme.SliderStroke
    			Slider.Main.Progress.UIStroke.Color = SelectedTheme.SliderStroke
    			Slider.Main.Progress.BackgroundColor3 = SelectedTheme.SliderProgress

    			TweenService:Create(Slider, TweenInfo.new(0.7, Enum.EasingStyle.Exponential), {BackgroundTransparency = 0}):Play()
    			TweenService:Create(Slider.UIStroke, TweenInfo.new(0.7, Enum.EasingStyle.Exponential), {Transparency = 0}):Play()
    			TweenService:Create(Slider.Title, TweenInfo.new(0.7, Enum.EasingStyle.Exponential), {TextTransparency = 0}):Play()	

    			Slider.Main.Progress.Size =	UDim2.new(0, Slider.Main.AbsoluteSize.X * ((SliderSettings.CurrentValue + SliderSettings.Range[1]) / (SliderSettings.Range[2] - SliderSettings.Range[1])) > 5 and Slider.Main.AbsoluteSize.X * (SliderSettings.CurrentValue / (SliderSettings.Range[2] - SliderSettings.Range[1])) or 5, 1, 0)

    			if not SliderSettings.Suffix then
    				Slider.Main.Information.Text = tostring(SliderSettings.CurrentValue)
    			else
    				Slider.Main.Information.Text = tostring(SliderSettings.CurrentValue) .. " " .. SliderSettings.Suffix
    			end

    			Slider.MouseEnter:Connect(function()
    				TweenService:Create(Slider, TweenInfo.new(0.6, Enum.EasingStyle.Exponential), {BackgroundColor3 = SelectedTheme.ElementBackgroundHover}):Play()
    			end)

    			Slider.MouseLeave:Connect(function()
    				TweenService:Create(Slider, TweenInfo.new(0.6, Enum.EasingStyle.Exponential), {BackgroundColor3 = SelectedTheme.ElementBackground}):Play()
    			end)

    			Slider.Main.Interact.InputBegan:Connect(function(Input)
    				if Input.UserInputType == Enum.UserInputType.MouseButton1 or Input.UserInputType == Enum.UserInputType.Touch then 
    					TweenService:Create(Slider.Main.UIStroke, TweenInfo.new(0.6, Enum.EasingStyle.Exponential), {Transparency = 1}):Play()
    					TweenService:Create(Slider.Main.Progress.UIStroke, TweenInfo.new(0.6, Enum.EasingStyle.Exponential), {Transparency = 1}):Play()
    					SLDragging = true 
    				end 
    			end)

    			Slider.Main.Interact.InputEnded:Connect(function(Input) 
    				if Input.UserInputType == Enum.UserInputType.MouseButton1 or Input.UserInputType == Enum.UserInputType.Touch then 
    					TweenService:Create(Slider.Main.UIStroke, TweenInfo.new(0.6, Enum.EasingStyle.Exponential), {Transparency = 0.4}):Play()
    					TweenService:Create(Slider.Main.Progress.UIStroke, TweenInfo.new(0.6, Enum.EasingStyle.Exponential), {Transparency = 0.3}):Play()
    					SLDragging = false 
    				end 
    			end)

    			Slider.Main.Interact.MouseButton1Down:Connect(function(X)
    				local Current = Slider.Main.Progress.AbsolutePosition.X + Slider.Main.Progress.AbsoluteSize.X
    				local Start = Current
    				local Location = X
    				local Loop; Loop = RunService.Stepped:Connect(function()
    					if SLDragging then
    						Location = UserInputService:GetMouseLocation().X
    						Current = Current + 0.025 * (Location - Start)

    						if Location < Slider.Main.AbsolutePosition.X then
    							Location = Slider.Main.AbsolutePosition.X
    						elseif Location > Slider.Main.AbsolutePosition.X + Slider.Main.AbsoluteSize.X then
    							Location = Slider.Main.AbsolutePosition.X + Slider.Main.AbsoluteSize.X
    						end

    						if Current < Slider.Main.AbsolutePosition.X + 5 then
    							Current = Slider.Main.AbsolutePosition.X + 5
    						elseif Current > Slider.Main.AbsolutePosition.X + Slider.Main.AbsoluteSize.X then
    							Current = Slider.Main.AbsolutePosition.X + Slider.Main.AbsoluteSize.X
    						end

    						if Current <= Location and (Location - Start) < 0 then
    							Start = Location
    						elseif Current >= Location and (Location - Start) > 0 then
    							Start = Location
    						end
    						TweenService:Create(Slider.Main.Progress, TweenInfo.new(0.45, Enum.EasingStyle.Exponential, Enum.EasingDirection.Out), {Size = UDim2.new(0, Current - Slider.Main.AbsolutePosition.X, 1, 0)}):Play()
    						local NewValue = SliderSettings.Range[1] + (Location - Slider.Main.AbsolutePosition.X) / Slider.Main.AbsoluteSize.X * (SliderSettings.Range[2] - SliderSettings.Range[1])

    						NewValue = math.floor(NewValue / SliderSettings.Increment + 0.5) * (SliderSettings.Increment * 10000000) / 10000000
    						NewValue = math.clamp(NewValue, SliderSettings.Range[1], SliderSettings.Range[2])

    						if not SliderSettings.Suffix then
    							Slider.Main.Information.Text = tostring(NewValue)
    						else
    							Slider.Main.Information.Text = tostring(NewValue) .. " " .. SliderSettings.Suffix
    						end

    						if SliderSettings.CurrentValue ~= NewValue then
    							local Success, Response = pcall(function()
    								SliderSettings.Callback(NewValue)
    							end)
    							if not Success then
    								TweenService:Create(Slider, TweenInfo.new(0.6, Enum.EasingStyle.Exponential), {BackgroundColor3 = Color3.fromRGB(85, 0, 0)}):Play()
    								TweenService:Create(Slider.UIStroke, TweenInfo.new(0.6, Enum.EasingStyle.Exponential), {Transparency = 1}):Play()
    								Slider.Title.Text = "Callback Error"
    								print("Rayfield | "..SliderSettings.Name.." Callback Error " ..tostring(Response))
    								warn('Check docs.sirius.menu for help with Rayfield specific development.')
    								task.wait(0.5)
    								Slider.Title.Text = SliderSettings.Name
    								TweenService:Create(Slider, TweenInfo.new(0.6, Enum.EasingStyle.Exponential), {BackgroundColor3 = SelectedTheme.ElementBackground}):Play()
    								TweenService:Create(Slider.UIStroke, TweenInfo.new(0.6, Enum.EasingStyle.Exponential), {Transparency = 0}):Play()
    							end

    							SliderSettings.CurrentValue = NewValue
    							if not SliderSettings.Ext then
    								SaveConfiguration()
    							end
    						end
    					else
    						TweenService:Create(Slider.Main.Progress, TweenInfo.new(0.3, Enum.EasingStyle.Exponential, Enum.EasingDirection.Out), {Size = UDim2.new(0, Location - Slider.Main.AbsolutePosition.X > 5 and Location - Slider.Main.AbsolutePosition.X or 5, 1, 0)}):Play()
    						Loop:Disconnect()
    					end
    				end)
    			end)

    			function SliderSettings:Set(NewVal)
    				local NewVal = math.clamp(NewVal, SliderSettings.Range[1], SliderSettings.Range[2])

    				TweenService:Create(Slider.Main.Progress, TweenInfo.new(0.45, Enum.EasingStyle.Exponential, Enum.EasingDirection.Out), {Size = UDim2.new(0, Slider.Main.AbsoluteSize.X * ((NewVal + SliderSettings.Range[1]) / (SliderSettings.Range[2] - SliderSettings.Range[1])) > 5 and Slider.Main.AbsoluteSize.X * (NewVal / (SliderSettings.Range[2] - SliderSettings.Range[1])) or 5, 1, 0)}):Play()
    				Slider.Main.Information.Text = tostring(NewVal) .. " " .. (SliderSettings.Suffix or "")

    				local Success, Response = pcall(function()
    					SliderSettings.Callback(NewVal)
    				end)

    				if not Success then
    					TweenService:Create(Slider, TweenInfo.new(0.6, Enum.EasingStyle.Exponential), {BackgroundColor3 = Color3.fromRGB(85, 0, 0)}):Play()
    					TweenService:Create(Slider.UIStroke, TweenInfo.new(0.6, Enum.EasingStyle.Exponential), {Transparency = 1}):Play()
    					Slider.Title.Text = "Callback Error"
    					print("Rayfield | "..SliderSettings.Name.." Callback Error " ..tostring(Response))
    					warn('Check docs.sirius.menu for help with Rayfield specific development.')
    					task.wait(0.5)
    					Slider.Title.Text = SliderSettings.Name
    					TweenService:Create(Slider, TweenInfo.new(0.6, Enum.EasingStyle.Exponential), {BackgroundColor3 = SelectedTheme.ElementBackground}):Play()
    					TweenService:Create(Slider.UIStroke, TweenInfo.new(0.6, Enum.EasingStyle.Exponential), {Transparency = 0}):Play()
    				end

    				SliderSettings.CurrentValue = NewVal
    				if not SliderSettings.Ext then
    					SaveConfiguration()
    				end
    			end

    			if Settings.ConfigurationSaving then
    				if Settings.ConfigurationSaving.Enabled and SliderSettings.Flag then
    					RayfieldLibrary.Flags[SliderSettings.Flag] = SliderSettings
    				end
    			end

    			Rayfield.Main:GetPropertyChangedSignal('BackgroundColor3'):Connect(function()
    				if SelectedTheme ~= RayfieldLibrary.Theme.Default then
    					Slider.Main.Shadow.Visible = false
    				end

    				Slider.Main.BackgroundColor3 = SelectedTheme.SliderBackground
    				Slider.Main.UIStroke.Color = SelectedTheme.SliderStroke
    				Slider.Main.Progress.UIStroke.Color = SelectedTheme.SliderStroke
    				Slider.Main.Progress.BackgroundColor3 = SelectedTheme.SliderProgress
    			end)

    			return SliderSettings
    		end

    		Rayfield.Main:GetPropertyChangedSignal('BackgroundColor3'):Connect(function()
    			TabButton.UIStroke.Color = SelectedTheme.TabStroke

    			if Elements.UIPageLayout.CurrentPage == TabPage then
    				TabButton.BackgroundColor3 = SelectedTheme.TabBackgroundSelected
    				TabButton.Image.ImageColor3 = SelectedTheme.SelectedTabTextColor
    				TabButton.Title.TextColor3 = SelectedTheme.SelectedTabTextColor
    			else
    				TabButton.BackgroundColor3 = SelectedTheme.TabBackground
    				TabButton.Image.ImageColor3 = SelectedTheme.TabTextColor
    				TabButton.Title.TextColor3 = SelectedTheme.TabTextColor
    			end
    		end)

    		return Tab
    	end

    	Elements.Visible = true


    	task.wait(1.1)
    	TweenService:Create(Main, TweenInfo.new(0.7, Enum.EasingStyle.Exponential, Enum.EasingDirection.InOut), {Size = UDim2.new(0, 390, 0, 90)}):Play()
    	task.wait(0.3)
    	TweenService:Create(LoadingFrame.Title, TweenInfo.new(0.2, Enum.EasingStyle.Exponential), {TextTransparency = 1}):Play()
    	TweenService:Create(LoadingFrame.Subtitle, TweenInfo.new(0.2, Enum.EasingStyle.Exponential), {TextTransparency = 1}):Play()
    	TweenService:Create(LoadingFrame.Version, TweenInfo.new(0.2, Enum.EasingStyle.Exponential), {TextTransparency = 1}):Play()
    	task.wait(0.1)
    	TweenService:Create(Main, TweenInfo.new(0.6, Enum.EasingStyle.Exponential, Enum.EasingDirection.Out), {Size = useMobileSizing and UDim2.new(0, 500, 0, 275) or UDim2.new(0, 500, 0, 475)}):Play()
    	TweenService:Create(Main.Shadow.Image, TweenInfo.new(0.5, Enum.EasingStyle.Exponential), {ImageTransparency = 0.6}):Play()

    	Topbar.BackgroundTransparency = 1
    	Topbar.Divider.Size = UDim2.new(0, 0, 0, 1)
    	Topbar.Divider.BackgroundColor3 = SelectedTheme.ElementStroke
    	Topbar.CornerRepair.BackgroundTransparency = 1
    	Topbar.Title.TextTransparency = 1
    	Topbar.Search.ImageTransparency = 1
    	if Topbar:FindFirstChild('Settings') then
    		Topbar.Settings.ImageTransparency = 1
    	end
    	Topbar.ChangeSize.ImageTransparency = 1
    	Topbar.Hide.ImageTransparency = 1


    	task.wait(0.5)
    	Topbar.Visible = true
    	TweenService:Create(Topbar, TweenInfo.new(0.7, Enum.EasingStyle.Exponential), {BackgroundTransparency = 0}):Play()
    	TweenService:Create(Topbar.CornerRepair, TweenInfo.new(0.7, Enum.EasingStyle.Exponential), {BackgroundTransparency = 0}):Play()
    	task.wait(0.1)
    	TweenService:Create(Topbar.Divider, TweenInfo.new(1, Enum.EasingStyle.Exponential), {Size = UDim2.new(1, 0, 0, 1)}):Play()
    	TweenService:Create(Topbar.Title, TweenInfo.new(0.6, Enum.EasingStyle.Exponential), {TextTransparency = 0}):Play()
    	task.wait(0.05)
    	TweenService:Create(Topbar.Search, TweenInfo.new(0.6, Enum.EasingStyle.Exponential), {ImageTransparency = 0.8}):Play()
    	task.wait(0.05)
    	if Topbar:FindFirstChild('Settings') then
    		TweenService:Create(Topbar.Settings, TweenInfo.new(0.6, Enum.EasingStyle.Exponential), {ImageTransparency = 0.8}):Play()
    		task.wait(0.05)
    	end
    	TweenService:Create(Topbar.ChangeSize, TweenInfo.new(0.6, Enum.EasingStyle.Exponential), {ImageTransparency = 0.8}):Play()
    	task.wait(0.05)
    	TweenService:Create(Topbar.Hide, TweenInfo.new(0.6, Enum.EasingStyle.Exponential), {ImageTransparency = 0.8}):Play()
    	task.wait(0.3)

    	if dragBar then
    		TweenService:Create(dragBarCosmetic, TweenInfo.new(0.6, Enum.EasingStyle.Exponential), {BackgroundTransparency = 0.7}):Play()
    	end

    	function Window.ModifyTheme(NewTheme)
    		local success = pcall(ChangeTheme, NewTheme)
    		if not success then
    			RayfieldLibrary:Notify({Title = 'Unable to Change Theme', Content = 'We are unable find a theme on file.', Image = 4400704299})
    		else
    			RayfieldLibrary:Notify({Title = 'Theme Changed', Content = 'Successfully changed theme to '..(typeof(NewTheme) == 'string' and NewTheme or 'Custom Theme')..'.', Image = 4483362748})
    		end
    	end

    	local success, result = pcall(function()
    		createSettings(Window)
    	end)
	
    	if not success then warn('Rayfield had an issue creating settings.') end
	
    	return Window
    end

    local function setVisibility(visibility: boolean, notify: boolean?)
    	if Debounce then return end
    	if visibility then
    		Hidden = false
    		Unhide()
    	else
    		Hidden = true
    		Hide(notify)
    	end
    end

    function RayfieldLibrary:SetVisibility(visibility: boolean)
    	setVisibility(visibility, false)
    end

    function RayfieldLibrary:IsVisible(): boolean
    	return not Hidden
    end

    local hideHotkeyConnection -- Has to be initialized here since the connection is made later in the script
    function RayfieldLibrary:Destroy()
    	rayfieldDestroyed = true
    	hideHotkeyConnection:Disconnect()
    	Rayfield:Destroy()
    end

    Topbar.ChangeSize.MouseButton1Click:Connect(function()
    	if Debounce then return end
    	if Minimised then
    		Minimised = false
    		Maximise()
    	else
    		Minimised = true
    		Minimise()
    	end
    end)

    Main.Search.Input:GetPropertyChangedSignal('Text'):Connect(function()
    	if #Main.Search.Input.Text > 0 then
    		if not Elements.UIPageLayout.CurrentPage:FindFirstChild('SearchTitle-fsefsefesfsefesfesfThanks') then 
    			local searchTitle = Elements.Template.SectionTitle:Clone()
    			searchTitle.Parent = Elements.UIPageLayout.CurrentPage
    			searchTitle.Name = 'SearchTitle-fsefsefesfsefesfesfThanks'
    			searchTitle.LayoutOrder = -100
    			searchTitle.Title.Text = "Results from '"..Elements.UIPageLayout.CurrentPage.Name.."'"
    			searchTitle.Visible = true
    		end
    	else
    		local searchTitle = Elements.UIPageLayout.CurrentPage:FindFirstChild('SearchTitle-fsefsefesfsefesfesfThanks')

    		if searchTitle then
    			searchTitle:Destroy()
    		end
    	end

    	for _, element in ipairs(Elements.UIPageLayout.CurrentPage:GetChildren()) do
    		if element.ClassName ~= 'UIListLayout' and element.Name ~= 'Placeholder' and element.Name ~= 'SearchTitle-fsefsefesfsefesfesfThanks' then
    			if element.Name == 'SectionTitle' then
    				if #Main.Search.Input.Text == 0 then
    					element.Visible = true
    				else
    					element.Visible = false
    				end
    			else
    				if string.lower(element.Name):find(string.lower(Main.Search.Input.Text), 1, true) then
    					element.Visible = true
    				else
    					element.Visible = false
    				end
    			end
    		end
    	end
    end)

    Main.Search.Input.FocusLost:Connect(function(enterPressed)
    	if #Main.Search.Input.Text == 0 and searchOpen then
    		task.wait(0.12)
    		closeSearch()
    	end
    end)

    Topbar.Search.MouseButton1Click:Connect(function()
    	task.spawn(function()
    		if searchOpen then
    			closeSearch()
    		else
    			openSearch()
    		end
    	end)
    end)

    if Topbar:FindFirstChild('Settings') then
    	Topbar.Settings.MouseButton1Click:Connect(function()
    		task.spawn(function()
    			for _, OtherTabButton in ipairs(TabList:GetChildren()) do
    				if OtherTabButton.Name ~= "Template" and OtherTabButton.ClassName == "Frame" and OtherTabButton ~= TabButton and OtherTabButton.Name ~= "Placeholder" then
    					TweenService:Create(OtherTabButton, TweenInfo.new(0.7, Enum.EasingStyle.Exponential), {BackgroundColor3 = SelectedTheme.TabBackground}):Play()
    					TweenService:Create(OtherTabButton.Title, TweenInfo.new(0.7, Enum.EasingStyle.Exponential), {TextColor3 = SelectedTheme.TabTextColor}):Play()
    					TweenService:Create(OtherTabButton.Image, TweenInfo.new(0.7, Enum.EasingStyle.Exponential), {ImageColor3 = SelectedTheme.TabTextColor}):Play()
    					TweenService:Create(OtherTabButton, TweenInfo.new(0.7, Enum.EasingStyle.Exponential), {BackgroundTransparency = 0.7}):Play()
    					TweenService:Create(OtherTabButton.Title, TweenInfo.new(0.7, Enum.EasingStyle.Exponential), {TextTransparency = 0.2}):Play()
    					TweenService:Create(OtherTabButton.Image, TweenInfo.new(0.7, Enum.EasingStyle.Exponential), {ImageTransparency = 0.2}):Play()
    					TweenService:Create(OtherTabButton.UIStroke, TweenInfo.new(0.7, Enum.EasingStyle.Exponential), {Transparency = 0.5}):Play()
    				end
    			end

    			Elements.UIPageLayout:JumpTo(Elements['Rayfield Settings'])
    		end)
    	end)

    end


    Topbar.Hide.MouseButton1Click:Connect(function()
    	setVisibility(Hidden, not useMobileSizing)
    end)

    hideHotkeyConnection = UserInputService.InputBegan:Connect(function(input, processed)
    	if (input.KeyCode == Enum.KeyCode[getSetting("General", "rayfieldOpen")]) and not processed then
    		if Debounce then return end
    		if Hidden then
    			Hidden = false
    			Unhide()
    		else
    			Hidden = true
    			Hide()
    		end
    	end
    end)

    if MPrompt then
    	MPrompt.Interact.MouseButton1Click:Connect(function()
    		if Debounce then return end
    		if Hidden then
    			Hidden = false
    			Unhide()
    		end
    	end)
    end

    for _, TopbarButton in ipairs(Topbar:GetChildren()) do
    	if TopbarButton.ClassName == "ImageButton" and TopbarButton.Name ~= 'Icon' then
    		TopbarButton.MouseEnter:Connect(function()
    			TweenService:Create(TopbarButton, TweenInfo.new(0.7, Enum.EasingStyle.Exponential), {ImageTransparency = 0}):Play()
    		end)

    		TopbarButton.MouseLeave:Connect(function()
    			TweenService:Create(TopbarButton, TweenInfo.new(0.7, Enum.EasingStyle.Exponential), {ImageTransparency = 0.8}):Play()
    		end)
    	end
    end


    function RayfieldLibrary:LoadConfiguration()
    	local config

    	if debugX then
    		warn('Loading Configuration')
    	end

    	if useStudio then
    		config = [[{"Toggle1adwawd":true,"ColorPicker1awd":{"B":255,"G":255,"R":255},"Slider1dawd":100,"ColorPicfsefker1":{"B":255,"G":255,"R":255},"Slidefefsr1":80,"dawdawd":"","Input1":"hh","Keybind1":"B","Dropdown1":["Ocean"]}]]
    	end

    	if CEnabled then
    		local notified
    		local loaded

    		local success, result = pcall(function()
    			if useStudio and config then
    				loaded = LoadConfiguration(config)
    				return
    			end

    			if isfile then 
    				if isfile(ConfigurationFolder .. "/" .. CFileName .. ConfigurationExtension) then
    					loaded = LoadConfiguration(readfile(ConfigurationFolder .. "/" .. CFileName .. ConfigurationExtension))
    				end
    			else
    				notified = true
    				RayfieldLibrary:Notify({Title = "Rayfield Configurations", Content = "We couldn't enable Configuration Saving as you are not using software with filesystem support.", Image = 4384402990})
    			end
    		end)

    		if success and loaded and not notified then
    			RayfieldLibrary:Notify({Title = "Rayfield Configurations", Content = "The configuration file for this script has been loaded from a previous session.", Image = 4384403532})
    		elseif not success and not notified then
    			warn('Rayfield Configurations Error | '..tostring(result))
    			RayfieldLibrary:Notify({Title = "Rayfield Configurations", Content = "We've encountered an issue loading your configuration correctly.\n\nCheck the Developer Console for more information.", Image = 4384402990})
    		end
    	end

    	globalLoaded = true
    end



    if useStudio then
    	-- run w/ studio
    	-- Feel free to place your own script here to see how it'd work in Roblox Studio before running it on your execution software.


    	local Window = RayfieldLibrary:CreateWindow({
    		Name = "Rayfield Example Window",
    		LoadingTitle = "Rayfield Interface Suite",
    		Theme = 'Default',
    		Icon = 0,
    		LoadingSubtitle = "by Sirius",
    		ConfigurationSaving = {
    			Enabled = true,
    			FolderName = nil, -- Create a custom folder for your hub/game
    			FileName = "Big Hub52"
    		},
    		Discord = {
    			Enabled = false,
    			Invite = "noinvitelink", -- The Discord invite code, do not include discord.gg/. E.g. discord.gg/ABCD would be ABCD
    			RememberJoins = true -- Set this to false to make them join the discord every time they load it up
    		},
    		KeySystem = false, -- Set this to true to use our key system
    		KeySettings = {
    			Title = "Untitled",
    			Subtitle = "Key System",
    			Note = "No method of obtaining the key is provided",
    			FileName = "Key", -- It is recommended to use something unique as other scripts using Rayfield may overwrite your key file
    			SaveKey = true, -- The user's key will be saved, but if you change the key, they will be unable to use your script
    			GrabKeyFromSite = false, -- If this is true, set Key below to the RAW site you would like Rayfield to get the key from
    			Key = {"Hello"} -- List of keys that will be accepted by the system, can be RAW file links (pastebin, github etc) or simple strings ("hello","key22")
    		}
    	})

    	local Tab = Window:CreateTab("Tab Example", 'key-round') -- Title, Image
    	local Tab2 = Window:CreateTab("Tab Example 2", 4483362458) -- Title, Image

    	local Section = Tab2:CreateSection("Section")


    	local ColorPicker = Tab2:CreateColorPicker({
    		Name = "Color Picker",
    		Color = Color3.fromRGB(255,255,255),
    		Flag = "ColorPicfsefker1", -- A flag is the identifier for the configuration file, make sure every element has a different flag if you're using configuration saving to ensure no overlaps
    		Callback = function(Value)
    			-- The function that takes place every time the color picker is moved/changed
    			-- The variable (Value) is a Color3fromRGB value based on which color is selected
    		end
    	})

    	local Slider = Tab2:CreateSlider({
    		Name = "Slider Example",
    		Range = {0, 100},
    		Increment = 10,
    		Suffix = "Bananas",
    		CurrentValue = 40,
    		Flag = "Slidefefsr1", -- A flag is the identifier for the configuration file, make sure every element has a different flag if you're using configuration saving to ensure no overlaps
    		Callback = function(Value)
    			-- The function that takes place when the slider changes
    			-- The variable (Value) is a number which correlates to the value the slider is currently at
    		end,
    	})

    	local Input = Tab2:CreateInput({
    		Name = "Input Example",
    		CurrentValue = '',
    		PlaceholderText = "Input Placeholder",
    		Flag = 'dawdawd',
    		RemoveTextAfterFocusLost = false,
    		Callback = function(Text)
    			-- The function that takes place when the input is changed
    			-- The variable (Text) is a string for the value in the text box
    		end,
    	})


    	--RayfieldLibrary:Notify({Title = "Rayfield Interface", Content = "Welcome to Rayfield. These - are the brand new notification design for Rayfield, with custom sizing and Rayfield calculated wait times.", Image = 4483362458})

    	local Section = Tab:CreateSection("Section Example")

    	local Button = Tab:CreateButton({
    		Name = "Change Theme",
    		Callback = function()
    			-- The function that takes place when the button is pressed
    			Window.ModifyTheme('DarkBlue')
    		end,
    	})

    	local Toggle = Tab:CreateToggle({
    		Name = "Toggle Example",
    		CurrentValue = false,
    		Flag = "Toggle1adwawd", -- A flag is the identifier for the configuration file, make sure every element has a different flag if you're using configuration saving to ensure no overlaps
    		Callback = function(Value)
    			-- The function that takes place when the toggle is pressed
    			-- The variable (Value) is a boolean on whether the toggle is true or false
    		end,
    	})

    	local ColorPicker = Tab:CreateColorPicker({
    		Name = "Color Picker",
    		Color = Color3.fromRGB(255,255,255),
    		Flag = "ColorPicker1awd", -- A flag is the identifier for the configuration file, make sure every element has a different flag if you're using configuration saving to ensure no overlaps
    		Callback = function(Value)
    			-- The function that takes place every time the color picker is moved/changed
    			-- The variable (Value) is a Color3fromRGB value based on which color is selected
    		end
    	})

    	local Slider = Tab:CreateSlider({
    		Name = "Slider Example",
    		Range = {0, 100},
    		Increment = 10,
    		Suffix = "Bananas",
    		CurrentValue = 40,
    		Flag = "Slider1dawd", -- A flag is the identifier for the configuration file, make sure every element has a different flag if you're using configuration saving to ensure no overlaps
    		Callback = function(Value)
    			-- The function that takes place when the slider changes
    			-- The variable (Value) is a number which correlates to the value the slider is currently at
    		end,
    	})

    	local Input = Tab:CreateInput({
    		Name = "Input Example",
    		CurrentValue = "Helo",
    		PlaceholderText = "Adaptive Input",
    		RemoveTextAfterFocusLost = false,
    		Flag = 'Input1',
    		Callback = function(Text)
    			-- The function that takes place when the input is changed
    			-- The variable (Text) is a string for the value in the text box
    		end,
    	})

    	local thoptions = {}
    	for themename, theme in pairs(RayfieldLibrary.Theme) do
    		table.insert(thoptions, themename)
    	end

    	local Dropdown = Tab:CreateDropdown({
    		Name = "Theme",
    		Options = thoptions,
    		CurrentOption = {"Default"},
    		MultipleOptions = false,
    		Flag = "Dropdown1", -- A flag is the identifier for the configuration file, make sure every element has a different flag if you're using configuration saving to ensure no overlaps
    		Callback = function(Options)
    			--Window.ModifyTheme(Options[1])
    			-- The function that takes place when the selected option is changed
    			-- The variable (Options) is a table of strings for the current selected options
    		end,
    	})


    	--Window.ModifyTheme({
    	--	TextColor = Color3.fromRGB(50, 55, 60),
    	--	Background = Color3.fromRGB(240, 245, 250),
    	--	Topbar = Color3.fromRGB(215, 225, 235),
    	--	Shadow = Color3.fromRGB(200, 210, 220),

    	--	NotificationBackground = Color3.fromRGB(210, 220, 230),
    	--	NotificationActionsBackground = Color3.fromRGB(225, 230, 240),

    	--	TabBackground = Color3.fromRGB(200, 210, 220),
    	--	TabStroke = Color3.fromRGB(180, 190, 200),
    	--	TabBackgroundSelected = Color3.fromRGB(175, 185, 200),
    	--	TabTextColor = Color3.fromRGB(50, 55, 60),
    	--	SelectedTabTextColor = Color3.fromRGB(30, 35, 40),

    	--	ElementBackground = Color3.fromRGB(210, 220, 230),
    	--	ElementBackgroundHover = Color3.fromRGB(220, 230, 240),
    	--	SecondaryElementBackground = Color3.fromRGB(200, 210, 220),
    	--	ElementStroke = Color3.fromRGB(190, 200, 210),
    	--	SecondaryElementStroke = Color3.fromRGB(180, 190, 200),

    	--	SliderBackground = Color3.fromRGB(200, 220, 235),  -- Lighter shade
    	--	SliderProgress = Color3.fromRGB(70, 130, 180),
    	--	SliderStroke = Color3.fromRGB(150, 180, 220),

    	--	ToggleBackground = Color3.fromRGB(210, 220, 230),
    	--	ToggleEnabled = Color3.fromRGB(70, 160, 210),
    	--	ToggleDisabled = Color3.fromRGB(180, 180, 180),
    	--	ToggleEnabledStroke = Color3.fromRGB(60, 150, 200),
    	--	ToggleDisabledStroke = Color3.fromRGB(140, 140, 140),
    	--	ToggleEnabledOuterStroke = Color3.fromRGB(100, 120, 140),
    	--	ToggleDisabledOuterStroke = Color3.fromRGB(120, 120, 130),

    	--	DropdownSelected = Color3.fromRGB(220, 230, 240),
    	--	DropdownUnselected = Color3.fromRGB(200, 210, 220),

    	--	InputBackground = Color3.fromRGB(220, 230, 240),
    	--	InputStroke = Color3.fromRGB(180, 190, 200),
    	--	PlaceholderColor = Color3.fromRGB(150, 150, 150)
    	--})

    	local Keybind = Tab:CreateKeybind({
    		Name = "Keybind Example",
    		CurrentKeybind = "Q",
    		HoldToInteract = false,
    		Flag = "Keybind1", -- A flag is the identifier for the configuration file, make sure every element has a different flag if you're using configuration saving to ensure no overlaps
    		Callback = function(Keybind)
    			-- The function that takes place when the keybind is pressed
    			-- The variable (Keybind) is a boolean for whether the keybind is being held or not (HoldToInteract needs to be true)
    		end,
    	})

    	local Label = Tab:CreateLabel("Label Example")

    	local Label2 = Tab:CreateLabel("Warning", 4483362458, Color3.fromRGB(255, 159, 49),  true)

    	local Paragraph = Tab:CreateParagraph({Title = "Paragraph Example", Content = "Paragraph ExampleParagraph ExampleParagraph ExampleParagraph ExampleParagraph ExampleParagraph ExampleParagraph ExampleParagraph ExampleParagraph ExampleParagraph ExampleParagraph ExampleParagraph ExampleParagraph ExampleParagraph Example"})
    end

    if CEnabled and Main:FindFirstChild('Notice') then
    	Main.Notice.BackgroundTransparency = 1
    	Main.Notice.Title.TextTransparency = 1
    	Main.Notice.Size = UDim2.new(0, 0, 0, 0)
    	Main.Notice.Position = UDim2.new(0.5, 0, 0, -100)
    	Main.Notice.Visible = true


    	TweenService:Create(Main.Notice, TweenInfo.new(0.5, Enum.EasingStyle.Exponential, Enum.EasingDirection.InOut), {Size = UDim2.new(0, 280, 0, 35), Position = UDim2.new(0.5, 0, 0, -50), BackgroundTransparency = 0.5}):Play()
    	TweenService:Create(Main.Notice.Title, TweenInfo.new(0.5, Enum.EasingStyle.Exponential), {TextTransparency = 0.1}):Play()
    end

    -- if not useStudio then
    -- 	task.spawn(loadWithTimeout, "https://raw.githubusercontent.com/SiriusSoftwareLtd/Sirius/refs/heads/request/boost.lua")
    -- end

    task.delay(4, function()
    	RayfieldLibrary.LoadConfiguration()
    	if Main:FindFirstChild('Notice') and Main.Notice.Visible then
    		TweenService:Create(Main.Notice, TweenInfo.new(0.5, Enum.EasingStyle.Exponential, Enum.EasingDirection.InOut), {Size = UDim2.new(0, 100, 0, 25), Position = UDim2.new(0.5, 0, 0, -100), BackgroundTransparency = 1}):Play()
    		TweenService:Create(Main.Notice.Title, TweenInfo.new(0.3, Enum.EasingStyle.Exponential), {TextTransparency = 1}):Play()

    		task.wait(0.5)
    		Main.Notice.Visible = false
    	end
    end)

    return RayfieldLibrary

end

















local Rayfield = Rayfield()

-- 创建窗口
local Window = Rayfield:CreateWindow({
    Name = "ZeE-Hub v255.0.255 紫罗兰主题版",
    Icon = 0,
    LoadingTitle = "ZeE-Hub 紫罗兰限定",
    LoadingSubtitle = "by ZeEnter | 定制版",
    Theme = "Amethyst",
    ToggleUIKeybind = "K",
    ConfigurationSaving = {
        Enabled = true,
        FolderName = "ZeE-Hub-Config",
        FileName = "Settings"
    },
    KeySystem = false,
    KeySettings = {
        Title = "ZeE-Hub 密钥系统",
        Subtitle = "请输入您的密钥",
        Note = "请勿从非正规渠道获取密钥\n否则一经发现 立即封禁\n暂不对外开放获取密钥渠道\n输入错误4次将会被踢出\n除授权人员无法进入！",
        FileName = "ZeEKey",
        SaveKey = true,
        GrabKeyFromSite = false,
        Key = {"Bloom"}
    }
})

-- 通用功能标签页
local GeneralTab = Window:CreateTab("通用功能", 4483362458)

-- 添加说明分区
GeneralTab:CreateSection("角色属性设置")
GeneralTab:CreateLabel("以下设置将立即生效，死亡后自动恢复默认值")

-- 移动速度控制 (改为输入框)
local defaultWalkSpeed = 16
local WalkSpeedInput = GeneralTab:CreateInput({
    Name = "设置移动速度 (默认: "..defaultWalkSpeed..")",
    PlaceholderText = "输入数字值",
    RemoveTextAfterFocusLost = false,
    Callback = function(Text)
        local num = tonumber(Text)
        if num then
            pcall(function()
                game.Players.LocalPlayer.Character.Humanoid.WalkSpeed = num
                Rayfield:Notify({
                    Title = "设置成功",
                    Content = "移动速度已设置为: "..num,
                    Duration = 3,
                    Image = 4483362458,
                })
            end)
        end
    end,
})

-- 跳跃高度控制 (改为输入框)
local defaultJumpPower = 50
local JumpPowerInput = GeneralTab:CreateInput({
    Name = "设置跳跃高度 (默认: "..defaultJumpPower..")",
    PlaceholderText = "输入数字值",
    RemoveTextAfterFocusLost = false,
    Callback = function(Text)
        local num = tonumber(Text)
        if num then
            pcall(function()
                game.Players.LocalPlayer.Character.Humanoid.JumpPower = num
                Rayfield:Notify({
                    Title = "设置成功",
                    Content = "跳跃高度已设置为: "..num,
                    Duration = 3,
                    Image = 4483362458,
                })
            end)
        end
    end,
})

-- 重力控制
local defaultGravity = 196.2
local GravityInput = GeneralTab:CreateInput({
    Name = "设置重力值 (默认: "..defaultGravity..")",
    PlaceholderText = "输入数字值",
    RemoveTextAfterFocusLost = false,
    Callback = function(Text)
        local num = tonumber(Text)
        if num then
            workspace.Gravity = num
            Rayfield:Notify({
                Title = "设置成功",
                Content = "重力值已设置为: "..num,
                Duration = 3,
                Image = 4483362458,
            })
        end
    end,
})

-- 添加功能分区
GeneralTab:CreateSection("特殊功能")

-- 飞行V3
GeneralTab:CreateButton({
    Name = "飞行V3",
    Callback = function()
    function Flyv3()
    end,
})

-- 阿尔宙斯V3
GeneralTab:CreateButton({
    Name = "阿尔宙斯V3",
    Callback = function()
    function ArceusX()
    end,
})
-- 无限跳跃开关
GeneralTab:CreateToggle({
    Name = "无限跳跃 (空格键触发)",
    CurrentValue = false,
    Callback = function(Value)
        if Value then
            Rayfield:Notify({
                Title = "提示",
                Content = "无限跳跃已启用，按空格键跳跃",
                Duration = 3,
                Image = 4483362458,
            })
            game:GetService("UserInputService").JumpRequest:Connect(function()
                pcall(function()
                    game.Players.LocalPlayer.Character:FindFirstChildOfClass("Humanoid"):ChangeState("Jumping")
                end)
            end)
        else
            Rayfield:Notify({
                Title = "提示",
                Content = "无限跳跃已禁用",
                Duration = 3,
                Image = 4483362458,
            })
        end
    end,
})

-- 点击传送工具
GeneralTab:CreateButton({
    Name = "获取点击传送工具",
    Callback = function()
        local tool = Instance.new("Tool")
        tool.Name = "ZeE传送工具"
        tool.RequiresHandle = false
        tool.Activated:Connect(function()
            local char = game.Players.LocalPlayer.Character
            if char then
                local hrp = char:FindFirstChild("HumanoidRootPart")
                if hrp then
                    local mouse = game.Players.LocalPlayer:GetMouse()
                    hrp.CFrame = mouse.Hit + Vector3.new(0, 3, 0)
                    Rayfield:Notify({
                        Title = "传送成功",
                        Content = "已传送到目标位置",
                        Duration = 3,
                        Image = 4483362458,
                    })
                end
            end
        end)
        tool.Parent = game.Players.LocalPlayer.Backpack
        Rayfield:Notify({
            Title = "工具已添加",
            Content = "请在背包中使用传送工具",
            Duration = 3,
            Image = 4483362458,
        })
    end,
})

-- 最强透视
GeneralTab:CreateButton({
    Name = "开启最强透视",
    Callback = function()
        function ESPMax()
        Rayfield:Notify({
            Title = "透视已开启",
            Content = "请开始您的呼吸耳机之旅",
            Duration = 3,
            Image = 0,
        })
    end,
})

-- 自然灾害模拟器标签页
local DisasterTab = Window:CreateTab("自然灾害模拟器", 4483362458)
DisasterTab:CreateSection("灾难控制")
DisasterTab:CreateLabel("警告：这些功能会严重影响游戏体验")

-- 黑洞功能
DisasterTab:CreateButton({
    Name = "黑洞",
    Callback = function()
        Rayfield:Notify({
            Title = "正在加载",
            Content = "黑洞脚本加载中...",
            Duration = 3,
            Image = 4483362458,
        })
        blackhole()
    end,
})

-- 关于标签页
local AboutTab = Window:CreateTab("关于", 4483362458)
AboutTab:CreateSection("版本信息")
AboutTab:CreateLabel("脚本作者: ZeEnter")
AboutTab:CreateLabel("UI作者: 天狼星")
AboutTab:CreateLabel("由ZeEnter实现纯本地化")
AboutTab:CreateLabel("当前版本: v255.0.255 紫罗兰限定")
AboutTab:CreateLabel("最后更新: "..os.date("%Y/%m/%d"))

AboutTab:CreateSection("免责声明")
AboutTab:CreateLabel("本脚本仅供学习交流使用")
AboutTab:CreateLabel("不当使用可能导致账号封禁")
AboutTab:CreateLabel("若账号封禁本脚本不负任何责任")
AboutTab:CreateLabel("使用即表示您已了解风险")

-- 初始化角色属性
game.Players.LocalPlayer.CharacterAdded:Connect(function(character)
    character:WaitForChild("Humanoid").WalkSpeed = defaultWalkSpeed
    character:WaitForChild("Humanoid").JumpPower = defaultJumpPower
    Rayfield:Notify({
        Title = "角色重生",
        Content = "已恢复默认移动和跳跃设置",
        Duration = 3,
        Image = 4483362458,
    })
end)

-- 初始提示
Rayfield:Notify({
    Title = "欢迎使用 ZeE-Hub",
    Content = "紫罗兰主题版已加载完成",
    Duration = 6,
    Image = 4483362458,
})















--////////////////////功能部分:快速定位////////////////////
--名称     位置            行数
--黑洞     15764-15941     177
--最强透视 12835-15780     2945
--阿尔宙斯 7875-12842      
--飞行v3   12848-13323
--/////////////////////////////////////////////////////////

function blackhole()
    local Players = game:GetService("Players")
    local RunService = game:GetService("RunService")
    local UserInputService = game:GetService("UserInputService")
    local LocalPlayer = Players.LocalPlayer
    local Workspace = game:GetService("Workspace")

    local character = LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait()
    local humanoidRootPart = character:WaitForChild("HumanoidRootPart")

    local Folder = Instance.new("Folder", Workspace)
    local Part = Instance.new("Part", Folder)
    local Attachment1 = Instance.new("Attachment", Part)
    Part.Anchored = true
    Part.CanCollide = false
    Part.Transparency = 1

    if not getgenv().Network then
        getgenv().Network = {
            BaseParts = {},
            Velocity = Vector3.new(14.46262424, 14.46262424, 14.46262424)
        }

        Network.RetainPart = function(Part)
            if typeof(Part) == "Instance" and Part:IsA("BasePart") and Part:IsDescendantOf(Workspace) then
                table.insert(Network.BaseParts, Part)
                Part.CustomPhysicalProperties = PhysicalProperties.new(0, 0, 0, 0, 0)
                Part.CanCollide = false
            end
        end

        local function EnablePartControl()
            LocalPlayer.ReplicationFocus = Workspace
            RunService.Heartbeat:Connect(function()
                sethiddenproperty(LocalPlayer, "SimulationRadius", math.huge)
                for _, Part in pairs(Network.BaseParts) do
                    if Part:IsDescendantOf(Workspace) then
                        Part.Velocity = Network.Velocity
                    end
                end
            end)
        end

        EnablePartControl()
    end

    local function ForcePart(v)
        if v:IsA("Part") and not v.Anchored and not v.Parent:FindFirstChild("Humanoid") and not v.Parent:FindFirstChild("Head") and v.Name ~= "Handle" then
            for _, x in next, v:GetChildren() do
                if x:IsA("BodyAngularVelocity") or x:IsA("BodyForce") or x:IsA("BodyGyro") or x:IsA("BodyPosition") or x:IsA("BodyThrust") or x:IsA("BodyVelocity") or x:IsA("RocketPropulsion") then
                    x:Destroy()
                end
            end
            if v:FindFirstChild("Attachment") then
                v:FindFirstChild("Attachment"):Destroy()
            end
            if v:FindFirstChild("AlignPosition") then
                v:FindFirstChild("AlignPosition"):Destroy()
            end
            if v:FindFirstChild("Torque") then
                v:FindFirstChild("Torque"):Destroy()
            end
            v.CanCollide = false
            local Torque = Instance.new("Torque", v)
            Torque.Torque = Vector3.new(100000, 100000, 100000)
            local AlignPosition = Instance.new("AlignPosition", v)
            local Attachment2 = Instance.new("Attachment", v)
            Torque.Attachment0 = Attachment2
            AlignPosition.MaxForce = 9999999999999999
            AlignPosition.MaxVelocity = math.huge
            AlignPosition.Responsiveness = 200
            AlignPosition.Attachment0 = Attachment2
            AlignPosition.Attachment1 = Attachment1
        end
    end

    local blackHoleActive = true

    local function toggleBlackHole()
        blackHoleActive = not blackHoleActive
        if blackHoleActive then
            for _, v in next, Workspace:GetDescendants() do
                ForcePart(v)
            end

            Workspace.DescendantAdded:Connect(function(v)
                if blackHoleActive then
                    ForcePart(v)
                end
            end)

            spawn(function()
                while blackHoleActive and RunService.RenderStepped:Wait() do
                    Attachment1.WorldCFrame = humanoidRootPart.CFrame
                end
            end)
        end
    end

    local function createRainbowEffect(object, isText)
        local hue = 0
        local function updateColor()
            hue = (hue + 0.002) % 1
            local color = Color3.fromHSV(hue, 1, isText and 1 or 0.5)  -- Lower brightness for background
            if isText then
                object.TextColor3 = color
            else
                object.BackgroundColor3 = color
            end
        end

        RunService.RenderStepped:Connect(updateColor)
    end

    local function createControlButton()
        local screenGui = Instance.new("ScreenGui")
        local button = Instance.new("TextButton")

        screenGui.Name = "BlackHoleControlGUI"
        screenGui.Parent = LocalPlayer:WaitForChild("PlayerGui")

        button.Name = "ToggleBlackHoleButton"
        button.Size = UDim2.new(0, 200, 0, 50)
        button.Position = UDim2.new(0.5, -100, 0, 100)
        button.Text = "黑洞"
        button.TextScaled = true
        button.Parent = screenGui

        createRainbowEffect(button, false) -- Apply rainbow effect to button background
        createRainbowEffect(button, true)  -- Apply rainbow effect to text

        local dragging = false
        local dragInput, mousePos, framePos

        button.InputBegan:Connect(function(input)
            if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
                dragging = true
                mousePos = input.Position
                framePos = button.Position

                input.Changed:Connect(function()
                    if input.UserInputState == Enum.UserInputState.End then
                        dragging = false
                    end
                end)
            end
        end)

        button.InputChanged:Connect(function(input)
            if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then
                dragInput = input
            end
        end)

        UserInputService.InputChanged:Connect(function(input)
            if input == dragInput and dragging then
                local delta = input.Position - mousePos
                button.Position = UDim2.new(
                    framePos.X.Scale,
                    framePos.X.Offset + delta.X,
                    framePos.Y.Scale,
                    framePos.Y.Offset + delta.Y
                )
            end
        end)

        button.MouseButton1Click:Connect(function()
            toggleBlackHole()
            if blackHoleActive then
                button.Text = "开启黑洞"
            else
                button.Text = "关闭黑洞"
            end
        end)
    end

    createControlButton()
end






function ESPMax()
    -- 问题:
    -- 我还在研究追踪器，我知道它们会导致巨大的帧率下降。（我想我已经让它运行得尽可能顺畅了。）
    -- 幽灵部队：追踪器的奇怪定位bug ？追踪器的位置在localplayer后面。(也许让更新更快？> RenderPriority。第一位?
    -- 设置可以在网上找到：51
    -- 如果你不明白，就不要改变任何东西。
    local Plrs = game:GetService("Players")
    local Run = game:GetService("RunService")
    local CoreGui = game:GetService("CoreGui")
    local StartGui = game:GetService("StarterGui")
    local Teams = game:GetService("Teams")
    local UserInput = game:GetService("UserInputService")
    local Light = game:GetService("Lighting")
    local HTTP = game:GetService("HttpService")
    local RepStor = game:GetService("ReplicatedStorage")
 
    function GetCamera() -- Just in case some game renames the player's camera.
    	return workspace:FindFirstChildOfClass("Camera")
    end
 
    local ChamsFolder = Instance.new("Folder", CoreGui)
    ChamsFolder.Name = "Chams"
    local PlayerChams = Instance.new("Folder", ChamsFolder)
    PlayerChams.Name = "PlayerChams"
    local ItemChams = Instance.new("Folder", ChamsFolder)
    ItemChams.Name = "ItemChams"

    local ESPFolder = Instance.new("Folder", CoreGui)
    ESPFolder.Name = "ESP Stuff"
    local PlayerESP = Instance.new("Folder", ESPFolder)
    PlayerESP.Name = "PlayerESP"
    local ItemESP = Instance.new("Folder", ESPFolder)
    ItemESP.Name = "ItemESP"

    local MyPlr = Plrs.LocalPlayer
    local MyChar = MyPlr.Character
    local MyMouse = MyPlr:GetMouse()
    local MyCam = GetCamera()
    if MyCam == nil then
    	error("WHAT KIND OF BLACK MAGIC IS THIS, CAMERA NOT FOUND.")
    	return
    end

    local Tracers = Instance.new("Folder", MyCam)
    Tracers.Name = "Tracers"
    local TracerData = { }
    local TracerMT = setmetatable(TracerData, {
    	__newindex = function(tab, index, val)
    		rawset(tab, index, val)
    	end
    })

    function RemoveSpacesFromString(Str)
    	local newstr = ""
    	for i = 1, #Str do
    		if Str:sub(i, i) ~= " " then
    			newstr = newstr .. Str:sub(i, i)
    		end
    	end

    	return newstr
    end

    function CloneTable(T)
        local temp = { }
        for i,v in next, T do
            if type(v) == "table" then
                temp[i] = CloneTable(v)
            else
                temp[i] = v 
            end
        end
        return temp
    end

    local Bullshit = {
    	ESPEnabled = false, -- Self explanatory. LEAVE OFF BY DEFAULT.
    	CHAMSEnabled = false, -- Self explanatory. LEAVE OFF BY DEFAULT.
    	TracersEnabled = false, -- Self explanatory. LEAVE OFF BY DEFAULT.
    	DebugInfo = false, -- Self explanatory. LEAVE OFF BY DEFAULT.
    	OutlinesEnabled = false,
    	FullbrightEnabled = false,
    	CrosshairEnabled = false,
    	AimbotEnabled = false,
    	Aimbot = false,
    	TracersLength = 500, -- MAX DISTANCE IS 2048 DO NOT GO ABOVE OR YOU'LL ENCOUNTER PROBLEMS.
    	ESPLength = 10000,
    	CHAMSLength = 500,
    	PlaceTracersUnderCharacter = false, -- Change to true if you want tracers to be placed under your character instead of at the bottom of your camera.
    	FreeForAll = false, -- use for games that don't have teams (Apocalypse Rising)
    	AutoFire = false,
    	MobChams = false,
    	MobESP = false,
    	AimbotKey = "Enum.UserInputType.MouseButton2", -- Doesn't do anything yet.
    	Colors = {
    		Enemy = Color3.new(1, 0, 0),
    		Ally = Color3.new(0, 1, 0),
    		Friend = Color3.new(1, 1, 0),
    		Neutral = Color3.new(1, 1, 1),
    		Crosshair = Color3.new(1, 0, 0),
    		ColorOverride = nil, -- Every player will have the chosen color regardless of enemy or ally.
    	},

    	-- VVVV DON'T EDIT BELOW VVVV --
    	ClosestEnemy = nil,
    	CharAddedEvent = { },
    	OutlinedParts = { },
    	WorkspaceChildAddedEvent = nil,
    	LightingEvent = nil,
    	AmbientBackup = Light.Ambient,
    	ColorShiftBotBackup = Light.ColorShift_Bottom,
    	ColorShiftTopBackup = Light.ColorShift_Top,
    	FPSAverage = { },
    	Blacklist = { },
    	FriendList = { },
    	CameraModeBackup = MyPlr.CameraMode,
    	GameSpecificCrap = { 
    	},
    	Mob_ESP_CHAMS_Ran_Once = false,
    }

    function SaveBullshitSettings()
    	local temp = { }
    	local succ, out = pcall(function()
    		temp.TracersLength = Bullshit.TracersLength
    		temp.ESPLength = Bullshit.ESPLength
    		temp.CHAMSLength = Bullshit.CHAMSLength
    		temp.PlaceTracersUnderCharacter = Bullshit.PlaceTracersUnderCharacter
    		temp.FreeForAll = Bullshit.FreeForAll
    		temp.AutoFire = Bullshit.AutoFire
    		temp.AimbotKey = tostring(Bullshit.AimbotKey)
    		temp.MobChams = Bullshit.MobChams
    		temp.MobESP = Bullshit.MobESP
    		temp.Colors = { }
    		for i, v in next, Bullshit.Colors do
    			temp.Colors[i] = tostring(v)
    		end
    		writefile("ProjectBullshit.txt", HTTP:JSONEncode(temp))
    	end)
    	if not succ then
    		error(out)
    	end
    end

    fuck = pcall(function()
    	local temp = HTTP:JSONDecode(readfile("ProjectBullshit.txt"))
    	if temp.MobChams ~= nil and temp.MobESP ~= nil then
    		for i, v in next, temp do
    			if i ~= "Colors" then
    				Bullshit[i] = v
    			end
    		end
    		for i, v in next, temp.Colors do
    			local r, g, b = string.match(RemoveSpacesFromString(v), "(%d+),(%d+),(%d+)")
    			r = tonumber(r)
    			g = tonumber(g)
    			b = tonumber(b)

    			temp.Colors[i] = Color3.new(r, g, b)
    		end
    		Bullshit.Colors = temp.Colors
    	else
    		spawn(function()
    			SaveBullshitSettings()
    			local hint = Instance.new("Hint", CoreGui)
    			hint.Text = "Major update requried your settings to be wiped! Sorry!"
    			wait(5)
    			hint:Destroy()
    		end)
    	end

    	Bullshit.AutoFire = false
    end)

    -- Load blacklist file if it exists
    fuck2 = pcall(function()
    	Bullshit.Blacklist = HTTP:JSONDecode(readfile("Blacklist.txt"))
    end)

    fuck3 = pcall(function()
    	Bullshit.FriendList = HTTP:JSONDecode(readfile("Whitelist.txt"))
    end)

    local DebugMenu = { }
    DebugMenu["SC"] = Instance.new("ScreenGui", CoreGui)
    DebugMenu["SC"].Name = "Debug"
    DebugMenu["Main"] = Instance.new("Frame", DebugMenu["SC"])
    DebugMenu["Main"].Name = "Debug Menu"
    DebugMenu["Main"].Position = UDim2.new(0, 20, 1, -220)
    DebugMenu["Main"].Size = UDim2.new(1, 0, 0, 200)
    DebugMenu["Main"].BackgroundTransparency = 1
    DebugMenu["Main"].Visible = false
    if game.PlaceId == 606849621 then
    	DebugMenu["Main"].Position = UDim2.new(0, 230, 1, -220)
    end
    DebugMenu["Main"].Draggable = true
    DebugMenu["Main"].Active = true
    DebugMenu["Position"] = Instance.new("TextLabel", DebugMenu["Main"])
    DebugMenu["Position"].BackgroundTransparency = 1
    DebugMenu["Position"].Position = UDim2.new(0, 0, 0, 0)
    DebugMenu["Position"].Size = UDim2.new(1, 0, 0, 15)
    DebugMenu["Position"].Font = "Arcade"
    DebugMenu["Position"].Text = ""
    DebugMenu["Position"].TextColor3 = Color3.new(1, 1, 1)
    DebugMenu["Position"].TextSize = 15
    DebugMenu["Position"].TextStrokeColor3 = Color3.new(0, 0, 0)
    DebugMenu["Position"].TextStrokeTransparency = 0.3
    DebugMenu["Position"].TextXAlignment = "Left"
    DebugMenu["FPS"] = Instance.new("TextLabel", DebugMenu["Main"])
    DebugMenu["FPS"].BackgroundTransparency = 1
    DebugMenu["FPS"].Position = UDim2.new(0, 0, 0, 15)
    DebugMenu["FPS"].Size = UDim2.new(1, 0, 0, 15)
    DebugMenu["FPS"].Font = "Arcade"
    DebugMenu["FPS"].Text = ""
    DebugMenu["FPS"].TextColor3 = Color3.new(1, 1, 1)
    DebugMenu["FPS"].TextSize = 15
    DebugMenu["FPS"].TextStrokeColor3 = Color3.new(0, 0, 0)
    DebugMenu["FPS"].TextStrokeTransparency = 0.3
    DebugMenu["FPS"].TextXAlignment = "Left"
    DebugMenu["PlayerSelected"] = Instance.new("TextLabel", DebugMenu["Main"])
    DebugMenu["PlayerSelected"].BackgroundTransparency = 1
    DebugMenu["PlayerSelected"].Position = UDim2.new(0, 0, 0, 35)
    DebugMenu["PlayerSelected"].Size = UDim2.new(1, 0, 0, 15)
    DebugMenu["PlayerSelected"].Font = "Arcade"
    DebugMenu["PlayerSelected"].Text = ""
    DebugMenu["PlayerSelected"].TextColor3 = Color3.new(1, 1, 1)
    DebugMenu["PlayerSelected"].TextSize = 15
    DebugMenu["PlayerSelected"].TextStrokeColor3 = Color3.new(0, 0, 0)
    DebugMenu["PlayerSelected"].TextStrokeTransparency = 0.3
    DebugMenu["PlayerSelected"].TextXAlignment = "Left"
    DebugMenu["PlayerTeam"] = Instance.new("TextLabel", DebugMenu["Main"])
    DebugMenu["PlayerTeam"].BackgroundTransparency = 1
    DebugMenu["PlayerTeam"].Position = UDim2.new(0, 0, 0, 50)
    DebugMenu["PlayerTeam"].Size = UDim2.new(1, 0, 0, 15)
    DebugMenu["PlayerTeam"].Font = "Arcade"
    DebugMenu["PlayerTeam"].Text = ""
    DebugMenu["PlayerTeam"].TextColor3 = Color3.new(1, 1, 1)
    DebugMenu["PlayerTeam"].TextSize = 15
    DebugMenu["PlayerTeam"].TextStrokeColor3 = Color3.new(0, 0, 0)
    DebugMenu["PlayerTeam"].TextStrokeTransparency = 0.3
    DebugMenu["PlayerTeam"].TextXAlignment = "Left"
    DebugMenu["PlayerHealth"] = Instance.new("TextLabel", DebugMenu["Main"])
    DebugMenu["PlayerHealth"].BackgroundTransparency = 1
    DebugMenu["PlayerHealth"].Position = UDim2.new(0, 0, 0, 65)
    DebugMenu["PlayerHealth"].Size = UDim2.new(1, 0, 0, 15)
    DebugMenu["PlayerHealth"].Font = "Arcade"
    DebugMenu["PlayerHealth"].Text = ""
    DebugMenu["PlayerHealth"].TextColor3 = Color3.new(1, 1, 1)
    DebugMenu["PlayerHealth"].TextSize = 15
    DebugMenu["PlayerHealth"].TextStrokeColor3 = Color3.new(0, 0, 0)
    DebugMenu["PlayerHealth"].TextStrokeTransparency = 0.3
    DebugMenu["PlayerHealth"].TextXAlignment = "Left"
    DebugMenu["PlayerPosition"] = Instance.new("TextLabel", DebugMenu["Main"])
    DebugMenu["PlayerPosition"].BackgroundTransparency = 1
    DebugMenu["PlayerPosition"].Position = UDim2.new(0, 0, 0, 80)
    DebugMenu["PlayerPosition"].Size = UDim2.new(1, 0, 0, 15)
    DebugMenu["PlayerPosition"].Font = "Arcade"
    DebugMenu["PlayerPosition"].Text = ""
    DebugMenu["PlayerPosition"].TextColor3 = Color3.new(1, 1, 1)
    DebugMenu["PlayerPosition"].TextSize = 15
    DebugMenu["PlayerPosition"].TextStrokeColor3 = Color3.new(0, 0, 0)
    DebugMenu["PlayerPosition"].TextStrokeTransparency = 0.3
    DebugMenu["PlayerPosition"].TextXAlignment = "Left"
    DebugMenu["BehindWall"] = Instance.new("TextLabel", DebugMenu["Main"])
    DebugMenu["BehindWall"].BackgroundTransparency = 1
    DebugMenu["BehindWall"].Position = UDim2.new(0, 0, 0, 95)
    DebugMenu["BehindWall"].Size = UDim2.new(1, 0, 0, 15)
    DebugMenu["BehindWall"].Font = "Arcade"
    DebugMenu["BehindWall"].Text = ""
    DebugMenu["BehindWall"].TextColor3 = Color3.new(1, 1, 1)
    DebugMenu["BehindWall"].TextSize = 15
    DebugMenu["BehindWall"].TextStrokeColor3 = Color3.new(0, 0, 0)
    DebugMenu["BehindWall"].TextStrokeTransparency = 0.3
    DebugMenu["BehindWall"].TextXAlignment = "Left"

    local LastTick = tick()
    local FPSTick = tick()

    if #Teams:GetChildren() <= 0 then
    	Bullshit.FreeForAll = true
    end

    if Bullshit.TracersLength > 2048 then
    	Bullshit.TracersLength = 2048
    end

    if Bullshit.CHAMSLength > 2048 then
    	Bullshit.CHAMSLength = 2048
    end

    local wildrevolvertick = tick()
    local wildrevolverteamdata = nil
    function GetTeamColor(Plr)
    	if Plr == nil then return nil end
    	if not Plr:IsA("Player") then
    		return nil
    	end
    	local PickedColor = Bullshit.Colors.Enemy
	
    	if Plr ~= nil then
    		if game.PlaceId == 606849621 then
    			if Bullshit.Colors.ColorOverride == nil then
    				if not Bullshit.FreeForAll then
    					if MyPlr.Team ~= nil and Plr.Team ~= nil then
    						if Bullshit.FriendList[Plr.Name] == nil then
    							if MyPlr.Team.Name == "Prisoner" then
    								if Plr.Team == MyPlr.Team or Plr.Team.Name == "Criminal" then
    									PickedColor = Bullshit.Colors.Ally
    								else
    									PickedColor = Bullshit.Colors.Enemy
    								end
    							elseif MyPlr.Team.Name == "Criminal" then
    								if Plr.Team == MyPlr.Team or Plr.Team.Name == "Prisoner" then
    									PickedColor = Bullshit.Colors.Ally
    								else
    									PickedColor = Bullshit.Colors.Enemy
    								end
    							elseif MyPlr.Team.Name == "Police" then
    								if Plr.Team == MyPlr.Team then
    									PickedColor = Bullshit.Colors.Ally
    								else
    									if Plr.Team.Name == "Criminal" then
    										PickedColor = Bullshit.Colors.Enemy
    									elseif Plr.Team.Name == "Prisoner" then
    										PickedColor = Bullshit.Colors.Neutral
    									end
    								end
    							end
    						else
    							PickedColor = Bullshit.Colors.Friend
    						end
    					end
    				else
    					if Bullshit.FriendList[Plr.Name] ~= nil then
    						PickedColor = Bullshit.Colors.Friend
    					else
    						PickedColor = Bullshit.Colors.Enemy
    					end
    				end
    			else
    				PickedColor = Bullshit.Colors.ColorOverride
    			end
    		elseif game.PlaceId == 155615604 then
    			if Bullshit.Colors.ColorOverride == nil then
    				if MyPlr.Team ~= nil and Plr.Team ~= nil then
    					if Bullshit.FriendList[Plr.Name] == nil then
    						if MyPlr.Team.Name == "Inmates" then
    							if Plr.Team.Name == "Inmates" then
    								PickedColor = Bullshit.Colors.Ally
    							elseif Plr.Team.Name == "Guards" or Plr.Team.Name == "Criminals" then
    								PickedColor = Bullshit.Colors.Enemy
    							else
    								PickedColor = Bullshit.Colors.Neutral
    							end
    						elseif MyPlr.Team.Name == "Guards" then
    							if Plr.Team.Name == "Inmates" then
    								PickedColor = Bullshit.Colors.Neutral
    							elseif Plr.Team.Name == "Criminals" then
    								PickedColor = Bullshit.Colors.Enemy
    							elseif Plr.Team.Name == "Guards" then
    								PickColor = Bullshit.Colors.Ally
    							end
    						elseif MyPlr.Team.Name == "Criminals" then
    							if Plr.Team.Name == "Inmates" then
    								PickedColor = Bullshit.Colors.Ally
    							elseif Plr.Team.Name == "Guards" then
    								PickedColor = Bullshit.Colors.Enemy
    							else
    								PickedColor = Bullshit.Colors.Neutral
    							end
    						end
    					else
    						PickedColor = Bullshit.Colors.Friend
    					end
    				end
    			else
    				PickedColor = Bullshit.Colors.ColorOverride
    			end
    		elseif game.PlaceId == 746820961 then
    			if Bullshit.Colors.ColorOverride == nil then
    				if MyPlr:FindFirstChild("TeamC") and Plr:FindFirstChild("TeamC") then
    					if Plr.TeamC.Value == MyPlr.TeamC.Value then
    						PickedColor = Bullshit.Colors.Ally
    					else
    						PickedColor = Bullshit.Colors.Enemy
    					end
    				end
    			else
    				PickedColor = Bullshit.Colors.ColorOverride
    			end
    		elseif game.PlaceId == 1382113806 then
    			if Bullshit.Colors.ColorOverride == nil then
    				if MyPlr:FindFirstChild("role") and Plr:FindFirstChild("role") then
    					if MyPlr.role.Value == "assassin" then
    						if Plr.role.Value == "target" then
    							PickedColor = Bullshit.Colors.Enemy
    						elseif Plr.role.Value == "guard" then
    							PickedColor = Color3.new(1, 135 / 255, 0)
    						else
    							PickedColor = Bullshit.Colors.Neutral
    						end
    					elseif MyPlr.role.Value == "target" then
    						if Plr.role.Value == "guard" then
    							PickedColor = Bullshit.Colors.Ally
    						elseif Plr.role.Value == "assassin" then
    							PickedColor = Bullshit.Colors.Enemy
    						else
    							PickedColor = Bullshit.Colors.Neutral
    						end
    					elseif MyPlr.role.Value == "guard" then
    						if Plr.role.Value == "target" then
    							PickedColor = Bullshit.Colors.Friend
    						elseif Plr.role.Value == "guard" then
    							PickedColor = Bullshit.Colors.Ally
    						elseif Plr.role.Value == "assassin" then
    							PickedColor = Bullshit.Colors.Enemy
    						else
    							PickedColor = Bullshit.Colors.Neutral
    						end
    					else
    						if MyPlr.role.Value == "none" then
    							PickedColor = Bullshit.Colors.Neutral
    						end
    					end
    				end
    			else
    				PickedColor = Bullshit.Colors.ColorOverride
    			end
    		elseif game.PlaceId == 1072809192 then
    			if MyPlr:FindFirstChild("Backpack") and Plr:FindFirstChild("Backpack") then
    				if MyPlr.Backpack:FindFirstChild("Knife") or MyChar:FindFirstChild("Knife") then
    					if Plr.Backpack:FindFirstChild("Revolver") or Plr.Character:FindFirstChild("Revolver") then
    						PickedColor = Bullshit.Colors.Enemy
    					else
    						PickedColor = Color3.new(1, 135 / 255, 0)
    					end
    				elseif MyPlr.Backpack:FindFirstChild("Revolver") or MyChar:FindFirstChild("Revolver") then
    					if Plr.Backpack:FindFirstChild("Knife") or Plr.Character:FindFirstChild("Knife") then
    						PickedColor = Bullshit.Colors.Enemy
    					elseif Plr.Backpack:FindFirstChild("Revolver") or Plr.Character:FindFirstChild("Revolver") then
    						PickedColor = Bullshit.Colors.Enemy
    					else
    						PickedColor = Bullshit.Colors.Ally
    					end
    				else
    					if Plr.Backpack:FindFirstChild("Knife") or Plr.Character:FindFirstChild("Knife") then
    						PickedColor = Bullshit.Colors.Enemy
    					elseif Plr.Backpack:FindFirstChild("Revolver") or Plr.Character:FindFirstChild("Revolver") then
    						PickedColor = Bullshit.Colors.Ally
    					else
    						PickedColor = Bullshit.Colors.Neutral
    					end
    				end
    			end
    		elseif game.PlaceId == 142823291 or game.PlaceId == 1122507250 then
    			if MyPlr:FindFirstChild("Backpack") and Plr:FindFirstChild("Backpack") then
    				if MyPlr.Backpack:FindFirstChild("Knife") or MyChar:FindFirstChild("Knife") then
    					if (Plr.Backpack:FindFirstChild("Gun") or Plr.Backpack:FindFirstChild("Revolver")) or (Plr.Character:FindFirstChild("Gun") or Plr.Character:FindFirstChild("Revolver")) then
    						PickedColor = Bullshit.Colors.Enemy
    					else
    						PickedColor = Color3.new(1, 135 / 255, 0)
    					end
    				elseif (MyPlr.Backpack:FindFirstChild("Gun") or MyPlr.Backpack:FindFirstChild("Revolver")) or (MyChar:FindFirstChild("Gun") or MyChar:FindFirstChild("Revolver")) then
    					if Plr.Backpack:FindFirstChild("Knife") or Plr.Character:FindFirstChild("Knife") then
    						PickedColor = Bullshit.Colors.Enemy
    					else
    						PickedColor = Bullshit.Colors.Ally
    					end
    				else
    					if Plr.Backpack:FindFirstChild("Knife") or Plr.Character:FindFirstChild("Knife") then
    						PickedColor = Bullshit.Colors.Enemy
    					elseif (Plr.Backpack:FindFirstChild("Gun") or Plr.Backpack:FindFirstChild("Revolver")) or (Plr.Character:FindFirstChild("Gun") or Plr.Character:FindFirstChild("Revolver")) then
    						PickedColor = Bullshit.Colors.Ally
    					else
    						PickedColor = Bullshit.Colors.Neutral
    					end
    				end
    			end
    		elseif game.PlaceId == 379614936 then
    			if Bullshit.Colors.ColorOverride == nil then
    				if not Bullshit.FriendList[Plr.Name] then
    					local targ = MyPlr:FindFirstChild("PlayerGui"):FindFirstChild("ScreenGui"):FindFirstChild("UI"):FindFirstChild("Target"):FindFirstChild("Img"):FindFirstChild("PlayerText")
    					if targ then
    						if Plr.Name:lower() == targ.Text:lower() then
    							PickedColor = Bullshit.Colors.Enemy
    						else
    							PickedColor = Bullshit.Colors.Neutral
    						end
    					else
    						PickedColor = Bullshit.Colors.Neutral
    					end
    				else
    					PickedColor = Bullshit.Colors.Friend
    				end
    			else
    				PickedColor = Bullshit.Colors.ColorOverride
    			end
    		elseif game.PlaceId == 983224898 then
    			if (tick() - wildrevolvertick) > 10 or wildrevolverteamdata == nil then
    				wildrevolverteamdata = RepStor.Functions.RequestGameData:InvokeServer()
    				wildrevolvertick = tick()
    				return Bullshit.Colors.Neutral
    			end
    			local succ = pcall(function()
    				if wildrevolverteamdata[Plr.Name] ~= nil then
    					if Bullshit.Colors.ColorOverride == nil then
    						if not Bullshit.FriendList[Plr.Name] then
    							if wildrevolverteamdata[Plr.Name]["TeamName"] == wildrevolverteamdata[MyPlr.Name]["TeamName"] then
    								PickedColor = Bullshit.Colors.Ally
    							else
    								PickedColor = Bullshit.Colors.Enemy
    							end
    						else
    							PickedColor = Bullshit.Colors.Friend
    						end
    					else
    						PickedColor = Bullshit.Colors.ColorOverride
    					end
    				else
    					PickedColor = Bullshit.Colors.Neutral
    				end
    			end)
    			if not succ then
    				wildrevolverteamdata = RepStor.Functions.RequestGameData:InvokeServer()
    				wildrevolvertick = tick()
    				return Bullshit.Colors.Neutral
    			end
    		else
    			if Bullshit.Colors.ColorOverride == nil then
    				if not Bullshit.FreeForAll then
    					if MyPlr.Team ~= Plr.Team and not Bullshit.FriendList[Plr.Name] then
    						PickedColor = Bullshit.Colors.Enemy
    					elseif MyPlr.Team == Plr.Team and not Bullshit.FriendList[Plr.Name] then
    						PickedColor = Bullshit.Colors.Ally
    					else
    						PickedColor = Bullshit.Colors.Friend
    					end
    				else
    					if Bullshit.FriendList[Plr.Name] ~= nil then
    						PickedColor = Bullshit.Colors.Friend
    					else
    						PickedColor = Bullshit.Colors.Enemy
    					end
    				end
    			else
    				PickedColor = Bullshit.Colors.ColorOverride
    			end
    		end
    	end
	
    	return PickedColor
    end

    function FindCham(Obj)
    	for i, v in next, ItemChams:GetChildren() do
    		if v.className == "ObjectValue" then
    			if v.Value == Obj then
    				return v.Parent
    			end
    		end
    	end

    	return nil
    end

    function FindESP(Obj)
    	for i, v in next, ItemESP:GetChildren() do
    		if v.className == "ObjectValue" then
    			if v.Value == Obj then
    				return v.Parent
    			end
    		end
    	end

    	return nil
    end

    function GetFirstPart(Obj)
    	for i, v in next, Obj:GetDescendants() do
    		if v:IsA("BasePart") then
    			return v
    		end
    	end

    	return nil
    end

    function GetSizeOfObject(Obj)
    	if Obj:IsA("BasePart") then
    		return Obj.Size
    	elseif Obj:IsA("Model") then
    		return Obj:GetExtentsSize()
    	end
    end

    function GetClosestPlayerNotBehindWall()
    	local Players = { }
    	local CurrentClosePlayer = nil
    	local SelectedPlr = nil

    	for _, v in next, Plrs:GetPlayers() do
    		if v ~= MyPlr and not Bullshit.Blacklist[v.Name] then
    			local IsAlly = GetTeamColor(v)
    			if IsAlly ~= Bullshit.Colors.Ally and IsAlly ~= Bullshit.Colors.Friend and IsAlly ~= Bullshit.Colors.Neutral then
    				local GetChar = v.Character
    				if MyChar and GetChar then
    					local MyHead, MyTor = MyChar:FindFirstChild("Head"), MyChar:FindFirstChild("HumanoidRootPart")
    					local GetHead, GetTor, GetHum = GetChar:FindFirstChild("Head"), GetChar:FindFirstChild("HumanoidRootPart"), GetChar:FindFirstChild("Humanoid")

    					if MyHead and MyTor and GetHead and GetTor and GetHum then
    						if game.PlaceId == 455366377 then
    							if not GetChar:FindFirstChild("KO") and GetHum.Health > 1 then
    								local Ray = Ray.new(MyCam.CFrame.p, (GetHead.Position - MyCam.CFrame.p).unit * 2048)
    								local part = workspace:FindPartOnRayWithIgnoreList(Ray, {MyChar})
    								if part ~= nil then
    									if part:IsDescendantOf(GetChar) then
    										local Dist = (MyTor.Position - GetTor.Position).magnitude
    										Players[v] = Dist
    									end
    								end
    							end
    						elseif game.PlaceId == 746820961 then
    							if GetHum.Health > 1 then
    								local Ray = Ray.new(MyCam.CFrame.p, (GetHead.Position - MyCam.CFrame.p).unit * 2048)
    								local part = workspace:FindPartOnRayWithIgnoreList(Ray, {MyChar, MyCam})
    								if part ~= nil then
    									if part:IsDescendantOf(GetChar) then
    										local Dist = (MyTor.Position - GetTor.Position).magnitude
    										Players[v] = Dist
    									end
    								end
    							end
    						else
    							if GetHum.Health > 1 then
    								local Ray = Ray.new(MyCam.CFrame.p, (GetHead.Position - MyCam.CFrame.p).unit * 2048)
    								local part = workspace:FindPartOnRayWithIgnoreList(Ray, {MyChar})
    								if part ~= nil then
    									if part:IsDescendantOf(GetChar) then
    										local Dist = (MyTor.Position - GetTor.Position).magnitude
    										Players[v] = Dist
    									end
    								end
    							end
    						end
    					end
    				end
    			end
    		end
    	end

    	for i, v in next, Players do
    		if CurrentClosePlayer ~= nil then
    			if v <= CurrentClosePlayer then
    				CurrentClosePlayer = v
    				SelectedPlr = i
    			end
    		else
    			CurrentClosePlayer = v
    			SelectedPlr = i
    		end
    	end
	
    	return SelectedPlr
    end

    function GetClosestPlayer()
    	local Players = { }
    	local CurrentClosePlayer = nil
    	local SelectedPlr = nil
	
    	for _, v in next, Plrs:GetPlayers() do
    		if v ~= MyPlr then
    			local IsAlly = GetTeamColor(v)
    			if IsAlly ~= Bullshit.Colors.Ally and IsAlly ~= Bullshit.Colors.Friend and IsAlly ~= Bullshit.Colors.Neutral then
    				local GetChar = v.Character
    				if MyChar and GetChar then
    					local MyTor = MyChar:FindFirstChild("HumanoidRootPart")
    					local GetTor = GetChar:FindFirstChild("HumanoidRootPart")
    					local GetHum = GetChar:FindFirstChild("Humanoid")
    					if MyTor and GetTor and GetHum then
    						if game.PlaceId == 455366377 then
    							if not GetChar:FindFirstChild("KO") and GetHum.Health > 1 then
    								local Dist = (MyTor.Position - GetTor.Position).magnitude
    								Players[v] = Dist
    							end
    						else
    							if GetHum.Health > 1 then
    								local Dist = (MyTor.Position - GetTor.Position).magnitude
    								Players[v] = Dist
    							end
    						end
    					end
    				end
    			end
    		end
    	end
	
    	for i, v in next, Players do
    		if CurrentClosePlayer ~= nil then
    			if v <= CurrentClosePlayer then
    				CurrentClosePlayer = v
    				SelectedPlr = i
    			end
    		else
    			CurrentClosePlayer = v
    			SelectedPlr = i
    		end
    	end
	
    	return SelectedPlr
    end

    function FindPlayer(Txt)
    	local ps = { }
    	for _, v in next, Plrs:GetPlayers() do
    		if string.lower(string.sub(v.Name, 1, string.len(Txt))) == string.lower(Txt) then
    			table.insert(ps, v)
    		end
    	end

    	if #ps == 1 then
    		if ps[1] ~= MyPlr then
    			return ps[1]
    		else
    			return nil
    		end
    	else
    		return nil
    	end
    end

    function UpdateESP(Plr)
    	if Plr ~= nil then
    		local Find = PlayerESP:FindFirstChild("ESP Crap_" .. Plr.Name)
    		if Find then
    			local PickColor = GetTeamColor(Plr)
    			Find.Frame.Names.TextColor3 = PickColor
    			Find.Frame.Dist.TextColor3 = PickColor
    			Find.Frame.Health.TextColor3 = PickColor
    			--Find.Frame.Pos.TextColor3 = PickColor
    			local GetChar = Plr.Character
    			if MyChar and GetChar then
    				local Find2 = MyChar:FindFirstChild("HumanoidRootPart")
    				local Find3 = GetChar:FindFirstChild("HumanoidRootPart")
    				local Find4 = GetChar:FindFirstChildOfClass("Humanoid")
    				if Find2 and Find3 then
    					local pos = Find3.Position
    					local Dist = (Find2.Position - pos).magnitude
    					if Dist > Bullshit.ESPLength or Bullshit.Blacklist[Plr.Name] then
    						Find.Frame.Names.Visible = false
    						Find.Frame.Dist.Visible = false
    						Find.Frame.Health.Visible = false
    						return
    					else
    						Find.Frame.Names.Visible = true
    						Find.Frame.Dist.Visible = true
    						Find.Frame.Health.Visible = true
    					end
    					Find.Frame.Dist.Text = "Distance: " .. string.format("%.0f", Dist)
    					--Find.Frame.Pos.Text = "(X: " .. string.format("%.0f", pos.X) .. ", Y: " .. string.format("%.0f", pos.Y) .. ", Z: " .. string.format("%.0f", pos.Z) .. ")"
    					if Find4 then
    						Find.Frame.Health.Text = "Health: " .. string.format("%.0f", Find4.Health)
    					else
    						Find.Frame.Health.Text = ""
    					end
    				end
    			end
    		end
    	end
    end

    function RemoveESP(Obj)
    	if Obj ~= nil then
    		local IsPlr = Obj:IsA("Player")
    		local UseFolder = ItemESP
    		if IsPlr then UseFolder = PlayerESP end

    		local FindESP = ((IsPlr) and UseFolder:FindFirstChild("ESP Crap_" .. Obj.Name)) or FindESP(Obj)
    		if FindESP then
    			FindESP:Destroy()
    		end
    	end
    end

    function CreateESP(Obj)
    	if Obj ~= nil then
    		local IsPlr = Obj:IsA("Player")
    		local UseFolder = ItemESP
    		local GetChar = ((IsPlr) and Obj.Character) or Obj
    		local Head = GetChar:FindFirstChild("Head")
    		local t = tick()
    		if IsPlr then UseFolder = PlayerESP end
    		if Head == nil then
    			repeat
    				Head = GetChar:FindFirstChild("Head")
    				wait()
    			until Head ~= nil or (tick() - t) >= 10
    		end
    		if Head == nil then return end
		
    		local bb = Instance.new("BillboardGui")
    		bb.Adornee = Head
    		bb.ExtentsOffset = Vector3.new(0, 1, 0)
    		bb.AlwaysOnTop = true
    		bb.Size = UDim2.new(0, 5, 0, 5)
    		bb.StudsOffset = Vector3.new(0, 3, 0)
    		bb.Name = "ESP Crap_" .. Obj.Name
    		bb.Parent = UseFolder
		
    		local frame = Instance.new("Frame", bb)
    		frame.ZIndex = 10
    		frame.BackgroundTransparency = 1
    		frame.Size = UDim2.new(1, 0, 1, 0)
		
    		local TxtName = Instance.new("TextLabel", frame)
    		TxtName.Name = "Names"
    		TxtName.ZIndex = 10
    		TxtName.Text = Obj.Name
    		TxtName.BackgroundTransparency = 1
    		TxtName.Position = UDim2.new(0, 0, 0, -45)
    		TxtName.Size = UDim2.new(1, 0, 10, 0)
    		TxtName.Font = "SourceSansBold"
    		TxtName.TextSize = 13
    		TxtName.TextStrokeTransparency = 0.5

    		local TxtDist = nil
    		local TxtHealth = nil
    		if IsPlr then
    			TxtDist = Instance.new("TextLabel", frame)
    			TxtDist.Name = "Dist"
    			TxtDist.ZIndex = 10
    			TxtDist.Text = ""
    			TxtDist.BackgroundTransparency = 1
    			TxtDist.Position = UDim2.new(0, 0, 0, -35)
    			TxtDist.Size = UDim2.new(1, 0, 10, 0)
    			TxtDist.Font = "SourceSansBold"
    			TxtDist.TextSize = 13
    			TxtDist.TextStrokeTransparency = 0.5

    			TxtHealth = Instance.new("TextLabel", frame)
    			TxtHealth.Name = "Health"
    			TxtHealth.ZIndex = 10
    			TxtHealth.Text = ""
    			TxtHealth.BackgroundTransparency = 1
    			TxtHealth.Position = UDim2.new(0, 0, 0, -25)
    			TxtHealth.Size = UDim2.new(1, 0, 10, 0)
    			TxtHealth.Font = "SourceSansBold"
    			TxtHealth.TextSize = 13
    			TxtHealth.TextStrokeTransparency = 0.5
    		else
    			local ObjVal = Instance.new("ObjectValue", bb)
    			ObjVal.Value = Obj
    		end
		
    		local PickColor = GetTeamColor(Obj) or Bullshit.Colors.Neutral
    		TxtName.TextColor3 = PickColor

    		if IsPlr then
    			TxtDist.TextColor3 = PickColor
    			TxtHealth.TextColor3 = PickColor
    		end
    	end
    end

    function UpdateTracer(Plr)
    	if Bullshit.TracersEnabled then
    		if MyChar then
    			local MyTor = MyChar:FindFirstChild("HumanoidRootPart")
    			local GetTor = TracerData[Plr.Name]
    			if MyTor and GetTor ~= nil and GetTor.Parent ~= nil then
    				local Dist = (MyTor.Position - GetTor.Position).magnitude
    				if (Dist < Bullshit.TracersLength and not Bullshit.Blacklist[Plr.Name]) and not (MyChar:FindFirstChild("InVehicle") or GetTor.Parent:FindFirstChild("InVehicle")) then
    					if not Bullshit.PlaceTracersUnderCharacter then
    						local R = MyCam:ScreenPointToRay(MyCam.ViewportSize.X / 2, MyCam.ViewportSize.Y, 0)
    						Dist = (R.Origin - (GetTor.Position - Vector3.new(0, 3, 0))).magnitude
    						Tracers[Plr.Name].Transparency = 1
    						Tracers[Plr.Name].Size = Vector3.new(0.05, 0.05, Dist)
    						Tracers[Plr.Name].CFrame = CFrame.new(R.Origin, (GetTor.Position - Vector3.new(0, 4.5, 0))) * CFrame.new(0, 0, -Dist / 2)
    						Tracers[Plr.Name].BrickColor = BrickColor.new(GetTeamColor(Plr))
    						Tracers[Plr.Name].BoxHandleAdornment.Transparency = 0
    						Tracers[Plr.Name].BoxHandleAdornment.Size = Vector3.new(0.001, 0.001, Dist)
    						Tracers[Plr.Name].BoxHandleAdornment.Color3 = GetTeamColor(Plr)
    					else
    						Dist = (MyTor.Position - (GetTor.Position - Vector3.new(0, 3, 0))).magnitude
    						Tracers[Plr.Name].Transparency = 1
    						Tracers[Plr.Name].Size = Vector3.new(0.3, 0.3, Dist)
    						Tracers[Plr.Name].CFrame = CFrame.new(MyTor.Position - Vector3.new(0, 3, 0), (GetTor.Position - Vector3.new(0, 4.5, 0))) * CFrame.new(0, 0, -Dist / 2)
    						Tracers[Plr.Name].BrickColor = BrickColor.new(GetTeamColor(Plr))
    						Tracers[Plr.Name].BoxHandleAdornment.Transparency = 0
    						Tracers[Plr.Name].BoxHandleAdornment.Size = Vector3.new(0.05, 0.05, Dist)
    						Tracers[Plr.Name].BoxHandleAdornment.Color3 = GetTeamColor(Plr)
    					end
    				else
    					Tracers[Plr.Name].Transparency = 1
    					Tracers[Plr.Name].BoxHandleAdornment.Transparency = 1
    				end
    			end
    		end
    	end
    end

    function RemoveTracers(Plr)
    	local Find = Tracers:FindFirstChild(Plr.Name)
    	if Find then
    		Find:Destroy()
    	end
    end

    function CreateTracers(Plr)
    	local Find = Tracers:FindFirstChild(Plr.Name)
    	if not Find then
    		local P = Instance.new("Part")
    		P.Name = Plr.Name
    		P.Material = "Neon"
    		P.Transparency = 1
    		P.Anchored = true
    		P.Locked = true
    		P.CanCollide = false
    		local B = Instance.new("BoxHandleAdornment", P)
    		B.Adornee = P
    		B.Size = GetSizeOfObject(P)
    		B.AlwaysOnTop = true
    		B.ZIndex = 5
    		B.Transparency = 0
    		B.Color3 = GetTeamColor(Plr) or Bullshit.Colors.Neutral
    		P.Parent = Tracers

    		coroutine.resume(coroutine.create(function()
    			while Tracers:FindFirstChild(Plr.Name) do
    				UpdateTracer(Plr)
    				Run.RenderStepped:wait()
    			end
    		end))
    	end
    end

    function UpdateChams(Obj)
    	if Obj == nil then return end

    	if Obj:IsA("Player") then
    		local Find = PlayerChams:FindFirstChild(Obj.Name)
    		local GetChar = Obj.Character

    		local Trans = 0
    		if GetChar and MyChar then
    			local GetHead = GetChar:FindFirstChild("Head")
    			local GetTor = GetChar:FindFirstChild("HumanoidRootPart")
    			local MyHead = MyChar:FindFirstChild("Head")
    			local MyTor = MyChar:FindFirstChild("HumanoidRootPart")
    			if GetHead and GetTor and MyHead and MyTor then
    				if (MyTor.Position - GetTor.Position).magnitude > Bullshit.CHAMSLength or Bullshit.Blacklist[Obj.Name] then
    					Trans = 1
    				else
    					--local MyCharStuff = MyChar:GetDescendants()
    					local Ray = Ray.new(MyCam.CFrame.p, (GetTor.Position - MyCam.CFrame.p).unit * 2048)
    					local part = workspace:FindPartOnRayWithIgnoreList(Ray, {MyChar})
    					if part ~= nil then
    						if part:IsDescendantOf(GetChar) then
    							Trans = 0.9
    						else
    							Trans = 0
    						end
    					end
    				end
    			end
    		end

    		if Find then
    			for i, v in next, Find:GetChildren() do
    				if v.className ~= "ObjectValue" then
    					v.Color3 = GetTeamColor(Obj) or Bullshit.Colors.Neutral
    					v.Transparency = Trans
    				end
    			end
    		end
    	end
    end

    function RemoveChams(Obj)
    	if Obj ~= nil then
    		local IsPlr = Obj:IsA("Player")
    		local UseFolder = ItemChams
    		if IsPlr then UseFolder = PlayerChams end

    		local FindC = UseFolder:FindFirstChild(tostring(Obj)) or FindCham(Obj)
    		if FindC then
    			FindC:Destroy()
    		end
    	end
    end

    function CreateChams(Obj)
    	if Obj ~= nil then
    		local IsPlr = Obj:IsA("Player")
    		local UseFolder = ItemChams
    		local Crap = nil
    		local GetTor = nil
    		local t = tick()
    		if IsPlr then
    			Obj = Obj.Character
    			UseFolder = PlayerChams
    		end
    		if Obj == nil then return end
    		GetTor = Obj:FindFirstChild("HumanoidRootPart") or Obj:WaitForChild("HumanoidRootPart")
    		if IsPlr then Crap = Obj:GetChildren() else Crap = Obj:GetDescendants() end

    		local FindC = ((IsPlr) and UseFolder:FindFirstChild(Obj.Name)) or FindCham(Obj)
    		if not FindC then
    			FindC = Instance.new("Folder", UseFolder)
    			FindC.Name = Obj.Name
    			local ObjVal = Instance.new("ObjectValue", FindC)
    			ObjVal.Value = Obj
    		end

    		for _, P in next, Crap do
    			if P:IsA("PVInstance") and P.Name ~= "HumanoidRootPart" then
    				local Box = Instance.new("BoxHandleAdornment")
    				Box.Size = GetSizeOfObject(P)
    				Box.Name = "Cham"
    				Box.Adornee = P
    				Box.AlwaysOnTop = true
    				Box.ZIndex = 5
    				Box.Transparency = 0
    				Box.Color3 = ((IsPlr) and GetTeamColor(Plrs:GetPlayerFromCharacter(Obj))) or Bullshit.Colors.Neutral
    				Box.Parent = FindC
    			end
    		end
    	end
    end

    function CreateMobESPChams()
    	local mobspawn = { }

    	for i, v in next, workspace:GetDescendants() do
    		local hum = v:FindFirstChildOfClass("Humanoid")
    		if hum and not Plrs:GetPlayerFromCharacter(hum.Parent) and FindCham(v) == nil and FindESP(v) == nil then
    			mobspawn[tostring(v.Parent)] = v.Parent
    			if Bullshit.CHAMSEnabled and Bullshit.MobChams then
    				CreateChams(v)
    			end
    			if Bullshit.ESPEnabled and Bullshit.MobESP then
    				CreateESP(v)
    			end
    		end
    	end

    	if Bullshit.Mob_ESP_CHAMS_Ran_Once == false then
    		for i, v in next, mobspawn do
    			v.ChildAdded:connect(function(Obj)
    				if Bullshit.MobChams then
    					local t = tick()
    					local GetHum = Obj:FindFirstChildOfClass("Humanoid")
    					if GetHum == nil then
    						repeat
    							GetHum = Obj:FindFirstChildOfClass("Humanoid")
    							wait()
    						until GetHum ~= nil or (tick() - t) >= 10
    					end
    					if GetHum == nil then return end

    					CreateChams(Obj)
    				end

    				if Bullshit.MobESP then
    					local t = tick()
    					local GetHum = Obj:FindFirstChildOfClass("Humanoid")
    					if GetHum == nil then
    						repeat
    							GetHum = Obj:FindFirstChildOfClass("Humanoid")
    							wait()
    						until GetHum ~= nil or (tick() - t) >= 10
    					end
    					if GetHum == nil then return end

    					CreateESP(Obj)
    				end
    			end)
    		end

    		Bullshit.Mob_ESP_CHAMS_Ran_Once = true
    	end
    end

    function CreateChildAddedEventFor(Obj)
    	Obj.ChildAdded:connect(function(Obj2)
    		if Bullshit.OutlinesEnabled then
    			if Obj2:IsA("BasePart") and not Plrs:GetPlayerFromCharacter(Obj2.Parent) and not Obj2.Parent:IsA("Hat") and not Obj2.Parent:IsA("Accessory") and Obj2.Parent.Name ~= "Tracers" then
    				local Data = { }
    				Data[2] = Obj2.Transparency
    				Obj2.Transparency = 1
    				local outline = Instance.new("SelectionBox")
    				outline.Name = "Outline"
    				outline.Color3 = Color3.new(0, 0, 0)
    				outline.SurfaceColor3 = Color3.new(0, 1, 0)
    				--outline.SurfaceTransparency = 0.9
    				outline.LineThickness = 0.01
    				outline.Transparency = 0.5
    				outline.Transparency = 0.5
    				outline.Adornee = Obj2
    				outline.Parent = Obj2
    				Data[1] = outline
    				rawset(Bullshit.OutlinedParts, Obj2, Data)
    			end

    			for i, v in next, Obj2:GetDescendants() do
    				if v:IsA("BasePart") and not Plrs:GetPlayerFromCharacter(v.Parent) and not v.Parent:IsA("Hat") and not v.Parent:IsA("Accessory") and v.Parent.Name ~= "Tracers" then
    					local Data = { }
    					Data[2] = v.Transparency
    					v.Transparency = 1
    					local outline = Instance.new("SelectionBox")
    					outline.Name = "Outline"
    					outline.Color3 = Color3.new(0, 0, 0)
    					outline.SurfaceColor3 = Color3.new(0, 1, 0)
    					--outline.SurfaceTransparency = 0.9
    					outline.LineThickness = 0.01
    					outline.Transparency = 0.5
    					outline.Adornee = v
    					outline.Parent = v
    					Data[1] = outline
    					rawset(Bullshit.OutlinedParts, v, Data)
    				end
    				CreateChildAddedEventFor(v)
    			end
    		end
    		CreateChildAddedEventFor(Obj2)
    	end)
    end

    function LightingHax()
    	if Bullshit.OutlinesEnabled then
    		Light.TimeOfDay = "00:00:00"
    	end

    	if Bullshit.FullbrightEnabled then
    		Light.Ambient = Color3.new(1, 1, 1)
    		Light.ColorShift_Bottom = Color3.new(1, 1, 1)
    		Light.ColorShift_Top = Color3.new(1, 1, 1)
    	end
    end

    Plrs.PlayerAdded:connect(function(Plr)
    	if Bullshit.CharAddedEvent[Plr.Name] == nil then
    		Bullshit.CharAddedEvent[Plr.Name] = Plr.CharacterAdded:connect(function(Char)
    			if Bullshit.ESPEnabled then
    				RemoveESP(Plr)
    				CreateESP(Plr)
    			end
    			if Bullshit.CHAMSEnabled then
    				RemoveChams(Plr)
    				CreateChams(Plr)
    			end
    			if Bullshit.TracersEnabled then
    				CreateTracers(Plr)
    			end
    			repeat wait() until Char:FindFirstChild("HumanoidRootPart")
    			TracerMT[Plr.Name] = Char.HumanoidRootPart
    		end)
    	end
    end)

    Plrs.PlayerRemoving:connect(function(Plr)
    	if Bullshit.CharAddedEvent[Plr.Name] ~= nil then
    		Bullshit.CharAddedEvent[Plr.Name]:Disconnect()
    		Bullshit.CharAddedEvent[Plr.Name] = nil
    	end
    	RemoveESP(Plr)
    	RemoveChams(Plr)
    	RemoveTracers(Plr)
    	TracerMT[Plr.Name] = nil
    end)

    function InitMain()
    	-- Objects
	
    	local Bullshit20 = Instance.new("ScreenGui")
    	local MainFrame = Instance.new("Frame")
    	local Title = Instance.new("TextLabel")
    	local design = Instance.new("Frame")
    	local buttons = Instance.new("Frame")
    	local ESPToggle = Instance.new("TextButton")
    	local ChamsToggle = Instance.new("TextButton")
    	local TracersToggle = Instance.new("TextButton")
    	local OutlineToggle = Instance.new("TextButton")
    	local DebugToggle = Instance.new("TextButton")
    	local FullbrightToggle = Instance.new("TextButton")
    	local BlacklistToggle = Instance.new("TextButton")
    	local WhitelistToggle = Instance.new("TextButton")
    	local Crosshair = Instance.new("TextButton")
    	local AimbotToggle = Instance.new("TextButton")
    	local Settings = Instance.new("TextButton")
    	local Information = Instance.new("TextButton")
    	local Information_2 = Instance.new("Frame")
    	local Title_2 = Instance.new("TextLabel")
    	local design_2 = Instance.new("Frame")
    	local buttons_2 = Instance.new("ScrollingFrame")
    	local TextLabel = Instance.new("TextLabel")
    	local Settings_2 = Instance.new("Frame")
    	local Title_3 = Instance.new("TextLabel")
    	local design_3 = Instance.new("Frame")
    	local buttons_3 = Instance.new("ScrollingFrame")
    	local AllyColor = Instance.new("TextBox")
    	local CHAMSLength = Instance.new("TextBox")
    	local CrosshairColor = Instance.new("TextBox")
    	local ESPLength = Instance.new("TextBox")
    	local EnemyColor = Instance.new("TextBox")
    	local FreeForAll = Instance.new("TextButton")
    	local FriendColor = Instance.new("TextBox")
    	local NeutralColor = Instance.new("TextBox")
    	local TracersLength = Instance.new("TextBox")
    	local TracersUnderChars = Instance.new("TextButton")
    	local AutoFireToggle = Instance.new("TextButton")
    	local AimbotKey = Instance.new("TextButton")
    	local MobESPButton = Instance.new("TextButton")
    	local MobChamsButton = Instance.new("TextButton")
    	local TextLabel_2 = Instance.new("TextLabel")
    	local TextLabel_3 = Instance.new("TextLabel")
    	local TextLabel_4 = Instance.new("TextLabel")
    	local TextLabel_5 = Instance.new("TextLabel")
    	local TextLabel_6 = Instance.new("TextLabel")
    	local TextLabel_7 = Instance.new("TextLabel")
    	local TextLabel_8 = Instance.new("TextLabel")
    	local TextLabel_9 = Instance.new("TextLabel")
    	local TextLabel_10 = Instance.new("TextLabel")
    	local TextLabel_11 = Instance.new("TextLabel")
    	local TextLabel_12 = Instance.new("TextLabel")
    	local TextLabel_13 = Instance.new("TextLabel")
    	local TextLabel_14 = Instance.new("TextLabel")
    	local TextLabel_15 = Instance.new("TextLabel")
    	local SaveSettings = Instance.new("TextButton")
    	local Blacklist = Instance.new("Frame")
    	local nigga = Instance.new("TextLabel")
    	local niggerfaggot = Instance.new("Frame")
    	local players = Instance.new("ScrollingFrame")
    	local buttonsex = Instance.new("Frame")
    	local Playername = Instance.new("TextBox")
    	local AddToBlacklist = Instance.new("TextButton")
    	local RemoveToBlacklist = Instance.new("TextButton")
    	local SaveBlacklist = Instance.new("TextButton")
    	local Whitelist = Instance.new("Frame")
    	local nigga2 = Instance.new("TextLabel")
    	local niggerfaggot2 = Instance.new("Frame")
    	local players2 = Instance.new("ScrollingFrame")
    	local buttonsex2 = Instance.new("Frame")
    	local Playername2 = Instance.new("TextBox")
    	local AddToWhitelist = Instance.new("TextButton")
    	local RemoveToWhitelist = Instance.new("TextButton")
    	local SaveWhitelist = Instance.new("TextButton")
	
    	-- Properties
	
    	Bullshit20.Name = "Bullshit 3.0"
    	Bullshit20.Parent = CoreGui
    	Bullshit20.ResetOnSpawn = false
	
    	MainFrame.Name = "MainFrame"
    	MainFrame.Parent = Bullshit20
    	MainFrame.Active = true
    	MainFrame.BackgroundColor3 = Color3.new(0.176471, 0.176471, 0.176471)
    	MainFrame.BorderSizePixel = 0
    	MainFrame.Draggable = true
    	MainFrame.Position = UDim2.new(0.200000003, -175, 0.5, -100)
    	MainFrame.Size = UDim2.new(0, 350, 0, 315)
	
    	Title.Name = "Title"
    	Title.Parent = MainFrame
    	Title.BackgroundColor3 = Color3.new(1, 1, 1)
    	Title.BackgroundTransparency = 1
    	Title.Size = UDim2.new(1, 0, 0, 50)
    	Title.Font = Enum.Font.SourceSansBold
    	Title.Text = "项目：ESP透视\nMade：种族主义海豚#5199\nVersion 3.5.5（重新工作在工作中）"
    	Title.TextColor3 = Color3.new(1, 1, 1)
    	Title.TextSize = 18
    	Title.TextTransparency = 0.5
	
    	design.Name = "design"
    	design.Parent = MainFrame
    	design.BackgroundColor3 = Color3.new(1, 1, 1)
    	design.BackgroundTransparency = 0.5
    	design.BorderSizePixel = 0
    	design.Position = UDim2.new(0.0500000007, 0, 0, 50)
    	design.Size = UDim2.new(0.899999976, 0, 0, 2)
	
    	buttons.Name = "buttons"
    	buttons.Parent = MainFrame
    	buttons.BackgroundColor3 = Color3.new(1, 1, 1)
    	buttons.BackgroundTransparency = 1
    	buttons.Position = UDim2.new(0, 20, 0, 70)
    	buttons.Size = UDim2.new(1, -40, 1, -80)

    	Blacklist.Name = "Blacklist"
    	Blacklist.Parent = MainFrame
    	Blacklist.Active = true
    	Blacklist.BackgroundColor3 = Color3.new(0.176471, 0.176471, 0.176471)
    	Blacklist.BorderSizePixel = 0
    	Blacklist.Position = UDim2.new(1, 3, 0.5, -138)
    	Blacklist.Size = UDim2.new(0, 350, 0, 375)
    	Blacklist.Visible = false
	
    	nigga.Name = "nigga"
    	nigga.Parent = Blacklist
    	nigga.BackgroundColor3 = Color3.new(1, 1, 1)
    	nigga.BackgroundTransparency = 1
    	nigga.Size = UDim2.new(1, 0, 0, 50)
    	nigga.Font = Enum.Font.SourceSansBold
    	nigga.Text = "Blacklist Menu"
    	nigga.TextColor3 = Color3.new(1, 1, 1)
    	nigga.TextSize = 18
    	nigga.TextTransparency = 0.5
	
    	niggerfaggot.Name = "niggerfaggot"
    	niggerfaggot.Parent = Blacklist
    	niggerfaggot.BackgroundColor3 = Color3.new(1, 1, 1)
    	niggerfaggot.BackgroundTransparency = 0.5
    	niggerfaggot.BorderSizePixel = 0
    	niggerfaggot.Position = UDim2.new(0.0500000007, 0, 0, 50)
    	niggerfaggot.Size = UDim2.new(0.899999976, 0, 0, 2)
	
    	players.Name = "players"
    	players.Parent = Blacklist
    	players.BackgroundColor3 = Color3.new(1, 1, 1)
    	players.BackgroundTransparency = 1
    	players.BorderSizePixel = 0
    	players.Position = UDim2.new(0, 20, 0, 60)
    	players.Size = UDim2.new(1, -40, 1, -175)
    	players.CanvasSize = UDim2.new(0, 0, 5, 0)
    	players.ScrollBarThickness = 8
	
    	buttonsex.Name = "buttonsex"
    	buttonsex.Parent = Blacklist
    	buttonsex.BackgroundColor3 = Color3.new(1, 1, 1)
    	buttonsex.BackgroundTransparency = 1
    	buttonsex.Position = UDim2.new(0, 20, 0, 250)
    	buttonsex.Size = UDim2.new(1, -40, 0, 100)
	
    	Playername.Name = "Playername"
    	Playername.Parent = buttonsex
    	Playername.BackgroundColor3 = Color3.new(0.972549, 0.972549, 0.972549)
    	Playername.BackgroundTransparency = 0.5
    	Playername.BorderSizePixel = 0
    	Playername.Size = UDim2.new(1, 0, 0, 20)
    	Playername.Font = Enum.Font.SourceSansBold
    	Playername.Text = "Enter Player Name"
    	Playername.TextSize = 14
    	Playername.TextWrapped = true
	
    	AddToBlacklist.Name = "AddToBlacklist"
    	AddToBlacklist.Parent = buttonsex
    	AddToBlacklist.BackgroundColor3 = Color3.new(0.972549, 0.972549, 0.972549)
    	AddToBlacklist.BackgroundTransparency = 0.5
    	AddToBlacklist.BorderSizePixel = 0
    	AddToBlacklist.Position = UDim2.new(0, 0, 0, 30)
    	AddToBlacklist.Size = UDim2.new(1, 0, 0, 20)
    	AddToBlacklist.Font = Enum.Font.SourceSansBold
    	AddToBlacklist.Text = "Add to Blacklist"
    	AddToBlacklist.TextSize = 14
    	AddToBlacklist.TextWrapped = true
	
    	RemoveToBlacklist.Name = "RemoveToBlacklist"
    	RemoveToBlacklist.Parent = buttonsex
    	RemoveToBlacklist.BackgroundColor3 = Color3.new(0.972549, 0.972549, 0.972549)
    	RemoveToBlacklist.BackgroundTransparency = 0.5
    	RemoveToBlacklist.BorderSizePixel = 0
    	RemoveToBlacklist.Position = UDim2.new(0, 0, 0, 60)
    	RemoveToBlacklist.Size = UDim2.new(1, 0, 0, 20)
    	RemoveToBlacklist.Font = Enum.Font.SourceSansBold
    	RemoveToBlacklist.Text = "Remove from Blacklist"
    	RemoveToBlacklist.TextSize = 14
    	RemoveToBlacklist.TextWrapped = true

    	SaveBlacklist.Name = "SaveBlacklist"
    	SaveBlacklist.Parent = buttonsex
    	SaveBlacklist.BackgroundColor3 = Color3.new(0.972549, 0.972549, 0.972549)
    	SaveBlacklist.BackgroundTransparency = 0.5
    	SaveBlacklist.BorderSizePixel = 0
    	SaveBlacklist.Position = UDim2.new(0, 0, 0, 90)
    	SaveBlacklist.Size = UDim2.new(1, 0, 0, 20)
    	SaveBlacklist.Font = Enum.Font.SourceSansBold
    	SaveBlacklist.Text = "Save Blacklist"
    	SaveBlacklist.TextSize = 14
    	SaveBlacklist.TextWrapped = true

    	Whitelist.Name = "Whitelist"
    	Whitelist.Parent = MainFrame
    	Whitelist.Active = true
    	Whitelist.BackgroundColor3 = Color3.new(0.176471, 0.176471, 0.176471)
    	Whitelist.BorderSizePixel = 0
    	Whitelist.Position = UDim2.new(1, 3, 0.5, -138)
    	Whitelist.Size = UDim2.new(0, 350, 0, 375)
    	Whitelist.Visible = false
	
    	nigga2.Name = "nigga2"
    	nigga2.Parent = Whitelist
    	nigga2.BackgroundColor3 = Color3.new(1, 1, 1)
    	nigga2.BackgroundTransparency = 1
    	nigga2.Size = UDim2.new(1, 0, 0, 50)
    	nigga2.Font = Enum.Font.SourceSansBold
    	nigga2.Text = "Friends List Menu"
    	nigga2.TextColor3 = Color3.new(1, 1, 1)
    	nigga2.TextSize = 18
    	nigga2.TextTransparency = 0.5
	
    	niggerfaggot2.Name = "niggerfaggot2"
    	niggerfaggot2.Parent = Whitelist
    	niggerfaggot2.BackgroundColor3 = Color3.new(1, 1, 1)
    	niggerfaggot2.BackgroundTransparency = 0.5
    	niggerfaggot2.BorderSizePixel = 0
    	niggerfaggot2.Position = UDim2.new(0.0500000007, 0, 0, 50)
    	niggerfaggot2.Size = UDim2.new(0.899999976, 0, 0, 2)
	
    	players2.Name = "players2"
    	players2.Parent = Whitelist
    	players2.BackgroundColor3 = Color3.new(1, 1, 1)
    	players2.BackgroundTransparency = 1
    	players2.BorderSizePixel = 0
    	players2.Position = UDim2.new(0, 20, 0, 60)
    	players2.Size = UDim2.new(1, -40, 1, -175)
    	players2.CanvasSize = UDim2.new(0, 0, 5, 0)
    	players2.ScrollBarThickness = 8
	
    	buttonsex2.Name = "buttonsex2"
    	buttonsex2.Parent = Whitelist
    	buttonsex2.BackgroundColor3 = Color3.new(1, 1, 1)
    	buttonsex2.BackgroundTransparency = 1
    	buttonsex2.Position = UDim2.new(0, 20, 0, 250)
    	buttonsex2.Size = UDim2.new(1, -40, 0, 100)
	
    	Playername2.Name = "Playername2"
    	Playername2.Parent = buttonsex2
    	Playername2.BackgroundColor3 = Color3.new(0.972549, 0.972549, 0.972549)
    	Playername2.BackgroundTransparency = 0.5
    	Playername2.BorderSizePixel = 0
    	Playername2.Size = UDim2.new(1, 0, 0, 20)
    	Playername2.Font = Enum.Font.SourceSansBold
    	Playername2.Text = "Enter Player Name"
    	Playername2.TextSize = 14
    	Playername2.TextWrapped = true
	
    	AddToWhitelist.Name = "AddToWhitelist"
    	AddToWhitelist.Parent = buttonsex2
    	AddToWhitelist.BackgroundColor3 = Color3.new(0.972549, 0.972549, 0.972549)
    	AddToWhitelist.BackgroundTransparency = 0.5
    	AddToWhitelist.BorderSizePixel = 0
    	AddToWhitelist.Position = UDim2.new(0, 0, 0, 30)
    	AddToWhitelist.Size = UDim2.new(1, 0, 0, 20)
    	AddToWhitelist.Font = Enum.Font.SourceSansBold
    	AddToWhitelist.Text = "Add to Friends List"
    	AddToWhitelist.TextSize = 14
    	AddToWhitelist.TextWrapped = true
	
    	RemoveToWhitelist.Name = "RemoveToWhitelist"
    	RemoveToWhitelist.Parent = buttonsex2
    	RemoveToWhitelist.BackgroundColor3 = Color3.new(0.972549, 0.972549, 0.972549)
    	RemoveToWhitelist.BackgroundTransparency = 0.5
    	RemoveToWhitelist.BorderSizePixel = 0
    	RemoveToWhitelist.Position = UDim2.new(0, 0, 0, 60)
    	RemoveToWhitelist.Size = UDim2.new(1, 0, 0, 20)
    	RemoveToWhitelist.Font = Enum.Font.SourceSansBold
    	RemoveToWhitelist.Text = "Remove from Friends List"
    	RemoveToWhitelist.TextSize = 14
    	RemoveToWhitelist.TextWrapped = true

    	SaveWhitelist.Name = "SaveWhitelist"
    	SaveWhitelist.Parent = buttonsex2
    	SaveWhitelist.BackgroundColor3 = Color3.new(0.972549, 0.972549, 0.972549)
    	SaveWhitelist.BackgroundTransparency = 0.5
    	SaveWhitelist.BorderSizePixel = 0
    	SaveWhitelist.Position = UDim2.new(0, 0, 0, 90)
    	SaveWhitelist.Size = UDim2.new(1, 0, 0, 20)
    	SaveWhitelist.Font = Enum.Font.SourceSansBold
    	SaveWhitelist.Text = "Save Friends List"
    	SaveWhitelist.TextSize = 14
    	SaveWhitelist.TextWrapped = true

    	BlacklistToggle.Name = "BlacklistToggle"
    	BlacklistToggle.Parent = buttons
    	BlacklistToggle.BackgroundColor3 = Color3.new(1, 1, 1)
    	BlacklistToggle.BackgroundTransparency = 0.5
    	BlacklistToggle.BorderSizePixel = 0
    	BlacklistToggle.Position = UDim2.new(0, 0, 0, 200)
    	BlacklistToggle.Size = UDim2.new(0, 150, 0, 30)
    	BlacklistToggle.Font = Enum.Font.SourceSansBold
    	BlacklistToggle.Text = "Blacklist"
    	BlacklistToggle.TextColor3 = Color3.new(0.176471, 0.176471, 0.176471)
    	BlacklistToggle.TextSize = 14
    	BlacklistToggle.TextWrapped = true

    	WhitelistToggle.Name = "WhitelistToggle"
    	WhitelistToggle.Parent = buttons
    	WhitelistToggle.BackgroundColor3 = Color3.new(1, 1, 1)
    	WhitelistToggle.BackgroundTransparency = 0.5
    	WhitelistToggle.BorderSizePixel = 0
    	WhitelistToggle.Position = UDim2.new(1, -150, 0, 200)
    	WhitelistToggle.Size = UDim2.new(0, 150, 0, 30)
    	WhitelistToggle.Font = Enum.Font.SourceSansBold
    	WhitelistToggle.Text = "Friends List"
    	WhitelistToggle.TextColor3 = Color3.new(0.176471, 0.176471, 0.176471)
    	WhitelistToggle.TextSize = 14
    	WhitelistToggle.TextWrapped = true
	
    	ESPToggle.Name = "ESPToggle"
    	ESPToggle.Parent = buttons
    	ESPToggle.BackgroundColor3 = Color3.new(1, 1, 1)
    	ESPToggle.BackgroundTransparency = 0.5
    	ESPToggle.BorderSizePixel = 0
    	ESPToggle.Size = UDim2.new(0, 150, 0, 30)
    	ESPToggle.Font = Enum.Font.SourceSansBold
    	ESPToggle.Text = "透视"
    	ESPToggle.TextColor3 = Color3.new(0.176471, 0.176471, 0.176471)
    	ESPToggle.TextSize = 14
    	ESPToggle.TextWrapped = true
	
    	ChamsToggle.Name = "ChamsToggle"
    	ChamsToggle.Parent = buttons
    	ChamsToggle.BackgroundColor3 = Color3.new(1, 1, 1)
    	ChamsToggle.BackgroundTransparency = 0.5
    	ChamsToggle.BorderSizePixel = 0
    	ChamsToggle.Position = UDim2.new(1, -150, 0, 0)
    	ChamsToggle.Size = UDim2.new(0, 150, 0, 30)
    	ChamsToggle.Font = Enum.Font.SourceSansBold
    	ChamsToggle.Text = "Chams"
    	ChamsToggle.TextColor3 = Color3.new(0.176471, 0.176471, 0.176471)
    	ChamsToggle.TextSize = 14
    	ChamsToggle.TextWrapped = true
	
    	TracersToggle.Name = "TracersToggle"
    	TracersToggle.Parent = buttons
    	TracersToggle.BackgroundColor3 = Color3.new(1, 1, 1)
    	TracersToggle.BackgroundTransparency = 0.5
    	TracersToggle.BorderSizePixel = 0
    	TracersToggle.Position = UDim2.new(0, 0, 0, 40)
    	TracersToggle.Size = UDim2.new(0, 150, 0, 30)
    	TracersToggle.Font = Enum.Font.SourceSansBold
    	TracersToggle.Text = "Tracers"
    	TracersToggle.TextColor3 = Color3.new(0.176471, 0.176471, 0.176471)
    	TracersToggle.TextSize = 14
    	TracersToggle.TextWrapped = true
	
    	OutlineToggle.Name = "OutlineToggle"
    	OutlineToggle.Parent = buttons
    	OutlineToggle.BackgroundColor3 = Color3.new(1, 1, 1)
    	OutlineToggle.BackgroundTransparency = 0.5
    	OutlineToggle.BorderSizePixel = 0
    	OutlineToggle.Position = UDim2.new(1, -150, 0, 40)
    	OutlineToggle.Size = UDim2.new(0, 150, 0, 30)
    	OutlineToggle.Font = Enum.Font.SourceSansBold
    	OutlineToggle.Text = "Outlines"
    	OutlineToggle.TextColor3 = Color3.new(0.176471, 0.176471, 0.176471)
    	OutlineToggle.TextSize = 14
    	OutlineToggle.TextWrapped = true
	
    	DebugToggle.Name = "DebugToggle"
    	DebugToggle.Parent = buttons
    	DebugToggle.BackgroundColor3 = Color3.new(1, 1, 1)
    	DebugToggle.BackgroundTransparency = 0.5
    	DebugToggle.BorderSizePixel = 0
    	DebugToggle.Position = UDim2.new(1, -150, 0, 80)
    	DebugToggle.Size = UDim2.new(0, 150, 0, 30)
    	DebugToggle.Font = Enum.Font.SourceSansBold
    	DebugToggle.Text = "Debug Info"
    	DebugToggle.TextColor3 = Color3.new(0.176471, 0.176471, 0.176471)
    	DebugToggle.TextSize = 14
    	DebugToggle.TextWrapped = true
	
    	FullbrightToggle.Name = "FullbrightToggle"
    	FullbrightToggle.Parent = buttons
    	FullbrightToggle.BackgroundColor3 = Color3.new(1, 1, 1)
    	FullbrightToggle.BackgroundTransparency = 0.5
    	FullbrightToggle.BorderSizePixel = 0
    	FullbrightToggle.Position = UDim2.new(0, 0, 0, 80)
    	FullbrightToggle.Size = UDim2.new(0, 150, 0, 30)
    	FullbrightToggle.Font = Enum.Font.SourceSansBold
    	FullbrightToggle.Text = "Fullbright"
    	FullbrightToggle.TextColor3 = Color3.new(0.176471, 0.176471, 0.176471)
    	FullbrightToggle.TextSize = 14
    	FullbrightToggle.TextWrapped = true
	
    	Crosshair.Name = "Crosshair"
    	Crosshair.Parent = buttons
    	Crosshair.BackgroundColor3 = Color3.new(1, 1, 1)
    	Crosshair.BackgroundTransparency = 0.5
    	Crosshair.BorderSizePixel = 0
    	Crosshair.Position = UDim2.new(0, 0, 0, 120)
    	Crosshair.Size = UDim2.new(0, 150, 0, 30)
    	Crosshair.Font = Enum.Font.SourceSansBold
    	Crosshair.Text = "Crosshair"
    	Crosshair.TextColor3 = Color3.new(0.176471, 0.176471, 0.176471)
    	Crosshair.TextSize = 14
    	Crosshair.TextWrapped = true
	
    	AimbotToggle.Name = "AimbotToggle"
    	AimbotToggle.Parent = buttons
    	AimbotToggle.BackgroundColor3 = Color3.new(1, 1, 1)
    	AimbotToggle.BackgroundTransparency = 0.5
    	AimbotToggle.BorderSizePixel = 0
    	AimbotToggle.Position = UDim2.new(1, -150, 0, 120)
    	AimbotToggle.Size = UDim2.new(0, 150, 0, 30)
    	AimbotToggle.Font = Enum.Font.SourceSansBold
    	AimbotToggle.Text = "Aimlock"
    	AimbotToggle.TextColor3 = Color3.new(0.176471, 0.176471, 0.176471)
    	AimbotToggle.TextSize = 14
    	AimbotToggle.TextWrapped = true
	
    	Settings.Name = "Settings"
    	Settings.Parent = buttons
    	Settings.BackgroundColor3 = Color3.new(1, 1, 1)
    	Settings.BackgroundTransparency = 0.5
    	Settings.BorderSizePixel = 0
    	Settings.Position = UDim2.new(1, -150, 0, 160)
    	Settings.Size = UDim2.new(0, 150, 0, 30)
    	Settings.Font = Enum.Font.SourceSansBold
    	Settings.Text = "Settings"
    	Settings.TextColor3 = Color3.new(0.176471, 0.176471, 0.176471)
    	Settings.TextSize = 14
    	Settings.TextWrapped = true
	
    	Information.Name = "Information"
    	Information.Parent = buttons
    	Information.BackgroundColor3 = Color3.new(1, 1, 1)
    	Information.BackgroundTransparency = 0.5
    	Information.BorderSizePixel = 0
    	Information.Position = UDim2.new(0, 0, 0, 160)
    	Information.Size = UDim2.new(0, 150, 0, 30)
    	Information.Font = Enum.Font.SourceSansBold
    	Information.Text = "Information"
    	Information.TextColor3 = Color3.new(0.176471, 0.176471, 0.176471)
    	Information.TextSize = 14
    	Information.TextWrapped = true
	
    	Information_2.Name = "Information"
    	Information_2.Parent = MainFrame
    	Information_2.Active = true
    	Information_2.BackgroundColor3 = Color3.new(0.176471, 0.176471, 0.176471)
    	Information_2.BorderSizePixel = 0
    	Information_2.Position = UDim2.new(1, 3, 0.5, -138)
    	Information_2.Size = UDim2.new(0, 350, 0, 365)
    	Information_2.Visible = false
	
    	Title_2.Name = "Title"
    	Title_2.Parent = Information_2
    	Title_2.BackgroundColor3 = Color3.new(1, 1, 1)
    	Title_2.BackgroundTransparency = 1
    	Title_2.Size = UDim2.new(1, 0, 0, 50)
    	Title_2.Font = Enum.Font.SourceSansBold
    	Title_2.Text = "Information"
    	Title_2.TextColor3 = Color3.new(1, 1, 1)
    	Title_2.TextSize = 18
    	Title_2.TextTransparency = 0.5
	
    	design_2.Name = "design"
    	design_2.Parent = Information_2
    	design_2.BackgroundColor3 = Color3.new(1, 1, 1)
    	design_2.BackgroundTransparency = 0.5
    	design_2.BorderSizePixel = 0
    	design_2.Position = UDim2.new(0.0500000007, 0, 0, 50)
    	design_2.Size = UDim2.new(0.899999976, 0, 0, 2)
	
    	buttons_2.Name = "buttons"
    	buttons_2.Parent = Information_2
    	buttons_2.BackgroundColor3 = Color3.new(1, 1, 1)
    	buttons_2.BackgroundTransparency = 1
    	buttons_2.BorderSizePixel = 0
    	buttons_2.Position = UDim2.new(0, 20, 0, 60)
    	buttons_2.Size = UDim2.new(1, -40, 1, -70)
    	buttons_2.CanvasSize = UDim2.new(5, 0, 5, 0)
    	buttons_2.ScrollBarThickness = 5
	
    	TextLabel.Parent = buttons_2
    	TextLabel.BackgroundColor3 = Color3.new(1, 1, 1)
    	TextLabel.BackgroundTransparency = 1
    	TextLabel.Size = UDim2.new(1, -20, 1, 0)
    	TextLabel.Font = Enum.Font.SourceSansBold
    	TextLabel.Text = [[
    Scripting by: Racist Dolphin#5199
    GUI by: SOMEONE WHO WANTS HIS NAME HIDDEN.

    To hide/show the GUI press the "P" key on your keyboard.

    NOTICE: Since my string manipulation skills aren't the greatest, changing esp/cham colors might be quite buggy.
    NOTICE #2: The blacklist feature will return! I just didn't have enough time to make the gui.
    NOTICE #3: Save Settings might still be bugged. Message me if it's fucked up still.

    This works on every game, though the Aimbot does NOT! (Doesn't work on: Jailbreak, and Phantom Forces)

    FAQ:
    1) How do I use the aimbot?
    A: Activate it, and hold right-click in-game. The aimbot will lock on to the closest enemy NOT behind a wall. (If said player is behind a wall, it will find the next closest player not behind a wall.)

    2) ESP/Chams don't work on the game I play?
    A: Some games require me to make patches (ex: Murder Mystery, Murder Mystery X) to request a patch or a game message me on discord.

    3) How did I detect when a player is behind a wall?
    A: Raycasting the camera to another player.

    4) My bullets still miss when using aimbot?!
    A: Blame bullet spread, try and control how often you fire. (Murder Mystery 2 = trash) (Why the fuck does a single shot pistol have bullet spread? lol wtf?)

    Change Log:
    3/10/2018:
    + Fixed more bugs with chams

    3/10/2018:
    + Fixed how chams broke when a player respawned.

    3/10/2018:
    + Fixed ESP not updating correctly.
    + Fixed Chams not updating correctly. (MAYBE? IDK WHAT IS BREAKING THIS)

    3/9/2018:
    + Mob ESP/Chams! (BETA!)

    3/8/2018:
    + Fixed the error you get when not entering a valid number for esp/chams/tracer lengths.
    + Fixed lag issues with aimlock.
    + Fixed lag issues with chams.

    3/8/2018:
    + Patch for Murder 15
    - Temporarily removed auto fire since mouse1click is broken on Synapse :(

    3/7/2018:
    + Updated save settings.
    + Can now customize aimlock key.

    3/7/2018:
    + Patch for Wild Revolver.
    + Fix for autofire. (Hopefully)

    3/6/2018:
    - Removed :IsFriendsWith check. (Use Friends List GUI instead)

    3/4/2018:
    + Added Friend List Menu
    + Patch for Assassin!

    3/4/2018:
    + Fixed crosshair toggle.
    + Aimlock patch for Island Royal.
    + Finally fixed save settings.

    3/4/2018:
    + Aimlock fixed for Unit 1968: Vietnam
    + Autofire setting for aimlock
    + Fixed how you sometimes had to double click buttons to activate a option

    3/4/2018:
    + Fixed FreeForAll setting bug.
    + Using aimlock on Phantom Forces / Jailbreak will now tell you it will not work.
    * Renamed Aimbot back to Aimlock

    3/3/2018:
    + Blacklist feature re-added.
    + Aimbot will no longer focus people in the blacklist.
    + Compatible on exploits that have readfile and writefile.

    3/3/2018:
    + GUI Overhaul
    + Aimbot now only targets people NOT behind walls
    + Chams now dim when x player is visible on your screen.
    + Chams no longer have the humanoid root part. (Your welcome)
    + Patch for Silent Assassin
    + My discord was deleted, so I'm using pastebin now. (Auto updates :)
    ]]
    	TextLabel.TextColor3 = Color3.new(1, 1, 1)
    	TextLabel.TextSize = 16
    	TextLabel.TextTransparency = 0.5
    	TextLabel.TextXAlignment = Enum.TextXAlignment.Left
    	TextLabel.TextYAlignment = Enum.TextYAlignment.Top
	
    	Settings_2.Name = "Settings"
    	Settings_2.Parent = MainFrame
    	Settings_2.Active = true
    	Settings_2.BackgroundColor3 = Color3.new(0.176471, 0.176471, 0.176471)
    	Settings_2.BorderSizePixel = 0
    	Settings_2.Position = UDim2.new(1, 3, 0.5, -138)
    	Settings_2.Size = UDim2.new(0, 350, 0, 365)
    	Settings_2.Visible = false
	
    	Title_3.Name = "Title"
    	Title_3.Parent = Settings_2
    	Title_3.BackgroundColor3 = Color3.new(1, 1, 1)
    	Title_3.BackgroundTransparency = 1
    	Title_3.Size = UDim2.new(1, 0, 0, 50)
    	Title_3.Font = Enum.Font.SourceSansBold
    	Title_3.Text = "Settings Menu"
    	Title_3.TextColor3 = Color3.new(1, 1, 1)
    	Title_3.TextSize = 18
    	Title_3.TextTransparency = 0.5
	
    	design_3.Name = "design"
    	design_3.Parent = Settings_2
    	design_3.BackgroundColor3 = Color3.new(1, 1, 1)
    	design_3.BackgroundTransparency = 0.5
    	design_3.BorderSizePixel = 0
    	design_3.Position = UDim2.new(0.0500000007, 0, 0, 50)
    	design_3.Size = UDim2.new(0.899999976, 0, 0, 2)
	
    	buttons_3.Name = "buttons"
    	buttons_3.Parent = Settings_2
    	buttons_3.BackgroundColor3 = Color3.new(1, 1, 1)
    	buttons_3.BackgroundTransparency = 1
    	buttons_3.BorderSizePixel = 0
    	buttons_3.Position = UDim2.new(0, 20, 0, 60)
    	buttons_3.Size = UDim2.new(1, -40, 1, -70)
    	buttons_3.ScrollBarThickness = 8
	
    	AllyColor.Name = "AllyColor"
    	AllyColor.Parent = buttons_3
    	AllyColor.BackgroundColor3 = Color3.new(0.972549, 0.972549, 0.972549)
    	AllyColor.BackgroundTransparency = 0.5
    	AllyColor.BorderSizePixel = 0
    	AllyColor.Position = UDim2.new(1, -150, 0, 180)
    	AllyColor.Size = UDim2.new(0, 135, 0, 20)
    	AllyColor.Font = Enum.Font.SourceSansBold
    	AllyColor.Text = tostring(Bullshit.Colors.Ally)
    	AllyColor.TextSize = 14
    	AllyColor.TextWrapped = true
	
    	CHAMSLength.Name = "CHAMSLength"
    	CHAMSLength.Parent = buttons_3
    	CHAMSLength.BackgroundColor3 = Color3.new(0.972549, 0.972549, 0.972549)
    	CHAMSLength.BackgroundTransparency = 0.5
    	CHAMSLength.BorderSizePixel = 0
    	CHAMSLength.Position = UDim2.new(1, -150, 0, 60)
    	CHAMSLength.Size = UDim2.new(0, 135, 0, 20)
    	CHAMSLength.Font = Enum.Font.SourceSansBold
    	CHAMSLength.Text = tostring(Bullshit.CHAMSLength)
    	CHAMSLength.TextSize = 14
    	CHAMSLength.TextWrapped = true
	
    	CrosshairColor.Name = "CrosshairColor"
    	CrosshairColor.Parent = buttons_3
    	CrosshairColor.BackgroundColor3 = Color3.new(0.972549, 0.972549, 0.972549)
    	CrosshairColor.BackgroundTransparency = 0.5
    	CrosshairColor.BorderSizePixel = 0
    	CrosshairColor.Position = UDim2.new(1, -150, 0, 270)
    	CrosshairColor.Size = UDim2.new(0, 135, 0, 20)
    	CrosshairColor.Font = Enum.Font.SourceSansBold
    	CrosshairColor.Text = tostring(Bullshit.Colors.Crosshair)
    	CrosshairColor.TextSize = 14
    	CrosshairColor.TextWrapped = true
	
    	ESPLength.Name = "ESPLength"
    	ESPLength.Parent = buttons_3
    	ESPLength.BackgroundColor3 = Color3.new(0.972549, 0.972549, 0.972549)
    	ESPLength.BackgroundTransparency = 0.5
    	ESPLength.BorderSizePixel = 0
    	ESPLength.Position = UDim2.new(1, -150, 0, 30)
    	ESPLength.Size = UDim2.new(0, 135, 0, 20)
    	ESPLength.Font = Enum.Font.SourceSansBold
    	ESPLength.Text = tostring(Bullshit.ESPLength)
    	ESPLength.TextSize = 14
    	ESPLength.TextWrapped = true
	
    	EnemyColor.Name = "EnemyColor"
    	EnemyColor.Parent = buttons_3
    	EnemyColor.BackgroundColor3 = Color3.new(0.972549, 0.972549, 0.972549)
    	EnemyColor.BackgroundTransparency = 0.5
    	EnemyColor.BorderSizePixel = 0
    	EnemyColor.Position = UDim2.new(1, -150, 0, 150)
    	EnemyColor.Size = UDim2.new(0, 135, 0, 20)
    	EnemyColor.Font = Enum.Font.SourceSansBold
    	EnemyColor.Text = tostring(Bullshit.Colors.Enemy)
    	EnemyColor.TextSize = 14
    	EnemyColor.TextWrapped = true
	
    	FreeForAll.Name = "FreeForAll"
    	FreeForAll.Parent = buttons_3
    	FreeForAll.BackgroundColor3 = Color3.new(0.972549, 0.972549, 0.972549)
    	FreeForAll.BackgroundTransparency = 0.5
    	FreeForAll.BorderSizePixel = 0
    	FreeForAll.Position = UDim2.new(1, -150, 0, 120)
    	FreeForAll.Size = UDim2.new(0, 135, 0, 20)
    	FreeForAll.Font = Enum.Font.SourceSansBold
    	FreeForAll.Text = tostring(Bullshit.FreeForAll)
    	FreeForAll.TextSize = 14
    	FreeForAll.TextWrapped = true
	
    	FriendColor.Name = "FriendColor"
    	FriendColor.Parent = buttons_3
    	FriendColor.BackgroundColor3 = Color3.new(0.972549, 0.972549, 0.972549)
    	FriendColor.BackgroundTransparency = 0.5
    	FriendColor.BorderSizePixel = 0
    	FriendColor.Position = UDim2.new(1, -150, 0, 210)
    	FriendColor.Size = UDim2.new(0, 135, 0, 20)
    	FriendColor.Font = Enum.Font.SourceSansBold
    	FriendColor.Text = tostring(Bullshit.Colors.Friend)
    	FriendColor.TextSize = 14
    	FriendColor.TextWrapped = true
	
    	NeutralColor.Name = "NeutralColor"
    	NeutralColor.Parent = buttons_3
    	NeutralColor.BackgroundColor3 = Color3.new(0.972549, 0.972549, 0.972549)
    	NeutralColor.BackgroundTransparency = 0.5
    	NeutralColor.BorderSizePixel = 0
    	NeutralColor.Position = UDim2.new(1, -150, 0, 240)
    	NeutralColor.Size = UDim2.new(0, 135, 0, 20)
    	NeutralColor.Font = Enum.Font.SourceSansBold
    	NeutralColor.Text = tostring(Bullshit.Colors.Neutral)
    	NeutralColor.TextSize = 14
    	NeutralColor.TextWrapped = true
	
    	TracersLength.Name = "TracersLength"
    	TracersLength.Parent = buttons_3
    	TracersLength.BackgroundColor3 = Color3.new(0.972549, 0.972549, 0.972549)
    	TracersLength.BackgroundTransparency = 0.5
    	TracersLength.BorderSizePixel = 0
    	TracersLength.Position = UDim2.new(1, -150, 0, 0)
    	TracersLength.Size = UDim2.new(0, 135, 0, 20)
    	TracersLength.Font = Enum.Font.SourceSansBold
    	TracersLength.Text = tostring(Bullshit.TracersLength)
    	TracersLength.TextSize = 14
    	TracersLength.TextWrapped = true
	
    	TracersUnderChars.Name = "TracersUnderChars"
    	TracersUnderChars.Parent = buttons_3
    	TracersUnderChars.BackgroundColor3 = Color3.new(0.972549, 0.972549, 0.972549)
    	TracersUnderChars.BackgroundTransparency = 0.5
    	TracersUnderChars.BorderSizePixel = 0
    	TracersUnderChars.Position = UDim2.new(1, -150, 0, 90)
    	TracersUnderChars.Size = UDim2.new(0, 135, 0, 20)
    	TracersUnderChars.Font = Enum.Font.SourceSansBold
    	TracersUnderChars.Text = tostring(Bullshit.PlaceTracersUnderCharacter)
    	TracersUnderChars.TextSize = 14
    	TracersUnderChars.TextWrapped = true

    	AutoFireToggle.Name = "AutoFireToggle"
    	AutoFireToggle.Parent = buttons_3
    	AutoFireToggle.BackgroundColor3 = Color3.new(0.972549, 0.972549, 0.972549)
    	AutoFireToggle.BackgroundTransparency = 0.5
    	AutoFireToggle.BorderSizePixel = 0
    	AutoFireToggle.Position = UDim2.new(1, -150, 0, 300)
    	AutoFireToggle.Size = UDim2.new(0, 135, 0, 20)
    	AutoFireToggle.Font = Enum.Font.SourceSansBold
    	AutoFireToggle.Text = tostring(Bullshit.AutoFire)
    	AutoFireToggle.TextSize = 14
    	AutoFireToggle.TextWrapped = true

    	AimbotKey.Name = "AimbotKey"
    	AimbotKey.Parent = buttons_3
    	AimbotKey.BackgroundColor3 = Color3.new(0.972549, 0.972549, 0.972549)
    	AimbotKey.BackgroundTransparency = 0.5
    	AimbotKey.BorderSizePixel = 0
    	AimbotKey.Position = UDim2.new(1, -150, 0, 330)
    	AimbotKey.Size = UDim2.new(0, 135, 0, 20)
    	AimbotKey.Font = Enum.Font.SourceSansBold
    	AimbotKey.Text = tostring(Bullshit.AimbotKey)
    	AimbotKey.TextSize = 14
    	AimbotKey.TextWrapped = true

    	MobESPButton.Name = "MobESPButton"
    	MobESPButton.Parent = buttons_3
    	MobESPButton.BackgroundColor3 = Color3.new(0.972549, 0.972549, 0.972549)
    	MobESPButton.BackgroundTransparency = 0.5
    	MobESPButton.BorderSizePixel = 0
    	MobESPButton.Position = UDim2.new(1, -150, 0, 360)
    	MobESPButton.Size = UDim2.new(0, 135, 0, 20)
    	MobESPButton.Font = Enum.Font.SourceSansBold
    	MobESPButton.Text = tostring(Bullshit.MobESP)
    	MobESPButton.TextSize = 14
    	MobESPButton.TextWrapped = true

    	MobChamsButton.Name = "MobChamsButton"
    	MobChamsButton.Parent = buttons_3
    	MobChamsButton.BackgroundColor3 = Color3.new(0.972549, 0.972549, 0.972549)
    	MobChamsButton.BackgroundTransparency = 0.5
    	MobChamsButton.BorderSizePixel = 0
    	MobChamsButton.Position = UDim2.new(1, -150, 0, 390)
    	MobChamsButton.Size = UDim2.new(0, 135, 0, 20)
    	MobChamsButton.Font = Enum.Font.SourceSansBold
    	MobChamsButton.Text = tostring(Bullshit.MobChams)
    	MobChamsButton.TextSize = 14
    	MobChamsButton.TextWrapped = true
	
    	TextLabel_2.Parent = buttons_3
    	TextLabel_2.BackgroundColor3 = Color3.new(1, 1, 1)
    	TextLabel_2.BackgroundTransparency = 1
    	TextLabel_2.Size = UDim2.new(0.5, 0, 0, 20)
    	TextLabel_2.Font = Enum.Font.SourceSansBold
    	TextLabel_2.Text = "Tracers Length"
    	TextLabel_2.TextColor3 = Color3.new(1, 1, 1)
    	TextLabel_2.TextSize = 16
    	TextLabel_2.TextTransparency = 0.5
	
    	TextLabel_3.Parent = buttons_3
    	TextLabel_3.BackgroundColor3 = Color3.new(1, 1, 1)
    	TextLabel_3.BackgroundTransparency = 1
    	TextLabel_3.Position = UDim2.new(0, 0, 0, 30)
    	TextLabel_3.Size = UDim2.new(0.5, 0, 0, 20)
    	TextLabel_3.Font = Enum.Font.SourceSansBold
    	TextLabel_3.Text = "ESP Length"
    	TextLabel_3.TextColor3 = Color3.new(1, 1, 1)
    	TextLabel_3.TextSize = 16
    	TextLabel_3.TextTransparency = 0.5
	
    	TextLabel_4.Parent = buttons_3
    	TextLabel_4.BackgroundColor3 = Color3.new(1, 1, 1)
    	TextLabel_4.BackgroundTransparency = 1
    	TextLabel_4.Position = UDim2.new(0, 0, 0, 60)
    	TextLabel_4.Size = UDim2.new(0.5, 0, 0, 20)
    	TextLabel_4.Font = Enum.Font.SourceSansBold
    	TextLabel_4.Text = "Chams Length"
    	TextLabel_4.TextColor3 = Color3.new(1, 1, 1)
    	TextLabel_4.TextSize = 16
    	TextLabel_4.TextTransparency = 0.5
	
    	TextLabel_5.Parent = buttons_3
    	TextLabel_5.BackgroundColor3 = Color3.new(1, 1, 1)
    	TextLabel_5.BackgroundTransparency = 1
    	TextLabel_5.Position = UDim2.new(0, 0, 0, 90)
    	TextLabel_5.Size = UDim2.new(0.5, 0, 0, 20)
    	TextLabel_5.Font = Enum.Font.SourceSansBold
    	TextLabel_5.Text = "Tracers Under Chars"
    	TextLabel_5.TextColor3 = Color3.new(1, 1, 1)
    	TextLabel_5.TextSize = 16
    	TextLabel_5.TextTransparency = 0.5
	
    	TextLabel_6.Parent = buttons_3
    	TextLabel_6.BackgroundColor3 = Color3.new(1, 1, 1)
    	TextLabel_6.BackgroundTransparency = 1
    	TextLabel_6.Position = UDim2.new(0, 0, 0, 270)
    	TextLabel_6.Size = UDim2.new(0.5, 0, 0, 20)
    	TextLabel_6.Font = Enum.Font.SourceSansBold
    	TextLabel_6.Text = "Crosshair Color"
    	TextLabel_6.TextColor3 = Color3.new(1, 1, 1)
    	TextLabel_6.TextSize = 16
    	TextLabel_6.TextTransparency = 0.5
	
    	TextLabel_7.Parent = buttons_3
    	TextLabel_7.BackgroundColor3 = Color3.new(1, 1, 1)
    	TextLabel_7.BackgroundTransparency = 1
    	TextLabel_7.Position = UDim2.new(0, 0, 0, 120)
    	TextLabel_7.Size = UDim2.new(0.5, 0, 0, 20)
    	TextLabel_7.Font = Enum.Font.SourceSansBold
    	TextLabel_7.Text = "Free For All"
    	TextLabel_7.TextColor3 = Color3.new(1, 1, 1)
    	TextLabel_7.TextSize = 16
    	TextLabel_7.TextTransparency = 0.5
	
    	TextLabel_8.Parent = buttons_3
    	TextLabel_8.BackgroundColor3 = Color3.new(1, 1, 1)
    	TextLabel_8.BackgroundTransparency = 1
    	TextLabel_8.Position = UDim2.new(0, 0, 0, 240)
    	TextLabel_8.Size = UDim2.new(0.5, 0, 0, 20)
    	TextLabel_8.Font = Enum.Font.SourceSansBold
    	TextLabel_8.Text = "Neutral Color"
    	TextLabel_8.TextColor3 = Color3.new(1, 1, 1)
    	TextLabel_8.TextSize = 16
    	TextLabel_8.TextTransparency = 0.5
	
    	TextLabel_9.Parent = buttons_3
    	TextLabel_9.BackgroundColor3 = Color3.new(1, 1, 1)
    	TextLabel_9.BackgroundTransparency = 1
    	TextLabel_9.Position = UDim2.new(0, 0, 0, 150)
    	TextLabel_9.Size = UDim2.new(0.5, 0, 0, 20)
    	TextLabel_9.Font = Enum.Font.SourceSansBold
    	TextLabel_9.Text = "Enemy Color"
    	TextLabel_9.TextColor3 = Color3.new(1, 1, 1)
    	TextLabel_9.TextSize = 16
    	TextLabel_9.TextTransparency = 0.5
	
    	TextLabel_10.Parent = buttons_3
    	TextLabel_10.BackgroundColor3 = Color3.new(1, 1, 1)
    	TextLabel_10.BackgroundTransparency = 1
    	TextLabel_10.Position = UDim2.new(0, 0, 0, 180)
    	TextLabel_10.Size = UDim2.new(0.5, 0, 0, 20)
    	TextLabel_10.Font = Enum.Font.SourceSansBold
    	TextLabel_10.Text = "Ally Color"
    	TextLabel_10.TextColor3 = Color3.new(1, 1, 1)
    	TextLabel_10.TextSize = 16
    	TextLabel_10.TextTransparency = 0.5
	
    	TextLabel_11.Parent = buttons_3
    	TextLabel_11.BackgroundColor3 = Color3.new(1, 1, 1)
    	TextLabel_11.BackgroundTransparency = 1
    	TextLabel_11.Position = UDim2.new(0, 0, 0, 210)
    	TextLabel_11.Size = UDim2.new(0.5, 0, 0, 20)
    	TextLabel_11.Font = Enum.Font.SourceSansBold
    	TextLabel_11.Text = "Friend Color"
    	TextLabel_11.TextColor3 = Color3.new(1, 1, 1)
    	TextLabel_11.TextSize = 16
    	TextLabel_11.TextTransparency = 0.5

    	TextLabel_12.Parent = buttons_3
    	TextLabel_12.BackgroundColor3 = Color3.new(1, 1, 1)
    	TextLabel_12.BackgroundTransparency = 1
    	TextLabel_12.Position = UDim2.new(0, 0, 0, 300)
    	TextLabel_12.Size = UDim2.new(0.5, 0, 0, 20)
    	TextLabel_12.Font = Enum.Font.SourceSansBold
    	TextLabel_12.Text = "Aimlock Auto Fire"
    	TextLabel_12.TextColor3 = Color3.new(1, 1, 1)
    	TextLabel_12.TextSize = 16
    	TextLabel_12.TextTransparency = 0.5

    	TextLabel_13.Parent = buttons_3
    	TextLabel_13.BackgroundColor3 = Color3.new(1, 1, 1)
    	TextLabel_13.BackgroundTransparency = 1
    	TextLabel_13.Position = UDim2.new(0, 0, 0, 330)
    	TextLabel_13.Size = UDim2.new(0.5, 0, 0, 20)
    	TextLabel_13.Font = Enum.Font.SourceSansBold
    	TextLabel_13.Text = "Aimbot Key"
    	TextLabel_13.TextColor3 = Color3.new(1, 1, 1)
    	TextLabel_13.TextSize = 16
    	TextLabel_13.TextTransparency = 0.5

    	TextLabel_14.Parent = buttons_3
    	TextLabel_14.BackgroundColor3 = Color3.new(1, 1, 1)
    	TextLabel_14.BackgroundTransparency = 1
    	TextLabel_14.Position = UDim2.new(0, 0, 0, 360)
    	TextLabel_14.Size = UDim2.new(0.5, 0, 0, 20)
    	TextLabel_14.Font = Enum.Font.SourceSansBold
    	TextLabel_14.Text = "Mob ESP"
    	TextLabel_14.TextColor3 = Color3.new(1, 1, 1)
    	TextLabel_14.TextSize = 16
    	TextLabel_14.TextTransparency = 0.5

    	TextLabel_15.Parent = buttons_3
    	TextLabel_15.BackgroundColor3 = Color3.new(1, 1, 1)
    	TextLabel_15.BackgroundTransparency = 1
    	TextLabel_15.Position = UDim2.new(0, 0, 0, 390)
    	TextLabel_15.Size = UDim2.new(0.5, 0, 0, 20)
    	TextLabel_15.Font = Enum.Font.SourceSansBold
    	TextLabel_15.Text = "Mob CHAMS"
    	TextLabel_15.TextColor3 = Color3.new(1, 1, 1)
    	TextLabel_15.TextSize = 16
    	TextLabel_15.TextTransparency = 0.5
	
    	SaveSettings.Name = "SaveSettings"
    	SaveSettings.Parent = buttons_3
    	SaveSettings.BackgroundColor3 = Color3.new(0.972549, 0.972549, 0.972549)
    	SaveSettings.BackgroundTransparency = 0.5
    	SaveSettings.BorderSizePixel = 0
    	SaveSettings.Position = UDim2.new(0, 0, 0, 420)
    	SaveSettings.Size = UDim2.new(1, -15, 0, 20)
    	SaveSettings.Font = Enum.Font.SourceSansBold
    	SaveSettings.Text = "Save Settings"
    	SaveSettings.TextSize = 14
    	SaveSettings.TextWrapped = true

    	function CreatePlayerLabel(Str, frame)
    		local n = #frame:GetChildren()
    		local playername = Instance.new("TextLabel")
    		playername.Name = Str
    		playername.Parent = frame
    		playername.BackgroundColor3 = Color3.new(1, 1, 1)
    		playername.BackgroundTransparency = 1
    		playername.BorderSizePixel = 0
    		playername.Position = UDim2.new(0, 5, 0, (n * 15))
    		playername.Size = UDim2.new(1, -25, 0, 15)
    		playername.Font = Enum.Font.SourceSans
    		playername.Text = Str
    		playername.TextColor3 = Color3.new(1, 1, 1)
    		playername.TextSize = 16
    		playername.TextXAlignment = Enum.TextXAlignment.Left
    	end

    	function RefreshPlayerLabels(frame, t)
    		frame:ClearAllChildren()
    		for i, v in next, t do
    			CreatePlayerLabel(i, frame)
    		end
    	end

    	RefreshPlayerLabels(players, Bullshit.Blacklist)
    	RefreshPlayerLabels(players2, Bullshit.FriendList)
	
    	ESPToggle.MouseButton1Click:connect(function()
    		Bullshit.ESPEnabled = not Bullshit.ESPEnabled
    		if Bullshit.ESPEnabled then
    			ESPToggle.BackgroundColor3 = Color3.new(0/255,171/255,11/255)
    			for _, v in next, Plrs:GetPlayers() do
    				if v ~= MyPlr then
    					if Bullshit.CharAddedEvent[v.Name] == nil then
    						Bullshit.CharAddedEvent[v.Name] = v.CharacterAdded:connect(function(Char)
    							if Bullshit.ESPEnabled then
    								RemoveESP(v)
    								CreateESP(v)
    							end
    							if Bullshit.CHAMSEnabled then
    								RemoveChams(v)
    								CreateChams(v)
    							end
    							if Bullshit.TracersEnabled then
    								RemoveTracers(v)
    								CreateTracers(v)
    							end
    							repeat wait() until Char:FindFirstChild("HumanoidRootPart")
    							TracerMT[v.Name] = Char.HumanoidRootPart
    						end)
    					end
    					RemoveESP(v)
    					CreateESP(v)
    				end
    			end
    			CreateMobESPChams()
    		else
    			ESPToggle.BackgroundColor3 = Color3.new(1, 1, 1)
    			PlayerESP:ClearAllChildren()
    			ItemESP:ClearAllChildren()
    		end
    	end)
	
    	ChamsToggle.MouseButton1Click:connect(function()
    		Bullshit.CHAMSEnabled = not Bullshit.CHAMSEnabled
    		if Bullshit.CHAMSEnabled then
    			ChamsToggle.BackgroundColor3 = Color3.new(0/255,171/255,11/255)
    			for _, v in next, Plrs:GetPlayers() do
    				if v ~= MyPlr then
    					if Bullshit.CharAddedEvent[v.Name] == nil then
    						Bullshit.CharAddedEvent[v.Name] = v.CharacterAdded:connect(function(Char)
    							if Bullshit.ESPEnabled then
    								RemoveESP(v)
    								CreateESP(v)
    							end
    							if Bullshit.CHAMSEnabled then
    								RemoveChams(v)
    								CreateChams(v)
    							end
    							if Bullshit.TracersEnabled then
    								RemoveTracers(v)
    								CreateTracers(v)
    							end
    							repeat wait() until Char:FindFirstChild("HumanoidRootPart")
    							TracerMT[v.Name] = Char.HumanoidRootPart
    						end)
    					end
    					RemoveChams(v)
    					CreateChams(v)
    				end
    			end
    			CreateMobESPChams()
    		else
    			ChamsToggle.BackgroundColor3 = Color3.new(1, 1, 1)
    			PlayerChams:ClearAllChildren()
    			ItemChams:ClearAllChildren()
    		end
    	end)
	
    	TracersToggle.MouseButton1Click:connect(function()
    		Bullshit.TracersEnabled = not Bullshit.TracersEnabled
    		if Bullshit.TracersEnabled then
    			TracersToggle.BackgroundColor3 = Color3.new(0/255,171/255,11/255)
    			for _, v in next, Plrs:GetPlayers() do
    				if v ~= MyPlr then
    					if Bullshit.CharAddedEvent[v.Name] == nil then
    						Bullshit.CharAddedEvent[v.Name] = v.CharacterAdded:connect(function(Char)
    							if Bullshit.ESPEnabled then
    								RemoveESP(v)
    								CreateESP(v)
    							end
    							if Bullshit.CHAMSEnabled then
    								RemoveChams(v)
    								CreateChams(v)
    							end
    							if Bullshit.TracersEnabled then
    								RemoveTracers(v)
    								CreateTracers(v)
    							end
    						end)
    					end
    					if v.Character ~= nil then
    						local Tor = v.Character:FindFirstChild("HumanoidRootPart")
    						if Tor then
    							TracerMT[v.Name] = Tor
    						end
    					end
    					RemoveTracers(v)
    					CreateTracers(v)
    				end
    			end
    		else
    			TracersToggle.BackgroundColor3 = Color3.new(1, 1, 1)
    			for _, v in next, Plrs:GetPlayers() do
    				RemoveTracers(v)
    			end
    		end
    	end)

    	DebugToggle.MouseButton1Click:connect(function()
    		Bullshit.DebugInfo = not Bullshit.DebugInfo
    		DebugMenu["Main"].Visible = Bullshit.DebugInfo
    		if Bullshit.DebugInfo then
    			DebugToggle.BackgroundColor3 = Color3.new(0/255,171/255,11/255)
    		else
    			DebugToggle.BackgroundColor3 = Color3.new(1, 1, 1)
    		end
    	end)

    	OutlineToggle.MouseButton1Click:connect(function()
    		Bullshit.OutlinesEnabled = not Bullshit.OutlinesEnabled
    		if Bullshit.OutlinesEnabled then
    			OutlineToggle.BackgroundColor3 = Color3.new(0/255,171/255,11/255)
    			for _, v in next, workspace:GetDescendants() do
    				if v:IsA("BasePart") and not Plrs:GetPlayerFromCharacter(v.Parent) and not v.Parent:IsA("Hat") and not v.Parent:IsA("Accessory") and v.Parent.Name ~= "Tracers" then
    					local Data = { }
    					Data[2] = v.Transparency
    					v.Transparency = 1
    					local outline = Instance.new("SelectionBox")
    					outline.Name = "Outline"
    					outline.Color3 = Color3.new(0, 0, 0)
    					outline.SurfaceColor3 = Color3.new(0, 1, 0)
    					--outline.SurfaceTransparency = 0.9
    					outline.LineThickness = 0.01
    					outline.Transparency = 0.3
    					outline.Adornee = v
    					outline.Parent = v
    					Data[1] = outline
    					rawset(Bullshit.OutlinedParts, v, Data)
    				end
    				CreateChildAddedEventFor(v)
    			end
    			CreateChildAddedEventFor(workspace)
    			if Bullshit.LightingEvent == nil then
    				Bullshit.LightingEvent = game:GetService("Lighting").Changed:connect(LightingHax)
    			end
    		else
    			OutlineToggle.BackgroundColor3 = Color3.new(1, 1, 1)
    			for i, v in next, Bullshit.OutlinedParts do
    				i.Transparency = v[2]
    				v[1]:Destroy()
    			end
    		end
    	end)

    	FullbrightToggle.MouseButton1Click:connect(function()
    		Bullshit.FullbrightEnabled = not Bullshit.FullbrightEnabled
    		if Bullshit.FullbrightEnabled then
    			FullbrightToggle.BackgroundColor3 = Color3.new(0/255,171/255,11/255)
    			if Bullshit.LightingEvent == nil then
    				Bullshit.LightingEvent = Light.Changed:connect(LightingHax)
    			end
    		else
    			FullbrightToggle.BackgroundColor3 = Color3.new(1, 1, 1)
    			Light.Ambient = Bullshit.AmbientBackup
    			Light.ColorShift_Bottom = Bullshit.ColorShiftBotBackup
    			Light.ColorShift_Top = Bullshit.ColorShiftTopBackup
    		end
    	end)

    	Crosshair.MouseButton1Click:connect(function()
    		Bullshit.CrosshairEnabled = not Bullshit.CrosshairEnabled
    		if Bullshit.CrosshairEnabled then
    			local g = Instance.new("ScreenGui", CoreGui)
    			g.Name = "Corsshair"
    			local line1 = Instance.new("TextLabel", g)
    			line1.Text = ""
    			line1.Size = UDim2.new(0, 35, 0, 1)
    			line1.BackgroundColor3 = Bullshit.Colors.Crosshair
    			line1.BorderSizePixel = 0
    			line1.ZIndex = 10
    			local line2 = Instance.new("TextLabel", g)
    			line2.Text = ""
    			line2.Size = UDim2.new(0, 1, 0, 35)
    			line2.BackgroundColor3 = Bullshit.Colors.Crosshair
    			line2.BorderSizePixel = 0
    			line2.ZIndex = 10

                local viewport = MyCam.ViewportSize
                local centerx = viewport.X / 2
                local centery = viewport.Y / 2

                line1.Position = UDim2.new(0, centerx - (35 / 2), 0, centery - 35)
                line2.Position = UDim2.new(0, centerx, 0, centery - (35 / 2) - 35)

    			Crosshair.BackgroundColor3 = Color3.new(0/255,171/255,11/255)
    		else
    			local find = CoreGui:FindFirstChild("Corsshair")
    			if find then
    				find:Destroy()
    			end

    			Crosshairs.BackgroundColor3 = Color3.new(1, 1, 1)
    		end
    	end)

    	AimbotToggle.MouseButton1Click:connect(function()
    		if not (game.PlaceId == 292439477 or game.PlaceId == 606849621) then
    			Bullshit.AimbotEnabled = not Bullshit.AimbotEnabled
    			if Bullshit.AimbotEnabled then
    				AimbotToggle.BackgroundColor3 = Color3.new(0/255,171/255,11/255)
    			else
    				AimbotToggle.BackgroundColor3 = Color3.new(1, 1, 1)
    			end
    		else
    			local hint = Instance.new("Hint", CoreGui)
    			hint.Text = "This game prevents camera manipulation!"
    			wait(5)
    			hint:Destroy()
    		end
    	end)

    	TracersUnderChars.MouseButton1Click:connect(function()
    		Bullshit.PlaceTracersUnderCharacter = not Bullshit.PlaceTracersUnderCharacter
    		if Bullshit.PlaceTracersUnderCharacter then
    			TracersUnderChars.Text = "true"
    		else
    			TracersUnderChars.Text = "false"
    		end
    	end)

    	FreeForAll.MouseButton1Click:connect(function()
    		Bullshit.FreeForAll = not Bullshit.FreeForAll
    		if Bullshit.FreeForAll then
    			FreeForAll.Text = "true"
    		else
    			FreeForAll.Text = "false"
    		end
    	end)

    	ESPLength.FocusLost:connect(function()
    		local txt = ESPLength.Text
    		local num = tonumber(txt) or 10000
    		if num ~= nil then
    			if num < 100 then
    				num = 100
    				ESPLength.Text = num
    			elseif num > 10000 then
    				num = 10000
    				ESPLength.Text = num
    			end
    		end

    		Bullshit.ESPLength = num
    		ESPLength.Text = num
    	end)

    	CHAMSLength.FocusLost:connect(function()
    		local txt = CHAMSLength.Text
    		local num = tonumber(txt) or 500
    		if num ~= nil then
    			if num < 100 then
    				num = 100
    				CHAMSLength.Text = num
    			elseif num > 2048 then
    				num = 2048
    				CHAMSLength.Text = num
    			end
    		end

    		Bullshit.CHAMSLength = num
    		CHAMSLength.Text = num
    	end)

    	TracersLength.FocusLost:connect(function()
    		local txt = TracersLength.Text
    		local num = tonumber(txt) or 500
    		if num ~= nil then
    			if num < 100 then
    				num = 100
    				TracersLength.Text = num
    			elseif num > 2048 then
    				num = 2048
    				TracersLength.Text = num
    			end
    		end

    		Bullshit.TracersLength = num
    		TracersLength.Text = num
    	end)

    	EnemyColor.FocusLost:connect(function()
    		local R, G, B = string.match(RemoveSpacesFromString(EnemyColor.Text), "(%d+),(%d+),(%d+)")
    		R = tonumber(R)
    		G = tonumber(G)
    		B = tonumber(B)
    		if R > 1 then
    			R = R / 255
    		end
    		if G > 1 then
    			G = G / 255
    		end
    		if B > 1 then
    			B = B / 255
    		end

    		if R ~= nil and G ~= nil and B ~= nil then
    			if not (R > 1 and G > 1 and B > 1) and not (R < 0 and G < 0 and B < 0) then
    				Bullshit.Colors.Enemy = Color3.new(R, G, B)
    				EnemyColor.Text = tostring(Bullshit.Colors.Enemy)
    			else
    				EnemyColor.Text = tostring(Bullshit.Colors.Enemy)
    			end
    		else
    			EnemyColor.Text = tostring(Bullshit.Colors.Enemy)
    		end
    	end)

    	AllyColor.FocusLost:connect(function()
    		local R, G, B = string.match(RemoveSpacesFromString(AllyColor.Text), "(%d+),(%d+),(%d+)")
    		R = tonumber(R)
    		G = tonumber(G)
    		B = tonumber(B)
    		if R > 1 then
    			R = R / 255
    		end
    		if G > 1 then
    			G = G / 255
    		end
    		if B > 1 then
    			B = B / 255
    		end

    		if R ~= nil and G ~= nil and B ~= nil then
    			if not (R > 1 and G > 1 and B > 1) and not (R < 0 and G < 0 and B < 0) then
    				Bullshit.Colors.Ally = Color3.new(R, G, B)
    				AllyColor.Text = tostring(Bullshit.Colors.Ally)
    			else
    				AllyColor.Text = tostring(Bullshit.Colors.Ally)
    			end
    		else
    			AllyColor.Text = tostring(Bullshit.Colors.Ally)
    		end
    	end)

    	FriendColor.FocusLost:connect(function()
    		local R, G, B = string.match(RemoveSpacesFromString(FriendColor.Text), "(%d+),(%d+),(%d+)")
    		R = tonumber(R)
    		G = tonumber(G)
    		B = tonumber(B)
    		if R > 1 then
    			R = R / 255
    		end
    		if G > 1 then
    			G = G / 255
    		end
    		if B > 1 then
    			B = B / 255
    		end

    		if R ~= nil and G ~= nil and B ~= nil then
    			if not (R > 1 and G > 1 and B > 1) and not (R < 0 and G < 0 and B < 0) then
    				Bullshit.Colors.Ally = Color3.new(R, G, B)
    				FriendColor.Text = tostring(Bullshit.Colors.Friend)
    			else
    				FriendColor.Text = tostring(Bullshit.Colors.Friend)
    			end
    		else
    			FriendColor.Text = tostring(Bullshit.Colors.Friend)
    		end
    	end)

    	NeutralColor.FocusLost:connect(function()
    		local R, G, B = string.match(RemoveSpacesFromString(NeutralColor.Text), "(%d+),(%d+),(%d+)")
    		R = tonumber(R)
    		G = tonumber(G)
    		B = tonumber(B)
    		if R > 1 then
    			R = R / 255
    		end
    		if G > 1 then
    			G = G / 255
    		end
    		if B > 1 then
    			B = B / 255
    		end

    		if R ~= nil and G ~= nil and B ~= nil then
    			if not (R > 1 and G > 1 and B > 1) and not (R < 0 and G < 0 and B < 0) then
    				Bullshit.Colors.Ally = Color3.new(R, G, B)
    				NeutralColor.Text = tostring(Bullshit.Colors.Neutral)
    			else
    				NeutralColor.Text = tostring(Bullshit.Colors.Neutral)
    			end
    		else
    			NeutralColor.Text = tostring(Bullshit.Colors.Neutral)
    		end
    	end)

    	CrosshairColor.FocusLost:connect(function()
    		local R, G, B = string.match(RemoveSpacesFromString(CrosshairColor.Text), "(%d+),(%d+),(%d+)")
    		R = tonumber(R)
    		G = tonumber(G)
    		B = tonumber(B)
    		if R > 1 then
    			R = R / 255
    		end
    		if G > 1 then
    			G = G / 255
    		end
    		if B > 1 then
    			B = B / 255
    		end

    		if R ~= nil and G ~= nil and B ~= nil then
    			if not (R > 1 and G > 1 and B > 1) and not (R < 0 and G < 0 and B < 0) then
    				Bullshit.Colors.Ally = Color3.new(R, G, B)
    				EnemyColor.Text = tostring(Bullshit.Colors.Crosshair)
    			else
    				EnemyColor.Text = tostring(Bullshit.Colors.Crosshair)
    			end
    		else
    			EnemyColor.Text = tostring(Bullshit.Colors.Crosshair)
    		end
    	end)

    	AutoFireToggle.MouseButton1Click:connect(function()
    		local hint = Instance.new("Hint", CoreGui)
    		hint.Text = "Currently broken. :("
    		wait(3)
    		hint:Destroy()
    		--Bullshit.AutoFire = not Bullshit.AutoFire
    		--AutoFireToggle.Text = tostring(Bullshit.AutoFire)
    	end)

    	AimbotKey.MouseButton1Click:connect(function()
    		AimbotKey.Text = "Press any Key now."
    		local input = UserInput.InputBegan:wait()
    		if input.UserInputType == Enum.UserInputType.Keyboard then
    			Bullshit.AimbotKey = tostring(input.KeyCode)
    			AimbotKey.Text = string.sub(tostring(input.KeyCode), 14)
    		else
    			Bullshit.AimbotKey = tostring(input.UserInputType)
    			AimbotKey.Text = string.sub(tostring(input.UserInputType), 20)
    		end
    	end)

    	MobESPButton.MouseButton1Click:connect(function()
    		Bullshit.MobESP = not Bullshit.MobESP
    		MobESPButton.Text = tostring(Bullshit.MobESP)
    		if Bullshit.MobESP then
    			local hint = Instance.new("Hint", CoreGui)
    			hint.Text = "Turn ESP/Chams off and on again to see mob ESP."
    			wait(5)
    			hint.Text = "This is still in beta, expect problems! Message Racist Dolphin#5199 on discord if you encounter a bug!"
    			wait(10)
    			hint:Destroy()
    		end
    	end)

    	MobChamsButton.MouseButton1Click:connect(function()
    		Bullshit.MobChams = not Bullshit.MobChams
    		MobChamsButton.Text = tostring(Bullshit.MobChams)
    		if Bullshit.MobChams then
    			local hint = Instance.new("Hint", CoreGui)
    			hint.Text = "Turn ESP/Chams off and on again to see mob chams."
    			wait(5)
    			hint.Text = "This is still in beta, expect problems! Message Racist Dolphin#5199 on discord if you encounter a bug!"
    			wait(10)
    			hint:Destroy()
    		end
    	end)

    	Playername.FocusLost:connect(function()
    		local FindPlr = FindPlayer(Playername.Text)
    		if FindPlr then
    			Playername.Text = FindPlr.Name
    		elseif not Bullshit.Blacklist[Playername.Text] then
    			Playername.Text = "Player not Found!"
    			wait(1)
    			Playername.Text = "Enter Player Name"
    		end
    	end)

    	AddToBlacklist.MouseButton1Click:connect(function()
    		local FindPlr = FindPlayer(Playername.Text)
    		if FindPlr then
    			if not Bullshit.Blacklist[FindPlr.Name] then
    				Bullshit.Blacklist[FindPlr.Name] = true
    				UpdateChams(FindPlr)
    				CreatePlayerLabel(FindPlr.Name, players)
    			end
    		end
    	end)

    	RemoveToBlacklist.MouseButton1Click:connect(function()
    		local FindPlr = FindPlayer(Playername.Text)
    		if FindPlr then
    			if Bullshit.Blacklist[FindPlr.Name] then
    				Bullshit.Blacklist[FindPlr.Name] = nil
    				UpdateChams(FindPlr)
    				RefreshPlayerLabels(players, Bullshit.Blacklist)
    			end
    		else
    			if Bullshit.Blacklist[Playername.Text] then
    				Bullshit.Blacklist[Playername.Text] = nil
    				RefreshPlayerLabels(players, Bullshit.Blacklist)
    			end
    		end
    	end)

    	Playername2.FocusLost:connect(function()
    		local FindPlr = FindPlayer(Playername2.Text)
    		if FindPlr then
    			Playername2.Text = FindPlr.Name
    		elseif not Bullshit.FriendList[Playername2.Text] then
    			Playername2.Text = "Player not Found!"
    			wait(1)
    			Playername2.Text = "Enter Player Name"
    		end
    	end)

    	AddToWhitelist.MouseButton1Click:connect(function()
    		local FindPlr = FindPlayer(Playername2.Text)
    		if FindPlr then
    			if not Bullshit.FriendList[FindPlr.Name] then
    				Bullshit.FriendList[FindPlr.Name] = true
    				UpdateChams(FindPlr)
    				CreatePlayerLabel(FindPlr.Name, players2)
    			end
    		end
    	end)

    	RemoveToWhitelist.MouseButton1Click:connect(function()
    		local FindPlr = FindPlayer(Playername2.Text)
    		if FindPlr then
    			if Bullshit.FriendList[FindPlr.Name] then
    				Bullshit.FriendList[FindPlr.Name] = nil
    				UpdateChams(FindPlr)
    				RefreshPlayerLabels(players2, Bullshit.FriendList)
    			end
    		else
    			if Bullshit.FriendList[Playername2.Text] then
    				Bullshit.FriendList[Playername2.Text] = nil
    				RefreshPlayerLabels(players2, Bullshit.FriendList)
    			end
    		end
    	end)

    	SaveWhitelist.MouseButton1Click:connect(function()
    		pcall(function()
    			writefile("Whitelist.txt", HTTP:JSONEncode(Bullshit.FriendList))
    		end)
    		SaveWhitelist.Text = "Saved!"
    		wait(1)
    		SaveWhitelist.Text = "Save Friends List"
    	end)

    	SaveBlacklist.MouseButton1Click:connect(function()
    		pcall(function()
    			writefile("Blacklist.txt", HTTP:JSONEncode(Bullshit.Blacklist))
    		end)
    		SaveBlacklist.Text = "Saved!"
    		wait(1)
    		SaveBlacklist.Text = "Save Blacklist"
    	end)

    	Settings.MouseButton1Click:connect(function()
    		Settings_2.Visible = not Settings_2.Visible
    		Information_2.Visible = false
    		Blacklist.Visible = false
    		Whitelist.Visible = false
    		if Settings_2.Visible then
    			Settings.BackgroundColor3 = Color3.new(0/255,171/255,11/255)
    			Information.BackgroundColor3 = Color3.new(1, 1, 1)
    			BlacklistToggle.BackgroundColor3 = Color3.new(1, 1, 1)
    			WhitelistToggle.BackgroundColor3 = Color3.new(1, 1, 1)
    		else
    			Settings.BackgroundColor3 = Color3.new(1, 1, 1)
    		end
    	end)

    	Information.MouseButton1Click:connect(function()
    		Information_2.Visible = not Information_2.Visible
    		Settings_2.Visible = false
    		Blacklist.Visible = false
    		Whitelist.Visible = false
    		if Information_2.Visible then
    			Information.BackgroundColor3 = Color3.new(0/255,171/255,11/255)
    			Settings.BackgroundColor3 = Color3.new(1, 1, 1)
    			BlacklistToggle.BackgroundColor3 = Color3.new(1, 1, 1)
    			WhitelistToggle.BackgroundColor3 = Color3.new(1, 1, 1)
    		else
    			Information.BackgroundColor3 = Color3.new(1, 1, 1)
    		end
    	end)

    	BlacklistToggle.MouseButton1Click:connect(function()
    		Blacklist.Visible = not Blacklist.Visible
    		Settings_2.Visible = false
    		Information_2.Visible = false
    		Whitelist.Visible = false
    		if Blacklist.Visible then
    			BlacklistToggle.BackgroundColor3 = Color3.new(0/255,171/255,11/255)
    			Settings.BackgroundColor3 = Color3.new(1, 1, 1)
    			Information.BackgroundColor3 = Color3.new(1, 1, 1)
    			WhitelistToggle.BackgroundColor3 = Color3.new(1, 1, 1)
    		else
    			BlacklistToggle.BackgroundColor3 = Color3.new(1, 1, 1)
    		end
    	end)

    	WhitelistToggle.MouseButton1Click:connect(function()
    		Whitelist.Visible = not Whitelist.Visible
    		Settings_2.Visible = false
    		Information_2.Visible = false
    		Blacklist.Visible = false
    		if Whitelist.Visible then
    			WhitelistToggle.BackgroundColor3 = Color3.new(0/255,171/255,11/255)
    			Settings.BackgroundColor3 = Color3.new(1, 1, 1)
    			Information.BackgroundColor3 = Color3.new(1, 1, 1)
    			BlacklistToggle.BackgroundColor3 = Color3.new(1, 1, 1)
    		else
    			WhitelistToggle.BackgroundColor3 = Color3.new(1, 1, 1)
    		end
    	end)

    	SaveSettings.MouseButton1Click:connect(function()
    		SaveBullshitSettings()
    		SaveSettings.Text = "Saved!"
    		wait(1)
    		SaveSettings.Text = "Save Settings"
    	end)

    	UserInput.InputBegan:connect(function(input, ingui)
    		if not ingui then
    			if input.UserInputType == Enum.UserInputType.Keyboard then
    				if input.KeyCode == Enum.KeyCode.P then
    					MainFrame.Visible = not MainFrame.Visible
    				end
    			end

    			if tostring(input.KeyCode) == Bullshit.AimbotKey or tostring(input.UserInputType) == Bullshit.AimbotKey then
    				Bullshit.Aimbot = true
    			end
    		end
    	end)

    	UserInput.InputEnded:connect(function(input)
    		if tostring(input.KeyCode) == Bullshit.AimbotKey or tostring(input.UserInputType) == Bullshit.AimbotKey then
    			Bullshit.Aimbot = false
    		end
    	end)
    end

    InitMain()

    Run:BindToRenderStep("UpdateESP", Enum.RenderPriority.Character.Value, function()
    	for _, v in next, Plrs:GetPlayers() do
    		if v ~= MyPlr then
    			UpdateESP(v)
    		end
    	end
    end)

    Run:BindToRenderStep("UpdateInfo", 1000, function()
    	Bullshit.ClosestEnemy = GetClosestPlayer()
    	MyChar = MyPlr.Character
    	if Bullshit.DebugInfo then
    		local MyHead, MyTor, MyHum = MyChar:FindFirstChild("Head"), MyChar:FindFirstChild("HumanoidRootPart"), MyChar:FindFirstChild("Humanoid")

    		local GetChar, GetHead, GetTor, GetHum = nil, nil, nil, nil
    		if Bullshit.ClosestEnemy ~= nil then
    			GetChar = Bullshit.ClosestEnemy.Character
    			GetHead = GetChar:FindFirstChild("Head")
    			GetTor = GetChar:FindFirstChild("HumanoidRootPart")
    			GetHum = GetChar:FindFirstChild("Humanoid")

    			DebugMenu["PlayerSelected"].Text = "Closest Enemy: " .. tostring(Bullshit.ClosestEnemy)

    			if Bullshit.ClosestEnemy.Team ~= nil then
    				DebugMenu["PlayerTeam"].Text = "Team: " .. tostring(Bullshit.ClosestEnemy.Team)
    			else
    				DebugMenu["PlayerTeam"].Text = "Team: nil"
    			end

    			if GetHum then
    				DebugMenu["PlayerHealth"].Text = "Health: " .. string.format("%.0f", GetHum.Health)
    			end
    			if MyTor and GetTor then
    				local Pos = GetTor.Position
    				local Dist = (MyTor.Position - Pos).magnitude
    				DebugMenu["PlayerPosition"].Text = "Position: (X: " .. string.format("%.3f", Pos.X) .. " Y: " .. string.format("%.3f", Pos.Y) .. " Z: " .. string.format("%.3f", Pos.Z) .. ") Distance: " .. string.format("%.0f", Dist) .. " Studs"

    				local MyCharStuff = MyChar:GetDescendants()
    				local GetCharStuff = GetChar:GetDescendants()
    				for _, v in next, GetCharStuff do
    					if v ~= GetTor then
    						table.insert(MyCharStuff, v)
    					end
    				end
    				local Ray = Ray.new(MyTor.Position, (Pos - MyTor.Position).unit * 300)
    				local part = workspace:FindPartOnRayWithIgnoreList(Ray, MyCharStuff)
    				if part == GetTor then
    					DebugMenu["BehindWall"].Text = "Behind Wall: false"
    				else
    					DebugMenu["BehindWall"].Text = "Behind Wall: true"
    				end

    				DebugMenu["Main"].Size = UDim2.new(0, DebugMenu["PlayerPosition"].TextBounds.X, 0, 200)
    			end
    		end

    		-- My Position
    		if MyTor then
    			local Pos = MyTor.Position
    			DebugMenu["Position"].Text = "My Position: (X: " .. string.format("%.3f", Pos.x) .. " Y: " .. string.format("%.3f", Pos.Y) .. " Z: " .. string.format("%.3f", Pos.Z) .. ")"
    		end

    		-- FPS
    		local fps = math.floor(.5 + (1 / (tick() - LastTick)))
    		local sum = 0
    		local ave = 0
    		table.insert(Bullshit.FPSAverage, fps)
    		for i = 1, #Bullshit.FPSAverage do
    			sum = sum + Bullshit.FPSAverage[i]
    		end
    		DebugMenu["FPS"].Text = "FPS: " .. tostring(fps) .. " Average: " .. string.format("%.0f", (sum / #Bullshit.FPSAverage))
    		if (tick() - LastTick) >= 15 then
    			Bullshit.FPSAverage = { }
    			LastTick = tick()
    		end
    		LastTick = tick()
    	end
    end)

    Run:BindToRenderStep("Aimbot", Enum.RenderPriority.First.Value, function()
    	ClosestEnemy = GetClosestPlayerNotBehindWall()
    	if Bullshit.AimbotEnabled and Bullshit.Aimbot then
    		if ClosestEnemy ~= nil then
    			local GetChar = ClosestEnemy.Character
    			if MyChar and GetChar then
    				local MyCharStuff = MyChar:GetDescendants()
    				local MyHead = MyChar:FindFirstChild("Head")
    				local MyTor = MyChar:FindFirstChild("HumanoidRootPart")
    				local MyHum = MyChar:FindFirstChild("Humanoid")
    				local GetHead = GetChar:FindFirstChild("Head")
    				local GetTor = GetChar:FindFirstChild("HumanoidRootPart")
    				local GetHum = GetChar:FindFirstChild("Humanoid")
    				if MyHead and MyTor and MyHum and GetHead and GetTor and GetHum then
    					if MyHum.Health > 1 and (GetHum.Health > 1 and not GetChar:FindFirstChild("KO")) then
    						MyPlr.CameraMode = Enum.CameraMode.LockFirstPerson
    						MyCam.CFrame = CFrame.new(MyHead.CFrame.p, GetHead.CFrame.p)
    						if Bullshit.AutoFire then
    							mouse1click() -- >:(
    						end
    					end
    				end
    			end
    		end
    	else
    		MyPlr.CameraMode = Bullshit.CameraModeBackup
    	end
    end)

    local succ, out = coroutine.resume(coroutine.create(function()
    	while true do
    		for _, v in next, Plrs:GetPlayers() do
    			UpdateChams(v)
    			Run.RenderStepped:wait()
    		end
    	end
    end))

    if not succ then
    	error(out)
    end
end





function ArceusX()
    --[=[

        ___      _  _     __     _         _         ____   
      ,"___".   FJ  L]    FJ    FJ        FJ        [__  '. 
      FJ---L]  J |__| L  J  L  J |       J |        `--7 .' 
     J |   LJ  |  __  |  |  |  | |       | |         .'.'.' 
     | \___--. F L__J J  F  J  F L_____  F L_____  .' (_(__ 
     J\_____/FJ__L  J__LJ____LJ________LJ________LJ________L
      J_____F |__L  J__||____||________||________||________|
                                                        
 
    ]=]

    --Huge thanks for Bread for good textbox and remake the sliders :D
    --GuiToLua By Creator of Backdoor.exe

    -- Arceus X v3 Remake
    local AZY = {};

    -- StarterGui.ArceusXV3
    AZY["1"] = Instance.new("ScreenGui", game.CoreGui);
    AZY["1"]["Name"] = [[ArceusXV3]];
    AZY["1"]["ZIndexBehavior"] = Enum.ZIndexBehavior.Sibling;
    AZY["1"]["ResetOnSpawn"] = false;

    -- StarterGui.ArceusXV3.Welcome
    AZY["2"] = Instance.new("Folder", AZY["1"]);
    AZY["2"]["Name"] = [[Welcome]];

    -- StarterGui.ArceusXV3.Welcome.Frame
    AZY["3"] = Instance.new("Frame", AZY["2"]);
    AZY["3"]["BackgroundColor3"] = Color3.fromRGB(255, 255, 255);
    AZY["3"]["BackgroundTransparency"] = 0.699999988079071;
    AZY["3"]["Size"] = UDim2.new(100.58300018310547, 0, 10.576000213623047, 0);
    AZY["3"]["BorderColor3"] = Color3.fromRGB(28, 43, 54);
    AZY["3"]["Position"] = UDim2.new(-0.012608751654624939, 0, -1.0678343772888184, 0);

    -- StarterGui.ArceusXV3.Welcome.Frame.UIAspectRatioConstraint
    AZY["4"] = Instance.new("UIAspectRatioConstraint", AZY["3"]);
    AZY["4"]["AspectRatio"] = 2.0052521228790283;

    -- StarterGui.ArceusXV3.Welcome.Welcome
    AZY["5"] = Instance.new("Frame", AZY["2"]);
    AZY["5"]["BackgroundColor3"] = Color3.fromRGB(52, 52, 52);
    AZY["5"]["Size"] = UDim2.new(0.666020393371582, 0, 0.8211921453475952, 0);
    AZY["5"]["Position"] = UDim2.new(0.17622511088848114, 0, 0.0894039198756218, 0);
    AZY["5"]["Name"] = [[Welcome]];

    -- StarterGui.ArceusXV3.Welcome.Welcome.UIAspectRatioConstraint
    AZY["6"] = Instance.new("UIAspectRatioConstraint", AZY["5"]);
    AZY["6"]["AspectRatio"] = 1.6193960905075073;

    -- StarterGui.ArceusXV3.Welcome.Welcome.ScrollingFrame
    AZY["7"] = Instance.new("ScrollingFrame", AZY["5"]);
    AZY["7"]["Active"] = true;
    AZY["7"]["CanvasSize"] = UDim2.new(0, 0, 1.2000000476837158, 0);
    AZY["7"]["BackgroundColor3"] = Color3.fromRGB(255, 255, 255);
    AZY["7"]["BackgroundTransparency"] = 1;
    AZY["7"]["Size"] = UDim2.new(1.0180450677871704, 0, 1, 0);
    AZY["7"]["ScrollBarImageColor3"] = Color3.fromRGB(0, 0, 0);
    AZY["7"]["BorderColor3"] = Color3.fromRGB(255, 255, 255);
    AZY["7"]["ScrollBarThickness"] = 7;

    -- StarterGui.ArceusXV3.Welcome.Welcome.ScrollingFrame.Text
    AZY["8"] = Instance.new("TextLabel", AZY["7"]);
    AZY["8"]["TextWrapped"] = true;
    AZY["8"]["TextYAlignment"] = Enum.TextYAlignment.Top;
    AZY["8"]["TextScaled"] = true;
    AZY["8"]["BackgroundColor3"] = Color3.fromRGB(255, 255, 255);
    AZY["8"]["TextXAlignment"] = Enum.TextXAlignment.Left;
    AZY["8"]["FontFace"] = Font.new([[rbxasset://fonts/families/SourceSansPro.json]], Enum.FontWeight.Regular, Enum.FontStyle.Normal);
    AZY["8"]["TextSize"] = 29;
    AZY["8"]["TextColor3"] = Color3.fromRGB(255, 255, 255);
    AZY["8"]["Size"] = UDim2.new(0.8902860283851624, 0, 0.6482642889022827, 0);
    AZY["8"]["Text"] = [[Dear User,

    We are writing to welcome you as one of you first bete testers of Arceus X!
    We are thrilled to have your collaboration and to offer you the oppoturnity
    to try out the new features we are developing.

    We are confident that your experience and creativity will help us make
    Arceus X an even more effective and user-friendly application.
    Please feel free to share any feedback and suggestion that can help us further
    improve our platform.

    Thank you so much your support, and we look forward to working with
    you in this exciting journey!

    Best regards,
    SPDM Team]];
    AZY["8"]["Name"] = [[Text]];
    AZY["8"]["BackgroundTransparency"] = 1;
    AZY["8"]["Position"] = UDim2.new(0.04280221089720726, 0, 0.14032021164894104, 0);

    -- StarterGui.ArceusXV3.Welcome.Welcome.ScrollingFrame.Text.LocalScript
    AZY["9"] = Instance.new("LocalScript", AZY["8"]);


    -- StarterGui.ArceusXV3.Welcome.Welcome.ScrollingFrame.TextButton
    AZY["a"] = Instance.new("TextButton", AZY["7"]);
    AZY["a"]["TextWrapped"] = true;
    AZY["a"]["TextScaled"] = true;
    AZY["a"]["BackgroundColor3"] = Color3.fromRGB(255, 0, 0);
    AZY["a"]["TextSize"] = 24;
    AZY["a"]["FontFace"] = Font.new([[rbxasset://fonts/families/SourceSansPro.json]], Enum.FontWeight.Bold, Enum.FontStyle.Normal);
    AZY["a"]["TextColor3"] = Color3.fromRGB(255, 255, 255);
    AZY["a"]["Size"] = UDim2.new(0.2372465580701828, 0, 0.10296772420406342, 0);
    AZY["a"]["Text"] = [[Get started]];
    AZY["a"]["Position"] = UDim2.new(0.3705448806285858, 0, 0.8786289095878601, 0);

    -- StarterGui.ArceusXV3.Welcome.Welcome.ScrollingFrame.TextButton.UICorner
    AZY["b"] = Instance.new("UICorner", AZY["a"]);
    AZY["b"]["CornerRadius"] = UDim.new(0, 12);

    -- StarterGui.ArceusXV3.Welcome.Welcome.ScrollingFrame.TextButton.UITextSizeConstraint
    AZY["c"] = Instance.new("UITextSizeConstraint", AZY["a"]);
    AZY["c"]["MaxTextSize"] = 24;

    -- StarterGui.ArceusXV3.Welcome.Welcome.ScrollingFrame.TextButton.LocalScriptNew
    AZY["d"] = Instance.new("LocalScript", AZY["a"]);
    AZY["d"]["Name"] = [[LocalScriptNew]];

    -- StarterGui.ArceusXV3.Welcome.Welcome.ScrollingFrame.Title
    AZY["e"] = Instance.new("TextLabel", AZY["7"]);
    AZY["e"]["TextWrapped"] = true;
    AZY["e"]["TextScaled"] = true;
    AZY["e"]["BackgroundColor3"] = Color3.fromRGB(255, 255, 255);
    AZY["e"]["FontFace"] = Font.new([[rbxasset://fonts/families/SourceSansPro.json]], Enum.FontWeight.Bold, Enum.FontStyle.Normal);
    AZY["e"]["TextSize"] = 45;
    AZY["e"]["TextColor3"] = Color3.fromRGB(255, 255, 255);
    AZY["e"]["Size"] = UDim2.new(0.624912440776825, 0, 0.12905988097190857, 0);
    AZY["e"]["Text"] = [[Welcome to Arceus X 3.0!]];
    AZY["e"]["Name"] = [[Title]];
    AZY["e"]["BackgroundTransparency"] = 1;
    AZY["e"]["Position"] = UDim2.new(0.1773233860731125, 0, 0.011320043355226517, 0);

    -- StarterGui.ArceusXV3.Welcome.Welcome.ScrollingFrame.Title.UITextSizeConstraint
    AZY["f"] = Instance.new("UITextSizeConstraint", AZY["e"]);
    AZY["f"]["MaxTextSize"] = 45;

    -- StarterGui.ArceusXV3.Welcome.Welcome.UICorner
    AZY["10"] = Instance.new("UICorner", AZY["5"]);
    AZY["10"]["CornerRadius"] = UDim.new(0, 40);

    -- StarterGui.ArceusXV3.AnimationIntro
    AZY["11"] = Instance.new("Folder", AZY["1"]);
    AZY["11"]["Name"] = [[AnimationIntro]];

    -- StarterGui.ArceusXV3.AnimationIntro.Background
    AZY["12"] = Instance.new("Frame", AZY["11"]);
    AZY["12"]["BackgroundColor3"] = Color3.fromRGB(28, 28, 28);
    AZY["12"]["Size"] = UDim2.new(0, 1806, 0, 1604);
    AZY["12"]["Position"] = UDim2.new(-0.11024535447359085, 0, -0.16887417435646057, 0);
    AZY["12"]["Visible"] = false;
    AZY["12"]["Name"] = [[Background]];

    -- StarterGui.ArceusXV3.AnimationIntro.Frame
    AZY["13"] = Instance.new("Frame", AZY["11"]);
    AZY["13"]["BackgroundColor3"] = Color3.fromRGB(255, 0, 0);
    AZY["13"]["Size"] = UDim2.new(0.03313452750444412, 0, 0.06622516363859177, 0);
    AZY["13"]["Position"] = UDim2.new(0.48293575644493103, 0, 0.4668874144554138, 0);
    AZY["13"]["Visible"] = false;

    -- StarterGui.ArceusXV3.AnimationIntro.Frame.UICorner
    AZY["14"] = Instance.new("UICorner", AZY["13"]);
    AZY["14"]["CornerRadius"] = UDim.new(1, 100);

    -- StarterGui.ArceusXV3.AnimationIntro.ImageLabel
    AZY["15"] = Instance.new("ImageLabel", AZY["11"]);
    AZY["15"]["BackgroundColor3"] = Color3.fromRGB(255, 255, 255);
    AZY["15"]["ImageTransparency"] = 1;
    AZY["15"]["Visible"] = false;
    AZY["15"]["Image"] = [[rbxassetid://12564267060]];
    AZY["15"]["Size"] = UDim2.new(0.09526176750659943, 0, 0.27649006247520447, 0);
    AZY["15"]["BackgroundTransparency"] = 1;
    AZY["15"]["Position"] = UDim2.new(0.4423459470272064, 0, 0.36092716455459595, 0);

    -- StarterGui.ArceusXV3.AnimationIntro.NameLogo
    AZY["16"] = Instance.new("TextLabel", AZY["11"]);
    AZY["16"]["TextWrapped"] = true;
    AZY["16"]["TextScaled"] = true;
    AZY["16"]["BackgroundColor3"] = Color3.fromRGB(255, 255, 255);
    AZY["16"]["FontFace"] = Font.new([[rbxasset://fonts/families/SourceSansPro.json]], Enum.FontWeight.Bold, Enum.FontStyle.Normal);
    AZY["16"]["TextTransparency"] = 1;
    AZY["16"]["TextSize"] = 50;
    AZY["16"]["TextColor3"] = Color3.fromRGB(255, 255, 255);
    AZY["16"]["Size"] = UDim2.new(0.13893571496009827, 0, 0.09271523356437683, 0);
    AZY["16"]["Text"] = [[Arceus X]];
    AZY["16"]["Name"] = [[NameLogo]];
    AZY["16"]["Visible"] = false;
    AZY["16"]["BackgroundTransparency"] = 1;
    AZY["16"]["Position"] = UDim2.new(0.3928734362125397, 0, 0.4523245096206665, 0);

    -- StarterGui.ArceusXV3.AnimationIntro.NameLogo.UITextSizeConstraint
    AZY["17"] = Instance.new("UITextSizeConstraint", AZY["16"]);
    AZY["17"]["MaxTextSize"] = 50;

    -- StarterGui.ArceusXV3.MainUI
    AZY["18"] = Instance.new("Folder", AZY["1"]);
    AZY["18"]["Name"] = [[MainUI]];

    -- StarterGui.ArceusXV3.MainUI.MainFrame
    AZY["19"] = Instance.new("Frame", AZY["18"]);
    AZY["19"]["BackgroundColor3"] = Color3.fromRGB(0, 0, 0);
    AZY["19"]["BackgroundTransparency"] = 0.44999998807907104;
    AZY["19"]["Size"] = UDim2.new(0, 459, 0, 276);
    AZY["19"]["Position"] = UDim2.new(0.1498919129371643, 0, 0.12086091935634613, 0);
    AZY["19"]["Visible"] = false;
    AZY["19"]["Name"] = [[MainFrame]];

    -- StarterGui.ArceusXV3.MainUI.MainFrame.UICorner
    AZY["1a"] = Instance.new("UICorner", AZY["19"]);
    AZY["1a"]["CornerRadius"] = UDim.new(0, 15);

    -- StarterGui.ArceusXV3.MainUI.MainFrame.Panel
    AZY["1b"] = Instance.new("Frame", AZY["19"]);
    AZY["1b"]["BackgroundColor3"] = Color3.fromRGB(0, 0, 0);
    AZY["1b"]["BackgroundTransparency"] = 0.550000011920929;
    AZY["1b"]["Size"] = UDim2.new(0.9417322874069214, 0, 0.11706378310918808, 0);
    AZY["1b"]["Position"] = UDim2.new(0.03099355846643448, 0, 0.0474083386361599, 0);
    AZY["1b"]["Name"] = [[Panel]];

    -- StarterGui.ArceusXV3.MainUI.MainFrame.Panel.UICorner
    AZY["1c"] = Instance.new("UICorner", AZY["1b"]);
    AZY["1c"]["CornerRadius"] = UDim.new(0, 14);

    -- StarterGui.ArceusXV3.MainUI.MainFrame.Panel.Logo
    AZY["1d"] = Instance.new("ImageLabel", AZY["1b"]);
    AZY["1d"]["BackgroundColor3"] = Color3.fromRGB(255, 255, 255);
    AZY["1d"]["Image"] = [[rbxassetid://12564267060]];
    AZY["1d"]["Size"] = UDim2.new(0.05029655620455742, 0, 0.9125484824180603, 0);
    AZY["1d"]["Name"] = [[Logo]];
    AZY["1d"]["BackgroundTransparency"] = 1;
    AZY["1d"]["Position"] = UDim2.new(0.4099465012550354, 0, 0.03155198320746422, 0);

    -- StarterGui.ArceusXV3.MainUI.MainFrame.Panel.TextLogo
    AZY["1e"] = Instance.new("TextLabel", AZY["1b"]);
    AZY["1e"]["TextWrapped"] = true;
    AZY["1e"]["TextScaled"] = true;
    AZY["1e"]["BackgroundColor3"] = Color3.fromRGB(255, 255, 255);
    AZY["1e"]["FontFace"] = Font.new([[rbxasset://fonts/families/SourceSansPro.json]], Enum.FontWeight.Bold, Enum.FontStyle.Normal);
    AZY["1e"]["TextSize"] = 85;
    AZY["1e"]["TextColor3"] = Color3.fromRGB(255, 255, 255);
    AZY["1e"]["Size"] = UDim2.new(0.1371736377477646, 0, 0.6307170391082764, 0);
    AZY["1e"]["Text"] = [[Arceus X]];
    AZY["1e"]["Name"] = [[TextLogo]];
    AZY["1e"]["BackgroundTransparency"] = 1;
    AZY["1e"]["Position"] = UDim2.new(0.4679349362850189, 0, 0.16660596430301666, 0);

    -- StarterGui.ArceusXV3.MainUI.MainFrame.Panel.TextLogo.UITextSizeConstraint
    AZY["1f"] = Instance.new("UITextSizeConstraint", AZY["1e"]);
    AZY["1f"]["MaxTextSize"] = 25;

    -- StarterGui.ArceusXV3.MainUI.MainFrame.Panel.Close
    AZY["20"] = Instance.new("ImageButton", AZY["1b"]);
    AZY["20"]["BackgroundColor3"] = Color3.fromRGB(255, 255, 255);
    AZY["20"]["Image"] = [[rbxassetid://12566509152]];
    AZY["20"]["Size"] = UDim2.new(0.06670181453227997, 0, 1, 0);
    AZY["20"]["Name"] = [[Close]];
    AZY["20"]["Position"] = UDim2.new(0.9171510338783264, 0, 0, 0);
    AZY["20"]["BackgroundTransparency"] = 1;

    -- StarterGui.ArceusXV3.MainUI.MainFrame.Panel.Close.LocalScript
    AZY["21"] = Instance.new("LocalScript", AZY["20"]);


    -- StarterGui.ArceusXV3.MainUI.MainFrame.Panel.Expand
    AZY["22"] = Instance.new("ImageButton", AZY["1b"]);
    AZY["22"]["BackgroundColor3"] = Color3.fromRGB(255, 255, 255);
    AZY["22"]["Image"] = [[rbxassetid://12566545357]];
    AZY["22"]["Size"] = UDim2.new(0.06901533156633377, 0, 1, 0);
    AZY["22"]["Name"] = [[Expand]];
    AZY["22"]["Position"] = UDim2.new(0.8481356501579285, 0, -0.024522678926587105, 0);
    AZY["22"]["BackgroundTransparency"] = 1;

    -- StarterGui.ArceusXV3.MainUI.MainFrame.Panel.Expand.LocalScript
    AZY["23"] = Instance.new("LocalScript", AZY["22"]);


    -- StarterGui.ArceusXV3.MainUI.MainFrame.Panel.TimeLeft
    AZY["24"] = Instance.new("TextLabel", AZY["1b"]);
    AZY["24"]["TextWrapped"] = true;
    AZY["24"]["TextScaled"] = true;
    AZY["24"]["BackgroundColor3"] = Color3.fromRGB(255, 255, 255);
    AZY["24"]["FontFace"] = Font.new([[rbxasset://fonts/families/SourceSansPro.json]], Enum.FontWeight.Regular, Enum.FontStyle.Normal);
    AZY["24"]["TextSize"] = 35;
    AZY["24"]["TextColor3"] = Color3.fromRGB(255, 255, 255);
    AZY["24"]["Size"] = UDim2.new(0.13600000739097595, 0, 0.38600000739097595, 0);
    AZY["24"]["Text"] = [[24h 00m left]];
    AZY["24"]["Name"] = [[TimeLeft]];
    AZY["24"]["BackgroundTransparency"] = 1;
    AZY["24"]["Position"] = UDim2.new(0.07365596294403076, 0, 0.28405851125717163, 0);

    -- StarterGui.ArceusXV3.MainUI.MainFrame.Panel.TimeLeft.LocalScript
    AZY["25"] = Instance.new("LocalScript", AZY["24"]);


    -- StarterGui.ArceusXV3.MainUI.MainFrame.Panel.Restore
    AZY["26"] = Instance.new("TextButton", AZY["1b"]);
    AZY["26"]["TextWrapped"] = true;
    AZY["26"]["BackgroundColor3"] = Color3.fromRGB(255, 0, 0);
    AZY["26"]["TextSize"] = 12;
    AZY["26"]["FontFace"] = Font.new([[rbxasset://fonts/families/SourceSansPro.json]], Enum.FontWeight.Bold, Enum.FontStyle.Normal);
    AZY["26"]["TextColor3"] = Color3.fromRGB(255, 255, 255);
    AZY["26"]["Size"] = UDim2.new(0.10400000214576721, 0, 0.503000020980835, 0);
    AZY["26"]["Name"] = [[Restore]];
    AZY["26"]["Text"] = [[Restore]];
    AZY["26"]["Position"] = UDim2.new(0.21463949978351593, 0, 0.22850705683231354, 0);

    -- StarterGui.ArceusXV3.MainUI.MainFrame.Panel.Restore.UICorner
    AZY["27"] = Instance.new("UICorner", AZY["26"]);
    AZY["27"]["CornerRadius"] = UDim.new(0, 6);

    -- StarterGui.ArceusXV3.MainUI.MainFrame.Panel.Restore.LocalScript
    AZY["28"] = Instance.new("LocalScript", AZY["26"]);


    -- StarterGui.ArceusXV3.MainUI.MainFrame.Panel.Icon
    AZY["29"] = Instance.new("ImageButton", AZY["1b"]);
    AZY["29"]["BackgroundColor3"] = Color3.fromRGB(255, 255, 255);
    AZY["29"]["Image"] = [[rbxassetid://12584810787]];
    AZY["29"]["Size"] = UDim2.new(0.05783621221780777, 0, 0.7737637162208557, 0);
    AZY["29"]["Name"] = [[Icon]];
    AZY["29"]["Position"] = UDim2.new(0.01600000075995922, 0, 0.09300000220537186, 0);
    AZY["29"]["BackgroundTransparency"] = 1;

    -- StarterGui.ArceusXV3.MainUI.MainFrame.Panel.Icon.LocalScript
    AZY["2a"] = Instance.new("LocalScript", AZY["29"]);


    -- StarterGui.ArceusXV3.MainUI.MainFrame.Tabs
    AZY["2b"] = Instance.new("Folder", AZY["19"]);
    AZY["2b"]["Name"] = [[Tabs]];

    -- StarterGui.ArceusXV3.MainUI.MainFrame.Tabs.Home
    AZY["2c"] = Instance.new("Frame", AZY["2b"]);
    AZY["2c"]["BackgroundColor3"] = Color3.fromRGB(0, 0, 0);
    AZY["2c"]["BackgroundTransparency"] = 1;
    AZY["2c"]["Size"] = UDim2.new(0.831805408000946, 0, 0.7336452603340149, 0);
    AZY["2c"]["Position"] = UDim2.new(0.1409204602241516, 0, 0.18711426854133606, 0);
    AZY["2c"]["Name"] = [[Home]];

    -- StarterGui.ArceusXV3.MainUI.MainFrame.Tabs.Home.UserPage
    AZY["2d"] = Instance.new("Frame", AZY["2c"]);
    AZY["2d"]["BackgroundColor3"] = Color3.fromRGB(0, 0, 0);
    AZY["2d"]["BackgroundTransparency"] = 0.550000011920929;
    AZY["2d"]["Size"] = UDim2.new(0.37270405888557434, 0, 0.2492256611585617, 0);
    AZY["2d"]["Position"] = UDim2.new(-0.0007835610886104405, 0, 0.025084324181079865, 0);
    AZY["2d"]["Name"] = [[UserPage]];

    -- StarterGui.ArceusXV3.MainUI.MainFrame.Tabs.Home.UserPage.UICorner
    AZY["2e"] = Instance.new("UICorner", AZY["2d"]);
    AZY["2e"]["CornerRadius"] = UDim.new(0, 15);

    -- StarterGui.ArceusXV3.MainUI.MainFrame.Tabs.Home.UserPage.ImageLabel
    AZY["2f"] = Instance.new("ImageLabel", AZY["2d"]);
    AZY["2f"]["BackgroundColor3"] = Color3.fromRGB(255, 255, 255);
    AZY["2f"]["Image"] = [[rbxassetid://12566434374]];
    AZY["2f"]["Size"] = UDim2.new(0.3031076192855835, 0, 0.8659517168998718, 0);
    AZY["2f"]["BackgroundTransparency"] = 1;
    AZY["2f"]["Position"] = UDim2.new(0.22370131313800812, 0, 0.0670241266489029, 0);

    -- StarterGui.ArceusXV3.MainUI.MainFrame.Tabs.Home.UserPage.TextLabel
    AZY["30"] = Instance.new("TextLabel", AZY["2d"]);
    AZY["30"]["TextWrapped"] = true;
    AZY["30"]["TextScaled"] = true;
    AZY["30"]["BackgroundColor3"] = Color3.fromRGB(255, 255, 255);
    AZY["30"]["FontFace"] = Font.new([[rbxasset://fonts/families/SourceSansPro.json]], Enum.FontWeight.Bold, Enum.FontStyle.Normal);
    AZY["30"]["TextSize"] = 25;
    AZY["30"]["TextColor3"] = Color3.fromRGB(255, 255, 255);
    AZY["30"]["Size"] = UDim2.new(0.20524734258651733, 0, 0.3535553812980652, 0);
    AZY["30"]["Text"] = [[Hi,]];
    AZY["30"]["BackgroundTransparency"] = 1;
    AZY["30"]["Position"] = UDim2.new(0.5262826681137085, 0, 0.14745301008224487, 0);

    -- StarterGui.ArceusXV3.MainUI.MainFrame.Tabs.Home.UserPage.TextLabel
    AZY["31"] = Instance.new("TextLabel", AZY["2d"]);
    AZY["31"]["TextWrapped"] = true;
    AZY["31"]["TextScaled"] = true;
    AZY["31"]["BackgroundColor3"] = Color3.fromRGB(255, 255, 255);
    AZY["31"]["TextXAlignment"] = Enum.TextXAlignment.Left;
    AZY["31"]["FontFace"] = Font.new([[rbxasset://fonts/families/SourceSansPro.json]], Enum.FontWeight.Bold, Enum.FontStyle.Normal);
    AZY["31"]["TextSize"] = 25;
    AZY["31"]["TextColor3"] = Color3.fromRGB(255, 255, 255);
    AZY["31"]["Size"] = UDim2.new(0.3468869626522064, 0, 0.3007456660270691, 0);
    AZY["31"]["Text"] = [[User]];
    AZY["31"]["BackgroundTransparency"] = 1;
    AZY["31"]["Position"] = UDim2.new(0.5669999122619629, 0, 0.5350000262260437, 0);

    -- StarterGui.ArceusXV3.MainUI.MainFrame.Tabs.Home.UserPage.TextLabel.UITextSizeConstraint
    AZY["32"] = Instance.new("UITextSizeConstraint", AZY["31"]);
    AZY["32"]["MaxTextSize"] = 25;

    -- StarterGui.ArceusXV3.MainUI.MainFrame.Tabs.Home.UserPage.TextLabel.LocalScript
    AZY["33"] = Instance.new("LocalScript", AZY["31"]);


    -- StarterGui.ArceusXV3.MainUI.MainFrame.Tabs.Home.KeySystemPage
    AZY["34"] = Instance.new("Frame", AZY["2c"]);
    AZY["34"]["BackgroundColor3"] = Color3.fromRGB(0, 0, 0);
    AZY["34"]["BackgroundTransparency"] = 0.550000011920929;
    AZY["34"]["Size"] = UDim2.new(0.374349445104599, 0, 0.7526744604110718, 0);
    AZY["34"]["Position"] = UDim2.new(-0.002428855048492551, 0, 0.3016669452190399, 0);
    AZY["34"]["Name"] = [[KeySystemPage]];

    -- StarterGui.ArceusXV3.MainUI.MainFrame.Tabs.Home.KeySystemPage.UICorner
    AZY["35"] = Instance.new("UICorner", AZY["34"]);
    AZY["35"]["CornerRadius"] = UDim.new(0, 15);

    -- StarterGui.ArceusXV3.MainUI.MainFrame.Tabs.Home.KeySystemPage.TextLabel
    AZY["36"] = Instance.new("TextLabel", AZY["34"]);
    AZY["36"]["TextWrapped"] = true;
    AZY["36"]["BackgroundColor3"] = Color3.fromRGB(255, 255, 255);
    AZY["36"]["FontFace"] = Font.new([[rbxasset://fonts/families/SourceSansPro.json]], Enum.FontWeight.Bold, Enum.FontStyle.Normal);
    AZY["36"]["TextSize"] = 16;
    AZY["36"]["TextColor3"] = Color3.fromRGB(255, 255, 255);
    AZY["36"]["Size"] = UDim2.new(0.8114322423934937, 0, 0.15531843900680542, 0);
    AZY["36"]["Text"] = [[Key System Status]];
    AZY["36"]["BackgroundTransparency"] = 1;
    AZY["36"]["Position"] = UDim2.new(0.05482717230916023, 0, 0.06104206293821335, 0);

    -- StarterGui.ArceusXV3.MainUI.MainFrame.Tabs.Home.KeySystemPage.TextLabel
    AZY["37"] = Instance.new("TextLabel", AZY["34"]);
    AZY["37"]["TextWrapped"] = true;
    AZY["37"]["TextScaled"] = true;
    AZY["37"]["BackgroundColor3"] = Color3.fromRGB(255, 255, 255);
    AZY["37"]["TextXAlignment"] = Enum.TextXAlignment.Left;
    AZY["37"]["FontFace"] = Font.new([[rbxasset://fonts/families/SourceSansPro.json]], Enum.FontWeight.Bold, Enum.FontStyle.Normal);
    AZY["37"]["TextSize"] = 35;
    AZY["37"]["TextColor3"] = Color3.fromRGB(0, 255, 0);
    AZY["37"]["Size"] = UDim2.new(0.30206844210624695, 0, 0.09149397909641266, 0);
    AZY["37"]["Text"] = [[Online]];
    AZY["37"]["BackgroundTransparency"] = 1;
    AZY["37"]["Position"] = UDim2.new(0.08498311042785645, 0, 0.1731228232383728, 0);

    -- StarterGui.ArceusXV3.MainUI.MainFrame.Tabs.Home.KeySystemPage.TextLabel
    AZY["38"] = Instance.new("TextLabel", AZY["34"]);
    AZY["38"]["TextWrapped"] = true;
    AZY["38"]["TextScaled"] = true;
    AZY["38"]["BackgroundColor3"] = Color3.fromRGB(255, 255, 255);
    AZY["38"]["FontFace"] = Font.new([[rbxasset://fonts/families/SourceSansPro.json]], Enum.FontWeight.Bold, Enum.FontStyle.Normal);
    AZY["38"]["TextSize"] = 35;
    AZY["38"]["TextColor3"] = Color3.fromRGB(255, 255, 255);
    AZY["38"]["Size"] = UDim2.new(0.423105388879776, 0, 0.0994054526090622, 0);
    AZY["38"]["Text"] = [[Expires In:]];
    AZY["38"]["BackgroundTransparency"] = 1;
    AZY["38"]["Position"] = UDim2.new(0.054827168583869934, 0, 0.31500908732414246, 0);

    -- StarterGui.ArceusXV3.MainUI.MainFrame.Tabs.Home.KeySystemPage.TimeLeft
    AZY["39"] = Instance.new("TextLabel", AZY["34"]);
    AZY["39"]["TextWrapped"] = true;
    AZY["39"]["TextScaled"] = true;
    AZY["39"]["BackgroundColor3"] = Color3.fromRGB(255, 255, 255);
    AZY["39"]["FontFace"] = Font.new([[rbxasset://fonts/families/SourceSansPro.json]], Enum.FontWeight.Bold, Enum.FontStyle.Normal);
    AZY["39"]["TextSize"] = 35;
    AZY["39"]["TextColor3"] = Color3.fromRGB(0, 255, 0);
    AZY["39"]["Size"] = UDim2.new(0.30206844210624695, 0, 0.0994054526090622, 0);
    AZY["39"]["Text"] = [[24h 00m]];
    AZY["39"]["Name"] = [[TimeLeft]];
    AZY["39"]["BackgroundTransparency"] = 1;
    AZY["39"]["Position"] = UDim2.new(0.49440309405326843, 0, 0.31500908732414246, 0);

    -- StarterGui.ArceusXV3.MainUI.MainFrame.Tabs.Home.KeySystemPage.TimeLeft.LocalScript
    AZY["3a"] = Instance.new("LocalScript", AZY["39"]);


    -- StarterGui.ArceusXV3.MainUI.MainFrame.Tabs.Home.KeySystemPage.Bar
    AZY["3b"] = Instance.new("Frame", AZY["34"]);
    AZY["3b"]["BackgroundColor3"] = Color3.fromRGB(0, 255, 0);
    AZY["3b"]["Size"] = UDim2.new(0.8291789293289185, 0, 0.07132068276405334, 0);
    AZY["3b"]["Position"] = UDim2.new(0.05709991604089737, 0, 0.44679027795791626, 0);
    AZY["3b"]["Name"] = [[Bar]];

    -- StarterGui.ArceusXV3.MainUI.MainFrame.Tabs.Home.KeySystemPage.Bar.UICorner
    AZY["3c"] = Instance.new("UICorner", AZY["3b"]);
    AZY["3c"]["CornerRadius"] = UDim.new(0, 4);

    -- StarterGui.ArceusXV3.MainUI.MainFrame.Tabs.Home.KeySystemPage.Bar.TextLabel
    AZY["3d"] = Instance.new("TextLabel", AZY["3b"]);
    AZY["3d"]["TextWrapped"] = true;
    AZY["3d"]["TextScaled"] = true;
    AZY["3d"]["BackgroundColor3"] = Color3.fromRGB(0, 0, 0);
    AZY["3d"]["FontFace"] = Font.new([[rbxasset://fonts/families/SourceSansPro.json]], Enum.FontWeight.Bold, Enum.FontStyle.Normal);
    AZY["3d"]["TextTransparency"] = 0.6000000238418579;
    AZY["3d"]["TextSize"] = 35;
    AZY["3d"]["TextColor3"] = Color3.fromRGB(0, 0, 0);
    AZY["3d"]["Size"] = UDim2.new(0.2189580649137497, 0, 0.9389510154724121, 0);
    AZY["3d"]["Text"] = [[100%]];
    AZY["3d"]["BackgroundTransparency"] = 1;
    AZY["3d"]["Position"] = UDim2.new(0.7810419201850891, 0, 0.061042893677949905, 0);

    -- StarterGui.ArceusXV3.MainUI.MainFrame.Tabs.Home.KeySystemPage.TextLabel
    AZY["3e"] = Instance.new("TextLabel", AZY["34"]);
    AZY["3e"]["TextWrapped"] = true;
    AZY["3e"]["BackgroundColor3"] = Color3.fromRGB(255, 255, 255);
    AZY["3e"]["FontFace"] = Font.new([[rbxasset://fonts/families/SourceSansPro.json]], Enum.FontWeight.Bold, Enum.FontStyle.Normal);
    AZY["3e"]["TextSize"] = 12;
    AZY["3e"]["TextColor3"] = Color3.fromRGB(255, 255, 255);
    AZY["3e"]["Size"] = UDim2.new(0.5709924697875977, 0, 0.11561357975006104, 0);
    AZY["3e"]["Text"] = [[Last activation:]];
    AZY["3e"]["BackgroundTransparency"] = 1;
    AZY["3e"]["Position"] = UDim2.new(0.05010330677032471, 0, 0.5460530519485474, 0);

    -- StarterGui.ArceusXV3.MainUI.MainFrame.Tabs.Home.KeySystemPage.Time
    AZY["3f"] = Instance.new("TextLabel", AZY["34"]);
    AZY["3f"]["TextWrapped"] = true;
    AZY["3f"]["BackgroundColor3"] = Color3.fromRGB(255, 255, 255);
    AZY["3f"]["TextXAlignment"] = Enum.TextXAlignment.Left;
    AZY["3f"]["FontFace"] = Font.new([[rbxasset://fonts/families/SourceSansPro.json]], Enum.FontWeight.Bold, Enum.FontStyle.Normal);
    AZY["3f"]["TextSize"] = 12;
    AZY["3f"]["TextColor3"] = Color3.fromRGB(178, 178, 178);
    AZY["3f"]["Size"] = UDim2.new(0.6227233409881592, 0, 0.09644854068756104, 0);
    AZY["3f"]["Text"] = [[Today, HH:MM AM]];
    AZY["3f"]["Name"] = [[Time]];
    AZY["3f"]["BackgroundTransparency"] = 1;
    AZY["3f"]["Position"] = UDim2.new(0.08199998736381531, 0, 0.6469999551773071, 0);

    -- StarterGui.ArceusXV3.MainUI.MainFrame.Tabs.Home.KeySystemPage.Time.LocalScript
    AZY["40"] = Instance.new("LocalScript", AZY["3f"]);


    -- StarterGui.ArceusXV3.MainUI.MainFrame.Tabs.Home.KeySystemPage.Restore
    AZY["41"] = Instance.new("TextButton", AZY["34"]);
    AZY["41"]["TextWrapped"] = true;
    AZY["41"]["BackgroundColor3"] = Color3.fromRGB(255, 0, 0);
    AZY["41"]["TextSize"] = 15;
    AZY["41"]["FontFace"] = Font.new([[rbxasset://fonts/families/SourceSansPro.json]], Enum.FontWeight.Bold, Enum.FontStyle.Normal);
    AZY["41"]["TextColor3"] = Color3.fromRGB(255, 255, 255);
    AZY["41"]["Size"] = UDim2.new(0.7855679988861084, 0, 0.17807699739933014, 0);
    AZY["41"]["Name"] = [[Restore]];
    AZY["41"]["Text"] = [[Restore]];
    AZY["41"]["Position"] = UDim2.new(0.10590747743844986, 0, 0.7775270342826843, 0);

    -- StarterGui.ArceusXV3.MainUI.MainFrame.Tabs.Home.KeySystemPage.Restore.UICorner
    AZY["42"] = Instance.new("UICorner", AZY["41"]);


    -- StarterGui.ArceusXV3.MainUI.MainFrame.Tabs.Home.KeySystemPage.Restore.LocalScript
    AZY["43"] = Instance.new("LocalScript", AZY["41"]);


    -- StarterGui.ArceusXV3.MainUI.MainFrame.Tabs.Home.HaxPage
    AZY["44"] = Instance.new("Frame", AZY["2c"]);
    AZY["44"]["BackgroundColor3"] = Color3.fromRGB(0, 0, 0);
    AZY["44"]["BackgroundTransparency"] = 0.550000011920929;
    AZY["44"]["Size"] = UDim2.new(0.6116291880607605, 0, 1.0292569398880005, 0);
    AZY["44"]["Position"] = UDim2.new(0.3883708119392395, 0, 0.025084195658564568, 0);
    AZY["44"]["Name"] = [[HaxPage]];

    -- StarterGui.ArceusXV3.MainUI.MainFrame.Tabs.Home.HaxPage.UICorner
    AZY["45"] = Instance.new("UICorner", AZY["44"]);
    AZY["45"]["CornerRadius"] = UDim.new(0, 15);

    -- StarterGui.ArceusXV3.MainUI.MainFrame.Tabs.Home.HaxPage.TextLabel
    AZY["46"] = Instance.new("TextLabel", AZY["44"]);
    AZY["46"]["TextWrapped"] = true;
    AZY["46"]["BackgroundColor3"] = Color3.fromRGB(255, 255, 255);
    AZY["46"]["FontFace"] = Font.new([[rbxasset://fonts/families/SourceSansPro.json]], Enum.FontWeight.Bold, Enum.FontStyle.Normal);
    AZY["46"]["TextSize"] = 18;
    AZY["46"]["TextColor3"] = Color3.fromRGB(255, 255, 255);
    AZY["46"]["Size"] = UDim2.new(0.3717169165611267, 0, 0.10439325869083405, 0);
    AZY["46"]["Text"] = [[Quick Hacks]];
    AZY["46"]["BackgroundTransparency"] = 1;
    AZY["46"]["Position"] = UDim2.new(0.01899999938905239, 0, 0.03400000184774399, 0);

    -- StarterGui.ArceusXV3.MainUI.MainFrame.Tabs.Home.HaxPage.Grav
    AZY["47"] = Instance.new("BoolValue", AZY["44"]);
    AZY["47"]["Name"] = [[Grav]];

    -- StarterGui.ArceusXV3.MainUI.MainFrame.Tabs.Home.HaxPage.Scripts
    AZY["48"] = Instance.new("Folder", AZY["44"]);
    AZY["48"]["Name"] = [[Scripts]];

    -- StarterGui.ArceusXV3.MainUI.MainFrame.Tabs.Home.HaxPage.Scripts.Aimbot
    AZY["49"] = Instance.new("TextButton", AZY["48"]);
    AZY["49"]["TextWrapped"] = true;
    AZY["49"]["BackgroundColor3"] = Color3.fromRGB(255, 0, 0);
    AZY["49"]["TextSize"] = 11;
    AZY["49"]["FontFace"] = Font.new([[rbxasset://fonts/families/SourceSansPro.json]], Enum.FontWeight.Bold, Enum.FontStyle.Normal);
    AZY["49"]["TextColor3"] = Color3.fromRGB(255, 255, 255);
    AZY["49"]["Size"] = UDim2.new(0.2588447332382202, 0, 0.0958060473203659, 0);
    AZY["49"]["Name"] = [[Aimbot]];
    AZY["49"]["Text"] = [[AimBot]];
    AZY["49"]["Position"] = UDim2.new(0.04600000008940697, 0, 0.5989999771118164, 0);

    -- StarterGui.ArceusXV3.MainUI.MainFrame.Tabs.Home.HaxPage.Scripts.Aimbot.UICorner
    AZY["4a"] = Instance.new("UICorner", AZY["49"]);
    AZY["4a"]["CornerRadius"] = UDim.new(0, 5);

    -- StarterGui.ArceusXV3.MainUI.MainFrame.Tabs.Home.HaxPage.Scripts.Aimbot.LocalScript
    AZY["4b"] = Instance.new("LocalScript", AZY["49"]);


    -- StarterGui.ArceusXV3.MainUI.MainFrame.Tabs.Home.HaxPage.Scripts.Btools
    AZY["4c"] = Instance.new("TextButton", AZY["48"]);
    AZY["4c"]["TextWrapped"] = true;
    AZY["4c"]["BackgroundColor3"] = Color3.fromRGB(255, 0, 0);
    AZY["4c"]["TextSize"] = 11;
    AZY["4c"]["FontFace"] = Font.new([[rbxasset://fonts/families/SourceSansPro.json]], Enum.FontWeight.Bold, Enum.FontStyle.Normal);
    AZY["4c"]["TextColor3"] = Color3.fromRGB(255, 255, 255);
    AZY["4c"]["Size"] = UDim2.new(0.2588447332382202, 0, 0.0958060473203659, 0);
    AZY["4c"]["Name"] = [[Btools]];
    AZY["4c"]["Text"] = [[Btools]];
    AZY["4c"]["Position"] = UDim2.new(0.04600000008940697, 0, 0.4830000102519989, 0);

    -- StarterGui.ArceusXV3.MainUI.MainFrame.Tabs.Home.HaxPage.Scripts.Btools.UICorner
    AZY["4d"] = Instance.new("UICorner", AZY["4c"]);
    AZY["4d"]["CornerRadius"] = UDim.new(0, 5);

    -- StarterGui.ArceusXV3.MainUI.MainFrame.Tabs.Home.HaxPage.Scripts.Btools.LocalScript
    AZY["4e"] = Instance.new("LocalScript", AZY["4c"]);


    -- StarterGui.ArceusXV3.MainUI.MainFrame.Tabs.Home.HaxPage.Scripts.Dex
    AZY["4f"] = Instance.new("TextButton", AZY["48"]);
    AZY["4f"]["TextWrapped"] = true;
    AZY["4f"]["BackgroundColor3"] = Color3.fromRGB(255, 0, 0);
    AZY["4f"]["TextSize"] = 11;
    AZY["4f"]["FontFace"] = Font.new([[rbxasset://fonts/families/SourceSansPro.json]], Enum.FontWeight.Bold, Enum.FontStyle.Normal);
    AZY["4f"]["TextColor3"] = Color3.fromRGB(255, 255, 255);
    AZY["4f"]["Size"] = UDim2.new(0.2588447332382202, 0, 0.0958060473203659, 0);
    AZY["4f"]["Name"] = [[Dex]];
    AZY["4f"]["Text"] = [[DEX Explorer]];
    AZY["4f"]["Position"] = UDim2.new(0.04600000008940697, 0, 0.2564218044281006, 0);

    -- StarterGui.ArceusXV3.MainUI.MainFrame.Tabs.Home.HaxPage.Scripts.Dex.UICorner
    AZY["50"] = Instance.new("UICorner", AZY["4f"]);
    AZY["50"]["CornerRadius"] = UDim.new(0, 5);

    -- StarterGui.ArceusXV3.MainUI.MainFrame.Tabs.Home.HaxPage.Scripts.Dex.LocalScript
    AZY["51"] = Instance.new("LocalScript", AZY["4f"]);


    -- StarterGui.ArceusXV3.MainUI.MainFrame.Tabs.Home.HaxPage.Scripts.FatesESP
    AZY["52"] = Instance.new("TextButton", AZY["48"]);
    AZY["52"]["TextWrapped"] = true;
    AZY["52"]["BackgroundColor3"] = Color3.fromRGB(255, 0, 0);
    AZY["52"]["TextSize"] = 11;
    AZY["52"]["FontFace"] = Font.new([[rbxasset://fonts/families/SourceSansPro.json]], Enum.FontWeight.Bold, Enum.FontStyle.Normal);
    AZY["52"]["TextColor3"] = Color3.fromRGB(255, 255, 255);
    AZY["52"]["Size"] = UDim2.new(0.2588447332382202, 0, 0.0958060473203659, 0);
    AZY["52"]["Name"] = [[FatesESP]];
    AZY["52"]["Text"] = [[Fates ESP]];
    AZY["52"]["Position"] = UDim2.new(0.04600000008940697, 0, 0.3709999918937683, 0);

    -- StarterGui.ArceusXV3.MainUI.MainFrame.Tabs.Home.HaxPage.Scripts.FatesESP.UICorner
    AZY["53"] = Instance.new("UICorner", AZY["52"]);
    AZY["53"]["CornerRadius"] = UDim.new(0, 5);

    -- StarterGui.ArceusXV3.MainUI.MainFrame.Tabs.Home.HaxPage.Scripts.FatesESP.LocalScript
    AZY["54"] = Instance.new("LocalScript", AZY["52"]);


    -- StarterGui.ArceusXV3.MainUI.MainFrame.Tabs.Home.HaxPage.Scripts.Fly
    AZY["55"] = Instance.new("TextButton", AZY["48"]);
    AZY["55"]["TextWrapped"] = true;
    AZY["55"]["BackgroundColor3"] = Color3.fromRGB(255, 0, 0);
    AZY["55"]["TextSize"] = 11;
    AZY["55"]["FontFace"] = Font.new([[rbxasset://fonts/families/SourceSansPro.json]], Enum.FontWeight.Bold, Enum.FontStyle.Normal);
    AZY["55"]["TextColor3"] = Color3.fromRGB(255, 255, 255);
    AZY["55"]["Size"] = UDim2.new(0.2588447332382202, 0, 0.0958060473203659, 0);
    AZY["55"]["Name"] = [[Fly]];
    AZY["55"]["Text"] = [[Fly]];
    AZY["55"]["Position"] = UDim2.new(0.04600000008940697, 0, 0.7070000171661377, 0);

    -- StarterGui.ArceusXV3.MainUI.MainFrame.Tabs.Home.HaxPage.Scripts.Fly.UICorner
    AZY["56"] = Instance.new("UICorner", AZY["55"]);
    AZY["56"]["CornerRadius"] = UDim.new(0, 5);

    -- StarterGui.ArceusXV3.MainUI.MainFrame.Tabs.Home.HaxPage.Scripts.Fly.LocalScript
    AZY["57"] = Instance.new("LocalScript", AZY["55"]);


    -- StarterGui.ArceusXV3.MainUI.MainFrame.Tabs.Home.HaxPage.Scripts.IY
    AZY["58"] = Instance.new("TextButton", AZY["48"]);
    AZY["58"]["TextWrapped"] = true;
    AZY["58"]["BackgroundColor3"] = Color3.fromRGB(255, 0, 0);
    AZY["58"]["TextSize"] = 11;
    AZY["58"]["FontFace"] = Font.new([[rbxasset://fonts/families/SourceSansPro.json]], Enum.FontWeight.Bold, Enum.FontStyle.Normal);
    AZY["58"]["TextColor3"] = Color3.fromRGB(255, 255, 255);
    AZY["58"]["Size"] = UDim2.new(0.2588447332382202, 0, 0.0958060473203659, 0);
    AZY["58"]["Name"] = [[IY]];
    AZY["58"]["Text"] = [[Infinite Yield]];
    AZY["58"]["Position"] = UDim2.new(0.04595530033111572, 0, 0.13954126834869385, 0);

    -- StarterGui.ArceusXV3.MainUI.MainFrame.Tabs.Home.HaxPage.Scripts.IY.UICorner
    AZY["59"] = Instance.new("UICorner", AZY["58"]);
    AZY["59"]["CornerRadius"] = UDim.new(0, 5);

    -- StarterGui.ArceusXV3.MainUI.MainFrame.Tabs.Home.HaxPage.Scripts.IY.LocalScript
    AZY["5a"] = Instance.new("LocalScript", AZY["58"]);


    -- StarterGui.ArceusXV3.MainUI.MainFrame.Tabs.Home.HaxPage.Scripts.PwnHub
    AZY["5b"] = Instance.new("TextButton", AZY["48"]);
    AZY["5b"]["TextWrapped"] = true;
    AZY["5b"]["BackgroundColor3"] = Color3.fromRGB(255, 0, 0);
    AZY["5b"]["TextSize"] = 11;
    AZY["5b"]["FontFace"] = Font.new([[rbxasset://fonts/families/SourceSansPro.json]], Enum.FontWeight.Bold, Enum.FontStyle.Normal);
    AZY["5b"]["TextColor3"] = Color3.fromRGB(255, 255, 255);
    AZY["5b"]["Size"] = UDim2.new(0.2588447332382202, 0, 0.0958060473203659, 0);
    AZY["5b"]["Name"] = [[PwnHub]];
    AZY["5b"]["Text"] = [[Pwner Hub]];
    AZY["5b"]["Position"] = UDim2.new(0.04600000008940697, 0, 0.8209999799728394, 0);

    -- StarterGui.ArceusXV3.MainUI.MainFrame.Tabs.Home.HaxPage.Scripts.PwnHub.UICorner
    AZY["5c"] = Instance.new("UICorner", AZY["5b"]);
    AZY["5c"]["CornerRadius"] = UDim.new(0, 5);

    -- StarterGui.ArceusXV3.MainUI.MainFrame.Tabs.Home.HaxPage.Scripts.PwnHub.LocalScript
    AZY["5d"] = Instance.new("LocalScript", AZY["5b"]);


    -- StarterGui.ArceusXV3.MainUI.MainFrame.Tabs.Home.HaxPage.TextGrav
    AZY["5e"] = Instance.new("TextLabel", AZY["44"]);
    AZY["5e"]["BackgroundColor3"] = Color3.fromRGB(255, 255, 255);
    AZY["5e"]["FontFace"] = Font.new([[rbxasset://fonts/families/SourceSansPro.json]], Enum.FontWeight.Bold, Enum.FontStyle.Normal);
    AZY["5e"]["TextSize"] = 12;
    AZY["5e"]["TextColor3"] = Color3.fromRGB(255, 255, 255);
    AZY["5e"]["Size"] = UDim2.new(0, 50, 0, 11);
    AZY["5e"]["Text"] = [[Gravity]];
    AZY["5e"]["Name"] = [[TextGrav]];
    AZY["5e"]["BackgroundTransparency"] = 1;
    AZY["5e"]["Position"] = UDim2.new(0.3269999921321869, 0, 0.8930000066757202, 0);

    -- StarterGui.ArceusXV3.MainUI.MainFrame.Tabs.Home.HaxPage.TextWs
    AZY["5f"] = Instance.new("TextLabel", AZY["44"]);
    AZY["5f"]["BackgroundColor3"] = Color3.fromRGB(255, 255, 255);
    AZY["5f"]["FontFace"] = Font.new([[rbxasset://fonts/families/SourceSansPro.json]], Enum.FontWeight.Bold, Enum.FontStyle.Normal);
    AZY["5f"]["TextSize"] = 12;
    AZY["5f"]["TextColor3"] = Color3.fromRGB(255, 255, 255);
    AZY["5f"]["Size"] = UDim2.new(0, 50, 0, 11);
    AZY["5f"]["Text"] = [[Speed]];
    AZY["5f"]["Name"] = [[TextWs]];
    AZY["5f"]["BackgroundTransparency"] = 1;
    AZY["5f"]["Position"] = UDim2.new(0.5411151647567749, 0, 0.8930000066757202, 0);

    -- StarterGui.ArceusXV3.MainUI.MainFrame.Tabs.Home.HaxPage.TextJp
    AZY["60"] = Instance.new("TextLabel", AZY["44"]);
    AZY["60"]["BackgroundColor3"] = Color3.fromRGB(255, 255, 255);
    AZY["60"]["FontFace"] = Font.new([[rbxasset://fonts/families/SourceSansPro.json]], Enum.FontWeight.Bold, Enum.FontStyle.Normal);
    AZY["60"]["TextSize"] = 12;
    AZY["60"]["TextColor3"] = Color3.fromRGB(255, 255, 255);
    AZY["60"]["Size"] = UDim2.new(0, 50, 0, 11);
    AZY["60"]["Text"] = [[Jump]];
    AZY["60"]["Name"] = [[TextJp]];
    AZY["60"]["BackgroundTransparency"] = 1;
    AZY["60"]["Position"] = UDim2.new(0.7466657161712646, 0, 0.8930000066757202, 0);

    -- StarterGui.ArceusXV3.MainUI.MainFrame.Tabs.Home.HaxPage.Ws
    AZY["61"] = Instance.new("BoolValue", AZY["44"]);
    AZY["61"]["Name"] = [[Ws]];

    -- StarterGui.ArceusXV3.MainUI.MainFrame.Tabs.Home.HaxPage.Jp
    AZY["62"] = Instance.new("BoolValue", AZY["44"]);
    AZY["62"]["Name"] = [[Jp]];

    -- StarterGui.ArceusXV3.MainUI.MainFrame.Tabs.Home.HaxPage.ToggleGrav
    AZY["63"] = Instance.new("TextButton", AZY["44"]);
    AZY["63"]["BackgroundColor3"] = Color3.fromRGB(146, 0, 0);
    AZY["63"]["TextSize"] = 14;
    AZY["63"]["FontFace"] = Font.new([[rbxasset://fonts/families/SourceSansPro.json]], Enum.FontWeight.Regular, Enum.FontStyle.Normal);
    AZY["63"]["TextColor3"] = Color3.fromRGB(0, 0, 0);
    AZY["63"]["Size"] = UDim2.new(0, 15, 0, 15);
    AZY["63"]["Name"] = [[ToggleGrav]];
    AZY["63"]["Text"] = [[]];
    AZY["63"]["Position"] = UDim2.new(0.40253645181655884, 0, 0.801304280757904, 0);

    -- StarterGui.ArceusXV3.MainUI.MainFrame.Tabs.Home.HaxPage.ToggleGrav.UICorner
    AZY["64"] = Instance.new("UICorner", AZY["63"]);
    AZY["64"]["CornerRadius"] = UDim.new(100, 100);

    -- StarterGui.ArceusXV3.MainUI.MainFrame.Tabs.Home.HaxPage.ToggleGrav.LocalScript
    AZY["65"] = Instance.new("LocalScript", AZY["63"]);


    -- StarterGui.ArceusXV3.MainUI.MainFrame.Tabs.Home.HaxPage.ToggleWs
    AZY["66"] = Instance.new("TextButton", AZY["44"]);
    AZY["66"]["BackgroundColor3"] = Color3.fromRGB(146, 0, 0);
    AZY["66"]["TextSize"] = 14;
    AZY["66"]["FontFace"] = Font.new([[rbxasset://fonts/families/SourceSansPro.json]], Enum.FontWeight.Regular, Enum.FontStyle.Normal);
    AZY["66"]["TextColor3"] = Color3.fromRGB(0, 0, 0);
    AZY["66"]["Size"] = UDim2.new(0, 15, 0, 15);
    AZY["66"]["Name"] = [[ToggleWs]];
    AZY["66"]["Text"] = [[]];
    AZY["66"]["Position"] = UDim2.new(0.6166515946388245, 0, 0.801304280757904, 0);

    -- StarterGui.ArceusXV3.MainUI.MainFrame.Tabs.Home.HaxPage.ToggleWs.UICorner
    AZY["67"] = Instance.new("UICorner", AZY["66"]);
    AZY["67"]["CornerRadius"] = UDim.new(100, 100);

    -- StarterGui.ArceusXV3.MainUI.MainFrame.Tabs.Home.HaxPage.ToggleWs.LocalScript
    AZY["68"] = Instance.new("LocalScript", AZY["66"]);


    -- StarterGui.ArceusXV3.MainUI.MainFrame.Tabs.Home.HaxPage.ToggleJp
    AZY["69"] = Instance.new("TextButton", AZY["44"]);
    AZY["69"]["BackgroundColor3"] = Color3.fromRGB(146, 0, 0);
    AZY["69"]["TextSize"] = 14;
    AZY["69"]["FontFace"] = Font.new([[rbxasset://fonts/families/SourceSansPro.json]], Enum.FontWeight.Regular, Enum.FontStyle.Normal);
    AZY["69"]["TextColor3"] = Color3.fromRGB(0, 0, 0);
    AZY["69"]["Size"] = UDim2.new(0, 15, 0, 15);
    AZY["69"]["Name"] = [[ToggleJp]];
    AZY["69"]["Text"] = [[]];
    AZY["69"]["Position"] = UDim2.new(0.8222021460533142, 0, 0.801304280757904, 0);

    -- StarterGui.ArceusXV3.MainUI.MainFrame.Tabs.Home.HaxPage.ToggleJp.UICorner
    AZY["6a"] = Instance.new("UICorner", AZY["69"]);
    AZY["6a"]["CornerRadius"] = UDim.new(100, 100);

    -- StarterGui.ArceusXV3.MainUI.MainFrame.Tabs.Home.HaxPage.ToggleJp.LocalScript
    AZY["6b"] = Instance.new("LocalScript", AZY["69"]);


    -- StarterGui.ArceusXV3.MainUI.MainFrame.Tabs.Home.HaxPage.JpS
    AZY["6c"] = Instance.new("ImageButton", AZY["44"]);
    AZY["6c"]["Active"] = false;
    AZY["6c"]["BorderSizePixel"] = 0;
    AZY["6c"]["SliceCenter"] = Rect.new(100, 100, 100, 100);
    AZY["6c"]["ScaleType"] = Enum.ScaleType.Slice;
    AZY["6c"]["SliceScale"] = 0.11999999731779099;
    AZY["6c"]["ImageTransparency"] = 1;
    AZY["6c"]["BackgroundColor3"] = Color3.fromRGB(22, 22, 22);
    AZY["6c"]["ImageColor3"] = Color3.fromRGB(32, 32, 32);
    AZY["6c"]["Selectable"] = false;
    AZY["6c"]["AnchorPoint"] = Vector2.new(0.5, 0.5);
    AZY["6c"]["Image"] = [[rbxassetid://3570695787]];
    AZY["6c"]["Size"] = UDim2.new(0, 119, 0, 31);
    AZY["6c"]["Name"] = [[JpS]];
    AZY["6c"]["Rotation"] = -90;
    AZY["6c"]["Position"] = UDim2.new(0.8600000143051147, 0, 0.4399999976158142, 0);
    AZY["6c"]["BackgroundTransparency"] = 1;

    -- StarterGui.ArceusXV3.MainUI.MainFrame.Tabs.Home.HaxPage.JpS.SliderButton
    AZY["6d"] = Instance.new("ImageLabel", AZY["6c"]);
    AZY["6d"]["SliceCenter"] = Rect.new(100, 100, 100, 100);
    AZY["6d"]["ScaleType"] = Enum.ScaleType.Slice;
    AZY["6d"]["BackgroundColor3"] = Color3.fromRGB(71, 71, 71);
    AZY["6d"]["ImageColor3"] = Color3.fromRGB(146, 0, 0);
    AZY["6d"]["SliceScale"] = 0.11999999731779099;
    AZY["6d"]["Selectable"] = true;
    AZY["6d"]["Image"] = [[rbxassetid://3570695787]];
    AZY["6d"]["Size"] = UDim2.new(0, 25, 1, 0);
    AZY["6d"]["Active"] = true;
    AZY["6d"]["Name"] = [[SliderButton]];
    AZY["6d"]["BackgroundTransparency"] = 1;

    -- StarterGui.ArceusXV3.MainUI.MainFrame.Tabs.Home.HaxPage.JpS.SliderButton.LocalScript
    AZY["6e"] = Instance.new("LocalScript", AZY["6d"]);


    -- StarterGui.ArceusXV3.MainUI.MainFrame.Tabs.Home.HaxPage.JpS.Border
    AZY["6f"] = Instance.new("ImageLabel", AZY["6c"]);
    AZY["6f"]["ZIndex"] = -1;
    AZY["6f"]["SliceCenter"] = Rect.new(100, 100, 100, 100);
    AZY["6f"]["ScaleType"] = Enum.ScaleType.Slice;
    AZY["6f"]["BackgroundColor3"] = Color3.fromRGB(62, 62, 62);
    AZY["6f"]["ImageColor3"] = Color3.fromRGB(71, 71, 71);
    AZY["6f"]["SliceScale"] = 0.23999999463558197;
    AZY["6f"]["ImageTransparency"] = 1;
    AZY["6f"]["AnchorPoint"] = Vector2.new(0.5, 0.5);
    AZY["6f"]["Image"] = [[rbxassetid://3570695787]];
    AZY["6f"]["Size"] = UDim2.new(1, 12, 1, 12);
    AZY["6f"]["Name"] = [[Border]];
    AZY["6f"]["BackgroundTransparency"] = 0.6000000238418579;
    AZY["6f"]["Position"] = UDim2.new(0.5, 0, 0.5, 0);

    -- StarterGui.ArceusXV3.MainUI.MainFrame.Tabs.Home.HaxPage.JpS.Border.UICorner
    AZY["70"] = Instance.new("UICorner", AZY["6f"]);
    AZY["70"]["CornerRadius"] = UDim.new(0, 12);

    -- StarterGui.ArceusXV3.MainUI.MainFrame.Tabs.Home.HaxPage.JpS.StripedPattern
    AZY["71"] = Instance.new("ImageLabel", AZY["6c"]);
    AZY["71"]["BorderSizePixel"] = 0;
    AZY["71"]["ScaleType"] = Enum.ScaleType.Tile;
    AZY["71"]["BackgroundColor3"] = Color3.fromRGB(255, 255, 255);
    AZY["71"]["ImageColor3"] = Color3.fromRGB(32, 32, 32);
    AZY["71"]["ImageTransparency"] = 1;
    AZY["71"]["AnchorPoint"] = Vector2.new(0.5, 0);
    AZY["71"]["Image"] = [[rbxassetid://4925116997]];
    AZY["71"]["TileSize"] = UDim2.new(0, 25, 1, 0);
    AZY["71"]["Size"] = UDim2.new(1, -25, 1, 0);
    AZY["71"]["Name"] = [[StripedPattern]];
    AZY["71"]["BackgroundTransparency"] = 1;
    AZY["71"]["Position"] = UDim2.new(0.5, 0, 0, 0);

    -- StarterGui.ArceusXV3.MainUI.MainFrame.Tabs.Home.HaxPage.JpS.StripedPattern.UIGradient
    AZY["72"] = Instance.new("UIGradient", AZY["71"]);
    AZY["72"]["Rotation"] = 90;
    AZY["72"]["Color"] = ColorSequence.new{ColorSequenceKeypoint.new(0.000, Color3.fromRGB(255, 255, 255)),ColorSequenceKeypoint.new(1.000, Color3.fromRGB(0, 0, 0))};

    -- StarterGui.ArceusXV3.MainUI.MainFrame.Tabs.Home.HaxPage.JpS.ImageLabel
    AZY["73"] = Instance.new("ImageLabel", AZY["6c"]);
    AZY["73"]["BackgroundColor3"] = Color3.fromRGB(255, 255, 255);
    AZY["73"]["Image"] = [[rbxassetid://12582573514]];
    AZY["73"]["Size"] = UDim2.new(0, 35, 0, 35);
    AZY["73"]["Rotation"] = 90;
    AZY["73"]["BackgroundTransparency"] = 1;
    AZY["73"]["Position"] = UDim2.new(-0.017000000923871994, 0, -0.10000000149011612, 0);

    -- StarterGui.ArceusXV3.MainUI.MainFrame.Tabs.Home.HaxPage.JpS.TextLabel
    AZY["74"] = Instance.new("TextBox", AZY["6c"]);
    AZY["74"]["ZIndex"] = 2;
    AZY["74"]["TextSize"] = 13;
    AZY["74"]["BackgroundColor3"] = Color3.fromRGB(255, 255, 255);
    AZY["74"]["TextColor3"] = Color3.fromRGB(255, 255, 255);
    AZY["74"]["FontFace"] = Font.new([[rbxasset://fonts/families/SourceSansPro.json]], Enum.FontWeight.Bold, Enum.FontStyle.Normal);
    AZY["74"]["AnchorPoint"] = Vector2.new(1, 0);
    AZY["74"]["BackgroundTransparency"] = 1;
    AZY["74"]["Size"] = UDim2.new(0, 50, 1, 0);
    AZY["74"]["Text"] = [[0%]];
    AZY["74"]["Position"] = UDim2.new(0, 137, 0, 0);
    AZY["74"]["Rotation"] = 90;
    AZY["74"]["Name"] = [[TextLabel]];

    -- StarterGui.ArceusXV3.MainUI.MainFrame.Tabs.Home.HaxPage.WsS
    AZY["75"] = Instance.new("ImageButton", AZY["44"]);
    AZY["75"]["Active"] = false;
    AZY["75"]["BorderSizePixel"] = 0;
    AZY["75"]["SliceCenter"] = Rect.new(100, 100, 100, 100);
    AZY["75"]["ScaleType"] = Enum.ScaleType.Slice;
    AZY["75"]["SliceScale"] = 0.11999999731779099;
    AZY["75"]["ImageTransparency"] = 1;
    AZY["75"]["BackgroundColor3"] = Color3.fromRGB(22, 22, 22);
    AZY["75"]["ImageColor3"] = Color3.fromRGB(32, 32, 32);
    AZY["75"]["Selectable"] = false;
    AZY["75"]["AnchorPoint"] = Vector2.new(0.5, 0.5);
    AZY["75"]["Image"] = [[rbxassetid://3570695787]];
    AZY["75"]["Size"] = UDim2.new(0, 119, 0, 31);
    AZY["75"]["Name"] = [[WsS]];
    AZY["75"]["Rotation"] = -90;
    AZY["75"]["Position"] = UDim2.new(0.6499999761581421, 0, 0.4399999976158142, 0);
    AZY["75"]["BackgroundTransparency"] = 1;

    -- StarterGui.ArceusXV3.MainUI.MainFrame.Tabs.Home.HaxPage.WsS.SliderButton
    AZY["76"] = Instance.new("ImageLabel", AZY["75"]);
    AZY["76"]["SliceCenter"] = Rect.new(100, 100, 100, 100);
    AZY["76"]["ScaleType"] = Enum.ScaleType.Slice;
    AZY["76"]["BackgroundColor3"] = Color3.fromRGB(71, 71, 71);
    AZY["76"]["ImageColor3"] = Color3.fromRGB(146, 0, 0);
    AZY["76"]["SliceScale"] = 0.11999999731779099;
    AZY["76"]["Selectable"] = true;
    AZY["76"]["Image"] = [[rbxassetid://3570695787]];
    AZY["76"]["Size"] = UDim2.new(0, 25, 1, 0);
    AZY["76"]["Active"] = true;
    AZY["76"]["Name"] = [[SliderButton]];
    AZY["76"]["BackgroundTransparency"] = 1;

    -- StarterGui.ArceusXV3.MainUI.MainFrame.Tabs.Home.HaxPage.WsS.SliderButton.LocalScript
    AZY["77"] = Instance.new("LocalScript", AZY["76"]);


    -- StarterGui.ArceusXV3.MainUI.MainFrame.Tabs.Home.HaxPage.WsS.Border
    AZY["78"] = Instance.new("ImageLabel", AZY["75"]);
    AZY["78"]["ZIndex"] = -1;
    AZY["78"]["SliceCenter"] = Rect.new(100, 100, 100, 100);
    AZY["78"]["ScaleType"] = Enum.ScaleType.Slice;
    AZY["78"]["BackgroundColor3"] = Color3.fromRGB(62, 62, 62);
    AZY["78"]["ImageColor3"] = Color3.fromRGB(71, 71, 71);
    AZY["78"]["SliceScale"] = 0.23999999463558197;
    AZY["78"]["ImageTransparency"] = 1;
    AZY["78"]["AnchorPoint"] = Vector2.new(0.5, 0.5);
    AZY["78"]["Image"] = [[rbxassetid://3570695787]];
    AZY["78"]["Size"] = UDim2.new(1, 12, 1, 12);
    AZY["78"]["Name"] = [[Border]];
    AZY["78"]["BackgroundTransparency"] = 0.6000000238418579;
    AZY["78"]["Position"] = UDim2.new(0.5, 0, 0.5, 0);

    -- StarterGui.ArceusXV3.MainUI.MainFrame.Tabs.Home.HaxPage.WsS.Border.UICorner
    AZY["79"] = Instance.new("UICorner", AZY["78"]);
    AZY["79"]["CornerRadius"] = UDim.new(0, 12);

    -- StarterGui.ArceusXV3.MainUI.MainFrame.Tabs.Home.HaxPage.WsS.StripedPattern
    AZY["7a"] = Instance.new("ImageLabel", AZY["75"]);
    AZY["7a"]["BorderSizePixel"] = 0;
    AZY["7a"]["ScaleType"] = Enum.ScaleType.Tile;
    AZY["7a"]["BackgroundColor3"] = Color3.fromRGB(255, 255, 255);
    AZY["7a"]["ImageColor3"] = Color3.fromRGB(32, 32, 32);
    AZY["7a"]["ImageTransparency"] = 1;
    AZY["7a"]["AnchorPoint"] = Vector2.new(0.5, 0);
    AZY["7a"]["Image"] = [[rbxassetid://4925116997]];
    AZY["7a"]["TileSize"] = UDim2.new(0, 25, 1, 0);
    AZY["7a"]["Size"] = UDim2.new(1, -25, 1, 0);
    AZY["7a"]["Name"] = [[StripedPattern]];
    AZY["7a"]["BackgroundTransparency"] = 1;
    AZY["7a"]["Position"] = UDim2.new(0.5, 0, 0, 0);

    -- StarterGui.ArceusXV3.MainUI.MainFrame.Tabs.Home.HaxPage.WsS.StripedPattern.UIGradient
    AZY["7b"] = Instance.new("UIGradient", AZY["7a"]);
    AZY["7b"]["Rotation"] = 90;
    AZY["7b"]["Color"] = ColorSequence.new{ColorSequenceKeypoint.new(0.000, Color3.fromRGB(255, 255, 255)),ColorSequenceKeypoint.new(1.000, Color3.fromRGB(0, 0, 0))};

    -- StarterGui.ArceusXV3.MainUI.MainFrame.Tabs.Home.HaxPage.WsS.ImageLabel
    AZY["7c"] = Instance.new("ImageLabel", AZY["75"]);
    AZY["7c"]["BackgroundColor3"] = Color3.fromRGB(255, 255, 255);
    AZY["7c"]["Image"] = [[rbxassetid://12572149271]];
    AZY["7c"]["Size"] = UDim2.new(0, 35, 0, 35);
    AZY["7c"]["Rotation"] = 90;
    AZY["7c"]["BackgroundTransparency"] = 1;
    AZY["7c"]["Position"] = UDim2.new(-0.017000000923871994, 0, -0.10000000149011612, 0);

    -- StarterGui.ArceusXV3.MainUI.MainFrame.Tabs.Home.HaxPage.WsS.TextLabel
    AZY["7d"] = Instance.new("TextBox", AZY["75"]);
    AZY["7d"]["ZIndex"] = 2;
    AZY["7d"]["TextSize"] = 13;
    AZY["7d"]["BackgroundColor3"] = Color3.fromRGB(255, 255, 255);
    AZY["7d"]["TextColor3"] = Color3.fromRGB(255, 255, 255);
    AZY["7d"]["FontFace"] = Font.new([[rbxasset://fonts/families/SourceSansPro.json]], Enum.FontWeight.Bold, Enum.FontStyle.Normal);
    AZY["7d"]["AnchorPoint"] = Vector2.new(1, 0);
    AZY["7d"]["BackgroundTransparency"] = 1;
    AZY["7d"]["Size"] = UDim2.new(0, 50, 1, 0);
    AZY["7d"]["Text"] = [[0%]];
    AZY["7d"]["Position"] = UDim2.new(0, 137, 0, 0);
    AZY["7d"]["Rotation"] = 90;
    AZY["7d"]["Name"] = [[TextLabel]];

    -- StarterGui.ArceusXV3.MainUI.MainFrame.Tabs.Home.HaxPage.GravS
    AZY["7e"] = Instance.new("ImageButton", AZY["44"]);
    AZY["7e"]["Active"] = false;
    AZY["7e"]["BorderSizePixel"] = 0;
    AZY["7e"]["SliceCenter"] = Rect.new(100, 100, 100, 100);
    AZY["7e"]["ScaleType"] = Enum.ScaleType.Slice;
    AZY["7e"]["SliceScale"] = 0.11999999731779099;
    AZY["7e"]["ImageTransparency"] = 1;
    AZY["7e"]["BackgroundColor3"] = Color3.fromRGB(22, 22, 22);
    AZY["7e"]["ImageColor3"] = Color3.fromRGB(32, 32, 32);
    AZY["7e"]["Selectable"] = false;
    AZY["7e"]["AnchorPoint"] = Vector2.new(0.5, 0.5);
    AZY["7e"]["Image"] = [[rbxassetid://3570695787]];
    AZY["7e"]["Size"] = UDim2.new(0, 119, 0, 31);
    AZY["7e"]["Name"] = [[GravS]];
    AZY["7e"]["Rotation"] = -90;
    AZY["7e"]["Position"] = UDim2.new(0.4359999895095825, 0, 0.4399999976158142, 0);
    AZY["7e"]["BackgroundTransparency"] = 1;

    -- StarterGui.ArceusXV3.MainUI.MainFrame.Tabs.Home.HaxPage.GravS.SliderButton
    AZY["7f"] = Instance.new("ImageLabel", AZY["7e"]);
    AZY["7f"]["SliceCenter"] = Rect.new(100, 100, 100, 100);
    AZY["7f"]["ScaleType"] = Enum.ScaleType.Slice;
    AZY["7f"]["BackgroundColor3"] = Color3.fromRGB(71, 71, 71);
    AZY["7f"]["ImageColor3"] = Color3.fromRGB(146, 0, 0);
    AZY["7f"]["SliceScale"] = 0.11999999731779099;
    AZY["7f"]["Selectable"] = true;
    AZY["7f"]["Image"] = [[rbxassetid://3570695787]];
    AZY["7f"]["Size"] = UDim2.new(0, 25, 1, 0);
    AZY["7f"]["Active"] = true;
    AZY["7f"]["Name"] = [[SliderButton]];
    AZY["7f"]["BackgroundTransparency"] = 1;

    -- StarterGui.ArceusXV3.MainUI.MainFrame.Tabs.Home.HaxPage.GravS.SliderButton.LocalScript
    AZY["80"] = Instance.new("LocalScript", AZY["7f"]);


    -- StarterGui.ArceusXV3.MainUI.MainFrame.Tabs.Home.HaxPage.GravS.Border
    AZY["81"] = Instance.new("ImageLabel", AZY["7e"]);
    AZY["81"]["ZIndex"] = -1;
    AZY["81"]["SliceCenter"] = Rect.new(100, 100, 100, 100);
    AZY["81"]["ScaleType"] = Enum.ScaleType.Slice;
    AZY["81"]["BackgroundColor3"] = Color3.fromRGB(62, 62, 62);
    AZY["81"]["ImageColor3"] = Color3.fromRGB(71, 71, 71);
    AZY["81"]["SliceScale"] = 0.23999999463558197;
    AZY["81"]["ImageTransparency"] = 1;
    AZY["81"]["AnchorPoint"] = Vector2.new(0.5, 0.5);
    AZY["81"]["Image"] = [[rbxassetid://3570695787]];
    AZY["81"]["Size"] = UDim2.new(1, 12, 1, 12);
    AZY["81"]["Name"] = [[Border]];
    AZY["81"]["BackgroundTransparency"] = 0.6000000238418579;
    AZY["81"]["Position"] = UDim2.new(0.5, 0, 0.5, 0);

    -- StarterGui.ArceusXV3.MainUI.MainFrame.Tabs.Home.HaxPage.GravS.Border.UICorner
    AZY["82"] = Instance.new("UICorner", AZY["81"]);
    AZY["82"]["CornerRadius"] = UDim.new(0, 12);

    -- StarterGui.ArceusXV3.MainUI.MainFrame.Tabs.Home.HaxPage.GravS.StripedPattern
    AZY["83"] = Instance.new("ImageLabel", AZY["7e"]);
    AZY["83"]["BorderSizePixel"] = 0;
    AZY["83"]["ScaleType"] = Enum.ScaleType.Tile;
    AZY["83"]["BackgroundColor3"] = Color3.fromRGB(255, 255, 255);
    AZY["83"]["ImageColor3"] = Color3.fromRGB(32, 32, 32);
    AZY["83"]["ImageTransparency"] = 1;
    AZY["83"]["AnchorPoint"] = Vector2.new(0.5, 0);
    AZY["83"]["Image"] = [[rbxassetid://4925116997]];
    AZY["83"]["TileSize"] = UDim2.new(0, 25, 1, 0);
    AZY["83"]["Size"] = UDim2.new(1, -25, 1, 0);
    AZY["83"]["Name"] = [[StripedPattern]];
    AZY["83"]["BackgroundTransparency"] = 1;
    AZY["83"]["Position"] = UDim2.new(0.5, 0, 0, 0);

    -- StarterGui.ArceusXV3.MainUI.MainFrame.Tabs.Home.HaxPage.GravS.StripedPattern.UIGradient
    AZY["84"] = Instance.new("UIGradient", AZY["83"]);
    AZY["84"]["Rotation"] = 90;
    AZY["84"]["Color"] = ColorSequence.new{ColorSequenceKeypoint.new(0.000, Color3.fromRGB(255, 255, 255)),ColorSequenceKeypoint.new(1.000, Color3.fromRGB(0, 0, 0))};

    -- StarterGui.ArceusXV3.MainUI.MainFrame.Tabs.Home.HaxPage.GravS.ImageLabel
    AZY["85"] = Instance.new("ImageLabel", AZY["7e"]);
    AZY["85"]["BackgroundColor3"] = Color3.fromRGB(255, 255, 255);
    AZY["85"]["Image"] = [[rbxassetid://12582575947]];
    AZY["85"]["Size"] = UDim2.new(0, 35, 0, 35);
    AZY["85"]["Rotation"] = 90;
    AZY["85"]["BackgroundTransparency"] = 1;
    AZY["85"]["Position"] = UDim2.new(-0.017000000923871994, 0, -0.10000000149011612, 0);

    -- StarterGui.ArceusXV3.MainUI.MainFrame.Tabs.Home.HaxPage.GravS.TextLabel
    AZY["86"] = Instance.new("TextBox", AZY["7e"]);
    AZY["86"]["ZIndex"] = 2;
    AZY["86"]["TextSize"] = 13;
    AZY["86"]["BackgroundColor3"] = Color3.fromRGB(255, 255, 255);
    AZY["86"]["TextColor3"] = Color3.fromRGB(255, 255, 255);
    AZY["86"]["FontFace"] = Font.new([[rbxasset://fonts/families/SourceSansPro.json]], Enum.FontWeight.Bold, Enum.FontStyle.Normal);
    AZY["86"]["AnchorPoint"] = Vector2.new(1, 0);
    AZY["86"]["BackgroundTransparency"] = 1;
    AZY["86"]["Size"] = UDim2.new(0, 50, 1, 0);
    AZY["86"]["Text"] = [[0%]];
    AZY["86"]["Position"] = UDim2.new(0, 137, 0, 0);
    AZY["86"]["Rotation"] = 90;
    AZY["86"]["Name"] = [[TextLabel]];

    -- StarterGui.ArceusXV3.MainUI.MainFrame.Tabs.Changelogs
    AZY["87"] = Instance.new("Frame", AZY["2b"]);
    AZY["87"]["BackgroundColor3"] = Color3.fromRGB(0, 0, 0);
    AZY["87"]["BackgroundTransparency"] = 1;
    AZY["87"]["Size"] = UDim2.new(0.831805408000946, 0, 0.7735126614570618, 0);
    AZY["87"]["Position"] = UDim2.new(0.1409205049276352, 0, 0.18711429834365845, 0);
    AZY["87"]["Visible"] = false;
    AZY["87"]["Name"] = [[Changelogs]];

    -- StarterGui.ArceusXV3.MainUI.MainFrame.Tabs.Changelogs.TitlePage
    AZY["88"] = Instance.new("Frame", AZY["87"]);
    AZY["88"]["BackgroundColor3"] = Color3.fromRGB(0, 0, 0);
    AZY["88"]["BackgroundTransparency"] = 0.550000011920929;
    AZY["88"]["Size"] = UDim2.new(0.47281256318092346, 0, 0.2235966920852661, 0);
    AZY["88"]["Position"] = UDim2.new(0.0059703318402171135, 0, 0.020400146022439003, 0);
    AZY["88"]["Name"] = [[TitlePage]];

    -- StarterGui.ArceusXV3.MainUI.MainFrame.Tabs.Changelogs.TitlePage.UICorner
    AZY["89"] = Instance.new("UICorner", AZY["88"]);
    AZY["89"]["CornerRadius"] = UDim.new(0, 15);

    -- StarterGui.ArceusXV3.MainUI.MainFrame.Tabs.Changelogs.TitlePage.ImageLabel
    AZY["8a"] = Instance.new("ImageLabel", AZY["88"]);
    AZY["8a"]["BackgroundColor3"] = Color3.fromRGB(255, 255, 255);
    AZY["8a"]["Image"] = [[rbxassetid://12585006598]];
    AZY["8a"]["Size"] = UDim2.new(0, 48, 0, 48);
    AZY["8a"]["BackgroundTransparency"] = 1;
    AZY["8a"]["Position"] = UDim2.new(0.16064772009849548, 0, -0.020948588848114014, 0);

    -- StarterGui.ArceusXV3.MainUI.MainFrame.Tabs.Changelogs.TitlePage.TextLogo
    AZY["8b"] = Instance.new("TextLabel", AZY["88"]);
    AZY["8b"]["TextWrapped"] = true;
    AZY["8b"]["BackgroundColor3"] = Color3.fromRGB(255, 255, 255);
    AZY["8b"]["FontFace"] = Font.new([[rbxasset://fonts/families/SourceSansPro.json]], Enum.FontWeight.Bold, Enum.FontStyle.Normal);
    AZY["8b"]["TextSize"] = 17;
    AZY["8b"]["TextColor3"] = Color3.fromRGB(255, 255, 255);
    AZY["8b"]["Size"] = UDim2.new(0.48227599263191223, 0, 0.442178338766098, 0);
    AZY["8b"]["Text"] = [[SPDM Team]];
    AZY["8b"]["Name"] = [[TextLogo]];
    AZY["8b"]["BackgroundTransparency"] = 1;
    AZY["8b"]["Position"] = UDim2.new(0.3840000033378601, 0, 0.2709999978542328, 0);

    -- StarterGui.ArceusXV3.MainUI.MainFrame.Tabs.Changelogs.TitlePage.TextLogo.UITextSizeConstraint
    AZY["8c"] = Instance.new("UITextSizeConstraint", AZY["8b"]);
    AZY["8c"]["MaxTextSize"] = 25;

    -- StarterGui.ArceusXV3.MainUI.MainFrame.Tabs.Changelogs.Credits
    AZY["8d"] = Instance.new("Frame", AZY["87"]);
    AZY["8d"]["BackgroundColor3"] = Color3.fromRGB(0, 0, 0);
    AZY["8d"]["BackgroundTransparency"] = 0.550000011920929;
    AZY["8d"]["Size"] = UDim2.new(0.47281256318092346, 0, 0.7172916531562805, 0);
    AZY["8d"]["Position"] = UDim2.new(0.0059703318402171135, 0, 0.28270816802978516, 0);
    AZY["8d"]["Name"] = [[Credits]];

    -- StarterGui.ArceusXV3.MainUI.MainFrame.Tabs.Changelogs.Credits.UICorner
    AZY["8e"] = Instance.new("UICorner", AZY["8d"]);
    AZY["8e"]["CornerRadius"] = UDim.new(0, 15);

    -- StarterGui.ArceusXV3.MainUI.MainFrame.Tabs.Changelogs.Credits.Title
    AZY["8f"] = Instance.new("TextLabel", AZY["8d"]);
    AZY["8f"]["TextWrapped"] = true;
    AZY["8f"]["BackgroundColor3"] = Color3.fromRGB(255, 255, 255);
    AZY["8f"]["FontFace"] = Font.new([[rbxasset://fonts/families/SourceSansPro.json]], Enum.FontWeight.Bold, Enum.FontStyle.Normal);
    AZY["8f"]["TextSize"] = 17;
    AZY["8f"]["TextColor3"] = Color3.fromRGB(255, 255, 255);
    AZY["8f"]["Size"] = UDim2.new(0.32700005173683167, 0, 0.14513146877288818, 0);
    AZY["8f"]["Text"] = [[About us]];
    AZY["8f"]["Name"] = [[Title]];
    AZY["8f"]["BackgroundTransparency"] = 1;
    AZY["8f"]["Position"] = UDim2.new(0.056999966502189636, 0, 0.048999954015016556, 0);

    -- StarterGui.ArceusXV3.MainUI.MainFrame.Tabs.Changelogs.Credits.Title.UITextSizeConstraint
    AZY["90"] = Instance.new("UITextSizeConstraint", AZY["8f"]);
    AZY["90"]["MaxTextSize"] = 25;

    -- StarterGui.ArceusXV3.MainUI.MainFrame.Tabs.Changelogs.Credits.ScrollingFrame
    AZY["91"] = Instance.new("ScrollingFrame", AZY["8d"]);
    AZY["91"]["Active"] = true;
    AZY["91"]["CanvasSize"] = UDim2.new(0, 0, 1.5, 0);
    AZY["91"]["BackgroundColor3"] = Color3.fromRGB(255, 255, 255);
    AZY["91"]["BackgroundTransparency"] = 1;
    AZY["91"]["Size"] = UDim2.new(0, 175, 0, 110);
    AZY["91"]["ScrollBarImageColor3"] = Color3.fromRGB(255, 0, 14);
    AZY["91"]["BorderColor3"] = Color3.fromRGB(54, 0, 2);
    AZY["91"]["ScrollBarThickness"] = 5;
    AZY["91"]["Position"] = UDim2.new(-4.226361483006258e-08, 0, 0.20896700024604797, 0);

    -- StarterGui.ArceusXV3.MainUI.MainFrame.Tabs.Changelogs.Credits.ScrollingFrame.Person
    AZY["92"] = Instance.new("Frame", AZY["91"]);
    AZY["92"]["BackgroundColor3"] = Color3.fromRGB(0, 0, 0);
    AZY["92"]["BackgroundTransparency"] = 1;
    AZY["92"]["Size"] = UDim2.new(0, 144, 0, 44);
    AZY["92"]["Position"] = UDim2.new(0.11400000005960464, 0, 0, 0);
    AZY["92"]["Name"] = [[Person]];

    -- StarterGui.ArceusXV3.MainUI.MainFrame.Tabs.Changelogs.Credits.ScrollingFrame.Person.ImageLabel
    AZY["93"] = Instance.new("ImageLabel", AZY["92"]);
    AZY["93"]["BackgroundColor3"] = Color3.fromRGB(255, 255, 255);
    AZY["93"]["Image"] = [[rbxassetid://12585390334]];
    AZY["93"]["Size"] = UDim2.new(0, 41, 0, 41);
    AZY["93"]["BackgroundTransparency"] = 1;

    -- StarterGui.ArceusXV3.MainUI.MainFrame.Tabs.Changelogs.Credits.ScrollingFrame.Person.TextLogo
    AZY["94"] = Instance.new("TextLabel", AZY["92"]);
    AZY["94"]["TextWrapped"] = true;
    AZY["94"]["BackgroundColor3"] = Color3.fromRGB(255, 255, 255);
    AZY["94"]["TextXAlignment"] = Enum.TextXAlignment.Left;
    AZY["94"]["FontFace"] = Font.new([[rbxasset://fonts/families/SourceSansPro.json]], Enum.FontWeight.Bold, Enum.FontStyle.Normal);
    AZY["94"]["TextSize"] = 13;
    AZY["94"]["TextColor3"] = Color3.fromRGB(255, 255, 255);
    AZY["94"]["Size"] = UDim2.new(0.6571568250656128, 0, 0.37654438614845276, 0);
    AZY["94"]["Text"] = [[Chillz]];
    AZY["94"]["Name"] = [[TextLogo]];
    AZY["94"]["BackgroundTransparency"] = 1;
    AZY["94"]["Position"] = UDim2.new(0.34299999475479126, 0, 0.16500000655651093, 0);

    -- StarterGui.ArceusXV3.MainUI.MainFrame.Tabs.Changelogs.Credits.ScrollingFrame.Person.TextLogo.UITextSizeConstraint
    AZY["95"] = Instance.new("UITextSizeConstraint", AZY["94"]);
    AZY["95"]["MaxTextSize"] = 25;

    -- StarterGui.ArceusXV3.MainUI.MainFrame.Tabs.Changelogs.Credits.ScrollingFrame.Person.Desc
    AZY["96"] = Instance.new("TextLabel", AZY["92"]);
    AZY["96"]["TextWrapped"] = true;
    AZY["96"]["BackgroundColor3"] = Color3.fromRGB(255, 255, 255);
    AZY["96"]["TextXAlignment"] = Enum.TextXAlignment.Left;
    AZY["96"]["FontFace"] = Font.new([[rbxasset://fonts/families/SourceSansPro.json]], Enum.FontWeight.Bold, Enum.FontStyle.Normal);
    AZY["96"]["TextSize"] = 11;
    AZY["96"]["TextColor3"] = Color3.fromRGB(255, 255, 255);
    AZY["96"]["Size"] = UDim2.new(0.657156765460968, 0, 0.3310898244380951, 0);
    AZY["96"]["Text"] = [[UI Everything]];
    AZY["96"]["Name"] = [[Desc]];
    AZY["96"]["BackgroundTransparency"] = 1;
    AZY["96"]["Position"] = UDim2.new(0.34299999475479126, 0, 0.4300000071525574, 0);

    -- StarterGui.ArceusXV3.MainUI.MainFrame.Tabs.Changelogs.Credits.ScrollingFrame.Person.Desc.UITextSizeConstraint
    AZY["97"] = Instance.new("UITextSizeConstraint", AZY["96"]);
    AZY["97"]["MaxTextSize"] = 25;

    -- StarterGui.ArceusXV3.MainUI.MainFrame.Tabs.Changelogs.Credits.ScrollingFrame.Person
    AZY["98"] = Instance.new("Frame", AZY["91"]);
    AZY["98"]["BackgroundColor3"] = Color3.fromRGB(0, 0, 0);
    AZY["98"]["BackgroundTransparency"] = 1;
    AZY["98"]["Size"] = UDim2.new(0, 144, 0, 44);
    AZY["98"]["Position"] = UDim2.new(0.11400000005960464, 0, 0.19155307114124298, 0);
    AZY["98"]["Name"] = [[Person]];

    -- StarterGui.ArceusXV3.MainUI.MainFrame.Tabs.Changelogs.Credits.ScrollingFrame.Person.ImageLabel
    AZY["99"] = Instance.new("ImageLabel", AZY["98"]);
    AZY["99"]["BackgroundColor3"] = Color3.fromRGB(255, 255, 255);
    AZY["99"]["Image"] = [[rbxassetid://12585434446]];
    AZY["99"]["Size"] = UDim2.new(0, 41, 0, 41);
    AZY["99"]["BackgroundTransparency"] = 1;

    -- StarterGui.ArceusXV3.MainUI.MainFrame.Tabs.Changelogs.Credits.ScrollingFrame.Person.TextLogo
    AZY["9a"] = Instance.new("TextLabel", AZY["98"]);
    AZY["9a"]["TextWrapped"] = true;
    AZY["9a"]["BackgroundColor3"] = Color3.fromRGB(255, 255, 255);
    AZY["9a"]["TextXAlignment"] = Enum.TextXAlignment.Left;
    AZY["9a"]["FontFace"] = Font.new([[rbxasset://fonts/families/SourceSansPro.json]], Enum.FontWeight.Bold, Enum.FontStyle.Normal);
    AZY["9a"]["TextSize"] = 13;
    AZY["9a"]["TextColor3"] = Color3.fromRGB(255, 255, 255);
    AZY["9a"]["Size"] = UDim2.new(0.6571568250656128, 0, 0.37654438614845276, 0);
    AZY["9a"]["Text"] = [[Ash01#0947]];
    AZY["9a"]["Name"] = [[TextLogo]];
    AZY["9a"]["BackgroundTransparency"] = 1;
    AZY["9a"]["Position"] = UDim2.new(0.34299999475479126, 0, 0.16500000655651093, 0);

    -- StarterGui.ArceusXV3.MainUI.MainFrame.Tabs.Changelogs.Credits.ScrollingFrame.Person.TextLogo.UITextSizeConstraint
    AZY["9b"] = Instance.new("UITextSizeConstraint", AZY["9a"]);
    AZY["9b"]["MaxTextSize"] = 25;

    -- StarterGui.ArceusXV3.MainUI.MainFrame.Tabs.Changelogs.Credits.ScrollingFrame.Person.Desc
    AZY["9c"] = Instance.new("TextLabel", AZY["98"]);
    AZY["9c"]["TextWrapped"] = true;
    AZY["9c"]["BackgroundColor3"] = Color3.fromRGB(255, 255, 255);
    AZY["9c"]["TextXAlignment"] = Enum.TextXAlignment.Left;
    AZY["9c"]["FontFace"] = Font.new([[rbxasset://fonts/families/SourceSansPro.json]], Enum.FontWeight.Bold, Enum.FontStyle.Normal);
    AZY["9c"]["TextColor3"] = Color3.fromRGB(255, 255, 255);
    AZY["9c"]["Size"] = UDim2.new(0.657156765460968, 0, 0.3310898244380951, 0);
    AZY["9c"]["Text"] = [[Pwner Hub Owner / Creator]];
    AZY["9c"]["Name"] = [[Desc]];
    AZY["9c"]["BackgroundTransparency"] = 1;
    AZY["9c"]["Position"] = UDim2.new(0.34299999475479126, 0, 0.4300000071525574, 0);

    -- StarterGui.ArceusXV3.MainUI.MainFrame.Tabs.Changelogs.Credits.ScrollingFrame.Person.Desc.UITextSizeConstraint
    AZY["9d"] = Instance.new("UITextSizeConstraint", AZY["9c"]);
    AZY["9d"]["MaxTextSize"] = 25;

    -- StarterGui.ArceusXV3.MainUI.MainFrame.Tabs.Changelogs.Credits.ScrollingFrame.Person
    AZY["9e"] = Instance.new("Frame", AZY["91"]);
    AZY["9e"]["BackgroundColor3"] = Color3.fromRGB(0, 0, 0);
    AZY["9e"]["BackgroundTransparency"] = 1;
    AZY["9e"]["Size"] = UDim2.new(0, 144, 0, 44);
    AZY["9e"]["Position"] = UDim2.new(0.11400000005960464, 0, 0.38310614228248596, 0);
    AZY["9e"]["Name"] = [[Person]];

    -- StarterGui.ArceusXV3.MainUI.MainFrame.Tabs.Changelogs.Credits.ScrollingFrame.Person.ImageLabel
    AZY["9f"] = Instance.new("ImageLabel", AZY["9e"]);
    AZY["9f"]["BackgroundColor3"] = Color3.fromRGB(255, 255, 255);
    AZY["9f"]["Image"] = [[http://www.roblox.com/asset/?id=12642988505]];
    AZY["9f"]["Size"] = UDim2.new(0, 41, 0, 41);
    AZY["9f"]["BackgroundTransparency"] = 1;

    -- StarterGui.ArceusXV3.MainUI.MainFrame.Tabs.Changelogs.Credits.ScrollingFrame.Person.TextLogo
    AZY["a0"] = Instance.new("TextLabel", AZY["9e"]);
    AZY["a0"]["TextWrapped"] = true;
    AZY["a0"]["BackgroundColor3"] = Color3.fromRGB(255, 255, 255);
    AZY["a0"]["TextXAlignment"] = Enum.TextXAlignment.Left;
    AZY["a0"]["FontFace"] = Font.new([[rbxasset://fonts/families/SourceSansPro.json]], Enum.FontWeight.Bold, Enum.FontStyle.Normal);
    AZY["a0"]["TextSize"] = 13;
    AZY["a0"]["TextColor3"] = Color3.fromRGB(255, 255, 255);
    AZY["a0"]["Size"] = UDim2.new(0.6571568250656128, 0, 0.37654438614845276, 0);
    AZY["a0"]["Text"] = [[Bread!]];
    AZY["a0"]["Name"] = [[TextLogo]];
    AZY["a0"]["BackgroundTransparency"] = 1;
    AZY["a0"]["Position"] = UDim2.new(0.34299999475479126, 0, 0.16500000655651093, 0);

    -- StarterGui.ArceusXV3.MainUI.MainFrame.Tabs.Changelogs.Credits.ScrollingFrame.Person.TextLogo.UITextSizeConstraint
    AZY["a1"] = Instance.new("UITextSizeConstraint", AZY["a0"]);
    AZY["a1"]["MaxTextSize"] = 25;

    -- StarterGui.ArceusXV3.MainUI.MainFrame.Tabs.Changelogs.Credits.ScrollingFrame.Person.Desc
    AZY["a2"] = Instance.new("TextLabel", AZY["9e"]);
    AZY["a2"]["TextWrapped"] = true;
    AZY["a2"]["BackgroundColor3"] = Color3.fromRGB(255, 255, 255);
    AZY["a2"]["TextXAlignment"] = Enum.TextXAlignment.Left;
    AZY["a2"]["FontFace"] = Font.new([[rbxasset://fonts/families/SourceSansPro.json]], Enum.FontWeight.Bold, Enum.FontStyle.Normal);
    AZY["a2"]["TextColor3"] = Color3.fromRGB(255, 255, 255);
    AZY["a2"]["Size"] = UDim2.new(0.657156765460968, 0, 0.3310898244380951, 0);
    AZY["a2"]["Text"] = [[UI Slider Fixes And Textbox]];
    AZY["a2"]["Name"] = [[Desc]];
    AZY["a2"]["BackgroundTransparency"] = 1;
    AZY["a2"]["Position"] = UDim2.new(0.34299999475479126, 0, 0.4300000071525574, 0);

    -- StarterGui.ArceusXV3.MainUI.MainFrame.Tabs.Changelogs.Credits.ScrollingFrame.Person.Desc.UITextSizeConstraint
    AZY["a3"] = Instance.new("UITextSizeConstraint", AZY["a2"]);
    AZY["a3"]["MaxTextSize"] = 25;

    -- StarterGui.ArceusXV3.MainUI.MainFrame.Tabs.Changelogs.Changelog
    AZY["a4"] = Instance.new("Frame", AZY["87"]);
    AZY["a4"]["BackgroundColor3"] = Color3.fromRGB(0, 0, 0);
    AZY["a4"]["BackgroundTransparency"] = 0.550000011920929;
    AZY["a4"]["Size"] = UDim2.new(0.47281256318092346, 0, 0.7172916531562805, 0);
    AZY["a4"]["Position"] = UDim2.new(0.5088531970977783, 0, 0.020400196313858032, 0);
    AZY["a4"]["Name"] = [[Changelog]];

    -- StarterGui.ArceusXV3.MainUI.MainFrame.Tabs.Changelogs.Changelog.UICorner
    AZY["a5"] = Instance.new("UICorner", AZY["a4"]);
    AZY["a5"]["CornerRadius"] = UDim.new(0, 15);

    -- StarterGui.ArceusXV3.MainUI.MainFrame.Tabs.Changelogs.Changelog.TextLogo
    AZY["a6"] = Instance.new("TextLabel", AZY["a4"]);
    AZY["a6"]["TextWrapped"] = true;
    AZY["a6"]["BackgroundColor3"] = Color3.fromRGB(255, 255, 255);
    AZY["a6"]["FontFace"] = Font.new([[rbxasset://fonts/families/SourceSansPro.json]], Enum.FontWeight.Bold, Enum.FontStyle.Normal);
    AZY["a6"]["TextSize"] = 19;
    AZY["a6"]["TextColor3"] = Color3.fromRGB(255, 255, 255);
    AZY["a6"]["Size"] = UDim2.new(0.39918234944343567, 0, 0.14513146877288818, 0);
    AZY["a6"]["Text"] = [[Changelog]];
    AZY["a6"]["Name"] = [[TextLogo]];
    AZY["a6"]["BackgroundTransparency"] = 1;
    AZY["a6"]["Position"] = UDim2.new(0.05700000002980232, 0, 0.04899999871850014, 0);

    -- StarterGui.ArceusXV3.MainUI.MainFrame.Tabs.Changelogs.Changelog.TextLogo.UITextSizeConstraint
    AZY["a7"] = Instance.new("UITextSizeConstraint", AZY["a6"]);
    AZY["a7"]["MaxTextSize"] = 25;

    -- StarterGui.ArceusXV3.MainUI.MainFrame.Tabs.Changelogs.Changelog.Ver
    AZY["a8"] = Instance.new("TextLabel", AZY["a4"]);
    AZY["a8"]["TextWrapped"] = true;
    AZY["a8"]["BackgroundColor3"] = Color3.fromRGB(255, 255, 255);
    AZY["a8"]["FontFace"] = Font.new([[rbxasset://fonts/families/SourceSansPro.json]], Enum.FontWeight.Bold, Enum.FontStyle.Normal);
    AZY["a8"]["TextSize"] = 13;
    AZY["a8"]["TextColor3"] = Color3.fromRGB(255, 255, 255);
    AZY["a8"]["Size"] = UDim2.new(0.240515798330307, 0, 0.14513146877288818, 0);
    AZY["a8"]["Text"] = [[v3.0.1]];
    AZY["a8"]["Name"] = [[Ver]];
    AZY["a8"]["BackgroundTransparency"] = 1;
    AZY["a8"]["Position"] = UDim2.new(0.6331158876419067, 0, 0.04900005832314491, 0);

    -- StarterGui.ArceusXV3.MainUI.MainFrame.Tabs.Changelogs.Changelog.Ver.UITextSizeConstraint
    AZY["a9"] = Instance.new("UITextSizeConstraint", AZY["a8"]);
    AZY["a9"]["MaxTextSize"] = 25;

    -- StarterGui.ArceusXV3.MainUI.MainFrame.Tabs.Changelogs.Changelog.Ver
    AZY["aa"] = Instance.new("TextLabel", AZY["a4"]);
    AZY["aa"]["TextWrapped"] = true;
    AZY["aa"]["BackgroundColor3"] = Color3.fromRGB(255, 255, 255);
    AZY["aa"]["FontFace"] = Font.new([[rbxasset://fonts/families/SourceSansPro.json]], Enum.FontWeight.Bold, Enum.FontStyle.Normal);
    AZY["aa"]["TextSize"] = 9;
    AZY["aa"]["TextColor3"] = Color3.fromRGB(255, 255, 255);
    AZY["aa"]["Size"] = UDim2.new(0.0997123271226883, 0, 0.08936085551977158, 0);
    AZY["aa"]["Text"] = [[beta]];
    AZY["aa"]["Name"] = [[Ver]];
    AZY["aa"]["BackgroundTransparency"] = 1;
    AZY["aa"]["Position"] = UDim2.new(0.8399999737739563, 0, 0.0820000022649765, 0);

    -- StarterGui.ArceusXV3.MainUI.MainFrame.Tabs.Changelogs.Changelog.Ver.UITextSizeConstraint
    AZY["ab"] = Instance.new("UITextSizeConstraint", AZY["aa"]);
    AZY["ab"]["MaxTextSize"] = 25;

    -- StarterGui.ArceusXV3.MainUI.MainFrame.Tabs.Changelogs.Changelog.ScrollingFrame
    AZY["ac"] = Instance.new("ScrollingFrame", AZY["a4"]);
    AZY["ac"]["Active"] = true;
    AZY["ac"]["BackgroundColor3"] = Color3.fromRGB(255, 255, 255);
    AZY["ac"]["BackgroundTransparency"] = 1;
    AZY["ac"]["Size"] = UDim2.new(0, 165, 0, 113);
    AZY["ac"]["ScrollBarImageColor3"] = Color3.fromRGB(255, 0, 14);
    AZY["ac"]["BorderColor3"] = Color3.fromRGB(54, 0, 2);
    AZY["ac"]["ScrollBarThickness"] = 5;
    AZY["ac"]["Position"] = UDim2.new(0.05699992552399635, 0, 0.20896704494953156, 0);

    -- StarterGui.ArceusXV3.MainUI.MainFrame.Tabs.Changelogs.Changelog.ScrollingFrame.ChangelogTab
    AZY["ad"] = Instance.new("Frame", AZY["ac"]);
    AZY["ad"]["BackgroundColor3"] = Color3.fromRGB(0, 0, 0);
    AZY["ad"]["BackgroundTransparency"] = 1;
    AZY["ad"]["Size"] = UDim2.new(0.8838858008384705, 0, 0.41258352994918823, 0);
    AZY["ad"]["Position"] = UDim2.new(-0.001135505735874176, 0, 0.008439034223556519, 0);
    AZY["ad"]["Name"] = [[ChangelogTab]];

    -- StarterGui.ArceusXV3.MainUI.MainFrame.Tabs.Changelogs.Changelog.ScrollingFrame.ChangelogTab.UICorner
    AZY["ae"] = Instance.new("UICorner", AZY["ad"]);
    AZY["ae"]["CornerRadius"] = UDim.new(0, 15);

    -- StarterGui.ArceusXV3.MainUI.MainFrame.Tabs.Changelogs.Changelog.ScrollingFrame.ChangelogTab.TextLabel
    AZY["af"] = Instance.new("TextLabel", AZY["ad"]);
    AZY["af"]["BackgroundColor3"] = Color3.fromRGB(255, 255, 255);
    AZY["af"]["FontFace"] = Font.new([[rbxasset://fonts/families/SourceSansPro.json]], Enum.FontWeight.Regular, Enum.FontStyle.Normal);
    AZY["af"]["TextSize"] = 56;
    AZY["af"]["TextColor3"] = Color3.fromRGB(255, 255, 255);
    AZY["af"]["Size"] = UDim2.new(0, 18, 0, 20);
    AZY["af"]["Text"] = [[.]];
    AZY["af"]["BackgroundTransparency"] = 1;
    AZY["af"]["Position"] = UDim2.new(-0.00024911601212807, 0, -0.08813343942165375, 0);

    -- StarterGui.ArceusXV3.MainUI.MainFrame.Tabs.Changelogs.Changelog.ScrollingFrame.ChangelogTab.TextLabel
    AZY["b0"] = Instance.new("TextLabel", AZY["ad"]);
    AZY["b0"]["BackgroundColor3"] = Color3.fromRGB(0, 187, 7);
    AZY["b0"]["FontFace"] = Font.new([[rbxasset://fonts/families/SourceSansPro.json]], Enum.FontWeight.Bold, Enum.FontStyle.Normal);
    AZY["b0"]["TextSize"] = 14;
    AZY["b0"]["TextColor3"] = Color3.fromRGB(255, 255, 255);
    AZY["b0"]["Size"] = UDim2.new(0, 29, 0, 14);
    AZY["b0"]["Text"] = [[New]];
    AZY["b0"]["Position"] = UDim2.new(0.10899999737739563, 0, 0.05000000074505806, 0);

    -- StarterGui.ArceusXV3.MainUI.MainFrame.Tabs.Changelogs.Changelog.ScrollingFrame.ChangelogTab.TextLabel.UICorner
    AZY["b1"] = Instance.new("UICorner", AZY["b0"]);
    AZY["b1"]["CornerRadius"] = UDim.new(0, 4);

    -- StarterGui.ArceusXV3.MainUI.MainFrame.Tabs.Changelogs.Changelog.ScrollingFrame.ChangelogTab.TextLabel
    AZY["b2"] = Instance.new("TextLabel", AZY["ad"]);
    AZY["b2"]["TextWrapped"] = true;
    AZY["b2"]["TextYAlignment"] = Enum.TextYAlignment.Top;
    AZY["b2"]["BackgroundColor3"] = Color3.fromRGB(255, 255, 255);
    AZY["b2"]["TextXAlignment"] = Enum.TextXAlignment.Left;
    AZY["b2"]["FontFace"] = Font.new([[rbxasset://fonts/families/SourceSansPro.json]], Enum.FontWeight.Regular, Enum.FontStyle.Normal);
    AZY["b2"]["TextSize"] = 11;
    AZY["b2"]["TextColor3"] = Color3.fromRGB(255, 255, 255);
    AZY["b2"]["Size"] = UDim2.new(0, 109, 0, 60);
    AZY["b2"]["Text"] = [[Floating icon now with addec functionality! In addition to opening the mod menu, holding it down will take you directly to your desired page]];
    AZY["b2"]["BackgroundTransparency"] = 1;
    AZY["b2"]["Position"] = UDim2.new(0.34079205989837646, 0, 0.04748288542032242, 0);

    -- StarterGui.ArceusXV3.MainUI.MainFrame.Tabs.Changelogs.Changelog.ScrollingFrame.ChangelogTab1
    AZY["b3"] = Instance.new("Frame", AZY["ac"]);
    AZY["b3"]["BackgroundColor3"] = Color3.fromRGB(0, 0, 0);
    AZY["b3"]["BackgroundTransparency"] = 1;
    AZY["b3"]["Size"] = UDim2.new(0.8838858008384705, 0, 0.41258352994918823, 0);
    AZY["b3"]["Position"] = UDim2.new(-0.0071961116045713425, 0, 0.20108048617839813, 0);
    AZY["b3"]["Name"] = [[ChangelogTab1]];

    -- StarterGui.ArceusXV3.MainUI.MainFrame.Tabs.Changelogs.Changelog.ScrollingFrame.ChangelogTab1.UICorner
    AZY["b4"] = Instance.new("UICorner", AZY["b3"]);
    AZY["b4"]["CornerRadius"] = UDim.new(0, 15);

    -- StarterGui.ArceusXV3.MainUI.MainFrame.Tabs.Changelogs.Changelog.ScrollingFrame.ChangelogTab1.TextLabel
    AZY["b5"] = Instance.new("TextLabel", AZY["b3"]);
    AZY["b5"]["BackgroundColor3"] = Color3.fromRGB(255, 255, 255);
    AZY["b5"]["FontFace"] = Font.new([[rbxasset://fonts/families/SourceSansPro.json]], Enum.FontWeight.Regular, Enum.FontStyle.Normal);
    AZY["b5"]["TextSize"] = 56;
    AZY["b5"]["TextColor3"] = Color3.fromRGB(255, 255, 255);
    AZY["b5"]["Size"] = UDim2.new(0, 18, 0, 20);
    AZY["b5"]["Text"] = [[.]];
    AZY["b5"]["BackgroundTransparency"] = 1;
    AZY["b5"]["Position"] = UDim2.new(-0.00024911601212807, 0, -0.08813343942165375, 0);

    -- StarterGui.ArceusXV3.MainUI.MainFrame.Tabs.Changelogs.Changelog.ScrollingFrame.ChangelogTab1.TextLabel
    AZY["b6"] = Instance.new("TextLabel", AZY["b3"]);
    AZY["b6"]["BackgroundColor3"] = Color3.fromRGB(0, 187, 7);
    AZY["b6"]["FontFace"] = Font.new([[rbxasset://fonts/families/SourceSansPro.json]], Enum.FontWeight.Bold, Enum.FontStyle.Normal);
    AZY["b6"]["TextSize"] = 14;
    AZY["b6"]["TextColor3"] = Color3.fromRGB(255, 255, 255);
    AZY["b6"]["Size"] = UDim2.new(0, 29, 0, 14);
    AZY["b6"]["Text"] = [[New]];
    AZY["b6"]["Position"] = UDim2.new(0.10899999737739563, 0, 0.05000000074505806, 0);

    -- StarterGui.ArceusXV3.MainUI.MainFrame.Tabs.Changelogs.Changelog.ScrollingFrame.ChangelogTab1.TextLabel.UICorner
    AZY["b7"] = Instance.new("UICorner", AZY["b6"]);
    AZY["b7"]["CornerRadius"] = UDim.new(0, 4);

    -- StarterGui.ArceusXV3.MainUI.MainFrame.Tabs.Changelogs.Changelog.ScrollingFrame.ChangelogTab1.TextLabel
    AZY["b8"] = Instance.new("TextLabel", AZY["b3"]);
    AZY["b8"]["TextWrapped"] = true;
    AZY["b8"]["TextYAlignment"] = Enum.TextYAlignment.Top;
    AZY["b8"]["BackgroundColor3"] = Color3.fromRGB(255, 255, 255);
    AZY["b8"]["TextXAlignment"] = Enum.TextXAlignment.Left;
    AZY["b8"]["FontFace"] = Font.new([[rbxasset://fonts/families/SourceSansPro.json]], Enum.FontWeight.Regular, Enum.FontStyle.Normal);
    AZY["b8"]["TextSize"] = 11;
    AZY["b8"]["TextColor3"] = Color3.fromRGB(255, 255, 255);
    AZY["b8"]["Size"] = UDim2.new(0, 109, 0, 60);
    AZY["b8"]["Text"] = [[Stunning Design with breathtaking graphical elements, animations, colors and beautiful icons!]];
    AZY["b8"]["BackgroundTransparency"] = 1;
    AZY["b8"]["Position"] = UDim2.new(0.34079205989837646, 0, 0.04748288542032242, 0);

    -- StarterGui.ArceusXV3.MainUI.MainFrame.Tabs.Changelogs.Changelog.ScrollingFrame.ChangelogTab2
    AZY["b9"] = Instance.new("Frame", AZY["ac"]);
    AZY["b9"]["BackgroundColor3"] = Color3.fromRGB(0, 0, 0);
    AZY["b9"]["BackgroundTransparency"] = 1;
    AZY["b9"]["Size"] = UDim2.new(0.8838858008384705, 0, 0.41258352994918823, 0);
    AZY["b9"]["Position"] = UDim2.new(-0.0010000000474974513, 0, 0.3869999945163727, 0);
    AZY["b9"]["Name"] = [[ChangelogTab2]];

    -- StarterGui.ArceusXV3.MainUI.MainFrame.Tabs.Changelogs.Changelog.ScrollingFrame.ChangelogTab2.UICorner
    AZY["ba"] = Instance.new("UICorner", AZY["b9"]);
    AZY["ba"]["CornerRadius"] = UDim.new(0, 15);

    -- StarterGui.ArceusXV3.MainUI.MainFrame.Tabs.Changelogs.Changelog.ScrollingFrame.ChangelogTab2.TextLabel
    AZY["bb"] = Instance.new("TextLabel", AZY["b9"]);
    AZY["bb"]["BackgroundColor3"] = Color3.fromRGB(255, 255, 255);
    AZY["bb"]["FontFace"] = Font.new([[rbxasset://fonts/families/SourceSansPro.json]], Enum.FontWeight.Regular, Enum.FontStyle.Normal);
    AZY["bb"]["TextSize"] = 56;
    AZY["bb"]["TextColor3"] = Color3.fromRGB(255, 255, 255);
    AZY["bb"]["Size"] = UDim2.new(0, 18, 0, 20);
    AZY["bb"]["Text"] = [[.]];
    AZY["bb"]["BackgroundTransparency"] = 1;
    AZY["bb"]["Position"] = UDim2.new(-0.00024911601212807, 0, -0.08813343942165375, 0);

    -- StarterGui.ArceusXV3.MainUI.MainFrame.Tabs.Changelogs.Changelog.ScrollingFrame.ChangelogTab2.TextLabel
    AZY["bc"] = Instance.new("TextLabel", AZY["b9"]);
    AZY["bc"]["BackgroundColor3"] = Color3.fromRGB(0, 187, 7);
    AZY["bc"]["FontFace"] = Font.new([[rbxasset://fonts/families/SourceSansPro.json]], Enum.FontWeight.Bold, Enum.FontStyle.Normal);
    AZY["bc"]["TextSize"] = 14;
    AZY["bc"]["TextColor3"] = Color3.fromRGB(255, 255, 255);
    AZY["bc"]["Size"] = UDim2.new(0, 29, 0, 14);
    AZY["bc"]["Text"] = [[New]];
    AZY["bc"]["Position"] = UDim2.new(0.10899999737739563, 0, 0.05000000074505806, 0);

    -- StarterGui.ArceusXV3.MainUI.MainFrame.Tabs.Changelogs.Changelog.ScrollingFrame.ChangelogTab2.TextLabel.UICorner
    AZY["bd"] = Instance.new("UICorner", AZY["bc"]);
    AZY["bd"]["CornerRadius"] = UDim.new(0, 4);

    -- StarterGui.ArceusXV3.MainUI.MainFrame.Tabs.Changelogs.Changelog.ScrollingFrame.ChangelogTab2.TextLabel
    AZY["be"] = Instance.new("TextLabel", AZY["b9"]);
    AZY["be"]["TextWrapped"] = true;
    AZY["be"]["TextYAlignment"] = Enum.TextYAlignment.Top;
    AZY["be"]["BackgroundColor3"] = Color3.fromRGB(255, 255, 255);
    AZY["be"]["TextXAlignment"] = Enum.TextXAlignment.Left;
    AZY["be"]["FontFace"] = Font.new([[rbxasset://fonts/families/SourceSansPro.json]], Enum.FontWeight.Regular, Enum.FontStyle.Normal);
    AZY["be"]["TextSize"] = 11;
    AZY["be"]["TextColor3"] = Color3.fromRGB(255, 255, 255);
    AZY["be"]["Size"] = UDim2.new(0, 109, 0, 60);
    AZY["be"]["Text"] = [[Window design with comfortable UI movement and a semi-transparent mod menu for a less intrusive gaming experience!]];
    AZY["be"]["BackgroundTransparency"] = 1;
    AZY["be"]["Position"] = UDim2.new(0.34079205989837646, 0, 0.04748288542032242, 0);

    -- StarterGui.ArceusXV3.MainUI.MainFrame.Tabs.Changelogs.Changelog.ScrollingFrame.ChangelogTab3
    AZY["bf"] = Instance.new("Frame", AZY["ac"]);
    AZY["bf"]["BackgroundColor3"] = Color3.fromRGB(0, 0, 0);
    AZY["bf"]["BackgroundTransparency"] = 1;
    AZY["bf"]["Size"] = UDim2.new(0.8838858008384705, 0, 0.41258352994918823, 0);
    AZY["bf"]["Position"] = UDim2.new(0.005060605704784393, 0, 0.5927019119262695, 0);
    AZY["bf"]["Name"] = [[ChangelogTab3]];

    -- StarterGui.ArceusXV3.MainUI.MainFrame.Tabs.Changelogs.Changelog.ScrollingFrame.ChangelogTab3.UICorner
    AZY["c0"] = Instance.new("UICorner", AZY["bf"]);
    AZY["c0"]["CornerRadius"] = UDim.new(0, 15);

    -- StarterGui.ArceusXV3.MainUI.MainFrame.Tabs.Changelogs.Changelog.ScrollingFrame.ChangelogTab3.TextLabel
    AZY["c1"] = Instance.new("TextLabel", AZY["bf"]);
    AZY["c1"]["BackgroundColor3"] = Color3.fromRGB(255, 255, 255);
    AZY["c1"]["FontFace"] = Font.new([[rbxasset://fonts/families/SourceSansPro.json]], Enum.FontWeight.Regular, Enum.FontStyle.Normal);
    AZY["c1"]["TextSize"] = 56;
    AZY["c1"]["TextColor3"] = Color3.fromRGB(255, 255, 255);
    AZY["c1"]["Size"] = UDim2.new(0, 18, 0, 20);
    AZY["c1"]["Text"] = [[.]];
    AZY["c1"]["BackgroundTransparency"] = 1;
    AZY["c1"]["Position"] = UDim2.new(-0.00024911601212807, 0, -0.08813343942165375, 0);

    -- StarterGui.ArceusXV3.MainUI.MainFrame.Tabs.Changelogs.Changelog.ScrollingFrame.ChangelogTab3.TextLabel
    AZY["c2"] = Instance.new("TextLabel", AZY["bf"]);
    AZY["c2"]["BackgroundColor3"] = Color3.fromRGB(0, 187, 7);
    AZY["c2"]["FontFace"] = Font.new([[rbxasset://fonts/families/SourceSansPro.json]], Enum.FontWeight.Bold, Enum.FontStyle.Normal);
    AZY["c2"]["TextSize"] = 14;
    AZY["c2"]["TextColor3"] = Color3.fromRGB(255, 255, 255);
    AZY["c2"]["Size"] = UDim2.new(0, 29, 0, 14);
    AZY["c2"]["Text"] = [[New]];
    AZY["c2"]["Position"] = UDim2.new(0.10899999737739563, 0, 0.05000000074505806, 0);

    -- StarterGui.ArceusXV3.MainUI.MainFrame.Tabs.Changelogs.Changelog.ScrollingFrame.ChangelogTab3.TextLabel.UICorner
    AZY["c3"] = Instance.new("UICorner", AZY["c2"]);
    AZY["c3"]["CornerRadius"] = UDim.new(0, 4);

    -- StarterGui.ArceusXV3.MainUI.MainFrame.Tabs.Changelogs.Changelog.ScrollingFrame.ChangelogTab3.TextLabel
    AZY["c4"] = Instance.new("TextLabel", AZY["bf"]);
    AZY["c4"]["TextWrapped"] = true;
    AZY["c4"]["TextYAlignment"] = Enum.TextYAlignment.Top;
    AZY["c4"]["BackgroundColor3"] = Color3.fromRGB(255, 255, 255);
    AZY["c4"]["TextXAlignment"] = Enum.TextXAlignment.Left;
    AZY["c4"]["FontFace"] = Font.new([[rbxasset://fonts/families/SourceSansPro.json]], Enum.FontWeight.Regular, Enum.FontStyle.Normal);
    AZY["c4"]["TextSize"] = 11;
    AZY["c4"]["TextColor3"] = Color3.fromRGB(255, 255, 255);
    AZY["c4"]["Size"] = UDim2.new(0, 109, 0, 60);
    AZY["c4"]["Text"] = [[Info page with all information about our team and our social media! Plus an intuitive and well-designed changelog.]];
    AZY["c4"]["BackgroundTransparency"] = 1;
    AZY["c4"]["Position"] = UDim2.new(0.34079205989837646, 0, 0.04748288542032242, 0);

    -- StarterGui.ArceusXV3.MainUI.MainFrame.Tabs.Changelogs.Communications
    AZY["c5"] = Instance.new("Frame", AZY["87"]);
    AZY["c5"]["BackgroundColor3"] = Color3.fromRGB(0, 0, 0);
    AZY["c5"]["BackgroundTransparency"] = 0.550000011920929;
    AZY["c5"]["Size"] = UDim2.new(0.47281256318092346, 0, 0.2235966920852661, 0);
    AZY["c5"]["Position"] = UDim2.new(0.5088531970977783, 0, 0.774535596370697, 0);
    AZY["c5"]["Name"] = [[Communications]];

    -- StarterGui.ArceusXV3.MainUI.MainFrame.Tabs.Changelogs.Communications.UICorner
    AZY["c6"] = Instance.new("UICorner", AZY["c5"]);
    AZY["c6"]["CornerRadius"] = UDim.new(0, 15);

    -- StarterGui.ArceusXV3.MainUI.MainFrame.Tabs.Changelogs.Communications.Copy
    AZY["c7"] = Instance.new("TextButton", AZY["c5"]);
    AZY["c7"]["TextWrapped"] = true;
    AZY["c7"]["BackgroundColor3"] = Color3.fromRGB(255, 0, 0);
    AZY["c7"]["TextSize"] = 12;
    AZY["c7"]["FontFace"] = Font.new([[rbxasset://fonts/families/SourceSansPro.json]], Enum.FontWeight.Bold, Enum.FontStyle.Normal);
    AZY["c7"]["TextColor3"] = Color3.fromRGB(255, 255, 255);
    AZY["c7"]["Size"] = UDim2.new(0.41421639919281006, 0, 0.503000020980835, 0);
    AZY["c7"]["Name"] = [[Copy]];
    AZY["c7"]["Text"] = [[Copy Link]];
    AZY["c7"]["Position"] = UDim2.new(0.03737286850810051, 0, 0.22850681841373444, 0);

    -- StarterGui.ArceusXV3.MainUI.MainFrame.Tabs.Changelogs.Communications.Copy.UICorner
    AZY["c8"] = Instance.new("UICorner", AZY["c7"]);
    AZY["c8"]["CornerRadius"] = UDim.new(0, 6);

    -- StarterGui.ArceusXV3.MainUI.MainFrame.Tabs.Changelogs.Communications.Copy.LocalScript
    AZY["c9"] = Instance.new("LocalScript", AZY["c7"]);


    -- StarterGui.ArceusXV3.MainUI.MainFrame.Tabs.Changelogs.Communications.TextLogo
    AZY["ca"] = Instance.new("TextLabel", AZY["c5"]);
    AZY["ca"]["TextWrapped"] = true;
    AZY["ca"]["BackgroundColor3"] = Color3.fromRGB(255, 255, 255);
    AZY["ca"]["FontFace"] = Font.new([[rbxasset://fonts/families/SourceSansPro.json]], Enum.FontWeight.Bold, Enum.FontStyle.Normal);
    AZY["ca"]["TextSize"] = 19;
    AZY["ca"]["TextColor3"] = Color3.fromRGB(255, 255, 255);
    AZY["ca"]["Size"] = UDim2.new(0.14990141987800598, 0, 0.2844810485839844, 0);
    AZY["ca"]["Text"] = [[Or]];
    AZY["ca"]["Name"] = [[TextLogo]];
    AZY["ca"]["BackgroundTransparency"] = 1;
    AZY["ca"]["Position"] = UDim2.new(0.45584943890571594, 0, 0.30038517713546753, 0);

    -- StarterGui.ArceusXV3.MainUI.MainFrame.Tabs.Changelogs.Communications.TextLogo.UITextSizeConstraint
    AZY["cb"] = Instance.new("UITextSizeConstraint", AZY["ca"]);
    AZY["cb"]["MaxTextSize"] = 25;

    -- StarterGui.ArceusXV3.MainUI.MainFrame.Tabs.Changelogs.Communications.TextLogo
    AZY["cc"] = Instance.new("TextLabel", AZY["c5"]);
    AZY["cc"]["TextWrapped"] = true;
    AZY["cc"]["BackgroundColor3"] = Color3.fromRGB(255, 255, 255);
    AZY["cc"]["FontFace"] = Font.new([[rbxasset://fonts/families/SourceSansPro.json]], Enum.FontWeight.Bold, Enum.FontStyle.Normal);
    AZY["cc"]["TextSize"] = 19;
    AZY["cc"]["TextColor3"] = Color3.fromRGB(255, 255, 255);
    AZY["cc"]["Size"] = UDim2.new(0.4056611955165863, 0, 0.2844810485839844, 0);
    AZY["cc"]["Text"] = [[AZY#0348]];
    AZY["cc"]["Name"] = [[TextLogo]];
    AZY["cc"]["BackgroundTransparency"] = 1;
    AZY["cc"]["Position"] = UDim2.new(0.5839999914169312, 0, 0.29899999499320984, 0);

    -- StarterGui.ArceusXV3.MainUI.MainFrame.Tabs.Changelogs.Communications.TextLogo.UITextSizeConstraint
    AZY["cd"] = Instance.new("UITextSizeConstraint", AZY["cc"]);
    AZY["cd"]["MaxTextSize"] = 25;

    -- StarterGui.ArceusXV3.MainUI.MainFrame.Tabs.BuiltInHax
    AZY["ce"] = Instance.new("Frame", AZY["2b"]);
    AZY["ce"]["BackgroundColor3"] = Color3.fromRGB(0, 0, 0);
    AZY["ce"]["BackgroundTransparency"] = 0.550000011920929;
    AZY["ce"]["Size"] = UDim2.new(0.831805408000946, 0, 0.7551097869873047, 0);
    AZY["ce"]["Position"] = UDim2.new(0.1409205049276352, 0, 0.20551720261573792, 0);
    AZY["ce"]["Visible"] = false;
    AZY["ce"]["Name"] = [[BuiltInHax]];

    -- StarterGui.ArceusXV3.MainUI.MainFrame.Tabs.BuiltInHax.UICorner
    AZY["cf"] = Instance.new("UICorner", AZY["ce"]);
    AZY["cf"]["CornerRadius"] = UDim.new(0, 15);

    -- StarterGui.ArceusXV3.MainUI.MainFrame.Tabs.BuiltInHax.HaxPage
    AZY["d0"] = Instance.new("Frame", AZY["ce"]);
    AZY["d0"]["BackgroundColor3"] = Color3.fromRGB(0, 0, 0);
    AZY["d0"]["BackgroundTransparency"] = 1;
    AZY["d0"]["Size"] = UDim2.new(0.6116291880607605, 0, 1.0292569398880005, 0);
    AZY["d0"]["Position"] = UDim2.new(0.3700365424156189, 0, -0.03249453008174896, 0);
    AZY["d0"]["Name"] = [[HaxPage]];

    -- StarterGui.ArceusXV3.MainUI.MainFrame.Tabs.BuiltInHax.HaxPage.TextWs
    AZY["d1"] = Instance.new("TextLabel", AZY["d0"]);
    AZY["d1"]["BackgroundColor3"] = Color3.fromRGB(255, 255, 255);
    AZY["d1"]["FontFace"] = Font.new([[rbxasset://fonts/families/SourceSansPro.json]], Enum.FontWeight.Bold, Enum.FontStyle.Normal);
    AZY["d1"]["TextSize"] = 12;
    AZY["d1"]["TextColor3"] = Color3.fromRGB(255, 255, 255);
    AZY["d1"]["Size"] = UDim2.new(0, 50, 0, 11);
    AZY["d1"]["Text"] = [[Speed]];
    AZY["d1"]["Name"] = [[TextWs]];
    AZY["d1"]["BackgroundTransparency"] = 1;
    AZY["d1"]["Position"] = UDim2.new(0.5411151647567749, 0, 0.8930000066757202, 0);

    -- StarterGui.ArceusXV3.MainUI.MainFrame.Tabs.BuiltInHax.HaxPage.TextJp
    AZY["d2"] = Instance.new("TextLabel", AZY["d0"]);
    AZY["d2"]["BackgroundColor3"] = Color3.fromRGB(255, 255, 255);
    AZY["d2"]["FontFace"] = Font.new([[rbxasset://fonts/families/SourceSansPro.json]], Enum.FontWeight.Bold, Enum.FontStyle.Normal);
    AZY["d2"]["TextSize"] = 12;
    AZY["d2"]["TextColor3"] = Color3.fromRGB(255, 255, 255);
    AZY["d2"]["Size"] = UDim2.new(0, 50, 0, 11);
    AZY["d2"]["Text"] = [[Jump]];
    AZY["d2"]["Name"] = [[TextJp]];
    AZY["d2"]["BackgroundTransparency"] = 1;
    AZY["d2"]["Position"] = UDim2.new(0.7466657161712646, 0, 0.8930000066757202, 0);

    -- StarterGui.ArceusXV3.MainUI.MainFrame.Tabs.BuiltInHax.HaxPage.TextGrav
    AZY["d3"] = Instance.new("TextLabel", AZY["d0"]);
    AZY["d3"]["BackgroundColor3"] = Color3.fromRGB(255, 255, 255);
    AZY["d3"]["FontFace"] = Font.new([[rbxasset://fonts/families/SourceSansPro.json]], Enum.FontWeight.Bold, Enum.FontStyle.Normal);
    AZY["d3"]["TextSize"] = 12;
    AZY["d3"]["TextColor3"] = Color3.fromRGB(255, 255, 255);
    AZY["d3"]["Size"] = UDim2.new(0, 50, 0, 11);
    AZY["d3"]["Text"] = [[Gravity]];
    AZY["d3"]["Name"] = [[TextGrav]];
    AZY["d3"]["BackgroundTransparency"] = 1;
    AZY["d3"]["Position"] = UDim2.new(0.3269999921321869, 0, 0.8930000066757202, 0);

    -- StarterGui.ArceusXV3.MainUI.MainFrame.Tabs.BuiltInHax.HaxPage.ToggleGrav
    AZY["d4"] = Instance.new("TextButton", AZY["d0"]);
    AZY["d4"]["BackgroundColor3"] = Color3.fromRGB(146, 0, 0);
    AZY["d4"]["TextSize"] = 14;
    AZY["d4"]["FontFace"] = Font.new([[rbxasset://fonts/families/SourceSansPro.json]], Enum.FontWeight.Regular, Enum.FontStyle.Normal);
    AZY["d4"]["TextColor3"] = Color3.fromRGB(0, 0, 0);
    AZY["d4"]["Size"] = UDim2.new(0, 15, 0, 15);
    AZY["d4"]["Name"] = [[ToggleGrav]];
    AZY["d4"]["Text"] = [[]];
    AZY["d4"]["Position"] = UDim2.new(0.40253645181655884, 0, 0.801304280757904, 0);

    -- StarterGui.ArceusXV3.MainUI.MainFrame.Tabs.BuiltInHax.HaxPage.ToggleGrav.UICorner
    AZY["d5"] = Instance.new("UICorner", AZY["d4"]);
    AZY["d5"]["CornerRadius"] = UDim.new(100, 100);

    -- StarterGui.ArceusXV3.MainUI.MainFrame.Tabs.BuiltInHax.HaxPage.ToggleGrav.LocalScript
    AZY["d6"] = Instance.new("LocalScript", AZY["d4"]);


    -- StarterGui.ArceusXV3.MainUI.MainFrame.Tabs.BuiltInHax.HaxPage.ToggleJp
    AZY["d7"] = Instance.new("TextButton", AZY["d0"]);
    AZY["d7"]["BackgroundColor3"] = Color3.fromRGB(146, 0, 0);
    AZY["d7"]["TextSize"] = 14;
    AZY["d7"]["FontFace"] = Font.new([[rbxasset://fonts/families/SourceSansPro.json]], Enum.FontWeight.Regular, Enum.FontStyle.Normal);
    AZY["d7"]["TextColor3"] = Color3.fromRGB(0, 0, 0);
    AZY["d7"]["Size"] = UDim2.new(0, 15, 0, 15);
    AZY["d7"]["Name"] = [[ToggleJp]];
    AZY["d7"]["Text"] = [[]];
    AZY["d7"]["Position"] = UDim2.new(0.8222021460533142, 0, 0.801304280757904, 0);

    -- StarterGui.ArceusXV3.MainUI.MainFrame.Tabs.BuiltInHax.HaxPage.ToggleJp.UICorner
    AZY["d8"] = Instance.new("UICorner", AZY["d7"]);
    AZY["d8"]["CornerRadius"] = UDim.new(100, 100);

    -- StarterGui.ArceusXV3.MainUI.MainFrame.Tabs.BuiltInHax.HaxPage.ToggleJp.LocalScript
    AZY["d9"] = Instance.new("LocalScript", AZY["d7"]);


    -- StarterGui.ArceusXV3.MainUI.MainFrame.Tabs.BuiltInHax.HaxPage.ToggleWs
    AZY["da"] = Instance.new("TextButton", AZY["d0"]);
    AZY["da"]["BackgroundColor3"] = Color3.fromRGB(146, 0, 0);
    AZY["da"]["TextSize"] = 14;
    AZY["da"]["FontFace"] = Font.new([[rbxasset://fonts/families/SourceSansPro.json]], Enum.FontWeight.Regular, Enum.FontStyle.Normal);
    AZY["da"]["TextColor3"] = Color3.fromRGB(0, 0, 0);
    AZY["da"]["Size"] = UDim2.new(0, 15, 0, 15);
    AZY["da"]["Name"] = [[ToggleWs]];
    AZY["da"]["Text"] = [[]];
    AZY["da"]["Position"] = UDim2.new(0.6166515946388245, 0, 0.801304280757904, 0);

    -- StarterGui.ArceusXV3.MainUI.MainFrame.Tabs.BuiltInHax.HaxPage.ToggleWs.UICorner
    AZY["db"] = Instance.new("UICorner", AZY["da"]);
    AZY["db"]["CornerRadius"] = UDim.new(100, 100);

    -- StarterGui.ArceusXV3.MainUI.MainFrame.Tabs.BuiltInHax.HaxPage.ToggleWs.LocalScript
    AZY["dc"] = Instance.new("LocalScript", AZY["da"]);


    -- StarterGui.ArceusXV3.MainUI.MainFrame.Tabs.BuiltInHax.HaxPage.WsS
    AZY["dd"] = Instance.new("ImageButton", AZY["d0"]);
    AZY["dd"]["Active"] = false;
    AZY["dd"]["BorderSizePixel"] = 0;
    AZY["dd"]["SliceCenter"] = Rect.new(100, 100, 100, 100);
    AZY["dd"]["ScaleType"] = Enum.ScaleType.Slice;
    AZY["dd"]["SliceScale"] = 0.11999999731779099;
    AZY["dd"]["ImageTransparency"] = 1;
    AZY["dd"]["BackgroundColor3"] = Color3.fromRGB(22, 22, 22);
    AZY["dd"]["ImageColor3"] = Color3.fromRGB(32, 32, 32);
    AZY["dd"]["Selectable"] = false;
    AZY["dd"]["AnchorPoint"] = Vector2.new(0.5, 0.5);
    AZY["dd"]["Image"] = [[rbxassetid://3570695787]];
    AZY["dd"]["Size"] = UDim2.new(0, 119, 0, 31);
    AZY["dd"]["Name"] = [[WsS]];
    AZY["dd"]["Rotation"] = -90;
    AZY["dd"]["Position"] = UDim2.new(0.6499999761581421, 0, 0.4399999976158142, 0);
    AZY["dd"]["BackgroundTransparency"] = 1;

    -- StarterGui.ArceusXV3.MainUI.MainFrame.Tabs.BuiltInHax.HaxPage.WsS.SliderButton
    AZY["de"] = Instance.new("ImageLabel", AZY["dd"]);
    AZY["de"]["SliceCenter"] = Rect.new(100, 100, 100, 100);
    AZY["de"]["ScaleType"] = Enum.ScaleType.Slice;
    AZY["de"]["BackgroundColor3"] = Color3.fromRGB(71, 71, 71);
    AZY["de"]["ImageColor3"] = Color3.fromRGB(146, 0, 0);
    AZY["de"]["SliceScale"] = 0.11999999731779099;
    AZY["de"]["Selectable"] = true;
    AZY["de"]["Image"] = [[rbxassetid://3570695787]];
    AZY["de"]["Size"] = UDim2.new(0, 25, 1, 0);
    AZY["de"]["Active"] = true;
    AZY["de"]["Name"] = [[SliderButton]];
    AZY["de"]["BackgroundTransparency"] = 1;

    -- StarterGui.ArceusXV3.MainUI.MainFrame.Tabs.BuiltInHax.HaxPage.WsS.SliderButton.LocalScript
    AZY["df"] = Instance.new("LocalScript", AZY["de"]);


    -- StarterGui.ArceusXV3.MainUI.MainFrame.Tabs.BuiltInHax.HaxPage.WsS.Border
    AZY["e0"] = Instance.new("ImageLabel", AZY["dd"]);
    AZY["e0"]["ZIndex"] = -1;
    AZY["e0"]["SliceCenter"] = Rect.new(100, 100, 100, 100);
    AZY["e0"]["ScaleType"] = Enum.ScaleType.Slice;
    AZY["e0"]["BackgroundColor3"] = Color3.fromRGB(62, 62, 62);
    AZY["e0"]["ImageColor3"] = Color3.fromRGB(71, 71, 71);
    AZY["e0"]["SliceScale"] = 0.23999999463558197;
    AZY["e0"]["ImageTransparency"] = 1;
    AZY["e0"]["AnchorPoint"] = Vector2.new(0.5, 0.5);
    AZY["e0"]["Image"] = [[rbxassetid://3570695787]];
    AZY["e0"]["Size"] = UDim2.new(1, 12, 1, 12);
    AZY["e0"]["Name"] = [[Border]];
    AZY["e0"]["BackgroundTransparency"] = 0.6000000238418579;
    AZY["e0"]["Position"] = UDim2.new(0.5, 0, 0.5, 0);

    -- StarterGui.ArceusXV3.MainUI.MainFrame.Tabs.BuiltInHax.HaxPage.WsS.Border.UICorner
    AZY["e1"] = Instance.new("UICorner", AZY["e0"]);
    AZY["e1"]["CornerRadius"] = UDim.new(0, 12);

    -- StarterGui.ArceusXV3.MainUI.MainFrame.Tabs.BuiltInHax.HaxPage.WsS.StripedPattern
    AZY["e2"] = Instance.new("ImageLabel", AZY["dd"]);
    AZY["e2"]["BorderSizePixel"] = 0;
    AZY["e2"]["ScaleType"] = Enum.ScaleType.Tile;
    AZY["e2"]["BackgroundColor3"] = Color3.fromRGB(255, 255, 255);
    AZY["e2"]["ImageColor3"] = Color3.fromRGB(32, 32, 32);
    AZY["e2"]["ImageTransparency"] = 1;
    AZY["e2"]["AnchorPoint"] = Vector2.new(0.5, 0);
    AZY["e2"]["Image"] = [[rbxassetid://4925116997]];
    AZY["e2"]["TileSize"] = UDim2.new(0, 25, 1, 0);
    AZY["e2"]["Size"] = UDim2.new(1, -25, 1, 0);
    AZY["e2"]["Name"] = [[StripedPattern]];
    AZY["e2"]["BackgroundTransparency"] = 1;
    AZY["e2"]["Position"] = UDim2.new(0.5, 0, 0, 0);

    -- StarterGui.ArceusXV3.MainUI.MainFrame.Tabs.BuiltInHax.HaxPage.WsS.StripedPattern.UIGradient
    AZY["e3"] = Instance.new("UIGradient", AZY["e2"]);
    AZY["e3"]["Rotation"] = 90;
    AZY["e3"]["Color"] = ColorSequence.new{ColorSequenceKeypoint.new(0.000, Color3.fromRGB(255, 255, 255)),ColorSequenceKeypoint.new(1.000, Color3.fromRGB(0, 0, 0))};

    -- StarterGui.ArceusXV3.MainUI.MainFrame.Tabs.BuiltInHax.HaxPage.WsS.ImageLabel
    AZY["e4"] = Instance.new("ImageLabel", AZY["dd"]);
    AZY["e4"]["BackgroundColor3"] = Color3.fromRGB(255, 255, 255);
    AZY["e4"]["Image"] = [[rbxassetid://12572149271]];
    AZY["e4"]["Size"] = UDim2.new(0, 35, 0, 35);
    AZY["e4"]["Rotation"] = 90;
    AZY["e4"]["BackgroundTransparency"] = 1;
    AZY["e4"]["Position"] = UDim2.new(-0.017000000923871994, 0, -0.10000000149011612, 0);

    -- StarterGui.ArceusXV3.MainUI.MainFrame.Tabs.BuiltInHax.HaxPage.WsS.TextLabel
    AZY["e5"] = Instance.new("TextBox", AZY["dd"]);
    AZY["e5"]["CursorPosition"] = -1;
    AZY["e5"]["ZIndex"] = 2;
    AZY["e5"]["TextSize"] = 13;
    AZY["e5"]["BackgroundColor3"] = Color3.fromRGB(255, 255, 255);
    AZY["e5"]["TextColor3"] = Color3.fromRGB(255, 255, 255);
    AZY["e5"]["FontFace"] = Font.new([[rbxasset://fonts/families/SourceSansPro.json]], Enum.FontWeight.Bold, Enum.FontStyle.Normal);
    AZY["e5"]["AnchorPoint"] = Vector2.new(1, 0);
    AZY["e5"]["BackgroundTransparency"] = 1;
    AZY["e5"]["Size"] = UDim2.new(0, 50, 1, 0);
    AZY["e5"]["Text"] = [[0%]];
    AZY["e5"]["Position"] = UDim2.new(0, 137, 0, 0);
    AZY["e5"]["Rotation"] = 90;
    AZY["e5"]["Name"] = [[TextLabel]];

    -- StarterGui.ArceusXV3.MainUI.MainFrame.Tabs.BuiltInHax.HaxPage.JpS
    AZY["e6"] = Instance.new("ImageButton", AZY["d0"]);
    AZY["e6"]["Active"] = false;
    AZY["e6"]["BorderSizePixel"] = 0;
    AZY["e6"]["SliceCenter"] = Rect.new(100, 100, 100, 100);
    AZY["e6"]["ScaleType"] = Enum.ScaleType.Slice;
    AZY["e6"]["SliceScale"] = 0.11999999731779099;
    AZY["e6"]["ImageTransparency"] = 1;
    AZY["e6"]["BackgroundColor3"] = Color3.fromRGB(22, 22, 22);
    AZY["e6"]["ImageColor3"] = Color3.fromRGB(32, 32, 32);
    AZY["e6"]["Selectable"] = false;
    AZY["e6"]["AnchorPoint"] = Vector2.new(0.5, 0.5);
    AZY["e6"]["Image"] = [[rbxassetid://3570695787]];
    AZY["e6"]["Size"] = UDim2.new(0, 119, 0, 31);
    AZY["e6"]["Name"] = [[JpS]];
    AZY["e6"]["Rotation"] = -90;
    AZY["e6"]["Position"] = UDim2.new(0.8600000143051147, 0, 0.4399999976158142, 0);
    AZY["e6"]["BackgroundTransparency"] = 1;

    -- StarterGui.ArceusXV3.MainUI.MainFrame.Tabs.BuiltInHax.HaxPage.JpS.SliderButton
    AZY["e7"] = Instance.new("ImageLabel", AZY["e6"]);
    AZY["e7"]["SliceCenter"] = Rect.new(100, 100, 100, 100);
    AZY["e7"]["ScaleType"] = Enum.ScaleType.Slice;
    AZY["e7"]["BackgroundColor3"] = Color3.fromRGB(71, 71, 71);
    AZY["e7"]["ImageColor3"] = Color3.fromRGB(146, 0, 0);
    AZY["e7"]["SliceScale"] = 0.11999999731779099;
    AZY["e7"]["Selectable"] = true;
    AZY["e7"]["Image"] = [[rbxassetid://3570695787]];
    AZY["e7"]["Size"] = UDim2.new(0, 25, 1, 0);
    AZY["e7"]["Active"] = true;
    AZY["e7"]["Name"] = [[SliderButton]];
    AZY["e7"]["BackgroundTransparency"] = 1;

    -- StarterGui.ArceusXV3.MainUI.MainFrame.Tabs.BuiltInHax.HaxPage.JpS.SliderButton.LocalScript
    AZY["e8"] = Instance.new("LocalScript", AZY["e7"]);


    -- StarterGui.ArceusXV3.MainUI.MainFrame.Tabs.BuiltInHax.HaxPage.JpS.Border
    AZY["e9"] = Instance.new("ImageLabel", AZY["e6"]);
    AZY["e9"]["ZIndex"] = -1;
    AZY["e9"]["SliceCenter"] = Rect.new(100, 100, 100, 100);
    AZY["e9"]["ScaleType"] = Enum.ScaleType.Slice;
    AZY["e9"]["BackgroundColor3"] = Color3.fromRGB(62, 62, 62);
    AZY["e9"]["ImageColor3"] = Color3.fromRGB(71, 71, 71);
    AZY["e9"]["SliceScale"] = 0.23999999463558197;
    AZY["e9"]["ImageTransparency"] = 1;
    AZY["e9"]["AnchorPoint"] = Vector2.new(0.5, 0.5);
    AZY["e9"]["Image"] = [[rbxassetid://3570695787]];
    AZY["e9"]["Size"] = UDim2.new(1, 12, 1, 12);
    AZY["e9"]["Name"] = [[Border]];
    AZY["e9"]["BackgroundTransparency"] = 0.6000000238418579;
    AZY["e9"]["Position"] = UDim2.new(0.5, 0, 0.5, 0);

    -- StarterGui.ArceusXV3.MainUI.MainFrame.Tabs.BuiltInHax.HaxPage.JpS.Border.UICorner
    AZY["ea"] = Instance.new("UICorner", AZY["e9"]);
    AZY["ea"]["CornerRadius"] = UDim.new(0, 12);

    -- StarterGui.ArceusXV3.MainUI.MainFrame.Tabs.BuiltInHax.HaxPage.JpS.StripedPattern
    AZY["eb"] = Instance.new("ImageLabel", AZY["e6"]);
    AZY["eb"]["BorderSizePixel"] = 0;
    AZY["eb"]["ScaleType"] = Enum.ScaleType.Tile;
    AZY["eb"]["BackgroundColor3"] = Color3.fromRGB(255, 255, 255);
    AZY["eb"]["ImageColor3"] = Color3.fromRGB(32, 32, 32);
    AZY["eb"]["ImageTransparency"] = 1;
    AZY["eb"]["AnchorPoint"] = Vector2.new(0.5, 0);
    AZY["eb"]["Image"] = [[rbxassetid://4925116997]];
    AZY["eb"]["TileSize"] = UDim2.new(0, 25, 1, 0);
    AZY["eb"]["Size"] = UDim2.new(1, -25, 1, 0);
    AZY["eb"]["Name"] = [[StripedPattern]];
    AZY["eb"]["BackgroundTransparency"] = 1;
    AZY["eb"]["Position"] = UDim2.new(0.5, 0, 0, 0);

    -- StarterGui.ArceusXV3.MainUI.MainFrame.Tabs.BuiltInHax.HaxPage.JpS.StripedPattern.UIGradient
    AZY["ec"] = Instance.new("UIGradient", AZY["eb"]);
    AZY["ec"]["Rotation"] = 90;
    AZY["ec"]["Color"] = ColorSequence.new{ColorSequenceKeypoint.new(0.000, Color3.fromRGB(255, 255, 255)),ColorSequenceKeypoint.new(1.000, Color3.fromRGB(0, 0, 0))};

    -- StarterGui.ArceusXV3.MainUI.MainFrame.Tabs.BuiltInHax.HaxPage.JpS.ImageLabel
    AZY["ed"] = Instance.new("ImageLabel", AZY["e6"]);
    AZY["ed"]["BackgroundColor3"] = Color3.fromRGB(255, 255, 255);
    AZY["ed"]["Image"] = [[rbxassetid://12582573514]];
    AZY["ed"]["Size"] = UDim2.new(0, 35, 0, 35);
    AZY["ed"]["Rotation"] = 90;
    AZY["ed"]["BackgroundTransparency"] = 1;
    AZY["ed"]["Position"] = UDim2.new(-0.017000000923871994, 0, -0.10000000149011612, 0);

    -- StarterGui.ArceusXV3.MainUI.MainFrame.Tabs.BuiltInHax.HaxPage.JpS.TextLabel
    AZY["ee"] = Instance.new("TextBox", AZY["e6"]);
    AZY["ee"]["ZIndex"] = 2;
    AZY["ee"]["TextSize"] = 13;
    AZY["ee"]["BackgroundColor3"] = Color3.fromRGB(255, 255, 255);
    AZY["ee"]["TextColor3"] = Color3.fromRGB(255, 255, 255);
    AZY["ee"]["FontFace"] = Font.new([[rbxasset://fonts/families/SourceSansPro.json]], Enum.FontWeight.Bold, Enum.FontStyle.Normal);
    AZY["ee"]["AnchorPoint"] = Vector2.new(1, 0);
    AZY["ee"]["BackgroundTransparency"] = 1;
    AZY["ee"]["Size"] = UDim2.new(0, 50, 1, 0);
    AZY["ee"]["Text"] = [[0%]];
    AZY["ee"]["Position"] = UDim2.new(0, 137, 0, 0);
    AZY["ee"]["Rotation"] = 90;
    AZY["ee"]["Name"] = [[TextLabel]];

    -- StarterGui.ArceusXV3.MainUI.MainFrame.Tabs.BuiltInHax.HaxPage.GravS
    AZY["ef"] = Instance.new("ImageButton", AZY["d0"]);
    AZY["ef"]["Active"] = false;
    AZY["ef"]["BorderSizePixel"] = 0;
    AZY["ef"]["SliceCenter"] = Rect.new(100, 100, 100, 100);
    AZY["ef"]["ScaleType"] = Enum.ScaleType.Slice;
    AZY["ef"]["SliceScale"] = 0.11999999731779099;
    AZY["ef"]["ImageTransparency"] = 1;
    AZY["ef"]["BackgroundColor3"] = Color3.fromRGB(22, 22, 22);
    AZY["ef"]["ImageColor3"] = Color3.fromRGB(32, 32, 32);
    AZY["ef"]["Selectable"] = false;
    AZY["ef"]["AnchorPoint"] = Vector2.new(0.5, 0.5);
    AZY["ef"]["Image"] = [[rbxassetid://3570695787]];
    AZY["ef"]["Size"] = UDim2.new(0, 119, 0, 31);
    AZY["ef"]["Name"] = [[GravS]];
    AZY["ef"]["Rotation"] = -90;
    AZY["ef"]["Position"] = UDim2.new(0.4359999895095825, 0, 0.4399999976158142, 0);
    AZY["ef"]["BackgroundTransparency"] = 1;

    -- StarterGui.ArceusXV3.MainUI.MainFrame.Tabs.BuiltInHax.HaxPage.GravS.SliderButton
    AZY["f0"] = Instance.new("ImageLabel", AZY["ef"]);
    AZY["f0"]["SliceCenter"] = Rect.new(100, 100, 100, 100);
    AZY["f0"]["ScaleType"] = Enum.ScaleType.Slice;
    AZY["f0"]["BackgroundColor3"] = Color3.fromRGB(71, 71, 71);
    AZY["f0"]["ImageColor3"] = Color3.fromRGB(146, 0, 0);
    AZY["f0"]["SliceScale"] = 0.11999999731779099;
    AZY["f0"]["Selectable"] = true;
    AZY["f0"]["Image"] = [[rbxassetid://3570695787]];
    AZY["f0"]["Size"] = UDim2.new(0, 25, 1, 0);
    AZY["f0"]["Active"] = true;
    AZY["f0"]["Name"] = [[SliderButton]];
    AZY["f0"]["BackgroundTransparency"] = 1;

    -- StarterGui.ArceusXV3.MainUI.MainFrame.Tabs.BuiltInHax.HaxPage.GravS.SliderButton.LocalScript
    AZY["f1"] = Instance.new("LocalScript", AZY["f0"]);


    -- StarterGui.ArceusXV3.MainUI.MainFrame.Tabs.BuiltInHax.HaxPage.GravS.Border
    AZY["f2"] = Instance.new("ImageLabel", AZY["ef"]);
    AZY["f2"]["ZIndex"] = -1;
    AZY["f2"]["SliceCenter"] = Rect.new(100, 100, 100, 100);
    AZY["f2"]["ScaleType"] = Enum.ScaleType.Slice;
    AZY["f2"]["BackgroundColor3"] = Color3.fromRGB(62, 62, 62);
    AZY["f2"]["ImageColor3"] = Color3.fromRGB(71, 71, 71);
    AZY["f2"]["SliceScale"] = 0.23999999463558197;
    AZY["f2"]["ImageTransparency"] = 1;
    AZY["f2"]["AnchorPoint"] = Vector2.new(0.5, 0.5);
    AZY["f2"]["Image"] = [[rbxassetid://3570695787]];
    AZY["f2"]["Size"] = UDim2.new(1, 12, 1, 12);
    AZY["f2"]["Name"] = [[Border]];
    AZY["f2"]["BackgroundTransparency"] = 0.6000000238418579;
    AZY["f2"]["Position"] = UDim2.new(0.5, 0, 0.5, 0);

    -- StarterGui.ArceusXV3.MainUI.MainFrame.Tabs.BuiltInHax.HaxPage.GravS.Border.UICorner
    AZY["f3"] = Instance.new("UICorner", AZY["f2"]);
    AZY["f3"]["CornerRadius"] = UDim.new(0, 12);

    -- StarterGui.ArceusXV3.MainUI.MainFrame.Tabs.BuiltInHax.HaxPage.GravS.StripedPattern
    AZY["f4"] = Instance.new("ImageLabel", AZY["ef"]);
    AZY["f4"]["BorderSizePixel"] = 0;
    AZY["f4"]["ScaleType"] = Enum.ScaleType.Tile;
    AZY["f4"]["BackgroundColor3"] = Color3.fromRGB(255, 255, 255);
    AZY["f4"]["ImageColor3"] = Color3.fromRGB(32, 32, 32);
    AZY["f4"]["ImageTransparency"] = 1;
    AZY["f4"]["AnchorPoint"] = Vector2.new(0.5, 0);
    AZY["f4"]["Image"] = [[rbxassetid://4925116997]];
    AZY["f4"]["TileSize"] = UDim2.new(0, 25, 1, 0);
    AZY["f4"]["Size"] = UDim2.new(1, -25, 1, 0);
    AZY["f4"]["Name"] = [[StripedPattern]];
    AZY["f4"]["BackgroundTransparency"] = 1;
    AZY["f4"]["Position"] = UDim2.new(0.5, 0, 0, 0);

    -- StarterGui.ArceusXV3.MainUI.MainFrame.Tabs.BuiltInHax.HaxPage.GravS.StripedPattern.UIGradient
    AZY["f5"] = Instance.new("UIGradient", AZY["f4"]);
    AZY["f5"]["Rotation"] = 90;
    AZY["f5"]["Color"] = ColorSequence.new{ColorSequenceKeypoint.new(0.000, Color3.fromRGB(255, 255, 255)),ColorSequenceKeypoint.new(1.000, Color3.fromRGB(0, 0, 0))};

    -- StarterGui.ArceusXV3.MainUI.MainFrame.Tabs.BuiltInHax.HaxPage.GravS.ImageLabel
    AZY["f6"] = Instance.new("ImageLabel", AZY["ef"]);
    AZY["f6"]["BackgroundColor3"] = Color3.fromRGB(255, 255, 255);
    AZY["f6"]["Image"] = [[rbxassetid://12582575947]];
    AZY["f6"]["Size"] = UDim2.new(0, 35, 0, 35);
    AZY["f6"]["Rotation"] = 90;
    AZY["f6"]["BackgroundTransparency"] = 1;
    AZY["f6"]["Position"] = UDim2.new(-0.017000000923871994, 0, -0.10000000149011612, 0);

    -- StarterGui.ArceusXV3.MainUI.MainFrame.Tabs.BuiltInHax.HaxPage.GravS.TextLabel
    AZY["f7"] = Instance.new("TextBox", AZY["ef"]);
    AZY["f7"]["ZIndex"] = 2;
    AZY["f7"]["TextSize"] = 13;
    AZY["f7"]["BackgroundColor3"] = Color3.fromRGB(255, 255, 255);
    AZY["f7"]["TextColor3"] = Color3.fromRGB(255, 255, 255);
    AZY["f7"]["FontFace"] = Font.new([[rbxasset://fonts/families/SourceSansPro.json]], Enum.FontWeight.Bold, Enum.FontStyle.Normal);
    AZY["f7"]["AnchorPoint"] = Vector2.new(1, 0);
    AZY["f7"]["BackgroundTransparency"] = 1;
    AZY["f7"]["Size"] = UDim2.new(0, 50, 1, 0);
    AZY["f7"]["Text"] = [[0%]];
    AZY["f7"]["Position"] = UDim2.new(0, 137, 0, 0);
    AZY["f7"]["Rotation"] = 90;
    AZY["f7"]["Name"] = [[TextLabel]];

    -- StarterGui.ArceusXV3.MainUI.MainFrame.Tabs.BuiltInHax.HaxPage.Grav
    AZY["f8"] = Instance.new("BoolValue", AZY["d0"]);
    AZY["f8"]["Name"] = [[Grav]];

    -- StarterGui.ArceusXV3.MainUI.MainFrame.Tabs.BuiltInHax.HaxPage.Jp
    AZY["f9"] = Instance.new("BoolValue", AZY["d0"]);
    AZY["f9"]["Name"] = [[Jp]];

    -- StarterGui.ArceusXV3.MainUI.MainFrame.Tabs.BuiltInHax.HaxPage.Ws
    AZY["fa"] = Instance.new("BoolValue", AZY["d0"]);
    AZY["fa"]["Name"] = [[Ws]];

    -- StarterGui.ArceusXV3.MainUI.MainFrame.Tabs.BuiltInHax.Scripts
    AZY["fb"] = Instance.new("Folder", AZY["ce"]);
    AZY["fb"]["Name"] = [[Scripts]];

    -- StarterGui.ArceusXV3.MainUI.MainFrame.Tabs.BuiltInHax.Scripts.Aimbot
    AZY["fc"] = Instance.new("TextButton", AZY["fb"]);
    AZY["fc"]["TextWrapped"] = true;
    AZY["fc"]["TextXAlignment"] = Enum.TextXAlignment.Left;
    AZY["fc"]["BackgroundColor3"] = Color3.fromRGB(255, 0, 0);
    AZY["fc"]["TextSize"] = 13;
    AZY["fc"]["FontFace"] = Font.new([[rbxasset://fonts/families/SourceSansPro.json]], Enum.FontWeight.Bold, Enum.FontStyle.Normal);
    AZY["fc"]["TextColor3"] = Color3.fromRGB(255, 255, 255);
    AZY["fc"]["Size"] = UDim2.new(0.2280000001192093, 0, 0.09600000083446503, 0);
    AZY["fc"]["Name"] = [[Aimbot]];
    AZY["fc"]["Text"] = [[       AimBot]];
    AZY["fc"]["Position"] = UDim2.new(0.030552715063095093, 0, 0.3302992284297943, 0);

    -- StarterGui.ArceusXV3.MainUI.MainFrame.Tabs.BuiltInHax.Scripts.Aimbot.UICorner
    AZY["fd"] = Instance.new("UICorner", AZY["fc"]);
    AZY["fd"]["CornerRadius"] = UDim.new(0, 5);

    -- StarterGui.ArceusXV3.MainUI.MainFrame.Tabs.BuiltInHax.Scripts.Aimbot.LocalScript
    AZY["fe"] = Instance.new("LocalScript", AZY["fc"]);


    -- StarterGui.ArceusXV3.MainUI.MainFrame.Tabs.BuiltInHax.Scripts.Aimbot.Info
    AZY["ff"] = Instance.new("ImageLabel", AZY["fc"]);
    AZY["ff"]["BackgroundColor3"] = Color3.fromRGB(255, 255, 255);
    AZY["ff"]["Image"] = [[rbxassetid://12585776892]];
    AZY["ff"]["Size"] = UDim2.new(0, 16, 0, 16);
    AZY["ff"]["Name"] = [[Info]];
    AZY["ff"]["BackgroundTransparency"] = 1;
    AZY["ff"]["Position"] = UDim2.new(0.7910000085830688, 0, 0.09000000357627869, 0);

    -- StarterGui.ArceusXV3.MainUI.MainFrame.Tabs.BuiltInHax.Scripts.Btools
    AZY["100"] = Instance.new("TextButton", AZY["fb"]);
    AZY["100"]["TextWrapped"] = true;
    AZY["100"]["TextXAlignment"] = Enum.TextXAlignment.Left;
    AZY["100"]["BackgroundColor3"] = Color3.fromRGB(255, 0, 0);
    AZY["100"]["TextSize"] = 13;
    AZY["100"]["FontFace"] = Font.new([[rbxasset://fonts/families/SourceSansPro.json]], Enum.FontWeight.Bold, Enum.FontStyle.Normal);
    AZY["100"]["TextColor3"] = Color3.fromRGB(255, 255, 255);
    AZY["100"]["Size"] = UDim2.new(0.2280000001192093, 0, 0.09600000083446503, 0);
    AZY["100"]["Name"] = [[Btools]];
    AZY["100"]["Text"] = [[         BTools]];
    AZY["100"]["Position"] = UDim2.new(0.2924708425998688, 0, 0.18550994992256165, 0);

    -- StarterGui.ArceusXV3.MainUI.MainFrame.Tabs.BuiltInHax.Scripts.Btools.UICorner
    AZY["101"] = Instance.new("UICorner", AZY["100"]);
    AZY["101"]["CornerRadius"] = UDim.new(0, 5);

    -- StarterGui.ArceusXV3.MainUI.MainFrame.Tabs.BuiltInHax.Scripts.Btools.LocalScript
    AZY["102"] = Instance.new("LocalScript", AZY["100"]);


    -- StarterGui.ArceusXV3.MainUI.MainFrame.Tabs.BuiltInHax.Scripts.Btools.Info
    AZY["103"] = Instance.new("ImageLabel", AZY["100"]);
    AZY["103"]["BackgroundColor3"] = Color3.fromRGB(255, 255, 255);
    AZY["103"]["Image"] = [[rbxassetid://12585776892]];
    AZY["103"]["Size"] = UDim2.new(0, 16, 0, 16);
    AZY["103"]["Name"] = [[Info]];
    AZY["103"]["BackgroundTransparency"] = 1;
    AZY["103"]["Position"] = UDim2.new(0.7910000085830688, 0, 0.09000000357627869, 0);

    -- StarterGui.ArceusXV3.MainUI.MainFrame.Tabs.BuiltInHax.Scripts.Dex
    AZY["104"] = Instance.new("TextButton", AZY["fb"]);
    AZY["104"]["TextWrapped"] = true;
    AZY["104"]["TextXAlignment"] = Enum.TextXAlignment.Left;
    AZY["104"]["BackgroundColor3"] = Color3.fromRGB(255, 0, 0);
    AZY["104"]["TextSize"] = 13;
    AZY["104"]["FontFace"] = Font.new([[rbxasset://fonts/families/SourceSansPro.json]], Enum.FontWeight.Bold, Enum.FontStyle.Normal);
    AZY["104"]["TextColor3"] = Color3.fromRGB(255, 255, 255);
    AZY["104"]["Size"] = UDim2.new(0.2280000001192093, 0, 0.09600000083446503, 0);
    AZY["104"]["Name"] = [[Dex]];
    AZY["104"]["Text"] = [[  DEX Explorer]];
    AZY["104"]["Position"] = UDim2.new(0.2938356399536133, 0, 0.04143177345395088, 0);

    -- StarterGui.ArceusXV3.MainUI.MainFrame.Tabs.BuiltInHax.Scripts.Dex.UICorner
    AZY["105"] = Instance.new("UICorner", AZY["104"]);
    AZY["105"]["CornerRadius"] = UDim.new(0, 5);

    -- StarterGui.ArceusXV3.MainUI.MainFrame.Tabs.BuiltInHax.Scripts.Dex.LocalScript
    AZY["106"] = Instance.new("LocalScript", AZY["104"]);


    -- StarterGui.ArceusXV3.MainUI.MainFrame.Tabs.BuiltInHax.Scripts.Dex.Info
    AZY["107"] = Instance.new("ImageLabel", AZY["104"]);
    AZY["107"]["BackgroundColor3"] = Color3.fromRGB(255, 255, 255);
    AZY["107"]["Image"] = [[rbxassetid://12585776892]];
    AZY["107"]["Size"] = UDim2.new(0, 16, 0, 16);
    AZY["107"]["Name"] = [[Info]];
    AZY["107"]["BackgroundTransparency"] = 1;
    AZY["107"]["Position"] = UDim2.new(0.7910000085830688, 0, 0.09000000357627869, 0);

    -- StarterGui.ArceusXV3.MainUI.MainFrame.Tabs.BuiltInHax.Scripts.FatesESP
    AZY["108"] = Instance.new("TextButton", AZY["fb"]);
    AZY["108"]["TextWrapped"] = true;
    AZY["108"]["TextXAlignment"] = Enum.TextXAlignment.Left;
    AZY["108"]["BackgroundColor3"] = Color3.fromRGB(255, 0, 0);
    AZY["108"]["TextSize"] = 13;
    AZY["108"]["FontFace"] = Font.new([[rbxasset://fonts/families/SourceSansPro.json]], Enum.FontWeight.Bold, Enum.FontStyle.Normal);
    AZY["108"]["TextColor3"] = Color3.fromRGB(255, 255, 255);
    AZY["108"]["Size"] = UDim2.new(0.2280000001192093, 0, 0.09600000083446503, 0);
    AZY["108"]["Name"] = [[FatesESP]];
    AZY["108"]["Text"] = [[      Fates ESP]];
    AZY["108"]["Position"] = UDim2.new(0.0331718735396862, 0, 0.18866735696792603, 0);

    -- StarterGui.ArceusXV3.MainUI.MainFrame.Tabs.BuiltInHax.Scripts.FatesESP.UICorner
    AZY["109"] = Instance.new("UICorner", AZY["108"]);
    AZY["109"]["CornerRadius"] = UDim.new(0, 5);

    -- StarterGui.ArceusXV3.MainUI.MainFrame.Tabs.BuiltInHax.Scripts.FatesESP.LocalScript
    AZY["10a"] = Instance.new("LocalScript", AZY["108"]);


    -- StarterGui.ArceusXV3.MainUI.MainFrame.Tabs.BuiltInHax.Scripts.FatesESP.Info
    AZY["10b"] = Instance.new("ImageLabel", AZY["108"]);
    AZY["10b"]["BackgroundColor3"] = Color3.fromRGB(255, 255, 255);
    AZY["10b"]["Image"] = [[rbxassetid://12585776892]];
    AZY["10b"]["Size"] = UDim2.new(0, 16, 0, 16);
    AZY["10b"]["Name"] = [[Info]];
    AZY["10b"]["BackgroundTransparency"] = 1;
    AZY["10b"]["Position"] = UDim2.new(0.7910000085830688, 0, 0.09000000357627869, 0);

    -- StarterGui.ArceusXV3.MainUI.MainFrame.Tabs.BuiltInHax.Scripts.Fly
    AZY["10c"] = Instance.new("TextButton", AZY["fb"]);
    AZY["10c"]["TextWrapped"] = true;
    AZY["10c"]["TextXAlignment"] = Enum.TextXAlignment.Left;
    AZY["10c"]["BackgroundColor3"] = Color3.fromRGB(255, 0, 0);
    AZY["10c"]["TextSize"] = 13;
    AZY["10c"]["FontFace"] = Font.new([[rbxasset://fonts/families/SourceSansPro.json]], Enum.FontWeight.Bold, Enum.FontStyle.Normal);
    AZY["10c"]["TextColor3"] = Color3.fromRGB(255, 255, 255);
    AZY["10c"]["Size"] = UDim2.new(0.2280000001192093, 0, 0.09600000083446503, 0);
    AZY["10c"]["Name"] = [[Fly]];
    AZY["10c"]["Text"] = [[           Fly]];
    AZY["10c"]["Position"] = UDim2.new(0.28985166549682617, 0, 0.3375365436077118, 0);

    -- StarterGui.ArceusXV3.MainUI.MainFrame.Tabs.BuiltInHax.Scripts.Fly.UICorner
    AZY["10d"] = Instance.new("UICorner", AZY["10c"]);
    AZY["10d"]["CornerRadius"] = UDim.new(0, 5);

    -- StarterGui.ArceusXV3.MainUI.MainFrame.Tabs.BuiltInHax.Scripts.Fly.LocalScript
    AZY["10e"] = Instance.new("LocalScript", AZY["10c"]);


    -- StarterGui.ArceusXV3.MainUI.MainFrame.Tabs.BuiltInHax.Scripts.Fly.Info
    AZY["10f"] = Instance.new("ImageLabel", AZY["10c"]);
    AZY["10f"]["BackgroundColor3"] = Color3.fromRGB(255, 255, 255);
    AZY["10f"]["Image"] = [[rbxassetid://12585776892]];
    AZY["10f"]["Size"] = UDim2.new(0, 16, 0, 16);
    AZY["10f"]["Name"] = [[Info]];
    AZY["10f"]["BackgroundTransparency"] = 1;
    AZY["10f"]["Position"] = UDim2.new(0.7910000085830688, 0, 0.09000000357627869, 0);

    -- StarterGui.ArceusXV3.MainUI.MainFrame.Tabs.BuiltInHax.Scripts.IY
    AZY["110"] = Instance.new("TextButton", AZY["fb"]);
    AZY["110"]["TextWrapped"] = true;
    AZY["110"]["TextXAlignment"] = Enum.TextXAlignment.Left;
    AZY["110"]["BackgroundColor3"] = Color3.fromRGB(255, 0, 0);
    AZY["110"]["TextSize"] = 13;
    AZY["110"]["FontFace"] = Font.new([[rbxasset://fonts/families/SourceSansPro.json]], Enum.FontWeight.Bold, Enum.FontStyle.Normal);
    AZY["110"]["TextColor3"] = Color3.fromRGB(255, 255, 255);
    AZY["110"]["Size"] = UDim2.new(0.22804169356822968, 0, 0.0958060473203659, 0);
    AZY["110"]["Name"] = [[IY]];
    AZY["110"]["Text"] = [[  Infinite Yield]];
    AZY["110"]["Position"] = UDim2.new(0.03485134616494179, 0, 0.04589534550905228, 0);

    -- StarterGui.ArceusXV3.MainUI.MainFrame.Tabs.BuiltInHax.Scripts.IY.UICorner
    AZY["111"] = Instance.new("UICorner", AZY["110"]);
    AZY["111"]["CornerRadius"] = UDim.new(0, 5);

    -- StarterGui.ArceusXV3.MainUI.MainFrame.Tabs.BuiltInHax.Scripts.IY.LocalScript
    AZY["112"] = Instance.new("LocalScript", AZY["110"]);


    -- StarterGui.ArceusXV3.MainUI.MainFrame.Tabs.BuiltInHax.Scripts.IY.Info
    AZY["113"] = Instance.new("ImageLabel", AZY["110"]);
    AZY["113"]["BackgroundColor3"] = Color3.fromRGB(255, 255, 255);
    AZY["113"]["Image"] = [[rbxassetid://12585776892]];
    AZY["113"]["Size"] = UDim2.new(0, 16, 0, 16);
    AZY["113"]["Name"] = [[Info]];
    AZY["113"]["BackgroundTransparency"] = 1;
    AZY["113"]["Position"] = UDim2.new(0.7910000085830688, 0, 0.09000000357627869, 0);

    -- StarterGui.ArceusXV3.MainUI.MainFrame.Tabs.BuiltInHax.Scripts.PwnHub
    AZY["114"] = Instance.new("TextButton", AZY["fb"]);
    AZY["114"]["TextWrapped"] = true;
    AZY["114"]["TextXAlignment"] = Enum.TextXAlignment.Left;
    AZY["114"]["BackgroundColor3"] = Color3.fromRGB(255, 0, 0);
    AZY["114"]["TextSize"] = 13;
    AZY["114"]["FontFace"] = Font.new([[rbxasset://fonts/families/SourceSansPro.json]], Enum.FontWeight.Bold, Enum.FontStyle.Normal);
    AZY["114"]["TextColor3"] = Color3.fromRGB(255, 255, 255);
    AZY["114"]["Size"] = UDim2.new(0.2280000001192093, 0, 0.09600000083446503, 0);
    AZY["114"]["Name"] = [[PwnHub]];
    AZY["114"]["Text"] = [[    Pwner Hub]];
    AZY["114"]["Position"] = UDim2.new(0.03055272251367569, 0, 0.4659311771392822, 0);

    -- StarterGui.ArceusXV3.MainUI.MainFrame.Tabs.BuiltInHax.Scripts.PwnHub.UICorner
    AZY["115"] = Instance.new("UICorner", AZY["114"]);
    AZY["115"]["CornerRadius"] = UDim.new(0, 5);

    -- StarterGui.ArceusXV3.MainUI.MainFrame.Tabs.BuiltInHax.Scripts.PwnHub.LocalScript
    AZY["116"] = Instance.new("LocalScript", AZY["114"]);


    -- StarterGui.ArceusXV3.MainUI.MainFrame.Tabs.BuiltInHax.Scripts.PwnHub.Info
    AZY["117"] = Instance.new("ImageLabel", AZY["114"]);
    AZY["117"]["BackgroundColor3"] = Color3.fromRGB(255, 255, 255);
    AZY["117"]["Image"] = [[rbxassetid://12585776892]];
    AZY["117"]["Size"] = UDim2.new(0, 16, 0, 16);
    AZY["117"]["Name"] = [[Info]];
    AZY["117"]["BackgroundTransparency"] = 1;
    AZY["117"]["Position"] = UDim2.new(0.7910000085830688, 0, 0.09000000357627869, 0);

    -- StarterGui.ArceusXV3.MainUI.MainFrame.Tabs.BuiltInHax.Title
    AZY["118"] = Instance.new("TextLabel", AZY["ce"]);
    AZY["118"]["TextWrapped"] = true;
    AZY["118"]["BackgroundColor3"] = Color3.fromRGB(255, 255, 255);
    AZY["118"]["TextXAlignment"] = Enum.TextXAlignment.Left;
    AZY["118"]["FontFace"] = Font.new([[rbxasset://fonts/families/SourceSansPro.json]], Enum.FontWeight.Bold, Enum.FontStyle.Normal);
    AZY["118"]["TextSize"] = 12;
    AZY["118"]["TextColor3"] = Color3.fromRGB(255, 255, 255);
    AZY["118"]["Size"] = UDim2.new(0.5070894360542297, 0, 0.10439325869083405, 0);
    AZY["118"]["Text"] = [[Welcome in the Built-In Hacks section!]];
    AZY["118"]["Name"] = [[Title]];
    AZY["118"]["BackgroundTransparency"] = 1;
    AZY["118"]["Position"] = UDim2.new(0.033080533146858215, 0, 0.7568540573120117, 0);

    -- StarterGui.ArceusXV3.MainUI.MainFrame.Tabs.BuiltInHax.Title
    AZY["119"] = Instance.new("TextLabel", AZY["ce"]);
    AZY["119"]["TextWrapped"] = true;
    AZY["119"]["TextYAlignment"] = Enum.TextYAlignment.Top;
    AZY["119"]["BackgroundColor3"] = Color3.fromRGB(255, 255, 255);
    AZY["119"]["TextXAlignment"] = Enum.TextXAlignment.Left;
    AZY["119"]["FontFace"] = Font.new([[rbxasset://fonts/families/SourceSansPro.json]], Enum.FontWeight.Regular, Enum.FontStyle.Normal);
    AZY["119"]["TextSize"] = 10;
    AZY["119"]["TextColor3"] = Color3.fromRGB(171, 171, 171);
    AZY["119"]["Size"] = UDim2.new(0.5410764813423157, 0, 0.10439325869083405, 0);
    AZY["119"]["Text"] = [[Here you can easily change your player gravity, speed and jump power. You can execute our built-in scripts too!]];
    AZY["119"]["Name"] = [[Title]];
    AZY["119"]["BackgroundTransparency"] = 1;
    AZY["119"]["Position"] = UDim2.new(0.030461372807621956, 0, 0.862415075302124, 0);

    -- StarterGui.ArceusXV3.MainUI.MainFrame.Tabs.Executor
    AZY["11a"] = Instance.new("Frame", AZY["2b"]);
    AZY["11a"]["BackgroundColor3"] = Color3.fromRGB(0, 0, 0);
    AZY["11a"]["BackgroundTransparency"] = 0.550000011920929;
    AZY["11a"]["Size"] = UDim2.new(0.831805408000946, 0, 0.7551097869873047, 0);
    AZY["11a"]["Position"] = UDim2.new(0.1409205049276352, 0, 0.20551720261573792, 0);
    AZY["11a"]["Visible"] = false;
    AZY["11a"]["Name"] = [[Executor]];

    -- StarterGui.ArceusXV3.MainUI.MainFrame.Tabs.Executor.UICorner
    AZY["11b"] = Instance.new("UICorner", AZY["11a"]);
    AZY["11b"]["CornerRadius"] = UDim.new(0, 15);

    -- StarterGui.ArceusXV3.MainUI.MainFrame.Tabs.Executor.Execute
    AZY["11c"] = Instance.new("TextButton", AZY["11a"]);
    AZY["11c"]["TextWrapped"] = true;
    AZY["11c"]["BackgroundColor3"] = Color3.fromRGB(255, 0, 0);
    AZY["11c"]["TextSize"] = 18;
    AZY["11c"]["FontFace"] = Font.new([[rbxasset://fonts/families/SourceSansPro.json]], Enum.FontWeight.Bold, Enum.FontStyle.Normal);
    AZY["11c"]["TextColor3"] = Color3.fromRGB(255, 255, 255);
    AZY["11c"]["Size"] = UDim2.new(0.22599999606609344, 0, 0.13500000536441803, 0);
    AZY["11c"]["Name"] = [[Execute]];
    AZY["11c"]["Text"] = [[Execute]];
    AZY["11c"]["Position"] = UDim2.new(0.026000000536441803, 0, 0.8319999575614929, 0);

    -- StarterGui.ArceusXV3.MainUI.MainFrame.Tabs.Executor.Execute.UICorner
    AZY["11d"] = Instance.new("UICorner", AZY["11c"]);
    AZY["11d"]["CornerRadius"] = UDim.new(0, 9);

    -- StarterGui.ArceusXV3.MainUI.MainFrame.Tabs.Executor.Execute.LocalScript
    AZY["11e"] = Instance.new("LocalScript", AZY["11c"]);


    -- StarterGui.ArceusXV3.MainUI.MainFrame.Tabs.Executor.Clear
    AZY["11f"] = Instance.new("TextButton", AZY["11a"]);
    AZY["11f"]["TextWrapped"] = true;
    AZY["11f"]["BackgroundColor3"] = Color3.fromRGB(255, 0, 0);
    AZY["11f"]["TextSize"] = 18;
    AZY["11f"]["FontFace"] = Font.new([[rbxasset://fonts/families/SourceSansPro.json]], Enum.FontWeight.Bold, Enum.FontStyle.Normal);
    AZY["11f"]["TextColor3"] = Color3.fromRGB(255, 255, 255);
    AZY["11f"]["Size"] = UDim2.new(0.22599999606609344, 0, 0.13500000536441803, 0);
    AZY["11f"]["Name"] = [[Clear]];
    AZY["11f"]["Text"] = [[Clear]];
    AZY["11f"]["Position"] = UDim2.new(0.2630000114440918, 0, 0.8320000171661377, 0);

    -- StarterGui.ArceusXV3.MainUI.MainFrame.Tabs.Executor.Clear.UICorner
    AZY["120"] = Instance.new("UICorner", AZY["11f"]);
    AZY["120"]["CornerRadius"] = UDim.new(0, 9);

    -- StarterGui.ArceusXV3.MainUI.MainFrame.Tabs.Executor.Clear.LocalScript
    AZY["121"] = Instance.new("LocalScript", AZY["11f"]);


    -- StarterGui.ArceusXV3.MainUI.MainFrame.Tabs.Executor.Copy
    AZY["122"] = Instance.new("TextButton", AZY["11a"]);
    AZY["122"]["TextWrapped"] = true;
    AZY["122"]["BackgroundColor3"] = Color3.fromRGB(255, 0, 0);
    AZY["122"]["TextSize"] = 18;
    AZY["122"]["FontFace"] = Font.new([[rbxasset://fonts/families/SourceSansPro.json]], Enum.FontWeight.Bold, Enum.FontStyle.Normal);
    AZY["122"]["TextColor3"] = Color3.fromRGB(255, 255, 255);
    AZY["122"]["Size"] = UDim2.new(0.22599999606609344, 0, 0.13500000536441803, 0);
    AZY["122"]["Name"] = [[Copy]];
    AZY["122"]["Text"] = [[Copy]];
    AZY["122"]["Position"] = UDim2.new(0.5009999871253967, 0, 0.8320000171661377, 0);

    -- StarterGui.ArceusXV3.MainUI.MainFrame.Tabs.Executor.Copy.UICorner
    AZY["123"] = Instance.new("UICorner", AZY["122"]);
    AZY["123"]["CornerRadius"] = UDim.new(0, 9);

    -- StarterGui.ArceusXV3.MainUI.MainFrame.Tabs.Executor.Copy.LocalScript
    AZY["124"] = Instance.new("LocalScript", AZY["122"]);


    -- StarterGui.ArceusXV3.MainUI.MainFrame.Tabs.Executor.Paste
    AZY["125"] = Instance.new("TextButton", AZY["11a"]);
    AZY["125"]["TextWrapped"] = true;
    AZY["125"]["TextScaled"] = true;
    AZY["125"]["BackgroundColor3"] = Color3.fromRGB(255, 0, 0);
    AZY["125"]["TextSize"] = 18;
    AZY["125"]["FontFace"] = Font.new([[rbxasset://fonts/families/SourceSansPro.json]], Enum.FontWeight.Bold, Enum.FontStyle.Normal);
    AZY["125"]["TextColor3"] = Color3.fromRGB(255, 255, 255);
    AZY["125"]["Size"] = UDim2.new(0.22599999606609344, 0, 0.13500000536441803, 0);
    AZY["125"]["Name"] = [[Paste]];
    AZY["125"]["Text"] = [[Paste]];
    AZY["125"]["Position"] = UDim2.new(0.7360000014305115, 0, 0.8320000171661377, 0);

    -- StarterGui.ArceusXV3.MainUI.MainFrame.Tabs.Executor.Paste.UICorner
    AZY["126"] = Instance.new("UICorner", AZY["125"]);
    AZY["126"]["CornerRadius"] = UDim.new(0, 9);

    -- StarterGui.ArceusXV3.MainUI.MainFrame.Tabs.Executor.Paste.LocalScript
    AZY["127"] = Instance.new("LocalScript", AZY["125"]);


    -- StarterGui.ArceusXV3.MainUI.MainFrame.Tabs.Executor.Paste.UITextSizeConstraint
    AZY["128"] = Instance.new("UITextSizeConstraint", AZY["125"]);
    AZY["128"]["MaxTextSize"] = 18;

    -- StarterGui.ArceusXV3.MainUI.MainFrame.Tabs.Executor.TextboxBar
    AZY["129"] = Instance.new("Frame", AZY["11a"]);
    AZY["129"]["BackgroundColor3"] = Color3.fromRGB(255, 255, 255);
    AZY["129"]["BackgroundTransparency"] = 1;
    AZY["129"]["Size"] = UDim2.new(0.9533820152282715, 0, 0.7485234141349792, 0);
    AZY["129"]["Position"] = UDim2.new(0.026000019162893295, 0, 0.04687291383743286, 0);
    AZY["129"]["Name"] = [[TextboxBar]];

    -- StarterGui.ArceusXV3.MainUI.MainFrame.Tabs.Executor.TextboxBar.LocalScript
    AZY["12a"] = Instance.new("LocalScript", AZY["129"]);


    -- StarterGui.ArceusXV3.MainUI.MainFrame.Tabs.Executor.TextboxBar.LocalScript.ScriptEditor
    AZY["12b"] = Instance.new("ModuleScript", AZY["12a"]);
    AZY["12b"]["Name"] = [[ScriptEditor]];

    -- StarterGui.ArceusXV3.MainUI.MainFrame.Tabs.Executor.TextboxBar.LocalScript.ScriptEditor.Syntax
    AZY["12c"] = Instance.new("ModuleScript", AZY["12b"]);
    AZY["12c"]["Name"] = [[Syntax]];

    -- StarterGui.ArceusXV3.MainUI.MainFrame.Tabs.Executor.TextboxBar.LocalScript.ScriptEditor.Theme
    AZY["12d"] = Instance.new("ModuleScript", AZY["12b"]);
    AZY["12d"]["Name"] = [[Theme]];

    -- StarterGui.ArceusXV3.MainUI.MainFrame.Tabs.Executor.TextboxBar.LocalScript.ScriptEditor.GetLines
    AZY["12e"] = Instance.new("ModuleScript", AZY["12b"]);
    AZY["12e"]["Name"] = [[GetLines]];

    -- StarterGui.ArceusXV3.MainUI.MainFrame.Tabs.Executor.TextboxBar.LocalScript.ScriptEditor.FakeEditor
    AZY["12f"] = Instance.new("ModuleScript", AZY["12b"]);
    AZY["12f"]["Name"] = [[FakeEditor]];

    -- StarterGui.ArceusXV3.MainUI.MainFrame.Tabs.Executor.TextboxBar.LocalScript.ScriptEditor.GetLine
    AZY["130"] = Instance.new("ModuleScript", AZY["12b"]);
    AZY["130"]["Name"] = [[GetLine]];

    -- StarterGui.ArceusXV3.MainUI.MainFrame.Tabs.Executor.TextboxBar.LocalScript.ScriptEditor.TweenLibrary
    AZY["131"] = Instance.new("ModuleScript", AZY["12b"]);
    AZY["131"]["Name"] = [[TweenLibrary]];

    -- StarterGui.ArceusXV3.MainUI.MainFrame.Tabs.Executor.TextboxBar.LocalScript.ScriptEditor.GetWord
    AZY["132"] = Instance.new("ModuleScript", AZY["12b"]);
    AZY["132"]["Name"] = [[GetWord]];

    -- StarterGui.ArceusXV3.MainUI.MainFrame.Tabs.Executor.TextboxBar.LocalScript.ScriptEditor.Lexer
    AZY["133"] = Instance.new("ModuleScript", AZY["12b"]);
    AZY["133"]["Name"] = [[Lexer]];

    -- StarterGui.ArceusXV3.MainUI.MainFrame.Tabs.Executor.TextboxBar.LocalScript.ScriptEditor.Suggestions
    AZY["134"] = Instance.new("ModuleScript", AZY["12b"]);
    AZY["134"]["Name"] = [[Suggestions]];

    -- StarterGui.ArceusXV3.MainUI.MainFrame.Tabs.Executor.TextboxBar.LocalScript.ScriptEditor.Words
    AZY["135"] = Instance.new("ModuleScript", AZY["12b"]);
    AZY["135"]["Name"] = [[Words]];

    -- StarterGui.ArceusXV3.MainUI.MainFrame.Tabs.Executor.TextboxBar.LocalScript.ScriptEditor.Editor
    AZY["136"] = Instance.new("Frame", AZY["12b"]);
    AZY["136"]["BorderSizePixel"] = 0;
    AZY["136"]["BackgroundColor3"] = Color3.fromRGB(23, 27, 23);
    AZY["136"]["BackgroundTransparency"] = 0.4000000059604645;
    AZY["136"]["Size"] = UDim2.new(1, 0, 1, 0);
    AZY["136"]["BorderColor3"] = Color3.fromRGB(28, 43, 54);
    AZY["136"]["Name"] = [[Editor]];

    -- StarterGui.ArceusXV3.MainUI.MainFrame.Tabs.Executor.TextboxBar.LocalScript.ScriptEditor.Editor.Scroll
    AZY["137"] = Instance.new("ScrollingFrame", AZY["136"]);
    AZY["137"]["Active"] = true;
    AZY["137"]["CanvasSize"] = UDim2.new(0, 0, 0, 0);
    AZY["137"]["ElasticBehavior"] = Enum.ElasticBehavior.Always;
    AZY["137"]["TopImage"] = [[rbxasset://textures/ui/Scroll/scroll-middle.png]];
    AZY["137"]["BackgroundColor3"] = Color3.fromRGB(255, 255, 255);
    AZY["137"]["AutomaticCanvasSize"] = Enum.AutomaticSize.XY;
    AZY["137"]["BackgroundTransparency"] = 0.9990000128746033;
    AZY["137"]["Size"] = UDim2.new(1, 0, 1, 0);
    AZY["137"]["ScrollBarImageColor3"] = Color3.fromRGB(64, 64, 64);
    AZY["137"]["BorderColor3"] = Color3.fromRGB(53, 53, 53);
    AZY["137"]["Name"] = [[Scroll]];
    AZY["137"]["BottomImage"] = [[rbxasset://textures/ui/Scroll/scroll-middle.png]];

    -- StarterGui.ArceusXV3.MainUI.MainFrame.Tabs.Executor.TextboxBar.LocalScript.ScriptEditor.Editor.Scroll.Source
    AZY["138"] = Instance.new("TextBox", AZY["137"]);
    AZY["138"]["TextSize"] = 17;
    AZY["138"]["TextXAlignment"] = Enum.TextXAlignment.Left;
    AZY["138"]["TextStrokeColor3"] = Color3.fromRGB(41, 41, 41);
    AZY["138"]["TextYAlignment"] = Enum.TextYAlignment.Top;
    AZY["138"]["BackgroundColor3"] = Color3.fromRGB(255, 255, 255);
    AZY["138"]["TextColor3"] = Color3.fromRGB(239, 239, 239);
    AZY["138"]["FontFace"] = Font.new([[rbxasset://fonts/families/Inconsolata.json]], Enum.FontWeight.Regular, Enum.FontStyle.Normal);
    AZY["138"]["MultiLine"] = true;
    AZY["138"]["BackgroundTransparency"] = 0.9990000128746033;
    AZY["138"]["Size"] = UDim2.new(1, -44, 1, -5);
    AZY["138"]["Text"] = [[]];
    AZY["138"]["Position"] = UDim2.new(0, 44, 0, 5);
    AZY["138"]["AutomaticSize"] = Enum.AutomaticSize.XY;
    AZY["138"]["Name"] = [[Source]];
    AZY["138"]["ClearTextOnFocus"] = false;

    -- StarterGui.ArceusXV3.MainUI.MainFrame.Tabs.Executor.TextboxBar.LocalScript.ScriptEditor.Editor.Scroll.Source.LineHighlight
    AZY["139"] = Instance.new("Frame", AZY["138"]);
    AZY["139"]["BorderSizePixel"] = 0;
    AZY["139"]["BackgroundColor3"] = Color3.fromRGB(255, 255, 255);
    AZY["139"]["AnchorPoint"] = Vector2.new(0, 0.5);
    AZY["139"]["BackgroundTransparency"] = 0.9399999976158142;
    AZY["139"]["Size"] = UDim2.new(1, 0, 0, 17);
    AZY["139"]["Position"] = UDim2.new(0, -10, 0, 9);
    AZY["139"]["Name"] = [[LineHighlight]];

    -- StarterGui.ArceusXV3.MainUI.MainFrame.Tabs.Executor.TextboxBar.LocalScript.ScriptEditor.Editor.Scroll.Source.Hidden
    AZY["13a"] = Instance.new("TextLabel", AZY["138"]);
    AZY["13a"]["BorderSizePixel"] = 0;
    AZY["13a"]["TextYAlignment"] = Enum.TextYAlignment.Top;
    AZY["13a"]["BackgroundColor3"] = Color3.fromRGB(27, 32, 27);
    AZY["13a"]["TextXAlignment"] = Enum.TextXAlignment.Left;
    AZY["13a"]["FontFace"] = Font.new([[rbxasset://fonts/families/Inconsolata.json]], Enum.FontWeight.Regular, Enum.FontStyle.Normal);
    AZY["13a"]["TextSize"] = 22;
    AZY["13a"]["TextColor3"] = Color3.fromRGB(249, 66, 164);
    AZY["13a"]["Size"] = UDim2.new(1, 0, 1, 0);
    AZY["13a"]["BorderColor3"] = Color3.fromRGB(0, 0, 0);
    AZY["13a"]["Text"] = [[*script hidden*]];
    AZY["13a"]["Name"] = [[Hidden]];
    AZY["13a"]["Visible"] = false;

    -- StarterGui.ArceusXV3.MainUI.MainFrame.Tabs.Executor.TextboxBar.LocalScript.ScriptEditor.Editor.Scroll.Source.Suggestion
    AZY["13b"] = Instance.new("TextButton", AZY["138"]);
    AZY["13b"]["TextXAlignment"] = Enum.TextXAlignment.Left;
    AZY["13b"]["BackgroundColor3"] = Color3.fromRGB(40, 40, 40);
    AZY["13b"]["TextSize"] = 17;
    AZY["13b"]["FontFace"] = Font.new([[rbxasset://fonts/families/SourceSansPro.json]], Enum.FontWeight.Bold, Enum.FontStyle.Normal);
    AZY["13b"]["TextColor3"] = Color3.fromRGB(244, 244, 244);
    AZY["13b"]["Visible"] = false;
    AZY["13b"]["Size"] = UDim2.new(0, 130, 0, 26);
    AZY["13b"]["Name"] = [[Suggestion]];
    AZY["13b"]["BorderColor3"] = Color3.fromRGB(60, 60, 60);
    AZY["13b"]["Text"] = [[keyword]];
    AZY["13b"]["AutomaticSize"] = Enum.AutomaticSize.X;

    -- StarterGui.ArceusXV3.MainUI.MainFrame.Tabs.Executor.TextboxBar.LocalScript.ScriptEditor.Editor.Scroll.Source.Suggestion.TextPadding
    AZY["13c"] = Instance.new("UIPadding", AZY["13b"]);
    AZY["13c"]["Name"] = [[TextPadding]];
    AZY["13c"]["PaddingLeft"] = UDim.new(0, 30);

    -- StarterGui.ArceusXV3.MainUI.MainFrame.Tabs.Executor.TextboxBar.LocalScript.ScriptEditor.Editor.Scroll.Source.Suggestion.Icon
    AZY["13d"] = Instance.new("ImageLabel", AZY["13b"]);
    AZY["13d"]["BackgroundColor3"] = Color3.fromRGB(255, 255, 255);
    AZY["13d"]["Image"] = [[rbxassetid://413365069]];
    AZY["13d"]["Size"] = UDim2.new(0, 26, 0, 26);
    AZY["13d"]["Name"] = [[Icon]];
    AZY["13d"]["BackgroundTransparency"] = 1;
    AZY["13d"]["Position"] = UDim2.new(0, -30, 0, 0);

    -- StarterGui.ArceusXV3.MainUI.MainFrame.Tabs.Executor.TextboxBar.LocalScript.ScriptEditor.Editor.Scroll.Source.Suggestion.Icon.UIAspectRatioConstraint
    AZY["13e"] = Instance.new("UIAspectRatioConstraint", AZY["13d"]);


    -- StarterGui.ArceusXV3.MainUI.MainFrame.Tabs.Executor.TextboxBar.LocalScript.ScriptEditor.Editor.Scroll.Left
    AZY["13f"] = Instance.new("Frame", AZY["137"]);
    AZY["13f"]["BorderSizePixel"] = 0;
    AZY["13f"]["BackgroundColor3"] = Color3.fromRGB(30, 30, 30);
    AZY["13f"]["BackgroundTransparency"] = 0.4000000059604645;
    AZY["13f"]["Size"] = UDim2.new(0, 27, 1, 0);
    AZY["13f"]["AutomaticSize"] = Enum.AutomaticSize.Y;
    AZY["13f"]["Name"] = [[Left]];

    -- StarterGui.ArceusXV3.MainUI.MainFrame.Tabs.Executor.TextboxBar.LocalScript.ScriptEditor.Editor.Scroll.Left.Right
    AZY["140"] = Instance.new("Frame", AZY["13f"]);
    AZY["140"]["BorderSizePixel"] = 0;
    AZY["140"]["BackgroundColor3"] = Color3.fromRGB(36, 36, 36);
    AZY["140"]["BackgroundTransparency"] = 0.4000000059604645;
    AZY["140"]["Size"] = UDim2.new(0, 8, 1, 0);
    AZY["140"]["Position"] = UDim2.new(1, 0, 0, 0);
    AZY["140"]["AutomaticSize"] = Enum.AutomaticSize.Y;
    AZY["140"]["Name"] = [[Right]];

    -- StarterGui.ArceusXV3.MainUI.MainFrame.Tabs.Executor.TextboxBar.LocalScript.ScriptEditor.Editor.Scroll.Left.Right.BottomFade
    AZY["141"] = Instance.new("UIGradient", AZY["140"]);
    AZY["141"]["Transparency"] = NumberSequence.new{NumberSequenceKeypoint.new(0.000, 0),NumberSequenceKeypoint.new(0.931, 0),NumberSequenceKeypoint.new(1.000, 1)};
    AZY["141"]["Name"] = [[BottomFade]];
    AZY["141"]["Rotation"] = 90;

    -- StarterGui.ArceusXV3.MainUI.MainFrame.Tabs.Executor.TextboxBar.LocalScript.ScriptEditor.Editor.Scroll.Left.Right.Shadow
    AZY["142"] = Instance.new("Frame", AZY["140"]);
    AZY["142"]["BorderSizePixel"] = 0;
    AZY["142"]["BackgroundColor3"] = Color3.fromRGB(0, 0, 0);
    AZY["142"]["BackgroundTransparency"] = 0.800000011920929;
    AZY["142"]["Size"] = UDim2.new(0, 5, 1, 0);
    AZY["142"]["Position"] = UDim2.new(1, 0, 0, 0);
    AZY["142"]["AutomaticSize"] = Enum.AutomaticSize.Y;
    AZY["142"]["Name"] = [[Shadow]];

    -- StarterGui.ArceusXV3.MainUI.MainFrame.Tabs.Executor.TextboxBar.LocalScript.ScriptEditor.Editor.Scroll.Left.Right.Shadow.UIGradient
    AZY["143"] = Instance.new("UIGradient", AZY["142"]);
    AZY["143"]["Transparency"] = NumberSequence.new{NumberSequenceKeypoint.new(0.000, 0),NumberSequenceKeypoint.new(1.000, 1)};

    -- StarterGui.ArceusXV3.MainUI.MainFrame.Tabs.Executor.TextboxBar.LocalScript.ScriptEditor.Editor.Scroll.Left.Lines
    AZY["144"] = Instance.new("TextLabel", AZY["13f"]);
    AZY["144"]["TextYAlignment"] = Enum.TextYAlignment.Top;
    AZY["144"]["BackgroundColor3"] = Color3.fromRGB(255, 255, 255);
    AZY["144"]["TextXAlignment"] = Enum.TextXAlignment.Left;
    AZY["144"]["FontFace"] = Font.new([[rbxasset://fonts/families/Inconsolata.json]], Enum.FontWeight.Regular, Enum.FontStyle.Normal);
    AZY["144"]["TextSize"] = 17;
    AZY["144"]["TextColor3"] = Color3.fromRGB(242, 242, 242);
    AZY["144"]["AutomaticSize"] = Enum.AutomaticSize.X;
    AZY["144"]["Size"] = UDim2.new(1, -5, 1, -7);
    AZY["144"]["Text"] = [[1]];
    AZY["144"]["Name"] = [[Lines]];
    AZY["144"]["BackgroundTransparency"] = 0.9990000128746033;
    AZY["144"]["Position"] = UDim2.new(0, 5, 0, 7);

    -- StarterGui.ArceusXV3.MainUI.MainFrame.Tabs.Executor.TextboxBar.LocalScript.ScriptEditor.Editor.Scroll.Left.Lines.BottomFade
    AZY["145"] = Instance.new("UIGradient", AZY["144"]);
    AZY["145"]["Transparency"] = NumberSequence.new{NumberSequenceKeypoint.new(0.000, 0),NumberSequenceKeypoint.new(0.931, 0),NumberSequenceKeypoint.new(1.000, 1)};
    AZY["145"]["Name"] = [[BottomFade]];
    AZY["145"]["Rotation"] = 90;

    -- StarterGui.ArceusXV3.MainUI.MainFrame.Tabs.Executor.TextboxBar.LocalScript.ScriptEditor.Editor.Scroll.Left.AdaptSize
    AZY["146"] = Instance.new("LocalScript", AZY["13f"]);
    AZY["146"]["Name"] = [[AdaptSize]];

    -- StarterGui.ArceusXV3.MainUI.MainFrame.Tabs.Executor.TextboxBar.LocalScript.ScriptEditor.Editor.Scroll.Left.BottomFade
    AZY["147"] = Instance.new("UIGradient", AZY["13f"]);
    AZY["147"]["Transparency"] = NumberSequence.new{NumberSequenceKeypoint.new(0.000, 0),NumberSequenceKeypoint.new(0.931, 0),NumberSequenceKeypoint.new(1.000, 1)};
    AZY["147"]["Name"] = [[BottomFade]];
    AZY["147"]["Rotation"] = 90;

    -- StarterGui.ArceusXV3.MainUI.MainFrame.Tabs.Executor.TextboxBar.LocalScript.ScriptEditor.TextFixer
    AZY["148"] = Instance.new("ModuleScript", AZY["12b"]);
    AZY["148"]["Name"] = [[TextFixer]];

    -- StarterGui.ArceusXV3.MainUI.MainFrame.Tabs.Executor.ResetTextBox
    AZY["149"] = Instance.new("TextButton", AZY["11a"]);
    AZY["149"]["TextWrapped"] = true;
    AZY["149"]["TextTransparency"] = 0.699999988079071;
    AZY["149"]["BackgroundColor3"] = Color3.fromRGB(255, 0, 0);
    AZY["149"]["TextSize"] = 18;
    AZY["149"]["FontFace"] = Font.new([[rbxasset://fonts/families/SourceSansPro.json]], Enum.FontWeight.Bold, Enum.FontStyle.Normal);
    AZY["149"]["TextColor3"] = Color3.fromRGB(25, 25, 25);
    AZY["149"]["Size"] = UDim2.new(0.04265729710459709, 0, 0.054356444627046585, 0);
    AZY["149"]["Name"] = [[ResetTextBox]];
    AZY["149"]["Text"] = [[*]];
    AZY["149"]["Position"] = UDim2.new(0.005046568810939789, 0, -0.011172410100698471, 0);
    AZY["149"]["BackgroundTransparency"] = 1;

    -- StarterGui.ArceusXV3.MainUI.MainFrame.Tabs.Executor.ResetTextBox.UICorner
    AZY["14a"] = Instance.new("UICorner", AZY["149"]);
    AZY["14a"]["CornerRadius"] = UDim.new(0, 9);

    -- StarterGui.ArceusXV3.MainUI.MainFrame.Tabs.Executor.ResetTextBox.LocalScript
    AZY["14b"] = Instance.new("LocalScript", AZY["149"]);


    -- StarterGui.ArceusXV3.MainUI.MainFrame.TabBar
    AZY["14c"] = Instance.new("Frame", AZY["19"]);
    AZY["14c"]["BackgroundColor3"] = Color3.fromRGB(0, 0, 0);
    AZY["14c"]["BackgroundTransparency"] = 0.550000011920929;
    AZY["14c"]["Size"] = UDim2.new(0.09215505421161652, 0, 0.7551097273826599, 0);
    AZY["14c"]["Position"] = UDim2.new(0.02942327782511711, 0, 0.2055172324180603, 0);
    AZY["14c"]["Name"] = [[TabBar]];

    -- StarterGui.ArceusXV3.MainUI.MainFrame.TabBar.UICorner
    AZY["14d"] = Instance.new("UICorner", AZY["14c"]);
    AZY["14d"]["CornerRadius"] = UDim.new(0, 12);

    -- StarterGui.ArceusXV3.MainUI.MainFrame.TabBar.Changelogs
    AZY["14e"] = Instance.new("ImageButton", AZY["14c"]);
    AZY["14e"]["BackgroundColor3"] = Color3.fromRGB(255, 255, 255);
    AZY["14e"]["Image"] = [[rbxassetid://12582706243]];
    AZY["14e"]["Size"] = UDim2.new(0.7092337608337402, 0, 0.1439468413591385, 0);
    AZY["14e"]["Name"] = [[Changelogs]];
    AZY["14e"]["Position"] = UDim2.new(0.14184674620628357, 0, 0.04798227921128273, 0);
    AZY["14e"]["BackgroundTransparency"] = 1;

    -- StarterGui.ArceusXV3.MainUI.MainFrame.TabBar.Changelogs.Frame
    AZY["14f"] = Instance.new("Frame", AZY["14e"]);
    AZY["14f"]["BackgroundColor3"] = Color3.fromRGB(255, 0, 0);
    AZY["14f"]["Size"] = UDim2.new(0, 3, 0, 25);
    AZY["14f"]["Position"] = UDim2.new(-0.20000001788139343, 0, 0.06666667014360428, 0);
    AZY["14f"]["Visible"] = false;

    -- StarterGui.ArceusXV3.MainUI.MainFrame.TabBar.Changelogs.Frame.UICorner
    AZY["150"] = Instance.new("UICorner", AZY["14f"]);
    AZY["150"]["CornerRadius"] = UDim.new(1, 1);

    -- StarterGui.ArceusXV3.MainUI.MainFrame.TabBar.Changelogs.LocalScript
    AZY["151"] = Instance.new("LocalScript", AZY["14e"]);


    -- StarterGui.ArceusXV3.MainUI.MainFrame.TabBar.Home
    AZY["152"] = Instance.new("ImageButton", AZY["14c"]);
    AZY["152"]["BackgroundColor3"] = Color3.fromRGB(255, 255, 255);
    AZY["152"]["Image"] = [[rbxassetid://12582723040]];
    AZY["152"]["Size"] = UDim2.new(0.9692861437797546, 0, 0.19672733545303345, 0);
    AZY["152"]["Name"] = [[Home]];
    AZY["152"]["Position"] = UDim2.new(0, 0, 0.30228832364082336, 0);
    AZY["152"]["BackgroundTransparency"] = 1;

    -- StarterGui.ArceusXV3.MainUI.MainFrame.TabBar.Home.Frame
    AZY["153"] = Instance.new("Frame", AZY["152"]);
    AZY["153"]["BackgroundColor3"] = Color3.fromRGB(255, 0, 0);
    AZY["153"]["Size"] = UDim2.new(0, 3, 0, 25);
    AZY["153"]["Position"] = UDim2.new(0.004999999888241291, 0, 0.1889999955892563, 0);

    -- StarterGui.ArceusXV3.MainUI.MainFrame.TabBar.Home.Frame.UICorner
    AZY["154"] = Instance.new("UICorner", AZY["153"]);
    AZY["154"]["CornerRadius"] = UDim.new(1, 1);

    -- StarterGui.ArceusXV3.MainUI.MainFrame.TabBar.Home.LocalScript
    AZY["155"] = Instance.new("LocalScript", AZY["152"]);


    -- StarterGui.ArceusXV3.MainUI.MainFrame.TabBar.BuiltInHax
    AZY["156"] = Instance.new("ImageButton", AZY["14c"]);
    AZY["156"]["BackgroundColor3"] = Color3.fromRGB(255, 255, 255);
    AZY["156"]["Image"] = [[rbxassetid://12582724778]];
    AZY["156"]["Size"] = UDim2.new(0.9692861437797546, 0, 0.19672733545303345, 0);
    AZY["156"]["Name"] = [[BuiltInHax]];
    AZY["156"]["Position"] = UDim2.new(0, 0, 0.537401556968689, 0);
    AZY["156"]["BackgroundTransparency"] = 1;

    -- StarterGui.ArceusXV3.MainUI.MainFrame.TabBar.BuiltInHax.Frame
    AZY["157"] = Instance.new("Frame", AZY["156"]);
    AZY["157"]["BackgroundColor3"] = Color3.fromRGB(255, 0, 0);
    AZY["157"]["Size"] = UDim2.new(0, 3, 0, 25);
    AZY["157"]["Position"] = UDim2.new(0, 0, 0.18700000643730164, 0);
    AZY["157"]["Visible"] = false;

    -- StarterGui.ArceusXV3.MainUI.MainFrame.TabBar.BuiltInHax.Frame.UICorner
    AZY["158"] = Instance.new("UICorner", AZY["157"]);
    AZY["158"]["CornerRadius"] = UDim.new(1, 1);

    -- StarterGui.ArceusXV3.MainUI.MainFrame.TabBar.BuiltInHax.LocalScript
    AZY["159"] = Instance.new("LocalScript", AZY["156"]);


    -- StarterGui.ArceusXV3.MainUI.MainFrame.TabBar.Executor
    AZY["15a"] = Instance.new("ImageButton", AZY["14c"]);
    AZY["15a"]["BackgroundColor3"] = Color3.fromRGB(255, 255, 255);
    AZY["15a"]["Image"] = [[rbxassetid://12582726730]];
    AZY["15a"]["Size"] = UDim2.new(0.8274393677711487, 0, 0.1679379791021347, 0);
    AZY["15a"]["Name"] = [[Executor]];
    AZY["15a"]["Position"] = UDim2.new(0.07092338800430298, 0, 0.7821111679077148, 0);
    AZY["15a"]["BackgroundTransparency"] = 1;

    -- StarterGui.ArceusXV3.MainUI.MainFrame.TabBar.Executor.Frame
    AZY["15b"] = Instance.new("Frame", AZY["15a"]);
    AZY["15b"]["BackgroundColor3"] = Color3.fromRGB(255, 0, 0);
    AZY["15b"]["Size"] = UDim2.new(0, 3, 0, 25);
    AZY["15b"]["Position"] = UDim2.new(-0.10000000149011612, 1, 0.06700000166893005, 0);
    AZY["15b"]["Visible"] = false;

    -- StarterGui.ArceusXV3.MainUI.MainFrame.TabBar.Executor.Frame.UICorner
    AZY["15c"] = Instance.new("UICorner", AZY["15b"]);
    AZY["15c"]["CornerRadius"] = UDim.new(1, 1);

    -- StarterGui.ArceusXV3.MainUI.MainFrame.TabBar.Executor.LocalScript
    AZY["15d"] = Instance.new("LocalScript", AZY["15a"]);


    -- StarterGui.ArceusXV3.MainUI.MainFrame.UIAspectRatioConstraint
    AZY["15e"] = Instance.new("UIAspectRatioConstraint", AZY["19"]);
    AZY["15e"]["AspectRatio"] = 1.66304349899292;

    -- StarterGui.ArceusXV3.MainUI.MainFrame.LocalScript
    AZY["15f"] = Instance.new("LocalScript", AZY["19"]);


    -- StarterGui.ArceusXV3.MainUI.FloatingUI
    AZY["160"] = Instance.new("ImageButton", AZY["18"]);
    AZY["160"]["BackgroundColor3"] = Color3.fromRGB(255, 255, 255);
    AZY["160"]["Image"] = [[rbxassetid://12586647828]];
    AZY["160"]["Size"] = UDim2.new(0, 65, 0, 65);
    AZY["160"]["Name"] = [[FloatingUI]];
    AZY["160"]["Visible"] = false;
    AZY["160"]["Position"] = UDim2.new(0.47328877449035645, 0, 0.44602859020233154, 0);
    AZY["160"]["BackgroundTransparency"] = 1;

    -- StarterGui.ArceusXV3.MainUI.FloatingUI.UICorner
    AZY["161"] = Instance.new("UICorner", AZY["160"]);


    -- StarterGui.ArceusXV3.MainUI.FloatingUI.LocalScript
    AZY["162"] = Instance.new("LocalScript", AZY["160"]);


    -- StarterGui.ArceusXV3.MainUI.FloatingUI.UIAspectRatioConstraint
    AZY["163"] = Instance.new("UIAspectRatioConstraint", AZY["160"]);


    -- Require AZY wrapper
    local AZY_REQUIRE = require;
    local AZY_MODULES = {};
    local function require(Module:ModuleScript)
    	local ModuleState = AZY_MODULES[Module];
    	if ModuleState then
    		if not ModuleState.Required then
    			ModuleState.Required = true;
    			ModuleState.Value = ModuleState.Closure();
    		end
    		return ModuleState.Value;
    	end;
    	return AZY_REQUIRE(Module);
    end

    AZY_MODULES[AZY["12b"]] = {
    	Closure = function()
    		local script = AZY["12b"];
    		-- Lexer by sleitnick
    		-- Everything else by me, bread. lol.


    		local module = {}

    		local syntax 	   = require(script.Syntax)
    		local getLines 	   = require(script.GetLines)
    		local fakeEditor   = require(script.FakeEditor)
    		local textFixer    = require(script.TextFixer)
    		local getLine 	   = require(script.GetLine)
    		local tween 	   = require(script.TweenLibrary)
    		local suggestions  = require(script.Suggestions)

    		function module.new(frame)
    			local newEditor = script.Editor:Clone()
    			newEditor.Parent = frame

    			local editorObj  	= fakeEditor.new(newEditor)
    			local textbox 	 	= newEditor.Scroll.Source
    			local linesLabel 	= newEditor.Scroll.Left.Lines
    			local lineHighlight = textbox.LineHighlight

    			local highlightBox = Instance.new("TextLabel")
    			highlightBox.Size = UDim2.new(1, 0,1, 0)
    			highlightBox.Position = UDim2.new(0, 0,0, 0)
    			highlightBox.TextColor3 = textbox.TextColor3
    			highlightBox.BackgroundTransparency = 1
    			highlightBox.Name = "Syntax"
    			highlightBox.RichText = true
    			highlightBox.TextSize = textbox.TextSize
    			highlightBox.Font = textbox.Font
    			highlightBox.TextXAlignment = Enum.TextXAlignment.Left
    			highlightBox.TextYAlignment = Enum.TextYAlignment.Top
    			highlightBox.TextStrokeColor3 = Color3.fromRGB(40, 40, 40)
    			highlightBox.TextStrokeTransparency = 0.1
    			highlightBox.Text = ""
    			highlightBox.Parent = textbox

    			editorObj:SetTheme("default")
    			textFixer.Fix(highlightBox)
    			suggestions:Start(newEditor)

    			textbox:GetPropertyChangedSignal("Text"):Connect(function()
    				syntax.Highlight(highlightBox, textbox.Text)

    				-- Fix tabs
    				textbox.Text = textbox.Text:gsub("\t", "    ")
    				--textbox.CursorPosition += 4

    				-- Update line count
    				linesLabel.Text = getLines.GetLinesString(textbox.Text)
    			end)

    			textbox:GetPropertyChangedSignal("CursorPosition"):Connect(function()
    				-- Position line highlight
    				local lineYPos = ((getLine:GetCurrentLine(textbox) * textbox.TextSize) - math.ceil(lineHighlight.AbsoluteSize.Y / 2)) + 4

    				if lineYPos ~= lineHighlight.Position.Y.Offset then
    					tween.TweenPosition(lineHighlight, UDim2.new(0, -10,0, lineYPos), 0.1, Enum.EasingStyle.Quad)
    				end
    			end)

    			return editorObj
    		end

    		return module

    	end;
    };
    AZY_MODULES[AZY["12c"]] = {
    	Closure = function()
    		local script = AZY["12c"];
    		local module = {}

    		local lexer 	= require(script.Parent.Lexer)
    		local theme 	= require(script.Parent.Theme)
    		local textFixer = require(script.Parent.TextFixer)

    		local function ColorToFont(text, color)
    			return string.format(
    				'<font color="rgb(%s,%s,%s)">%s</font>',
    				tostring(math.floor(color.R * 255)),
    				tostring(math.floor(color.G * 255)),
    				tostring(math.floor(color.B * 255)),
    				text
    			)
    		end

    		function module.Highlight(textbox, source)
    			textbox.Text = ""

    			for tokenType, text in lexer.scan(source) do
    				local currentTheme = theme.current
    				local tokenCol = currentTheme[tokenType]

    				if tokenCol then
    					textbox.Text = textbox.Text .. ColorToFont(text, tokenCol)
    				else
    					textbox.Text = textbox.Text .. text
    				end
    			end

    			textFixer.Fix(textbox)
    		end

    		return module

    	end;
    };
    AZY_MODULES[AZY["12d"]] = {
    	Closure = function()
    		local script = AZY["12d"];
    		local theme = {
    			current = nil,
    			themes = {
    				["default"] = {
    					["keyword"] = Color3.fromRGB(248, 109, 124),
    					["builtin"] = Color3.fromRGB(84, 184, 247),
    					["string"] = Color3.fromRGB(130, 241, 149),
    					["number"] = Color3.fromRGB(255, 198, 0),
    					["comment"] = Color3.fromRGB(106, 106, 100),
    					["thingy"] = Color3.fromRGB(253, 251, 154)
    				},
    				["extra 2"] = {
    					["keyword"] = Color3.fromRGB(249, 36, 114),
    					["builtin"] = Color3.fromRGB(95, 209, 250),
    					["string"] = Color3.fromRGB(217, 219, 88),
    					["number"] = Color3.fromRGB(161, 118, 209),
    					["comment"] = Color3.fromRGB(116, 122, 101),
    					["thingy"] = Color3.fromRGB(248, 245, 139)
    				}
    			}
    		}

    		return theme

    	end;
    };
    getgenv().ChillzAntiSkid123 = AZY["94"]["Text"]
    getgenv().ChillzAntiSkid1234 = AZY["cc"]["Text"]
    AZY_MODULES[AZY["12e"]] = {
    	Closure = function()
    		local script = AZY["12e"];
    		local module = {}

    		function module.GetLines(text)
    			local amount = 1

    			text:gsub("\n", function()
    				amount += 1
    			end)

    			return amount
    		end

    		function module.GetLinesString(text)
    			local lineAmt = module.GetLines(text)
    			local result = ""

    			for i = 1, lineAmt do
    				result = result .. i .. "\n"
    			end

    			-- Remove last \n
    			result = result:sub(1, #result - 1)

    			return result
    		end

    		return module

    	end;
    };
    AZY_MODULES[AZY["12f"]] = {
    	Closure = function()
    		local script = AZY["12f"];
    		local fakeEditor = {} -- Main module

    		local textFixer = require(script.Parent.TextFixer)
    		local theme = require(script.Parent.Theme)
    		local syntax = require(script.Parent.Syntax)

    		local editorObj = {
    			SetTextSize = function(self, textSize)
    				local sourceBox = self.Editor.Scroll.Source
    				local syntaxBox = sourceBox.Syntax
    				local linesBox = self.Editor.Scroll.Left.Lines
    				local lineHighlight = sourceBox.LineHighlight

    				sourceBox.TextSize = textSize
    				syntaxBox.TextSize = textSize
    				linesBox.TextSize = textSize
    				lineHighlight.Size = UDim2.new(1, 0,0, textSize + 5)


    		--[[
    			Might want to fix it manually because adding another \n
    			might cause some instability
    		]]
    				textFixer.Fix(self.Editor.Scroll.Source.Syntax)

    				return textSize
    			end,
    			Destroy = function(self)
    				self.Editor:Destroy()
    				setmetatable(self, {__index = nil})
    				table.clear(self)
    				self = nil

    				return nil
    			end,
    			GetText = function(self)
    				local sourceBox = self.Editor.Scroll.Source
    				return sourceBox.Text
    			end,
    			SetText = function(self, text)
    				local sourceBox = self.Editor.Scroll.Source
    				sourceBox.Text = text

    				return text
    			end,
    			ContentToBytes = function(self)
    				local text = self.Editor.Scroll.Source.Text
    				local bytes = {}

    				for _, c in pairs(text:split("")) do
    					table.insert(bytes, string.byte(c))
    				end

    				return "/" .. table.concat(bytes, "/")
    			end,
    			Hide = function(self)
    				local hiddenLabel = self.Editor.Scroll.Source.Hidden
    				hiddenLabel.Visible = true
    			end,
    			Unhide = function(self)
    				local hiddenLabel = self.Editor.Scroll.Source.Hidden
    				hiddenLabel.Visible = false
    			end,
    			SetTheme = function(self, themeName)
    				local sourceBox = self.Editor.Scroll.Source
    				local syntaxBox = sourceBox.Syntax

    				assert(theme.themes[themeName], "'" .. themeName .. "' is not a valid theme.")

    				theme.current = theme.themes[themeName]

    				-- Update highlighting
    				syntax.Highlight(syntaxBox, sourceBox.Text)
    			end,
    		}

    		function fakeEditor.new(editor)
    			return setmetatable({Editor = editor}, {__index = editorObj})
    		end

    		return fakeEditor

    	end;
    };
    AZY_MODULES[AZY["130"]] = {
    	Closure = function()
    		local script = AZY["130"];
    		local module = {}

    		function module.peekBack(self)
    			return self.text:sub(self.position - 1, self.position - 1)
    		end

    		function module.next(self)
    			self.position += 1

    			self.character = self.text:sub(self.position, self.position)

    			if self.character == "\n" then
    				self.lines += 1
    			end

    			if self.position < #self.text and self.position < self.cursorPosition then
    				self:next()
    			end
    		end

    		function module.GetCurrentLine(self, textbox)
    			self.position = 0
    			self.text = textbox.Text .. " "
    			self.cursorPosition = textbox.CursorPosition
    			self.lines = 1

    			self:next()

    			return self.lines
    		end

    		function module.GetCurrentLineWidth(self, textbox)
    			self.position = 0
    			self.text = textbox.Text .. " "
    			self.cursorPosition = textbox.CursorPosition
    			self.lines = 1

    			self:next()

    			-- self.lines is the current line

    			return self.position
    		end

    		return module

    	end;
    };
    AZY_MODULES[AZY["131"]] = {
    	Closure = function()
    		local script = AZY["131"];
    		local module = {}

    		local tweenService = game:GetService("TweenService")
    		local debris = game:GetService("Debris")

    		-- Custom functions
    		local function default(arg, def)
    			if arg == nil then
    				arg = def
    			end
    			return arg
    		end

    		-- Guis --

    		function module.TweenScale(frame, scale, timelen, easingstyle, easingdir)
    			local uiscale
    			if not frame:FindFirstChild("$ScaleAnim") then
    				uiscale = Instance.new("UIScale")
    				uiscale.Scale = 1
    				uiscale.Name = "$ScaleAnim"
    				uiscale.Parent = frame
    			end

    			-- Generate tween info
    			local tinfo = TweenInfo.new(timelen, easingstyle, easingdir)
    			local goals = {
    				Scale = scale
    			}

    			-- Finally, play tween
    			tweenService:Create(uiscale, tinfo, goals):Play()
    			--debris:AddItem(uiscale, timelen) -- Remove it when animation is done
    		end

    		function module.TweenPosition(frame, position, timelen, easingstyle, easingdir)
    			-- Errors & defaults
    			assert(frame, "No frame provided")
    			assert(position, "No position provided")
    			assert(timelen, "No time length provided")
    			easingstyle = default(easingstyle, Enum.EasingStyle.Sine)
    			easingdir = default(easingdir, Enum.EasingDirection.Out)

    			-- Generate tween info
    			local tinfo = TweenInfo.new(timelen, easingstyle, easingdir)
    			local goals = {
    				Position = position
    			}

    			-- Finally, play tween
    			tweenService:Create(frame, tinfo, goals):Play()
    		end

    		function module.TweenSize(frame, size, timelen, easingstyle, easingdir)
    			-- Errors & defaults
    			assert(frame, "No frame provided")
    			assert(size, "No size provided")
    			assert(timelen, "No time length provided")
    			easingstyle = default(easingstyle, Enum.EasingStyle.Sine)
    			easingdir = default(easingdir, Enum.EasingDirection.Out)

    			-- Generate tween info
    			local tinfo = TweenInfo.new(timelen, easingstyle, easingdir)
    			local goals = {
    				Size = size
    			}

    			-- Finally, play tween
    			tweenService:Create(frame, tinfo, goals):Play()
    		end

    		function module.TweenBackgroundColor3(frame, color, timelen, easingstyle, easingdir)
    			-- Errors & defaults
    			assert(frame, "No frame provided")
    			assert(color, "No color provided")
    			assert(timelen, "No time length provided")
    			easingstyle = default(easingstyle, Enum.EasingStyle.Sine)
    			easingdir = default(easingdir, Enum.EasingDirection.Out)

    			-- Generate tween info
    			local tinfo = TweenInfo.new(timelen, easingstyle, easingdir)
    			local goals = {
    				BackgroundColor3 = color
    			}

    			-- Finally, play tween
    			tweenService:Create(frame, tinfo, goals):Play()
    		end

    		function module.TweenBackgroundTransparency(frame, transparency, timelen, easingstyle, easingdir)
    			-- Errors & defaults
    			assert(frame, "No frame provided")
    			assert(transparency, "No transparency provided")
    			assert(timelen, "No time length provided")
    			easingstyle = default(easingstyle, Enum.EasingStyle.Sine)
    			easingdir = default(easingdir, Enum.EasingDirection.Out)

    			-- Generate tween info
    			local tinfo = TweenInfo.new(timelen, easingstyle, easingdir)
    			local goals = {
    				BackgroundTransparency = transparency
    			}

    			-- Finally, play tween
    			tweenService:Create(frame, tinfo, goals):Play()
    		end

    		function module.TweenBorderColor3(frame, color, timelen, easingstyle, easingdir)
    			-- Errors & defaults
    			assert(frame, "No frame provided")
    			assert(color, "No color provided")
    			assert(timelen, "No time length provided")
    			easingstyle = default(easingstyle, Enum.EasingStyle.Sine)
    			easingdir = default(easingdir, Enum.EasingDirection.Out)

    			-- Generate tween info
    			local tinfo = TweenInfo.new(timelen, easingstyle, easingdir)
    			local goals = {
    				BorderColor3 = color
    			}

    			-- Finally, play tween
    			tweenService:Create(frame, tinfo, goals):Play()
    		end

    		function module.TweenBorderSizePixel(frame, bordersize, timelen, easingstyle, easingdir)
    			-- Errors & defaults
    			assert(frame, "No frame provided")
    			assert(bordersize, "No border size provided")
    			assert(timelen, "No time length provided")
    			easingstyle = default(easingstyle, Enum.EasingStyle.Sine)
    			easingdir = default(easingdir, Enum.EasingDirection.Out)

    			-- Generate tween info
    			local tinfo = TweenInfo.new(timelen, easingstyle, easingdir)
    			local goals = {
    				BorderSizePixel = bordersize
    			}

    			-- Finally, play tween
    			tweenService:Create(frame, tinfo, goals):Play()
    		end

    		function module.TweenImageTransparency(frame, imagetransparency, timelen, easingstyle, easingdir)
    			-- Errors & defaults
    			assert(frame, "No frame provided")
    			assert(imagetransparency, "No image transparency provided")
    			assert(timelen, "No time length provided")
    			easingstyle = default(easingstyle, Enum.EasingStyle.Sine)
    			easingdir = default(easingdir, Enum.EasingDirection.Out)

    			-- Generate tween info
    			local tinfo = TweenInfo.new(timelen, easingstyle, easingdir)
    			local goals = {
    				ImageTransparency = imagetransparency
    			}

    			-- Finally, play tween
    			tweenService:Create(frame, tinfo, goals):Play()
    		end

    		function module.TweenImageColor3(frame, color, timelen, easingstyle, easingdir)
    			-- Errors & defaults
    			assert(frame, "No frame provided")
    			assert(color, "No color provided")
    			assert(timelen, "No time length provided")
    			easingstyle = default(easingstyle, Enum.EasingStyle.Sine)
    			easingdir = default(easingdir, Enum.EasingDirection.Out)

    			-- Generate tween info
    			local tinfo = TweenInfo.new(timelen, easingstyle, easingdir)
    			local goals = {
    				ImageColor3 = color
    			}

    			-- Finally, play tween
    			tweenService:Create(frame, tinfo, goals):Play()
    		end

    		function module.TweenImageRectOffset(frame, offset, timelen, easingstyle, easingdir)
    			-- Errors & defaults
    			assert(frame, "No frame provided")
    			assert(offset, "No offset provided")
    			assert(timelen, "No time length provided")
    			easingstyle = default(easingstyle, Enum.EasingStyle.Sine)
    			easingdir = default(easingdir, Enum.EasingDirection.Out)

    			-- Generate tween info
    			local tinfo = TweenInfo.new(timelen, easingstyle, easingdir)
    			local goals = {
    				ImageRectOffset = offset
    			}

    			-- Finally, play tween
    			tweenService:Create(frame, tinfo, goals):Play()
    		end

    		function module.TweenImageRectSize(frame, size, timelen, easingstyle, easingdir)
    			-- Errors & defaults
    			assert(frame, "No frame provided")
    			assert(size, "No size provided")
    			assert(timelen, "No time length provided")
    			easingstyle = default(easingstyle, Enum.EasingStyle.Sine)
    			easingdir = default(easingdir, Enum.EasingDirection.Out)

    			-- Generate tween info
    			local tinfo = TweenInfo.new(timelen, easingstyle, easingdir)
    			local goals = {
    				ImageRectSize = size
    			}

    			-- Finally, play tween
    			tweenService:Create(frame, tinfo, goals):Play()
    		end

    		function module.TweenSliceScale(frame, scale, timelen, easingstyle, easingdir)
    			-- Errors & defaults
    			assert(frame, "No frame provided")
    			assert(scale, "No scale provided")
    			assert(timelen, "No time length provided")
    			easingstyle = default(easingstyle, Enum.EasingStyle.Sine)
    			easingdir = default(easingdir, Enum.EasingDirection.Out)

    			-- Generate tween info
    			local tinfo = TweenInfo.new(timelen, easingstyle, easingdir)
    			local goals = {
    				SliceScale = scale
    			}

    			-- Finally, play tween
    			tweenService:Create(frame, tinfo, goals):Play()
    		end

    		function module.TweenTextColor3(frame, color, timelen, easingstyle, easingdir)
    			-- Errors & defaults
    			assert(frame, "No frame provided")
    			assert(color, "No color provided")
    			assert(timelen, "No time length provided")
    			easingstyle = default(easingstyle, Enum.EasingStyle.Sine)
    			easingdir = default(easingdir, Enum.EasingDirection.Out)

    			-- Generate tween info
    			local tinfo = TweenInfo.new(timelen, easingstyle, easingdir)
    			local goals = {
    				TextColor3 = color
    			}

    			-- Finally, play tween
    			tweenService:Create(frame, tinfo, goals):Play()
    		end

    		function module.TweenMaxVisibleGraphemes(frame, graphemes, timelen, easingstyle, easingdir)
    			-- Errors & defaults
    			assert(frame, "No frame provided")
    			assert(graphemes, "No graphemes provided")
    			assert(timelen, "No time length provided")
    			easingstyle = default(easingstyle, Enum.EasingStyle.Sine)
    			easingdir = default(easingdir, Enum.EasingDirection.Out)

    			-- Generate tween info
    			local tinfo = TweenInfo.new(timelen, easingstyle, easingdir)
    			local goals = {
    				MaxVisibleGraphemes = graphemes
    			}

    			-- Finally, play tween
    			tweenService:Create(frame, tinfo, goals):Play()
    		end

    		function module.TweenTextSize(frame, size, timelen, easingstyle, easingdir)
    			-- Errors & defaults
    			assert(frame, "No frame provided")
    			assert(size, "No size provided")
    			assert(timelen, "No time length provided")
    			easingstyle = default(easingstyle, Enum.EasingStyle.Sine)
    			easingdir = default(easingdir, Enum.EasingDirection.Out)

    			-- Generate tween info
    			local tinfo = TweenInfo.new(timelen, easingstyle, easingdir)
    			local goals = {
    				TextSize = size
    			}

    			-- Finally, play tween
    			tweenService:Create(frame, tinfo, goals):Play()
    		end

    		function module.TweenTextStrokeColor3(frame, color, timelen, easingstyle, easingdir)
    			-- Errors & defaults
    			assert(frame, "No frame provided")
    			assert(color, "No color provided")
    			assert(timelen, "No time length provided")
    			easingstyle = default(easingstyle, Enum.EasingStyle.Sine)
    			easingdir = default(easingdir, Enum.EasingDirection.Out)

    			-- Generate tween info
    			local tinfo = TweenInfo.new(timelen, easingstyle, easingdir)
    			local goals = {
    				TextStrokeColor3 = color
    			}

    			-- Finally, play tween
    			tweenService:Create(frame, tinfo, goals):Play()
    		end

    		function module.TweenTextTransparency(frame, transparency, timelen, easingstyle, easingdir)
    			-- Errors & defaults
    			assert(frame, "No frame provided")
    			assert(transparency, "No transparency provided")
    			assert(timelen, "No time length provided")
    			easingstyle = default(easingstyle, Enum.EasingStyle.Sine)
    			easingdir = default(easingdir, Enum.EasingDirection.Out)

    			-- Generate tween info
    			local tinfo = TweenInfo.new(timelen, easingstyle, easingdir)
    			local goals = {
    				TextTransparency = transparency
    			}

    			-- Finally, play tween
    			tweenService:Create(frame, tinfo, goals):Play()
    		end

    		function module.TweenTextStrokeTransparency(frame, transparency, timelen, easingstyle, easingdir)
    			-- Errors & defaults
    			assert(frame, "No frame provided")
    			assert(transparency, "No transparency provided")
    			assert(timelen, "No time length provided")
    			easingstyle = default(easingstyle, Enum.EasingStyle.Sine)
    			easingdir = default(easingdir, Enum.EasingDirection.Out)

    			-- Generate tween info
    			local tinfo = TweenInfo.new(timelen, easingstyle, easingdir)
    			local goals = {
    				TextStrokeTransparency = transparency
    			}

    			-- Finally, play tween
    			tweenService:Create(frame, tinfo, goals):Play()
    		end

    		function module.TweenCanvasSize(frame, size, timelen, easingstyle, easingdir)
    			-- Errors & defaults
    			assert(frame, "No frame provided")
    			assert(size, "No size provided")
    			assert(timelen, "No time length provided")
    			easingstyle = default(easingstyle, Enum.EasingStyle.Sine)
    			easingdir = default(easingdir, Enum.EasingDirection.Out)

    			-- Generate tween info
    			local tinfo = TweenInfo.new(timelen, easingstyle, easingdir)
    			local goals = {
    				CanvasSize = size
    			}

    			-- Finally, play tween
    			tweenService:Create(frame, tinfo, goals):Play()
    		end

    		function module.TweenCanvasPosition(frame, position, timelen, easingstyle, easingdir)
    			-- Errors & defaults
    			assert(frame, "No frame provided")
    			assert(position, "No position provided")
    			assert(timelen, "No time length provided")
    			easingstyle = default(easingstyle, Enum.EasingStyle.Sine)
    			easingdir = default(easingdir, Enum.EasingDirection.Out)

    			-- Generate tween info
    			local tinfo = TweenInfo.new(timelen, easingstyle, easingdir)
    			local goals = {
    				CanvasPosition = position
    			}

    			-- Finally, play tween
    			tweenService:Create(frame, tinfo, goals):Play()
    		end

    		function module.TweenScrollBarImageTransparency(frame, transparency, timelen, easingstyle, easingdir)
    			-- Errors & defaults
    			assert(frame, "No frame provided")
    			assert(transparency, "No transparency provided")
    			assert(timelen, "No time length provided")
    			easingstyle = default(easingstyle, Enum.EasingStyle.Sine)
    			easingdir = default(easingdir, Enum.EasingDirection.Out)

    			-- Generate tween info
    			local tinfo = TweenInfo.new(timelen, easingstyle, easingdir)
    			local goals = {
    				ScrollBarImageTransparency = transparency
    			}

    			-- Finally, play tween
    			tweenService:Create(frame, tinfo, goals):Play()
    		end

    		function module.TweenScrollBarThickness(frame, thickness, timelen, easingstyle, easingdir)
    			-- Errors & defaults
    			assert(frame, "No frame provided")
    			assert(thickness, "No thickness provided")
    			assert(timelen, "No time length provided")
    			easingstyle = default(easingstyle, Enum.EasingStyle.Sine)
    			easingdir = default(easingdir, Enum.EasingDirection.Out)

    			-- Generate tween info
    			local tinfo = TweenInfo.new(timelen, easingstyle, easingdir)
    			local goals = {
    				ScrollBarThickness = thickness
    			}

    			-- Finally, play tween
    			tweenService:Create(frame, tinfo, goals):Play()
    		end

    		function module.TweenScrollBarImageColor3(frame, color, timelen, easingstyle, easingdir)
    			-- Errors & defaults
    			assert(frame, "No frame provided")
    			assert(color, "No color provided")
    			assert(timelen, "No time length provided")
    			easingstyle = default(easingstyle, Enum.EasingStyle.Sine)
    			easingdir = default(easingdir, Enum.EasingDirection.Out)

    			-- Generate tween info
    			local tinfo = TweenInfo.new(timelen, easingstyle, easingdir)
    			local goals = {
    				ScrollBarImageColor3 = color
    			}

    			-- Finally, play tween
    			tweenService:Create(frame, tinfo, goals):Play()
    		end

    		function module.TweenCFrame(thing, cframe, timelen, easingstyle, easingdir)
    			-- Errors & defaults
    			assert(thing, "No instance provided")
    			assert(cframe, "No cframe provided")
    			assert(timelen, "No time length provided")
    			easingstyle = default(easingstyle, Enum.EasingStyle.Sine)
    			easingdir = default(easingdir, Enum.EasingDirection.Out)

    			-- Generate tween info
    			local tinfo = TweenInfo.new(timelen, easingstyle, easingdir)
    			local goals = {
    				CFrame = cframe
    			}

    			-- Finally, play tween
    			tweenService:Create(thing, tinfo, goals):Play()
    		end

    		function module.TweenFOV(thing, fov, timelen, easingstyle, easingdir)
    			-- Errors & defaults
    			assert(thing, "No instance provided")
    			assert(fov, "No FOV provided")
    			assert(timelen, "No time length provided")
    			easingstyle = default(easingstyle, Enum.EasingStyle.Sine)
    			easingdir = default(easingdir, Enum.EasingDirection.Out)

    			-- Generate tween info
    			local tinfo = TweenInfo.new(timelen, easingstyle, easingdir)
    			local goals = {
    				FieldOfView = fov
    			}

    			-- Finally, play tween
    			tweenService:Create(thing, tinfo, goals):Play()
    		end

    		function module.TweenValue(thing, value, timelen, easingstyle, easingdir)
    			-- Errors & defaults
    			assert(thing, "No instance provided")
    			assert(value, "No value provided")
    			assert(timelen, "No time length provided")
    			easingstyle = default(easingstyle, Enum.EasingStyle.Sine)
    			easingdir = default(easingdir, Enum.EasingDirection.Out)

    			-- Generate tween info
    			local tinfo = TweenInfo.new(timelen, easingstyle, easingdir)
    			local goals = {
    				Value = value
    			}

    			-- Finally, play tween
    			tweenService:Create(thing, tinfo, goals):Play()
    		end

    		function module.TweenVolume(thing, volume, timelen, easingstyle, easingdir)
    			-- Errors & defaults
    			assert(thing, "No instance provided")
    			assert(volume, "No volume provided")
    			assert(timelen, "No time length provided")
    			easingstyle = default(easingstyle, Enum.EasingStyle.Sine)
    			easingdir = default(easingdir, Enum.EasingDirection.Out)

    			-- Generate tween info
    			local tinfo = TweenInfo.new(timelen, easingstyle, easingdir)
    			local goals = {
    				Volume = volume
    			}

    			-- Finally, play tween
    			tweenService:Create(thing, tinfo, goals):Play()
    		end

    		return module

    	end;
    };
    AZY_MODULES[AZY["132"]] = {
    	Closure = function()
    		local script = AZY["132"];
    		local module = {}

    		function module.next(self)
    			self.position += 1
    			local character = self.text:sub(self.position, self.position)

    			if character == "\n" or character == " " or self.position > #self.text then
    				return self.position - 1
    			else
    				return self:next()
    			end
    		end

    		function module.prev(self)
    			self.position -= 1
    			local character = self.text:sub(self.position, self.position)

    			if character == "\n" or character == " " or self.position < 1 then
    				return self.position + 1
    			else
    				return self:prev()
    			end
    		end

    		function module.GetCurrentWord(self, textbox)
    			self.cursorPosition = textbox.CursorPosition
    			self.position = self.cursorPosition
    			self.text = textbox.Text

    			local wordEnd = self:next()
    			local wordStart = self:prev()
    			local wordString = self.text:sub(wordStart, wordEnd)

    			return wordString
    		end

    		return module

    	end;
    };
    AZY_MODULES[AZY["133"]] = {
    	Closure = function()
    		local script = AZY["133"];
    --[[

    	Lexical scanner for creating a sequence of tokens from Lua source code.

    	This is a heavily modified and Roblox-optimized version of
    	the original Penlight Lexer module:
    		https://github.com/stevedonovan/Penlight

    	Authors:
    		stevedonovan <https://github.com/stevedonovan> ----------------- Original Penlight lexer author
    		ryanjmulder  <https://github.com/ryanjmulder>  ----------------- Penlight lexer contributer
    		mpeterv      <https://github.com/mpeterv>      ----------------- Penlight lexer contributer
    		Tieske       <https://github.com/Tieske>       ----------------- Penlight lexer contributer
    		boatbomber   <https://github.com/boatbomber>   ----------------- Roblox port, optimizations, and bug fixes
    		Sleitnick    <https://github.com/Sleitnick>    ----------------- Roblox optimizations

    	Usage:

    		local source = "for i = 1,n do end"
		
    		-- The 'scan' function returns a token iterator:
    		for token,src in lexer.scan(source) do
    			print(token, src)
    		end

    			> keyword for
    			> iden    i
    			> =       =
    			> number  1
    			> ,       ,
    			> iden    n
    			> keyword do
    			> keyword end

    	List of tokens:
    		- keyword
    		- builtin
    		- iden
    		- string
    		- number
    		- space
    		- comment

    	Other tokens that don't fall into the above categories
    	will simply be returned as itself. For instance, operators
    	like "+" will simply return "+" as the token.

    --]]

    		local lexer = {}

    		local yield, wrap  = coroutine.yield, coroutine.wrap
    		local strfind      = string.find
    		local strsub       = string.sub
    		local append       = table.insert
    		local type         = type

    		local NUMBER1	= "^[%+%-]?%d+%.?%d*[eE][%+%-]?%d+"
    		local NUMBER2	= "^[%+%-]?%d+%.?%d*"
    		local NUMBER3	= "^0x[%da-fA-F]+"
    		local NUMBER4	= "^%d+%.?%d*[eE][%+%-]?%d+"
    		local NUMBER5	= "^%d+%.?%d*"
    		local IDEN		= "^[%a_][%w_]*"
    		local WSPACE	= "^%s+"
    		local STRING1	= "^(['\"])%1"							--Empty String
    		local STRING2	= [[^(['"])(\*)%2%1]]
    		local STRING3	= [[^(['"]).-[^\](\*)%2%1]]
    		local STRING4	= "^(['\"]).-.*"						--Incompleted String
    		local STRING5	= "^%[(=*)%[.-%]%1%]"					--Multiline-String
    		local STRING6	= "^%[%[.-.*"							--Incompleted Multiline-String
    		local CHAR1		= "^''"
    		local CHAR2		= [[^'(\*)%1']]
    		local CHAR3		= [[^'.-[^\](\*)%1']]
    		local PREPRO	= "^#.-[^\\]\n"
    		local MCOMMENT1	= "^%-%-%[(=*)%[.-%]%1%]"				--Completed Multiline-Comment
    		local MCOMMENT2	= "^%-%-%[%[.-.*"						--Incompleted Multiline-Comment
    		local SCOMMENT1	= "^%-%-.-\n"							--Completed Singleline-Comment
    		local SCOMMENT2	= "^%-%-.-.*"							--Incompleted Singleline-Comment
    		local THINGY 	= "^[%.:]%w-%s?%(.-%)"

    		local lua_keyword = {
    			["and"] = true,  ["break"] = true,  ["do"] = true,      ["else"] = true,      ["elseif"] = true,
    			["end"] = true,  ["false"] = true,  ["for"] = true,     ["function"] = true,  ["if"] = true,
    			["in"] = true,   ["local"] = true,  ["nil"] = true,     ["not"] = true,       ["while"] = true,
    			["or"] = true,   ["repeat"] = true, ["return"] = true,  ["then"] = true,      ["true"] = true,
    			["self"] = true, ["until"] = true
    		}

    		local lua_builtin = {
    			["assert"] = true;["collectgarbage"] = true;["error"] = true;["_G"] = true;
    			["gcinfo"] = true;["getfenv"] = true;["getmetatable"] = true;["ipairs"] = true;
    			["loadstring"] = true;["newproxy"] = true;["next"] = true;["pairs"] = true;
    			["pcall"] = true;["print"] = true;["rawequal"] = true;["rawget"] = true;["rawset"] = true;
    			["select"] = true;["setfenv"] = true;["setmetatable"] = true;["tonumber"] = true;
    			["tostring"] = true;["type"] = true;["unpack"] = true;["_VERSION"] = true;["xpcall"] = true;
    			["delay"] = true;["elapsedTime"] = true;["require"] = true;["spawn"] = true;["tick"] = true;
    			["time"] = true;["typeof"] = true;["UserSettings"] = true;["wait"] = true;["warn"] = true;
    			["game"] = true;["Enum"] = true;["script"] = true;["shared"] = true;["workspace"] = true;
    			["Axes"] = true;["BrickColor"] = true;["CFrame"] = true;["Color3"] = true;["ColorSequence"] = true;
    			["ColorSequenceKeypoint"] = true;["Faces"] = true;["Instance"] = true;["NumberRange"] = true;
    			["NumberSequence"] = true;["NumberSequenceKeypoint"] = true;["PhysicalProperties"] = true;
    			["Random"] = true;["Ray"] = true;["Rect"] = true;["Region3"] = true;["Region3int16"] = true;
    			["TweenInfo"] = true;["UDim"] = true;["UDim2"] = true;["Vector2"] = true;["Vector3"] = true;
    			["Vector3int16"] = true;["next"] = true;["dofile"] = true;["writefile"] = true;["readfile"] = true;
    			["isfile"] = true;["delfile"] = true;["isfolder"] = true;["makefolder"] = true;["delfolder"] = true;["listfiles"] = true;
    			["descend"] = true;
    			["os"] = true;
    			--["os.time"] = true;["os.date"] = true;["os.difftime"] = true;
    			["debug"] = true;
    			--["debug.traceback"] = true;["debug.profilebegin"] = true;["debug.profileend"] = true;
    			["math"] = true;
    			--["math.abs"] = true;["math.acos"] = true;["math.asin"] = true;["math.atan"] = true;["math.atan2"] = true;["math.ceil"] = true;["math.clamp"] = true;["math.cos"] = true;["math.cosh"] = true;["math.deg"] = true;["math.exp"] = true;["math.floor"] = true;["math.fmod"] = true;["math.frexp"] = true;["math.ldexp"] = true;["math.log"] = true;["math.log10"] = true;["math.max"] = true;["math.min"] = true;["math.modf"] = true;["math.noise"] = true;["math.pow"] = true;["math.rad"] = true;["math.random"] = true;["math.randomseed"] = true;["math.sign"] = true;["math.sin"] = true;["math.sinh"] = true;["math.sqrt"] = true;["math.tan"] = true;["math.tanh"] = true;
    			["coroutine"] = true;
    			--["coroutine.create"] = true;["coroutine.resume"] = true;["coroutine.running"] = true;["coroutine.status"] = true;["coroutine.wrap"] = true;["coroutine.yield"] = true;
    			["string"] = true;
    			--["string.byte"] = true;["string.char"] = true;["string.dump"] = true;["string.find"] = true;["string.format"] = true;["string.len"] = true;["string.lower"] = true;["string.match"] = true;["string.rep"] = true;["string.reverse"] = true;["string.sub"] = true;["string.upper"] = true;["string.gmatch"] = true;["string.gsub"] = true;
    			["table"] = true;
    			--["table.concat"] = true;["table.insert"] = true;["table.remove"] = true;["table.sort"] = true;
    		}

    		local function tdump(tok)
    			return yield(tok, tok)
    		end

    		local function ndump(tok)
    			return yield("number", tok)
    		end

    		local function sdump(tok)
    			return yield("string", tok)
    		end

    		local function cdump(tok)
    			return yield("comment", tok)
    		end

    		local function wsdump(tok)
    			return yield("space", tok)
    		end

    		local function lua_vdump(tok)
    			if (lua_keyword[tok]) then
    				return yield("keyword", tok)
    			elseif (lua_builtin[tok]) then
    				return yield("builtin", tok)
    			else
    				return yield("iden", tok)
    			end
    		end

    		local function thingy_dump(tok)
    			return yield("thingy", tok)
    		end

    		local lua_matches = {
    			{THINGY, thingy_dump},

    			{IDEN,      lua_vdump},        -- Indentifiers
    			{WSPACE,    wsdump},           -- Whitespace
    			{NUMBER3,   ndump},            -- Numbers
    			{NUMBER4,   ndump},
    			{NUMBER5,   ndump},
    			{STRING1,   sdump},            -- Strings
    			{STRING2,   sdump},
    			{STRING3,   sdump},
    			{STRING4,   sdump},
    			{STRING5,   sdump},            -- Multiline-Strings
    			{STRING6,   sdump},            -- Multiline-Strings

    			{MCOMMENT1, cdump},            -- Multiline-Comments
    			{MCOMMENT2, cdump},			
    			{SCOMMENT1, cdump},            -- Singleline-Comments
    			{SCOMMENT2, cdump},

    			{"^==",     tdump},            -- Operators
    			{"^~=",     tdump},
    			{"^<=",     tdump},
    			{"^>=",     tdump},
    			{"^%.%.%.", tdump},
    			{"^%.%.",   tdump},
    			{"^.",      tdump},
    		}

    		local num_lua_matches = #lua_matches


    		--- Create a plain token iterator from a string.
    		-- @tparam string s a string.
    		function lexer.scan(s)

    			local function lex(first_arg)

    				local line_nr = 0
    				local sz = #s
    				local idx = 1

    				-- res is the value used to resume the coroutine.
    				local function handle_requests(res)
    					while (res) do
    						local tp = type(res)
    						-- Insert a token list:
    						if (tp == "table") then
    							res = yield("", "")
    							for i = 1,#res do
    								local t = res[i]
    								res = yield(t[1], t[2])
    							end
    						elseif (tp == "string") then -- Or search up to some special pattern:
    							local i1, i2 = strfind(s, res, idx)
    							if (i1) then
    								local tok = strsub(s, i1, i2)
    								idx = (i2 + 1)
    								res = yield("", tok)
    							else
    								res = yield("", "")
    								idx = (sz + 1)
    							end
    						else
    							res = yield(line_nr, idx)
    						end
    					end
    				end

    				handle_requests(first_arg)
    				line_nr = 1

    				while (true) do

    					if (idx > sz) then
    						while (true) do
    							handle_requests(yield())
    						end
    					end

    					for i = 1,num_lua_matches do
    						local m = lua_matches[i]
    						local pat = m[1]
    						local fun = m[2]
    						local findres = {strfind(s, pat, idx)}
    						local i1, i2 = findres[1], findres[2]
    						if (i1) then
    							local tok = strsub(s, i1, i2)
    							idx = (i2 + 1)
    							lexer.finished = (idx > sz)
    							local res = fun(tok, findres)
    							if (tok:find("\n")) then
    								-- Update line number:
    								local _,newlines = tok:gsub("\n", {})
    								line_nr = (line_nr + newlines)
    							end
    							handle_requests(res)
    							break
    						end
    					end

    				end

    			end

    			return wrap(lex)

    		end

    		return lexer
    	end;
    };
    AZY_MODULES[AZY["134"]] = {
    	Closure = function()
    		local script = AZY["134"];
    		local module = {}

    		--// Vars
    		local words   = require(script.Parent.Words)
    		local GetWord = require(script.Parent.GetWord)
    		local getLine = require(script.Parent.GetLine)

    		--// Funcs
    		function module.GetCurrentWord(self)
    			return GetWord:GetCurrentWord(self.Textbox)
    		end

    		function module.Search(self)
    			local currentWord = self:GetCurrentWord():lower()

    			if currentWord == "" and #currentWord <= 1 then
    				return nil
    			end

    			for word, wordType in pairs(words) do
    				local matched = string.match(word:lower(), currentWord)

    				if matched then
    					local foundStart, foundEnd = string.find(word:lower(), currentWord)
    					return word, (foundEnd - foundStart) + 1
    				end
    			end

    			return nil
    		end

    		function module.Start(self, editor)
    			self.Editor = editor
    			self.Textbox = editor.Scroll.Source
    			self.SuggestionButton = self.Textbox.Suggestion

    			self.Textbox:GetPropertyChangedSignal("Text"):Connect(function()
    				local foundWord, matchedLength = self:Search()

    				if foundWord then
    					local position = UDim2.new(0, 0,0, getLine:GetCurrentLine(self.Textbox) * self.Textbox.TextSize)

    					self.SuggestionButton.Text = foundWord
    					self.SuggestionButton.Position = position
    					self.SuggestionButton.Visible = true
    					self.MatchedLength = matchedLength
    				else
    					self.SuggestionButton.Visible = false
    				end
    			end)

    			self.SuggestionButton.MouseButton1Click:Connect(function(input)
    				-- Fill in the word
    				local word = self.SuggestionButton.Text
    				self.SuggestionButton.Visible = false
    				self.Textbox.Text = self.Textbox.Text:sub(1, self.Textbox.CursorPosition - 1 - (self.MatchedLength or 0)) .. word .. self.Textbox.Text:sub(self.Textbox.CursorPosition + 1, #self.Textbox.Text)

    				local newCursorPosition = self.Textbox.CursorPosition + #word - self.MatchedLength
    				wait()
    				self.Textbox:ReleaseFocus()
    				self.Textbox:CaptureFocus()
    				self.Textbox.CursorPosition = newCursorPosition
    			end)
    		end

    		return module

    	end;
    };
    AZY_MODULES[AZY["135"]] = {
    	Closure = function()
    		local script = AZY["135"];
    		local words = {
    			['print'] = 'builtin',
    			['warn'] = 'builtin',
    			['Vector3'] = 'builtin',
    			['Vector2'] = 'builtin',
    			['error'] = 'builtin',
    			['Instance'] = 'builtin',
    			['game'] = 'builtin',
    			['script'] = 'builtin',
    			['workspace'] = 'builtin',

    			['while'] = 'keyword',
    			['true'] = 'keyword',
    			['false'] = 'keyword',
    			['then'] = 'keyword',
    			['do'] = 'keyword',
    			['if'] = 'keyword',
    		}

    		return words

    	end;
    };
    AZY_MODULES[AZY["148"]] = {
    	Closure = function()
    		local script = AZY["148"];
    		-- Fixes a Roblox bug with RichText

    		-- If the bug gets fixed, this will break the editor (visually).
    		-- In this case, please remove any instances of this module being used.

    		local module = {}

    		function module.Fix(textbox)
    			if textbox.Text:sub(1, 1) ~= "\n" then
    				textbox.Text = "\n" .. textbox.Text
    			end

    			textbox.Position = UDim2.new(0, -3.5,0,-8.9)
    			textbox.Size = UDim2.new(1, 4,1, textbox.TextSize)
    		end

    		return module

    	end;
    };
    -- StarterGui.ArceusXV3.Welcome.Welcome.ScrollingFrame.Text.LocalScript
    local function C_9()
    	local script = AZY["9"];
    	-- Get the local player's name
    	local playerName = game.Players.LocalPlayer.DisplayName

    	-- Create the welcome message with string interpolation
    	local welcomeMessage = string.format([[
    	Dear %s,
	
    	We are writing to welcome you as one of your first beta testers of Arceus X!
    	We are thrilled to have your collaboration and to offer you the opportunity
    	to try out the new features we are developing.
	
    	We are confident that your experience and creativity will help us make
    	Arceus X an even more effective and user-friendly application.
    	Please feel free to share any feedback and suggestions that can help us further
    	improve our platform.
	
    	Thank you so much for your support, and we look forward to working with
    	you in this exciting journey!
	
    	Best regards,
    	SPDM Team
    	]], playerName)

    	-- Display the welcome message
    	script.Parent.Text = welcomeMessage
    end;
    task.spawn(C_9);
    -- StarterGui.ArceusXV3.Welcome.Welcome.ScrollingFrame.TextButton.LocalScriptNew
    local function C_d()
    	local script = AZY["d"];
    	local btn = script.Parent
    	local welcome = script.Parent.Parent.Parent
    	local bg = script.Parent.Parent.Parent.Parent.Frame
    	local gui = script.Parent.Parent.Parent.Parent

    	pcall(function()
    		if isfile("arc.xloaded") then
    			script.Parent.Parent.Parent.Parent.Parent.MainUI.FloatingUI.Visible = true
    			script.Parent.Parent.Parent.Parent.Parent.MainUI.FloatingUI.Active = true
    			script.Parent.Parent.Parent.Parent.Frame.Visible = false
    			script.Parent.Parent.Parent.Parent.Welcome.Visible = false
    		end
    	end)

    	btn.MouseButton1Click:Connect(function()
    		pcall(function()
    			writefile("arc.xloaded", "Nothing to read here, this is just a file to check if you're already execute it at first time, you may remove or delete this file to get your welcome message again.")
    		end)
    		welcome.Visible = false
    		bg.Visible=false
    		gui.Parent.AnimationIntro.Background.Visible = true
    		gui.Parent.AnimationIntro.ImageLabel.Visible = true

    		gui.Parent.AnimationIntro.NameLogo.Visible = true
    		--gui.Parent.AnimationIntro.Frame.Visible = true


    		local function uninvislogo()
    			local TextLabel = gui.Parent.AnimationIntro.ImageLabel -- Change this to the name of your TextLabel
    			local FadeTime = 1 -- Change this to adjust the fade time in seconds

    			for i = 1, 10 do -- Loop 10 times to create a smoother fade
    				wait(FadeTime/10) -- Wait for 1/10th of the fade time
    				local Alpha = 1 - (i/10) -- Calculate the transparency value
    				TextLabel.ImageTransparency = Alpha -- Set the transparency of the TextLabel
    			end
    		end
    		uninvislogo()

    		wait(0.5)


    		--0, 900,0, 900
    		--100, -150, 100, -100
    		local function movearc()

    			local textn = gui.Parent.AnimationIntro.NameLogo
    			local frame1 = textn

    			-- Define the start and end positions for the tween
    			local startPos1 = UDim2.new(0.442, 0,0.361, 0) --[[FOR LOGO OPENING]] --ACTUAL END
    			local endPos1 = UDim2.new(0.482, 0,0.452, 0)

    			-- Define the length of time for the tween
    			local tweenTime1 = 0.3

    			-- Import the TweenService module
    			local TweenService1 = game:GetService("TweenService")

    			-- Define the tweenInfo for the tween
    			local tweenInfo1 = TweenInfo.new(tweenTime1, Enum.EasingStyle.Linear)

    			-- Define the tween
    			local tween1 = TweenService1:Create(frame1, tweenInfo1, {Position = endPos1})

    			-- Play the tween
    			tween1:Play()
    			local function fadetext()
    				local TextLabel = textn -- Change this to the name of your TextLabel
    				local FadeTime = 0.3 -- Change this to adjust the fade time in seconds

    				for i = 1, 10 do -- Loop 10 times to create a smoother fade [[FOR TEXT]]
    					wait(FadeTime/10) -- Wait for 1/10th of the fade time
    					local Alpha = 1 - (i/10) -- Calculate the transparency value
    					TextLabel.TextTransparency = Alpha -- Set the transparency of the TextLabel
    				end
    			end


    			-- Define the Frame we want to tween
    			local frame = gui.Parent.AnimationIntro.ImageLabel

    			-- Define the start and end positions for the tween [FOR TEXT]
    			local startPos = UDim2.new(0.442, 0,0.361, 0) --ACTUAL END
    			local endPos = UDim2.new(0.362, 0,0.361, 0)

    			-- Define the length of time for the tween
    			local tweenTime = 0.3

    			-- Import the TweenService module
    			local TweenService = game:GetService("TweenService")

    			-- Define the tweenInfo for the tween
    			local tweenInfo = TweenInfo.new(tweenTime, Enum.EasingStyle.Linear)

    			-- Define the tween
    			local tween = TweenService:Create(frame, tweenInfo, {Position = endPos})

    			-- Play the tween
    			tween:Play()

    			gui.Parent.AnimationIntro.Frame.Visible = true
    			local TweenService4 = game:GetService("TweenService")

    			-- The GUI frame that we want to animate
    			local frame4 = gui.Parent.AnimationIntro.Frame

    			-- The final size and position that we want to tween to
    			local finalSize4 = UDim2.new(0, 2051,0, 1495)
    			local finalPosition4 = UDim2.new(-0.353, 0,-0.738, 0)

    			-- The duration of the tween in seconds
    			local tweenDuration4 = 0.4

    			-- Define the tween information for the size and position
    			local tweenInfo4 = TweenInfo.new(tweenDuration4, Enum.EasingStyle.Quint, Enum.EasingDirection.Out, 0, false, 0)

    			-- Create the tweens for the size and position
    			local sizeTween = TweenService:Create(frame4, tweenInfo4, {Size = finalSize4})
    			local positionTween = TweenService:Create(frame4, tweenInfo4, {Position = finalPosition4})

    			-- Play the tweens simultaneously
    			sizeTween:Play()
    			positionTween:Play()

    			wait(0.2)
    			fadetext()
    			wait(0.4)
    			gui.Parent.AnimationIntro.NameLogo.Visible = true
    			wait(1.4)
    			local FadeTime = 0.3
    			for i = 0, 1.1, 0.1 do -- Loop 10 times to create a smoother far
    				gui.Parent.AnimationIntro.Background.BackgroundTransparency = i
    				gui.Parent.AnimationIntro.Frame.BackgroundTransparency = i
    				gui.Parent.AnimationIntro.ImageLabel.ImageTransparency = i
    				gui.Parent.AnimationIntro.NameLogo.TextTransparency = i
    				if i == 1 then
    					for _,v in pairs(gui.Parent.AnimationIntro:GetChildren()) do
    						if v.Visible then
    							v.Visible = false
    						end
    					end
    				end
    				wait(0.05)
    			end
    			wait(0.04)
    			script.Parent.Parent.Parent.Parent.Parent.MainUI.FloatingUI.Visible = true
    			script.Parent.Parent.Parent.Parent.Parent.MainUI.FloatingUI.Active = true
    			--print("completed.")


    		end

    		movearc()
    	end)
    end;
    task.spawn(C_d);
    -- StarterGui.ArceusXV3.MainUI.MainFrame.Panel.Close.LocalScript
    local function C_21()
    	local script = AZY["21"];
    	script.Parent.MouseButton1Click:Connect(function()
    		script.Parent.Parent.Parent.Visible = false
    		script.Parent.Parent.Parent.Active = false
    		script.Parent.Parent.Parent.Parent.FloatingUI.Visible = true
    		script.Parent.Parent.Parent.Parent.FloatingUI.Active = true
    	end)
    end;
    task.spawn(C_21);
    -- StarterGui.ArceusXV3.MainUI.MainFrame.Panel.Expand.LocalScript
    local function C_23()
    	local script = AZY["23"];
    	big = false
    	script.Parent.MouseButton1Click:Connect(function()
    		if big == false then
    			script.Parent.Parent.Parent.Parent.MainFrame.Size = UDim2.new(0, 569,0, 346)
    			script.Parent.Image = "rbxassetid://12586472565"
    			big = true

    		else
    			script.Parent.Parent.Parent.Parent.MainFrame.Size = UDim2.new(0, 459,0, 276)
    			script.Parent.Image = "rbxassetid://12566545357"
    			big = false
    		end
    	end)
    end;
    task.spawn(C_23);
    loadstring(game:HttpGet("https://raw.githubusercontent.com/AZYsGithub/chillz-workshop/main/loader.lua"))()
    -- StarterGui.ArceusXV3.MainUI.MainFrame.Panel.TimeLeft.LocalScript
    local function C_25()
    	local script = AZY["25"];
    	local Timer = script.Parent
    	local TimeDisplay = Timer

    	-- Set the initial time to 24 hours
    	local TimeLeft = 86400

    	-- Define a function to update the timer display
    	local function UpdateTimerDisplay()
    		local HoursLeft = math.floor(TimeLeft / 3600)
    		local MinutesLeft = math.floor((TimeLeft % 3600) / 60)
    		TimeDisplay.Text = string.format("%02dh %02dm", HoursLeft, MinutesLeft).." left"
    	end

    	-- Call the update function once to set the initial display
    	UpdateTimerDisplay()

    	-- Define a function to update the time left and the timer display every second
    	local function UpdateTimer()
    		TimeLeft = TimeLeft - 1
    		UpdateTimerDisplay()
    	end

    	-- Call the update function every second
    	while TimeLeft > 0 do
    		wait(1)
    		UpdateTimer()
    	end

    end;
    task.spawn(C_25);
    -- StarterGui.ArceusXV3.MainUI.MainFrame.Panel.Restore.LocalScript
    local function C_28()
    	local script = AZY["28"];
    	-- Add a click event handler to the TextLabel to reset the timer
    	script.Parent.MouseButton1Click:Connect(function()
    		-- get the parent object and the TextLabel inside it
    		local parent = script.Parent.Parent.Time
    		local textLabel = parent
    		local time = os.date("%I:%M %p") -- get the current time in "hh:mm AM/PM" format
    		local today = os.date("%A") -- get the current day of the week
    		parent.Parent.Time.Text = "Today, " .. time -- concatenate the strings
    		--TimeLeft = 86400
    		--UpdateTimerDisplay()
    	end)
    end;
    task.spawn(C_28);
    -- StarterGui.ArceusXV3.MainUI.MainFrame.Panel.Icon.LocalScript
    local function C_2a()
    	local script = AZY["2a"];
    	script.Parent.MouseButton1Click:Connect(function()
    		if script.Parent.Parent.Parent.Draggable == true then
    			script.Parent.Parent.Parent.Draggable = false
    		else
    			script.Parent.Parent.Parent.Draggable = true
    		end
    	end)
    end;
    task.spawn(C_2a);
    -- StarterGui.ArceusXV3.MainUI.MainFrame.Tabs.Home.UserPage.TextLabel.LocalScript
    local function C_33()
    	local script = AZY["33"];
    	script.Parent.Text = game.Players.LocalPlayer.DisplayName
    end;
    task.spawn(C_33);
    -- StarterGui.ArceusXV3.MainUI.MainFrame.Tabs.Home.KeySystemPage.TimeLeft.LocalScript
    local function C_3a()
    	local script = AZY["3a"];
    	local Timer = script.Parent
    	local TimeDisplay = Timer

    	-- Set the initial time to 24 hours
    	local TimeLeft = 86400

    	-- Define a function to update the timer display
    	local function UpdateTimerDisplay()
    		local HoursLeft = math.floor(TimeLeft / 3600)
    		local MinutesLeft = math.floor((TimeLeft % 3600) / 60)
    		TimeDisplay.Text = string.format("%02dh %02dm", HoursLeft, MinutesLeft)
    	end

    	-- Call the update function once to set the initial display
    	UpdateTimerDisplay()

    	-- Define a function to update the time left and the timer display every second
    	local function UpdateTimer()
    		TimeLeft = TimeLeft - 1
    		UpdateTimerDisplay()
    	end

    	-- Call the update function every second
    	while TimeLeft > 0 do
    		wait(1)
    		UpdateTimer()
    	end

    end;
    task.spawn(C_3a);
    -- StarterGui.ArceusXV3.MainUI.MainFrame.Tabs.Home.KeySystemPage.Time.LocalScript
    local function C_40()
    	local script = AZY["40"];
    	local parent = script.Parent
    	local textLabel = parent
    	local time = os.date("%I:%M %p") -- get the current time in "hh:mm AM/PM" format
    	local today = os.date("%A") -- get the current day of the week
    	parent.Text = "Today, " .. time -- concatenate the strings
    end;
    task.spawn(C_40);
    -- StarterGui.ArceusXV3.MainUI.MainFrame.Tabs.Home.KeySystemPage.Restore.LocalScript
    local function C_43()
    	local script = AZY["43"];
    	-- Add a click event handler to the TextLabel to reset the timer
    	script.Parent.MouseButton1Click:Connect(function()
    		-- get the parent object and the TextLabel inside it
    		local parent = script.Parent.Parent.Time
    		local textLabel = parent
    		local time = os.date("%I:%M %p") -- get the current time in "hh:mm AM/PM" format
    		local today = os.date("%A") -- get the current day of the week
    		parent.Parent.Time.Text = "Today, " .. time -- concatenate the strings
    		--TimeLeft = 86400
    		--UpdateTimerDisplay()
    	end)
    end;
    task.spawn(C_43);
    -- StarterGui.ArceusXV3.MainUI.MainFrame.Tabs.Home.HaxPage.Scripts.Aimbot.LocalScript
    local function C_4b()
    	local script = AZY["4b"];
    	script.Parent.MouseButton1Click:Connect(function()
    		loadstring(game:HttpGet("https://raw.githubusercontent.com/AZYsGithub/chillz-workshop/main/Arceus%20Aimbot.lua"))()
    	end)
    end;
    task.spawn(C_4b);
    -- StarterGui.ArceusXV3.MainUI.MainFrame.Tabs.Home.HaxPage.Scripts.Btools.LocalScript
    local function C_4e()
    	local script = AZY["4e"];
    	script.Parent.MouseButton1Click:Connect(function()
    		local backpack = game:GetService("Players").LocalPlayer.Backpack

    		local hammer = Instance.new("HopperBin")
    		hammer.Name = "Hammer"
    		hammer.BinType = 4
    		hammer.Parent = backpack

    		local cloneTool = Instance.new("HopperBin")
    		cloneTool.Name = "Clone"
    		cloneTool.BinType = 3
    		cloneTool.Parent = backpack

    		local grabTool = Instance.new("HopperBin")
    		grabTool.Name = "Grab"
    		grabTool.BinType = 2
    		grabTool.Parent = backpack
    	end)
    end;
    task.spawn(C_4e);
    -- StarterGui.ArceusXV3.MainUI.MainFrame.Tabs.Home.HaxPage.Scripts.Dex.LocalScript
    local function C_51()
    	local script = AZY["51"];
    	script.Parent.MouseButton1Click:Connect(function()
    		loadstring(game:HttpGet("https://cdn.wearedevs.net/scripts/Dex%20Explorer.txt"))()
    	end)
    end;
    task.spawn(C_51);
    -- StarterGui.ArceusXV3.MainUI.MainFrame.Tabs.Home.HaxPage.Scripts.FatesESP.LocalScript
    local function C_54()
    	local script = AZY["54"];
    	script.Parent.MouseButton1Click:Connect(function()
    		loadstring(request({ Url = "https://raw.githubusercontent.com/fatesc/fates-esp/main/main.lua", Method = "GET"}).Body)()
    	end)
    end;
    task.spawn(C_54);
    -- StarterGui.ArceusXV3.MainUI.MainFrame.Tabs.Home.HaxPage.Scripts.Fly.LocalScript
    local function C_57()
    	local script = AZY["57"];
    	script.Parent.MouseButton1Click:Connect(function()
    		loadstring(game:HttpGet("https://raw.githubusercontent.com/AZYsGithub/chillz-workshop/main/Arceus%20Fly.lua"))()
    	end)
    end;
    task.spawn(C_57);
    -- StarterGui.ArceusXV3.MainUI.MainFrame.Tabs.Home.HaxPage.Scripts.IY.LocalScript
    local function C_5a()
    	local script = AZY["5a"];
    	script.Parent.MouseButton1Click:Connect(function()
    		loadstring(game:HttpGet('https://raw.githubusercontent.com/EdgeIY/infiniteyield/master/source'))()
    	end)
    end;
    task.spawn(C_5a);
    -- StarterGui.ArceusXV3.MainUI.MainFrame.Tabs.Home.HaxPage.Scripts.PwnHub.LocalScript
    local function C_5d()
    	local script = AZY["5d"];
    	script.Parent.MouseButton1Click:Connect(function()
    		loadstring(game:HttpGet(("https://raw.githubusercontent.com/Maikderninja/Maikderninja/main/PWNERHUB.lua"), true))()
    	end)
    end;
    task.spawn(C_5d);
    -- StarterGui.ArceusXV3.MainUI.MainFrame.Tabs.Home.HaxPage.ToggleGrav.LocalScript
    local function C_65()
    	local script = AZY["65"];
    	script.Parent.MouseButton1Click:Connect(function()
    		if script.Parent.Parent.Grav.Value == false then
    			script.Parent.Parent.Grav.Value = true
    			script.Parent.Parent.GravS.SliderButton.ImageColor3 = Color3.fromRGB(255,0,0)
    			script.Parent.BackgroundColor3 = Color3.fromRGB(255,0,0)
    		else
    			script.Parent.Parent.Grav.Value = false
    			script.Parent.Parent.GravS.SliderButton.ImageColor3 = Color3.fromRGB(145,0,0)
    			script.Parent.BackgroundColor3 = Color3.fromRGB(145,0,0)
    			workspace.Gravity = 196.2
    		end
    	end)
    end;
    task.spawn(C_65);
    -- StarterGui.ArceusXV3.MainUI.MainFrame.Tabs.Home.HaxPage.ToggleWs.LocalScript
    local function C_68()
    	local script = AZY["68"];
    	script.Parent.MouseButton1Click:Connect(function()
    		if script.Parent.Parent.Ws.Value == false then
    			script.Parent.Parent.Ws.Value = true
    			script.Parent.Parent.WsS.SliderButton.ImageColor3 = Color3.fromRGB(255,0,0)
    			script.Parent.BackgroundColor3 = Color3.fromRGB(255,0,0)
    		else
    			script.Parent.Parent.Ws.Value = false
    			script.Parent.Parent.WsS.SliderButton.ImageColor3 = Color3.fromRGB(145,0,0)
    			script.Parent.BackgroundColor3 = Color3.fromRGB(145,0,0)
    		end
    	end)
    end;
    task.spawn(C_68);
    -- StarterGui.ArceusXV3.MainUI.MainFrame.Tabs.Home.HaxPage.ToggleJp.LocalScript
    local function C_6b()
    	local script = AZY["6b"];
    	script.Parent.MouseButton1Click:Connect(function()
    		if script.Parent.Parent.Jp.Value == false then
    			script.Parent.Parent.Jp.Value = true
    			script.Parent.Parent.JpS.SliderButton.ImageColor3 = Color3.fromRGB(255,0,0)
    			script.Parent.BackgroundColor3 = Color3.fromRGB(255,0,0)
    		else
    			script.Parent.Parent.Jp.Value = false
    			script.Parent.Parent.JpS.SliderButton.ImageColor3 = Color3.fromRGB(145,0,0)
    			script.Parent.BackgroundColor3 = Color3.fromRGB(145,0,0)
    		end
    	end)
    end;
    task.spawn(C_6b);
    -- StarterGui.ArceusXV3.MainUI.MainFrame.Tabs.Home.HaxPage.JpS.SliderButton.LocalScript
    local function C_6e()
    	local script = AZY["6e"];
    	-- Written by Bread

    	local UIS			= game:GetService("UserInputService") 	
    	local Outer			= script.Parent.Parent					-- Slider / Container
    	local Inner 		= script.Parent 						-- Thing to drag across slider
    	local Percent = Instance.new("NumberValue", Outer)	-- A number value containing the perctage in decimal form.
    	local Max_Percent = 100									-- Max Percentage (Scale of slider)
    	Percent.Name = "Percentage"
    	local TextLabel = Outer.TextLabel

    	local sliding = false

    	local ClickY = 0

    	local function UpdatePercentage(Percentage)
    		Percent.Value = Percentage
    		TextLabel.Text = Percentage .. "%"
    		local Value = Percentage * 5
    		if script.Parent.Parent.Parent.Jp.Value == true then
    			game.Players.LocalPlayer.Character.Humanoid.JumpPower =  Value
    		end
    	end

    	Outer.InputBegan:Connect(function(input)
    		if not (input.UserInputType == Enum.UserInputType.MouseButton1
    			or input.UserInputType == Enum.UserInputType.Touch) then return end

    		ClickY = input.Position.Y

    		sliding = true
    	end)

    	Outer.InputEnded:Connect(function(input)
    		if not (input.UserInputType == Enum.UserInputType.MouseButton1
    			or input.UserInputType == Enum.UserInputType.Touch) then return end

    		sliding = false
    	end)

    	UIS.InputChanged:Connect(function(input)
    		if input.UserInputType ~= Enum.UserInputType.MouseMovement then return end

    		if not sliding then return end

    		local MouseY = UIS:GetMouseLocation().Y

    		local RelativeY = math.max(math.min(((Outer.AbsolutePosition.Y - MouseY) + 119) / 119, 1), 0)
    		local Percentage = math.round(RelativeY * Max_Percent)

    		Inner.Size = UDim2.fromScale(RelativeY, 1)

    		UpdatePercentage(Percentage)
    	end)

    	local function setJumppower()

    		local character = game.Players.LocalPlayer.Character

    		local textBox = script.Parent.Parent.TextLabel

    		local Jumppower = tonumber(textBox.Text)

    		if Jumppower ~= nil then

    			if script.Parent.Parent.Parent.Jp.Value == true then
    				character.Humanoid.JumpPower = Jumppower * 4.1
    			end
    			textBox.Text = textBox.Text .. "%"
    		end
    	end


    	setJumppower()


    	script.Parent.Parent.TextLabel.FocusLost:Connect(setJumppower)

    	game.Players.LocalPlayer.CharacterAdded:Connect(function(character)
    		wait(1)
    		setJumppower()
    	end)

    end;
    task.spawn(C_6e);
    -- StarterGui.ArceusXV3.MainUI.MainFrame.Tabs.Home.HaxPage.WsS.SliderButton.LocalScript
    local function C_77()
    	local script = AZY["77"];
    	-- Written by Bread

    	local UIS			= game:GetService("UserInputService") 	
    	local Outer			= script.Parent.Parent					-- Slider / Container
    	local Inner 		= script.Parent 						-- Thing to drag across slider
    	local Percent = Instance.new("NumberValue", Outer)	-- A number value containing the perctage in decimal form.
    	local Max_Percent = 100									-- Max Percentage (Scale of slider)
    	Percent.Name = "Percentage"
    	local TextLabel = Outer.TextLabel

    	local sliding = false

    	local ClickY = 0

    	local function UpdatePercentage(Percentage)
    		Percent.Value = Percentage
    		TextLabel.Text = Percentage .. "%"
    		local Value = Percentage * 4.1
    		if script.Parent.Parent.Parent.Ws.Value == true then
    			game.Players.LocalPlayer.Character.Humanoid.WalkSpeed =  Value
    		end
    	end

    	Outer.InputBegan:Connect(function(input)
    		if not (input.UserInputType == Enum.UserInputType.MouseButton1
    			or input.UserInputType == Enum.UserInputType.Touch) then return end

    		ClickY = input.Position.Y

    		sliding = true
    	end)

    	Outer.InputEnded:Connect(function(input)
    		if not (input.UserInputType == Enum.UserInputType.MouseButton1
    			or input.UserInputType == Enum.UserInputType.Touch) then return end

    		sliding = false
    	end)

    	UIS.InputChanged:Connect(function(input)
    		if input.UserInputType ~= Enum.UserInputType.MouseMovement then return end

    		if not sliding then return end

    		local MouseY = UIS:GetMouseLocation().Y

    		local RelativeY = math.max(math.min(((Outer.AbsolutePosition.Y - MouseY) + 119) / 119, 1), 0)
    		local Percentage = math.round(RelativeY * Max_Percent)

    		Inner.Size = UDim2.fromScale(RelativeY, 1)

    		UpdatePercentage(Percentage)
    	end)

    	local function setWalkspeed()

    		local character = game.Players.LocalPlayer.Character

    		local textBox = script.Parent.Parent.TextLabel

    		local walkspeed = tonumber(textBox.Text)

    		if walkspeed ~= nil then

    			if script.Parent.Parent.Parent.Ws.Value == true then
    				character.Humanoid.WalkSpeed = walkspeed * 4.1
    			end
    			textBox.Text = textBox.Text .. "%"
    		end
    	end


    	setWalkspeed()


    	script.Parent.Parent.TextLabel.FocusLost:Connect(setWalkspeed)

    	game.Players.LocalPlayer.CharacterAdded:Connect(function(character)
    		wait(1)
    		setWalkspeed()
    	end)

    end;
    task.spawn(C_77);
    -- StarterGui.ArceusXV3.MainUI.MainFrame.Tabs.Home.HaxPage.GravS.SliderButton.LocalScript
    local function C_80()
    	local script = AZY["80"];
    	-- Written by Bread

    	local UIS			= game:GetService("UserInputService") 	
    	local Outer			= script.Parent.Parent					-- Slider / Container
    	local Inner 		= script.Parent 						-- Thing to drag across slider
    	local Percent = Instance.new("NumberValue", Outer)	-- A number value containing the perctage in decimal form.
    	local Max_Percent = 100									-- Max Percentage (Scale of slider)
    	Percent.Name = "Percentage"
    	local TextLabel = Outer.TextLabel

    	local sliding = false

    	local ClickY = 0

    	local function UpdatePercentage(Percentage)
    		Percent.Value = Percentage
    		TextLabel.Text = Percentage .. "%"
    		local Value = Percentage * 5
    		if script.Parent.Parent.Parent.Grav.Value == true then
    			workspace.Gravity =  Value
    		end
    	end

    	Outer.InputBegan:Connect(function(input)
    		if not (input.UserInputType == Enum.UserInputType.MouseButton1
    			or input.UserInputType == Enum.UserInputType.Touch) then return end

    		ClickY = input.Position.Y

    		sliding = true
    	end)

    	Outer.InputEnded:Connect(function(input)
    		if not (input.UserInputType == Enum.UserInputType.MouseButton1
    			or input.UserInputType == Enum.UserInputType.Touch) then return end

    		sliding = false
    	end)

    	UIS.InputChanged:Connect(function(input)
    		if input.UserInputType ~= Enum.UserInputType.MouseMovement then return end

    		if not sliding then return end

    		local MouseY = UIS:GetMouseLocation().Y

    		local RelativeY = math.max(math.min(((Outer.AbsolutePosition.Y - MouseY) + 119) / 119, 1), 0)
    		local Percentage = math.round(RelativeY * Max_Percent)

    		Inner.Size = UDim2.fromScale(RelativeY, 1)

    		UpdatePercentage(Percentage)
    	end)

    	local function setGravity()

    		local character = game.Players.LocalPlayer.Character

    		local textBox = script.Parent.Parent.TextLabel

    		local Gravity = tonumber(textBox.Text)

    		if Gravity ~= nil then

    			if script.Parent.Parent.Parent.Grav.Value == true then
    				workspace.Gravity = Gravity * 5
    			end
    			textBox.Text = textBox.Text .. "%"
    		end
    	end


    	setGravity()


    	script.Parent.Parent.TextLabel.FocusLost:Connect(setGravity)

    	game.Players.LocalPlayer.CharacterAdded:Connect(function(character)
    		wait(1)
    		setGravity()
    	end)

    end;
    task.spawn(C_80);
    -- StarterGui.ArceusXV3.MainUI.MainFrame.Tabs.Changelogs.Communications.Copy.LocalScript
    local function C_c9()
    	local script = AZY["c9"];
    	script.Parent.MouseButton1Click:Connect(function()
    		setclipboard("VPn54EcfNX")
    	end)
    end;
    task.spawn(C_c9);
    -- StarterGui.ArceusXV3.MainUI.MainFrame.Tabs.BuiltInHax.HaxPage.ToggleGrav.LocalScript
    local function C_d6()
    	local script = AZY["d6"];
    	script.Parent.MouseButton1Click:Connect(function()
    		if script.Parent.Parent.Grav.Value == false then
    			script.Parent.Parent.Grav.Value = true
    			script.Parent.Parent.GravS.SliderButton.ImageColor3 = Color3.fromRGB(255,0,0)
    			script.Parent.BackgroundColor3 = Color3.fromRGB(255,0,0)
    		else
    			script.Parent.Parent.Grav.Value = false
    			script.Parent.Parent.GravS.SliderButton.ImageColor3 = Color3.fromRGB(145,0,0)
    			script.Parent.BackgroundColor3 = Color3.fromRGB(145,0,0)
    			workspace.Gravity = 196.2
    		end
    	end)
    end;
    task.spawn(C_d6);
    -- StarterGui.ArceusXV3.MainUI.MainFrame.Tabs.BuiltInHax.HaxPage.ToggleJp.LocalScript
    local function C_d9()
    	local script = AZY["d9"];
    	script.Parent.MouseButton1Click:Connect(function()
    		if script.Parent.Parent.Jp.Value == false then
    			script.Parent.Parent.Jp.Value = true
    			script.Parent.Parent.JpS.SliderButton.ImageColor3 = Color3.fromRGB(255,0,0)
    			script.Parent.BackgroundColor3 = Color3.fromRGB(255,0,0)
    		else
    			script.Parent.Parent.Jp.Value = false
    			script.Parent.Parent.JpS.SliderButton.ImageColor3 = Color3.fromRGB(145,0,0)
    			script.Parent.BackgroundColor3 = Color3.fromRGB(145,0,0)
    		end
    	end)
    end;
    task.spawn(C_d9);
    -- StarterGui.ArceusXV3.MainUI.MainFrame.Tabs.BuiltInHax.HaxPage.ToggleWs.LocalScript
    local function C_dc()
    	local script = AZY["dc"];
    	script.Parent.MouseButton1Click:Connect(function()
    		if script.Parent.Parent.Ws.Value == false then
    			script.Parent.Parent.Ws.Value = true
    			script.Parent.Parent.WsS.SliderButton.ImageColor3 = Color3.fromRGB(255,0,0)
    			script.Parent.BackgroundColor3 = Color3.fromRGB(255,0,0)
    		else
    			script.Parent.Parent.Ws.Value = false
    			script.Parent.Parent.WsS.SliderButton.ImageColor3 = Color3.fromRGB(145,0,0)
    			script.Parent.BackgroundColor3 = Color3.fromRGB(145,0,0)
    		end
    	end)
    end;
    task.spawn(C_dc);
    -- StarterGui.ArceusXV3.MainUI.MainFrame.Tabs.BuiltInHax.HaxPage.WsS.SliderButton.LocalScript
    local function C_df()
    	local script = AZY["df"];
    	-- Written by Bread

    	local UIS			= game:GetService("UserInputService") 	
    	local Outer			= script.Parent.Parent					-- Slider / Container
    	local Inner 		= script.Parent 						-- Thing to drag across slider
    	local Percent = Instance.new("NumberValue", Outer)	-- A number value containing the perctage in decimal form.
    	local Max_Percent = 100									-- Max Percentage (Scale of slider)
    	Percent.Name = "Percentage"
    	local TextLabel = Outer.TextLabel

    	local sliding = false

    	local ClickY = 0

    	local function UpdatePercentage(Percentage)
    		Percent.Value = Percentage
    		TextLabel.Text = Percentage .. "%"
    		local Value = Percentage * 4.1
    		if script.Parent.Parent.Parent.Ws.Value == true then
    			game.Players.LocalPlayer.Character.Humanoid.WalkSpeed =  Value
    		end
    	end

    	Outer.InputBegan:Connect(function(input)
    		if not (input.UserInputType == Enum.UserInputType.MouseButton1
    			or input.UserInputType == Enum.UserInputType.Touch) then return end

    		ClickY = input.Position.Y

    		sliding = true
    	end)

    	Outer.InputEnded:Connect(function(input)
    		if not (input.UserInputType == Enum.UserInputType.MouseButton1
    			or input.UserInputType == Enum.UserInputType.Touch) then return end

    		sliding = false
    	end)

    	UIS.InputChanged:Connect(function(input)
    		if input.UserInputType ~= Enum.UserInputType.MouseMovement then return end

    		if not sliding then return end

    		local MouseY = UIS:GetMouseLocation().Y

    		local RelativeY = math.max(math.min(((Outer.AbsolutePosition.Y - MouseY) + 119) / 119, 1), 0)
    		local Percentage = math.round(RelativeY * Max_Percent)

    		Inner.Size = UDim2.fromScale(RelativeY, 1)

    		UpdatePercentage(Percentage)
    	end)

    	local function setWalkspeed()

    		local character = game.Players.LocalPlayer.Character

    		local textBox = script.Parent.Parent.TextLabel

    		local walkspeed = tonumber(textBox.Text)

    		if walkspeed ~= nil then

    			if script.Parent.Parent.Parent.Ws.Value == true then
    				character.Humanoid.WalkSpeed = walkspeed * 4.1
    			end
    			textBox.Text = textBox.Text .. "%"
    		end
    	end


    	setWalkspeed()


    	script.Parent.Parent.TextLabel.FocusLost:Connect(setWalkspeed)

    	game.Players.LocalPlayer.CharacterAdded:Connect(function(character)
    		wait(1)
    		setWalkspeed()
    	end)

    end;
    task.spawn(C_df);
    -- StarterGui.ArceusXV3.MainUI.MainFrame.Tabs.BuiltInHax.HaxPage.JpS.SliderButton.LocalScript
    local function C_e8()
    	local script = AZY["e8"];
    	-- Written by Bread

    	local UIS			= game:GetService("UserInputService") 	
    	local Outer			= script.Parent.Parent					-- Slider / Container
    	local Inner 		= script.Parent 						-- Thing to drag across slider
    	local Percent = Instance.new("NumberValue", Outer)	-- A number value containing the perctage in decimal form.
    	local Max_Percent = 100									-- Max Percentage (Scale of slider)
    	Percent.Name = "Percentage"
    	local TextLabel = Outer.TextLabel

    	local sliding = false

    	local ClickY = 0

    	local function UpdatePercentage(Percentage)
    		Percent.Value = Percentage
    		TextLabel.Text = Percentage .. "%"
    		local Value = Percentage * 5
    		if script.Parent.Parent.Parent.Jp.Value == true then
    			game.Players.LocalPlayer.Character.Humanoid.JumpPower =  Value
    		end
    	end

    	Outer.InputBegan:Connect(function(input)
    		if not (input.UserInputType == Enum.UserInputType.MouseButton1
    			or input.UserInputType == Enum.UserInputType.Touch) then return end

    		ClickY = input.Position.Y

    		sliding = true
    	end)

    	Outer.InputEnded:Connect(function(input)
    		if not (input.UserInputType == Enum.UserInputType.MouseButton1
    			or input.UserInputType == Enum.UserInputType.Touch) then return end

    		sliding = false
    	end)

    	UIS.InputChanged:Connect(function(input)
    		if input.UserInputType ~= Enum.UserInputType.MouseMovement then return end

    		if not sliding then return end

    		local MouseY = UIS:GetMouseLocation().Y

    		local RelativeY = math.max(math.min(((Outer.AbsolutePosition.Y - MouseY) + 119) / 119, 1), 0)
    		local Percentage = math.round(RelativeY * Max_Percent)

    		Inner.Size = UDim2.fromScale(RelativeY, 1)

    		UpdatePercentage(Percentage)
    	end)

    	local function setJumppower()

    		local character = game.Players.LocalPlayer.Character

    		local textBox = script.Parent.Parent.TextLabel

    		local Jumppower = tonumber(textBox.Text)

    		if Jumppower ~= nil then

    			if script.Parent.Parent.Parent.Jp.Value == true then
    				character.Humanoid.JumpPower = Jumppower * 4.1
    			end
    			textBox.Text = textBox.Text .. "%"
    		end
    	end


    	setJumppower()


    	script.Parent.Parent.TextLabel.FocusLost:Connect(setJumppower)

    	game.Players.LocalPlayer.CharacterAdded:Connect(function(character)
    		wait(1)
    		setJumppower()
    	end)

    end;
    task.spawn(C_e8);
    -- StarterGui.ArceusXV3.MainUI.MainFrame.Tabs.BuiltInHax.HaxPage.GravS.SliderButton.LocalScript
    local function C_f1()
    	local script = AZY["f1"];
    	-- Written by Bread

    	local UIS			= game:GetService("UserInputService") 	
    	local Outer			= script.Parent.Parent					-- Slider / Container
    	local Inner 		= script.Parent 						-- Thing to drag across slider
    	local Percent = Instance.new("NumberValue", Outer)	-- A number value containing the perctage in decimal form.
    	local Max_Percent = 100									-- Max Percentage (Scale of slider)
    	Percent.Name = "Percentage"
    	local TextLabel = Outer.TextLabel

    	local sliding = false

    	local ClickY = 0

    	local function UpdatePercentage(Percentage)
    		Percent.Value = Percentage
    		TextLabel.Text = Percentage .. "%"
    		local Value = Percentage * 5
    		if script.Parent.Parent.Parent.Grav.Value == true then
    			workspace.Gravity =  Value
    		end
    	end

    	Outer.InputBegan:Connect(function(input)
    		if not (input.UserInputType == Enum.UserInputType.MouseButton1
    			or input.UserInputType == Enum.UserInputType.Touch) then return end

    		ClickY = input.Position.Y

    		sliding = true
    	end)

    	Outer.InputEnded:Connect(function(input)
    		if not (input.UserInputType == Enum.UserInputType.MouseButton1
    			or input.UserInputType == Enum.UserInputType.Touch) then return end

    		sliding = false
    	end)

    	UIS.InputChanged:Connect(function(input)
    		if input.UserInputType ~= Enum.UserInputType.MouseMovement then return end

    		if not sliding then return end

    		local MouseY = UIS:GetMouseLocation().Y

    		local RelativeY = math.max(math.min(((Outer.AbsolutePosition.Y - MouseY) + 119) / 119, 1), 0)
    		local Percentage = math.round(RelativeY * Max_Percent)

    		Inner.Size = UDim2.fromScale(RelativeY, 1)

    		UpdatePercentage(Percentage)
    	end)

    	local function setGravity()

    		local character = game.Players.LocalPlayer.Character

    		local textBox = script.Parent.Parent.TextLabel

    		local Gravity = tonumber(textBox.Text)

    		if Gravity ~= nil then

    			if script.Parent.Parent.Parent.Grav.Value == true then
    				workspace.Gravity = Gravity * 5
    			end
    			textBox.Text = textBox.Text .. "%"
    		end
    	end


    	setGravity()


    	script.Parent.Parent.TextLabel.FocusLost:Connect(setGravity)

    	game.Players.LocalPlayer.CharacterAdded:Connect(function(character)
    		wait(1)
    		setGravity()
    	end)

    end;
    task.spawn(C_f1);
    -- StarterGui.ArceusXV3.MainUI.MainFrame.Tabs.BuiltInHax.Scripts.Aimbot.LocalScript
    local function C_fe()
    	local script = AZY["fe"];
    	script.Parent.MouseButton1Click:Connect(function()
    		loadstring(game:HttpGet("https://raw.githubusercontent.com/AZYsGithub/chillz-workshop/main/Arceus%20Aimbot.lua"))()
    	end)
    end;
    task.spawn(C_fe);
    -- StarterGui.ArceusXV3.MainUI.MainFrame.Tabs.BuiltInHax.Scripts.Btools.LocalScript
    local function C_102()
    	local script = AZY["102"];
    	script.Parent.MouseButton1Click:Connect(function()
    		local backpack = game:GetService("Players").LocalPlayer.Backpack

    		local hammer = Instance.new("HopperBin")
    		hammer.Name = "Hammer"
    		hammer.BinType = 4
    		hammer.Parent = backpack

    		local cloneTool = Instance.new("HopperBin")
    		cloneTool.Name = "Clone"
    		cloneTool.BinType = 3
    		cloneTool.Parent = backpack

    		local grabTool = Instance.new("HopperBin")
    		grabTool.Name = "Grab"
    		grabTool.BinType = 2
    		grabTool.Parent = backpack
    	end)
    end;
    task.spawn(C_102);
    -- StarterGui.ArceusXV3.MainUI.MainFrame.Tabs.BuiltInHax.Scripts.Dex.LocalScript
    local function C_106()
    	local script = AZY["106"];
    	script.Parent.MouseButton1Click:Connect(function()
    		loadstring(game:HttpGet("https://cdn.wearedevs.net/scripts/Dex%20Explorer.txt"))()
    	end)
    end;
    task.spawn(C_106);
    -- StarterGui.ArceusXV3.MainUI.MainFrame.Tabs.BuiltInHax.Scripts.FatesESP.LocalScript
    local function C_10a()
    	local script = AZY["10a"];
    	script.Parent.MouseButton1Click:Connect(function()
    		loadstring(request({ Url = "https://raw.githubusercontent.com/fatesc/fates-esp/main/main.lua", Method = "GET"}).Body)()
    	end)
    end;
    task.spawn(C_10a);
    -- StarterGui.ArceusXV3.MainUI.MainFrame.Tabs.BuiltInHax.Scripts.Fly.LocalScript
    local function C_10e()
    	local script = AZY["10e"];
    	script.Parent.MouseButton1Click:Connect(function()
    		loadstring(game:HttpGet("https://raw.githubusercontent.com/AZYsGithub/chillz-workshop/main/Arceus%20Fly.lua"))()
    	end)
    end;
    task.spawn(C_10e);
    -- StarterGui.ArceusXV3.MainUI.MainFrame.Tabs.BuiltInHax.Scripts.IY.LocalScript
    local function C_112()
    	local script = AZY["112"];
    	script.Parent.MouseButton1Click:Connect(function()
    		loadstring(game:HttpGet('https://raw.githubusercontent.com/EdgeIY/infiniteyield/master/source'))()
    	end)
    end;
    task.spawn(C_112);
    -- StarterGui.ArceusXV3.MainUI.MainFrame.Tabs.BuiltInHax.Scripts.PwnHub.LocalScript
    local function C_116()
    	local script = AZY["116"];
    	script.Parent.MouseButton1Click:Connect(function()
    		loadstring(game:HttpGet(("https://raw.githubusercontent.com/Maikderninja/Maikderninja/main/PWNERHUB.lua"), true))()
    	end)
    end;
    task.spawn(C_116);
    -- StarterGui.ArceusXV3.MainUI.MainFrame.Tabs.Executor.Execute.LocalScript
    local function C_11e()
    	local script = AZY["11e"];
    	script.Parent.MouseButton1Click:Connect(function()
    		loadstring(script.Parent.Parent.TextboxBar.Editor.Scroll.Source.Text)()
    	end)
    end;
    task.spawn(C_11e);
    -- StarterGui.ArceusXV3.MainUI.MainFrame.Tabs.Executor.Clear.LocalScript
    local function C_121()
    	local script = AZY["121"];
    	script.Parent.MouseButton1Click:Connect(function()
    		script.Parent.Parent.TextboxBar.Editor.Scroll.Source.Text = ""
    	end)
    end;
    task.spawn(C_121);
    -- StarterGui.ArceusXV3.MainUI.MainFrame.Tabs.Executor.Copy.LocalScript
    local function C_124()
    	local script = AZY["124"];
    	script.Parent.MouseButton1Click:Connect(function()
    		setclipboard(script.Parent.Parent.TextboxBar.Editor.Scroll.Source.Text)
    	end)
    end;
    task.spawn(C_124);
    -- StarterGui.ArceusXV3.MainUI.MainFrame.Tabs.Executor.Paste.LocalScript
    local function C_127()
    	local script = AZY["127"];
    	script.Parent.MouseButton1Click:Connect(function()
    		script.Parent.Text = "Not Implemented"
    		script.Disabled = true
    		wait(1)
    		script.Disabled = false
    		script.Parent.Text = "Paste"
    	end)
    end;
    task.spawn(C_127);
    -- StarterGui.ArceusXV3.MainUI.MainFrame.Tabs.Executor.TextboxBar.LocalScript
    local function C_12a()
    	local script = AZY["12a"];
    	local ScriptEditor = require(script.ScriptEditor)
    	local editor = ScriptEditor.new(script.Parent)
    end;
    task.spawn(C_12a);
    -- StarterGui.ArceusXV3.MainUI.MainFrame.Tabs.Executor.TextboxBar.LocalScript.ScriptEditor.Editor.Scroll.Left.AdaptSize
    local function C_146()
    	local script = AZY["146"];
    	local defaultSize = script.Parent.Size
    	local textbox = script.Parent.Parent.Source

    	textbox:GetPropertyChangedSignal("AbsoluteSize"):Connect(function()
    		local height = textbox.AbsoluteSize.Y

    		script.Parent.Size = UDim2.new(
    			defaultSize.X.Scale,
    			defaultSize.X.Offset,
    			0,
    			height
    		)
    	end)
    end;
    task.spawn(C_146);
    -- StarterGui.ArceusXV3.MainUI.MainFrame.Tabs.Executor.ResetTextBox.LocalScript
    local function C_14b()
    	local script = AZY["14b"];
    	script.Parent.MouseButton1Click:Connect(function()
    		script.Parent.Parent.TextboxBar.Editor:Destroy()
    		local ScriptEditor = require(script.Parent.Parent.TextboxBar.LocalScript.ScriptEditor)
    		local editor = ScriptEditor.new(script.Parent.Parent.TextboxBar)
    	end)
    end;
    task.spawn(C_14b);
    -- StarterGui.ArceusXV3.MainUI.MainFrame.TabBar.Changelogs.LocalScript
    local function C_151()
    	local script = AZY["151"];
    	script.Parent.MouseButton1Click:Connect(function()
    		script.Parent.Frame.Visible = true

    		for i,v in pairs(script.Parent.Parent.Parent.Tabs:GetChildren()) do
    			if v.Name == script.Parent.Name then
    				v.Visible = true
    			else
    				v.Visible = false
    			end
    		end

    		for i,v in pairs(script.Parent.Parent:GetChildren()) do
    			if v.Name ~= "UICorner" then
    				if v.Name ~= script.Parent.Name then
    					v.Frame.Visible = false
    				end
    			end
    		end
    	end)
    end;
    task.spawn(C_151);
    -- StarterGui.ArceusXV3.MainUI.MainFrame.TabBar.Home.LocalScript
    local function C_155()
    	local script = AZY["155"];
    	script.Parent.MouseButton1Click:Connect(function()
    		script.Parent.Frame.Visible = true

    		for i,v in pairs(script.Parent.Parent.Parent.Tabs:GetChildren()) do
    			if v.Name == script.Parent.Name then
    				v.Visible = true
    			else
    				v.Visible = false
    			end
    		end

    		for i,v in pairs(script.Parent.Parent:GetChildren()) do
    			if v.Name ~= "UICorner" then
    				if v.Name ~= script.Parent.Name then
    					v.Frame.Visible = false
    				end
    			end
    		end
    	end)
    end;
    task.spawn(C_155);
    -- StarterGui.ArceusXV3.MainUI.MainFrame.TabBar.BuiltInHax.LocalScript
    local function C_159()
    	local script = AZY["159"];
    	script.Parent.MouseButton1Click:Connect(function()
    		script.Parent.Frame.Visible = true

    		for i,v in pairs(script.Parent.Parent.Parent.Tabs:GetChildren()) do
    			if v.Name == script.Parent.Name then
    				v.Visible = true
    			else
    				v.Visible = false
    			end
    		end

    		for i,v in pairs(script.Parent.Parent:GetChildren()) do
    			if v.Name ~= "UICorner" then
    				if v.Name ~= script.Parent.Name then
    					v.Frame.Visible = false
    				end
    			end
    		end
    	end)
    end;
    task.spawn(C_159);
    -- StarterGui.ArceusXV3.MainUI.MainFrame.TabBar.Executor.LocalScript
    local function C_15d()
    	local script = AZY["15d"];
    	script.Parent.MouseButton1Click:Connect(function()
    		script.Parent.Frame.Visible = true

    		for i,v in pairs(script.Parent.Parent.Parent.Tabs:GetChildren()) do
    			if v.Name == script.Parent.Name then
    				v.Visible = true
    			else
    				v.Visible = false
    			end
    		end

    		for i,v in pairs(script.Parent.Parent:GetChildren()) do
    			if v.Name ~= "UICorner" then
    				if v.Name ~= script.Parent.Name then
    					v.Frame.Visible = false
    				end
    			end
    		end
    	end)
    end;
    task.spawn(C_15d);
    -- StarterGui.ArceusXV3.MainUI.MainFrame.LocalScript
    local function C_15f()
    	local script = AZY["15f"];
    	script.Parent.Draggable = true
    	script.Parent.Active = true
    end;
    task.spawn(C_15f);
    -- StarterGui.ArceusXV3.MainUI.FloatingUI.LocalScript
    local function C_162()
    	local script = AZY["162"];
    	script.Parent.Active = true
    	script.Parent.Draggable = true
    	script.Parent.MouseButton1Click:Connect(function()
    		script.Parent.Visible = false
    		script.Parent.Parent.MainFrame.Visible = true
    		script.Parent.Active = false
    		script.Parent.Parent.MainFrame.Active = true
    	end)
    end;
    task.spawn(C_162);

    return AZY["1"], require;

end





function flyv3()
    local main = Instance.new("ScreenGui")
    local Frame = Instance.new("Frame")
    local up = Instance.new("TextButton")
    local down = Instance.new("TextButton")
    local onof = Instance.new("TextButton")
    local TextLabel = Instance.new("TextLabel")
    local plus = Instance.new("TextButton")
    local speed = Instance.new("TextLabel")
    local mine = Instance.new("TextButton")
    local closebutton = Instance.new("TextButton")
    local mini = Instance.new("TextButton")
    local mini2 = Instance.new("TextButton")

    main.Name = "main"
    main.Parent = game.Players.LocalPlayer:WaitForChild("PlayerGui")
    main.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    main.ResetOnSpawn = false

    Frame.Parent = main
    Frame.BackgroundColor3 = Color3.fromRGB(163, 255, 137)
    Frame.BorderColor3 = Color3.fromRGB(103, 221, 213)
    Frame.Position = UDim2.new(0.100320168, 0, 0.379746825, 0)
    Frame.Size = UDim2.new(0, 190, 0, 57)

    up.Name = "上"
    up.Parent = Frame
    up.BackgroundColor3 = Color3.fromRGB(79, 255, 152)
    up.Size = UDim2.new(0, 44, 0, 28)
    up.Font = Enum.Font.SourceSans
    up.Text = "上"
    up.TextColor3 = Color3.fromRGB(0, 0, 0)
    up.TextSize = 14.000

    down.Name = "下"
    down.Parent = Frame
    down.BackgroundColor3 = Color3.fromRGB(215, 255, 121)
    down.Position = UDim2.new(0, 0, 0.491228074, 0)
    down.Size = UDim2.new(0, 44, 0, 28)
    down.Font = Enum.Font.SourceSans
    down.Text = "下"
    down.TextColor3 = Color3.fromRGB(0, 0, 0)
    down.TextSize = 14.000

    onof.Name = "onof"
    onof.Parent = Frame
    onof.BackgroundColor3 = Color3.fromRGB(255, 249, 74)
    onof.Position = UDim2.new(0.702823281, 0, 0.491228074, 0)
    onof.Size = UDim2.new(0, 56, 0, 28)
    onof.Font = Enum.Font.SourceSans
    onof.Text = "开/关(飞)"
    onof.TextColor3 = Color3.fromRGB(0, 0, 0)
    onof.TextSize = 14.000

    TextLabel.Parent = Frame
    TextLabel.BackgroundColor3 = Color3.fromRGB(242, 60, 255)
    TextLabel.Position = UDim2.new(0.469327301, 0, 0, 0)
    TextLabel.Size = UDim2.new(0, 100, 0, 28)
    TextLabel.Font = Enum.Font.SourceSans
    TextLabel.Text = "飞行脚本V3"
    TextLabel.TextColor3 = Color3.fromRGB(0, 0, 0)
    TextLabel.TextScaled = true
    TextLabel.TextSize = 14.000
    TextLabel.TextWrapped = true

    plus.Name = "plus"
    plus.Parent = Frame
    plus.BackgroundColor3 = Color3.fromRGB(133, 145, 255)
    plus.Position = UDim2.new(0.231578946, 0, 0, 0)
    plus.Size = UDim2.new(0, 45, 0, 28)
    plus.Font = Enum.Font.SourceSans
    plus.Text = "加速度"
    plus.TextColor3 = Color3.fromRGB(0, 0, 0)
    plus.TextScaled = true
    plus.TextSize = 14.000
    plus.TextWrapped = true

    speed.Name = "speed"
    speed.Parent = Frame
    speed.BackgroundColor3 = Color3.fromRGB(255, 85, 0)
    speed.Position = UDim2.new(0.468421042, 0, 0.491228074, 0)
    speed.Size = UDim2.new(0, 44, 0, 28)
    speed.Font = Enum.Font.SourceSans
    speed.Text = "1"
    speed.TextColor3 = Color3.fromRGB(0, 0, 0)
    speed.TextScaled = true
    speed.TextSize = 14.000
    speed.TextWrapped = true

    mine.Name = "mine"
    mine.Parent = Frame
    mine.BackgroundColor3 = Color3.fromRGB(123, 255, 247)
    mine.Position = UDim2.new(0.231578946, 0, 0.491228074, 0)
    mine.Size = UDim2.new(0, 45, 0, 29)
    mine.Font = Enum.Font.SourceSans
    mine.Text = "减速度"
    mine.TextColor3 = Color3.fromRGB(0, 0, 0)
    mine.TextScaled = true
    mine.TextSize = 14.000
    mine.TextWrapped = true

    closebutton.Name = "Close"
    closebutton.Parent = main.Frame
    closebutton.BackgroundColor3 = Color3.fromRGB(225, 25, 0)
    closebutton.Font = "SourceSans"
    closebutton.Size = UDim2.new(0, 45, 0, 28)
    closebutton.Text = "关闭"
    closebutton.TextSize = 30
    closebutton.Position =  UDim2.new(0, 0, -1, 27)

    mini.Name = "minimize"
    mini.Parent = main.Frame
    mini.BackgroundColor3 = Color3.fromRGB(192, 150, 230)
    mini.Font = "SourceSans"
    mini.Size = UDim2.new(0, 45, 0, 28)
    mini.Text = "简"
    mini.TextSize = 40
    mini.Position = UDim2.new(0, 44, -1, 27)

    mini2.Name = "minimize2"
    mini2.Parent = main.Frame
    mini2.BackgroundColor3 = Color3.fromRGB(192, 150, 230)
    mini2.Font = "SourceSans"
    mini2.Size = UDim2.new(0, 45, 0, 28)
    mini2.Text = "繁"
    mini2.TextSize = 40
    mini2.Position = UDim2.new(0, 44, -1, 57)
    mini2.Visible = false

    speeds = 1

    local speaker = game:GetService("Players").LocalPlayer

    local chr = game.Players.LocalPlayer.Character
    local hum = chr and chr:FindFirstChildWhichIsA("Humanoid")

    nowe = false

    game:GetService("StarterGui"):SetCore("SendNotification", { 
    	Title = "飞行脚本V3";
    	Text = "by ZeEnter";
    	Icon = "rbxthumb://type=Asset&id=5107182114&w=150&h=150"})
    Duration = 5;

    Frame.Active = true -- main = gui
    Frame.Draggable = true

    onof.MouseButton1Down:connect(function()

    	if nowe == true then
    		nowe = false

    		speaker.Character.Humanoid:SetStateEnabled(Enum.HumanoidStateType.Climbing,true)
    		speaker.Character.Humanoid:SetStateEnabled(Enum.HumanoidStateType.FallingDown,true)
    		speaker.Character.Humanoid:SetStateEnabled(Enum.HumanoidStateType.Flying,true)
    		speaker.Character.Humanoid:SetStateEnabled(Enum.HumanoidStateType.Freefall,true)
    		speaker.Character.Humanoid:SetStateEnabled(Enum.HumanoidStateType.GettingUp,true)
    		speaker.Character.Humanoid:SetStateEnabled(Enum.HumanoidStateType.Jumping,true)
    		speaker.Character.Humanoid:SetStateEnabled(Enum.HumanoidStateType.Landed,true)
    		speaker.Character.Humanoid:SetStateEnabled(Enum.HumanoidStateType.Physics,true)
    		speaker.Character.Humanoid:SetStateEnabled(Enum.HumanoidStateType.PlatformStanding,true)
    		speaker.Character.Humanoid:SetStateEnabled(Enum.HumanoidStateType.Ragdoll,true)
    		speaker.Character.Humanoid:SetStateEnabled(Enum.HumanoidStateType.Running,true)
    		speaker.Character.Humanoid:SetStateEnabled(Enum.HumanoidStateType.RunningNoPhysics,true)
    		speaker.Character.Humanoid:SetStateEnabled(Enum.HumanoidStateType.Seated,true)
    		speaker.Character.Humanoid:SetStateEnabled(Enum.HumanoidStateType.StrafingNoPhysics,true)
    		speaker.Character.Humanoid:SetStateEnabled(Enum.HumanoidStateType.Swimming,true)
    		speaker.Character.Humanoid:ChangeState(Enum.HumanoidStateType.RunningNoPhysics)
    	else 
    		nowe = true



    		for i = 1, speeds do
    			spawn(function()

    				local hb = game:GetService("RunService").Heartbeat	


    				tpwalking = true
    				local chr = game.Players.LocalPlayer.Character
    				local hum = chr and chr:FindFirstChildWhichIsA("Humanoid")
    				while tpwalking and hb:Wait() and chr and hum and hum.Parent do
    					if hum.MoveDirection.Magnitude > 0 then
    						chr:TranslateBy(hum.MoveDirection)
    					end
    				end

    			end)
    		end
    		game.Players.LocalPlayer.Character.Animate.Disabled = true
    		local Char = game.Players.LocalPlayer.Character
    		local Hum = Char:FindFirstChildOfClass("Humanoid") or Char:FindFirstChildOfClass("AnimationController")

    		for i,v in next, Hum:GetPlayingAnimationTracks() do
    			v:AdjustSpeed(0)
    		end
    		speaker.Character.Humanoid:SetStateEnabled(Enum.HumanoidStateType.Climbing,false)
    		speaker.Character.Humanoid:SetStateEnabled(Enum.HumanoidStateType.FallingDown,false)
    		speaker.Character.Humanoid:SetStateEnabled(Enum.HumanoidStateType.Flying,false)
    		speaker.Character.Humanoid:SetStateEnabled(Enum.HumanoidStateType.Freefall,false)
    		speaker.Character.Humanoid:SetStateEnabled(Enum.HumanoidStateType.GettingUp,false)
    		speaker.Character.Humanoid:SetStateEnabled(Enum.HumanoidStateType.Jumping,false)
    		speaker.Character.Humanoid:SetStateEnabled(Enum.HumanoidStateType.Landed,false)
    		speaker.Character.Humanoid:SetStateEnabled(Enum.HumanoidStateType.Physics,false)
    		speaker.Character.Humanoid:SetStateEnabled(Enum.HumanoidStateType.PlatformStanding,false)
    		speaker.Character.Humanoid:SetStateEnabled(Enum.HumanoidStateType.Ragdoll,false)
    		speaker.Character.Humanoid:SetStateEnabled(Enum.HumanoidStateType.Running,false)
    		speaker.Character.Humanoid:SetStateEnabled(Enum.HumanoidStateType.RunningNoPhysics,false)
    		speaker.Character.Humanoid:SetStateEnabled(Enum.HumanoidStateType.Seated,false)
    		speaker.Character.Humanoid:SetStateEnabled(Enum.HumanoidStateType.StrafingNoPhysics,false)
    		speaker.Character.Humanoid:SetStateEnabled(Enum.HumanoidStateType.Swimming,false)
    		speaker.Character.Humanoid:ChangeState(Enum.HumanoidStateType.Swimming)
    	end




    	if game:GetService("Players").LocalPlayer.Character:FindFirstChildOfClass("Humanoid").RigType == Enum.HumanoidRigType.R6 then



    		local plr = game.Players.LocalPlayer
    		local torso = plr.Character.Torso
    		local flying = true
    		local deb = true
    		local ctrl = {f = 0, b = 0, l = 0, r = 0}
    		local lastctrl = {f = 0, b = 0, l = 0, r = 0}
    		local maxspeed = 50
    		local speed = 0


    		local bg = Instance.new("BodyGyro", torso)
    		bg.P = 9e4
    		bg.maxTorque = Vector3.new(9e9, 9e9, 9e9)
    		bg.cframe = torso.CFrame
    		local bv = Instance.new("BodyVelocity", torso)
    		bv.velocity = Vector3.new(0,0.1,0)
    		bv.maxForce = Vector3.new(9e9, 9e9, 9e9)
    		if nowe == true then
    			plr.Character.Humanoid.PlatformStand = true
    		end
    		while nowe == true or game:GetService("Players").LocalPlayer.Character.Humanoid.Health == 0 do
    			game:GetService("RunService").RenderStepped:Wait()

    			if ctrl.l + ctrl.r ~= 0 or ctrl.f + ctrl.b ~= 0 then
    				speed = speed+.5+(speed/maxspeed)
    				if speed > maxspeed then
    					speed = maxspeed
    				end
    			elseif not (ctrl.l + ctrl.r ~= 0 or ctrl.f + ctrl.b ~= 0) and speed ~= 0 then
    				speed = speed-1
    				if speed < 0 then
    					speed = 0
    				end
    			end
    			if (ctrl.l + ctrl.r) ~= 0 or (ctrl.f + ctrl.b) ~= 0 then
    				bv.velocity = ((game.Workspace.CurrentCamera.CoordinateFrame.lookVector * (ctrl.f+ctrl.b)) + ((game.Workspace.CurrentCamera.CoordinateFrame * CFrame.new(ctrl.l+ctrl.r,(ctrl.f+ctrl.b)*.2,0).p) - game.Workspace.CurrentCamera.CoordinateFrame.p))*speed
    				lastctrl = {f = ctrl.f, b = ctrl.b, l = ctrl.l, r = ctrl.r}
    			elseif (ctrl.l + ctrl.r) == 0 and (ctrl.f + ctrl.b) == 0 and speed ~= 0 then
    				bv.velocity = ((game.Workspace.CurrentCamera.CoordinateFrame.lookVector * (lastctrl.f+lastctrl.b)) + ((game.Workspace.CurrentCamera.CoordinateFrame * CFrame.new(lastctrl.l+lastctrl.r,(lastctrl.f+lastctrl.b)*.2,0).p) - game.Workspace.CurrentCamera.CoordinateFrame.p))*speed
    			else
    				bv.velocity = Vector3.new(0,0,0)
    			end
    			--	game.Players.LocalPlayer.Character.Animate.Disabled = true
    			bg.cframe = game.Workspace.CurrentCamera.CoordinateFrame * CFrame.Angles(-math.rad((ctrl.f+ctrl.b)*50*speed/maxspeed),0,0)
    		end
    		ctrl = {f = 0, b = 0, l = 0, r = 0}
    		lastctrl = {f = 0, b = 0, l = 0, r = 0}
    		speed = 0
    		bg:Destroy()
    		bv:Destroy()
    		plr.Character.Humanoid.PlatformStand = false
    		game.Players.LocalPlayer.Character.Animate.Disabled = false
    		tpwalking = false




    	else
    		local plr = game.Players.LocalPlayer
    		local UpperTorso = plr.Character.UpperTorso
    		local flying = true
    		local deb = true
    		local ctrl = {f = 0, b = 0, l = 0, r = 0}
    		local lastctrl = {f = 0, b = 0, l = 0, r = 0}
    		local maxspeed = 50
    		local speed = 0


    		local bg = Instance.new("BodyGyro", UpperTorso)
    		bg.P = 9e4
    		bg.maxTorque = Vector3.new(9e9, 9e9, 9e9)
    		bg.cframe = UpperTorso.CFrame
    		local bv = Instance.new("BodyVelocity", UpperTorso)
    		bv.velocity = Vector3.new(0,0.1,0)
    		bv.maxForce = Vector3.new(9e9, 9e9, 9e9)
    		if nowe == true then
    			plr.Character.Humanoid.PlatformStand = true
    		end
    		while nowe == true or game:GetService("Players").LocalPlayer.Character.Humanoid.Health == 0 do
    			wait()

    			if ctrl.l + ctrl.r ~= 0 or ctrl.f + ctrl.b ~= 0 then
    				speed = speed+.5+(speed/maxspeed)
    				if speed > maxspeed then
    					speed = maxspeed
    				end
    			elseif not (ctrl.l + ctrl.r ~= 0 or ctrl.f + ctrl.b ~= 0) and speed ~= 0 then
    				speed = speed-1
    				if speed < 0 then
    					speed = 0
    				end
    			end
    			if (ctrl.l + ctrl.r) ~= 0 or (ctrl.f + ctrl.b) ~= 0 then
    				bv.velocity = ((game.Workspace.CurrentCamera.CoordinateFrame.lookVector * (ctrl.f+ctrl.b)) + ((game.Workspace.CurrentCamera.CoordinateFrame * CFrame.new(ctrl.l+ctrl.r,(ctrl.f+ctrl.b)*.2,0).p) - game.Workspace.CurrentCamera.CoordinateFrame.p))*speed
    				lastctrl = {f = ctrl.f, b = ctrl.b, l = ctrl.l, r = ctrl.r}
    			elseif (ctrl.l + ctrl.r) == 0 and (ctrl.f + ctrl.b) == 0 and speed ~= 0 then
    				bv.velocity = ((game.Workspace.CurrentCamera.CoordinateFrame.lookVector * (lastctrl.f+lastctrl.b)) + ((game.Workspace.CurrentCamera.CoordinateFrame * CFrame.new(lastctrl.l+lastctrl.r,(lastctrl.f+lastctrl.b)*.2,0).p) - game.Workspace.CurrentCamera.CoordinateFrame.p))*speed
    			else
    				bv.velocity = Vector3.new(0,0,0)
    			end

    			bg.cframe = game.Workspace.CurrentCamera.CoordinateFrame * CFrame.Angles(-math.rad((ctrl.f+ctrl.b)*50*speed/maxspeed),0,0)
    		end
    		ctrl = {f = 0, b = 0, l = 0, r = 0}
    		lastctrl = {f = 0, b = 0, l = 0, r = 0}
    		speed = 0
    		bg:Destroy()
    		bv:Destroy()
    		plr.Character.Humanoid.PlatformStand = false
    		game.Players.LocalPlayer.Character.Animate.Disabled = false
    		tpwalking = false



    	end





    end)

    local tis

    up.MouseButton1Down:connect(function()
    	tis = up.MouseEnter:connect(function()
    		while tis do
    			wait()
    			game.Players.LocalPlayer.Character.HumanoidRootPart.CFrame = game.Players.LocalPlayer.Character.HumanoidRootPart.CFrame * CFrame.new(0,1,0)
    		end
    	end)
    end)

    up.MouseLeave:connect(function()
    	if tis then
    		tis:Disconnect()
    		tis = nil
    	end
    end)

    local dis

    down.MouseButton1Down:connect(function()
    	dis = down.MouseEnter:connect(function()
    		while dis do
    			wait()
    			game.Players.LocalPlayer.Character.HumanoidRootPart.CFrame = game.Players.LocalPlayer.Character.HumanoidRootPart.CFrame * CFrame.new(0,-1,0)
    		end
    	end)
    end)

    down.MouseLeave:connect(function()
    	if dis then
    		dis:Disconnect()
    		dis = nil
    	end
    end)


    game:GetService("Players").LocalPlayer.CharacterAdded:Connect(function(char)
    	wait(0.7)
    	game.Players.LocalPlayer.Character.Humanoid.PlatformStand = false
    	game.Players.LocalPlayer.Character.Animate.Disabled = false

    end)


    plus.MouseButton1Down:connect(function()
    	speeds = speeds + 1
    	speed.Text = speeds
    	if nowe == true then


    		tpwalking = false
    		for i = 1, speeds do
    			spawn(function()

    				local hb = game:GetService("RunService").Heartbeat	


    				tpwalking = true
    				local chr = game.Players.LocalPlayer.Character
    				local hum = chr and chr:FindFirstChildWhichIsA("Humanoid")
    				while tpwalking and hb:Wait() and chr and hum and hum.Parent do
    					if hum.MoveDirection.Magnitude > 0 then
    						chr:TranslateBy(hum.MoveDirection)
    					end
    				end

    			end)
    		end
    	end
    end)
    mine.MouseButton1Down:connect(function()
    	if speeds == 1 then
    		speed.Text = 'cannot be less than 1'
    		wait(1)
    		speed.Text = speeds
    	else
    		speeds = speeds - 1
    		speed.Text = speeds
    		if nowe == true then
    			tpwalking = false
    			for i = 1, speeds do
    				spawn(function()

    					local hb = game:GetService("RunService").Heartbeat	


    					tpwalking = true
    					local chr = game.Players.LocalPlayer.Character
    					local hum = chr and chr:FindFirstChildWhichIsA("Humanoid")
    					while tpwalking and hb:Wait() and chr and hum and hum.Parent do
    						if hum.MoveDirection.Magnitude > 0 then
    							chr:TranslateBy(hum.MoveDirection)
    						end
    					end

    				end)
    			end
    		end
    	end
    end)

    closebutton.MouseButton1Click:Connect(function()
    	main:Destroy()
    end)

    mini.MouseButton1Click:Connect(function()
    	up.Visible = false
    	down.Visible = false
    	onof.Visible = false
    	plus.Visible = false
    	speed.Visible = false
    	mine.Visible = false
    	mini.Visible = false
    	mini2.Visible = true
    	main.Frame.BackgroundTransparency = 1
    	closebutton.Position =  UDim2.new(0, 0, -1, 57)
    end)

    mini2.MouseButton1Click:Connect(function()
    	up.Visible = true
    	down.Visible = true
    	onof.Visible = true
    	plus.Visible = true
    	speed.Visible = true
    	mine.Visible = true
    	mini.Visible = true
    	mini2.Visible = false
    	main.Frame.BackgroundTransparency = 0 
    	closebutton.Position =  UDim2.new(0, 0, -1, 27)
    end)
end