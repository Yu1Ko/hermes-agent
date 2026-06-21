-- ---------------------------------------------------------------------------------
-- Author: luwenhao
-- Name: UIBattlePersonalCardSettleView
-- Date: 2024-07-29 11:32:56
-- Desc: PanelBattlePersonalCardSettle 战场结算-优秀表现-名片
-- ---------------------------------------------------------------------------------

local UIBattlePersonalCardSettleView = class("UIBattlePersonalCardSettleView")

local szCanPraiseIconPath = "UIAtlas2_Pvp_PvpList_Btn_Praise03.png"
local szPraisedIconPath = "UIAtlas2_Pvp_PvpList_Btn_Praise04.png"

local tShowIndex = {2, 1, 3}
local ARENA_INDEX = tShowIndex[1]

local tExcellentIDToImgTextIndex = {
    [1] = 5,    --全场最佳
    [2] = 13,   --战无不胜
    [3] = 5,    --全场最佳
    [4] = 14,   --最佳连伤
    [5] = 16,   --最佳治疗
    [6] = 3,    --击伤第一
    [7] = 15,   --最佳协伤
    [8] = 6,    --伤害第一
    [9] = 0,    --空的
    [10] = 1,   --超神
    [11] = 17,  --最佳助攻
    [12] = 11,  --一击必杀
    [13] = 2,   --汗马功劳
    [14] = 9,   --万劫不灭
    [15] = 4,   --凌波微步
    [16] = 12,  --斩将搴旗
    [17] = 8,   --万夫莫开
    [18] = 7,   --神输鬼运
    [19] = 7,   --神输鬼运
    [20] = 10,  --眼疾手快
    [21] = 12,  --斩将搴旗
    [22] = 1,   --超神
    [23] = 0,   --富甲一方 TODO
    [24] = 0,   --势破星阵 TODO
    [25] = 7,   --神输鬼运
    [26] = 0,   --背旗时间 TODO
    [27] = 5,   --全场最佳
}

function UIBattlePersonalCardSettleView:OnEnter(tExcellentData, nClientPlayerSide, nBanishTime, funcCloseCallback, bTreasureBattle)
    if not self.bInit then
        self:RegEvent()
        self:BindUIEvent()
        self.bInit = true

        Timer.AddFrameCycle(self, 1, function()
            self:UpdateTime()
        end)
    end

    self.tExcellentData = tExcellentData
    self.nClientPlayerSide = nClientPlayerSide
    self.nBanishTime = nBanishTime
    self.funcCloseCallback = funcCloseCallback
    self.bTreasureBattle = bTreasureBattle

    self.tPlayerIDList = {}
    self.tScriptPersonalCard = {}

    self:InitData()
    self:UpdateInfo()
end

function UIBattlePersonalCardSettleView:OnExit()
    self.bInit = false
    self:UnRegEvent()
end

function UIBattlePersonalCardSettleView:BindUIEvent()
    UIHelper.BindUIEvent(self.BtnLeave, EventType.OnClick, function()
        if ArenaData.IsInArena() then
            ArenaData.LogOutArena()
        else
            BattleFieldData.LeaveBattleField()
        end
    end)
    UIHelper.BindUIEvent(self.BtnBack, EventType.OnClick, function()
        if self.funcCloseCallback then
            self.funcCloseCallback()
        else
            BattleFieldData.OpenBattleFieldSettle()
        end
    end)

    for i, btnPriaise in ipairs(self.tBtnPriaise) do
        local nIndex = i
        UIHelper.BindUIEvent(btnPriaise, EventType.OnClick, function()
            local selfPlayer = GetClientPlayer()
            if not selfPlayer then
                return
            end

            if ArenaData.IsInArena() then
                local dwPlayerID = self.tPlayerIDList and self.tPlayerIDList[1]
                if not dwPlayerID then
                    return
                end

                local bPraised = ArenaData.IsPraised(dwPlayerID)
                if bPraised then
                    return
                end

                ArenaData.ReqPraise(dwPlayerID)
            else
                local dwPlayerID = self.tPlayerIDList and self.tPlayerIDList[nIndex]
                if not dwPlayerID then
                    return
                end

                local bPraised = BattleFieldData.IsAddPraise(dwPlayerID)
                if bPraised then
                    return
                end

                RemoteCallToServer("On_FriendPraise_AddRequest", selfPlayer.dwID, dwPlayerID, PRAISE_TYPE.BATTLE_FIELD) --返回Add_FriendPraiseShow
                BattleFieldData.OnAddPraise(dwPlayerID)
            end

            UIHelper.SetTouchEnabled(self.tBtnPriaise[nIndex], false)
            UIHelper.SetSpriteFrame(self.tImgPraise[nIndex], szPraisedIconPath)
        end)
    end
