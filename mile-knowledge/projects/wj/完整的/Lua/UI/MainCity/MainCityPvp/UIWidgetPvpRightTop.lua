-- ---------------------------------------------------------------------------------
-- Author: Unknown
-- Name: UIWidgetPvpRightTop
-- Date: 2022-12-09 11:10:03
-- Desc: PVP右上角实时战斗信息 WidgetPvpRightTop
-- ---------------------------------------------------------------------------------
local NAME_TO_UI_INDEX = {
    ["织梦梭"] = 1,
    ["关卡"] = 2,
    ["心念"] = 3,
    ["命魂"] = 4,
}

local UIWidgetPvpRightTop = class("UIWidgetPvpRightTop")

---_LuaBindList 在这里对绑定的组件进行无意义自赋值，从而方便查询以及ide进行智能提示
function UIWidgetPvpRightTop:_LuaBindList()
    self.WidgetMobaKill               = self.WidgetMobaKill --- moba KDA 组件
    self.LabelMobaKill                = self.LabelMobaKill --- moba KDA label

    self.WidgetScore                  = self.WidgetScore --- 比分信息
    self.LabelScoreBlue               = self.LabelScoreBlue --- 蓝方比分
    self.LabelScoreRed                = self.LabelScoreRed --- 红方比分
    self.LayoutBlue                   = self.LayoutBlue --- 蓝方比分的layout
    self.LayoutRed                    = self.LayoutRed --- 红方比分的layout

    self.WidgetScoreMoba              = self.WidgetScoreMoba --- MOBA比分信息
    self.LayoutRedMoba                = self.LayoutRedMoba --- 红方比分的layout
    self.LayoutBlueMoba               = self.LayoutBlueMoba --- 蓝方比分的layout
    self.ImgScoreRedMoba              = self.ImgScoreRedMoba --- 红方比分的图标
    self.LabelScoreRedMoba            = self.LabelScoreRedMoba --- 红方比分的label
    self.ImgScoreBlueMoba             = self.ImgScoreBlueMoba --- 蓝方比分的图标
    self.LabelScoreBlueMoba           = self.LabelScoreBlueMoba --- 蓝方比分的label

    -- ---------------- 帮会联赛 ----------------
    self.WidgetFactionChampionship    = self.WidgetFactionChampionship --- 帮会联赛核心数据组件
    self.FactionLabelRedFlagPercent   = self.FactionLabelRedFlagPercent --- 红方大旗血量百分比的label
    self.FactionSliderRedFlagPercent  = self.FactionSliderRedFlagPercent --- 红方大旗血量百分比的进度条
    self.FactionLabelMoraleRed        = self.FactionLabelMoraleRed --- 红方士气值
    self.FactionLabelBlueFlagPercent  = self.FactionLabelBlueFlagPercent --- 蓝方大旗血量百分比的label
    self.FactionSliderBlueFlagPercent = self.FactionSliderBlueFlagPercent --- 蓝方大旗血量百分比的进度条
    self.FactionLabelMoraleBlue       = self.FactionLabelMoraleBlue --- 蓝方士气值

    self.BtnSkill                     = self.BtnSkill --- 打开武学界面；在帮会联赛中，则是打开指挥界面

    self.WidgetFactionCommandPanel    = self.WidgetFactionCommandPanel --- 指挥面板挂载点

    self.WidgetDragonRed              = self.WidgetDragonRed --- 红方大龙buff 组件
    self.LabelDragonRed               = self.LabelDragonRed --- 红方大龙buff 剩余时间
    self.WidgetDragonBlue             = self.WidgetDragonBlue --- 蓝方大龙buff 组件
    self.LabelDragonBlue              = self.LabelDragonBlue --- 蓝方大龙buff 剩余时间

    self.BtnTongWarCommandPanel       = self.BtnTongWarCommandPanel --- 打开指挥面板

    self.ImgFactionRed                = self.ImgFactionRed --- 红方标记图片
    self.ImgFactionBlue               = self.ImgFactionBlue --- 蓝方标记图片

    self.LabelBlueFactionName         = self.LabelBlueFactionName --- 蓝方 帮会名
    self.LabelBlueServerName          = self.LabelBlueServerName --- 蓝方 服务器名
    self.LabelRedFactionName          = self.LabelRedFactionName --- 红方 帮会名
    self.LabelRedServerName           = self.LabelRedServerName --- 红方 服务器名

    self.LayoutChampionshipData       = self.LayoutChampionshipData --- 帮会联赛关键数据上层的layout

    self.WidgetGlobalViewTimeRed      = self.WidgetGlobalViewTimeRed --- 红方全局视野 组件
    self.LabelGlobalViewTimeRed       = self.LabelGlobalViewTimeRed --- 红方全局视野 剩余时间
    self.WidgetGlobalViewTimeBlue     = self.WidgetGlobalViewTimeBlue --- 蓝方全局视野 组件
    self.LabelGlobalViewTimeBlue      = self.LabelGlobalViewTimeBlue --- 蓝方全局视野 剩余时间

    self.FactionLabeMapLevel          = self.FactionLabeMapLevel --- 地图等级类别
end

local tbIconPath = {
    --nBattleFieldSide 0 我方为蓝色，nBattleFieldSide 1 我方为红色
    Blue = {
        [0] = "UIAtlas2_Pvp_PvpMainCity_Icon4", --我方 nBattleFieldSide == 0
        [1] = "UIAtlas2_Pvp_PvpMainCity_Icon3", --敌方
    },
    Red = {
        [0] = "UIAtlas2_Pvp_PvpMainCity_Icon1", --敌方
        [1] = "UIAtlas2_Pvp_PvpMainCity_Icon2", --我方 nBattleFieldSide == 1
    },

    ArenaBlue = {
        [0] = "UIAtlas2_Pvp_PvpMainCity_Icon3", --敌方
        [1] = "UIAtlas2_Pvp_PvpMainCity_Icon4", --我方 nBattleFieldSide == 1
    },
    ArenaRed = {
        [0] = "UIAtlas2_Pvp_PvpMainCity_Icon2", --我方 nBattleFieldSide == 0
        [1] = "UIAtlas2_Pvp_PvpMainCity_Icon1", --敌方
    },

    SwordBlue = "UIAtlas2_Public_PublicIcon_PublicIcon1_icon_friend",
    SwordRed = "UIAtlas2_Public_PublicIcon_PublicIcon1_icon_enemy",
    YunHu = "UIAtlas2_Public_PublicIcon_PublicIcon1_img_FlagRed",
    JiuGong1 = "UIAtlas2_Public_PublicIcon_PublicIcon1_img_FlagRed", --右
    JiuGong2 = "UIAtlas2_Public_PublicIcon_PublicIcon1_img_FlagRed", --左
}

function UIWidgetPvpRightTop:OnEnter(nPlayType, nSubType, tbArgs)
    self.nPlayType       = nPlayType
    self.nSubType        = nSubType
    self.tbArgs          = tbArgs
    self.bBattleFieldEnd = false

    if not self.bInit then
        self:RegEvent()
        self:BindUIEvent()
        self.bInit = true

        --自身默认隐藏
        self:SetVisible(false)

        UIHelper.UpdateMask(self.MaskLight)
        UIHelper.UpdateMask(self.MaskLightLine)
    end

    self:UpdateInfo()
end

function UIWidgetPvpRightTop:OnExit()
    self.bInit = false
    self:UnRegEvent()
end

