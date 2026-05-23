-- ---------------------------------------------------------------------------------
-- Author: Unknown
-- Name: UIHomelandMyHomeCustomBuyMemberCell
-- Date: 2023-04-13 15:56:29
-- Desc: ?
-- ---------------------------------------------------------------------------------

local UIHomelandMyHomeCustomBuyMemberCell = class("UIHomelandMyHomeCustomBuyMemberCell")

function UIHomelandMyHomeCustomBuyMemberCell:OnEnter(tInfo, nIndex)
    if not self.bInit then
        self:RegEvent()
        self:BindUIEvent()
        self.bInit = true
    end
    self.tInfo = tInfo
    self.nIndex = nIndex
    self:UpdateInfo()
end

function UIHomelandMyHomeCustomBuyMemberCell:OnExit()
    self.bInit = false
end

function UIHomelandMyHomeCustomBuyMemberCell:BindUIEvent()
    UIHelper.BindUIEvent(self.TogRanking, EventType.OnSelectChanged, function (_, bSelected)
        if bSelected then
            Event.Dispatch(EventType.OnHomelandGroupBuySelectMember, self.tInfo.GlobalRoleID)
        end
    end)
end

function UIHomelandMyHomeCustomBuyMemberCell:RegEvent()
    Event.Reg(self, EventType.HideAllHoverTips, function ()
        UIHelper.SetSelected(self.TogRanking, false)
    end)
end

function UIHomelandMyHomeCustomBuyMemberCell:UpdateInfo()
    local tInfo = self.tInfo
    local nGlobalRoleID = tInfo.GlobalRoleID
    local nLandIndex = tInfo.LandIndex
    local szPlayerName = UIHelper.GBKToUTF8(tInfo.Name)
    local bReady = tInfo.State == BUY_LAND_GROUPON_PLAYER_STATE.READY

    UIHelper.SetString(self.LabelPlayerName, szPlayerName)
    UIHelper.SetVisible(self.ImgRankBg, math.fmod(self.nIndex,2) == 0)
    if nGlobalRoleID == HomelandGroupBuyData.nLeaderId then
        UIHelper.SetVisible(self.ImgTagBg02, true)
    elseif nGlobalRoleID == HomelandGroupBuyData.nMyGlobalRoleID then
        UIHelper.SetVisible(self.ImgTagBg01, true)
    end

    if nLandIndex == 0 then
        UIHelper.SetString(self.LabelYiRong, g_tStrings.STR_GROUP_BUY_NO_LAND_INDEX)
    else
        UIHelper.SetString(self.LabelYiRong, nLandIndex)
    end

    UIHelper.SetVisible(self.ImgCheck, bReady)  -- 定制确认

    if g_tStrings.tHomelandGroupBuyPlayerState[tInfo.State] and tInfo.State ~= BUY_LAND_GROUPON_PLAYER_STATE.READY_FAILED then    -- 是否达成购买条件
        UIHelper.SetVisible(self.ImgHint, true)
        self.szCareInfo = g_tStrings.tHomelandGroupBuyPlayerState[tInfo.State]
    else
        UIHelper.SetVisible(self.ImgHint, false)
    end
end

return UIHomelandMyHomeCustomBuyMemberCell