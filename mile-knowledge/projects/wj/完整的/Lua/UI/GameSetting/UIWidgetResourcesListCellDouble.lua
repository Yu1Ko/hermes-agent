-- ---------------------------------------------------------------------------------
-- Author: luwenhao1
-- Name: UIWidgetResourcesListCellDouble
-- Date: 2023-10-07 16:02:03
-- Desc: WidgetResourcesListCell
-- ---------------------------------------------------------------------------------

local UIWidgetResourcesListCellDouble = class("UIWidgetResourcesListCellDouble")

function UIWidgetResourcesListCellDouble:OnEnter()
    if not self.bInit then
        self:RegEvent()
        self:BindUIEvent()
        self.bInit = true

        self:InitCellList()
    end
end

function UIWidgetResourcesListCellDouble:OnExit()
    self.bInit = false
    self:UnRegEvent()
end

function UIWidgetResourcesListCellDouble:BindUIEvent()
    
end

function UIWidgetResourcesListCellDouble:RegEvent()
    --Event.Reg(self, EventType.XXX, func)
end

function UIWidgetResourcesListCellDouble:UnRegEvent()
    --Event.UnReg(self, EventType.XXX)
end






-- ----------------------------------------------------------
-- Please write your own code below  ↓↓↓
-- ----------------------------------------------------------

function UIWidgetResourcesListCellDouble:InitCellList()
    if not self.tWidgetResourcesList then
        return
    end

    self.tScriptView = self.tScriptView or {}

    local nIndex = 1
    while self.tWidgetResourcesList[nIndex] do
        if not self.tScriptView[nIndex] then
            local scriptView = UIHelper.GetBindScript(self.tWidgetResourcesList[nIndex])
            scriptView._aniMgr = self._aniMgr
            scriptView._widgetMgr = self._widgetMgr
            self.tScriptView[nIndex] = scriptView
        end
        nIndex = nIndex + 1
    end
end

function UIWidgetResourcesListCellDouble:UpdateInfo(nType, bDiscard, ...)
    if not self.tWidgetResourcesList or not self.tScriptView then
        return
    end

    local tIDList = {...}
    for nIndex, scriptView in ipairs(self.tScriptView) do
        local nID = tIDList[nIndex]
        if nID then
            UIHelper.SetVisible(self.tWidgetResourcesList[nIndex], true)
            scriptView:OnEnter(nID, nType)
            scriptView:SetDiscard(bDiscard)
        else
            UIHelper.SetVisible(self.tWidgetResourcesList[nIndex], false)
        end
    end
end

function UIWidgetResourcesListCellDouble:SetRecommend(...)
    if not self.tWidgetResourcesList or not self.tScriptView then
        return
    end

    local tRecommend = {...}
    for nIndex, scriptView in ipairs(self.tScriptView) do
        local bRecommend = tRecommend[nIndex]
        scriptView:SetRecommend(bRecommend)
    end
end

return UIWidgetResourcesListCellDouble