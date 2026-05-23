Global = Global or {
    className = "Global",
    nLogicMapID = 0,
}
-- 缓存客户端自己角色
g_pClientPlayer = g_pClientPlayer

local self = Global
self._tLastPlayerDisplayData = {} -- 用于判断数据是否有变化
local mfloor, mmin, mmax, mceil = math.floor, math.min, math.max, math.ceil
local g2u = UIHelper.GBKToUTF8
local u2g = UIHelper.UTF8ToGBK

function FireHelpEvent(...)
    -- local argSave = {}
    -- local arg = {...}
    -- for nIndex, value in ipairs(arg) do
    -- 	argSave[nIndex] = _G["arg" .. nIndex - 1]
    -- 	_G["arg" .. nIndex - 1] = arg[nIndex]
    -- end

    FireUIEvent("HELP_EVENT", ...)

    -- for nIndex, value in ipairs(argSave) do
    -- 	_G["arg" .. nIndex - 1] = argSave[nIndex]
    -- end
end

Global.nNetMode = App_GetNetMode()

-------------------- 临时消息屏蔽黑名单
local _tMsgShieldBlackList = {
    "声望",
}
function Global.IsThereKeyOfShielding(szUtf8)
    for i = 1, #_tMsgShieldBlackList do
        if string.find(szUtf8, _tMsgShieldBlackList[i]) then
            return true
        end
    end
    return false
end

-------------------- 全局事件监听 beg -----------------------

--- 仅在批量修改帮会成员组的最后一批时尝试弹出修改成功提示
Global.bLastBatchChangeTongMemberGroup = false

-- 帮会事件 {{{{
Event.Reg(Global, "TONG_EVENT_NOTIFY", function()
    --- 针对帮会批量变更成员组的分批处理，仅在最后一批的时候尝试弹出提示，避免刷多次
    if arg0 == TONG_EVENT_CODE.CHANGE_MEMBER_GROUP_SUCCESS and not Global.bLastBatchChangeTongMemberGroup then
        return
    end

    local v = g_tStrings.STR_GUILD_ERROR[arg0] or { g_tStrings.tGuildRenameEventCode[arg0] or "", "MSG_SYS" }
    if v and v[1] ~= "" then
        if type(arg1) == "string" and arg1 ~= "" then
            local szText = string.gsub(v[1], "<link 0>", "[" .. g2u(arg1) .. "]")
            TipsHelper.OutputMessage(v[2], szText)
        else
            TipsHelper.OutputMessage(v[2], v[1])
        end
    end
end)

Event.Reg(Global, "ON_COIN_BUY_RESPOND", function()
    Global.OnCoinBuyRespond(arg0)
    GetTongClient().ApplyTongInfo()
end)


function Global.OnCoinBuyRespond(nType)
    local szRespond = g_tStrings.tCoinBuyRespond[nType]
    OutputMessage("MSG_SYS", szRespond)
end


-- 帮会事件 }}}}

Event.Reg(Global, "FIRST_LOADING_END", function()
    Table_GetItemDesc(0)

    local player = GetClientPlayer()
    local AvatarMgr = player.GetMiniAvatarMgr()
    if not AvatarMgr.bDataSynced then
        AvatarMgr.ApplyMiniAvatarData()
    end

    SetModelTopBarSize() -- 初始化字体表现
end)


-- Event.Reg(Global, "PLAYER_TALK", function ()
-- 	self.OnPlayerTalk("PLAYER_TALK", nil, arg0, arg1, arg2, arg3, arg4, arg5, arg6, arg7, arg8 or 0, arg11)
-- end)

Event.Reg(Global, "PLAYER_DISPLAY_DATA_UPDATE", function()
    if PlayerData.IsSelf(arg0) then
        self.OnPlayerDisplayDataUpdate()
    end
    UpdatePlayerTitleEffect(arg0)
    self.OnUpdatePlayerDesignation(arg0)
end)

Event.Reg(Global, "ON_CAPTION_ICON_TYPE_CHANGED", function()
	UpdatePlayerTitleEffect(arg0)
end)

Event.Reg(Global, "EQUIP_ITEM_UPDATE", function(nInventoryIndex, nEquipmentInventory)
    if not g_pClientPlayer then
        return
    end

    if TreasureBattleFieldSkillData.IsInDynamic() then
        if nInventoryIndex == INVENTORY_INDEX.EQUIP and
        (nEquipmentInventory == EQUIPMENT_INVENTORY.MELEE_WEAPON or
        nEquipmentInventory == EQUIPMENT_INVENTORY.AMULET or
        nEquipmentInventory == EQUIPMENT_INVENTORY.PENDANT) then
            RemoteCallToServer("On_JueJing_ExchangeEquip", nInventoryIndex, nEquipmentInventory)
        end
    end

    if not BattleFieldData.IsInMobaBattleFieldMap() then
        if nInventoryIndex == 0 and nEquipmentInventory == 0 then
            return
        end
    else
        --- moba玩法中购买装备时，会在服务器切换装备，这里设置下提示战力变化标记
        APIHelper.SetCanShowEquipScore(true)
    end

    self.OnPlayerDisplayDataUpdate()
end)

Event.Reg(Global, "PARTY_DISBAND", function()
    UpdatePartyMark()
end)

Event.Reg(Global, "PARTY_SET_MARK", function()
    UpdatePartyMark()
end)

Event.Reg(Global, "PARTY_UPDATE_MEMBER_INFO", function()
    local hPlayer = GetClientPlayer()
    if not hPlayer then
        return
    end
    if arg1 == hPlayer.dwID then
        UpdatePartyMark()
    end
end)

Event.Reg(Global, "PARTY_DELETE_MEMBER", function()
    local hPlayer = GetClientPlayer()
    if not hPlayer then
        return
    end
    if arg1 == hPlayer.dwID then
        UpdatePartyMark()
    end
end)

local m_tLastPartyMarkList = {}
function UpdatePartyMark(bRefresh)
    local tMarkList = {}
    local hPlayer = GetClientPlayer()
    if not hPlayer then
        return
    end

    if OBDungeonData.IsPlayerInOBDungeon() then
        tMarkList = GetClientTeam().GetTeamMarkExceptTeamID() or {}
    elseif hPlayer.IsInParty() then
        tMarkList = GetClientTeam().GetTeamMark() or {}
    end


    if bRefresh then
        m_tLastPartyMarkList = {}
    end

    for dwID, dwMarkID in pairs(tMarkList) do
        if m_tLastPartyMarkList[dwID] then
            if m_tLastPartyMarkList[dwID] ~= dwMarkID then
                UpdateTitleEffect(dwID)
            end
            m_tLastPartyMarkList[dwID] = nil
        else
            UpdateTitleEffect(dwID)
        end
    end

    for dwID, dwMarkID in pairs(m_tLastPartyMarkList) do
        UpdateTitleEffect(dwID)
    end

    m_tLastPartyMarkList = tMarkList
end

function UpdateTitleEffect(dwID)
    if IsPlayer(dwID) then
        UpdatePlayerTitleEffect(dwID)
    else
        NpcData.UpdateTitleEffect(dwID)
    end
end

-- 核心事件的逻辑不支持重载
-- 逻辑模块对事件时序有要求, 需要优先处理事件
if not g_bIsReloading then
    Event.Reg(self, "SET_MAIN_PLAYER", function(nPlayerID)
        -- 更新本地角色
        if nPlayerID == 0 then
            g_pClientPlayer = nil
            Event.Dispatch(EventType.OnClientPlayerLeave)
            self.nLogicMapID = 0
        else
            g_pClientPlayer = GetClientPlayer()     ---@type KPlayer 角色
            self.nLogicMapID = g_pClientPlayer.GetMapID()
            Event.Dispatch(EventType.OnClientPlayerEnter, self.nLogicMapID)
        end
    end)

    Event.Reg(self, EventType.OnClientPlayerEnter, function()
        Global.OnPlayerDisplayDataUpdate()
    end)

    Event.Reg(self, "PLAYER_LEAVE_GAME", function(nPlayerID)
        self.bIsEnterGame = false
        self._tLastPlayerDisplayData = {} -- 清理记录,

        BubbleMsgData.Reset()
        PropsSort.Reset()
        rlcmd("on disconnect")
    end)
    Event.Reg(self, "NPC_ENTER_SCENE", function(nNpcID)
        NpcData.OnNpcEnter(nNpcID)
        PublicQuestData.OnNpcEnter(nNpcID)
    end)
    Event.Reg(self, "NPC_LEAVE_SCENE", function(nNpcID)
        NpcData.OnNpcLeave(nNpcID)
        PublicQuestData.OnNpcLeave(nNpcID)
    end)

end

Event.Reg(Global, "ANNOUNCE_TALK", function()
    Global.OnAnnounceTalk("ANNOUNCE_TALK")
end)

Event.Reg(Global, "SYS_MSG", function()
    local szEvent = arg0
    Global.OnSysMsgEvent(szEvent)
end)

Event.Reg(Global, "ON_AWARD_NOTIFY", function(nCode)
    if nCode == AWARD_RESEAON.ReturnItem then
        Global.bRecevingAward = true
        Global.tAwardBuffer = {}
        Global.tAwardBuffer.nAwardDeltaGold = 0
        Global.tAwardBuffer.nAwardDeltaSilver = 0
        Global.tAwardBuffer.nAwardDeltaCopper = 0
        Global.tAwardBuffer.nAwardDeltaJustice = 0
        Global.tAwardBuffer.nLastUpdateJustice = 0
        Global.tAwardBuffer.nAwardDeltaContribution = 0
        Global.tAwardBuffer.nAwardDeltaExamPrint = 0
        Global.tAwardBuffer.nAwardDeltaArenaAward = 0
        Global.tAwardBuffer.nAwardDeltaPrestige = 0
        Global.tAwardBuffer.nAwardDeltaArchitecture = 0
        Global.tAwardBuffer.tAwardItemList = {}
    else
        Global.bRecevingAward = false
        local szRichTextContent = ""
        local nMoney = PackMoney(Global.tAwardBuffer.nAwardDeltaGold, Global.tAwardBuffer.nAwardDeltaSilver, Global.tAwardBuffer.nAwardDeltaCopper)
        if nMoney.nGold > 0 or nMoney.nSilver > 0 or nMoney.nCopper > 0 then
            szRichTextContent = szRichTextContent .. UIHelper.GetMoneyText(nMoney, 30)
        end
        local fPackCurrencyText = function(nCurrency, szIconFileName)
            if nCurrency > 0 then
                szRichTextContent = szRichTextContent .. UIHelper.GetCurrencyText(nCurrency, szIconFileName, 30)
            end
        end
        fPackCurrencyText(Global.tAwardBuffer.nAwardDeltaJustice, ShopData.CurrencyCode2TexObj[ShopData.CurrencyCode.Justice])
        --fPackCurrencyText(self.tAwardBuffer.nAwardDeltaContribution, ShopData.CurrencyCode2Tex[ShopData.CurrencyCode.Contribution])
        --fPackCurrencyText(self.tAwardBuffer.nAwardDeltaExamPrint, ShopData.CurrencyCode2Tex[ShopData.CurrencyCode.ExamPrint])
        fPackCurrencyText(Global.tAwardBuffer.nAwardDeltaArenaAward, ShopData.CurrencyCode2TexObj[ShopData.CurrencyCode.ArenaCoin])
        fPackCurrencyText(Global.tAwardBuffer.nAwardDeltaPrestige, ShopData.CurrencyCode2TexObj[ShopData.CurrencyCode.Prestige])
        fPackCurrencyText(Global.tAwardBuffer.nAwardDeltaArchitecture, ShopData.CurrencyCode2TexObj[ShopData.CurrencyCode.Architecture])

        for _, tItemPack in ipairs(Global.tAwardBuffer.tAwardItemList) do
            local item = GetItem(tItemPack.nItemId)
            if item then
                local szPath = UIHelper.GetIconPathByItemInfo(item, true)
                szRichTextContent = szRichTextContent ..tItemPack.nCount.."<img src='" .. szPath .. "' width='70' height='70' type='0'/>"
            end
        end
        -- 当前版本屏蔽了所有的全屏奖励
        -- UIHelper.ShowConfirm(szRichTextContent, function()

        -- end, function()

        -- end, true)
    end
end)

Event.Reg(Global, "MONEY_UPDATE", function()
    if arg3 then
        local tMoney = PackMoney(arg0, arg1, arg2)

        if Global.bRecevingAward then
            Global.tAwardBuffer.nAwardDeltaGold = tMoney.nGold
            Global.tAwardBuffer.nAwardDeltaSilver = tMoney.nSilver
            Global.tAwardBuffer.nAwardDeltaCopper = tMoney.nCopper
        end

        if MoneyOptCmp(tMoney, 0) ~= 1 then
            return
        end

        if not self.CanShowRewardList() then
            return
        end

        TipsHelper.ShowRewardList({
            { nItemId = 0, nCount = tMoney }
        })

    end
end)

Event.Reg(Global, "UPDATE_VIGOR", function()
    local nOldVigor = arg0
    local hPlayer = GetClientPlayer()
    if not hPlayer then
        return
    end
    local nDeltaVigor = hPlayer.nVigor - nOldVigor
    if nDeltaVigor < 0 then
        --local szMsg = FormatString(g_tStrings.STR_CRAFT_COST_VIGOR_ENTER, -nDeltaVigor)
        --OutputMessage("MSG_THEW_STAMINA", szMsg)

        --教学 消耗精力
        FireHelpEvent("OnVigorChange", nDeltaVigor)
    elseif nDeltaVigor > 0 then
        --local szMsg = FormatString(g_tStrings.STR_CRAFT_ADD_VIGOR_ENTER, nDeltaVigor)
        --OutputMessage("MSG_THEW_STAMINA", szMsg)

        --教学 消耗精力
        FireHelpEvent("OnVigorChange", nDeltaVigor)
    end
end)

Event.Reg(Global, "UPDATE_JUSTICE", function(nOldJustice)
    if Global.bRecevingAward and Global.tAwardBuffer.nLastUpdateJustice ~= nOldJustice then
        Global.tAwardBuffer.nLastUpdateJustice = nOldJustice
        Global.tAwardBuffer.nAwardDeltaJustice = Global.tAwardBuffer.nAwardDeltaJustice + GetClientPlayer().nJustice - nOldJustice
    end

    --教学 获取侠义值
    if GetClientPlayer().nJustice > nOldJustice then
        FireUIEvent("CURRENCY_GET", "OnGetJustice")
    end
end)

Event.Reg(Global, "UPDATE_CONTRIBUTION", function(nPreContribution, nContribution)
    if Global.bRecevingAward then
        Global.tAwardBuffer.nAwardDeltaContribution = Global.tAwardBuffer.nAwardDeltaContribution + nContribution - nPreContribution
    end

    --教学 获得贡献
    if GetClientPlayer().nContribution > nPreContribution then
        FireUIEvent("CURRENCY_GET", "OnGetContribution")
    end
end)

Event.Reg(Global, "UPDATE_EXAMPRINT", function(nOldExamPrint)
    if Global.bRecevingAward then
        Global.tAwardBuffer.nAwardDeltaExamPrint = Global.tAwardBuffer.nAwardDeltaExamPrint + GetClientPlayer().nExamPrint - nOldExamPrint
    end

    --教学 获取监本印文
    if GetClientPlayer().nExamPrint > nOldExamPrint then
        FireUIEvent("CURRENCY_GET", "OnGetExamPrint")
    end
end)

Event.Reg(Global, "UPDATE_ARENAAWARD", function(nOldArenaAward)
    if Global.bRecevingAward then
        Global.tAwardBuffer.nAwardDeltaArenaAward = Global.tAwardBuffer.nAwardDeltaArenaAward + GetClientPlayer().nArenaAward - nOldArenaAward
    end

    --教学 获取名剑币
    if GetClientPlayer().nArenaAward > nOldArenaAward then
        FireUIEvent("CURRENCY_GET", "OnGetArenaAware")
    end
end)

Event.Reg(Global, "UPDATE_PRESTIGE", function(nOldPrestige)
    if Global.bRecevingAward then
        Global.tAwardBuffer.nAwardDeltaPrestige = Global.tAwardBuffer.nAwardDeltaPrestige + GetClientPlayer().nCurrentPrestige - nOldPrestige
    end

    --教学 获取威望值
    if GetClientPlayer().nCurrentPrestige > nOldPrestige then
        FireUIEvent("CURRENCY_GET", "OnGetPrestige")
    end
end)

Event.Reg(Global, "UPDATE_ARCHITECTURE", function(nOldArchitecture)
    if Global.bRecevingAward then
        Global.tAwardBuffer.nAwardDeltaArchitecture = Global.tAwardBuffer.nAwardDeltaArchitecture + GetClientPlayer().nArchitecture - nOldArchitecture
    end
end)

Event.Reg(Global, "TITLE_POINT_UPDATE", function(nNewTitlePoint, nAddTitlePoint)
    --教学 获取第一次获取战阶积分
    if nAddTitlePoint > 0 then
        FireUIEvent("CURRENCY_GET", "OnGetPointTitle")
    end
end)

Event.Reg(Global, "UPDATE_ACHIEVEMENT_COUNT", function()
    if not g_pClientPlayer then
        return
    end

    --教学 获取江湖资历
    local nValue = g_pClientPlayer.GetAchievementRecord()
    if nValue > 0 then
        FireUIEvent("CURRENCY_GET", "OnGetJHZILI")
    end
end)

Event.Reg(Global, "SYNC_COIN", function()
    if not g_pClientPlayer then
        return
    end

    --教学 获取通宝
    local nValue = g_pClientPlayer.nCoin
    if nValue > 0 then
        FireUIEvent("CURRENCY_GET", "OnGetCoin")
    end
end)

Event.Reg(Global, "ON_SYNC_TA_EQUIPS_SCORE", function()
    if not g_pClientPlayer then
        return
    end

    --教学 获取师徒装备分数
    local nValue = g_pClientPlayer.dwTAEquipsScore
    if nValue > 0 then
        FireUIEvent("CURRENCY_GET", "OnGetMentorScore")
    end
end)

Event.Reg(Global, "DISTRIBUTE_ITEM", function(arg0, arg1, arg2)
    AuctionData.OnPlayerDistributeItem(arg0, arg1, arg2)
end)

Event.Reg(Global, "LOOT_ITEM", function()
    AuctionData.OnPlayerLootItem(arg0, arg1, arg2)
    local nPlayerId = arg0
    local nItemId = arg1
    local nCount = arg2 or 1

    local player = GetClientPlayer()
    if not player or player.dwID ~= nPlayerId then
        return
    end

    if Global.bRecevingAward then
        table.insert(self.tAwardBuffer.tAwardItemList, { nItemId = nItemId, nCount = nCount })
    end

    --教学 道具获得
    FireHelpEvent("OnGetItem", nItemId)

    if not self.CanShowRewardList() then
        return
    end

    TipsHelper.ShowRewardList({
        { nItemId = nItemId, nCount = nCount }
    })

end)

Event.Reg(Global, "BAG_ITEM_UPDATE", function()
    local dwBox = tonumber(arg0)
    local dwX = tonumber(arg1)
    local bNew = arg2

    if bNew then
        local player = GetClientPlayer()
        if not player then
            return
        end
        local item = PlayerData.GetPlayerItem(player, dwBox, dwX)
        if not item then
            return
        end

        if BattleFieldData.IsInTreasureBattleFieldMap() and SceneMgr.IsLoading() then
            return
        end

        if ItemData.IsBanUseItem(item) then
            return
        end

        -- 快速穿装备
        if item.nQuality > 0
                and item.nGenre == ITEM_GENRE.EQUIPMENT
                and IsSafisfyEquipRequire(item, true, player) then
            local itemInfo = GetItemInfo(item.dwTabType, item.dwIndex)
            if not item.bSystemFlag and ((IsItemFitKungfu(itemInfo) and IsBetterEquipment(item)) or IsBetterBag(item)) and not ItemData.IsBanUseItem(item) then

                if not self.tbNewEquipItem then self.tbNewEquipItem = {} end--装备
                if not self.tbNewBagItem then self.tbNewBagItem = {} end--扩充背包

                if itemInfo.nSub == EQUIPMENT_SUB.PACKAGE then
                    table.insert(self.tbNewBagItem, {dwBox = dwBox, dwX = dwX})
                else
                    table.insert(self.tbNewEquipItem, {dwBox = dwBox, dwX = dwX})
                end

                if not self.nTimerShowQuickEquipTip then
                    self.nTimerShowQuickEquipTip = Timer.Add(Global, 0.5, function()

                        if #self.tbNewEquipItem >= 1 then
                            TipsHelper.ShowQuickEquipTip(self.tbNewEquipItem)
                        end

                        if #self.tbNewBagItem >= 1 then--背包提示一个一个弹，否则一键全部装备会有bug
                            for nIndex, tbBag in ipairs(self.tbNewBagItem) do
                                TipsHelper.ShowQuickEquipTip({tbBag})
                            end
                            -- TipsHelper.ShowQuickEquipTip(self.tbNewBagItem)
                        end

                        self.tbNewEquipItem = {}
                        self.tbNewBagItem = {}
                        self.nTimerShowQuickEquipTip = nil
                    end)
                end
            end
        end

        local bTreasureBF = TreasureBattleFieldData.GetQuickEquipInfo(item)
        if bTreasureBF then
            TipsHelper.ShowQuickEquipTip({{dwBox = dwBox, dwX = dwX}})
        end
    end
end)

Event.Reg(Global, EventType.UILoadingStart, function(nMapID)
    Global.m_bInLoading = true
    Global.ChangeClientPerfState()
    NotifyPakV5EnterScene(nMapID)
end)

Event.Reg(Global, EventType.UILoadingFinish, function(nMapID)
    Global.m_bInLoading = false
    Global.ChangeClientPerfState()
    if nMapID then
        NotifyPakV5LoadingSceneFinish(nMapID)
    else
        NotifyPakV5LeaveScene(0)
    end
end)

Event.Reg(Global, "LOADING_END", function()
    self.bIsEnterGame = true -- 表示是否进入到游戏场景（登录创角这些不算）

    local player = GetClientPlayer()
    if not player then
        return
    end

    if not Storage_Server.GetData(STORAGE_KEY_ENUM.NotFirstEnterGame) then
        Storage_Server.SetData(STORAGE_KEY_ENUM.NotFirstEnterGame, true)
        Global.InitFirstLoginSkill()
    end

    local AvatarMgr = player.GetMiniAvatarMgr()
    if not AvatarMgr.bDataSynced then
        AvatarMgr.ApplyMiniAvatarData()
    end

    -- 发送帮会上线通知
    TongData.ShowTongMessage()

    -- 进入地图提示
    local dwMapID = player.GetMapID()
    if dwMapID then
        if dwMapID == 247 then
		    RemoteCallToServer("On_Activity_MHDXPlay", player.dwID)
        end

        local szMapName = UIHelper.GBKToUTF8(Table_GetMapName(dwMapID))
        if szMapName ~= "" then
            -- TipsHelper.ShowPlaceBlueTip(UIHelper.GBKToUTF8(szMapName))
            local _, _, _, _, nCampType = GetMapParams(dwMapID)
            local bShowMapCopy = GDAPI_GetMapCopyInfo(dwMapID) ~= nil
            if bShowMapCopy then
                local scene = g_pClientPlayer.GetScene()
                if scene then
                    local nCopyIndex = scene.nCopyIndex
                    if nCopyIndex == 0 then nCopyIndex = 1 end
                    szMapName = szMapName .. string.format(" [%s]线", nCopyIndex)
                end
            end
            MapMgr.AddMapTip(szMapName, WORLD_MAP_TIP_COLOR[nCampType], false)
        end
    end

    UpdatePartyMark(true)

    -- 同步装备ID列表
    RemoteCallToServer("OnSyncEquipIDArray")

    -- 同步家具套装收集状态
    --player.ApplySetCollection()

    -- 跳场景，这些传送副本的倒计时要移出
	BubbleMsgData.RemoveMsg("guild")
    BubbleMsgData.RemoveMsg("tong_dif")
    BubbleMsgData.RemoveMsg("party_copy")
    BubbleMsgData.RemoveMsg("refresh_copy")

    PropsSort.Reset()

    --- 没有剩余时长的账号进行游戏内界面弹窗推送，每日最多弹一次
    do
        -- 2024-07-19 07:00:00
        local nStartTime = 1721343600
        -- 2024-07-22 07:00:00
        local nEndTime = 1721602800

        local nCurrentTime = Global.Get_719_722_CurrentTime()
        if nCurrentTime >= nStartTime and nCurrentTime < nEndTime then
            local _, _, _, nFeeEndTime = Login_GetTimeOfFee()

            local bHasTime = nFeeEndTime > nCurrentTime
            if not bHasTime then
                if not APIHelper.IsDidToday("ChargeHintPop") then
                    APIHelper.DoToday("ChargeHintPop")

                    --- 延迟一会，确保能放在各种弹窗最上面
                    Timer.Add(Global, 0.3, function()
                        UIMgr.Open(VIEW_ID.PanelChargeHintPop)
                    end)
                end
            end
        end
    end
end)

function Global.Get_719_722_CurrentTime()
    return GetCurrentTime()
end

Event.Reg(Global, "OPEN_WINDOW", function(dwIndex, szText, dwTargetType, dwTargetID, bNewWindow, dwCameraID)
    local npc = GetNpc(dwTargetID)
    local nPlotType = bNewWindow and PLOT_TYPE.NEW or PLOT_TYPE.OLD
    if dwTargetType == TARGET.NPC and (npc and (npc.dwTemplateID == 494 or npc.dwTemplateID == 495 or npc.dwTemplateID == 496 or npc.dwTemplateID == 5926)) then
        UIMgr.Open(VIEW_ID.PanelCopyCommit, szText, dwTargetType, dwTargetID)
    else
        PlotMgr.OpenPanel(nPlotType, dwIndex, szText, dwTargetType, dwTargetID, dwCameraID)
    end

end)

