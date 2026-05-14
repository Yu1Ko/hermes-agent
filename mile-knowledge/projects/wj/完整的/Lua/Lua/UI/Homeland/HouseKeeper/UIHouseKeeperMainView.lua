-- ---------------------------------------------------------------------------------
-- Author: Unknown
-- Name: UIHouseKeeperMainView
-- Date: 2023-08-08 20:45:09
-- Desc: ?
-- ---------------------------------------------------------------------------------

local UIHouseKeeperMainView = class("UIHouseKeeperMainView")

local HouseKeeperSkillType = {
    -- 天赋
    ["GiftSkill"]           = 1,
    -- 已装备技能
    ["CurSkill"]            = 2,
    -- 常驻技能
    ["StaticSkill"]         = 3,
    -- 未装备技能
    ["NotActiveSkill"]      = 4,
}

function UIHouseKeeperMainView:OnEnter(tHouseKeeperData)
    if not self.bInit then
        self:RegEvent()
        self:BindUIEvent()
        self.bInit = true
        cc.SpriteFrameCache:getInstance():addSpriteFramesWithJson("Resource/JYPlay/HouseKeeper_Avatar.json")
    end

    self.tHouseKeeperData = tHouseKeeperData
    HouseKeeperData.OnInit(tHouseKeeperData)
    UIHelper.HideInteract()
    self:UpdateInfo()
end

function UIHouseKeeperMainView:OnExit()
    UIHelper.ShowInteract()
    self.bInit = false
end

function UIHouseKeeperMainView:BindUIEvent()

    UIHelper.BindUIEvent(self.BtnUp, EventType.OnClick, function ()
        local tHKData = HouseKeeperData.GetHouseKeeperData()
        if tHKData.Exp < tHKData.LevelUpExp then
            TipsHelper.ShowNormalTip("阅历值不足，暂时无法升级")
            return
        end

        HouseKeeperData.RemoteCall("On_NPCServant_LevelUp", tHKData.ServantID)
    end)

    UIHelper.BindUIEvent(self.BtnUpdate, EventType.OnClick, function ()
        if not self.tbSelectedInfo then return end

        local tHKData = HouseKeeperData.GetHouseKeeperData()
        HouseKeeperData.RemoteCall("On_NPCServant_LevelUpSkill", tHKData.ServantID, self.tbSelectedInfo.nSkillID)
    end)

    UIHelper.BindUIEvent(self.BtnSet, EventType.OnClick, function ()
        if not self.tbSelectedInfo then return end

        local tHKData = HouseKeeperData.GetHouseKeeperData()
        HouseKeeperData.RemoteCall("On_NPCServant_LoadSkill", tHKData.ServantID, self.tbSelectedInfo.nSkillID)
    end)

    UIHelper.BindUIEvent(self.BtnUnload, EventType.OnClick, function ()
        if not self.tbSelectedInfo then return end

        local tHKData = HouseKeeperData.GetHouseKeeperData()
        HouseKeeperData.RemoteCall("On_NPCServant_UnLoadSkill", tHKData.ServantID, self.tbSelectedInfo.nSkillID)
    end)

    UIHelper.BindUIEvent(self.BtnReplace, EventType.OnClick, function ()
        if not self.tbSelectedInfo then return end

        local tHKData = HouseKeeperData.GetHouseKeeperData()
        local nSkillIDBeReplaced = HouseKeeperData.GetOldSkillIDInReplace()
        if not nSkillIDBeReplaced then
            HouseKeeperData.RemoteCall("On_NPCServant_LoadSkill", tHKData.ServantID, self.tbSelectedInfo.nSkillID)
        else
            HouseKeeperData.SetOldSkillIDInReplace(nil)
            HouseKeeperData.RemoteCall("On_NPCServant_SwitchSkill", tHKData.ServantID, nSkillIDBeReplaced, self.tbSelectedInfo.nSkillID)
        end

    end)

    UIHelper.BindUIEvent(self.BtnReset, EventType.OnClick, function ()
        if not self.tbSelectedInfo then return end

        local tHKData = HouseKeeperData.GetHouseKeeperData()
        HouseKeeperData.RemoteCall("On_NPCServant_ReSetTalent", tHKData.ServantID, self.tbSelectedInfo.nSkillID)
    end)
