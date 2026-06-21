-- ---------------------------------------------------------------------------------
-- Author: Unknown
-- Name: UIHomelandBuildUpgradeView
-- Date: 2023-06-20 19:45:21
-- Desc: ?
-- ---------------------------------------------------------------------------------

local UIHomelandBuildUpgradeView = class("UIHomelandBuildUpgradeView")

local nMaxUpgradeLevel = 15 --目前最大等级15
local nAttrNum = 5 --属性数量 目前这些 观赏、实用、坚固、风水、趣味

function UIHomelandBuildUpgradeView:OnEnter()
    if not self.bInit then
        self:RegEvent()
        self:BindUIEvent()
        self.bInit = true
    end

    self.dwCurrMapID, self.nCurrCopyIndex, self.nCurrLandIndex = HomelandBuildData.GetMapInfo()
    GetHomelandMgr().ApplyLandInfo(self.dwCurrMapID, self.nCurrCopyIndex, self.nCurrLandIndex)
    self:UpdateInfo()

    APIHelper.DoToday("RedPointExcute_3801")
end

function UIHomelandBuildUpgradeView:OnExit()
    self.bInit = false
end

function UIHomelandBuildUpgradeView:BindUIEvent()
    UIHelper.BindUIEvent(self.BtnClose, EventType.OnClick, function ()
        UIMgr.Close(self)
    end)

    UIHelper.BindUIEvent(self.BtnUpgrade, EventType.OnClick, function ()
        if self.nCurrLandIndex and self.nCurrLandIndex > 0 then
            RemoteCallToServer("On_Home_LevelUp", self.dwCurrMapID, self.nCurrCopyIndex, self.nCurrLandIndex, self.nCurrSelectionLevel + 1)
            UIHelper.SetButtonState(self.BtnUpgrade, BTN_STATE.Disable)
        end
    end)
end

function UIHomelandBuildUpgradeView:RegEvent()
    Event.Reg(self, "HOME_LAND_RESULT_CODE_INT", function()
        local nResultType = arg0
		if nResultType == HOMELAND_RESULT_CODE.APPLY_LAND_INFO then --获取地块属性信息
			local dwMapID, nCopyIndex, nLandIndex = arg1, arg2, arg3
			if self.dwCurrMapID == dwMapID and self.nCurrCopyIndex == nCopyIndex and self.nCurrLandIndex == nLandIndex then
                self:UpdateInfo()
			end
		elseif nResultType == HOMELAND_RESULT_CODE.APPLY_LEVEL_UP then --是否可以升级
			local dwMapID, nCopyIndex, nLandIndex, bCanLevelUp = arg1, arg2, arg3, arg4
			if self.dwCurrMapID == dwMapID and self.nCurrCopyIndex == nCopyIndex and self.nCurrLandIndex == nLandIndex then
                self:UpdateInfo()
			end
		end
    end)

    Event.Reg(self, "HOMELAND_UPGRADE_SUCCESS", function()
        local dwMapID, nCopyIndex, nLandIndex, nCurrLevel, nOldLevel = arg0, arg1, arg2, arg3, arg4
		if self.dwCurrMapID == dwMapID and self.nCurrCopyIndex == nCopyIndex and self.nCurrLandIndex == nLandIndex then
			GetHomelandMgr().ApplyHLLandInfo(nLandIndex) -- 为了让下次打开家园建造界面时，数量统计模块正常工作；可能需要换地方
            GetHomelandMgr().ApplyLandInfo(self.dwCurrMapID, self.nCurrCopyIndex, self.nCurrLandIndex)
            UIHelper.PlayAni(self, self.AniAll, "AniUpgrade")

			-- HouseUpgrade.tLandInfo.nLevel = nCurrLevel
			-- HouseUpgrade.nCurrSelectionLevel = nCurrLevel
			-- ShowAllLevelBtnInfo(this, HouseUpgrade.nCurrSelectionLevel)
			-- ShowHouseUpgradeInfo(this, HouseUpgrade.nCurrSelectionLevel)
			-- ShowUpgradeSFX(this)
		end
    end)
