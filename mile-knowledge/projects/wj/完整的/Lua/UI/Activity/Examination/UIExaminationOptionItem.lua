-- ---------------------------------------------------------------------------------
-- Author: Unknown
-- Name: UIExaminationOptionItem
-- Date: 2023-03-13 19:51:58
-- Desc: ?
-- ---------------------------------------------------------------------------------

local UIExaminationOptionItem = class("UIExaminationOptionItem")

function UIExaminationOptionItem:OnEnter(nType,nIndex,szContent,bSelected)
    if not self.bInit then
        self:RegEvent()
        self:BindUIEvent()
        self.bInit = true
    end
    self.bMultiple = nType == 2
    self.nAnswerID = nIndex
    self.szContent = szContent
    self:UpdateInfo(bSelected)
end

function UIExaminationOptionItem:OnExit()
    self.bInit = false
    self:UnRegEvent()
end

function UIExaminationOptionItem:BindUIEvent()
    UIHelper.BindUIEvent(self.TogRadioOption,EventType.OnSelectChanged,function (tog,bSelected)
        if bSelected then
            Event.Dispatch(EventType.OnSelectAnswer,self.nAnswerID)
        end
    end)
    UIHelper.BindUIEvent(self.TogMultipleOption,EventType.OnSelectChanged,function (_,bSelected)
        Event.Dispatch(EventType.OnSelectAnswer,self.nAnswerID,bSelected)
    end)
end

function UIExaminationOptionItem:RegEvent()
    --Event.Reg(self, EventType.XXX, func)
end

function UIExaminationOptionItem:UnRegEvent()
    --Event.UnReg(self, EventType.XXX)
end






-- ----------------------------------------------------------
-- Please write your own code below  ↓↓↓
-- ----------------------------------------------------------

function UIExaminationOptionItem:UpdateInfo(bSelected)
    UIHelper.SetVisible(self.TogRadioOption, not self.bMultiple)
    UIHelper.SetVisible(self.TogMultipleOption, self.bMultiple)
    UIHelper.SetString(self.bMultiple and self.LabelNormalMultipleOption or self.LabelNormalRadioOption, self.szContent)
    if bSelected and not self.bMultiple then
        UIHelper.SetSelected(self.TogRadioOption,bSelected)
    elseif bSelected and self.bMultiple then
        UIHelper.SetSelected(self.TogMultipleOption,bSelected)
    end
end


return UIExaminationOptionItem