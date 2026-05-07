-- ---------------------------------------------------------------------------------
-- Author: Unknown
-- Name: UIWidgetActionBarSkillUsed
-- Date: 2023-12-06 16:29:42
-- Desc: ?
-- ---------------------------------------------------------------------------------

local UIWidgetActionBarSkillUsed = class("UIWidgetActionBarSkillUsed")

function UIWidgetActionBarSkillUsed:OnEnter(tbSkillInfo, bItem, nIndex, bDynamicSkill)
    if not self.bInit then
        self:RegEvent()
        self:BindUIEvent()
        self.bInit = true
    end

    self.bItem = bItem
    self.bDynamicSkill = bDynamicSkill

    if bItem then
        self.tbItemInfoList = tbSkillInfo
        self.nIndex = nIndex
        self:UpdateItemInfo()
        return
    end

    self.tbSkillInfo = tbSkillInfo
    self.nIndex = nIndex

    if not tbSkillInfo then
        return
    end

    if tbSkillInfo.bSimpleSkill then
        self:UpdateSimpleSkill()
        return
    end

    self:UpdateInfo()
end

function UIWidgetActionBarSkillUsed:OnExit()
    self.bInit = false
    self:UnRegEvent()
end

function UIWidgetActionBarSkillUsed:BindUIEvent()

end

function UIWidgetActionBarSkillUsed:RegEvent()
    Event.Reg(self, EventType.OnActionBarBtnClick, function(nIndex, bIsDown)
        if self.nIndex == nIndex then
            if self.bItem then
                Event.Dispatch(EventType.OnShortcutUseQuickItem, 300 + nIndex, bIsDown and 1 or 3)
            else
                Event.Dispatch(EventType.OnShortcutUseSkillSelect, 200 + nIndex, bIsDown and 1 or 3)
            end
        end
    end)

    Event.Reg(self, "BAG_ITEM_UPDATE", function(_nBox, _nIndex, _bNewAdd)
        if self.bItem then
            self:UpdateFuncName()
        end
    end)
end

function UIWidgetActionBarSkillUsed:UnRegEvent()
    --Event.UnReg(self, EventType.XXX)
end






-- ----------------------------------------------------------
-- Please write your own code below  ↓↓↓
-- ----------------------------------------------------------

function UIWidgetActionBarSkillUsed:UpdateInfo()
    UIHelper.RemoveAllChildren(self.WidgetSkillNormal)
    self.scriptSkill = UIHelper.AddPrefab(PREFAB_ID.WidgetNormalSkill, self.WidgetSkillNormal, 200 + self.nIndex)
    self.scriptSkill:SwitchDynamicSkills(true, self.tbSkillInfo)

    local scriptMainCity = UIMgr.GetViewScript(VIEW_ID.PanelMainCity)
    local scriptCancel = scriptMainCity:GetSkillCanCelScript()
    local scriptDirection = scriptMainCity:GetSkillDirectionScript()

    self.scriptSkill:SetSkillCancelCtrl(scriptCancel)
    self.scriptSkill:SetSkillDirectionCtrl(scriptDirection)

    self:UpdateFuncName()
end

function UIWidgetActionBarSkillUsed:UpdateSimpleSkill()
    local nSkillID = self.tbSkillInfo.id

    UIHelper.RemoveAllChildren(self.WidgetSkillNormal)
    self.scriptSkill = UIHelper.AddPrefab(PREFAB_ID.WidgetSimpleSkill, self.WidgetSkillNormal, 200 + self.nIndex)
    self.scriptSkill:InitSkill(nSkillID)

    local szIcon = FeiXingIconDict[nSkillID]
    if szIcon then
        self.scriptSkill:UpdateIcon(szIcon)
    end
end

function UIWidgetActionBarSkillUsed:UpdateQuickMark(nIndex)
    UIHelper.RemoveAllChildren(self.WidgetSkillNormal)
    self.scriptSkill = UIHelper.AddPrefab(PREFAB_ID.WidgetQuickMark, self.WidgetSkillNormal, 200 + self.nIndex, nIndex)

    local scriptMainCity = UIMgr.GetViewScript(VIEW_ID.PanelMainCity)
    local scriptCancel = scriptMainCity:GetSkillCanCelScript()
    local scriptDirection = scriptMainCity:GetSkillDirectionScript()

    self.scriptSkill:SetSkillCancelCtrl(scriptCancel)
    self.scriptSkill:SetSkillDirectionCtrl(scriptDirection)
end

function UIWidgetActionBarSkillUsed:UpdateDXYaoZongPlant(nIndex)
    UIHelper.RemoveAllChildren(self.WidgetSkillNormal)
    self.scriptSkill = UIHelper.AddPrefab(PREFAB_ID.WidgetYaoZongCangJi, self.WidgetSkillNormal, nIndex)
end

function UIWidgetActionBarSkillUsed:GetDynamicSkillName(nSkillID)
    local szName = ""
    local tbFuncName = UIDynamicSkillInfoTab[nSkillID]
    if tbFuncName then
        szName = UIHelper.GetUtf8SubString(tbFuncName.szFuncName, 1, 4)
    else
        szName = UIHelper.GetUtf8SubString(SkillData.GetSkillName(nSkillID, self.nDynamicSkillLevel), 1, 4)
    end
    return szName
end

function UIWidgetActionBarSkillUsed:UpdateFuncName()
    UIHelper.SetVisible(self.LabelName, true)
    UIHelper.SetString(self.LabelName, " ")
    if g_pClientPlayer and self.bDynamicSkill then
        local szName = self:GetDynamicSkillName(self.tbSkillInfo.id)
        UIHelper.SetString(self.LabelName, szName)
    end
    UIHelper.LayoutDoLayout(self.Layout)
end

function UIWidgetActionBarSkillUsed:UpdateItemInfo()
    UIHelper.RemoveAllChildren(self.WidgetSkillNormal)
    self.scriptQuickUseItem = UIHelper.AddPrefab(PREFAB_ID.WidgetQuickUseItem, self.WidgetSkillNormal, 300 + self.nIndex, self.tbItemInfoList, true)

    local scriptMainCity = UIMgr.GetViewScript(VIEW_ID.PanelMainCity)
    local scriptCancel = scriptMainCity:GetSkillCanCelScript()
    local scriptDirection = scriptMainCity:GetSkillDirectionScript()

    self.scriptQuickUseItem:SetSkillCancelCtrl(scriptCancel)
    self.scriptQuickUseItem:SetSkillDirectionCtrl(scriptDirection)
    self:UpdateFuncName()
end

function UIWidgetActionBarSkillUsed:UnBindUIEvent()
    local scriptItem = self.bItem and self.scriptQuickUseItem or self.scriptSkill
    if scriptItem then
        UIHelper.UnBindUIEvent(scriptItem.skillBtn, EventType.OnTouchBegan)
        UIHelper.UnBindUIEvent(scriptItem.skillBtn, EventType.OnLongPress)
        UIHelper.UnBindUIEvent(scriptItem.skillBtn, EventType.OnTouchMoved)
        UIHelper.UnBindUIEvent(scriptItem.skillBtn, EventType.OnTouchEnded)
        UIHelper.UnBindUIEvent(scriptItem.skillBtn, EventType.OnTouchCanceled)
        UIHelper.UnBindUIEvent(scriptItem.skillBtn, EventType.OnClick)
        UIHelper.SetButtonState(scriptItem.skillBtn, BTN_STATE.Normal)
    end
end

return UIWidgetActionBarSkillUsed