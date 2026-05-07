-- ---------------------------------------------------------------------------------
-- Author: Unknown
-- Name: UICharacterSkillSkinPage
-- Date: 2024-09-06 10:01:15
-- Desc: ?
-- ---------------------------------------------------------------------------------

---@type UICharacterPendantPublicPage
---@class UICharacterSkillSkinPage : UICharacterPendantPublicPage
local UICharacterSkillSkinPage = class(UICharacterPendantPublicPage, "UICharacterSkillSkinPage")

function UICharacterSkillSkinPage:Init()
    self.nCurSelectedIndex = 1
    self:BindMainPageIndex(AccessoryMainPageIndex.SkillSkin)
    self:BindDataModel(CharacterSkillSkinData)

    if not self.bInit then
        self:RegEvent()
        self:BindUIEvent()
        self.bInit = true
    end
    self.DataModel.Init()
    self:UpdateInfo()
end

function UICharacterSkillSkinPage:BindUIEvent()
    for i, tog in ipairs(self.tbTogType) do
        UIHelper.ToggleGroupAddToggle(self.ToggleGroupRightNav, tog)
        UIHelper.BindUIEvent(tog, EventType.OnClick, function()
            self:ClearSelect()
            self.nCurSelectedIndex = i - 1
            self:SetNowCollectPage(self.nCurSelectedIndex == 0)
            Event.Dispatch(EventType.OnCharacterPendantSelectedSubPage, self.nCurSelectedIndex)
        end)
    end
    UIHelper.SetToggleGroupSelected(self.ToggleGroupRightNav, self.nCurSelectedIndex)
end

function UICharacterSkillSkinPage:RegEvent()
    Event.Reg(self, EventType.OnFilter, function(szKey, tbInfo)
        if not self.tbFilter or szKey ~= self.tbFilter.Key then
            return
        end

        local nFilterHave = tbInfo[1][1]
        self.DataModel.SetFilterHave(nFilterHave - 1)
        self.DataModel.UpdateFilterList()
        self.DataModel.SetCurrentPage(1)
        self:UpdateButtonInfo()
        self:UpdateInfo()
    end)

    Event.Reg(self, "ON_UPDATE_ACTIVE_SKILL_SKIN", function(dwPlayerID)
        if dwPlayerID ~= PlayerData.GetPlayerID() then
            return
        end

        self:UpdateInfo()
    end)

    Event.Reg(self, "ON_UPDATE_SKILL_SKIN", function(dwPlayerID)
        if dwPlayerID ~= PlayerData.GetPlayerID() then
            return
        end

        self:UpdateInfo()
    end)

    Event.Reg(self, EventType.OnUpdateSkillSkinLike, function()
        self.DataModel.UpdateFilterList()
        self.DataModel.SetCurrentPage(1)
        self:UpdateButtonInfo()
        self:UpdateInfo()
    end)
end

function UICharacterSkillSkinPage:UnRegEvent()
    --Event.UnReg(self, EventType.XXX)
end






-- ----------------------------------------------------------
-- Please write your own code below  ↓↓↓
-- ----------------------------------------------------------

