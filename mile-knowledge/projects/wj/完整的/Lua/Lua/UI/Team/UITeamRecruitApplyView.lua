-- ---------------------------------------------------------------------------------
-- Author: Unknown
-- Name: UITeamRecruitApplyView
-- Date: 2023-02-07 11:16:03
-- Desc: ?
-- ---------------------------------------------------------------------------------

local tbTogIndex2Type = {
    [1] = "Heal",
    [2] = "T",
    [3] = "Dps",
    [4] = "Leader",
    [5] = "Pay",
}

local UITeamRecruitApplyView = class("UITeamRecruitApplyView")

function UITeamRecruitApplyView:OnEnter(tbRecruitInfo)
    if not self.bInit then
        self:RegEvent()
        self:BindUIEvent()
        self.bInit = true
    end

    self.tbRecruitInfo = tbRecruitInfo
    self:UpdateInfo()
end

function UITeamRecruitApplyView:OnExit()
    self.bInit = false
    self:UnRegEvent()
end

function UITeamRecruitApplyView:BindUIEvent()
    for _, togPosition in ipairs(self.tbTogPosition) do
        UIHelper.BindUIEvent(togPosition, EventType.OnSelectChanged, function (_, bSelected)
            self:OnSelectedPosition(togPosition, bSelected)
        end)
    end

    if Platform.IsWindows() or Platform.IsMac() then
        UIHelper.RegisterEditBoxEnded(self.EditBox, function()
            self:UpdateEditBoxText()
        end)
    else
        UIHelper.RegisterEditBoxReturn(self.EditBox, function()
            self:UpdateEditBoxText()
        end)
    end

    -- UIHelper.RegisterEditBoxChanged(self.EditBox, function ()
    --     self:UpdateEditBoxText()
    -- end)

    UIHelper.BindUIEvent(self.BtnSendApplication, EventType.OnClick, function ()
        self:RegisterApply()
    end)

    UIHelper.BindUIEvent(self.BtnClose, EventType.OnClick, function ()
        UIMgr.Close(self)
    end)
end

function UITeamRecruitApplyView:RegEvent()
    --Event.Reg(self, EventType.XXX, func)
end

function UITeamRecruitApplyView:UnRegEvent()
    --Event.UnReg(self, EventType.XXX)
end

-- ----------------------------------------------------------
-- Please write your own code below  ↓↓↓
-- ----------------------------------------------------------

function UITeamRecruitApplyView:UpdateInfo()
    local hPlayer = GetClientPlayer()
    local nBaseScores = hPlayer.GetBaseEquipScore()
	local nStrengthScores = hPlayer.GetStrengthEquipScore()
	local nStoneScores = hPlayer.GetMountsEquipScore()
	local nScores =  nBaseScores + nStrengthScores + nStoneScores
    UIHelper.SetString(self.LabelEquipScore, nScores)
    UIHelper.SetString(self.LabelRoleName, UIHelper.GBKToUTF8(hPlayer.szName))
    UIHelper.SetSpriteFrame(self.ImgIcon01, PlayerForceID2SchoolImg2[hPlayer.dwForceID])
    UIHelper.AddPrefab(PREFAB_ID.WidgetHead, self.WidgetMemberHead, hPlayer.dwID)

    CampData.SetUICampImg(self.ImgIcon02, hPlayer.nCamp)
end

function UITeamRecruitApplyView:OnSelectedPosition(toggle, bSelected)
    if not bSelected then
        return
    end
    local dwAllCheck = 0
    local dwForceID = GetClientPlayer().dwForceID
    for index, togPosition in ipairs(self.tbTogPosition) do
        if UIHelper.GetSelected(togPosition) or togPosition == toggle then
            local szType = tbTogIndex2Type[index]
            local dwMask = Table_GetTeamRecruitPosMask(szType)
            dwAllCheck = BitwiseOr(dwAllCheck, dwMask)
        end
    end
    local bOk = Table_GetTeamRecruitForceMask(dwForceID, dwAllCheck)
    if not bOk then
        OutputMessage("MSG_ANNOUNCE_NORMAL", g_tStrings.STR_TEAM_RECRUIT_MASK)
        Timer.AddFrame(self, 1, function ()
            UIHelper.SetSelected(toggle, false)
        end)
    end
end

function UITeamRecruitApplyView:UpdateEditBoxText()
    local szContent = UIHelper.GetString(self.EditBox)
    local nCharNum = TeamBuilding.GetStringCharCount(szContent)
    UIHelper.SetString(self.LabelEditBoxNum, ""..nCharNum.."/30")
end

function UITeamRecruitApplyView:RegisterApply()
    local dwAllCheck = 0
    for index, togPosition in ipairs(self.tbTogPosition) do
        if UIHelper.GetSelected(togPosition) then
            local szType = tbTogIndex2Type[index]
            local dwMask = Table_GetTeamRecruitPosMask(szType)
            dwAllCheck = BitwiseOr(dwAllCheck, dwMask)
        end
    end
    if dwAllCheck == 0 then
        OutputMessage("MSG_ANNOUNCE_NORMAL", g_tStrings.STR_RAIDPOS_SELECT)
		return
    end
    local dwApplyID = self.tbRecruitInfo["dwRoleID"]
    local szRoomID = self.tbRecruitInfo["szRoomID"]
    local szContent = UIHelper.GetString(self.EditBox)
    if szContent == "" then
        szContent = self.EditBox:getPlaceHolder()
    end
    local nHas = TeamBuilding.HasBuff()
    if szRoomID then
        GetGlobalRoomPushClient().RegisterRoomPushApply(szRoomID, dwAllCheck, nHas, UIHelper.UTF8ToGBK(szContent))
    else
        RegisterApply(dwApplyID, dwAllCheck, nHas, UIHelper.UTF8ToGBK(szContent))
    end
    UIMgr.Close(self)
end

return UITeamRecruitApplyView