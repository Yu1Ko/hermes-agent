PVPFieldData = PVPFieldData or {className = "PVPFieldData"}
local self = PVPFieldData

local REFRESH_COUNT = 60 * 60

local _szOccupied = "成功夺得"
local _tMsg = {
    "%[(.-)%]服务器：%[(.-)%]大侠，率领%[(.-)%]阵营侠士们，成功夺得【盘碣关】，为本阵营获得【盘碣关】复活点！",
    "%[(.-)%]服务器：%[(.-)%]大侠，率领%[(.-)%]阵营侠士们，成功夺得【回雁关】，为本阵营获得【回雁关】复活点！",
    "%[(.-)%]服务器：%[(.-)%]大侠，率领%[(.-)%]阵营侠士们，成功夺得【赤焰关】，占领本服河西瀚漠【白沙龙墟】，为本阵营获得【蚀风遗迹】开采权！(.-)",
}

--千里伐逐
PVPFieldData.tQueueList = {}

function PVPFieldData.Init()
    self.RegEvent()
end

function PVPFieldData.UnInit()
    Event.UnRegAll(self)
    Timer.DelAllTimer(self)
end

function PVPFieldData.RegEvent()

    Event.Reg(self, EventType.OnGetChatMsg, function(szPlainText)
        self.SysMsgMonitor(szPlainText)
    end)

    Event.Reg(self, "ON_PVP_FIELD_QUEUE_INFO_NOTIFY", function(nInfoType, nPos, dwMapID, nCopyIndex)
        if nInfoType == PVP_FIELD_QUEUE_INFO_CODE.QUEUEING then
            self.OnQueuePosUpdate(nPos, dwMapID, nCopyIndex)
        elseif nInfoType == PVP_FIELD_QUEUE_INFO_CODE.JOIN_PVPFIELD_QUEUE then
            self.OnCanEnterServerMap(dwMapID, nCopyIndex)
        elseif nInfoType == PVP_FIELD_QUEUE_INFO_CODE.LEAVE_PVPFIELD_QUEUE then
            self.OnQueueEnd(dwMapID, nCopyIndex)
        end
    end)
    Event.Reg(self, "ON_PVP_FIELD_QUEUE_LEAVE_NOTIFY", function(nResultCode, dwMapID, nCopyIndex)
        if nResultCode == PVP_FIELD_RESULT_CODE.SUCCESS then
            self.OnQueueEnd(dwMapID, nCopyIndex)
        end
    end)
    Event.Reg(self, "SWITCH_SERVER_INIT_INFO", function(tServerInfo)
        self.InitCrossMsg(tServerInfo)
    end)

    Event.Reg(self, EventType.OnClientPlayerEnter, function()
        PVPFieldData.UpdatePVPButton()
    end)

    Event.Reg(self, "PLAYER_EXIT_GAME", function()
        self.tQueueList = {}
    end)
end

function PVPFieldData.IsInPVPField()
    local player = GetClientPlayer()
    if not player then
        return
    end

    local hPVP = GetPVPFieldClient()
    if not hPVP then
        return
    end

    local hScene = player.GetScene()
    if not hScene then
        return
    end

    if hPVP.IsPVPField(hScene.dwMapID, hScene.nCopyIndex) then
        return true
    end
end

function PVPFieldData.LeavePVPField()
    -- local hPlayer = GetClientPlayer()
    -- if not hPlayer then
    --     return
    -- end

    -- if hPlayer.bFightState then
    --     TipsHelper.ShowImportantRedTip(g_tStrings.STR_LEAVE_PVP_MSG_1)
    --     return
    -- end

    local szContent = FormatString(g_tStrings.STR_LEAVE_PVP_MSG, Table_GetSwitchServerMapName())
    UIHelper.ShowConfirm(szContent, function()
        -- local hPVP = GetPVPFieldClient()
        -- if not hPVP then
        --     return
        -- end
        RemoteCallToServer("On_CrossServer_LeavePVPField")
    end)
end

