-- ---------------------------------------------------------------------------------
-- Author: JiaYuRan
-- Name: UIWidgetBalanceBar
-- Date: 2026-3-25 15:26:05
-- Desc: 气势条
-- ---------------------------------------------------------------------------------

local function GetSelectTarget()
    local player = GetClientPlayer()
    if not player then
        return
    end

    local dwType, dwID = player.GetTarget()
    return GetTargetHandle(dwType, dwID)
end

local UIWidgetBalanceBar = class("UIWidgetBalanceBar")

function UIWidgetBalanceBar:OnEnter()
    if not self.bInit then
        self:RegEvent()
        self:BindUIEvent()
        self.bInit = true
    end

    self:Update()
    self:SetVisible(false)
end

function UIWidgetBalanceBar:OnExit()
    self.bInit = false
    self:UnRegEvent()
end

function UIWidgetBalanceBar:BindUIEvent()
end

function UIWidgetBalanceBar:RegEvent()
    Event.Reg(self, "OnTargetChanged", function(nTargetType, nSelectID)
        print(nTargetType, nSelectID)
        if nSelectID then
            self:SetVisible(true)
        else
            self:SetVisible(false)
        end
    end)

    Event.Reg(self, "NPC_STATE_UPDATE", function()
        if self.dwType == TARGET.NPC and self.dwID == arg0 then
            self:Update()
        end
    end)
end

function UIWidgetBalanceBar:UnRegEvent()
    --Event.UnReg(self, EventType.XXX)
end

-- ----------------------------------------------------------
-- Please write your own code below  ↓↓↓
-- ----------------------------------------------------------

function UIWidgetBalanceBar:SetVisible(bState)
    if bState then
        Timer.AddCycle(self, 0.05, function()
            if self.nLastPostureState and self.nLastPostureState ~= CHARACTER_POSTURE_STATE.NONE then
                self:Update()
            end
        end)
    else
        Timer.DelAllTimer(self)
    end
    UIHelper.SetVisible(self._rootNode, bState)
end

function UIWidgetBalanceBar:Update()
    local hTarget = GetSelectTarget()
    local nBarLength = 237
    local bShow = false
    if hTarget then
        local nMaxPosture = hTarget.nMaxPosture or 0
        if nMaxPosture > 0 and nMaxPosture ~= 255 then
            local nCurrentPosture = hTarget.nCurrentPosture or 0
            local fCurrentPosture = 0
            if nCurrentPosture > 0 then
                fCurrentPosture = nCurrentPosture / nMaxPosture
            end
            bShow = true
            local nPostureState = hTarget.nPostureState or CHARACTER_POSTURE_STATE.NORMAL
            if nPostureState == CHARACTER_POSTURE_STATE.NONE then
                UIHelper.SetWidth(self.MaskNormal, fCurrentPosture * nBarLength)
                UIHelper.SetActiveAndCache(self, self.MaskNormal, true)
                UIHelper.SetActiveAndCache(self, self.MaskBreak, false)
                UIHelper.SetActiveAndCache(self, self.SFXImBalance, false)
            elseif nPostureState == CHARACTER_POSTURE_STATE.ENTER_BREAK then
                if self.nLastPostureState and self.nLastPostureState == CHARACTER_POSTURE_STATE.NONE then
                    UIHelper.PlaySFX(self.SfxBreak, false)
                    
                    UIHelper.SetWidth(self.MaskNormal, 0)
                    UIHelper.SetWidth(self.MaskBreak, nBarLength)
                    UIHelper.SetActiveAndCache(self, self.MaskNormal, false)
                    UIHelper.SetActiveAndCache(self, self.MaskBreak, true)
                    UIHelper.SetActiveAndCache(self, self.SFXImBalance, true)
                end
            elseif nPostureState == CHARACTER_POSTURE_STATE.BREAK or nPostureState == CHARACTER_POSTURE_STATE.EXIT_BREAK then
                if self.nLastPostureState and self.nLastPostureState == CHARACTER_POSTURE_STATE.ENTER_BREAK then
                    self.nTotalFrame = math.max(hTarget.nPostureBreakEndFrame - GetLogicFrameCount(), 0) --总时间
                end

                local nLeftFrame = math.max(hTarget.nPostureBreakEndFrame - GetLogicFrameCount(), 0) --当前剩余时间
                local fLeftPercent = 0
                if self.nTotalFrame and self.nTotalFrame > 0 then
                    fLeftPercent = nLeftFrame / self.nTotalFrame
                end
                
                UIHelper.SetWidth(self.MaskBreak, fLeftPercent * nBarLength)
                UIHelper.SetActiveAndCache(self, self.MaskNormal, false)
                UIHelper.SetActiveAndCache(self, self.MaskBreak, true)
            end
            self.nLastPostureState = nPostureState
        end

        self.dwID = hTarget.dwID
        self.dwType = TARGET.NPC
    end
    UIHelper.SetVisible(self._rootNode, bShow)
end

return UIWidgetBalanceBar