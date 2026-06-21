-- 可以在这个文件里封装一些常用但又不好归类的接口

APIHelper = APIHelper or {className = "APIHelper"}


-- 今天做了某事 -----------------------------------------
function APIHelper.IsDidToday(szKey)
    local bResult = false

    if not string.is_nil(szKey) then
        if Storage.HasDidSomething.tbToday then
            local szValue = Storage.HasDidSomething.tbToday[szKey]
            local szValueToday = os.date("%Y-%m-%d")
            bResult = szValue == szValueToday
        end
    end

    return bResult
end

function APIHelper.DoToday(szKey, bIsUnDo)
    if string.is_nil(szKey) then
        return
    end
    if not Storage.HasDidSomething.tbToday then
        return
    end

    local szValueToday = os.date("%Y-%m-%d")
    Storage.HasDidSomething.tbToday[szKey] = bIsUnDo and "" or szValueToday
    Storage.HasDidSomething.Flush()
    Event.Dispatch(EventType.OnDoSomethingToday, szKey)
end


-- 是否做过某事（一辈子）-----------------------------------------
function APIHelper.IsDid(szKey)
    local bResult = false

    if not string.is_nil(szKey) then
        if Storage.HasDidSomething.tbPermanent then
            bResult = Storage.HasDidSomething.tbPermanent[szKey] == true
        end
    end

    return bResult
end

function APIHelper.Do(szKey, bIsUnDo)
    if string.is_nil(szKey) then
        return
    end
    if not Storage.HasDidSomething.tbPermanent then
        return
    end

    local bValue = true
    if bIsUnDo then bValue = false end
    Storage.HasDidSomething.tbPermanent[szKey] = bValue
    Storage.HasDidSomething.Flush()
    Event.Dispatch(EventType.OnDoSomething, szKey)
end

-- 账号级 今天做了某事 -----------------------------------------
function APIHelper.AccountIsDidToday(szKey)
    local bResult = false

    if not string.is_nil(szKey) then
        if Storage.AccountHasDidSomething.tbToday then
            local szValue = Storage.AccountHasDidSomething.tbToday[szKey]
            local szValueToday = os.date("%Y-%m-%d")
            bResult = szValue == szValueToday
        end
    end

    return bResult
end

function APIHelper.AccountDoToday(szKey)
    if string.is_nil(szKey) then
        return
    end
    if not Storage.AccountHasDidSomething.tbToday then
        return
    end

    local szValueToday = os.date("%Y-%m-%d")
    Storage.AccountHasDidSomething.tbToday[szKey] = szValueToday
    Storage.AccountHasDidSomething.Flush()
    Event.Dispatch(EventType.OnAccountDoSomethingToday, szKey)
end


-- 账号级 是否做过某事（一辈子）-----------------------------------------
function APIHelper.AccountIsDid(szKey)
    local bResult = false

    if not string.is_nil(szKey) then
        if Storage.AccountHasDidSomething.tbPermanent then
            bResult = Storage.AccountHasDidSomething.tbPermanent[szKey] == true
        end
    end

    return bResult
end

function APIHelper.AccountDo(szKey)
    if string.is_nil(szKey) then
        return
    end
    if not Storage.AccountHasDidSomething.tbPermanent then
        return
    end

    Storage.AccountHasDidSomething.tbPermanent[szKey] = true
    Storage.AccountHasDidSomething.Flush()
    Event.Dispatch(EventType.OnAccountDoSomething, szKey)
end


-- 设备级 今天做了某事 -----------------------------------------
function APIHelper.GlobalIsDidToday(szKey)
    local bResult = false

    if not string.is_nil(szKey) then
        if Storage.GlobalHasDidSomething.tbToday then
            local szValue = Storage.GlobalHasDidSomething.tbToday[szKey]
            local szValueToday = os.date("%Y-%m-%d")
            bResult = szValue == szValueToday
        end
    end

    return bResult
end

