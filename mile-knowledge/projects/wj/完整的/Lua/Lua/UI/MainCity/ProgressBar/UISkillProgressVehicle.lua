local UISkillProgressVehicle = class("UISkillProgressVehicle")

function UISkillProgressVehicle:OnEnter()

end

function UISkillProgressVehicle:OnExit()

end

function UISkillProgressVehicle:OnUpdate()
    local player = g_pClientPlayer
    UIHelper.SetProgressBarPercent(self.ProgressBarRageVehicleBlood, 100 * player.nCurrentLife / player.nMaxLife)
    UIHelper.SetProgressBarPercent(self.ProgressBarRageVehicleSkill, 100 * player.nCurrentMana / player.nMaxMana)
end

return UISkillProgressVehicle