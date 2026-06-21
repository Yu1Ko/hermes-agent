-- ---------------------------------------------------------------------------------
-- Author: Unknown
-- Name: UIItemTipContent7
-- Date: 2022-11-15 15:45:32
-- Desc: ?
-- ---------------------------------------------------------------------------------

local UIItemTipContent7 = class("UIItemTipContent7")

function UIItemTipContent7:OnEnter(tbInfo)
    if not tbInfo then return end

    self.tbInfo = tbInfo

    if not self.bInit then
        self:RegEvent()
        self:BindUIEvent()
        self.bInit = true
    end

    self:UpdateInfo()
end

function UIItemTipContent7:OnExit()
    self.bInit = false
end

function UIItemTipContent7:BindUIEvent()

end

function UIItemTipContent7:RegEvent()
    --Event.Reg(self, EventType.XXX, func)
end

function UIItemTipContent7:UpdateInfo()
    -- LOG.TABLE(self.tbInfo)
    if not self.tbInfo or table.is_empty(self.tbInfo) then
        UIHelper.SetVisible(self._rootNode, false)
    else
        UIHelper.SetVisible(self.LayoutCost1, false)
        UIHelper.SetString(self.Label_Cost2, self.tbInfo[1])
        UIHelper.LayoutDoLayout(self.LayoutCost2)
        UIHelper.LayoutDoLayout(self.LayoutCostAll)

        UIHelper.SetVisible(self._rootNode, true)
    end
end

return UIItemTipContent7