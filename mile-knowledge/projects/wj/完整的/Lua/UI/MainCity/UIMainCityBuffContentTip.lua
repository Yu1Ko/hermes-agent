local UIMainCityBuffContentTip = class("UIMainCityBuffContentTip")

local MAX_BUFF_COUNT = 3

function UIMainCityBuffContentTip:OnEnter(nPlayerID)
    self.bBuffCountChanged = true -- Buff数量发生变化了
    self.bIsRemoving = false

    self.tbDeletedBuffMap = {}
    self.tbExpiredBuffMap = {}

    Event.Reg(self, EventType.OnClientPlayerLeave, function()
        UIHelper.SetVisible(self._rootNode, false)
    end)

    Event.Reg(self, "PLAYER_REMOVE_BUFF", function(buff)
        if not buff then return end
        self:AddDeletedBuff(buff.dwID, buff.nLevel, buff.nIndex)
    end)

    Event.Reg(self, "UPDATE_EXPIRED_BUFF", function(buff)
        if not buff then return end
        self:AddExpiredBuff(buff.dwID, buff.nLevel, buff.nIndex)
    end)

    Event.Reg(self, "MAIN_CITY_BUFF_TIP_NEED_LAYOUT", function()
        self:UpdateScrollViewLayout()
    end)
end

function UIMainCityBuffContentTip:UpdatePlayerInfo(nPlayerID, tbBuff, bNeedRefresh, bNeedUpdateBuffTips)
    self.nPlayerID = nPlayerID
    self.tbBuff = tbBuff
    self.bNeedRefresh = bNeedRefresh
    self.bNeedUpdateBuffTips = bNeedUpdateBuffTips
    self:UpdateInfo()
end

function UIMainCityBuffContentTip:UpdateNpcInfo(nNpcID, tbBuff, bNeedRefresh)
    self.nNpcID = nNpcID
    self.tbBuff = tbBuff
    self.bNeedRefresh = bNeedRefresh
    self:UpdateInfo()
end

function UIMainCityBuffContentTip:UpdateInfo()
    self.bPlayer = false
    local PrefabComponent = require("Lua/UI/Map/Component/UIPrefabComponent")
    self.ScrollViewBuffMore:setTouchDownHideTips(false)
    self.tbMoreScripts = PrefabComponent:CreateInstance()
    self.tbMoreScripts:Init(self.LayoutBuffMore, PREFAB_ID.WidgetMainCityBuffCell)
    self:Update()
    self.nUpdateTimer = Timer.AddCycle(self, 0.1, function()
        self:Update()
    end)

    UIHelper.ScrollToTop(self.ScrollViewBuffMore, 0, false)
end

function UIMainCityBuffContentTip:OnExit()

end

function UIMainCityBuffContentTip:Update(nPlayerID)
    local character = self:GetCharacter()
    if not character then
        return
    end

    local funcIsExist = function(buff)
        local bIsExist, nIdx = false, 0

        if buff then
            for k, v in ipairs(self.tbBuff) do
                if buff.dwID == v.dwID and buff.nLevel == v.nLevel and buff.nIndex == v.nIndex then
                    bIsExist = true
                    nIdx = k
                    break
                end
            end
        end

        return bIsExist, nIdx
    end

    local nOldLen = #self.tbBuff
    local tBuff = self.tbBuff
    if self.bNeedRefresh then
        --tBuff = BuffMgr.GetVisibleBuff(character, true)
        --tBuff = BuffMgr.GetSortedBuff(character, true)

        self.tbNowBuffMap = {}
        local tbNowBuff = BuffMgr.GetSortedBuff(character, true, true)
        if TreasureBattleFieldSkillData.InSkillMap() then
            local tSkillBuffs = TreasureBattleFieldSkillData.GetSkillBuffList(character)
            table.insert_tab(tbNowBuff, tSkillBuffs)
        end
        for i, v in ipairs(tbNowBuff) do
            local dwID = v.dwID
            local nLevel = v.nLevel
            local bIsExist, nIdx = funcIsExist(v)
            local nIndex = v.nIndex
            if bIsExist then
                tBuff[nIdx] = v
                self:RemoveDeletedBuff(dwID, nLevel, nIndex)
                self:RemoveExpiredBuff(dwID, nLevel, nIndex)
            else
                table.insert(tBuff, 1, v)
            end

            if not self.tbNowBuffMap[dwID] then
                self.tbNowBuffMap[dwID] = {}
            end
            if not self.tbNowBuffMap[dwID][nLevel] then
                self.tbNowBuffMap[dwID][nLevel] = {}
            end
            self.tbNowBuffMap[dwID][nLevel][nIndex] = true
        end
    end

    local nCount = #tBuff
    if nOldLen ~= nCount then
        self.tbBuff = tBuff
        self.bBuffCountChanged = true

        self.bNeedToTop = true
    end

    -- 这里把 nCatalog 为0的放在最前面显示
    local tSortedBuff = self:SortBuffList(tBuff)
    self:UpdateMoreLayout(tSortedBuff, nCount)

    self.bBuffCountChanged = false
    if nCount == 0 then
        TipsHelper.DeleteHoverTips(PREFAB_ID.WidgetMainCityBuffContentTip)
    end
