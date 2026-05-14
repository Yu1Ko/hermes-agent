-- ---------------------------------------------------------------------------------
-- Author: huqing
-- Name: UITouchMask
-- Date: 2023-05-13 11:33:35
-- Desc: 点击遮罩,屏蔽所有点击
-- ---------------------------------------------------------------------------------

local USE_BLACK = false

local UITouchMask = class("UITouchMask")

function UITouchMask:OnEnter()
    self.nShowCount = 0

    if not self.bInit then
        self:RegEvent()
        self:BindUIEvent()
        self.bInit = true
    end

    UIHelper.SetVisible(self.AniAll, false)
end

function UITouchMask:OnExit()
    self.bInit = false
    self:UnRegEvent()
end

function UITouchMask:BindUIEvent()
    UIHelper.BindUIEvent(self.BtnTouchMask, EventType.OnClick, function(btn)
        --LOG.ERROR("[UITouchMask] UITouchMask is intercept click.")
    end)
end

function UITouchMask:RegEvent()
    Event.Reg(self, EventType.OnTouchMaskShow, function(nAutoHideDelay)
        --LOG.INFO("[UITouchMask] UITouchMask show, nShowCount = %d.", self.nShowCount)

        self:_showTouch()

        -- 10秒钟自动关闭，避免出现卡死的情况
        if nAutoHideDelay == nil then
        --    nAutoHideDelay = 10
        end

        if IsNumber(nAutoHideDelay) and nAutoHideDelay > 0 then
            --Timer.DelTimer(self, self.nTimerID)
            self.nTimerID = Timer.Add(self, nAutoHideDelay, function()
                self:_hideTouch()
            end)
        end
    end)

    Event.Reg(self, EventType.OnTouchMaskHide, function()
        --LOG.INFO("[UITouchMask] UITouchMask hide, nShowCount = %d.", self.nShowCount)

        self:_hideTouch()

        --Timer.DelTimer(self, self.nTimerID)
    end)


    Event.Reg(self, EventType.OnBlackMaskEnter, function(nViewID, callback)
        if USE_BLACK then
            self:_blackMaskEnter(nViewID, callback)
        else
            self:_aniMaskEnter(nViewID, callback)
        end
    end)

    Event.Reg(self, EventType.OnBlackMaskExit, function(nViewID, callback)
        if USE_BLACK then
            self:_blackMaskExit(nViewID, callback)
        else
            self:_aniMaskExit(nViewID, callback)
        end
    end)

    Event.Reg(self, EventType.OnTouchMaskWithTipsShow, function(szTips, nAutoHideDelay)
        self:_showTips(szTips)
        if nAutoHideDelay == nil then
            nAutoHideDelay = 10 -- 10秒钟自动关闭，避免出现卡死的情况
        end

        if IsNumber(nAutoHideDelay) and nAutoHideDelay > 0 then
            self.nTipsTimerID = Timer.Add(self, nAutoHideDelay, function()
                self:_hideTips()
            end)
        end
    end)

    Event.Reg(self, EventType.OnTouchMaskWithTipsHide, function()
        self:_hideTips()
        Timer.DelTimer(self, self.nTipsTimerID)
    end)
end

function UITouchMask:UnRegEvent()
    --Event.UnReg(self, EventType.XXX)
end






-- ----------------------------------------------------------
-- Please write your own code below  ↓↓↓
-- ----------------------------------------------------------

function UITouchMask:UpdateInfo()

end

function UITouchMask:_showTouch()
    self.nShowCount = self.nShowCount + 1
    UIHelper.SetVisible(self.BtnTouchMask, self.nShowCount > 0)
end

function UITouchMask:_hideTouch()
    self.nShowCount = self.nShowCount - 1
    if self.nShowCount < 0 then self.nShowCount = 0 end
    UIHelper.SetVisible(self.BtnTouchMask, self.nShowCount > 0)
end

