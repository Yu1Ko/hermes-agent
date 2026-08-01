local UIRobotThirdPanelCell = class("UIRobotThirdPanelCell")

-- 这里应该接受参数和保存参数
function UIRobotThirdPanelCell:OnEnter(tbSelectCell, tbCMDParams)
    if not self.bInit then
        self:RegEvent()
        self:BindUIEvent()
        self.bInit = true
    end
    if tbSelectCell then
        UIHelper.SetString(self.LabelContent, tbSelectCell.szText)
        self.szCellKey = tbSelectCell.szKey
        self.tbDropdownSelect = tbSelectCell.tbDropdownSelect
        self.tbCMDParams = tbCMDParams
        local szValue = self.tbCMDParams[self.szCellKey] or tbSelectCell.szDefaultValue
        self.tbCMDParams[self.szCellKey] = szValue
        if tbSelectCell.nBtnType == 2 then
            UIHelper.SetVisible(self.ToggleGroupDropList, true)
            UIHelper.SetString(self.LabelDropList, tbSelectCell.szDefaultTitle)
        elseif tbSelectCell.nBtnType == 3 then
            UIHelper.SetVisible(self.TogSelect, true)
        else
            UIHelper.SetVisible(self.EditBoxParam, true)
            UIHelper.SetString(self.EditBoxParam, szValue)
        end
    else
        self:OnExit()
    end
end

function UIRobotThirdPanelCell:OnExit()
    self.bInit = false
    self:UnRegEvent()
end

function UIRobotThirdPanelCell:BindUIEvent()
    UIHelper.BindUIEvent(self.TogDropList, EventType.OnSelectChanged, function (_, bSelected)
        UIMgr.Close(VIEW_ID.PanelRobotThirdSubView)
        if bSelected then
            UIMgr.Open(VIEW_ID.PanelRobotThirdSubView, self, self.tbDropdownSelect, self.tbCMDParams)
        end
    end)

    UIHelper.BindUIEvent(self.TogSelect, EventType.OnSelectChanged, function (_, bSelected)
        self.tbCMDParams[self.szCellKey] = bSelected
    end)

    UIHelper.RegisterEditBoxEnded(self.EditBoxParam, function()
        local szEditValue = UIHelper.GetString(self.EditBoxParam)
        self.tbCMDParams[self.szCellKey] = szEditValue
    end)
end

function UIRobotThirdPanelCell:RegEvent()
    --Event.Reg(self, EventType.XXX, func)
end

function UIRobotThirdPanelCell:UnRegEvent()
    --Event.UnReg(self, EventType.XXX)
end



-- ----------------------------------------------------------
-- Please write your own code below  ↓↓↓
-- ----------------------------------------------------------

function UIRobotThirdPanelCell:UpdateInfo()

end


return UIRobotThirdPanelCell