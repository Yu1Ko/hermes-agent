-- ---------------------------------------------------------------------------------
-- Author: Unknown
-- Name: UIExaminationQuestion
-- Date: 2023-03-15 16:57:50
-- Desc: ?
-- ---------------------------------------------------------------------------------

local UIExaminationQuestion = class("UIExaminationQuestion")

function UIExaminationQuestion:OnEnter(nQuestionIndex)
    if not self.bInit then
        self:RegEvent()
        self:BindUIEvent()
        self.bInit = true
    end
    self.nQuestionIndex = nQuestionIndex
    if nQuestionIndex == 1 then UIHelper.SetSelected(self.TogQuestion,true) end
    UIHelper.SetString(self.LabelNormalQuestion,  g_tStrings.STR_NUMBER[nQuestionIndex])
    UIHelper.SetString(self.LabelQuestionSelect, g_tStrings.STR_NUMBER[nQuestionIndex])
    UIHelper.SetString(self.LabelQuestionFinish, g_tStrings.STR_NUMBER[nQuestionIndex])
end

function UIExaminationQuestion:OnExit()
    self.bInit = false
    self:UnRegEvent()
end

function UIExaminationQuestion:BindUIEvent()
    UIHelper.BindUIEvent(self.TogQuestion,EventType.OnSelectChanged,function (_,bSelected)
        if bSelected then
            Event.Dispatch(EventType.OnSelectQuestion,self.nQuestionIndex)
        end
    end)
end

function UIExaminationQuestion:RegEvent()
    --Event.Reg(self, EventType.XXX, func)
end

function UIExaminationQuestion:UnRegEvent()
    --Event.UnReg(self, EventType.XXX)
end






-- ----------------------------------------------------------
-- Please write your own code below  ↓↓↓
-- ----------------------------------------------------------

function UIExaminationQuestion:UpdateInfo()

end


return UIExaminationQuestion