-- ---------------------------------------------------------------------------------
-- Author: Unknown
-- Name: UIWidgetOldDialogueContent9
-- Date: 2023-09-04 19:41:32
-- Desc: ?
-- ---------------------------------------------------------------------------------

local UIWidgetOldDialogueContent9 = class("UIWidgetOldDialogueContent9")

function UIWidgetOldDialogueContent9:OnEnter(tbData)
    if not self.bInit then
        self:RegEvent()
        self:BindUIEvent()
        self.bInit = true
    end

    self.tbData = tbData
    self:UpdateInfo()
end

function UIWidgetOldDialogueContent9:OnExit()
    self.bInit = false
end

function UIWidgetOldDialogueContent9:BindUIEvent()

end

function UIWidgetOldDialogueContent9:RegEvent()
    --Event.Reg(self, EventType.XXX, func)
end

function UIWidgetOldDialogueContent9:UpdateInfo()
    if not self.tbData then
        return
    end

    local tbInfo = self.tbData.tbInfo
    UIHelper.SetString(self.LabelChoose, tbInfo[1].szContent)
    UIHelper.SetString(self.LabelNum, tbInfo[3].szContent)

    UIHelper.BindUIEvent(self.BtnDown, EventType.OnClick, function ()
        if tbInfo[2] and tbInfo[2].callback then
            tbInfo[2].callback()
        end
    end)

    UIHelper.BindUIEvent(self.BtnUp, EventType.OnClick, function ()
        if tbInfo[4] and tbInfo[4].callback then
            tbInfo[4].callback()
        end
    end)
end


return UIWidgetOldDialogueContent9