Event.Reg(Global, "OPEN_SWITCH_MAP_WINDOW", function(dwWindowID, dwTargetType, dwTargetID)
    local tMapInfoList = DungeonData.GetMapInfoListByWindowID(dwWindowID)
    if not SceneMgr.IsLoading() and tMapInfoList and #tMapInfoList > 0 then
        local tMapInfo = tMapInfoList[1]
        if #tMapInfoList == 1 and tMapInfo.nMapType == 1 then
            if not UIMgr.IsViewOpened(VIEW_ID.PanelDungeonDetail) then
                UIMgr.Open(VIEW_ID.PanelDungeonDetail, dwWindowID, tMapInfo)
            end
        elseif not UIMgr.IsViewOpened(VIEW_ID.PanelSwitchMap) then
            UIMgr.Open(VIEW_ID.PanelSwitchMap, dwWindowID, tMapInfoList)
            AutoNav.OnOpenSwitchMapWindow()
        end
    end
end)

Event.Reg(Global, "ON_FORCE_SYNC_PLAYER_MAP_PROGRESS", function(dwMapID, nCopyIndex, nLeftTime, tpbyProgress)
    if not dwMapID or not nCopyIndex or not tpbyProgress then return end
    UIMgr.Open(VIEW_ID.PanelDungeonChallengeSync, dwMapID, nCopyIndex, nLeftTime, tpbyProgress)
end)

Event.Reg(Global, "PLAYER_EXIT_GAME", function()
    UIMgr.ReportOpenedViewList()
    LogoutGame()
end)

Event.Reg(Global, "OnNetModeChanged", function(nNetMode)
    Log("[Global] OnNetModeChanged", Global.nNetMode, nNetMode, App_GetNetMode())
    if Global.nNetMode == NET_MODE.CELLULAR and nNetMode == NET_MODE.WIFI then
        TriggerReconnect()
    elseif nNetMode == NET_MODE.NONE then
        TriggerReconnect()
    end

    Global.nNetMode = nNetMode
end)

Event.Reg(Global, "DISCONNECT", function(bNeedReconnect)
    Log("DISCONNECT event callback")

    if bNeedReconnect then
        TipsHelper.ShowNormalTip(g_tStrings.STR_MSG_LOGIN_DROPLINE)

        if not UIMgr.IsViewOpened(VIEW_ID.PanelWaittingWithDarkBg) then
            Log("Open VIEW_ID.PanelWaittingWithDarkBg on RECONNECT event")
            local tMsg = {
                szWaitingMsg = g_tStrings.tbLoginString.RECONNECTING,            -- 文本提示
                bHidePage = false,                      -- 是否隐藏UI的Page层
                bSwallow = true,                        -- 是否吞噬点击事件
                nPriority = 10
            }
            UIMgr.Open(VIEW_ID.PanelWaittingWithDarkBg, tMsg)
        end
    else
        local funcShowDisconnect = function()
            local confirm = UIHelper.ShowSystemConfirm(g_tStrings.tbLoginString.CONNECT_GAME_SERVER_FAILED, function()
                Global.BackToLogin(false)
            end)

            confirm:SetConfirmButtonContent("返回登录界面")
            confirm:HideButton("Cancel")
        end

        if PSMMgr.IsEnterPSMMode() then
            self.bNeedShowDisconnectAfterPSM = true
            return
        end

        funcShowDisconnect()
    end

    if LoginMgr.IsWaiting() then
        LoginMgr.SetWaiting(false)
    end
end)

Event.Reg(Global, "RECONNECT_SUCCESS", function()
    Log("RECONNECT_SUCCESS event. Close VIEW_ID.PanelWaittingWithDarkBg")
    UIMgr.Close(VIEW_ID.PanelWaittingWithDarkBg)
end)

Event.Reg(Global, "KICK_ACCOUNT", function()
    g_tbLoginData.bKickAccount = true
    g_tbLoginData.nKickAccountReason = LOAD_LOGIN_REASON.KICK_OUT_BY_OTHERS
    Global.BackToLogin(false)

    if Platform.IsWindows() then
        XGSDK.UpdateNeedSuccessNotify("被顶号(windows)", false)
    end

    if Channel.Is_WLColud() then
        -- 在蔚领云游戏中被顶号的话，需要通知云游戏app去退出本次游戏
        LOG.DEBUG("蔚领云版本游戏被顶号，通知云游戏app")
        XGSDK_WLCloud_OnGameKickAccount(true, "你的账号正在其他地方登录。如有任何疑问可通过在线客服咨询。")
    end
end)

Event.Reg(Global, "ShowBindPhoneMsgBox", function()
    if not UIMgr.IsViewOpened(VIEW_ID.PanelSystemConfirm) then
        UIHelper.ShowSystemConfirm(g_tStrings.BIND_PHONE_TIPS, function()
            APIHelper.OpenURL_VerifyPhone()
        end)
    end
end)

Event.Reg(Global, "SWITCH_GS_NOTIFY", function()
    ClearConfigCache(KCACHE_CLEAR_STAGE.ccsSwitchMap)
end)

Event.Reg(Global, "UI_LUA_RESET", function()
    ResetGameworld()

    SceneMgr.DeleteCurScene()
    SceneMgr.SetScene(nil)

    CameraMgr.UnInit()
    LoginMgr.Clear()

    TipsHelper:UnInit()
    UIMgr.CloseAll()
    UIMgr.Reset()

    CameraMgr.Init()

    g_tbLoginData.szCurrentStep = nil
    g_tbLoginData.bAutoLogin = false

    Timer.AddFrame(self, 1, function()
        GC.FullGC(true)     -- 先执行一遍完整GC，一遍能正确清理缓存数据
        ClearConfigCache(KCACHE_CLEAR_STAGE.ccsResetGame)

        LoginMgr.SwitchStep(LoginModule.LOGIN_SCENE)
        if Config.bGM then
            UIMgr.Open(VIEW_ID.PanelGMBall)
        end
    end)
end)

Event.Reg(Global, "INVITE_JOIN_TONG_REQUEST", function(dwInviterID, dwTongID, szInviterName, szTongName)
    -- TipsHelper.ShowPlaceYellowTip(string.format("TODO（帮会系统）: dwInviterID=%d dwTongID=%d szInviterName=%s szTongName=%s 邀请你加入帮会",
    -- 		dwInviterID, dwTongID, UIHelper.GBKToUTF8(szInviterName), UIHelper.GBKToUTF8(szTongName)))
    TongData.OnInviteJoinTong(dwInviterID, dwTongID, szInviterName, szTongName)
end)

Event.Reg(Global, "ON_INVITE_PLAYER_JOIN_ASURA_TEAM_REQEUST", function(dwInviterID, cszInviterName, dwAsuraTeamID, cszTeamName)
    TipsHelper.ShowPlaceYellowTip(string.format("TODO（帮会系统）: dwInviterID=%d cszInviterName=%d dwAsuraTeamID=%s cszTeamName=%s 邀请你加入修罗队",
            dwInviterID, UIHelper.GBKToUTF8(cszInviterName), dwAsuraTeamID, UIHelper.GBKToUTF8(cszTeamName)))
end)

Event.Reg(Global, "APPLY_DUEL", function(dwSrcPlayerID)
    if not IsRegisterEvent("APPLY_DUEL") then
        -- 与端游保持一致，在勿扰选项开启时，直接无视切磋请求，不做任何操作
        return
    end

    if FellowshipData.IsInBlackListByPlayerID(dwSrcPlayerID) then
        GetClientPlayer().RefuseDuel()
        return
    end

    local ClientPlayer = GetClientPlayer()
    local player = GetPlayer(dwSrcPlayerID)
    local ePKState = ClientPlayer.GetPKState()

    local fnAutoCloseTrade = function()
        local ePKState = GetClientPlayer().GetPKState()
        if ePKState ~= PK_STATE.CONFIRM_DUEL then
            return true
        end
    end

    if player and player.dwID ~= ClientPlayer.dwID and ePKState == PK_STATE.CONFIRM_DUEL then
        if IsFilterOperate("PLAYER_APPLYDUEL") then
            GetClientPlayer().RefuseDuel()
            return
        end

        local szMessage = FormatString(g_tStrings.STR_PK_DUEL_INVITE, UIHelper.GBKToUTF8(player.szName))
        local fnConfirm = function()
            GetClientPlayer().AcceptDuel()
            -- BubbleMsgData.RemoveMsg("PKDuelInviteTip")
        end
        local fnCancel = function()
            GetClientPlayer().RefuseDuel()
            -- BubbleMsgData.RemoveMsg("PKDuelInviteTip")
        end
        local tbInfo = {
            -- szTitle = FormatString(tStringInfo[nInviteType], ""),
            szType = "PKDuelInviteTip",
            szInviterName = player.szName,
            fnConfirmAction = function()
                fnConfirm()
            end,
            fnCancelAction = function()
                fnCancel()
            end,
            fnAutoClose = fnAutoCloseTrade
        }
        TipsHelper.ShowInteractTip(tbInfo)
        -- BubbleMsgData.PushMsgWithType("PKDuelInviteTip", {
        --     nBarTime = 0, -- 显示在气泡栏的时长, 单位为秒
        --     szContent = szMessage,
        --     szAction = function()
        --         local dialog = UIHelper.ShowConfirm(szMessage, fnConfirm, fnCancel)
        --         dialog:SetAutoClose(fnAutoCloseTrade)
        --     end,
        --     fnAutoClose = fnAutoCloseTrade
        -- })
    end
end)

Event.Reg(Global, "SYNC_PLAYER_REVIVE", function(bReviveInSite, bReviveInAlter, bReviveByPlayer, bReviveByCustom, nLeftReviveFrame, dwReviver, nMessageID, nReviveUIType, nCustomData)
    --- 打开复活界面
    ReviveMgr.OpenRevivePanel(bReviveInSite, bReviveInAlter, bReviveByPlayer, bReviveByCustom, nLeftReviveFrame, dwReviver, nMessageID, nReviveUIType, nCustomData)

    --- 保存下复活参数，以便出现意外情况时重新拉起
    ReviveMgr.SaveParameters(bReviveInSite, bReviveInAlter, bReviveByPlayer, bReviveByCustom, nLeftReviveFrame, dwReviver, nMessageID, nReviveUIType, nCustomData)
end)

-- 头顶Buff显示
Event.Reg(Global, "BUFF_UPDATE", function()
    if not GameSettingData.GetNewValue(UISettingKey.ShowDungeonHeadBuff) then
        return
    end

    local owner, bdelete, index, cancancel, id = arg0, arg1, arg2, arg3, arg4
    local player = GetClientPlayer()
    if not player then
        return
    end
    local bIsPlayerBuff = owner == player.dwID
    local obj
    if bIsPlayerBuff then
        obj = player
    else
        local npc = GetNpc(owner)
        if npc and (npc.nIntensity == 6 or DungeonData.IsInDungeon()) then
            obj = npc
        end
    end
    if obj then
        local tBuffList = {}
        local nBuffCount = obj.GetBuffCount()
        local nCurrentFrame = GetLogicFrameCount()
        if nBuffCount and nBuffCount > 0 then
            local dwID, nLevel, bCanCancel, nEndFrame, nIndex, nStackNum, dwSkillSrcID, bValid, bIsStackable, nLeftFrame
            for i = nBuffCount, 1, -1 do
                dwID, nLevel, bCanCancel, nEndFrame, nIndex, nStackNum, dwSkillSrcID, bValid, bIsStackable, nLeftFrame = obj.GetBuff(i - 1)
                local tBuffTab = dwID and Table_GetBuff(dwID, nLevel)
                local bShow = tBuffTab and tBuffTab.bMbIsShow
                if bShow then
                    table.insert(tBuffList, { ['dwID'] = dwID, ['nLevel'] = nLevel, ['bCanCancel'] = bCanCancel, ['nEndFrame'] = nEndFrame
                    , ['nIndex'] = nIndex, ['nStackNum'] = nStackNum, ['dwSkillSrcID'] = dwSkillSrcID, ['bValid'] = bValid, ['nLeftFrame'] = nEndFrame - nCurrentFrame })
                    if #tBuffList >= 2 then
                        break
                    end
                end

                -- 创意食品Buff提示
                if dwID == 17365 and bIsPlayerBuff then
                    local tBuff = { ['dwID'] = dwID, ['nLevel'] = nLevel, ['bCanCancel'] = bCanCancel, ['nEndFrame'] = nEndFrame
                    , ['nIndex'] = nIndex, ['nStackNum'] = nStackNum, ['dwSkillSrcID'] = dwSkillSrcID, ['bValid'] = bValid, ['nLeftFrame'] = nEndFrame - nCurrentFrame }
                    Event.Dispatch(EventType.OnShowSpecialEnhanceBuff, tBuff)
                end
            end
        end

        Event.Dispatch(EventType.OnShowCharacterHeadBuff, owner, tBuffList)
    end
end)

-------------------- 双人同骑事件 -----------------------

Event.Reg(Global, "FOLLOW_RESPOND", function(nCode)
    local szMsg = g_tStrings.tFollowRespond[nCode]
    OutputMessage("MSG_SYS", szMsg)
    OutputMessage("MSG_ANNOUNCE_NORMAL", szMsg)
end)

Event.Reg(Global, "FOLLOW_INVITE", function(szInviterName, nFollowType, nInviteType, nFollowIndex, nMemberIndex)
    print("[FOLLOW_INVITE]", szInviterName, nFollowType, nInviteType, nMemberIndex)
    if not IsRegisterEvent("FOLLOW_INVITE") then
        GetClientPlayer().FollowInviteRespond(false, nFollowType, nInviteType, nFollowIndex, nMemberIndex)
        return
    end

    if FellowshipData.IsInBlackListByName(szInviterName) then
        GetClientPlayer().FollowInviteRespond(false, nFollowType, nInviteType, nFollowIndex, nMemberIndex)
        return
    end
    -- local tStringInfo = g_tStrings.tInviteType[nFollowType]
    local tbInfo = {
        -- szTitle = FormatString(tStringInfo[nInviteType], ""),
        szType = "FollowInviteTip",
        szInviterName = szInviterName,
        nFollowType = nFollowType,
        nInviteType = nInviteType,
        nFollowIndex = nFollowIndex,
        fnConfirmAction = function()
            GetClientPlayer().FollowInviteRespond(true, nFollowType, nInviteType, nFollowIndex, nMemberIndex)
        end,
        fnCancelAction = function()
            GetClientPlayer().FollowInviteRespond(false, nFollowType, nInviteType, nFollowIndex, nMemberIndex)
        end
    }
    if nFollowType == FOLLOW_TYPE.GROUPRIDE then
        tbInfo.nAutoConfirmTime = 5
    end
    TipsHelper.ShowInteractTip(tbInfo)
end)

Event.Reg(Global, "FOLLOW_STOP", function(nCode, szName)
    OutputMessage("MSG_SYS", FormatString(g_tStrings.tFollowStopType[nCode], UIHelper.GBKToUTF8(szName)))
end)

Event.Reg(Global, "PLAYER_ENTER_SCENE", function(dwPlayerID)
    if g_pClientPlayer and g_pClientPlayer.dwID == dwPlayerID then
        local tTime = TimeLib.GetTodayTime()
        local hCalendar = GetActivityMgrClient()
        local tActivityList = hCalendar.GetActivityOfDayEx(tTime.year, tTime.month, tTime.day)
        for _, tActivity in ipairs(tActivityList) do
            for _, tTime in ipairs(tActivity.TimeInfo) do
                Scene_AddSwitchesEvent(tActivity.dwID, tTime.nStartTime, tTime.nEndTime)
            end
        end
    end
end)

-------------------- 称号事件 -----------------------

Event.Reg(Global, "SET_CURRENT_DESIGNATION", function(dwID)
    self.OnUpdatePlayerDesignation(dwID)
end)

Event.Reg(Global, "SYNC_DESIGNATION_DATA", function(dwID)
    self.OnUpdatePlayerDesignation(dwID)
end)

Event.Reg(Global, "SYNC_ROLE_DATA_END", function()
    self.OnUpdatePlayerDesignation()
end)

Event.Reg(Global, "ACQUIRE_DESIGNATION", function(nPrefix, nPostfix)
    self.OnAcuireDesignation(nPrefix, nPostfix)
end)

Event.Reg(Global, "DESIGNATION_ANNOUNCE", function(szName, nPrifix, nPostfix, nChannel)
    self.OnDesignationAnnounce(szName, nPrifix, nPostfix, nChannel)
end)

Event.Reg(Global, "SET_GENERATION_NOTIFY", function(dwID, nGeneration, nCharacter)
    self.OnSetDesignationGeneration(dwID, nGeneration, nCharacter)
end)

Event.Reg(Global, "REMOVE_DESIGNATION", function(nPrefix, nPostfix)
    self.OnRemoveDesignation(nPrefix, nPostfix)
end)

-------------------- 千里伐逐事件 -----------------------

Event.Reg(Global, "ON_PVP_FIELD_QUEUE_JOIN_NOTIFY", function(nResultCode)
    if nResultCode == PVP_FIELD_RESULT_CODE.SUCCESS then
        OutputMessage("MSG_SYS", g_tStrings.STR_PVP_FIELD_RESULT_JOIN_SUCCESS_TIP)
        OutputMessage("MSG_ANNOUNCE_NORMAL", g_tStrings.STR_PVP_FIELD_RESULT_JOIN_SUCCESS_TIP)
    elseif g_tStrings.STR_PVP_FIELD_RESULT_NEED_MAP_NAME_TIP[nResultCode] then
        local szMsg = FormatString(g_tStrings.STR_PVP_FIELD_RESULT_NEED_MAP_NAME_TIP[nResultCode], Table_GetSwitchServerMapName())
        if szMsg then
            OutputMessage("MSG_SYS", szMsg)
            OutputMessage("MSG_ANNOUNCE_RED", szMsg)
        end
    else
        local szMsg = g_tStrings.STR_PVP_FIELD_RESULT_TIP[nResultCode]
        if szMsg then
            OutputMessage("MSG_SYS", szMsg)
            OutputMessage("MSG_ANNOUNCE_NORMAL", szMsg)
        end
    end
end)

Event.Reg(Global, "ON_PVP_FIELD_QUEUE_LEAVE_NOTIFY", function(nResultCode)
    if nResultCode == PVP_FIELD_RESULT_CODE.SUCCESS then
        OutputMessage("MSG_SYS", g_tStrings.STR_PVP_FIELD_RESULT_LEAVE_SUCCESS_TIP)
        OutputMessage("MSG_ANNOUNCE_NORMAL", g_tStrings.STR_PVP_FIELD_RESULT_LEAVE_SUCCESS_TIP)
    elseif g_tStrings.STR_PVP_FIELD_RESULT_NEED_MAP_NAME_TIP[nResultCode] then
        local szMsg = FormatString(g_tStrings.STR_PVP_FIELD_RESULT_NEED_MAP_NAME_TIP[nResultCode], Table_GetSwitchServerMapName())
        if szMsg then
            OutputMessage("MSG_SYS", szMsg)
            OutputMessage("MSG_ANNOUNCE_RED", szMsg)
        end
    else
        local szMsg = g_tStrings.STR_PVP_FIELD_RESULT_TIP[nResultCode]
        if szMsg then
            OutputMessage("MSG_SYS", szMsg)
            OutputMessage("MSG_ANNOUNCE_NORMAL", szMsg)
        end
    end
end)

-----------------------

Event.Reg(Global, EventType.OnOpenChapters, function(dwChapterID, tTime1, tTime2, tTime3, tTime4, tTime5, nAlpha)
    UIMgr.Open(VIEW_ID.PanelPassage, dwChapterID, tTime1, tTime2, tTime3, tTime4, tTime5, nAlpha)
end)

Event.Reg(Global, EventType.OPEN_BOOK_NOTIFY, function(nBookID, nSubID, nItemID, nRecipeID, nTargetType)
    local scriptView = UIMgr.Open(VIEW_ID.PanelBookInfo, nBookID, nSubID, nRecipeID, nItemID, nTargetType)
    scriptView:OnEnter(nBookID, nSubID, nRecipeID, nItemID, nTargetType)
end)

Event.Reg(self, "CHANGE_DYNAMIC_SKILL_GROUP", function(dwOldGroupID, dwNowGroupID, dwGroupType)
    QTEMgr.OnSwitchDynamicSkillState(dwNowGroupID ~= 0, dwOldGroupID, dwNowGroupID, dwGroupType)
end)

Event.Reg(self, EventType.CloseLevelUpPanel, function(bCloseLevelUpPanel)
    self.bCloseLevelUpPanel = bCloseLevelUpPanel
end)

--- 控制某些功能是否开启
--- 当对应key的值为true时，表示该功能开启
--- 若为false或nil，则表示关闭
--- 从 ui/Config/Default/GlobalEventHandler.lua 搬过来的
local m_tRegisterEvent = {}

--- 某功能是否启用.
--- ps: 不知道为什么叫这个函数名，不过为了方便定位到端游代码，这里函数名保持不变
function IsRegisterEvent(event)
    return m_tRegisterEvent[event or ""]
end

local function OnShieldEvent(szEventKey, bEnable)
    if bEnable and not m_tRegisterEvent[szEventKey] then
        -- 启用这个功能
        m_tRegisterEvent[szEventKey] = true
        --this:RegisterEvent(szEventKey)
    elseif not bEnable and m_tRegisterEvent[szEventKey] then
        -- 禁用这个功能
        m_tRegisterEvent[szEventKey] = nil
        --this:UnRegisterEvent(szEventKey)
    end
end

-- 基于 m_tRegisterEvent 来控制是否启用的一些功能的key列表
local m_tRegisterEventKeyList = {
    "TRADING_INVITE",
    "APPLY_DUEL",
    "PLAYER_BE_ADD_FELLOWSHIP",
    "INVITE_JOIN_TONG_REQUEST",
    "FOLLOW_INVITE",
    "PARTY_INVITE_REQUEST",
    "PARTY_APPLY_REQUEST",
    "EMOTION_ACTION_REQUEST",
    "GLOBAL_ROOM_JOIN_REQUEST",
}

local function InitRegisterEvent()
    for _, szEventKey in ipairs(m_tRegisterEventKeyList) do
        local szEventName = "ENABLE_" .. szEventKey

        -- 默认开启
        m_tRegisterEvent[szEventKey] = true

        -- 注册状态变更事件
        Event.Reg(Global, szEventName, function(bEnable)
            OnShieldEvent(szEventKey, bEnable)
        end)
    end
end

InitRegisterEvent()

function ResetRegisterEvent()
    m_tRegisterEvent = {}
    InitRegisterEvent()
end

Event.Reg(self, EventType.OnAccountLogout, function()
    ResetRegisterEvent()
    ResetFilterOperate()
end)

-------------------- 全局事件监听 end -----------------------

---comment 获取当前逻辑场景ID
---@return integer
function Global.GetLogicMapID()
    return self.nLogicMapID
end

function Global.BackToLogin(bReLogin)
    XGSDK_TrackLogoutRole()
    g_FirstMoviePlayed = nil

    if not bReLogin then
        local loginAccount = LoginMgr.GetModule(LoginModule.LOGIN_ACCOUNT)
        if loginAccount then
            loginAccount.ClearLogin()
        end
    end

    g_tbLoginData.bReLoginToRoleListFlag = bReLogin
    UIMgr.Close(VIEW_ID.PanelSystemMenu)
    SoundMgr.StopBgMusic()
    TeachEvent.CloseAllTeach()
    UIHelper.ExitHideAllUIMode()
    UIHelper.ClearAnnouncement()
    OnBackToLogin()
    Event.Dispatch(EventType.OnAccountLogout, bReLogin)
end