function UITouchMask:_blackMaskEnter(nViewID, callback)
    local conf = TabHelper.GetUIViewTab(nViewID)
    if not conf then
        return
    end

    if not conf.tbBlackFadeIn then
        Lib.SafeCall(callback)
        return
    end

    if not self:_specialCheck(nViewID) then
        Lib.SafeCall(callback)
        return
    end

    local nFadeInTime = conf.tbBlackFadeIn[1]
    local nWaitTime = conf.tbBlackFadeIn[2]
    local nFadeOutTime = conf.tbBlackFadeIn[3]

    UIHelper.SetVisible(self.BlackMask, true)
    UIHelper.SetOpacity(self.BlackMask, 60)

    local _fadeOutCallback = function()
        local _doFadeout = function()
            local nFadeoutDelay = Platform.IsMobile() and 0.7 or 0.2 -- 这里再加一段延时，因为有时候加载完了，还是会有点其他的散件在加载
            local delay = cc.DelayTime:create(nFadeoutDelay)
            local fadeOut = cc.FadeTo:create(nFadeOutTime, 0)
            local callback2 = cc.CallFunc:create(function()
                UIHelper.SetVisible(self.BlackMask, false)
                Event.UnReg(self, EventType.OnMiniSceneLoadProgress)
            end)

            local sequence = cc.Sequence:create(delay, fadeOut, callback2)
            self.BlackMask:stopAllActions()
            self.BlackMask:runAction(sequence)
        end

        -- if SceneHelper.IsLoading() then
        --     Event.Reg(self, EventType.OnMiniSceneLoadProgress, function(nProcess)
        --         if nProcess >= 100 then
        --             Event.UnReg(self, EventType.OnMiniSceneLoadProgress)
        --             _doFadeout()
        --         end
        --     end)
        -- else
        --     _doFadeout()
        -- end

        -- Event.Reg(self, EventType.OnMiniSceneLoadProgress, function(nProcess)
        --     if nProcess >= 100 then
        --         Event.UnReg(self, EventType.OnMiniSceneLoadProgress)
        --         _doFadeout()
        --     end
        -- end)

        Timer.DelTimer(self, self.nDoFadeoutTimerID)
        self.nDoFadeoutTimerID = Timer.Add(self, 0.2, function()
            _doFadeout()
        end)
    end



    local fadeIn = cc.FadeTo:create(nFadeInTime, 255)
    local callback1 = cc.CallFunc:create(function() Lib.SafeCall(callback) end)
    local delay = cc.DelayTime:create(nWaitTime)
    local callback2 = cc.CallFunc:create(function()
        Lib.SafeCall(_fadeOutCallback)
        Event.Dispatch(EventType.OnBlackMaskEnterFinish)
    end)
    local sequence = cc.Sequence:create(fadeIn, callback1, delay, callback2)

    self.BlackMask:stopAllActions()
	self.BlackMask:runAction(sequence)
end

function UITouchMask:_blackMaskExit(nViewID, callback)
    local conf = TabHelper.GetUIViewTab(nViewID)
    if not conf then
        return
    end

    if not conf.tbBlackFadeOut then
        Lib.SafeCall(callback)
        return
    end

    if not self:_specialCheck(nViewID) then
        Lib.SafeCall(callback)
        return
    end

    local nFadeInTime = conf.tbBlackFadeOut[1]
    local nWaitTime = conf.tbBlackFadeOut[2]
    local nFadeOutTime = conf.tbBlackFadeOut[3]

    UIHelper.SetVisible(self.BlackMask, true)
    UIHelper.SetOpacity(self.BlackMask, 60)

    local fadeIn = cc.FadeTo:create(nFadeInTime, 255)
    local callback1 = cc.CallFunc:create(function() Lib.SafeCall(callback) end)
    local delay = cc.DelayTime:create(nWaitTime)
    local fadeOut = cc.FadeTo:create(nFadeOutTime, 0)
    local callback2 = cc.CallFunc:create(function()
        UIHelper.SetVisible(self.BlackMask, false)
        Event.Dispatch(EventType.OnBlackMaskExitFinish)
    end)
    local sequence = cc.Sequence:create(fadeIn, callback1, delay, fadeOut, callback2)

    self.BlackMask:stopAllActions()
	self.BlackMask:runAction(sequence)
