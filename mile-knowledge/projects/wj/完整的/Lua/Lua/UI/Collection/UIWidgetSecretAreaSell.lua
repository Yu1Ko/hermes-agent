-- ---------------------------------------------------------------------------------
-- Author: Unknown
-- Name: UIWidgetSecretAreaSell
-- Date: 2023-12-18 17:24:49
-- Desc: ?
-- ---------------------------------------------------------------------------------

local UIWidgetSecretAreaSell = class("UIWidgetSecretAreaSell")

function UIWidgetSecretAreaSell:OnEnter(tbCardInfo)
    if not self.bInit then
        self:RegEvent()
        self:BindUIEvent()
        self.bInit = true
    end
    self.tbCardInfo = tbCardInfo
    self:UpdateInfo()
end

function UIWidgetSecretAreaSell:OnExit()
    self.bInit = false
    self:UnRegEvent()
end

function UIWidgetSecretAreaSell:BindUIEvent()
    UIHelper.BindUIEvent(self.BtnSecretArea, EventType.OnClick, function()
        local szOpenViewFunc = self.tbCardInfo.szOpenViewFunc2
        string.execute(szOpenViewFunc)
    end)
end

function UIWidgetSecretAreaSell:RegEvent()
    --Event.Reg(self, EventType.XXX, func)
end

function UIWidgetSecretAreaSell:UnRegEvent()
    --Event.UnReg(self, EventType.XXX)
end






-- ----------------------------------------------------------
-- Please write your own code below  ↓↓↓
-- ----------------------------------------------------------

function UIWidgetSecretAreaSell:UpdateInfo()
    local tbCardInfo = self.tbCardInfo
    local szName = tbCardInfo.Title
    UIHelper.SetString(self.LabelName, szName)
    
    local szPeopleNum = tbCardInfo.szPlayerCountRequirement
    UIHelper.SetString(self.LabelNum, szPeopleNum)

    UIHelper.SetString(self.LabelTime, tbCardInfo.Desc)

    local szImage = tbCardInfo.szMainCityIcon
    UIHelper.ClearTexture(self.ImgMap)
    UIHelper.SetTexture(self.ImgMap, szImage, false)

    local bCompleted = CollectionData.IsCardCompleted(tbCardInfo)

    UIHelper.SetVisible(self.ImgComplete, bCompleted)

    local bEnabled = tbCardInfo.bEnabled
    UIHelper.SetVisible(self.WidgetUnopen, not bEnabled)

    UIHelper.SetString(self.LabelGrade, tbCardInfo.szDifficult)

    local nState = BTN_STATE.Normal
    local szTips = ""
    if g_pClientPlayer and g_pClientPlayer.nLevel < tbCardInfo.nUnlockLevel then
        nState = BTN_STATE.Disable
        szTips = tbCardInfo.UnlockedDesc
    end

    if not tbCardInfo.bEnabled then 
        nState = BTN_STATE.Disable
        szTips = "本次测试暂未开放，敬请期待！"
    end

    UIHelper.SetButtonState(self.BtnSecretArea, nState, function()
        TipsHelper.ShowNormalTip(szTips)
    end)

    --等级限制
    UIHelper.SetVisible(self.WidgetLvLock, g_pClientPlayer and g_pClientPlayer.nLevel < tbCardInfo.nUnlockLevel)
    UIHelper.SetString(self.Label120, string.format("%s级开启", tostring(tbCardInfo.nUnlockLevel)))

     --难易程度
    local szDifficult = tbCardInfo.szDifficult
    if not string.is_nil(szDifficult) then
        UIHelper.SetSpriteFrame(self.ImgLv, szDifficult)
    end

    --标签
    local szTags = tbCardInfo.szTags
    if not string.is_nil(szTags) then
        UIHelper.SetSpriteFrame(self.ImgTag, szTags)
    end

    UIHelper.SetVisible(self.ImgTag, not string.is_nil(szTags))
    --品质
    local szQuality = tbCardInfo.szQuality
    if not string.is_nil(szQuality) then
        UIHelper.SetSpriteFrame(self.ImgLvBg, szQuality)
    end

    UIHelper.UpdateMask(self.Mask)
end


return UIWidgetSecretAreaSell