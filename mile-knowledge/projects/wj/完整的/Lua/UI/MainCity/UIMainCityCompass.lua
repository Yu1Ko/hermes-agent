-- ---------------------------------------------------------------------------------
-- Author: Unknown
-- Name: UIMainCityCompass
-- Date: 2023-04-19 19:46:57
-- Desc: ?
-- ---------------------------------------------------------------------------------

local WidgetMainCityCompass = class("WidgetMainCityCompass")

local MAX_PARTY_COUNT 		= 40
local UPDATE_TIME 			= 30000
local nShowDigPosDist       = 1280
local FOUND_DIST 			= 255
local ROTATE_SPEED          = 50
local COMPASS_TAPE = {
    PERSONAL = 1,
    TEAM = 2
}
local TEAMBUFFID = 1819
g_bCompassFind              = false
g_bCompassVisible           = true
g_bCompassStart             = false

function WidgetMainCityCompass:OnEnter()
    if not self.bInit then
        self:RegEvent()
        self:BindUIEvent()
        self.bInit = true
    end

    -- 现在游戏里应该是默认都有且不会损坏
    -- RemoteCallToServer("On_Xunbao_IfHaveDigEquip")

    self.tLocalData = {}
    self.nCompassLevel = 0
    self.nCompassAngleForDraw = 0
    self.nIndex = 1
    self:InitCompass()
    --Timer.AddCycle(self,2,function ()
    --    self:UpdateInfo()
    --end)
    Timer.AddFrameCycle(self,1,function ()
        self:UpdateInfo()
        self:DrawAllArrow()
        self:UpdateTeamPointBuffCD()
        self:UpdateFangshiTime()
    end)
end

function WidgetMainCityCompass:OnExit()
    self.bInit = false
    self:UnRegEvent()
    Timer.DelAllTimer(self)
end

function WidgetMainCityCompass:BindUIEvent()
    UIHelper.BindUIEvent(self.BtnClose, EventType.OnClick, function()
        Event.Dispatch(EventType.OnTogCompass,false)
    end)
    UIHelper.BindUIEvent(self.BtnStart, EventType.OnClick, function()
        --已经找到了点击挖掘
        if self.bFind then
            RemoteCallToServer("On_Xunbao_HoroDigRequest")
        else
            if self.nCompassState and self.nCompassState == COMPASS_TAPE.TEAM then
                TipsHelper.ShowNormalTip("请根据罗盘方向前往团队宝藏点！只存在一刻钟，速去寻找！")
            else
                self.nIndex = 1
                local tTargetList = self.tLocalData.tChestList or {}
                local tbData = tTargetList[self.nIndex]
                if tbData and tbData.nIndex == 2 then
                    self:AddFangshiNaviPoint(tbData.nMapID)
                else
                    RemoteCallToServer("OnHoroSysUpdateLocRequest")
                    RemoteCallToServer("On_Xunbao_FreshGuide3D")
                    UIHelper.SetVisible(self.WidgetArrow1,true)
                    UIHelper.SetVisible(self.WidgetArrow2,true)
                end

            end

        end
    end)
    UIHelper.BindUIEvent(self.BtnHint, EventType.OnClick, function()
        TipsHelper.ShowNodeHoverTips(PREFAB_ID.WidgetCompassTips,self.BtnHint,self.nCompassLevel,self.nDigCount or 0)
    end)

    UIHelper.BindUIEvent(self.BtnTeamPoint, EventType.OnClick, function()   --追踪团点
        self:SwitchToTeamPoint(true)
    end)

    UIHelper.BindUIEvent(self.BtnTeamPointEsc, EventType.OnClick, function()   --切到个人挖宝点
        self:SwitchToTeamPoint(false)
    end)
end


