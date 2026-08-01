-- ---------------------------------------------------------------------------------
-- Author: Unknown
-- Name: UIXiaoChengWu
-- Date: 2024-04-22 13:29:05
-- Desc: ?
-- ---------------------------------------------------------------------------------

local UIXiaoChengWu = class("UIXiaoChengWu")

local UPGRADE_CD_BUFF = 28375
local REMOTE_BATTLEPASS = 1072
local XCWStone_TO_Gold = 4

local tRepresentSubToIndex =
{
    [EQUIPMENT_REPRESENT.HELM_STYLE] = 13,
    [EQUIPMENT_REPRESENT.CHEST_STYLE] = 14,
    [EQUIPMENT_REPRESENT.BANGLE_STYLE] = 16,
    [EQUIPMENT_REPRESENT.WAIST_STYLE] = 15,
    [EQUIPMENT_REPRESENT.BOOTS_STYLE] = 17,
    [EQUIPMENT_REPRESENT.WEAPON_STYLE] = 12,
    [EQUIPMENT_REPRESENT.BIG_SWORD_STYLE] = 18,
    [EQUIPMENT_REPRESENT.L_SHOULDER_EXTEND] = 1,
    [EQUIPMENT_REPRESENT.R_SHOULDER_EXTEND] = 2,
    [EQUIPMENT_REPRESENT.FACE_EXTEND] = 3,
    [EQUIPMENT_REPRESENT.L_GLOVE_EXTEND] = 4,
    [EQUIPMENT_REPRESENT.R_GLOVE_EXTEND] = 5,
    [EQUIPMENT_REPRESENT.GLASSES_EXTEND] = 6,
    [EQUIPMENT_REPRESENT.BACK_CLOAK_EXTEND] = 7,
    [EQUIPMENT_REPRESENT.PENDENT_PET_STYLE] = 8,
    [EQUIPMENT_REPRESENT.BAG_EXTEND] = 9,
    [EQUIPMENT_REPRESENT.BACK_EXTEND] = 10,
    [EQUIPMENT_REPRESENT.WAIST_EXTEND] = 11
}

local richImg120 = "<img src='UIAtlas2_Public_PublicMoney_PublicMoney_Small_img_Fushi' width='36' height='36'/>"
local richImg130 = "<img src='UIAtlas2_Public_PublicMoney_PublicMoney_Small_img_YuLingCuiShi' width='36' height='36'/>"
local richImgCoin = "<img src='UIAtlas2_Public_PublicMoney_PublicMoney_Small_img_Jin' width='36' height='36'/>"
local nTabType = 5
local nTabIndex = HuaELouData.WEEK_CHIPS_ITEM_INDEX

function UIXiaoChengWu:OnEnter(nLevel)
    if not self.bInit then
        self:RegEvent()
        self:BindUIEvent()
        self.bInit = true
    end

    for k, v in ipairs(self.tbTogXinFa) do
        UIHelper.SetEnable(v, false)
    end

    self:InitDate(nLevel)
    self:InitViewInfo()
    self:UpdateAni()
end

function UIXiaoChengWu:OnExit()
    self.bInit = false
    self:UnRegEvent()
    Timer.DelAllTimer(self)
    UIHelper.StopAllAni(self)
end

