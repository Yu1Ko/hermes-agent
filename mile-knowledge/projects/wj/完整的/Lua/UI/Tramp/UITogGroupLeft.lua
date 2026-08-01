-- ---------------------------------------------------------------------------------
-- Author: Unknown
-- Name: UITogGroupLeft
-- Date: 2023-04-10 16:12:05
-- Desc: ?
-- ---------------------------------------------------------------------------------

local UITogGroupLeft = class("UITogGroupLeft")

function UITogGroupLeft:OnEnter(tbInfo)
    if not self.bInit then
        self:RegEvent()
        self:BindUIEvent()
        self.bInit = true
    end
    if tbInfo then 
        self.tbInfo = tbInfo
        self:UpdateInfo()
    end
end

function UITogGroupLeft:OnExit()
    self.bInit = false
    self:UnRegEvent()
end

function UITogGroupLeft:BindUIEvent()
    UIHelper.BindUIEvent(self._rootNode, EventType.OnSelectChanged, function(toggle, bSelect)
        if bSelect then
            Event.Dispatch(EventType.OnSelectTogGroupLeft, self.tbInfo.dwID)
        end
    end)
end

function UITogGroupLeft:RegEvent()
    --Event.Reg(self, EventType.XXX, func)
end

function UITogGroupLeft:UnRegEvent()
    --Event.UnReg(self, EventType.XXX)
end






-- ----------------------------------------------------------
-- Please write your own code below  ↓↓↓
-- ----------------------------------------------------------

function UITogGroupLeft:UpdateInfo()
    local nCurrentID = VagabondData.GetCurrentID()
    local nSaveSelectionID = VagabondData.GetSaveSelectionID()
    UIHelper.SetSelected(self._rootNode, self.tbInfo.dwID == nCurrentID, false)
    UIHelper.SetVisible(self.LabelLastChoose, self.tbInfo.nID == nSaveSelectionID)
    UIHelper.SetString(self.LabelNormal, UIHelper.GBKToUTF8(self.tbInfo.szTitle))
end


return UITogGroupLeft