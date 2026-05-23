-- PanelShowSetUpPop

local UICareerCompeteFliter = class("UICareerCompeteFliter")
local tOldData = {}

function UICareerCompeteFliter:OnEnter(tData)
    self.tData = tData
    for i = 1, 6 do
        tOldData[i] = tData[i]
    end
    if not self.bInit then
        self:RegEvent()
        self:BindUIEvent()
        self.bInit = true
    end
    self:UpdateInfo()
end

function UICareerCompeteFliter:OnExit()
    self.bInit = false
    self:UnRegEvent()
end

function UICareerCompeteFliter:BindUIEvent()
    UIHelper.BindUIEvent(self.BtnClose, EventType.OnClick, function ()
        self:UpdateFliter()
        UIMgr.Close(VIEW_ID.PanelShowSetUpPop)
    end)

    for index, tog in ipairs(self.tbTogGroup) do
        UIHelper.BindUIEvent(tog, EventType.OnClick, function ()
            self:UpdateData(index)
        end)
    end
end

function UICareerCompeteFliter:RegEvent()
    --
end

function UICareerCompeteFliter:UnRegEvent()
    --Event.UnReg(self, EventType.XXX)
end

function UICareerCompeteFliter:UpdateInfo()
    for i = 1, 6 do
        UIHelper.SetSelected(self.tbTogGroup[i], self.tData[i])
    end
end

function UICareerCompeteFliter:UpdateData(index)
    self.tData[index] = not self.tData[index]
    UIHelper.SetSelected(self.tbTogGroup[index], self.tData[index])
end

function UICareerCompeteFliter:UpdateFliter()
    for i = 1, 6 do
        if self.tData[i] ~= tOldData[i] then
            FireUIEvent("CareerCompeteFliter", self.tData)
            return
        end
    end
end

return UICareerCompeteFliter