end

function UIBattlePersonalCardSettleView:RegEvent()
    --Event.Reg(self, EventType.XXX, func)
    Event.Reg(self, "BATTLE_FIELD_SYNC_STATISTICS", function ()
        if self.bTreasureBattle then
            self:UpdateTreasureBattleFieldInfo()
        end
    end)
end

function UIBattlePersonalCardSettleView:UnRegEvent()
    --Event.UnReg(self, EventType.XXX)
end

function UIBattlePersonalCardSettleView:InitData()
    self.tPlayerIDList = {}
    self.tExcellentList = {}

    local tExcellentData = self.tExcellentData or {}

    local tAllExcellentIDList = {}
    for dwPlayerID, tExcellent in pairs(tExcellentData) do
        for _, dwExcellentID in ipairs(tExcellent) do
            local tInfo = g_tTable.BFArenaExcellent:Search(dwExcellentID)
            if dwExcellentID == EXCELLENT_ID.BEST_COURSE then
                --MVP仅显示本方
                local tData = BattleFieldData.GetPlayerStatisticData(dwPlayerID)
                if tData and tData.nBattleFieldSide == self.nClientPlayerSide then
                    table.insert(tAllExcellentIDList, tInfo)
                end
            else
                table.insert(tAllExcellentIDList, tInfo)
            end
        end
    end

    local fnSort = function(tLeft, tRight)
        return tLeft.nIndex < tRight.nIndex
    end
    table.sort(tAllExcellentIDList, fnSort)

    for i, nIndex in ipairs(tShowIndex) do
        self.tExcellentList[i] = tAllExcellentIDList[nIndex] and tAllExcellentIDList[nIndex].dwID or 1
    end

    local bOK = false
    local nCount = #self.tExcellentList
    for dwPlayerID, tExcellent in pairs(tExcellentData) do
        for _, dwExcellentID in ipairs(tExcellent) do

            local bCanShow = false
            if dwExcellentID == EXCELLENT_ID.BEST_COURSE then
                --MVP仅显示本方
                local tData = BattleFieldData.GetPlayerStatisticData(dwPlayerID)
                if tData and tData.nBattleFieldSide == self.nClientPlayerSide then
                    bCanShow = true
                end
            else
                bCanShow = true
            end

            if bCanShow then
                for nIndex, dwID in ipairs(self.tExcellentList) do
                    if dwExcellentID == dwID and not self.tPlayerIDList[nIndex] then
                        self.tPlayerIDList[nIndex] = dwPlayerID
                        if #self.tPlayerIDList == nCount then
                            bOK = true
                        end
                        break
                    end
                end
            end

            if bOK then
                break
            end
        end

        if bOK then
            break
        end
    end
end

function UIBattlePersonalCardSettleView:UpdateInfo()
    if ArenaData.IsInArena() then
        self:UpdateArenaInfo()
    else
        self:UpdateBattleFieldInfo()
    end
end

