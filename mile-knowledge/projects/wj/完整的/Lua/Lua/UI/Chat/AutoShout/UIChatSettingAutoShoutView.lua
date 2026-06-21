-- ---------------------------------------------------------------------------------
-- Author: Unknown
-- Name: UIChatSettingAutoShoutView
-- Date: 2024-10-12 17:03:24
-- Desc: ?
-- ---------------------------------------------------------------------------------
local UIChatSettingAutoShoutView = class("UIChatSettingAutoShoutView")

function UIChatSettingAutoShoutView:OnEnter(szType, tbConf, tbSettingData, tbRuntimeMap)
    self.tbConf = tbConf
    self.tbSettingData = tbSettingData
    self.szType = szType or tbConf.tbGroupList[1].szType
    self.tbRuntimeMap = tbRuntimeMap

    if not self.bInit then
        self:RegEvent()
        self:BindUIEvent()
        self.bInit = true
    end

    self.tbRuntimeMap[szType] = tbSettingData
    self:UpdateInfo()
end

function UIChatSettingAutoShoutView:OnExit()
    self.bInit = false
    self:UnRegEvent()
end

function UIChatSettingAutoShoutView:BindUIEvent()
    UIHelper.BindUIEvent(self.BtnClose, EventType.OnClick, function()
        UIMgr.Close(self)
    end)

    UIHelper.BindUIEvent(self.BtnCancel, EventType.OnClick, function()
        UIMgr.Close(self)
    end)

    UIHelper.BindUIEvent(self.BtnSave, EventType.OnClick, function()
        self:SaveSetting()

        Event.Dispatch(EventType.OnChatAutoShoutSettingUpdate, self.tbRuntimeMap)
        UIMgr.Close(self)
    end)
end

function UIChatSettingAutoShoutView:RegEvent()
    Event.Reg(self, EventType.OnChatEmojiClosed, function()
        self:HideEmoji()
    end)

    Event.Reg(self, EventType.OnChatEmojiSelected, function(tbEmojiConf)
        self:HideEmoji()

        if not tbEmojiConf then
            return
        end

        local nID = tbEmojiConf.nID
        local szEmoji = string.format("[%s]", tbEmojiConf.szName)

        if nID == -1 then
            UIMgr.Open(VIEW_ID.PanelCollectEmoticons)
        else
            self.scriptEditbox:AddTagToEditbox(szEmoji)
        end
    end)
end

function UIChatSettingAutoShoutView:UnRegEvent()
    --Event.UnReg(self, EventType.XXX)
end






-- ----------------------------------------------------------
-- Please write your own code below  ↓↓↓
-- ----------------------------------------------------------

function UIChatSettingAutoShoutView:UpdateInfo()
    self:UpdateInfo_LeftList()
    self:UpdateInfo_RightList()
end

function UIChatSettingAutoShoutView:UpdateInfo_LeftList()
    UIHelper.RemoveAllChildren(self.ScrollViewLeftList)

    local tbGroupList = self.tbConf.tbGroupList
    local szSelectType = self.szType or tbGroupList[1].szType
    for _, tbInfo in ipairs(tbGroupList) do
        local szType = tbInfo.szType
        local script = UIHelper.AddPrefab(PREFAB_ID.WidgetShoutSettingToggle, self.ScrollViewLeftList)
        UIHelper.SetToggleGroupIndex(script._rootNode, ToggleGroupIndex.AutoShoutGroup)

        script:OnEnter(szType, tbInfo.szName, szSelectType == szType, function() self:Select(szType) end)
    end

    UIHelper.ScrollViewDoLayout(self.ScrollViewLeftList)
end

function UIChatSettingAutoShoutView:UpdateInfo_RightList()
    self:UpdateChannelList()
    self:UpdateTagList()
    self:UpdateAutoShoutInfo()

    UIHelper.CascadeDoLayoutDoWidget(self.ScrollViewRightList, true, true)
    UIHelper.ScrollViewDoLayoutAndToTop(self.ScrollViewRightList)
end

local fnApplyChannelTable = function(tbApplyList, tbChannelList, bSelected)
    for k, v in pairs(tbApplyList) do
        tbApplyList[k] = nil
    end

    if not bSelected then
        return
    end

    for index, nID in ipairs(tbChannelList) do
        if not table.contain_value(tbApplyList, nID) then
            table.insert(tbApplyList, nID)
        end
    end
end

function UIChatSettingAutoShoutView:UpdateChannelList()
    if not self.scriptContent1 then -- 发布频道
        self.scriptContent1 = UIHelper.AddPrefab(PREFAB_ID.WidgetChatShoutTittle, self.ScrollViewRightList)
        self.scriptContent1:OnInitWithTitle("发布频道", true)
        self.scriptContent1:ShowBtnEdit(false)
        self.scriptContent1:ShowBtnDes(false)
    end
    self.scriptContent1:ClearSelected()

    local bApplied = false
    local tbChannelList = ChatAutoShout.GetChannelList()
    local tbApplyChannelList = self.tbSettingData and self.tbSettingData[2] or {}
    for i = 0, #tbChannelList, 1 do
        local tbInfo = tbChannelList[i]
        local tbChannelID = tbInfo.tbChannelID
        local scriptCell = self.scriptContent1:AddTag(i)
        self:InitChannelCell(i, tbInfo, scriptCell, function (bSelected)
            local tbScript = self.scriptContent1:GetTagScriptList()
            fnApplyChannelTable(tbApplyChannelList, tbChannelID, bSelected)

            for index, tog in pairs(tbScript) do
                tog:SetSelected(index == i, false)
            end
            Timer.AddFrame(self, 1, function()
                tbScript[0]:SetSelected(table.is_empty(tbApplyChannelList), false)
            end)
        end)

        for _, nID in ipairs(tbChannelID) do
            if table.contain_value(tbApplyChannelList, nID) then
                bApplied = true
                scriptCell:SetSelected(true, false)
                break
            end
        end
    end

    if table.is_empty(self.tbSettingData[2]) then
        local tbScript = self.scriptContent1:GetTagScriptList()
        tbScript[0]:SetSelected(not bApplied, false)
    end