end

function UIHouseKeeperMainView:RegEvent()
    Event.Reg(self, EventType.OnSelectedHouseKeeperSkillCell, function (nIndex, tbInfo)
        HouseKeeperData.SetOldSkillIDInReplace(nil)

        if nIndex == 0 then
            self:ShowRightInfo(false)
            self:ShowSkillTipsInfo(false)
            return
        end

        if not tbInfo then
            self:ShowRightInfo(true)
            self:ShowSkillTipsInfo(false)
        else
            self:ShowRightInfo(false)
            self:ShowSkillTipsInfo(true, nIndex, tbInfo)

            if tbInfo.nSkillType == HouseKeeperSkillType.GiftSkill then

            elseif tbInfo.nSkillType == HouseKeeperSkillType.CurSkill then
                HouseKeeperData.SetOldSkillIDInReplace(tbInfo.nSkillID)
                self:ShowRightInfo(true)
            elseif tbInfo.nSkillType == HouseKeeperSkillType.StaticSkill then
                local tHKData = HouseKeeperData.GetHouseKeeperData()
                HouseKeeperData.RemoteCall("On_NPCServant_UseSkill", tHKData.ServantID, tbInfo.nSkillID)
            end
        end
    end)

    Event.Reg(self, EventType.OnSelectedHouseKeeperChangeSkillCell, function (nIndex, nItemType, nItemIndex)
        if nIndex == 0 then
            self:ShowSkillTipsInfo(false)
            return
        end

        local nSkillID = HouseKeeperData.GetSkillIDByItemInfo(nItemType, nItemIndex)
	    local szBoxInfo = nItemType .. "_" .. nItemIndex
        self:ShowSkillTipsInfo(true, nIndex, {
            nSkillType = HouseKeeperSkillType.NotActiveSkill,
            nSkillID = nSkillID,
            szBoxInfo = szBoxInfo,
        })
    end)

    Event.Reg(self, EventType.OnUpdateHouseKeeperData, function()
        self:UpdateInfo()

        Event.Dispatch(EventType.OnSelectedHouseKeeperSkillCell, 0)
    end)

    Event.Reg(self, EventType.OnViewOpen, function(nViewID)
        if nViewID == VIEW_ID.PanelOldDialogue then
            UIHelper.SetVisible(self._scriptBG._rootNode, false)
        end
    end)

    Event.Reg(self, EventType.OnViewClose, function(nViewID)
        if nViewID == VIEW_ID.PanelOldDialogue then
            UIHelper.SetVisible(self._scriptBG._rootNode, true)
        end
    end)
end

function UIHouseKeeperMainView:UpdateInfo()
    self:UpdateKeeperInfo()
    self:UpdateGiftSkill()
    self:UpdateCurSkill()
    self:UpdateStaticSkill()

    UIHelper.ScrollViewDoLayoutAndToTop(self.ScrollViewSkill)
end

