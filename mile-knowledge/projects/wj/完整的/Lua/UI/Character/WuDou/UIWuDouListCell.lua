-- ---------------------------------------------------------------------------------
-- Author: Unknown
-- Name: UIWuDouListCell
-- Date: 2022-12-23 10:55:15
-- Desc: ?
-- ---------------------------------------------------------------------------------

local UIWuDouListCell = class("UIWuDouListCell")

local nApplyType2Words = {
    [REAL_TIME_RANK_LIST_TYPE.KILLER] = {
        szScoreName = "当前敌对数"
    },
    [REAL_TIME_RANK_LIST_TYPE.HUNTER] = {
        szScoreName = "本周抓捕数"
    },
    [REAL_TIME_RANK_LIST_TYPE.WANTED] = {
        szRewardName = "赏金额",
        szScoreName = "剩余时间"
    },
}

local APPLY_TONG_NAME_TYPE = 6
local nRankPos2Icon = {
    [1] = "UIAtlas2_Public_PublicIcon_PublicIcon1_icon_ranking01.png",
    [2] = "UIAtlas2_Public_PublicIcon_PublicIcon1_icon_ranking02.png",
    [3] = "UIAtlas2_Public_PublicIcon_PublicIcon1_icon_ranking03.png",
    
}

local function CheckSelfLegal(szName)
    if not szName or szName == "" then
        return
    end

    local hPlayer = GetClientPlayer()
    if not hPlayer then
        return
    end

    if hPlayer.szName == szName then
        return true
    end
end

local function CheckTeamLegal(szName)
    if not szName or szName == "" then
        return
    end
    local hPlayer = GetClientPlayer()
    if not hPlayer then
        return
    end

    if hPlayer.szName == szName then
        return
    end

    if not hPlayer.IsInParty() then
        return
    end

    local hTeam = GetClientTeam()
    if not hTeam then
        return
    end

    local nGroupID = hTeam.GetMemberGroupIndex(hPlayer.dwID)
    local tGroupInfo = hTeam.GetGroupInfo(nGroupID)
    for _, dwID in pairs(tGroupInfo.MemberList) do
        local tMemberInfo = hTeam.GetMemberInfo(dwID)
        if tMemberInfo and tMemberInfo.szName == szName then
            return true
        end
    end
end

local function CheckGuildLegal(dwTongID)
    if dwTongID == 0 then
        return
    end

    local hPlayer = GetClientPlayer()
    if not hPlayer then
        return
    end

    if not hPlayer.dwTongID == 0 then
        return
    end

    --同帮会
    if hPlayer.dwTongID == dwTongID then
        return true
    end

    local tData = GetTongDiplomacyList(hPlayer.dwTongID, TONG_DIPLOMACY_RELATION_TYPE.ALLIANCE)
    if not tData or IsTableEmpty(tData) then
        return
    end

    --同盟
    for _, v in pairs(tData) do
        if v.dwSrcTongID == dwTongID or v.dwDstTongID == dwTongID then
            return true
        end
    end
end

local function CanJoinGuild(dwTongID)
    if dwTongID == 0 then
        return
    end

    local hPlayer = g_pClientPlayer
    if not hPlayer then
        return
    end

    if hPlayer.dwTongID ~= 0 then
        return 
    end
    return true
end

function UIWuDouListCell:OnEnter(nApplyType, nIndex, tRecord, bPrivate)
    if not tRecord then
        return
    end
    if not self.bInit then
        self:RegEvent()
        self:BindUIEvent()
        self.bInit = true
    end
    self:UpdateInfo(nApplyType, nIndex, tRecord, bPrivate)
    Timer.AddFrame(self, 1, function ()
        self:Resize()
    end)
end

function UIWuDouListCell:OnExit()
    self.bInit = false
    self:UnRegEvent()
end

