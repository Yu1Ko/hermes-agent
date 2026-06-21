-- ---------------------------------------------------------------------------------
-- Author: Unknown
-- Name: UISkillShoutSettingView
-- Date: 2025-03-04 16:40:56
-- Desc: ?
-- ---------------------------------------------------------------------------------

local UISkillShoutSettingView = class("UISkillShoutSettingView")

function UISkillShoutSettingView:OnEnter(nSelectSkill, tbNewList)
    if not self.bInit then
        self:RegEvent()
        self:BindUIEvent()
        self.bInit = true
    end
    self.nSelectType = 1
    self.szSearchSkill = ""
    self.nSelectSkill = nSelectSkill or 1
    self.tbNewList = tbNewList
    self:InitRuntimeMap()
    self:UpdateInfo()
end

function UISkillShoutSettingView:OnExit()
    self.bInit = false
    self:UnRegEvent()
end

function UISkillShoutSettingView:BindUIEvent()
    UIHelper.BindUIEvent(self.BtnClose, EventType.OnClick, function(btn)
        self:OnClose()
    end)

    UIHelper.BindUIEvent(self.BtnSave, EventType.OnClick, function(btn)
        ChatAutoShout.SaveSkillShout("tbSkillList", self.tbSkillList)
        self:UpdateShoutTypeList()
        TipsHelper.ShowNormalTip("保存成功")
    end)

    UIHelper.BindUIEvent(self.BtnDelete, EventType.OnClick, function(btn)
        self:OnChangeSkillList(false)
    end)

    UIHelper.BindUIEvent(self.BtnAddNew_Skill, EventType.OnClick, function(btn)
        -- self:OnChangeSkillList(true, VIEW_ID.PanelSkillList)
        local tbBtnParams = {
            {
                szName = "旗舰",
                OnClick = function ()
                    self:OnChangeSkillList(true, VIEW_ID.PanelSkillList, true)
                end
            },
            {
                szName = "无界",
                OnClick = function()
                    self:OnChangeSkillList(true, VIEW_ID.PanelSkillList, false)
                end
            },
        }
        local nSizeW,nSizeH = UIHelper.GetContentSize(self.BtnAddNew_Skill)
        APIHelper.ShowMoreOperTips(self.BtnAddNew_Skill, tbBtnParams, -nSizeW/2, 300)
    end)

    UIHelper.BindUIEvent(self.BtnAddNew_PrintName, EventType.OnClick, function(btn)
        self:OnChangeSkillList(true, VIEW_ID.PanelCreateSkillShoutName)
    end)
end

function UISkillShoutSettingView:RegEvent()
    Event.Reg(self, EventType.OnTouchViewBackGround, function(script)
        if script == self then
            self:OnClose()
        end
    end)

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
            self:EditBoxCallBack()
        end
    end)

    if Platform.IsWindows() or Platform.IsMac() then
        UIHelper.RegisterEditBoxEnded(self.EditKindSearch, function()
            local szSkill = UIHelper.GetText(self.EditKindSearch)
            self.nSelectSkill = 1
            self.szSearchSkill = szSkill
            self:UpdateInfo()
            UIHelper.ScrollViewDoLayoutAndToTop(self.ScrollViewLeftList)
        end)
    else
        UIHelper.RegisterEditBoxReturn(self.EditKindSearch, function()
            local szSkill = UIHelper.GetText(self.EditKindSearch)
            self.nSelectSkill = 1
            self.szSearchSkill = szSkill
            self:UpdateInfo()
            UIHelper.ScrollViewDoLayoutAndToTop(self.ScrollViewLeftList)
        end)
    end
end

function UISkillShoutSettingView:UnRegEvent()
    --Event.UnReg(self, EventType.XXX)
end






-- ----------------------------------------------------------
-- Please write your own code below  ↓↓↓
-- ----------------------------------------------------------
function UISkillShoutSettingView:InitRuntimeMap()
    self.tbSkillList = clone(Storage.Chat_SkillShout.tbSkillList)