end

function UIMainCityBuffContentTip:SortBuffList(tBuff)
    local tbResult = {}
    local tbHeadBuffs = {}
    local tbTailBuffs = {}
    for k, v in ipairs(tBuff) do
        local tbBuffConf = Table_GetBuff(v.dwID, v.nLevel)
        local nMbUIListPriority = BuffMgr.GetMBUIListPriority(v.dwID, v.nLevel)
        if nMbUIListPriority > 0 then
            table.insert(tbHeadBuffs, v)
        else
            table.insert(tbTailBuffs, v)
        end
    end

    -- 按照nMbUIListPriority排序
    table.sort(tbHeadBuffs, function(a, b)
        local priorityA = BuffMgr.GetMBUIListPriority(a.dwID, a.nLevel) or 0
        local priorityB = BuffMgr.GetMBUIListPriority(b.dwID, b.nLevel) or 0
        if priorityA ~= priorityB then
            return priorityA > priorityB
        end
    end)

    table.insert_tab(tbResult, tbHeadBuffs)
    table.insert_tab(tbResult, tbTailBuffs)

    return tbResult
end

function UIMainCityBuffContentTip:GetCharacter()
    if self.nPlayerID then
        if g_pClientPlayer and self.nPlayerID  == g_pClientPlayer.dwID then
            self.bPlayer = true
        end
        return GetPlayer(self.nPlayerID)
    elseif self.nNpcID then
        return GetNpc(self.nNpcID)
    end
    return nil
end