function WidgetMainCityCompass:RegEvent()
    --Event.Reg(self, EventType.XXX, func)
    --现在应该不会有这种情况，应策划要求先保留逻辑
    -- Event.Reg(self,"ON_NOT_HAVE_DIG_ITEM",function ()
    --     OutputMessage("MSG_ANNOUNCE_NORMAL", g_tStrings.STR_NOT_HAVE_DIG_ITEM)
    -- end)

    --应该是收到这个事件绘制罗盘的，暂时先用定时器绘制
    Event.Reg(self,"RENDER_FRAME_UPDATE",function ()
        self:DrawAllArrow()
    end)

    Event.Reg(self,"ON_HORO_SYS_DATA_UPDATE",function (tHoroSysData)
        self:OnHoroSysDataUpdate(tHoroSysData)
    end)

    Event.Reg(self,"ON_XUNBAO_GET_FOR_DIG_COUNT",function (nLevel, nCount)
        self:UpdateDigCount(nLevel, nCount)
    end)

    Event.Reg(self,"ON_XUNBAO_GET_PARTY_DIG_COUNT",function (nDigCount)
        self:UpdatePartyDigCount(nDigCount)
    end)

    Event.Reg(self,"PARTY_UPDATE_BASE_INFO",function (nDigCount)
        self:UpdatePartyDigCount(0)
    end)

    Event.Reg(self,"PARTY_DELETE_MEMBER",function (nDigCount)
        self:UpdatePartyDigCount(0)
    end)

    Event.Reg(self, EventType.OnClientPlayerEnter, function()
        local hPlayer = g_pClientPlayer
		if hPlayer then
			if CheckPlayerIsRemote(nil, g_tStrings.STR_REMOTE_NOT_TIP1) then
        		Event.Dispatch(EventType.OnTogCompass,false)
    		end
            local scene 			= g_pClientPlayer.GetScene()
            local bOutScene = not Table_DoesMapHaveTreasure(scene.dwMapID)
            local scriptView = UIMgr.GetViewScript(VIEW_ID.PanelMainCity)
            local bShowCompass = scriptView:HasWidgetItem(TraceInfoType.Compass)
            if bOutScene and bShowCompass then
                Event.Dispatch(EventType.OnTogCompass,false)
            end
    	end
    end)

    -- 切前台后挖宝cd时间需要更新
    Event.Reg(self, EventType.OnApplicationWillEnterForeground, function()
        UIHelper.SetString(self.LabelCD,"")
        Timer.DelTimer(self, self.nItemCDTimerID)
        self.nItemCDTimerID = nil
    end)
end

function WidgetMainCityCompass:UnRegEvent()
    --Event.UnReg(self, EventType.XXX)
end






-- ----------------------------------------------------------
-- Please write your own code below  ↓↓↓
-- ----------------------------------------------------------

function WidgetMainCityCompass:InitCompass()
    RemoteCallToServer("On_Xunbao_AskForDigCount")
    self.nPlayerTime = GetTickCount()
    UIHelper.SetSpriteFrame(self.ImgCompass,CompassImg[self.nCompassLevel + 1])
    UIHelper.SetVisible(self.WidgetReward,false)
    UIHelper.SetVisible(self.WidgetArrow1,false)
    UIHelper.SetVisible(self.WidgetArrow2,false)
    UIHelper.SetString(self.LabelTextTitle,g_tStrings.STR_START_COMPASS)
    UIHelper.SetTextColor(self.LabelTextTitle, cc.c4b(255, 255, 255, 255))

    if g_bCompassStart then
        g_bCompassStart = false
        Event.Dispatch(EventType.OnCompassStateChanged)
    end
    UIHelper.SetVisible(self.LabelCD , true)
    UIHelper.SetString(self.LabelCD,"")
    
    UIHelper.SetString(self.LabelLevel, string.format("%d级", self.nCompassLevel))
    UIHelper.SetSwallowTouches(self.BtnHint, true)
end

function WidgetMainCityCompass:UpdateInfo()
    self:UpdateTeamShow()
    self:UptateDigCount()
    local _, nLeft = ItemData.GetItemCDProgressByTab(ITEM_TABLE_TYPE.OTHER, 6604)
    if nLeft > 0 and not self.nItemCDTimerID then
        self.nItemCDTimerID = Timer.AddCountDown(self,math.ceil(nLeft / GLOBAL.GAME_FPS),function (nTime)
            UIHelper.SetString(self.LabelCD,nTime.."秒")
        end , function ()
            UIHelper.SetString(self.LabelCD,"")
            self.nItemCDTimerID = nil
        end)
    end