function UIXiaoChengWu:BindUIEvent()
    for k, v in ipairs(self.tbTogXinFa) do
        UIHelper.BindUIEvent(v, EventType.OnClick, function ()
            local nIndex = k
            --单心法解锁流派 第二个会隐藏起来 列表里是第二个 预制里用的是第三个
            if k == 3 then
                if self.nXinFaCount == 1 then
                    nIndex = 2
                elseif self.nXinFaCount == 0 then
                    nIndex = 1
                end
            end

            self.dwSelectMKungFuID = self.tKungFuList[nIndex][1]
            self.nSelectStage = 0
            self:UpdateInfo()
        end)
    end

    UIHelper.BindUIEvent(self.TogCangJian, EventType.OnClick, function ()
        self.dwSelectMKungFuID = self.tKungFuList[1][1]
        self.nSelectStage = 0
        self:UpdateInfo()
    end)

    UIHelper.BindUIEvent(self.BtnObtain, EventType.OnClick, function ()
        local bNeed = self:CheckChangeKungFu()
        if not bNeed then
            RemoteCallToServer("On_UpXCW_GetWeapon", self.nSelectLevel)
        end
    end)

    UIHelper.BindUIEvent(self.BtnFind, EventType.OnClick, function ()
        local bNeed = self:CheckChangeKungFu(false,true)
        if bNeed then
            return
        end

        local nStage = self:GetStage()
        local tWeaponList = self:GetCurWeaponByStage(nStage)
        local tWeaponInfo = tWeaponList and tWeaponList[1] or nil

        if not tWeaponInfo then
            return
        end

        if BankLock.CheckHaveLocked(SAFE_LOCK_EFFECT_TYPE.TRADE) then
            return
        end

        RemoteCallToServer("On_UpXCW_RecoverWeapon", self.nSelectLevel, tWeaponInfo.dwWeaponIndex, nStage)
    end)

    UIHelper.BindUIEvent(self.BtnUpgrade, EventType.OnClick, function ()
        local hPlayer = g_pClientPlayer
        if not hPlayer then
            return
        end

        if Buff_Have(hPlayer, UPGRADE_CD_BUFF) then
            TipsHelper.ShowNormalTip(g_tStrings.STR_HAVE_CD)
            return
        end

        local bNeed = self:CheckChangeKungFu(true)
        if bNeed then
            return
        end

        local nStage = self:GetStage()
        local tWeaponList = self:GetCurWeaponByStage(nStage)
        local tWeaponInfo = tWeaponList and tWeaponList[1] or nil
        if not tWeaponInfo then
            return
        end

        if BankLock.CheckHaveLocked(SAFE_LOCK_EFFECT_TYPE.TRADE) then
            return
        end

        RemoteCallToServer("On_UpXCW_UpgradeWeapon", self.nSelectLevel, tWeaponInfo.dwWeaponIndex)
    end)

    UIHelper.BindUIEvent(self.BtnJianFuUpgrade, EventType.OnClick, function ()
        local hPlayer = g_pClientPlayer
        if not hPlayer then
            return
        end

        if Buff_Have(hPlayer, UPGRADE_CD_BUFF) then
            TipsHelper.ShowNormalTip(g_tStrings.STR_HAVE_CD)
            return
        end

        local bNeed = self:CheckChangeKungFu(true)
        if bNeed then
            return
        end

        local nStage = self:GetStage()
        local tWeaponList = self:GetCurWeaponByStage(nStage)
        local tWeaponInfo = tWeaponList and tWeaponList[1] or nil
        if not tWeaponInfo then
            return
        end

        if BankLock.CheckHaveLocked(SAFE_LOCK_EFFECT_TYPE.TRADE) then
            return
        end

        RemoteCallToServer("On_UpXCW_CheaperUpgrade", self.nSelectLevel, tWeaponInfo.dwWeaponIndex)
    end)

    UIHelper.BindUIEvent(self.TogLevelList, EventType.OnSelectChanged, function (_, bSelected)
        if bSelected then
            self:UpdateSelectLevelMenu()
        end
    end)

    UIHelper.BindUIEvent(self.tbTryOn01[1], EventType.OnClick, function ()
        local tWeaponList  = self:GetCurWeaponByStage(self.nSelectStage)
        local tWeaponInfo  = tWeaponList and tWeaponList[1] or {}
        local tItemInfo    = GetItemInfo(ITEM_TABLE_TYPE.CUST_WEAPON, tWeaponInfo.dwWeaponIndex)
        self:TryOnWeponItem(tItemInfo, ITEM_TABLE_TYPE.CUST_WEAPON, tWeaponInfo.dwWeaponIndex)
    end)

    UIHelper.BindUIEvent(self.tbTryOn02[1], EventType.OnClick, function ()
        local tWeaponList  = self:GetCurWeaponByStage(self.nSelectStage)
        local tWeaponInfo = tWeaponList and tWeaponList[2] or {}
        local tItemInfo    = GetItemInfo(ITEM_TABLE_TYPE.CUST_WEAPON, tWeaponInfo.dwWeaponIndex)
        self:TryOnWeponItem(tItemInfo, ITEM_TABLE_TYPE.CUST_WEAPON, tWeaponInfo.dwWeaponIndex)
    end)

    UIHelper.BindUIEvent(self.tbTryOn01[2], EventType.OnClick, function ()
        local nCurStage, nMaxStage, bLock = self:GetStage()
        local tWeaponList  = self:GetCurWeaponByStage(nMaxStage)
        local tWeaponInfo  = tWeaponList and tWeaponList[1] or {}
        local tItemInfo    = GetItemInfo(ITEM_TABLE_TYPE.CUST_WEAPON, tWeaponInfo.dwWeaponIndex)
        self:TryOnWeponItem(tItemInfo, ITEM_TABLE_TYPE.CUST_WEAPON, tWeaponInfo.dwWeaponIndex)
    end)

    UIHelper.BindUIEvent(self.tbTryOn02[2], EventType.OnClick, function ()
        local nCurStage, nMaxStage, bLock = self:GetStage()
        local tWeaponList  = self:GetCurWeaponByStage(nMaxStage)
        local tWeaponInfo  = tWeaponList and tWeaponList[2] or {}
        local tItemInfo    = GetItemInfo(ITEM_TABLE_TYPE.CUST_WEAPON, tWeaponInfo.dwWeaponIndex)
        self:TryOnWeponItem(tItemInfo, ITEM_TABLE_TYPE.CUST_WEAPON, tWeaponInfo.dwWeaponIndex)
    end)

    UIHelper.BindUIEvent(self.BtnTryOn_01, EventType.OnClick, function ()
        local tWeaponList  = self:GetCurWeaponByStage(self.nSelectStage)
        local tWeaponInfo  = tWeaponList and tWeaponList[1] or {}
        local tItemInfo    = GetItemInfo(ITEM_TABLE_TYPE.CUST_WEAPON, tWeaponInfo.dwWeaponIndex)
        self:TryOnWeponItem(tItemInfo, ITEM_TABLE_TYPE.CUST_WEAPON, tWeaponInfo.dwWeaponIndex)
    end)

    UIHelper.BindUIEvent(self.BtnTryOn_02, EventType.OnClick, function ()
        local tWeaponList  = self:GetCurWeaponByStage(self.nSelectStage)
        local tWeaponInfo = tWeaponList and tWeaponList[2] or {}
        local tItemInfo    = GetItemInfo(ITEM_TABLE_TYPE.CUST_WEAPON, tWeaponInfo.dwWeaponIndex)
        self:TryOnWeponItem(tItemInfo, ITEM_TABLE_TYPE.CUST_WEAPON, tWeaponInfo.dwWeaponIndex)
    end)

    UIHelper.BindUIEvent(self.WidgetProgressFinalFinal, EventType.OnClick, function ()
        local nCurStage, nMaxStage, bLock = self:GetStage()
        self.nSelectStage = nMaxStage
        self:SetSelectStage(self.nSelectStage)
    end)

    UIHelper.BindUIEvent(self.WidgetProgressFinal, EventType.OnClick, function ()
        local nCurStage, nMaxStage, bLock = self:GetStage()
        self:SetSelectStage(nMaxStage)
    end)

    UIHelper.BindUIEvent(self.LayoutCoin, EventType.OnClick, function ()
        TipsHelper.ShowItemTips(self.LayoutCoin, nTabType, nTabIndex, false, TipsLayoutDir.AUTO)
    end)
    UIHelper.SetTouchEnabled(self.LayoutCoin , true)

    UIHelper.BindUIEvent(self.BtnAdd, EventType.OnClick, function ()
        UIMgr.Close(VIEW_ID.PanelShenBingUpgrade)
        if not UIMgr.GetView(VIEW_ID.PanelBenefits) then
            UIMgr.Open(VIEW_ID.PanelBenefits, 2, true)
        end
    end)

    UIHelper.BindUIEvent(self.BtnRule, EventType.OnClick, function ()
        TipsHelper.ShowNodeHoverTipsInDir(PREFAB_ID.WidgetPublicLabelTips, self.BtnRule, TipsLayoutDir.BOTTOM_CENTER, g_tStrings.STR_SHENBING_TIPS)
    end)
