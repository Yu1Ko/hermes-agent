-- ---------------------------------------------------------------------------------
-- Author: Unknown
-- Name: UIOperationContentTitleTog
-- Date: 2026-03-29 23:03:57
-- Desc: ?
-- ---------------------------------------------------------------------------------

local UIOperationContentTitleTog = class("UIOperationContentTitleTog")

-- nType: 1 - WidgetContentTitleTog80, 2 - WidgetContentTitleTog100
function UIOperationContentTitleTog:OnEnter(nOperationID, nID)
    if not self.bInit then
        self:RegEvent()
        self:BindUIEvent()
        self.bInit = true
    end

    self.nOperationID = nOperationID
    self.nID = nID

    self.scriptToggle2 = UIHelper.GetBindScript(self.WidgetToggle2)
    self.scriptToggle3 = UIHelper.GetBindScript(self.WidgetToggle3)

    self:UpdateInfo()
end

function UIOperationContentTitleTog:OnExit()
    self.bInit = false
    self:UnRegEvent()
end

function UIOperationContentTitleTog:BindUIEvent()

end

function UIOperationContentTitleTog:RegEvent()
    --Event.Reg(self, EventType.XXX, func)
end

function UIOperationContentTitleTog:UnRegEvent()
    --Event.UnReg(self, EventType.XXX)
end

-- ----------------------------------------------------------
-- Please write your own code below  ↓↓↓
-- ----------------------------------------------------------
function UIOperationContentTitleTog:getTaskList()
    if tonumber(self.nType) == 1 then
        return PREFAB_ID.WidgetTaskList80
    elseif tonumber(self.nType) == 2 then
        return PREFAB_ID.WidgetTaskList100
    end
end

function UIOperationContentTitleTog:UpdateInfo()
    UIHelper.RemoveAllChildren(self.LayoutContentTopWide)
    self.tScriptTaskList = {}
    for i = 1, 5 do
        local script = UIHelper.AddPrefab(self:getTaskList(), self.LayoutContentTopWide)
        script.nType = self.nType
        table.insert(self.tScriptTaskList, script)
    end

    if self.nOperationID then
        local tCheckBoxInfo = Table_GetOperationCheckBox(self.nOperationID)
        if tCheckBoxInfo then
            self:InitCheckBoxByConfig(tCheckBoxInfo)
        end
    end

    UIHelper.LayoutDoLayout(self.LayoutContentTopWide)
end

function UIOperationContentTitleTog:InitCheckBoxByConfig(tCheckBoxInfo)
    local nCheckBoxNum = tCheckBoxInfo.nCheckBoxNum or 0

    local function InitToggleGroup(widgetToggle, nNum)
        local scriptToggle = UIHelper.GetBindScript(widgetToggle)
        if not scriptToggle then
            return
        end

        UIHelper.SetVisible(widgetToggle, true)
        local scriptLabelContent = UIHelper.AddPrefab(PREFAB_ID.WidgetLabelContent, self.LayoutContentTopWide, self.nOperationID, self.nID)
        UIHelper.SetLocalZOrder(scriptLabelContent._rootNode, -1)

        for i = 1, nNum do
            local tContent = Table_GetCheckBoxContent(self.nOperationID, i)
            local szName = tContent and UIHelper.GBKToUTF8(tContent.szName) or ""
            scriptToggle:SetLabel(i, szName)
        end
        scriptToggle:SetSelectCallback(function(nIndex)
            if self.fnToggleSelectCallback then
                self.fnToggleSelectCallback(nIndex)
            end
            local tContent = Table_GetCheckBoxContent(self.nOperationID, nIndex)
            local szDsc = tContent and tContent.szDsc or ""
            szDsc = ParseTextHelper.ParseNormalText(szDsc, false)
            szDsc = UIHelper.GBKToUTF8(szDsc)
            scriptLabelContent:SetContent(szDsc)
            UIHelper.SetVisible(scriptLabelContent._rootNode, szDsc ~= "")
            UIHelper.LayoutDoLayout(self.LayoutContentTopWide)
            UIHelper.LayoutDoLayout(self._rootNode)
        end)

        Timer.AddFrame(self, 2, function()
            scriptToggle:SetSelectIndex(1, true)
        end)

        for i = 1, #self.tScriptTaskList do
            self:SetVisibleTaskCell(i, false)
        end
    end

    UIHelper.SetVisible(self.WidgetToggle2, false)
    UIHelper.SetVisible(self.WidgetToggle3, false)
    if nCheckBoxNum == 2 then
        InitToggleGroup(self.WidgetToggle2, 2)
    elseif nCheckBoxNum == 3 then
        InitToggleGroup(self.WidgetToggle3, 3)
    end

    UIHelper.LayoutDoLayout(self.LayoutContentTopWide)
    UIHelper.LayoutDoLayout(self._rootNode)
end

-- 设置Toggle选中回调（供父面板注入，参数为 nIndex）
function UIOperationContentTitleTog:SetToggleSelectCallback(fnCallBack)
    self.fnToggleSelectCallback = fnCallBack
end

-- 设置任务项点击回调（供父面板注入）
function UIOperationContentTitleTog:SetfnCallBack(fnCallBack)
    for i = 1, #self.tScriptTaskList do
        self.tScriptTaskList[i]:SetfnCallBack(function()
            fnCallBack(i)
        end)
    end
end

-- 设置任务单元显隐
function UIOperationContentTitleTog:SetVisibleTaskCell(index, bVisible)
    if self.tScriptTaskList[index] then
        UIHelper.SetVisible(self.tScriptTaskList[index]._rootNode, bVisible)
    end
end

return UIOperationContentTitleTog
