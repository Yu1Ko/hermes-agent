-- ---------------------------------------------------------------------------------
-- Author: Unknown
-- Name: UICustomizedSetRecommendView
-- Date: 2024-07-19 15:45:31
-- Desc: ?
-- ---------------------------------------------------------------------------------

local UICustomizedSetRecommendView = class("UICustomizedSetRecommendView")
local MAX_ITEM_COUNT = 30

function UICustomizedSetRecommendView:OnEnter()
    if not self.bInit then
        self:RegEvent()
        self:BindUIEvent()
        self.bInit = true
    end

    self.nCurIndex = 1
    EquipCodeData.LoginAccount(false)
    self:UpdateInfo()
end

function UICustomizedSetRecommendView:OnExit()
    self.bInit = false
end

function UICustomizedSetRecommendView:BindUIEvent()
    UIHelper.BindUIEvent(self.BtnClose, EventType.OnClick, function(btn)
        UIMgr.Close(self)
    end)

    UIHelper.BindUIEvent(self.BtnApply, EventType.OnClick, function(btn)
        local tbSetData = EquipCodeData.tRecommendEquips and EquipCodeData.tRecommendEquips[self.nCurIndex]
        if not tbSetData then
            return
        end
        EquipCodeData.ImportCustomizedSetEquip(tbSetData, false)
        TipsHelper.ShowNormalTip("已成功导入热门配装")
        UIMgr.Close(self)
    end)
end

function UICustomizedSetRecommendView:RegEvent()
    Event.Reg(self, EventType.OnEquipCodeRsp, function (szKey, tInfo)
        if szKey == "LOGIN_ACCOUNT_EQUIPCODE" then
            if EquipCodeData.szSessionID then
                self.bLoginWeb = true
                local dwBelongSchoolID = Table_ForceToSchool(EquipCodeData.dwCurForceID)
                local szSchoolName = Table_GetSkillSchoolName(dwBelongSchoolID, true)
                EquipCodeData.ReqGetRecommendEquipList(nil, szSchoolName, EquipCodeData.dwCurKungfuID, self.nCurTag, 30)
                self:UpdateInfo()
            else
                TipsHelper.ShowNormalTip("连接云端服务器失败，请稍候重试")
                UIMgr.Close(self)
            end
        elseif szKey == "EQUIPS_LIST" then
            if tInfo and tInfo.code and tInfo.code == 1 then
                self:UpdateInfo()
            end
        end
    end)

    Event.Reg(self, EventType.OnSelectCustomizedSetRecommendCell, function (nIndex, tbData)
        self.nCurIndex = nIndex
        -- self:UpdateEquipListInfo()
        self:UpdateEquipAttrInfo()
    end)
end

function UICustomizedSetRecommendView:UpdateInfo()
    self:UpdateSetListInfo()
    -- self:UpdateEquipListInfo()
    self:UpdateEquipAttrInfo()
    self:UpdateTagsInfo()
end

function UICustomizedSetRecommendView:UpdateSetListInfo()
    UIHelper.HideAllChildren(self.ScrollViewExpertSetList)
    for _, shellCell in pairs(self.tbSetShellCells) do
        for _, widget in pairs(shellCell.tbWidgetShell) do
            UIHelper.SetVisible(widget, false)
        end
    end

    UIHelper.SetButtonState(self.BtnApply, BTN_STATE.Normal)
    if not EquipCodeData.tRecommendEquips or table.is_empty(EquipCodeData.tRecommendEquips) then
        UIHelper.SetVisible(self.WidgetTipsEmpty, true)
        UIHelper.SetButtonState(self.BtnApply, BTN_STATE.Disable)
    else
        UIHelper.SetVisible(self.WidgetTipsEmpty, false)
        self.tbSetShellCells = self.tbSetShellCells or {}
        self.tbSetCells = self.tbSetCells or {}

        for i, tbSetData in ipairs(EquipCodeData.tRecommendEquips) do
            if not self.tbSetCells[i] then
                self.tbSetCells[i] = UIHelper.AddPrefab(PREFAB_ID.WidgetExpertRecSetItemCellNew, self.ScrollViewExpertSetList)
                UIHelper.ToggleGroupAddToggle(self.TogGroupSetCell, self.tbSetCells[i].TogCell)
            end

            UIHelper.SetVisible(self.tbSetCells[i]._rootNode, true)
            self.tbSetCells[i]:OnEnter(i, tbSetData)
        end
    end

    UIHelper.ScrollViewDoLayoutAndToTop(self.ScrollViewExpertSetList)
