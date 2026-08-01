-- ---------------------------------------------------------------------------------
-- Author: huqing
-- Name: UIWordBlockEditView
-- Date: 2024-09-06 11:11:01
-- Desc: ?
-- ---------------------------------------------------------------------------------

local UIWordBlockEditView = class("UIWordBlockEditView")

function UIWordBlockEditView:OnEnter(tbWordData)
    -- tbWordData = {
	-- 	szWord = "屏蔽文字1",
	-- 	tbChatKeyList = {"Near", "Map", "Team"},
	-- 	bRecruitBlock = false,
	-- }
    self.tbWordData = Lib.copyTab(tbWordData) -- 拷贝一份出来，避免污染原有数据
    self.bAdd = tbWordData == nil

    if tbWordData == nil then
        local tbChatKeyList = {}
        for k, v in ipairs(WordBlockMgr.GetChatBlockCfgList()) do
            if v.bDefaultSelect then
                table.insert(tbChatKeyList, v.szKey)
            end
        end

        self.tbWordData =
        {
            szWord = "",
            tbChatKeyList = tbChatKeyList,
            bRecruitBlock = false,
        }
    end

    if not self.bInit then
        self:RegEvent()
        self:BindUIEvent()
        self.bInit = true
    end

    self:UpdateInfo()
end

function UIWordBlockEditView:OnExit()
    self.bInit = false
    self:UnRegEvent()
end

function UIWordBlockEditView:BindUIEvent()
    UIHelper.BindUIEvent(self.BtnClose, EventType.OnClick, function()
        UIMgr.Close(self)
    end)

    UIHelper.BindUIEvent(self.BtnDel, EventType.OnClick, function()
        if not self:CheckWord() then return end

        local bResult = WordBlockMgr.SetStorageByWord(self.tbWordData.szWord, nil)
        if bResult then
            Event.Dispatch(EventType.OnWordBlockChanged)
            TipsHelper.ShowNormalTip("删除关键词成功")
            UIMgr.Close(self)
        end
    end)

    UIHelper.BindUIEvent(self.BtnSave, EventType.OnClick, function()
        if not self:CheckWord() then return end

        local szTips = "添加关键词成功"

        -- 如果原来就已经有了
        local tbStorage = WordBlockMgr.GetStorageByWord(self.tbWordData.szWord)
        if tbStorage then
            TipsHelper.ShowNormalTip("该关键词已存在")
            return
        end

        local bResult = WordBlockMgr.SetStorageByWord(self.tbWordData.szWord, self.tbWordData)
        if bResult then
            Event.Dispatch(EventType.OnWordBlockChanged)
            TipsHelper.ShowNormalTip(szTips)
            UIMgr.Close(self)
        end
    end)

    UIHelper.BindUIEvent(self.BtnChange, EventType.OnClick, function()
        if not self:CheckWord() then return end

        local szTips = "修改关键词成功"

        -- 如果原来没有
        local tbStorage = WordBlockMgr.GetStorageByWord(self.tbWordData.szWord)
        if not tbStorage then
            szTips = "修改的关键词不存在，已为您添加新关键词"
        end

        local bResult = WordBlockMgr.SetStorageByWord(self.tbWordData.szWord, self.tbWordData)
        if bResult then
            Event.Dispatch(EventType.OnWordBlockChanged)
            TipsHelper.ShowNormalTip(szTips)
            UIMgr.Close(self)
        end
    end)
end

function UIWordBlockEditView:RegEvent()
    UIHelper.RegisterEditBoxEnded(self.EditBoxSearch, function()
        local szWord = string.trim(UIHelper.GetString(self.EditBoxSearch), " ")
        self.tbWordData.szWord = szWord
    end)
end

function UIWordBlockEditView:UnRegEvent()
    --Event.UnReg(self, EventType.XXX)
end






-- ----------------------------------------------------------
-- Please write your own code below  ↓↓↓
-- ----------------------------------------------------------

function UIWordBlockEditView:UpdateInfo()
    -- 标题
    UIHelper.SetString(self.LabelTitle, self.bAdd and "添加屏蔽关键词" or "编辑屏蔽关键词")

    -- 按钮
    UIHelper.SetVisible(self.BtnSave, self.bAdd)
    UIHelper.SetVisible(self.BtnDel, not self.bAdd)
    UIHelper.SetVisible(self.BtnChange, not self.bAdd)

    -- 输入框
    local nMaxWordLen = WordBlockMgr.GetMaxWordLen()
    UIHelper.SetMaxLength(self.EditBoxSearch, nMaxWordLen)
    UIHelper.SetEnable(self.EditBoxSearch, self.bAdd)
    if self.bAdd then
        UIHelper.SetText(self.EditBoxSearch, "")
        UIHelper.SetPlaceHolder(self.EditBoxSearch, string.format("请输入屏蔽关键词（1-%d个字）", nMaxWordLen))
    else
        UIHelper.SetText(self.EditBoxSearch, self.tbWordData.szWord or "")
    end

    -- 招募列表
    self:UpdateInfo_Recruit()

    -- 聊天
    self:UpdateInfo_Chat()

    UIHelper.ScrollViewDoLayoutAndToTop(self.ScrollViewList)
end

