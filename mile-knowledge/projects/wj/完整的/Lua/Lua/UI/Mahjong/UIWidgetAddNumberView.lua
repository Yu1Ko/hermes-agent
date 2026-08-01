-- ---------------------------------------------------------------------------------
-- Author: Unknown
-- Name: UIWidgetAddNumberView
-- Date: 2023-08-11 15:46:21
-- Desc: ?
-- ---------------------------------------------------------------------------------

local UIWidgetAddNumberView = class("UIWidgetAddNumberView")

function UIWidgetAddNumberView:OnEnter(tbInfo)
    if not self.bInit then
        self:RegEvent()
        self:BindUIEvent()
        self.bInit = true
    end
    self:UpdateInfo(tbInfo)
end

function UIWidgetAddNumberView:OnExit()
    self.bInit = false
    self:UnRegEvent()
end

function UIWidgetAddNumberView:BindUIEvent()
    
end

function UIWidgetAddNumberView:RegEvent()
    --Event.Reg(self, EventType.XXX, func)
end

function UIWidgetAddNumberView:UnRegEvent()
    --Event.UnReg(self, EventType.XXX)
end






-- ----------------------------------------------------------
-- Please write your own code below  ↓↓↓
-- ----------------------------------------------------------

function UIWidgetAddNumberView:UpdateInfo(tbInfo)
    local nAddNumber = tbInfo.nAddNumber

    if nAddNumber then
        local szNumber = nAddNumber > 0 and "+"..tostring(nAddNumber) or tostring(nAddNumber)
        UIHelper.SetString(self.TextNum, szNumber)
    end


    UIHelper.SetVisible(self.TextNum, nAddNumber ~= nil)
    UIHelper.SetVisible(self.ImgText, false)
    UIHelper.SetVisible(self._rootNode, true)


    MahjongAnimHelper.PlayAddNumerEffects(self._rootNode, tbInfo.nUIDirection, 0.2, function()
        if self.nTimer then
            Timer.DelTimer(self, self.nTimer)
        end
        self.nTimer = Timer.Add(self, 2, function()
            UIHelper.SetVisible(self._rootNode, false)
        end)
    end)
end


return UIWidgetAddNumberView