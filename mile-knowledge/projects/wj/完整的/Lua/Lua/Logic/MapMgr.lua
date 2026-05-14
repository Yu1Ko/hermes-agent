MapMgr = MapMgr or {className = "MapMgr"}

local TRANSPORT_SKILL_ID = 81
local BLOCK_WIDTH = 128
local TEAM_MARK_SFX_ID = 1
local MAX_LIKE_MAP_COUNT = 5
local SEARCH_CRAFT_RADIUS = 60 * 64 --尺数*转换为米的值（最终为米数）
local MIN_DISTANCE_CHECKZVALUE = 1000 * 64 --检测z值得最小距离, 1000尺

--必须和MiddleMapCommandNpc.txt表的boss被攻击配置信息一致
local ID_OF_BOSS_BE_ATTACTED_TABLE_INFO = 21

local RESET_ITEM = {
    dwTabType = 5,
    dwIndex = 40385,
}

--小攻防
local tCastleMap = {
    [1] = {30, 23, 153, 103, 104, 139, 100 },   --浩气
    [2] = {22, 35, 101, 13, 21, 105, 9},    --恶人
}

--小攻防分线地图
local tBranchMap = {
    216, 656
}

-- 中地图NPC黑名单
local tbMiddleMapNpcBlackList =
{
    [352] = true,
    [51401] = true,
    [51501] = true,
    [59585] = true,
    [62758] = true,
    [105155] = true,
}


MapMgr.tShowMonsterAnger = {} --百战怒韧条
function MapMgr.IsInGFMapInGFTime(dwMapID)
    if not dwMapID then
        return false
    end

    --大攻防
    if (dwMapID == 25 or dwMapID == 27) and (IsActivityOn(706) or IsActivityOn(707)) then
        return true
    end

    --小攻防
    if (DectTableValue(tCastleMap[CAMP.GOOD], dwMapID) or DectTableValue(tCastleMap[CAMP.EVIL], dwMapID) or DectTableValue(tBranchMap, dwMapID)) and CampData.IsInCastleActivity() then
        return true
    end

    return false
end



function MapMgr.GetMapParams_UIEx(nMapID)
    local hHomeland = GetHomelandMgr()
    if not hHomeland then
        return GetMapParams(nMapID)
    end
    local bPrivateHome = hHomeland.IsPrivateHomeMap(nMapID)
    if not bPrivateHome then
        return GetMapParams(nMapID)
    end

    local tPrivateHomeInfo = hHomeland.GetCurPrivateHomeInfo()
    if not tPrivateHomeInfo then
        return GetMapParams(nMapID)
    end

    local uMapSkinID = hHomeland.GetMapSkinID(nMapID, tPrivateHomeInfo.dwSkinID)
    if tPrivateHomeInfo.dwSkinID == 0 then
        return GetMapParams(nMapID)
    end

    local tSkinConfig= hHomeland.GetPrivateHomeSkinConfig(uMapSkinID)
    if not tSkinConfig then
        return GetMapParams(nMapID)
    end
    return tSkinConfig.szResourceDir, select(2, GetMapParams(nMapID))
end

function MapMgr.CastSkillXYZ(...)
    UIMgr.CloseAllInLayer("UIPageLayer", {VIEW_ID.PanelRevive})
    UIMgr.CloseAllInLayer("UIPopupLayer")

    CastSkillXYZ(...)
end

function MapMgr.Transfer(nMapID, nCityID, funcTransferCallBack)
    local player = GetClientPlayer()
    if player.nLevel < 20 then
        OutputMessage("MSG_ANNOUNCE_NORMAL", g_tStrings.tUse_Item_Msg[USE_ITEM_RESULT_CODE.TOO_LOW_LEVEL])
        return
    end
    local szPath, nMapType = MapMgr.GetMapParams_UIEx(nMapID)
    local tTrafficNodeTitle =
    {
        {f="i", t="dwTrafficID"},
        {f="s", t="szName"},
        {f="i", t="nX"},
        {f="i", t="nY"},
        {f="i", t="nZ"},
        {f="i", t="nType"},
        {f="i", t="dwCityID"}
    }

    local tTrafficNodeFile = KG_Table.Load(szPath .. "minimap_mb\\trafficnode.tab", tTrafficNodeTitle, 0)
    if not tTrafficNodeFile then
        return
    end

    for i, v in ipairs(Storage.WorldMapData.tbRecordList) do
        if v == nMapID then
            table.remove(Storage.WorldMapData.tbRecordList, i)
            break
        end
    end
    table.insert(Storage.WorldMapData.tbRecordList, 1, nMapID)
    Storage.WorldMapData.Dirty()

    if funcTransferCallBack then funcTransferCallBack() end
    --非正常地图,直接读条
    if nMapType ~= MAP_TYPE.NORMAL_MAP and nMapType ~= MAP_TYPE.BIRTH_MAP then
        local tNode = tTrafficNodeFile:GetRow(2)
        if tNode then
            nCityID = tNode.dwCityID
            MapMgr.CastSkillXYZ(3691, 1, nCityID , nMapID, 0)
        end
        return
    end

    MapMgr.CastSkillXYZ(3691, 1, nCityID , nMapID, 0)
end

function MapMgr.TransferWithConfirm(nMapID, nCityID, szConfirm, funcTransferCallBack)
    local szName = GBKToUTF8(Table_GetMapName(nMapID))
    local dialog = UIHelper.ShowConfirm(szConfirm or string.format(g_tStrings.TRANSFER_CONFIRM, szName), function()
        MapMgr.Transfer(nMapID, nCityID, funcTransferCallBack)
    end)
    dialog:SetDynamicText(function()
        local nCurrentTime = GetCurrentTime()
        local tTime = TimeToDate(nCurrentTime)
        return string.format("当前系统时间：%02d:%02d:%02d", tTime.hour, tTime.minute, tTime.second)
    end)
end

function MapMgr.TransferUseItem(nMapID, nCityID, szUseItemTip, funcTransferCallBack)
    UIHelper.ShowSwitchMapConfirm(szUseItemTip or g_tStrings.USE_RESET_ITEM, function()
        MapMgr.UseResetItem()
        Timer.Add(MapMgr, 0.2, function()
            MapMgr.Transfer(nMapID, nCityID, funcTransferCallBack)
        end)
    end)
end

function MapMgr.TryTransfer(nMapID, nCityID, bDungeonEnterMap, szUseItemTip, szConfirm, funcTransferCallBack)
    if PVPFieldData.IsInPVPField() then -- 千里伐逐内需求：神行到其他地图需打开玩法界面退出
        UIMgr.Open(VIEW_ID.PanelQianLiFaZhu)
        return
    end

    -- 地图资源下载检测拦截
    local tMapIDList = {nMapID}
    if bDungeonEnterMap then
        -- 神行至秘境时，需同时下载秘境+秘境入口两张地图
        local tDungeonInfo = Table_GetDungeonInfo(nMapID)
        local nEnterMapID = tDungeonInfo and tDungeonInfo.nEnterMapID
        if nEnterMapID then
            tMapIDList = {nMapID, nEnterMapID}
        end
    end

    local szName = GBKToUTF8(Table_GetMapName(nMapID))
    if not PakDownloadMgr.UserCheckDownloadMapRes(tMapIDList, function()
        local bCD, _ = MapMgr.GetTransferSkillInfo()
        if bCD then
            MapMgr.TransferUseItem(nMapID, nCityID, szUseItemTip, funcTransferCallBack)
        else
            MapMgr.Transfer(nMapID, nCityID, funcTransferCallBack) --下载完成后若不在CD就直接神行
        end
    end, "地图资源文件下载完成，" .. string.format(g_tStrings.TRANSFER_CONFIRM, szName)) then
        return
    end

    local bCD, _ = MapMgr.GetTransferSkillInfo()
    if bCD then
        MapMgr.TransferUseItem(nMapID, nCityID, szUseItemTip, funcTransferCallBack)
    else
        MapMgr.TransferWithConfirm(nMapID, nCityID, szConfirm, funcTransferCallBack)
    end
end

function MapMgr.BeforeTeleport()
    local hPlayer = GetClientPlayer()
    if not hPlayer then
        return
    end

    --打坐中站起
    if hPlayer.nMoveState == MOVE_STATE.ON_SIT then
        hPlayer.Stand()
    end
end