function UIBattlePersonalCardSettleView:UpdateArenaInfo()
    -- UIHelper.SetTabVisible(self.tLabelMvpLabel, false)
    UIHelper.SetTabVisible(self.tImgMvpLabel, false)
    UIHelper.SetTabVisible(self.tImgMvpLabelBg, false)
    UIHelper.SetTabVisible(self.tWidgetPersonalCard, false)
    UIHelper.SetTabVisible(self.tBtnPriaise, false)

    -- UIHelper.SetVisible(self.tLabelMvpLabel[AREAN_INDEX], true)
    UIHelper.SetVisible(self.tImgMvpLabel[ARENA_INDEX], true)
    UIHelper.SetVisible(self.tImgMvpLabelBg[ARENA_INDEX], true)
    UIHelper.SetVisible(self.tWidgetPersonalCard[ARENA_INDEX], true)
    UIHelper.SetVisible(self.tBtnPriaise[ARENA_INDEX], true)

    for _, dwID in ipairs(self.tExcellentList) do
        local tLine = g_tTable.BFArenaExcellent:Search(dwID)
        UIHelper.SetString(self.tLabelMvpLabel[ARENA_INDEX], UIHelper.GBKToUTF8(tLine.szName))
        UIHelper.SetSpriteFrame(self.tImgMvpLabel[ARENA_INDEX], self:GetImgPathByExcellentID(dwID))
    end

    for _, dwPlayerID in ipairs(self.tPlayerIDList or {}) do
        local bShowPraise = ArenaData.CanAddPraise(dwPlayerID)
        local bPraised = ArenaData.IsAddPraise(dwPlayerID)
        local tData = ArenaData.GetPlayerStatisticData(dwPlayerID)
        local szGlobalID = tData.szGlobalRoleID

        UIHelper.SetVisible(self.tImgPraise[ARENA_INDEX], bShowPraise)
        UIHelper.SetSpriteFrame(self.tImgPraise[ARENA_INDEX], bPraised and szPraisedIconPath or szCanPraiseIconPath)

        if GDAPI_CanPeekPersonalCard(szGlobalID) then
            UIHelper.SetVisible(self.tWidgetPersonalCard[ARENA_INDEX], true)

            local tInfo = {
                szName = UIHelper.GBKToUTF8(tData.szPlayerName),
                dwPlayerID = dwPlayerID,
                dwForceID = tData.dwForceID,
                szHeadIconPath = PlayerForceID2SchoolImg2[tData.dwForceID],
            }

            self.tScriptPersonalCard[ARENA_INDEX] = self.tScriptPersonalCard[ARENA_INDEX] or UIHelper.AddPrefab(PREFAB_ID.WidgetPersonalCard, self.tWidgetPersonalCard[ARENA_INDEX], szGlobalID)
            if self.tScriptPersonalCard[ARENA_INDEX] then
                self.tScriptPersonalCard[ARENA_INDEX]:OnEnter(szGlobalID)
                self.tScriptPersonalCard[ARENA_INDEX]:SetPlayerId(dwPlayerID)
                self.tScriptPersonalCard[ARENA_INDEX]:SetEquipNumVisible(false)
                self.tScriptPersonalCard[ARENA_INDEX]:SetPersonalInfo(tInfo)

                UIHelper.SetAnchorPoint(self.tScriptPersonalCard[ARENA_INDEX]._rootNode, 0.5, 0.5)
            end
        else
            UIHelper.SetVisible(self.tWidgetPersonalCard[ARENA_INDEX], false)
        end
    end

    -- UIHelper.SetString(self.LabelLeave, "名剑结算")
end

