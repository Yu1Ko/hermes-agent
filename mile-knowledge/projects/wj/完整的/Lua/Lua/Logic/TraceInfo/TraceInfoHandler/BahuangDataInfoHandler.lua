local _M = {className = "BahuangDataInfoHandler"}
local self = _M

local tbInfoFunc = {
    ["nSceneLevel"] = function(scrollViewParent) 
        self.UpdateSceneLevel(scrollViewParent) 
        self.UpdateKillTip(scrollViewParent)
    end,
    ["nKillCount"] = function(scrollViewParent) self.UpdateKillCount(scrollViewParent) end,
    ["nLastLife"] = function(scrollViewParent) 
        self.UpdateLastLife(scrollViewParent) 
        self.UpdateKillTip(scrollViewParent)
        self.UpdateKillCount(scrollViewParent)
    end,
    ["nLastTime"] = function(scrollViewParent) self.UpdateLastTime(scrollViewParent) end,
    ["nKillBossNum"] = function(scrollViewParent) self.UpdateKillBossNum(scrollViewParent) end,
    ["szKillTip"] = function(scrollViewParent) self.UpdateKillTip(scrollViewParent) end,
}

--八荒
_M.szInfoType = TraceInfoType.BahuangDataInfo

function _M.Init()
    self.cellTaskTeamPool = PrefabPool.New(PREFAB_ID.WidgetTaskTeamSubtitle, 1)
    self.cellDescPool = PrefabPool.New(PREFAB_ID.WidgetRichTextOtherDescribe)
    self.RegEvent()
end

function _M.UnInit()
    Event.UnRegAll(self)
    Timer.DelAllTimer(self)

    if self.cellDescPool then self.cellDescPool:Dispose() end
    self.cellDescPool = nil
end

function _M.RegEvent()
    Event.Reg(self, EventType.OnUpdateBattleInfoList, function(szInfoType)
        if not self.tbBattleInfoList then self.tbBattleInfoList = {} end
        self.bNewInfo = self.tbBattleInfoList[szInfoType] == nil
        self.szInfoType = szInfoType
        self.tbBattleInfoList[szInfoType] = BahuangData.GetBattleInfoByType(szInfoType)

        TraceInfoData.UpdateInfo(TraceInfoType.BahuangDataInfo)
        Event.Dispatch(EventType.OnTogTraceInfo, TraceInfoType.BahuangDataInfo, true)

    end)

    Event.Reg(self, EventType.OnClearBattleInfo, function()
        self.tbBattleInfoList = {}
        Event.Dispatch(EventType.OnTogTraceInfo, TraceInfoType.BahuangDataInfo, false)
    end)

    Event.Reg(self, "PARTY_UPDATE_BASE_INFO", function (_, nMemberID, _, nGroupIndex)--加入队伍
        if BahuangData.IsInBaHuangMap() and arg4 then
            self.bNewInfo = false
            self.szInfoType = "szKillTip"
            TraceInfoData.UpdateInfo(TraceInfoType.BahuangDataInfo)
		end
    end)

    Event.Reg(self, "PARTY_DELETE_MEMBER", function (dwTeamID, nMemberID, nGroupIndex)--退出队伍
        if BahuangData.IsInBaHuangMap() and g_pClientPlayer and nMemberID == g_pClientPlayer.dwID then
            self.bNewInfo = false
            self.szInfoType = "szKillTip"
            TraceInfoData.UpdateInfo(TraceInfoType.BahuangDataInfo)
        end
    end)

    Event.Reg(self, "PARTY_DISBAND", function()--退出队伍
        if BahuangData.IsInBaHuangMap() then
            self.bNewInfo = false
            self.szInfoType = "szKillTip"
            TraceInfoData.UpdateInfo(TraceInfoType.BahuangDataInfo)
        end
    end)



end

function _M.OnUpdateView(script, scrollViewParent, tbInfo)
    if not self.tbScriptView or self.bNewInfo then
        self.UpdateBattleList(scrollViewParent)--出现新的类型，更新全部ui（因为要保证顺序一致）
    else
        tbInfoFunc[self.szInfoType](scrollViewParent)
    end
end

function _M.OnClear(script)

end

