local UISkillProgressPartnerNormal = class("UISkillProgressPartnerNormal")

function UISkillProgressPartnerNormal:OnEnter()
    Timer.AddFrame(self,3,function ()
        UIHelper.SetProgressBarPercent(self.ProgressBarRagePartner, 10)
    end)
end

function UISkillProgressPartnerNormal:OnExit()

end

function UISkillProgressPartnerNormal:OnUpdate()
    if g_pClientPlayer and g_pClientPlayer.dwMorphID > 0 then
        local nBuff, nMaxBuff = PartnerData.GetBuffCount()
        UIHelper.SetProgressBarPercent(self.ProgressBarRagePartner, (nBuff / nMaxBuff) * 100)
    end
end

return UISkillProgressPartnerNormal