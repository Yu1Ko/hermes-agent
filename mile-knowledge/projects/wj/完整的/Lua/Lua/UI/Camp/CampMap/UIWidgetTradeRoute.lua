-- ---------------------------------------------------------------------------------
-- Author: Unknown
-- Name: WidgetTradeRoute
-- Date: 2023-07-25 17:05:24
-- Desc: WidgetTradeRoute 阵营沙盘-跑商
-- ---------------------------------------------------------------------------------

local WidgetTradeRoute = class("WidgetTradeRoute")

function WidgetTradeRoute:OnEnter(tData)
    self.tData = tData

    if not self.bInit then
        self:RegEvent()
        self:BindUIEvent()
        self.bInit = true
    end

    self:UpdateInfo()
end

function WidgetTradeRoute:OnExit()
    self.bInit = false
    self:UnRegEvent()
end

function WidgetTradeRoute:BindUIEvent()
    UIHelper.BindUIEvent(self.BtnTradeCity1, EventType.OnClick, function()
        local tData = self.tData
        if tData then
            self:OnClickTraceNPCBtn(tData.dwSourceLinkID, tData.dwSourceMapID)
        end
    end)
    UIHelper.BindUIEvent(self.BtnTradeCity2, EventType.OnClick, function()
        local tData = self.tData
        if tData then
            self:OnClickTraceNPCBtn(tData.dwTargetLinkID, tData.dwTargetMapID)
        end
    end)
    UIHelper.BindUIEvent(self._rootNode, EventType.OnSelectChanged, function(_, bSelected) --toggle挂在自己_rootNode身上了
        if self.fnSelectedCallback then
            self.fnSelectedCallback(bSelected)
        end
    end)
end

function WidgetTradeRoute:RegEvent()
    --Event.Reg(self, EventType.XXX, func)
end

function WidgetTradeRoute:UnRegEvent()
    --Event.UnReg(self, EventType.XXX)
end






-- ----------------------------------------------------------
-- Please write your own code below  ↓↓↓
-- ----------------------------------------------------------

function WidgetTradeRoute:UpdateInfo()
    local tData = self.tData

    local szTitle = "路线" .. g_tStrings.STR_NUMBER[tData.nIndex]
    if tData.bWarState then
        szTitle = szTitle .. "（当前处于小攻防活动中）"
    end
    UIHelper.SetString(self.LabelTradeRoute, szTitle)

    UIHelper.SetString(self.LabelTradeCity11, tData.szSourceMapName)
    UIHelper.SetString(self.LabelTradeCity12, tData.szSourceCastleName)
    UIHelper.SetString(self.LabelTradeCity21, tData.szTargetMapName)
    UIHelper.SetString(self.LabelTradeCity22, tData.szTargetCastleName)

    local bCampRoute_Good, bCampRoute_Evil = false, false
    if tData.bCampRoute then
        local player = GetClientPlayer()
        if player then
            if player.nCamp == CAMP.GOOD then
                bCampRoute_Good = true
            elseif player.nCamp == CAMP.EVIL then
                bCampRoute_Evil = true
            end
        end
    end
    UIHelper.SetVisible(self.LabelTradeWayCity_H, bCampRoute_Good)
    UIHelper.SetVisible(self.LabelTradeWayCity_E, bCampRoute_Evil)
end

function WidgetTradeRoute:SetSelectedCallback(fnSelectedCallback)
    self.fnSelectedCallback = fnSelectedCallback
end

function WidgetTradeRoute:OnClickTraceNPCBtn(dwLinkID, dwMapID)
    local tLinkInfo = Table_GetCareerLinkNpcInfo(dwLinkID, dwMapID)
    if not tLinkInfo then
        LOG.ERROR("[Camp Map] Trace NPC Error. dwLinkID: %s, dwMapID: %s", tostring(dwLinkID), tostring(dwMapID))
        return
    end

    local szText = UIHelper.GBKToUTF8(tLinkInfo.szNpcName)
    MapMgr.SetTracePoint(szText, tLinkInfo.dwMapID, {tLinkInfo.fX, tLinkInfo.fY, tLinkInfo.fZ})

    UIMgr.Open(VIEW_ID.PanelMiddleMap, dwMapID, 0)
end

return WidgetTradeRoute