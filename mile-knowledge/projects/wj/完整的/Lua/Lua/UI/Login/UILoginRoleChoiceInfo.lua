-- ---------------------------------------------------------------------------------
-- Author: Unknown
-- Name: UILoginRoleChoiceInfo
-- Date: 2022-11-25 10:04:54
-- Desc: ?
-- ---------------------------------------------------------------------------------

local SHITU_IMAGE = {
    "UIAtlas2_Login_login1_QinChuanShiFu.png",
    "UIAtlas2_Login_login1_QinChuanTuDi.png",
}

local DOUBLE_CLICK_INTERVAL = 500--毫秒

local UILoginRoleChoiceInfo = class("UILoginRoleChoiceInfo")

function UILoginRoleChoiceInfo:OnEnter(tbRoleInfo, scriptRoleChoice, toggleGroup)
    if not self.bInit then
        self:RegEvent()
        self:BindUIEvent()
        self.bInit = true
    end
    self.tbRoleInfo = tbRoleInfo
    self.scriptRoleChoice = scriptRoleChoice
    self.toggleGroup = toggleGroup
    self:UpdateInfo()
end

function UILoginRoleChoiceInfo:OnExit()
    self.bInit = false
    self:UnRegEvent()
end

function UILoginRoleChoiceInfo:BindUIEvent()
    UIHelper.BindUIEvent(self.BtnEditName, EventType.OnClick, function()
        UIMgr.Open(VIEW_ID.PanelInputName, true, nil, self.tbRoleInfo.RoleName, self.tbRoleInfo.nRenameChanceCount)
    end)

    UIHelper.BindUIEvent(self.TogSlect, EventType.OnClick, function()
        if not self.nClickTime then
            self:OnClick()
        else
            local nTime = Timer.RealMStimeSinceStartup()
            local nInterval = nTime - self.nClickTime
            if nInterval <= DOUBLE_CLICK_INTERVAL then
                self:OnDoubleClick()
            else
                self:OnClick()
            end
        end
        self.nClickTime = Timer.RealMStimeSinceStartup()
    end)
end

function UILoginRoleChoiceInfo:RegEvent()
    --Event.Reg(self, EventType.XXX, func)
end

function UILoginRoleChoiceInfo:UnRegEvent()
    --Event.UnReg(self, EventType.XXX)
end



function UILoginRoleChoiceInfo:OnClick()
    self.scriptRoleChoice:SetCurRoleIndex(self.tbRoleInfo.nIndex)
end

function UILoginRoleChoiceInfo:OnDoubleClick()
    self.scriptRoleChoice:EnterGame()
end


-- ----------------------------------------------------------
-- Please write your own code below  ↓↓↓
-- ----------------------------------------------------------

function UILoginRoleChoiceInfo:UpdateInfo()

    if not self.tbRoleInfo then
        UIHelper.SetVisible(self.WidgetTogSlect, false)
        return
    end

    local szRoleName = self.tbRoleInfo.RoleName
    local nRoleLevel = self.tbRoleInfo.RoleLevel
    local dwMapID = self.tbRoleInfo.dwMapID
    local szMapName = Table_GetMapName(dwMapID)
    local dwForceID = self.tbRoleInfo.dwForceID
    local nCamp = self.tbRoleInfo.nCamp
    local nDeleteTime = self.tbRoleInfo.nDeleteTime
    local nRenameChanceCount = self.tbRoleInfo.nRenameChanceCount
    local tbDeleteTime = TimeToDate(nDeleteTime)
    local szDeleteTime = string.format("%d/%02d/%02d %02d:%02d:%02d",
    tbDeleteTime["year"], tbDeleteTime["month"], tbDeleteTime["day"], tbDeleteTime["hour"], tbDeleteTime["minute"], tbDeleteTime["second"])

    UIHelper.SetString(self.LabelNickname01, UIHelper.GBKToUTF8(szRoleName), 7)
    UIHelper.SetString(self.LabelGrade, UIHelper.GBKToUTF8(nRoleLevel).."级")
    UIHelper.SetString(self.LabelGrade_copy, UIHelper.GBKToUTF8(nRoleLevel).."级")
    UIHelper.SetString(self.LabelNickname02, UIHelper.GBKToUTF8(szRoleName), 7)
    UIHelper.SetString(self.LabelLocation, UIHelper.GBKToUTF8(szMapName), 6)
    UIHelper.SetString(self.LabelLocation_copy, UIHelper.GBKToUTF8(szMapName), 6)
    UIHelper.SetVisible(self.WidgetDelete, nDeleteTime ~= 0)
    UIHelper.SetVisible(self.BtnEditName, nRenameChanceCount > 0)
    UIHelper.SetString(self.LabelDeleteTimeNum, szDeleteTime)

    local szCampImage = ""
    if nCamp == CAMP.GOOD then
        szCampImage = "UIAtlas2_Login_login1_HQM.png"
    elseif nCamp == CAMP.EVIL then
        szCampImage = "UIAtlas2_Login_login1_ERG.png"
    end
    --阵营图标
    -- CampData.SetUICampImg(self.ImgCamp, nCamp)
    UIHelper.SetVisible(self.ImgCamp, szCampImage ~= "")
    if szCampImage ~= "" then
        UIHelper.SetSpriteFrame(self.ImgCamp, szCampImage)
    end

    UIHelper.SetSpriteFrame(self.ImgSect, PlayerForceID2SchoolImg[dwForceID] or "UIAtlas2_Public_PublicSchool_PublicSchool_iocn_school_DaXia.png")
    UIHelper.SetSpriteFrame(self.ImgSchoolSelected, PlayerForceID2SchoolImg2[dwForceID] or "UIAtlas2_Public_PublicSchool_PublicSchool_iocn_school_DaXia.png")
    UIHelper.LayoutDoLayout(self._rootNode)

    UIHelper.ToggleGroupAddToggle(self.toggleGroup, self.TogSlect)


    --试玩账号
    -- local bTestAccount = not (IsVersionTW() or (Login_GetZoneChargeFlag() and Login_GetChargeFlag()))
    -- UIHelper.SetVisible(self.WidgetTestAccount, bTestAccount)
    UIHelper.SetVisible(self.WidgetTestAccount, false)

    UIHelper.SetClickInterval(self.TogSlect, 0)

    local bIsDirectMentor = self.tbRoleInfo.bIsDirectMentor
    local bIsDirectApprentice = self.tbRoleInfo.bIsDirectApprentice
    UIHelper.SetVisible(self.ImgShiTu, bIsDirectMentor or bIsDirectApprentice)

    if bIsDirectMentor then
        UIHelper.SetSpriteFrame(self.ImgShiTu, SHITU_IMAGE[1])
    elseif bIsDirectApprentice then
        UIHelper.SetSpriteFrame(self.ImgShiTu, SHITU_IMAGE[2])
    end

    local byFreezeType = self.tbRoleInfo.byFreezeType or 0
    UIHelper.SetVisible(self.WidgetFrozenAccount, byFreezeType > 0)
end

function UILoginRoleChoiceInfo:SetSelect(bSelect)
    if bSelect then
        UIHelper.SetToggleGroupSelectedToggle(self.toggleGroup, self.TogSlect)
    end
end



return UILoginRoleChoiceInfo