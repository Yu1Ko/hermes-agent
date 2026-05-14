-- ---------------------------------------------------------------------------------
-- Author: Unknown
-- Name: UITreasureBattleFieldSkillListView
-- Date: 2024-08-05 09:55:55
-- Desc: ?
-- ---------------------------------------------------------------------------------

local UITreasureBattleFieldSkillListView = class("UITreasureBattleFieldSkillListView")

function UITreasureBattleFieldSkillListView:OnEnter()
    if not self.bInit then
        self:RegEvent()
        self:BindUIEvent()
        self.bInit = true
    end

    local nQuality, nEffect
    if FilterDef.TreasureBattleFieldSkill.tbRuntime then
        nQuality = FilterDef.TreasureBattleFieldSkill.tbRuntime[1][1] - 1
        nEffect = FilterDef.TreasureBattleFieldSkill.tbRuntime[2][1] - 1
    else
        nQuality = 0
        nEffect = 0
    end
    self.tFilterData = {
        nQuality = nQuality,
        nEffect = nEffect,
        szSearch = ""
    }


    self:UpdateInfo()
end

function UITreasureBattleFieldSkillListView:OnExit()
    self.bInit = false
    self:UnRegEvent()
end

function UITreasureBattleFieldSkillListView:BindUIEvent()
    UIHelper.BindUIEvent(self.BtnClose, EventType.OnClick, function ()
        UIMgr.Close(self)
    end)

    UIHelper.BindUIEvent(self.TogScreenWithLabel, EventType.OnSelectChanged, function(_, bSelected)
        if bSelected then
            local tbInfo, tbList
            tbInfo = Tabel_GetDesertStormSkillQuality()
            tbList = {"任何品质"}
            for k, v in ipairs(tbInfo) do
                table.insert(tbList, UIHelper.GBKToUTF8(v.szName))
            end
            FilterDef.TreasureBattleFieldSkill[1].tbList = tbList
            tbInfo = Tabel_GetDesertStormSkillEffect()
            tbList = {"任何效果"}
            for k, v in ipairs(tbInfo) do
                table.insert(tbList, UIHelper.GBKToUTF8(v.szName))
            end
            FilterDef.TreasureBattleFieldSkill[2].tbList = tbList
            TipsHelper.ShowNodeHoverTipsInDir(PREFAB_ID.WidgetFiltrateTip, self.TogScreenWithLabel, TipsLayoutDir.BOTTOM_CENTER, FilterDef.TreasureBattleFieldSkill)
        end
    end)

    if Platform.IsWindows() or Platform.IsMac() then
		UIHelper.RegisterEditBoxEnded(self.WidgetEdit, function()
			local szSearch = UIHelper.GetString(self.WidgetEdit)
			self.tFilterData.szSearch = szSearch
			self:UpdateInfo()
		end)
	else
		UIHelper.RegisterEditBoxReturn(self.WidgetEdit, function()
			local szSearch = UIHelper.GetString(self.WidgetEdit)
			self.tFilterData.szSearch = szSearch
			self:UpdateInfo()
		end)
	end

    UIHelper.RegisterEditBoxChanged(self.WidgetEdit, function()
        local szSearch = UIHelper.GetString(self.WidgetEdit)
        self.tFilterData.szSearch = szSearch
        self:UpdateInfo()
    end)
end

function UITreasureBattleFieldSkillListView:RegEvent()
    Event.Reg(self, EventType.OnFilter, function(szKey, tbSelected)
        if szKey == FilterDef.TreasureBattleFieldSkill.Key then
            self.tFilterData.nQuality = tbSelected[1][1] - 1
            self.tFilterData.nEffect = tbSelected[2][1] - 1
            self:UpdateInfo()
        end
    end)

    Event.Reg(self, EventType.HideAllHoverTips, function()
        UIHelper.SetSelected(self.TogScreenWithLabel, false, false)
    end)
end

function UITreasureBattleFieldSkillListView:UnRegEvent()
    --Event.UnReg(self, EventType.XXX)
end

-- ----------------------------------------------------------
-- Please write your own code below  ↓↓↓
-- ----------------------------------------------------------

function UITreasureBattleFieldSkillListView:UpdateInfo()
    UIHelper.RemoveAllChildren(self.ScrollViewSkillList)
    local tInfo = self:GetData()
    for i = 1, #tInfo do
        local script = UIMgr.AddPrefab(PREFAB_ID.WidgetSkillCell1, self.ScrollViewSkillList)
        script:UpdateInfo(tInfo[i].dwSkillID, tInfo[i].nLevel)
        local tog = script:GetToggle()
        UIHelper.BindUIEvent(tog, EventType.OnSelectChanged, function(toggle, bSelected)
            local fnExit = function()
                UIHelper.SetSelected(tog, false)
            end
            if bSelected then
                local tips, tipsScriptView = TipsHelper.ShowNodeHoverTipsInDir(PREFAB_ID.WidgetSkillInfoTips, tog, TipsLayoutDir.LEFT_CENTER, tInfo[i].dwSkillID, nil, nil, tInfo[i].nLevel)
                tipsScriptView:BindExitFunc(fnExit)
            end
        end)
    end
    UIHelper.ScrollViewDoLayoutAndToTop(self.ScrollViewSkillList)
end

function UITreasureBattleFieldSkillListView:GetData()
    local tInfo = Tabel_GetDesertStormSkill()
    if self.tFilterData.nQuality <= 0 and self.tFilterData.nEffect <= 0 and (not self.tFilterData.szSearch) then
        return tInfo
    end
    local tRes = {}
    for i = 1, #tInfo do
        local bInsert = true
        if bInsert and self.tFilterData.nQuality > 0 and tInfo[i].nQuality ~= self.tFilterData.nQuality then
            bInsert = false
        end
        if bInsert and self.tFilterData.nEffect > 0 and tInfo[i].nEffect ~= self.tFilterData.nEffect then
            bInsert = false
        end
        if bInsert and self.tFilterData.szSearch and (not string.find(UIHelper.GBKToUTF8(tInfo[i].szName), self.tFilterData.szSearch)) then
            bInsert = false
        end
        if bInsert then
            table.insert(tRes, tInfo[i])
        end
    end
    return tRes
end


return UITreasureBattleFieldSkillListView