end

function UIXiaoChengWu:RegEvent()
    --Event.Reg(self, EventType.XXX, func)
    Event.Reg(self, "On_Upgrade_OrangeWeapon", function ()
        local nCurStage, nMaxStage, bLock = self:GetStage()
        self.nSelectStage = nCurStage

        self:UpdateInfo()
    end)

    Event.Reg(self, "QUEST_FINISHED", function ()
        self:UpdateInfo()
    end)

    Event.Reg(self, "SET_QUEST_STATE", function ()
        self:UpdateInfo()
    end)

    Event.Reg(self, "BAG_ITEM_UPDATE", function ()
        self:UpdateCostStone()
        self:UpdateProgressBar()
    end)

    Event.Reg(self, "REMOTE_BATTLEPASS", function ()
        self:UpdateGrindstoneOnHDDL()
        self:UpdateCostStone()
    end)

    Event.Reg(self, "ON_SYNC_SET_COLLECTION", function ()
        self:UpdateGrindstoneOnHDDL()
        self:UpdateCostStone()
    end)

    Event.Reg(self, EventType.OnViewClose, function(nViewID)
        if nViewID == VIEW_ID.PanelSkillNew then
            self:InitDate()
            self:InitViewInfo()
            self:UpdateSelectLevelMenu()
        end
    end)
end

function UIXiaoChengWu:UnRegEvent()
    --Event.UnReg(self, EventType.XXX)
end






-- ----------------------------------------------------------
-- Please write your own code below  ↓↓↓
-- ----------------------------------------------------------
local function IsQuestFinished(dwQuestID)
    local nQuestState = g_pClientPlayer.GetQuestPhase(dwQuestID)
    return nQuestState == QUEST_PHASE.FINISH
end

function UIXiaoChengWu:InitDate(nLevel)
    self.dwForceID         = g_pClientPlayer.dwForceID
    self.dwSelectMKungFuID = g_pClientPlayer.GetActualKungfuMountID()
    self.nSelectLevel      = nLevel or ShenBingUpgradeMgr.DEFAULT_LEVEL
    self:GetAllWeaponList()
    self:ParseInfo()
    self.nWeekChipsNow     = g_pClientPlayer.GetRemoteArrayUInt(REMOTE_BATTLEPASS, 10, 2)
    self.nSelectStage = 0

    --目前在神兵界面不能切换心法 所以初始化一次
    self:ResetSkillData()
end

function UIXiaoChengWu:GetAllWeaponList()
    self.tAllWeaponList = Table_GetOrangeWeaponInfoByForceID(g_pClientPlayer.dwForceID)
    local OtherWeaponList = Table_GetOrangeWeaponInfoByForceID(0)

    for i = 1, #OtherWeaponList do
        table.insert(self.tAllWeaponList, OtherWeaponList[i])
    end
end

function UIXiaoChengWu:ParseInfo()
    local tState = {}
    local tLevel = {}
    local bHasLevel = false

    for _, v in pairs(self.tAllWeaponList) do
        if not tState[v.nLevel] then
            tState[v.nLevel] = true
            table.insert(tLevel, {nLevel = v.nLevel, dwItemIndex = v.dwItemIndex})
        end

        if v.nLevel == self.nSelectLevel then
            bHasLevel = true
        end
    end

    table.sort(tLevel, function (a, b)
        return a.nLevel < b.nLevel
    end)

    self.tLevelList = tLevel
    self.nSelectLevel = bHasLevel and self.nSelectLevel or ShenBingUpgradeMgr.DEFAULT_LEVEL
end

function UIXiaoChengWu:InitViewInfo()
    self:UpdateGrindstoneOnHDDL()
    self:UpdateKungFuInfo()
    self:UpdateProgressBar()
    self:UpdateSelectLevel()
    self:UpdateEmptyState()
end

function UIXiaoChengWu:UpdateInfo()
    self:UpdateGrindstoneOnHDDL()
    self:UpdateProgressBar()
    self:UpdateSelectLevel()
    self:UpdateEmptyState()
end

function UIXiaoChengWu:UpdateAni()
    local nCurStage, nMaxStage, bLock = self:GetStage()

    local szClipName = ""
    if nCurStage == nMaxStage then
        szClipName = "AniXiaoChengWuIn03"
    else
        szClipName = "AniXiaoChengWuIn02"
    end

    UIHelper.PlayAni(self, self.AniAll, szClipName, function ()
        for k, v in ipairs(self.tbTogXinFa) do
            UIHelper.SetEnable(v, true)
        end
    end)
end