function UICharacterSkillSkinPage:UpdateInfo()
    self.tbScriptSkillSkinCell = self.tbScriptSkillSkinCell or {}
    self:SetImgTitle(ACCSEEORY_SKILL_SKIN_TITLE_IMG[self.DataModel.GetSkillID()] or "")
    self:UpdateTogInfo()    -- 红点相关

    if self.nCurSelectedIndex == 0 then
        self:SetLabelEmpty("暂无收藏的武技殊影图")
    else
        self:SetLabelEmpty(string.format("暂无符合条件的武技殊影图"))
    end

    for i, scriptCell in ipairs(self.tbScriptSkillSkinCell) do
        UIHelper.SetVisible(scriptCell._rootNode, false)
    end

    local tbSkillSkinList = self.DataModel.GetSkillSkinList()
    for index, tbInfo in ipairs(tbSkillSkinList) do
        local scriptCell = self.tbScriptSkillSkinCell[index]
        if not scriptCell then
            scriptCell = UIHelper.AddPrefab(PREFAB_ID.WidgetAccessoryEffect, self.ScrollViewStandbyList)
            table.insert(self.tbScriptSkillSkinCell, scriptCell)
            UIHelper.ToggleGroupAddToggle(self.ToggleGroupStandbyList, scriptCell.TogAccessoryEffect)
        end
        scriptCell:InitWithSkillSkin(tbInfo)
        scriptCell:SetClickCallback(function ()
            local nSkillID = tbInfo.nSkillID
            local nSkinID = tbInfo.nSkinID or 0

            RedpointHelper.SkillSkin_SetNew(nSkinID)
            self:ShowSkillSkinTips(nSkillID, nSkinID)
            self:UpdateTogInfo()
            scriptCell:InitWithSkillSkin(tbInfo)
        end)
        UIHelper.SetVisible(scriptCell._rootNode, true)
    end
    self:ClearSelect()
    self:ShowWidgetEmpty(#tbSkillSkinList == 0)
    UIHelper.ScrollViewDoLayoutAndToTop(self.ScrollViewStandbyList)
    UIHelper.ScrollViewSetupArrow(self.ScrollViewEffecScrollViewStandbyListtList, self.WidgetArrow)
end

function UICharacterSkillSkinPage:UpdateTogInfo()
    for i, imgRedpoint in ipairs(self.tbTogRedPoint) do
        local bHasNew = false
        local nIndex = i - 1
        local nSkillID = self.DataModel.GetSkillID(nIndex)
        local tbSkillInfo = UISkillSkinTab[nSkillID]
        for nSkinID, _ in pairs(tbSkillInfo) do
            if not bHasNew and RedpointHelper.SkillSkin_IsNew(nSkinID) then
                bHasNew = true
            end
        end
        UIHelper.SetVisible(imgRedpoint, bHasNew)
    end
end

function UICharacterSkillSkinPage:ShowSkillSkinTips(nSkillID, nSkinID)
    UIHelper.SetSelected(self.TogSift, false)
    local player = PlayerData.GetClientPlayer()

    local scriptItemTip = self:GetItemTips()
    if not scriptItemTip then
        return
    end

    scriptItemTip:OnInitSkillSkin(nSkillID, nSkinID)
    local tbBtnState = {}

    local bHaveActSkin = false
    local bLike = self.DataModel.GetSkinLike(nSkinID)
    local dwGroupID = CharacterSkillSkinData.GetGroupID(nSkillID)
	local dwActSkinID = player.GetActiveSkillSkinByGroupID(dwGroupID)
	if dwActSkinID and dwActSkinID > 0 then
		bHaveActSkin = true
	end

    if nSkinID ~= 0 then
        if bLike then
            table.insert(tbBtnState, {szName = "取消收藏", OnClick = function ()
                Event.Dispatch(EventType.HideAllHoverTips)
                self.DataModel.SetSkinLike(nSkinID, true)
            end})
        else
            table.insert(tbBtnState, {szName = "加入收藏", OnClick = function ()
                Event.Dispatch(EventType.HideAllHoverTips)
                self.DataModel.SetSkinLike(nSkinID, false)
            end})
        end
    end

    if nSkinID == 0 or player.IsHaveSkillSkin(nSkinID) then
        local bIsActivityOn = player.IsSkillSkinActive(nSkinID)
        if bIsActivityOn then
            if nSkinID ~= 0 then
                table.insert(tbBtnState, {szName = "脱下", OnClick = function ()
                    Event.Dispatch(EventType.HideAllHoverTips)
                    player.DeactiveSkillSkin(nSkinID)
                end})
            end
        else
            if (bHaveActSkin and nSkinID == 0) or nSkinID ~= 0 then
                table.insert(tbBtnState, {szName = "穿戴", OnClick = function ()
                    Event.Dispatch(EventType.HideAllHoverTips)
                    if nSkinID == 0 then
                        self:DeactiveSkillSkin(nSkillID)
                    else
                        local nRetCode = player.CanActiveSkillSkin(nSkinID)
                        if nRetCode == SKILL_SKIN_RESULT_CODE.SUCCESS then
                            player.ActiveSkillSkin(nSkinID)
                        else
                            local szTips = g_tStrings.tSkillSkinResult[nRetCode]
                            TipsHelper.ShowImportantRedTip(szTips)
                        end
                    end
                end})
            end
        end
    end

    if nSkinID > 0 then
        local tList = Table_GetSkillSkinPreivew(nSkinID)
        if tList and not table.is_empty(tList) then
            table.insert(tbBtnState, {szName = "预览", OnClick = function ()
                local tbConfig = {}
                local szUrl = tList[1].szUrl
                tbConfig.bNet = true
                tbConfig.bShop = true
                MovieMgr.PlayVideo(szUrl, tbConfig ,{})
            end})
        end
    end

    scriptItemTip:SetBtnState(tbBtnState)
end

function UICharacterSkillSkinPage:DeactiveSkillSkin(nSkillID)
	local hPlayer = GetClientPlayer()
	if not hPlayer then
		return
	end

    local dwGroupID = CharacterSkillSkinData.GetGroupID(nSkillID)
	local dwSkinID = hPlayer.GetActiveSkillSkinByGroupID(dwGroupID)
	if not dwSkinID then
		return
	end
	local nRetCode = hPlayer.DeactiveSkillSkin(dwSkinID)
	if nRetCode ~= SKILL_SKIN_RESULT_CODE.SUCCESS then
        local szTips = g_tStrings.tSkillSkinResult[nRetCode]
        TipsHelper.ShowImportantRedTip(szTips)
	end
end

function UICharacterSkillSkinPage:ClearSelect()
    if self.tbScriptSkillSkinCell then
        for i, scriptCell in ipairs(self.tbScriptSkillSkinCell) do
            scriptCell:SetSelected(false)
        end
    end

    UIHelper.SetSelected(self.TogSift, false)
end

return UICharacterSkillSkinPage