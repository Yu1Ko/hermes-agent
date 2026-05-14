-- ---------------------------------------------------------------------------------
-- Author: Unknown
-- Name: UIChatSettingAutoShoutTiltle
-- Date: 2024-10-12 11:19:49
-- Desc: ?
-- ---------------------------------------------------------------------------------
local CONTENT_TYPE = {
    SHOUT = 1,
    CHANNEL = 2,
}
local UIChatSettingAutoShoutTiltle = class("UIChatSettingAutoShoutTiltle")

function UIChatSettingAutoShoutTiltle:OnInitWithTitle(szTitle, bTagList, bSkillList)
    self.szTitle = szTitle

    if not self.bInit then
        self:RegEvent()
        self:BindUIEvent()
        self.bInit = true
    end
    self.bSkillList = bSkillList
    UIHelper.SetVisible(self.LayoutShoutContent, not bTagList and not bSkillList)
    UIHelper.SetVisible(self.LayoutShoutSetting, bTagList and not bSkillList)
    UIHelper.SetVisible(self.ScrollViewCell, bSkillList)
    UIHelper.SetString(self.LabelTitle, szTitle)
end

function UIChatSettingAutoShoutTiltle:OnEnter_Other(szType, tbConf, tbGroupConf, tbSettingData, bEditMode)
    self.szType = szType
    self.tbConf = tbConf
    self.tbGroupConf = tbGroupConf
    self.tbSettingData = tbSettingData
    self.bEditMode = bEditMode or false

    if not self.bInit then
        self:RegEvent()
        self:BindUIEvent()
        self.bInit = true
    end

    self:UpdateInfo()
end

function UIChatSettingAutoShoutTiltle:OnEnter_Death(szType, tbConf, tbGroupConf, tbSettingData, bEditMode)
    self.szType = szType
    self.tbConf = tbConf
    self.tbGroupConf = tbGroupConf
    self.tbSettingData = tbSettingData
    self.bEditMode = bEditMode or false

    if not self.bInit then
        self:RegEvent()
        self:BindUIEvent()
        self.bInit = true
    end

    self:UpdateInfo()
end

function UIChatSettingAutoShoutTiltle:OnEnter_Skill(szType, tbConf, tbGroupConf, tbSettingData, bEditMode)
    self.szType = szType
    self.tbConf = tbConf
    self.tbGroupConf = tbGroupConf
    self.tbSettingData = tbSettingData
    self.bEditMode = bEditMode or false

    if not self.bInit then
        self:RegEvent()
        self:BindUIEvent()
        self.bInit = true
    end

    self:UpdateInfo()
end

function UIChatSettingAutoShoutTiltle:OnExit()
    self.bInit = false
    self:UnRegEvent()
end

function UIChatSettingAutoShoutTiltle:BindUIEvent()
    UIHelper.SetSwallowTouches(self.ScrollViewCell, true)

    UIHelper.BindUIEvent(self.BtnEdit, EventType.OnClick, function()
        Event.Dispatch(EventType.OpenAutoShoutSettingView, self.szType)
    end)

    UIHelper.BindUIEvent(self.BtnDes, EventType.OnClick, function()
        TipsHelper.ShowNodeHoverTips(PREFAB_ID.WidgetPublicLabelTips, self.BtnDes, g_tStrings.CHAT_SETTING_AUTO_SHOUT_TAG_TIPS)
    end)
end

function UIChatSettingAutoShoutTiltle:RegEvent()
    --Event.Reg(self, EventType.XXX, func)
end

function UIChatSettingAutoShoutTiltle:UnRegEvent()
    --Event.UnReg(self, EventType.XXX)
end






-- ----------------------------------------------------------
-- Please write your own code below  ↓↓↓
-- ----------------------------------------------------------

function UIChatSettingAutoShoutTiltle:UpdateInfo()
    self:UpdateTitle()
    self:UpdateAutoShoutInfo()
end

function UIChatSettingAutoShoutTiltle:UpdateTitle()
    UIHelper.SetVisible(self.BtnDes, self.bEditMode)
    UIHelper.SetVisible(self.BtnEdit, not self.bEditMode)

    local szTitle = self.tbGroupConf.szName
    if self.tbGroupConf and self.tbGroupConf.szType == UI_Chat_Setting_Type.Auto_Tong then
        szTitle = szTitle..g_tStrings.CHAT_SETTING_AUTO_SHOUT_TONG_TIPS
    elseif self.tbGroupConf and self.tbGroupConf.szType == UI_Chat_Setting_Type.Auto_Party then
        szTitle = szTitle..g_tStrings.CHAT_SETTING_AUTO_SHOUT_PARTY_TIPS
    end
    UIHelper.SetString(self.LabelTitle, szTitle)
