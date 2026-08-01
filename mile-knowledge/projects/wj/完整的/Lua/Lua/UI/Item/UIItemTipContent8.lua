-- ---------------------------------------------------------------------------------
-- Author: Unknown
-- Name: UIItemTipContent8
-- Date: 2023-05-23 11:23:43
-- Desc: ?
-- ---------------------------------------------------------------------------------

local UIItemTipContent8 = class("UIItemTipContent8")

function UIItemTipContent8:OnEnter(tbInfo)
    self.tbInfo = tbInfo

    if not self.bInit then
        self:RegEvent()
        self:BindUIEvent()
        self.bInit = true
    end

    self:UpdateInfo()
end

function UIItemTipContent8:OnExit()
    self.bInit = false
end

function UIItemTipContent8:BindUIEvent()

end

function UIItemTipContent8:RegEvent()
    --Event.Reg(self, EventType.XXX, func)
end

function UIItemTipContent8:UpdateInfo()
    if not self.tbInfo or #self.tbInfo <= 0 then
        UIHelper.SetVisible(self._rootNode, false)
        return
    else
        UIHelper.SetVisible(self._rootNode, true)
    end

    for i, widget in ipairs(self.tbWidgetAttrib) do
        local tbInfo = self.tbInfo[i]
        if tbInfo then
            UIHelper.SetVisible(widget, true)

            if tbInfo.szIcon then
                UIHelper.SetSpriteFrame(self.tbImgIcon[i], tbInfo.szIcon)
            end

            if tbInfo.szDesc then
                UIHelper.SetString(self.tbLabelAttrib[i], tbInfo.szDesc)
            end
        else
            UIHelper.SetVisible(widget, false)
        end
    end
    UIHelper.LayoutDoLayout(self.LayoutAttri)
    UIHelper.LayoutDoLayout(self._rootNode)
end


return UIItemTipContent8