local UIWidgetMonsterBookSkillItem = class("UIWidgetMonsterBookSkillItem")

function UIWidgetMonsterBookSkillItem:OnEnter(dwSkillID, nLevel, fCallBack)
    if not self.bInit then
        self:RegEvent()
        self:BindUIEvent()
        self.bInit = true
    end

    self.dwSkillID = dwSkillID
    self.nLevel = nLevel
    self.fCallBack = fCallBack
    self:UpdateInfo()
end

function UIWidgetMonsterBookSkillItem:OnExit()
    self.bInit = false
    self:UnRegEvent()
end

function UIWidgetMonsterBookSkillItem:BindUIEvent()
    UIHelper.BindUIEvent(self.ToggleSelect, EventType.OnClick, function ()
        self.fCallBack()
    end)

    UIHelper.BindUIEvent(self.BtnClick, EventType.OnClick, function ()
        self.fCallBack(self)
    end)

    UIHelper.SetLongPressDelay(self.ToggleSelect, SHOW_TIP_PRESS_TIME)
    UIHelper.SetLongPressDistThreshold(self.ToggleSelect, 5)
    UIHelper.BindUIEvent(self.ToggleSelect, EventType.OnLongPress, function(_, x, y)
        if self.dwSkillID then
            local nSkillLevel = self.nLevel or g_pClientPlayer.GetSkillLevel(self.dwSkillID)
            if nSkillLevel == 0 then
                nSkillLevel = 1
            end

            self:ShowSkillTip()
        end
    end)

    UIHelper.BindUIEvent(self.ToggleSelect, EventType.OnTouchEnded, function()
        TipsHelper.DeleteHoverTips(PREFAB_ID.WidgetSkillInfoTips)
    end)

    UIHelper.BindUIEvent(self.ToggleSelect, EventType.OnTouchCanceled, function()
        TipsHelper.DeleteHoverTips(PREFAB_ID.WidgetSkillInfoTips)
    end)

    UIHelper.SetLongPressDelay(self.BtnClick, SHOW_TIP_PRESS_TIME)
    UIHelper.SetLongPressDistThreshold(self.BtnClick, 5)
    UIHelper.BindUIEvent(self.BtnClick, EventType.OnLongPress, function(_, x, y)
        if self.dwSkillID then
            local nSkillLevel = self.nLevel or g_pClientPlayer.GetSkillLevel(self.dwSkillID)
            if nSkillLevel == 0 then
                nSkillLevel = 1
            end

            self:ShowSkillTip()
        end
    end)

    UIHelper.BindUIEvent(self.BtnClick, EventType.OnTouchEnded, function()
        TipsHelper.DeleteHoverTips(PREFAB_ID.WidgetSkillInfoTips)
    end)

    UIHelper.BindUIEvent(self.BtnClick, EventType.OnTouchCanceled, function()
        TipsHelper.DeleteHoverTips(PREFAB_ID.WidgetSkillInfoTips)
    end)
end

function UIWidgetMonsterBookSkillItem:RegEvent()

end

function UIWidgetMonsterBookSkillItem:UnRegEvent()
    --Event.UnReg(self, EventType.XXX)
end

-- ----------------------------------------------------------
-- Please write your own code below  ↓↓↓
-- ----------------------------------------------------------

function UIWidgetMonsterBookSkillItem:UpdateInfo()
    self.bCollected = self.nLevel and self.nLevel > 0
    local nLevel = self.nLevel
    if not self.bCollected then
        nLevel = 1
    end
    local tSkill = GetSkill(self.dwSkillID, nLevel) or {bIsPassiveSkill = false}
    self.tSkillInfo = Table_GetMonsterSkillInfo(self.dwSkillID)
    local bEmptySkill = MonsterBookData.IsEmptySkill(self.dwSkillID, self.tSkillInfo)
    if not bEmptySkill then
        local szLevel = MonsterBookData.GetLevelText(nLevel)
        if nLevel == 0 then
            szLevel = ""
        end
        local szSkillName = UIHelper.GBKToUTF8(self.tSkillInfo.szSkillName)
        local szImagePath = TabHelper.GetSkillIconPathByIDAndLevel(self.dwSkillID, nLevel)
        local szFramePath = MonsterBookData.GetEdgeFramePath(self.tSkillInfo.nColor)
        
        UIHelper.SetString(self.LabelLevel, szLevel)
        UIHelper.SetString(self.LabelName, szSkillName)
        UIHelper.SetTexture(self.ImgItemIcon, szImagePath)
        UIHelper.SetSpriteFrame(self.ImgItemIcon, szImagePath)
        if szFramePath then
            UIHelper.SetSpriteFrame(self.ImgColorFrame, szFramePath)
        end        
        UIHelper.SetVisible(self.ImgColorFrame, szFramePath ~= nil)
        UIHelper.SetVisible(self.ImgPassiveFrame, tSkill.bIsPassiveSkill)
        for nIndex, ImgCostPoint in ipairs(self.ImgCostPointList) do
            UIHelper.SetVisible(ImgCostPoint, nIndex <= self.tSkillInfo.nCost)
        end
    end
    UIHelper.SetVisible(self.ImgLockedMask, not self.bCollected)
    UIHelper.SetVisible(self.LabelLevel, not bEmptySkill)
    UIHelper.SetVisible(self.LabelName, not bEmptySkill)
    UIHelper.SetNodeGray(self.ImgItemIcon, not self.bCollected, true)
    UIHelper.SetSwallowTouches(self.ToggleSelect, false)
    UIHelper.SetSwallowTouches(self.LayoutCost, false)
    UIHelper.LayoutDoLayout(self.LayoutCost)
    Timer.AddFrame(self, 1, function ()
        UIHelper.UpdateMask(self.MaskItem)
    end)
end

function UIWidgetMonsterBookSkillItem:ShowSkillTip()
    if self.bDisableSkillTip then -- 屏蔽Tips的时候长按与单击等效
        self.fCallBack(self)
        return
    end

    local tCursor = GetCursorPoint()
    local nLevel = self.nLevel
    if not self.bCollected then
        nLevel = 1
    end

    local dwOutSkillID = MonsterBookData.tIn2OutSkillMap[self.dwSkillID] or self.dwSkillID
    local tips, tipsScriptView = TipsHelper.ShowClickHoverTips(PREFAB_ID.WidgetBZSkillTip, tCursor.x,
            tCursor.y, dwOutSkillID)
    tipsScriptView:SetBtnVisible(false)
end

function UIWidgetMonsterBookSkillItem:SetMultiMode(bMultiMode)
    self.bMultiMode = bMultiMode
    UIHelper.SetVisible(self.BtnClick, bMultiMode)
    UIHelper.SetTouchEnabled(self.BtnClick, bMultiMode)
    UIHelper.SetTouchEnabled(self.ToggleSelect, not bMultiMode)
end

function UIWidgetMonsterBookSkillItem:SetMultiSelected(bSelected)
    self.bMultiSelected = bSelected
    UIHelper.SetVisible(self.ImgUp, self.bMultiSelected)
end

function UIWidgetMonsterBookSkillItem:SetActived(bActived)
    self.bActived = bActived
    UIHelper.SetVisible(self.Eff_Activated, self.bActived)
end

function UIWidgetMonsterBookSkillItem:SetDisableSkillTip(bDisableSkillTip)
    self.bDisableSkillTip = bDisableSkillTip
end

return UIWidgetMonsterBookSkillItem