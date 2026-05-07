-- ---------------------------------------------------------------------------------
-- Author: Unknown
-- Name: UIWidgetPoneKongView
-- Date: 2023-08-07 11:43:41
-- Desc: ?
-- ---------------------------------------------------------------------------------
local UIWidgetPoneKongView = class("UIWidgetPoneKongView")

function UIWidgetPoneKongView:OnEnter(tbCardlistInfo, nUIDirection)
    if not self.bInit then
        self:RegEvent()
        self:BindUIEvent()
        self.bInit = true
    end
    self.tbCardlistInfo = tbCardlistInfo
    self.nUIDirection = nUIDirection
    self:UpdateInfo()
end

function UIWidgetPoneKongView:OnExit()
    self.bInit = false
    self:UnRegEvent()
end

function UIWidgetPoneKongView:BindUIEvent()
    
end

function UIWidgetPoneKongView:RegEvent()
    --Event.Reg(self, EventType.XXX, func)
end

function UIWidgetPoneKongView:UnRegEvent()
    --Event.UnReg(self, EventType.XXX)
end






-- ----------------------------------------------------------
-- Please write your own code below  ↓↓↓
-- ----------------------------------------------------------

function UIWidgetPoneKongView:UpdateInfo()
    local nUIDirection = self.nUIDirection
    local tbCardlistInfo = self.tbCardlistInfo

    if self.WidgetLeft then
        UIHelper.SetVisible(self.WidgetLeft, nUIDirection == tUIPosIndex.Left)
    end

    if self.WidgetRight then
        UIHelper.SetVisible(self.WidgetRight, nUIDirection == tUIPosIndex.Right)
    end

    if self.WidgetDown then
        UIHelper.SetVisible(self.WidgetDown, nUIDirection == tUIPosIndex.Down)
    end

    if self.WidgetUp then
        UIHelper.SetVisible(self.WidgetUp, nUIDirection == tUIPosIndex.Up)
    end

    for nIndex, tbCard in ipairs(tbCardlistInfo) do
        if self.tbImage1 then
            UIHelper.SetVisible(self.tbImage1[nIndex], tbCard.bShow)
            UIHelper.SetSpriteFrame(self.tbImage1[nIndex], tbCard.szImage)
        end

        if self.tbImage2 then
            UIHelper.SetVisible(self.tbImage2[nIndex], tbCard.bShow)
            UIHelper.SetSpriteFrame(self.tbImage2[nIndex], tbCard.szImage)
        end
    end

end

return UIWidgetPoneKongView