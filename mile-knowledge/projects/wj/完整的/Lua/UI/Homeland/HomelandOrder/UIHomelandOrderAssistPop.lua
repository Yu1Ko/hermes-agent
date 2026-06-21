-- ---------------------------------------------------------------------------------
-- Author: Unknown
-- Name: UIHomelandOrderAssistPop
-- Date: 2024-01-17 15:24:02
-- Desc: ?
-- ---------------------------------------------------------------------------------
local MIN_MONEY = 1
local MAX_MONEY = 9999
local UIHomelandOrderAssistPop = class("UIHomelandOrderAssistPop")

function UIHomelandOrderAssistPop:OnEnter(dwID, nIndex, DataModel)
    if not self.bInit then
        self:RegEvent()
        self:BindUIEvent()
        self.bInit = true
    end
    self.dwID = dwID
    self.nIndex = nIndex
    self.DataModel = DataModel
    self:UpdateInfo()
end

function UIHomelandOrderAssistPop:OnExit()
    self.bInit = false
    self:UnRegEvent()
end

function UIHomelandOrderAssistPop:BindUIEvent()
    UIHelper.BindUIEvent(self.BtnAnnounce, EventType.OnClick, function ()
        self:Publish()
    end)

    UIHelper.BindUIEvent(self.BtnClose, EventType.OnClick, function ()
        UIMgr.Close(self)
    end)

    UIHelper.BindUIEvent(self.BtnCancel, EventType.OnClick, function ()
        RemoteCallToServer("On_HomeLand_CancelAssist", self.dwID, self.nIndex)
        UIMgr.Close(self)
    end)

    UIHelper.BindUIEvent(self.BtnShare, EventType.OnClick, function ()
        self:ShareAssist()
        UIMgr.Close(self)
    end)
end

function UIHomelandOrderAssistPop:RegEvent()
    --Event.Reg(self, EventType.XXX, func)
end

function UIHomelandOrderAssistPop:UnRegEvent()
    --Event.UnReg(self, EventType.XXX)
end






-- ----------------------------------------------------------
-- Please write your own code below  ↓↓↓
-- ----------------------------------------------------------

function UIHomelandOrderAssistPop:UpdateInfo()
    local tData = self.DataModel.GetOrderData(HLORDER_TYPE.FLOWER, self.nIndex)
    local tRefreshData      = GDAPI_GetRefreshData(HLORDER_TYPE.FLOWER)
    if not tData then
        return
    end
    UIHelper.SetVisible(self.BtnShare, tData.bAssist)
    UIHelper.SetVisible(self.BtnCancel, tData.bAssist)
    UIHelper.SetVisible(self.WidgetAssistMoney01, tData.bAssist)

    UIHelper.SetVisible(self.BtnAnnounce, not tData.bAssist)
    UIHelper.SetVisible(self.EditPaginate, not tData.bAssist)
    UIHelper.SetVisible(self.WidgetAssistMoney, not tData.bAssist)
    if tData.bAssist then
        UIHelper.SetString(self.LabelMoneyToatal01, tData.nMoney)
    end
    UIHelper.SetString(self.LaberRemarks, string.format(g_tStrings.STR_HOMELAND_ASSIST_TITLE, tRefreshData.nCurAssist))
    UIHelper.LayoutDoLayout(self.LayoutButton)
end

function UIHomelandOrderAssistPop:Publish()
    local dwID   = self.dwID
    local nMoney = tonumber(UIHelper.GetText(self.EditPaginate))
    local nIndex = self.nIndex
    -- local szName = UI_GetClientPlayerName()
    if not dwID then
        return
    end

    if nMoney < MIN_MONEY or nMoney > MAX_MONEY then
        OutputMessage("MSG_ANNOUNCE_RED", g_tStrings.STR_HOMELAND_ILLEGAL_MONEY)
        return
    end
    RemoteCallToServer("On_HomeLand_PublishAssist", dwID, nIndex, nMoney)
    UIMgr.Close(self)
end

function UIHomelandOrderAssistPop:ShareAssist()
    local szName = PlayerData.GetClientPlayer().szName
    local dwID   = self.dwID
    local nIndex = self.nIndex
    local tData  = self.DataModel.GetOrderData(HLORDER_TYPE.FLOWER, nIndex)
    local aAllMyOwnHomeData, aAllPrivateHomeData = HomelandData.GetAllMyLandInfo()
    if aAllMyOwnHomeData and not table.is_empty(aAllMyOwnHomeData) then
        local tbInfo = aAllMyOwnHomeData[1]
        ChatHelper.SendLandToChat(tbInfo.nIndex, tbInfo.nMapID, tbInfo.nCopyIndex, tbInfo.nLandIndex)
    elseif aAllPrivateHomeData and not table.is_empty(aAllPrivateHomeData) then
        local tbInfo = aAllPrivateHomeData[1]
        ChatHelper.SendPrivateLandToChat(tbInfo.nSkinID or 0, tbInfo.nMapID, tbInfo.nCopyIndex)
    end

    ChatHelper.SendHomelandOrderToChat(dwID, tData.nMoney, szName)
end
return UIHomelandOrderAssistPop