function UIWuDouListCell:BindUIEvent()
    UIHelper.BindUIEvent(self.BtnAll, EventType.OnClick, function ()
        if self.nApplyType == REAL_TIME_RANK_LIST_TYPE.WANTED then
            Event.Dispatch(EventType.OnClickWantedRankCell, self.szName)
        else
            Event.Dispatch(EventType.OnClickHunterRankCell, self.szName)
        end        
    end)

    UIHelper.BindUIEvent(self.BtnRank, EventType.OnClick, function ()
        UIMgr.Open(VIEW_ID.PanelMiddleMap, self.dwMapID, 0)
    end)
end

function UIWuDouListCell:RegEvent()
    Event.Reg(self, "ON_GET_TONG_NAME_NOTIFY", function()
         if arg0 == APPLY_TONG_NAME_TYPE then
            self:UpdateTongName()
        end
    end)


end

function UIWuDouListCell:UnRegEvent()
    --Event.UnReg(self, EventType.XXX)
end

function UIWuDouListCell:OnHeadClick()
    -- if self.nApplyType ~= REAL_TIME_RANK_LIST_TYPE.WANTED then return end
    local bIsWanted = self.nApplyType == REAL_TIME_RANK_LIST_TYPE.WANTED
    local tRecord = self.tRecord
    local szPlayerName = self.szName
    local dwForceID = tRecord.dwForceID
    local nRoleType = tRecord.nRoleType
    local dwPlayerID = tRecord.dwID

    local tbAllMenuConfig = {
        {
            szName = bIsWanted and "追加金额" or "发布决斗",
            bCloseOnClick = true,
            callback = function ()
                if bIsWanted then
                    Event.Dispatch(EventType.OnClickWantedRankCell, self.szName)
                else
                    Event.Dispatch(EventType.OnClickHunterRankCell, self.szName)
                end  
            end
        },
        {
            szName = "加为好友",
            bCloseOnClick = true,
            callback = function ()
                GetSocialManagerClient().AddFellowship(UTF8ToGBK(szPlayerName))
            end
        },
        {
            szName = "组队",
            bCloseOnClick = true,
            callback = function()
                TeamData.InviteJoinTeam(UTF8ToGBK(szPlayerName))
            end,
            fnDisable = function()
                return not TeamData.CanMakeParty()
            end
        },
        {
            szName = "拜师收徒", bNesting = true, tbSubMenus =
            {
                { szName = "收徒", bCloseOnClick = true, callback = function()
                    RemoteCallToServer("OnApplyApprentice", UTF8ToGBK(szPlayerName))
                end },
                { szName = "拜师", bCloseOnClick = true, callback = function()
                    RemoteCallToServer("OnApplyMentor", UTF8ToGBK(szPlayerName))
                end },
                { szName = "拜亲传师父", bCloseOnClick = true, callback = function()
                    RemoteCallToServer("OnApplyDirectMentor", UTF8ToGBK(szPlayerName))
                end },
            }
        },

        {
            szName = "邀请入帮",
            bCloseOnClick = true,
            callback = function()
                if BankLock.CheckHaveLocked(SAFE_LOCK_EFFECT_TYPE.TONG_OPERATE, "Tong") then
                    return
                end

                TongData.InvitePlayerJoinTong(UTF8ToGBK(szPlayerName))
            end,
            fnDisable = function()
                return g_pClientPlayer.dwTongID == 0
            end,
            bHideIfDisable = false
        },
        {
            szName = "加入名剑队", bNesting = true, tbSubMenus = {
                { szName = "2对2", fnDisable = function()
                    SyncCorpsList(UI_GetClientPlayerID())
                    ArenaData.SyncAllCorpsBaseInfo()
                    local nCorpsID = ArenaData.GetCorpsID(ARENA_UI_TYPE.ARENA_2V2, UI_GetClientPlayerID())
                    if nCorpsID and nCorpsID > 0 then
                        return false
                    end
                    return CrossMgr.IsCrossing()
                end,
                callback = function()
                    TipsHelper.ShowNormalTip("已成功发出邀请")
                    local nCorpsID = ArenaData.GetCorpsID(ARENA_UI_TYPE.ARENA_2V2, UI_GetClientPlayerID())
                    InvitationJoinCorps(UTF8ToGBK(szPlayerName), nCorpsID)
                end },
                { szName = "3对3", fnDisable = function()
                    SyncCorpsList(UI_GetClientPlayerID())
                    ArenaData.SyncAllCorpsBaseInfo()
                    local nCorpsID = ArenaData.GetCorpsID(ARENA_UI_TYPE.ARENA_3V3, UI_GetClientPlayerID())
                    if nCorpsID and nCorpsID > 0 then
                        return false
                    end
                    return CrossMgr.IsCrossing()
                end,callback = function()
                    TipsHelper.ShowNormalTip("已成功发出邀请")
                    local nCorpsID = ArenaData.GetCorpsID(ARENA_UI_TYPE.ARENA_3V3, UI_GetClientPlayerID())
                    InvitationJoinCorps(UTF8ToGBK(szPlayerName), nCorpsID)
                end },
                { szName = "5对5", fnDisable = function()
                    ArenaData.SyncAllCorpsBaseInfo()
                    local nCorpsID = ArenaData.GetCorpsID(ARENA_UI_TYPE.ARENA_5V5, UI_GetClientPlayerID())
                    if nCorpsID and nCorpsID > 0 then
                        return false
                    end
                    return CrossMgr.IsCrossing()
                end,callback = function()
                    TipsHelper.ShowNormalTip("已成功发出邀请")
                    local nCorpsID = ArenaData.GetCorpsID(ARENA_UI_TYPE.ARENA_5V5, UI_GetClientPlayerID())
                    InvitationJoinCorps(UTF8ToGBK(szPlayerName), nCorpsID)
                end },
                { szName = "海选赛", fnDisable = function()
                    ArenaData.SyncAllCorpsBaseInfo()
                    local nCorpsID = ArenaData.GetCorpsID(ARENA_UI_TYPE.ARENA_MASTER_3V3, UI_GetClientPlayerID())
                    if nCorpsID and nCorpsID > 0 then
                        return false
                    end
                    return CrossMgr.IsCrossing()
                end,callback = function()
                    TipsHelper.ShowNormalTip("已成功发出邀请")
                    local nCorpsID = ArenaData.GetCorpsID(ARENA_UI_TYPE.ARENA_MASTER_3V3, UI_GetClientPlayerID())
                    InvitationJoinCorps(UTF8ToGBK(szPlayerName), nCorpsID)
                end },
                { szName = "名剑训练赛", fnDisable = function()
                    ArenaData.SyncAllCorpsBaseInfo()
                    if nCorpsID and nCorpsID > 0 then
                        return false
                    end
                    return CrossMgr.IsCrossing()
                end,callback = function()
                    TipsHelper.ShowNormalTip("已成功发出邀请")
                    local nCorpsID = ArenaData.GetCorpsID(ARENA_UI_TYPE.ARENA_PRACTICE, UI_GetClientPlayerID())
                    InvitationJoinCorps(UTF8ToGBK(szPlayerName), nCorpsID)
                end },
            }
        },

        {
            szName = "邀请加入团购",
            bCloseOnClick = true,
            bHideIfDisable = true,
            callback = function()
                GetHomelandMgr().BuyLandGrouponAddPlayerRequest(UTF8ToGBK(szPlayerName))
            end,
            fnDisable = function()
                return not HomelandGroupBuyData.State or not HomelandGroupBuyData.State.bInGroupBuyState
                    or not HomelandGroupBuyData.IsGroupBuyOrganizer()
            end
        },

        {
            szName = "举报外挂",
            bCloseOnClick = true,
            callback = function()
                local dwMapID = MapHelper.GetMapID()
                local tbSelectInfo =
                {
                    szName = UTF8ToGBK(szPlayerName),
                    szMapName = Table_GetMapName(dwMapID),
                }
                UIMgr.Open(VIEW_ID.PanelTutorialCollection, ServiceCenterData.TabModleType.InformScript, tbSelectInfo, 1)
            end
        },

        {
            szName = "信誉举报",
            bCloseOnClick = true,
            callback = function()
                --战场举报/JJC举报
                local dwReportID = BattleFieldData.IsCanReportPlayer(UTF8ToGBK(szPlayerName)) or ArenaData.IsCanReportPlayer(UTF8ToGBK(szPlayerName))
                if dwReportID then
                    RemoteCallToServer("On_XinYu_Jubao", dwReportID)
                end
            end,
            fnCheckShow = function()
                return BattleFieldData.IsCanReportPlayer(UTF8ToGBK(szPlayerName)) or ArenaData.IsCanReportPlayer(UTF8ToGBK(szPlayerName))
            end
        },

         {
            szName = "反馈问题",
            bCloseOnClick = true,
            callback = function()
                local tbSelectInfo =
                {
                    nSelectIndex = 1,
                    tbParams = {}
                }
                local tbScript = UIMgr.Open(VIEW_ID.PanelTutorialCollection, ServiceCenterData.TabModleType.FeeBug, tbSelectInfo , 1)
                TipsHelper.DeleteAllHoverTips()
            end
        },

        {
            szName = "屏蔽发言",
            bCloseOnClick = true,
            fnCheckShow = function()
                return true
            end,
            callback = function()
                FellowshipData.AddBlackList(UTF8ToGBK(szPlayerName), 0, 0)
            end,
            fnDisable = function()
                return not UTF8ToGBK(szPlayerName)
            end
        },
    }

    local tbPlayerCard = {
        dwMiniAvatarID = nil,
        nRoleType = nRoleType,
        dwForceID = dwForceID,
        nLevel = nil,
        szName = UTF8ToGBK(szPlayerName),
        nCamp = nil,
        dwCenterID = nil,
    }
    local tips, script = TipsHelper.ShowNodeHoverTipsInDir(PREFAB_ID.WidgetPlayerPop, self.scriptHead._rootNode, TipsLayoutDir.RIGHT_CENTER, dwPlayerID, tbAllMenuConfig, tbPlayerCard, nil, true)
    script:SetEquipVis(false)
