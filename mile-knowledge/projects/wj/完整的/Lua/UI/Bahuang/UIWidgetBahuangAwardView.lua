-- ---------------------------------------------------------------------------------
-- Author: Unknown
-- Name: UIWidgetBahuangAwardView
-- Date: 2024-01-23 14:43:48
-- Desc: ?
-- ---------------------------------------------------------------------------------

local UIWidgetBahuangAwardView = class("UIWidgetBahuangAwardView")

function UIWidgetBahuangAwardView:OnEnter(tbAwardInfo, nCurrentLevel, nIndex, bLevel)
    if not self.bInit then
        self:RegEvent()
        self:BindUIEvent()
        self.bInit = true
    end
    self.tbAwardInfo = tbAwardInfo
    self.nCurrentLevel = nCurrentLevel
    self.nIndex = nIndex
    if bLevel then
        self:UpdateLevelAward()
    else
        self:UpdateCommonAward()
    end
end

function UIWidgetBahuangAwardView:OnExit()
    self.bInit = false
    self:UnRegEvent()
end

function UIWidgetBahuangAwardView:BindUIEvent()

end

function UIWidgetBahuangAwardView:RegEvent()
    --Event.Reg(self, EventType.XXX, func)
end

function UIWidgetBahuangAwardView:UnRegEvent()
    --Event.UnReg(self, EventType.XXX)
end






-- ----------------------------------------------------------
-- Please write your own code below  ↓↓↓
-- ----------------------------------------------------------

function UIWidgetBahuangAwardView:UpdateCommonAward()
    local tbAwardInfo = self.tbAwardInfo
    local scriptView = UIHelper.AddPrefab(PREFAB_ID.WidgetItem_80, self.WidgetItem_80)
    scriptView:OnInitWithTabID(tbAwardInfo[1][1], tbAwardInfo[1][2], tbAwardInfo[1][3])
    scriptView:SetClickNotSelected(true)
    scriptView:SetToggleSwallowTouches(false)
    scriptView:SetClickCallback(function()
        local tips, scriptTips = TipsHelper.ShowNodeHoverTips(PREFAB_ID.WidgetItemTip, scriptView._rootNode)
        scriptTips:OnInitWithTabID(tbAwardInfo[1][1], tbAwardInfo[1][2])
    end)

    local tbPointAccrue = BahuangData.GetPointAccrue()
    UIHelper.SetString(self.LabelAwardCondiction, tbPointAccrue.tPoint[self.nIndex].."积分")

    local bGet = self.nCurrentLevel >= self.nIndex
    UIHelper.SetVisible(self.ImgGet, bGet)
    UIHelper.SetVisible(self.ImgGet1, bGet)
    local szImageLeft = bGet and "UIAtlas2_Public_PublicItem_PublicItem1_Img_Bar_Color.png" or "UIAtlas2_Public_PublicItem_PublicItem1_Img_Bar_Bg.png"
    UIHelper.SetVisible(self.ImgLineBefore, self.nIndex ~= 1)
    UIHelper.SetSpriteFrame(self.ImgLineBefore, szImageLeft)
end

function UIWidgetBahuangAwardView:UpdateLevelAward()
    local tbAwardInfo = self.tbAwardInfo
    local bSkill = tbAwardInfo.key == "Skill"
    local parent = bSkill and self.ImgSkillIcon or self.WidgetItem_80
    local scriptView = UIHelper.AddPrefab(PREFAB_ID.WidgetItem_80, parent)
    local bGet = self.nCurrentLevel >= tbAwardInfo.nLevel
    if bSkill then
        scriptView:OnInitSkill(tbAwardInfo.tSkill.dwSkillID, tbAwardInfo.tSkill.dwLevel, function()
            UIHelper.UpdateMask(self.MaskSkill)
        end, false)
        UIHelper.UpdateMask(self.MaskSkill)
    else
        scriptView:OnInitWithTabID(tbAwardInfo.tItem[1], tbAwardInfo.tItem[2], tbAwardInfo.tItem[3])
        scriptView:SetClickNotSelected(true)
        UIHelper.SetVisible(self.ImgGet1, bGet)
    end
    scriptView:SetToggleSwallowTouches(false)

    scriptView:SetClickCallback(function()
        if bSkill then
            local tips, tipsScriptView = TipsHelper.ShowNodeHoverTips(PREFAB_ID.WidgetSkillInfoTips, scriptView._rootNode,
            tbAwardInfo.tSkill.dwSkillID, nil, nil, tbAwardInfo.tSkill.dwLevel)
            tipsScriptView:SetBtnVisible(false)
        else
            local tips, scriptTips = TipsHelper.ShowNodeHoverTips(PREFAB_ID.WidgetItemTip, scriptView._rootNode)
            scriptTips:OnInitWithTabID(tbAwardInfo.tItem[1], tbAwardInfo.tItem[2])
        end
    end)

    local bGet = self.nCurrentLevel >= tbAwardInfo.nLevel

    UIHelper.SetVisible(self.ImgGet, bGet)
    UIHelper.SetString(self.LabelAwardCondiction, tbAwardInfo.nLevel.."级")

    local szImageLeft = bGet and "UIAtlas2_Public_PublicItem_PublicItem1_Img_Bar_Color.png" or "UIAtlas2_Public_PublicItem_PublicItem1_Img_Bar_Bg.png"
    UIHelper.SetVisible(self.ImgLineBefore, self.nIndex ~= 1)
    UIHelper.SetSpriteFrame(self.ImgLineBefore, szImageLeft)

    UIHelper.SetVisible(self.WidgetSkill, bSkill)

    UIHelper.UpdateMask(self.MaskSkill)

end

return UIWidgetBahuangAwardView