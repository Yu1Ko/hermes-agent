local UIRobotThirdPanelSubView = class("UIRobotThirdPanelSubView")

function UIRobotThirdPanelSubView:OnEnter(tbSelectCell, tbDropdownSelect, tbCMDParams)
    if tbSelectCell then
        if not self.bInit then
            self:RegEvent()
            self:BindUIEvent()
            self.bInit = true
        end
        self.tbSelectCell = tbSelectCell
        self.tbDropdownSelect = tbDropdownSelect
        self.tbCMDParams = tbCMDParams
        self:UpdateInfo()
    else
        self:OnExit()
    end
end

function UIRobotThirdPanelSubView:OnExit()
    self.bInit = false
    self:UnRegEvent()
end

function UIRobotThirdPanelSubView:BindUIEvent()
        UIHelper.TableView_addCellAtIndexCallback(self.ScrollViewDropList, function(tableView, nIndex, script, node, cell)
            local tbSelect= self.tbDropdownSelect[nIndex]
            script:OnEnter(tbSelect.nValue, tbSelect.szlabel, function (nValue, nKey)
                self.tbCMDParams[self.tbSelectCell.szCellKey] = nValue
                UIHelper.SetString(self.tbSelectCell.LabelDropList, nKey)
                UIMgr.Close(VIEW_ID.PanelRobotThirdSubView)
                self:ToggleSelect()
            end)
            UIHelper.ToggleGroupAddToggle(self.ToggleGroupDropList, script.ToggleSelect)
        end)
end

function UIRobotThirdPanelSubView:RegEvent()
    --Event.Reg(self, EventType.XXX, func)
end

function UIRobotThirdPanelSubView:UnRegEvent()
    --Event.UnReg(self, EventType.XXX)
end

function UIRobotThirdPanelSubView:ToggleSelect()
    UIHelper.TableView_init(self.ScrollViewDropList, #self.tbDropdownSelect, PREFAB_ID.WidgetRobotThirdLevelSubCell)
    UIHelper.TableView_reloadData(self.ScrollViewDropList)
end




-- ----------------------------------------------------------
-- Please write your own code below  ↓↓↓
-- ----------------------------------------------------------

function UIRobotThirdPanelSubView:UpdateInfo()
    self:ToggleSelect()
end


return UIRobotThirdPanelSubView