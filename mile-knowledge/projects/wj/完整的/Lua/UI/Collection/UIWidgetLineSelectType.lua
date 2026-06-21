-- ---------------------------------------------------------------------------------
-- Author: Unknown
-- Name: UIWidgetLineSelectType
-- Date: 2024-03-22 11:05:55
-- Desc: ?
-- ---------------------------------------------------------------------------------

local UIWidgetLineSelectType = class("UIWidgetLineSelectType")

function UIWidgetLineSelectType:OnEnter(tbInfo)
    if not self.bInit then
        self:RegEvent()
        self:BindUIEvent()
        self.bInit = true
    end
    self.tbInfo = tbInfo
    self:UpdateInfo()
end

function UIWidgetLineSelectType:OnExit()
    self.bInit = false
    self:UnRegEvent()
end

function UIWidgetLineSelectType:BindUIEvent()
    UIHelper.BindUIEvent(self.TogType, EventType.OnSelectChanged, function(_, bSelect)
        if bSelect then
            Event.Dispatch(EventType.OnSelectLineType, self.tbInfo.nIndex, self.tbInfo.nMapId)
        end
    end)
end

function UIWidgetLineSelectType:RegEvent()
    --Event.Reg(self, EventType.XXX, func)
end

function UIWidgetLineSelectType:UnRegEvent()
    --Event.UnReg(self, EventType.XXX)
end






-- ----------------------------------------------------------
-- Please write your own code below  ↓↓↓
-- ----------------------------------------------------------

function UIWidgetLineSelectType:UpdateInfo()
    local tbInfo = self.tbInfo
    local szContent = ""
    if tbInfo.szNum ~= "" then
        szContent = tbInfo.szName .. "(" ..tbInfo.szNum .. ")"
    else
        szContent = tbInfo.szName
    end
    UIHelper.SetString(self.LabelAllSuit, szContent)
    UIHelper.SetVisible(self.WidgetTipRight1, tbInfo.bMainBattleField)
    UIHelper.SetVisible(self.WidgetTipRight2, tbInfo.bQixi)
end


return UIWidgetLineSelectType