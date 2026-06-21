-- ---------------------------------------------------------------------------------
-- Author: Unknown
-- Name: UIHomelandIdentityBaseTipList
-- Date: 2024-01-22 11:20:45
-- Desc: ?
-- ---------------------------------------------------------------------------------

local UIHomelandIdentityBaseTipList = class("UIHomelandIdentityBaseTipList")

function UIHomelandIdentityBaseTipList:OnEnter(tbIdentityBaseTip)
    if not self.bInit then
        self:RegEvent()
        self:BindUIEvent()
        self.bInit = true
    end
    self.tbIdentityBaseTip = tbIdentityBaseTip
    self:UpdateInfo()
end

function UIHomelandIdentityBaseTipList:InitWithFishHolder(tInfo, nWeight, nStar)
    if not self.bInit then
        self:RegEvent()
        self:BindUIEvent()
        self.bInit = true
    end
    UIHelper.SetString(self.LabelTitle, g_tStrings.STR_HOMELAND_FISH_HOLDER_TITLE)
    self.scriptContent = self.scriptContent or UIHelper.AddPrefab(PREFAB_ID.WidgetTipsLabelCell, self.LayoutTipsLabelCell)
    self.scriptContent:InitFishHolder(tInfo, nWeight, nStar)
    UIHelper.CascadeDoLayoutDoWidget(self.WidgetTipsLabelList, true, false)
end

function UIHomelandIdentityBaseTipList:OnExit()
    self.bInit = false
    self:UnRegEvent()
end

function UIHomelandIdentityBaseTipList:BindUIEvent()

end

function UIHomelandIdentityBaseTipList:RegEvent()
    --Event.Reg(self, EventType.XXX, func)
end

function UIHomelandIdentityBaseTipList:UnRegEvent()
    --Event.UnReg(self, EventType.XXX)
end






-- ----------------------------------------------------------
-- Please write your own code below  ↓↓↓
-- ----------------------------------------------------------

function UIHomelandIdentityBaseTipList:UpdateInfo()
    local tbTips = self.tbIdentityBaseTip.tbTip
    if not tbTips or table.is_empty(tbTips) then
        return
    end

    local bEmpty = true
    UIHelper.RemoveAllChildren(self.LayoutTipsLabelCell)
    for _, tbTip in ipairs(tbTips) do
        if not empty(tbTip.szContent) then
            local script = UIHelper.AddPrefab(PREFAB_ID.WidgetTipsLabelCell, self.LayoutTipsLabelCell)
            script:OnEnter(tbTip)
            bEmpty = false
        end
    end
    if bEmpty then
        UIHelper.SetVisible(self._rootNode, false)
    end
    UIHelper.SetString(self.LabelTitle, self.tbIdentityBaseTip.szTitle)
    UIHelper.CascadeDoLayoutDoWidget(self.WidgetTipsLabelList, true, false)
end

function UIHomelandIdentityBaseTipList:UpdateHolderInfo(tHolder)
    self.scriptContent:UpdateFishHolderInfo(tHolder)
end

return UIHomelandIdentityBaseTipList