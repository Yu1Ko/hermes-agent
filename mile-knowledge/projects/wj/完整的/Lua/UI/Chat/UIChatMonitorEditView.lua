-- ---------------------------------------------------------------------------------
-- Author: Unknown
-- Name: UIChatMonitorEditView
-- Date: 2024-11-22 14:39:25
-- Desc: ?
-- ---------------------------------------------------------------------------------

local UIChatMonitorEditView = class("UIChatMonitorEditView")

function UIChatMonitorEditView:OnEnter(tbMonitorData)	
	self.tbMonitorData = Lib.copyTab(tbMonitorData)	--需编辑的监控Data
	self.bAdd = tbMonitorData == nil

	if tbMonitorData == nil then
        local tbChatKeyList = {}
        for k, v in ipairs(ChatMonitor.GetChatMonitorCfgList()) do
            if v.bDefaultSelect then
                table.insert(tbChatKeyList, v.szKey)
            end
        end

        self.tbMonitorData =
        {
            szWord = "",
            tbChatKeyList = tbChatKeyList,
            bMonitor = true
        }
    end

	if not self.bInit then
		self:RegEvent()
		self:BindUIEvent()
		self.bInit = true
	end

	self:UpdateInfo()
end

function UIChatMonitorEditView:OnExit()
	self.bInit = false
	self:UnRegEvent()
end

function UIChatMonitorEditView:BindUIEvent()
	UIHelper.BindUIEvent(self.BtnClose, EventType.OnClick, function(btn)
        UIMgr.Close(self)
    end)

	UIHelper.BindUIEvent(self.BtnSave, EventType.OnClick, function()
        if not self:CheckWord() then return end

        local szTips = "添加关键词成功"

        -- 如果原来就已经有了
        local tbStorage = ChatMonitor.GetStorageByWord(self.tbMonitorData.szWord)
        if tbStorage then
            TipsHelper.ShowNormalTip("该关键词已存在")
            return
        end

        local bResult = ChatMonitor.SetStorageByWord(self.tbMonitorData.szWord, self.tbMonitorData)
        if bResult then
            Event.Dispatch(EventType.OnWordMonitorChanged)
            TipsHelper.ShowNormalTip(szTips)
            UIMgr.Close(self)
        end
    end)

	UIHelper.BindUIEvent(self.BtnChange, EventType.OnClick, function()
        if not self:CheckWord() then return end

        local szTips = "修改关键词成功"

        local bResult = ChatMonitor.SetStorageByWord(self.tbMonitorData.szWord, self.tbMonitorData, self.szOldWord)
        if bResult then
            Event.Dispatch(EventType.OnWordMonitorChanged)
            TipsHelper.ShowNormalTip(szTips)
            UIMgr.Close(self)
        end
    end)

	UIHelper.BindUIEvent(self.BtnStop, EventType.OnClick, function()
        if not self:CheckWord() then return end

        self.tbMonitorData.bMonitor = not self.tbMonitorData.bMonitor
        local szTips = self.tbMonitorData.bMonitor and "关键词监控开启成功" or "关键词监控停止成功"
        local bResult = ChatMonitor.SetStorageByWord(self.tbMonitorData.szWord, self.tbMonitorData)
        if bResult then
            Event.Dispatch(EventType.OnWordMonitorChanged)
            TipsHelper.ShowNormalTip(szTips)
            UIMgr.Close(self)
        end
    end)

    UIHelper.BindUIEvent(self.BtnDel, EventType.OnClick, function()
        if not self:CheckWord() then return end

        local bResult = ChatMonitor.SetStorageByWord(self.tbMonitorData.szWord, nil)
        if bResult then
            Event.Dispatch(EventType.OnWordMonitorChanged)
            TipsHelper.ShowNormalTip("删除关键词成功")
            UIMgr.Close(self)
        end
    end)
end

