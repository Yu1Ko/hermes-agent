-- ---------------------------------------------------------------------------------
-- Author: Unknown
-- Name: UIRobotCaseView
-- Date: 2023-09-20 10:01:53
-- Desc: ?
-- ---------------------------------------------------------------------------------

local UIRobotCaseView = class("UIRobotCaseView")



function UIRobotCaseView:OnEnter(tCaseInfo)
    if not self.bInit then
        self:RegEvent()
        self:BindUIEvent()
        self.bInit = true
    end
    self.CallBack = tCaseInfo.callback
    self.tParams = tCaseInfo.tParams
    UIHelper.SetString(self.LabelCaseName, tCaseInfo.szCaseName)
    UIHelper.TableView_init(self.TableViewParam, #tCaseInfo.tParams, PREFAB_ID.WidgetParamCell)
    UIHelper.TableView_reloadData(self.TableViewParam)
end

function UIRobotCaseView:OnExit()
    self.bInit = false
    self:UnRegEvent()
end

function UIRobotCaseView:BindUIEvent()
    UIHelper.BindUIEvent(self.BtnClose, EventType.OnClick, function(btn)
        UIMgr.Close(self)
    end)

    UIHelper.BindUIEvent(self.BtnConfirm, EventType.OnClick, function(btn)
        -- 这里加一个机器人启动逻辑
        self.CallBack(self.tParams)
        UIMgr.Close(self)
    end)

    -- UIHelper.BindUIEvent(self.BtnReset, EventType.OnClick, function(btn)
    --     UIHelper.TableView_init(self.TableViewParam, #self.tParams, PREFAB_ID.WidgetParamCell)
    --     UIHelper.TableView_reloadData(self.TableViewParam)
    -- end)

    UIHelper.TableView_addCellAtIndexCallback(self.TableViewParam, function(tableView, nIndex, script, node, cell)
        if script then
            script:OnEnter(self, self.tParams[nIndex])
        end
    end)

    UIHelper.TableView_addCellAtIndexCallback(self.ParamOptional, function(tableView, nIndex, script, node, cell)
        local callback = function ()
            self.ViewSelection:setVisible(false)
        end

        if script then
            script:OnEnter(self.tOptional[nIndex], callback, self.ParamCellCallBack)
        end
    end)
end

function UIRobotCaseView:RegEvent()
    --Event.Reg(self, EventType.XXX, func)
end

function UIRobotCaseView:UnRegEvent()
    --Event.UnReg(self, EventType.XXX)
end






-- ----------------------------------------------------------
-- Please write your own code below  ↓↓↓
-- ----------------------------------------------------------

function UIRobotCaseView:UpdateInfo(tOptional, callback)
    if tOptional and next(tOptional) then
        self.tOptional = tOptional
        self.ViewSelection:setVisible(true)
        self.ParamCellCallBack = callback
        UIHelper.TableView_init(self.ParamOptional, #tOptional, PREFAB_ID.WidgetParamOptional)
        UIHelper.TableView_reloadData(self.ParamOptional)
    else
        self.ViewSelection:setVisible(false)
    end
end


return UIRobotCaseView