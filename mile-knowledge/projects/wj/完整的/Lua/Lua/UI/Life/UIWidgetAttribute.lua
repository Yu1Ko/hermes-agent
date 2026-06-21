-- ---------------------------------------------------------------------------------
-- Author: Unknown
-- Name: UIWidgetAttribute
-- Date: 2022-12-23 10:55:15
-- Desc: ?
-- ---------------------------------------------------------------------------------

local UIWidgetAttribute = class("UIWidgetAttribute")
function UIWidgetAttribute:OnEnter(tCubAttribute, tAttrInfo, tDomesticate)
    if not self.bInit then
        self:RegEvent()
        self:BindUIEvent()
        self.bInit = true
    end
    self:UpdateInfo(tCubAttribute, tAttrInfo, tDomesticate)
end

function UIWidgetAttribute:OnExit()
    self.bInit = false
    self:UnRegEvent()
end

function UIWidgetAttribute:BindUIEvent()
    
end

function UIWidgetAttribute:RegEvent()
    --Event.Reg(self, EventType.XXX, func)
end

function UIWidgetAttribute:UnRegEvent()
    --Event.UnReg(self, EventType.XXX)
end

function UIWidgetAttribute:UpdateInfo(tCubAttribute, tAttrInfo, tDomesticate)
    ItemData.FormatAttributeValue(tAttrInfo)
    local nLevel = tDomesticate.nGrowthLevel
    local nMaxLevel = tDomesticate.nMaxGrowthLevel
    local szName = tCubAttribute.szName
    local szValue = ""
    local szNextValue = ""
    if tAttrInfo.Param0 then
        szValue = FormatString(tCubAttribute.szValue, tAttrInfo.Param0, tAttrInfo.Param1, tAttrInfo.Param2, tAttrInfo.Param3, nLevel, nMaxLevel)
        szNextValue = FormatString(tCubAttribute.szValue, tAttrInfo.Param0, tAttrInfo.Param1, tAttrInfo.Param2, tAttrInfo.Param3, nLevel + 1, nMaxLevel)
    else
        szValue = FormatString(tCubAttribute.szValue,  tAttrInfo.nMin, tAttrInfo.nMax, 0, 0, nLevel, nMaxLevel)
        szNextValue = FormatString(tCubAttribute.szValue, tAttrInfo.nMin, tAttrInfo.nMax, 0, 0, nLevel + 1, nMaxLevel)
    end
    szName = UIHelper.GBKToUTF8(szName)
    szValue = UIHelper.GBKToUTF8(szValue)
    szNextValue = UIHelper.GBKToUTF8(szNextValue)
    szValue = string.gsub(szValue, "提高", "+")
    szValue = string.gsub(szValue, "降低", "-")
    szNextValue = string.gsub(szNextValue, "提高", "+")
    szNextValue = string.gsub(szNextValue, "降低", "-")
    UIHelper.SetString(self.LabelPropertyTitle, szName)
    if nLevel < nMaxLevel then
        UIHelper.SetString(self.LabelPropetyGrade01, szValue)
        UIHelper.SetString(self.LabelPropetyGrade02, szNextValue)
    else
        UIHelper.SetString(self.LabelPropetyGrade02, szValue)
    end
    UIHelper.SetVisible(self.LabelPropetyGrade01, nLevel < nMaxLevel)
end

return UIWidgetAttribute