function APIHelper.GlobalDoToday(szKey)
    if string.is_nil(szKey) then
        return
    end
    if not Storage.GlobalHasDidSomething.tbToday then
        return
    end

    local szValueToday = os.date("%Y-%m-%d")
    Storage.GlobalHasDidSomething.tbToday[szKey] = szValueToday
    Storage.GlobalHasDidSomething.Flush()
    Event.Dispatch(EventType.OnGlobalDoSomethingToday, szKey)
end


-- 设备级 是否做过某事（一辈子）-----------------------------------------
function APIHelper.GlobalIsDid(szKey)
    local bResult = false

    if not string.is_nil(szKey) then
        if Storage.GlobalHasDidSomething.tbPermanent then
            bResult = Storage.GlobalHasDidSomething.tbPermanent[szKey] == true
        end
    end

    return bResult
end

function APIHelper.GlobalDo(szKey)
    if string.is_nil(szKey) then
        return
    end
    if not Storage.GlobalHasDidSomething.tbPermanent then
        return
    end

    Storage.GlobalHasDidSomething.tbPermanent[szKey] = true
    Storage.GlobalHasDidSomething.Flush()
    Event.Dispatch(EventType.OnGlobalDoSomething, szKey)
end

-- 屏蔽
function APIHelper.SetPlayDisplay(tPlayDisplaySetting, bWithTips)
    if not tPlayDisplaySetting then
        return
    end

    local setting = CopyTable(tPlayDisplaySetting)

    if SelfieData.IsInStudioMap() then
        if setting.szDec == GameSettingType.PlayDisplay.All.szDec then
            setting  = GameSettingType.PlayDisplay.OnlyPartyPlay
        end
    end
    GameSettingData.ApplyNewValue(UISettingKey.PlayerDisplay, setting)

    if bWithTips then
        local szTips = ""
        if setting.szDec == GameSettingType.PlayDisplay.OnlyPartyPlay.szDec then
            szTips = "已屏蔽其他玩家，仅显示队友"
        elseif setting.szDec == GameSettingType.PlayDisplay.All.szDec then
            szTips = "已显示所有玩家"
        elseif setting.szDec == GameSettingType.PlayDisplay.HideAll.szDec then
            szTips = "已屏蔽所有玩家"
        end

        if not string.is_nil(szTips) then
            TipsHelper.ShowNormalTip(szTips)
        end
    end
end

-- 切换走路
function APIHelper.SwitchWalk()
    if not g_pClientPlayer then
        return
    end

    if g_pClientPlayer.bHoldHorse then --当玩家在牵马状态的时候，不能切换走/跑
        return
    end

    if g_pClientPlayer.bWalk then
        GameSettingData.ApplyNewValue(UISettingKey.ToggleWalk, GameSettingType.ToggleRunOrWalk.ToggleRun)
        TipsHelper.ShowNormalTip("已关闭走路")
    else
        GameSettingData.ApplyNewValue(UISettingKey.ToggleWalk, GameSettingType.ToggleRunOrWalk.ToggleWalk)
        TipsHelper.ShowNormalTip("已打开走路")
    end
end

----走路方式互斥检查
function APIHelper.WalkModeCheck()
    local bResult = false
    local tbWalkMode = GameSettingData.GetNewValue(UISettingKey.ToggleWalk)
    if tbWalkMode.szDec == GameSettingType.ToggleRunOrWalk.ToggleWalk.szDec then
        bResult = true
    end
    return bResult
end

function APIHelper.GetPlayDisplay()
    return GameSettingData.GetNewValue(UISettingKey.PlayerDisplay)
end

function APIHelper.MainCityLeftBottomPlayDisplayCheck()
    local bResult = false
    local tbData = APIHelper.GetPlayDisplay()
    if tbData.szDec == GameSettingType.PlayDisplay.OnlyPartyPlay.szDec or tbData.szDec == GameSettingType.PlayDisplay.HideAll.szDec then
        bResult = true
    end
    return bResult
end