end

--团队寻宝
function WidgetMainCityCompass:UpdateTeamShow()
    local hPlayer 	= GetClientPlayer()
	local hTeam 	= GetClientTeam()
	local bInTeam 	= hTeam.IsPlayerInTeam(hPlayer.dwID)
    if bInTeam then
		if not self.bInTeam or (self.nTeamTime and GetTickCount() - self.nTeamTime >= UPDATE_TIME) then
			self.nTeamTime = GetTickCount()
			RemoteCallToServer("On_Xunbao_AskForPartyDigCount")
		end
    else
        UIHelper.SetString(self.LabelTeam, g_tStrings.STR_COMPASS_TEAM)
	end
    self.bInTeam = bInTeam
end

--个人寻宝
function WidgetMainCityCompass:UptateDigCount()
    if (GetTickCount() - self.nPlayerTime >= UPDATE_TIME) or not self.nPlayerTime then
		self.nPlayerTime = GetTickCount()
		RemoteCallToServer("On_Xunbao_AskForDigCount")
	end
end

--寻宝过程中发给这边的距离信息一类的
function WidgetMainCityCompass:OnHoroSysDataUpdate(tHoroSysData)
    self.nStateSysLevel = tHoroSysData.nStateSysLevel
    local tLoc 					 = tHoroSysData.Locs or {}
    local nLength = table.get_len(self.tLocalData.tChestList)
    self.tLocalData.tChestList = {}

    if tLoc.Player.nMapID and tLoc.Player.nMapID ~= 0 then
		self.bPlayerMapID = true
		if tLoc.Player.bWizard then
			table.insert(self.tLocalData.tChestList, {nIndex = 2, nMapID = tLoc.Player.nMapID, nX = tLoc.Player.nX, nY = tLoc.Player.nY, szDistance = tLoc.Player.szDistance, nCompassAngle = tLoc.Player.nCompassAngle, nEndTime = tLoc.Player.nEndTime})
        else
			table.insert(self.tLocalData.tChestList, {nIndex = 4, nMapID = tLoc.Player.nMapID, nX = tLoc.Player.nX, nY = tLoc.Player.nY, szDistance = tLoc.Player.szDistance, nCompassAngle = tLoc.Player.nCompassAngle})
        end
	else
		self.bPlayerMapID = false
	end
    if tLoc.Party.nMapID and tLoc.Party.nMapID ~= 0 then
		table.insert(self.tLocalData.tChestList, {nIndex = 3, nMapID = tLoc.Party.nMapID, nX = tLoc.Party.nX, nY = tLoc.Party.nY, szDistance = tLoc.Party.szDistance, nCompassAngle = tLoc.Party.nCompassAngle})
        if not self.bPartyMapID or nLength - table.get_len(self.tLocalData.tChestList) == 1 then --团点刷出
            self:UpdateTeamPointState(true)
        end
		self.bPartyMapID = true
    else
        if self.bPartyMapID then --团点消失
            self:UpdateTeamPointState(false)
        end
		self.bPartyMapID = false
	end
    self:UpdateAllArrowRotate()
end

