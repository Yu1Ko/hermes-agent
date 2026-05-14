local UISkillProgressYaoZong = class("UISkillProgressYaoZong")

function UISkillProgressYaoZong:OnEnter()

end

function UISkillProgressYaoZong:OnExit()

end

function UISkillProgressYaoZong:OnUpdate()
   local player = g_pClientPlayer
    local nOrigin = 100

    local nDots = 3
    for i = 1, nDots do
        UIHelper.SetVisible(self.yz_reds[i], false)
        UIHelper.SetVisible(self.yz_blues[i], false)
    end

    local nDist = math.abs(player.nNaturePowerValue - nOrigin)
    if player.nNaturePowerValue > nOrigin then
        for i = 1, nDist do
            UIHelper.SetVisible(self.yz_reds[i], true)
        end
    elseif player.nNaturePowerValue < nOrigin then
        for i = 1, nDist do
            UIHelper.SetVisible(self.yz_blues[i], true)
        end
    end
end

return UISkillProgressYaoZong