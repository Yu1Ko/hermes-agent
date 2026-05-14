-- ---------------------------------------------------------------------------------
-- Author: huqing
-- Name: UISocialView
-- Date: 2024-01-22 15:00:12
-- Desc: 社交界面 里面包含聊天、联系人、师徒、帮会
-- ---------------------------------------------------------------------------------

local INDEX_TO_PREFAB =
{
    [1] = PREFAB_ID.WidgetChatContent,
    [2] = PREFAB_ID.WidgetInteractionContent,
    [3] = PREFAB_ID.WidgetInteractionContent,
    [4] = PREFAB_ID.WidgetInteractionContent,
    [5] = PREFAB_ID.WidgetVoiceChatContent,
}


local UISocialView = class("UISocialView")

function UISocialView:OnEnter(nIndex, ...)
    self.tbArgs = {...}

    if not self.bInit then
        self.tbScripts = {}
        self:RegEvent()
        self:BindUIEvent()
        self.bInit = true
    end

    self:Select(nIndex or 1)

    -- UIHelper.ScrollViewDoLayoutAndToTop(self.ScrollViewTab)
    UIHelper.SetVisible(self.BtnBox, UIMgr.GetFullPageViewCount() > 0 and not UIMgr.IsViewOpened(VIEW_ID.PanelConstructionMain))
    UIHelper.SetVisible(self.BtnBox2, UIMgr.GetFullPageViewCount() > 0 and not UIMgr.IsViewOpened(VIEW_ID.PanelConstructionMain))
    UIHelper.SetVisible(self.WidgetTogTab_5, RoomVoiceData.CheckCanShowRoomVoice())
end

function UISocialView:OnExit()
    self.bInit = false
    self:UnRegEvent()
end

function UISocialView:BindUIEvent()
    UIHelper.BindUIEvent(self.BtnClose, EventType.OnClick, function()
        UIMgr.Close(self)
    end)

    UIHelper.BindUIEvent(self.BtnBox, EventType.OnClick, function()
        UIMgr.Close(self)
    end)

    UIHelper.BindUIEvent(self.BtnBox2, EventType.OnClick, function()
        UIMgr.Close(self)
    end)

    for k, tog in ipairs(self.tbTogList) do
        UIHelper.BindUIEvent(tog, EventType.OnSelectChanged, function(_, bSelected)
            if bSelected then
                if self.nIndex ~= k then
                    self.nIndex = k
                    self:UpdateInfo_Content()
                end
            end
        end)
    end
end

function UISocialView:RegEvent()
    -- Event.Reg(self, EventType.OnWindowsSizeChanged, function()
    --     UIHelper.WidgetFoceDoAlignAssignNode(self, self.WidgetContentAnchor)
    -- end)

    -- Event.Reg(self, EventType.OnWindowsSetFocus, function()
    --     UIHelper.WidgetFoceDoAlignAssignNode(self, self.WidgetContentAnchor)
    -- end)
end

function UISocialView:UnRegEvent()
    --Event.UnReg(self, EventType.XXX)
end






-- ----------------------------------------------------------
-- Please write your own code below  ↓↓↓
-- ----------------------------------------------------------

function UISocialView:UpdateInfo()

end

function UISocialView:UpdateInfo_Content()
    local nPrefabID = INDEX_TO_PREFAB[self.nIndex]
    if not nPrefabID then
        return
    end

    for k, _ in ipairs(INDEX_TO_PREFAB) do
        local script = self.tbScripts[k]

        if k == self.nIndex then
            if not script then
                if k == 1 then
                    script = UIHelper.AddPrefab(nPrefabID, self.WidgetContentAnchor, unpack(self.tbArgs))
                    if Platform.IsMobile() then
                        script:UpdateScrollList()
                    end
                else
                    script = UIHelper.AddPrefab(nPrefabID, self.WidgetContentAnchor, self.nIndex, unpack(self.tbArgs))
                end
                self.tbScripts[k] = script
            else
                if k == 1 then
                    script:OnEnter(unpack(self.tbArgs))
                else
                    script:OnEnter(self.nIndex, unpack(self.tbArgs))
                end
            end
            UIHelper.SetVisible(script._rootNode, true)
        else
            if script then
                UIHelper.SetVisible(script._rootNode, false)
            end
        end
    end

    UIHelper.ScrollViewDoLayout(self.ScrollViewTab)

    if self.nTimer then 
        Timer.DelTimer(self.nTimer)
        self.nTimer = nil
    end

    self.nTimer = Timer.AddFrame(self, 1, function ()
        if self.nIndex < 5 then
            UIHelper.ScrollToTop(self.ScrollViewTab)
        else
            UIHelper.ScrollToBottom(self.ScrollViewTab)
        end
    end)

    self.tbArgs = {}
end

function UISocialView:Select(nIndex)
    if not nIndex then
        return
    end

    UIHelper.SetSelected(self.tbTogList[nIndex], true)
end

function UISocialView:IsSelected(nIndex)
    if not nIndex then
        return
    end

    return UIHelper.GetSelected(self.tbTogList[nIndex])
end


return UISocialView