function _M.UpdateBattleList(scrollViewParent)

    self.RemovePQInfo()

    local nLevel = self.tbBattleInfoList["nSceneLevel"]
    if nLevel then
        local szSceneLevel = g_tStrings.tRougeLikeLevel[nLevel]
        local node, scriptView = self.cellTaskTeamPool:Allocate(scrollViewParent, szSceneLevel)
        scriptView:SetFontSize(26)
        scriptView:SetBtnHintVis(true)
        scriptView:SetClickCallBack(function()
            TeachBoxData.OpenTutorialPanel(63, 64, 65)
        end)
        UIHelper.LayoutDoLayout(node)
        self.AddNodeInfo(node, self.cellTaskTeamPool, scriptView, "nSceneLevel")
    end

    local nLastLife = self.tbBattleInfoList["nLastLife"]
    local nKillCount = self.tbBattleInfoList["nKillCount"]
    if nKillCount then
        local szKillCount = g_tStrings.STR_ROUGE_KILL_COUNT..tostring(nKillCount)
        if nKillCount >= 4000 and ((nLevel <= 8) or (nLevel == 9 and not TeamData.IsInParty())) and nLastLife == 3 then
            szKillCount = szKillCount .. "(可解锁下一关)"
        end
        local node, scriptView = self.cellDescPool:Allocate(scrollViewParent, szKillCount, nil, 26)
        self.AddNodeInfo(node, self.cellDescPool, scriptView, "nKillCount")
        UIHelper.SetVisible(node, true)
    end

    if nLastLife then
        local szLastLife = FormatString(g_tStrings.STR_ROUGE_REVIVE_LEFT_COUNT, nLastLife)
        local node, scriptView = self.cellDescPool:Allocate(scrollViewParent, szLastLife, nil, 26)
        self.AddNodeInfo(node, self.cellDescPool, scriptView, "nLastLife")
        UIHelper.SetVisible(node, true)
    end


    local nLastTime = self.tbBattleInfoList["nLastTime"]
    if nLastTime then
        local node, scriptView = self.cellDescPool:Allocate(scrollViewParent, g_tStrings.STR_ROUGE_LIGHT_TIME, nLastTime, 26)
        self.AddNodeInfo(node, self.cellDescPool, scriptView, "nLastTime")
        UIHelper.SetVisible(node, true)
    end


    local nKillBossNum = self.tbBattleInfoList["nKillBossNum"]
    if nKillBossNum then
        local szKillBossNum = g_tStrings.STR_KILL_BOSS_COUNT..tostring(nKillBossNum)
        local node, scriptView = self.cellDescPool:Allocate(scrollViewParent, szKillBossNum, nil, 26)
        self.AddNodeInfo(node, self.cellDescPool, scriptView, "nKillBossNum")
        UIHelper.SetVisible(node, true)
    end

    local node, scriptView = self.cellDescPool:Allocate(scrollViewParent, g_tStrings.STR_KILL_NUM_TIP, nil, 26)
    self.AddNodeInfo(node, self.cellDescPool, scriptView, "szKillTip")

    self.UpdateKillTip(scrollViewParent)

end


function _M.UpdateSceneLevel(scrollViewParent)
    local scriptView = self.tbScriptView["nSceneLevel"].script
    local nLevel = self.tbBattleInfoList["nSceneLevel"]
    if nLevel then
        local szSceneLevel = g_tStrings.tRougeLikeLevel[nLevel]
        scriptView:OnEnter(szSceneLevel)
        UIHelper.SetVisible(scriptView._rootNode, true)
    end
end

function _M.UpdateKillCount(scrollViewParent)
    local scriptView = self.tbScriptView["nKillCount"].script
    local nKillCount = self.tbBattleInfoList["nKillCount"]
    local nLevel = self.tbBattleInfoList["nSceneLevel"]
    local nLastLife = self.tbBattleInfoList["nLastLife"]
    if nKillCount then
        local szKillCount = g_tStrings.STR_ROUGE_KILL_COUNT..tostring(nKillCount)
        if nKillCount >= 4000 and ((nLevel <= 8) or (nLevel == 9 and not TeamData.IsInParty())) and nLastLife == 3 then
            szKillCount = szKillCount .. "(可解锁下一关)"
        end
        scriptView:OnEnter(szKillCount, nil, 26)
        UIHelper.SetVisible(scriptView._rootNode, true)
    end
end


function _M.UpdateLastLife(scrollViewParent)
    local scriptView = self.tbScriptView["nLastLife"].script
    local nLastLife = self.tbBattleInfoList["nLastLife"]
    if nLastLife then
        local szLastLife = FormatString(g_tStrings.STR_ROUGE_REVIVE_LEFT_COUNT, nLastLife)
        scriptView:OnEnter(szLastLife, nil, 26)
        UIHelper.SetVisible(scriptView._rootNode, true)
    end
end

function _M.UpdateLastTime(scrollViewParent)
    local scriptView = self.tbScriptView["nLastTime"].script
    local nLastTime = self.tbBattleInfoList["nLastTime"]
    if nLastTime then
        scriptView:OnEnter(g_tStrings.STR_ROUGE_LIGHT_TIME, nLastTime, 26)
        UIHelper.SetVisible(scriptView._rootNode, true)
    end
end

function _M.UpdateKillBossNum(scrollViewParent)
    local scriptView = self.tbScriptView["nKillBossNum"].script
    local nKillBossNum = self.tbBattleInfoList["nKillBossNum"]
    if nKillBossNum then
        local szKillBossNum = g_tStrings.STR_KILL_BOSS_COUNT..tostring(nKillBossNum)
        scriptView:OnEnter(szKillBossNum, nil, 26)
        UIHelper.SetVisible(scriptView._rootNode, true)
    end
end

function _M.AddNodeInfo(node, pool, scriptView, szInfoType)
    self.tbScriptView[szInfoType] = {node = node, pool = pool, script = scriptView}
end

function _M.RemovePQInfo()
    for nType, tbInfo in pairs(self.tbScriptView or {}) do
        tbInfo.pool:Recycle(tbInfo.node)
    end
    self.tbScriptView = {}
end


function _M.UpdateKillTip(scrollViewParent)
    local nLevel = self.tbBattleInfoList["nSceneLevel"]
    local nLastLife = self.tbBattleInfoList["nLastLife"]
    if not nLevel or not nLastLife then return end
    local tbInfo = self.tbScriptView["szKillTip"]
    if tbInfo then
        UIHelper.SetVisible(tbInfo.node, (not (nLevel == 10 or (nLevel == 9 and TeamData.IsInParty()))) and nLastLife ==3)
    end
    UIHelper.ScrollViewDoLayoutAndToTop(scrollViewParent)
end

return _M