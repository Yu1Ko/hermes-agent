-- ---------------------------------------------------------------------------------
-- Author: Unknown
-- Name: UIWidgetMatchCell
-- Date: 2025-12-26 14:58:04
-- Desc: ?
-- ---------------------------------------------------------------------------------

local UIWidgetMatchCell = class("UIWidgetMatchCell")
local tbCellBreakAni = {
    gold = "AniEliminate_YuanBao",
    purple = "AniEliminate_HuaBan",
    blue = "AniEliminate_TangYuan",
    red = "AniEliminate_DengLong"
}

function UIWidgetMatchCell:OnEnter()
    if not self.bInit then
        self:RegEvent()
        self:BindUIEvent()
        self.bInit = true
    end
end

function UIWidgetMatchCell:OnExit()
    self.bInit = false
    self:UnRegEvent()
end

function UIWidgetMatchCell:BindUIEvent()
    
end

function UIWidgetMatchCell:RegEvent()
    --Event.Reg(self, EventType.XXX, func)
end

function UIWidgetMatchCell:UnRegEvent()
    --Event.UnReg(self, EventType.XXX)
end






-- ----------------------------------------------------------
-- Please write your own code below  ↓↓↓
-- ----------------------------------------------------------

function UIWidgetMatchCell:UpdateInfo(szImg, szColor)
    self:SetIconVisible(false)
    UIHelper.StopAni(self, self.AniAll, tbCellBreakAni[self.szColor])
    self.__bNilColorAniPlayed = self.__bNilColorAniPlayed or false
    if szColor then
        self.__bNilColorAniPlayed = false
        self.szColor = szColor
        -- local r, g, b = unpack(tbBgColor)
        -- UIHelper.SetColor(self.ImgBg, cc.c3b(r, g, b))
        UIHelper.SetSpriteFrame(self.ImgIcon, szImg)
        self:SetIconVisible(true)
    else
        if not self.__bNilColorAniPlayed then
            self.__bNilColorAniPlayed = true
            UIHelper.PlayAni(self, self.AniAll, tbCellBreakAni[self.szColor], function ()
                self:SetIconVisible(true)
            end)
        else
            self:SetIconVisible(false)
        end
    end

    if UIHelper.GetSelected(self.TogMatch) then
        UIHelper.SetSelected(self.TogMatch, false)
        UIHelper.SetVisible(self.ImgChoose, false)
    end
end

function UIWidgetMatchCell:BindClick(callback)
    UIHelper.BindUIEvent(self.TogMatch, EventType.OnSelectChanged, function(_, bSelected)
        if bSelected and callback then
            callback()
        end
    end)
end

function UIWidgetMatchCell:SetInteractive(bEnable)
    UIHelper.SetEnable(self.TogMatch, bEnable)
end

function UIWidgetMatchCell:SetIconVisible(bVisible)
    UIHelper.SetVisible(self.ImgIcon, bVisible)
end

return UIWidgetMatchCell