---@param dwConfirmEnterMapID number|nil 弹出确认神行弹窗时显示地图名称所用的地图ID，如果不填则不弹窗直接执行
function MapMgr.CheckTransferCDExecute(fnCallback, dwConfirmEnterMapID)
    if not fnCallback then
        return
    end
    MapMgr.BeforeTeleport()
    local bCD, _ = MapMgr.GetTransferSkillInfo()
    if bCD then
        UIHelper.ShowSwitchMapConfirm(g_tStrings.USE_RESET_ITEM, function()
            MapMgr.UseResetItem()
            Timer.Add(MapMgr, 0.2, fnCallback)
        end)
    elseif dwConfirmEnterMapID then
        local szName = UIHelper.GBKToUTF8(Table_GetMapName(dwConfirmEnterMapID))
        local dialog = UIHelper.ShowConfirm(string.format(g_tStrings.TRANSFER_CONFIRM, szName), function()
            fnCallback()
        end)
        dialog:SetDynamicText(function()
            local nCurrentTime = GetCurrentTime()
            local tTime = TimeToDate(nCurrentTime)
            return string.format("当前系统时间：%02d:%02d:%02d", tTime.hour, tTime.minute, tTime.second)
        end)
    else
        fnCallback()
    end
end

function MapMgr.CampCrossServerTeleport(dwMapID, nSelServer)
	local bSafeCity = GDAPI_CrossServer_SafeCity()
    local bCD, _ = MapMgr.GetTransferSkillInfo()
	if not bSafeCity then
        MapMgr.CheckTransferCDExecute(function()
            RemoteCallToServer("On_CrossServer_Transfer", dwMapID, nSelServer)
        end)
		return
	end
	RemoteCallToServer("On_CrossServer_Transfer", dwMapID, nSelServer)
end

function MapMgr.TrafficTo(nNodeID, nCityID)
    RoadTrackStartOut(nNodeID, nCityID)
    UIMgr.Close(VIEW_ID.PanelMiddleMap)
    UIMgr.CloseAllInLayer("UIPageLayer")
    UIMgr.CloseAllInLayer("UIPopupLayer")
end

function MapMgr.GetTransferSkillCD()
    local bCool = false
    local player = GetClientPlayer()
    if not player then
        return bCool
    end
    local nSkillLevel = player.GetSkillLevel(TRANSPORT_SKILL_ID)
    local bCd, nLeft, nTotal = Skill_GetCDProgress(TRANSPORT_SKILL_ID, nSkillLevel, nil, player)
    local szLeft = UIHelper.GetTimeText(nLeft, true)
    if bCd and nTotal > 24 then
        bCool =  true
    end

    return bCool or not nSkillLevel, szLeft, nLeft
end

function MapMgr.GetTransferSkillInfo()
    local bSkillInCD, szLeft = MapMgr.GetTransferSkillCD()
    local szTraffic = g_tStrings.WORLD_MAP_TO
    if bSkillInCD then
        szTraffic = szTraffic .. "(" .. szLeft .. ")"
    end

    return bSkillInCD, szTraffic
end

function MapMgr.UnselectOther(node, tbParent)
    for i, v in ipairs(tbParent) do
        if v ~= node then
            UIHelper.SetSelected(v, false, false)
        end
    end
end

function MapMgr.ToggleSelect(prev, cur, bSelected)
    if bSelected and prev and prev ~= cur then
        prev:SetSelected(false)
    end
    cur:SetSelected(bSelected)
end

function MapMgr.GetResetItemCount()
    local player = GetClientPlayer()
    if not player then
        return 0
    end
    return player.GetItemAmountInPackage(RESET_ITEM.dwTabType, RESET_ITEM.dwIndex)
end

function MapMgr.UpdateResetItemIcon(script)
    script:OnInitWithTabID(RESET_ITEM.dwTabType, RESET_ITEM.dwIndex)
end

function MapMgr.UseResetItem()
    local player = GetClientPlayer()
    if not player then
        return
    end
    local dwBox, dwX = player.GetItemPos(RESET_ITEM.dwTabType, RESET_ITEM.dwIndex)
    if not dwBox or not dwX then
        return
    end
    ItemData.UseItemWrapper(dwBox, dwX)
end

function MapMgr.GetPlayerRotation(player)
    return (255 + 64 - player.nFaceDirection) / 255  * 360
end

function MapMgr.GetCameraRotation()
    local _, nYaw, _ = Camera_GetRTParams()
    return nYaw / 6.2832 * 360
end

function MapMgr.SetTracePoint(szName, nMapID, tbPoint, szUID, szFrame)
    if not MapHelper.IsMapOpen(nMapID) then
        return
    end

    local bCheckZValue = false
    local nZ = tbPoint[3]
    if not nZ then
        tbPoint[3] = Scene_GetFloor(tbPoint[1], tbPoint[2])
        bCheckZValue = true
    end

    MapMgr.szName = szName
    MapMgr.nMapID = nMapID
    MapMgr.tbPoint = tbPoint
    MapMgr.szUID = szUID
    MapMgr.szFrame = szFrame
    Event.Dispatch(EventType.OnMapUpdateNpcTrace)

    if bCheckZValue then--处理Z值不正确得情况，比如角色距离自定义标记点太远，此时标记点地形未加载，会获得错误得z值坐标（在地下），因此在这里适当时候更新z值坐标
        MapMgr.StartCheckZValue()
    end
end

function MapMgr.ClearTracePoint(bNearAutoClear)
    if MapMgr.tbPoint == nil then return end
    MapMgr.szName = nil
    MapMgr.nMapID = nil
    MapMgr.tbPoint = nil
    MapMgr.szUID = nil
    MapMgr.szFrame = nil
    Event.Dispatch(EventType.OnMapUpdateNpcTrace, bNearAutoClear)
end

function MapMgr.StartCheckZValue()
    MapMgr.StopCheckZValue()
    MapMgr.nCheckTimer = Timer.AddCycle(MapMgr, 1, function()
        local tbPoint = MapMgr.tbPoint
        local nTraceMapID = MapMgr.nMapID
        local player = g_pClientPlayer

        if SceneMgr.IsLoading() then
            return
        end

        if not tbPoint or not nTraceMapID then
            MapMgr.StopCheckZValue()
            return
        end

        if not player then
            return
        end

        local nMapID = g_pClientPlayer.GetMapID()
        if nMapID ~= nTraceMapID then
            return
        end

        local nPlayerX, nPlayerY = player.nX, player.nY
        local nDistance = math.sqrt(math.pow(tbPoint[1] - player.nX, 2) + math.pow(tbPoint[2] - player.nY, 2))
        if nDistance <= MIN_DISTANCE_CHECKZVALUE then
             local nZ = Scene_GetFloor(tbPoint[1], tbPoint[2])
            if not tbPoint[3] or nZ ~= tbPoint[3] then
                MapMgr.tbPoint = {tbPoint[1], tbPoint[2], nZ}
                Event.Dispatch(EventType.OnMapUpdateNpcTrace)
            end
            MapMgr.StopCheckZValue()
        end
    end)
end

function MapMgr.StopCheckZValue()
    if MapMgr.nCheckTimer then
        Timer.DelTimer(MapMgr, MapMgr.nCheckTimer)
        MapMgr.nCheckTimer = nil
    end
end

function MapMgr.RemoveTracePointByUID(szUID)
    if szUID and MapMgr.szUID == szUID then
        MapMgr.ClearTracePoint(false)
    end
end

function MapMgr.CanShowTrace(bIsNpcTrace)
    --特殊处理，拭剑园战场不显示追踪
    if MapHelper.GetBattleFieldType() == BATTLEFIELD_MAP_TYPE.NEWCOMERBATTLE then
        return false
    end

    -- 服务器命令控制下来的要显示
    if not bIsNpcTrace and IsBoolean(Storage.Player.bShowTrace) then
        return Storage.Player.bShowTrace
    end

    -- 102级之前不显示
    if g_pClientPlayer and g_pClientPlayer.nLevel < 102 then
        return false
    end

    --自动寻路与追踪是同一个目标，不显示追踪
    -- if MapMgr.nMapID and MapMgr.tbPoint and AutoNav.IsCurNavPoint(MapMgr.nMapID, MapMgr.tbPoint[1], MapMgr.tbPoint[2], MapMgr.tbPoint[3]) then
        -- return false--注释掉这一段，防止出现主界面寻路和追踪同一个目标时，没显示追踪图标--温健豪，何黄靖
    -- end

    return true
end

function MapMgr.InitCraft()
    if table.is_empty(Storage.MiddleMapData.tbCraftList) then
        Storage.MiddleMapData.bShowCraft = false
    end
    Storage.MiddleMapData.Dirty()
