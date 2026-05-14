-- ---------------------------------------------------------------------------------
-- Author: Unknown
-- Name: UICharacterPendantItem
-- Date: 2023-03-06 15:25:59
-- Desc: ?
-- ---------------------------------------------------------------------------------

local szGreen = "#95ff95"
local szInActivated = "#94ACB9"

local UIWidgetPowerUpAttriCell = class("UIWidgetPowerUpAttriCell")
function UIWidgetPowerUpAttriCell:OnEnter(szText, nVal, nDiff, nCount, bQuality)
    if not self.bInit then
        self:RegEvent()
        self:BindUIEvent()
        self.bInit = true
    end

    if not nVal and not nDiff then
        UIHelper.SetVisible(self.LayoutNum, false)
        UIHelper.SetWidth(self.RichTextAttri, 420)
        UIHelper.SetRichText(self.RichTextAttri, szText)
        return
    end
    szText = string.gsub(szText, "提高", function()
        return ""
    end)
    UIHelper.SetRichText(self.RichTextAttri, szText)

    UIHelper.SetRichText(self.RichTextNum02, UIHelper.AttachTextColor(tostring(nDiff + nVal), bQuality and UI_SUCCESS_COLOR or szGreen))
    UIHelper.SetVisible(self.ImgBg, (nCount % 2) == 1)

    if not nDiff or nDiff == 0 then
        UIHelper.SetRichText(self.RichTextNum01, UIHelper.AttachTextColor(tostring(nVal), szInActivated))
        UIHelper.SetVisible(self.ImgArrow, false)
        UIHelper.SetVisible(self.RichTextNum02, false)
    else
        UIHelper.SetRichText(self.RichTextNum01, UIHelper.AttachTextColor(string.format("%d (+%d)", nVal, nDiff), szInActivated))
    end
    --local szPattern = "<color=#ffffff>属性描述</c><color=#79EAB4>新增属性</c><color=#9DFFA6>属性" .. "增量</c><color=#ECDF22>品级及增量</c>"
end

function UIWidgetPowerUpAttriCell:OnExit()
    self.bInit = false
end

function UIWidgetPowerUpAttriCell:BindUIEvent()

end

function UIWidgetPowerUpAttriCell:RegEvent()
    --Event.Reg(self, EventType.XXX, func)
end

function UIWidgetPowerUpAttriCell:ShowSpecialBg()
    UIHelper.SetVisible(self.ImgBgSpecialHint, true)
    UIHelper.SetVisible(self.ImgBg, false)
end

return UIWidgetPowerUpAttriCell