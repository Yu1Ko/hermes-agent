-- ---------------------------------------------------------------------------------
-- Author: Unknown
-- Name: UIWidgetBillTotalView
-- Date: 2023-08-08 14:09:34
-- Desc: ?
-- ---------------------------------------------------------------------------------

local UIWidgetBillTotalView = class("UIWidgetBillTotalView")

function UIWidgetBillTotalView:OnEnter(tbData)
    if not self.bInit then
        self:RegEvent()
        self:BindUIEvent()
        self.bInit = true
    end
    self:UpdateInfo(tbData)
end

function UIWidgetBillTotalView:OnExit()
    self.bInit = false
    self:UnRegEvent()
end

function UIWidgetBillTotalView:BindUIEvent()
    
end

function UIWidgetBillTotalView:RegEvent()
    --Event.Reg(self, EventType.XXX, func)
end

function UIWidgetBillTotalView:UnRegEvent()
    --Event.UnReg(self, EventType.XXX)
end






-- ----------------------------------------------------------
-- Please write your own code below  ↓↓↓
-- ----------------------------------------------------------

function UIWidgetBillTotalView:UpdateInfo(tbData)

    local szBillContent = MahjongData.GetBillContent(tbData)
    UIHelper.SetString(self.TextInfo1Mod, szBillContent)

    local szMultiply = MahjongData.GetMultiplyText(tbData[8])
    UIHelper.SetString(self.TextInfo2Mod, szMultiply)

    local szGrade = MahjongData.GetGradeText(tbData)
    UIHelper.SetString(self.TextInfo3Mod, szGrade)

    local szAlias = MahjongData.GetAliasByDirection(tbData[2])
    UIHelper.SetString(self.TextInfo4Mod, szAlias)

end


return UIWidgetBillTotalView