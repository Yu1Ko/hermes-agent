-- ---------------------------------------------------------------------------------
-- Author: Unknown
-- Name: UIChatSettingGroup
-- Date: 2022-12-13 19:41:26
-- Desc: ?
-- ---------------------------------------------------------------------------------

local UIChatSettingGroup = class("UIChatSettingGroup")

function UIChatSettingGroup:OnEnter(nIndex, tbConf, tbGroupConf, tbSettingData)
    self.nIndex = nIndex
    self.tbConf = tbConf
    self.tbGroupConf = tbGroupConf
    self.tbSettingData = tbSettingData

    self.nMinSelect = self.tbGroupConf.tbSelectedCount and self.tbGroupConf.tbSelectedCount[1] or -1
    self.nMaxSelect = self.tbGroupConf.tbSelectedCount and self.tbGroupConf.tbSelectedCount[2] or -1

    self.tbScriptList = {}

    if not self.bInit then
        self:RegEvent()
        self:BindUIEvent()
        self.bInit = true
    end

    self:UpdateInfo()
end

function UIChatSettingGroup:OnExit()
    self.bInit = false
    self:UnRegEvent()
end

function UIChatSettingGroup:BindUIEvent()
    UIHelper.BindUIEvent(self.TogTitle, EventType.OnSelectChanged, function(btn, bSelected)
        for k, v in ipairs(self.tbScriptList) do
            v:SetSelected(bSelected)
        end
    end)
end

function UIChatSettingGroup:RegEvent()
    Event.Reg(self, EventType.OnChatSettingChanged, function(szUIChannel, szGroupName, tbChannelID, szChannelName, bSelected)
        if szUIChannel == self.tbConf.szUIChannel then
            if szGroupName == self.tbGroupConf.szType then
                local bIsAllSelected = self:IsAllSelected()
                UIHelper.SetSelected(self.TogTitle, bIsAllSelected, false)
            end
        end
    end)
end

function UIChatSettingGroup:UnRegEvent()
    --Event.UnReg(self, EventType.XXX)
end






-- ----------------------------------------------------------
-- Please write your own code below  ↓↓↓
-- ----------------------------------------------------------

function UIChatSettingGroup:UpdateInfo()
    -- 标题
    UIHelper.SetVisible(self.TogTitle, self.tbGroupConf.bCanSelectAll)
    UIHelper.SetString(self.LabelTitle, self.tbGroupConf.szName)
    UIHelper.LayoutDoLayout(self.LayoutTitle)

    -- 选项
    self.tbScriptList = {}
    for k, tbOneChannel in ipairs(self.tbGroupConf.tbChannelList) do
        local szName = tbOneChannel.szName
        local bUnCheckAble = tbOneChannel.bUnCheckAble
        local script = UIHelper.AddPrefab(PREFAB_ID.WidgetChatSettingGroupOption, self.LayoutOptions)
        local bSelected = self.tbSettingData[szName]
        script:OnEnter(self.nIndex, self.tbConf.szUIChannel, self.tbGroupConf.szType, self.nMinSelect, self.nMaxSelect,
                        bUnCheckAble, szName, bSelected, tbOneChannel,
                    function() return self:SelectCheck() end, function() return self:UnSelectCheck() end)

        table.insert(self.tbScriptList, script)
    end

    UIHelper.LayoutDoLayout(self.LayoutOptions)
    UIHelper.LayoutDoLayout(self.WidgetChatSettingGroup)
end

function UIChatSettingGroup:IsAllSelected()
    local bResult = true
    for k, v in ipairs(self.tbScriptList) do
        if not v:IsSelected() then
            bResult = false
            break
        end
    end
    return bResult
end

function UIChatSettingGroup:UnSelectCheck()
    local bResult = true

    if self.nMinSelect > 0 then
        local nSelected = 0
        for k, v in ipairs(self.tbScriptList) do
            if v:IsSelected() then
                nSelected = nSelected + 1
            end
        end
        if nSelected < self.nMinSelect then
            bResult = false
            TipsHelper.ShowNormalTip(string.format("至少要选择%s项", g_tStrings.STR_NUMBER[self.nMinSelect]))
        end
    end

    return bResult
end

function UIChatSettingGroup:SelectCheck()
    local bResult = true

    if self.nMaxSelect > 0 then
        local nSelected = 0
        local onlyOne = nil
        for k, v in ipairs(self.tbScriptList) do
            if v:IsSelected() then
                nSelected = nSelected + 1

                if onlyOne == nil and self.nMaxSelect == 1 then
                    onlyOne = v
                end
            end
        end

        if onlyOne then
            onlyOne:SetSelected(false)
        else
            if nSelected > self.nMaxSelect then
                bResult = false
                TipsHelper.ShowNormalTip(string.format("最多可选择%s项", g_tStrings.STR_NUMBER[self.nMaxSelect]))
            end
        end
    end

    return bResult
end


return UIChatSettingGroup