end

function UITouchMask:_aniMaskEnter(nViewID, callback)
    local conf = TabHelper.GetUIViewTab(nViewID)
    if not conf then
        return
    end

    if not conf.tbBlackFadeIn then
        Lib.SafeCall(callback)
        return
    end

    if not self:_specialCheck(nViewID) then
        Lib.SafeCall(callback)
        return
    end

    -- UIHelper.SetTexture(self.ImgBg, "Texture/PublicBg/ZhuanChang.png", true)

    local nFadeInTime = conf.tbBlackFadeIn[1]
    local nWaitTime = conf.tbBlackFadeIn[2]
    local nFadeOutTime = conf.tbBlackFadeIn[3]

    --self:_showTouch()
    UIHelper.SetVisible(self.AniAll, true)
    UIHelper.StopAllAni(self)
    UIHelper.PlayAni(self, self.AniAll, "AniIn02", function()
        Lib.SafeCall(callback)

        local delay = cc.DelayTime:create(nWaitTime + 0.2)
        local callback2 = cc.CallFunc:create(function()
            UIHelper.StopAllAni(self)
             UIHelper.PlayAni(self, self.AniAll, "AniOut02", function()
                --self:_hideTouch()
                UIHelper.SetVisible(self.AniAll, false)
                Event.Dispatch(EventType.OnBlackMaskEnterFinish)

                -- local pTex = self.ImgBg:getTexture()
                -- if pTex then pTex:release() end
                -- UIHelper.ClearTexture(self.ImgBg)
             end)
        end)

        local sequence = cc.Sequence:create(delay, callback2)

        self.BlackMask:stopAllActions()
        self.BlackMask:runAction(sequence)
    end)
end

function UITouchMask:_aniMaskExit(nViewID, callback)
    local conf = TabHelper.GetUIViewTab(nViewID)
    if not conf then
        return
    end

    do
        Lib.SafeCall(callback)
        return
    end

    if not conf.tbBlackFadeOut then
        Lib.SafeCall(callback)
        return
    end

    if not self:_specialCheck(nViewID) then
        Lib.SafeCall(callback)
        return
    end

    -- UIHelper.SetTexture(self.ImgBg, "Texture/PublicBg/ZhuanChang.png", true)

    local nFadeInTime = conf.tbBlackFadeOut[1]
    local nWaitTime = conf.tbBlackFadeOut[2]
    local nFadeOutTime = conf.tbBlackFadeOut[3]

    --self:_showTouch()
    UIHelper.SetVisible(self.AniAll, true)
    UIHelper.StopAllAni(self)
    UIHelper.PlayAni(self, self.AniAll, "AniIn02", function()
        Lib.SafeCall(callback)

        local delay = cc.DelayTime:create(nWaitTime)
        local callback2 = cc.CallFunc:create(function()
            UIHelper.StopAllAni(self)
             UIHelper.PlayAni(self, self.AniAll, "AniOut02", function()
                --self:_hideTouch()
                UIHelper.SetVisible(self.AniAll, false)
                Event.Dispatch(EventType.OnBlackMaskExitFinish)

                -- local pTex = self.ImgBg:getTexture()
                -- if pTex then pTex:release() end
                -- UIHelper.ClearTexture(self.ImgBg)
             end)
        end)

        local sequence = cc.Sequence:create(delay, callback2)

        self.BlackMask:stopAllActions()
        self.BlackMask:runAction(sequence)
    end)
end

function UITouchMask:_showTips(szTips)
    self:_showTouch()
    UIHelper.SetVisible(self.WidgetTipsMask, true)
    UIHelper.SetString(self.LabelTips, szTips)
end

function UITouchMask:_hideTips()
    self:_hideTouch()
    UIHelper.SetVisible(self.WidgetTipsMask, false)
end

function UITouchMask:_specialCheck(nViewID)
    local bResult = true
    if nViewID == VIEW_ID.PanelTeam then
        if not TeamData.IsPlayerInTeam() and not RoomData.IsHaveRoom() then
            bResult = false
        end
    end
    return bResult
end

return UITouchMask