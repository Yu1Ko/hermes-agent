local UIRobotThirdPanel = class("UIRobotThirdPanel")

function UIRobotThirdPanel:OnEnter(tbCellData)
    if not self.bInit then
        self:RegEvent()
        self:BindUIEvent()
        self.bInit = true
    end
    self.tbSubPanel = tbCellData.tbSubPanel
    self.tbCMDParams = tbCellData.tbCMDParams
    self.fnCallBack = tbCellData.fnCallBack
    UIHelper.SetString(self.LabelTitle, self.tbSubPanel.szTitle)
    self:UpdateInfo()
end

function UIRobotThirdPanel:OnExit()
    self.bInit = false
    self:UnRegEvent()
end

function UIRobotThirdPanel:BindUIEvent()
    UIHelper.BindUIEvent(self.BtnCannel, EventType.OnClick, function(btn)
        if UIMgr.GetView(VIEW_ID.PanelRobotThirdSubView) then
            UIMgr.Close(VIEW_ID.PanelRobotThirdSubView)
        end
        UIMgr.Close(self)
    end)

    UIHelper.BindUIEvent(self.BtnConfirm, EventType.OnClick, function(btn)
        self.fnCallBack(self.tbCMDParams)
    end)

    UIHelper.BindUIEvent(self.BtnThirdPanelClose, EventType.OnClick, function(btn)
        if UIMgr.GetView(VIEW_ID.PanelRobotThirdSubView) then
            UIMgr.Close(VIEW_ID.PanelRobotThirdSubView)
        end
        UIMgr.Close(self)
    end)

    UIHelper.TableView_addCellAtIndexCallback(self.TableViewThirdLevel, function(tableView, nIndex, script, node, cell)
        local tbSelectCell = self.tbSubPanel.tbPanelConfig[nIndex]
        if script and tbSelectCell then
            script:OnEnter(tbSelectCell, self.tbCMDParams)
        end
    end)
end

function UIRobotThirdPanel:RegEvent()
    --Event.Reg(self, EventType.XXX, func)
end

function UIRobotThirdPanel:UnRegEvent()
    --Event.UnReg(self, EventType.XXX)
end






-- ----------------------------------------------------------
-- Please write your own code below  ↓↓↓
-- ----------------------------------------------------------

function UIRobotThirdPanel:UpdateInfo()
    UIHelper.TableView_init(self.TableViewThirdLevel, #self.tbSubPanel.tbPanelConfig, PREFAB_ID.WidgetRobotThirdLevelCell)
    UIHelper.TableView_reloadData(self.TableViewThirdLevel)
end


return UIRobotThirdPanel