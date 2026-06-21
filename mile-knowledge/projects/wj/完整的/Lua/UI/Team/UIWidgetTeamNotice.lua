-- ---------------------------------------------------------------------------------
-- Author: Unknown
-- Name: UIWidgetTeamNotice
-- Date: 2026-03-25 15:09:15
-- Desc: ?
-- ---------------------------------------------------------------------------------

local UIWidgetTeamNotice = class("UIWidgetTeamNotice")

function UIWidgetTeamNotice:OnEnter()
    if not self.bInit then
        self:RegEvent()
        self:BindUIEvent()
        self.bInit = true
    end

    self:UpdateVisible()
        
    local tbSizeInfo = MainCityCustomData.GetFontSizeInfo()
	if tbSizeInfo then
		UIHelper.SetScale(self._rootNode, tbSizeInfo["nTeamNotice"]  or 1, tbSizeInfo["nTeamNotice"] or 1)
	end
end

function UIWidgetTeamNotice:OnExit()
    self.bInit = false
    self:UnRegEvent()
end

function UIWidgetTeamNotice:BindUIEvent()
    UIHelper.SetTouchEnabled(self.LayoutTeamNotice, true)
    UIHelper.BindFreeDrag(self, self.BtnTeamNotice)
    UIHelper.BindFreeDrag(self, self.BtnRoomNotice)

    UIHelper.BindUIEvent(self.BtnTeamNotice, EventType.OnClick, function()
        if self.bTeamNoticeScript then
            local bVisible = UIHelper.GetVisible(self.bTeamNoticeScript.WidgetTeamNoticeTips)
            UIHelper.SetVisible(self.bTeamNoticeScript.WidgetTeamNoticeTips, not bVisible)
            self:UpdateVisible()
        end
    end)

    UIHelper.BindUIEvent(self.BtnRoomNotice, EventType.OnClick, function()
        if self.bRoomNoticeScript then
            local bVisible = UIHelper.GetVisible(self.bRoomNoticeScript.WidgetTeamNoticeTips)
            UIHelper.SetVisible(self.bRoomNoticeScript.WidgetTeamNoticeTips, not bVisible)
            self:UpdateVisible()
        end
    end)
end

