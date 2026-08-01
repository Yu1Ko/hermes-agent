-- ---------------------------------------------------------------------------------
-- Author: Unknown
-- Name: UIPanelSeasonRewardView
-- Date: 2026-03-11 17:52:49
-- Desc: ?
-- ---------------------------------------------------------------------------------
-- UIMgr.Open(VIEW_ID.PanelSeasonRewardList)
local UIPanelSeasonRewardView = class("UIPanelSeasonRewardView")

function UIPanelSeasonRewardView:OnEnter()
    if not self.bInit then
        self:RegEvent()
        self:BindUIEvent()
        self.bInit = true
    end
    self:UpdateInfo()
end

function UIPanelSeasonRewardView:OnExit()
    self.bInit = false
    self:UnRegEvent()
end

function UIPanelSeasonRewardView:BindUIEvent()
    UIHelper.BindUIEvent(self.BtnClose, EventType.OnClick, function()
        UIMgr.Close(self)
    end)

    UIHelper.BindUIEvent(self.ScrollViewRewardBigList, EventType.OnScrollingScrollView, function (_, eventType)
        local nX, nY = UIHelper.GetScrolledPosition(self.ScrollViewRewardBigList)
        UIHelper.SetScrolledPosition(self.ScrollViewRewardBigBg, nX, nY)
	end)
end

function UIPanelSeasonRewardView:RegEvent()
    Event.Reg(self, EventType.HideAllHoverTips, function()
        self:CloseTip()
    end)
end

function UIPanelSeasonRewardView:UnRegEvent()
    --Event.UnReg(self, EventType.XXX)
end






-- ----------------------------------------------------------
-- Please write your own code below  ↓↓↓
-- ----------------------------------------------------------
local function GetSeasonRewardPath(tSeasonReward)
    if not tSeasonReward then
        return
    end

    if not tSeasonReward.bRoleType then
        return tSeasonReward.szMobilePath
    end

    local pPlayer = GetClientPlayer()
    local nRoleType = pPlayer and pPlayer.nRoleType or ROLE_TYPE.STANDARD_MALE
    if nRoleType == ROLE_TYPE.STANDARD_MALE then
        return tSeasonReward.szMobileStandardMan
    elseif nRoleType == ROLE_TYPE.STANDARD_FEMALE then
        return tSeasonReward.szMobileStandardFemale
    elseif nRoleType == ROLE_TYPE.LITTLE_BOY then
        return tSeasonReward.szMobileLittleBoy
    elseif nRoleType == ROLE_TYPE.LITTLE_GIRL then
        return tSeasonReward.szMobileLittleGirl
    end
end

function UIPanelSeasonRewardView:UpdateInfo()
    local tbTopRewardList = Table_GetSeasonReward("RewardPanelPic")
    local tbOtherRewardList = Table_GetSeasonReward("RewardPanelItem")
    for i, widget in ipairs(self.tbRewardList) do
        local tbRewardInfo = tbTopRewardList[i]
        if tbRewardInfo then
            local script = UIHelper.AddPrefab(PREFAB_ID.WidgetSeasonRewardBigCell, widget)
            self:UpdateRewardInfo(script, tbRewardInfo)
        else
            UIHelper.SetVisible(UIHelper.GetParent(widget), false)
        end
    end
    Timer.AddFrame(self, 10, function ()
        UIHelper.ScrollViewDoLayout(self.ScrollViewRewardBigList)
    end)


    for i, tbReward in ipairs(tbOtherRewardList) do
        local script = UIHelper.AddPrefab(PREFAB_ID.WidgetItem_80, self.ScrollViewSeasonOtherList)
        UIHelper.SetAnchorPoint(script._rootNode, 0, -0.5)
        self:UpdateOtherRewardInfo(script, tbReward)
    end

    UIHelper.ScrollViewDoLayout(self.ScrollViewSeasonOtherList)

end

function UIPanelSeasonRewardView:UpdateRewardInfo(script, tbRewardInfo)
    if not tbRewardInfo then
        return
    end
    local nTabType, nTabID, nCount = tbRewardInfo.nType, tbRewardInfo.nIndex, tbRewardInfo.nCount
    local itemInfo = GetItemInfo(nTabType, nTabID)
    if not itemInfo then
        return
    end
    local szName = UIHelper.GBKToUTF8(itemInfo.szName) or ""
    local szTypePath = tbRewardInfo.szMobileTitlePath
    local szPath = GetSeasonRewardPath(tbRewardInfo)
    local szHint = UIHelper.GBKToUTF8(tbRewardInfo.szColorTips) or ""
    if szPath then
        UIHelper.SetTexture(script.ImgReward, szPath)
    end
    UIHelper.SetString(script.LabelSeasonTime, szName)
    UIHelper.SetSpriteFrame(script.ImgRewardRewardType, szTypePath)
    UIHelper.SetString(script.LabelSeasonHint, szHint)
end

function UIPanelSeasonRewardView:UpdateOtherRewardInfo(script, tbRewardInfo)
    if not tbRewardInfo then
        return
    end
    local nTabType, nTabID, nCount = tbRewardInfo.nType, tbRewardInfo.nIndex, tbRewardInfo.nCount
    script:OnInitWithTabID(nTabType, nTabID, nCount)
    script:SetClickCallback(function(nTabType, nTabID)
        -- local nReachLv = CollectionData.GetReachLv() or 0
        -- local nGetRewardLv = CollectionData.GetGetRewardLv() or 0
        -- local bCanGet = nGetRewardLv < tbInfo.nLevel
        -- if bCanGet then
        --     RemoteCallToServer("On_Daily_GetRewardLevel", tbInfo.nLevel)
        -- else
            self:OpenTip(script, nTabType, nTabID)
        -- end
    end)
    if nCount == 1 then
        script:SetLabelCount()
    end
end

function UIPanelSeasonRewardView:OpenTip(scriptView, nTabType, nTabID)
    self:CloseTip()
    local tip, scriptItemTip = TipsHelper.ShowNodeHoverTipsInDir(PREFAB_ID.WidgetItemTip, scriptView._rootNode, TipsLayoutDir.TOP_CENTER)
    scriptItemTip:OnInitWithTabID(nTabType, nTabID)
    scriptItemTip:SetBtnState({})
    self.scriptIcon = scriptView
end

function UIPanelSeasonRewardView:CloseTip()
    if self.scriptIcon then
        TipsHelper.DeleteHoverTips(PREFAB_ID.WidgetItemTip)
        self.scriptIcon:RawSetSelected(false)
        self.scriptIcon = nil
    end
end

return UIPanelSeasonRewardView