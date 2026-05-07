-- ---------------------------------------------------------------------------------
-- Author: luwenhao1
-- Name: UIWidgetTaskGongFang
-- Date: 2023-06-13 16:35:45
-- Desc: WidgetTaskGongFang 左侧信息 阵营大攻防士气条、Boss头像等
-- ---------------------------------------------------------------------------------

local UIWidgetTaskGongFang = class("UIWidgetTaskGongFang")

function UIWidgetTaskGongFang:OnEnter()
    if not self.bInit then
        self:RegEvent()
        self:BindUIEvent()
        self.bInit = true
    end

    self:UpdateInfo()
end

function UIWidgetTaskGongFang:OnExit()
    self.bInit = false
    self:UnRegEvent()
end

function UIWidgetTaskGongFang:BindUIEvent()
    UIHelper.BindUIEvent(self.BtnGongFang, EventType.OnClick, function()
        UIMgr.Open(VIEW_ID.PanelPvPCampMorale)
    end)
end

function UIWidgetTaskGongFang:RegEvent()
    Event.Reg(self, EventType.OnCameInfoUpdate, function()
        self:UpdateInfo()
    end)
end

function UIWidgetTaskGongFang:UnRegEvent()
    --Event.UnReg(self, EventType.XXX)
end






-- ----------------------------------------------------------
-- Please write your own code below  ↓↓↓
-- ----------------------------------------------------------

function UIWidgetTaskGongFang:UpdateInfo()
    --士气条
    local _, _, fPercentage = CampData.GetMoraleInfo()
    UIHelper.SetProgressBarPercent(self.SliderHaoQi, fPercentage * 100)

    local nLeft, nRight = 22, 202
    local nPosX = nLeft + (nRight - nLeft) * fPercentage
    UIHelper.SetPositionX(self.ImgHandle, nPosX)

    --Boss
    self:UpdateBossInfo()
end

function UIWidgetTaskGongFang:UpdateBossInfo()
    local tInfo = CampData.GetCampBossInfo()
    local nGoodIndex, nEvilIndex = 1, 1

    --print_table(tInfo)

    -- 浩气阵营boss
    for _, tNpcInfo in ipairs(tInfo.tGoodCampBoss or {}) do
        local widget = self.tWidgetHaoQi[nGoodIndex]
        local img = self.tImgHaoQi[nGoodIndex]
        local slider = self.tSliderBloodHaoQi[nGoodIndex]

        local szHeadImagePath = self:GetBossHeadImagePath(tNpcInfo.dwNpcTemplateID)
        
        UIHelper.SetVisible(widget, true)
        UIHelper.SetTexture(img, szHeadImagePath)
        UIHelper.SetProgressBarPercent(slider, tNpcInfo.nLifePercent)
        
        nGoodIndex = nGoodIndex + 1
    end
    
    -- 恶人阵营boss
    for _, tNpcInfo in ipairs(tInfo.tEvilCampBoss or {}) do
        local widget = self.tWidgetERen[nEvilIndex]
        local img = self.tImgERen[nEvilIndex]
        local slider = self.tSliderBloodERen[nEvilIndex]

        local szHeadImagePath = self:GetBossHeadImagePath(tNpcInfo.dwNpcTemplateID)
        
        UIHelper.SetVisible(widget, true)
        UIHelper.SetTexture(img, szHeadImagePath)
        UIHelper.SetProgressBarPercent(slider, tNpcInfo.nLifePercent)
        
        nEvilIndex = nEvilIndex + 1
    end
    
    for i = nGoodIndex, 4 do
        local widget = self.tWidgetHaoQi[i]
        UIHelper.SetVisible(widget, false)
    end
    
    for i = nEvilIndex, 4 do
        local widget = self.tWidgetERen[i]
        UIHelper.SetVisible(widget, false)
    end
    
    -- 浩气士气boss
    for _, tNpcInfo in ipairs(tInfo.tGoodMoraleBoss or {}) do
        local nMoraleIndex = CampData.GoodMoraleBossIndex[tNpcInfo.dwNpcTemplateID]
        local widget = self.tWidgetHaoQi[nMoraleIndex]
        local img = self.tImgHaoQi[nMoraleIndex]
        local slider = self.tSliderBloodHaoQi[nMoraleIndex]

        local szHeadImagePath = self:GetBossHeadImagePath(tNpcInfo.dwNpcTemplateID)
        
        UIHelper.SetVisible(widget, true)
        UIHelper.SetTexture(img, szHeadImagePath)
        UIHelper.SetProgressBarPercent(slider, tNpcInfo.nLifePercent)
    end
    
    -- 恶人士气boss
    for _, tNpcInfo in ipairs(tInfo.tEvilMoraleBoss or {}) do
        local nMoraleIndex = CampData.EvilMoraleBossIndex[tNpcInfo.dwNpcTemplateID]
        local widget = self.tWidgetERen[nMoraleIndex]
        local img = self.tImgERen[nMoraleIndex]
        local slider = self.tSliderBloodERen[nMoraleIndex]

        local szHeadImagePath = self:GetBossHeadImagePath(tNpcInfo.dwNpcTemplateID)
        
        UIHelper.SetVisible(widget, true)
        UIHelper.SetTexture(img, szHeadImagePath)
        UIHelper.SetProgressBarPercent(slider, tNpcInfo.nLifePercent)
    end

    UIHelper.LayoutDoLayout(self.LayoutHaoQi)
    UIHelper.LayoutDoLayout(self.LayoutEren)
end

function UIWidgetTaskGongFang:GetBossHeadImagePath(dwID)
	return "Resource/GFBoss/" .. dwID .. ".png"
end

return UIWidgetTaskGongFang