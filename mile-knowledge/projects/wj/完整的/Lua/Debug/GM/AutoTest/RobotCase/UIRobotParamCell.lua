-- ---------------------------------------------------------------------------------
-- Author: Unknown
-- Name: UIRobotParamCell
-- Date: 2023-09-20 09:58:10
-- Desc: ?
-- ---------------------------------------------------------------------------------

local UIRobotParamCell = class("UIRobotParamCell")

function UIRobotParamCell:OnEnter(tCaseView, tParam)
    if not self.bInit then
        self:RegEvent()
        self:BindUIEvent()
        self.bInit = true
    end
    self.tCaseView = tCaseView
    self.tParam = tParam
    UIHelper.SetString(self.ParamTitle, tParam.paramName)
    UIHelper.SetString(self.EditBoxParam, tParam.paramValue)
end

function UIRobotParamCell:OnExit()
    self.bInit = false
    self:UnRegEvent()
end

function UIRobotParamCell:BindUIEvent()
    UIHelper.RegisterEditBox(self.EditBoxParam, function()
        local szSearchkey = UIHelper.GetString(self.EditBoxParam)
        self:UpdateInfo(szSearchkey)
    end)
end

function UIRobotParamCell:RegEvent()
    --Event.Reg(self, EventType.XXX, func)
end

function UIRobotParamCell:UnRegEvent()
    --Event.UnReg(self, EventType.XXX)
end






-- ----------------------------------------------------------
-- Please write your own code below  ↓↓↓
-- ----------------------------------------------------------

function UIRobotParamCell:UpdateInfo(szSearchkey)
    local setParamValue = function (paramValue)
        UIHelper.SetString(self.EditBoxParam, paramValue)
        for _, param in ipairs(self.tCaseView.tParams) do
            if param.paramName == self.tParam.paramName then
                param.paramValue = paramValue
                break
            end
        end
    end
    for _, param in ipairs(self.tCaseView.tParams) do
        if param.paramName == self.tParam.paramName then
            param.paramValue = szSearchkey
            break
        end
    end

    local tSearchTable = {}
    if szSearchkey ~= "" then 
        for _, tData in pairs(self.tParam.paramTable) do
            local szDataName = tData.OptionalName
            if szDataName and string.find(szDataName, szSearchkey) then
                table.insert(tSearchTable, tData)
            end
        end
    else
        tSearchTable = self.tParam.paramTable
    end
    self.tCaseView:UpdateInfo(tSearchTable, setParamValue)
end


return UIRobotParamCell