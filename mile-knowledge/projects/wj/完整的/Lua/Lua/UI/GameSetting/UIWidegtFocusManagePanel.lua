-- ---------------------------------------------------------------------------------
-- Author: Unknown
-- Name: UIWidegtFocusManagePanel
-- Date: 2024-5-11
-- Desc: ?
-- ---------------------------------------------------------------------------------
local sgsub, sformat, sfind = string.gsub, string.format, string.find
local tinsert = table.insert

---@class UIWidegtFocusManagePanel
local UIWidegtFocusManagePanel = class("UIWidegtFocusManagePanel")

function UIWidegtFocusManagePanel:OnEnter()
    if not self.bInit then
        self:RegEvent()
        self:BindUIEvent()
        self.bInit = true
        --self.parentScript = parentScript ---@type UIGameSettingView

        self.tScrollLists = { self.ScrollViewListPlayer, self.ScrollViewListID, self.ScrollViewListNPC }
    end

    self:UpdateInfo()
end

function UIWidegtFocusManagePanel:OnExit()
    self.bInit = false
    self:UnRegEvent()
end

function UIWidegtFocusManagePanel:BindUIEvent()
    UIHelper.BindUIEvent(self.BtnPlayerAdd, EventType.OnClick, function()
        self:AddBtnClick(1, self.ScrollViewListPlayer)
    end)
    UIHelper.BindUIEvent(self.BtnIDAdd, EventType.OnClick, function()
        self:AddBtnClick(2, self.ScrollViewListID)
    end)
    UIHelper.BindUIEvent(self.BtnNPCAdd, EventType.OnClick, function()
        self:AddBtnClick(3, self.ScrollViewListNPC)
    end)
end

function UIWidegtFocusManagePanel:RegEvent()

end

function UIWidegtFocusManagePanel:UnRegEvent()

end

function UIWidegtFocusManagePanel:UpdateInfo()
    if not Storage.FocusList._tFocusTargetData then
        return
    end

    local tParam = {
        [1] = {},
        [2] = {},
        [3] = {},
    }
    for szName, v in pairs(Storage.FocusList._tFocusTargetData) do
        if sfind(szName, 'NPC_') then
            local name = sgsub(szName, "NPC_", "")
            local _l = name
            if type(v) ~= 'boolean' then
                _l = { name, v }
            end
            tinsert(tParam[3], _l)
        elseif tonumber(szName) then
            local _l = szName
            if type(v) ~= 'boolean' then
                _l = { szName, v }
            end
            tinsert(tParam[2], _l)
        else
            local _l = szName
            if type(v) ~= 'boolean' then
                _l = { szName, v }
            end
            tinsert(tParam[1], _l)
        end
    end

    for nType = 1, 3 do
        local tScrollView = self.tScrollLists[nType]
        local tDataList = tParam[nType]

        local nOldCount = UIHelper.GetChildrenCount(tScrollView)
        local nOldPercent = UIHelper.GetScrollPercent(tScrollView)

        UIHelper.RemoveAllChildren(tScrollView)
        for nIndex, szName in ipairs(tDataList) do
            self:AddCell(szName, nType, tScrollView)
        end

        local nNewCount = #tParam[nType]
        local nPercent = nNewCount == 0 and 0 or math.min(100, nOldCount / nNewCount * nOldPercent)

        UIHelper.ScrollViewDoLayout(tScrollView)
        UIHelper.ScrollToPercent(tScrollView, nPercent)
    end
end

function UIWidegtFocusManagePanel:AddBtnClick(nType)
    local fnAdd = function(szText)
        if nType == 3 then
            Storage.FocusList._tFocusTargetData['NPC_' .. szText] = true
        else
            if tonumber(szText) then
                nType = 2
            else
                nType = 1
            end
            Storage.FocusList._tFocusTargetData[szText] = true
        end
        Storage.FocusList.Flush()

        local tar
        if nType == 1 then
            tar = JX.GetPlayerByName(szText)
        elseif nType == 2 then
            tar = GetPlayer(szText)
        elseif nType == 3 then
            tar = JX.GetNpcByName(szText)
        end
        if tar then
            _JX_TargetList.ChangeFocusTable(true, 1, tar.dwID)
        end
    end
    local tTips = {
        [1] = "请填写玩家名字",
        [2] = "请填写玩家ID",
        [3] = "请填写NPC名字",
    }

    local editBox = UIMgr.Open(VIEW_ID.PanelPromptPop, "", tTips[nType], function(szText)
        if szText == "" then
            TipsHelper.ShowNormalTip("内容不能为空")
            return
        end

        if TextFilterCheck(UIHelper.UTF8ToGBK(szText)) then
            if nType ~= 3 then
                if tonumber(szText) then
                    nType = 2
                else
                    nType = 1
                end
            end

            fnAdd(szText)
            self:UpdateInfo()
            --local tScrollView = self.tScrollLists[nType]
            --self:AddCell(szText, nType, tScrollView)
            --UIHelper.ScrollViewDoLayoutAndToTop(tScrollView)
        else
            TipsHelper.ShowNormalTip(g_tStrings.STR_BODY_RENAME_ERROR)
        end
    end)
    editBox:SetTitle("添加名字")
    editBox:SetMaxLength(10)
end

function UIWidegtFocusManagePanel:DelItemList(szText, nType, script, tScrollView)
    if not szText then
        return
    end
    if nType == 3 then
        Storage.FocusList._tFocusTargetData['NPC_' .. szText] = nil
    else
        Storage.FocusList._tFocusTargetData[szText] = nil
    end
    Storage.FocusList.Flush()
    local tar
    szText = UIHelper.UTF8ToGBK(szText)
    if nType == 1 then
        tar = JX.GetPlayerByName(szText)
    elseif nType == 2 then
        tar = GetPlayer(szText)
    elseif nType == 3 then
        tar = JX.GetNpcByName(szText)
    end
    if tar then
        _JX_TargetList.ChangeFocusTable(false, 1, tar.dwID)
    end

    --UIHelper.RemoveFromParent(script._rootNode, true)
    --UIHelper.ScrollViewDoLayout(tScrollView)
end

function UIWidegtFocusManagePanel:AddCell(szName, nType, tScrollView)
    local script = UIHelper.AddPrefab(PREFAB_ID.WidgetSettingPermanenAdd, tScrollView)
    local szProcessedName = UIHelper.LimitUtf8Len(szName, 6)
    UIHelper.SetString(script.LabelName, szProcessedName)
    UIHelper.BindUIEvent(script.BtnDelete, EventType.OnClick, function()
        self:DelItemList(szName, nType, script, tScrollView)
        self:UpdateInfo()
    end)
end

--function UIWidegtFocusManagePanel:RemoveCell(szName, nType, tScrollView)
--end


return UIWidegtFocusManagePanel