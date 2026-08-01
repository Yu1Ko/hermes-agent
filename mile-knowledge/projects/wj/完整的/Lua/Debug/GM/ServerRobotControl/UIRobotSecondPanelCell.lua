local UIRobotSecondPanelCell = class("UIRobotSecondPanelCell")

function UIRobotSecondPanelCell:OnEnter(tbCellData)
    if not self.bInit then
        self:RegEvent()
        self:BindUIEvent()
        self.bInit = true
    end
    if tbCellData then
        UIHelper.SetString(self.LabelContent, tbCellData.szlabel)
        UIHelper.SetVisible(self.BtnSetParams, false)
        if tbCellData.bNeedBtn then
            UIHelper.SetVisible(self.BtnSetParams, tbCellData.bNeedBtn)
        end
        self.tbCellData = tbCellData
    else
        self:OnExit()
    end
    
end

function UIRobotSecondPanelCell:OnExit()
    self.bInit = false
    self:UnRegEvent()
end

function UIRobotSecondPanelCell:BindUIEvent()
    UIHelper.BindUIEvent(self.BtnSetParams, EventType.OnClick, function(btn)
        UIMgr.Open(VIEW_ID.PanelRobotThirdLevel, self.tbCellData)
    end)

    UIHelper.BindUIEvent(self.BtnExecute, EventType.OnClick, function(btn)
        self.tbCellData.fnCallBack(self.tbCellData.tbCMDParams)
    end)
end

function UIRobotSecondPanelCell:RegEvent()
    --Event.Reg(self, EventType.XXX, func)
end

function UIRobotSecondPanelCell:UnRegEvent()
    --Event.UnReg(self, EventType.XXX)
end






-- ----------------------------------------------------------
-- Please write your own code below  ↓↓↓
-- ----------------------------------------------------------

function UIRobotSecondPanelCell:UpdateInfo()
    
end


return UIRobotSecondPanelCell