function UIChatMonitorEditView:RegEvent()
	UIHelper.RegisterEditBoxEnded(self.EditBoxSearch, function()
        local szWord = string.trim(UIHelper.GetString(self.EditBoxSearch), " ")
        self.tbMonitorData.szWord = szWord
    end)
end

function UIChatMonitorEditView:UnRegEvent()
	--Event.UnReg(self, EventType.XXX)
end






-- ----------------------------------------------------------
-- Please write your own code below  ↓↓↓
-- ----------------------------------------------------------

function UIChatMonitorEditView:UpdateInfo()
	-- 标题
	UIHelper.SetString(self.LabelTitle, self.bAdd and "添加监控关键词" or "编辑监控关键词")

	-- 按钮
	UIHelper.SetVisible(self.BtnSave, self.bAdd)
	UIHelper.SetVisible(self.BtnDel, not self.bAdd)
	UIHelper.SetVisible(self.BtnChange, not self.bAdd)
    UIHelper.SetVisible(self.BtnStop, not self.bAdd)

    local szMonitor = self.tbMonitorData.bMonitor and "停止监控" or "开启监控"
    UIHelper.SetString(self.LabelRecover, szMonitor)

	--输入框
	local nMaxWordLen = ChatMonitor.GetMaxWordLen()
	UIHelper.SetMaxLength(self.EditBoxSearch, nMaxWordLen)
    --UIHelper.SetEnable(self.EditBoxSearch, self.bAdd)

	if self.bAdd then
        UIHelper.SetText(self.EditBoxSearch, "")
        UIHelper.SetPlaceHolder(self.EditBoxSearch, string.format("请输入想要监控的关键词（1-%d个字）", nMaxWordLen))
    else
        UIHelper.SetText(self.EditBoxSearch, self.tbMonitorData.szWord or "")
		self.szOldWord = self.tbMonitorData.szWord or ""
    end

	self:UpdateInfo_Chat()
end

function UIChatMonitorEditView:UpdateInfo_Chat()
	local tbCfgList = ChatMonitor.GetChatMonitorCfgList()
	self.tbScriptCell = {}
    UIHelper.RemoveAllChildren(self.ScrollViewList)
    for k, v in ipairs(tbCfgList) do
        self.tbScriptCell[k] = UIHelper.AddPrefab(PREFAB_ID.WidgetProhibitWordPopCell, self.ScrollViewList)
        self:UpdateInfo_OneChatCell(self.tbScriptCell[k], k, v)
    end

	UIHelper.ScrollViewDoLayoutAndToTop(self.ScrollViewList)
end

function UIChatMonitorEditView:UpdateInfo_OneChatCell(scriptCell, nIndex, tbCfg)
	local szName = tbCfg.szName
    local szKey = tbCfg.szKey
	UIHelper.SetString(scriptCell.LabelOption, szName)
	UIHelper.SetSelected(scriptCell.TogSelect, self:CheckChatChannelSelected(szKey))

	UIHelper.BindUIEvent(scriptCell.TogSelect, EventType.OnSelectChanged, function(_, bSelected)
        if bSelected then
            if not table.contain_value(self.tbMonitorData.tbChatKeyList, szKey) then
                table.insert(self.tbMonitorData.tbChatKeyList, szKey)
            end
        else
            table.remove_value(self.tbMonitorData.tbChatKeyList, szKey)
        end

    end)
end

function UIChatMonitorEditView:CheckChatChannelSelected(szKey)
	local bResult = false

    for k, v in ipairs(self.tbMonitorData.tbChatKeyList or {}) do
        if v == szKey then
            bResult = true
            break
        end
    end

    return bResult
end

function UIChatMonitorEditView:CheckWord()
	local szWord = self.tbMonitorData.szWord

    if string.is_nil(szWord) then
        TipsHelper.ShowNormalTip("关键词不能为空。")
        return false
    end

    return true
end

return UIChatMonitorEditView