function UIXiaoChengWu:UpdateGrindstoneOnHDDL()
    local REMOTE_BATTLEPASS = 1072
    local nWeekChipsNow = g_pClientPlayer.GetRemoteArrayUInt(REMOTE_BATTLEPASS, 10, 2)
    UIHelper.SetString(self.LabelFuShi, nWeekChipsNow .."/" .. HuaELouData.WEEK_CHIPS_LIMIT)

    local nExtPoint = GDAPI_GetXCWStone_EXTByLevel(self.nSelectLevel)
    local nUnlockLevelA
    if nExtPoint then
        nUnlockLevelA = g_pClientPlayer.GetExtPoint(nExtPoint)
        UIHelper.SetString(self.LabslUnlockLevelA, nUnlockLevelA)
    end
    local tRoleData = GDAPI_GetXCWStone_RoleByLevel(self.nSelectLevel)
    if nExtPoint then
        local nUnlockLevelC = g_pClientPlayer.GetRemoteArrayUInt(tRoleData[1], tRoleData[2], tRoleData[3])
        UIHelper.SetString(self.LabslUnlockLevelC, nUnlockLevelC)
    end
    local tLevelLimit = GDAPI_GetStageLimitByLevel(self.nSelectLevel)
    local nCurStage = self:GetCurWeapon()
    local nTimeLimit = nCurStage
    if tLevelLimit then
        self.nUpgradeStage = nCurStage
        for i = nCurStage + 1, 6 do
            if tLevelLimit[i] and tLevelLimit[i].tTime then
                local tTimeMess = tLevelLimit[i].tTime
                if GetCurrentTime() >= DateToTime(tTimeMess[1], tTimeMess[2], tTimeMess[3], tTimeMess[4], tTimeMess[5], tTimeMess[6]) then
                    nTimeLimit = i
                end
                self.nUpgradeStage = nUnlockLevelA >= tLevelLimit[i].nXCWStone and i or self.nUpgradeStage
            end
        end
        local nUpgradeStage
        self.nStateLimit = tLevelLimit.nMaxStage
        nUpgradeStage = math.min(self.nUpgradeStage, self.nStateLimit)
        nUpgradeStage = math.min(nUpgradeStage, nTimeLimit)

        if nUpgradeStage == nCurStage and self.nUpgradeStage > nCurStage and self.nUpgradeStage > nCurStage then
            nUpgradeStage = nUpgradeStage + 1
        end
        self.nUpgradeStage = nUpgradeStage

        if self.nUpgradeStage == 1 then
            self.nUpgradeStone = 0
        elseif nCurStage == 1 then
            self.nUpgradeStone = tLevelLimit[self.nUpgradeStage].nXCWStone
        else
            self.nUpgradeStone = tLevelLimit[self.nUpgradeStage].nXCWStone - tLevelLimit[nCurStage].nXCWStone
        end
    end
end

function UIXiaoChengWu:ResetSkillData()
    self.bHD = TabHelper.IsHDKungfuID(self.dwSelectMKungFuID)
    self.tKungFuList = SkillData.GetKungFuList_Sorted(self.bHD) or {}
end

function UIXiaoChengWu:UpdateKungFuInfo()
    local bHasDivided = false
    self.nXinFaCount = 0
    local nNoneSchoolXinFaCount = 0;
    local dwCurID = g_pClientPlayer.GetActualKungfuMountID()
    local bNoneSchoolKungfu = IsNoneSchoolKungfu(dwCurID)

    for k, v in ipairs(self.tKungFuList) do
        local nSkillID = v[1]
        local tSkillInfo, skillName1
        local bHD = TabHelper.IsHDKungfuID(dwCurID)
        if not bHD then
                tSkillInfo = TabHelper.GetUISkill(nSkillID)
                skillName1 = tSkillInfo.szName
        else
            local nSkillLevel = g_pClientPlayer.GetSkillLevel(nSkillID)
            if not nSkillLevel or nSkillLevel == 0 then
                nSkillLevel = 1
            end
            skillName1 = UIHelper.GBKToUTF8(Table_GetSkillName(nSkillID, nSkillLevel))
        end

        local szIconPath = PlayerKungfuImg[nSkillID]

        if IsNoneSchoolKungfu(nSkillID) then
            nNoneSchoolXinFaCount = nNoneSchoolXinFaCount + 1
            if not bHasDivided then
                if not bNoneSchoolKungfu or dwCurID == nSkillID then
                    bHasDivided = true
                    for i, _ in ipairs(self.tbliupaiXinfaImg) do
                        UIHelper.SetSpriteFrame(self.tbliupaiXinfaImg[i], szIconPath)
                    end
                    UIHelper.SetString(self.LiuPaiLabelNormal1, skillName1)
                    UIHelper.SetString(self.LiuPaiLabelUp1, skillName1)
                    UIHelper.SetVisible(self.ImgLineMiddle, self.nXinFaCount ~= 0)
                    UIHelper.SetVisible(self.WidgetLiuPaiXinFa, true)
                end
            end
        else
            self.nXinFaCount = self.nXinFaCount + 1
            if k == 1 then
                for i, _ in ipairs(self.tbXinfa1Img) do
                    UIHelper.SetSpriteFrame(self.tbXinfa1Img[i], szIconPath)
                    UIHelper.SetString(self.tbXinfa1Label[i], skillName1)
                end
            else
                for i, _ in ipairs(self.tbXinfa2Img) do
                    UIHelper.SetSpriteFrame(self.tbXinfa2Img[i], szIconPath)
                    UIHelper.SetString(self.tbXinfa2Label[i], skillName1)
                end
            end
        end
    end

    local bHDChangJian = self.dwForceID == FORCE_TYPE.CANG_JIAN and self.bHD

    UIHelper.SetVisible(self.TogXinFa2, self.nXinFaCount >= 2 and not bHDChangJian)
    UIHelper.SetVisible(self.TogXinFa1, self.nXinFaCount >= 1 and not bHDChangJian)
    UIHelper.SetVisible(self.ImgCurrent, self.nXinFaCount >= 1 and self.tKungFuList[1] and dwCurID == self.tKungFuList[1][1] and not bHDChangJian)
    UIHelper.SetVisible(self.ImgCurrent1, self.nXinFaCount >= 2 and self.tKungFuList[2] and dwCurID == self.tKungFuList[2][1] and not bHDChangJian)
    UIHelper.SetVisible(self.ImgCurrent2, bNoneSchoolKungfu)
    UIHelper.SetVisible(self.WidgetCangJian, bHDChangJian)
    UIHelper.SetVisible(self.ImgCurrentCangJian, bHDChangJian and (dwCurID == self.tKungFuList[1][1] or dwCurID == self.tKungFuList[2][1]))
    UIHelper.SetVisible(self.LayoutSchoolXinFa, self.nXinFaCount ~= 0)

    Timer.AddFrame(self, 1, function ()
        UIHelper.LayoutDoLayout(self.LayoutSchoolXinFa)
        UIHelper.LayoutDoLayout(self.LayoutMiddle)
        UIHelper.LayoutDoLayout(self.WidgetAnchorTopNew)
    end)

    if dwCurID == self.dwSelectMKungFuID then
        Timer.AddFrame(self, 1, function ()
            if dwCurID == self.tKungFuList[1][1] then
                if bHDChangJian then
                    UIHelper.SetSelected(self.TogCangJian, true)
                else
                    UIHelper.SetSelected(self.TogXinFa1, true)
                end
            elseif self.nXinFaCount >= 2 and self.tKungFuList[2] and dwCurID == self.tKungFuList[2][1] then
                if bHDChangJian then
                    UIHelper.SetSelected(self.TogCangJian, true)
                else
                    UIHelper.SetSelected(self.TogXinFa2, true)
                end
            else
                UIHelper.SetSelected(self.TogLiuPaiXinFa, bNoneSchoolKungfu)
                -- self.nSelectStage = 0
                -- self:UpdateInfo()
            end
        end)
    end