function UIBattlePersonalCardSettleView:UpdateBattleFieldInfo()
    for k, v in ipairs(self.tWidgetPersonalCard) do
        UIHelper.SetVisible(self.tWidgetPersonalCard[k], false)
        UIHelper.SetVisible(self.tBtnPriaise[k], false)
        UIHelper.SetVisible(self.tImgMvpLabel[k], false)
        UIHelper.SetVisible(self.tLabelMvpLabel[k], false)
        UIHelper.SetVisible(self.tImgMvpLabelBg[k], false)
    end

    for nIndex, dwID in ipairs(self.tExcellentList) do
        local tLine = g_tTable.BFArenaExcellent:Search(dwID)
        UIHelper.SetString(self.tLabelMvpLabel[nIndex], UIHelper.GBKToUTF8(tLine.szName))
        UIHelper.SetSpriteFrame(self.tImgMvpLabel[nIndex], self:GetImgPathByExcellentID(dwID))
    end

    local bArenaTower = ArenaTowerData.IsInArenaTowerMap()
    for nIndex, dwPlayerID in pairs(self.tPlayerIDList or {}) do
        local bShowPraise = BattleFieldData.CanAddPraise(dwPlayerID)
        local bPraised = BattleFieldData.IsAddPraise(dwPlayerID)
        UIHelper.SetVisible(self.tImgPraise[nIndex], bShowPraise)
        UIHelper.SetSpriteFrame(self.tImgPraise[nIndex], bPraised and szPraisedIconPath or szCanPraiseIconPath)

        local tData = BattleFieldData.GetPlayerStatisticData(dwPlayerID)
        local szGlobalID = tData and tData.GlobalID

        local bShowCard = not bArenaTower or nIndex == 2 -- 扬刀大会特殊处理，只显示一个
        if bShowCard and GDAPI_CanPeekPersonalCard(szGlobalID) then
            UIHelper.SetVisible(self.tWidgetPersonalCard[nIndex], true)
            UIHelper.SetVisible(self.tBtnPriaise[nIndex], not bArenaTower) -- 扬刀大会不显示点赞按钮
            UIHelper.SetVisible(self.tImgMvpLabel[nIndex], true)
            -- UIHelper.SetVisible(self.tLabelMvpLabel[nIndex], true)
            UIHelper.SetVisible(self.tImgMvpLabelBg[nIndex], true)

            local tInfo = {
                szName = UIHelper.GBKToUTF8(tData.Name),
                dwPlayerID = dwPlayerID,
                dwForceID = tData.ForceID,
                szHeadIconPath = PlayerForceID2SchoolImg2[tData.ForceID],
            }

            self.tScriptPersonalCard[nIndex] = self.tScriptPersonalCard[nIndex] or UIHelper.AddPrefab(PREFAB_ID.WidgetPersonalCard, self.tWidgetPersonalCard[nIndex], szGlobalID)
            self.tScriptPersonalCard[nIndex]:OnEnter(szGlobalID)
            self.tScriptPersonalCard[nIndex]:SetPlayerId(dwPlayerID)
            self.tScriptPersonalCard[nIndex]:SetEquipNumVisible(false)
            self.tScriptPersonalCard[nIndex]:SetPersonalInfo(tInfo)

            UIHelper.SetAnchorPoint(self.tScriptPersonalCard[nIndex]._rootNode, 0.5, 0.5)
        else
            UIHelper.SetVisible(self.tWidgetPersonalCard[nIndex], false)
            UIHelper.SetVisible(self.tBtnPriaise[nIndex], false)
            UIHelper.SetVisible(self.tImgMvpLabel[nIndex], false)
            UIHelper.SetVisible(self.tLabelMvpLabel[nIndex], false)
            UIHelper.SetVisible(self.tImgMvpLabelBg[nIndex], false)
        end
    end
end