end

function UIWuDouListCell:OnHead2Click()
    if self.nApplyType == REAL_TIME_RANK_LIST_TYPE.WANTED and self.bPrivate then
        local dwForceID = self.tRecord.dwForceID
        local szPayerName = self.tRecord.szPayerName
        local dwTongID = self.tRecord.dwTongID
        local szTongName = self.szTongName
        local bSelf = CheckSelfLegal(szPayerName)
        local szPlayerName = self:GetPayerName()

        local tbAllMenuConfig = {
            {
                szName = "组队申请",
                bCloseOnClick = true,
                callback = function()
                    UI_PlayerInviteJoinTeam(szPayerName)
                end,
                fnDisable = function()
                    return not (TeamData.CanMakeParty() and szPayerName ~= "" and not bSelf)
                end
            },
            {
                szName = "帮会申请",
                bCloseOnClick = true,
                callback = function()
                    if szTongName and szTongName ~= ""then
                        RemoteCallToServer("On_Tong_ApplyJoinRequest", UIHelper.UTF8ToGBK(szTongName))
                    end
                end,
                fnDisable = function()
                    return not (dwTongID and CanJoinGuild(dwTongID) and szPayerName ~= "" and not bSelf)
                end
            },
        }

        local tbPlayerCard = {
            dwMiniAvatarID = nil,
            nRoleType = nil,
            dwForceID = nil,
            nLevel = nil,
            szName = UTF8ToGBK(szPlayerName),
            nCamp = nil,
            dwCenterID = nil,
            szImgHeadIcon = "UIAtlas2_Public_PublicSchool_PublicSchool_iocn_school_DaXia",
        }
        local tips, script = TipsHelper.ShowNodeHoverTipsInDir(PREFAB_ID.WidgetPlayerPop, self.scriptHead2._rootNode, TipsLayoutDir.LEFT_CENTER, nil, tbAllMenuConfig, tbPlayerCard, nil, true)
        script:SetShareVis(szPlayerName ~= g_tStrings.STR_WANTED_ANONYMOUS)
        script:SetEquipVis(false)
    end