--更新玩家当前面向
function WidgetMainCityCompass:DrawAllArrow()
    local _, nCameraAngle 	= Camera_GetRTParams()
    --这个和下面的增量都是因为预制里三个箭头初始方向不同
    UIHelper.SetRotation(self.WidgetArrow2,(nCameraAngle - math.pi / 2) / (math.pi * 2) * 360 + 180)

    local tTargetList = self.tLocalData.tChestList or {}
    self.bFind = false
    UIHelper.SetVisible(self.WidgetReward,false)

    local i = self.nIndex
    if tTargetList[i] then
        local nMapID = tTargetList[i].nMapID
        local nTargetX, nTargetY = tTargetList[i].nX, tTargetList[i].nY
        if nTargetX > 0 or nTargetY > 0 then
            local nTargetAngle, nDist = self:GetTwoPointAngle(g_pClientPlayer.nX, g_pClientPlayer.nY, tTargetList[i].nX, tTargetList[i].nY)
            if nDist <= FOUND_DIST then
                self.bFind = true
                UIHelper.SetString(self.LabelTextTitle,g_tStrings.STR_COMPASS_FIND)
                UIHelper.SetTextColor(self.LabelTextTitle, cc.c4b(255, 226, 110, 255))
            else
                UIHelper.SetVisible(self.WidgetReward,true)

                UIHelper.SetRotation(self.WidgetReward,nTargetAngle / (math.pi * 2) * 360 - 90)
                UIHelper.SetRotation(self.ImgReward,-(nTargetAngle / (math.pi * 2) * 360 - 90))

                local nX = nDist / nShowDigPosDist * (-60) -- 60是预制里宝箱到圆心的距离 40是里圈到外圈的距离
                UIHelper.SetPositionX(self.ImgReward, nX)
            end
            UIHelper.SetVisible(self.WidgetArrow1,false)
        else
            UIHelper.SetVisible(self.WidgetArrow1,true)
            self:CompassAngleForDraw(tTargetList[i].nCompassAngle)
        end
        UIHelper.SetVisible(self.LabelStart,false)
        UIHelper.SetVisible(self.WidgetArrow2, not self.bFind)
    else
        UIHelper.SetString(self.LabelTextTitle,g_tStrings.STR_START_COMPASS)
        UIHelper.SetTextColor(self.LabelTextTitle, cc.c4b(255, 255, 255, 255))
        UIHelper.SetVisible(self.LabelStart,true)
        UIHelper.SetVisible(self.WidgetArrow1, false)
        UIHelper.SetVisible(self.WidgetArrow2, false)

        if g_bCompassStart then
            g_bCompassStart = false
            Event.Dispatch(EventType.OnCompassStateChanged)
        end
    end
    UIHelper.SetVisible(self.Eff_UIwaBao, self.bFind)

    if g_bCompassFind ~= self.bFind then
        g_bCompassFind = self.bFind
        Event.Dispatch(EventType.OnCompassStateChanged)
    end
end

function WidgetMainCityCompass:CompassAngleForDraw(nCompassAngle)
	local nAngle = nCompassAngle
    --这是角度制的值，先换算成弧度制
    local nAngleDraw = self.nCompassAngleForDraw / 360 * (math.pi * 2)
    local nCompassRadian = 0

    if nAngle - math.pi <= 0 then
		if nAngleDraw >= math.pi + nAngle then
			nAngleDraw = math.pi * 2 - nAngleDraw
		end
	else
		if nAngleDraw <= nAngle - math.pi then
			nAngleDraw = math.pi * 2 + nAngleDraw
		end
	end
	local nAngleOffset = math.abs(nAngleDraw - nAngle)
	if nAngleOffset >= math.pi then
		nAngleOffset = math.pi
	end

	if nAngleDraw >= nAngle then
		nCompassRadian = nAngleDraw - (0 + nAngleOffset / (math.pi * ROTATE_SPEED))
	else
		nCompassRadian = nAngleDraw + (0 + nAngleOffset / (math.pi * ROTATE_SPEED))
	end

    self.nCompassAngleForDraw = nCompassRadian / (math.pi * 2) * 360
    UIHelper.SetRotation(self.WidgetArrow1,self.nCompassAngleForDraw)
end

--更新个人寻宝表现
function WidgetMainCityCompass:UpdateDigCount(nLevel, nCount)
    if nLevel > self.nCompassLevel then
        local szTips = nLevel == 5 and "罗盘已升满级（10分钟后重置等级）" or string.format("罗盘已升为%d级（10分钟内不升级则重置等级）", nLevel)
        TipsHelper.ShowNormalTip(szTips)
    end
    self.nCompassLevel = nLevel
    for k,v in ipairs(self.tbImgProgress) do
        UIHelper.SetVisible(v, k <= nCount)
    end
    UIHelper.SetSpriteFrame(self.ImgCompass,CompassImg[self.nCompassLevel + 1])
    UIHelper.SetString(self.LabelLevel, string.format("%d级", self.nCompassLevel))
end