function UIMainCityBuffContentTip:UpdateMoreLayout(tBuff, nCount)
    UIHelper.SetActiveAndCache(self, self.WidgetBuffLess, false)
    UIHelper.SetActiveAndCache(self, self.WidgetBuffMore, true)

    self.nLastPercent = UIHelper.GetScrollPercent(self.ScrollViewBuffMore)
    for i, v in ipairs(tBuff) do
        local script = self.tbMoreScripts:Alloc(i)
        local bShowTime = Table_BuffNeedShowTime(v.dwID, v.nLevel) or v.bShowTime
        local nIndex = v.nIndex or 0
        local bDeleted = self:IsDeletedBuff(v.dwID, v.nLevel, nIndex)
        local bExpired = v.bExpired
        if bExpired == nil then
            bExpired = v.nEndFrame and (self:IsExpiredBuff(v.dwID, v.nLevel, nIndex) or (not self:IsInNowBuffMap(v.dwID, v.nLevel, nIndex))) or false
        end
        script:UpdateInfo(v, bShowTime, i == #tBuff, self.bPlayer, bDeleted, bExpired, self.bNeedUpdateBuffTips)

        if self.bBuffCountChanged then
            UIHelper.LayoutDoLayout(script._rootNode)
        end
    end

    local bShow = self:ShowMatrixData(nCount)
    if bShow then
        self.tbMoreScripts:Clear(nCount + 2)
    else
        self.tbMoreScripts:Clear(nCount + 1)
    end

    if self.bBuffCountChanged then
        --UIHelper.CascadeDoLayoutDoWidget(self.ScrollViewBuffMore:getInnerContainer(), true, true)
        --UIHelper.CascadeDoLayoutDoWidget(self.WidgetMainCityBuffContentTip, true, true)
        self:UpdateScrollViewLayout()
    end
end

function UIMainCityBuffContentTip:ShowMatrixData(nCount)
    local bShow, bChange
    if self.bPlayer then
        bShow, bChange = MatrixData.GetShowState()
        if bShow then
            local script = self.tbMoreScripts:Alloc(nCount + 1)
            script:UpdateMatrix()
        end
        if nCount > 0 then
            local lastScript = self.tbMoreScripts:Alloc(nCount)
            lastScript:ShowImgLine(bShow)
        end
    end
    return bShow, bChange
end

function UIMainCityBuffContentTip:CheckScrollViewNeedToTop()
    if self.nLastPercent == 0 then
        UIHelper.ScrollToTop(self.ScrollViewBuffMore, 0, false)
    end

    -- if not self.bNeedToTop then
    --     return
    -- end
    -- self.bNeedToTop = false

    -- --自然过期的buff需要下次update()才会删除，所以加个延迟
    -- if self.bDelayToTop then
    --     self.bDelayToTop = false
    --     self.nDelayTimerID = self.nDelayTimerID or Timer.Add(self, 0.11, function ()
    --             -- UIHelper.ScrollToTop(self.ScrollViewBuffMore, 0, false)
    --             -- buff自然过期后保留玩家原先的滑动进度，把旧的buff顶上去
    --             local nPercent = UIHelper.GetScrollPercent(self.ScrollViewBuffMore)
    --             UIHelper.ScrollToPercent(self.ScrollViewBuffMore, nPercent)
    --             self.nDelayTimerID = nil
    --         end)
    --     return
    -- end
    -- UIHelper.ScrollToTop(self.ScrollViewBuffMore, 0, false)
end

function UIMainCityBuffContentTip:AddDeletedBuff(dwID, nLevel, nIndex)
    if not dwID or not nLevel or not nIndex then
        return
    end

    if not self.tbDeletedBuffMap[dwID] then
        self.tbDeletedBuffMap[dwID] = {}
    end

    if not self.tbDeletedBuffMap[dwID][nLevel] then
        self.tbDeletedBuffMap[dwID][nLevel] = {}
    end

    self.tbDeletedBuffMap[dwID][nLevel][nIndex] = true
end

function UIMainCityBuffContentTip:RemoveDeletedBuff(dwID, nLevel, nIndex)
    if not dwID or not nLevel or not nIndex then
        return
    end

    if not self.tbDeletedBuffMap[dwID] then
        return
    end

    if not self.tbDeletedBuffMap[dwID][nLevel] then
        return
    end

    self.tbDeletedBuffMap[dwID][nLevel][nIndex] = nil
end

function UIMainCityBuffContentTip:IsDeletedBuff(dwID, nLevel, nIndex)
    if not dwID or not nLevel or not nIndex then
        return
    end

    if not self.tbDeletedBuffMap[dwID] then
        return
    end

    if not self.tbDeletedBuffMap[dwID][nLevel] then
        return
    end

    return self.tbDeletedBuffMap[dwID][nLevel][nIndex]
end

function UIMainCityBuffContentTip:AddExpiredBuff(dwID, nLevel, nIndex)
    if not dwID or not nLevel or not nIndex then
        return
    end

    if not self.tbExpiredBuffMap[dwID] then
        self.tbExpiredBuffMap[dwID] = {}
    end

    if not self.tbExpiredBuffMap[dwID][nLevel] then
        self.tbExpiredBuffMap[dwID][nLevel] = {}
    end

    self.tbExpiredBuffMap[dwID][nLevel][nIndex] = true
end

function UIMainCityBuffContentTip:RemoveExpiredBuff(dwID, nLevel, nIndex)
    if not dwID or not nLevel or not nIndex then
        return
    end

    if not self.tbExpiredBuffMap[dwID] then
        return
    end

    if not self.tbExpiredBuffMap[dwID][nLevel] then
        return
    end

    self.tbExpiredBuffMap[dwID][nLevel][nIndex] = nil
end

function UIMainCityBuffContentTip:IsExpiredBuff(dwID, nLevel, nIndex)
    if not dwID or not nLevel or not nIndex then
        return
    end

    if not self.tbExpiredBuffMap[dwID] then
        return
    end

    if not self.tbExpiredBuffMap[dwID][nLevel] then
        return
    end

    return self.tbExpiredBuffMap[dwID][nLevel][nIndex]
end

function UIMainCityBuffContentTip:IsInNowBuffMap(dwID, nLevel, nIndex)
    local bResult = false

    if dwID and nLevel and nIndex and self.tbNowBuffMap then
        if self.tbNowBuffMap[dwID] then
            if self.tbNowBuffMap[dwID][nLevel] then
                if self.tbNowBuffMap[dwID][nLevel][nIndex] then
                    bResult = true
                end
            end
        end
    end

    return bResult
end

function UIMainCityBuffContentTip:UpdateScrollViewLayout()
    UIHelper.ScrollViewDoLayout(self.ScrollViewBuffMore)

    local size = self.ScrollViewBuffMore:getInnerContainerSize()
    local nHeight = (size.height < 440) and size.height or 440
    UIHelper.SetHeight(self.ScrollViewBuffMore, nHeight)
    UIHelper.SetHeight(self.ImgTipBgMore, nHeight == 0 and nHeight or nHeight + 40)

    self:CheckScrollViewNeedToTop() --buff更新后的ScrollToTop在这里处理
end

return UIMainCityBuffContentTip