local m_nEndFrame, m_CalculaPKType, m_nLastShowSecond
local m_bOpenSkillEffectLog = true
function Global.OnSysMsgEvent(event)
    if arg0 == "UI_OME_SKILL_CAST_LOG" then
        FightLog.OnSkillCast(arg1, arg2, arg3)
    elseif arg0 == "UI_OME_SKILL_CAST_RESPOND_LOG" then
        FightLog.OnSkillCastRespond(arg1, arg2, arg3, arg4)
    elseif arg0 == "UI_OME_SKILL_EFFECT_LOG" then
        if m_bOpenSkillEffectLog then
            FightLog.OnSkillEffectLog(arg1, arg2, arg3, arg4, arg5, arg6, arg7, arg8, arg9)
        end
    elseif arg0 == "UI_OME_SKILL_BLOCK_LOG" then
        FightLog.OnSkillBlockLog(arg1, arg2, arg3, arg4, arg5, arg6)
    elseif arg0 == "UI_OME_SKILL_BLOCK_LONG_RANGE_LOG" then
        FightLog.OnSkillBlockLongRangeLog(arg1, arg2, arg3, arg4, arg5)
    elseif arg0 == "UI_OME_SKILL_SHIELD_LOG" then
        FightLog.OnSkillShieldLog(arg1, arg2, arg3, arg4, arg5)
    elseif arg0 == "UI_OME_SKILL_MISS_LOG" then
        FightLog.OnSkillMissLog(arg1, arg2, arg3, arg4, arg5)
    elseif arg0 == "UI_OME_SKILL_HIT_LOG" then
        FightLog.OnSkillHitLog(arg1, arg2, arg3, arg4, arg5)
    elseif arg0 == "UI_OME_SKILL_DODGE_LOG" then
        FightLog.OnSkillDodgeLog(arg1, arg2, arg3, arg4, arg5)
    elseif arg0 == "UI_OME_COMMON_HEALTH_LOG" then
        FightLog.OnCommonHealthLog(arg1, arg2)
    elseif arg0 == "UI_OME_EXP_LOG" then
        Global.OnExpLog(arg1, arg2)
    elseif arg0 == "UI_OME_BUFF_LOG" then
        FightLog.OnBuffLog(arg1, arg2, arg3, arg4, arg5)
    elseif arg0 == "UI_OME_BUFF_IMMUNITY" then
        FightLog.OnBuffImmunity(arg1, arg2, arg3, arg4, arg5)
    elseif arg0 == "UI_OME_DEATH_NOTIFY" then
        FightLog.OnDeathNotify(arg1, arg2)
        if arg1 and arg2 and arg2 == UI_GetClientPlayerID() and arg2 ~= arg1 then
            local hTarget = GetPlayer(arg1)
            if hTarget then
                local szTip = g_tStrings.STR_KILL .. " " .. hTarget.szName
                --VVVV OnBowledCharacterHeadLog(arg2, szTip, 199)
                OutputMessage("MSG_ANNOUNCE_NORMAL", szTip)
                GameSettingData.AddKillCount()
            end
        end
    elseif arg0 == "UI_OME_SKILL_RESPOND" then
        FightLog.OnSkillRespond(arg1)
    elseif arg0 == "UI_OME_ITEM_RESPOND" then
        Global.OnItemRespond(arg1)
    elseif arg0 == "UI_OME_ADD_ITEM_RESPOND" then
        Global.OnAddItemRespond(arg1)
    elseif arg0 == "UI_OME_USE_ITEM_RESPOND" then
        Global.OnUseItemRespond(arg1)
    elseif arg0 == "UI_OME_TRADING_RESPOND" then
        Global.OnTradingRespond(arg1)
    elseif arg0 == "UI_OME_SHOP_RESPOND" then
        Global.OnShopRespond(arg1, arg2)
    elseif arg0 == "UI_OME_MAIL_RESPOND" then
        Global.OnMailRespond(arg1)
    elseif arg0 == "UI_OME_MAIL_COUNT_INFO" then
        Global.OnMailCountInfo(arg1, arg2)
    elseif arg0 == "UI_OME_CHAT_RESPOND" then
        Global.ResponseMsgOnTalkError(arg1)
    elseif arg0 == "UI_OME_LOOT_RESPOND" then
        Global.OnLootRespond(arg1)
    elseif arg0 == "UI_OME_CRAFT_RESPOND" then
        Global.OnCraftRespond(arg1, arg2, arg3, arg4, arg5)
    elseif arg0 == "UI_OME_QUEST_RESPOND" then
        Global.OnQuestRespond(arg1, arg2)
    elseif arg0 == "UI_OME_APPLY_DUEL" then
        Global.OnApplyDuelRespond(arg1, arg2)
    elseif arg0 == "UI_OME_PREPARE_DUEL" then
        Global.OnAcceptDuelRespond(arg1, arg2)
        m_nLastShowSecond = -1
        SprintData.SetViewState(false)
        if arg4 then
            if arg5 then
                UIMgr.Open(VIEW_ID.PanelArenaConfirmPop, arg2, arg3 + GetLogicFrameCount(), arg5)
            else
                local nLeftSecond = arg3 / GLOBAL.GAME_FPS
                nLeftSecond = math.ceil(nLeftSecond)
                nLeftSecond = math.max(0, nLeftSecond)
                TipsHelper.PlayCountDown(nLeftSecond)
                if g_pClientPlayer and g_pClientPlayer.dwID == arg1 then
                    TargetMgr.doSelectTarget(arg2, TARGET.PLAYER)
                elseif g_pClientPlayer and g_pClientPlayer.dwID == arg2 then
                    TargetMgr.doSelectTarget(arg1, TARGET.PLAYER)
                end
            end
        else
            m_nEndFrame = arg3 + GetLogicFrameCount()
            m_CalculaPKType = "DUEL"

            local function fnCountDown()
                if not g_pClientPlayer then
                    return
                end
                local nLeftSeconds = (m_nEndFrame - GetLogicFrameCount()) / 16
                nLeftSeconds = math.ceil(nLeftSeconds)

                if nLeftSeconds >= 1 and m_nLastShowSecond ~= nLeftSeconds then
                    TipsHelper.PlayCountDown(nLeftSeconds)
                    m_nLastShowSecond = nLeftSeconds
                end

                if nLeftSeconds >= 1 then
                    Timer.DelTimer(Global, Global.nDUELTimerID)
                    Global.nDUELTimerID = Timer.AddFrame(Global, 1, fnCountDown)
                end
            end
            if g_pClientPlayer and g_pClientPlayer.dwID == arg1 then
                TargetMgr.doSelectTarget(arg2, TARGET.PLAYER)
            elseif g_pClientPlayer and g_pClientPlayer.dwID == arg2 then
                TargetMgr.doSelectTarget(arg1, TARGET.PLAYER)
            end
            fnCountDown()
        end
    elseif arg0 == "UI_OME_ACCEPT_DUEL" then

    elseif arg0 == "UI_OME_REFUSE_DUEL" then
        Global.OnRefuseDuelRespond(arg1, arg2)
    elseif arg0 == "UI_OME_START_DUEL" then
        --PK开始倒计时结束
        m_nEndFrame = 0
        m_nLastShowSecond = -1
        UIMgr.Close(VIEW_ID.PanelArenaConfirmPop)
        Global.OnStartDuelRespond(arg1)
        TargetMgr.doSelectTarget(arg1, TARGET.PLAYER)
    elseif arg0 == "UI_OME_CANCEL_DUEL" then
        --PK开始倒计时结束
        m_nEndFrame = 0
        m_nLastShowSecond = -1
        UIMgr.Close(VIEW_ID.PanelArenaConfirmPop)
        Global.OnCancelDuelRespond(arg1)
        StopDuelPunishCountDown()
    elseif arg0 == "UI_OME_WIN_DUEL" then
        Global.OnWinDuelRespond(arg1, arg2)
        StopDuelPunishCountDown()
    elseif arg0 == "UI_OME_FINISH_DUEL" then
        Global.OnFinishDuelRespond()
    elseif arg0 == "UI_OME_APPLY_SLAY" then
        Global.OnApplySlayRespond(arg1, arg2)
    elseif arg0 == "UI_OME_START_SLAY" then
        Global.OnStartSlayRespond(arg1)
    elseif arg0 == "UI_OME_CLOSE_SLAY" then
        Global.OnCloseSlayRespond(arg1, arg2)
    elseif arg0 == "UI_OME_SLAY_CLOSED" then
        Global.OnSlayClosedRespond(arg1)
    elseif arg0 == "UI_OME_SYS_ERROR" then
        OutputMessage("MSG_ANNOUNCE_NORMAL", arg1)
    elseif arg0 == "UI_OME_LEVEL_UP" then
        Global.OnLevelUpMessage()
    elseif arg0 == "UI_OME_FELLOWSHIP_RESPOND" then
        Global.OnFellowshipMessage(arg1)
    elseif arg0 == "UI_OME_LEARN_PROFESSION" then
        Global.OnLearnProfession(arg1)
    elseif arg0 == "UI_OME_LEARN_BRANCH" then
        Global.OnLearnBranch(arg1, arg2)
    elseif arg0 == "UI_OME_FORGET_PROFESSION" then
        Global.OnForgetProfession(arg1)
    elseif arg0 == "UI_OME_ADD_PROFESSION_PROFICIENCY" then
        Global.OnAddProfessionProficiency(arg1, arg2)
    elseif arg0 == "UI_OME_PROFESSION_LEVEL_UP" then
        Global.OnProfessionLevelUp(arg1, arg2)
    elseif arg0 == "UI_OME_SET_PROFESSION_MAX_LEVEL" then
        Global.OnSetProfessionMaxLevel(arg1, arg2)
    elseif arg0 == "UI_OME_LEARN_RECIPE" then
        Global.OnLearnRecipe(arg1, arg2)
    elseif arg0 == "UI_OME_PK_RESPOND" then
        Global.OnPKRespond(arg1)
    elseif arg0 == "UI_OME_BANISH_PLAYER" then
        if not BattleFieldData.IsInBattleField() and not ArenaData.IsInArena() then
            Global.OnBanishPlayer(arg1, arg2)
        elseif arg1 == BANISH_CODE.MAP_UNLOAD then
            Global.OnBattleFieldMapUnload(arg2)
        end
    elseif arg0 == "UI_OME_CHECK_OPNE_DOODAD" then
        Global.OnCheckOpenDoodad()
    end
end

----------------------- 生活技能学习提示 -------------------------
function Global.OnLearnProfession(nProfessionID)
    local profession = GetProfession(nProfessionID)
    if profession and nProfessionID ~= 8 and nProfessionID ~= 9 and nProfessionID ~= 10 and nProfessionID ~= 11 then
        --不显示阅读,佛学，道学，杂集的学习
        OutputMessage("MSG_SYS", FormatString(g_tStrings.STR_LEARN_PROFESSION, Table_GetProfessionName(nProfessionID)))
    end
    FireUIEvent("ON_LEARN_PROFESSION", nProfessionID)
    --教学 技艺学习
    FireHelpEvent("OnLearnCraft", nProfessionID)
end

function Global.OnLearnBranch(nProfessionID, nBranchID)
    local profession = GetProfession(nProfessionID)

    if profession then
        local szBranchName = Table_GetBranchName(nProfessionID, nBranchID)
        if szBranchName then
            OutputMessage("MSG_SYS", FormatString(g_tStrings.STR_LEARN_BRANCH, Table_GetProfessionName(nProfessionID), szBranchName))
        end
    end
end

function Global.OnForgetProfession(nProfessionID)
    local profession = GetProfession(nProfessionID)

    if profession then
        OutputMessage("MSG_SYS", FormatString(g_tStrings.STR_FORGET_PROFESSION, Table_GetProfessionName(nProfessionID)))
    end
end

function Global.OnAddProfessionProficiency(nProfessionID, nExp)
    local profession = GetProfession(nProfessionID)
    local hPlayer = GetClientPlayer()
    if profession then
        local nLevel = hPlayer.GetProfessionLevel(nProfessionID)
        local nMaxLevel = hPlayer.GetProfessionMaxLevel(nProfessionID)
        if nLevel < nMaxLevel then
            OutputMessage("MSG_SYS", FormatString(g_tStrings.STR_ADD_PROFESSION_PROFICIENCY, Table_GetProfessionName(nProfessionID), nExp))
        end
    end
end

function Global.OnProfessionLevelUp(nProfessionID, nNewLevel)
    local profession = GetProfession(nProfessionID)
    if profession then
        OutputMessage("MSG_SYS", FormatString(g_tStrings.STR_PROFESSION_LEVEL_UP, Table_GetProfessionName(nProfessionID), nNewLevel))

        local hPlayer = GetClientPlayer()
        if hPlayer then
            local nMaxLevel = hPlayer.GetProfessionMaxLevel(nProfessionID)
            --教学 技艺升级
            FireHelpEvent("OnCraftLevelUp", nProfessionID, nNewLevel, nMaxLevel)
        end
    end
end

function Global.OnSetProfessionMaxLevel(nProfessionID, nNewMaxLevel)
    if nProfessionID == 8 or nProfessionID == 9 or nProfessionID == 10 or nProfessionID == 11 then
        return
    end

    local profession = GetProfession(nProfessionID)

    if profession then
        local szLevelName = g_tStrings.tProfessionLevelName[nNewMaxLevel]
        if szLevelName then
            OutputMessage("MSG_SYS", FormatString(g_tStrings.STR_SET_PROFESSION_MAX_LEVEL, szLevelName, Table_GetProfessionName(nProfessionID)))
        end

        --教学 技艺等级上限提高
        FireHelpEvent("OnProfessionMaxLevelUp", nProfessionID, nNewMaxLevel)
    end
end

function Global.OnLearnRecipe(nCraftID, nRecipeID)
    local szRecipeName = Table_GetRecipeName(nCraftID, nRecipeID)
    if not string.is_nil(szRecipeName) then
        OutputMessage("MSG_SYS", FormatString(g_tStrings.STR_LEARN_RECIPE, szRecipeName))
    end

    --教学 学习配方
    FireHelpEvent("OnLearnRecipe", nCraftID, nRecipeID)
end

function Global.OnReputationRespond(dwForceID, nAddNum)
    local tRepuForceInfo = Table_GetReputationForceInfo(dwForceID)
    if not tRepuForceInfo then
        return
    end

    if nAddNum >= 0 then
        OutputMessage("MSG_REPUTATION", FormatString(g_tStrings.STR_MSG_REPUTE_ADD, tRepuForceInfo.szName, nAddNum))
    else
        OutputMessage("MSG_REPUTATION", FormatString(g_tStrings.STR_MSG_REPUTE_DEL, tRepuForceInfo.szName, -nAddNum))
    end
end

function Global.OnPKRespond(dwPKCode)
    local szMsg = g_tStrings.tPKResult[dwPKCode]
    if szMsg then
        OutputMessage("MSG_ANNOUNCE_NORMAL", szMsg)
    end
end

function Global.OnBanishPlayer(nBanishCode, nLeftSeconds, ...)
    local szTitle = nil
    local szBarTitle = nil
    local szCountDownDes = nil
    local szType = nil
    local tbArgs = { ... }

    if nBanishCode == BANISH_CODE.MAP_REFRESH then
        szType = "refresh_copy"
        szBarTitle = "%d秒后传送出副本"
        szCountDownDes = "你所在的副本即将重置，你将在%d秒内传送出副本！"
    elseif nBanishCode == BANISH_CODE.NOT_IN_MAP_OWNER_PARTY then
        szType = "party_copy"
        szBarTitle = "%d秒后传送出副本"
        szCountDownDes = "你现在不在这个副本的队伍中，你将在%d秒内传送出副本！"
    elseif nBanishCode == BANISH_CODE.CANCEL_BANISH then
        --CloseBanishPanel()
    elseif nBanishCode == BANISH_CODE.NOT_IN_MAP_OWNER_TONG then
        szType = "guild"
        szBarTitle = "%d秒后传送出帮会领地"
        szCountDownDes = "你已退出了帮会领地所在的帮会，你将在%d秒内传送出该帮会领地！"
    elseif nBanishCode == BANISH_CODE.NOT_IN_MAP_OWNER_TONG_DIF then
        szType = "tong_dif"
        szBarTitle = "%d秒后传送出副本"
        local szTongName = tbArgs and tbArgs[1] or g_tStrings.GUILD_UNKNOWN
        szCountDownDes = string.format("当前秘境为【%s】帮会的秘境，只允许该帮会及其同盟的正式成员（入帮7天）进入。你将在%d秒内传送出副本！", szTongName)
    end

    if not szCountDownDes or not szType or not nLeftSeconds then
        return
    end

    BubbleMsgData.PushMsgWithType(szType,{
        szTitle = szTitle,
        szBarTitle = szBarTitle,
        nBarTime = nLeftSeconds, -- 显示在气泡栏的时长, 单位为秒
        szContent = szCountDownDes,
        szAction = nil,
        nLifeTime = nLeftSeconds, -- 存在时长, 单位为秒
        bIsCountDown = true,
        nCountDown = nLeftSeconds,
        nCountDownEndTime = (Timer.RealtimeSinceStartup() + nLeftSeconds),
        szCountDownDes = szCountDownDes,
    })
end

local tBanishTime = { 5 * 60, 3 * 60, 60, 45, 30, 15, 0 }
local nLastBanishIndex = nil
function Global.OnBattleFieldMapUnload(nBanishTime)
    for nIndex, nTime in ipairs(tBanishTime) do
        if nBanishTime <= nTime and tBanishTime[nIndex + 1] and nBanishTime > tBanishTime[nIndex + 1] then
            if nLastBanishIndex ~= nIndex then
                local szTime = UIHelper.GetTimeText(tBanishTime[nIndex])
                OutputMessage("MSG_SYS", FormatString(g_tStrings.STR_BATTLEFIELD_MESSAGE_MAP_UNLOAD, szTime))
                nLastBanishIndex = nIndex
            end
            return
        end
    end
    nLastBanishIndex = nil
end

function Global.OnCheckOpenDoodad()
    local szMsg = g_tStrings.STR_CHECK_OPEN_DOODAD

    -- 因移动状态导致打开失败的, 作特定说明
    if g_pClientPlayer
            and g_pClientPlayer.nMoveState ~= MOVE_STATE.ON_STAND
            and g_pClientPlayer.nMoveState ~= MOVE_STATE.ON_FLOAT
    then
        szMsg = g_tStrings.STR_CHECK_OPEN_DOODAD_ON_MOVING
    end

    OutputMessage("MSG_ANNOUNCE_NORMAL", szMsg)
end

function Global.OnLevelUpMessage()
    --[[
        local nLevel = arg1
        local nStrength = arg2
        local nAgility = arg3
        local nVitality = arg4
        local nSpirit = arg5
        local nSpunk = arg6
        local nMaxLife = arg7
        local nMaxMana = arg8
        local nMaxRage = arg9
        local nMaxStamina = arg10
        local nMaxThew = arg11

        if nLevel ~= 0 then	OutputMessage("MSG_SYS", FormatString(g_tStrings.STR_MSG_LEVEL_UP, nLevel)) end
        if nStrength ~= 0 then OutputMessage("MSG_SYS", FormatString(g_tStrings.STR_MSG_LEVEL_UP_STRENGTH, nStrength)) end
        if nVitality ~= 0 then OutputMessage("MSG_SYS", FormatString(g_tStrings.STR_MSG_LEVEL_UP_VITALITY, nVitality)) end
        if nSpirit ~= 0 then OutputMessage("MSG_SYS", FormatString(g_tStrings.STR_MSG_LEVEL_UP_SPIRIT, nSpirit)) end
        if nAgility ~= 0 then OutputMessage("MSG_SYS", FormatString(g_tStrings.STR_MSG_LEVEL_UP_AGILITY, nAgility)) end
        if nSpunk ~= 0 then OutputMessage("MSG_SYS", FormatString(g_tStrings.STR_MSG_LEVEL_UP_SPUNK, nSpunk)) end
        if nMaxLife ~= 0 then OutputMessage("MSG_SYS", FormatString(g_tStrings.STR_MSG_LEVEL_UP_MAX_LIFE, nMaxLife)) end
        if nMaxMana ~= 0 then OutputMessage("MSG_SYS", FormatString(g_tStrings.STR_MSG_LEVEL_UP_MAX_MANA, nMaxMana)) end
        if nMaxStamina ~= 0 then OutputMessage("MSG_SYS", FormatString(g_tStrings.STR_MSG_LEVEL_UP_MAX_STAMINA, nMaxStamina)) end
        if nMaxThew ~= 0 then OutputMessage("MSG_SYS", FormatString(g_tStrings.STR_MSG_LEVEL_UP_MAX_THEW, nMaxThew)) end

        if nMaxRage ~= 0 then OutputMessage("MSG_SYS", FormatString(g_tStrings.STR_MSG_LEVEL_UP_MAX_RAGE, nMaxRage)) end
    ]]
end