function UIHouseKeeperMainView:UpdateKeeperInfo()
    local tHouseKeeperData = HouseKeeperData.GetHouseKeeperData()

    UIHelper.SetString(self.LabelName, UIHelper.GBKToUTF8(tHouseKeeperData.szServantName))
    UIHelper.SetString(self.LabelLevel, string.format("等级：%s", g_tStrings.tHouseKeeperLevel[tHouseKeeperData.Level]))

	local szExp = tostring(tHouseKeeperData.Exp) .. "/" .. tostring(tHouseKeeperData.LevelUpExp)
    UIHelper.SetString(self.LabelLevelNum, string.format("%s", szExp))
    if tHouseKeeperData.Level >= HouseKeeperData.GetMaxLevelOfHK() then
        UIHelper.SetString(self.LabelLevelNum, "已经是最棒的管家！")
    end

    local fExpPercent = tHouseKeeperData.Exp / tHouseKeeperData.LevelUpExp
    UIHelper.SetProgressBarPercent(self.ProgressBarLevel, fExpPercent * 100)

    local szLove = tostring(tHouseKeeperData.Love) .. "/" .. tostring(tHouseKeeperData.MaxLove)
    UIHelper.SetString(self.LabelFavorabilityNum, szLove)
    UIHelper.SetString(self.LabelFavorabilityLevel, string.format("%d级", tHouseKeeperData.nLoveLevel))

	local fPercent = tHouseKeeperData.Love / tHouseKeeperData.MaxLove
    UIHelper.SetProgressBarPercent(self.ProgressBarFavorability, fPercent * 100)

    local szSpriteFrame = tHouseKeeperData.tAvatarFrame[tHouseKeeperData.Level]
    UIHelper.SetSpriteFrame(self.ImgPlayerIcon, HouseKeeperAvatarImg[tonumber(szSpriteFrame)])

    if tHouseKeeperData.Exp < tHouseKeeperData.LevelUpExp then
        UIHelper.SetButtonState(self.BtnUp, BTN_STATE.Disable, "阅历值不足，暂时无法升级")
    else
        UIHelper.SetButtonState(self.BtnUp, BTN_STATE.Normal)
    end
end

function UIHouseKeeperMainView:UpdateGiftSkill()
	local tHouseKeeperData = HouseKeeperData.GetHouseKeeperData()

	local tSkillData = HouseKeeperData.GetSkillData()
    local tSingleSkillData = Lib.copyTab(tSkillData[tHouseKeeperData.GiftSkillID])
    tSingleSkillData.nSkillID = tHouseKeeperData.GiftSkillID
    tSingleSkillData.nSkillType = HouseKeeperSkillType.GiftSkill

	self.scriptGiftSkill = self.scriptGiftSkill or UIHelper.AddPrefab(PREFAB_ID.WidgetHouseKeepSkill, self.ScrollViewSkill)
    self.scriptGiftSkill:OnEnter("天赋技能", {tSingleSkillData})
end

function UIHouseKeeperMainView:UpdateCurSkill()
	local tHouseKeeperData = HouseKeeperData.GetHouseKeeperData()

	local tSkillData = HouseKeeperData.GetSkillData()
    local tbSkillInfo = {}
	for _, tSkillInfo in ipairs(tHouseKeeperData.tCurrentSkill) do
		local tSkillData = HouseKeeperData.GetSkillData()
		local tSingleSkillData = Lib.copyTab(tSkillData[tSkillInfo[1]])
        tSingleSkillData.nSkillID = tSkillInfo[1]
        tSingleSkillData.nSkillLevel = tSkillInfo[2] or 1
        tSingleSkillData.nSkillType = HouseKeeperSkillType.CurSkill

		table.insert(tbSkillInfo, tSingleSkillData)
	end

	self.scriptCurSkill = self.scriptCurSkill or UIHelper.AddPrefab(PREFAB_ID.WidgetHouseKeepSkill, self.ScrollViewSkill)
    self.scriptCurSkill:OnEnter("装备技能", tbSkillInfo, tHouseKeeperData.MaxSkillNum)
end

function UIHouseKeeperMainView:UpdateStaticSkill()
	local tHouseKeeperData = HouseKeeperData.GetHouseKeeperData()

	local tSkillData = HouseKeeperData.GetSkillData()
    local tbSkillInfo = {}
	for _, tSkillInfo in ipairs(tHouseKeeperData.tStaticSkill) do
		local tSkillData = HouseKeeperData.GetSkillData()
		local tSingleSkillData = Lib.copyTab(tSkillData[tSkillInfo[1]])
        tSingleSkillData.nSkillID = tSkillInfo[1]
        tSingleSkillData.nSkillType = HouseKeeperSkillType.StaticSkill

		table.insert(tbSkillInfo, tSingleSkillData)
	end

	self.scriptStaticSkill = self.scriptStaticSkill or UIHelper.AddPrefab(PREFAB_ID.WidgetHouseKeepSkill, self.ScrollViewSkill)
    self.scriptStaticSkill:OnEnter("常驻技能", tbSkillInfo)