function APIHelper.QuestTraceFlyTo(nFlyTime, startNode, dwNpcTemplateID)
    if not safe_check(startNode) then
        return
    end

    if not IsNumber(dwNpcTemplateID) then
        return
    end

    local targetNpc = nil
    local npcList = NpcData.GetAllNpc()
    for k, npc in pairs(npcList or {}) do
        if npc.dwTemplateID == dwNpcTemplateID then
            targetNpc = npc
            break
        end
    end

    if not targetNpc then
        return
    end

    local nFromWorldX, nFromWorldY = 0, 0
    if startNode.nX and startNode.nY then
        nFromWorldX, nFromWorldY = startNode.nX, startNode.nY
    else
        nFromWorldX, nFromWorldY = UIHelper.GetWorldPosition(startNode)
    end

    if APIHelper.nCTCID then
        CrossThreadCoor_Unregister(APIHelper.nCTCID)
    end
    APIHelper.nCTCID = CrossThreadCoor_Register(CTCT.GAME_WORLD_2_SCREEN_POS, targetNpc.nX, targetNpc.nY, targetNpc.nZ)

    Timer.DelTimer(APIHelper, APIHelper.nQuestTraceFlyToTimerID)
    APIHelper.nQuestTraceFlyToTimerID = Timer.AddFrame(APIHelper, 1, function()
        local nNpcScreenX, nNpcScreenY, bNpcFront = CrossThreadCoor_Get(APIHelper.nCTCID)

        local nScaleX, nScaleY = UIHelper.GetScreenToResolutionScale()
        local nNpcScreenRealX, nNpcScreenRealY = nNpcScreenX / nScaleX, nNpcScreenY / nScaleY
        local tPos = cc.Director:getInstance():convertToGL({ x = nNpcScreenRealX, y = nNpcScreenRealY })
        local nToWorldX, nToWorldY = tPos.x, tPos.y

        Event.Dispatch(EventType.OnQuestTraceFlyTo, nFlyTime, nFromWorldX, nFromWorldY, nToWorldX, nToWorldY)
    end)


end

--阵营模式
function APIHelper.OpenCloseCamp()
    if not g_pClientPlayer then
        return
    end

    if g_pClientPlayer.bCampFlag then
        --关闭阵营模式
        if g_pClientPlayer.CanCloseCampFlag() then
            RemoteCallToServer("OnCloseCampFlag")
        else
            local nMapID = g_pClientPlayer.GetMapID()
            local _, nMapType, _, _, nCampType = MapMgr.GetMapParams_UIEx(nMapID)
            local szMsg = "已进入关闭状态/当前无法关闭"
            if nCampType == MAP_CAMP_TYPE.FIGHT then
                szMsg = "当前地图为战争区无法关闭阵营模式"
            elseif g_pClientPlayer.bFightState then
                szMsg = "战斗中无法关闭阵营模式"
            else
                local nEndTime = APIHelper.nCampEndTime or 0
                local nCurrentTime = GetCurrentTime()
                local nLeftTime = nEndTime - nCurrentTime
                if nLeftTime > 0 and nLeftTime < 3600 then
                    local szTime = UIHelper.GetHeightestTimeText(nLeftTime)
                    szMsg = FormatString(g_tStrings.STR_SYS_MSG_WAIT_CLOSE_CAMP_FLAG1, szTime)
                end
            end
            OutputMessage("MSG_ANNOUNCE_NORMAL", szMsg)
        end
    else
        --开启阵营模式
        if g_pClientPlayer.CanOpenCampFlag() then
            UIHelper.ShowConfirm(g_tStrings.STR_CONFIRM_MSG_CAMP_FLAG, function()
                RemoteCallToServer("OnOpenCampFlag")
            end)
        else
            if g_pClientPlayer.nCamp == CAMP.NEUTRAL then
                OutputMessage("MSG_ANNOUNCE_NORMAL", "中立阵营无法开启阵营模式")
            else
                OutputMessage("MSG_ANNOUNCE_NORMAL", "当前地图无法开启阵营模式")
            end
        end
    end
end

--切换外装预设
function APIHelper.ChangeOutfit()
    local tbList = CoinShopData.GetOutfitList() or {}
    if table.is_empty(tbList) then
        Event.Dispatch("EVENT_LINK_NOTIFY", "CoinShopMy/Outfit")
        UIMgr.Close(VIEW_ID.PanelQuickOperation)
    else
        if UIMgr.IsViewOpened(VIEW_ID.PanelCharacter) then
            UIMgr.Open(VIEW_ID.PanelAccessory, nil,  3)
        else
            UIMgr.Open(VIEW_ID.PanelCharacter)
            UIMgr.Open(VIEW_ID.PanelAccessory, true,  3)
        end
    end
