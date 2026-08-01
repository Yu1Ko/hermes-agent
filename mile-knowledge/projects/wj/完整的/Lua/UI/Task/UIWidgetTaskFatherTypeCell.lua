-- ---------------------------------------------------------------------------------
-- Author: Unknown
-- Name: UIWidgetTaskFatherTypeCell
-- Date: 2024-05-16 10:33:46
-- Desc: ?
-- ---------------------------------------------------------------------------------

local UIWidgetTaskFatherTypeCell = class("UIWidgetTaskFatherTypeCell")

function UIWidgetTaskFatherTypeCell:OnEnter(tbQuestInfo, tbCurInfo)
    if not self.bInit then
        self:RegEvent()
        self:BindUIEvent()
        self.bInit = true
    end
    self.tbQuestInfo = tbQuestInfo
    self.tbCurInfo = tbCurInfo
    self:UpdateInfo()
end

function UIWidgetTaskFatherTypeCell:OnExit()
    self.bInit = false
    self:UnRegEvent()
end

function UIWidgetTaskFatherTypeCell:BindUIEvent()
    UIHelper.BindUIEvent(self.TogDetail, EventType.OnSelectChanged, function(_, bSelected)
        UIHelper.SetVisible(self.LayoutDetail, bSelected)
        self:UpdateLayout()
        Event.Dispatch("OnTaskFatherSelectChanged")
    end)
end

function UIWidgetTaskFatherTypeCell:RegEvent()
    
end

function UIWidgetTaskFatherTypeCell:UnRegEvent()
    
end






-- ----------------------------------------------------------
-- Please write your own code below  ↓↓↓
-- ----------------------------------------------------------
--[[
    szTypeName = "主线", 	
	tbQuestList = {
	{
		szClassName = "稻香村",
		tbQuestList = {
			tbQuestInfo,
			tbQuestInfo,
		}
	},
	{
		szClassName = "XXXX",
		tbQuestList = {
			tbQuestInfo,
			tbQuestInfo,
		}
	},
]]--
function UIWidgetTaskFatherTypeCell:UpdateInfo()
    self.tbScript = {}
    UIHelper.RemoveAllChildren(self.WidgetContent)
    for nIndex, tbInfo in ipairs(self.tbQuestInfo.tbQuestList) do
        local scriptView = UIHelper.AddPrefab(PREFAB_ID.WidgetTaskListCell, self.WidgetContent, tbInfo, self.tbCurInfo)
        table.insert(self.tbScript, scriptView)
    end
    UIHelper.LayoutDoLayout(self.WidgetContent)
    UIHelper.LayoutDoLayout(self.LayoutDetail)
    UIHelper.LayoutDoLayout(self._rootNode)

    UIHelper.SetString(self.LabelNameNormal, self.tbQuestInfo.szTypeName)
    UIHelper.SetString(self.LabelNameUp, self.tbQuestInfo.szTypeName)
end

function UIWidgetTaskFatherTypeCell:GetScriptCells()
    local tbScript = {}
    for nIndex, script in ipairs(self.tbScript) do
        table.insert(tbScript, script:GetScriptCells())
    end
    return tbScript
end


function UIWidgetTaskFatherTypeCell:UpdateLayout()
    local nWidth = UIHelper.GetWidth(self.WidgetContent)
    for nIndex, script in ipairs(self.tbScript) do
        UIHelper.SetPositionX(script._rootNode, - nWidth / 2)
        script:LayoutDoLayout()
    end
    UIHelper.LayoutDoLayout(self.WidgetContent)
    UIHelper.LayoutDoLayout(self.LayoutDetail)
    UIHelper.LayoutDoLayout(self._rootNode)
end

function UIWidgetTaskFatherTypeCell:SetSelected(bSelected)
    UIHelper.SetSelected(self.TogDetail, bSelected)
end

return UIWidgetTaskFatherTypeCell