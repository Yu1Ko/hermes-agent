-- ---------------------------------------------------------------------------------
-- Author: Unknown
-- Name: UIExtractFavoreabilitySilder
-- Date: 2025-03-31 17:17:04
-- Desc: ?
-- ---------------------------------------------------------------------------------
local REMOTE_DATA = {
	TREASURE_HUNT = 1183,
}
local UIExtractFavoreabilitySilder = class("UIExtractFavoreabilitySilder")

function UIExtractFavoreabilitySilder:OnEnter()
    if not self.bInit then
        self:RegEvent()
        self:BindUIEvent()
        self.bInit = true
    end

    local hPlayer = GetClientPlayer()
    if not hPlayer.HaveRemoteData(REMOTE_DATA.TREASURE_HUNT) then
        hPlayer.ApplyRemoteData(REMOTE_DATA.TREASURE_HUNT, REMOTE_DATA_APPLY_EVENT_TYPE.CLIENT_APPLY_SERVER_CALL_BACK)
        return
    end

    self:UpdateInfo()
end

function UIExtractFavoreabilitySilder:OnExit()
    self.bInit = false
    self:UnRegEvent()
end

function UIExtractFavoreabilitySilder:BindUIEvent()
    UIHelper.BindUIEvent(self.BtnGot, EventType.OnClick, function(btn)
        UIMgr.Open(VIEW_ID.PanelXunBaoReward)
    end)
end

function UIExtractFavoreabilitySilder:RegEvent()
    Event.Reg(self, EventType.OnTBFUpdateAllView, function ()
        self:UpdateInfo()
    end)
end

function UIExtractFavoreabilitySilder:UnRegEvent()
    --Event.UnReg(self, EventType.XXX)
end






-- ----------------------------------------------------------
-- Please write your own code below  ↓↓↓
-- ----------------------------------------------------------

function UIExtractFavoreabilitySilder:UpdateInfo()
    local tBPInfo = GDAPI_TbfWareSeasonLvInfo()
    if not tBPInfo then
        return
    end
    local nCurExp = tBPInfo.nCurExp or 0
    local nLvUpExp = tBPInfo.nLvUpExp or 1
    local nGotLv = tBPInfo.nCurLv or 0
    local szExp = nCurExp .. "/" .. nLvUpExp
    local nPercent = nCurExp / nLvUpExp * 100

    UIHelper.SetString(self.LabelFavorabilityLevel, "寻宝等级："..tostring(nGotLv))
    UIHelper.SetString(self.LabelFavorabilityNum, szExp)
    UIHelper.SetProgressBarPercent(self.ProgressBarFavorability, nPercent)
end


return UIExtractFavoreabilitySilder