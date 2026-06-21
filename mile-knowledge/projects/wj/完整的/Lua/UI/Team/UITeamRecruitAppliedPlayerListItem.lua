-- ---------------------------------------------------------------------------------
-- Author: Unknown
-- Name: UITeamRecruitAppliedPlayerListItem
-- Date: 2023-02-07 15:57:54
-- Desc: ?
-- ---------------------------------------------------------------------------------

local tbPostion2Img = {
    ["Heal"] = "UIAtlas2_Team_Team1_icon_doctor.png",
    ["T"] = "UIAtlas2_Team_Team1_icon_defense.png",
    ["Dps"] = "UIAtlas2_Team_Team1_img_output.png",
    ["Leader"] = "UIAtlas2_Team_Team1_icon_command.png",
    ["Pay"] = "UIAtlas2_Team_Team1_icon_boss.png",
}

local UITeamRecruitAppliedPlayerListItem = class("UITeamRecruitAppliedPlayerListItem")

function UITeamRecruitAppliedPlayerListItem:OnEnter(tbPlayerInfo, fnCallback)
    if not self.bInit then
        self:RegEvent()
        self:BindUIEvent()
        self.bInit = true
    end

    self.tbPlayerInfo = tbPlayerInfo
    self.fnCallback = fnCallback
    self.widgetHead = nil
    self:UpdateInfo()
end

function UITeamRecruitAppliedPlayerListItem:OnExit()
    self.bInit = false
    self:UnRegEvent()
end

function UITeamRecruitAppliedPlayerListItem:BindUIEvent()
    UIHelper.BindUIEvent(self.BtnAccept, EventType.OnClick, function ()
        TeamBuilding.RespondTeamApply(self.tbPlayerInfo, 1)
        self.fnCallback(self.tbPlayerInfo["dwRoleID"], self.tbPlayerInfo["szGlobalID"])
    end)

    UIHelper.BindUIEvent(self.BtnRefuse, EventType.OnClick, function ()
        TeamBuilding.RespondTeamApply(self.tbPlayerInfo, 0)
        self.fnCallback(self.tbPlayerInfo["dwRoleID"], self.tbPlayerInfo["szGlobalID"])
    end)

    UIHelper.BindUIEvent(self.TogCoFightBuff, EventType.OnClick, function ()
        local tBuff = Table_GetTeamSpecialBuff()
        local szTips = string.format("<color=#FFEDA3>%s\n</color><color=#FEFEFE>%s</color>",  UIHelper.GBKToUTF8(tBuff.szName), UIHelper.GBKToUTF8(tBuff.szDes))
        local tips, tipsScript = TipsHelper.ShowNodeHoverTips(PREFAB_ID.WidgetPublicLabelTips, self.TogCoFightBuff, szTips)
        local nTipsWidth, nTipsHeight = UIHelper.GetContentSize(tipsScript.ImgPublicLabelTips)
        tips:SetSize(nTipsWidth, nTipsHeight)
        tips:UpdatePosByNode(self.TogCoFightBuff)
    end)

    UIHelper.BindUIEvent(self.BtnRoleInformation, EventType.OnClick, function()
        self:OnClickHead()
    end)

    UIHelper.BindUIEvent(self.BtnDetail, EventType.OnClick, function()
        local szComment = UIHelper.GBKToUTF8(self.tbPlayerInfo.szComment)
        local szTips = string.format("<color=#FEFEFE>%s</color>",  szComment)
        local tips, tipsScript = TipsHelper.ShowNodeHoverTips(PREFAB_ID.WidgetPublicLabelTips, self.BtnDetail, szTips)
        -- local nTipsWidth, nTipsHeight = UIHelper.GetContentSize(tipsScript.ImgPublicLabelTips)
        -- tips:SetSize(nTipsWidth, nTipsHeight)
        -- tips:UpdatePosByNode(self.BtnDetail)
    end)
end

function UITeamRecruitAppliedPlayerListItem:RegEvent()
    --Event.Reg(self, EventType.XXX, func)
end

function UITeamRecruitAppliedPlayerListItem:UnRegEvent()
    --Event.UnReg(self, EventType.XXX)
end

-- ----------------------------------------------------------
-- Please write your own code below  ↓↓↓
-- ----------------------------------------------------------