function UIWidgetPvpRightTop:BindUIEvent()
    UIHelper.BindUIEvent(self.BtnQuickOperation, EventType.OnClick, function()
        if not UIMgr.GetView(VIEW_ID.PanelQuickOperation) then
            UIMgr.Open(VIEW_ID.PanelQuickOperation)
        end
    end)

    UIHelper.BindUIEvent(self.BtnBattleIEsc, EventType.OnClick, function(btn)
        if ArenaData.IsInArena() then
            if IfOpenBoxLeaveArenaMap and IfOpenBoxLeaveArenaMap(PlayerData.GetClientPlayer()) then
                UIHelper.ShowConfirm(g_tStrings.STR_ARENA_LEAVE_SURE, function()
                    ArenaData.LogOutArena()
                end)
            else
                UIHelper.ShowConfirm("您确定要现在离开吗？", function()
                    ArenaData.LogOutArena()
                end)
            end
        elseif BahuangData.IsInBaHuangMap() then
            UIHelper.ShowConfirm("是否立即结算？", function()
                RemoteCallToServer("On_EightWastes_FinishScene")
            end)
        elseif MapHelper.IsRemotePvpMap() then
            PVPFieldData.LeavePVPField()
        elseif BattleFieldData.IsInZombieBattleFieldMap() then
            UIHelper.ShowConfirm("您确定要现在离开吗？", function()
                BattleFieldData.LeaveBattleField()
            end)
        end
    end)


    UIHelper.BindUIEvent(self.BtnBattleInfo, EventType.OnClick, function()
        if ArenaData.IsInArena() then
            if not UIMgr.IsViewOpened(VIEW_ID.PanelPVPInterface) then
                UIMgr.Open(VIEW_ID.PanelPVPInterface)
            end
        elseif BahuangData.IsInBaHuangMap() then
            if not UIMgr.GetView(VIEW_ID.PanelBahuangSettings) then
                UIMgr.Open(VIEW_ID.PanelBahuangSettings)
            end
        elseif BattleFieldData.IsInBattleField() then
            local nBFMapType      = MapHelper.GetBattleFieldType()
            local bNotNewPlayerBF = nBFMapType ~= BATTLEFIELD_MAP_TYPE.NEWCOMERBATTLE
            local bTreasureBattle = nBFMapType == BATTLEFIELD_MAP_TYPE.TREASUREBATTLE or nBFMapType == BATTLEFIELD_MAP_TYPE.TREASURE_HUNT

            if bTreasureBattle then
                if BattleFieldData.BattleField_IsEnd() then
                    UIMgr.Open(VIEW_ID.PanelEndSettlement)
                else
                    UIMgr.Open(VIEW_ID.PanelBattleFieldPubgListPop)
                end
                return
            end

            if bNotNewPlayerBF or self.bBattleFieldEnd then
                BattleFieldData.OpenBattleFieldSettle(bNotNewPlayerBF)
            else
                --若在拭剑园战场且游戏未结束，则不弹数据界面 直接询问是否退出，因为这里结算数据是假的，局内无法获取实时的数据
                UIHelper.ShowConfirm(g_tStrings.STR_SURE_LEAVE_BATTLE, BattleFieldData.LeaveBattleField)
            end
        end
    end)
    UIHelper.BindUIEvent(self.BtnSkill, EventType.OnClick, function()
        if BahuangData.IsInBaHuangMap() then
            if not UIMgr.IsViewOpened(VIEW_ID.PanelBaHuangEditSkill) then
                UIMgr.Open(VIEW_ID.PanelBaHuangEditSkill)
            end
        elseif TreasureBattleFieldSkillData.IsInDynamic() then
            self:ShowExtractEquipSwitchPanel()
        else
            if not UIMgr.IsViewOpened(VIEW_ID.PanelSkillNew) then
                SkillData.TryOpenPanelSkillNew()
            end
        end
    end)
    UIHelper.BindUIEvent(self.BtnOverview, EventType.OnClick, function(btn)
        UIMgr.Open(VIEW_ID.PanelYangDaoOverview)
    end)
    UIHelper.BindUIEvent(self.BtnTongWarCommandPanel, EventType.OnClick, function()
        if BattleFieldData.IsInTongWarFieldMap() then
            self:ShowTongWarCommandPanel()
        end
    end)
    UIHelper.BindUIEvent(self.BtnSystemMenu, EventType.OnClick, function()
        if not UIMgr.IsViewOpened(VIEW_ID.PanelSystemMenu) then
            UIMgr.Open(VIEW_ID.PanelSystemMenu)
        end
    end)
    UIHelper.BindUIEvent(self.BtnBattleBag, EventType.OnClick, function()
        if BattleFieldData.IsInXunBaoBattleFieldMap() then
            ExtractWareHouseData.OpenExtractPersetPanel()
        elseif BattleFieldData.IsInTreasureBattleFieldMap() then
            UIMgr.Open(VIEW_ID.PanelBattleFieldPubgEquipBagRightPop)
        elseif BattleFieldData.IsInZombieBattleFieldMap() then
            UIMgr.Open(VIEW_ID.PanelHalfBag)
        else
            UIMgr.Open(VIEW_ID.PanelHalfBag)
        end
    end)
    UIHelper.BindUIEvent(self.BtnBattleFieldPubgMap, EventType.OnClick, function()
        if self.nPlayType == PlayType.JingHua then
            UIMgr.Open(VIEW_ID.PanelMiddleMap, 487, 0)
        elseif BattleFieldData.IsInXunBaoBattleFieldMap() then
            UIMgr.Open(VIEW_ID.PanelMiddleMap)
        else
            UIMgr.Open(VIEW_ID.PanelBattleFieldPubgMapRightPop)
        end
    end)
    UIHelper.BindUIEvent(self.BtnChangeMapSize, EventType.OnClick, function()
        UIHelper.SetVisible(self.WidgetMapPvp, false)
        UIHelper.SetVisible(self.WidgetMapPvp2, true)
        self:UpdateMapSize()
        UIHelper.LayoutDoLayout(self.LayoutPvpMap)
        UIHelper.LayoutDoLayout(self.LayoutAll)
        Event.Dispatch(EventType.OnPvpMapUpdate)
    end)
    UIHelper.BindUIEvent(self.BtnChangeMapSize2, EventType.OnClick, function()
        UIHelper.SetVisible(self.WidgetMapPvp, true)
        UIHelper.SetVisible(self.WidgetMapPvp2, false)
        self:UpdateMapSize()
        UIHelper.LayoutDoLayout(self.LayoutPvpMap)
        UIHelper.LayoutDoLayout(self.LayoutAll)
        Event.Dispatch(EventType.OnPvpMapUpdate)
    end)
    UIHelper.BindUIEvent(self.BtnSkillMessage, EventType.OnClick, function()
        ArenaData.PeekAllPlayerQiXue()
        Timer.Add(self, 0.5, function()
            ArenaData.OpenQiXuePanel()
        end)
    end)
    UIHelper.BindUIEvent(self.BtnNextStep, EventType.OnClick, function()
        if self.bChooseBless then
            UIMgr.Open(VIEW_ID.PanelBlessChoose)
        elseif ArenaTowerData.CanGetBattleFieldInfo() then
            ArenaTowerData.bArenaTowerViewFold = false
            self:UpdateArenaTowerBtnState()
        end
    end)
end

function UIWidgetPvpRightTop:RegEvent()
    --战场相关
    Event.Reg(self, EventType.BF_UpdateNewPlayerBF, function(dwEnemyCurrentScore, dwEnemyMaxScore, dwOwnCurrentScore, dwOwnMaxScore)
        if ArenaData.IsInArena() then return end
        self:NewPlayerBFUpdate(dwEnemyCurrentScore, dwEnemyMaxScore, dwOwnCurrentScore, dwOwnMaxScore)
    end)
    Event.Reg(self, EventType.BF_CloseNewPlayerBF, function()
        if ArenaData.IsInArena() then return end
        self:NewPlayerBFClose()
    end)

    Event.Reg(self, "BATTLE_FIELD_UPDATE_OBJECTIVE", function()
        if ArenaData.IsInArena() then return end
        LOG.INFO("[BattleField] BATTLE_FIELD_UPDATE_OBJECTIVE")
        self:BattleFieldUpdate()
    end)

    --竞技场相关
    Event.Reg(self, EventType.OnArenaPlayerUpdate, function()
        if not ArenaData.IsInArena() then return end
        self:UpdateArenaEnemyHead()
    end)

    Event.Reg(self, EventType.OnArenaEventNotify, function(szEvent, ...)
        if not ArenaData.IsInArena() then return end
        local tbParams = { ... }
        if szEvent == "PLAYER_UPDATE" then
            if ArenaData.IsInArena() then
                self:UpdateArenaTitleInfo(tbParams[1], tbParams[2])
            end
        end
    end)

    Event.Reg(self, EventType.OnArenaTowerPlayerUpdate, function()
        if not ArenaTowerData.IsInArenaTowerMap() then return end
        self:UpdateArenaTowerEnemyHead()
    end)

    --通用
    Event.Reg(self, EventType.OnClientPlayerLeave, function(nPlayerID)
        self.bBattleFieldEnd = false
        self:SetVisible(false)
    end)

    Event.Reg(self, EventType.On_Update_GeneralProgressBar, function(tbInfo)
        self:OnOtherInfoShow(tbInfo)
        self:UpdateJingHuaProgress(tbInfo)
    end)
    Event.Reg(self, EventType.On_Delete_GeneralProgressBar, function(szName)
        self:OnOtherInfoHide(szName)
    end)

    Event.Reg(self, EventType.OnUpdateBattleInfoList, function(szInfoType)
        if szInfoType == "nLastTime" then
            UIHelper.SetVisible(self.WidgetTime, true)
            self:SetCountDown(GetCurrentTime() + BahuangData.GetBattleInfoByType("nLastTime"))
            UIHelper.CascadeDoLayoutDoWidget(self.LayoutPvpInfo, true, true)
        end
    end)

    Event.Reg(self, EventType.OnClearBattleInfo, function()
        UIHelper.SetVisible(self.WidgetTime, false)
        UIHelper.CascadeDoLayoutDoWidget(self.LayoutPvpInfo, true, true)
    end)

    Event.Reg(self, "Moba_UpdatePlayerKillData", function(nKills, nAssistKills, nDeaths)
        UIHelper.SetString(self.LabelMobaKill, string.format("%d/%d/%d", nKills, nDeaths, nAssistKills))
    end)

    Event.Reg(self, EventType.OnTreasureHuntInfoOpen, function (dwID, nTime)
        self:SetCountDown()
    end)

    Event.Reg(self, EventType.OnWindowsSizeChanged, function()
        self:UpdateMapSize()
    end)

    Event.Reg(self, "ON_OPENTONGWAR_BATTLEINFO_NOTIFY", function(bIsOpen, nMapLevel)
        if bIsOpen then
            self:UpdateFactionChampionshipInfo()
        end
        UIHelper.SetVisible(self.WidgetFactionChampionship, bIsOpen)
    end)

    Event.Reg(self, "ON_SYNC_SCENE_TEMP_CUSTOM_DATA", function()
        if UIHelper.GetVisible(self.WidgetFactionChampionship) then
            self:UpdateFactionChampionshipInfo()
        end
    end)
    
    Event.Reg(self, EventType.OnArenaTowerUpdateRoundState, function()
        -- 扬刀大会局内数据 SPECIAL_OP_1 ~ SPECIAL_OP_4 更新（当前模式/当前关卡进度/关卡状态/准备状态）
        if not ArenaTowerData.IsInArenaTowerMap() then return end
        self:UpdateArenaTowerBtnState()
        self:UpdateArenaTowerTitleInfo()
    end)
    Event.Reg(self, EventType.OnArenaTowerDataUpdate, function()
        if not ArenaTowerData.IsInArenaTowerMap() then return end
        self:UpdateArenaTowerBtnState()
    end)
    Event.Reg(self, EventType.OnArenaTowerDiffProgressUpdate, function()
        if not ArenaTowerData.IsInArenaTowerMap() then return end
        self:UpdateArenaTowerLevelInfo()
    end)
    Event.Reg(self, EventType.OnArenaTowerUpdateLevelInfo, function()
        if not ArenaTowerData.IsInArenaTowerMap() then return end
        self:UpdateArenaTowerLevelInfo()
    end)
    Event.Reg(self, EventType.OnArenaTowerCardEventAniEnd, function()
        UIHelper.SetVisible(self.SFX_btnBoWen, false)
        UIHelper.SetVisible(self.SFX_btnBoWen, true)
    end)
    Event.Reg(self, "On_ArenaTower_ButtonShow", function()
        if not ArenaTowerData.IsInArenaTowerMap() then return end
        self:UpdateArenaTowerBtnState()
    end)
    Event.Reg(self, EventType.OnViewOpen, function(nViewID)
        if not ArenaTowerData.IsInArenaTowerMap() then return end
        if nViewID == VIEW_ID.PanelRevive then
            self:UpdateArenaTowerBtnState()
        end
    end)
    Event.Reg(self, EventType.OnViewClose, function(nViewID)
        if not ArenaTowerData.IsInArenaTowerMap() then return end
        if nViewID == VIEW_ID.PanelPostBattleOperation then
            ArenaTowerData.bArenaTowerViewFold = true
            self:UpdateArenaTowerBtnState()
        else
            self:UpdateArenaTowerBtnState()
            UIHelper.PlayAni(self, self.AniBtn, "AniFoldedBtnShow")
        end
    end)
