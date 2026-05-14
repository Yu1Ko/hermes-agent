-- ---------------------------------------------------------------------------------
-- Author: luwenhao
-- Name: UIPanelYangDaoMainCityCardShowView
-- Date: 2026-03-27 17:23:37
-- Desc: 扬刀大会-主界面卡片动画展示界面（如点燃等） PanelYangDaoMainCityCardShow
-- ---------------------------------------------------------------------------------

local UIPanelYangDaoMainCityCardShowView = class("UIPanelYangDaoMainCityCardShowView")

function UIPanelYangDaoMainCityCardShowView:OnEnter(nAniEvent, nCardID)
    if not self.bInit then
        self:RegEvent()
        self:BindUIEvent()
        self.bInit = true
    end

    local tBlessCardList = ArenaTowerData.GetCardListInfo()
    for _, tCardData in ipairs(tBlessCardList or {}) do
        if tCardData.nCardID == nCardID then
            tCardData.nAniEvent = nAniEvent -- SetAniEvent
            self.tCardData = tCardData
            break
        end
    end

    if not self.tCardData then
        LOG.ERROR("[ArenaTower] UIPanelYangDaoMainCityCardShowView:OnEnter Error, player does not has card: %s", tostring(nCardID))
        UIMgr.Close(self)
        return
    end

    self:UpdateInfo()
end

function UIPanelYangDaoMainCityCardShowView:OnExit()
    self.bInit = false
    self:UnRegEvent()
end

function UIPanelYangDaoMainCityCardShowView:BindUIEvent()

end

function UIPanelYangDaoMainCityCardShowView:RegEvent()
    --Event.Reg(self, EventType.XXX, func)
end

function UIPanelYangDaoMainCityCardShowView:UnRegEvent()
    --Event.UnReg(self, EventType.XXX)
end

function UIPanelYangDaoMainCityCardShowView:UpdateInfo()
    Timer.DelAllTimer(self)

    local tCardData = self.tCardData
    if not tCardData then
        return
    end

    local script = UIHelper.AddPrefab(PREFAB_ID.WidgetBlessCardL, self.WidgetAnchorCardShell)
    script:OnInitLargeCard(tCardData)

    UIHelper.StopAllAni(self)
    Timer.Add(self, 2.5, function()
        UIHelper.PlayAni(self, self.AniAll, "AniYangDaoMainCityCardShow", function()
            UIMgr.Close(self)
            Event.Dispatch(EventType.OnArenaTowerCardEventAniEnd)
        end)
    end)
end


return UIPanelYangDaoMainCityCardShowView