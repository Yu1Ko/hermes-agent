-- ---------------------------------------------------------------------------------
-- Author: Unknown
-- Name: UIHomelandBuildFurnitureExtractMultiCell
-- Date: 2023-12-19 10:46:42
-- Desc: ?
-- ---------------------------------------------------------------------------------

local UIHomelandBuildFurnitureExtractMultiCell = class("UIHomelandBuildFurnitureExtractMultiCell")

function UIHomelandBuildFurnitureExtractMultiCell:OnEnter(nIndex, tbInfo, bSelected, funcClickCallback)
    if not self.bInit then
        self:RegEvent()
        self:BindUIEvent()
        self.bInit = true
    end

    self.nIndex = nIndex
    self.tbInfo = tbInfo
    self.bSelected = bSelected
    self.funcClickCallback = funcClickCallback
    self:UpdateInfo()
end

function UIHomelandBuildFurnitureExtractMultiCell:OnExit()
    self.bInit = false
end

function UIHomelandBuildFurnitureExtractMultiCell:BindUIEvent()
    UIHelper.BindUIEvent(self.TogCheck, EventType.OnClick, function(btn)
        if self.funcClickCallback then
            self.funcClickCallback(self.nIndex, UIHelper.GetSelected(self.TogCheck))
        end
    end)

end

function UIHomelandBuildFurnitureExtractMultiCell:RegEvent()
    --Event.Reg(self, EventType.XXX, func)
end

function UIHomelandBuildFurnitureExtractMultiCell:UpdateInfo()
    UIHelper.SetSelected(self.TogCheck, self.bSelected)
    UIHelper.SetString(self.LabelName, UIHelper.GBKToUTF8(self.tbInfo.szName))
    UIHelper.SetString(self.LabelNum, self.tbInfo.nNum)
end


return UIHomelandBuildFurnitureExtractMultiCell