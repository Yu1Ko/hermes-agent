local UIRobotSecondPanel = class("UIRobotSecondPanel")

function UIRobotSecondPanel:OnEnter(szTitle, tbTableView)
    if not self.bInit then
        self:RegEvent()
        self:BindUIEvent()
        self.bInit = true
    end
    self.tbTableView = tbTableView
    UIHelper.SetString(self.LabelTitle, szTitle)
    self:UpdateInfo()
end

function UIRobotSecondPanel:OnExit()
    self.bInit = false
    self:UnRegEvent()
end

function UIRobotSecondPanel:BindUIEvent()
    UIHelper.BindUIEvent(self.BtnClose, EventType.OnClick, function(btn)
        UIMgr.Close(VIEW_ID.PanelRobotSecondary)
    end)

    UIHelper.TableView_addCellAtIndexCallback(self.TableViewSecondLevel, function(tableView, nIndex, script, node, cell)
        local tbSelectCell = self.tbTableView[nIndex]
        if script and tbSelectCell then
            script:OnEnter(tbSelectCell)
        end
    end)
end

function UIRobotSecondPanel:RegEvent()
    --Event.Reg(self, EventType.XXX, func)
end

function UIRobotSecondPanel:UnRegEvent()
    --Event.UnReg(self, EventType.XXX)
end






-- ----------------------------------------------------------
-- Please write your own code below  ↓↓↓
-- ----------------------------------------------------------

function UIRobotSecondPanel:UpdateInfo()
    UIHelper.TableView_init(self.TableViewSecondLevel, #self.tbTableView, PREFAB_ID.WidgetRobotSecondaryCell)
    UIHelper.TableView_reloadData(self.TableViewSecondLevel)
end


return UIRobotSecondPanel