end

--切换轻功模式
function APIHelper.SwitchQingGong()
    local szSprintMode = GameSettingData.GetNewValue(UISettingKey.SprintMode).szDec
    if szSprintMode == GameSettingType.SprintMode.Classic.szDec then
        APIHelper.SetSprintMode(GameSettingType.SprintMode.Simple, true)
    elseif szSprintMode == GameSettingType.SprintMode.Simple.szDec then
        APIHelper.SetSprintMode(GameSettingType.SprintMode.Common, true)
    elseif szSprintMode == GameSettingType.SprintMode.Common.szDec then
        APIHelper.SetSprintMode(GameSettingType.SprintMode.Classic, true)
    end
end

function APIHelper.SetSprintMode(tSprintModeSetting, bWithTips)
    if not tSprintModeSetting then
        return
    end

    if g_pClientPlayer and g_pClientPlayer.bSprintFlag then
        TipsHelper.ShowNormalTip(g_tStrings.STR_CHANGE_SPRINT_MODE_IN_SPRINT)
        return
    end

    SprintData.SyncServerSprintSetting()
    GameSettingData.ApplyNewValue(UISettingKey.SprintMode, tSprintModeSetting)

    if bWithTips then
        local szTips = ""
        if tSprintModeSetting == GameSettingType.SprintMode.Classic then
            szTips = "轻功模式已切换为：经典轻功。相关设置已跟随改动，可在设置-操作设置-轻功中进行调整。"
        elseif tSprintModeSetting == GameSettingType.SprintMode.Simple then
            szTips = "轻功模式已切换为：简化轻功。相关设置已跟随改动，可在设置-操作设置-轻功中进行调整。"
        elseif tSprintModeSetting == GameSettingType.SprintMode.Common then
            szTips = "轻功模式已切换为：通用轻功。相关设置已跟随改动，可在设置-操作设置-轻功中进行调整。"
        end

        if not string.is_nil(szTips) then
            TipsHelper.ShowNormalTip(szTips)
        end
    end
end

function APIHelper.GetSprintMode()
    return GameSettingData.GetNewValue(UISettingKey.SprintMode)
end

--寻宝互斥检查
function APIHelper.TreasureHuntingCheck()
    local scriptView = UIMgr.GetViewScript(VIEW_ID.PanelMainCity)
    local bOpen = scriptView:HasWidgetItem(TraceInfoType.Compass)
    return bOpen
end
--寻宝
function APIHelper.TreasureHunting(bOpen)
    local scriptView = UIMgr.GetViewScript(VIEW_ID.PanelMainCity)
    local bOpen = scriptView:HasWidgetItem(TraceInfoType.Compass)
    if bOpen then
        Event.Dispatch(EventType.OnTogCompass, false)
    else
        local scene = GetClientScene()
        local dwCurrentMapID = scene.dwMapID
        local bOutScene = not Table_DoesMapHaveTreasure(dwCurrentMapID)
        if bOutScene then
            -- OutputMessage("MSG_SYS", Craft_GetCantOpenCompassInSceneMsg())
            TipsHelper.ShowNormalTip("当前场景不能感应到宝藏点")
        else
            Event.Dispatch(EventType.OnTogCompass, true)
            RemoteCallToServer("OnHoroSysDataRequest")
        end
    end
end

--摆擂
function APIHelper.OpenChallenge()
    local bOpen = Player_IsBuffExist(ChallengeData.LEI_TAI_BUFF_ID)
    if bOpen then
        if Player_IsBuffExist(ChallengeData.PK_BUFF_ID) then
            OutputMessage("MSG_ANNOUNCE_NORMAL", g_tStrings.CAN_NOT_RETRACT)
        else
            RemoteCallToServer("On_PK_PackUp")
        end
    else
        local player = GetClientPlayer()
        local nCDLeft = player.GetCDLeft(ChallengeData.BAI_LEI_ID)
        if nCDLeft > 0 then
            OutputMessage("MSG_ANNOUNCE_NORMAL", g_tStrings.PK_CD_MSG)
        else
            RemoteCallToServer("On_PK_TryBaiTan")
        end
    end