end

function UIChatSettingAutoShoutTiltle:UpdateAutoShoutInfo()
    local nPrefabID = self.bEditMode and PREFAB_ID.WidgetEditShoutContent or PREFAB_ID.WidgetSoutContent
    if not self.scriptContent1 then -- 喊话内容
        self.scriptContent1 = UIHelper.AddPrefab(nPrefabID, self.LayoutShoutContent)
    end

    if not self.scriptContent2 then -- 发布频道
        self.scriptContent2 = UIHelper.AddPrefab(nPrefabID, self.LayoutShoutContent)
    end

    self.scriptContent1:OnEnter(CONTENT_TYPE.SHOUT, self.tbSettingData)
    self.scriptContent2:OnEnter(CONTENT_TYPE.CHANNEL, self.tbSettingData)

    UIHelper.LayoutDoLayout(self.LayoutShoutContent)
    UIHelper.LayoutDoLayout(self._rootNode)
end

function UIChatSettingAutoShoutTiltle:AddAutoShoutEditbox()
    self.scriptEditbox = self.scriptEditbox or UIHelper.AddPrefab(PREFAB_ID.WidgetEditShoutContent, self.LayoutShoutContent)

    UIHelper.LayoutDoLayout(self.LayoutShoutContent)
    UIHelper.LayoutDoLayout(self._rootNode)
    return self.scriptEditbox
end

function UIChatSettingAutoShoutTiltle:AddTag(nIndex)
    self.tbTagScriptList = self.tbTagScriptList or {}

    if self.tbTagScriptList[nIndex] then
        return self.tbTagScriptList[nIndex]
    end

    local nodeParent = self.bSkillList and self.ScrollViewCell or self.LayoutShoutSetting
    local scriptCell = UIHelper.AddPrefab(PREFAB_ID.WidgetShoutSettingGroupOption, nodeParent)
    self.tbTagScriptList[nIndex] = scriptCell

    UIHelper.LayoutDoLayout(self.LayoutShoutSetting)
    UIHelper.ScrollViewDoLayoutAndToTop(self.ScrollViewCell)
    UIHelper.LayoutDoLayout(self._rootNode)
    return self.tbTagScriptList[nIndex]
end

function UIChatSettingAutoShoutTiltle:AddNewBtn(nIndex, fnOnClick)
    self.tbTagScriptList = self.tbTagScriptList or {}

    if self.tbTagScriptList[nIndex] then
        return self.tbTagScriptList[nIndex]
    end

    local nodeParent = self.bSkillList and self.ScrollViewCell or self.LayoutShoutSetting
    local scriptCell = UIHelper.AddPrefab(PREFAB_ID.WidgetSkillShout_AddNew, nodeParent, fnOnClick)
    self.tbTagScriptList[nIndex] = scriptCell

    UIHelper.LayoutDoLayout(self.LayoutShoutSetting)
    UIHelper.ScrollViewDoLayoutAndToTop(self.ScrollViewCell)
    UIHelper.LayoutDoLayout(self._rootNode)
    return self.tbTagScriptList[nIndex]
end

function UIChatSettingAutoShoutTiltle:ClearSelected()
    if self.tbTagScriptList then
        for k, cell in pairs(self.tbTagScriptList) do
            cell:SetSelected(false, false)
        end
    end
end

function UIChatSettingAutoShoutTiltle:ShowBtnEdit(bShow)
    UIHelper.SetVisible(self.BtnEdit, bShow)
end

function UIChatSettingAutoShoutTiltle:ShowBtnDes(bShow)
    UIHelper.SetVisible(self.BtnDes, bShow)
end

function UIChatSettingAutoShoutTiltle:ShowBtnSetting(bShow)
    UIHelper.SetVisible(self.BtnSetting, bShow)
end

function UIChatSettingAutoShoutTiltle:GetTagScriptList()
    return self.tbTagScriptList
end

return UIChatSettingAutoShoutTiltle