function UIWidgetTeamNotice:RegEvent()
    Event.Reg(self, "ON_BG_CHANNEL_MSG", function (szKey, nChannel, dwTalkerID, szName, aParam)
        if szKey == "RAID_NOTICE" and nChannel == PLAYER_TALK_CHANNEL.RAID then
            self:ShowTeamNotice(aParam)
        elseif szKey == "ROOM_NOTICE" and nChannel == PLAYER_TALK_CHANNEL.ROOM then
            self:ShowRoomNotice(aParam)
        end
    end)

    Event.Reg(self, "PARTY_DELETE_MEMBER", function(dwTeamID, dwMemberID, szName, nGroupIndex)
        if g_pClientPlayer and g_pClientPlayer.dwID == dwMemberID then
            self:CloseTeamNotice()
        end
    end)

    Event.Reg(self, "PARTY_DISBAND", function ()
        self:CloseTeamNotice()
    end)

    Event.Reg(self, "On_Close_TeamNotice", function ()
        self:CloseTeamNotice()
    end)

    Event.Reg(self, "LEAVE_GLOBAL_ROOM", function ()
        self:CloseRoomNotice()
    end)

    Event.Reg(self, "On_Close_RoomNotice", function ()
        self:CloseRoomNotice()
    end)

    Event.Reg(self, "LOADING_END", function()
        if not g_pClientPlayer then return end
        if not TeamData.IsPlayerInTeam() then
            self:CloseTeamNotice()
        end
        if not RoomData.IsHaveRoom() then
            self:CloseRoomNotice()
        end
    end)

    Event.Reg(self, EventType.OnSaveDragNodePosition, function ()
		local size = UIHelper.GetCurResolutionSize()
		local szNodeName = self._rootNode:getName()
		Storage.MainCityNode.tbMaincityNodePos[szNodeName] =
		{
			nX = UIHelper.GetWorldPositionX(self._rootNode),
			nY = UIHelper.GetWorldPositionY(self._rootNode),
			Height = size.height,
			Width = size.width,
		}
		Storage.MainCityNode.Dirty()
    end)

    Event.Reg(self, EventType.OnSetDragNodeScale, function (tbSizeType)
        if tbSizeType then
            UIHelper.SetScale(self._rootNode, tbSizeType["nTeamNotice"] or 1, tbSizeType["nTeamNotice"] or 1)
        end
    end)

    Event.Reg(self, EventType.OnResetDragNodePosition, function (tbDefaultPositionList, nType)
        if nType ~= DRAGNODE_TYPE.TEAMNOTICE then
			return
		end
        local size = UIHelper.GetCurResolutionSize()
        local tbDefaultPosition = tbDefaultPositionList[DRAGNODE_TYPE.TEAMNOTICE]
        local nX, nY = table.unpack(tbDefaultPosition)
        local nRadioX, nRadioY = size.width / 1600, size.height / 900
        UIHelper.SetWorldPosition(self._rootNode, nX * nRadioX, nY * nRadioY)
        MainCityCustomData.ShowScaleSetTip(self, DRAGNODE_TYPE.TEAMNOTICE)
    end)

    Event.Reg(self, EventType.OnUpdateDragNodeCustomState, function (bSubsidiaryCustomState)
        local bTeamVisible = UIHelper.GetVisible(self.BtnTeamNotice)
        local bRoomVisible = UIHelper.GetVisible(self.BtnRoomNotice)
		if bSubsidiaryCustomState then
			self:EnterCustomInfo(bTeamVisible, bRoomVisible)
		else
			self:ExitCustomInfo()
		end
    end)

    Event.Reg(self, EventType.OnWindowsSizeChanged, function(nMode)
        UIHelper.UpdateNodeInsideScreen(self._rootNode)
    end)
end

function UIWidgetTeamNotice:UnRegEvent()
    --Event.UnReg(self, EventType.XXX)
end






-- ----------------------------------------------------------
-- Please write your own code below  ↓↓↓
-- ----------------------------------------------------------
function UIWidgetTeamNotice:ShowTeamNotice(aParam)
    if aParam then
        if aParam[2] == "" or aParam[2] == UI_GetClientPlayerGlobalID() then
            if not self.bTeamNoticeScript then
                self.bTeamNoticeScript = UIHelper.AddPrefab(PREFAB_ID.WidgetTeamNoticeTips, self.LayoutNotice, false, self)
                UIHelper.BindFreeDrag(self, self.bTeamNoticeScript.BtnDrag)
            end

            local szTitle = UIHelper.GBKToUTF8(aParam[1][1])
            local szContent = UIHelper.GBKToUTF8(aParam[1][2])
            self.bTeamNoticeScript:SetTeamNotice(szTitle, szContent)

            UIHelper.SetVisible(self.bTeamNoticeScript.WidgetTeamNoticeTips, true)
            UIHelper.LayoutDoLayout(self.LayoutNotice)
            self:UpdateVisible()
        end
    end
end

function UIWidgetTeamNotice:ShowRoomNotice(aParam)
    if aParam then
        if aParam[2] == "" or aParam[2] == UI_GetClientPlayerGlobalID() then
            if not self.bRoomNoticeScript then
                self.bRoomNoticeScript = UIHelper.AddPrefab(PREFAB_ID.WidgetTeamNoticeTips, self.LayoutNotice, true, self)
                UIHelper.BindFreeDrag(self, self.bRoomNoticeScript.BtnDrag)
            end

            local szTitle = UIHelper.GBKToUTF8(aParam[1][1])
            local szContent = UIHelper.GBKToUTF8(aParam[1][2])
            self.bRoomNoticeScript:SetTeamNotice(szTitle, szContent)

            UIHelper.SetVisible(self.bRoomNoticeScript.WidgetTeamNoticeTips, true)
            UIHelper.LayoutDoLayout(self.LayoutNotice)
            self:UpdateVisible()
        end
    end
