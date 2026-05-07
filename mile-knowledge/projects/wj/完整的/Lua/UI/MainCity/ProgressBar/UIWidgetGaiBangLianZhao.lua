-- ---------------------------------------------------------------------------------
-- Author: jiayuran
-- Name: UIWidgetGaiBangLianZhao
-- Date: 2025-08-19 15:00:55
-- Desc: ?
-- ---------------------------------------------------------------------------------

local nCycleTime = 1 / 8
local NUMBER_COUNT = 3
local NUMBER_MAX = 999
local COMBO_TIME = 4000
local ANI_SHOW_TIME = 600

local szNormalFormat = "UIAtlas2_SkillDX_SpecialSkill_GaiBang_%d.png"
local szBgFormat = "UIAtlas2_SkillDX_SpecialSkill_GaiBang_%d_dark.png"

local function IsComboSkill(dwSkillID)
    local tComboSkill = Table_GetCountComboInfo(dwSkillID)
    if tComboSkill then
        return true
    end
    return false
end

local function IsKoMoveSkill(dwSkillID)
    local tComboSkill = Table_GetCountComboInfo(dwSkillID)
    if not tComboSkill then
        return false
    end

    return tComboSkill.bKoMove
end

local UIWidgetGaiBangLianZhao = class("UIWidgetGaiBangLianZhao")

function UIWidgetGaiBangLianZhao:OnEnter()
    if not self.bInit then
        self:RegEvent()
        self:BindUIEvent()
        self.bInit = true

        UIHelper.SetActiveAndCache(self, self._rootNode, false)
        Timer.AddCycle(self, nCycleTime, function()
            self:OnFrameBreathe()
        end)
    end
end

function UIWidgetGaiBangLianZhao:BindUIEvent()

end

function UIWidgetGaiBangLianZhao:RegEvent()
    Event.Reg(self, "LOCAL_CHARACTER_HIT_RESULT", function(dwSkillID, bCritical, dwTargetID)
        self:Update(dwSkillID, bCritical, dwTargetID)
    end)
end

function UIWidgetGaiBangLianZhao:UnRegEvent()
    --Event.UnReg(self, EventType.XXX)
end

function UIWidgetGaiBangLianZhao:Update(dwSkillID, bCritical, dwTargetID)
    if not IsComboSkill(dwSkillID) then
        return
    end

    self.nLastComboTime = GetTickCount()

    self:UpdateComboCount(dwTargetID)
    self:UpdateHitOrCrit(bCritical)
    self:UpdateNumber(self.nCount, bCritical)
    --ComboPanel.UpdateKoMove(hTotal, dwSkillID)
    self.dwLastTargetID = dwTargetID
end

function UIWidgetGaiBangLianZhao:UpdateComboCount(dwTargetID)
    --[[
    if not ComboPanel.dwLastTargetID or ComboPanel.dwLastTargetID ~= dwTargetID then
        ComboPanel.nCount = 0
    end
    --]]
    if not self.nCount then
        self.nCount = 0
    end
    self.nCount = self.nCount + 1
    self.nCount = math.min(self.nCount, NUMBER_MAX)
end

function UIWidgetGaiBangLianZhao:UpdateHitOrCrit(bCritical)
    UIHelper.SetActiveAndCache(self, self.ImgHuiXin, bCritical)
    UIHelper.SetActiveAndCache(self, self.ImgLian, not bCritical)
end

function UIWidgetGaiBangLianZhao:UpdateNumber(nCount, bCritical)
    UIHelper.SetActiveAndCache(self, self._rootNode, true)

    local szCount = string.format("%d", nCount)
    self.nCountLen = string.len(szCount)
    local nLen = string.len(szCount)

    for i = 1, NUMBER_COUNT do
        local bShow = nLen >= NUMBER_COUNT - i + 1
        UIHelper.SetActiveAndCache(self, self.tNumberParent[i], bShow)
        if bShow then
            local nIndex = i - (NUMBER_COUNT - nLen)
            local szNumber = string.sub(szCount, nIndex, nIndex)
            UIHelper.SetSpriteFrame(self.tNumberBgs[i], string.format(szBgFormat, szNumber))
            UIHelper.SetSpriteFrame(self.tNumberSlider[i], string.format(szNormalFormat, szNumber))
            UIHelper.SetProgressBarPercent(self.tNumberSlider[i], 100)
        end
    end
end

function UIWidgetGaiBangLianZhao:OnFrameBreathe()
    if not self.nLastComboTime then
        return
    end

    if not self.nCount or self.nCount < 0 then
        return
    end

    local nTime = GetTickCount() - self.nLastComboTime

    local fPercent = (COMBO_TIME - nTime) / COMBO_TIME
    fPercent = math.max(fPercent, 0)

    --if nTime > 800 then
    --    uiani_finish(hCombo._play_id) --由于现在动画会不消失，暂时做个处理
    --end

    for i = 1, NUMBER_COUNT do
        UIHelper.SetProgressBarPercent(self.tNumberSlider[i], fPercent * 100)
    end
    if nTime > COMBO_TIME then
        self.nCount = 0
        UIHelper.SetActiveAndCache(self, self._rootNode, false)
    end
end

return UIWidgetGaiBangLianZhao