-- ---------------------------------------------------------------------------------
-- Author: Unknown
-- Name: UIPanelInterludeView
-- Date: 2023-11-28 14:55:04
-- Desc: ?
-- ---------------------------------------------------------------------------------
local tbInterludeType = {
    ["/ui/Config/Default/InterludePanel.ini"] = {szAnimName = "AniForwardShow", szNodeName = "WidgetDeco"},
    ["/ui/Config/Default/InterludeHPanel.ini"] = {szAnimName = "AniForwardShow", szNodeName = "WidgetDeco"},
    ["/ui/Config/Default/InterludeNPanel.ini"] = {szAnimName = "AniReverseShow", szNodeName = "WidgetDeco"},
    ["/ui/Config/Default/InterludeHNPanel.ini"] = {szAnimName = "AniReverseShow", szNodeName = "WidgetDeco"},
    ["/ui/Config/Default/InterludeQSMYPanel.ini"] = {szAnimName = "AniQinShiMingYueShow", szNodeName = "WidgetQinShiMingYue"},
    ["/ui/Config/Default/InterludePanelS.ini"] = {szAnimName = "AniCommonShow", szNodeName = "WidgetDeco"}, --接天气的时候发现这个没接，临时接一下
    ["/ui/Config/Default/InterludeGFTQPanel.ini"] = {szAnimName = "AniCommonShow", szBgSFXPath = "data\\source\\other\\HD特效\\其他\\Pss\\UI_天气系统_通用时辰.pss", bWeather = true},
}

local UIPanelInterludeView = class("UIPanelInterludeView")

function UIPanelInterludeView:OnEnter(nIndex, tbCustomInfo)
    if not self.bInit then
        self:RegEvent()
        self:BindUIEvent()
        self.bInit = true
    end
    if nIndex then
        self.nIndex = nIndex
        self.tbInfo = Table_GetInterludeInfo(nIndex)
        self:UpdateInfo()
    elseif tbCustomInfo then
        self.tbInfo = tbCustomInfo -- {szText = "", szContent = "", szAnimName = ""}
        self:UpdateCustomInfo()
    end
end

function UIPanelInterludeView:OnExit()
    self.bInit = false
    self:UnRegEvent()
end

function UIPanelInterludeView:BindUIEvent()
    UIHelper.BindUIEvent(self.BtnHelp4, EventType.OnClick, function()
        local szContent = "开启后显示攻防场景（浩气盟、恶人谷）系统预设场景和镜头的天气表现效果。"
        TipsHelper.ShowNodeHoverTipsInDir(PREFAB_ID.WidgetPublicLabelTips, self.BtnHelp4, TipsLayoutDir.TOP_CENTER, szContent)
    end)
    UIHelper.BindUIEvent(self.ToggleLightPositionSwitch, EventType.OnSelectChanged, function(_, bSelected)
        local function _setActivityPreset()
            SelfieData.EnableActivityPreset(bSelected)
            SelfieData.ResetFilterFromStorage()
        end

        if bSelected then
            UIHelper.ShowConfirm("开启后显示攻防场景（浩气盟、恶人谷）系统预设场景和镜头的天气表现效果，会影响性能消耗，是否开启？",
            _setActivityPreset,
            function()
                if self and self.bInit then
                    UIHelper.SetSelected(self.ToggleLightPositionSwitch, false, false)
                end
            end)
        else
            _setActivityPreset()
        end
    end)
end

function UIPanelInterludeView:RegEvent()
    --Event.Reg(self, EventType.XXX, func)
end

function UIPanelInterludeView:UnRegEvent()
    --Event.UnReg(self, EventType.XXX)
end






-- ----------------------------------------------------------
-- Please write your own code below  ↓↓↓
-- ----------------------------------------------------------

function UIPanelInterludeView:UpdateInfo()
    if not self.tbInfo then
        LOG.ERROR("Interlude Config Error, nIndex: %s", tostring(self.nIndex))
        return
    end

    local bShowTitle = not self.tbInfo.bHideTitle_MB
    local tbType = tbInterludeType[self.tbInfo.szIniFile]
    if tbType and tbType.bWeather then
        UIHelper.SetVisible(self.LabelUnlock, false)
        UIHelper.SetVisible(self.LabelUnlockTitle2, true)
        UIHelper.SetString(self.LabelUnlockTitle2, UIHelper.GBKToUTF8(self.tbInfo.szText))
    else
        UIHelper.SetVisible(self.LabelUnlock, bShowTitle)
        UIHelper.SetString(self.LabelUnlock, UIHelper.GBKToUTF8(self.tbInfo.szText))
    end

    local bShowContent = not string.is_nil(self.tbInfo.szContent)
    UIHelper.SetVisible(self.LabelUnlockContent, bShowContent)
    if bShowContent then
        UIHelper.SetString(self.LabelUnlockContent, UIHelper.GBKToUTF8(self.tbInfo.szContent))
    end

    --初始化，隐藏所有Node
    for _, v in pairs(tbInterludeType) do
        UIHelper.SetVisible(self[v.szNodeName], false)
    end
    
    if not tbType then
        LOG.ERROR("Interlude Config Error, szIniFile: %s", tostring(self.tbInfo.szIniFile))

        --容错，避免界面无法关闭卡住
        Timer.Add(self, 3, function()
            UIMgr.Close(self)
        end)
        return
    end

    UIHelper.SetVisible(self[tbType.szNodeName], true)
    if tbType.szAnimName then
        UIHelper.PlayAni(self, self.AniAll, tbType.szAnimName, function()
            UIMgr.Close(self)
        end)
    end

    if not string.is_nil(tbType.szBgSFXPath) then
        UIHelper.SetVisible(self.SfxHintBig, true)
        UIHelper.SetSFXPath(self.SfxHintBig, UIHelper.UTF8ToGBK(tbType.szBgSFXPath))
        UIHelper.PlaySFX(self.SfxHintBig)
    end

    if not string.is_nil(self.tbInfo.szSFXPath) then
        UIHelper.SetVisible(self.SfxHintNormal, true)
        UIHelper.SetSFXPath(self.SfxHintNormal, self.tbInfo.szSFXPath)
        UIHelper.PlaySFX(self.SfxHintNormal)
    end

    UIHelper.SetVisible(self.WidgetWeatherSwitch, tbType.bWeather or false)
    if tbType.bWeather then
        local bEnablePreset = SelfieData.IsActivityPresetEnabled()
        UIHelper.SetSelected(self.ToggleLightPositionSwitch, bEnablePreset, false)
    end
end


function UIPanelInterludeView:UpdateCustomInfo()
    UIHelper.SetVisible(self.LabelUnlock, true)
    UIHelper.SetString(self.LabelUnlock, self.tbInfo.szText)

    local bShowContent = not string.is_nil(self.tbInfo.szContent)
    UIHelper.SetVisible(self.LabelUnlockContent, bShowContent)
    if bShowContent then
        UIHelper.SetString(self.LabelUnlockContent, self.tbInfo.szContent)
    end

    --初始化，隐藏所有Node
    for _, v in pairs(tbInterludeType) do
        UIHelper.SetVisible(self[v.szNodeName], false)
    end

    UIHelper.SetVisible(self.WidgetDeco, true)
    if self.tbInfo.szAnimName then
        UIHelper.PlayAni(self, self.AniAll, self.tbInfo.szAnimName, function()
            UIMgr.Close(self)
        end)
    end
end

return UIPanelInterludeView