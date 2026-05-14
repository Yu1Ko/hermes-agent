-- ---------------------------------------------------------------------------------
-- Author: huqing
-- Name: UIWordBlock
-- Date: 2024-09-06 11:09:26
-- Desc: ?
-- ---------------------------------------------------------------------------------

local UIWordBlock = class("UIWordBlock")

function UIWordBlock:OnEnter()
    if not self.bInit then
        self:RegEvent()
        self:BindUIEvent()
        self.bInit = true
    end

    self.tbSelectWords = {}

    self:UpdateInfo()
end

function UIWordBlock:OnExit()
    self.bInit = false
    self:UnRegEvent()
end

function UIWordBlock:BindUIEvent()
    UIHelper.BindUIEvent(self.BtnDelAll, EventType.OnClick, function()
        UIHelper.SetVisible(self.BtnDelAll, false)
        UIHelper.SetVisible(self.BtnAddWord, false)
        UIHelper.SetVisible(self.BtnCancelDel, true)
        UIHelper.SetVisible(self.BtnComfirmDel, true)

        Event.Dispatch(EventType.OnEnterWordBlockDelAll)

        self:UpdateSelectMode()
    end)

    UIHelper.BindUIEvent(self.BtnAddWord, EventType.OnClick, function()
        UIMgr.Open(VIEW_ID.PanelProhibitWordPop)
    end)

    UIHelper.BindUIEvent(self.BtnCancelDel, EventType.OnClick, function()
        UIHelper.SetVisible(self.BtnDelAll, true)
        UIHelper.SetVisible(self.BtnAddWord, true)
        UIHelper.SetVisible(self.BtnCancelDel, false)
        UIHelper.SetVisible(self.BtnComfirmDel, false)

        self.tbSelectWords = {}
        Event.Dispatch(EventType.OnExitWordBlockDelAll)
    end)

    UIHelper.BindUIEvent(self.BtnComfirmDel, EventType.OnClick, function()
        UIHelper.SetVisible(self.BtnDelAll, true)
        UIHelper.SetVisible(self.BtnAddWord, true)
        UIHelper.SetVisible(self.BtnCancelDel, false)
        UIHelper.SetVisible(self.BtnComfirmDel, false)

        self:DeleteSelected()
    end)

    UIHelper.BindUIEvent(self.BtnExit, EventType.OnClick, function()
        self.szSearchWord = ""
        UIHelper.SetText(self.EditKindSearch, "")
        UIHelper.SetSelected(self.TogSearch, false)

        self:UpdateInfo_List()
    end)

    UIHelper.BindUIEvent(self.BtnHelp, EventType.OnClick, function()
        TipsHelper.ShowNodeHoverTips(PREFAB_ID.WidgetPublicLabelTips, self.BtnHelp, WordBlockMgr.GetStringTips())
    end)
end

function UIWordBlock:RegEvent()
    Event.Reg(self, EventType.OnWordBlockChanged, function()
        self:UpdateInfo_List()
    end)

    Event.Reg(self, EventType.OnWordBlockSelected, function(szWord, bSelected)
        if bSelected then
            if not table.contain_value(self.tbSelectWords, szWord) then
                table.insert(self.tbSelectWords, szWord)
            end
        else
            for k, v in ipairs(self.tbSelectWords) do
                if v == szWord then
                    table.remove(self.tbSelectWords, k)
                    break
                end
            end
        end

        self:UpdateSelectMode()
    end)

    UIHelper.RegisterEditBoxEnded(self.EditKindSearch, function()
        self.szSearchWord = UIHelper.GetString(self.EditKindSearch)
        self:UpdateInfo_List()
    end)
end

function UIWordBlock:UnRegEvent()
    --Event.UnReg(self, EventType.XXX)
end






-- ----------------------------------------------------------
-- Please write your own code below  ↓↓↓
-- ----------------------------------------------------------

function UIWordBlock:UpdateInfo()
    UIHelper.SetSelected(self.ToggleHide, WordBlockMgr.GetIsOpen())
    UIHelper.BindUIEvent(self.ToggleHide, EventType.OnSelectChanged, function(_, bSelected)
        WordBlockMgr.SetIsOpen(bSelected)
    end)

    UIHelper.SetVisible(self.BtnDelAll, true)
    UIHelper.SetVisible(self.BtnAddWord, true)
    UIHelper.SetVisible(self.BtnCancelDel, false)
    UIHelper.SetVisible(self.BtnComfirmDel, false)

    self:UpdateInfo_List()
end

function UIWordBlock:UpdateInfo_List()
    --local nCount = WordBlockMgr.GetStorageLen()
    local nTotal = WordBlockMgr.GetMaxStorageLen()
    local tbList = WordBlockMgr.GetStorageList(self.szSearchWord)
    local nCount = #tbList

    UIHelper.SetString(self.LabelSettingsCount, string.format("(%d/%d)", nCount, nTotal))

    UIHelper.SetVisible(self.WidgetSettingProhibitWordEmpty, nCount == 0)
    UIHelper.SetVisible(self.ScrollViewProhibitWord, nCount > 0)

    local nPrefabCount = math.ceil(nCount / 2)
    UIHelper.RemoveAllChildren(self.ScrollViewProhibitWord)
    for i = 1, nPrefabCount do
        local script = UIHelper.AddPrefab(PREFAB_ID.WidgetSettingProhibitWordCell, self.ScrollViewProhibitWord)
        script:OnEnter({tbList[i * 2 - 1], tbList[i * 2]})
    end

    UIHelper.ScrollViewDoLayoutAndToTop(self.ScrollViewProhibitWord)
end

function UIWordBlock:UpdateSelectMode()
    local nCount = #self.tbSelectWords
    UIHelper.SetString(self.LabelComfirmDel, string.format("确认删除(%d)", nCount))

    UIHelper.SetButtonState(self.BtnComfirmDel, (nCount > 0) and BTN_STATE.Normal or BTN_STATE.Disable, "请先选择要删除的关键词")
end

function UIWordBlock:DeleteSelected()
    WordBlockMgr.DeleteStorageByWordList(self.tbSelectWords)

    self.tbSelectWords = {}
    self:UpdateInfo_List()
end


return UIWordBlock