end

function UIWidgetTeamNotice:CloseTeamNotice()
    if self.bTeamNoticeScript then
        UIHelper.RemoveFromParent(self.bTeamNoticeScript.WidgetTeamNoticeTips)
        self.bTeamNoticeScript = nil
        UIHelper.LayoutDoLayout(self.LayoutNotice)
        self:UpdateVisible()
    end
end

function UIWidgetTeamNotice:CloseRoomNotice()
    if self.bRoomNoticeScript then
        UIHelper.RemoveFromParent(self.bRoomNoticeScript.WidgetTeamNoticeTips)
        self.bRoomNoticeScript = nil
        UIHelper.LayoutDoLayout(self.LayoutNotice)
        self:UpdateVisible()
    end
end

function UIWidgetTeamNotice:UpdateVisible()
    local bTeamVisible = self.bTeamNoticeScript and UIHelper.GetVisible(self.bTeamNoticeScript.WidgetTeamNoticeTips) or false
    local bRoomVisible = self.bRoomNoticeScript and UIHelper.GetVisible(self.bRoomNoticeScript.WidgetTeamNoticeTips) or false
    local bVisible = bTeamVisible or bRoomVisible
    local bShowTeamBtn = self.bTeamNoticeScript or false
    local bShowRoomBtn = self.bRoomNoticeScript or false
    UIHelper.SetVisible(self.BtnTeamNotice, bShowTeamBtn)
    UIHelper.SetVisible(self.BtnRoomNotice, bShowRoomBtn)
    UIHelper.SetVisible(self.ImgTeamSelect, bTeamVisible)
    UIHelper.SetVisible(self.ImgRoomSelect, bRoomVisible)
    UIHelper.LayoutDoLayout(self.LayoutTeamNotice)
    UIHelper.LayoutDoLayout(self.LayoutNotice)
    UIHelper.SetVisible(self._rootNode, bShowTeamBtn or bShowRoomBtn)
    TeamData.SetTeamAndRoomNoticeState(bShowTeamBtn, bShowRoomBtn)
end

function UIWidgetTeamNotice:EnterCustomInfo(bTeamVisible, bRoomVisible)
    self.bTeamVisible = bTeamVisible
    self.bRoomVisible = bRoomVisible
    UIHelper.SetVisible(self.ImgSelectZone, true)
    UIHelper.SetEnable(self.BtnTeamNotice, false)
    UIHelper.SetEnable(self.BtnRoomNotice, false)
    UIHelper.SetVisible(self.BtnTeamNotice, true)
    UIHelper.SetVisible(self.BtnRoomNotice, true)
    local function callback()
		MainCityCustomData.ShowScaleSetTip(self, DRAGNODE_TYPE.TEAMNOTICE)
	end
    UIHelper.BindFreeDrag(self, self.LayoutTeamNotice, 0, callback)
    UIHelper.CascadeDoLayoutDoWidget(self.LayoutTeamNotice, true, true)
    UIHelper.SetVisible(self._rootNode, true) 
end

function UIWidgetTeamNotice:ExitCustomInfo()
    UIHelper.BindFreeDrag(self, self.LayoutTeamNotice)
    UIHelper.SetVisible(self.ImgSelectZone, false)
    UIHelper.SetEnable(self.BtnTeamNotice, true)
    UIHelper.SetEnable(self.BtnRoomNotice, true)
    UIHelper.SetVisible(self.BtnTeamNotice, self.bTeamVisible or false)
    UIHelper.SetVisible(self.BtnRoomNotice, self.bRoomVisible or false)
    UIHelper.SetVisible(self._rootNode, self.bTeamVisible or self.bRoomVisible or false) 
    UIHelper.LayoutDoLayout(self.LayoutTeamNotice)
    UIHelper.LayoutDoLayout(self.LayoutNotice)
end

return UIWidgetTeamNotice