-- ---------------------------------------------------------------------------------
-- Author: Unknown
-- Name: UIWidgetHintContentBahuang
-- Date: 2024-04-07 20:38:01
-- Desc: ?
-- ---------------------------------------------------------------------------------

local UIWidgetHintContentBahuang = class("UIWidgetHintContentBahuang")

function UIWidgetHintContentBahuang:OnEnter()
    if not self.bInit then
        self:RegEvent()
        self:BindUIEvent()
        self.bInit = true
    end
end

function UIWidgetHintContentBahuang:OnExit()
    self.bInit = false
    self:UnRegEvent()
end

function UIWidgetHintContentBahuang:BindUIEvent()

end

function UIWidgetHintContentBahuang:RegEvent()
    Event.Reg(self, EventType.OnShieldTip, function(szEvent, tbData)
        local bClose = tbData.bClose
        if bClose then
            -- self[string.format("Close", ...)]()--关闭
        else
            local func = self[string.format("Update%sVis", szEvent)]
            if func then func(self) end
        end
    end)

    Event.Reg(self, EventType.OnUnShieldTip, function(szEvent, bClose)
        if not bClose then
            local func = self[string.format("Update%sVis", szEvent)]
            if func then func(self) end
        end
    end)

    Event.Reg(self, EventType.OnLeaveBahuangDynamic, function()
        self:UpdateRefreshAltarVis()
        self:StopRefreshProgress()
    end)
end

function UIWidgetHintContentBahuang:UnRegEvent()
    --Event.UnReg(self, EventType.XXX)
end
------------------------------------------------------------日冕倒计时 Start----------------------------
function UIWidgetHintContentBahuang:OnRefreshAltar(szAltar,tbNumber,tbTime, bStart)
    if UIMgr.IsViewOpened(VIEW_ID.PanelBahuangResult) then
        self:UpdateRefreshAltarVis()
        self:UpdateRefreshBossVis()
        self:StopRefreshProgress()
        return
    end

    if self.tbTime and not szAltar then--失败
        self.tbTime = {0, 0}
        self:OnFailed()
        return
    end

    self.szAltar = szAltar
    self.tbTimer = tbNumber or {0, 0}
    self.tbTime = tbTime or {0, 0}

    UIHelper.SetString(self.LabelTaskDiscribe, UIHelper.GBKToUTF8(self.szAltar))
    UIHelper.SetString(self.LabelTaskProgress, FormatString(g_tStrings.STR_ADD_FRINEND_TEXT_NUM, tbNumber[1], tbNumber[2]))
    UIHelper.LayoutDoLayout(self.LayoutTaskProgress)

    self:StartRefreshProgress()

    if tbTime[1] <= 0 then
        if tbNumber[1] >= tbNumber[2] then
            self:OnVictory()
        else
            self:OnFailed()
        end
    end
end

function UIWidgetHintContentBahuang:StartRefreshProgress()
    self:StopRefreshProgress()
    self.nRefresh = Timer.AddFrameCycle(self, 5, function()
        self:UpdateProgress()
    end)
end

function UIWidgetHintContentBahuang:StopRefreshProgress()
    if self.nRefresh then
        Timer.DelTimer(self, self.nRefresh)
        self.nRefresh = nil
    end
end

function UIWidgetHintContentBahuang:UpdateProgress()
    local bShow = self:CanShowAltar()
    self:UpdateRefreshAltarVis()
    if not bShow then
        self:StopRefreshProgress()
        return
    end

    self.tbTime[1] = self.tbTime[1] - 1/GLOBAL.GAME_FPS
    local nPercent = self.tbTime[1] / self.tbTime[2]
    UIHelper.SetProgressBarPercent(self.ProgressBar01, nPercent * 100)
end
------------------------------------------------------------日冕倒计时 End----------------------------



function UIWidgetHintContentBahuang:OnRefreshBoss()
    self.bShowBoss = true
    self.tbTime = {0, 0}
    self:UpdateRefreshBossVis()
    self:UpdateRefreshAltarVis()
    UIHelper.SetSpriteFrame(self.ImgTaskBg, "UIAtlas2_Bahuang_BahuangHint_img_Boss.png")
    UIHelper.SetString(self.LabelTaskTitle, "Boss来袭")
    UIHelper.SetVisible(self.LabelTaskTitle, true)
    self:StartCloseBossTimer()
