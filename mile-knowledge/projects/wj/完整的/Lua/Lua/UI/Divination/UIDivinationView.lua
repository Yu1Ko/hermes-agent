-- ---------------------------------------------------------------------------------
-- Author: Unknown
-- Name: UIDivinationView
-- Date: 2023-05-17 15:36:03
-- Desc: ?
-- ---------------------------------------------------------------------------------

local UIDivinationView = class("UIDivinationView")

function UIDivinationView:OnEnter(tbParam ,tbInfo)
    if not self.bInit then
        self:RegEvent()
        self:BindUIEvent()
        self.bInit = true
    end
    self.tbParam = tbParam
    self.tbInfo = tbInfo
    self:UpdateInfo()
end

function UIDivinationView:OnExit()
    self.bInit = false
    self:UnRegEvent()
end

function UIDivinationView:BindUIEvent()
    UIHelper.BindUIEvent(self.BtnPress, EventType.OnClick, function()
        UIHelper.StopAni(self, self.WidgetAniLotPot, "AniLotPotLoop")
        UIHelper.PlayAni(self, self.WidgetAniLotPot, "AniPressSignin", function() 
            RemoteCallToServer("On_Map_DivinationRequest")
        end)
    end)
end

function UIDivinationView:RegEvent()
    --Event.Reg(self, EventType.XXX, func)
    Event.Reg(self, EventType.OnTouchViewBackGround, function()
        UIMgr.Close(self)
    end)
end

function UIDivinationView:UnRegEvent()
    --Event.UnReg(self, EventType.XXX)
end





-- ----------------------------------------------------------
-- Please write your own code below  ↓↓↓
-- ----------------------------------------------------------

function UIDivinationView:UpdateInfo()

    UIHelper.SetVisible(self.WidgetLotBig, self.tbParam.bEnd ~= nil and self.tbParam.bEnd == true)
    UIHelper.SetVisible(self.WidgetAnchorDrawedNew, self.tbParam.bEnd ~= nil and self.tbParam.bEnd == true)
    UIHelper.SetVisible(self.BtnPress, self.tbParam.bBegin ~= nil and self.tbParam.bBegin == true)
    UIHelper.SetVisible(self.WidgetLotPot, self.tbParam.bBegin ~= nil and self.tbParam.bBegin == true)

    local tbText = string.split(UIHelper.GBKToUTF8(self.tbInfo.szSignetText), "，")
    local szText1 = tbText[1].."，"
    local szText2 = tbText[2]

    UIHelper.SetString(self.LabelContent, UIHelper.GBKToUTF8(self.tbInfo.szSignetText))
    UIHelper.LayoutDoLayout(self.LayoutPoets)

    if self.tbParam.bBegin ~= nil and self.tbParam.bBegin == true then
        UIHelper.PlayAni(self, self.WidgetAniLotPot, "AniLotPotLoop", function() end, 2)
    else

    end

end


return UIDivinationView