end

function UICustomizedSetRecommendView:UpdateEquipListInfo()
    UIHelper.HideAllChildren(self.ScrollViewEquipList)

    self.tbEquipCells = self.tbEquipCells or {}
    if EquipCodeData.tRecommendEquips and EquipCodeData.tRecommendEquips[self.nCurIndex] then
        local tbSetData = EquipCodeData.tRecommendEquips[self.nCurIndex]
        if not string.is_nil(tbSetData.equips) then
            local tbEquipData, szErrMsg = JsonDecode(tbSetData.equips)
            for i, tbInfo in pairs(tbEquipData.Equips) do
                local nIndex = tonumber(i)
                local nPosType = tonumber(tbInfo.UcPos)
                local nTabID = tonumber(tbInfo.ID)

                local nStrengthLevel = tonumber(tbInfo.StrengthLevel) or 0
                local nMaxStrengthLevel = tonumber(tbInfo.MaxStrengthLevel) or 0

                if not self.tbEquipCells[nIndex] then
                    self.tbEquipCells[nIndex] = UIHelper.AddPrefab(PREFAB_ID.WidgetEquipCompareItemCell, self.ScrollViewEquipList)
                end

                UIHelper.SetVisible(self.tbEquipCells[nIndex]._rootNode, true)

                local itemInfo = ItemData.GetItemInfo(EquipType2ItemType[nPosType], nTabID)
                local tbRecommendEquipInfo = Table_GetRecommendEquipInfo(EquipType2ItemType[nPosType], nTabID)
                if tbRecommendEquipInfo then
                    self.tbEquipCells[nIndex]:OnInit({
                        item = itemInfo,
                        tbConfig = tbRecommendEquipInfo.tbConfig,
                        dwTabType = tbRecommendEquipInfo.tbConfig.dwTabType,
                        dwIndex = tbRecommendEquipInfo.tbConfig.dwIndex,
                        nStrengthLevel = nStrengthLevel,
                    }, false)
                else
                    self.tbEquipCells[nIndex]:OnInit({
                        item = itemInfo,
                        dwTabType = EquipType2ItemType[nPosType],
                        dwIndex = nTabID,
                        nStrengthLevel = nStrengthLevel,
                    }, false)
                end

                self.tbEquipCells[nIndex]:HideRecommend()
                self.tbEquipCells[nIndex]:HideStarEffect()
                -- WidgetEquipCompareItemCell
            end
        end
    end

    UIHelper.ScrollViewDoLayoutAndToTop(self.ScrollViewEquipList)
end

function UICustomizedSetRecommendView:UpdateEquipAttrInfo()
    self.scriptEquipAttributePage = self.scriptEquipAttributePage or UIHelper.GetBindScript(self.WidgetAnchorAttri)

    if EquipCodeData.tRecommendEquips and EquipCodeData.tRecommendEquips[self.nCurIndex] then
        local tbSetData = EquipCodeData.tRecommendEquips[self.nCurIndex]
        if tbSetData and not string.is_nil(tbSetData.equips) then
            local dwKungfuID = tonumber(tbSetData.kungfu_id)
            local szKungFu = PlayerKungfuName[dwKungfuID]

            local bPVE = true
            local tbEquipData, szErrMsg = JsonDecode(tbSetData.equips)

            if not string.is_nil(tbSetData.tags) and string.find(tbSetData.tags, "PVP", 1, true) then
                bPVE = false
            end

            local tShowAttr = CalculateKungfuPanel(szKungFu, Lib.copyTab(tbEquipData), bPVE)
            local nTotalScore = CalculateTotalEquipsScore(szKungFu, Lib.copyTab(tbEquipData))
            self.scriptEquipAttributePage:OnEnter(tShowAttr, nTotalScore)
        end
    else
        self.scriptEquipAttributePage:OnEnter({}, 0)
    end
end

