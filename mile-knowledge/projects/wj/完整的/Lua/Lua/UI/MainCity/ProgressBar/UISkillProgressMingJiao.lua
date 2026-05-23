local UISkillProgressMingJiao = class("UISkillProgressMingJiao")

function UISkillProgressMingJiao:OnEnter()
    if g_pClientPlayer and g_pClientPlayer.dwForceID == FORCE_TYPE.DAO_ZONG then
        UIHelper.SetColor(self.ProgressBarRageSun, cc.c3b(209, 255, 255))
        UIHelper.SetColor(self.ProgressBarRageMoon, cc.c3b(209, 255, 255))
        UIHelper.SetVisible(self.ImgSkillBarLine, false)
    end
    if g_pClientPlayer and g_pClientPlayer.dwForceID == FORCE_TYPE.MING_JIAO then
        UIHelper.SetColor(self.ProgressBarRageSun, cc.c3b(255, 251, 78))
        UIHelper.SetColor(self.ProgressBarRageMoon, cc.c3b(194, 244, 255))
        UIHelper.SetVisible(self.ImgSkillBarLine, true)
    end
    if g_pClientPlayer and g_pClientPlayer.dwForceID == FORCE_TYPE.DUAN_SHI then
        UIHelper.SetColor(self.ProgressBarRageSun, cc.c3b(255, 251, 78))
        UIHelper.SetColor(self.ProgressBarRageMoon, cc.c3b(194, 244, 255))
        UIHelper.SetVisible(self.WidgetLineDuanShi, true)
    end
    UIHelper.SetProgressBarPercent(self.ProgressBarRageMoon, 10)
    UIHelper.SetProgressBarPercent(self.ProgressBarRageSun, 10)
end

function UISkillProgressMingJiao:OnExit()

end

function UISkillProgressMingJiao:OnUpdate()
    local player = g_pClientPlayer
    --print(player.nCurrentMoonEnergy,player.nMaxMoonEnergy)
    if player.dwForceID == FORCE_TYPE.MING_JIAO then
        UIHelper.SetProgressBarPercent(self.ProgressBarRageMoon, 22 * player.nCurrentMoonEnergy / player.nMaxMoonEnergy)
        UIHelper.SetProgressBarPercent(self.ProgressBarRageSun, 22 * player.nCurrentSunEnergy / player.nMaxSunEnergy) -- 最大百分比为22
    elseif player.dwForceID == FORCE_TYPE.DAO_ZONG then
        local nRage = 100 * player.nCurrentRage / player.nMaxRage
        local nLower = math.min(1, nRage / 50) * 22
        local nUpper = math.max(0, nRage / 50 - 1) * 22
        UIHelper.SetProgressBarPercent(self.ProgressBarRageSun, nLower)
        UIHelper.SetProgressBarPercent(self.ProgressBarRageMoon, nUpper)
    elseif player.dwForceID == FORCE_TYPE.DUAN_SHI then      
        UIHelper.SetProgressBarPercent(self.ProgressBarRageMoon, 22 * player.nCurrentMoonEnergy / player.nMaxMoonEnergy)
        UIHelper.SetProgressBarPercent(self.ProgressBarRageSun, 22 * player.nCurrentSunEnergy / player.nMaxSunEnergy) -- 最大百分比为22
    end
end

return UISkillProgressMingJiao