end

function UIXiaoChengWu:UpdateProgressBar()
    local nCurStage, nMaxStage, bLock = self:GetStage()
    if self.nSelectStage == 0 then
        self.nSelectStage = nCurStage
    end

    local _, tWeaponList, bLock = self:GetCurWeapon()

    local bHasObtain = false
    local bShowFind  = false

    for _, v in pairs(tWeaponList) do
        local dwItemIndex = v.dwWeaponIndex
        local bFinish = IsQuestFinished(v.dwQuestID)
        local bExist = self:IsWeaponExist(dwItemIndex)
        bHasObtain = bHasObtain or bFinish
        if bFinish and not bExist then
            bShowFind = true
            break
        end
    end

    UIHelper.RemoveAllChildren(self.LayoutProgressNormal)
    self.tProgressCell = {}

    for i = 1, nMaxStage - 1 do
        local tProgressCell = UIHelper.AddPrefab(PREFAB_ID.WidgetXiaoChengWuProgressCell, self.LayoutProgressNormal, i)
        if tProgressCell then
            if self.nSelectStage == i then
                UIHelper.SetSelected(tProgressCell.WidgetXiaoChengWuProgressCell, true)
            end

            UIHelper.SetVisible(tProgressCell.ImgBarReached, nCurStage >= i and bHasObtain)
            UIHelper.SetVisible(tProgressCell.WidgetStatusFinal, nCurStage == i and bHasObtain)
            UIHelper.SetVisible(tProgressCell.WidgetStatusFinalWeapon, nCurStage == i and (not bHasObtain))
            UIHelper.BindUIEvent(tProgressCell.WidgetXiaoChengWuProgressCell, EventType.OnSelectChanged, function (_, bSelected)
                if bSelected then
                    self:SetSelectStage(i)
                end
            end)
        end

        table.insert(self.tProgressCell, tProgressCell)
    end

    UIHelper.LayoutDoLayout(self.LayoutProgressNormal)
    for _, tProgressCell in ipairs(self.tProgressCell) do
        UIHelper.CascadeDoLayoutDoWidget(tProgressCell.WidgetXiaoChengWuProgressCell, true, true)
    end
    UIHelper.LayoutDoLayout(self.LayoutProgressNormal)

    UIHelper.SetVisible(self.WidgetProgressFinal, nCurStage ~= nMaxStage)
    UIHelper.SetVisible(self.WidgetProgressFinalFinal, nCurStage == nMaxStage)
    if nCurStage == nMaxStage then
        UIHelper.SetSelected(self.WidgetProgressFinalFinal, true)
    end
    UIHelper.SetVisible(self.WidgetFinalMiddle, nCurStage == nMaxStage)
    UIHelper.SetVisible(self.WidgetNow, nCurStage ~= nMaxStage)
    UIHelper.SetVisible(self.WidgetFinal, nCurStage ~= nMaxStage)
    UIHelper.SetVisible(self.WidgetAniBg1, nCurStage ~= nMaxStage)

    self:SetSelectStage(self.nSelectStage)
end

function UIXiaoChengWu:SetSelectStage(nIndex)
    self.nSelectStage = nIndex
    self:UpdateKungFuXiaoChengWu()
    self:UpdateCostStone()
end

function UIXiaoChengWu:UpdateKungFuXiaoChengWu()
    local nCurStage, nMaxStage, bLock = self:GetStage()
    local tWeaponList  = self:GetCurWeaponByStage(self.nSelectStage)

    local tWeaponInfo  = tWeaponList and tWeaponList[1] or {}
    local tWeaponInfo1 = tWeaponList and tWeaponList[2] or {}
    local szStage      = FormatString(g_tStrings.STR_WEAPON_UPGRADE_CURSTAGE, g_tStrings.STR_NUMBER[self.nSelectStage])
    local tItemInfo    = GetItemInfo(ITEM_TABLE_TYPE.CUST_WEAPON, tWeaponInfo.dwWeaponIndex)


    for k, v in ipairs(self.tblayoutWeapon02) do
        UIHelper.SetVisible(self.tblayoutWeapon02[k], self.dwForceID == FORCE_TYPE.CANG_JIAN and (not IsNoneSchoolKungfu(self.dwSelectMKungFuID)))
    end
    if self.dwForceID == FORCE_TYPE.CANG_JIAN and (not IsNoneSchoolKungfu(self.dwSelectMKungFuID)) then
        local tItemInfo1 = GetItemInfo(ITEM_TABLE_TYPE.CUST_WEAPON, tWeaponInfo1.dwWeaponIndex)
        for k, v in ipairs(self.tblayoutWeaponName02) do
            UIHelper.SetString(self.tblayoutWeaponName02[k], UIHelper.GBKToUTF8(tItemInfo1.szName))
        end

        if nCurStage == nMaxStage then
            self:SetWeponItem(self.WidgetItem60_2, tWeaponInfo1.dwWeaponIndex)
        else
            self:SetWeponItem(self.tbwidgetitem02[1], tWeaponInfo1.dwWeaponIndex)
        end
    end

    for k, v in ipairs(self.tblayoutWeaponName01) do
        if tItemInfo then
            UIHelper.SetString(self.tblayoutWeaponName01[k], UIHelper.GBKToUTF8(tItemInfo.szName))
        end
    end

    if nCurStage == nMaxStage then
        self:SetWeponItem(self.WidgetItem60_1, tWeaponInfo.dwWeaponIndex)
        UIHelper.SetTexture(self.ImgWeapenFinalFinal, tWeaponInfo.szMoblieImagePath)
    else

        UIHelper.SetTexture(self.ImgWeapenNow, tWeaponInfo.szMoblieImagePath)
        self:SetWeponItem(self.tbwidgetitem01[1], tWeaponInfo.dwWeaponIndex)

        tWeaponList = self:GetCurWeaponByStage(nMaxStage)
        tWeaponInfo = tWeaponList and tWeaponList[1] or {}
        tWeaponInfo1 = tWeaponList and tWeaponList[2] or {}
        UIHelper.SetTexture(self.ImgWeapenFinal, tWeaponInfo.szMoblieImagePath)

        self:SetWeponItem(self.tbwidgetitem01[2], tWeaponInfo.dwWeaponIndex)
        self:SetWeponItem(self.tbwidgetitem02[2], tWeaponInfo1.dwWeaponIndex)

        -- if nCurStage == self.nSelectStage then
        --     szStage = szStage .. " (当前)"
        -- end
        UIHelper.SetString(self.LabelPhase, szStage)
    end