end

function MapMgr.AddCraftInfo(dwTemplateID, nCraftID)
    Storage.MiddleMapData.tbCraftList = {}
    Storage.MiddleMapData.tbCraftList[dwTemplateID] = nCraftID
    Storage.MiddleMapData.Dirty()
end

function MapMgr.ClearCraftInfo()
    Storage.MiddleMapData.tbCraftList = {}
    Storage.MiddleMapData.Dirty()
end

function MapMgr.SetShowCraft(bShowCraft)
    Storage.MiddleMapData.bShowCraft = bShowCraft
    Storage.MiddleMapData.Dirty()
end

function MapMgr.IsMiddleMapShowCraft()
    local viewScript = UIMgr.GetViewScript(VIEW_ID.PanelMiddleMap)
    local nMapID = viewScript and viewScript.nMapID
    if not nMapID then
        return false
    end
    MapHelper.InitMiddleMapInfo(nMapID)
    for nIndex, craft in pairs(MapHelper.tbMiddleMapCraftGuide[nMapID] or {}) do
        if Storage.MiddleMapData.tbCraftList[craft.dwID] ~= nil then
            return true
        end
    end
    return false
end

function MapMgr.SetShowQuest(bShowQuest)
    MapMgr.bShowQuest = bShowQuest
end

function MapMgr.IsShowQuest()
    if MapMgr.bShowQuest ~= nil then return MapMgr.bShowQuest end
    return true
end

function MapMgr.SetShowShenXing(bShowShenXing)
    MapMgr.bShowShenXing = bShowShenXing
end

function MapMgr.IsShowShenXing()
    if MapMgr.bShowShenXing ~= nil then return MapMgr.bShowShenXing end
    return true
end

function MapMgr.SetShowTraffic(bShowTraffic)
    MapMgr.bShowTraffic = bShowTraffic
end

function MapMgr.IsShowTraffic()
    if MapMgr.bShowTraffic ~= nil then return MapMgr.bShowTraffic end
    return true
end

function MapMgr.SetShowExploreFinish(bShowExploreFinish)
    Storage.MiddleMapData.bShowExploreFinish = bShowExploreFinish
end

function MapMgr.IsShowExploreFinish()
    return Storage.MiddleMapData.bShowExploreFinish
end

Event.Reg(MapMgr, "UPDATE_MAP_MARK", function(nX, nY, nZ, nType, szComment, bShowMidMap)
    if bShowMidMap then
	    local szMarkName = UIHelper.GBKToUTF8(szComment)
        if szMarkName == g_tStrings.STR_MY_HOMELAND or szMarkName == g_tStrings.STR_MY_HOMELAND_QUEST then
            -- MapMgr会在loadingEnd的时候清掉原有的Mapmark
            -- 但是家园的这俩都是只在进图前或者日常任务状态改变时更新一次，所以需要单独拎出来
            MapMgr.szHomeLandMarkName = szMarkName
            MapMgr.nHomeLandMarkX = nX
            MapMgr.nHomeLandMarkY = nY
            MapMgr.nHomeLandMarkZ = nZ

            Event.Dispatch(EventType.OnHomeLandMapMarkUpdate)
            return
        end

        MapMgr.szMarkName = szMarkName
        MapMgr.nMarkX = nX
        MapMgr.nMarkY = nY
        MapMgr.nMarkZ = nZ
        MapMgr.nMapMarkMapID = GetClientPlayer().GetMapID()
        Event.Dispatch(EventType.OnMapMarkUpdate)
    end
end)

Event.Reg(MapMgr, "DEL_MAP_MARK", function(nX, nY, nZ, nType, szComment, bShowMidMap)
    if bShowMidMap then
	    local szMarkName = UIHelper.GBKToUTF8(szComment)
        if szMarkName == g_tStrings.STR_MY_HOMELAND or szMarkName == g_tStrings.STR_MY_HOMELAND_QUEST then
            MapMgr.szHomeLandMarkName = nil
            MapMgr.nHomeLandMarkX = nil
            MapMgr.nHomeLandMarkY = nil
            MapMgr.nHomeLandMarkZ = nil

            Event.Dispatch(EventType.OnHomeLandMapMarkUpdate)
            return
        end

        MapMgr.szMarkName = nil
        MapMgr.nMarkX = nil
        MapMgr.nMarkY = nil
        MapMgr.nMarkZ = nil
        MapMgr.nMapMarkMapID = nil

        Event.Dispatch(EventType.OnMapMarkUpdate, true)
    end
end)



function MapMgr.GetMarkInfo()
    return MapMgr.szMarkName, MapMgr.nMarkX, MapMgr.nMarkY, MapMgr.nMarkZ, MapMgr.nMapMarkMapID
end

function MapMgr.GetHomelandMarkInfo()
    return MapMgr.szHomeLandMarkName, MapMgr.nHomeLandMarkX, MapMgr.nHomeLandMarkY, MapMgr.nHomeLandMarkZ
end

function MapMgr.GetTraceInfo()
    return MapMgr.szName, MapMgr.nMapID, MapMgr.tbPoint, MapMgr.szUID, MapMgr.szFrame
end

function MapMgr.IsNodeTraced(nMapID, tbPoint)
    if not tbPoint or not MapMgr.tbPoint then
        return false
    end
    return MapMgr.nMapID == nMapID and MapMgr.tbPoint[1] == tbPoint[1]
        and MapMgr.tbPoint[2] == tbPoint[2] and MapMgr.tbPoint[3] == tbPoint[3]
end

function MapMgr.IsCurrentMap(nMapID)
    local player = GetClientPlayer()
    if not player then
        return
    end
    return player.GetMapID() == nMapID
end

function MapMgr.OpenWorldMapTransportPanel(nMapID, bHighlight)
    if not UIMgr.GetView(VIEW_ID.PanelWorldMap) then
        UIMgr.Open(VIEW_ID.PanelWorldMap, {
            nTraceMapID = nMapID,
            bHighlight = bHighlight,
        })
    end
    Event.Dispatch(EventType.OnMapTraceZoning, nMapID, bHighlight, true)
end

function MapMgr.OpenMiddleMapTraffic(nTrafficID, nFinishCityID, nNpcID, nMapID, szMessage)
    if not g_pClientPlayer then
        return
    end
    local tbTraffic = {
        nTrafficID    = nTrafficID,
        nFinishCityID = nFinishCityID,
    }
    if not UIMgr.GetView(VIEW_ID.PanelMiddleMap) then
        nMapID = nMapID or g_pClientPlayer.GetMapID()
        UIMgr.Open(VIEW_ID.PanelMiddleMap, nMapID, 0, nil, tbTraffic, {szMessage = szMessage})
    end
    Event.Dispatch(EventType.OnMapOpenTraffic, tbTraffic)
end

function MapMgr.InitPosConvertor(self, w, h, startx, starty, scale)
    self.nWidth = w
    self.nHeight = h
    self.nStartX = startx
    self.nStartY = starty
    self.nScale = scale
end

function MapMgr.UpdatePosConvertor(self, img)
    local x, y = UIHelper.GetWorldPosition(img)
    local size = img:getPreferredSize()
    local scale = UIHelper.GetScale(img)
    self.nImageWidth = size.width * scale
    self.nImageHeight = size.height * scale
    self.nMapX = x - self.nImageWidth / 2
    self.nMapY = y + self.nImageHeight / 2
    self.nScaleX = self.nImageWidth / self.nWidth * self.nScale
    self.nScaleY = self.nImageHeight / self.nHeight * self.nScale
end

-- World Position
function MapMgr.LogicPosToMapPos(self, x, y, w, h)
    local retX = self.nMapX + (x - self.nStartX) * self.nScaleX
    local retY = self.nMapY + (y - self.nStartY) * self.nScaleY - self.nImageHeight
    return retX, retY
end

function MapMgr.MapPosToLogicPos(self, x, y)
    local tPos = cc.Director:getInstance():convertToGL({x = x, y = y})
    local retX = self.nStartX + (tPos.x - self.nMapX) / self.nScaleX
    local retY = self.nStartY + (self.nMapY - tPos.y) / self.nScaleY
    return retX, retY
end

function MapMgr.AllocScript(tb, parent, nPrefabID, nIndex)
    if #tb < nIndex then
        local script = UIHelper.AddPrefab(nPrefabID, parent)
        table.insert(tb, script)
    end
    UIHelper.SetVisible(tb[nIndex]._rootNode, true)
    if IsFunction(tb[nIndex].OnShow) then tb[nIndex]:OnShow() end
    return tb[nIndex]
