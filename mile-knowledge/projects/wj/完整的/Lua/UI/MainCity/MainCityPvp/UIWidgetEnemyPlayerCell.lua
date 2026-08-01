-- ---------------------------------------------------------------------------------
-- Author: Unknown
-- Name: UIWidgetEnemyPlayerCell
-- Date: 2022-12-13 15:48:06
-- Desc: ?
-- ---------------------------------------------------------------------------------
local KUNGFUTYPE_TO_NAME = {
    [1] = "输出",
    [2] = "治疗",
    [3] = "防御",
}

local UIWidgetEnemyPlayerCell = class("UIWidgetEnemyPlayerCell")

function UIWidgetEnemyPlayerCell:OnEnter(tbInfo)
    self.tbInfo = tbInfo
    if not self.bInit then
        self:RegEvent()
        self:BindUIEvent()
        self.bInit = true
    end

    self:UpdateInfo()
end

function UIWidgetEnemyPlayerCell:OnExit()
    self.bInit = false
end

function UIWidgetEnemyPlayerCell:RegEvent()
    Event.Reg(self, EventType.OnTargetChanged, function(...)
        self:OnTargetChanged(...)
    end)

    Event.Reg(self, EventType.UpdateMarkData, function(...)
        self:UpdateMarkInfo()
    end)
end

function UIWidgetEnemyPlayerCell:BindUIEvent()
    UIHelper.BindUIEvent(self.BtnSelect, EventType.OnClick, function()
        TargetMgr.doSelectTarget(self.tbInfo.dwID, TARGET.PLAYER)
    end)
end

function UIWidgetEnemyPlayerCell:UpdateInfo()
    if self.tbInfo.dwMountKungfuID and PlayerKungfuImg[self.tbInfo.dwMountKungfuID] then
        UIHelper.SetSpriteFrame(self.ImgXinFa, PlayerKungfuImg[self.tbInfo.dwMountKungfuID])
        UIHelper.SetVisible(self.ImgXinFa, true)
    else
        UIHelper.SetVisible(self.ImgXinFa, false)
    end

    local nType = GetKungfuTypeByKungfuID(self.tbInfo.dwMountKungfuID)
    UIHelper.SetString(self.LabelType, KUNGFUTYPE_TO_NAME[nType])
    UIHelper.SetProgressBarPercent(self.SliderBlood, self.tbInfo.nCurrentLife / self.tbInfo.nMaxLife * 100)

    self:UpdateMarkInfo()
    self:UpdatePlayerInfo()
    self.nUpdatePlayerTimerID = self.nUpdatePlayerTimerID or Timer.AddFrameCycle(self, 1, function ()
        self:UpdatePlayerInfo()
    end)
end

function UIWidgetEnemyPlayerCell:UpdatePlayerInfo()
    local player  = GetPlayer(self.tbInfo.dwID)
    if not player then return end
    local bDead = player.nMoveState == MOVE_STATE.ON_DEATH
    UIHelper.SetVisible(self.ImgTeamDead, bDead)
    UIHelper.SetVisible(self.SliderBlood, not bDead)

    local nCurrentLife = player.nCurrentLife or 0
    local nMaxLife = player.nMaxLife or 1
    local nDamageAbsorbValue = player.nDamageAbsorbValue or 0
    if nDamageAbsorbValue > 0 then
        if nCurrentLife + nDamageAbsorbValue > nMaxLife then
            nMaxLife = nCurrentLife + nDamageAbsorbValue
        end
        -- UIHelper.SetActiveAndCache(self, hDamageBar, true)
        -- local fDamagePercent = 100 * (nCurrentLife + nDamageAbsorbValue) / nMaxLife
        -- UIHelper.SetProgressBarPercent(hDamageBar, fDamagePercent)
    else
        -- UIHelper.SetActiveAndCache(self, hDamageBar, false)
    end

    local fBloodPercent = 100 * nCurrentLife / nMaxLife
    UIHelper.SetProgressBarPercent(self.SliderBlood, fBloodPercent)
end

function UIWidgetEnemyPlayerCell:OnTargetChanged(nTargetType, nTargetId)
    UIHelper.SetVisible(self.ImgSelect, false)
    if nTargetType == TARGET.PLAYER then
        UIHelper.SetVisible(self.ImgSelect, nTargetId == self.tbInfo.dwID)
    end
end

function UIWidgetEnemyPlayerCell:UpdateMarkInfo()
    local bShow = false

    if ArenaData.IsInArena() or ArenaTowerData.IsInArenaTowerMap() then
        local tbMarkInfo = TeamMarkData.GetTeamMarkInfo()
        if tbMarkInfo and self.tbInfo.dwID then
            for _, tbInfo in ipairs(tbMarkInfo) do
                if tbInfo.dwCharacterID == self.tbInfo.dwID then
                    if tbInfo.dwMarkID then
                        bShow = true
                        UIHelper.SetSpriteFrame(self.ImgBattleMark, TeamData.TargetMarkIcon[tbInfo.dwMarkID])
                    end
                    break
                end
            end
        end
    end

    UIHelper.SetVisible(self.ImgBattleMark, bShow)
end

return UIWidgetEnemyPlayerCell