end

function UIWidgetPvpRightTop:UnRegEvent()
    --Event.UnReg(self, EventType.XXX)
end

function UIWidgetPvpRightTop:SetVisible(bVisible)
    UIHelper.SetVisible(self._rootNode, bVisible)
end

function UIWidgetPvpRightTop:UpdateInfo()
    if self.nPlayType == PlayType.Arena then
        self:UpdateArenaEnemyHead()
        self:UpdateArenaTitleInfo(ArenaData.tbBattleData, ArenaData.nBattleStartTime)
    elseif self.nPlayType == PlayType.BattleField then
        if self.nSubType == BATTLEFIELD_MAP_TYPE.NEWCOMERBATTLE and self.tbArgs then
            self:NewPlayerBFOpen(table.unpack(self.tbArgs))
        else
            self:BattleFieldOpen()
        end
    elseif self.nPlayType == PlayType.CampWar then
        self:UpdateCampWarInfo()
    elseif self.nPlayType == PlayType.JingHua then
        self:UpdateJingHuaInfo()
    end

    local scriptMapBig = UIHelper.GetBindScript(self.WidgetMapPvp2)
    scriptMapBig:InitTouchComponent()
    self:UpdateMapSize()
end

---------------------------------------------------------------------------------
-------------------------------战场相关-------------------------------------------
---------------------------------------------------------------------------------

function UIWidgetPvpRightTop:NewPlayerBFOpen(dwEnemyCurrentScore, dwEnemyMaxScore, dwOwnCurrentScore, dwOwnMaxScore, dwEndTime)
    --注意参数顺序
    LOG.INFO("[BattleField] UIWidgetPvpRightTop:NewPlayerBF, Own(%d/%d):Enemy(%d/%d), nEndTime: %d",
             dwOwnCurrentScore, dwOwnMaxScore, dwEnemyCurrentScore, dwEnemyMaxScore, dwEndTime)

    self:BattleFieldOpen()
    self:SetCountDown(dwEndTime)
    self:NewPlayerBFUpdate(dwEnemyCurrentScore, dwEnemyMaxScore, dwOwnCurrentScore, dwOwnMaxScore)
end

function UIWidgetPvpRightTop:NewPlayerBFUpdate(dwEnemyCurrentScore, dwEnemyMaxScore, dwOwnCurrentScore, dwOwnMaxScore)
    -- --注意参数顺序
    -- LOG.INFO("[BattleField] UIWidgetPvpRightTop:BattleFieldUpdate, Own(%d/%d):Enemy(%d/%d)",
    -- dwOwnCurrentScore, dwOwnMaxScore, dwEnemyCurrentScore, dwEnemyMaxScore)

    UIHelper.SetString(self.LabelScoreBlue, string.format("%d/%d", dwOwnCurrentScore, dwOwnMaxScore))
    UIHelper.SetString(self.LabelScoreRed, string.format("%d/%d", dwEnemyCurrentScore, dwEnemyMaxScore))

    UIHelper.LayoutDoLayout(self.LayoutBlue)
    UIHelper.LayoutDoLayout(self.LayoutRed)
    UIHelper.LayoutDoLayout(self.WidgetScore)

    if dwEnemyCurrentScore >= dwEnemyMaxScore or dwOwnCurrentScore >= dwOwnMaxScore then
        self.bBattleFieldEnd = true
    else
        self.bBattleFieldEnd = false
    end
end

function UIWidgetPvpRightTop:NewPlayerBFClose()
    self.bBattleFieldEnd = true
end