end

function MapMgr.ClearScript(tb, nCount)
    for i = nCount, #tb do
        UIHelper.SetVisible(tb[i]._rootNode, false)
        if IsFunction(tb[i].OnHide) then tb[i]:OnHide() end
    end
end

function MapMgr.ApplyDynamicDataEx()
    local player = GetClientPlayer()
	local scene = GetClientScene()
	local dwMapID = scene.dwMapID
	if dwMapID == 194 then--太原
		local tData = player.GetMapMark()
		if dwMapID ~= player.GetMapID() then
			tData = {}
		end

		local tApply = {}
		for k, v in ipairs(tData) do
			local dwID = Table_GetNewPQId(v.nType)
			if dwID then
				table.insert(tApply, dwID)
			end
		end
		RemoteCallToServer("On_PQ_MidMapPQPr", tApply)
	end
end

function MapMgr.GetDeathPosition()
    return MapMgr.tbDeathPos
end

function MapMgr.UpdateDeathPosition()
    local player = GetClientPlayer()
    MapMgr.tbDeathPos = {player.nX, player.nY, player.nZ}
end

function MapMgr.ClearDeathPosition()
    MapMgr.tbDeathPos = nil
end

function MapMgr.ClearMapMarkInfo()
    MapMgr.szMarkName = nil
    MapMgr.nMarkX = nil
    MapMgr.nMarkY = nil
    MapMgr.nMarkZ = nil
    MapMgr.nMapMarkMapID = nil
end

function MapMgr.UpdateActivityState()
    local nTime = GetCurrentTime()
    if not MapMgr.nActivityRefreshTime or (nTime - MapMgr.nActivityRefreshTime > 30) then
        MapMgr.nActivityRefreshTime = nTime
        RemoteCallToServer("On_Map_GetSpecialActivityState")
        return true
    end
    return false
end

function MapMgr.OnLoadingEnd()
    MapMgr.UpdateActivityState()
    MapMgr.ClearDeathPosition()
    MapMgr.ClearMapMarkInfo()
    MapMgr.CheckAutoStart()
    MapMgr.ClearMonsterAnger()
    MapMgr.CallServerLoadingEnd()
    MapMgr.TreasureHuntShield()
end

function MapMgr.OpenMiddleMap()
    local nViewID
    if BattleFieldData.IsInTreasureBattleFieldMap() and not BattleFieldData.IsInXunBaoBattleFieldMap() then
        nViewID = VIEW_ID.PanelBattleFieldPubgMapRightPop
    else
        nViewID = VIEW_ID.PanelMiddleMap
    end
    UIMgr.Open(nViewID)
end

Event.Reg(MapMgr, "PLAYER_DEATH", MapMgr.UpdateDeathPosition)

Event.Reg(MapMgr, "PLAYER_EXIT_GAME", MapMgr.ClearTracePoint)
Event.Reg(MapMgr, "LOADING_END", MapMgr.OnLoadingEnd)
Event.Reg(MapMgr, "ON_SPECIAL_ACTIVE_STATE_RESPOND", function()
    MapMgr.tActivityList = arg0 or {}
    Event.Dispatch(EventType.ON_SPECIAL_ACTIVE_STATE_RESPOND)
end)

function MapMgr.SetMapTrace(nMapID)
    MapMgr.nTraceMapID = nMapID
end

function MapMgr.ClearMapTrace()
    MapMgr.nTraceMapID = nil
end

function MapMgr.IsMapTraced(nMapID)
    return MapMgr.nTraceMapID == nMapID
end

function MapMgr.ChangeSFXMark(nLPosx, nLPosy, nMapID)

    local bRet = GetClientTeam().ChangeSFXMark(TEAM_MARK_SFX_ID, nLPosx, nLPosy)
    if bRet then
        g_pClientPlayer.SyncMidMapMark(nMapID, nLPosx, nLPosy, -1, UIHelper.UTF8ToGBK(g_tStrings.MIDDLEMAP_NEW_TEAM_FLAG))
        MapMgr.SetMapTeamTag(nMapID, nLPosx, nLPosy)
    end
    return bRet
end

function MapMgr.SetMapTeamTag(nMapID, nX, nY)

    if not MapMgr.HasTeamTag() and not nMapID then return end

    MapMgr.RemoveTeamMark()

    if nMapID ~= nil and nX ~= 0 and nY ~= 0 then
        local tbTagList = MapMgr.GetTagList(nMapID)

        local tbData = {szUID = string.format("%d_%d_%d", nMapID, nX, nY),
                        nIndex = #tbTagList + 1,
                        nIconID = 8,
                        szName = g_tStrings.MIDDLEMAP_NEW_TEAM_FLAG,
                        nMapID = nMapID,
                        nX = nX,
                        nY = nY,
                        bCreated = true,
        }
        Storage.MiddleMapData.tbTeamTagInfo.nMapID = nMapID
        table.insert(tbTagList, tbData)
    end
    Storage.MiddleMapData.Dirty()
end

function MapMgr.RemoveTeamMark()
    if MapMgr.HasTeamTag() then
        local nIndex = MapMgr.GetTeamTagIndex()
        MapMgr.DeleteTag(Storage.MiddleMapData.tbTeamTagInfo.nMapID, nIndex)
        Storage.MiddleMapData.tbTeamTagInfo.nMapID = 0
        Event.Dispatch(EventType.OnDeleteTeamMark)
    end
end

function MapMgr.GetTagList(nMapID)
    if not Storage.MiddleMapData.tbTagList[nMapID] then
        Storage.MiddleMapData.tbTagList[nMapID] = {}
        Storage.MiddleMapData.Dirty()
    end
    return Storage.MiddleMapData.tbTagList[nMapID]
end

function MapMgr.DeleteTag(nMapID, nIndex)
    local tbTagList = MapMgr.GetTagList(nMapID)
    if tbTagList[nIndex] then
        table.remove(tbTagList, nIndex)
        for i, v in ipairs(tbTagList) do
            v.nIndex = i
        end
        Storage.MiddleMapData.Dirty()
    end
end

function MapMgr.GetTagByIndex(nMapID, nIndex)
    local tbTagList = MapMgr.GetTagList(nMapID)
    return tbTagList[nIndex]
end

function MapMgr.GetTagListLen(nMapID)
    local tbTagList = MapMgr.GetTagList(nMapID)
    return  #tbTagList
end

function MapMgr.AddNormalTag(nMapID, tbData)
    local tbTagList = MapMgr.GetTagList(nMapID)
    table.insert(tbTagList, tbData)
    Storage.MiddleMapData.Dirty()
end

function MapMgr.GetTeamTagIndex()
    if MapMgr.HasTeamTag() then
        local tbTagList = MapMgr.GetTagList(Storage.MiddleMapData.tbTeamTagInfo.nMapID)
        for nIndex, tbData in pairs(tbTagList) do
            if tbData.szName == g_tStrings.MIDDLEMAP_NEW_TEAM_FLAG then
                return nIndex
            end
        end
        LOG.INFO("GetTeamTagIndex Failed nMapID:%s", tostring(Storage.MiddleMapData.tbTeamTagInfo.nMapID))--正常不会走到这
    end
    return 0
end

function MapMgr.HasTeamTag()
    return Storage.MiddleMapData.tbTeamTagInfo.nMapID ~= 0
end

function MapMgr.GetTeamTag()
    if MapMgr.HasTeamTag() then
        local tbTagList = MapMgr.GetTagList(Storage.MiddleMapData.tbTeamTagInfo.nMapID)
        for nIndex, tbData in pairs(tbTagList) do
            if tbData.szName == g_tStrings.MIDDLEMAP_NEW_TEAM_FLAG then
                return tbData
            end
        end
    end
    return nil
end

function MapMgr.UpdateMapTeamTag()

    local hTeamClient = GetClientTeam()

    if not hTeamClient or hTeamClient.dwTeamID == 0 then
        MapMgr.SetMapTeamTag()
        return
    end

    local tbTeamFlag = hTeamClient.GetTeamSFXMark()
    if tbTeamFlag.dwSFXID == 0 then
        MapMgr.SetMapTeamTag()
    elseif tbTeamFlag.dwSFXID == 1 then
        MapMgr.SetMapTeamTag(tbTeamFlag.dwMapID, tbTeamFlag.nX, tbTeamFlag.nY)
    end
end

function MapMgr.GetLikeMapList()
    return Storage.MiddleMapData.tbLikeMapList
end