end

--侠客互斥检查 true => 显示召回 false => 显示召请
function APIHelper.PartnerSummonCheck()
    --- 侠客召请、召回界面改版整合为同时显示，永远显示召请页面
    local bShowRecall = false
    return bShowRecall
end

--侠客召请/召回
function APIHelper.PartnerSummon()
    Event.Dispatch(EventType.OpenPartnerSummonPanelForSummon)
end

--共鸣互斥检查
function APIHelper.PartnerMorphCheck()
    return PartnerData.bShowMorphInMainCity
end

--战斗数据互斥检查
function APIHelper.StatistVisibilityCheck()
    return Storage.HurtStatisticSettings["IsStatisticOpen"]
end

--战斗数据互斥检查
function APIHelper.FocusVisibilityCheck()
    return Storage.HurtStatisticSettings["IsStatisticOpen"]
end

function APIHelper.WhoSeeMeVisibilityCheck()
    return Storage.HurtStatisticSettings["IsSeeMeOpen"]
end

--宠物互斥检查
function APIHelper.PetCheck()
    return Storage.CustomBtn.bHaveFellowPet
end

function APIHelper.FellowPet(bOpen)
    if bOpen then
        UIMgr.Open(VIEW_ID.PanelQuickOperationBagNormal, true)
    else
        RemoteCallToServer("On_FellowPet_Dissolution")
    end
end

--屏蔽npc互斥检查
function APIHelper.NpcDisplayCheck()
    return not RLEnv.GetActiveVisibleCtrl().bShowNpc
end

-- 屏蔽npc
function APIHelper.SetNpcDisplay()
    ToggleNpc()

    local szTips = ""
    if APIHelper.NpcDisplayCheck() then
        szTips = "已屏蔽所有NPC"
    else
        szTips = "已显示所有NPC"
    end

    if not string.is_nil(szTips) then
        TipsHelper.ShowNormalTip(szTips)
    end
end

--开启同模互斥检查
function APIHelper.CampUniformCheck()
    return not QualityMgr.IsCampUniform()
end

function APIHelper.SetWindowTitle()
    if not Platform.IsWindows() then
        return
    end

    local moduleServerList = LoginMgr.GetModule(LoginModule.LOGIN_SERVERLIST)
    if not moduleServerList then
        return
    end

    local tServer = moduleServerList.GetSelectServer()
    if tServer == nil then
        tServer = {szServer = "", szRealServer = "", szDisplayRegion = "",}
        local tbRecentServer = moduleServerList.LoadRecentLoginServer()
        if tbRecentServer then
            tServer.szServer = tbRecentServer.szServer
            tServer.szRealServer = tbRecentServer.szServer
            tServer.szDisplayRegion = tbRecentServer.szRegion
        end
    end

    local szServer, szRealServer, szDisplayRegion = UTF8ToGBK(tServer.szServer), UTF8ToGBK(tServer.szRealServer), UTF8ToGBK(tServer.szDisplayRegion)

	local szVersionName = select(5, GetVersion())
    if string.is_nil(szVersionName) then
        return
    end

    local szTitle = szVersionName

    if szServer then
        szTitle = szVersionName .. " - " .. szServer
        if szRealServer ~= szServer then
            szTitle = szTitle .. "(" .. tostring(szRealServer) .. ")"
        end
        szTitle = szTitle .. " @ " .. (szDisplayRegion)
    end

    SetWindowTitle(szTitle)
end

---comment 是否主城场景
---@param nMapID integer|nil 场景模板ID，如果为nil则判断玩家当前所在场景
---@return boolean
function APIHelper.IsMainCityScene(nMapID)
    -- 如果nMapID为空，就拿当前场景
    if nMapID then
        return table.contain_value(MAIN_CITY_MAP_IDS, nMapID)
    else
        local scene = GetClientScene()
        if scene then
            return table.contain_value(MAIN_CITY_MAP_IDS, scene.dwMapID)
        end
    end
    return false
