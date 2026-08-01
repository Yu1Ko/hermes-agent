-- ---------------------------------------------------------------------------------
-- Author: huqing
-- Name: UIChatBulletSettingView
-- Date: 2026-03-23 20:26:35
-- Desc: 弹幕设置
-- ---------------------------------------------------------------------------------

-- 字体ID对应名字
local FontSize_ID_To_Name =
{
    [0] = "大字体",
    [1] = "小字体"
}

-- 字体显示的顺序 对应 字体ID
local FontSize_Display_To_ID = {
    [1] = 1,
    [2] = 0
}

-- 显示模式对应名字
local ShowMode_ID_To_Name =
{
    [BULLETSCREEN_SHOWMODE_TYPE.TOP] = "顶部弹幕",
    [BULLETSCREEN_SHOWMODE_TYPE.ROLL] = "滚动弹幕",
    [BULLETSCREEN_SHOWMODE_TYPE.BOTTOM] = "底部弹幕",
}

-- 字体显示的顺序 对应 字体ID
local ShowMode_Display_To_ID = {
    [1] = BULLETSCREEN_SHOWMODE_TYPE.TOP,
    [2] = BULLETSCREEN_SHOWMODE_TYPE.ROLL,
    [3] = BULLETSCREEN_SHOWMODE_TYPE.BOTTOM,
}


local UIChatBulletSettingView = class("UIChatBulletSettingView")

function UIChatBulletSettingView:OnEnter()
    if not self.bInit then
        self:RegEvent()
        self:BindUIEvent()
        self.bInit = true
    end

    self:InitData()
    self:UpdateInfo()
end

function UIChatBulletSettingView:InitData()
    self.tbSetting = clone(Storage.Chat_Bullet)
    self:SetOpacity(self.tbSetting.nOpacity or 100)
end

function UIChatBulletSettingView:OnExit()
    self.bInit = false
    self:UnRegEvent()
end

function UIChatBulletSettingView:BindUIEvent()
    UIHelper.BindUIEvent(self.BtnClose, EventType.OnClick, function(btn)
        UIMgr.Close(self)
    end)

    -- 确定
    UIHelper.BindUIEvent(self.BtnConfirm, EventType.OnClick, function(btn)
        local tbRebuildKey = {"nColorID", "nFontSize", "nShowMode"}
        local bNeedRebuild = false -- 弹幕是否需要全部重建 重新开始，换了颜色、字体大小、显示模式都要重建

        for key, val in pairs(self.tbSetting) do
            local nOld = Storage.Chat_Bullet[key]
            if not bNeedRebuild and nOld ~= val and table.contain_value(tbRebuildKey, key) then
                bNeedRebuild = true
            end
            Storage.Chat_Bullet[key] = val
        end
        Storage.Chat_Bullet.Flush()

        LOG.TABLE(Storage.Chat_Bullet)

        Event.Dispatch(EventType.OnChatBulletSettingUpdate, bNeedRebuild)

        UIMgr.Close(self)
    end)

    -- 取消
    UIHelper.BindUIEvent(self.BtnCancel, EventType.OnClick, function(btn)
        UIMgr.Close(self)
    end)

    -- 开关
    UIHelper.BindUIEvent(self.ToggleOpenFlag, EventType.OnSelectChanged, function(_tog, bSelected)
        self.tbSetting.bOpenFlag = bSelected
    end)

    -- 字体大小
    UIHelper.BindUIEvent(self.ToggleFontSize, EventType.OnSelectChanged, function(_tog, bSelected)
        if bSelected then
            self:UpdateFontSize()
        end
    end)

    for nFontSizeIndex, btnFontSize in ipairs(self.tbFontSizeBtnList) do
        UIHelper.BindUIEvent(btnFontSize, EventType.OnClick, function(btn)
            local nID = FontSize_Display_To_ID[nFontSizeIndex]
            if nID then
                self.tbSetting.nFontSize = nID
                self:UpdateFontSize()
            end
        end)
    end

    -- 字体颜色
    for nColorIndex, togColor in ipairs(self.tbColorToggleList) do
        UIHelper.BindUIEvent(togColor, EventType.OnSelectChanged, function(_togColor, bSelected)
            if bSelected then
                self.tbSetting.nColorID = nColorIndex
            end
        end)
    end

    -- 不透明度
    UIHelper.BindUIEvent(self.SliderOpacity, EventType.OnChangeSliderPercent, function(SliderEventType, nSliderEvent)
        if nSliderEvent == ccui.SliderEventType.slideBallDown then
            self.bSliding = true
        elseif nSliderEvent == ccui.SliderEventType.slideBallUp then
            self.bSliding = false

            self.tbSetting.nOpacity = self.nOpacityVal
        end

        if self.bSliding then
            self.nOpacityVal = UIHelper.GetProgressBarPercent(self.SliderOpacity)
            self:UpdateOpacity(true)

        end
    end)

    -- 弹幕类型
    for nShowModeIndex, togShowMode in ipairs(self.tbShowModeToggleList) do
        UIHelper.BindUIEvent(togShowMode, EventType.OnSelectChanged, function(_togShowMode, bSelected)
            if bSelected then
                self.tbSetting.nShowMode = ShowMode_Display_To_ID[nShowModeIndex]
            end
        end)
    end