end

function UIHomelandBuildUpgradeView:UpdateInfo()
    self.tbLandInfo = GetHomelandMgr().GetLandInfo(self.dwCurrMapID, self.nCurrCopyIndex, self.nCurrLandIndex)
    if not self.tbLandInfo then
		return
	end

	self.nCurrSelectionLevel = self.tbLandInfo.nLevel
    self:UpdateConditionInfo()
    self:UpdateUnlockInfo()
end


function UIHomelandBuildUpgradeView:UpdateConditionInfo()
    UIHelper.SetString(self.LabelMansionTitleLevel01, string.format("%d级", self.nCurrSelectionLevel))
    UIHelper.SetString(self.LabelMansionTitleLevel02, string.format("%d级", self.nCurrSelectionLevel + 1))

    local bCanLevelUp = true
    local bFullLevel = false
	local tbConfig = GetHomelandMgr().GetLevelUpConfig(self.nCurrSelectionLevel)  --逻辑配置表是1级代表 1级升2级需要的条件
    local nScore = GetClientPlayer().GetHomelandRecord()
    if not tbConfig then
        UIHelper.SetRichText(self.RichTextCondition, g_tStrings.STR_HOMELAND_UPGRADE_FULL_LEVEL)
        UIHelper.SetString(self.LabelMansionTitleLevel02, g_tStrings.STR_HOMELAND_UPGRADE_FULL_LEVEL)
        bFullLevel = true
    else
        local szCon = ""

        if nScore >= tbConfig.Record then
            szCon = szCon .. GetFormatText(string.format("%s%d/%d\n", g_tStrings.STR_HOMELAND_UPGRADE_RECORD, nScore, tbConfig.Record), nil, 157,255,166)
        else
            szCon = szCon .. GetFormatText(string.format("%s%d/%d\n", g_tStrings.STR_HOMELAND_UPGRADE_RECORD, nScore, tbConfig.Record), nil, 255,118,118)
            bCanLevelUp = false
        end

        if tbConfig.Currency > 0 then
            local player = GetClientPlayer()
            if player.nArchitecture >= tbConfig.Currency then
                szCon = szCon .. GetFormatText(FormatString("园宅币：<D0>/<D1>", player.nArchitecture, tbConfig.Currency), nil, 157,255,166)
            else
                szCon = szCon .. GetFormatText(FormatString("园宅币：<D0>/<D1>", player.nArchitecture, tbConfig.Currency), nil, 255,118,118)
                bCanLevelUp = false
            end
        end

        UIHelper.SetRichText(self.RichTextCondition, szCon)
    end

    UIHelper.ScrollViewDoLayoutAndToTop(self.ScrollViewCondition)

    if bCanLevelUp and not bFullLevel then
        UIHelper.SetButtonState(self.BtnUpgrade, BTN_STATE.Normal)
    elseif bFullLevel then
        UIHelper.SetButtonState(self.BtnUpgrade, BTN_STATE.Disable, "已满级无法继续升级")
    else
        UIHelper.SetButtonState(self.BtnUpgrade, BTN_STATE.Disable, "升级条件未达成")
    end
end

function UIHomelandBuildUpgradeView:UpdateUnlockInfo()
    local tbConfigs = Table_GetTableHomelandUpgradeInfos()
    local tbConfig = tbConfigs[self.nCurrSelectionLevel]

    if tbConfig then
        local szUnlockInfo = UIHelper.GBKToUTF8(tbConfig.szUnlockInfo)
        szUnlockInfo = ParseTextHelper.ParseNormalText(szUnlockInfo, false)
        UIHelper.SetRichText(self.RichTextUnlock, szUnlockInfo)
    end

    UIHelper.ScrollViewDoLayoutAndToTop(self.ScrollViewUnlock)

end


return UIHomelandBuildUpgradeView