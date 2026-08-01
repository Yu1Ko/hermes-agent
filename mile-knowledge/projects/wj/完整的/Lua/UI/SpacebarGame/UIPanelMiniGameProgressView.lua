-- ---------------------------------------------------------------------------------
-- Author: Unknown
-- Name: UIPanelMiniGameProgressView
-- Date: 2024-01-19 15:17:52
-- Desc: ?
-- ---------------------------------------------------------------------------------

local UIPanelMiniGameProgressView = class("UIPanelMiniGameProgressView")

function UIPanelMiniGameProgressView:OnEnter(tbInfo, bRepeat, szSource)
    if not self.bInit then
        self:RegEvent()
        self:BindUIEvent()
        self.bInit = true
    end
    self:Init(tbInfo, bRepeat, szSource)
    UIMgr.HideLayer(UILayer.Main, {VIEW_ID.PanelHint})
end

function UIPanelMiniGameProgressView:OnExit()
    self.bInit = false
    self:UnRegEvent()
    UIMgr.ShowLayer(UILayer.Main, {VIEW_ID.PanelHint})
end

function UIPanelMiniGameProgressView:BindUIEvent()
    -- UIHelper.BindUIEvent(self.btn, EventType.OnClick, function()
    --     self:StartNewRound()
    --     UIHelper.SetVisible(self.btn, false)
    -- end)--开始游戏

    UIHelper.BindUIEvent(self.BtnTap, EventType.OnClick, function()--端游还没明确规划，先写死
        local nSKillID = 25433
        OnUseSkill(nSKillID, (nSKillID * (nSKillID % 10 + 1)), { _vir=true, nSkillLevel = 1}, false)
    end)
end

function UIPanelMiniGameProgressView:RegEvent()
    Event.Reg(self, "UI_ON_SPACEBARGAME_BEGIN", function()
        self:StartTimer()
    end)

    Event.Reg(self, "UI_ON_SPACEBARGAME_RESULT", function(bResult, nRound, nRegion)
        local tbRoundInfo = self.tbRoundInfo
        local bLastClick = false
        if tbRoundInfo.type == 1 and bResult and not nRegion then
            bLastClick = true
            nRegion = #tbRoundInfo.region / 2
        end

        -- 局部点击结果,区域变黄
        if nRegion then
            if tbRoundInfo.type == 1 then
                self:AddSuccessRegion(nRegion)
            end
        end
        --游戏结果
        if not nRegion or bLastClick then
            self:StopTimer()
            if nRound == #self.tbAllInfo or bResult == false then
                self:UpdateResult(bResult)
            else
                if bResult and nRound < #self.tbAllInfo then
                    Timer.Add(self, 0.5, function()
                        self:SetCurRound(nRound + 1)--端游延了0.5秒
                    end)
                else
                    UIMgr.Close(self)
                end
            end
        end

    end)
end

function UIPanelMiniGameProgressView:UnRegEvent()
    --Event.UnReg(self, EventType.XXX)
end

function UIPanelMiniGameProgressView:Init(tbInfo, bRepeat, szSource)
    if not bRepeat then
        self.tbAllInfo = {tbInfo}
    else
        self.tbAllInfo = tbInfo
    end
    self.szSource = szSource
    UIHelper.SetTouchEnabled(self.SliderGameBar, false)
    self:SetCurRound(1)
end

function UIPanelMiniGameProgressView:StartTimer()
    self:StopTimer()
    self.nTimer = Timer.AddFrameCycle(self, 1, function()
        self:OnTimer()
    end)
end

function UIPanelMiniGameProgressView:StopTimer()
    if self.nTimer then
        Timer.DelTimer(self, self.nTimer)
        self.nTimer = nil
    end
end

function UIPanelMiniGameProgressView:OnTimer()
    local fPercentage, nLength = self:GetPercentage()
    --更新进度条
    self:UpdateProgress(nLength)
    self:CheckFinish(nLength)
end

function UIPanelMiniGameProgressView:CheckFinish(nLength)
    local tbRoundInfo = self.tbRoundInfo
    if tbRoundInfo.type == 1 and nLength >= 100 then
        self:StopTimer()
    end
end

-- ----------------------------------------------------------
-- Please write your own code below  ↓↓↓
-- ----------------------------------------------------------

