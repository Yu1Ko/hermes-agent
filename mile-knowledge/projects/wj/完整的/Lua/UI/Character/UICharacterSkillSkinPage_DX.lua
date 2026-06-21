-- ---------------------------------------------------------------------------------
-- Author: Unknown
-- Name: UICharacterSkillSkinPage_DX
-- Date: 2024-09-06 10:01:15
-- Desc: ?
-- ---------------------------------------------------------------------------------

---@type UICharacterPendantPublicPage
---@class UICharacterSkillSkinPage_DX : UICharacterPendantPublicPage
---@field DataModel CharacterSkillSkinData_DX
local UICharacterSkillSkinPage_DX = class(UICharacterPendantPublicPage, "UICharacterSkillSkinPage_DX")

function UICharacterSkillSkinPage_DX:Init()
    self.nCurSelectedIndex = 1
    self:BindMainPageIndex(AccessoryMainPageIndex.SkillSkin_DX)
    self:BindDataModel(CharacterSkillSkinData_DX)

    if not self.bInit then
        self:RegEvent()
        self:BindUIEvent()
        self.bInit = true
    end

    self.DataModel.Init()
    self:InitTogList()
    self:UpdateInfo()
end

function UICharacterSkillSkinPage_DX:BindUIEvent()

end

function UICharacterSkillSkinPage_DX:RegEvent()
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

function UICharacterSkillSkinPage_DX:UnRegEvent()
    --Event.UnReg(self, EventType.XXX)
end






-- ----------------------------------------------------------
-- Please write your own code below  ↓↓↓
-- ----------------------------------------------------------

function UICharacterSkillSkinPage_DX:UpdateInfo()
    self.tbScriptSkillSkinCell = self.tbScriptSkillSkinCell or {}
    self:ShowImgTitle(false)
    -- self:UpdateTogList()    -- 红点相关

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
            scriptCell = UIHelper.AddPrefab(PREFAB_ID.WidgetAccessoryListItem, self.ScrollViewStandbyList)
            table.insert(self.tbScriptSkillSkinCell, scriptCell)
            -- UIHelper.ToggleGroupAddToggle(self.ToggleGroupStandbyList, scriptCell.TogAccessoryEffect)
        end
        scriptCell:OnInitWithDXSkillSkin(tbInfo.nSkillID, tbInfo.nSkinID, tbInfo.bHave)
        scriptCell:SetClickCallback(function ()
            self:ShowSkillSkinTips(tbInfo.nSkillID, tbInfo.nSkinID)
        end)
        UIHelper.SetVisible(scriptCell._rootNode, true)
    end
    self:ClearSelect()
    self:ShowWidgetEmpty(#tbSkillSkinList == 0 and self.nSelectMainPage == AccessoryMainPageIndex.SkillSkin_DX)
    UIHelper.ScrollViewDoLayoutAndToTop(self.ScrollViewStandbyList)
end

function UICharacterSkillSkinPage_DX:InitTogList()
    self.tbScriptToggle = {}
    UIHelper.RemoveAllChildren(self.ScrollViewSkillList)
    local tbSkillSkinList = self.DataModel.GetAllSkinList()
    for i, tbSkill in ipairs(tbSkillSkinList) do
        local scriptCell = UIHelper.AddPrefab(PREFAB_ID.WidgetSkillCell1, self.ScrollViewSkillList)
        RedpointMgr.RegisterRedpoint(scriptCell.ImgRedPoint, nil, {1106})
        scriptCell:UpdateInfo(tbSkill.nSkillID)
        scriptCell:SetToggleGroup(self.ToggleGroupRightNav)
        scriptCell:BindSelectFunction(function ()
            self:ClearSelect()
            self.nCurSelectedIndex = i
            -- self:SetNowCollectPage(self.nCurSelectedIndex == 0)
            Event.Dispatch(EventType.OnCharacterPendantSelectedSubPage, self.nCurSelectedIndex)
        end)
        table.insert(self.tbScriptToggle, scriptCell)
    end
    UIHelper.ScrollViewDoLayoutAndToTop(self.ScrollViewSkillList)
    UIHelper.ScrollViewSetupArrow(self.ScrollViewSkillList, self.WidgetArrow)
    UIHelper.SetToggleGroupSelected(self.ToggleGroupRightNav, self.nCurSelectedIndex - 1)
end

function UICharacterSkillSkinPage_DX:ShowSkillSkinTips(nSkillID, nSkinID)
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

    if nSkinID == 0 or player.IsHaveSkillSkin(nSkinID) then
        local bIsActivityOn = player.IsSkillSkinActive(nSkinID)
        if bIsActivityOn then
            if nSkinID ~= 0 then
                table.insert(tbBtnState, {szName = "脱下", OnClick = function ()
                    Event.Dispatch(EventType.HideAllHoverTips)
                    local nRetCode = player.DeactiveSkillSkin(nSkinID)
	                if nRetCode == SKILL_SKIN_RESULT_CODE.SUCCESS then
                        local tSkin = Table_GetSkillSkinInfo(nSkinID)
		                if tSkin and tSkin.bCallBack then
			                RemoteCallToServer("On_LiuPai_ChangeLiuPaiSkin", 0)
                        end
		            end
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
                            local tSkin = Table_GetSkillSkinInfo(nSkinID)
                            if tSkin and tSkin.bCallBack then
			                    RemoteCallToServer("On_LiuPai_ChangeLiuPaiSkin", nSkinID)
		                    end
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

function UICharacterSkillSkinPage_DX:DeactiveSkillSkin(nSkillID)
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
    else
        local tSkin = Table_GetSkillSkinInfo(dwSkinID)
		if tSkin and tSkin.bCallBack then
			RemoteCallToServer("On_LiuPai_ChangeLiuPaiSkin", 0)
		end
	end
end

function UICharacterSkillSkinPage_DX:ClearSelect()
    if self.tbScriptSkillSkinCell then
        for i, scriptCell in ipairs(self.tbScriptSkillSkinCell) do
            scriptCell:SetSelected(false)
        end
    end

    UIHelper.SetSelected(self.TogSift, false)
end

return UICharacterSkillSkinPage_DX