function UIWidgetPvpRightTop:BattleFieldOpen()
    self.bBattleFieldEnd = false
    local dwMapID = MapHelper.GetMapID()

    self:Clear()
    self:SetVisible(true)

    --战场玩法，不显示系统菜单、快捷操作按钮、角色信息、其他信息
    UIHelper.SetVisible(self.WidgetEnemyPlayer, false)

    local nBFMapType      = MapHelper.GetBattleFieldType()
    --拭剑园战场隐藏地图、技能、系统菜单
    local bNewPlayerBF    = nBFMapType == BATTLEFIELD_MAP_TYPE.NEWCOMERBATTLE
    local bNormalBF       = nBFMapType == BATTLEFIELD_MAP_TYPE.BATTLEFIELD
    local bSkillTreasure  = BattleFieldData.IsInSkillTreasureBattleFieldMap()
    local bTreasureBattle = nBFMapType == BATTLEFIELD_MAP_TYPE.TREASUREBATTLE and not BattleFieldData.IsInSkillTreasureBattleFieldMap()
    local bFeiHuoLunFeng  = nBFMapType == BATTLEFIELD_MAP_TYPE.FBBATTLE
    local bZombie         = nBFMapType == BATTLEFIELD_MAP_TYPE.ZOMBIEBATTLE
    local bInBaHuangMap   = BahuangData.IsInBaHuangMap()
    local bMoba           = nBFMapType == BATTLEFIELD_MAP_TYPE.MOBABATTLE
    local bXunbao         = nBFMapType == BATTLEFIELD_MAP_TYPE.TREASURE_HUNT
    local bTongWar        = nBFMapType == BATTLEFIELD_MAP_TYPE.TONGWAR -- 帮会联赛
    local bArenaTower     = nBFMapType == BATTLEFIELD_MAP_TYPE.ARENA_TOWER

    UIHelper.SetVisible(self.BtnSkill, not bNewPlayerBF and not bNormalBF and not bFeiHuoLunFeng and not bZombie and not bTreasureBattle and not bTongWar and not bArenaTower)
    UIHelper.PlaySFX(self.Eff_JiNengPeiZhi, 1)
    UIHelper.SetVisible(self.BtnSystemMenu, bNewPlayerBF or bNormalBF or bTreasureBattle or bInBaHuangMap or bTongWar or bFeiHuoLunFeng or bZombie or bXunbao or bSkillTreasure or bArenaTower)
    UIHelper.SetVisible(self.BtnQuickOperation, bNewPlayerBF or bNormalBF or bTreasureBattle or bInBaHuangMap or bTongWar or bFeiHuoLunFeng or bZombie or bXunbao or bSkillTreasure or bArenaTower)
    UIHelper.SetVisible(self.BtnBattleBag, bTreasureBattle or bZombie or bXunbao or bSkillTreasure)
    UIHelper.SetVisible(self.BtnBattleInfo, not bZombie and not bArenaTower)
    UIHelper.SetVisible(self.BtnBattleIEsc, bInBaHuangMap or bZombie)
    UIHelper.SetVisible(self.BtnTongWarCommandPanel, bTongWar)
    UIHelper.SetVisible(self.BtnSkillMessage, bArenaTower)
    UIHelper.SetVisible(self.BtnOverview, bArenaTower)

    UIHelper.SetVisible(self.WidgetInfoList, false)
    UIHelper.SetVisible(self.LayoutBtnBubbleList, false)
    UIHelper.SetVisible(self.WidgetOtherInfo, false)
    UIHelper.SetVisible(self.WidgetOtherInfo2, false)
    UIHelper.SetVisible(self.WidgetTime, bNewPlayerBF or bNormalBF or bMoba or bTongWar or bFeiHuoLunFeng or bXunbao)
    UIHelper.SetVisible(self.WidgetScore, not bTreasureBattle and not bInBaHuangMap and not bMoba and not bTongWar and not bFeiHuoLunFeng and not bZombie and not bXunbao and not bSkillTreasure and not bArenaTower)
    UIHelper.SetVisible(self.WidgetScore2, dwMapID == BATTLE_FIELD_MAP_ID.XUE_YU_GUAN_CHENG)
    UIHelper.SetVisible(self.WidgetBattleFieldPubg, bTreasureBattle or bXunbao or bSkillTreasure)
    UIHelper.SetVisible(self.WdigetYangDaoLevelHint, bArenaTower)

    --UIHelper.SetVisible(self.WidgetPvpInfo, not bZombie)

    UIHelper.SetVisible(self.WidgetScoreMoba, bMoba)
    UIHelper.SetVisible(self.WidgetMobaKill, bMoba)
    if bMoba then
        UIHelper.SetString(self.LabelMobaKill, string.format("%d/%d/%d", 0, 0, 0))
        RemoteCallToServer("On_Moba_GetKillData")
    end

    UIHelper.SetVisible(self.WidgetFactionChampionship, bTongWar)
    UIHelper.SetVisible(self.WidgetFactionCommandPanel, bTongWar)

    UIHelper.SetVisible(self.LayoutPvpMap, not bNewPlayerBF and not bTreasureBattle and not bXunbao and not bSkillTreasure and not bArenaTower)
    UIHelper.SetVisible(self.WidgetMainCityInfo, not bTreasureBattle and not bSkillTreasure)
    if bXunbao then
        UIHelper.SetVisible(self.LayoutBtnBubbleList, true)
        UIHelper.SetVisible(self.LayoutMainCityInfo, false)
        local scriptBubble = UIHelper.GetBindScript(self.LayoutBtnBubbleList) --UIWidgetBubbleBar
        scriptBubble:OnEnter(self)
    end
    if bArenaTower then
        ArenaTowerData.bArenaTowerViewFold = true
        self:UpdateArenaTowerLevelInfo()
        self:UpdateArenaTowerBtnState()
        self:UpdateArenaTowerEnemyHead()
        self:UpdateArenaTowerTitleInfo()
    end

    UIHelper.SetVisible(self.WidgetMapPvp, Platform.IsMobile())
    UIHelper.SetVisible(self.WidgetMapPvp2, not Platform.IsMobile())
    UIHelper.SetVisible(self.WidgetBattleFieldPubgMap, bTreasureBattle or bXunbao or bSkillTreasure)

    local player           = GetClientPlayer()
    local nBattleFieldSide = player and player.nBattleFieldSide

    --拭剑园战场特殊处理
    if nBattleFieldSide == -1 and bNewPlayerBF then
        nBattleFieldSide = 0
    end

    if nBattleFieldSide and nBattleFieldSide >= 0 then
        if bArenaTower then
            UIHelper.SetSpriteFrame(self.ImgScoreBlue, tbIconPath.ArenaBlue[nBattleFieldSide])
            UIHelper.SetSpriteFrame(self.ImgScoreRed, tbIconPath.ArenaRed[nBattleFieldSide])
        else
            UIHelper.SetSpriteFrame(self.ImgScoreBlue, tbIconPath.Blue[nBattleFieldSide])
            UIHelper.SetSpriteFrame(self.ImgScoreRed, tbIconPath.Red[nBattleFieldSide])
            UIHelper.SetSpriteFrame(self.ImgScoreBlue2, tbIconPath.Blue[nBattleFieldSide])
            UIHelper.SetSpriteFrame(self.ImgScoreRed2, tbIconPath.Red[nBattleFieldSide])
        end
    else
        UIHelper.SetSpriteFrame(self.ImgScoreBlue, tbIconPath.SwordBlue)
        UIHelper.SetSpriteFrame(self.ImgScoreRed, tbIconPath.SwordRed)
        UIHelper.SetSpriteFrame(self.ImgScoreBlue2, tbIconPath.SwordBlue)
        UIHelper.SetSpriteFrame(self.ImgScoreRed2, tbIconPath.SwordRed)
    end

    --设置不同玩法下图标
    if nBFMapType == BATTLEFIELD_MAP_TYPE.BATTLEFIELD then
        --左边其他信息 图标
        if dwMapID == BATTLE_FIELD_MAP_ID.YUN_HU_TIAN_DI then --云湖
            -- UIHelper.SetVisible(self.WidgetOtherInfo, true)
            UIHelper.SetSpriteFrame(self.ImgOtherInfoIcon, tbIconPath.YunHu)
        elseif dwMapID == BATTLE_FIELD_MAP_ID.JIU_GONG_QI_GU then --九宫棋谷
            -- UIHelper.SetVisible(self.WidgetOtherInfo, true)
            -- UIHelper.SetVisible(self.WidgetOtherInfo2, true)
            UIHelper.SetSpriteFrame(self.ImgOtherInfoIcon, tbIconPath.JiuGong1)
            UIHelper.SetSpriteFrame(self.ImgOtherInfoIcon2, tbIconPath.JiuGong2)
        end
    end

    UIHelper.SetString(self.LabelScoreBlue, "")
    UIHelper.SetString(self.LabelScoreRed, "")
    UIHelper.SetString(self.LabelScoreBlue2, "")
    UIHelper.SetString(self.LabelScoreRed2, "")
    UIHelper.SetString(self.LabelScoreOtherInfo, "")
    UIHelper.SetString(self.LabelScoreOtherInfo2, "")
    UIHelper.LayoutDoLayout(self.LayoutBlue)
    UIHelper.LayoutDoLayout(self.LayoutRed)
    UIHelper.LayoutDoLayout(self.LayoutBlue2)
    UIHelper.LayoutDoLayout(self.LayoutRed2)
    UIHelper.LayoutDoLayout(self.WidgetScore)
    UIHelper.LayoutDoLayout(self.WidgetScore2)

    UIHelper.LayoutDoLayout(self.LayoutBtnPvp)
    UIHelper.CascadeDoLayoutDoWidget(self.LayoutPvpInfo, true, true)
    UIHelper.WidgetFoceDoAlign(self)

    UIHelper.SetString(self.LabelScoreRedMoba, "0")
    UIHelper.SetString(self.LabelScoreBlueMoba, "0")
    UIHelper.LayoutDoLayout(self.LayoutRedMoba)
    UIHelper.LayoutDoLayout(self.LayoutBlueMoba)
    UIHelper.LayoutDoLayout(self.WidgetScoreMoba)

    self:BattleFieldUpdate()

    UIHelper.LayoutDoLayout(self.LayoutMainCityInfo)
    UIHelper.LayoutDoLayout(self.LayoutAll)
end

function UIWidgetPvpRightTop:BattleFieldUpdate()
    if ArenaTowerData.IsInArenaTowerMap() then
        return
    end

    local tObjective = GetBattleFieldObjective()
    if not tObjective then
        return
    end

    local _, dwPQTemplateID, nBeginTime, nEndTime = GetBattleFieldPQInfo()
    if not dwPQTemplateID or dwPQTemplateID == 0 then
        return
    end

    self:SetCountDown(nEndTime)

    if BattleFieldData.IsInMobaBattleFieldMap() then
        ---参考端游 View.UpdateTotalKills
        local nTotalKillsL, nTotalKillsR = tObjective[3][1], tObjective[4][1]

        LOG.INFO("[BattleField] UIWidgetPvpRightTop:BattleFieldUpdate, Red(%d):Blue(%d)",
                 nTotalKillsL, nTotalKillsR)

        UIHelper.SetString(self.LabelScoreRedMoba, string.format("%d", nTotalKillsL))
        UIHelper.SetString(self.LabelScoreBlueMoba, string.format("%d", nTotalKillsR))

        UIHelper.LayoutDoLayout(self.LayoutRedMoba)
        UIHelper.LayoutDoLayout(self.LayoutBlueMoba)
        UIHelper.LayoutDoLayout(self.WidgetScoreMoba)
    else
        local tObjectiveInfo = g_tTable.NewPQObjective:Search(dwPQTemplateID)
        if not tObjectiveInfo then
            return
        end
        --assert(tObjectiveInfo)

        local dwBlueCurScore, dwBlueMaxScore = tObjective[1][1], tObjective[1][2]
        local dwRedCurScore, dwRedMaxScore   = tObjective[2][1], tObjective[2][2]

        LOG.INFO("[BattleField] UIWidgetPvpRightTop:BattleFieldUpdate, Blue(%d/%d):Red(%d/%d)",
                 dwBlueCurScore, dwBlueMaxScore, dwRedCurScore, dwRedMaxScore)

        UIHelper.SetString(self.LabelScoreBlue, string.format("%d/%d", dwBlueCurScore, dwBlueMaxScore))
        UIHelper.SetString(self.LabelScoreRed, string.format("%d/%d", dwRedCurScore, dwRedMaxScore))

        UIHelper.LayoutDoLayout(self.LayoutBlue)
        UIHelper.LayoutDoLayout(self.LayoutRed)
        UIHelper.LayoutDoLayout(self.WidgetScore)

        -- 雪域关城特殊处理
        local dwMapID = MapHelper.GetMapID()
        if dwMapID == BATTLE_FIELD_MAP_ID.XUE_YU_GUAN_CHENG then
            --背旗时间
            local dwBlueTime = tObjective[4][1]
            local dwRedTime  = tObjective[5][1]

            UIHelper.SetString(self.LabelScoreBlue2, string.format(" %d ", dwBlueTime))
            UIHelper.SetString(self.LabelScoreRed2, string.format(" %d ", dwRedTime))

            UIHelper.LayoutDoLayout(self.LayoutBlue2)
            UIHelper.LayoutDoLayout(self.LayoutRed2)
            UIHelper.LayoutDoLayout(self.WidgetScore2)
        end

        UIHelper.LayoutDoLayout(self.LayoutPvpInfo)

        if dwRedCurScore >= dwRedMaxScore or dwBlueCurScore >= dwBlueMaxScore then
            self.bBattleFieldEnd = true
        else
            self.bBattleFieldEnd = false
        end
    end