end

function UIChatBulletSettingView:RegEvent()
    Event.Reg(self, EventType.HideAllHoverTips, function()
        if UIHelper.GetSelected(self.ToggleFontSize) then
            UIHelper.SetSelected(self.ToggleFontSize, false)
        end
    end)
end

function UIChatBulletSettingView:UnRegEvent()
    --Event.UnReg(self, EventType.XXX)
end






-- ----------------------------------------------------------
-- Please write your own code below  ↓↓↓
-- ----------------------------------------------------------

function UIChatBulletSettingView:UpdateInfo()
    self:UpdateOpenFlag()
    self:UpdateFontSize()
    self:UpdateColor()
    self:UpdateOpacity()
    self:UpdateShowMode()
end

function UIChatBulletSettingView:UpdateOpenFlag()
    UIHelper.SetSelected(self.ToggleOpenFlag, self.tbSetting.bOpenFlag)
end

function UIChatBulletSettingView:UpdateFontSize()
    local nCurFontSize = self.tbSetting.nFontSize
    local nFontSize = nCurFontSize or 1
    local szName = FontSize_ID_To_Name[nFontSize] or ""
    UIHelper.SetString(self.LabelFontSize, szName)

    -- 选中的小点点
    for i = 1, 2 do
        local imgFontSizeDot = self.tbFontSizeDotList[i]
        local labelFontSize = self.tbFontSizeLabelList[i]

        local nID = FontSize_Display_To_ID[i]
        UIHelper.SetVisible(imgFontSizeDot, nCurFontSize == nID)
        UIHelper.SetString(labelFontSize, FontSize_ID_To_Name[nID] or "")
    end

end

-- 检查值是否在表中（参考 DanmakuBase.CheckUp）
local function CheckInTable(tTable, var)
    if not tTable then
        return false
    end
    for _, v in pairs(tTable) do
        if v == var then
            return true
        end
    end
    return false
end

function UIChatBulletSettingView:UpdateColor()
    local tBaseConf = ChatData.GetBulletBaseConf()

    for k, tog in ipairs(self.tbColorToggleList) do
        local imgColor = self.tbColorImgList[k]
        local imgLock = self.tbColorLockList[k]
        local tColor = Table_GetDanmakuColor(k)

        local bColorUnlocked = tColor.r >= 0 and CheckInTable(tBaseConf and tBaseConf.tColor, k)
        if bColorUnlocked then
            UIHelper.SetVisible(imgColor, true)
            UIHelper.SetColor(imgColor, cc.c3b(tColor.r, tColor.g, tColor.b))
            UIHelper.SetVisible(imgLock, false)
            UIHelper.SetEnable(tog, true)
        else
            UIHelper.SetVisible(imgColor, false)
            UIHelper.SetVisible(imgLock, true)
            UIHelper.SetEnable(tog, false)
        end
    end

    local nColorID = self.tbSetting.nColorID or 1
    UIHelper.SetSelected(self.tbColorToggleList[nColorID], true)
end

function UIChatBulletSettingView:UpdateOpacity()
    UIHelper.SetString(self.LabelOpacity, self.nOpacityVal)

    local nPercent = self.nOpacityVal / 100
    self.nOpacitySliderWidth = self.nOpacitySliderWidth or UIHelper.GetWidth(self.SliderOpacity)
    UIHelper.SetWidth(self.ImgOpacity, nPercent * self.nOpacitySliderWidth)
end

function UIChatBulletSettingView:SetOpacity(nVal)
    if self.nOpacityVal == nVal then
        return
    end
    self.nOpacityVal = nVal
    UIHelper.SetProgressBarPercent(self.SliderOpacity, nVal)
end

function UIChatBulletSettingView:UpdateShowMode()
    local nShowMode = self.tbSetting.nShowMode or 3

    for k, togShowMode in ipairs(self.tbShowModeToggleList) do
        local nID = ShowMode_Display_To_ID[k]
        UIHelper.SetSelected(togShowMode, nID == nShowMode)
    end
end


return UIChatBulletSettingView