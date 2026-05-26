-- ---------------------------------------------------------------------------------
-- Author: Unknown
-- Name: UIWidgetTaskLangKeXing
-- Date: 2023-05-08 14:19:10
-- Desc: ?
-- ---------------------------------------------------------------------------------

local UIWidgetTaskLangKeXing = class("UIWidgetTaskLangKeXing")

function UIWidgetTaskLangKeXing:OnEnter()
    if not self.bInit then
        self:RegEvent()
        self:BindUIEvent()
        self.bInit = true
    end
end


function UIWidgetTaskLangKeXing:OnExit()
    self.bInit = false
    self:UnRegEvent()
end

function UIWidgetTaskLangKeXing:BindUIEvent()
    UIHelper.BindUIEvent(self.BtnMode, EventType.OnClick, function()
        local szTip = UIHelper.GBKToUTF8(self.tbLKXInfo["LKX_XinQingZhi"].szTip)
        TipsHelper.ShowNodeHoverTipsInDir(PREFAB_ID.WidgetPublicLabelTips, self.BtnMode, TipsLayoutDir.BOTTOM_CENTER, ParseTextHelper.ParseNormalText(szTip))
    end)

    UIHelper.BindUIEvent(self.BtnEat, EventType.OnClick, function()
        local szTip = UIHelper.GBKToUTF8(self.tbLKXInfo["LKX_BaoShiDu"].szTip)
        TipsHelper.ShowNodeHoverTipsInDir(PREFAB_ID.WidgetPublicLabelTips, self.BtnEat, TipsLayoutDir.BOTTOM_CENTER, ParseTextHelper.ParseNormalText(szTip))
    end)
end

function UIWidgetTaskLangKeXing:RegEvent()
    --Event.Reg(self, EventType.XXX, func)
end

function UIWidgetTaskLangKeXing:UnRegEvent()
    --Event.UnReg(self, EventType.XXX)
end






-- ----------------------------------------------------------
-- Please write your own code below  ↓↓↓
-- ----------------------------------------------------------

function UIWidgetTaskLangKeXing:UpdateInfo(tbInfo)

    if not self.tbLKXInfo then self.tbLKXInfo = {} end
    self.tbLKXInfo[tbInfo.szName] = tbInfo

    local szText = ""
    if tbInfo.szName == "LKX_ShiChen" then
        szText = UIHelper.GBKToUTF8(tbInfo.szTitle)
    end
    szText = szText..self:GetValue(tbInfo)
    if tbInfo.szName == "LKX_XinQingZhi" then
        UIHelper.SetString(self.LabelMood, szText)
    elseif tbInfo.szName == "LKX_BaoShiDu" then
        UIHelper.SetString(self.LabelEat, szText)
        UIHelper.SetColor(self.LabelEat, tbInfo.szDiscrible == "" and cc.c3b(255, 255, 255) or cc.c3b(255, 118, 118))
    else
        UIHelper.SetString(self.LabelTime, szText)
    end

    self:UpdateUIInfo()

    UIHelper.SetFontSize(self.LabelTime, 26)
    UIHelper.SetFontSize(self.LabelEat, 20)
    UIHelper.SetFontSize(self.LabelMood, 20)
end

function UIWidgetTaskLangKeXing:DeleteUIInfo(szName)

    if self.tbLKXInfo and self.tbLKXInfo[szName] then
        self.tbLKXInfo[szName] = nil
    end

    self:UpdateUIInfo()
end

function UIWidgetTaskLangKeXing:UpdateUIInfo()
    UIHelper.SetVisible(self.LabelTime, self.tbLKXInfo["LKX_ShiChen"] ~= nil)
    UIHelper.SetVisible(self.BtnMode, self.tbLKXInfo["LKX_XinQingZhi"] ~= nil)
    UIHelper.SetVisible(self.BtnEat, self.tbLKXInfo["LKX_BaoShiDu"] ~= nil)

    local tbInfoList = GeneralProgressBarData.GetProgresBarList()
    UIHelper.SetVisible(self._rootNode, #tbInfoList ~= 0)
end

function UIWidgetTaskLangKeXing:GetValue(tbInfo)
    local nWay = tbInfo.nWay
	local nMolecular = tbInfo.nMolecular
	local nDenominator = tbInfo.nDenominator
	if nWay == 1 then
        local fProportion = nMolecular / nDenominator
        return math.floor(fProportion * 100) .. "%"
   	elseif nWay == 2 then
        return nMolecular .. "/" .. nDenominator
   	elseif nWay == 3 then
   		return ""
	elseif nWay == 4 then
        return nMolecular
   	end
end


return UIWidgetTaskLangKeXing