function UIWordBlockEditView:UpdateInfo_Chat()
    self.scriptChatSub = self.scriptChatSub or UIHelper.AddPrefab(PREFAB_ID.WidgetSeetingProhibitWordContent, self.ScrollViewList)
    local LabelTitle = self.scriptChatSub.LabelTitle
    local WidgetContent = self.scriptChatSub.WidgetContent
    local Layout = self.scriptChatSub.Layout
    local TogFold = self.scriptChatSub.TogFold
    local TogSelect = self.scriptChatSub.TogSelect

    local fnUpdateLayout = function(bContentVisible, bScrollUpdate)
        UIHelper.SetVisible(WidgetContent, bContentVisible)
        UIHelper.LayoutDoLayout(WidgetContent)
        UIHelper.LayoutDoLayout(Layout)
        if bScrollUpdate then
            UIHelper.ScrollViewDoLayoutAndToTop(self.ScrollViewList)
        end
    end

    self:UpdateInfo_ChatTitle(true)

    local tbCfgList = WordBlockMgr.GetChatBlockCfgList()
    self.tbScriptCell = {}
    UIHelper.RemoveAllChildren(WidgetContent)
    for k, v in ipairs(tbCfgList) do
        self.tbScriptCell[k] = UIHelper.AddPrefab(PREFAB_ID.WidgetProhibitWordPopCell, WidgetContent)
        self:UpdateInfo_OneChatCell(self.tbScriptCell[k], k, v)
    end
    fnUpdateLayout(true, false)

    UIHelper.SetSelected(TogFold, false)
    UIHelper.BindUIEvent(TogFold, EventType.OnSelectChanged, function(_, bSelected)
        fnUpdateLayout(not bSelected, true)
    end)

    UIHelper.BindUIEvent(TogSelect, EventType.OnSelectChanged, function(_, bSelected)
        if self.bTitleListenerDisable then return end
        self.tbWordData.tbChatKeyList = {}
        if bSelected then
            for k, v in ipairs(tbCfgList) do
                table.insert(self.tbWordData.tbChatKeyList, v.szKey)
            end
        end

        self.bCellListenerDisable = true
        for k, script in ipairs(self.tbScriptCell) do
            self:UpdateInfo_OneChatCell(script, k, tbCfgList[k])
        end
        self.bCellListenerDisable = false

        self:UpdateInfo_ChatTitle()
    end)
end

function UIWordBlockEditView:UpdateInfo_Recruit()
    self.scriptRecruitSub = self.scriptRecruitSub or UIHelper.AddPrefab(PREFAB_ID.WidgetSeetingProhibitWordContent, self.ScrollViewList)
    local LabelTitle = self.scriptRecruitSub.LabelTitle
    local WidgetContent = self.scriptRecruitSub.WidgetContent
    local Layout = self.scriptRecruitSub.Layout
    local TogFold = self.scriptRecruitSub.TogFold
    local TogSelect = self.scriptRecruitSub.TogSelect

    UIHelper.SetString(LabelTitle, "招募列表")
    UIHelper.SetVisible(WidgetContent, false)
    UIHelper.SetVisible(TogFold, false)
    UIHelper.LayoutDoLayout(Layout)

    local bSelected = self.tbWordData.bRecruitBlock
    UIHelper.SetSelected(TogSelect, bSelected)
    UIHelper.BindUIEvent(TogSelect, EventType.OnSelectChanged, function(_, bSelected)
        self.tbWordData.bRecruitBlock = bSelected
    end)
end

function UIWordBlockEditView:UpdateInfo_ChatTitle(bUpdateAllSelect)
    local bIsAllSelected, nSelectCount, nTotalCfgLen = self:CheckChatAllChannelSelected()

    local szTitle = string.format("聊天频道(%d/%d)", nSelectCount, nTotalCfgLen)
    UIHelper.SetString(self.scriptChatSub.LabelTitle, szTitle)

    if bUpdateAllSelect then
        self.bTitleListenerDisable = true
        UIHelper.SetSelected(self.scriptChatSub.TogSelect, bIsAllSelected)
        self.bTitleListenerDisable = false
    end
end

function UIWordBlockEditView:UpdateInfo_OneChatCell(scriptCell, nIndex, tbCfg)
    local szName = tbCfg.szName
    local szKey = tbCfg.szKey

    UIHelper.SetString(scriptCell.LabelOption, szName)
    UIHelper.SetSelected(scriptCell.TogSelect, self:CheckChatChannelSelected(szKey))

    UIHelper.BindUIEvent(scriptCell.TogSelect, EventType.OnSelectChanged, function(_, bSelected)
        if self.bCellListenerDisable then return end
        if bSelected then
            if not table.contain_value(self.tbWordData.tbChatKeyList, szKey) then
                table.insert(self.tbWordData.tbChatKeyList, szKey)
            end
        else
            table.remove_value(self.tbWordData.tbChatKeyList, szKey)
        end

        self:UpdateInfo_ChatTitle(true)
    end)
end

function UIWordBlockEditView:CheckChatAllChannelSelected()
    local tbCfgList = WordBlockMgr.GetChatBlockCfgList()
    local nSelectCount = #self.tbWordData.tbChatKeyList
    local nTotalCfgLen = #tbCfgList

    local bIsAllSelected = nSelectCount == nTotalCfgLen

    return bIsAllSelected, nSelectCount, nTotalCfgLen
end

function UIWordBlockEditView:CheckChatChannelSelected(szKey)
    local bResult = false

    for k, v in ipairs(self.tbWordData.tbChatKeyList or {}) do
        if v == szKey then
            bResult = true
            break
        end
    end

    return bResult
end

function UIWordBlockEditView:CheckWord()
    local szWord = self.tbWordData.szWord

    if string.is_nil(szWord) then
        TipsHelper.ShowNormalTip("关键词不能为空。")
        return false
    end

    return true
end


return UIWordBlockEditView