--设置团队寻宝进度
function WidgetMainCityCompass:UpdatePartyDigCount(nDigCount)
    self.nDigCount = nDigCount
	local bInTeam 	= GetClientTeam().IsPlayerInTeam(g_pClientPlayer.dwID)
    if bInTeam then
        UIHelper.SetString(self.LabelTeam,nDigCount .. "/" .. MAX_PARTY_COUNT)
    else
        UIHelper.SetString(self.LabelTeam,g_tStrings.STR_COMPASS_TEAM)
    end
end

function WidgetMainCityCompass:GetTwoPointAngle(nOX, nOY, nX, nY)
    local nPi = math.pi
	local nTwoPi = math.pi * 2

    local nDist = ((nX - nOX) ^ 2 + (nY - nOY) ^ 2) ^ 0.5
	if nDist == 0 then
		return -1, nDist
	end

    local nAngle = math.asin((nY - nOY) / nDist)
	if nX < nOX then
		nAngle = nPi + nAngle
	else
		nAngle = nTwoPi - nAngle
	end
	return nAngle, nDist
end

--更新距离，之类的
function WidgetMainCityCompass:UpdateAllArrowRotate()
    local hPlayer = g_pClientPlayer
    local scene 			= hPlayer.GetScene()
	local dwCurrentMapID 	= scene.dwMapID

    local tTargetList 		= self.tLocalData.tChestList or {}
    local i = self.nIndex
    if tTargetList[i] then
        local nMapID = tTargetList[i].nMapID
        if dwCurrentMapID ~= nMapID then
            --寻宝结束
            UIHelper.SetString(self.LabelTextTitle, g_tStrings.STR_START_COMPASS)
            UIHelper.SetTextColor(self.LabelTextTitle, cc.c4b(255, 255, 255, 255))
            UIHelper.SetVisible(self.LabelStart,true)
            UIHelper.SetVisible(self.WidgetArrow1,false)

            if g_bCompassStart then
                g_bCompassStart = false
                Event.Dispatch(EventType.OnCompassStateChanged)
            end
        else
            if tTargetList[i].szDistance then
                UIHelper.SetString(self.LabelTextTitle,UIHelper.GBKToUTF8(tTargetList[i].szDistance))
                UIHelper.SetTextColor(self.LabelTextTitle, cc.c4b(255, 255, 255, 255))
            end
            if tTargetList[i].nIndex == 3 then--团队
            end
            if tTargetList[i].nIndex == 4 then--个人
            end

            if not g_bCompassStart then
                g_bCompassStart = true
                Event.Dispatch(EventType.OnCompassStateChanged)
            end
        end
    end
end

function WidgetMainCityCompass:UpdateTeamPointState(bTeamPointAppear)
    local tTargetList = self.tLocalData.tChestList or {}
    self.nIndex = 1
    if bTeamPointAppear then
        if table.get_len(tTargetList) == 1 then
            UIHelper.SetVisible(self.BtnTeamPoint, false)
            UIHelper.SetVisible(self.BtnTeamPointEsc, true)

            UIHelper.SetVisible(self.LabelHintTeamPoint, true)
            UIHelper.SetVisible(self.LabelTeam, false)
            UIHelper.SetVisible(self.ImgTeamIcon, false)
            self.nCompassState = COMPASS_TAPE.TEAM
        elseif table.get_len(tTargetList) == 2 then
            UIHelper.SetVisible(self.BtnTeamPoint, true)
            UIHelper.SetVisible(self.BtnTeamPointEsc, false)

            UIHelper.SetVisible(self.LabelHintTeamPoint, false)
            UIHelper.SetVisible(self.LabelTeam, true)
            UIHelper.SetVisible(self.ImgTeamIcon, true)
            self.nCompassState = COMPASS_TAPE.PERSONAL
        end
    else
        UIHelper.SetVisible(self.BtnTeamPoint, false)
        UIHelper.SetVisible(self.BtnTeamPointEsc, false)

        UIHelper.SetVisible(self.LabelHintTeamPoint, false)
        UIHelper.SetVisible(self.LabelTeam, true)
        UIHelper.SetVisible(self.ImgTeamIcon, true)
        self.nCompassState = COMPASS_TAPE.PERSONAL
    end