end


function UIWuDouListCell:UpdateInfo(nApplyType, nIndex, tRecord, bPrivate)
    self.nApplyType = nApplyType
    self.tRecord = tRecord
    self.bPrivate = bPrivate
    local szName = UIHelper.GBKToUTF8(tRecord.szName)    
    local szScore = tRecord.nScore and UIHelper.GBKToUTF8(tRecord.nScore)
    local nForceID = tonumber(tRecord.dwForceID)
    local szImgName = PlayerForceID2SchoolImg2[nForceID]
    local dwPlayerID = tonumber(tRecord.dwID)
    local dwMiniAvatarID = tonumber(tRecord.dwMiniAvatarID)
    local nRoleType = tonumber(tRecord.nRoleType)
    local szDescription = tRecord.szDescription and UIHelper.GBKToUTF8(tRecord.szDescription)
    local dwTongID = tRecord.dwTongID
    local szPayerName = tRecord.szPayerName
    local bSelf = CheckSelfLegal(szPayerName)
    local bTeamLegal = szPayerName and CheckTeamLegal(szPayerName)
    local bGuildLegal = dwTongID and CheckGuildLegal(dwTongID)
    local nTimeNow = os.time()
    local bTargetOffline = tRecord.dwMapID == nil or tRecord.dwMapID == 0
    local bIsWanted = nApplyType == REAL_TIME_RANK_LIST_TYPE.WANTED

    self.szName = szName
    self.nApplyType = nApplyType

    self.scriptHead = self.scriptHead or UIHelper.AddPrefab(PREFAB_ID.WidgetHead, self.WidgetHead, dwPlayerID)
    self.scriptHead:SetClickCallback(function() self:OnHeadClick() end)
    Timer.AddFrame(self, 1, function ()
        -- if dwMiniAvatarID then
        --     self.scriptHead:SetRankFlag(true, false)
        --     self.scriptHead:SetHeadInfo(dwPlayerID, dwMiniAvatarID, nRoleType, nForceID)
        -- else
            self.scriptHead:SetHeadWithForceID(nForceID)--端游直接用的门派图标
        -- end
    end)
    
    UIHelper.SetString(self.LabelPlayerName, szName, 4)
    UIHelper.SetSpriteFrame(self.ImgPlayerSchool, szImgName)
    UIHelper.SetString(self.LabelLocation, "")
    UIHelper.SetString(self.LabelNumber, szScore)
    UIHelper.SetString(self.LabelNumberTitle, nApplyType2Words[nApplyType].szScoreName)

    UIHelper.SetVisible(self.ImgSignal, false)
    UIHelper.SetVisible(UIHelper.GetParent(self.LabelLocation), bIsWanted)
    UIHelper.SetVisible(self.LabelReward, bIsWanted)
    UIHelper.SetVisible(self.LabelRewardNum, bIsWanted)
    UIHelper.SetVisible(self.ImgMoneyIcon, bIsWanted)
    UIHelper.SetVisible(self.LabelNumber, true)

    UIHelper.SetSwallowTouches(self.BtnRank, false)
    UIHelper.SetVisible(self.BtnRank, false)
    
    UIHelper.SetVisible(self.LabelRewardValid, bTeamLegal or bGuildLegal or bSelf)

    if bIsWanted then
        if tRecord.dwMapID and tRecord.dwMapID > 0 then
            local dwMap = tonumber(tRecord.dwMapID)
            local tMapInfo = Table_GetMap(dwMap)
            local szMapName = UIHelper.GBKToUTF8(tMapInfo.szName)
            self.dwMapID = dwMap
            UIHelper.SetString(self.LabelLocation, szMapName, 6)
            UIHelper.SetVisible(self.BtnRank, dwPlayerID ~= UI_GetClientPlayerID())
        else
            UIHelper.SetString(self.LabelLocation, "已离线")
        end
        
        if tRecord.nTimeOut then
            local nTimeOut = tonumber(tRecord.nTimeOut)
            local szTime = UIHelper.GetHeightestTimeText(nTimeOut - nTimeNow)
            UIHelper.SetString(self.LabelNumber, szTime)
        else
            UIHelper.SetVisible(self.LabelNumber, false)
        end
        UIHelper.SetString(self.LabelRewardNum, tRecord.nMoney)
        UIHelper.SetString(self.LabelReward, nApplyType2Words[nApplyType].szRewardName)
    end

    local szRankIcon = nRankPos2Icon[nIndex]
    local bTop3 = szRankIcon ~= nil
    if bTop3 then
        UIHelper.SetSpriteFrame(self.ImgRankIcon, szRankIcon)
    else
        UIHelper.SetString(self.LabelRankNumber, tostring(nIndex))
    end
    UIHelper.SetVisible(self.ImgRankIcon, bTop3)
    UIHelper.SetVisible(self.LabelRankNumber, not bTop3)

    --UIHelper.SetVisible(self.ImgRankBg, nIndex % 2 ~= 0)
    UIHelper.LayoutDoLayout(UIHelper.GetParent(self.LabelRewardNum))
    UIHelper.LayoutDoLayout(UIHelper.GetParent(self.LabelPlayerName))
    Timer.AddFrame(self, 1, function ()
        UIHelper.CascadeDoLayoutDoWidget(self._rootNode, true, true)
    end)

    local bOnline = tRecord.dwMapID and tRecord.dwMapID > 0
    local bShowOnline = (nApplyType == REAL_TIME_RANK_LIST_TYPE.KILLER or nApplyType == REAL_TIME_RANK_LIST_TYPE.WANTED)
    and bOnline
    local szStateImg = bShowOnline and FRIEND_ONLINE_STATE[1] or FRIEND_ONLINE_STATE[0]
    UIHelper.SetSpriteFrame(self.ImgOnline, szStateImg)

    UIHelper.SetVisible(self.BtnPlayer2, szPayerName ~= nil and self.bPrivate)
    if szPayerName and self.bPrivate then
        UIHelper.SetString(self.LabelPlayerName2, self:GetPayerName(), 4)
        self.scriptHead2 = self.scriptHead2 or UIHelper.AddPrefab(PREFAB_ID.WidgetHead, self.WidgetHead2, nil)
        self.scriptHead2:SetHeadWithImg("UIAtlas2_Public_PublicSchool_PublicSchool_iocn_school_DaXia")
        self.scriptHead2:SetClickCallback(function() self:OnHead2Click() end)
    end
    
    self:UpdateTongName()

end

function UIWuDouListCell:GetPayerName()
    local szPayerName = self.tRecord.szPayerName
    if szPayerName and szPayerName ~= "" then
        return UIHelper.GBKToUTF8(szPayerName)
    end
    return g_tStrings.STR_WANTED_ANONYMOUS
end


function UIWuDouListCell:UpdateTongName()
    local dwTongID = self.tRecord.dwTongID
    if not dwTongID then return end
    if dwTongID == 0 then
        self.szTongName = "暂无帮会"
    else
        self.szTongName = UIHelper.GBKToUTF8(TongData.GetName(dwTongID, APPLY_TONG_NAME_TYPE))
    end
    if self.tRecord.szPayerName == "" then self.szTongName = "未知帮会" end
    UIHelper.SetString(self.LabelTongName, self.szTongName)
end

function UIWuDouListCell:Resize()
    local nodeParent = UIHelper.GetParent(self._rootNode)
    local nodeGrandParent = UIHelper.GetParent(nodeParent)
    local nWidth = UIHelper.GetWidth(nodeGrandParent)

    UIHelper.SetWidth(nodeParent, nWidth)
    UIHelper.CascadeDoLayoutDoWidget(self._rootNode, true, true)
end

return UIWuDouListCell