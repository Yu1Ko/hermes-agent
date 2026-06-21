-- ---------------------------------------------------------------------------------
-- Author: Unknown
-- Name: UIWidgetWanHuaSanDuMonitor
-- Date: 2025-08-25 14:44:48
-- Desc: ?
-- ---------------------------------------------------------------------------------

local UIWidgetWanHuaSanDuMonitor = class("UIWidgetWanHuaSanDuMonitor")
local TARGET_PLAYER_MAX_NUM = 2
local TARGET_BUFF_MAX_NUM = 3

function UIWidgetWanHuaSanDuMonitor:OnEnter(bCustom)
    if bCustom then
        UIHelper.SetVisible(self._rootNode, true)
    else
        if not self.bInit then
            self:RegEvent()
            self:BindUIEvent()
            self.bInit = true
        end
    
        self.tPlayerList = {}
        self.tBuffTotalTime	= {}
        local tab = g_tTable.BuffMonitor
        for i = 2, tab:GetRowCount() do
            local tLine = tab:GetRow(i)
            for j = 1, TARGET_BUFF_MAX_NUM do
                local dwBuffID = tLine["dwBuffID" .. j]
                self.tBuffTotalTime[dwBuffID] = 0;
            end
        end
    
        self:UpdateInfo()
    
        Timer.AddCycle(self, 0.1, function ()
            self:UpdateBuffList(self.tPlayerHandleList)
        end)
    end
end

function UIWidgetWanHuaSanDuMonitor:OnExit()
    self.bInit = false
    self:UnRegEvent()
    Timer.DelAllTimer(self)
end

function UIWidgetWanHuaSanDuMonitor:BindUIEvent()
    
end

function UIWidgetWanHuaSanDuMonitor:RegEvent()
    Event.Reg(self, "ON_ADD_BUFF_MONITOR", function()
        self:AddBuffMonitor(arg0, arg1)
    end)

    Event.Reg(self, "ON_REMOVE_BUFF_MONITOR", function()
        self:RemoveBuffMonitor(arg0)
    end)
    
    Event.Reg(self, "BUFF_UPDATE", function()
        if not self.tBuffTotalTime[arg4] then return end
		local player = GetClientPlayer()
		if player.dwID == arg0 and arg1 then
			self:RemoveBuffMonitor(arg4)
		end
		
		local nLeftFrame = arg6 - GetLogicFrameCount()
		self.tBuffTotalTime[arg4] = math.max(self.tBuffTotalTime[arg4], nLeftFrame)
    end)
end

function UIWidgetWanHuaSanDuMonitor:UnRegEvent()
    --Event.UnReg(self, EventType.XXX)
end






-- ----------------------------------------------------------
-- Please write your own code below  ↓↓↓
-- ----------------------------------------------------------

function UIWidgetWanHuaSanDuMonitor:UpdateInfo()
    local pPlayer = GetClientPlayer() or {}

    local hPlayer = {}

    local info = self.tPlayerList[1]
    if info then
        UIHelper.SetVisible(self._rootNode, true)
        local szPath = DefaultAvatar[info.dwForceID] or "Resource/PlayerAvatar/jianghu.png"
        UIHelper.SetTexture(self.ImgTargetHead, szPath)
        UIHelper.SetString(self.LabelTargetName, UIHelper.GBKToUTF8(info.szName))

        hPlayer.dwMainBuffID = info.dwBuffID
        local tBuff = self:GetBuffInfoList(info.dwBuffID)
        for i = 1, table.get_len(tBuff) do
            hPlayer[i] = {
                dwMainBuffID = info.dwBuffID,
				dwSrcID  = pPlayer.dwID,
				dwBuffID = tBuff[i].dwBuffID,
				dwBuffIconID = tBuff[i].dwBuffIconID
            }
        end
        self:UpdateBuffList(hPlayer)
    else
        UIHelper.SetVisible(self._rootNode, false)
    end
    self.tPlayerHandleList = hPlayer