end

function UIXiaoChengWu:SetWeponItem(widgetitem, dwWeaponIndex, hItemInfo)
    local scriptItem = UIHelper.AddPrefab(PREFAB_ID.WidgetItem_60, widgetitem)
    if scriptItem then
        scriptItem:OnInitWithTabID(ITEM_TABLE_TYPE.CUST_WEAPON, dwWeaponIndex)
        scriptItem:SetClickCallback(function ()
            if UIHelper.GetSelected(scriptItem.ToggleSelect) then
                UIHelper.SetSelected(scriptItem.ToggleSelect, false)
            end
            TipsHelper.ShowItemTips(nil, ITEM_TABLE_TYPE.CUST_WEAPON, dwWeaponIndex)
        end)
    end
end

function UIXiaoChengWu:TryOnWeponItem(hItemInfo, dwTabType, dwIndex)
    local tbOtherPlayerOutFit = {}
    local dwWeaponID = CoinShop_GetWeaponIDByItemInfo(hItemInfo)
    local nRepresentSub = ExteriorView_GetRepresentSub(hItemInfo.nSub, hItemInfo.nDetail)
    local nIndex = tRepresentSubToIndex[nRepresentSub]
    table.insert(tbOtherPlayerOutFit ,nIndex, {["nType"] = OutFitPreviewData.PreviewType.EquipWeapon, ["nTabType"] = dwTabType, ["dwIndex"] = dwIndex})
    Event.Dispatch("ON_HIDEMINISCENE_UNTILNEWVIEWCLOSE")
    UIMgr.Open(VIEW_ID.PanelOutfitPreview, nil, tbOtherPlayerOutFit)
end

function UIXiaoChengWu:UpdateCostStone()
    local dwIndex     = self:GetUpgradeIndex()
    local nCost       = self:GetUpgradeCost()
    local _, nMaxStage, _ = self:GetStage()
    local nSelStage = self.nSelectStage

    local nCount = g_pClientPlayer.GetItemAmountInAllPackages(ITEM_TABLE_TYPE.OTHER, dwIndex)
    local nCurStage, tWeaponList, bLock = self:GetCurWeapon()

    local bHasObtain = false
    local bShowFind  = false
    local dwQuestID;

    for _, v in pairs(tWeaponList) do
        local dwItemIndex = v.dwWeaponIndex
        local bFinish = IsQuestFinished(v.dwQuestID)
        local bExist = self:IsWeaponExist(dwItemIndex)
        dwQuestID = v.dwQuestID
        bHasObtain = bHasObtain or bFinish
        if bFinish and not bExist then
            bShowFind = true
        end
    end

    UIHelper.SetVisible(self.BtnObtain, not bHasObtain)
    UIHelper.SetVisible(self.BtnUpgrade, not bShowFind and bHasObtain)
    self.bUpgrade = not bShowFind and bHasObtain
    UIHelper.SetVisible(self.WidgetBtnJianFuUpgradeAll, not bShowFind and bHasObtain and self.nSelectLevel == ShenBingUpgradeMgr.DEFAULT_LEVEL and nCurStage ~= nMaxStage)
    UIHelper.SetVisible(self.BtnFind, bShowFind and bHasObtain)
    UIHelper.SetVisible(self.WidgetCoin, bShowFind and bHasObtain)

    UIHelper.SetVisible(self.RichTextCost, not bShowFind and bHasObtain)
    local bTimeLimit, bLevelLimit = self:GetBtnUpgradeText(nCount, nCost)

    local bEnable = not bLock and nCount >= nCost and nCurStage == nSelStage and (not bLevelLimit)
    UIHelper.SetButtonState(self.BtnUpgrade, (bEnable and bTimeLimit) and BTN_STATE.Normal or BTN_STATE.Disable)
    local tbMoney = g_pClientPlayer.GetMoney()
    bEnable = not bLock and self.nUpgradeStage > nCurStage and tbMoney.nGold >= self.nUpgradeMoney and nCurStage == nSelStage and (not bLevelLimit)
    UIHelper.SetButtonState(self.BtnJianFuUpgrade, (bEnable and bTimeLimit) and BTN_STATE.Normal or BTN_STATE.Disable)

    -- if bShowFind and bHasObtain then
    --     UIHelper.SetVisible(self.WidgetHint, false)
    -- else
    --     UIHelper.SetVisible(self.WidgetHint, nCost > 0 and nCount < nCost or false)
    -- end

    if nCurStage == nMaxStage then
        UIHelper.SetVisible(self.RichTextCost, false)
        UIHelper.SetString(self.LabelSwitch, "已满级")
        UIHelper.SetButtonState(self.BtnUpgrade, BTN_STATE.Disable)
    else
        UIHelper.SetString(self.LabelSwitch, "升级神兵")
    end

    UIHelper.LayoutDoLayout(self.LayoutInfo)
    UIHelper.LayoutDoLayout(self.WidgetAnchorBottom)
end

