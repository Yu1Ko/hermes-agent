local UISkillProgressPartnerDou = class("UISkillProgressPartnerDou")

function UISkillProgressPartnerDou:OnEnter()

end

function UISkillProgressPartnerDou:OnExit()

end

function UISkillProgressPartnerDou:OnUpdate()
    if g_pClientPlayer and g_pClientPlayer.dwMorphID > 0 then
        local nBuff, nMaxBuff = PartnerData.GetBuffCount()
        local nCurrentCount = nMaxBuff == 5 and nBuff * 2 or nBuff
        for i = 1, 10 do
            UIHelper.SetVisible(self.tPartnerDous[i], i <= nCurrentCount)
        end
    end
end

return UISkillProgressPartnerDou