end

function UIHouseKeeperMainView:ShowRightInfo(bShow)
    UIHelper.SetVisible(self.WidgetAniRight, bShow)
    if bShow then
        UIHelper.PlayAni(self, self.AinAll, "AniRightShow")
    else
        UIHelper.PlayAni(self, self.AinAll, "AniRightHide")
    end
    if not bShow then return end

    self.tbRightSkillCells = self.tbRightSkillCells or {}
    UIHelper.HideAllChildren(self.ScrollViewSkillList)
    local tbInfo = HouseKeeperData.ConstructSmallBagCofig()
    for i, nItemType in ipairs(tbInfo.tItemType) do
        local nItemIndex = tbInfo.tItemIndex[i]
        if not self.tbRightSkillCells[i] then
            self.tbRightSkillCells[i] = UIHelper.AddPrefab(PREFAB_ID.WidgetHouseKeepSkillinstallation, self.ScrollViewSkillList)
        end

        UIHelper.SetVisible(self.tbRightSkillCells[i]._rootNode, true)
        self.tbRightSkillCells[i]:OnEnter(i, nItemType, nItemIndex)
    end

    UIHelper.ScrollViewDoLayoutAndToTop(self.ScrollViewSkillList)
end

function UIHouseKeeperMainView:ShowSkillTipsInfo(bShow, nIndex, tbInfo)
    UIHelper.SetVisible(self.WidgetSkillTip, bShow)
    self.nSelectedIndex = nIndex
    self.tbSelectedInfo = tbInfo

    if not bShow or not tbInfo then return end

    local tBoxInfo = string.split(tbInfo.szBoxInfo, "_")
    local dwTabType, dwIndex, _ = tBoxInfo[1], tBoxInfo[2]
    local item = ItemData.GetItemInfo(dwTabType, dwIndex)
    UIHelper.SetString(self.LabelSkillName, UIHelper.GBKToUTF8(Table_GetItemName(item.nUiId)))
    UIHelper.SetString(self.LabelSkillContent, UIHelper.GBKToUTF8(ParseTextHelper.ParseNormalText(Table_GetItemDesc(item.nUiId), true)))


    UIHelper.SetVisible(self.BtnUpdate, false)
    UIHelper.SetVisible(self.BtnSet, false)
    UIHelper.SetVisible(self.BtnUnload, false)
    UIHelper.SetVisible(self.BtnReplace, false)
    UIHelper.SetVisible(self.BtnReset, false)

    local bHadBtn = false
    if tbInfo.nSkillType == HouseKeeperSkillType.GiftSkill then
        UIHelper.SetVisible(self.BtnReset, true)
        bHadBtn = true
    elseif tbInfo.nSkillType == HouseKeeperSkillType.CurSkill then
        UIHelper.SetVisible(self.BtnUpdate, true)
        UIHelper.SetVisible(self.BtnUnload, true)
        bHadBtn = true
    elseif tbInfo.nSkillType == HouseKeeperSkillType.StaticSkill then

    elseif tbInfo.nSkillType == HouseKeeperSkillType.NotActiveSkill then
        local nSkillIDBeReplaced = HouseKeeperData.GetOldSkillIDInReplace()
        if not nSkillIDBeReplaced then
            UIHelper.SetVisible(self.BtnSet, true)
        else
            UIHelper.SetVisible(self.BtnReplace, true)
        end
        UIHelper.SetVisible(self.BtnUpdate, true)
        bHadBtn = true
    end

    UIHelper.SetVisible(self.LayoutSkillBtn, bHadBtn)

    UIHelper.LayoutDoLayout(self.LayoutSkillBtn)
    UIHelper.LayoutDoLayout(self.WidgetTipContent)
end


return UIHouseKeeperMainView