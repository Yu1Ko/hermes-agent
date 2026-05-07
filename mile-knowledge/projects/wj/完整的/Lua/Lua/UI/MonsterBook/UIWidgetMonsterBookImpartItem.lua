local UIWidgetMonsterBookImpartItem = class("UIWidgetMonsterBookImpartItem")

function UIWidgetMonsterBookImpartItem:OnEnter(dwSkillID, nLevel, fRemoveCallBack)
    if not self.bInit then
        self:RegEvent()
        self:BindUIEvent()
        self.bInit = true
    end

    self.fRemoveCallBack = fRemoveCallBack
    if dwSkillID and dwSkillID > 0 then
        self.dwSkillID = dwSkillID
        self.nLevel = nLevel
        self:UpdateInfo()
    end
    self:UpdateState(dwSkillID)
end

function UIWidgetMonsterBookImpartItem:OnExit()
    self.bInit = false
    self:UnRegEvent()
end

function UIWidgetMonsterBookImpartItem:BindUIEvent()
    UIHelper.BindUIEvent(self.BtnRemove, EventType.OnClick, function ()
        if self.fRemoveCallBack then
            self.fRemoveCallBack()
        end
    end)

    UIHelper.SetLongPressDelay(self.BtnTips, SHOW_TIP_PRESS_TIME)
    UIHelper.SetLongPressDistThreshold(self.BtnTips, 5)
    UIHelper.BindUIEvent(self.BtnTips, EventType.OnLongPress, function(_, x, y)
        if self.dwSkillID then
            local nSkillLevel = self.nLevel or g_pClientPlayer.GetSkillLevel(self.dwSkillID)
            if nSkillLevel == 0 then
                nSkillLevel = 1
            end

            local tCursor = GetCursorPoint()
            local dwOutSkillID = MonsterBookData.tIn2OutSkillMap[self.dwSkillID] or self.dwSkillID
            local tips, tipsScriptView = TipsHelper.ShowClickHoverTips(PREFAB_ID.WidgetBZSkillTip, tCursor.x,
                    tCursor.y, dwOutSkillID)
            tipsScriptView:SetBtnVisible(false)
        end
    end)

    UIHelper.BindUIEvent(self.BtnTips, EventType.OnTouchEnded, function()
        TipsHelper.DeleteHoverTips(PREFAB_ID.WidgetSkillInfoTips)
    end)

    UIHelper.BindUIEvent(self.BtnTips, EventType.OnTouchCanceled, function()
        TipsHelper.DeleteHoverTips(PREFAB_ID.WidgetSkillInfoTips)
    end)
end

function UIWidgetMonsterBookImpartItem:RegEvent()

end

function UIWidgetMonsterBookImpartItem:UnRegEvent()
    --Event.UnReg(self, EventType.XXX)
end

-- ----------------------------------------------------------
-- Please write your own code below  ↓↓↓
-- ----------------------------------------------------------

function UIWidgetMonsterBookImpartItem:UpdateInfo()
    self.bCollected = self.nLevel and self.nLevel > 0
    local nLevel = self.nLevel
    if not self.bCollected then
        self.nLevel = 1
    end
    local tSkill = GetSkill(self.dwSkillID, self.nLevel) or {bIsPassiveSkill = false}
    self.tSkillInfo = Table_GetMonsterSkillInfo(self.dwSkillID)
    local bEmptySkill = MonsterBookData.IsEmptySkill(self.dwSkillID, self.tSkillInfo)
    if not bEmptySkill then
        local szLevel = MonsterBookData.GetLevelText(self.nLevel)
        if nLevel == 0 then
            szLevel = ""
        end
        local dwOutSkillID = MonsterBookData.tIn2OutSkillMap[self.dwSkillID] or self.dwSkillID
        local szImagePath = TabHelper.GetSkillIconPathByIDAndLevel(dwOutSkillID, self.nLevel)
        local szFramePath = MonsterBookData.GetEdgeFramePath(self.tSkillInfo.nColor)
        
        UIHelper.SetString(self.LabelLevel, szLevel)
        UIHelper.SetTexture(self.ImgItemIcon, szImagePath)
        if szFramePath then
            UIHelper.SetSpriteFrame(self.ImgColorFrame, szFramePath)
        end        
        UIHelper.SetVisible(self.ImgColorFrame, szFramePath ~= nil)
        UIHelper.SetVisible(self.ImgPassiveFrame, tSkill.bIsPassiveSkill)
        for nIndex, ImgCostPoint in ipairs(self.ImgCostPointList) do
            UIHelper.SetVisible(ImgCostPoint, nIndex <= self.tSkillInfo.nCost)
        end
        UIHelper.LayoutDoLayout(self.LayoutCost)

        local szSkillName = UIHelper.GBKToUTF8(self.tSkillInfo.szSkillName)
        UIHelper.SetString(self.LabelSkillName, szSkillName)
    end
    
    UIHelper.SetVisible(self.LabelSkillName, self.bShowSkillName)
    UIHelper.SetVisible(self.LabelLevel, not bEmptySkill)
    UIHelper.SetVisible(self.LabelName, not bEmptySkill)
    UIHelper.SetNodeGray(self.ImgItemIcon, not self.bCollected, true)
    Timer.AddFrame(self, 1, function ()
        UIHelper.UpdateMask(self.MaskItem)
        --UIHelper.UpdateMask(self.MaskSkill1)
        --UIHelper.UpdateMask(self.MaskSkill2)
    end)
end

function UIWidgetMonsterBookImpartItem:UpdateState(dwSkillID)
    UIHelper.SetVisible(self.WidgetEmpty, dwSkillID == nil)
    UIHelper.SetVisible(self.WidgetAddSign, dwSkillID and dwSkillID == 0)
    UIHelper.SetVisible(self.WidgetItem,  dwSkillID and dwSkillID > 0)
    UIHelper.SetVisible(self.BtnRemove, self.fRemoveCallBack ~= nil)

    if dwSkillID == nil then
        UIHelper.SetTextColor(self.LabelSkillName, cc.c4b(0xae,0xd6,0xe0, 153))
        UIHelper.SetString(self.LabelSkillName, "未激活")
    end
end

function UIWidgetMonsterBookImpartItem:SetSkillNameEnable(bEnable)
    self.bShowSkillName = bEnable
    UIHelper.SetVisible(self.LabelSkillName, self.bShowSkillName)
end

return UIWidgetMonsterBookImpartItem