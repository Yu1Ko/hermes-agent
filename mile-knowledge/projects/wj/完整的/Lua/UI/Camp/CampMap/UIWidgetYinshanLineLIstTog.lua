-- ---------------------------------------------------------------------------------
-- Author: luwenhao1
-- Name: UIWidgetYinshanLineLIstTog
-- Date: 2024-03-22 10:51:16
-- Desc: WidgetYinshanLineLIstTog
-- ---------------------------------------------------------------------------------

local UIWidgetYinshanLineLIstTog = class("UIWidgetYinshanLineLIstTog")

function UIWidgetYinshanLineLIstTog:OnEnter(nCopyIndex)
    if not self.bInit then
        self:RegEvent()
        self:BindUIEvent()
        self.bInit = true
    end

    self.nCopyIndex = nCopyIndex

    self:UpdateInfo()
end

function UIWidgetYinshanLineLIstTog:OnExit()
    self.bInit = false
    self:UnRegEvent()
end

function UIWidgetYinshanLineLIstTog:BindUIEvent()
    UIHelper.BindUIEvent(self.ToggleYinshanLineList, EventType.OnSelectChanged, function(_, bSelected)
        if self.fnCallback then
            self.fnCallback(bSelected)
        end
    end)
end

function UIWidgetYinshanLineLIstTog:RegEvent()
    --Event.Reg(self, EventType.XXX, func)
end

function UIWidgetYinshanLineLIstTog:UnRegEvent()
    --Event.UnReg(self, EventType.XXX)
end






-- ----------------------------------------------------------
-- Please write your own code below  ↓↓↓
-- ----------------------------------------------------------

function UIWidgetYinshanLineLIstTog:UpdateInfo()
    local szName = FormatString(g_tStrings.STR_BATTLE_BRANCH_NAME, self.nCopyIndex)
    UIHelper.SetString(self.LabelYinshanLineListName1, szName)
    UIHelper.SetString(self.LabelYinshanLineListName2, szName)
    UIHelper.SetString(self.LabelYinshanLineListName11, "0/200")
    UIHelper.SetString(self.LabelYinshanLineListName22, "0/200")
end

function UIWidgetYinshanLineLIstTog:SetPlayerNum(nNum, nMax)
    nNum = nNum or 0
    nMax = nMax or 200
    local szNum = nNum .. "/" .. nMax
    UIHelper.SetString(self.LabelYinshanLineListName11, szNum)
    UIHelper.SetString(self.LabelYinshanLineListName22, szNum)
end

function UIWidgetYinshanLineLIstTog:SetNowVisible(bVisible)
    --UIHelper.SetVisible() --TODO
end

function UIWidgetYinshanLineLIstTog:SetSelectedCallback(fnCallback)
    self.fnCallback = fnCallback
end

function UIWidgetYinshanLineLIstTog:SetSelected(bSelected, bCallback)
    UIHelper.SetSelected(self.ToggleYinshanLineList, bSelected, bCallback)
end

function UIWidgetYinshanLineLIstTog:GetSelected()
    UIHelper.GetSelected(self.ToggleYinshanLineList)
end

return UIWidgetYinshanLineLIstTog