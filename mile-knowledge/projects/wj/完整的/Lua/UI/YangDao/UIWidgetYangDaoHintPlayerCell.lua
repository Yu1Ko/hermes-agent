-- ---------------------------------------------------------------------------------
-- Author: luwenhao1
-- Name: UIWidgetYangDaoHintPlayerCell
-- Date: 2026-03-09 19:43:02
-- Desc: 扬刀大会-报名界面提示窗口Cell WidgetYangDaoHintPlayerCell (PanelYangDaoHintPop)
-- ---------------------------------------------------------------------------------

local UIWidgetYangDaoHintPlayerCell = class("UIWidgetYangDaoHintPlayerCell")

function UIWidgetYangDaoHintPlayerCell:OnEnter(szName, dwForceID, szText)
    if not self.bInit then
        self:RegEvent()
        self:BindUIEvent()
        self.bInit = true
    end

    UIHelper.SetString(self.LabelPlayerName, szName)
    UIHelper.SetString(self.LabelProgress, szText)

    local szImgPath = PlayerForceID2SchoolImg2[dwForceID]
    UIHelper.SetSpriteFrame(self.ImgSchoolIcon, szImgPath)
end

function UIWidgetYangDaoHintPlayerCell:OnExit()
    self.bInit = false
    self:UnRegEvent()
end

function UIWidgetYangDaoHintPlayerCell:BindUIEvent()

end

function UIWidgetYangDaoHintPlayerCell:RegEvent()
    --Event.Reg(self, EventType.XXX, func)
end

function UIWidgetYangDaoHintPlayerCell:UnRegEvent()
    --Event.UnReg(self, EventType.XXX)
end

return UIWidgetYangDaoHintPlayerCell