end

-- 是否为多人场景
function APIHelper.IsMultiPlayerScene(nMapID)
    local bResult = false

    -- 如果nMapID为空，就拿当前场景
    if not nMapID then
        local scene = GetClientScene()
        if scene then
            nMapID = scene.dwMapID
        end
    end

    if nMapID then
        bResult = table.contain_value(MULTI_PLAYER_MAP_IDS, nMapID)
    end

    return bResult
end

function APIHelper.IsMinimize()
    if not Platform.IsWindows() then
        return false
    end

    local tScreenSize = UIHelper.GetScreenSize()
    return tScreenSize.width < 0.01 and tScreenSize.height < 0.01
end

function APIHelper.IsHaveSecondRepresent()
    if not g_pClientPlayer then
        return false
    end

    local dwBox, dwX = INVENTORY_INDEX.EQUIP, EQUIPMENT_INVENTORY.CHEST
    local hItemSource = g_pClientPlayer.GetItem(dwBox, dwX)
    if not hItemSource then
        return false
    end
    local bHaveSecondRepresent = g_pClientPlayer.IsHaveSecondRepresent(dwBox, dwX)
    return bHaveSecondRepresent
end

function APIHelper.IsInSecondRepresent()
    if not g_pClientPlayer then
        return false
    end

    return g_pClientPlayer.IsSecondRepresent(INVENTORY_INDEX.EQUIP, EQUIPMENT_INVENTORY.CHEST)
end

function APIHelper.GetNpcLODLvl()
    local nLodLvl = APIHelper.nNpcLodLvl or 1
    local bitLod = kmath.lShiftOperator(1, nLodLvl) -- 使用 LOD 1
    return bitLod
end

function APIHelper.SetNpcLODLvl(nLvl)
    APIHelper.nNpcLodLvl = nLvl
end

-- 设置是否可以显示战力提示
function APIHelper.SetCanShowEquipScore(bCanShow)
    APIHelper.bCanShowEquipScore = bCanShow
end

-- 获取是否可以显示战力提示
function APIHelper.GetCanShowEquipScore()
    return APIHelper.bCanShowEquipScore
end

-- 验证邮箱
function APIHelper.OpenURL_VerifyMail()
    UIHelper.OpenWeb(tUrl.EmailBind , false , true)
    --[[
    if Platform.IsWindows() or Platform.IsMac() then
        WebUrl.OpenByID(42)
    else
        WebUrl.OpenByID(43)
    end
    ]]
end

-- 验证手机
function APIHelper.OpenURL_VerifyPhone()
    if Global.bIsEnterGame then
        if Platform.IsWindows() or Platform.IsMac() then
            WebUrl.OpenByID(46)
        else
            WebUrl.OpenByID(44)
        end
    else
        if Platform.IsWindows() or Platform.IsMac() then
            WebUrl.OpenByID(47)
        else
            WebUrl.OpenByID(45)
        end
    end
end

-- 帮会改名
function APIHelper.OpenURL_TongChangeName()
    if Platform.IsWindows() or Platform.IsMac() then
        WebUrl.OpenByID(38)
    else
        WebUrl.OpenByID(39)
    end
end

-- 转服等
function APIHelper.OpenURL_PlayerReserve()
    UIHelper.OpenWeb(tUrl.RoleRelate , false , true)
    --[[
    if Platform.IsWindows() or Platform.IsMac()then
        WebUrl.OpenByID(40)
    else
        WebUrl.OpenByID(41)
    end
    ]]
end

function APIHelper.SetUsePendantAction(nTime)
    APIHelper.bUsePendantAction = true

    nTime = nTime or 0.5
    Timer.DelTimer(APIHelper, APIHelper.nUserPendantActionTimerID)
    APIHelper.nUserPendantActionTimerID = Timer.Add(APIHelper, nTime, function()
        APIHelper.bUsePendantAction = false
    end)
end