end

function UISkillShoutSettingView:UpdateInfo()
    self:UpdateInfo_LeftList()
end

function UISkillShoutSettingView:UpdateInfo_LeftList()
    UIHelper.RemoveAllChildren(self.ScrollViewLeftList)

    local nCount = 1
    for nIndex, tbInfo in pairs(self.tbSkillList) do
        local bSelectFirst = false
        local bShow = true
        local bNew = self.tbNewList and self.tbNewList[tbInfo.szSkillName] or false
        if not string.is_nil(self.szSearchSkill) then
            bSelectFirst = true
            bShow = string.find(tbInfo.szSkillName, self.szSearchSkill) and true or false
        end

        if bShow then
            local szTitle = UIHelper.LimitUtf8Len(tbInfo.szSkillName, 5)
            local script = UIHelper.AddPrefab(PREFAB_ID.WidgetShoutSettingToggle, self.ScrollViewLeftList)
            local bSelected = bSelectFirst and (nCount == 1) or (nIndex == self.nSelectSkill)
            script:OnEnter(nIndex, szTitle, bSelected, function() self:Select(nIndex) end)
            script:SetNew(bNew)
            nCount = nCount + 1
        end
    end

    UIHelper.SetVisible(self.BtnDelete, nCount > 1)
    UIHelper.SetVisible(self.WidgetRight, nCount > 1)
    UIHelper.SetVisible(self.WidgetEmpty, nCount <= 1)

    UIHelper.LayoutDoLayout(self.LayoutBtns)
    UIHelper.ScrollViewDoLayout(self.ScrollViewLeftList)
    UIHelper.ScrollViewSetupArrow(self.ScrollViewLeftList, self.WidgetArrowDown_L)
    if self.nSelectSkill >= 1 then
        Timer.AddFrame(self, 1, function ()
            UIHelper.ScrollToIndex(self.ScrollViewLeftList, self.nSelectSkill - 1, 0.1, true)
        end)
    end
end

function UISkillShoutSettingView:UpdateInfo_Group()
    local tbSkillData = self:GetSkillData(self.nSelectSkill)
    local szTitle = "技能名："..tbSkillData.szSkillName
    UIHelper.SetString(self.LabelSkillName, szTitle)

    self:UpdateShoutTypeList()
    self:UpdateTagList()
    self:UpdateAutoShoutInfo()

    UIHelper.CascadeDoLayoutDoWidget(self.ScrollViewRightList, true, true)
    UIHelper.ScrollViewDoLayoutAndToTop(self.ScrollViewRightList)
    UIHelper.ScrollViewSetupArrow(self.ScrollViewRightList, self.WidgetArrowDown_R)
end

function UISkillShoutSettingView:UpdateShoutTypeList()
    local tbSkillData = self:GetSkillData(self.nSelectSkill)
    for nIndex, tog in ipairs(self.tbSkillTypeToggle) do
        local bEquipText = false
        local imgEquip = self.tbTypeEquipImg[nIndex]
        if tbSkillData and tbSkillData[nIndex - 1] then
            bEquipText = true
        end
        UIHelper.SetVisible(imgEquip, bEquipText)
        UIHelper.SetSelected(tog, (nIndex - 1) == self.nSelectType, false)
        UIHelper.SetToggleGroupIndex(tog, ToggleGroupIndex.SkillShoutType)

        UIHelper.BindUIEvent(tog, EventType.OnClick, function ()
            self.nSelectType = nIndex - 1
            self:UpdateShoutTypeList()
            self:UpdateAutoShoutInfo()
            UIHelper.ScrollViewDoLayoutAndToTop(self.ScrollViewRightList)

            for i, v in ipairs(self.tbSkillTypeToggle) do
                UIHelper.SetSelected(v, (i - 1) == self.nSelectType, false)
            end
        end)
    end