function UIXiaoChengWu:GetBtnUpgradeText(nCount, nCost)
    local bTimeLimit = true
    local nCurStage = self:GetCurWeapon()
    local bLevelLimit = self.nSelectLevel == ShenBingUpgradeMgr.DEFAULT_LEVEL and nCurStage >= self.nStateLimit

    local tWeaponList = self:GetCurWeaponByStage(nCurStage + 1)
    if not tWeaponList or table_is_empty(tWeaponList) then
        return bTimeLimit, bLevelLimit
    end

    local dwQuestID
    for k,v in ipairs(tWeaponList) do
        dwQuestID = v.dwQuestID
    end

    local szCount
    if nCount < nCost then
        szCount = "<color=#ff7575>" .. nCount .. "</c>"
    else
        szCount = "<color=#95ff95>" .. nCount .. "</c>"
    end

    local tTimeMess, szTimeText
    if self.nSelectLevel == ShenBingUpgradeMgr.DEFAULT_LEVEL then
        local tQuestTimeLimit = GDAPI_GetQuestTimeLimitByLevel(self.nSelectLevel)
        if tQuestTimeLimit and tQuestTimeLimit[dwQuestID] then
            tTimeMess = tQuestTimeLimit[dwQuestID]
            if GetCurrentTime() < DateToTime(tTimeMess[1], tTimeMess[2], tTimeMess[3], tTimeMess[4], tTimeMess[5], tTimeMess[6]) then
                bTimeLimit = false
            end
        end

        szTimeText = FormatString(g_tStrings.STR_SHENBING_TIME_LIMIT, tTimeMess[2],tTimeMess[3],tTimeMess[4])
    end

    local richImg = richImg130
    if self.nSelectLevel == 120 then
        richImg = richImg120
    end

    UIHelper.SetRichText(self.RichTextCost, szCount .. "/" .. nCost .. richImg)
    UIHelper.SetVisible(self.LabelMaxLevel, bLevelLimit)
    UIHelper.SetString(self.LabelActivateTime, szTimeText)
    UIHelper.SetVisible(self.LabelActivateTime, not bTimeLimit and not bLevelLimit and self.bUpgrade)

    local nStone = nCount >= self.nUpgradeStone and self.nUpgradeStone or nCount
    UIHelper.SetString(self.LabelCoinFuShi, nStone)
    UIHelper.SetString(self.LabelTag, "升至"..self.nUpgradeStage.."阶段")

    self.nUpgradeMoney = nCount >= self.nUpgradeStone and 0 or (self.nUpgradeStone - nCount) * XCWStone_TO_Gold
    local szStoneText, szCoinText = "",""
    if self.nUpgradeMoney ~= 0 then
        local tbMoney = g_pClientPlayer.GetMoney()
        if tbMoney.nGold > self.nUpgradeMoney then
            szCoinText = "<color=#D7F6FF>" .. self.nUpgradeMoney .. "</c>" ..richImgCoin
        else
            szCoinText = "<color=#ff7575>" .. self.nUpgradeMoney .. "</c>" ..richImgCoin
        end
    end
    if nStone ~= 0  then
        szStoneText = "<color=#D7F6FF>" .. nStone .. "</c>" .. richImg130
    end

    UIHelper.SetRichText(self.LabelCoinJin, szStoneText..szCoinText)
    UIHelper.SetVisible(self.LabelCoinJin, szStoneText..szCoinText ~= "" and true or false)

    UIHelper.SetVisible(self.WidgetTag, self.nUpgradeStage ~= nCurStage)
    UIHelper.SetVisible(self.RichTextCostA, self.nUpgradeStage == nCurStage)
    UIHelper.LayoutDoLayout(self.LayoutCoins)
    UIHelper.LayoutDoLayout(self.LayoutInfoR)

    return bTimeLimit, bLevelLimit
end

