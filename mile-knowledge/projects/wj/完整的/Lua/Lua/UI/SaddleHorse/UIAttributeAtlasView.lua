-- ---------------------------------------------------------------------------------
-- Author: Unknown
-- Name: UIAttributeAtlasView
-- Date: 2022-12-07 15:06:54
-- Desc: ?
-- ---------------------------------------------------------------------------------

local UIAttributeAtlasView = class("UIAttributeAtlasView")

function UIAttributeAtlasView:OnEnter(tAllAttr)
    if not self.bInit then
        self:RegEvent()
        self:BindUIEvent()
        self.bInit = true
    end

    self.tAllAttr = tAllAttr
    self.ScrollViewBasicContent:setTouchDownHideTips(false)
    self:UpdateAttributeLevel()
    self:UpdateInfo()
end

function UIAttributeAtlasView:OnExit()
    self.bInit = false
    self:UnRegEvent()
end

function UIAttributeAtlasView:BindUIEvent()
    UIHelper.BindUIEvent(self.BtnClose,EventType.OnClick,function ()
        UIMgr.Close(self)
    end)
end

function UIAttributeAtlasView:RegEvent()
    --Event.Reg(self, EventType.XXX, func)
    Event.Reg(self, EventType.HideAllHoverTips, function ()
        if self.scriptItemTip then
            self.scriptItemTip:OnInit()
            self.scriptItemTip = nil
            UIHelper.SetVisible(self.WidgetTip,false)
        end
    end)
end

function UIAttributeAtlasView:UnRegEvent()
    --Event.UnReg(self, EventType.XXX)
end






-- ----------------------------------------------------------
-- Please write your own code below  ↓↓↓
-- ----------------------------------------------------------

function UIAttributeAtlasView:UpdateInfo()
    --UIHelper.LayoutDoLayout(self.LayoutBasicContent)
    local tAllBasic, tAllMagic = Table_GetHorseAttrs()
    for nIndex, v in pairs(tAllBasic) do
        self:UpdateAttributeInfo(nIndex, v, false)
    end

    for nIndex, v in pairs(tAllMagic) do
        self:UpdateAttributeInfo(nIndex, v, true)
    end

    UIHelper.LayoutDoLayout(self.LayoutBasicAttrib)
    UIHelper.LayoutDoLayout(self.LayoutSpecialAttrib)
    UIHelper.ScrollViewDoLayout(self.ScrollViewBasicContent)
    UIHelper.ScrollToTop(self.ScrollViewBasicContent)
end

function UIAttributeAtlasView:UpdateAttributeInfo(nIndex, v, bVisible)
    local line = Table_GetHorseTuJianAttr(nIndex, 0)
    local szName = UIHelper.GBKToUTF8(line.szName)
    local szChildTip = ParseTextHelper.ParseNormalText(UIHelper.GBKToUTF8(line.szTuJianTip), true)
    local AttributeScripts
    if not bVisible then
        AttributeScripts = UIHelper.AddPrefab(PREFAB_ID.WidgetBasicContent, self.LayoutBasicAttrib)
    else
        AttributeScripts = UIHelper.AddPrefab(PREFAB_ID.WidgetBasicContent, self.LayoutSpecialAttrib)
    end

    if AttributeScripts then
        UIHelper.SetSwallowTouches(AttributeScripts.TogContent, false)
        UIHelper.SetString(AttributeScripts.LabelSpeed, szName)
        UIHelper.SetString(AttributeScripts.LabelSpeedSelected, szName)

        local number, szChildTip = UIHelper.TruncateString(szChildTip, 28, "...")
        UIHelper.SetString(AttributeScripts.LabelSpeedContent, szChildTip)
        UIHelper.SetString(AttributeScripts.LabelSpeedContentSelected, szChildTip)
        UIHelper.SetVisible(AttributeScripts.ImgIcon, bVisible)

        UIHelper.SetItemIconByIconID(AttributeScripts.ImgSkill, v[1].nIconID)
        UIHelper.SetVisible(AttributeScripts.WidgetNow, self.tbAttributeLevel[nIndex] and true or false)

        if bVisible then
            UIHelper.BindUIEvent(AttributeScripts.TogContent,EventType.OnSelectChanged, function (_, bSelected)
                UIHelper.RemoveAllChildren(self.WidgetTip)
                if bSelected then
                    local _, tAllMagic = Table_GetHorseAttrs()
                    if tAllMagic[nIndex] then
                        self.scriptItemTip = UIHelper.AddPrefab(PREFAB_ID.WidgetEquitationTip, self.WidgetTip)
                        self.scriptItemTip:OnInit(nIndex, self.tbAttributeLevel[nIndex])
                        UIHelper.SetVisible(self.WidgetTip, true)
                        UIHelper.SetVisible(AttributeScripts.WidgetNormal, not bSelected)
                        UIHelper.SetVisible(AttributeScripts.WidgetSelected, bSelected)
                    end
                end
            end )
        end
    end
end

function UIAttributeAtlasView:UpdateAttributeLevel()
    self.tbAttributeLevel = {}
    for _, tab in ipairs(self.tAllAttr) do
        local dwID, nLevel, nValue = tab[1], tab[2], tab[3]
        local tAttr = Table_GetHorseChildAttr(dwID, nLevel)
        if tAttr and tAttr.nType == 1 then
            tAttr.nLevel = nLevel
            self.tbAttributeLevel[dwID] = nLevel
        end
    end


end

return UIAttributeAtlasView