function MapMgr.AddLikeMap(nMapID)
    if MapMgr.IsLikeMap(nMapID) then return false end

    if #Storage.MiddleMapData.tbLikeMapList == MAX_LIKE_MAP_COUNT then
        TipsHelper.ShowNormalTip("收藏已达最大数量")
        return false
    end

    table.insert(Storage.MiddleMapData.tbLikeMapList, nMapID)
    Storage.MiddleMapData.tbLikeMap[nMapID] = true
    Storage.MiddleMapData.Dirty()

    TipsHelper.ShowNormalTip("已加入常用神行点")
    Event.Dispatch(EventType.OnLikeMapListChange)
    return true
end

function MapMgr.RemoveLikeMap(nMapID)
    for nIndex, dwMapID in ipairs(Storage.MiddleMapData.tbLikeMapList) do
        if dwMapID == nMapID then
            table.remove(Storage.MiddleMapData.tbLikeMapList, nIndex)
            Storage.MiddleMapData.tbLikeMap[nMapID] = false
            Storage.MiddleMapData.Dirty()
            Event.Dispatch(EventType.OnLikeMapListChange)
            break
        end
    end
end

function MapMgr.IsLikeMap(nMapID)
    return Storage.MiddleMapData.tbLikeMap[nMapID] == true
end

function MapMgr.GetMaxLikeMapCount()
    return MAX_LIKE_MAP_COUNT
end
-------------------------------- 轻功登顶相关 --------------------------------

MapMgr.dwSprintSummitID = 0

function MapMgr.UpdateSprintPoints(bAdd, dwID, x, y, z)
    if bAdd then
        MapMgr.m_tSprintPoint = MapMgr.m_tSprintPoint or {}
        if x < 0 or y < 0 or z < 0 then
            return
        end
        MapMgr.m_tSprintPoint[dwID] = {x=x, y=y, z=z}
    else
        if MapMgr.m_tSprintPoint then
            MapMgr.m_tSprintPoint[dwID] = nil
        end
    end
end

function MapMgr.SprintGetSummitID()
    local dwSprintSummitID = MapMgr.dwSprintSummitID
    local tSprintPoint = MapMgr.m_tSprintPoint
	if dwSprintSummitID > 0 and tSprintPoint and tSprintPoint[dwSprintSummitID]
	then
		local x, y, z = Scene_ScenePositionToGameWorldPosition(tSprintPoint[dwSprintSummitID].x,
                                                               tSprintPoint[dwSprintSummitID].y,
                                                               tSprintPoint[dwSprintSummitID].z)
		return 1, x, y, z
	else
		return 0, 0, 0, 0
	end
end



-----------------地图名、区域名tip显示相关-----------
-- 1、地图名称提示显示的优先级>区域名称提示
-- 2、如果地图名称提示还在显示过程时遇到区域名称的提示，此时把此条区域提示吞掉不再显示
-- 3、没有地图名称提示显示时，遇到区域名称时，此时可以弹区域名称提示

--1、黄色 2、红色 3、蓝色
function MapMgr.AddMapTip(szText, nColor, bArea)

    if string.is_nil(szText) then return end--没有地名不显示

    if not MapMgr.tbMapTip then MapMgr.tbMapTip = {} end
    if not MapMgr.tbAreaTip then MapMgr.tbAreaTip = {} end

    local tbData = {}
    tbData = {
        szText = szText,
        nColor = nColor,
    }
    if bArea then
        table.insert(MapMgr.tbAreaTip, tbData)
    else
        table.insert(MapMgr.tbMapTip, tbData)
    end
    MapMgr.ShowMapTip()
end

function MapMgr.ShowMapTip()
    if SceneMgr.IsLoading() then return end

    if not MapMgr.tbMapTip then return end

    if #MapMgr.tbMapTip > 0 then MapMgr.tbAreaTip = {} end--如果地图名称提示还在显示过程时遇到区域名称的提示，此时把此条区域提示吞掉不再显示

    local function ShowTip(szText, nColor)
        if nColor == 1 then
            TipsHelper.ShowPlaceYellowTip(szText)
        elseif nColor == 2 then
            TipsHelper.ShowPlaceRedTip(szText)
        else
            TipsHelper.ShowPlaceBlueTip(szText)
        end
    end

    for nIndex, tbTip in ipairs(MapMgr.tbMapTip) do
        ShowTip(tbTip.szText, tbTip.nColor)
    end

    for nIndex, tbTip in ipairs(MapMgr.tbAreaTip) do
        ShowTip(tbTip.szText, tbTip.nColor)
    end

    MapMgr.tbMapTip = {}
    MapMgr.tbAreaTip = {}


end


function MapMgr.GetMarkInfoByTypeID(nType)
    for _, tLineMarkInfo in pairs(MapMgr.GetMapCommandInfo()) do
        if tLineMarkInfo.dwID == nType then
            return tLineMarkInfo
        end
    end
    return nil
end

function MapMgr.GetMapCommandInfo()
    if not MapMgr.tMapCommandInfo then
        MapMgr.tMapCommandInfo = Table_GetMiddleMapCommandInfo()
    end
    return MapMgr.tMapCommandInfo
end

function MapMgr.GetNPCTableInfo()
    if not MapMgr.tNPCTableInfo then
        MapMgr.tNPCTableInfo = Table_GetMiddleMapCommandNpc()
    end
    return MapMgr.tNPCTableInfo
end

function MapMgr.GetSyncBoardInfo()
    local nCamp = CampOBBaseData.GetCampOfBoardInfo()
    return CommandBaseData.GetSyncBoardInfo(nCamp)
end

function MapMgr.GetCraftPosByID(nMapID, dwID)
    if MapMgr.tbCraftPos and MapMgr.tbCraftPos[nMapID] then
        return MapMgr.tbCraftPos[nMapID][dwID]
    end
    local tbCraftGuide = MapHelper.tbMiddleMapCraftGuide[nMapID]
    MapMgr.tbCraftPos = MapMgr.tbCraftPos or {}
    MapMgr.tbCraftPos[nMapID] = {}

    for nIndex, craft in pairs(tbCraftGuide) do
        MapMgr.tbCraftPos[nMapID][craft.dwID] = craft.tPos
    end

    return MapMgr.tbCraftPos[nMapID][dwID]
end



function MapMgr.IsPlayerCanDraw()
    local bRet          = false
    local nPlayerRole   = CommandBaseData.GetRoleType()

    if nPlayerRole == COMMAND_MODE_PLAYER_ROLE.SUPREME_COMMANDER then
        bRet = true
    end

    return bRet
end

function MapMgr.IsCommander()
    local bIsCommander = false
    -- if Model.nPlayerRole == COMMAND_MODE_PLAYER_ROLE.VICE_COMMANDER or Model.nPlayerRole == COMMAND_MODE_PLAYER_ROLE.SUPREME_COMMANDER then
    --     bIsCommander = true
    -- end
    local hPlayer = g_pClientPlayer
    if not hPlayer then
        return
    end
    bIsCommander = ( hPlayer.nCamp == CAMP.GOOD or hPlayer.nCamp == CAMP.EVIL )

    return bIsCommander
end

function MapMgr.Table_GetMapDynamicData()
    if not MapMgr.tbDynamicData then
        MapMgr.tbDynamicData = Table_GetMapDynamicData()
    end
    return MapMgr.tbDynamicData
end

function MapMgr.Table_GetBattleMarkState()
    if not MapMgr.tFieldMarkStateFrame then
        MapMgr.tFieldMarkStateFrame = Table_GetBattleMarkState()
    end
    return MapMgr.tFieldMarkStateFrame
end

function MapMgr.Table_GetBattleFieldData()
    if not MapMgr.tBattleData then
        local nCount = g_tTable.BattleFieldData:GetRowCount()
        MapMgr.tBattleData = {}

        --Row One for default value
        for i = 2, nCount do
            local tData = g_tTable.BattleFieldData:GetRow(i)
            MapMgr.tBattleData[tData.nType] = tData
        end
    end
    return MapMgr.tBattleData
end

