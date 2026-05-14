-- ---------------------------------------------------------------------------------
-- Author: Unknown
-- Name: UIWidgetMiJiBtn
-- Date: 2022-11-14 19:57:23
-- Desc: ?
-- ---------------------------------------------------------------------------------
-- 本脚本已废弃
---@class UIWidgetSkillAttributeTips
local UIWidgetSkillAttributeTips = class("UIWidgetSkillAttributeTips")

function UIWidgetSkillAttributeTips:OnEnter(szSelectedName, szTotalNoun)
    if not self.bInit then
        self:RegEvent()
        self:BindUIEvent()
        self.bInit = true
    end

    self.szSelectedName = szSelectedName
    self.tTotalNounList = string.split(szTotalNoun, ",")

    UIHelper.SetTouchDownHideTips(self.ScrollViewSkillAttribute, false)
    UIHelper.SetTouchDownHideTips(self.BtnMask, false)
    UIHelper.SetTouchDownHideTips(self.LayoutListLess, false)
    UIHelper.SetTouchEnabled(self.LayoutListLess, true)

    --local scriptBG = UIMgr.AddPrefab(PREFAB_ID.WidgetTouchBackGround, self._rootNode, true, self)
    --scriptBG:SetTouchDownHideTips(PREFAB_ID.WidgetSkillAttributeTips)

    self:PlayAnim()
    self:UpdateInfo()
end

function UIWidgetSkillAttributeTips:OnExit()
    self.bInit = false
    Event.UnRegAll(self)
end

function UIWidgetSkillAttributeTips:BindUIEvent()
end

function UIWidgetSkillAttributeTips:RegEvent()

end

function UIWidgetSkillAttributeTips:UpdateInfo()
    if self.tTotalNounList then
        UIHelper.SetVisible(self.WidgetListLess, true)
        for _, szName in pairs(self.tTotalNounList) do
            local nNumber = tonumber(szName)
            local tNounInfo = UISpecialNoun[szName]
            local bSelected = szName == tostring(self.szSelectedName)

            -- 兼容端游的特殊名词逻辑 只显示选中的名词
            if nNumber and bSelected then
                local tSkillNounInfo = SkillData.g_tSkillNounsList[szName] or {}
                if tSkillNounInfo.szName then
                    szName = UIHelper.GBKToUTF8(tSkillNounInfo.szName)
                    local szDesc1, szDesc2 = ParseSkillDesc(tSkillNounInfo.szDesc, tSkillNounInfo.dwSkillID, tSkillNounInfo.dwSkillLevel)
                    local szDesc = UIHelper.GBKToUTF8(szDesc1)
                    tNounInfo = { szDescription = szDesc }
                end
            end
            if tNounInfo then
                UIHelper.AddPrefab(PREFAB_ID.WidgetSkillAttributeCell, self.LayoutListLess, szName, tNounInfo, bSelected)
            end
        end

        Timer.AddFrame(self, 1, function()
            UIHelper.CascadeDoLayoutDoWidget(self.LayoutListLess, true, true)
        end)
    else
        UIHelper.SetVisible(self.WidgetListFull, true)

        local nCount = 0
        local nSelectedIndex
        for szName, tInfo in pairs(UISpecialNoun) do
            local bIsSelected = szName == self.szSelectedName
            if bIsSelected then
                nSelectedIndex = nCount
            end

            UIHelper.AddPrefab(PREFAB_ID.WidgetSkillAttributeCell, self.ScrollViewSkillAttribute, szName, tInfo, bIsSelected)
            nCount = nCount + 1
        end

        UIHelper.ScrollViewDoLayout(self.ScrollViewSkillAttribute)
        UIHelper.ScrollToIndex(self.ScrollViewSkillAttribute, nSelectedIndex, 0)
    end
end

function UIWidgetSkillAttributeTips:PlayAnim()
    if not self.bPlayAni then
        self.bPlayAni = true
        UIHelper.SetOpacity(self.AniTip, 0) --设置初始状态，防止闪
        Timer.Add(self, 0.05, function()
            UIHelper.PlayAni(self, self.AniTip, "AniItemTip", function()
                self.bPlayAni = false
            end)
        end)
    end
end

return UIWidgetSkillAttributeTips