end

function UIWidgetHintContentBahuang:StartCloseBossTimer()
    if self.nCloseBossTimer then
        Timer.DelTimer(self, self.nCloseBossTimer)
        self.nCloseBossTimer = nil
    end
    self.nCloseBossTimer = Timer.Add(self, 3, function()
        self.bShowBoss = false
        self:UpdateRefreshBossVis()
        self.nCloseBossTimer = nil
    end)
end

function UIWidgetHintContentBahuang:OnStartEvent()
    self.bShowStartEvent = true
    self.tbTime = {0, 0}
    self:UpdateRefreshBossVis()
    self:UpdateRefreshAltarVis()
    UIHelper.SetSpriteFrame(self.ImgTaskBg, "UIAtlas2_Bahuang_BahuangHint_img_Boss.png")
    UIHelper.SetString(self.LabelTaskTitle, "敌人来袭")
    UIHelper.SetVisible(self.LabelTaskTitle, true)
    self:StartCloseEventTimer()
end

function UIWidgetHintContentBahuang:StartCloseEventTimer()
    if self.nCloseEventTimer then
        Timer.DelTimer(self, self.nCloseEventTimer)
        self.nCloseEventTimer = nil
    end
    self.nCloseEventTimer = Timer.Add(self, 3, function()
        self.bShowStartEvent = false
        self:UpdateRefreshBossVis()
        self.nCloseEventTimer = nil
    end)
end

--胜利
function UIWidgetHintContentBahuang:OnVictory()
    self.bShowRes = true
    self.tbTime = {0, 0}
    self:UpdateRefreshAltarVis()
    self:UpdateRefreshBossVis()
    self:UpdateResVis()
    UIHelper.SetVisible(self.ImgDefeat, false)
    UIHelper.SetVisible(self.ImgVictory, true)
    self:StartCloseResTimer()
end

--失败
function UIWidgetHintContentBahuang:OnFailed()
    self.bShowRes = true
    self.tbTime = {0, 0}
    self:UpdateRefreshAltarVis()
    self:UpdateRefreshBossVis()
    self:UpdateResVis()
    UIHelper.SetVisible(self.ImgDefeat, true)
    UIHelper.SetVisible(self.ImgVictory, false)
    self:StartCloseResTimer()
end

function UIWidgetHintContentBahuang:StartCloseResTimer()
    if self.nCloseResTimer then
        Timer.DelTimer(self, self.nCloseResTimer)
        self.nCloseResTimer = nil
    end
    self.nCloseResTimer = Timer.Add(self, 3, function()
        self.bShowRes = false
        self:UpdateResVis()
        self.nCloseResTimer = nil
    end)
end


function UIWidgetHintContentBahuang:UpdateRefreshAltarVis()
    local bShow = self:CanShowAltar()
    local bVis = not TipsHelper.IsTipShield(EventType.RefreshAltar) and bShow
    UIHelper.SetVisible(self.WidgetTaskHint, bVis)
end

function UIWidgetHintContentBahuang:CanShowAltar()
    local bShow = self.tbTime and self.tbTime[1] and self.tbTime[1] > 0 and not UIMgr.IsViewOpened(VIEW_ID.PanelBahuangResult) and BahuangData.IsInBahuangDynamic()
    return bShow
end

function UIWidgetHintContentBahuang:UpdateRefreshBossVis()
    local bVis = not TipsHelper.IsTipShield(EventType.RefreshBoss) and (self.bShowStartEvent or self.bShowBoss) and not self.bShowRes
    and not UIMgr.IsViewOpened(VIEW_ID.PanelBahuangResult)
    UIHelper.SetVisible(self.WidgetBossHint, bVis)
end

function UIWidgetHintContentBahuang:UpdateResVis()
    local bVis = self.bShowRes and not UIMgr.IsViewOpened(VIEW_ID.PanelBahuangResult)
    UIHelper.SetVisible(self.WidgetResultHint, bVis)
end

return UIWidgetHintContentBahuang