function MapMgr.GetMapDynamicImage(nType)
    local tbDynamicData = MapMgr.Table_GetMapDynamicData()
    local tbInfo = tbDynamicData[nType]
    local szImage = UIHelper.GBKToUTF8(tbInfo.szImage)
    local tbText = string.split(szImage, "/")
    local szImgPath = ""
    local nFrame = tbInfo.nFrame
    if #tbText > 1 then
        szImage = tbText[#tbText - 1] .. "_".. string.gsub(tbText[#tbText], ".UITex", "")
        szImgPath = "Resource_" .. szImage .. "_" .. tostring(nFrame)
    else
        szImgPath = UIHelper.GBKToUTF8(tbInfo.szMobileImage)
    end
    return szImgPath
end

function MapMgr.GetBattleMarkImage(nState)
    local tbBattleMarkData = MapMgr.Table_GetBattleMarkState()
    local tbInfo = tbBattleMarkData[nState]
    local szImage = UIHelper.GBKToUTF8(tbInfo.szPath)
    local tbText = string.split(szImage, "\\")
    local szImgPath = ""
    local nFrame = tbInfo.nFrame
    if #tbText > 1 then
        szImage = tbText[#tbText - 1] .. "_".. string.gsub(tbText[#tbText], ".UITex", "")
        szImgPath = "Resource_" .. szImage .. "_" .. tostring(nFrame)
    else
        szImgPath = UIHelper.GBKToUTF8(tbInfo.szMobileImage)
    end

    if not UISpriteNameToFileTab.tbSpriteNameToFileMap[szImgPath] and not UISpriteNameToFileTab.tbSpriteNameToFileMap[szImgPath .. ".png"] then
        szImgPath = UIHelper.GBKToUTF8(tbInfo.szMobileImage)
    end
    return szImgPath
end

function MapMgr.GetBattleFieldDataImage(nType)
    local tbBattleData = MapMgr.Table_GetBattleFieldData()
    local tbInfo = tbBattleData[nType]
    local szImage = UIHelper.GBKToUTF8(tbInfo.szImage)
    local tbText = string.split(szImage, "/")
    local szImgPath = ""
    local nFrame = tbInfo.nFrame
    if #tbText > 1 then
        szImage = tbText[#tbText - 1] .. "_".. string.gsub(tbText[#tbText], ".UITex", "")
        szImgPath = "Resource_" .. szImage .. "_" .. tostring(nFrame)
    else
        szImgPath = UIHelper.GBKToUTF8(tbInfo.szFrame)
    end

    if not UISpriteNameToFileTab.tbSpriteNameToFileMap[szImgPath] and not UISpriteNameToFileTab.tbSpriteNameToFileMap[szImgPath .. ".png"] then
        szImgPath = UIHelper.GBKToUTF8(tbInfo.szFrame)
    end
    return szImgPath
end

function MapMgr.GetNpcList(nMapID)
    if MapMgr.tbMiddleMapNpc and MapMgr.tbMiddleMapNpc[nMapID] then
        return MapMgr.tbMiddleMapNpc[nMapID]
    end

    if not MapMgr.tbMiddleMapNpc then MapMgr.tbMiddleMapNpc = {} end
    if not MapMgr.tbMiddleMapNpc[nMapID] then MapMgr.tbMiddleMapNpc[nMapID] = {} end

    table.insert_tab(MapMgr.tbMiddleMapNpc[nMapID], MapHelper.tbMiddleMapNpc[nMapID])
    table.insert_tab(MapMgr.tbMiddleMapNpc[nMapID], MapHelper.tbMiddleMapDoodad[nMapID])

    return MapMgr.tbMiddleMapNpc[nMapID]
end

function MapMgr.GetRedPointQuestInfo(nMapID)
    if not MapMgr.tbRedPointQuest then return end
    return MapMgr.tbRedPointQuest[nMapID]
end

function MapMgr.SetRedPointQuest(tbRedPointQuestInfo, nMapID)
    if not MapMgr.tbRedPointQuest then MapMgr.tbRedPointQuest = {} end
    if not MapMgr.tbQuestToMap then MapMgr.tbQuestToMap = {} end
    if not MapMgr.tbRedPointQuest[nMapID] then MapMgr.tbRedPointQuest[nMapID] = {} end
    MapMgr.tbRedPointQuest[nMapID] = tbRedPointQuestInfo
    MapMgr.tbQuestToMap[tbRedPointQuestInfo[1]] = nMapID
    Event.Dispatch("ON_MIDDLE_MAP_REDPOINT_CHANGE")
end

function MapMgr.RemoveRedPoint(nQuestID)
    local tbQuestToMap = MapMgr.tbQuestToMap
    local nMapID = tbQuestToMap and tbQuestToMap[nQuestID] or nil
    if nMapID then
        MapMgr.tbRedPointQuest[nMapID] = nil
        MapMgr.tbQuestToMap[nQuestID] = nil
    end
end

function MapMgr.GetNPCListByKey(nMapID, szKey)

    if not MapMgr.tbNPCList then MapMgr.tbNPCList = {} end

    if not MapMgr.tbNPCList[nMapID] then
        MapMgr.UpdateNPCList(nMapID)
    end

    local tbRes = {}
    for szName, tbInfo in pairs(MapMgr.tbNPCList[nMapID]) do
        if string.match(szName, szKey) then
            table.insert(tbRes, {szName = szName, tbNpcList = tbInfo})
        end
    end
    return tbRes
end

function MapMgr.UpdateNPCList(nMapID)
    if MapMgr.tbNPCList[nMapID] then
        return
    end
    MapMgr.tbNPCList[nMapID] = {}

    local szMapName = GetMapParams(nMapID)
    szMapName = string.gsub(szMapName, "data\\source\\maps\\", "")

    local szDataFile
    if Platform.IsWindows() then
        szDataFile = "data\\source\\maps\\" .. szMapName .. "\\" .. szMapName .. ".Map.Logical"
    else
        szDataFile =
            "data\\source\\maps\\" ..
            szMapName .. "\\" .. szMapName .. ".Map.Logical"
    end

    if Config.bOptickLuaSample then BeginSample("LoadFile") end
    local tData = LoadLogicFileHelper.LoadFile(szDataFile)
    if Config.bOptickLuaSample then EndSample() end

    if not tData then
        OutputMessage("MSG_ANNOUNCE_NORMAL", "对应的逻辑文件不存在" .. UIHelper.GBKToUTF8(szDataFile))
        LOG.ERROR("对应的逻辑文件不存在" .. UIHelper.GBKToUTF8(szDataFile))
        return
    end

    for i, v in pairs(tData.tbData) do
        if v and tbMiddleMapNpcBlackList[tonumber(v.nTempleteID)] == nil then
            local szName = UIHelper.GBKToUTF8(v.szName)
            if szName ~= nil then
                if not MapMgr.tbNPCList[nMapID][szName] then
                    MapMgr.tbNPCList[nMapID][szName] = {}
                end
                table.insert(MapMgr.tbNPCList[nMapID][szName], v)
            end
        end
    end
end


function MapMgr.GetNearestCityID(nMapID, tbPoint)
    local nNearestDis = 99999999999
    local nCityID = 0
    local tbCityList = MapHelper.InitTrafficInfo(nMapID)
    if tbCityList and tbPoint then
        for nIndex, tbInfo in ipairs(tbCityList) do
            local tbTargetPoint = {tbInfo.nX, tbInfo.nY, tbInfo.nZ}
            local nDistance = GetLogicDist(tbPoint, tbTargetPoint)
            if nNearestDis > nDistance then
                nNearestDis = nDistance
                nCityID = tbInfo.dwCityID
            end
        end
    end
    return nCityID
end

function MapMgr.TransferToNearestCity(nQuestID)
    local nMapID, tPointList = QuestData.GetQuestMapIDAndPoints(nQuestID, false)

    local nCityID = MapMgr.GetNearestCityID(nMapID, tPointList)

    local hPlayer = g_pClientPlayer
    if not hPlayer then
        return
    end
    local hScene = hPlayer.GetScene()
    local dwSceneMapID = hScene.dwMapID

    if dwSceneMapID == nMapID then--当前地图直接寻路
        AutoNav.StartAutoNavPoint(dwSceneMapID, tPointList[1], tPointList[2], tPointList[3])
        return
    end

    if nCityID ~= 0 and nMapID then
        local szUseItemTip = string.format(g_tStrings.USE_RESET_ITEM_ACCEPT_QUEST, GBKToUTF8(Table_GetMapName(nMapID)), QuestData.GetQuestName(nQuestID))
        local szTransferTip = string.format(g_tStrings.QUEST_TRANSFER_CONFIRM, GBKToUTF8(Table_GetMapName(nMapID)), QuestData.GetQuestName(nQuestID))
        if not QuestData.IsUnAccept(nQuestID) then
            szUseItemTip = string.format(g_tStrings.USE_RESET_ITEM_CONTINUE_QUEST, GBKToUTF8(Table_GetMapName(nMapID)), QuestData.GetQuestName(nQuestID))
            szTransferTip = string.format(g_tStrings.QUEST_CONTINUE_TRANSFER_CONFIRM, GBKToUTF8(Table_GetMapName(nMapID)), QuestData.GetQuestName(nQuestID))
        end
        MapMgr.TryTransfer(nMapID, nCityID, false, szUseItemTip, szTransferTip, function()
            MapMgr.bAutoNav = true
            MapMgr.nTargetMapID = nMapID
            MapMgr.tbTargetPoint = tPointList
            MapMgr.StartCheckAutoNav()
            local szFrame = QuestData.GetQuestImg(nQuestID)
            MapMgr.SetTracePoint(QuestData.GetQuestName(nQuestID), nMapID, tPointList, nil, szFrame)
        end)
    else
        local tQuestString = Table_GetQuestStringInfo(nQuestID)
        local szQuestName = tQuestString and UIHelper.GBKToUTF8(tQuestString.szName) or ""
        local szMapName = ""
        if nMapID then
            szMapName = UIHelper.GBKToUTF8(Table_GetMapName(nMapID))
            if szMapName ~= "" then
                szMapName = FormatString(g_tStrings.STR_BRACKETS, szMapName)
            end
        end
        local szErrorMsg = FormatString(g_tStrings.STR_QUEST_MAP_TP_FORBIDDEN, szQuestName, szMapName)
        TipsHelper.ShowNormalTip(szErrorMsg)
    end
end

function MapMgr.StartCheckAutoNav()
    MapMgr.StopCheckAutoNav()
    MapMgr.nCheckTimer = Timer.AddFrameCycle(MapMgr, 1, function()
        if not MapMgr.bAutoNav then
            MapMgr.StopCheckAutoNav()
            return
        end
        if not g_pClientPlayer then
            return
        end
        if g_pClientPlayer.nMoveState == MOVE_STATE.ON_RUN then--神行被移动打断了
            MapMgr.bAutoNav = false
            MapMgr.StopCheckAutoNav()
            return
        end
    end)
end

function MapMgr.StopCheckAutoNav()
    if MapMgr.nCheckTimer then
        Timer.DelTimer(MapMgr, MapMgr.nCheckTimer)
        MapMgr.nCheckTimer = nil
    end
end

function MapMgr.CheckAutoStart()
    if MapMgr.bAutoNav then
        local hPlayer = g_pClientPlayer
        if not hPlayer then
            return
        end
        local hScene = hPlayer.GetScene()
        local dwSceneMapID = hScene.dwMapID
        local tbPoint = MapMgr.tbTargetPoint
        if MapMgr.nTargetMapID == dwSceneMapID then
            AutoNav.StartAutoNavPoint(dwSceneMapID, tbPoint[1], tbPoint[2], tbPoint[3])
        end
        MapMgr.bAutoNav = false
    end
end

function MapMgr.CallServerLoadingEnd()
    local hPlayer = GetClientPlayer()
    if not hPlayer then
        return
    end

    local hScene  = GetClientScene()
    if not hScene then
        return
    end

    local dwMapID  = hScene.dwMapID
    local nMapCopy = hScene.nCopyIndex
    local bResult = GDAPI_LoadingEnd(hPlayer, dwMapID, nMapCopy)
    if not bResult then
        return
    end

    RemoteCallToServer("On_Map_LoadingEnd", dwMapID, nMapCopy)
end

--吃鸡寻宝屏蔽处理
function MapMgr.TreasureHuntShield()
    if BattleFieldData.IsInXunBaoBattleFieldMap() then
        MapMgr.bTreasureHuntShield = true

        --屏蔽其他玩家称号
        RLEnv.GetLowerVisibleCtrl():ShowHeadFlag(HEAD_FLAG_OBJ.OTHERPLAYER, HEAD_FLAG_TYPE.TITLE, false)
        Global_UpdateHeadTopPosition()
    elseif MapMgr.bTreasureHuntShield then
        MapMgr.bTreasureHuntShield = false

        --恢复其他玩家称号
        local bOpen = GameSettingData.GetNewValue(UISettingKey.ShowOtherPlayerTitle)
        RLEnv.GetLowerVisibleCtrl():ShowHeadFlag(HEAD_FLAG_OBJ.OTHERPLAYER, HEAD_FLAG_TYPE.TITLE, bOpen)
        Global_UpdateHeadTopPosition()
    end
end

function MapMgr.ClearMonsterAnger()
    MapMgr.tShowMonsterAnger = {}
end

function MapMgr.RefreshHuntEvent(tInfo)
    if not MapMgr.tPQHunt then MapMgr.tPQHunt = {} end
    local tbPQHunt = {}
    for _, v in pairs(tInfo) do
        if v.nDynamicdataID then
            MapMgr.tPQHunt[v.nDynamicdataID] = v
        end
    end
    if table.deepCompare(tbPQHunt, MapMgr.tPQHunt) then
        return
    end
    MapMgr.tPQHunt = tbPQHunt
    Event.Dispatch(EventType.OnRefreshHuntEvent)
end

function MapMgr.ClearHuntEvent(nPQID, bNewPQ)
    if not MapMgr.tPQHunt or MapMgr.tPQHunt[nPQID] == nil then return end
    MapMgr.tPQHunt[nPQID] = nil
    Event.Dispatch(EventType.OnRefreshHuntEvent)
end

function MapMgr.GetPQHuntInfo(nPQID)
    if not MapMgr.tPQHunt then return end
    return MapMgr.tPQHunt[nPQID]
end



--数值显示方式1：分子/分母
function MapMgr.appendType1(nIndex, nValue, tPQInfo)
	local szText   = FormatString(g_tStrings.STR_NEW_PQ_TYPE1, UIHelper.GBKToUTF8(tPQInfo["szValueText"..nIndex]), nValue, tPQInfo["dwValueMax"..nIndex])
	return szText
end

--数值显示方式2：进度条
function MapMgr.appendType2(nIndex, nValue, tPQInfo)
	local szText    = FormatString(g_tStrings.STR_NEW_PQ_TYPE2, nValue, tPQInfo["dwValueMax"..nIndex])
    local szTip = UIHelper.GBKToUTF8(tPQInfo["szValueText"..nIndex]) .. "：" .. szText
    return szTip
end

--数值显示方式3：boss血量（百分比）
function MapMgr.appendType3(nIndex, nValue, tPQInfo)
	local szText    = string.format("%.0f%%", nValue/tPQInfo["dwValueMax"..nIndex]*100)
    local szTip = UIHelper.GBKToUTF8(tPQInfo["szValueText"..nIndex]).. szText
    return szTip
end

--数值显示方式4：倒计时，倒计时的单位是秒
function MapMgr.appendType4(nIndex, nValue, tPQInfo)
	local szTime   = UIHelper.GetCoolTimeText(nValue)
	local szText   = UIHelper.GBKToUTF8(tPQInfo["szValueText"..nIndex])

	szText = szText .. szTime
    return szText
end

--数值显示方式5：倒计时，nValue为结束时间的时间戳
function MapMgr.appendType5(nIndex, nValue, tPQInfo)
	local nLeftTime = math.max(nValue - GetCurrentTime(), 0)
	local szTime    = UIHelper.GetCoolTimeText(nLeftTime)
	local szText    = UIHelper.GBKToUTF8(tPQInfo["szValueText"..nIndex])

	szText = szText .. szTime
    return szText
end

local tAppendValueFunc = {
	[1] = MapMgr.appendType1,
	[2] = MapMgr.appendType2,
	[3] = MapMgr.appendType3,
	[4] = MapMgr.appendType4,
	[5] = MapMgr.appendType5,
}

function MapMgr.AppendTipMod(tValue, tPQInfo)
	if not tValue then
		return
	end
    local szTip = ""
	for k, v in pairs(tValue) do
		local nType = tPQInfo["nValueType"..k]
		if tAppendValueFunc[nType] then
            if szTip == "" then
			    szTip = szTip .. tAppendValueFunc[nType](k, v, tPQInfo)
            else
                szTip = szTip .. "\n" .. tAppendValueFunc[nType](k, v, tPQInfo)
            end
		end
	end
    return szTip
end

function MapMgr.GetHuntInfoTip(tEventInfo)
    local nNewPQID = tEventInfo.nPQID
    local tNewPQInfo = Table_GetNewPQ(nNewPQID)
    local szTip = ""

    local bNewLine = false

    if tEventInfo.tArgs then
        for _, v in pairs(tEventInfo.tArgs) do
            local tCondition = Table_GetMapEventCondition(v.nConditionID)
            if tCondition then
                local szNewline = bNewLine and "\n" or ""
                if bNewLine then bNewLine = false end
                if tCondition.nValueType == 1 then
                    if not v.tValue or type(v.tValue) ~= "table" or IsTableEmpty(v.tValue) then
                        szTip = szTip .. szNewline .. ParseTextHelper.ParseNormalText(UIHelper.GBKToUTF8(tCondition.szContent))
                    else
                        local tbValue = {}
                        for index, value in ipairs(v.tValue) do
                            table.insert(tbValue, UIHelper.GBKToUTF8(value))
                        end
                        szTip = szTip .. "\n" .. FormatString(ParseTextHelper.ParseNormalText(UIHelper.GBKToUTF8(tCondition.szContent)), unpack(tbValue)) or ""
                        bNewLine = true
                    end
                elseif tCondition.nValueType == 2 then
                    local t = {}
                    for _, v2 in pairs(v.tValue) do
                        local nLeftTime = v2 - GetCurrentTime()
                        if nLeftTime < 0 then
                            nLeftTime = 0
                        end
                        local szText    = UIHelper.GetCoolTimeText(nLeftTime)
                        table.insert(t, szText)
                    end
                    szTip = szTip .. szNewline .. FormatString(ParseTextHelper.ParseNormalText(UIHelper.GBKToUTF8(tCondition.szContent)), unpack(t))
                end
            end
        end
    end

    if tEventInfo.tPQValues then
        if szTip == "" then
            szTip = MapMgr.AppendTipMod(tEventInfo.tPQValues, tNewPQInfo)
        else
            szTip = szTip .. "\n" .. MapMgr.AppendTipMod(tEventInfo.tPQValues, tNewPQInfo)
        end
	end
    return szTip
end

-- 初始化角色滤镜
function MapMgr.InitFilter()
    if not g_pClientPlayer then
        return
    end
    SelfieData.ResetFilterFromStorage()
end

function MapMgr.AppendDrawLine(dwMapID, szKey, tbPointStart, tbPointEnd)
    if not MapMgr.tbDrawLine then
        MapMgr.tbDrawLine = {}
    end
    if not MapMgr.tbDrawLine[dwMapID] then
        MapMgr.tbDrawLine[dwMapID] = {}
    end
    if not MapMgr.tbDrawLine[dwMapID][szKey] then
        MapMgr.tbDrawLine[dwMapID][szKey] = {}
    end
    MapMgr.tbDrawLine[dwMapID][szKey] = {tbStart = tbPointStart, tbEnd = tbPointEnd}
    Event.Dispatch(EventType.ON_MAP_DRAW_LINE_ADD, dwMapID, szKey, tbPointStart, tbPointEnd)
end

--根据key删线
function MapMgr.DeleteDrawLineByKey(dwMapID, szKey)
	if MapMgr.tbDrawLine and MapMgr.tbDrawLine[dwMapID] then
        MapMgr.tbDrawLine[dwMapID][szKey] = {}
    end
    Event.Dispatch(EventType.ON_MAP_DRAW_LINE_DELETE, dwMapID, szKey)
end

--根据dwMapID删线
function MapMgr.DeleteDrawLineByMapID(dwMapID)
	if MapMgr.tbDrawLine then
        MapMgr.tbDrawLine[dwMapID] = {}
    end
    Event.Dispatch(EventType.ON_MAP_DRAW_LINE_DELETE, dwMapID)
end

function MapMgr.GetLineByMapID(dwMapID)
    if MapMgr.tbDrawLine == nil then
        return nil
    end
    return MapMgr.tbDrawLine[dwMapID]
end

Event.Reg(MapMgr, EventType.OnRoleLogin, function ()
    MapMgr.bAutoNav = false
end)



Event.Reg(MapMgr, EventType.OnClientPlayerEnter, function(nLogicMapID)
    MapMgr.nCurrentMapID = nLogicMapID
    MapMgr.SetShowQuest(true)
    MapMgr.SetShowShenXing(true)
    MapMgr.SetShowTraffic(true)
end)

Event.Reg(MapMgr, EventType.OnClientPlayerLeave, function()
    local nCurrentID = MapMgr.nCurrentMapID
    local nTraceID = MapMgr.nMapID
    if nCurrentID and Table_IsTreasureBattleFieldMap(nCurrentID) and nTraceID and Table_IsTreasureBattleFieldMap(nTraceID) then
        MapMgr.ClearTracePoint()
    end
    MapMgr.nCurrentMapID = nil
end)

Event.Reg(MapMgr, EventType.UILoadingFinish, function()
    MapMgr.InitFilter()
end)

Event.Reg(MapMgr, EventType.OnViewClose, function(nViewID)
    if nViewID == VIEW_ID.PanelLoading then
        MapMgr.ShowMapTip()
    end
end)

Event.Reg(MapMgr, "QUEST_FINISHED", function(nQuestID, bForceFinish, bAssist, nAddStamina, nAddThew)
    MapMgr.RemoveRedPoint(nQuestID)
end)


Event.Reg(MapMgr, "QUEST_CANCELED", function(nQuestID)
    MapMgr.RemoveRedPoint(nQuestID)
end)


Event.Reg(MapMgr, "ADD_SUMMIT", function(dwID, x, y, z)
    --print("[MapMgr] ADD_SUMMIT", dwID, x, y, z)
    MapMgr.UpdateSprintPoints(true, dwID, x, y, z)
end)

Event.Reg(MapMgr, "REMOVE_SUMMIT", function(dwID, x, y, z)
    --print("[MapMgr] REMOVE_SUMMIT", dwID, x, y, z)
    MapMgr.UpdateSprintPoints(false, dwID, x, y, z)
end)

Event.Reg(MapMgr, "HIGHLIGHT_SUMMIT", function(dwID, bEnable)
    --print("[MapMgr] HIGHLIGHT_SUMMIT", dwID, bEnable)
    if bEnable then
        MapMgr.dwSprintSummitID = dwID
    else
        MapMgr.dwSprintSummitID = 0
    end
end)

Event.Reg(MapMgr, "UPDATE_REGION_INFO", function(nArea)
    MapMgr.nAreaID = nArea

    local dwMapID = g_pClientPlayer.GetMapID()
    local szName = MapHelper.GetMapAreaName(dwMapID, nArea)
    local bShowMapCopy = GDAPI_GetMapCopyInfo(dwMapID) ~= nil
    local szTip = UIHelper.GBKToUTF8(szName)
    if bShowMapCopy then
        local scene = g_pClientPlayer.GetScene()
        if scene then
            local nCopyIndex = scene.nCopyIndex
            if nCopyIndex == 0 then nCopyIndex = 1 end
            szTip = szTip .. string.format(" [%s]线", nCopyIndex)
        end
    end
    if szName ~= "" then
        -- TipsHelper.ShowPlaceYellowTip(UIHelper.GBKToUTF8(szName))
        MapMgr.AddMapTip(szTip, 3, true)
    end
end)

Event.Reg(MapMgr, "UPDATE_MID_MAP_MARK", function(nMapID, nX, nY, nType, szComment)
    if nX == 0 and nY == 0 and nType == -1 then
        MapMgr.RemoveTeamMark()
    else
        MapMgr.SetMapTeamTag(nMapID, nX, nY)
    end
    Event.Dispatch(EventType.OnLeaderChangeTeamTag)
end)

Event.Reg(MapMgr, "PARTY_UPDATE_BASE_INFO", function(dwTeamID, dwLeaderID, nLootMode, nRollQuality, bAddTeamMemberFlag)
    if bAddTeamMemberFlag then
        MapMgr.UpdateMapTeamTag()
    end
end)

Event.Reg(MapMgr, "TEAM_AUTHORITY_CHANGED", function(nAuthorityType, dwTeamID, dwOldAuthorityID, dwNewAuthorityID)
    if nAuthorityType and nAuthorityType == TEAM_AUTHORITY_TYPE.LEADER then
        MapMgr.UpdateMapTeamTag()
    end
end)

Event.Reg(MapMgr, "PARTY_DELETE_MEMBER", function(dwTeamID, dwMemberID, szName, nGroupIndex)
    if g_pClientPlayer and g_pClientPlayer.dwID == dwMemberID then
        MapMgr.UpdateMapTeamTag()
    end
end)

Event.Reg(MapMgr, "PARTY_DISBAND", function(dwTeamID)--团队解散
    MapMgr.UpdateMapTeamTag()
end)