-- ---------------------------------------------------------------------------------
-- Author: Unknown
-- Name: UISelfieDataTextParam
-- Date: 2025-10-23 11:49:52
-- Desc: ?
-- ---------------------------------------------------------------------------------

local UISelfieDataTextParam = class("UISelfieDataTextParam")

function UISelfieDataTextParam:OnEnter(tParam, nIndex)
    if not self.bInit then
        self:RegEvent()
        self:BindUIEvent()
        self.bInit = true
    end
    self.nIndex = nIndex
    self.tParam = tParam
    self:UpdateInfo()
end

function UISelfieDataTextParam:OnExit()
    self.bInit = false
    self:UnRegEvent()
end

function UISelfieDataTextParam:BindUIEvent()
    
end

function UISelfieDataTextParam:RegEvent()
    --Event.Reg(self, EventType.XXX, func)
end

function UISelfieDataTextParam:UnRegEvent()
    --Event.UnReg(self, EventType.XXX)
end






-- ----------------------------------------------------------
-- Please write your own code below  ������
-- ----------------------------------------------------------

function UISelfieDataTextParam:UpdateInfo()
    if not self.tParam then
        return
    end
    local nOffset = (self.nIndex == 1 and 0 or 3)
    for k, cell in ipairs(self.tbParam) do
        local szParam = self.tParam[k + nOffset]
        if szParam then
            UIHelper.SetString(cell, szParam)
            UIHelper.SetVisible(cell , true)
        else
            UIHelper.SetVisible(cell , false)
        end
    end  
    UIHelper.LayoutDoLayout(self._rootNode)
end


return UISelfieDataTextParam