function APIHelper.IsUsePendantAction()
    return APIHelper.bUsePendantAction
end

function APIHelper.CountChineseAndEnglish(str)
    local chineseCount = 0
    local englishCount = 0
    if not string.is_nil(str) then
        for i = 1, #str do
            local c = string.sub(str, i, i)
            if c:match("[%z\1-\127]") then -- ASCII字符（包括空格）
                englishCount = englishCount + 1
            else
                chineseCount = chineseCount + 1
            end
        end
    end
    return math.floor(chineseCount/3), englishCount
end

-- 是否显示系统公告
function APIHelper.IsShowSystemAnnouncement()
    return GameSettingData.GetNewValue(UISettingKey.ScrollingAnnouncement)
end

-- 是否是18岁成人
function APIHelper.IsShowBarMitzvah()
	if not g_pClientPlayer then
		return false
	end

	local nValue = g_pClientPlayer.GetExtPoint(EXT_POINT.BAR_MITZVAH) or 0
	return nValue ~= 0  --只有扩展点的值不为0时才需要显示，否则都不需要
end

-- 是否可以使用萌新频道 (746为1 或者 736为0可以使用萌新频道)
function APIHelper.CanUseIdentityChatChannel()
	if not g_pClientPlayer then
		return false
	end

    local bResult = g_pClientPlayer.GetExtPoint(746) == 1 or g_pClientPlayer.GetExtPoint(736) == 0
	return bResult
end

-- 等Loading结束后去做某些事情
function APIHelper.WaitLoadingFinishToDo(callback)
    if not IsFunction(callback) then
        return
    end

    if SceneMgr.IsLoading() then
        if APIHelper.tbWaitList == nil then
            APIHelper.tbWaitList = {}
        end

        table.insert(APIHelper.tbWaitList, callback)

        Event.Reg(APIHelper, EventType.UILoadingFinish, function()
            Event.UnReg(APIHelper, EventType.UILoadingFinish)

            for k, v in ipairs(APIHelper.tbWaitList or {}) do
                if IsFunction(v) then
                    v()
                end
            end

            APIHelper.tbWaitList = nil
        end)
        return
    end

    callback()
end

-- 显示更多操作tips
function APIHelper.ShowMoreOperTips(node, tbBtnParams, nOffsetX, nOffsetY)
    if not node then return end
    if table.is_empty(tbBtnParams) then return end

    local nX, nY = UIHelper.GetWorldPosition(node)
    local tips, scriptTips = TipsHelper.ShowClickHoverTips(PREFAB_ID.WidgetTipMoreOper, nX, nY, tbBtnParams)
    scriptTips:OnEnter(tbBtnParams)
    local w, h = UIHelper.GetContentSize(scriptTips.LayoutMoreOper)
    UIHelper.SetContentSize(scriptTips._rootNode, w, h)
    if nOffsetX then nX = nX + nOffsetX end
    if nOffsetY then nY = nY + nOffsetY end
    tips:Show(nX, nY)
end

-- 根据ID判断是否是自己
function APIHelper.IsSelf(dwID)
    local bIsSelf = (dwID == UI_GetClientPlayerID())
    return bIsSelf
end

function APIHelper.IsSelfByGlobalID(szGlobalID)
    local bIsSelf = (szGlobalID == UI_GetClientPlayerGlobalID())
    return bIsSelf
end

-- 聊天面板是否打开，并且且当前选中的频道是 szUIChannel
function APIHelper.IsChatInUIChannel(szUIChannel)
    local bResult = false
    local chatScript = nil

    local nChatIndex = 1
    local scriptSocial = UIMgr.GetViewScript(VIEW_ID.PanelChatSocial)
    if scriptSocial and scriptSocial:IsSelected(nChatIndex) then
        chatScript = scriptSocial.tbScripts[nChatIndex]
        if chatScript then
            if szUIChannel == chatScript:GetCurUIChannel() then
                bResult = true
            end
        end
    end

    return bResult, chatScript
end

