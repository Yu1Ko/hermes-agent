-- ---------------------------------------------------------------------------------
-- Author: luwenhao1
-- Name: UIAnswerPopView
-- Date: 2023-06-14 15:06:04
-- Desc: 阵营攻防暂离答题窗口 PanelAnswerPop
-- ---------------------------------------------------------------------------------

local UIAnswerPopView = class("UIAnswerPopView")

local CLOSE_TIME = 30

function UIAnswerPopView:OnEnter(szProblem, tAnswer)
    self.szProblem = szProblem
    self.tAnswer = tAnswer

    if not self.bInit then
        self:RegEvent()
        self:BindUIEvent()
        self.bInit = true
    end

    self:UpdateInfo()
end

function UIAnswerPopView:OnExit()
    self.bInit = false
    self:UnRegEvent()
end

function UIAnswerPopView:BindUIEvent()
    UIHelper.BindUIEvent(self.BtnOk, EventType.OnClick, function()
        if not self.nID then
            return
        end

        print("[UIAnswerPopView] RemoteCallToServer On_Camp_CheckAnswer", self.nID)
        RemoteCallToServer("On_Camp_CheckAnswer", self.nID)
        UIMgr.Close(self)
    end)
    UIHelper.BindUIEvent(self.BtnClose, EventType.OnClick, function()
        UIMgr.Close(self)
    end)

    for i, toggle in ipairs(self.tTogAnswer) do
        local nID = i
        UIHelper.BindUIEvent(toggle, EventType.OnSelectChanged, function(_, bSelected)
            if bSelected then
                self.nID = i
                for j, otherTog in ipairs(self.tTogAnswer) do
                    if j ~= nID then
                        UIHelper.SetSelected(otherTog, false, false)
                    end
                end
            else
                self.nID = nil
            end
            self:UpdateBtnState()
        end)
    end
end

function UIAnswerPopView:RegEvent()
    --Event.Reg(self, EventType.XXX, func)
end

function UIAnswerPopView:UnRegEvent()
    --Event.UnReg(self, EventType.XXX)
end

function UIAnswerPopView:UpdateInfo()
    local szProblem = UIHelper.GBKToUTF8(self.szProblem or "")
    szProblem = string.gsub(szProblem, "%(.*%)", "") --去掉括号里的内容: "(Ctrl + M 可查看沙盘地图)"
    UIHelper.SetString(self.LabelTopic, szProblem)

    local tAnswer = self.tAnswer or {}
    for i = 1, 4 do
        if tAnswer[i] then
            local label = self.tLabelAnswer[i]
            local szAnswer = UIHelper.GBKToUTF8(tAnswer[i])
            UIHelper.SetString(label, szAnswer)
        end
    end

    --倒计时
    Timer.DelAllTimer(self)
    UIHelper.SetString(self.LabelNum, tostring(CLOSE_TIME))
    Timer.AddCountDown(self, CLOSE_TIME, function(nRemain)
        UIHelper.SetString(self.LabelNum, tostring(nRemain))
    end, function()
        UIMgr.Close(self)
    end)

    self:UpdateBtnState()
end

function UIAnswerPopView:UpdateBtnState()
    UIHelper.SetButtonState(self.BtnOk, self.nID ~= nil and BTN_STATE.Normal or BTN_STATE.Disable)
end

return UIAnswerPopView