end

function WidgetMainCityCompass:SwitchToTeamPoint(bTeam)
    local tTargetList = self.tLocalData.tChestList or {}
    

    UIHelper.SetVisible(self.BtnTeamPoint, not bTeam)
    UIHelper.SetVisible(self.BtnTeamPointEsc, bTeam)

    UIHelper.SetVisible(self.LabelHintTeamPoint, bTeam)
    UIHelper.SetVisible(self.LabelTeam, not bTeam)
    UIHelper.SetVisible(self.ImgTeamIcon, not bTeam)

    if table.get_len(tTargetList) == 1 then
        self.nIndex = bTeam and 1 or 2
    elseif table.get_len(tTargetList) == 2 then
        self.nIndex = bTeam and 2 or 1
    end
    self.nCompassState = bTeam and COMPASS_TAPE.TEAM or COMPASS_TAPE.PERSONAL
    if bTeam then
        Event.Dispatch("OnRemoteRemoveNaviPoint", "TreasurePoint")
    else
        RemoteCallToServer("On_Xunbao_FreshGuide3D")
    end
    
end

function WidgetMainCityCompass:UpdateTeamPointBuffCD()
    local tBuffInfo = Buffer_GetTimeData(TEAMBUFFID)
    if tBuffInfo then
        local nLeftFrame = Buffer_GetLeftFrame(tBuffInfo)
        local szTime = self:GetFormatTime(nLeftFrame)
        UIHelper.SetString(self.LabelHintTeamPoint, string.format("团队宝藏：%s", szTime))
        UIHelper.SetString(self.LabelTeamPoint, string.format("追踪团队宝藏  %s", szTime))
    end
end

function WidgetMainCityCompass:GetFormatTime(nTime)
    nTime = nTime / GLOBAL.GAME_FPS
    local nM = math.floor(nTime / 60)
    local nS = math.floor(nTime % 60)
    local szTimeText = ""

    if nM ~= 0 then
        szTimeText= szTimeText..nM..":"
    end

    if nS < 10 and nM ~= 0 then
        szTimeText = szTimeText.."0"
    end

    szTimeText= szTimeText..nS

    return szTimeText
end

function WidgetMainCityCompass:AddFangshiNaviPoint(dwMapID)
    local tPoint = {}
    local player = g_pClientPlayer
    local tbData = player and player.GetMapMark() or {}
    for i = 1, #tbData do
        local tMarkD = tbData[i]
        if tMarkD.nType == 318 then
            tPoint = {fX = tMarkD.nX, fY = tMarkD.nY, fZ = tMarkD.nZ}
            Event.Dispatch("OnRemoteAddNaviPoint", "TreasurePoint", dwMapID, tPoint)
            break
        end
    end
end

function WidgetMainCityCompass:UpdateFangshiTime()
    local tTargetList = self.tLocalData.tChestList or {}
    if self.nIndex == 1 then
        local tbData = tTargetList[self.nIndex]
        if tbData and tbData.nIndex == 2 then
            local nLeft = tbData.nEndTime - GetCurrentTime()
            UIHelper.SetVisible(self.LabelHintFangshiPoint, true)
            UIHelper.SetVisible(self.LabelHintTeamPoint, false)
            UIHelper.SetVisible(self.LayoutTeam, false)
            if nLeft > 0 then
                local nH, nM, nS = TimeLib.GetTimeToHourMinuteSecond(nLeft, false)
                local szValue = "魂墟封印 "..string.format("%02d:%02d", nM, nS)
                UIHelper.SetString(self.LabelHintFangshiPoint, szValue)
            end
        else
            UIHelper.SetVisible(self.LayoutTeam, true)
            UIHelper.SetVisible(self.LabelHintFangshiPoint, false)
        end
    elseif self.nIndex == 2 then
        local tbData = tTargetList[self.nIndex]
        if tbData then
            UIHelper.SetVisible(self.LabelHintFangshiPoint, false)
        end
    end

end

return WidgetMainCityCompass