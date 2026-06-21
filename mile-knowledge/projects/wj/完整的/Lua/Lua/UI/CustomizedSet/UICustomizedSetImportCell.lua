-- ---------------------------------------------------------------------------------
-- Author: Unknown
-- Name: UICustomizedSetImportCell
-- Date: 2024-08-27 14:09:56
-- Desc: ?
-- ---------------------------------------------------------------------------------

local UICustomizedSetImportCell = class("UICustomizedSetImportCell")

function UICustomizedSetImportCell:OnEnter(nIndex, tData)
    if not self.bInit then
        self:RegEvent()
        self:BindUIEvent()
        self.bInit = true
    end

    self.nIndex = nIndex
    self.tData = tData
    self:UpdateInfo()
end

function UICustomizedSetImportCell:OnExit()
    self.bInit = false
end

function UICustomizedSetImportCell:BindUIEvent()
    UIHelper.BindUIEvent(self.TogType, EventType.OnClick, function(btn)
        Event.Dispatch(EventType.OnSelectCustomizedSetImportCell, self.nIndex, self.tData)
    end)

end

function UICustomizedSetImportCell:RegEvent()
    --Event.Reg(self, EventType.XXX, func)
end

function UICustomizedSetImportCell:UpdateInfo()
    if self.tData then
        UIHelper.SetString(self.LabelTogName, string.format("覆盖【%s】", self.tData.title))
        UIHelper.SetString(self.LabelTogNameUp, string.format("覆盖【%s】", self.tData.title))
    else
        UIHelper.SetString(self.LabelTogName, "新建配装方案")
        UIHelper.SetString(self.LabelTogNameUp, "新建配装方案")
    end
end


return UICustomizedSetImportCell