-- ---------------------------------------------------------------------------------
-- Author: Unknown
-- Name: UIWidgetCampSell
-- Date: 2023-12-18 19:07:23
-- Desc: ?
-- ---------------------------------------------------------------------------------

local UIWidgetCampSell = class("UIWidgetCampSell")

function UIWidgetCampSell:OnEnter(tbCardInfo)
    if not self.bInit then
        self:RegEvent()
        self:BindUIEvent()
        self.bInit = true
    end
    self.tbCardInfo = tbCardInfo
    self:UpdateInfo()
end

function UIWidgetCampSell:OnExit()
    self.bInit = false
    self:UnRegEvent()
end

function UIWidgetCampSell:BindUIEvent()
    UIHelper.BindUIEvent(self.WidgetSecretArea, EventType.OnClick, function()
        self:OnClick()
    end)

    -- UIHelper.BindUIEvent(self.BtnReservation, EventType.OnClick, function()
    --     self:OnClick()
    -- end)
end

function UIWidgetCampSell:RegEvent()
    --Event.Reg(self, EventType.XXX, func)
end

function UIWidgetCampSell:UnRegEvent()
    --Event.UnReg(self, EventType.XXX)
end


function UIWidgetCampSell:OnClick() 
    local tbCardInfo = self.tbCardInfo
    local bInTime, nType = CollectionData.IsInAppointmentOrOpenTime(tbCardInfo)
    if bInTime then 
        local szOpenViewFunc = nType == 1 and tbCardInfo.szOpenViewFunc1 or tbCardInfo.szOpenViewFunc2
        string.execute(szOpenViewFunc)
    else
        --提示，不在时间内
    end
end



-- ----------------------------------------------------------
-- Please write your own code below  ↓↓↓
-- ----------------------------------------------------------

function UIWidgetCampSell:UpdateInfo()
    local tbCardInfo = self.tbCardInfo

    local bEnabled = tbCardInfo.bEnabled
    UIHelper.SetVisible(self.WidgetUnopen, not bEnabled)

    local nType = tbCardInfo.nType
    UIHelper.SetVisible(self.BtnReservation, nType and nType == 1)
    UIHelper.SetVisible(self.BtnGo, nType and nType == 2)

    local szName = tbCardInfo.Title
    UIHelper.SetString(self.LabelName, szName)

    local szImage = tbCardInfo.szMainCityIcon
    UIHelper.ClearTexture(self.ImgMap)
    UIHelper.SetTexture(self.ImgMap, szImage, false)

    local nState = tbCardInfo.bEnabled and BTN_STATE.Normal or BTN_STATE.Disable
    -- UIHelper.SetButtonState(self.BtnGo, nState, function()
    --     TipsHelper.ShowNormalTip("本次测试暂未开放，敬请期待！")
    -- end)

    -- UIHelper.SetButtonState(self.BtnReservation, nState, function()
    --     TipsHelper.ShowNormalTip("本次测试暂未开放，敬请期待！")
    -- end)

    UIHelper.SetButtonState(self.WidgetSecretArea, nState, function()
        TipsHelper.ShowNormalTip("本次测试暂未开放，敬请期待！")
    end)

    --品质
    local szQuality = tbCardInfo.szQuality
    if not string.is_nil(szQuality) then
        UIHelper.SetSpriteFrame(self.ImgLvBg, szQuality)
    end

    UIHelper.UpdateMask(self.Mask)
end

return UIWidgetCampSell