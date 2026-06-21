-- ---------------------------------------------------------------------------------
-- Author: huqing
-- Name: UITestMarkView
-- Date: 2024-04-23 15:34:50
-- Desc: 测试标记（游戏右下角）
-- ---------------------------------------------------------------------------------

local tbHideTopViewIDs = {
    VIEW_ID.PanelSystemMenu,
    --VIEW_ID.PanelExteriorMain,
}


local UITestMarkView = class("UITestMarkView")

function UITestMarkView:OnEnter(szDesc)
    self.szDesc = szDesc

    if not self.bInit then
        self:RegEvent()
        self:BindUIEvent()
        self.bInit = true
    end

    self:UpdateInfo()
end

function UITestMarkView:OnExit()
    self.bInit = false
    self:UnRegEvent()
end

function UITestMarkView:BindUIEvent()

end

function UITestMarkView:RegEvent()
    Event.Reg(self, EventType.OnViewOpen, function()
        self:UpdateCE()
    end)

    Event.Reg(self, EventType.OnViewClose, function()
        self:UpdateCE()
    end)
end

function UITestMarkView:UnRegEvent()
    --Event.UnReg(self, EventType.XXX)
end






-- ----------------------------------------------------------
-- Please write your own code below  ↓↓↓
-- ----------------------------------------------------------

function UITestMarkView:UpdateInfo()
    UIHelper.SetString(self.LabelRightBottom, self.szDesc)
    UIHelper.SetWidth(self.ImgRightBottomBg, UIHelper.GetWidth(self.LabelRightBottom) + 120)
    UIHelper.WidgetFoceDoAlign(self)

    self:UpdateCE()
end

function UITestMarkView:UpdateCE()
    local bHide = false

    if Platform.IsMobile() then
        local nViewID = UIMgr.GetLayerTopViewID(UILayer.Page, IGNORE_TEACH_VIEW_IDS)
        if table.contain_value(tbHideTopViewIDs, nViewID) then
            bHide = true
        end
    end

    UIHelper.SetVisible(self.WidgeRightBttom, not bHide)
end


return UITestMarkView