end

function UIChatSettingAutoShoutView:UpdateTagList()
    if not self.scriptContent2 then -- 常用标签
        self.scriptContent2 = UIHelper.AddPrefab(PREFAB_ID.WidgetChatShoutTittle, self.ScrollViewRightList)
        self.scriptContent2:OnInitWithTitle("常用", true)
        self.scriptContent2:ShowBtnEdit(false)
        self.scriptContent2:ShowBtnDes(true)
    end

    local tbTagList = ChatAutoShout.GetTagList(self.szType)
    for nIndex, szTitle in pairs(tbTagList) do
        local scriptCell = self.scriptContent2:AddTag(nIndex)
        szTitle = "@"..szTitle
        self:InitTagCell(nIndex, szTitle, scriptCell, function ()
            self.scriptEditbox:AddTagToEditbox(szTitle)
        end)
    end
end

function UIChatSettingAutoShoutView:UpdateAutoShoutInfo()
    if not self.scriptContent3 then -- 喊话内容
        self.scriptContent3 = UIHelper.AddPrefab(PREFAB_ID.WidgetChatShoutTittle, self.ScrollViewRightList)
        self.scriptContent3:OnInitWithTitle("喊话内容", false)
        self.scriptContent3:ShowBtnEdit(false)
        self.scriptContent3:ShowBtnDes(false)
    end

    if not self.scriptEditbox then
        self.scriptEditbox = self.scriptContent3:AddAutoShoutEditbox()
        self.scriptEditbox:OnEnter()
        UIHelper.BindUIEvent(self.scriptEditbox.BtnEmoji, EventType.OnClick, function()
            self:ShowEmoji()
        end)
    end

    if self.szType == UI_Chat_Setting_Type.Auto_Tong then
        self.scriptContent3:OnInitWithTitle("喊话内容"..g_tStrings.CHAT_SETTING_AUTO_SHOUT_TONG_TIPS, false)
    elseif self.szType == UI_Chat_Setting_Type.Auto_Party then
        self.scriptContent3:OnInitWithTitle("喊话内容"..g_tStrings.CHAT_SETTING_AUTO_SHOUT_PARTY_TIPS, false)
    else
        self.scriptContent3:OnInitWithTitle("喊话内容", false)
    end

    local tbDefaultData = self:GetDefaultData(self.szType)
    local szDefaultText = tbDefaultData.szDefaultText
    local szEditText = ""
    if self.tbSettingData and self.tbSettingData[1] then
        szEditText = self.tbSettingData[1]
    end
    self.scriptEditbox:SetCurGroupType(self.szType)
    self.scriptEditbox:SetPlaceHolder(szDefaultText)
    self.scriptEditbox:SetEditBox(szEditText)
end

function UIChatSettingAutoShoutView:InitChannelCell(nIndex, tbInfo, scriptCell, fnOnSelectChanged)
    local szTitle = tbInfo.szTitle
    scriptCell:OnEnter(true, true)
    scriptCell:SetTitle(szTitle)
    scriptCell:BindOnSelectChanged(fnOnSelectChanged)
end

function UIChatSettingAutoShoutView:InitTagCell(nIndex, szTitle, scriptCell, fnOnSelectChanged)
    scriptCell:OnEnter(false)
    scriptCell:SetTitle(szTitle)
    scriptCell:BindOnSelectChanged(fnOnSelectChanged)
end

function UIChatSettingAutoShoutView:Select(szType)
    -- 储存当前分页的数据，切页时还原
    self:SaveSetting()
    local tbOneConf = self.tbRuntimeMap[szType] or Lib.copyTab(Storage.Chat_AutoShout[szType])

    self.tbSettingData = tbOneConf
    self.szType = szType

    self:UpdateInfo_RightList()
end

function UIChatSettingAutoShoutView:SaveSetting()
    if not self.scriptEditbox then
        return
    end

    self.tbSettingData[1] = self.scriptEditbox:GetEditBox()
    self.tbRuntimeMap[self.szType] = self.tbSettingData
end

-- 聊天表情
function UIChatSettingAutoShoutView:ShowEmoji()
    if not self.scriptEmoji then
        self.scriptEmoji = UIHelper.AddPrefab(PREFAB_ID.WidgetChatExpression, self.WidgetChatExpression)
    else
        if self.scriptEmoji.nCurGroupID == -1 then
            self.scriptEmoji:UpdateInfo_EmojiList()
        end
    end

    UIHelper.SetVisible(self.WidgetChatExpression, true)
end

function UIChatSettingAutoShoutView:HideEmoji()
    UIHelper.SetVisible(self.WidgetChatExpression, false)
end

function UIChatSettingAutoShoutView:GetDefaultData(szType)
    if not self.tbConf or not self.tbConf.tbGroupList then
        return {}
    end

    for index, tbGroup in ipairs(self.tbConf.tbGroupList) do
        if tbGroup.szType == szType then
            return tbGroup
        end
    end
    return {}
end

return UIChatSettingAutoShoutView