end

function UIWidgetWanHuaSanDuMonitor:AddBuffMonitor(dwTargetID, dwBuffID)
    local tar = GetPlayer(dwTargetID) or GetNpc(dwTargetID)
	if not tar then return end
    
    for k, v in ipairs(self.tPlayerList) do
        if v.dwBuffID == dwBuffID and v.dwTargetID == dwTargetID then
            self:UpdateInfo()
            return
        end
    end

    table.insert(self.tPlayerList, {
		dwTargetID 	= dwTargetID,
		dwBuffID 	= dwBuffID,
		szName 		= tar.szName or  "BuffID: " .. dwBuffID,
		dwForceID	= tar.dwForceID or 1,
	})
    
    if #self.tPlayerList > 1 then
		table.remove(self.tPlayerList, 1)
	end
	self:UpdateInfo()
end

function UIWidgetWanHuaSanDuMonitor:RemoveBuffMonitor(dwBuffID)
    for k, v in ipairs(self.tPlayerList) do
        if v.dwBuffID == dwBuffID then
            self.tPlayerList = {}
            break
        end
    end
    self:UpdateInfo()
end

function UIWidgetWanHuaSanDuMonitor:GetBuffInfoList(dwBuffID)
	local tBuff 	= {}
	local tTab 		= g_tTable.BuffMonitor:Search(dwBuffID)
	if not tTab then return tBuff end
	
	for i = 1, TARGET_BUFF_MAX_NUM do
		local info = {
			dwBuffID = tTab["dwBuffID" .. i],
			dwBuffIconID = tTab["dwBuffIconID" .. i],
		}
		tBuff[i] = info
	end
	return tBuff
end

function UIWidgetWanHuaSanDuMonitor:GetBuffByID(dwSrcID, dwBuffID)
	if not dwBuffID then return end
	
	local player = GetClientPlayer()
	if not player then return end
	
	for i = 1, player.GetBuffCount() do
		local buff = {}
		Buffer_Get(player, i - 1, buff)
		if buff.dwSkillSrcID == dwSrcID and buff.dwID == dwBuffID then
			return buff
		end
	end
end

function UIWidgetWanHuaSanDuMonitor:UpdateBuffList(hPlayer)
    for i, hBuff in ipairs(hPlayer) do
        local buff = self:GetBuffByID(hBuff.dwSrcID, hBuff.dwBuffID)
		if buff then
			local nLeftFrame = Buffer_GetLeftFrame(buff)
			if nLeftFrame >= 0 then
				UIHelper.SetVisible(self.tbBuffList[i], true)
                local tbScript = UIHelper.GetBindScript(self.tbBuffList[i])
                local szPath = UIHelper.GetIconPathByIconID(hBuff.dwBuffIconID)
                UIHelper.SetTexture(tbScript.ImgWanHuaBuff, UIHelper.GetIconPathByIconID(hBuff.dwBuffIconID))
				
				local nTotalFrame = self.tBuffTotalTime[hBuff.dwBuffID]
                UIHelper.SetProgressBarPercent(tbScript.barWanHuaBuff, nLeftFrame / nTotalFrame * 100)
				local nHour, nMinute, nSecond, nTenthSec = TimeLib.GetTimeToHourMinuteSecondTenthSec(nLeftFrame, true)
				local szTimeText = tostring(nHour * 3600 + nMinute * 60 + nSecond) .. '.' .. tostring(nTenthSec)
                UIHelper.SetString(tbScript.LabelWanHuaBuff, szTimeText)
			else
                UIHelper.SetVisible(self.tbBuffList[i], false)
			end
		else
			UIHelper.SetVisible(self.tbBuffList[i], false)
		end
    end
    UIHelper.LayoutDoLayout(self.LayoutWanHuaBuff)
end

return UIWidgetWanHuaSanDuMonitor