end

function UISkillShoutSettingView:UpdateTagList()
    if not self.scriptContent2 then -- 常用标签
        self.scriptContent2 = UIHelper.AddPrefab(PREFAB_ID.WidgetChatShoutTittle, self.ScrollViewRightList)
        self.scriptContent2:OnInitWithTitle("常用", true)
        self.scriptContent2:ShowBtnEdit(false)
        self.scriptContent2:ShowBtnDes(true)
    end

    local tbTagList = ChatAutoShout.GetTagList(UI_Chat_Setting_Type.Auto_Skill)
    for nIndex, szTitle in pairs(tbTagList) do
        local scriptCell = self.scriptContent2:AddTag(nIndex)
        szTitle = "@"..szTitle
        self:InitTagCell(nIndex, szTitle, scriptCell, function ()
            self.scriptEditbox:AddTagToEditbox(szTitle)
            self:EditBoxCallBack()
        end)
    end
end

function UISkillShoutSettingView:UpdateAutoShoutInfo()
    if not self.scriptContent3 then -- 喊话内容
        self.scriptContent3 = UIHelper.AddPrefab(PREFAB_ID.WidgetChatShoutTittle, self.ScrollViewRightList)
        self.scriptContent3:OnInitWithTitle("喊话内容", false)
        self.scriptContent3:ShowBtnEdit(false)
        self.scriptContent3:ShowBtnDes(false)
    end

    if not self.scriptEditbox then
        self.scriptEditbox = self.scriptContent3:AddAutoShoutEditbox()
        self.scriptEditbox:OnEnter()
        self.scriptEditbox:SetOverflow(LabelOverflow.RESIZE_HEIGHT)
        self.scriptEditbox:SetHorizontalAlignment(TextHAlignment.CENTER)
        self.scriptEditbox:SetPlaceHolder(g_tStrings.CHAT_SETTING_SKILL_SHOUT_PLACEHOLDER)
        self.scriptEditbox:RegisterEditBox(function()
            self:EditBoxCallBack()
            self.scriptEditbox:UpdateLimitInfo()
        end)
        UIHelper.BindUIEvent(self.scriptEditbox.BtnEmoji, EventType.OnClick, function()
            self:ShowEmoji()
        end)
    end

    local tbSkillData = self:GetSkillData(self.nSelectSkill)
    local szEditText = ""
    if tbSkillData and tbSkillData[self.nSelectType] then
        szEditText = tbSkillData[self.nSelectType]
    end
    self.scriptEditbox:SetEditBox(szEditText)
end

function UISkillShoutSettingView:EditBoxCallBack()
    if not self.tbSkillList[self.nSelectSkill] then
        return
    end

    if not self.nSelectType then
        self.scriptEditbox:SetEditBox("")
        TipsHelper.ShowNormalTip("请先选择类型")
        return
    end

    local szText = self.scriptEditbox:GetEditBox()
    if string.is_nil(szText) then
        szText = nil
    end

    self.tbSkillList[self.nSelectSkill][self.nSelectType] = szText
end

function UISkillShoutSettingView:InitTypeCell(nIndex, szTitle, scriptCell, fnOnSelectChanged)
    scriptCell:OnEnter(true, true)
    scriptCell:SetTitle(szTitle)
    scriptCell:BindOnSelectChanged(fnOnSelectChanged)
end

function UISkillShoutSettingView:InitTagCell(nIndex, szTitle, scriptCell, fnOnSelectChanged)
    scriptCell:OnEnter(false)
    scriptCell:SetTitle(szTitle)
    scriptCell:BindOnSelectChanged(fnOnSelectChanged)
end