function UIXiaoChengWu:UpdateSelectLevel()
    local nLevel = self.nSelectLevel
    UIHelper.SetString(self.LabelContent, FormatString(g_tStrings.STR_BLUEPRINT_TIP_REQUIRED_LEVEL, nLevel))
    UIHelper.SetString(self.LabelContent1, FormatString(g_tStrings.STR_BLUEPRINT_TIP_REQUIRED_LEVEL, nLevel))

    UIHelper.SetVisible(self.TogLevelList, #self.tLevelList > 0)
end

function UIXiaoChengWu:UpdateSelectLevelMenu()
    UIHelper.RemoveAllChildren(self.WidgetSimpleFilterTipShell)
    self.SimpleFilterTip = UIHelper.AddPrefab(PREFAB_ID.WidgetSimpleFilterTip, self.WidgetSimpleFilterTipShell)
    if self.SimpleFilterTip then
        UIHelper.RemoveAllChildren(self.SimpleFilterTip.LayoutListShort)

        for _, v in pairs(self.tLevelList) do
            local SimpleFilterTipCell = UIHelper.AddPrefab(PREFAB_ID.WidgetSimpleFilterTipCell, self.SimpleFilterTip.LayoutListShort)
            if SimpleFilterTipCell then
                local szText = FormatString(g_tStrings.STR_BLUEPRINT_TIP_REQUIRED_LEVEL, v.nLevel)
                UIHelper.SetString(SimpleFilterTipCell.LabelContentText, szText)
                if self.nSelectLevel == v.nLevel then
                    UIHelper.SetSelected(SimpleFilterTipCell.TogType, true)
                end

                UIHelper.BindUIEvent(SimpleFilterTipCell.TogType, EventType.OnClick, function ()
                    self.nSelectStage = 0
                    self:ChangeLevel(v.nLevel)
                    UIHelper.SetSelected(self.TogLevelList, false)
                end)
            end
        end

        UIHelper.LayoutDoLayout(self.SimpleFilterTip.LayoutListShort)
    end
end

function UIXiaoChengWu:ChangeLevel(nLevel)
    self.nSelectLevel = nLevel
    UIHelper.SetVisible(self.WidgetCoinvisit, HuaELouData.WEEK_CHIPS_LIMIT_VISIBLE and self.nSelectLevel == ShenBingUpgradeMgr.DEFAULT_LEVEL)
    UIHelper.SetVisible(self.WidgetAnchorCoinCompare, HuaELouData.WEEK_CHIPS_LIMIT_VISIBLE and self.nSelectLevel == ShenBingUpgradeMgr.DEFAULT_LEVEL)
    UIHelper.LayoutDoLayout(self.LayoutRightTopContent)
    self:UpdateInfo()
end

--当前心法当前等级的所有橙武
function UIXiaoChengWu:GetCurWeaponList()
    local nLevel = self.nSelectLevel
    local dwMKungFuID = self.dwSelectMKungFuID
    --特殊兼容一下 藏剑的山居剑意也用问水诀的心法来判断
    if dwMKungFuID == 10145 then
        dwMKungFuID = 10144
    end
    local tRes = {}
    for _, v in pairs(self.tAllWeaponList) do
        if v.dwMobileMKungFuID == dwMKungFuID and v.nLevel == nLevel then
            table.insert(tRes, v)
        end
        if v.dwMKungFuID == dwMKungFuID and v.nLevel == nLevel then
            table.insert(tRes, v)
        end
    end

    table.sort(tRes, function (a, b)
        if a.nStage ~= b.nStage then
            return a.nStage < b.nStage
        end
        return a.dwID < b.dwID
    end)

    self.tCurWeaponList = tRes
end

--当前心法当前阶段的武器列表
function UIXiaoChengWu:GetCurWeapon()
    self:GetCurWeaponList()

    local bLock       = false
    local nStage      = 0
    local tWeaponInfo = nil
    local tList       = {}
    local tCurList    = self.tCurWeaponList

    for i = 1, #tCurList do
        local tInfo = tCurList[i]
        local dwQuestID = tInfo.dwQuestID
        local bFinish = IsQuestFinished(dwQuestID)
        if bFinish then
            if nStage ~= tInfo.nStage then
                tList = {}
            end
            nStage = tInfo.nStage
            table.insert(tList, tInfo)
        end
    end

    if IsTableEmpty(tList) then
        bLock = true
        nStage = 1
        tList = self:GetCurWeaponByStage(1)
    end

    return nStage, tList, bLock
end

function UIXiaoChengWu:GetCurWeaponByStage(nStage)
    local tRes = {}
    local tCurList = self.tCurWeaponList
    for i = 1, #tCurList do
        local tInfo = tCurList[i]
        if tInfo.nStage == nStage then
            table.insert(tRes, tInfo)
        end
    end
    return tRes
end

function UIXiaoChengWu:GetStage()
    local nStage, tWeaponList, bLock = self:GetCurWeapon()
    local tWeaponInfo = tWeaponList and tWeaponList[1] or nil
    if not tWeaponInfo then
        return 0, 6, true
    end
    return tWeaponInfo.nStage, tWeaponInfo.nMaxStage, bLock
end

function UIXiaoChengWu:GetUpgradeIndex()
    local nLevel = self.nSelectLevel
    for _, v in pairs(self.tLevelList) do
        if v.nLevel == nLevel then
            return v.dwItemIndex
        end
    end
end

function UIXiaoChengWu:GetUpgradeCost()
    local _, tWeaponList = self:GetCurWeapon()
    local tWeaponInfo = tWeaponList and tWeaponList[1] or nil
    if not tWeaponInfo then
        return 0
    end
    local nCost = tWeaponInfo.nStoneCost or 0
    return nCost
end

function UIXiaoChengWu:IsWeaponExist(dwIndex)
    local nItemCount = g_pClientPlayer.GetItemAmountInAllPackages(ITEM_TABLE_TYPE.CUST_WEAPON, dwIndex)
    return nItemCount > 0
end

function UIXiaoChengWu:UpdateEmptyState()
    local bEmpty = not self.tAllWeaponList or #self.tAllWeaponList == 0
    UIHelper.SetVisible(self.WidgetAnchorEmpty, bEmpty)
    UIHelper.SetVisible(self.WidgetAnchorWeapon, not bEmpty)
    UIHelper.SetVisible(self.WidgetAniBottom, not bEmpty)
    UIHelper.SetVisible(self.LabelEmpty, bEmpty)

    if not self.tCurWeaponList or #self.tCurWeaponList == 0 then
        UIHelper.SetVisible(self.WidgetAnchorEmpty, true)
        UIHelper.SetVisible(self.WidgetAnchorWeapon, false)
        UIHelper.SetVisible(self.WidgetAniBottom, false)
        UIHelper.SetVisible(self.LabelCurEmpty, true)
    end
end

function UIXiaoChengWu:CheckChangeKungFu(bUpgrade, bFind)
    local bResult = false
    local dwCurID = g_pClientPlayer.GetActualKungfuMountID()
    local bNoneSchoolKungfu = IsNoneSchoolKungfu(self.dwSelectMKungFuID)
    if bNoneSchoolKungfu and self.dwSelectMKungFuID ~= dwCurID then
        bResult = true
    elseif (not bNoneSchoolKungfu) and IsNoneSchoolKungfu(dwCurID) then
        bResult = true
    end

    if bResult then
        local szText
        local tSkillInfo, skillName1

        local bHD = TabHelper.IsHDKungfuID(dwCurID)
        if not bHD then
            tSkillInfo = TabHelper.GetUISkill(self.dwSelectMKungFuID)
            skillName1 = tSkillInfo.szName
        else
            local nSkillLevel = g_pClientPlayer.GetSkillLevel(self.dwSelectMKungFuID)
            if not nSkillLevel or nSkillLevel == 0 then
                nSkillLevel = 1
            end
            skillName1 = UIHelper.GBKToUTF8(Table_GetSkillName(self.dwSelectMKungFuID, nSkillLevel))
        end

        if bUpgrade then
            szText = FormatString(g_tStrings.STR_SHENBING_CHANGE_UPGRADE, skillName1)
        elseif bFind then
            szText = FormatString(g_tStrings.STR_SHENBING_CHANGE_FIND, skillName1)
        else
            szText = FormatString(g_tStrings.STR_SHENBING_CHANGE_OBTAIN, skillName1)
        end

        UIHelper.ShowConfirm(szText, function ()
            UIMgr.Open(VIEW_ID.PanelSkillNew)
        end,nil,true)
    end

    return bResult
end

return UIXiaoChengWu