function UIBattlePersonalCardSettleView:UpdateTreasureBattleFieldInfo()
    local nIndex = 2
    for k, v in ipairs(self.tWidgetPersonalCard) do
        UIHelper.SetVisible(self.tWidgetPersonalCard[k], false)
        UIHelper.SetVisible(self.tBtnPriaise[k], false)
        UIHelper.SetVisible(self.tImgMvpLabel[k], false)
        UIHelper.SetVisible(self.tLabelMvpLabel[k], false)
        UIHelper.SetVisible(self.tImgMvpLabelBg[k], false)
    end

    local tStatistics 	= GetBattleFieldStatistics()
    local dwMyID 		= UI_GetClientPlayerID()
    local tInfo 		= tStatistics[dwMyID] or {}
    local dwMyTeamID    = tInfo[PQ_STATISTICS_INDEX.SPECIAL_OP_2]
    local tList = {}
    for k, v in pairs(tStatistics) do
        if v[PQ_STATISTICS_INDEX.SPECIAL_OP_2] == dwMyTeamID then
            table.insert(tList, v)
        end
    end
    table.sort(tList, function (a, b)
        return a[PQ_STATISTICS_INDEX.SPECIAL_OP_3] > b[PQ_STATISTICS_INDEX.SPECIAL_OP_3]
    end)

    if tList and tList[1] then
        local szGlobalID = tList[1].GlobalID
        local szName = tList[1].Name

        if GDAPI_CanPeekPersonalCard(szGlobalID) or szGlobalID == UI_GetClientPlayerGlobalID() then
            UIHelper.SetVisible(self.tWidgetPersonalCard[nIndex], true)
            UIHelper.SetVisible(self.tImgMvpLabel[nIndex], true)
            UIHelper.SetVisible(self.tImgMvpLabelBg[nIndex], true)


            local dwPlayerID, dwMiniAvatarID, nRoleType, dwForceID

            local hTeam = GetClientTeam()
            local nGroupNum = hTeam.nGroupNum
            for i = 0, nGroupNum - 1 do
                local tGroupInfo = hTeam.GetGroupInfo(i)
                if tGroupInfo and tGroupInfo.MemberList then
                    for _, dwID in pairs(tGroupInfo.MemberList) do
                        local tMemberInfo = hTeam.GetMemberInfo(dwID)
                        if tMemberInfo.szName == szName then
                            dwPlayerID, dwMiniAvatarID, nRoleType, dwForceID = dwID, tMemberInfo.dwMiniAvatarID, tMemberInfo.nRoleType, tMemberInfo.dwForceID
                        end
                    end
                end
            end

            local tPersonalInfo = {
                szName = UIHelper.GBKToUTF8(szName),
                dwPlayerID = dwPlayerID,
                dwMiniAvatarID = dwMiniAvatarID,
                nRoleType = nRoleType,
                dwForceID = dwForceID,
            }

            self.tScriptPersonalCard[nIndex] = self.tScriptPersonalCard[nIndex] or UIHelper.AddPrefab(PREFAB_ID.WidgetPersonalCard, self.tWidgetPersonalCard[nIndex], szGlobalID)
            self.tScriptPersonalCard[nIndex]:OnEnter(szGlobalID)
            self.tScriptPersonalCard[nIndex]:SetPlayerId(dwPlayerID)
            self.tScriptPersonalCard[nIndex]:SetEquipNumVisible(false)
            self.tScriptPersonalCard[nIndex]:SetPersonalInfo(tPersonalInfo)

            UIHelper.SetAnchorPoint(self.tScriptPersonalCard[nIndex]._rootNode, 0.5, 0.5)
        end
    end
end

function UIBattlePersonalCardSettleView:UpdateTime()
    local nCurTime = GetCurrentTime()

    if ArenaData.IsInArena() or self.bTreasureBattle then
        nCurTime = GetTickCount()
    end

    if self.nBanishTime and self.nBanishTime > nCurTime then
        local nTime = self.nBanishTime - nCurTime
        -- UIHelper.SetString(self.LabelNum, tostring(nTime))
        -- UIHelper.SetVisible(self.LabelTime, true)

        local szContent = string.format("<color=#d7f6ff>将在</c><color=#ffe26e>%s秒</c><color=#d7f6ff>后传出战场</c>", nTime)
        if ArenaData.IsInArena() or self.bTreasureBattle then
            nTime = math.floor((self.nBanishTime - nCurTime) / 1000)
            nTime = math.max(nTime, 0)
            if ArenaData.IsInArena()   then
                szContent = string.format("<color=#d7f6ff>将在</c><color=#ffe26e>%s秒</c><color=#d7f6ff>后传出名剑大会</c>", nTime)
            else
                szContent = string.format("<color=#d7f6ff>将在</c><color=#ffe26e>%s秒</c><color=#d7f6ff>后传出战场</c>", nTime)
            end
        end

        UIHelper.SetRichText(self.RichTextTime, szContent)
        UIHelper.SetVisible(self.RichTextTime, true)
    else
        self.nBanishTime = nil
        -- UIHelper.SetVisible(self.LabelTime, false)
        UIHelper.SetVisible(self.RichTextTime, false)
    end
end

function UIBattlePersonalCardSettleView:SetVisible(bVisible)
    UIHelper.SetOpacity(self._rootNode, bVisible and 255 or 0)
    for _, node in ipairs(self.tWidgetPersonalCard) do
        UIHelper.SetVisible(node, bVisible)
    end

    if bVisible then
        UIHelper.PlayAni(self, self.AniAll, "AniBattlePersonalCardSettleShow")
    end
end

function UIBattlePersonalCardSettleView:GetImgPathByExcellentID(dwExcellentID)
    local nIndex = tExcellentIDToImgTextIndex[dwExcellentID]
    if nIndex then
        return "UIAtlas2_Pvp_PvpTopOne1_img_text" .. nIndex
    end
end

return UIBattlePersonalCardSettleView