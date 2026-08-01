-- ---------------------------------------------------------------------------------
-- Author: Unknown
-- Name: UIWidgetTestChooseCell
-- Date: 2023-06-20 20:56:54
-- Desc: ?
-- ---------------------------------------------------------------------------------

local UIWidgetTestChooseCell = class("UIWidgetTestChooseCell")

function UIWidgetTestChooseCell:OnEnter(tbInfo, scriptTestPop)
    if not self.bInit then
        self:RegEvent()
        self:BindUIEvent()
        self.bInit = true
    end
    self.tbInfo = tbInfo
    self.scriptTestPop = scriptTestPop
    self:UpdateInfo()
end

function UIWidgetTestChooseCell:OnExit()
    self.bInit = false
    self:UnRegEvent()
end

function UIWidgetTestChooseCell:BindUIEvent()
    UIHelper.BindUIEvent(self.TogChoose, EventType.OnSelectChanged, function(toggle, bSelect)
        if bSelect then
            self.scriptTestPop:SetCurInfo(self.tbInfo)
        end
    end)
end

function UIWidgetTestChooseCell:RegEvent()
    --Event.Reg(self, EventType.XXX, func)
end

function UIWidgetTestChooseCell:UnRegEvent()
    --Event.UnReg(self, EventType.XXX)
end

function UIWidgetTestChooseCell:OnRecycled()
    self.tbInfo = nil
    UIHelper.SetVisible(self._rootNode, false)
end




-- ----------------------------------------------------------
-- Please write your own code below  ↓↓↓
-- ----------------------------------------------------------

function UIWidgetTestChooseCell:UpdateInfo()
    UIHelper.SetVisible(self._rootNode, true)
    UIHelper.SetString(self.LabelChoose, self.tbInfo.szAnswer)
    UIHelper.SetSelected(self.TogChoose, self.tbInfo.bSelect)
end

return UIWidgetTestChooseCell