--------------------------------- PK提示 --------------------------------------------
function Global.OnApplyDuelRespond(dwSrcPlayerID, dwDstPlayerID)
    local SrcPlayer = GetPlayer(dwSrcPlayerID)
    local DstPlayer = GetPlayer(dwDstPlayerID)
    local dwClientID = GetClientPlayer().dwID
    if dwSrcPlayerID == dwClientID or dwDstPlayerID == dwClientID then
        FireHelpEvent("OnApplyFight")
    end
    if SrcPlayer and DstPlayer then
        OutputMessage("MSG_SYS", FormatString(g_tStrings.STR_PK_APPLY_DUEL, g2u(SrcPlayer.szName), g2u(DstPlayer.szName)))
    end

    local ClientPlayer = GetClientPlayer()
    if ClientPlayer.dwID == dwSrcPlayerID then
        Player_Talk(ClientPlayer, PLAYER_TALK_CHANNEL.NEARBY, "",
                { { type = "text", text = u2g(g_tStrings.STR_PK_APPLY_DUEL_EXT[Random(1, #g_tStrings.STR_PK_APPLY_DUEL_EXT)]) } }
        )
        DoAction(0, 10150)
    end
end

function Global.OnAcceptDuelRespond(dwSrcPlayerID, dwDstPlayerID)
    local SrcPlayer = GetPlayer(dwSrcPlayerID)
    local DstPlayer = GetPlayer(dwDstPlayerID)

    if SrcPlayer and DstPlayer then
        OutputMessage("MSG_SYS", FormatString(g_tStrings.STR_PK_ACCEPT_DUEL, g2u(SrcPlayer.szName), g2u(DstPlayer.szName)))
    end

    local ClientPlayer = GetClientPlayer()
    if ClientPlayer.dwID == dwSrcPlayerID then
        Player_Talk(ClientPlayer, PLAYER_TALK_CHANNEL.NEARBY, "",
                { { type = "text", text = u2g(g_tStrings.STR_PK_ACCEPT_DUEL_EXT[Random(1, #g_tStrings.STR_PK_ACCEPT_DUEL_EXT)]) } }
        )
        DoAction(0, 10150)
    end
end

function Global.OnRefuseDuelRespond(dwSrcPlayerID, dwDstPlayerID)
    local SrcPlayer = GetPlayer(dwSrcPlayerID)
    local DstPlayer = GetPlayer(dwDstPlayerID)
    local szMsg = g_tStrings.STR_PK_CANCEL_DUEL

    if SrcPlayer and DstPlayer then
        szMsg = FormatString(g_tStrings.STR_PK_REFUSE_DUEL, g2u(SrcPlayer.szName), g2u(DstPlayer.szName))
    end

    OutputMessage("MSG_SYS", szMsg)
end

function Global.OnStartDuelRespond(dwTargetPlayerID)
    OutputMessage("MSG_ANNOUNCE_NORMAL", g_tStrings.STR_PK_START_DUEL)
end

function Global.OnCancelDuelRespond(dwTargetPlayerID)
    OutputMessage("MSG_ANNOUNCE_NORMAL", g_tStrings.STR_PK_CANCEL_DUEL)
end

function Global.OnWinDuelRespond(dwWinnerID, dwLosserID)
    local Winner = GetPlayer(dwWinnerID)
    local Losser = GetPlayer(dwLosserID)
    local ClientPlayer = GetClientPlayer()

    if Losser and Losser.dwID == ClientPlayer.dwID then
        local szMsg = FormatString(g_tStrings.STR_PK_LOSS_ANOTHER, g2u(Losser.szName))
        if Winner then
            szMsg = FormatString(g_tStrings.STR_PK_LOSS_DUEL, g2u(Losser.szName), g2u(Winner.szName))
        end
        OutputMessage("MSG_SYS", szMsg)
        Player_Talk(ClientPlayer, PLAYER_TALK_CHANNEL.NEARBY, "",
                { { type = "text", text = u2g(g_tStrings.STR_PK_LOSS_DUEL_EXT[Random(1, #g_tStrings.STR_PK_LOSS_DUEL_EXT)]) } }
        )
        DoAction(0, 10150)
    elseif Winner then
        local szMsg = FormatString(g_tStrings.STR_PK_WIN_ANOTHER, g2u(Winner.szName))
        if Losser then
            szMsg = FormatString(g_tStrings.STR_PK_WIN_DUEL, g2u(Winner.szName), g2u(Losser.szName))
        end
        OutputMessage("MSG_SYS", szMsg)
        --	OutputMessage()
    end

    if Winner and Winner.dwID == ClientPlayer.dwID then
        Player_Talk(ClientPlayer, PLAYER_TALK_CHANNEL.NEARBY, "",
                { { type = "text", text = u2g(g_tStrings.STR_PK_WIN_DUEL_EXT[Random(1, #g_tStrings.STR_PK_WIN_DUEL_EXT)]) } }
        )
    end
end

function Global.OnFinishDuelRespond()
    OutputMessage("MSG_SYS", g_tStrings.STR_PK_FINISH_DUEL)
end

function Global.GetPlayerName(dwPlayerID)
    local player = GetPlayer(dwPlayerID)

    if not player then
        return
    end

    local szName = player.szName

    if dwPlayerID == GetClientPlayer().dwID then
        szName = g_tStrings.STR_NAME_YOU
    end

    return szName
end

function Global.OnApplySlayRespond(dwPlayerID, nEndFrame)
    local szName = Global.GetPlayerName(dwPlayerID)
    local nLeftSeconds = (nEndFrame - GetLogicFrameCount()) / 16
    nLeftSeconds = math.ceil(nLeftSeconds)

    if szName then
        OutputMessage("MSG_SYS", FormatString(g_tStrings.STR_PK_APPLY_SLAY, szName, nLeftSeconds))
    end

    if dwPlayerID == GetClientPlayer().dwID then
        if nLeftSeconds > 0 and m_nLastShowSecond ~= nLeftSeconds then
            OutputMessage("MSG_ANNOUNCE_NORMAL", FormatString(g_tStrings.STR_PK_START_SLAY_CALCULAGRAPH, nLeftSeconds))
            m_CalculaPKType = "SLAY_START"
            m_nEndFrame = nEndFrame
            m_nLastShowSecond = -1

            TipsHelper.PlayCountDown(nLeftSeconds)
        end
    end
end

function Global.OnStartSlayRespond(dwPlayerID)
    local szName = Global.GetPlayerName(dwPlayerID)

    if szName and szName ~= "" then
        OutputMessage("MSG_SYS", FormatString(g_tStrings.STR_PK_START_SLAY, szName))
    end

    if dwPlayerID == GetClientPlayer().dwID then
        m_CalculaPKType = nil
        m_nEndFrame = 0
        m_nLastShowSecond = -1
    end
end

function Global.OnCloseSlayRespond(dwPlayerID, nEndFrame)
    local szName = Global.GetPlayerName(dwPlayerID)
    local nLeftSeconds = (nEndFrame - GetLogicFrameCount()) / 16
    nLeftSeconds = math.ceil(nLeftSeconds)

    if szName then
        local szMsg = FormatString(g_tStrings.STR_PK_CLOSE_SLAY, szName, nLeftSeconds)
        OutputMessage("MSG_SYS", szMsg)
    end

    if dwPlayerID == GetClientPlayer().dwID then
        if nLeftSeconds > 0 and m_nLastShowSecond ~= nLeftSeconds then
            OutputMessage("MSG_ANNOUNCE_NORMAL", FormatString(g_tStrings.STR_PK_CLOSE_SLAY_CALCULAGRAPH, nLeftSeconds))
            m_CalculaPKType = "SLAY_CLOSE"
            m_nEndFrame = nEndFrame
            m_nLastShowSecond = -1

        end
    end
end

function Global.OnSlayClosedRespond(dwPlayerID)
    local szName = Global.GetPlayerName(dwPlayerID)

    if szName then
        OutputMessage("MSG_SYS", FormatString(g_tStrings.STR_PK_SLAY_CLOSED, szName))
    end

    if dwPlayerID == GetClientPlayer().dwID then
        m_CalculaPKType = nil
        m_nEndFrame = 0
        m_nLastShowSecond = -1
    end
end

function Global.OnExpLog(dwPlayerID, nAddExp)
    if nAddExp > 0 and not self.bCloseLevelUpPanel then
        -- local szMsg = FormatString(g_tStrings.STR_EXP_YOU_GET_EXP_MSG, nAddExp)

        -- OutputMessage("MSG_EXP", szMsg)

        FireUIEvent("ON_EXP_LOG", dwPlayerID, nAddExp)
    end
end

function Global.OnCoinBuyRespond(nType)
    local szRespond = g_tStrings.tCoinBuyRespond[nType]
    OutputMessage("MSG_SYS", szRespond)
end

function Global.OnShopRespond(nRespondCode, nMoney)
    ShopData.nLastBuyTime = nil

    local szMsg = nil

    if nRespondCode >= SHOP_SYSTEM_RESPOND_CODE.HAVE_TOO_MUCH_CURRENCY then

        szMsg = g_tStrings.g_ShopStrings[SHOP_SYSTEM_RESPOND_CODE.HAVE_TOO_MUCH_CURRENCY][nRespondCode - SHOP_SYSTEM_RESPOND_CODE.HAVE_TOO_MUCH_CURRENCY]
    elseif nRespondCode >= SHOP_SYSTEM_RESPOND_CODE.NOT_ENOUGH_CURRENCY then
        szMsg = g_tStrings.g_ShopStrings[SHOP_SYSTEM_RESPOND_CODE.NOT_ENOUGH_CURRENCY][nRespondCode - SHOP_SYSTEM_RESPOND_CODE.NOT_ENOUGH_CURRENCY]
        if nRespondCode - SHOP_SYSTEM_RESPOND_CODE.NOT_ENOUGH_CURRENCY == CURRENCY_TYPE.PRESTIGE then
            PlayTipSound("081")
        else
            PlayTipSound("081_1")
        end
    else
	    szMsg = g_tStrings.g_ShopStrings[nRespondCode]
    end

	if not szMsg then
		return
	end

    if nRespondCode == SHOP_SYSTEM_RESPOND_CODE.SELL_FAILED then
        PlayTipSound("079")
    elseif nRespondCode == SHOP_SYSTEM_RESPOND_CODE.BUY_FAILED then
        PlayTipSound("079_1")
    elseif nRespondCode == SHOP_SYSTEM_RESPOND_CODE.REPAIR_FAILED then
        PlayTipSound("079_2")
    elseif nRespondCode == SHOP_SYSTEM_RESPOND_CODE.NOT_ENOUGH_MONEY then
        PlayTipSound("080")
    elseif nRespondCode == SHOP_SYSTEM_RESPOND_CODE.ACHIEVEMENT_RECORD_ERROR then
        PlayTipSound("082")
    elseif nRespondCode == SHOP_SYSTEM_RESPOND_CODE.NOT_ENOUGH_ACHIEVEMENT_POINT then
        PlayTipSound("082_1")
    elseif nRespondCode == SHOP_SYSTEM_RESPOND_CODE.NOT_ENOUGH_MENTOR_VALUE then
        PlayTipSound("083")
    elseif nRespondCode == SHOP_SYSTEM_RESPOND_CODE.ITEM_SOLD_OUT or nRetCode == SHOP_SYSTEM_RESPOND_CODE.PLAYER_BUY_COUNT_LIMIT then
        PlayTipSound("084")
    elseif nRespondCode == SHOP_SYSTEM_RESPOND_CODE.BAG_FULL then
        PlayTipSound("006")
    elseif nRespondCode == SHOP_SYSTEM_RESPOND_CODE.CAN_NOT_SELL then
        PlayTipSound("085")
    elseif nRespondCode == SHOP_SYSTEM_RESPOND_CODE.NOT_ENOUGH_ITEM then
        PlayTipSound("086")
    elseif nRespondCode == SHOP_SYSTEM_RESPOND_CODE.ITEM_CD then
        PlayTipSound("087")
    elseif nRespondCode == SHOP_SYSTEM_RESPOND_CODE.HAVE_TOO_MUCH_MONEY then
        PlayTipSound("088")
    elseif nRespondCode == SHOP_SYSTEM_RESPOND_CODE.TITLE_TOO_LOW then
        PlayTipSound("089")
    elseif nRespondCode == SHOP_SYSTEM_RESPOND_CODE.NOT_ENOUGH_CORPS_VALUE then
        --PlayTipSound("089")
    end

    if (nRespondCode == SHOP_SYSTEM_RESPOND_CODE.SELL_SUCCESS) then
        -- OutputMessage("MSG_ANNOUNCE_NORMAL", szMsg)
        -- PlaySound(SOUND.UI_SOUND,g_sound.Sell)
        return
    elseif (nRespondCode == SHOP_SYSTEM_RESPOND_CODE.BUY_SUCCESS) then
        OutputMessage("MSG_ANNOUNCE_NORMAL", szMsg)
        -- PlaySound(SOUND.UI_SOUND,g_sound.Trade)
        return
    elseif (nRespondCode == SHOP_SYSTEM_RESPOND_CODE.RETURN_SUCCESS) then
        OutputMessage("MSG_ANNOUNCE_NORMAL", szMsg)
        -- PlaySound(SOUND.UI_SOUND,g_sound.Trade)
        return
    elseif (nRespondCode == SHOP_SYSTEM_RESPOND_CODE.TONG_PAY_REPAIR) then
        ------------------在聊天框显示修理装备信息--------------------------------

        QuestData.ExcuteFinishQuestByType("Repaire")

        --local szFont = GetMsgFontString("MSG_ITEM")

        if nMoney > 0 then
            local szTongPayRepairMoney = UIHelper.GetTongGoldText(nMoney)
            --OutputMessage("MSG_MONEY", "<text>text=\""..g_tStrings.STR_REPAIR_COST_TONG_MONEY.."\" font="..szFont.."</text>"..szTongPayRepairMoney.."<text>text=\"\n\" font="..szFont.."</text>", true)
            OutputMessage("MSG_MONEY", g_tStrings.STR_REPAIR_COST_TONG_MONEY .. szTongPayRepairMoney, true)
            local nRate = GetTongClient().GetRepairDiscountRate() --帮会修理折扣
            local nTongTechTreeWelfare = 10 - nRate / 10.0
            if nTongTechTreeWelfare > 0 then
                local szWelfareMsg = FormatString(g_tStrings.STR_TONG_TECH_TREE_WELFARE, nTongTechTreeWelfare)--天工树福利
                --OutputMessage("MSG_SYS", GetFormatText(szWelfareMsg, szFont), true)
                OutputMessage("MSG_SYS", GetFormatText(szWelfareMsg), true)
            end
        end

        return
    elseif (nRespondCode == SHOP_SYSTEM_RESPOND_CODE.REPAIR_SUCCESS) then
        QuestData.ExcuteFinishQuestByType("Repaire")

        OutputMessage("MSG_ANNOUNCE_NORMAL", szMsg)
        -- PlaySound(SOUND.UI_SOUND,g_sound.Repair)

        if nMoney > 0 then
            --local szFont = GetMsgFontString("MSG_ITEM")
            --local szMoney = UIHelper.GetMoneyText(nMoney, szFont, "cut_front4")
            -- OutputMessage("MSG_MONEY", "<text>text=\""..g_tStrings.STR_SHOP_REPAIR_COST_MONEY.."\" font="..szFont.."</text>"..szMoney.."<text>text=\"\n\" font="..szFont.."</text>", true)
            local szMoney = UIHelper.GetMoneyText(nMoney, 22)
            OutputMessage("MSG_MONEY", g_tStrings.STR_SHOP_REPAIR_COST_MONEY .. tostring(nMoney), true)
            local nRate = GetTongClient().GetRepairDiscountRate() --帮会修理折扣
            local nTongTechTreeWelfare = 10 - nRate / 10.0
            if nTongTechTreeWelfare > 0 then
                local szFont = GetMsgFontString("MSG_ITEM")
                local szWelfareMsg = FormatString(g_tStrings.STR_TONG_TECH_TREE_WELFARE, nTongTechTreeWelfare)--天工树福利
                OutputMessage("MSG_MONEY", GetFormatText(szWelfareMsg, szFont), true)
            end
        end

        return
    elseif (nRespondCode == SHOP_SYSTEM_RESPOND_CODE.NONE_ITEM_NEED_REPAIR) then
        -- 由于互通版只有自动修理，策划要求屏蔽此消息
        return
    else
        OutputMessage("MSG_ANNOUNCE_NORMAL", szMsg)
    end
end

function Global.OnMailRespond(nRespondCode)
    local szMsg = ""

    if nRespondCode == MAIL_RESPOND_CODE.SUCCEED then
        -- szMsg = g_tStrings.STR_MAIL_SUCCEED
        -- OutputMessage("MSG_ANNOUNCE_NORMAL", szMsg)
        return
    elseif nRespondCode == MAIL_RESPOND_CODE.FAILED then
        -- szMsg = g_tStrings.STR_MAIL_FAILED
        return
    elseif nRespondCode == MAIL_RESPOND_CODE.SYSTEM_BUSY then
        szMsg = g_tStrings.STR_MAIL_SYSTEM_BUSY
    elseif nRespondCode == MAIL_RESPOND_CODE.DST_NOT_EXIST then
        szMsg = g_tStrings.STR_MAIL_DST_NOT_EXIST
        PlayTipSound("104")
    elseif nRespondCode == MAIL_RESPOND_CODE.DST_REMOTE_PLAYER then
        szMsg = g_tStrings.STR_MAIL_DST_REMOTE_PLAYER
        PlayTipSound("104")
    elseif nRespondCode == MAIL_RESPOND_CODE.NOT_ENOUGH_MONEY then
        szMsg = g_tStrings.STR_MAIL_NOT_ENOUGH_MONEY
    elseif nRespondCode == MAIL_RESPOND_CODE.ITEM_AMOUNT_LIMIT then
        szMsg = g_tStrings.STR_MAIL_ITEM_AMOUNT_LIMIT
        Event.Dispatch(EventType.MailItemAmountLimit)
    elseif nRespondCode == MAIL_RESPOND_CODE.NOT_ENOUGH_ROOM then
        szMsg = g_tStrings.STR_MAIL_NOT_ENOUGH_ROOM
        Event.Dispatch(EventType.MailNotEnoughRoom)
    elseif nRespondCode == MAIL_RESPOND_CODE.MAIL_NOT_FOUND then
        szMsg = g_tStrings.STR_MAIL_NOT_FOUND
    elseif nRespondCode == MAIL_RESPOND_CODE.MAIL_BOX_FULL then
        szMsg = g_tStrings.STR_MAIL_BOX_FULL
    elseif nRespondCode == MAIL_RESPOND_CODE.RETURN_MAIL_FAILED then
        szMsg = g_tStrings.STR_MAIL_RETURN_MAIL_FAILED
    elseif nRespondCode == MAIL_RESPOND_CODE.ITEM_BE_BIND then
        szMsg = g_tStrings.STR_MAIL_ITEM_BE_BIND
    elseif nRespondCode == MAIL_RESPOND_CODE.TIME_LIMIT_ITEM then
        szMsg = g_tStrings.STR_TIME_LIMIT_ITEM
    elseif nRespondCode == MAIL_RESPOND_CODE.ITEM_NOT_IN_PACKAGE then
        szMsg = g_tStrings.STR_MAIL_ITEM_NOT_IN_PACKAGE
    elseif nRespondCode == MAIL_RESPOND_CODE.MONEY_LIMIT then
        szMsg = g_tStrings.STR_MAIL_MONEY_LIMIT
        Event.Dispatch(EventType.MailMoneyLimit)
    elseif nRespondCode == MAIL_RESPOND_CODE.DST_NOT_SELF then
        szMsg = g_tStrings.STR_MAIL_DST_NOT_SELF
    elseif nRespondCode == MAIL_RESPOND_CODE.DELETE_REFUSED then
        szMsg = g_tStrings.STR_MAIL_DELETE_REFUSED
    elseif nRespondCode == MAIL_RESPOND_CODE.SELF_MAIL_BOX_FULL then
        szMsg = g_tStrings.STR_MAIL_SELF_MAIL_BOX_FULL
    elseif nRespondCode == MAIL_RESPOND_CODE.TOO_FAWAY then
        szMsg = g_tStrings.STR_MAIL_TOO_FAR_AWAY
    elseif nRespondCode == MAIL_RESPOND_CODE.DELAY_TRADE_ITEM then
        szMsg = g_tStrings.STR_MAIL_TOO_DELAY_TRADE_ITEM
    elseif nRespondCode == MAIL_RESPOND_CODE.DAILY_SEND_LIMIT then
        szMsg = g_tStrings.STR_MAIL_DAILY_SEND_LIMIT
    elseif nRespondCode == MAIL_RESPOND_CODE.PACKAGE_CANNOT_USE then
        szMsg = g_tStrings.STR_MAIL_PACKAGE_CANNOT_USE
    elseif nRespondCode == MAIL_RESPOND_CODE.SEND_MAIL_TOO_FREQUENTLY then
        szMsg = g_tStrings.STR_SEND_MAIL_TOO_FREQUENTLY
    elseif nRespondCode == MAIL_RESPOND_CODE.ILLEGAL_MAIL_TEXT then
        szMsg = g_tStrings.STR_ILLEGAL_MAIL_TEXT
    end

    OutputMessage("MSG_ANNOUNCE_NORMAL", szMsg)
end

function Global.OnMailCountInfo(nUnreadCount, nTotalCount)
    local szMsg = ""
    szMsg = FormatString(g_tStrings.STR_MSG_MAIL_COUNT_INFO, nUnreadCount, nTotalCount)
    OutputMessage("MSG_SYS", szMsg)

    if SOUND then
        PlaySound(SOUND.UI_SOUND, g_sound.NewMail)
    end
end

-------------------------拾取物品的返回结果-----------------------------
function Global.OnLootRespond(nRespondCode)
    local szMsg = g_tStrings.tLootResult[nRespondCode]
    if szMsg then
        OutputMessage("MSG_ANNOUNCE_NORMAL", szMsg)
        if nRespondCode == LOOT_ITEM_RESULT_CODE.INVENTORY_IS_FULL then
            PlayTipSound("006")
        elseif nRespondCode == LOOT_ITEM_RESULT_CODE.NOT_EXIST_LOOT_ITEM then
            PlayTipSound("013")
        elseif nRespondCode == LOOT_ITEM_RESULT_CODE.ADD_LOOT_ITEM_FAILED then
        elseif nRespondCode == LOOT_ITEM_RESULT_CODE.NO_LOOT_TARGET then
        elseif nRespondCode == LOOT_ITEM_RESULT_CODE.TOO_FAR_TO_LOOT then
            PlayTipSound("014")
        elseif nRespondCode == LOOT_ITEM_RESULT_CODE.OVER_ITEM_LIMIT then
            PlayTipSound("015")
        end
    end
end

-------------------------使用生活技能的返回结果----------------------
function Global.OnCraftRespond(nRespondCode, dwCraftID, dwRecipeID, dwTargetType, dwTargetID)
    --local szMsg = g_tStrings.tCraftResultString[nRespondCode].." "..nRespondCode.." "..dwCraftID.." "..dwRecipeID.." "..dwTargetType.." "..dwTargetID
    local szMsg = ""

    if nRespondCode == CRAFT_RESULT_CODE.SUCCESS then
        local hPlayer = GetClientPlayer()
        if not hPlayer then
            return
        end
        local recipe = GetRecipe(dwCraftID, dwRecipeID)
        if recipe.nCraftType == ALL_CRAFT_TYPE.COLLECTION or recipe.nCraftType == ALL_CRAFT_TYPE.COPY then
            -- if recipe.nVigor > 0 then --消耗活力的提示放全局那边
            -- 	szMsg = FormatString(g_tStrings.STR_CRAFT_COST_VIGOR_ENTER, recipe.nVigor)
            -- 	OutputMessage("MSG_THEW_STAMINA", szMsg)
            -- end
        elseif recipe.nCraftType == ALL_CRAFT_TYPE.PRODUCE or recipe.nCraftType == ALL_CRAFT_TYPE.READ or recipe.nCraftType == ALL_CRAFT_TYPE.ENCHANT then
            -- if recipe.nVigor > 0 then --消耗活力的提示放全局那边
            -- 	local nCostVigor = recipe.nVigor
            -- 	szMsg = FormatString(g_tStrings.STR_CRAFT_COST_VIGOR_ENTER, nCostVigor)

            -- 	OutputMessage("MSG_THEW_STAMINA", szMsg)
            -- end

            if recipe.nCraftType == ALL_CRAFT_TYPE.READ then
                szMsg = g_tStrings.STR_CRAFT_READ_SUCCESS
                OutputMessage("MSG_SYS", szMsg)
                FireUIEvent("ON_READ_BOOK", BookID2GlobelRecipeID(recipe.dwID, recipe.dwSubID))

                if hPlayer then
                    local tSegmentBook = hPlayer.GetBookSegmentList(recipe.dwID)
                    local nBookNum = Table_GetBookNumber(recipe.dwID, 1)
                    local nHaveNum = #tSegmentBook
                    if nHaveNum == nBookNum then
                        FireHelpEvent("OnOneBookListReaded")
                    end
                end
            end
        end

        if hPlayer then
            if hPlayer.nCurrentStamina == 0 or hPlayer.nCurrentThew == 0 then
                FireHelpEvent("OnWithoutStaminaOrThew")
            end
        end

        if recipe.nCraftType == ALL_CRAFT_TYPE.COLLECTION or recipe.nCraftType == ALL_CRAFT_TYPE.PRODUCE then
            local nCurrentLevel = hPlayer.GetProfessionLevel(recipe.dwProfessionID)
            local nMaxLevel = hPlayer.GetProfessionMaxLevel(recipe.dwProfessionID)
            if nCurrentLevel == nMaxLevel and nMaxLevel < 50 then
                OutputMessage("MSG_SYS", g_tStrings.STR_CRAFT_NOT_EXP_MIDDLE)
            elseif nCurrentLevel == nMaxLevel and nMaxLevel < 70 then
                OutputMessage("MSG_SYS", g_tStrings.STR_CRAFT_NOT_EXP_HIGH)
            end
        end

        return
    elseif nRespondCode == CRAFT_RESULT_CODE.NOT_ENOUGH_VIGOR then
        local hPlayer = GetClientPlayer()
        if not hPlayer then
            return
        end
        local recipe = GetRecipe(dwCraftID, dwRecipeID)
        if recipe then
            local nCostVigor = recipe.nVigor
            szMsg = FormatString(g_tStrings.tCraftResultString[nRespondCode], nCostVigor)
        end
    elseif nRespondCode == CRAFT_RESULT_CODE.NOT_ENOUGH_STAMINA then
        local hPlayer = GetClientPlayer()
        if not hPlayer then
            return
        end
        local recipe = GetRecipe(dwCraftID, dwRecipeID)
        if recipe then
            local nCostStamina = recipe.nStamina
            szMsg = FormatString(g_tStrings.tCraftResultString[nRespondCode], nCostStamina)
        end
    elseif nRespondCode == CRAFT_RESULT_CODE.NOT_ENOUGH_THEW then
        local recipe = GetRecipe(dwCraftID, dwRecipeID)
        if recipe then
            szMsg = FormatString(g_tStrings.tCraftResultString[nRespondCode], recipe.nThew)
        end
    elseif nRespondCode == CRAFT_RESULT_CODE.TOO_LOW_PROFESSION_LEVEL then
        local craft = GetCraft(dwCraftID)
        local profession = GetProfession(craft.ProfessionID)
        local recipe = GetRecipe(dwCraftID, dwRecipeID)
        if recipe and profession then
            szMsg = FormatString(g_tStrings.tCraftResultString[nRespondCode], Table_GetProfessionName(craft.ProfessionID), recipe.dwRequireProfessionLevel)
        end
    elseif nRespondCode == CRAFT_RESULT_CODE.PROFESSION_NOT_LEARNED then
        local craft = GetCraft(dwCraftID)
        local profession = GetProfession(craft.ProfessionID)
        if profession then
            szMsg = FormatString(g_tStrings.tCraftResultString[nRespondCode], Table_GetProfessionName(craft.ProfessionID))
        end
    elseif nRespondCode == CRAFT_RESULT_CODE.ERROR_TOOL then
        local recipe = GetRecipe(dwCraftID, dwRecipeID)
        if recipe then
            local ItemInfo = GetItemInfo(recipe.dwToolItemType, recipe.dwToolItemIndex)
            local szItemName = ItemData.GetItemNameByItemInfo(ItemInfo)
            local CommonItemInfo = GetItemInfo(recipe.dwPowerfulToolItemType, recipe.dwPowerfulToolItemIndex)
            if ItemInfo then
                szMsg = FormatString(g_tStrings.tCraftResultString[nRespondCode], szItemName)
                if CommonItemInfo then
                    local szCommonItemName = ItemData.GetItemNameByItemInfo(CommonItemInfo)
                    szMsg = FormatString(g_tStrings.tCraftResultString[nRespondCode], szItemName .. g_tStrings.STR_OR .. szCommonItemName)
                end
            end
        end
    elseif nRespondCode == CRAFT_RESULT_CODE.REQUIRE_DOODAD then
        local recipe = GetRecipe(dwCraftID, dwRecipeID)
        if recipe then
            local doodadTemplateID = recipe.dwRequireDoodadID
            local doodadTemplate = GetDoodadTemplate(doodadTemplateID)
            if doodadTemplate then
                local szName = Table_GetDoodadTemplateName(doodadTemplate.dwTemplateID)
                szMsg = FormatString(g_tStrings.tCraftResultString[nRespondCode], szName)
            end
        end
    elseif nRespondCode == CRAFT_RESULT_CODE.TOO_LOW_EXT_PROFESSION_LEVEL then
        local recipe = GetRecipe(dwCraftID, dwRecipeID)
        local profession = GetProfession(recipe.dwProfessionIDExt)

        if recipe and profession then
            szMsg = FormatString(g_tStrings.tCraftResultString[nRespondCode], Table_GetProfessionName(recipe.dwProfessionIDExt), recipe.dwRequireProfessionLevelExt)
        end
    elseif nRespondCode == CRAFT_RESULT_CODE.EXT_PROFESSION_NOT_LEARNED then
        local recipe = GetRecipe(dwCraftID, dwRecipeID)
        local profession = GetProfession(recipe.dwProfessionIDExt)
        if profession then
            szMsg = FormatString(g_tStrings.tCraftResultString[nRespondCode], Table_GetProfessionName(recipe.dwProfessionIDExt))
        end
    else
        szMsg = g_tStrings.tCraftResultString[nRespondCode]
    end

    if nRespondCode == CRAFT_RESULT_CODE.SKILL_NOT_READY then
        PlayTipSound("058")
    elseif nRespondCode == CRAFT_RESULT_CODE.WEAPON_ERROR then
        PlayTipSound("059")
    elseif nRespondCode == CRAFT_RESULT_CODE.ADD_ITEM_FAILED then
        PlayTipSound("060")
    elseif nRespondCode == CRAFT_RESULT_CODE.INVENTORY_IS_FULL then
        PlayTipSound("006")
    elseif nRespondCode == CRAFT_RESULT_CODE.BOOK_IS_ALREADY_MEMORIZED then
        PlayTipSound("061")
    elseif nRespondCode == CRAFT_RESULT_CODE.BOOK_CANNOT_BE_COPY then
        PlayTipSound("061_1")
    elseif nRespondCode == CRAFT_RESULT_CODE.ITEM_TYPE_ERROR then
        PlayTipSound("062")
    elseif nRespondCode == CRAFT_RESULT_CODE.DOING_OTACTION then
        PlayTipSound("063")
    end

    OutputMessage("MSG_ANNOUNCE_NORMAL", szMsg)
end

-------------------------任务操作的返回结果--------------------------
function Global.OnQuestRespond(nRespondCode, dwQuestID)
    local szMsg = g_tStrings.tQuestResultString[nRespondCode]
    Event.Dispatch(EventType.OnQuestRespond, nRespondCode, dwQuestID)
    if nRespondCode == QUEST_RESULT.QUESTLIST_FULL then
        PlayTipSound("064")
    elseif nRespondCode == QUEST_RESULT.ERROR_QUEST_STATE then
        PlayTipSound("065")
    elseif nRespondCode == QUEST_RESULT.NOT_ENOUGH_FREE_ROOM then
        PlayTipSound("006")
    elseif nRespondCode == QUEST_RESULT.DAILY_QUEST_FULL then
        PlayTipSound("066")
    elseif nRespondCode == QUEST_RESULT.ERROR_CAMP then
        PlayTipSound("067")
    elseif nRespondCode == QUEST_RESULT.CHARGE_LIMIT then
        PlayTipSound("068")
    elseif nRespondCode == QUEST_RESULT.ERROR_REPUTE then
        PlayTipSound("069")
    end

    if not szMsg then
        szMsg = ""
    end

    if nRespondCode == QUEST_RESULT.ERROR_REPUTE then
        local hPlayer = GetClientPlayer()
        if not hPlayer then
            return
        end
        local t = hPlayer.GetQuestReputationInfo(dwQuestID)
        if not t then
            return
        end
        for dwForceID, v in pairs(t) do
            local tRepuForceInfo = Table_GetReputationForceInfo(dwForceID)
            if tRepuForceInfo then
                local reputationname = tRepuForceInfo.szName
                if reputationname then
                    if v == "low" then
                        szMsg = FormatString(g_tStrings.STR_REPUTATION_TOO_LOW, reputationname)
                    elseif v == "high" then
                        szMsg = FormatString(g_tStrings.STR_REPUTATION_TOO_HIGH, reputationname)
                    else
                        szMsg = ""
                    end
                    OutputMessage("MSG_ANNOUNCE_NORMAL", szMsg)
                end
            end
        end
        return
    end

    OutputMessage("MSG_ANNOUNCE_NORMAL", szMsg)
    OutputMessage("MSG_SYS", szMsg);
end

---------------------------好友操作的返回结果------------------------
function Global.OnFellowshipMessage(nRespondCode)
    local szMsg = g_tStrings.tFellowshipErrorString[nRespondCode]
    if nRespondCode == PLAYER_FELLOWSHIP_RESPOND.ERROR_INVALID_NAME then
        PlayTipSound("070")
    elseif nRespondCode == PLAYER_FELLOWSHIP_RESPOND.ERROR_ADD_SELF then
        PlayTipSound("071")
    elseif nRespondCode == PLAYER_FELLOWSHIP_RESPOND.ERROR_LIST_FULL then
        PlayTipSound("072")
    elseif nRespondCode == PLAYER_FELLOWSHIP_RESPOND.ERROR_EXISTS then
        PlayTipSound("073")
    elseif nRespondCode == PLAYER_FELLOWSHIP_RESPOND.ERROR_NOT_FOUND then
        PlayTipSound("074")
    elseif nRespondCode == PLAYER_FELLOWSHIP_RESPOND.ERROR_FOE_LIST_FULL then
        PlayTipSound("075")
    elseif nRespondCode == PLAYER_FELLOWSHIP_RESPOND.ERROR_BLACK_LIST_FULL then
        PlayTipSound("076")
    elseif nRespondCode == PLAYER_FELLOWSHIP_RESPOND.ERROR_BLACK_LIST_EXISTS then
        PlayTipSound("077")
    elseif nRespondCode == PLAYER_FELLOWSHIP_RESPOND.ERROR_SET_GROUP then
        PlayTipSound("078")
    elseif nRespondCode == PLAYER_FELLOWSHIP_RESPOND.ERROR_IN_FIGHT then
        OutputMessage("MSG_ANNOUNCE_NORMAL", g_tStrings.tFeudResult[PLAYER_FELLOWSHIP_RESPOND.ERROR_IN_FIGHT])
        OutputMessage("MSG_SYS", g_tStrings.tFeudResult[PLAYER_FELLOWSHIP_RESPOND.ERROR_IN_FIGHT])
    end
    if szMsg then
        OutputMessage("MSG_ANNOUNCE_NORMAL", szMsg)
    end
end

function Global.OnItemRespond(nRespondCode)
    local szMsg = g_tStrings.tItem_Msg[nRespondCode]

    if nRespondCode == ITEM_RESULT_CODE.PLAYER_IS_DEAD then
        PlayTipSound("101")
    elseif nRespondCode == ITEM_RESULT_CODE.ERROR_EQUIP_PLACE then
        PlayTipSound("102")
    elseif nRespondCode == ITEM_RESULT_CODE.ITEM_BINDED then
        PlayTipSound("103")
    elseif nRespondCode == ITEM_RESULT_CODE.BANK_PASSWORD_EXIST then
        --PlayTipSound("103")
    end

    if szMsg ~= "" then
        OutputMessage("MSG_ANNOUNCE_NORMAL", szMsg)
    end

end

function Global.OnAddItemRespond(nRespondCode)
    local szMsg = g_tStrings.tAdd_Item_Msg[nRespondCode]
    if nRespondCode == ADD_ITEM_RESULT_CODE.ITEM_AMOUNT_LIMITED and arg2 ~= "" then
        szMsg = FormatString(g_tStrings.STR_ITEM_AMOUNT_LIMITED_WITH_NAME, UIHelper.GBKToUTF8(arg2))
    end

    if szMsg ~= "" then
        OutputMessage("MSG_ANNOUNCE_NORMAL", szMsg)
    end

end

-------------------------使用物品的返回结果--------------------------
function Global.OnUseItemRespond(nRespondCode)
    local szMsg = g_tStrings.tUse_Item_Msg[nRespondCode]

    if nRespondCode == USE_ITEM_RESULT_CODE.FAILED then
        PlayTipSound("100")
    elseif nRespondCode == USE_ITEM_RESULT_CODE.NOT_READY then
        PlayTipSound("091")
    elseif nRespondCode == USE_ITEM_RESULT_CODE.NOT_READY then
        PlayTipSound("091")
    elseif nRespondCode == USE_ITEM_RESULT_CODE.ON_HORSE then
        PlayTipSound("099")
    elseif nRespondCode == USE_ITEM_RESULT_CODE.IN_FIGHT then
        PlayTipSound("098")
    end

    if nRespondCode == USE_ITEM_RESULT_CODE.REQUIRE_PROFESSION then
        profession = GetProfession(arg2)
        if profession then
            szMsg = FormatString(szMsg, Table_GetProfessionName(arg2))
        end
    elseif nRespondCode == USE_ITEM_RESULT_CODE.REQUIRE_PROFESSION_BRANCH then
        profession = GetProfession(arg2)
        if profession then
            local szBranchName = Table_GetBranchName(arg2, arg3)
            if szBranchName then
                szMsg = FormatString(szMsg, Table_GetProfessionName(arg2), szBranchName)
            end
        end
    elseif nRespondCode == USE_ITEM_RESULT_CODE.PROFESSION_LEVEL_TOO_LOW then
        profession = GetProfession(arg2)
        if profession then
            szMsg = FormatString(szMsg, Table_GetProfessionName(arg2), arg3)
        end
    end

    if szMsg ~= "" then
        OutputMessage("MSG_ANNOUNCE_NORMAL", szMsg)
    end

end

function Global.OnTradingRespond(nRespondCode)
    local szMsg = g_tStrings.tTradingResultString[nRespondCode]

    if not szMsg then
        return
    end

    if nRespondCode == TRADING_RESPOND_CODE.SUCCESS then
        OutputMessage("MSG_ANNOUNCE_NORMAL", szMsg)
        PlaySound(SOUND.UI_SOUND, g_sound.Trade)
        return
    elseif nRespondCode == TRADING_RESPOND_CODE.REFUSE_INVITE then
        PlayTipSound("054")
    elseif nRespondCode == TRADING_RESPOND_CODE.TARGET_NOT_IN_GAME then
        PlayTipSound("055")
    elseif nRespondCode == TRADING_RESPOND_CODE.TARGET_BUSY then
        PlayTipSound("056")
    elseif nRespondCode == TRADING_RESPOND_CODE.TOO_FAR then
        PlayTipSound("057")
    end

    OutputMessage("MSG_ANNOUNCE_NORMAL", szMsg)

    return
end

function Global.ResponseMsgOnTalkError(nRespondCode)
    local szMsg = ""
    if nRespondCode == PLAYER_TALK_ERROR.BAN then
        if GetClientPlayer().GetChargeFlag() then
            szMsg = g_tStrings.STR_TALK_ERROR_BAN
        else
            szMsg = g_tStrings.STR_TALK_ERROR_NO_CHARGE_FLAG
        end
    elseif nRespondCode == PLAYER_TALK_ERROR.TARGET_BLACKLIST_YOU then
        return -- 李琳要求的密聊去掉已在对方黑名单的提示
    else
        szMsg = g_tStrings.tTalkError[nRespondCode]
    end

    if szMsg ~= "" then
        TipsHelper.OutputMessage("MSG_SYS", szMsg, false)
    end
end

local _tTalkDecodeFunc = {
    ["text"] = function(info, szFont)
        --return "<text>text="..EncodeComponentsString(info.text)..szFont.."</text>", info.text
        return info.text, info.text
    end,
    ["HyperLink"] = function(tInfo, szFont)
        local szRawText = tInfo.text
        local nRawTextLen = string.len(szRawText)
        local szResultStr = ""
        local szPreText  -- 每个链接的前置文字（把szRawText看成以若干个"前置文字"+"链接"的组合为元素的数组）
        local szLinkFont = szFont .. "r=239 g=55 b=12 "
        local szWebLinkTagLeft = "<HyperLink>"
        local szWebLinkTagRight = "</HyperLink>"
        local szSeparator = "\\t"
        local nSiteBeginIndex, nSiteEndIndex
        local nSearchBeginIndex = 1

        while true do
            nSiteBeginIndex = StringFindW(szRawText, szWebLinkTagLeft, nSearchBeginIndex)
            nSiteEndIndex = StringFindW(szRawText, szWebLinkTagRight, nSearchBeginIndex)

            if nSiteBeginIndex and nSiteEndIndex then
                if nSiteBeginIndex < nSiteEndIndex then
                    szPreText = string.sub(szRawText, nSearchBeginIndex, nSiteBeginIndex - 1)
                    if szPreText ~= "" then
                        --szResultStr = szResultStr .. "<text>text=" .. EncodeComponentsString(szPreText) .. szFont .. "</text>"
                        szResultStr = szResultStr .. szPreText
                    end
                    local szLinkText = string.sub(szRawText, nSiteBeginIndex + string.len(szWebLinkTagLeft), nSiteEndIndex - 1)
                    local nLinkDispTextEndIndex = StringFindW(szLinkText, szSeparator, 1)
                    local szLinkDispText, szLinkSiteText
                    if nLinkDispTextEndIndex then
                        szLinkDispText = string.sub(szLinkText, 1, nLinkDispTextEndIndex - 1)
                        szLinkSiteText = string.sub(szLinkText, nLinkDispTextEndIndex + string.len(szSeparator), string.len(szLinkText))
                    else
                        szLinkDispText = ""
                        szLinkSiteText = szLinkText
                        Log("Error!  \"HyperLink\"类型的GM公告文字的网站链接信息无显示文字，将以所有文字作为网址！")
                    end
                    --szResultStr = szResultStr .. MakeWebsiteLink("[" .. szLinkDispText .. "]", szLinkFont, szLinkSiteText)
                    szResultStr = szResultStr .. "[" .. szLinkDispText .. "]" .. szLinkSiteText
                else
                    Log("Error! \"HyperLink\"类型的GM公告文字的网站链接标签错位！")
                end
            else
                if nSiteBeginIndex or nSiteEndIndex then
                    Log("Error! \"HyperLink\"类型的GM公告文字的网站链接标签不匹配！")
                    -- 把后面所有的当做纯文字
                else
                    -- 剩下的都是纯文字
                end

                szPreText = string.sub(szRawText, nSearchBeginIndex, nRawTextLen)
                if szPreText ~= "" then
                    --szResultStr = szResultStr .. "<text>text=" .. EncodeComponentsString(szPreText) .. szFont .. "</text>"
                    szResultStr = szResultStr .. szPreText
                end

                break
            end
            nSearchBeginIndex = nSiteEndIndex + string.len(szWebLinkTagRight)
        end
        return szResultStr, szRawText
    end,
    ["item"] = function(info, szFont)
        local player = GetClientPlayer()
        local item = player.GetTalkLinkItem(info.item)
        if item then
            local szItemName = "[" .. GetItemNameByItem(item) .. "]"
            -- return MakeItemLink(szItemName, szFont..GetItemFontColorByQuality(item.nQuality, true), info.item), szItemName
            return szItemName, szItemName
        else
            -- return "<text>text="..EncodeComponentsString(g_tStrings.STR_TALK_UNKNOWN_ITEM_LINK)..szFont.."</text>", g_tStrings.STR_TALK_UNKNOWN_ITEM_LINK
            return g_tStrings.STR_TALK_UNKNOWN_ITEM_LINK, g_tStrings.STR_TALK_UNKNOWN_ITEM_LINK
        end
    end,
    ["iteminfo"] = function(info, szFont)
        local intemInfo = GetItemInfo(info.tabtype, info.index)
        if intemInfo then
            local szItemName = "[" .. ItemData.GetItemNameByItemInfo(intemInfo) .. "]"
            --return MakeItemInfoLink(szItemName, szFont..GetItemFontColorByQuality(intemInfo.nQuality, true), 0, info.tabtype, info.index), szItemName
            return szItemName, szItemName
        else
            --return "<text>text="..EncodeComponentsString(g_tStrings.STR_TALK_UNKNOWN_ITEM_LINK)..szFont.."</text>", g_tStrings.STR_TALK_UNKNOWN_ITEM_LINK
            return g_tStrings.STR_TALK_UNKNOWN_ITEM_LINK, g_tStrings.STR_TALK_UNKNOWN_ITEM_LINK
        end
    end,
    ["name"] = function(info, szFont, dwTalkerID)
        local szName = "[" .. info.name .. "]"
        --return MakeNameLink(szName, szFont, dwTalkerID), szName
        return szName, szName
    end,
    ["quest"] = function(info, szFont)
        local tQuestStringInfo = Table_GetQuestStringInfo(info.questid)
        if tQuestStringInfo then
            local szQName = "[" .. tQuestStringInfo.szName .. "]"
            --return MakeQuestLink(szQName, szFont, info.questid), szQName
            return szQName, szQName
        else
            --return "<text>text="..EncodeComponentsString(g_tStrings.STR_TALK_UNKNOWN_QUEST_LINK)..szFont.."</text>", g_tStrings.STR_TALK_UNKNOWN_QUEST_LINK
            return g_tStrings.STR_TALK_UNKNOWN_QUEST_LINK, g_tStrings.STR_TALK_UNKNOWN_QUEST_LINK
        end
    end,
    ["recipe"] = function(info, szFont)
        local recipe = GetRecipe(info.craftid, info.recipeid)
        if recipe then
            local szRecipeName = "[" .. Table_GetRecipeName(info.craftid, info.recipeid) .. "]"
            --return MakeRecipeLink(szRecipeName, szFont, info.craftid, info.recipeid), szRecipeName
            return szRecipeName, szRecipeName
        else
            --return "<text>text="..EncodeComponentsString(g_tStrings.STR_TALK_UNKNOWN_RECIPE_LINK)..szFont.."</text>", g_tStrings.STR_TALK_UNKNOWN_RECIPE_LINK
            return g_tStrings.STR_TALK_UNKNOWN_RECIPE_LINK, g_tStrings.STR_TALK_UNKNOWN_RECIPE_LINK
        end
    end,
    ["enchant"] = function(info, szFont)
        local szName = Table_GetEnchantName(info.proid, info.craftid, info.recipeid)
        local nQuality = Table_GetEnchantQuality(info.proid, info.craftid, info.recipeid)
        if szName then
            szName = "[" .. szName .. "]"
            --return MakeEnchantLink(szName, szFont..GetItemFontColorByQuality(nQuality, true), info.proid, info.craftid, info.recipeid), szName
            return szName, szName
        else
            --return "<text>text="..EncodeComponentsString(g_tStrings.STR_TALK_UNKNOWN_RECIPE_LINK)..szFont.."</text>", g_tStrings.STR_TALK_UNKNOWN_RECIPE_LINK
            return g_tStrings.STR_TALK_UNKNOWN_RECIPE_LINK, g_tStrings.STR_TALK_UNKNOWN_RECIPE_LINK
        end
    end,
    ["skill"] = function(info, szFont)
        local szSkillName = "[" .. Table_GetSkillName(info.skill_id, info.skill_level) .. "]"
        --return MakeSkillLink(szSkillName, szFont, info), szSkillName
        return szSkillName, szSkillName
    end,
    ["skillrecipe"] = function(info, szFont)
        local tSkillRecipe = Table_GetSkillRecipe(info.id, info.level)
        local szSkillRecipeName = ""
        if tSkillRecipe then
            szSkillRecipeName = tSkillRecipe.szName
        end
        szSkillRecipeName = "[" .. szSkillRecipeName .. "]"
        --return MakeSkillRecipeLink(szSkillRecipeName, szFont, info.id, info.level), szSkillRecipeName
        return szSkillRecipeName, szSkillRecipeName
    end,
    ["book"] = function(info, szFont)
        local iteminfo = GetItemInfo(info.tabtype, info.index)
        if iteminfo then
            local nBookID, nSegmentID = GlobelRecipeID2BookID(info.bookinfo)
            local szBookName = "[" .. Table_GetSegmentName(nBookID, nSegmentID) .. "]"
            --return MakeBookLink(szBookName, szFont..GetItemFontColorByQuality(iteminfo.nQuality, true), info.version, info.tabtype, info.index, info.bookinfo), szBookName
            return szBookName, szBookName
        end
    end,
    ["achievement"] = function(info, szFont)
        local aAchievement = g_tTable.Achievement:Search(info.id)
        if aAchievement then
            local szName = "[" .. aAchievement.szName .. "]"
            -- return MakeAchievementLink(szName, szFont, info.id), szName
            return szName, szName
        end
    end,
    ["designation"] = function(info, szFont)
        local aDesignation
        if info.prefix then
            aDesignation = Table_GetDesignationPrefixByID(info.id, info.forceid)
        else
            aDesignation = g_tTable.Designation_Postfix:Search(info.id)
        end
        if aDesignation then
            local szName = "[" .. aDesignation.szName .. "]"
            -- return MakeDesignationLink("["..aDesignation.szName.."]", szFont, info.id, info.prefix), szName
            return szName, szName
        end
    end,
    ["eventlink"] = function(info, szFont)
        -- return MakeEventLink(info.name, szFont, info.name, info.linkinfo), info.name
        return info.name, info.name
    end,

    ["pet"] = function(info, szFont)
        local tPet = Table_GetFellowPet(info.id)
        if tPet then
            local szName = "[" .. tPet.szName .. "]"
            --return MakePetLink(szName, szFont..GetPetFontColorByQuality(tPet.nQuality, true), info.id), szName
            return szName, szName
        end
    end,

    ["land"] = function(info, szFont)
        if info.landindex == 0 and GetHomelandMgr() and GetHomelandMgr().IsPrivateHomeMap(info.mapid) then
            local tLine = Table_GetPrivateHomeSkin(info.mapid, info.index)
            if tLine and tLine.szSkinName then
                local szName = "[" .. FormatString(g_tStrings.STR_LINK_PRIVATE, tLine.szSkinName) .. "]"
                --return MakeLandLink(szName, szFont .. " r=186 g=251 b=223", info.index, info.mapid, info.copyindex, info.landindex), szName
                return szName, szName
            end
        else
            local szName = Homeland_GetHomeName(info.mapid, info.landindex)
            if szName then
                szName = "[" .. FormatString(g_tStrings.STR_LINK_LAND, szName, info.index) .. "]"
                --return MakeLandLink(szName, szFont .. " r=186 g=251 b=223", info.index, info.mapid, info.copyindex, info.landindex), szName
                return szName, szName
            end
        end
    end,

    ["gamegift"] = function(info, szFont)
        -- return MakeGameGiftLink(info.ownername, szFont, info.giftid)
        return info.ownername
    end,

    ["toybox"] = function(info, szFont)
        local tLine = Table_GetToyBox(info.id)
        -- return MakeToyLink(tLine.szName, szFont, info.id)
        return tLine.szName
    end
}

local _tTalkDecodeFuncSpecial = {
    ["richtext"] = function(info, szFont)
        --怕工作室或者插件利用这个去拼一些奇怪的东西，先只给LOG使用
        if info then
            return info.text
        end
    end,
}

function Global.OnAnnounceTalk()
    local nChannel = arg0
    local bChatShow = arg1
    local bScrollShow = arg2
    local bCalendarShow = arg3
    local bBossTip = arg4
    local bCountDown = arg5
    local bScrollShowGM = arg6
    local bScrollShowFireworks = arg7
    local bSkillTip = arg8
    local szData = arg9
    local bFilter = arg10
    local bRookieChannel = arg11

    local t = nil
    local szMsgType = nil
    local szMsg = ""
    local szPlainText = ""
    local szFont = ""
    local bHasSelfInIt = false
    local player = GetClientPlayer()
    if not player then
        return
    end

    t = ParseTalkData(szData, false) or {}
    if not t then
        return
    end

    t = ChatData.PreProcessTalkData(nil, t)
    local bTreatedAsScrollShow = bScrollShow or bScrollShowGM--策划要求ScrollShowFireworks跑马灯不显示
    local bUsePlainText = true --(bTreatedAsScrollShow or bCalendarShow)
    local func, tag, plain

    local bIsFireworks = false -- 是否是烟花公告

    for k, v in ipairs(t) do
        --处理格式化文本
        if v.type == "text" and string.sub(v.text, 1, string.len("<text>")) == "<text>" then
            if bUsePlainText then
                string.gsub(v.text, "text=\"(.-)\"", function(context)
                    szPlainText = szPlainText .. context
                end)
            end
            szMsg = szMsg .. v.text
        elseif v.type == "eventlink" and v.linkinfo == "Fireworks/true" then
            bIsFireworks = true
        else
            local bResult, szResult = ChatHelper.DecodeTalkData(v, 0, nChannel)
            szPlainText = szPlainText .. (szResult or "")

            if v.type == "name" and v.name == UI_GetClientPlayerName() then
                bHasSelfInIt = true
            end
        end
    end


    szPlainText = g2u(szPlainText)

    if bChatShow then
        Event.Dispatch(EventType.OnGetChatMsg, szPlainText)
    end

    if bTreatedAsScrollShow then
        if bScrollShow then
            szMsgType = "MSG_GM_ANNOUNCE"
        elseif bScrollShowGM then
            szMsgType = "MSG_GM_ANNOUNCE_FOR_GM"
        else
            szMsgType = "MSG_GM_ANNOUNCE_FOR_FIREWORKS"
        end

        TipsHelper.ShowAnnounceTip({ szMsg = szPlainText })
    end

    if bChatShow or bRookieChannel then
        local bFilterFlag = not ChatData.IsSystemMsgFiltered(nChannel, szPlainText)
        local bFireworksFlag = not bIsFireworks or ChatData.IsSystemNoticeDisplayFireworks()
        if bHasSelfInIt or (bFilterFlag and bFireworksFlag) then
            if bChatShow then
                ChatData.Append(szPlainText, 0, nChannel or PLAYER_TALK_CHANNEL.SYSTEM_NOTICE, false, "")
            end

            if bRookieChannel then
                nChannel = PLAYER_TALK_CHANNEL.IDENTITY
                ChatData.Append(szPlainText, 0, nChannel or PLAYER_TALK_CHANNEL.SYSTEM_NOTICE, false, "", nil, nil, nil, nil, nil,
            nil, nil, nil, nil, nil, nil, nil, nil, bRookieChannel)
            end
        end
    end

    if bBossTip and t[1] and t[1].text then
        TipsHelper.ShowCampHint(tonumber(t[1].text))
    end

    if bSkillTip and t[1] and t[1].text then
        TipsHelper.ShowWinterFestivalSkillHint(tonumber(t[1].text))
    end
end


-- 在这些界面上禁止弹出获取列表
local _tBlackListForShowRewardList = {
    "PanelTask",
    "PanelPlotDialogue",
    "PanelOldDialogue",
    "PanelChooseDLC",
    "PanelPassage",
    "PanelFactionWarehouse",
    "PanelAccountsWarehouse",
    "PanelPokerMain",
    "PanelMahjongMain",
    "PanelRevive",
    "PanelPowerUp",
}

Global.tWhiteListForShowRewardList = {
    --[501] = true,
}
function Global.CanShowRewardList()
    local bShow = false
    -- 有上层界面挡住
    if self.HaveFullScreenUI() then
        local nTopViewID = UIMgr.GetLayerTopViewID(UILayer.Page, IGNORE_TEACH_VIEW_IDS)
        if nTopViewID then
            bShow = true
            for _, szViewKey in ipairs(_tBlackListForShowRewardList) do
                if nTopViewID == VIEW_ID[szViewKey] then
                    bShow = false
                    break
                end
            end
            -- 不在黑名单里，且在白名单内才可以展示全屏奖励
            bShow = bShow and Global.tWhiteListForShowRewardList[nTopViewID]
        end
    end
    -- 正在批量接收奖励
    if Global.bRecevingAward then
        bShow = false
    end
    return bShow
end

function Global.SetShowRewardListEnable(nViewID, bEnable)
    if type(nViewID) ~= "number" then return end
    Global.tWhiteListForShowRewardList[nViewID] = bEnable
end

Global.tBlackListForLeftRewardTips = {
    --[501] = true,
}
function Global.CanShowLeftRewardTips()
    local bShow = true
    -- 有上层界面挡住
    if self.HaveFullScreenUI() then
        local nTopViewID = UIMgr.GetLayerTopViewID(UILayer.Page, IGNORE_TEACH_VIEW_IDS)
        if nTopViewID then
            -- 不在黑名单里才可以展示左下角奖励
            bShow = not Global.tBlackListForLeftRewardTips[nTopViewID]
        end
    end

    return bShow
end

function Global.SetShowLeftRewardTipsEnable(nViewID, bEnable)
    Global.tBlackListForLeftRewardTips[nViewID] = not bEnable
end

function Global.AddtBlackListForShowRewardList(szPanelName)
    if not table.contain_value(_tBlackListForShowRewardList, szPanelName) then
        table.insert(_tBlackListForShowRewardList, szPanelName)
    end
end

function Global.RemovetBlackListForShowRewardList(szPanelName)
    table.remove_value(_tBlackListForShowRewardList, szPanelName)
end

function Global.HaveFullScreenUI()
    local nLen = UIMgr.GetLayerStackLength(UILayer.Page, IGNORE_TEACH_VIEW_IDS)
    return nLen > 0
end


-- 稳定排序(插入排序法)
-- 注: fnCompare中的比较需要把等于作为true返回
function Global.SortStably(arr, fnCompare)
    repeat
        if not arr or #arr == 0 then
            break
        end
        if not fnCompare then
            error()
        end

        for nCurIndex = 2, #arr do
            local v = arr[nCurIndex]
            local nInsertIndex = nCurIndex
            -- 找到插入位置
            for i = nCurIndex - 1, 1, -1 do
                if fnCompare(arr[i], v) then
                    break
                else
                    nInsertIndex = i
                end
            end
            -- 后移出空位并插入
            if nInsertIndex < nCurIndex then
                for i = nCurIndex, nInsertIndex + 1, -1 do
                    arr[i] = arr[i - 1]
                end
                arr[nInsertIndex] = v
            end
        end

    until true
end

function Global.OnPlayerDisplayDataUpdate(bImmediately)
    if not g_pClientPlayer then
        return
    end

    if not Storage.Player.bShowFightingNum then
        return
    end

    -- 这里等10帧再处理，因为比如像C界面切套装配置，会一下来来很多，导致战力提示变化取的是最后一次的，会有显示问题
    if not bImmediately then
        Timer.DelTimer(Global, Global.nPlayerDisplayDataUpdateTimerID)
        Global.nPlayerDisplayDataUpdateTimerID = Timer.AddFrame(Global, 10, function()
            Global.OnPlayerDisplayDataUpdate(true)
        end)
        return
    end

    local szText = ""
    local bChanged = false
    local nAttackPVP, nToughPVP, nTherapyPVP, nAttackPVE, nToughPVE, nTherapyPVE = PlayerData.GetAttackAndToughScore(g_pClientPlayer)
    local tInfo = PlayerData.GetShowInfo(g_pClientPlayer)
    local bShowTherapy = tInfo.bShowTherapy
    local bTherapyMainly = tInfo.bTherapyMainly
    local nPVPSkillAttackScore, nPVPSkillToughScore = 0, 0
    local nPVESkillAttackScore, nPVESkillToughScore = 0, 0
    local tbData = {}

    local nAttack, nSkillAttackScore = nAttackPVE, nPVESkillAttackScore
    local nTough, nSkillToughScore = nToughPVE, nPVESkillToughScore
    local nHeal, nSkillHealScore = nTherapyPVE, nPVESkillAttackScore
    local nLastAttack, nLastTough, nLastHeal = self._tLastPlayerDisplayData.nLastAttackPVE, self._tLastPlayerDisplayData.nLastToughPVE, self._tLastPlayerDisplayData.nLastHealPVE
    if Storage.Player.bShowPVPSkillScore then
        nAttack, nSkillAttackScore = nAttackPVP, nPVPSkillAttackScore
        nTough, nSkillToughScore = nToughPVP, nPVPSkillToughScore
        nHeal, nSkillHealScore = nTherapyPVP, nPVPSkillAttackScore
        nLastAttack, nLastTough, nLastHeal = self._tLastPlayerDisplayData.nLastAttackPVP, self._tLastPlayerDisplayData.nLastToughPVP, self._tLastPlayerDisplayData.nLastHealPVP
    end

    -- 攻击变化
    nAttack = nSkillAttackScore + nAttack
    if nLastAttack and nLastAttack ~= nAttack and not bTherapyMainly then
        local nDelta = nAttack - nLastAttack
        tbData[1] = { value = nAttack, delta = nDelta, }  -- 攻击
    end
    -- 治疗变化
    nHeal = nSkillHealScore + nHeal
    if nLastHeal and nLastHeal ~= nHeal and bTherapyMainly then
        local nDelta = nHeal - nLastHeal
        tbData[2] = { value = nHeal, delta = nDelta, }  -- 治疗
    end

    -- 防御变化
    nTough = nSkillToughScore + nTough
    if nLastTough and nLastTough ~= nTough then
        local nDelta = nTough - nLastTough
        tbData[3] = { value = nTough, delta = nDelta, }  -- 防御
    end

    if Storage.Player.bShowPVPSkillScore then
        self._tLastPlayerDisplayData.nLastAttackPVP = nAttack
        self._tLastPlayerDisplayData.nLastToughPVP = nTough
        self._tLastPlayerDisplayData.nLastHealPVP = nHeal
    else
        self._tLastPlayerDisplayData.nLastAttackPVE = nAttack
        self._tLastPlayerDisplayData.nLastToughPVE = nTough
        self._tLastPlayerDisplayData.nLastHealPVE = nHeal
    end

    if table.get_len(tbData) > 0 then
        TipsHelper.ShowEquipScore(tbData)
    end
end

function Global.OnUpdatePlayerDesignation(dwID)
    local player = dwID and GetPlayer(dwID) or GetClientPlayer()
    if player then
        player.SetDesignationContent(GetPlayerDesignation(player.dwID), true)
    end
end

function Global.OnAcuireDesignation(nPrefix, nPostfix)
    if nPrefix ~= 0 then
        TipsHelper.ShowNewDesignation(nPrefix, true)
    end

    if nPostfix ~= 0 then
        TipsHelper.ShowNewDesignation(nPostfix, false)
    end

    RedpointHelper.PersonalTitle_SetNew(nPrefix, nPostfix, false, true)
end

function Global.OnDesignationAnnounce(szName, nPrefix, nPostfix, nChannel)
    -- if GetClientPlayer().szName == szName then
    --     RedpointHelper.PersonalTitle_SetNew(nPrefix, nPostfix, false, true)
    --     return
    -- end
end

function Global.OnSetDesignationGeneration(dwID, nGeneration, nCharacter)
    local player = GetClientPlayer()
    if dwID == player.dwID then
        local nPrefix = player.GetCurrentDesignationPrefix()
        local nPostfix = player.GetCurrentDesignationPostfix()
        local nGeneration = player.GetDesignationGeneration()
        local nCharacter = player.GetDesignationByname()
        local bShow = player.GetDesignationBynameDisplayFlag()
        local nForceID = player.dwForceID
        local aGen = g_tTable.Designation_Generation:Search(nForceID, nGeneration)
        local szDesignation = ""
        if aGen then
            szDesignation = szDesignation .. aGen.szName
            if aGen.szCharacter and aGen.szCharacter ~= "" then
                local aCharacter = g_tTable[aGen.szCharacter]:Search(nCharacter)
                if aCharacter then
                    szDesignation = szDesignation .. aCharacter.szName
                end
            end
            RedpointHelper.PersonalTitle_SetNew(nil, nil, true, true)
        end
        local szText = string.gsub(g_tStrings.STR_GET_GENERATION, "\n", "")
        OutputMessage("MSG_DESGNATION", FormatString(szText, UIHelper.GBKToUTF8(szDesignation)))

        --门派称号升级时刷新称号显示
        if bShow then
            player.SetCurrentDesignation(nPrefix, nPostfix, not bShow)
            player.SetCurrentDesignation(nPrefix, nPostfix, bShow)
        end
    else
        local player = GetPlayer(dwID)
        if player then
            local aGen = g_tTable.Designation_Generation:Search(player.dwForceID, nGeneration)
            local szDesignation = ""
            if aGen then
                szDesignation = szDesignation .. aGen.szName
                if aGen.szCharacter and aGen.szCharacter ~= "" then
                    local aCharacter = g_tTable[aGen.szCharacter]:Search(nCharacter)
                    if aCharacter then
                        szDesignation = szDesignation .. aCharacter.szName
                    end
                end
            end
            local szText = string.gsub(g_tStrings.STR_OTHER_GET_GENERATION, "\n", "")
            OutputMessage("MSG_DESGNATION", FormatString(szText, "[" .. UIHelper.GBKToUTF8(player.szName) .. "]", UIHelper.GBKToUTF8(szDesignation)))
        end
    end
end

function Global.OpenViewByLink(szLinkArg)
    if szLinkArg == "FBlistMonster" then
        UIMgr.OpenSingle(true, VIEW_ID.PanelBaizhanMain)
    elseif szLinkArg == "FBlist.Open" then
        UIMgr.OpenSingle(true, VIEW_ID.PanelDungeonEntrance)
    elseif szLinkArg == "CampMaps.Open" then
        CampData.OnClickCampMap()
    elseif szLinkArg == "FBlistRaid" then
        UIMgr.OpenSingle(true, VIEW_ID.PanelDungeonEntrance, {bRaid = true})
    elseif szLinkArg == "GuildPanel" then
        UIMgr.OpenSingle(true, VIEW_ID.PanelFactionManagement)
    elseif szLinkArg == "FBlist.LinkWeeklyTeamDungeon" then
        UIMgr.OpenSingle(true, VIEW_ID.PanelDungeonEntrance, {bLinkWeeklyTeamDungeon = true})
    elseif szLinkArg == "FamePanel" then
        UIMgr.OpenSingle(true, VIEW_ID.PanelFame)
    elseif szLinkArg == "ArenaQueue.Open" then
        UIMgr.OpenSingle(true, VIEW_ID.PanelPvPMatching)
    elseif szLinkArg == "DesertStorm" then
        UIMgr.OpenSingle(true, VIEW_ID.PanelImpasseMatching)
    elseif szLinkArg == "BattleField" then
        UIMgr.OpenSingle(true, VIEW_ID.PanelBattleFieldInformation)
    elseif szLinkArg == "GuildLeagueMatches.Open" or szLinkArg == "GuildLeagueMatches" then
        UIMgr.OpenSingle(true, VIEW_ID.PanelFactionChampionship)
    elseif szLinkArg == "JJCRougePanel.Open" then
        UIMgr.OpenSingle(true, VIEW_ID.PanelYangDaoMain)
    elseif szLinkArg == "SeasonRankPanel.Open" then
        UIMgr.OpenSingle(true, VIEW_ID.PanelSeasonLevel)
    elseif szLinkArg == "HorsePanel.Open" then
        UIMgr.OpenSingle(true, VIEW_ID.PanelSaddleHorse)
    else
        szLinkArg = szLinkArg:match("GameGuideFunction.(%w+)") or szLinkArg
        CollectionFuncList.Excute(szLinkArg)
    end
end

function Global.OpenHorsePanel()
    if BattleFieldData.IsInTreasureBattleFieldMap() and not BattleFieldData.IsInXunBaoBattleFieldMap() then
        UIMgr.Open(VIEW_ID.PanelBattleFieldPubgEquipBagRightPop, 2)
    elseif BattleFieldData.IsInXunBaoBattleFieldMap() then
        PvpExtractData.OpenBagAndHorse()
    else
        UIMgr.Open(VIEW_ID.PanelSaddleHorse)
    end
end

function Global.OnRemoveDesignation(nPrefix, nPostfix)
    local szChannel = "MSG_DESGNATION"
    local szFont = GetMsgFontString(szChannel)
    local szNameLink = GetFormatText(g_tStrings.STR_YOU, "1 " .. szFont)

    local szText
    if nPrefix ~= 0 then
        local aDesignation = Table_GetDesignationPrefixByID(nPrefix, UI_GetPlayerForceID())
        if aDesignation then
            local aInfo = GetDesignationPrefixInfo(nPrefix)
            local bWorld = aInfo.nType == DESIGNATION_PREFIX_TYPE.WORLD_DESIGNATION
            local bCampTitle = aInfo.nType == DESIGNATION_PREFIX_TYPE.MILITARY_RANK_DESIGNATION
            if bWorld then
                szText = g_tStrings.STR_LOSE_DESGNATION_WORLD
            elseif bCampTitle then
                szText = g_tStrings.STR_LOSE_DESGNATION_TITLE
            else
                szText = g_tStrings.STR_LOSE_DESGNATION_PREFIX
            end
            szText = string.gsub(szText, "<link 0>", g_tStrings.STR_YOU)
            szText = string.gsub(szText, "<link 1>", DesignationMgr.GetDesignationText(aDesignation))
        end
    end

    if nPostfix ~= 0 then
        local aDesignation = g_tTable.Designation_Postfix:Search(nPostfix)
        if aDesignation then
            szText = g_tStrings.STR_LOSE_DESGNATION_POSTFIX
            szText = string.gsub(szText, "<link 0>", g_tStrings.STR_YOU)
            szText = string.gsub(szText, "<link 1>", DesignationMgr.GetDesignationText(aDesignation))
        end
    end

    RedpointHelper.PersonalTitle_SetNew(nPrefix, nPostfix, false, false)

    if szText then
        szText = string.gsub(szText, "\n", "")
        TipsHelper.ShowNormalTip(szText, true)
    end
end

---comment 获取角色对象
---@param dwID number 角色ID
---@return KCharacter pCharacter 返回角色
function Global.GetCharacter(dwID)
    if IsPlayer(dwID) then
        return PlayerData.GetPlayer(dwID)
    else
        return NpcData.GetNpc(dwID)
    end
end

-- Widget Touch Down Event Called by C++
function Global.OnWidgetTouchDown()
    Event.Dispatch(EventType.OnWidgetTouchDown)
    Event.Dispatch(EventType.HideAllHoverTips)
end

function Global.InitFirstLoginSkill()
    local hPlayer = GetClientPlayer()
    if not hPlayer then
        return
    end
    --local dwSelectKungfuIndex = hPlayer.dwSelectKungfuIndex
    --
    --local tSkill = Table_GetFirstLoginSkill(dwSelectKungfuIndex)
    --if not tSkill then
    --    return
    --end

    local pose_initiativeskillid = {
        [POSE_TYPE.BROADSWORD] = 16454,
        [POSE_TYPE.DOUBLE_BLADE] = 16608,
        [POSE_TYPE.SHEATH_KNIFE] = 16459,
    }

    for nPoseIndex, szKey in ipairs(STORAGE_DXACTIONBAR_ENUM_LIST) do
        Storage_Server.SetData(szKey, 26, DX_ACTIONBAR_TYPE.SKILL, 9007)
        Storage_Server.SetData(szKey, 27, DX_ACTIONBAR_TYPE.SKILL, UI_SKILL_JUMP_ID)
        Storage_Server.SetData(szKey, 28, DX_ACTIONBAR_TYPE.SKILL, 9002)

        Storage_Server.SetData(szKey, 29, DX_ACTIONBAR_TYPE.SKILL, UI_DXSKILL_DASH_ID)

        Storage_Server.SetData(szKey, 30, DX_ACTIONBAR_TYPE.SKILL, UI_DXSKILL_DASH_ID)
        Storage_Server.SetData(szKey, 31, DX_ACTIONBAR_TYPE.SKILL, UI_DXSKILL_YAOTAI_ID)
        Storage_Server.SetData(szKey, 32, DX_ACTIONBAR_TYPE.SKILL, UI_DXSKILL_YINGFENG_ID)
        Storage_Server.SetData(szKey, 33, DX_ACTIONBAR_TYPE.SKILL, UI_DXSKILL_LINGXIAO_ID)

        if g_pClientPlayer and g_pClientPlayer.dwForceID == FORCE_TYPE.BA_DAO and nPoseIndex <= 3 then
            Storage_Server.SetData(szKey, 9, DX_ACTIONBAR_TYPE.SKILL, nPoseIndex == POSE_TYPE.BROADSWORD and
                    pose_initiativeskillid[POSE_TYPE.BROADSWORD] or l_badaoposeskill[POSE_TYPE.BROADSWORD])
            Storage_Server.SetData(szKey, 10, DX_ACTIONBAR_TYPE.SKILL, nPoseIndex == POSE_TYPE.SHEATH_KNIFE and
                    pose_initiativeskillid[POSE_TYPE.SHEATH_KNIFE] or l_badaoposeskill[POSE_TYPE.SHEATH_KNIFE])
            Storage_Server.SetData(szKey, 11, DX_ACTIONBAR_TYPE.SKILL, nPoseIndex == POSE_TYPE.DOUBLE_BLADE and
                    pose_initiativeskillid[POSE_TYPE.DOUBLE_BLADE] or l_badaoposeskill[POSE_TYPE.DOUBLE_BLADE])
        end
    end
end

Global.m_bInLoading = false
Global.m_bInBackgroundMode = false
local m_bClientPerf = false
local m_flushGameInfoTime = 0
local m_SendGameInfoStepTime = 1000

-- 记录玩家最后操作时间，用于长时间未操作自动闭麦
local AUTO_CLOSE_MIC_DURATION = 10 * 60 * 1000 -- 10分钟（毫秒）
Global.m_nAutoCloseMicLastOpTime = nil
Global.m_tAutoCloseMicHandler = {className = "GlobalAutoCloseMicHandler"}

function Global.ResetLastOperateTime()
    Global.m_nAutoCloseMicLastOpTime = GetTickCount()
end

function Global.CheckAutoCloseMic(nNowTime)
    if not Global.m_nAutoCloseMicLastOpTime then
        Global.m_nAutoCloseMicLastOpTime = nNowTime
        return
    end

    if not GVoiceMgr.IsInitSDK() then
        return
    end

    Global.InitAutoCloseMicCheck()

    if nNowTime - Global.m_nAutoCloseMicLastOpTime >= AUTO_CLOSE_MIC_DURATION then
        -- 实时语音
        if GVoiceMgr.IsMicOpened() then
            GVoiceMgr.CloseMic()
            GVoiceMgr.SetMicState(MIC_STATE.CLOSE)
            OutputMessage("MSG_SYS", g_tStrings.GVOICE_AUTO_CLOSE_TEAM_MIC_TIP)
        end

        -- 房间语音
        local szRoomID = RoomVoiceData.GetCurVoiceRoomID()
        if RoomVoiceData.IsMicOpen(szRoomID) then
            RoomVoiceData.CloseMic(szRoomID)
            OutputMessage("MSG_SYS", g_tStrings.GVOICE_AUTO_CLOSE_ROOM_MIC_TIP)
        end

        Global.ResetLastOperateTime()

        LOG.INFO("[Global] Auto close mic due to long idle time.")
    end
end

function Global.InitAutoCloseMicCheck()
    if Global.m_bAutoCloseMicInit then
        return
    end

    Global.m_bAutoCloseMicInit = true

    Global.ResetLastOperateTime()

    Event.Reg(Global.m_tAutoCloseMicHandler, EventType.OnKeyboardDown, function()
        Global.ResetLastOperateTime()
    end)

    Event.Reg(Global.m_tAutoCloseMicHandler, EventType.OnSceneTouchBegan, function()
        Global.ResetLastOperateTime()
    end)

    Event.Reg(Global.m_tAutoCloseMicHandler, EventType.OnWidgetTouchDown, function()
        Global.ResetLastOperateTime()
    end)
end

function Global.ChangeClientPerfState()
    -- LOG.INFO("[PerfStat] Global.ChangeClientPerfState, perf:%s loading:%s background:%s psm:%s",
    --     tostring(m_bClientPerf), tostring(Global.m_bInLoading), tostring(Global.m_bInBackgroundMode), tostring((PSMMgr.IsEnterPSMMode()))
    -- )
    if m_bClientPerf then
        if Global.m_bInLoading or Global.m_bInBackgroundMode or PSMMgr.IsEnterPSMMode() then
            m_bClientPerf = false
            PauseClientPerf(true)
        end
    else
        if not (Global.m_bInLoading or Global.m_bInBackgroundMode or PSMMgr.IsEnterPSMMode()) then
            m_bClientPerf = true
            PauseClientPerf(false)
            m_flushGameInfoTime = GetTickCount() + m_SendGameInfoStepTime
        end
    end
end

function Global.Update()
    if m_nEndFrame and m_nEndFrame > 0 then
        local nLeftSeconds = (m_nEndFrame - GetLogicFrameCount()) / 16
        nLeftSeconds = math.ceil(nLeftSeconds)
        if nLeftSeconds >= 1 and m_nLastShowSecond ~= nLeftSeconds then
            if m_CalculaPKType == "SLAY_CLOSE" then
                LOG.WARN("nLeftSeconds %d", nLeftSeconds)
                if nLeftSeconds == 30 then
                    TipsHelper.PlayCountDown(nLeftSeconds, false)
                    OutputMessage("MSG_ANNOUNCE_NORMAL", FormatString(g_tStrings.STR_PK_CLOSE_SLAY_CALCULAGRAPH, nLeftSeconds))
                end
                m_nLastShowSecond = nLeftSeconds
            end
        end
    end

    local nTime = GetTickCount()
    if m_bClientPerf and m_flushGameInfoTime < nTime then
        local nFps = GetFPS()
        UpdateClientPerf(nFps, nFps, 0)
        m_flushGameInfoTime = nTime + m_SendGameInfoStepTime
    end

    if not Global.nUITickCount then
        Global.nUITickCount = 0
    end
    Global.nUITickCount = Global.nUITickCount + 1

    Global.CheckAutoCloseMic(nTime)
end

Timer.AddFrameCycle(Global, 1, Global.Update)

local tPayResultCodeToMessage = {
    [2000] = "支付失败，请稍后再试[1]",
    [2010] = "创建订单失败，请稍后再试",
    [2020] = "订单金额错误，请核对后再试",
    [2021] = "货币错误，请核对后再试",
    [2030] = "用户信息错误，请核对后再试",
    [2040] = "货品数量错误，请核对后再试",
    [2050] = "支付信息错误，请稍后再试",
    [2060] = "支付失败，请稍后再试[2]",
    [2070] = "重复操作，请稍后再试",
    [2080] = "正在支付中，请稍等",
    [2090] = "支付结果未知，请确认订单支付状态",
    [2100] = "支付取消",
}

local tPayChannelCodeToMessage = {
    ["-12"] = "未满8周岁用户不能充值",
    ["-13"] = "8周岁以上未满16周岁未成年单次充值不得超过50元人民币",
    ["-14"] = "16周岁以上未满18周岁未成年单次充值不得超过100元人民币",
    ["-15"] = "8周岁以上未满16周岁未成年每月充值累计金额不得超过200元人民币",
    ["-16"] = "16周岁以上未满18周岁未成年每月充值累计金额不得超过400元人民币",
}

local tSpecialPayChannelCodeToMessage = {
    ["-5000"] = "云游戏iOS版本暂不支持充值",
}

Event.Reg(Global, "XGSDK_OnPayResult", function(szResultType, nCode, szMsg, szChannelCode, szChannelMsg)
    LOG.DEBUG("XGSDK_OnPayResult szResultType=%s nCode=%d szMsg=%s szChannelCode=%s szChannelMsg=%s",
            szResultType, nCode, szMsg, szChannelCode, szChannelMsg)

    local szShowMessage = tPayResultCodeToMessage[nCode]
    if nCode == 2010 then
        -- 当code为2010时，且渠道错误码有相应的具体提示消息，需要以这个为准来显示提示消息，如防沉迷相关错误码
        local szChannelShowMessage = tPayChannelCodeToMessage[szChannelCode]
        if szChannelShowMessage ~= nil then
            szShowMessage = szChannelShowMessage
        end
    elseif nCode == 2000 then
        local szChannelShowMessage = tSpecialPayChannelCodeToMessage[szChannelCode]
        if szChannelShowMessage ~= nil then
            szShowMessage = szChannelShowMessage
        end
    end
    if szChannelCode == "-104" then
        -- 移动端充值功能被封禁的情况下，使用channelMsg弹提示
        szShowMessage = szChannelMsg
    end

    -- Success  Cancel  Fail    Others  Progress

    -- 取消和失败的情况下取消提示标记，其他的情况认为仍需要提示
    if szResultType == "Cancel" or szResultType == "Fail" then
        XGSDK.UpdateNeedSuccessNotify(string.format("支付结果%s", szResultType), false)
    end

    if szResultType == "Cancel" then
        XGSDK.TryDeleteBattlePassOrder()
    end

    if szResultType ~= "Success" and szShowMessage ~= nil then
        TipsHelper.ShowNormalTip(szShowMessage)
    elseif szResultType == "Success" then
        if XGSDK.szPayType == PayData.RechargeTypeEnum.szBuyItemWithRMB then
            TipsHelper.ShowNormalTip("购买成功")
        else
            -- note: 通宝、点卡、月卡充值成功时可能数据还未同步到客户端，因此其提示在实际收到对应数值变动的事件时提示
            -- XGSDK.lua 中监听 SYNC_COIN OnSyncRechargeInfo 事件
        end
    end
end)

-- 用于判断当前提示充值弹窗是否已开启，避免多次弹出
local bHasOpenRemindRecharge = false

--- 登录界面触发，提示玩家充值时长
--- 1. 在选择角色界面，如果玩家剩余时间在1分钟到2天内，弹出该提示
--- 2. 玩家没有剩余时长，点了进入游戏，服务器返回特定错误码时触发
function RemindRecharge(bOnLoginEnterGame)
    if bHasOpenRemindRecharge or UIMgr.IsViewOpened(VIEW_ID.PanelTopUpMain) then
        LOG.DEBUG("RemindRecharge has open remind tip or recharge view, do not show again")
        return
    end

    local _, _, _, nFeeEndTime = Login_GetTimeOfFee()

    local nCurrentTime = GetCurrentTime()
    local nRemainingTime = nFeeEndTime - nCurrentTime
    if nRemainingTime < 0 then
        nRemainingTime = 0
    end
    if bOnLoginEnterGame then
        --- 当从登录界面触发时，说明玩家已经没有时长了。在没有时长的情况下，每次尝试登录的时候，会从paysys同步最新的 nFeeEndTime 值下来，此时其值为当前时间。
        ---     paysys同学：【dwEndTimeOfFee 是会变的，paysys这边如果用户时长是不足的，这个字段是赋值为当前时间】
        --- 会导致本次登录进选择角色界面后，多次尝试登录进入游戏时计算出的剩余时长会越来越长（当前时间 - 账号登录时间），很奇怪
        --- 这种情况下，剩余时间直接用0就可以了
        nRemainingTime = 0
    end
    local szLeftTime = PayData.FormatPointTime(nRemainingTime)

    local szContent = "游玩时长余额不足，请及时充值点卡或月卡。"
    if Platform.IsIos() then
        szContent = "游玩时长余额不足，请及时充值点卡。"
    end
    szContent = szContent .. string.format("\n剩余游戏时长: %s", szLeftTime)

    --- 2024.7.18 - 7.29 内，登录界面点进入游戏时触发的情况，使用单独的文案
    if bOnLoginEnterGame then
        if Global.CanOpen_718_729_Tips() then
            szContent = "游玩时长余额不足，请及时充值点卡或月卡，7月29日7:00前累计充值30元游戏时长即可额外获得价值280元金发。"
            if Platform.IsIos() then
                --- ios没有月卡
                szContent = "游玩时长余额不足，请及时充值点卡，7月29日7:00前累计充值30元游戏时长即可额外获得价值280元金发。"
            end
        end
    end

    local dialog = UIHelper.ShowConfirm(szContent, function()
        UIMgr.Open(VIEW_ID.PanelTopUpMain, true)
        bHasOpenRemindRecharge = false
    end, function()
        bHasOpenRemindRecharge = false
    end, false)
    bHasOpenRemindRecharge = true
    dialog:SetButtonContent("Confirm", "前往充值中心")
    dialog:SetButtonContent("Cancel", "取消")
end

function Global.CanOpen_718_729_Tips()
    -- 2024-07-18 07:00:00
    local nStartTime = 1721257200
    -- 2024-07-29 07:00:00
    local nEndTime = 1722207600

    local nCurrentTime = Global.Get_718_729_CurrentTime()

    return nCurrentTime >= nStartTime and nCurrentTime < nEndTime
end

function Global.Get_718_729_CurrentTime()
    return GetCurrentTime()
end

-- 限制充值提示弹窗频率
local CAN_OPEN_INTERVAL_TIME = 10 * 60
local nLastOpenTime

Event.Reg(Global, "ACCOUNT_END_TIME", function(nLeftTime)
    LOG.DEBUG("ACCOUNT_END_TIME nLeftTime=%s", tostring(nLeftTime))

    local nCurTime = GetCurrentTime()
    if nLastOpenTime then
        local nNextOpenTime = nLastOpenTime + CAN_OPEN_INTERVAL_TIME
        if nCurTime < nNextOpenTime then
            LOG.DEBUG("ACCOUNT_END_TIME nLastOpenTime=%d nCurTime=%d won't open until %d", nLastOpenTime, nCurTime, nNextOpenTime)
            return
        end
    end
    nLastOpenTime = nCurTime

    ---@see UIChargeTimeView
    UIMgr.OpenSingle(false, VIEW_ID.PanelChargeTime)
end)

Event.Reg(Global, "KICK_ACCOUNT_NOTIFY", function(nReason, nRemainderTime)
    LOG.INFO("KICK_ACCOUNT_NOTIFY, nReason = %s, nRemainderTime = %s", tostring(nReason), tostring(nRemainderTime))
    if nReason == KICK_ACCOUNT_REASON_CODE.END_OF_DAY_TIME then
        --- fixme: dx的这个流程在 1332401 提交中被移除了，暂时不确定原因，先备注下
        RemindRecharge()
    elseif nReason == KICK_ACCOUNT_REASON_CODE.UNDERAGE_LIMIT then
        if nRemainderTime > 0 then
            local szTime = TimeLib.GetTimeText(nRemainderTime, nil, true)
            local szContent = FormatString(g_tStrings.tbLoginString.BE_PREPARE_KICK_UNDERAGE_LIMIT, UTF8ToGBK(szTime))
            UIHelper.ShowConfirm(GBKToUTF8(szContent))
        else
            g_tbLoginData.bKickAccount = true
            --g_tbLoinData.nKickAccountReason = LOAD_LOGIN_REASON.KICK_OUT_FOR_UNDERAGE_LIMIT
            Global.BackToLogin(false)
        end
    elseif nReason == KICK_ACCOUNT_REASON_CODE.GM_KICK_ACCOUNT then
        g_tbLoginData.bKickAccount = true
        g_tbLoginData.nKickAccountReason = LOAD_LOGIN_REASON.KICK_OUT_BY_GM
        Global.BackToLogin(false)

        if Channel.Is_WLColud() then
            -- 在蔚领云游戏中被顶号的话，需要通知云游戏app去退出本次游戏
            LOG.DEBUG("蔚领云版本游戏被GM踢下线，通知云游戏app")
            XGSDK_WLCloud_OnGameKickAccount(false, "您的账号已被系统强制断开连接。\n如有任何疑问可通过在线客服咨询。")
        end
    end
end)

Event.Reg(Global, "NEW_ACHIEVEMENT", function(dwAchievement)
    TipsHelper.ShowNewAchievement(dwAchievement)
end)

--- 安全锁相关通知处理
Event.Reg(Global, "BANK_LOCK_RESPOND", function(szEvent, nCode)
    if szEvent == "PASSWORD_EXIST" then
        OutputMessage("MSG_ANNOUNCE_NORMAL", g_tStrings.STR_PASSWORD_EXIST)
    elseif szEvent == "PASSWORD_CANNOT_BE_EMPTY" then
        OutputMessage("MSG_ANNOUNCE_NORMAL", g_tStrings.STR_PASSWORD_EMPTY)
    elseif szEvent == "SET_BANK_PASSWORD_SUCCESS" then
        OutputMessage("MSG_ANNOUNCE_NORMAL", g_tStrings.STR_PASSWORD_SET_SUCCESS)
        FireUIEvent("SYNC_PASSWORD_SUCCESS_TO_GM")
    elseif szEvent == "SET_BANK_PASSWORD_FAILED" then
        OutputMessage("MSG_ANNOUNCE_NORMAL", g_tStrings.STR_PASSWORD_SET_FAILURE)
    elseif szEvent == "RESET_BANK_PASSWORD_SUCCESS" then
        OutputMessage("MSG_ANNOUNCE_NORMAL", g_tStrings.STR_PASSWORD_RESET_SUCCESS)
    elseif szEvent == "CANCEL_RESET_BANK_PASSWORD_SUCCESS" then
        OutputMessage("MSG_ANNOUNCE_NORMAL", g_tStrings.STR_PASSWORD_CANCEL_RESET_SUCCESS)
    elseif szEvent == "VERIFY_BANK_PASSWORD_SUCCESS" then
        TipsHelper.ShowImportantBlueTip(g_tStrings.STR_PASSWORD_VERIFY_SUCCESS, false, 1.5)
    elseif szEvent == "VERIFY_BANK_PASSWORD_FAILED" then
        TipsHelper.ShowImportantYellowTip(g_tStrings.STR_PASSWORD_VERIFY_FAILURE, false, 1.5)
    elseif szEvent == "SECURITY_VERIFY_PASSWORD_SUCCESS" then
        local player = GetClientPlayer()
        if player then
            local bTalkLocked = BankLock.Lock_IsChoiceTypeLocked(SAFE_LOCK_EFFECT_TYPE.TALK) --- 聊天锁与其他锁不是一套，需要特别处理
            FireUIEvent("SAFE_LOCK_TALK_UNLOCKED")

            local szMsg
            if (not player.bIsBankPasswordVerified) or bTalkLocked then
                --bInHalfLocked     = true

                local bBankLocked = BankLock.Lock_IsChoiceTypeLocked(SAFE_LOCK_EFFECT_TYPE.BANK)

                if bBankLocked and bTalkLocked then
                    szMsg = g_tStrings.STR_PASSWORD_HALF_VERIFY_SUCCESS_EXCEPT_BANK_AND_TALK
                elseif bBankLocked then
                    szMsg = g_tStrings.STR_PASSWORD_HALF_VERIFY_SUCCESS_EXCEPT_BANK
                else
                    --- 必然成立 bTalkLocked
                    szMsg = g_tStrings.STR_PASSWORD_HALF_VERIFY_SUCCESS_EXCEPT_TALK
                end
            else
                if bTalkLocked then
                    szMsg = g_tStrings.STR_PASSWORD_HALF_VERIFY_SUCCESS_EXCEPT_TALK
                else
                    szMsg = g_tStrings.STR_PASSWORD_VERIFY_SUCCESS
                end
            end
            TipsHelper.ShowImportantBlueTip(szMsg, false, 1.5)
        end
    elseif szEvent == "SECURITY_VERIFY_PASSWORD_FAILED" then
        TipsHelper.ShowImportantYellowTip(g_tStrings.STR_PASSWORD_VERIFY_FAILURE, false, 1.5)
    elseif szEvent == "SECURITY_BIND_DEVICE_VERIFY_PASSWORD_SUCCESS" then
        TipsHelper.ShowImportantBlueTip(g_tStrings.STR_PASSWORD_VERIFY_SUCCESS, false, 1.5)
    elseif szEvent == "SECURITY_BIND_DEVICE_VERIFY_PASSWORD_FAILED" then
        local szMsg = g_tStrings.STR_PASSWORD_VERIFY_FAILURE
        --if nCode == 17 then
        --    szMsg = "设备ID不一致"
        --elseif nCode == 33 then
        --    szMsg = "未绑定密保锁或未开启交易保护"
        --elseif nCode == 58 then
        --    szMsg = "token已过期"
        --end
        TipsHelper.ShowImportantYellowTip(szMsg, false, 1.5)
        LOG.DEBUG("SECURITY_BIND_DEVICE_VERIFY_PASSWORD_FAILED nCode=%d", nCode)
    elseif szEvent == "MODIFY_BANK_PASSWORD_SUCCESS" then
        OutputMessage("MSG_ANNOUNCE_NORMAL", g_tStrings.STR_PASSWORD_MODIFY_SUCCESS)
    elseif szEvent == "BANK_PASSWORD_ANSWER_IS_WRONG" then
        OutputMessage("MSG_ANNOUNCE_NORMAL", g_tStrings.STR_PASSWORD_MODIFY_FAILURE_FOR_WRONG_ANSWER)
    elseif szEvent == "MODIFY_BANK_PASSWORD_FAILED" then
        OutputMessage("MSG_ANNOUNCE_NORMAL", g_tStrings.STR_PASSWORD_MODIFY_FAILURE)
    elseif szEvent == "ANSWER_CANNOT_BE_EMPTY" then
        OutputMessage("MSG_ANNOUNCE_NORMAL", g_tStrings.STR_BANK_PASSWORD_CANT_EMPTY_ANSWER)
    elseif szEvent == "NEED_UNLOCK_FIRST" then
        OutputMessage("MSG_ANNOUNCE_NORMAL", g_tStrings.STR_CHOICE_ERROR_UNLOCK)
    elseif szEvent == "SET_OPTION_SUCCESS" then
        OutputMessage("MSG_ANNOUNCE_NORMAL", g_tStrings.STR_CHOICE_MODIFY_SUCCESS)
    elseif szEvent == "UNLOCK_TIME_LIMIT" then
        OutputMessage("MSG_ANNOUNCE_NORMAL", g_tStrings.STR_TIME_UNLOCK)
    elseif szEvent == "INPUT_TOO_FREQUENT" then
        OutputMessage("MSG_ANNOUNCE_NORMAL", g_tStrings.STR_UNLOCK_FREQUENT)
    elseif szEvent == "VERIFY_FAILURE_TOO_MUCH" then
        OutputMessage("MSG_ANNOUNCE_NORMAL", g_tStrings.STR_VERIFY_FAILURE_TOO_MUCH)
    end
end)

local m_nPunishEndFrame, m_nPunishLastShowSecond

function StopDuelPunishCountDown()
    m_nPunishEndFrame = -1
    m_nPunishLastShowSecond = -1
end

Event.Reg(Global, "LEAVE_DUEL", function()
    ----PK离开战斗中心倒计时开始,设定为10秒
    local dwPunishFrame = 10
    m_nPunishEndFrame = (dwPunishFrame + 0.1) * 1000 + GetTickCount()
    m_nPunishLastShowSecond = -1

    local function fnCountDown()
        local nLeftSeconds = (m_nPunishEndFrame - GetTickCount()) / 1000
        nLeftSeconds = math.floor(nLeftSeconds)

        if nLeftSeconds >= 1 and m_nPunishLastShowSecond ~= nLeftSeconds then
            TipsHelper.OutputMessage("MSG_ANNOUNCE_NORMAL", FormatString(g_tStrings.STR_PK_LEAVE_DUEL_CALCULAGRAPH, nLeftSeconds), false, 0.1)
            m_nPunishLastShowSecond = nLeftSeconds
        end

        if nLeftSeconds >= 1 then
            Timer.AddFrame(Global, 1, fnCountDown)
        end
    end

    fnCountDown()
end)

Event.Reg(Global, "FIGHT_HINT", function(bFight)
    local bOpen = UIMgr.IsViewOpened(VIEW_ID.PanelInjuryHint)
    if not bOpen then
        UIMgr.Open(VIEW_ID.PanelInjuryHint)
    end
    if bFight then
        local scriptView = UIMgr.GetViewScript(VIEW_ID.PanelInjuryHint)
        scriptView:OnEnter()
    end
end)

Event.Reg(Global, "BEGIN_ROLL_ITEM", function(dwDoodadID, dwItemID, nLeftFrame)
    Log("--BEGIN_ROLL_ITEM--")
    local dwFrame = GetLogicFrameCount()
    AuctionData.OnRollCreate(dwFrame, dwDoodadID, dwItemID, nLeftFrame)
    AuctionData.TryOpenAuctionView()
end)

Event.Reg(Global, "ROLL_ITEM", function(...)
    AuctionData.OnPlayerRollItem(...)
end)

Event.Reg(Global, "CANCEL_ROLL_ITEM", function(...)
    AuctionData.OnPlayerCancelRollItem(...)
end)

Event.Reg(Global, "RETURN_DUEL", function()
    StopDuelPunishCountDown()
end)

Event.Reg(Global, "FINISH_DUEL", function()
    StopDuelPunishCountDown()
end)

Event.Reg(Global, "ON_NPC_ASSISTED_RESULT_CODE", function(nRetCode, dwAssistedID)
    OnNpcAssistedResultCode(nRetCode, dwAssistedID)
end)

Event.Reg(Global, "ON_ARENA_COMBO_WIN", function()
    TipsHelper.OutputMessage("MSG_ANNOUNCE_NORMAL", FormatString(g_tStrings.STR_ARENA_V_L2, arg0))
end)

Event.Reg(Global, "ON_SWITCH_MAP", function(nErrorID)
    local strMsg = g_tStrings.tSwitchMap[nErrorID]
    if strMsg then
        OutputMessage("MSG_ANNOUNCE_NORMAL", strMsg)
    end
    if nErrorID ~= SWITCH_MAP.SUCCESS then
        DungeonData.bIsWaitingEnterDungeon = false
    end
end)

Event.Reg(Global, EventType.OpenPartnerSummonPanelForSummon, function()
    UIMgr.Open(VIEW_ID.PanelPartnerSummonPop)
end)

Event.Reg(Global, EventType.On_Partner_TankAttack, function()
    UIHelper.RemoteCallToServer("On_Partner_TankAttack")
end)

Event.Reg(Global, EventType.ShowPartnerMorph, function()
    local tMorphIDList = PartnerData.GetMorphList()
    if #tMorphIDList == 0 then
        ---@see UIPartnerView
        UIMgr.Open(VIEW_ID.PanelPartner, nil, PartnerViewOpenType.Morph)
        return
    end

    PartnerData.bShowMorphInMainCity = true
    Event.Dispatch(EventType.UpdatePartnerMorphShowState)
    Event.Dispatch("OnPartnerMorphChanged")
end)

Event.Reg(Global, EventType.HidePartnerMorph, function()
    PartnerData.bShowMorphInMainCity = false
    Event.Dispatch(EventType.UpdatePartnerMorphShowState)
    Event.Dispatch("OnPartnerMorphChanged")
end)

--Event.Reg(Global, "OPEN_TONG_REPERTORY", function(arg0)
--    print("OPEN_TONG_REPERTORY", arg0)
--
--    if BankLock.CheckHaveLocked(SAFE_LOCK_EFFECT_TYPE.TONG_REPERTORY) then
--        return
--    end
--
--    UIMgr.Open(VIEW_ID.PanelFactionWarehouse, arg0)
--end)

Event.Reg(Global, "BEGIN_CAMERA_ANIMATION", function(dwID, bHideUI, bEnableWord)
    APIHelper.BeginCameraAnimation(dwID, bHideUI, bEnableWord)
end)

Event.Reg(Global, "END_CAMERA_ANIMATION", function()
    APIHelper.EndCameraAnimation()
end)

-- 开/关UI显示
Event.Reg(Global, "EnableUIRender", function(bEnable)
    if bEnable then
        UIMgr.ShowAllLayer()
    else
        UIMgr.HideAllLayer()
    end
end)

-- 开/关UI显示
Event.Reg(Global, "OPEN_BANK", function(arg0)
    UIMgr.OpenSingle(false,VIEW_ID.PanelHalfBag)
    UIMgr.Open(VIEW_ID.PanelHalfWarehouse)
end)

-- 事件跳转
Event.Reg(Global, "EVENT_LINK_NOTIFY", function ()
    local szLinkInfo = arg0
	local szLinkEvent, szLinkArg = szLinkInfo:match("(%w+)/(.*)")
    szLinkEvent = szLinkEvent or szLinkInfo

    if szLinkEvent == "Exterior" then
        CoinShopData.LinkGoods(szLinkArg, true)
    elseif szLinkEvent == "CoinShopTitle" then
        CoinShopData.LinkTitle(szLinkArg, true)
    elseif szLinkEvent == "BuildFace" then
        CoinShopData.LinkFace(szLinkArg, true)
    elseif szLinkEvent == "CoinShopHair" then
        CoinShopData.LinkHair(szLinkArg, true)
    elseif szLinkEvent == "CoinShopMy" then
        CoinShopData.LinkTitle(szLinkArg, false)
    elseif szLinkEvent == "Craft" then
        CraftData.CraftOpenFacture(szLinkArg)
    elseif szLinkEvent == "LinkActivity" then
        local tActivityID = SplitString(szLinkArg, "/")
        for _, szID in ipairs(tActivityID) do
            local nID = tonumber(szID)
            ActivityData.LinkToActiveByID(nID)
        end
    elseif szLinkEvent == "CraftMarkNpc" or szLinkEvent == "CraftMarkCollectN" then
        CraftData.CraftMarkNpc(szLinkArg)
    elseif szLinkEvent == "CraftMarkDoodad" or szLinkEvent == "CraftMarkCollectD" then
        CraftData.CraftMarkDoodad(szLinkArg)
    elseif szLinkEvent == "QuestTip" then
        CraftData.CreateQuestTips(szLinkArg)
    elseif szLinkEvent == "MiddleMap" then
        CraftData.OpenMiddleMap(szLinkArg)
    elseif szLinkEvent == "SourceTrade" then
        TradingData.OpenSourceTradeSearchPanel(szLinkArg)
    elseif szLinkEvent == "SourceTradeWithName" then
        TradingData.OpenSourceTradeSearchPanelWithName(szLinkArg)
    elseif szLinkEvent == "SourceShop" then
        ShopData.OnSourceOpenSystemShop(szLinkArg)
    elseif szLinkEvent == "Reputation" then
        ItemData.RedirectForceToRenownView(szLinkArg)
    elseif szLinkEvent == "Achievement" then
		ItemData.RedirectForceToAchievement(szLinkArg)
    elseif szLinkEvent == "OpenDLCPanel" then
		ItemData.RedirectForceToDLCPanel(szLinkArg)
    elseif szLinkEvent == "LuckyMeeting" then
		ItemData.RedirectForceToAdventure(szLinkArg)
    elseif szLinkEvent == "FBlist" then
        --CraftData.OpenDungeonBossView(szLinkArg)
        CraftData.OpenDungeonEntranceView(szLinkArg) -- FBlist现打秘境界面
    elseif szLinkEvent == "MainStoryPanel" then
        local t = SplitString(szLinkArg, "/")
		local nSeason = tonumber(t[1])
		local nChapter = tonumber(t[2])
        UIMgr.Open(VIEW_ID.PanelSwordMemories, nChapter)
    elseif szLinkEvent == "PanelLink" then
        Global.OpenViewByLink(szLinkArg)
    elseif szLinkEvent == "RealBP" then
        if not UIMgr.GetView(VIEW_ID.PanelBenefits) then
            UIMgr.Open(VIEW_ID.PanelBenefits, 2, true)
        end
    elseif szLinkEvent == "ShareStation" then
        local tLinkArg = SplitString(szLinkArg, "/")
        local szDataType, szPage = tLinkArg[1], tLinkArg[2]
        local nDataType = szDataType and tonumber(szDataType) or SHARE_DATA_TYPE.EXTERIOR
        ShareStationData.OpenShareStation(nDataType)
    elseif szLinkEvent == "HLIdentity" then
        UIMgr.Open(VIEW_ID.PanelHomeIdentity, tonumber(szLinkArg))
    elseif szLinkEvent == "OperationActivity" then
        local dwID = tonumber(szLinkArg)
		UIMgr.Open(VIEW_ID.PanelOperationCenter, dwID)
    elseif szLinkEvent == "DaTangJiaYuan" then
        HomelandData.OpenHomelandPanel()
    elseif szLinkEvent == "SwitchServerDLC" then
        -- CampData.TryEnterCampPVPField()
        UIMgr.Open(VIEW_ID.PanelQianLiFaZhu)
    elseif szLinkEvent == "GameGuidePanel" then
        local nType = DX2VK_COLLECTION_PAGE_TYPE[szLinkArg]
        if nType == COLLECTION_PAGE_TYPE.CAMP and g_pClientPlayer and g_pClientPlayer.nCamp == CAMP.NEUTRAL then
            UIMgr.Open(VIEW_ID.PanelPvPCampJoin)
        else
            UIMgr.OpenSingle(true, VIEW_ID.PanelRoadCollection, nType)
        end
    elseif szLinkEvent == "GameGuide" then
		local dwID = tonumber(szLinkArg)
		CollectionData.LinkToCard(dwID)
	elseif szLinkEvent == "GameGuideDaily" then
		local dwID = tonumber(szLinkArg)
		CollectionData.LinkToCard(dwID)
    elseif szLinkEvent == "HomelandGuide" then
        local tLinkIndex = SplitString(szLinkArg, "/")
        UIMgr.CloseAllInLayer(UILayer.Page)
        HomelandData.OpenHomeOverviewPanel(tLinkIndex)
    elseif szLinkEvent == "SchoolSplit" then
        CoinShopData.LinkTitle(szLinkArg, false)
    elseif szLinkEvent == "TeamRecruit" then
		local dwID = tonumber(szLinkArg)
        UIMgr.Open(VIEW_ID.PanelTeam, 1, nil, dwID)
    elseif szLinkEvent == "WebURL" then
        WebUrl.OpenByID(tonumber(szLinkArg))
    elseif szLinkEvent == "ArenaQueue" then
        ArenaData.OpenPvpMatching(tonumber(szLinkArg))
    elseif szLinkEvent == "HLOrder" or szLinkEvent == "OrderPanel" then
        OrderPanel.Open(nil, szLinkArg)
    elseif szLinkEvent == "HLIdentitySkill" then
        local dwSkillID = tonumber(szLinkArg)
        HomelandIdentity.UseToyBoxSkill(dwSkillID)
    elseif szLinkEvent == "PerfumePanel" then
        UIMgr.Open(VIEW_ID.PanelConfigurationPop)
        UIMgr.Close(VIEW_ID.PanelHomeIdentity)
    elseif szLinkEvent == "PreviewTreasureBox" then
        TreasureBoxData.OpenByLinkEvent(szLinkArg)
    elseif szLinkEvent == "GuideGetActRewardPanel" then
        local nActivityID = tonumber(szLinkArg)
        ActivityData.OpenFestivalRewardPop(nActivityID)
    elseif szLinkEvent == "GuideActRewardCollectPanel" then
        local nActivityID = tonumber(szLinkArg)
        ActivityData.OpenFestivalStampPop(nActivityID)
    elseif szLinkEvent == "QuickEating" then
        local tLinkIndex = SplitString(szLinkArg, "/")
        UIMgr.Open(VIEW_ID.PanelWuWeiJueOthersPop, tLinkIndex)
    elseif szLinkEvent == "BattleFieldQueue" then
        local tLinkIndex = SplitString(szLinkArg, "/")
		local dwMapID = tonumber(tLinkIndex[1])
        if dwMapID and TreasureBattleFieldData.IsSkillMatchMap(dwMapID) then
            UIMgr.Open(VIEW_ID.PanelImpasseMatching, nil, 6)
        elseif dwMapID and Table_IsTreasureBattleFieldMap(dwMapID) then
            UIMgr.Open(VIEW_ID.PanelImpasseMatching, nil, 1)
        end
    elseif szLinkEvent == "OrangeWeaponUpg" then
        local nLevel = tonumber(szLinkArg)
        UIMgr.Open(VIEW_ID.PanelShenBingUpgrade, nil, nLevel)
    elseif szLinkEvent == "ArenaTower" then
        UIMgr.OpenSingle(true, VIEW_ID.PanelYangDaoMain)
    elseif szLinkEvent == "OperationCenter" then
        local nOperationID = tonumber(szLinkArg)
        OperationCenterData.OpenCenterView(nOperationID)
    elseif szLinkEvent == "GuideTeleport" then
        local tLinkArg = SplitString(szLinkArg, "/")
        local nLinkID = tonumber(tLinkArg[1])
        local dwMapID = tonumber(tLinkArg[2])
        if nLinkID and dwMapID then
            HuaELouData.Teleport(nLinkID, dwMapID)
        end
    elseif szLinkEvent == "TrackingNpc" then
        local szLinkID, szMapID = szLinkArg:match("(%w+)/(%w+)")
		local dwLinkID
		local dwMapID
		if szLinkID and szMapID then
			dwLinkID = tonumber(szLinkID)
			dwMapID = tonumber(szMapID)
		elseif szLinkID then
			dwLinkID = tonumber(szLinkID)
		end
        if dwLinkID then
            local tLinkInfo = Table_GetCareerLinkNpcInfo(dwLinkID, dwMapID)
            local szText = UIHelper.GBKToUTF8(tLinkInfo.szNpcName)
            MapMgr.SetTracePoint(szText, tLinkInfo.dwMapID, {tLinkInfo.fX, tLinkInfo.fY, tLinkInfo.fZ})
            UIMgr.Open(VIEW_ID.PanelMiddleMap, tLinkInfo.dwMapID, 0)
        end
    end
end)

-- 打开Hint面板
Event.Reg(Global, EventType.OnViewClose, function(nViewID)
    if nViewID == VIEW_ID.PanelLoading then
        TipsHelper:Init()
        TipsHelper:Init(true) -- 事实上该界面应当常驻，不需要反复初始化

        local tTypeList = Table_GetSpecialActivityType()
        local nYuanXiaoStartTime = tTypeList and tTypeList[2] and tTypeList[2].nStartTime
        local nYuanXiaoEndTime = tTypeList and tTypeList[2] and tTypeList[2].nEndTime
        local nCurrentTime = GetCurrentTime()
        local bYuanXiaoStart = nYuanXiaoStartTime and nCurrentTime >= nYuanXiaoStartTime
        local bYuanXiaoEnabled = nYuanXiaoEndTime and nCurrentTime <= nYuanXiaoEndTime -- 活动结束后不显示
        local nBubbleType = bYuanXiaoStart and "YuanXiao" or "SpringFestival"
        if bYuanXiaoEnabled then
            BubbleMsgData.PushMsgWithType(nBubbleType, {
                szType = nBubbleType, -- 类型(用于排重)
                nBarTime = 0, -- 显示在气泡栏的时长, 单位为秒
                szContent = function()
                    local szContent = ""
                    return szContent, 0.5
                end,
                szAction = function()
                    if not CrossMgr.IsCrossing(nil, true) then
                        UIMgr.Open(VIEW_ID.PanelSpringFestival, bYuanXiaoStart and 2 or 1)
                    end
                end,
            })
        end
    end
end)

-- 邀请
Event.Reg(Global, "ON_INVITE_EMOTION_ACTION_REQUEST", function(dwInviterID, dwActionID)
    if not IsRegisterEvent("EMOTION_ACTION_REQUEST") or IsFilterOperate("EMOTION_ACTION_REQUEST") then
        EmotionData.RefuseInviteAction(dwInviterID)
        return
    end

    if FellowshipData.IsInBlackListByPlayerID(dwInviterID) then--在黑名单
        EmotionData.RefuseInviteAction(dwInviterID)
        return
    end

    local KPlayer = GetPlayer(dwInviterID)
	local tAction = EmotionData.GetEmotionAction(dwActionID)
	if KPlayer and tAction then
        EmotionData.OnActionInvited(dwInviterID)
        local szInviterName = KPlayer.szName
        -- local szMessage = FormatString(g_tStrings.STR_EMOTION_BE_INVITED1, UIHelper.GBKToUTF8(tAction.szName))
        local tbInfo = {
            szType = "EmotionActionInviteTip",
            -- szTitle = szMessage,
            szInviterName = szInviterName,
            fnConfirmAction = function()
                EmotionData.AcceptInviteAction(dwInviterID)
            end,
            fnCancelAction = function()
                EmotionData.RefuseInviteAction(dwInviterID)
            end
        }
        TipsHelper.ShowInteractTip(tbInfo)
	end
end)

--幻境云图
Event.Reg(Global, EventType.OpenCameraPanel, function()
    local tbData = TipsHelper.GetProgressBarSkillInfo()

    if IsInLishijie() or (tbData and tbData.szTitle == "出魂入定") then
        return OutputMessage("MSG_ANNOUNCE_NORMAL", g_tStrings.STR_UNABLE_TO_USE_SELFIE.."(1)")
    end

    -- 幻化状态下禁用幻境云图
    if PartnerData.bEnterHero then
        return OutputMessage("MSG_ANNOUNCE_NORMAL", g_tStrings.STR_UNABLE_TO_USE_SELFIE.."(2)")
    end

    local nMode = HLBOp_Main.GetBuildMode()
    if nMode and nMode ~= 0 then
        return OutputMessage("MSG_ANNOUNCE_NORMAL", g_tStrings.STR_UNABLE_TO_USE_SELFIE.."(3-"..tostring(nMode)..")")
    end

    UIMgr.Open(VIEW_ID.PanelCamera)
end)

Event.Reg(Global, "HORSE_ITEM_UPDATE", function(dwBoxIndex, dwX, bNewAdd)
    if not dwBoxIndex then
        return
    end

    if BattleFieldData.IsInTreasureBattleFieldMap() then
        return
    end

    RedpointHelper.Horse_SetNew(dwBoxIndex, dwX, true)
end)

Event.Reg(Global, "CHARGE_LIMIT_NOTIFT", function(nCode)
    local szMsg = g_tStrings.tChargeLimit[nCode]
	if szMsg and szMsg ~= "" then
		OutputMessage("MSG_SYS", szMsg)
        TipsHelper.ShowNormalTip(szMsg)
	end
end)

Event.Reg(Global, "REAL_NAME_LIMIT_NOTIFY", function(nCode)
    local szMsg = g_tStrings.tRealNameLimit[nCode]
    if szMsg and szMsg ~= "" then
        OutputMessage("MSG_SYS", szMsg)
        TipsHelper.ShowNormalTip(szMsg)
    end
end)

Event.Reg(Global, "ACQUIRE_FELLOW_PET", function(nFellowPetIndex)
    if not nFellowPetIndex then
        return
    end

    RedpointHelper.Pet_SetNew(nFellowPetIndex, true)
end)

Event.Reg(Global, "TOYBOX_ADD", function(dwID)
    if not dwID then
        return
    end

    RedpointHelper.ToyBox_SetNew(dwID, true)
end)

Event.Reg(Global, "ON_ADD_EMOTION_ACTION_NOTIFY", function(dwActionID)
    if not dwActionID then
        return
    end
    TipsHelper.ShowNewEmotionTip(dwActionID)
    RedpointHelper.Emotion_SetNew(dwActionID, true)
end)

Event.Reg(Global, "ON_OPERATE_BRIGHT_MARK_NOTIFY", function(cszMethod, dwBrightMarkID)
    if not dwBrightMarkID then
        return
    end

    if cszMethod == "ADD" then
        RedpointHelper.BrightMark_SetNew(dwBrightMarkID, true)
    end
end)

Event.Reg(Global, "ACQUIRE_SFX", function(dwEffectID, bAcquire)
    print("ACQUIRE_SFX",dwEffectID,bAcquire)
    local szText = bAcquire and g_tStrings.PENDANT_EFFECT_ACQUIRE or g_tStrings.PENDANT_EFFECT_REMOVE
    local szName = UIHelper.GBKToUTF8(Table_GetPendantEffectInfo(dwEffectID).szName)
    OutputMessage("MSG_SYS", FormatString(szText, szName))

    if bAcquire then
        local szText2 = g_tStrings.PENDANT_EFFECT_ACQUIRE2
        --OutputWarningMessage("MSG_NOTICE_GREEN",FormatString(szText2, szName), 4)
        OutputMessage("MSG_ANNOUNCE_NORMAL", FormatString(szText2, szName))
    end
end)

Event.Reg(Global, EventType.OnApplicationDidEnterBackground, function()
    LOG.INFO("OnApplicationDidEnterBackground")
    UIMgr.ReportOpenedViewList()
    Global.m_bInBackgroundMode = true
    Global.ChangeClientPerfState()
end)

Event.Reg(Global, EventType.OnApplicationWillEnterForeground, function()
    LOG.INFO("OnApplicationWillEnterForeground")
    Global.m_bInBackgroundMode = false
    Global.ChangeClientPerfState()
end)

Event.Reg(Global, EventType.OnEnterPowerSaveMode, function()
    LOG.INFO("OnEnterPowerSaveMode")
    Global.ChangeClientPerfState()
end)

Event.Reg(Global, EventType.OnExitPowerSaveMode, function()
    LOG.INFO("OnExitPowerSaveMode")
    Global.ChangeClientPerfState()

    if self.bNeedShowDisconnectAfterPSM then
        Timer.DelTimer(self, self.nShowDisconnectAfterPSMTimer)
        self.nShowDisconnectAfterPSMTimer = Timer.AddFrame(self, 1, function()
            local confirm = UIHelper.ShowSystemConfirm(g_tStrings.tbLoginString.CONNECT_GAME_SERVER_FAILED, function()
                Global.BackToLogin(false)
            end)

            confirm:SetConfirmButtonContent("返回登录界面")
            confirm:HideButton("Cancel")
        end)

        self.bNeedShowDisconnectAfterPSM = false
    end
end)

--- 实物订单通知
Event.Reg(self, "ON_UPDATE_BUY_ITEM_ORDER_SN", function(szOrder, bAddFlag, bDelFlag)
    LOG.DEBUG("[直购] ON_UPDATE_BUY_ITEM_ORDER_SN szOrder=%s bAddFlag=%s bDelFlag=%s", szOrder, tostring(bAddFlag), tostring(bDelFlag))
    local player = GetClientPlayer()
    if bAddFlag then
        -- 请求签名
        player.ApplyWebDataSign(WEB_DATA_SIGN_RQST.REAL_ITEM_ORDER, szOrder)
    end
end)

--- 订单签名通知
Event.Reg(self, "ON_WEB_DATA_SIGN_NOTIFY", function(uSign, dwType, nTime, nZoneID, dwCenterID, bIsFirstWebPhoneVerified, szOrderSN)
    LOG.DEBUG("[直购] ON_WEB_DATA_SIGN_NOTIFY uSign=%d dwType=%d nTime=%d nZoneID=%d dwCenterID=%d bIsFirstWebPhoneVerified=%s szOrderSN=%s",
              uSign, dwType, nTime, nZoneID, dwCenterID, tostring(bIsFirstWebPhoneVerified), szOrderSN)

    if dwType ~= WEB_DATA_SIGN_RQST.REAL_ITEM_ORDER then
        return
    end

    local player = GetClientPlayer()
    if not player then
        return
    end

    local tInfo = player.GetBuyItemOrderInfoBySN(szOrderSN)
    if not tInfo then
        return
    end

    --local szAccount = GetUserAccount()
    local szAccount        = Login_GetAccount()
    local szName           = player.szName
    local dwID             = player.dwID
    local szCenterName     = GetCenterName()
    local szItemName       = GetItemInfo(tInfo.dwItemType, tInfo.dwItemIndex).szName
    --local _, szUserServer = GetUserServer()
    --local szServerCode = LoginServerList.GetServerCode(szUserServer)
    local szServerCode     = LoginMgr.GetModule(LoginModule.LOGIN_SERVERLIST).GetSelectServer().szSerial
    local nAccountType     = GetAccountType()

    --- 通过实物订单来实现直购，目前游戏逻辑测需要 nIsBP 为1，但是在西瓜那边的时候需要这个为false，所以这里改为通过是否是战令商品来判断
    --local bIsBattlePass    = tInfo.nIsBP == 1
    local bIsBattlePass    = PayData.GetBattlePassRMBItemProductID(tInfo.dwItemType, tInfo.dwItemIndex) ~= ""

    if bIsBattlePass then
        --- 战令商品会在成功或取消时删除实物订单，所以在这里记录下订单信息
        --- PS：由于待付款中的实物订单在服务器不允许删除，所以取消时的删除操作实际好像不会生效，详见 #C720592
        XGSDK.BattlePass_szOrderSN = szOrderSN
    end

    --- 下单30分钟后需要付款，否则订单会关闭并过期。这里传递给西瓜，方便西瓜在订单截止之后不再允许支付，避免支付成功但游戏侧该订单已关闭，导致无法给玩家激活战令或发放对应奖励
    local nEndTime = tInfo.nBuyTime + 1800

    local tXiGuaCustomData = {
        serverName = UIHelper.GBKToUTF8(szCenterName),
        itemType = tInfo.dwItemType,
        itemIndex = tInfo.dwItemIndex,
        gameOrder = szOrderSN,
        gameRoleId = tostring(dwID),
        isBattlePass = bIsBattlePass,
        endTime = nEndTime,
    }

    local szJsonCustomData = JsonEncode(tXiGuaCustomData)
    local szProductId      = PayData.GetRMBItemProductID(tInfo.dwItemType, tInfo.dwItemIndex)

    LOG.DEBUG("[直购] szProductId=%s json数据为 %s", tostring(szProductId), szJsonCustomData)

    if szProductId ~= "" then
        PayData.Pay(szProductId, szJsonCustomData, szOrderSN)
    end
end)

local UpdateMentorTips = function(szMsg, szName, nMode, tInfo, bOnline)
    local player = g_pClientPlayer
    if not player then
        return
    end

    if not bOnline then
        BubbleMsgData.RemoveMsg("NewMentorTips")
    else
        BubbleMsgData.PushMsgWithType("NewMentorTips", {
            nBarTime = 6,
            szContent = szMsg,
            szBarTitle = szMsg,
            szAction = function()
                local szText
                if nMode == 1 then
                    szText = FormatString(g_tStrings.STR_MENTORMESSAGE_TEXT, g_tStrings.STR_MENTORMESSAGE_MENTOR, UIHelper.GBKToUTF8(szName))
                elseif nMode == 2 then
                    szText = FormatString(g_tStrings.STR_MENTORMESSAGE_TEXT, g_tStrings.STR_MENTORMESSAGE_APPRENTICE, UIHelper.GBKToUTF8(szName))
                end
                szText = ParseTextHelper.ParseNormalText(szText, false)

                local dialog = UIHelper.ShowConfirm(szText, function ()
                    TeamData.InviteJoinTeam(szName)
                    BubbleMsgData.RemoveMsg("NewMentorTips")
                end, function ()
                    UIMgr.Close(self)
                    BubbleMsgData.RemoveMsg("NewMentorTips")
                end, true)

                dialog:ShowOtherButton()
                dialog:SetOtherButtonClickedCallback(function()
                    UIMgr.Open(VIEW_ID.PanelInteractActivityPop, UIHelper.GBKToUTF8(szName), FellowshipData.tMode2RelationType[nMode], tInfo.dwPlayerID)
                    BubbleMsgData.RemoveMsg("NewMentorTips")
                end)

                dialog:SetConfirmButtonContent("组队")
                dialog:SetCancelButtonContent("取消")
                dialog:SetOtherButtonContent("共同活动")
            end,
        })
    end
end

Event.Reg(Global, EventType.OnUpdateMentorOnlineInfo, function (szMsg, param, nMode, tInfo)
    UpdateMentorTips(szMsg, param, nMode, tInfo, true)
end)

Event.Reg(Global, EventType.OnUpdateMentorOfflineInfo, function (szMsg, param, nMode, tInfo)
    UpdateMentorTips(szMsg, param, nMode, tInfo, false)
end)

Event.Reg(Global, "ON_NAV_RESULT", function (nCode)
    if nCode ~= NAV_RESULT_CODE.SUCCESS then
        if IsHomelandCommunityMap() and g_tStrings.tHomelandNavResultCode[nCode] then
            TipsHelper.ShowNormalTip(g_tStrings.tHomelandNavResultCode[nCode])
            return
        else
            TipsHelper.ShowNormalTip(g_tStrings.tNavResultCode[nCode])
            return
        end
    end
end)

local tbWindowsSizeChangedExtraIgnoreViewIDs = {}
function Global.SetWindowsSizeChangedExtraIgnoreViewIDs(tbViewIDs)
    tbWindowsSizeChangedExtraIgnoreViewIDs = tbViewIDs
end

Event.Reg(Global, EventType.OnWindowsSizeChanged, function(width, height)
    if Platform.IsAndroid() then
        -- 如果正在处理支付订单，就不做这个操作
        if UIMgr.GetView(VIEW_ID.PanelTopUpMain) then
            return
        end

        -- 豪侠大礼界面也不做这个操作
        if UIMgr.GetView(VIEW_ID.PanelBenefitBPRewardDetail) then
            return
        end

        PlotMgr.ClosePanel(PLOT_TYPE.OLD)
        PlotMgr.ClosePanel(PLOT_TYPE.NEW)

        local tbIgnoreViewIDs =
        {
            VIEW_ID.PanelLogin,
            VIEW_ID.PanelRoleChoices,
            VIEW_ID.PanelSchoolSelect,
            VIEW_ID.PanelBuildFace_Step2,
            VIEW_ID.PanelBuildFace_DetailAdjust,
            VIEW_ID.PanelBuildFace,
            VIEW_ID.PanelRevive,
            VIEW_ID.PanelModelVideo,
            VIEW_ID.PanelCamera,
            VIEW_ID.PanelCameraVertical,
            VIEW_ID.PanelExteriorMain,
            VIEW_ID.PanelSettleAccounts,
            VIEW_ID.PanelToVideo,
            VIEW_ID.PanelCameraSettingRight
        }
        -- 额外添加可以动态不关闭的界面，例如幻境云图分享时切换
        table.insert_tab(tbIgnoreViewIDs ,tbWindowsSizeChangedExtraIgnoreViewIDs )

        for k, v in pairs(tbWindowsSizeChangedExtraIgnoreViewIDs) do
            LOG.INFO("OnWindowsSizeChanged %d",v)
        end

        LOG.DEBUG("OnWindowsSizeChanged try close all views")
        UIMgr.CloseAllInLayer(UILayer.Popup , tbWindowsSizeChangedExtraIgnoreViewIDs)
        UIMgr.CloseAllInLayer(UILayer.Page, tbIgnoreViewIDs)
    end
    GamepadData.ResetScreenSize()
end)

Event.Reg(Global, "OnEditBoxShowGameNumKeyboard", function(editbox)
    LOG.INFO("OnEditBoxShowGameNumKeyboard")
    UIHelper.ShowMiniKeyboard(editbox)
end)

if Platform.IsWindows() then
    local isProcess
    Event.Reg(Config, "OnWindowsClose", function()
        if isProcess then
            return
        end

        if UIMgr.GetView(VIEW_ID.PanelEmbeddedWebPages) then
            UIMgr.Close(VIEW_ID.PanelEmbeddedWebPages)
            return
        end

        if UIMgr.GetView(VIEW_ID.PanelH5GameView) then
            UIMgr.Close(VIEW_ID.PanelH5GameView)
            return
        end

        isProcess = true
        UIHelper.ShowSystemConfirm(g_tStrings.EXIT_QUIT,
            function()
                Game.Exit()
            end,
            function()
                isProcess = nil
            end
        )
    end)
else
    Event.Reg(Config, "ON_APPLICATION_WILL_TERMINATE", function()
        Log("ON_APPLICATION_WILL_TERMINATE:" .. Platform.GetPlatformName())
        LogoutGame()
        if Platform.IsIos() then
            ResetGameworld()
        end
    end)
end

Event.Reg(Global, "FOCUS_FACE_STATUS_CHANGE", function(bInFaceState)
    local nQualityConf = QualityMgr.GetHDFaceCount()
    self.bInFaceState = bInFaceState
    if bInFaceState then
        -- 0档镜头时至少显示5个亲友脸
        RLEnv.GetLowerVisibleCtrl():SetHDFaceCount(math.max(5, nQualityConf))
    else
        RLEnv.GetLowerVisibleCtrl():SetHDFaceCount(nQualityConf)
    end
end)

-- moba星露（玩法货币）变动
local MIN_ACTIVITY_AWARD_UP = 5

Event.Reg(Global, "UPDATE_ACTIVITYAWARD", function(nOldMoney)
    if not g_pClientPlayer then
        return
    end

    local nNewMoney = g_pClientPlayer.nActivityAward
    local nDelta    = nNewMoney - nOldMoney

    if nDelta >= MIN_ACTIVITY_AWARD_UP then
        -- fixme: 这个暂时先用普通tips，后面看看是否要改。端游是与 REPRESENT_SKILL_EFFECT_TEXT 事件一样，在主界面上处理的
        TipsHelper.ShowNormalTip(string.format("<color=#EAEC20>%s%d</color>", g_tStrings.STR_COMBATMSG_AA, nDelta), true)
    end
end)

--查看他人奇穴
Event.Reg(Global, "ON_UPDATE_TALENT", function(dwPlayerID, nType)
    local hPlayer = GetClientPlayer()
    if hPlayer and hPlayer.dwID ~= dwPlayerID and nType == QIXUE_TYPE.OTHER_POP then
        if CheckShieldPanel(g_tStrings.CONTROL_TIP.QX) then
            return
        end
        UIMgr.Open(VIEW_ID.PanelCheckPlayerSkillPop, dwPlayerID)
    end
end)

Event.Reg(Global, "QUEST_FINISHED", function(dwQuestID)

    --稻香村任务完成，判断核心包下载状态并弹窗
    if dwQuestID == 27139 then
        if not PakDownloadMgr.IsEnabled() then
            return
        end

        local tCorePackIDList = PakDownloadMgr.GetCorePackIDList()
        local tCoreStateInfo = PakDownloadMgr.GetStateInfoByPackIDList(tCorePackIDList)
        local szTotalSize = PakDownloadMgr.FormatSize(tCoreStateInfo.dwTotalSize)
        if tCoreStateInfo.nState ~= DOWNLOAD_STATE.DOWNLOADING and tCoreStateInfo.nState ~= DOWNLOAD_STATE.COMPLETE then
            local szContent
            if Platform.IsWindows() or Platform.IsMac() then
                szContent = "建议下载" .. szTotalSize .."核心资源包（可<color=#ffe26e>边玩边下</c>）。\n\n若未下载核心资源包，游玩过程中可能会影响游戏体验，是否下载？"
            else
                local nNetMode = App_GetNetMode()
                if nNetMode == NET_MODE.WIFI then
                    szContent = "建议下载" .. szTotalSize .."核心资源包（可<color=#ffe26e>边玩边下</c>）。\n\n若未下载核心资源包，游玩过程中可能会<color=#ffe26e>因资源下载导致额外流量消耗</c>，\n当前为WiFi网络环境，是否下载？"
                elseif nNetMode == NET_MODE.CELLULAR then
                    szContent = "建议下载" .. szTotalSize .."核心资源包（可<color=#ffe26e>边玩边下</c>）。\n\n若未下载核心资源包，游玩过程中可能会<color=#ffe26e>因资源下载导致额外流量消耗</c>，\n当前为移动网络环境，是否下载？"
                else
                    --无网络
                end
            end
            if szContent then
                UIHelper.ShowConfirm(szContent, function()
                    PakDownloadMgr.DownloadPackListImmediately(tCorePackIDList)
                    local tCoreStateInfo = PakDownloadMgr.GetStateInfoByPackIDList(tCorePackIDList)
                    if tCoreStateInfo.nState == DOWNLOAD_STATE.DOWNLOADING then
                        TipsHelper.ShowNormalTip("核心资源已开始下载")
                    end
                end, nil, true)
            end
        end
    end

end)

Event.Reg(self, "ACQUIRE_MINI_AVATAR", function(dwID)
    if not dwID then
        return
    end
    RedpointHelper.Avatar_SetNew(dwID, true)
end)

Event.Reg(self, "OnButtonPressStateUpdateTexture", function(render, szFrameName)
    if not render then
        return
    end
    UIHelper.SetSpriteFrame(render, szFrameName)
end)

Event.Reg(self, "FREEZE_PLAYER_CODE_NOTIFY", function()
    OutputMessage("MSG_ANNOUNCE_RED", g_tStrings.tFreezeCodeNotify[arg0])
    OutputMessage("MSG_SYS", g_tStrings.tFreezeCodeNotify[arg0])
end)