function UITeamRecruitAppliedPlayerListItem:UpdateInfo()
    UIHelper.SetString(self.LabelRoleName, UIHelper.LimitUtf8Len(UIHelper.GBKToUTF8(self.tbPlayerInfo["szName"]), 8))
    if not self.widgetHead then
        self.widgetHead = UIHelper.AddPrefab(PREFAB_ID.WidgetHead, self.WidgetHead, dwID)
    end
    self.widgetHead:SetHeadInfo(self.dwID, self.tbPlayerInfo["dwMiniAvatarID"], self.tbPlayerInfo["nRoleType"], self.tbPlayerInfo["nForceID"])
    self.widgetHead:SetClickCallback(function ()
        self:OnClickHead()
    end)
    -- UIHelper.SetSpriteFrame(self.ImgIcon01, PlayerKungfuImg[self.tbPlayerInfo["dwMountKungfuID"]])
    PlayerData.SetMountKungfuIcon(self.ImgIcon01, self.tbPlayerInfo["dwMountKungfuID"], self.tbPlayerInfo["nClientVersionType"])
    UIHelper.SetString(self.LabelEquipScore, self.tbPlayerInfo["nEquipScore"])

    local szComment, bCommentLimit = self:GetFirstLineComment()
    UIHelper.SetString(self.LabelRoleRemark, szComment)
    UIHelper.SetVisible(self.BtnDetail, bCommentLimit)

    UIHelper.SetString(self.LabelLevel, self.tbPlayerInfo["nLevel"])
    CampData.SetUICampImg(self.ImgIcon02, self.tbPlayerInfo["nCamp"])

    local tbPosition = {}
    local nPosition = self.tbPlayerInfo["nPosition"]
    for i = 1, 5 do
        local bBit = GetNumberBit(nPosition, i)
        if bBit then
            table.insert(tbPosition, i)
        end
    end
    for i, img in ipairs(self.tbImgTeamPosition) do
        if i <= #tbPosition then
            local tbInfo = Table_GetTeamRecruitMask(tbPosition[i])
            UIHelper.SetSpriteFrame(img, tbPostion2Img[tbInfo.szPosition])
        else
            UIHelper.SetVisible(img, false)
        end
    end

    if self.tbPlayerInfo["nParam"] == 1 then
        UIHelper.SetVisible(self.TogCoFightBuff, true)
        if not self.itemIconScript then
            self.itemIconScript = UIHelper.AddPrefab(PREFAB_ID.WidgetItem_44, self.WidgetItemBuffIcon)
        end
        local tBuff = Table_GetTeamSpecialBuff()
        self.itemIconScript:OnInitWithIconID(tBuff.dwIconID)
        self.itemIconScript:SetSelectEnable(false)
    else
        UIHelper.SetVisible(self.TogCoFightBuff, false)
    end
    PlayerData.SetPlayerLogionSite(self.ImgLoginSite , self.tbPlayerInfo["nClientVersionType"])

    local dwKungfuID = self.tbPlayerInfo["dwMountKungfuID"]
    local szKungfuName = UIHelper.GBKToUTF8(Table_GetSkillName(dwKungfuID, 1))
    UIHelper.SetString(self.LabelSchoolXinFa, string.format("%s-%s", Table_GetForceName(self.tbPlayerInfo["nForceID"]), szKungfuName))
end

function UITeamRecruitAppliedPlayerListItem:GetFirstLineComment()
    local szComment = UIHelper.GBKToUTF8(self.tbPlayerInfo.szComment)
    local szFirstLine = string.match(szComment, "^[^\r\n]*")
    local bMultiline = string.find(szComment, "[\r\n]") ~= nil
    if bMultiline then
        szFirstLine = szFirstLine .. "..."
    end
    if szFirstLine == "" then
        szFirstLine = "暂无申请信息"
    end
    return UIHelper.LimitUtf8Len(szFirstLine, 18), bMultiline or UIHelper.GetUtf8Len(szFirstLine) > 18
end

function UITeamRecruitAppliedPlayerListItem:OnClickHead()
    local tInfo = self.tbPlayerInfo

    local tbAllMenuConfig = {}
    table.insert(tbAllMenuConfig, {
        szName = "密聊",
        bCloseOnClick = true,
        callback = function ()
            local szName = UIHelper.GBKToUTF8(tInfo["szName"])
            local dwTalkerID = tInfo["dwRoleID"]
            local dwForceID = tInfo["nForceID"]
            local dwMiniAvatarID = tInfo["dwMiniAvatarID"]
            local nRoleType = tInfo["nRoleType"]
            local nLevel = tInfo["nLevel"]
            local szGlobalID = tInfo["szGlobalID"]
            local dwCenterID = tInfo["dwCenterID"]
            local tbData = {szName = szName, dwTalkerID = dwTalkerID, dwForceID = dwForceID, dwMiniAvatarID = dwMiniAvatarID, nRoleType = nRoleType, nLevel = nLevel, szGlobalID = szGlobalID, dwCenterID = dwCenterID}
            ChatHelper.WhisperTo(szName, tbData)
        end
    })
    table.insert(tbAllMenuConfig, {
        szName = "加为好友",
        bCloseOnClick = true,
        callback = function ()
            GetSocialManagerClient().AddFellowship(tInfo["szName"])
        end
    })
    table.insert(tbAllMenuConfig, {
        szName = "查看装备",
        bCloseOnClick = true,
        callback = function()
            UIMgr.Open(VIEW_ID.PanelOtherPlayer, tInfo.dwRoleID, tInfo.dwCenterID, tInfo.szGlobalID)
        end
    })

    table.insert(tbAllMenuConfig, {
        szName = "查看百战信息",
        CloseOnClick = true,
        callback = function()
            MonsterBookData.CheckMonsterBookInfo(tInfo["dwRoleID"], tInfo.dwCenterID, tInfo.szGlobalID)
        end
    })

    local tbPlayerCard = {
        dwMiniAvatarID = tInfo["dwMiniAvatarID"],
        nRoleType = tInfo["nRoleType"],
        nForceID = tInfo["nForceID"],
        nLevel = tInfo["nLevel"],
        szName = tInfo["szName"],
        nCamp = tInfo["nCamp"],
    }

    local prefabID = PREFAB_ID.WidgetPlayerPop
    local tips, _ = TipsHelper.ShowNodeHoverTips(prefabID, self.WidgetHead, nil, tbAllMenuConfig, tbPlayerCard)
end

return UITeamRecruitAppliedPlayerListItem