function UICustomizedSetRecommendView:UpdateTagsInfo()
    local nPosType = PlayerKungfuPosition[EquipCodeData.dwCurKungfuID] or KUNGFU_POSITION.DPS
    local tbTags = PlayerKungfuPosition2EquipTags[nPosType]

    for i = 1, 2, 1 do
        local tbTag = tbTags[i]
        if i == 1 then
            self.tbCell1 = self.tbCell1 or {}
            for j, szName in ipairs(tbTag) do
                if not self.tbCell1[j] then
                    self.tbCell1[j] = UIHelper.AddPrefab(PREFAB_ID.WidgetExpertFilterTagCell, self.LayoutFilterSection01)
                    UIHelper.ToggleGroupAddToggle(self.TogGroupTag1, self.tbCell1[j].TogCell)
                end
                self.tbCell1[j]:OnEnter(szName, true, function ()
                    local szNewTags = self:GetCurTagsString()
                    self:SetCurTagsString(szNewTags)
                end)
                UIHelper.SetVisible(self.tbCell1[j]._rootNode, true)
            end
            UIHelper.SetVisible(self.WidgetSection01, #tbTag > 0)
            UIHelper.SetVisible(self.ImgLine, #tbTag > 0)
        elseif i == 2 then
            self.tbCell2 = self.tbCell2 or {}
            for j, szName in ipairs(tbTag) do
                if not self.tbCell2[j] then
                    self.tbCell2[j] = UIHelper.AddPrefab(PREFAB_ID.WidgetExpertFilterTagCell, self.LayoutFilterSection02)
                end
                self.tbCell2[j]:OnEnter(szName, false, function ()
                    local szNewTags = self:GetCurTagsString()
                    self:SetCurTagsString(szNewTags)
                end)
                UIHelper.SetVisible(self.tbCell2[j]._rootNode, true)
            end
            UIHelper.SetVisible(self.WidgetSection02, #tbTag > 0)
        end
    end

    UIHelper.LayoutDoLayout(self.LayoutFilterSection01)
    UIHelper.LayoutDoLayout(self.LayoutFilterSection02)
    UIHelper.LayoutDoLayout(self.LayoutContent)

    if not self.nCurTag then
        self:SetCurTagsString(tbTags["Default"])
    end
end

function UICustomizedSetRecommendView:GetCurTagsString()
    local nPosType = PlayerKungfuPosition[EquipCodeData.dwCurKungfuID] or KUNGFU_POSITION.DPS
    local tbTags = PlayerKungfuPosition2EquipTags[nPosType]

    local szTag = ""
    for i = 1, 2, 1 do
        local tbTag = tbTags[i]
        if i == 1 then
            self.tbCell1 = self.tbCell1 or {}
            for j, szName in ipairs(tbTag) do
                if self.tbCell1[j] then
                    local bSelected = UIHelper.GetSelected(self.tbCell1[j].TogCell)
                    if bSelected then
                        szTag = szName
                        break
                    end
                end
            end
        elseif i == 2 then
            self.tbCell2 = self.tbCell2 or {}
            for j, szName in ipairs(tbTag) do
                if self.tbCell2[j] then
                    local bSelected = UIHelper.GetSelected(self.tbCell2[j].TogCell)
                    if bSelected then
                        if szTag ~= "" then
                            szTag = szTag .. "," .. szName
                        else
                            szTag = szName
                        end
                    end
                end
            end
        end
    end

    return szTag
end

function UICustomizedSetRecommendView:SetCurTagsString(szTags)
    if szTags == self.nCurTag then
        return
    end

    self.nCurTag = szTags
    if self.bLoginWeb then
        local dwBelongSchoolID = Table_ForceToSchool(EquipCodeData.dwCurForceID)
        local szSchoolName = Table_GetSkillSchoolName(dwBelongSchoolID, true)
        EquipCodeData.ReqGetRecommendEquipList(nil, szSchoolName, EquipCodeData.dwCurKungfuID, self.nCurTag, MAX_ITEM_COUNT)
    end

    local tbCurTags = string.split(self.nCurTag, ",")

    local nPosType = PlayerKungfuPosition[EquipCodeData.dwCurKungfuID] or KUNGFU_POSITION.DPS
    local tbTags = PlayerKungfuPosition2EquipTags[nPosType]

    for i = 1, 2, 1 do
        local tbTag = tbTags[i]
        if i == 1 then
            self.tbCell1 = self.tbCell1 or {}
            local nSelectedIndex = -1
            for j, szName in ipairs(tbTag) do
                if table.contain_value(tbCurTags, szName) then
                    nSelectedIndex = j - 1
                    break
                end
            end
            if nSelectedIndex ~= -1 then
                UIHelper.SetToggleGroupSelected(self.TogGroupTag1, nSelectedIndex)
            end
        elseif i == 2 then
            self.tbCell2 = self.tbCell2 or {}
            for j, szName in ipairs(tbTag) do
                if table.contain_value(tbCurTags, szName) then
                    if self.tbCell2[j] then
                        UIHelper.SetSelected(self.tbCell2[j].TogCell, true)
                    end
                end
            end
        end
    end
end


return UICustomizedSetRecommendView