-- ---------------------------------------------------------------------------------
-- Author: luwenhao1
-- Name: UIWidgetPlayerName_Color
-- Date: 2026-04-20 17:39:06
-- Desc: 大富翁 玩家名字+不同颜色底图 WidgetPlayerName_Color
-- ---------------------------------------------------------------------------------

local UIWidgetPlayerName_Color = class("UIWidgetPlayerName_Color")

function UIWidgetPlayerName_Color:OnEnter(szName, szBgPath)
    if not self.bInit then
        self:RegEvent()
        self:BindUIEvent()
        self.bInit = true
    end

    self:SetName(szName)
    self:SetColorBg(szBgPath)
end

function UIWidgetPlayerName_Color:OnExit()
    self.bInit = false
    self:UnRegEvent()
end

function UIWidgetPlayerName_Color:BindUIEvent()

end

function UIWidgetPlayerName_Color:RegEvent()
    --Event.Reg(self, EventType.XXX, func)
end

function UIWidgetPlayerName_Color:UnRegEvent()
    --Event.UnReg(self, EventType.XXX)
end

function UIWidgetPlayerName_Color:SetName(szName)
    if not szName then
        return
    end

    local _, szName = UIHelper.TruncateString(szName, 7, nil, 6)
    UIHelper.SetString(self.LabelName, szName)
end

function UIWidgetPlayerName_Color:SetColorBg(szBgPath)
    if not szBgPath then
        return
    end
    UIHelper.SetSpriteFrame(self.ImgColorBg, szBgPath)
end

return UIWidgetPlayerName_Color