-- 获取聊天的脚本
function APIHelper.GetChatViewScript()
    local chatScript = nil

    local nChatIndex = 1
    local scriptSocial = UIMgr.GetViewScript(VIEW_ID.PanelChatSocial)
    if scriptSocial and scriptSocial:IsSelected(nChatIndex) then
        chatScript = scriptSocial.tbScripts[nChatIndex]
    end

    return chatScript
end

-- 处理富文本链接跳转
function APIHelper.HandleRichTextLink(szUrl, node)
    if string.is_nil(szUrl) then
        return
    end

    szUrl = UrlDecode(szUrl)

    szUrl = string.gsub(szUrl, "\\", "/")
    local szLinkEvent, szLinkArg = szUrl:match("(%w+)/(.*)")

    if szLinkEvent == "WebURL" then
        local nLinkID = tonumber(szLinkArg)
        WebUrl.OpenByID(nLinkID)
    elseif szLinkEvent == "ItemLinkInfo" then
        local szType, szID = szLinkArg:match("(%d+)/(%d+)")
        local dwType       = tonumber(szType)
        local dwID         = tonumber(szID)
        TipsHelper.ShowItemTips(node, dwType, dwID)
    elseif szLinkEvent == "NPCGuide" then
        local tLinkInfo = Table_GetCareerLinkNpcInfo(szLinkArg)
        local szText = UIHelper.GBKToUTF8(tLinkInfo.szNpcName)
        MapMgr.SetTracePoint(szText, tLinkInfo.dwMapID, {tLinkInfo.fX, tLinkInfo.fY, tLinkInfo.fZ})
        UIMgr.Open(VIEW_ID.PanelMiddleMap, tLinkInfo.dwMapID, 0)
    elseif szLinkEvent == "OperationActivity" then
    else
        Event.Dispatch("EVENT_LINK_NOTIFY", szUrl)
    end
end

function APIHelper.BeginCameraAnimation(dwID, bHideUI, bEnableWord)
    LOG.INFO("APIHelper.BeginCameraAnimation, dwID = %d, bHideUI = %s, bEnableWord = %s", tostring(dwID), tostring(bHideUI), tostring(bEnableWord))

    if bHideUI then
        APIHelper.bBeginCameraAnimationHideUI = true
        Event.Dispatch(EventType.SetKeyBoardEnableByCustomState, true)
        UIMgr.HideAllLayer()

        if not UIMgr.IsLayerVisible(UILayer.Scene) then
            UIMgr.ShowLayer(UILayer.Scene)
            APIHelper.bShowSceneWhenBeginCameraAni = true
        end

        -- 因为有可能在进入镜头动画后，战斗结束或者失败或者掉线退出场景，会导致UI看不见的问题，所以这里要解锁一下
        Event.Reg(APIHelper, "LOADING_END", function()
            Event.UnReg(APIHelper, "LOADING_END")
            LOG.INFO("APIHelper.BeginCameraAnimation, end camera animation by loading end.")
            APIHelper.EndCameraAnimation()
        end)

        Event.Reg(APIHelper, EventType.OnAccountLogout, function()
            Event.UnReg(APIHelper, EventType.OnAccountLogout)
            LOG.INFO("APIHelper.BeginCameraAnimation, end camera animation by logout.")
            APIHelper.EndCameraAnimation()
        end)
    else
        APIHelper.bBeginCameraAnimationHideUI = false
    end
end

function APIHelper.EndCameraAnimation()
    LOG.INFO("APIHelper.EndCameraAnimation")
    if APIHelper.bBeginCameraAnimationHideUI then
        if APIHelper.bShowSceneWhenBeginCameraAni then
            APIHelper.bShowSceneWhenBeginCameraAni = nil
            UIMgr.HideLayer(UILayer.Scene)
        end
        UIMgr.ShowAllLayer()
        Event.Dispatch(EventType.SetKeyBoardEnableByCustomState, false)
        APIHelper.bBeginCameraAnimationHideUI = false

        Event.UnReg(APIHelper, "LOADING_END")
        Event.UnReg(APIHelper, EventType.OnAccountLogout)
    end
end

function APIHelper.ShowRule(nRuleID)
    UIMgr.Open(VIEW_ID.PanelHelpPop, nRuleID)
end