end

function UIWidgetPvpRightTop:OnOtherInfoShow(tbInfo)
    local nShowIndex

    if MapHelper.IsInBattleField() then
        local dwMapID = MapHelper.GetMapID()
        if dwMapID == BATTLE_FIELD_MAP_ID.YUN_HU_TIAN_DI then
            if tbInfo.szName == "box_progress" and tbInfo.nID == 21 then
                nShowIndex = 1
            end
        elseif dwMapID == BATTLE_FIELD_MAP_ID.JIU_GONG_QI_GU then
            if tbInfo.szName == "box0_progress" and tbInfo.nID == 22 then
                nShowIndex = 2
            elseif tbInfo.szName == "box1_progress" and tbInfo.nID == 21 then
                nShowIndex = 1
            end
        end
    end

    if nShowIndex then
        LOG.INFO("[BattleField] OnOtherInfoShow %s: %d/%d", UIHelper.GBKToUTF8(tbInfo.szTitle), tbInfo.nMolecular, tbInfo.nDenominator)
        --local szText = string.format("%d/%d", tbInfo.nMolecular, tbInfo.nDenominator)
        local szText = tbInfo.nMolecular .. "秒"
        if nShowIndex == 1 then
            UIHelper.SetVisible(self.WidgetOtherInfo, true)
            UIHelper.SetString(self.LabelScoreOtherInfo, szText)
        elseif nShowIndex == 2 then
            UIHelper.SetVisible(self.WidgetOtherInfo2, true)
            UIHelper.SetString(self.LabelScoreOtherInfo2, szText)
        end
        UIHelper.CascadeDoLayoutDoWidget(self.LayoutPvpInfo, true, true)
    end
end

function UIWidgetPvpRightTop:OnOtherInfoHide(szName)
    if MapHelper.IsInBattleField() then
        local dwMapID = MapHelper.GetMapID()
        if dwMapID == BATTLE_FIELD_MAP_ID.YUN_HU_TIAN_DI then
            if szName == "box_progress" then
                UIHelper.SetVisible(self.WidgetOtherInfo, false)
            end
        elseif dwMapID == BATTLE_FIELD_MAP_ID.JIU_GONG_QI_GU then
            if szName == "box0_progress" then
                UIHelper.SetVisible(self.WidgetOtherInfo2, false)
            elseif szName == "box1_progress" then
                UIHelper.SetVisible(self.WidgetOtherInfo, false)
            end
        end
        UIHelper.CascadeDoLayoutDoWidget(self.LayoutPvpInfo, true, true)
    end
end

---------------------------------------------------------------------------------
-------------------------------竞技场相关-----------------------------------------
---------------------------------------------------------------------------------

