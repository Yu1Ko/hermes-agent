-- ---------------------------------------------------------------------------------
-- Author: Unknown
-- Name: UINameCardDescribe
-- Date: 2023-04-13 10:30:43
-- Desc: ?
-- ---------------------------------------------------------------------------------

local UINameCardDescribe = class("UINameCardDescribe")

function UINameCardDescribe:OnEnter(szText,bChangeColor)
    if not self.bInit then
        self:RegEvent()
        self:BindUIEvent()
        self.bInit = true
    end
    local szUtfText = UIHelper.GBKToUTF8(szText)
    szUtfText = ParseTextHelper.ParseNormalText(szUtfText)
    if bChangeColor then
        UIHelper.SetRichText(self.LabelMessageMiniTips,"<color=#5ae3a2>"..szUtfText.."</color>")
    else
        UIHelper.SetRichText(self.LabelMessageMiniTips,"<color=#ffcf65>"..szUtfText.."</color>")
    end
    UIHelper.LayoutDoLayout(self.ImgDescribeBg)
    UIHelper.LayoutDoLayout(self.WidgetDescribe)
end

function UINameCardDescribe:OnExit()
    self.bInit = false
    self:UnRegEvent()
end

function UINameCardDescribe:BindUIEvent()
    
end

function UINameCardDescribe:RegEvent()
    --Event.Reg(self, EventType.XXX, func)
end

function UINameCardDescribe:UnRegEvent()
    --Event.UnReg(self, EventType.XXX)
end






-- ----------------------------------------------------------
-- Please write your own code below  ↓↓↓
-- ----------------------------------------------------------

function UINameCardDescribe:UpdateInfo()
    
end


return UINameCardDescribe