function UISkillShoutSettingView:UpdateArrow()
    local nPercent = UIHelper.GetScrollPercent(self.ScrollViewLeftList)
    local nHeight = UIHelper.GetHeight(self.ScrollViewLeftList)
    local bShow = nPercent <= 90
    local tbSize = self.ScrollViewLeftList:getInnerContainerSize()
    UIHelper.SetVisible(self.widgetArrowDown, bShow and tbSize.height > nHeight)
end

-- 聊天表情
function UISkillShoutSettingView:ShowEmoji()
    if not self.nSelectType then
        TipsHelper.ShowNormalTip("请先选择类型")
        return
    end

    if not self.scriptEmoji then
        self.scriptEmoji = UIHelper.AddPrefab(PREFAB_ID.WidgetChatExpression, self.WidgetChatExpression)
    else
        if self.scriptEmoji.nCurGroupID == -1 then
            self.scriptEmoji:UpdateInfo_EmojiList()
        end
    end

    UIHelper.SetVisible(self.WidgetChatExpression, true)
end

function UISkillShoutSettingView:HideEmoji()
    UIHelper.SetVisible(self.WidgetChatExpression, false)
end

function UISkillShoutSettingView:Select(nIndex)
    self.nSelectSkill = nIndex
    self:UpdateInfo_Group()
end

function UISkillShoutSettingView:GetSkillData(nIndex)
    local tbData = self.tbSkillList[nIndex]
    return tbData
end

function UISkillShoutSettingView:Save()
    ChatAutoShout.SaveSkillShout("tbSkillList", self.tbSkillList)
end

function UISkillShoutSettingView:Delete()
    local tbInfo = {}
    for nIndex, value in ipairs(self.tbSkillList) do
        if nIndex ~= self.nSelectSkill then
            table.insert(tbInfo, value)
        end
    end

    self.nSelectSkill = math.max(self.nSelectSkill - 1, 1)
    self.tbSkillList = tbInfo
    self:UpdateInfo()
end

function UISkillShoutSettingView:CheckHaveChange()
    local bHaveChange = false
    if not table.deepCompare(Storage.Chat_SkillShout.tbSkillList, self.tbSkillList)
        or not table.deepCompare(self.tbSkillList, Storage.Chat_SkillShout.tbSkillList) then
        bHaveChange = true
    end

    return bHaveChange
end

function UISkillShoutSettingView:OnClose()
    local funcConfirm = function()
        ChatAutoShout.SaveSkillShout("tbSkillList", self.tbSkillList)
        UIMgr.Close(self)
    end

    local funcCancel = function()
        UIMgr.Close(self)
    end

    if self:CheckHaveChange() then
        local scriptTips = UIHelper.ShowConfirm("当前内容发生修改，是否保存并退出？", funcConfirm, funcCancel)
        scriptTips:SetCancelButtonContent("取消并退出")
        scriptTips:SetConfirmButtonContent("保存")
        return
    end
    UIMgr.Close(self)
end

function UISkillShoutSettingView:TryDeleteSkill()
    local tbSkill = self:GetSkillData(self.nSelectSkill)
    if not tbSkill then
        return
    end
    local szSkillName = tbSkill.szSkillName
    local szContent = string.format("是否删除【%s】的技能喊话？", szSkillName)

    UIHelper.ShowConfirm(szContent, function()
        self:Delete()
    end)
end

function UISkillShoutSettingView:OnChangeSkillList(bAdd, nViewID, bDxSkill)
    local funcConfirm = function()
        ChatAutoShout.SaveSkillShout("tbSkillList", self.tbSkillList)
        if bAdd then
            if bDxSkill ~= nil then
                UIMgr.Open(nViewID, bDxSkill)
            else
                UIMgr.Open(nViewID)
            end
        else
            self:TryDeleteSkill()
        end
    end

    if self:CheckHaveChange() then
        local scriptTips = UIHelper.ShowConfirm("当前内容发生修改，是否保存？", funcConfirm)
        scriptTips:SetConfirmButtonContent("保存")
        return
    end
    funcConfirm()
end

return UISkillShoutSettingView