function UIWidgetPvpRightTop:UpdateArenaEnemyHead()
    local tbData = ArenaData.GetBattlePlayerData(true)
    UIHelper.SetVisible(self.LayoutPvpMap, false)
    UIHelper.SetVisible(self.WidgetMainCityInfo, true)
    UIHelper.SetVisible(self.LayoutBtnBubbleList, false)
    UIHelper.SetVisible(self.WidgetInfoList, false)
    UIHelper.SetVisible(self.WidgetEnemyPlayer, #tbData > 0)
    UIHelper.HideAllChildren(self.LayoutEnemyPlayer)

    self.tbScriptEnemyPlayerHead = self.tbScriptEnemyPlayerHead or {}
    for i, tbInfo in ipairs(tbData) do
        if not self.tbScriptEnemyPlayerHead[i] then
            self.tbScriptEnemyPlayerHead[i] = UIHelper.AddPrefab(PREFAB_ID.WidgetEnemyPlayerCell, self.LayoutEnemyPlayer)
        end
        UIHelper.SetVisible(self.tbScriptEnemyPlayerHead[i]._rootNode, true)
        self.tbScriptEnemyPlayerHead[i]:OnEnter(tbInfo)
    end

    local player           = GetClientPlayer()
    local nBattleFieldSide = player and player.nBattleFieldSide
    if nBattleFieldSide then
        UIHelper.SetSpriteFrame(self.ImgScoreBlue, tbIconPath.ArenaBlue[nBattleFieldSide])
        UIHelper.SetSpriteFrame(self.ImgScoreRed, tbIconPath.ArenaRed[nBattleFieldSide])
    else
        UIHelper.SetSpriteFrame(self.ImgScoreBlue, tbIconPath.SwordBlue)
        UIHelper.SetSpriteFrame(self.ImgScoreRed, tbIconPath.SwordRed)
    end

    UIHelper.LayoutDoLayout(self.LayoutEnemyPlayer)
    UIHelper.LayoutDoLayout(self.LayoutAll)
end

function UIWidgetPvpRightTop:UpdateArenaTitleInfo(tbData, nBattleStartTime)
    if not ArenaData.IsInArena() then
        return
    end

    UIHelper.SetVisible(self.WidgetOtherInfo, false)
    UIHelper.SetVisible(self.WidgetOtherInfo2, false)

    UIHelper.SetString(self.LabelScoreBlue, tbData[1] or 0)
    UIHelper.SetString(self.LabelScoreRed, tbData[0] or 0)

    if UIHelper.GetWidth(self.LabelScoreBlue) < 40 then
        UIHelper.SetWidth(self.LabelScoreBlue, 40)
        UIHelper.SetLabelDimensions(self.LabelScoreBlue, 40, 24)
        UIHelper.SetOverflow(self.LabelScoreBlue, LabelOverflow.CLAMP)
        UIHelper.SetHorizontalAlignment(self.LabelScoreBlue, TextHAlignment.LEFT)
    end

    if UIHelper.GetWidth(self.LabelScoreRed) < 40 then
        UIHelper.SetWidth(self.LabelScoreRed, 40)
        UIHelper.SetLabelDimensions(self.LabelScoreRed, 40, 24)
        UIHelper.SetOverflow(self.LabelScoreRed, LabelOverflow.CLAMP)
        UIHelper.SetHorizontalAlignment(self.LabelScoreRed, TextHAlignment.RIGHT)
    end

    UIHelper.LayoutDoLayout(self.LayoutBlue)
    UIHelper.LayoutDoLayout(self.LayoutRed)
    UIHelper.LayoutDoLayout(self.WidgetScore)

    UIHelper.SetVisible(self.BtnSystemMenu, true)
    UIHelper.SetVisible(self.BtnQuickOperation, true)
    UIHelper.SetVisible(self.WidgetTime, true)
    UIHelper.SetVisible(self.BtnBattleIEsc, true)
    UIHelper.SetVisible(self.BtnBattleInfo, false)
    UIHelper.SetVisible(self.BtnSkillMessage, true)
    UIHelper.SetVisible(self.BtnOverview, false)
    UIHelper.SetVisible(self.WdigetYangDaoLevelHint, false)

    local nArenaType = ArenaData.GetBattleArenaType()
    if not nArenaType then
        self:Clear()
        UIHelper.SetString(self.LabelTime, "准备中")
        UIHelper.LayoutDoLayout(self.LayoutPvpInfo)
    elseif nBattleStartTime > 0 then
        local nEndTime = nBattleStartTime + ArenaData.MATCH_TIME2
        if nArenaType and nArenaType ~= ARENA_UI_TYPE.ARENA_2V2 then
            nEndTime = nBattleStartTime + ArenaData.MATCH_TIME
        end

        self:Clear()
        self.m_nLeftTimer = nEndTime - GetCurrentTime()
        self:UpdateTimeView()

        --倒计时
        Timer.AddCountDown(self, self.m_nLeftTimer, function()
            self.m_nLeftTimer = self.m_nLeftTimer - 1
            self:UpdateTimeView()
        end)
    else
        local nEndTime = ArenaData.MATCH_TIME2
        if nArenaType and nArenaType ~= ARENA_UI_TYPE.ARENA_2V2 then
            nEndTime = nBattleStartTime + ArenaData.MATCH_TIME
        end

        self:Clear()
        self.m_nLeftTimer = nEndTime
        self:UpdateTimeView()
    end
end

---------------------------------------------------------------------------------
-------------------------------阵营大攻防相关-------------------------------------
---------------------------------------------------------------------------------

function UIWidgetPvpRightTop:UpdateCampWarInfo()
    self:Clear()
    self:SetVisible(true)

    local bIsInPvpMap = MapHelper.IsRemotePvpMap()

    --按钮
    UIHelper.SetVisible(self.BtnSkill, true)
    UIHelper.SetVisible(self.BtnOverview, false)
    UIHelper.PlaySFX(self.Eff_JiNengPeiZhi, 1)
    UIHelper.SetVisible(self.BtnSystemMenu, true)
    UIHelper.SetVisible(self.BtnQuickOperation, true)
    UIHelper.SetVisible(self.BtnBattleBag, true)
    UIHelper.SetVisible(self.BtnBattleInfo, false)
    UIHelper.SetVisible(self.BtnBattleIEsc, bIsInPvpMap)

    UIHelper.SetVisible(self.LayoutBtnBubbleList, true)
    local scriptBubble = UIHelper.GetBindScript(self.LayoutBtnBubbleList) --UIWidgetBubbleBar
    scriptBubble:OnEnter(self)

    --信息
    UIHelper.SetVisible(self.WidgetPvpInfo, true)
    UIHelper.SetVisible(self.WidgetScore, false)
    UIHelper.SetVisible(self.WidgetScore2, false)
    UIHelper.SetVisible(self.WidgetOtherInfo, false)
    UIHelper.SetVisible(self.WidgetOtherInfo2, false)
    UIHelper.SetVisible(self.WidgetEnemyPlayer, false)
    UIHelper.SetVisible(self.WidgetBattleFieldPubg, false)
    UIHelper.SetVisible(self.WdigetYangDaoLevelHint, false)
    UIHelper.SetVisible(self.WidgetMobaKill, false)
    UIHelper.SetVisible(self.WidgetInfoList, false)

    if CampData.nEndTime and not bIsInPvpMap then
        UIHelper.SetVisible(self.WidgetTime, true)
        self:SetCountDown(CampData.nEndTime)
    else
        UIHelper.SetVisible(self.WidgetTime, false)
    end

    --地图
    UIHelper.SetVisible(self.LayoutPvpMap, true)
    UIHelper.SetVisible(self.WidgetMainCityInfo, true)
    UIHelper.SetVisible(self.WidgetMapPvp, Platform.IsMobile())
    UIHelper.SetVisible(self.WidgetMapPvp2, not Platform.IsMobile())
    UIHelper.SetVisible(self.WidgetBattleFieldPubgMap, false)

    UIHelper.LayoutDoLayout(self.LayoutBtnPvp)
    UIHelper.CascadeDoLayoutDoWidget(self.LayoutPvpInfo, true, true)
    UIHelper.WidgetFoceDoAlign(self)

    UIHelper.LayoutDoLayout(self.LayoutAll)
end


---------------------------------------------------------------------------------
-------------------------------镜花梦影相关-------------------------------------
---------------------------------------------------------------------------------

function UIWidgetPvpRightTop:UpdateJingHuaInfo()
    UIHelper.SetVisible(self.BtnBattleInfo, false)
    UIHelper.SetVisible(self.BtnSkill, false)
    UIHelper.SetVisible(self.BtnOverview, false)
    UIHelper.SetVisible(self.WidgetScore, false)
    UIHelper.SetVisible(self.WidgetScore2, false)
    UIHelper.SetVisible(self.WidgetTime, false)
    UIHelper.SetVisible(self.WidgetOtherInfo, false)
    UIHelper.SetVisible(self.LayoutPvpMap, false)
    UIHelper.SetVisible(self.WidgetMainCityInfo, false)
    UIHelper.SetVisible(self.WdigetYangDaoLevelHint, false)

    UIHelper.SetVisible(self.WidgetBattleFieldPubgMap, true)
    UIHelper.SetVisible(self.WidgetInfoList, true)

    UIHelper.LayoutDoLayout(self.LayoutPvpInfo)
    UIHelper.LayoutDoLayout(self.LayoutAll)

    local script = UIHelper.GetBindScript(self.WidgetBattleFieldPubgMap)
    script:SetLabelNorthVis(false)

    self.szCheckPoint = "0"
    self.szProscenium = "0"
end

function UIWidgetPvpRightTop:UpdateJingHuaProgress(tbInfo)

    if self.nPlayType ~= PlayType.JingHua then return end

    local szName = UIHelper.GBKToUTF8(tbInfo.szTitle)
    if szName == "关卡" then
        self.szCheckPoint = tostring(tbInfo.nMolecular)
    elseif string.find(szName, "舞台") then
        self.szProscenium = tostring(tbInfo.nMolecular)
        szName = "关卡"
    end

    local nIndex = NAME_TO_UI_INDEX[szName]
    local widgetInfo = self.tbWidgetInfoList[nIndex]
    local labelInfo = self.tbLabelInfoList[nIndex]
    local szContent = ""
    if nIndex == 2 then--关卡
        szContent = szName .. "：" .. self.szCheckPoint .. "-" .. self.szProscenium
    else
        szContent = szName .. "：" .. tostring(tbInfo.nMolecular)
    end

    UIHelper.SetString(labelInfo, szContent)

    UIHelper.LayoutDoLayout(widgetInfo)
    UIHelper.LayoutDoLayout(self.LayoutInfoList)
    UIHelper.LayoutDoLayout(self.LayoutPvpInfo)
    UIHelper.LayoutDoLayout(self.LayoutAll)
end

---------------------------------------------------------------------------------
-------------------------------扬刀大会相关-------------------------------------
---------------------------------------------------------------------------------

function UIWidgetPvpRightTop:UpdateArenaTowerLevelInfo()
    if not ArenaTowerData.PlayerHaveRemoteData() then
        UIHelper.SetVisible(self.LabelLevelNum, false)
        return
    end

    local nDiffMode, nLevelProgress, _, _ = ArenaTowerData.GetBaseInfo()
    local nNextLevel = nLevelProgress + 1
    local szNextLevel
    if nDiffMode == ArenaTowerDiffMode.Practice then
        szNextLevel = string.format(g_tStrings.ARENA_TOWER_NEXT_LEVEL_PRACTICE, tostring(nNextLevel))
    elseif nDiffMode == ArenaTowerDiffMode.Challenge then
        szNextLevel = string.format(g_tStrings.ARENA_TOWER_NEXT_LEVEL_CHALLENGE, tostring(nNextLevel))
    else
        szNextLevel = string.format("<color=#D7F6FF> - 第 %s 关</c>", tostring(nNextLevel))
    end

    UIHelper.SetVisible(self.LabelLevelNum, nNextLevel <= ArenaTowerData.MAX_LEVEL_COUNT)
    UIHelper.SetRichText(self.LabelLevelNum, szNextLevel)
end

function UIWidgetPvpRightTop:UpdateArenaTowerBtnState()
    self.bChooseBless = false
    if not ArenaTowerData.PlayerHaveRemoteData() or not ArenaTowerData.CanGetBattleFieldInfo() then
        UIMgr.Close(VIEW_ID.PanelPostBattleOperation)
        UIHelper.SetVisible(self.WidgetYangDaoFoldedBtn, false)
        UIHelper.LayoutDoLayout(self.LayoutAll)
        return
    end

    local nPageCount = UIMgr.GetLayerStackLength(UILayer.Page, {VIEW_ID.PanelPostBattleOperation, VIEW_ID.PanelTeach_UIPageLayer})
    if nPageCount > 0 then -- 与其它Page界面互斥
        UIMgr.Close(VIEW_ID.PanelPostBattleOperation)
        UIHelper.SetVisible(self.WidgetYangDaoFoldedBtn, false)
    else
        local _, nLevelProgress, _, _ = ArenaTowerData.GetBaseInfo()
        local nBattleState, bReady = ArenaTowerData.GetBattleStateInfo()
        local bCanChooseBless = ArenaTowerData.CanChooseBless()
        local bRest = nBattleState == ArenaTowerBattleState.Rest
        local bMatching = nBattleState == ArenaTowerBattleState.Matching
        if ArenaTowerData.bArenaTowerViewFold then
            UIMgr.Close(VIEW_ID.PanelPostBattleOperation)
            local szLabelBefore = UIHelper.GetString(self.LabelNextStep)
            local bVisibleBefore = UIHelper.GetVisible(self.WidgetYangDaoFoldedBtn)
            local bVisible = bRest or bMatching
            UIHelper.SetVisible(self.WidgetYangDaoFoldedBtn, bVisible)
            local szNextStep
            if bMatching then
                szNextStep = "匹配中"
            elseif bReady then
                szNextStep = "等待中"
            elseif bCanChooseBless then
                szNextStep = "选择卦象"
                self.bChooseBless = true
            elseif nLevelProgress <= 0 then
                szNextStep = "开始挑战"
            else
                szNextStep = "下一步"
            end
            UIHelper.SetString(self.LabelNextStep, szNextStep)
            if szNextStep ~= szLabelBefore or bVisible ~= bVisibleBefore then
                UIHelper.PlayAni(self, self.AniBtn, "AniFoldedBtnShow") -- 按钮状态刷新才播放闪光动画
            end
        else
            if bRest or bMatching then
                UIMgr.OpenSingle(false, VIEW_ID.PanelPostBattleOperation)
            end
            UIHelper.SetVisible(self.WidgetYangDaoFoldedBtn, false)
        end
    end
    UIHelper.LayoutDoLayout(self.LayoutAll)
end

function UIWidgetPvpRightTop:UpdateArenaTowerEnemyHead()
    if not ArenaTowerData.IsInArenaTowerMap() then
        return
    end

    local tbData = ArenaTowerData.GetBattlePlayerData(true)
    UIHelper.SetVisible(self.WidgetEnemyPlayer, #tbData > 0)
    UIHelper.HideAllChildren(self.LayoutEnemyPlayer)

    self.tbScriptEnemyPlayerHead = self.tbScriptEnemyPlayerHead or {}
    for i, tbInfo in ipairs(tbData) do
        if not self.tbScriptEnemyPlayerHead[i] then
            self.tbScriptEnemyPlayerHead[i] = UIHelper.AddPrefab(PREFAB_ID.WidgetEnemyPlayerCell, self.LayoutEnemyPlayer)
        end
        UIHelper.SetVisible(self.tbScriptEnemyPlayerHead[i]._rootNode, true)
        self.tbScriptEnemyPlayerHead[i]:OnEnter(tbInfo)
    end

    UIHelper.LayoutDoLayout(self.LayoutEnemyPlayer)
    UIHelper.LayoutDoLayout(self.LayoutAll)
end

function UIWidgetPvpRightTop:UpdateArenaTowerTitleInfo()
    if not ArenaTowerData.IsInArenaTowerMap() then
        return
    end

    local tData, nBattleStartTime, _ = ArenaTowerData.GetTitleInfo()
    local nBattleState, _ = ArenaTowerData.GetBattleStateInfo()
    local bVisible = nBattleState == ArenaTowerBattleState.Prepare or nBattleState == ArenaTowerBattleState.Battle
    if not bVisible then
        UIHelper.SetVisible(self.WidgetScore, false)
        UIHelper.SetVisible(self.WidgetTime, false)
        UIHelper.LayoutDoLayout(self.LayoutPvpInfo)
        return
    end

    UIHelper.SetVisible(self.WidgetScore, true)
    UIHelper.SetVisible(self.WidgetTime, true)
    
    UIHelper.SetString(self.LabelScoreBlue, tData and tData[1] or 0)
    UIHelper.SetString(self.LabelScoreRed, tData and tData[0] or 0)

    if UIHelper.GetWidth(self.LabelScoreBlue) < 40 then
        UIHelper.SetWidth(self.LabelScoreBlue, 40)
        UIHelper.SetLabelDimensions(self.LabelScoreBlue, 40, 24)
        UIHelper.SetOverflow(self.LabelScoreBlue, LabelOverflow.CLAMP)
        UIHelper.SetHorizontalAlignment(self.LabelScoreBlue, TextHAlignment.LEFT)
    end

    if UIHelper.GetWidth(self.LabelScoreRed) < 40 then
        UIHelper.SetWidth(self.LabelScoreRed, 40)
        UIHelper.SetLabelDimensions(self.LabelScoreRed, 40, 24)
        UIHelper.SetOverflow(self.LabelScoreRed, LabelOverflow.CLAMP)
        UIHelper.SetHorizontalAlignment(self.LabelScoreRed, TextHAlignment.RIGHT)
    end

    UIHelper.LayoutDoLayout(self.LayoutBlue)
    UIHelper.LayoutDoLayout(self.LayoutRed)
    UIHelper.LayoutDoLayout(self.WidgetScore)

    self:Clear()
    if nBattleState == ArenaTowerBattleState.Battle and nBattleStartTime and nBattleStartTime > 0 then
        local nEndTime = nBattleStartTime + ArenaData.MATCH_TIME
        self.m_nLeftTimer = nEndTime - GetCurrentTime()
        self:UpdateTimeView()

        --倒计时
        Timer.AddCountDown(self, self.m_nLeftTimer, function()
            self.m_nLeftTimer = self.m_nLeftTimer - 1
            self:UpdateTimeView()
        end)
    else
        self.m_nLeftTimer = ArenaData.MATCH_TIME
        self:UpdateTimeView()
    end

    UIHelper.LayoutDoLayout(self.LayoutPvpInfo)
end

-------------------------------通用-----------------------------------------

function UIWidgetPvpRightTop:UpdateMapSize()
    --根据主界面右下区域的大小动态调整精简中地图的大小，避免区域重叠
    UIHelper.SetScale(self.LayoutPvpMap, 1, 1)
    if not UIHelper.GetVisible(self.WidgetMapPvp2) then
        return
    end

    local nXMin, nXMax, nYMin, nYMax = UIHelper.GetNodeEdgeXY(self.WidgetMapPvp2, true)
    local nWidth, nHeight            = UIHelper.GetScaledContentSize(self.WidgetMapPvp2)

    local scriptMainCity             = UIMgr.GetViewScript(VIEW_ID.PanelMainCity)
    local scriptSkill                = scriptMainCity and scriptMainCity.scriptSkill
    if scriptSkill then
        --local _, _, nOverHeight = scriptSkill:IsOverLapping(nXMin, nYMax, nWidth, nHeight) --左上角
        local _, _, nOverHeight = MainCityCustomData.GetNodeOverLapping(nXMin, nYMax, nWidth, nHeight, scriptSkill.ImgSelectZone) --左上角
        local nScale            = math.max(nHeight / (nHeight + nOverHeight), 0.75) --加个限制，避免意外情况缩太小缩没了
        UIHelper.SetScale(self.LayoutPvpMap, nScale, nScale)
        UIHelper.WidgetFoceDoAlign(self)
    end
end

function UIWidgetPvpRightTop:Clear()
    Timer.DelAllTimer(self)
end

function UIWidgetPvpRightTop:SetCountDown(nEndTime)
    self:Clear()

    if BattleFieldData.IsInMobaBattleFieldMap() then
        -- moba也需要显示时间，但是时间逻辑跟这里不一样
        Timer.AddCycle(self, 0.5, function()
            self:UpdateMobaTime()
        end)
        return
    elseif BattleFieldData.IsInTongWarFieldMap() then
        -- 帮会联赛的时间刷新频率改成与dx一样，每帧刷新一次，特殊处理下
        Timer.AddFrameCycle(self, 1, function()
            self:UpdateTongWarTime()
        end)
        return
    elseif BattleFieldData.IsInXunBaoBattleFieldMap() then
        Timer.AddFrameCycle(self, 1, function()
            self:UpdateXunbaoTime()
        end)
        return
    end

    if not nEndTime then
        return
    end

    self.m_nLeftTimer = nEndTime - GetCurrentTime()
    if self.m_nLeftTimer < 0 then
        self.m_nLeftTimer = 0
    end
    self:UpdateTimeView()

    --倒计时
    if self.m_nLeftTimer > 0 then
        Timer.AddCountDown(self, self.m_nLeftTimer, function()
            self.m_nLeftTimer = self.m_nLeftTimer - 1
            self:UpdateTimeView()
        end)
    end

end

function UIWidgetPvpRightTop:UpdateTimeView()
    local szFormatTime = self:GetFormatTime(self.m_nLeftTimer)
    UIHelper.SetString(self.LabelTime, szFormatTime)
end

function UIWidgetPvpRightTop:UpdateMobaTime()
    local szPassTime = BattleFieldData.GetMobaShowPassTime()

    UIHelper.SetString(self.LabelTime, szPassTime)
    UIHelper.CascadeDoLayoutDoWidget(self.LayoutPvpInfo, true, true)
end

function UIWidgetPvpRightTop:UpdateTongWarTime()
    local TimeLimit      = self:GetTongWarEndTime()
    local nTime = GetGSCurrentTime()


    local nPoor = math.max(0, TimeLimit - nTime)
    local szFormatTime = TimeLib.ACCInfo_Base_GetFormatTime(nPoor, true)

    UIHelper.SetString(self.LabelTime, szFormatTime)
    --- 帮会联赛这里不刷新layout，避免在部分字体（如小米sans）下，因为不同数字的宽度不一样，导致左侧的帮会联赛信息区域不停跳动
    -- UIHelper.CascadeDoLayoutDoWidget(self.LayoutPvpInfo, true, true)
end

function UIWidgetPvpRightTop:GetTongWarEndTime()
    local tInfo = BattleFieldData.GetTongFight2024Info()
    local TimeLimit = tInfo.EndTime

    return TimeLimit
end

function UIWidgetPvpRightTop:UpdateXunbaoTime()
    local nEndTime = PvpExtractData.GetEndTime() or 0
    local nTime = nEndTime - GetCurrentTime()
    if nTime < 0 then
        nTime = 0
    end
    local szLeftTime = self:GetFormatTime(nTime)

    UIHelper.SetString(self.LabelTime, szLeftTime)
    UIHelper.CascadeDoLayoutDoWidget(self.LayoutPvpInfo, true, true)
end

function UIWidgetPvpRightTop:GetFormatTime(nTime)
    local nM         = math.floor(nTime / 60)
    local nS         = math.floor(nTime % 60)
    local szTimeText = ""

    if nM ~= 0 then
        szTimeText = szTimeText .. nM .. ":"
    end

    if nS < 10 and nM ~= 0 then
        szTimeText = szTimeText .. "0"
    end

    szTimeText = szTimeText .. nS

    return szTimeText
end

-- ------------------------ 帮会联赛 begin ------------------------

local BLUE_INDEX = 0
local RED_INDEX  = 1
local MAP_ID     = 689

local function GetCenterNameByID(tCenterList, dwCenterID)
    if (not tCenterList) or IsTableEmpty(tCenterList) then
        return
    end

    for _, v in pairs(tCenterList) do
        if v.dwCenterID == dwCenterID then
            return v.szCenterName
        end
    end
end

function UIWidgetPvpRightTop:UpdateFactionChampionshipInfo()
    --- 获取相关数据
    local tInfo   = BattleFieldData.GetTongFight2024Info()

    local dwMapID = nil
    if g_pClientPlayer and g_pClientPlayer.GetScene() then
        dwMapID = g_pClientPlayer.GetMapID()
    end

    local tBlueInfo        = tInfo[BLUE_INDEX]
    local tRedInfo         = tInfo[RED_INDEX]

    local szBlueCenterName = nil
    local tBlueCenterList  = GetHomelandMgr().GetRelationCenter(tBlueInfo.nCenterID)
    szBlueCenterName       = GetCenterNameByID(tBlueCenterList, tBlueInfo.nCenterID)

    local szRedCenterName  = nil
    local tRedCenterList   = GetHomelandMgr().GetRelationCenter(tRedInfo.nCenterID)
    szRedCenterName        = GetCenterNameByID(tRedCenterList, tRedInfo.nCenterID)

    self:SetCountDown(nil)

    -- 刷新界面
    local fnG2uAndTruncate = function(szGbk, nMaxShowLength)
        return UIHelper.TruncateStringReturnOnlyResult(UIHelper.GBKToUTF8(szGbk), nMaxShowLength)
    end

    UIHelper.SetString(self.LabelBlueFactionName, fnG2uAndTruncate(tBlueInfo.szTongName, 3))
    UIHelper.SetString(self.LabelBlueServerName, UIHelper.GBKToUTF8(szBlueCenterName))

    UIHelper.SetString(self.LabelRedFactionName, fnG2uAndTruncate(tRedInfo.szTongName, 3))
    UIHelper.SetString(self.LabelRedServerName, UIHelper.GBKToUTF8(szRedCenterName))

    local nBluePercent     = tBlueInfo.nFlagBloodPer / 100
    local szBlueBloodCount = string.format("%.2f%%", nBluePercent)

    local nRedPercent      = tRedInfo.nFlagBloodPer / 100
    local szRedBloodCount  = string.format("%.2f%%", nRedPercent)

    UIHelper.SetString(self.FactionLabelBlueFlagPercent, szBlueBloodCount)
    UIHelper.SetProgressBarPercent(self.FactionSliderBlueFlagPercent, nBluePercent)
    UIHelper.SetString(self.FactionLabelMoraleBlue, tBlueInfo.nEncourageLv)

    UIHelper.SetString(self.FactionLabelRedFlagPercent, szRedBloodCount)
    UIHelper.SetProgressBarPercent(self.FactionSliderRedFlagPercent, nRedPercent)
    UIHelper.SetString(self.FactionLabelMoraleRed, tRedInfo.nEncourageLv)

    local fnUpdateDragonTime = function(nSideIndex, widgetDragon, labelTime)
        local nDragonEndTime = tInfo[nSideIndex].nDragonTime
        local nCurrentTime   = GetGSCurrentTime()

        local bHasBuff       = nDragonEndTime > nCurrentTime

        UIHelper.SetVisible(widgetDragon, bHasBuff)
        if bHasBuff then
            local nDeltaTime      = nDragonEndTime - nCurrentTime
            local nSecond         = math.floor(nDeltaTime % 60)
            local nMinute         = math.floor(nDeltaTime / 60)

            local szRemainingTime = FormatString(g_tStrings.STR_TIME_11, nMinute, nSecond)
            UIHelper.SetString(labelTime, szRemainingTime)
        end
    end

    fnUpdateDragonTime(BLUE_INDEX, self.WidgetDragonBlue, self.LabelDragonBlue)
    fnUpdateDragonTime(RED_INDEX, self.WidgetDragonRed, self.LabelDragonRed)

    local fnUpdateGlobalViewTime = function(nSideIndex, widgetGlobalViewTime, labelTime)
        local nFogEndTime    = tInfo[nSideIndex].nFogTime
        local nCurrentTime   = GetGSCurrentTime()

        local bHasGlobalView = nFogEndTime > nCurrentTime

        UIHelper.SetVisible(widgetGlobalViewTime, bHasGlobalView)
        if bHasGlobalView then
            local nDeltaTime      = nFogEndTime - nCurrentTime
            local nSecond         = math.floor(nDeltaTime % 60)
            local nMinute         = math.floor(nDeltaTime / 60)

            local szRemainingTime = FormatString(g_tStrings.STR_TIME_11, nMinute, nSecond)
            UIHelper.SetString(labelTime, szRemainingTime)
        end
    end

    fnUpdateGlobalViewTime(BLUE_INDEX, self.WidgetGlobalViewTimeBlue, self.LabelGlobalViewTimeBlue)
    fnUpdateGlobalViewTime(RED_INDEX, self.WidgetGlobalViewTimeRed, self.LabelGlobalViewTimeRed)

    local fnUpdateSideImg = function(nSideIndex, imgSide, normalImgPath, selfImgPath)
        local nPlayerSide = g_pClientPlayer.nBattleFieldSide

        local szImgPath
        if nSideIndex == nPlayerSide then
            szImgPath = selfImgPath
        else
            szImgPath = normalImgPath
        end

        UIHelper.SetSpriteFrame(imgSide, szImgPath)
    end

    fnUpdateSideImg(BLUE_INDEX, self.ImgFactionBlue, "UIAtlas2_Pvp_PvpMainCity_Icon3.png", "UIAtlas2_Pvp_PvpMainCity_Icon4.png")
    fnUpdateSideImg(RED_INDEX, self.ImgFactionRed, "UIAtlas2_Pvp_PvpMainCity_Icon1.png", "UIAtlas2_Pvp_PvpMainCity_Icon2.png")

    self:UpdateFactionChampionshipDetailInfoList()

    local szLevelName    = BattleFieldData.GetTongFightMapLevel()
    UIHelper.SetString(self.FactionLabeMapLevel, szLevelName)

    UIHelper.CascadeDoLayoutDoWidget(self.WidgetFactionChampionship, true, true)
end

function UIWidgetPvpRightTop:UpdateFactionChampionshipDetailInfoList()
    UIHelper.RemoveAllChildren(self.LayoutChampionshipData)

    local tInfo           = BattleFieldData.GetTongFight2024Info()

    local tBlueInfo       = tInfo[BLUE_INDEX]
    local tRedInfo        = tInfo[RED_INDEX]

    local szBlueResource  = string.format("%d/%d", tBlueInfo.nCurResource, tBlueInfo.nAllResource)
    local szRedResource   = string.format("%d/%d", tRedInfo.nCurResource, tRedInfo.nAllResource)

    local function GetTongRank(nRank)
        if not nRank or nRank == 0 then
            return g_tStrings.STR_GUILD_NOT_IN_RANK
        end
        return nRank
    end
    local tDetailInfoList = {
        { szTitle = "箭塔", szIcon = "UIAtlas2_Faction_ChampionshipNotice_jt.png", szBlue = tBlueInfo.nCurTower, szRed = tRedInfo.nCurTower },
        { szTitle = "资源", szIcon = "UIAtlas2_Faction_ChampionshipNotice_zhzy.png", szBlue = szBlueResource, szRed = szRedResource },
        { szTitle = "击败", szIcon = "UIAtlas2_Faction_ChampionshipNotice_js.png", szBlue = tBlueInfo.nKill, szRed = tRedInfo.nKill },
        { szTitle = "人数", szIcon = "UIAtlas2_Faction_ChampionshipNotice_rs.png", szBlue = tBlueInfo.nCurMan, szRed = tRedInfo.nCurMan },
        { szTitle = "装分", szIcon = "UIAtlas2_Faction_ChampionshipNotice_zf.png", szBlue = tBlueInfo.nEquipAvg, szRed = tRedInfo.nEquipAvg },
        { szTitle = "排名", szIcon = "UIAtlas2_Faction_ChampionshipNotice_pm.png", szBlue = GetTongRank(tBlueInfo.nRank) , szRed = GetTongRank(tRedInfo.nRank) },
    }
    for _, tDetail in ipairs(tDetailInfoList) do
        ---@see UIChampionshipData
        UIHelper.AddPrefab(PREFAB_ID.WidgetChampionshipData, self.LayoutChampionshipData, tDetail.szTitle, tDetail.szIcon, tDetail.szBlue, tDetail.szRed)
    end

    UIHelper.CascadeDoLayoutDoWidget(self.LayoutChampionshipData, true, true)
end

function UIWidgetPvpRightTop:ShowTongWarCommandPanel()
    local widgetAnchor = self.WidgetFactionCommandPanel
    if UIHelper.GetChildrenCount(widgetAnchor) > 0 then
        return
    end

    UIHelper.AddPrefab(PREFAB_ID.WidgetConductorNoticeTips, widgetAnchor)
end

-- ------------------------ 帮会联赛 end ------------------------

function UIWidgetPvpRightTop:ShowExtractEquipSwitchPanel()
    TipsHelper.ShowNodeHoverTips(PREFAB_ID.WidgetXunBaoSwitchTips, self.BtnSkill)
end

return UIWidgetPvpRightTop