function PVPFieldData.OnQueuePosUpdate(nPos, dwMapID, nCopyIndex)
    local bNewQueueMap = false
    local bPosChanged = false
    local bExist = false
    for _, v in ipairs(self.tQueueList) do
        if v.mapid == dwMapID and v.copyindex == nCopyIndex then
            if nPos ~= v.rank then
                bPosChanged = true
            end
            v.queuetype = g_pClientPlayer.nCamp
            v.camp = g_pClientPlayer.nCamp
            v.rank = nPos
            bExist = true
            break
        end
    end
    if not bExist then
        bNewQueueMap = true
        table.insert(self.tQueueList, {
            mapid = dwMapID,
            copyindex = nCopyIndex,
            queuetype = g_pClientPlayer.nCamp,
            camp = g_pClientPlayer.nCamp,
            rank = nPos
        })
    end

    table.sort(self.tQueueList, function(l, r)
        if l.rank == r.rank then
           return l.mapid < r.mapid
        end
        return l.rank < r.rank
    end)

    if bNewQueueMap then
        if not UIMgr.IsViewOpened(VIEW_ID.PanelMapLineUpPop) then
            UIMgr.Open(VIEW_ID.PanelMapLineUpPop)
        end
    end
    if bNewQueueMap or bPosChanged then
        self.UpdateBubbleMsgData()
    end
end

