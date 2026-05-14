-- ---------------------------------------------------------------------------------
-- Author: Unknown
-- Name: UIUIWidgetCompeteListCell
-- Date: 2023-05-29 10:36:57
-- Desc: WidgetCompeteListCell 攻防结算界面 Cell
-- ---------------------------------------------------------------------------------

local UIWidgetCompeteListCell = class("UIWidgetCompeteListCell")

function UIWidgetCompeteListCell:OnEnter(tLineData)
    if not tLineData then
        return
    end

    self.tLineData = tLineData

    if not self.bInit then
        self:RegEvent()
        self:BindUIEvent()
        self.bInit = true
    end

    self:UpdateInfo()
end

function UIWidgetCompeteListCell:OnExit()
    self.bInit = false
    self:UnRegEvent()
end

function UIWidgetCompeteListCell:OnPoolAllocated(tLineData)
    self:OnEnter(tLineData)
end

function UIWidgetCompeteListCell:OnPoolRecycled()
    self:OnExit()
end

function UIWidgetCompeteListCell:BindUIEvent()
    
end

function UIWidgetCompeteListCell:RegEvent()
    --Event.Reg(self, EventType.XXX, func)
end

function UIWidgetCompeteListCell:UnRegEvent()
    --Event.UnReg(self, EventType.XXX)
end

function UIWidgetCompeteListCell:UpdateInfo()
    local tLine = self.tLineData
    if not tLine then
        return
    end

    --左
    UIHelper.SetString(self.LabelSettleNum, tLine.nScore_HQ)
    UIHelper.SetString(self.LabelPointNum, tLine.szCount_HQ)
    UIHelper.SetString(self.LabelDangerNum, tLine.szTitle)

    --右
    UIHelper.SetString(self.LabelDangerNum1, tLine.szTitle)
    UIHelper.SetString(self.LabelPlayerName, tLine.nScore_ER)
    UIHelper.SetString(self.LabelWoundNum, tLine.szCount_ER)

    -- TODO Tip?
    -- if tLine.szLinkTip and #tLine.szLinkTip > 0 then
    --     UIHelper.SetString(self.XXX, tLine.szLinkTip or "")
    -- end
end


return UIWidgetCompeteListCell