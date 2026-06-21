-- ---------------------------------------------------------------------------------
-- Author: Unknown
-- Name: UIItemTipContent12
-- Date: 2024-05-08 11:34:09
-- Desc: ?
-- ---------------------------------------------------------------------------------

local UIItemTipContent12 = class("UIItemTipContent12")

function UIItemTipContent12:OnEnter(tbInfo)
    if not self.bInit then
        self:RegEvent()
        self:BindUIEvent()
        self.bInit = true
    end
    self.tbInfo = tbInfo
    self:UpdateInfo()
end

function UIItemTipContent12:OnExit()
    self.bInit = false
    self:UnRegEvent()
end

function UIItemTipContent12:BindUIEvent()

end

function UIItemTipContent12:RegEvent()
    --Event.Reg(self, EventType.XXX, func)
end

function UIItemTipContent12:UnRegEvent()
    --Event.UnReg(self, EventType.XXX)
end






-- ----------------------------------------------------------
-- Please write your own code below  ↓↓↓
-- ----------------------------------------------------------

function UIItemTipContent12:UpdateInfo()
    local tbInfo = self.tbInfo
    local bHasAnyVisable = false
    for index, layout in ipairs(self.tLayoutList) do
        local tInfo = tbInfo[index]
        local bVisable = tInfo ~= nil
        UIHelper.SetVisible(layout, bVisable)
        if bVisable then
            bHasAnyVisable = true
            UIHelper.SetString(self.tLabelTitleList[index], tInfo.szTitle)
            UIHelper.SetRichText(self.tRichTextList[index], tInfo.szText)
        end
    end

    UIHelper.CascadeDoLayoutDoWidget(self._rootNode, true, true)
    UIHelper.SetVisible(self._rootNode, bHasAnyVisable)
end


return UIItemTipContent12