function PVPFieldData.UpdateBubbleMsgData()
    if table_is_empty(self.tQueueList) then
        BubbleMsgData.RemoveMsg("PVPFieldMapQueueTips")
        Event.Dispatch(EventType.OnMapQueueDataUpdate)
        return
    end
    local mapid = self.tQueueList[1].mapid
    local rank = self.tQueueList[1].rank
    local camp = self.tQueueList[1].camp
    local szCamp = g_tStrings.STR_CAMP_TITLE[camp]

    -- local szContent = string.format("[%s]%s(%d)\n已排队：%d个场景", szCamp, UIHelper.GBKToUTF8(Table_GetMapName(mapid)), rank, #self.tQueueList)
    local szContent = string.format("已排队：%d个场景", #self.tQueueList)
    BubbleMsgData.PushMsgWithType("PVPFieldMapQueueTips",{
        szBarTitle = MapQueueData.GetBubbleBarTitle(), 			-- 显示在小地图旁边的气泡栏的短标题(若与szTitle一样, 可以不填)
        nBarTime = 0, 			-- 显示在气泡栏的时长, 单位为秒
        szContent = szContent, 		-- 显示在信息列表项中的内容
        nRank = rank,
        nQueueMapCount = #self.tQueueList,
        szAction = function ()
            UIMgr.Open(VIEW_ID.PanelMapLineUpPop)
        end,
    })
    Event.Dispatch(EventType.OnMapQueueDataUpdate)
end

function PVPFieldData.OnQueueEnd(dwMapID, nCopyIndex)
    for k, v in ipairs(self.tQueueList) do
        if v.mapid == dwMapID and v.copyindex == nCopyIndex then
            table.remove(self.tQueueList, k)
            break
        end
    end
    self.UpdateBubbleMsgData()
end

function PVPFieldData.OnCanEnterServerMap(dwMapID, nCopyIndex)
    if not Storage.MapQueue.bShowSureNotice then
        local hPVP = GetPVPFieldClient()
        if not hPVP then
            return
        end
        hPVP.ConfirmJoinPVPField(dwMapID, nCopyIndex, true)
        return
    end

    local szMapName     = Table_GetMapName(dwMapID) or ""
    local hPVP          = GetPVPFieldClient()
    local szServer      = hPVP.GetPVPFieldBindCenter(dwMapID, nCopyIndex)

    local szMessage = FormatString(g_tStrings.STR_SWITCHMAP_GFZ_TIP, UIHelper.GBKToUTF8(szServer .. "-" .. szMapName))
    UIHelper.ShowConfirm(szMessage, function()
        local hPVP = GetPVPFieldClient()
        if hPVP then
            hPVP.ConfirmJoinPVPField(dwMapID, nCopyIndex, true)
        end
    end, function()
        local hPVP = GetPVPFieldClient()
        if hPVP then
            hPVP.ConfirmJoinPVPField(dwMapID, nCopyIndex, false)
        end
    end)
end

function PVPFieldData.OnClearMapQueue()
    local hPVP = GetPVPFieldClient()
    if hPVP then
        for _, v in ipairs(self.tQueueList) do
            hPVP.LeavePVPFieldQueue(v.mapid, v.copyindex)
        end
    end
end

function PVPFieldData.UpdatePVPButton()
    if PVPFieldData.IsInPVPField() then
        BubbleMsgData.PushMsgWithType("PVPFieldMapButton", {
            nBarTime = 0, 							-- 显示在气泡栏的时长, 单位为秒
            szContent = g_tStrings.STR_PVP_MAP_BUBBLE_MGR,
            szAction = function ()
                UIMgr.Open(VIEW_ID.PanelQianLiFaZhu)
            end,
        })
	else
		BubbleMsgData.RemoveMsg("PVPFieldMapButton")
	end
end

function PVPFieldData.GetCrossMsg()
    return Storage.QianLiFaZhu.tbCrossData
end

-- 打开千里伐逐界面时，根据界面发的事件信息初始化或刷新一次数据
function PVPFieldData.InitCrossMsg(tServerInfo)
    local tCrossMsg = Storage.QianLiFaZhu.tbCrossData
    local nCurrentTime = GetCurrentTime()
    local tbCopyIndex = {}
    for k, v in ipairs(tServerInfo) do
        local szServer = UIHelper.GBKToUTF8(v.szBindCenter)
        if szServer then
            tCrossMsg[szServer]                 = tCrossMsg[szServer] or {}
            tCrossMsg[szServer].nCopyIndex      = v.nCopyIndex
            tCrossMsg[szServer].nOpenTime       = v.nOpenTime
            tCrossMsg[szServer].nCamp           = v.nCamp
            tCrossMsg[szServer].szServer        = szServer
            tCrossMsg[szServer].nPassTime       = v.nPassTime
            table.insert(tbCopyIndex, v.nCopyIndex)
            if not tCrossMsg[szServer]["nBossTime1"] then
                tCrossMsg[szServer].nBossTime1   = 0
                tCrossMsg[szServer].nBossTime2   = 0
                tCrossMsg[szServer].nBossTime3   = 0
                tCrossMsg[szServer].nCurrentBoss = 0
                tCrossMsg[szServer].nOccupyCamp  = 0
                tCrossMsg[szServer].nRefreshTime = nCurrentTime
            end

            for i = 1, 3 do
                --占领已经超过N分钟就清空占领信息
                if tCrossMsg[szServer]["nBossTime" .. i] and tCrossMsg[szServer]["nBossTime" .. i] ~= 0 and tCrossMsg[szServer]["nBossTime" .. i] < nCurrentTime - REFRESH_COUNT then
                    tCrossMsg[szServer]["nLastBossTime"..i] = tCrossMsg[szServer]["nBossTime"..i]
                    tCrossMsg[szServer]["nBossTime"..i] = 0
                    tCrossMsg[szServer].nCurrentBoss = 0
                    tCrossMsg[szServer].nOccupyCamp = 0
                    tCrossMsg[szServer].nRefreshTime = nCurrentTime
                end
            end
        end
    end

    for key, value in pairs(tCrossMsg) do
        if not table.contain_value(tbCopyIndex, value.nCopyIndex) then
            tCrossMsg[key] = nil
        end
    end

    Storage.QianLiFaZhu.Flush()
end

-- 监听关隘BOSS被击败消息
function PVPFieldData.SysMsgMonitor(szMsg, nFont, bRich, r, g, b, szType)
    if bRich then
        szMsg = UIHelper.GetPureText(szMsg)
    end
    if not szMsg or szMsg == "" then
        return
    end
    if not string.find(szMsg, _szOccupied) then
        return
    end
    local tCrossMsg = Storage.QianLiFaZhu.tbCrossData
    for k, v in ipairs(_tMsg) do
        local _, _, szServer, szPlayer, szCamp = string.find(szMsg, v)
        if szServer then
            tCrossMsg[szServer]                 = tCrossMsg[szServer] or {}
            tCrossMsg[szServer].nRefreshTime    = GetCurrentTime()
            tCrossMsg[szServer].nOccupyCamp     = self.GetCampEnum(szCamp)
            tCrossMsg[szServer].nCurrentBoss    = k
            tCrossMsg[szServer]["nBossTime"..k] = GetCurrentTime()
            if k == 3 then
                tCrossMsg[szServer].nCamp = tCrossMsg[szServer].nOccupyCamp
            end
            return
        end
    end
    Storage.QianLiFaZhu.Flush()
end


function PVPFieldData.GetCampEnum(szCamp)
    if szCamp == "浩气盟" or szCamp == "浩气" then
        return 1
    elseif szCamp == "恶人谷" or szCamp == "恶人" then
        return 2
    elseif szCamp == "中立" then
        return 0
    end
    return -1
end