function UIPanelMiniGameProgressView:UpdateInfo()
    local szTip = string.format("<color=#FFE26E>第%s/%s轮</color> <color=#d7f6ff>指针经过高亮区域时，按下按钮</color>", self.nRound, #self.tbAllInfo)
    UIHelper.SetRichText(self.RichTextScript, szTip)

    self.tbHighLightBarScript = {}
    UIHelper.RemoveAllChildren(self.WidgetHighLightBarShell)
    local tbRoundInfo = self.tbRoundInfo
    local tbRegion = tbRoundInfo.region
    if tbRoundInfo.type == 1 then
        for i = 1, #tbRegion, 2 do
            -- local hTargetArea = hList:AppendItemFromIni(INI_FILE, "Handle_TargetArea_1")
            local nLeft = tbRegion[i]
            local nRight = tbRegion[i + 1]
            local nStartPos = nLeft * 12
            local nLength = (nRight - nLeft) * 12
            local scriptView = UIHelper.AddPrefab(PREFAB_ID.WidgetMiniGameHighLightBar, self.WidgetHighLightBarShell, nStartPos, nLength)
            table.insert(self.tbHighLightBarScript, scriptView)
        end
    elseif tbRoundInfo.type == 2 then --暂时还没这种情况

    end
    self:UpdateProgress(0)
end

function UIPanelMiniGameProgressView:UpdateRegionState()
    if not self.tbHighLightBarScript then return end
    for nIndex, scriptView in ipairs(self.tbHighLightBarScript) do
        local bSuccess = self:IsReginSuccess(nIndex)
        local bHighlight = self.nRegionIndex == (nIndex - 1)
        local nState = bSuccess and 3 or (bHighlight and 2 or 1)
        scriptView:UpdateState(nState)
    end
end

function UIPanelMiniGameProgressView:UpdateProgress(nLength)
    UIHelper.SetProgressBarPercent(self.SliderGameBar, nLength)
end

function UIPanelMiniGameProgressView:UpdateResult(bResult)
    UIHelper.SetVisible(self.WidgetAnchorCountdown, false)
    UIHelper.SetVisible(self.WidgetSucceed, bResult)
    UIHelper.SetVisible(self.WidgetFailed, not bResult)--端游播完动画就关了，我们延时关闭
    Timer.Add(self, 2, function()  UIMgr.Close(VIEW_ID.PanelMiniGameProgress) end)
end

function UIPanelMiniGameProgressView:UpdateCountDown(nRemain)
    for nIndex, ImgCountDown in ipairs(self.tbImgCountDown) do
        UIHelper.SetVisible(ImgCountDown, nRemain == nIndex)
    end
end


--开始新一轮游戏
function UIPanelMiniGameProgressView:StartNewRound()
    if self.nNewRoundTimer then
        Timer.DelTimer(self, self.nNewRoundTimer)
        self.nNewRoundTimer = nil
    end
    local tbRoundInfo = self.tbRoundInfo
    UIHelper.SetVisible(self.WidgetAnchorCountdown, true)
    self:UpdateCountDown(tbRoundInfo.pretime)
    self.nNewRoundTimer = Timer.AddCountDown(self, tbRoundInfo.pretime, function(nRemain)
        --倒计时
        self:UpdateCountDown(nRemain)
    end, function()
        --倒计时

        UIHelper.SetRichText(self.RichTextRound, "<color=#FFFFFF>"..FormatString(g_tStrings.STR_MINIGAME_ROUND, self.nRound, #self.tbAllInfo).."</color>")
        UIHelper.SetVisible(self.RichTextRound, true)
        Timer.Add(self, 2, function()
            UIHelper.SetVisible(self.RichTextRound, false)
            UIHelper.SetVisible(self.WidgetAnchorCountdown, false)
            self.nLastFresh = GetTickCount()
            RemoteCallToServer("On_SpacebarGame_BeginSend", tbRoundInfo.type)
        end)

        -- self.nLastFresh = GetTickCount()
        -- RemoteCallToServer("On_SpacebarGame_BeginSend", tbRoundInfo.type)
    end)

end

function UIPanelMiniGameProgressView:UpdateCurRoundData()
    self.tbRoundInfo = self.tbAllInfo[self.nRound]
    self.nRegionIndex = nil
end

--设置当前游戏轮数
function UIPanelMiniGameProgressView:SetCurRound(nRound)
    self.nRound = nRound
    self:UpdateCurRoundData()

    local tbRoundInfo = self.tbRoundInfo
    local bAutoStart = nRound > 1 or tbRoundInfo.autostart
    if bAutoStart then
        self:StartNewRound()
    end
    self:UpdateInfo()
    self:InitSuccessRegion()
    -- UIHelper.SetVisible(self.btn, not bAutoStart)--不自动开始的游戏显示开始按钮
end

function UIPanelMiniGameProgressView:IsReginSuccess(nRegion)
    return table.contain_value(self.tbSuccessRegion, nRegion)
end

function UIPanelMiniGameProgressView:AddSuccessRegion(nRegion)
    if self:IsReginSuccess(nRegion) then return end
    table.insert(self.tbSuccessRegion, nRegion)
    self:UpdateRegionState()
end

function UIPanelMiniGameProgressView:InitSuccessRegion()
    self.tbSuccessRegion = {}
    self:UpdateRegionState()
end

function UIPanelMiniGameProgressView:GetPercentage()

    local tbRoundInfo = self.tbRoundInfo
    local fPercentage  = 0
    local fLength      = 0
    local nRegionIndex = nil
    local tRegion = tbRoundInfo.region
    if tbRoundInfo.type == 1 then
        local fTime = (GetTickCount() - self.nLastFresh) / 1000
        fLength = 100 / tbRoundInfo.time * fTime
        fPercentage = fLength / 100
        for i = 1, #tRegion, 2 do
            if fLength >= tRegion[i] and fLength <= tRegion[i + 1] then
                nRegionIndex = (i - 1) / 2
                break
            end
        end
        if nRegionIndex ~= self.nRegionIndex then
            self.nRegionIndex = nRegionIndex
            self:UpdateRegionState()
        end
    end
    return fPercentage, fLength
end

return UIPanelMiniGameProgressView