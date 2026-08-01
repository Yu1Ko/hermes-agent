-- ---------------------------------------------------------------------------------
-- Author: Unknown
-- Name: UIPanelMahjongMainView
-- Date: 2023-07-27 16:47:19
-- Desc: ?
-- ---------------------------------------------------------------------------------
local nMaxHandCardNum = 14 --最大手牌数
local nCardMaxNum = 4 --相同牌值张数
local nPongModNum = 2  	--碰的麻将摆法
local nAllCardNum = 108  --全部麻将总数
local nDiceNumTime = 2 * 1000 --塞子特效显示时间
local BLACK_GOLD_SKINID = 3


local tbSFXName = {
    [MahjongEffectType.PENG] = "Peng",--碰
    [MahjongEffectType.GANG] = "Gang",--杠
    [MahjongEffectType.GSKH] = "GSKH",--杠上开花
    [MahjongEffectType.HDLY] = "HDLY",--海底捞月
    [MahjongEffectType.ZM] = "ZM",  --自摸
    [MahjongEffectType.HU] = "Hu",  --胡
    [MahjongEffectType.FP] = "Feng",  --放炮
    [MahjongEffectType.YPDX] = "YPDX",--一炮多响
    [MahjongEffectType.PASS] = "Guo",--过牌
}

local tPongCardImgInfo = { --碰牌特殊组合图片方向
	[tUIPosIndex.Down] = {
		[1] = { nPreferb =  PREFAB_ID.WidgetUpDownMod01, tbInfo =  {[4] = {szImgPosName = "Down2", bShow = true}}},
		[2] = { nPreferb =  PREFAB_ID.WidgetUpDownMod02, tbInfo =  {[1] = {szImgPosName = "Down2", bShow = true}, [2] = {szImgPosName = "Down2", bShow = true}, [3] = {szImgPosName = "Down2", bShow = true}, [4] = {szImgPosName = "Down2", bShow = true}}},
		[3] = { nPreferb =  PREFAB_ID.WidgetUpDownMod03, tbInfo =  {[1] = {szImgPosName = "Down2", bShow = true}, [2] = {szImgPosName = "Right", bShow = false}, [3] = {szImgPosName = "Right", bShow = true}, [4] = {szImgPosName = "Down2", bShow = true}}},
		[4] = { nPreferb =  PREFAB_ID.WidgetUpDownMod04, tbInfo =  {[1] = {szImgPosName = "Right", bShow = false}, [2] = {szImgPosName = "Right", bShow = true}, [3] = {szImgPosName = "Down2", bShow = true}, [4] = {szImgPosName = "Down2", bShow = true}}},
	},
	[tUIPosIndex.Left] = {
		[1] = { nPreferb =  PREFAB_ID.WidgetLeftRightMod01, tbInfo =  {[4] = {szImgPosName = "Left", bShow = true}}},
		[2] = { nPreferb =  PREFAB_ID.WidgetLeftRightMod02, tbInfo =  {[1] = {szImgPosName = "Left", bShow = true}, [2] = {szImgPosName = "Left", bShow = true}, [3] = {szImgPosName = "Left", bShow = true}, [4] = {szImgPosName = "Left", bShow = true}}},
		[3] = { nPreferb =  PREFAB_ID.WidgetLeftRightMod03, tbInfo =  {[1] = {szImgPosName = "Left", bShow = true}, [2] = {szImgPosName = "Down2", bShow = false}, [3] = {szImgPosName = "Down2", bShow = true}, [4] = {szImgPosName = "Left", bShow = true}}},
		[4] = { nPreferb =  PREFAB_ID.WidgetLeftRightMod04, tbInfo =  {[1] = {szImgPosName = "Down2", bShow = false}, [2] = {szImgPosName = "Down2", bShow = true}, [3] = {szImgPosName = "Left", bShow = true}, [4] = {szImgPosName = "Left", bShow = true}}},
	},
	[tUIPosIndex.Up] = {
		[1] = { nPreferb =  PREFAB_ID.WidgetUpDownMod01, tbInfo =  {[1] = {szImgPosName = "Up", bShow = true}}},
		[2] = { nPreferb =  PREFAB_ID.WidgetUpDownMod02, tbInfo =  {[1] = {szImgPosName = "Up", bShow = true}, [2] = {szImgPosName = "Up", bShow = true}, [3] = {szImgPosName = "Up", bShow = true}, [4] = {szImgPosName = "Up", bShow = true}}},
		[3] = { nPreferb =  PREFAB_ID.WidgetUpDownMod03, tbInfo =  {[1] = {szImgPosName = "Up", bShow = true}, [2] = {szImgPosName = "Right", bShow = true}, [3] = {szImgPosName = "Right", bShow = false}, [4] = {szImgPosName = "Up", bShow = true}}},
		[4] = { nPreferb =  PREFAB_ID.WidgetUpDownMod04, tbInfo =  {[1] = {szImgPosName = "Up", bShow = true}, [2] = {szImgPosName = "Up", bShow = true}, [3] = {szImgPosName = "Right", bShow = true}, [4] = {szImgPosName = "Right", bShow = false}}},
	},
	[tUIPosIndex.Right] = {
		[1] = { nPreferb =  PREFAB_ID.WidgetLeftRightMod01, tbInfo =  {[4] = {szImgPosName = "Right", bShow = true}}},
		[2] = { nPreferb =  PREFAB_ID.WidgetLeftRightMod02, tbInfo =  {[1] = {szImgPosName = "Right", bShow = true}, [2] = {szImgPosName = "Right", bShow = true}, [3] = {szImgPosName = "Right", bShow = true}, [4] = {szImgPosName = "Right", bShow = true}}},
		[3] = { nPreferb =  PREFAB_ID.WidgetLeftRightMod03, tbInfo =  {[1] = {szImgPosName = "Right", bShow = true}, [2] = {szImgPosName = "Down2", bShow = true}, [3] = {szImgPosName = "Down2", bShow = false}, [4] = {szImgPosName = "Right", bShow = true}}},
		[4] = { nPreferb =  PREFAB_ID.WidgetLeftRightMod04, tbInfo =  {[1] = {szImgPosName = "Down2", bShow = false}, [2] = {szImgPosName = "Down2", bShow = true}, [3] = {szImgPosName = "Right", bShow = true}, [4] = {szImgPosName = "Right", bShow = true}}},
	},
}

local tbHandCardPrefab = {
    [tUIPosIndex.Down] = PREFAB_ID.WidgetSettlementHead,
    [tUIPosIndex.Up] = PREFAB_ID.WidgetMahjongUpMod,
    [tUIPosIndex.Left] = PREFAB_ID.WidgetMahjongLeftMod,
    [tUIPosIndex.Right] = PREFAB_ID.WidgetMahjongRightMod,
}

local tbWallCardPrefab = {
    [tUIPosIndex.Down] = PREFAB_ID.WidgetUnknownImgUp,
    [tUIPosIndex.Up] = PREFAB_ID.WidgetUnknownImgUp,
    [tUIPosIndex.Left] = PREFAB_ID.WidgetUnknownImgLeft,
    [tUIPosIndex.Right] = PREFAB_ID.WidgetUnknownImgLeft,
}


local tbDirectionWordImg = {
    [tDirectionType.East] = "UIAtlas2_Mahjong_MahjongMiddle_east1.png",
    [tDirectionType.West] = "UIAtlas2_Mahjong_MahjongMiddle_west1.png",
    [tDirectionType.North] = "UIAtlas2_Mahjong_MahjongMiddle_north1.png",
    [tDirectionType.South] = "UIAtlas2_Mahjong_MahjongMiddle_south1.png",
}

local tDirection2CardStackNnm = {
    [tDirectionType.East] = 13,
    [tDirectionType.South] = 14,
    [tDirectionType.West] = 13,
    [tDirectionType.North] = 14,
}

--骰子点数图片
local tDiceNumImgPath = {
	szIconPath = "ui\\Image\\UICommon\\Mahjong07.UITex",
	tIconFrame = {[1] = 22, [2] = 23, [3] = 24, [4] = 25, [5] = 26, [6] = 27,},
}

local UIPanelMahjongMainView = class("UIPanelMahjongMainView")

function UIPanelMahjongMainView:OnEnter()
    if not self.bInit then
        self:Init()
        self:RegEvent()
        self:BindUIEvent()
        self.bInit = true
    end
    SoundMgr.PlayUIBgMusic(UIHelper.UTF8ToGBK("data\\sound\\专有\\小游戏\\麻将音效\\家园麻将主题曲.mp3"))
    self:UpdateInfo()
end

function UIPanelMahjongMainView:OnExit()
    self.bInit = false
    self:UnRegEvent()
    SoundMgr.StopUIBgMusic(UIHelper.UTF8ToGBK("data\\sound\\专有\\小游戏\\麻将音效\\家园麻将主题曲.mp3"))
    SoundMgr.PlayBackBgMusic()
end

function UIPanelMahjongMainView:BindUIEvent()
    UIHelper.BindUIEvent(self.BtnReady, EventType.OnClick, function()
        MahjongData.SendReadyStartGame(tPlayerState.nReady)
    end)

    UIHelper.BindUIEvent({self.BtnExit, self.BtnClose01}, EventType.OnClick, function()
        UIHelper.ShowConfirm("是否退出麻将游戏", function()
            MahjongData.OnExit()
        end)
    end)

    UIHelper.BindUIEvent(self.BtnCancel, EventType.OnClick, function()
        MahjongData.SendReadyStartGame(tPlayerState.nNotReady)
    end)

    UIHelper.BindUIEvent(self.ToggleSlips, EventType.OnSelectChanged, function(toggle, bSelect)
        -- if bSelect then
            self:ShowDingQueBtn(false)
            MahjongData.SendServerOperate(MINI_GAME_OPERATE_TYPE.SERVER_OPERATE, PLAYER_OPERATE_SET_LACK, tMahjongType.Bamboo)
        -- end
    end)

    UIHelper.BindUIEvent(self.ToggleTube, EventType.OnSelectChanged, function(toggle, bSelect)
        -- if bSelect then
            self:ShowDingQueBtn(false)
            MahjongData.SendServerOperate(MINI_GAME_OPERATE_TYPE.SERVER_OPERATE, PLAYER_OPERATE_SET_LACK, tMahjongType.Dot)
        -- end
    end)

    UIHelper.BindUIEvent(self.ToggleWan, EventType.OnSelectChanged, function(toggle, bSelect)
        -- if bSelect then
            self:ShowDingQueBtn(false)
            MahjongData.SendServerOperate(MINI_GAME_OPERATE_TYPE.SERVER_OPERATE, PLAYER_OPERATE_SET_LACK, tMahjongType.Character)
        -- end
    end)

    UIHelper.BindUIEvent(self.BtnPass, EventType.OnClick, function()
        self:UpdateOperate()
        self:UpdateHuTips()
        MahjongData.SendServerOperate(MINI_GAME_OPERATE_TYPE.SERVER_OPERATE, PLAYER_OPERATE_JUMP)
    end)

    UIHelper.BindUIEvent(self.BtnPeng, EventType.OnClick, function()
        local nValue = MahjongData.GetCurrOperateCard(false)
	    if nValue then
		    MahjongData.SendServerOperate(MINI_GAME_OPERATE_TYPE.SERVER_OPERATE, PLAYER_OPERATE_PENG, nValue)
	    end
        self:UpdateOperate()
        self:UpdateHuTips()
    end)

    UIHelper.BindUIEvent(self.BtnGang, EventType.OnClick, function()
        local tbDatas = MahjongData.GetCanKongCard(MahjongData.GetPlayerDataDirection()) --可杠的牌
        local nLength = #tbDatas
        if nLength < 1 then

        elseif nLength > 1 then
            -- ShowSelectKongCard()
        elseif nLength ==1 then
            local tbData = tbDatas[1]
            MahjongData.SendServerOperate(MINI_GAME_OPERATE_TYPE.SERVER_OPERATE, tbData[1], tbData[2])
            self:UpdateOperate()
            self:UpdateHuTips()
        end
    end)

    UIHelper.BindUIEvent(self.BtnHu, EventType.OnClick, function()
        local nValue = MahjongData.GetCurrOperateCard(false)
        MahjongData.SendServerOperate(MINI_GAME_OPERATE_TYPE.SERVER_OPERATE, PLAYER_OPERATE_HU, nValue)
        self:UpdateOperate()
        self:UpdateHuTips()
    end)

    UIHelper.BindUIEvent(self.BtnRulePop, EventType.OnClick, function()
        if UIMgr.IsViewOpened(VIEW_ID.PanelMahjongRulePop) then
            UIMgr.Close(VIEW_ID.PanelMahjongRulePop)
        else
            UIMgr.Open(VIEW_ID.PanelMahjongRulePop)
        end
    end)

    UIHelper.BindUIEvent(self.BtnBill, EventType.OnClick, function()
        self:UpdateBill()
    end)

    UIHelper.BindUIEvent(self.ToggleTrusteeship, EventType.OnClick, function()--托管
        -- if not MahjongData.GetGameStart() then UIHelper.SetSelected(self.ToggleTrusteeship, false, false) return end
        local bSelect = UIHelper.GetSelected(self.ToggleTrusteeship)
        MahjongData.SendServerOperate(MINI_GAME_OPERATE_TYPE.NO_CHECK_OPERATE, PLAYER_OPERATE_SET_AGENT, bSelect and 1 or 0)
    end)

    UIHelper.BindUIEvent(self.BtnOption, EventType.OnClick, function()
        local bShow = UIHelper.GetVisible(self.WidgetOption2)
        UIHelper.SetVisible(self.WidgetOption2, not bShow)
    end)

    UIHelper.BindUIEvent(self.TogCheckPTH, EventType.OnSelectChanged, function()
        if bSelect then
            MahjongData.SendServerOperate(MINI_GAME_OPERATE_TYPE.NO_CHECK_OPERATE, PLAYER_OPERATE_SET_ACCENT, 0)--普通话
            UIHelper.SetVisible(self.WidgetOption2, false)
        end
    end)

    UIHelper.BindUIEvent(self.TogCheckCP, EventType.OnSelectChanged, function()
        if bSelect then
            MahjongData.SendServerOperate(MINI_GAME_OPERATE_TYPE.NO_CHECK_OPERATE, PLAYER_OPERATE_SET_ACCENT, 1)--四川话
            UIHelper.SetVisible(self.WidgetOption2, false)
        end
    end)

    UIHelper.BindUIEvent(self.BtnSure, EventType.OnClick, function()
        if MahjongData.ConfirmSwapCard() then
            self:UpdateSwapCardTip(false)
        end
    end)

    UIHelper.BindUIEvent(self.BtnHuTips, EventType.OnClick, function()
        local tbPoints = MahjongData.GetFutureWinPoints()
        self:UpdateHuTips(tbPoints)
    end)

    UIHelper.BindUIEvent(self.BtnChat, EventType.OnClick, function ()
        ChatHelper.Chat()
    end)

    UIHelper.BindUIEvent(self.BtnFindGroup, EventType.OnClick, function()
        UIMgr.Open(VIEW_ID.PanelReleaseRecruitPop, nil, 276)
    end)

    UIHelper.BindUIEvent(self.BtnStageStore, EventType.OnClick, function()
        ShopData.OpenSystemShopGroup(1, 1242)
    end)
end

function UIPanelMahjongMainView:RegEvent()

    Event.Reg(self, EventType.OnUpdatePlayerInfo, function()
        self:UpdatePlayerInfo()
    end)

    Event.Reg(self, EventType.OnGameStart, function()
        local bStart = MahjongData.GetGameStart()
        if bStart then
            self:UpdateDiceEffect(true, function()
                self:UpdateDiceNum()
                self:UpdatePlayerInfo()
                self:InitPlayerCards(true, function()
                    self:UpdateDiceEffect()
                    self:UpdateSwapOutCard()
                    self:UpdateAgent()
                end)
                self:UpdateReadyState()
                self:InitWallCards()
                self:UpdateWordDirection()
                self:ShowCurrentOperatePlayer(GetCurOperatePlayer())
                self:ShowBankerIcon()
                self:UpdateSurplusState()
                self:UpdateSurplusNum()
            end)
        end
    end)

    Event.Reg(self, EventType.OnSwapOutCardResult, function(tbIndex, funcCallBack)
        --换出的牌
        self:UpdateMyCards(MahjongData.GetMyHandCardInfo(), nil, tbIndex, funcCallBack)
        self:UpdatePlayerInfo()
    end)

    Event.Reg(self, EventType.OnChangeCard, function()
        self:UpdateExchangeOrder(true)
        self:UpdateSwapCardTip(false)
        self:UpdatePlayerInfo(true)
    end)

    Event.Reg(self, EventType.OnSwapInCardResult, function()
        self:UpdateExchangeOrder(false)
        local tbCardList = MahjongData.GetMyHandCardInfo()
        local nLength = #tbCardList
        self:UpdateMyCards(tbCardList, {nLength - 2, nLength - 1, nLength})
    end)

    Event.Reg(self, EventType.StartSelectionLackType, function(nCardType)
        self:UpdateMyCards(MahjongData.GetMyHandCardInfo())
        self:UpdatePlayerInfo()
        self:ShowDingQueBtn(true, nCardType)
    end)

    Event.Reg(self, EventType.LackTypeResult, function()
        self:UpdateMyCards(MahjongData.GetMyHandCardInfo())
        self:UpdatePlayerInfo()
        self:ShowDingQueBtn(false)
        self:ShowCurrentOperatePlayer(MahjongData.GetGameData("nBankerDirection"))
    end)

    Event.Reg(self, EventType.GainCard, function(nDataDirection)
        self:ShowCurrentOperatePlayer(nDataDirection)
        self:ReduceWallCard()
        self:UpdateSurplusNum()
        if nDataDirection ~= MahjongData.GetPlayerDataDirection() then

            self:UpdateOtherPlayerCards(nDataDirection)
        else
            self:UpadteMyGainCard()
        end
    end)

    Event.Reg(self, EventType.DisCardResult, function(nDataDirection, nIndex)
        local tbDisCardList = MahjongData.GetPlayerDisCardInfoByDirection(nDataDirection)
        self:AddDisCards(nDataDirection, tbDisCardList[#tbDisCardList], true)
        if nDataDirection == MahjongData.GetPlayerDataDirection() then
            self:UpdateHuTipsBtn()
            self:UpdateHuTips()
            -- self:RemoveMyGainCard()
            --手牌进牌组

            local nUIDirection = MahjongData.ConvertDataDirectionToUIDirection(nDataDirection)

            local function UpdateMyCards()
                self.scriptDisCard = nil
                local tbPlayAnimIndex = nIndex ~= 0 and {nIndex} or nil
                self:UpdateMyCards(MahjongData.GetMyHandCardInfo(), tbPlayAnimIndex)
                self:RemoveMyGainCard()
            end

            if self.scriptDisCard then
                MahjongAnimHelper.PlayCardOutAnim({self.scriptDisCard._rootNode}, nUIDirection, nil, function()
                    UpdateMyCards()
                end)
            else
                UpdateMyCards()
            end
        else
            self:UpdateOtherPlayerCards(nDataDirection)
        end

    end)

    Event.Reg(self, EventType.OnUpdateTime, function(szTime)
        self:UpdateTime(szTime)
    end)

    Event.Reg(self, EventType.OperatePongKongWin, function(nType, tbOperateInfo)
        if nType > 0 then
            self:UpdateOperate(tbOperateInfo)
            self:UpdateHuTips()
            if tbOperateInfo[PLAYER_OPERATE_HU] > 0 then
                self:UpdateHuTipsBtn(true)
            end
        else
            self:UpdateOperate()
        end
    end)

    Event.Reg(self, EventType.PongResult, function(nOperationType, nDataDirection, nCard)
        local nOwnDirection = MahjongData.GetPlayerDataDirection()
        if nDataDirection == nOwnDirection then
            self:UpdateOperate()
            self:UpdateHuTips()
            self:UpdateMyCards(MahjongData.GetMyHandCardInfo())
        else

            self:UpdateOtherPlayerCards(nDataDirection)
        end
        self:ShowCurrentOperatePlayer(nDataDirection)
        self:RemoveLastDisCard()
        self:AddPongKongCard(MahjongData.Card16ToCardInfo(nCard), nDataDirection, nOperationType)
        self:PlayEffects(nDataDirection, MahjongEffectType.PENG)
    end)

    Event.Reg(self, EventType.KongResult, function(nOperationType, nDataDirection, nCard, nMaxNum)
        local nOwnDirection = MahjongData.GetPlayerDataDirection()
        if nDataDirection == nOwnDirection then
            self:UpdateOperate()
            self:UpdateHuTips()

            if nOperationType == PLAYER_OPERATE_AN_GANG then
                MahjongData.SetGameData("tbWaitCardInfo", nil)
                self:RemoveMyGainCard()
            elseif nOperationType == PLAYER_OPERATE_MING_GANG then
                self:RemoveLastDisCard()  --明杠需要删除弃牌区那张牌
            end

            self:UpdateMyCards(MahjongData.GetMyHandCardInfo())
            self:PlayEffects(nDataDirection, MahjongEffectType.GANG)
        else

            self:UpdateOtherPlayerCards(nDataDirection)
        end
        self:AddPongKongCard(MahjongData.Card16ToCardInfo(nCard), nDataDirection, nOperationType)

    end)

    Event.Reg(self, EventType.WinResult, function(nWinDirection, tbCardInfo, tbWinType)
        self:AddWinCard(tbCardInfo, nWinDirection)
        --ShowAgentImg(nWinDirection, false)
        if tbWinType[2] > 0 then  --自摸 删除是手牌
            --自摸

            self:UpdateOtherPlayerCards(nWinDirection)
        else
            if tbWinType[5] > 0 then
                --一炮多响播只要删除一次
                if MahjongData.GetGameData("bMultipleWin") then
                    self:RemoveLastDisCard()
                    MahjongData.SetGameData("bMultipleWin", false)
                end
            else
                self:RemoveLastDisCard()
            end
            self:PlayEffects(nWinDirection, MahjongEffectType.FP)
        end

        local tbWins = MahjongData.GetPlayerWinsCardInfoByDirection(nWinDirection)
        if nWinDirection == MahjongData.GetPlayerDataDirection() then
            self:UpdateOperate()
            self:UpdateHuTips()
            --胡牌后手牌要变灰
            if #tbWins >= 1 then
                self:UpdateMyCards(MahjongData.GetMyHandCardInfo())
            end
            if tbWinType[2] > 0 then--自摸 刚摸到的牌置空
                MahjongData.SetGameData("tbWaitCardInfo", nil)
            end
        else
            --其他玩家胡牌后手牌盖上显示
            if #tbWins == 1 then
                self:UpdateOneOtherOpenCards(nWinDirection, true)
            end
        end

        if tbWinType[5] > 0 then
            --一炮多响播一炮多响的特效
		    return
        end

        self.tbWinSFXInfo = {}
        if tbWinType[1] > 0 and tbWinType[2] > 0 then
            --杠上开花
            table.insert(self.tbWinSFXInfo, {nWinDirection, MahjongEffectType.GSKH})
        end
        if tbWinType[3] > 0 then
            --海底捞月
            table.insert(self.tbWinSFXInfo,  {nWinDirection, MahjongEffectType.HDLY})
        elseif tbWinType[1] < 1 and tbWinType[2] > 0 then
            --自摸
            table.insert(self.tbWinSFXInfo,  {nWinDirection, MahjongEffectType.ZM})
        end

        if #self.tbWinSFXInfo == 0 then
            table.insert(self.tbWinSFXInfo,  {nWinDirection, MahjongEffectType.HU})
        end

    end)

    Event.Reg(self, EventType.MultipleWinResult, function(nDataDirection1, nDataDirection2, nDataDirection3)
        if nDataDirection1 > 0 then self:PlayEffects(nDataDirection1, MahjongEffectType.YPDX) end
        if nDataDirection2 > 0 then self:PlayEffects(nDataDirection2, MahjongEffectType.YPDX) end
        if nDataDirection3 > 0 then self:PlayEffects(nDataDirection3, MahjongEffectType.YPDX) end
    end)

    Event.Reg(self, EventType.PassCardResult, function(nDataDirection)
        self:UpdateOperate()
        self:PlayEffects(nDataDirection, MahjongEffectType.PASS)
    end)


    Event.Reg(self, EventType.SyncGradeOrHonor, function(nOperationType, nDataDirection, nCurrGrade, nAddGrade)
        if nOperationType == PLAYER_OPERATE_SYN_CASH then
            self:UpdatePlayerInfoByDataDirection(nDataDirection)
            self:UpdateWidgetAddNumber(nDataDirection, nAddGrade)
        else
            --荣誉点
        end
    end)

    Event.Reg(self, EventType.SyncGameState, function(nState)
        if nState == CONST_TABLE_STATE_END_GAME then
            self:UpdateTime("")

        end
    end)

    Event.Reg(self, EventType.GameOver, function()
        -- ShowOtherPlayerHandCardFront()
        self:UpdateReadyState()
        self:UpdateOtherOpenCards()
        self:UpdateOperate()
        self:UpdateHuTips()
    end)

    Event.Reg(self, EventType.SyncDisconnectedData, function(nDataDirection, nCard, nGameState)
        local nOwnDirection = MahjongData.GetPlayerDataDirection()
        if nDataDirection == nOwnDirection and nCard > 0 then
            self:UpadteMyGainCard()
        end
        if nGameState == CONST_TABLE_STATE_WAIT_CS_SEND or nGameState == CONST_TABLE_STATE_WAIT_CS_SEND_1 then
            --等待玩家出牌
            self:ShowCurrentOperatePlayer(nDataDirection)
            -- local tCardData = GetLastDiscard()
            -- if tCardData then
            --     ShowHighlightLastDiscards(tCardData.nDirection, tCardData.tCardInfo)
            -- end
        elseif (nGameState == CONST_TABLE_STATE_WAIT_OPERATE or nGameState == CONST_TABLE_STATE_WAIT_OPERATE_COMBO) and nCard > 0
        and nDataDirection ~= nOwnDirection then
            --等待玩家碰杠胡
            local tbCardInfo = MahjongData.GetLastDisCardInfo()
            self:AddDisCards(nDataDirection, tbCardInfo)
        end
    end)

    Event.Reg(self, EventType.OnAgentStateChange, function(nDataDirection, bAgent)
        if nDataDirection == MahjongData.GetPlayerDataDirection() then
            self:UpdateAgent()
        end
        self:UpdatePlayerInfo()
    end)

    Event.Reg(self, EventType.OnSetPlayerCardInfo, function(nDataDirection, szVarName, value)
        if szVarName == "nGrade" and value <= 0 and nDataDirection == MahjongData.GetPlayerDataDirection() then
            self:UpdateMyCards(MahjongData.GetMyHandCardInfo())
        end
    end)

    -- Event.Reg(self, EventType.OnPlayerWinsCardChange, function(nDataDirection, nLength)
    --     if nLength >= 0 then
    --         if nDataDirection == MahjongData.GetPlayerDataDirection() then
    --             self:UpdateMyCards(MahjongData.GetMyHandCardInfo())
    --         end
    --     end
    -- end)

    Event.Reg(self, EventType.OnSelectMyHandCard, function(bDisCard, tbCardInfo, scriptView)
        local tbPoints = bDisCard and nil or MahjongData.GetFutureWinPoints(tbCardInfo)
        self:UpdateHuTips(tbPoints)
        if bDisCard then
            self.scriptDisCard = scriptView
        end
    end)

    Event.Reg(self, EventType.OnClearGameData, function()--对局结束清理上一局数据后，刷新页面
        self:InitAllCards()
        self:ClearAllOpenCards()
        self:HideWordDirection()
        self:HideBankerIcon()
        self:ShowCurrentOperatePlayer(nil)
        self:CloseHuTips()
    end)

    Event.Reg(self, EventType.OnTouchViewBackGround, function()
        self:UpdateHuTips()
        UIHelper.SetVisible(self.WidgetOption2, false)
        UIHelper.SetVisible(self.WidgetBill, false)
        self:ClosePlayerTips()
    end)
end

function UIPanelMahjongMainView:UnRegEvent()

end

function UIPanelMahjongMainView:Init()
    self.tbPlayerInfoScript = {}
    self.nFrame = Timer.AddFrameCycle(self, 1, function()
        self:OnTimer()
    end)
end

function UIPanelMahjongMainView:OnTimer()
    if self.tbWinSFXInfo and #self.tbWinSFXInfo > 0 then
        self.nWinSFXCounter = self.nWinSFXCounter or 0
        if self.nWinSFXCounter % 15 == 0 then
            local tbWinSFXInfo = self.tbWinSFXInfo[1]
            self:PlayEffects(tbWinSFXInfo[1], tbWinSFXInfo[2])
            table.remove(self.tbWinSFXInfo, 1)
        end
        self.nWinSFXCounter = self.nWinSFXCounter + 1
    end

end

-- ----------------------------------------------------------
-- Please write your own code below  ↓↓↓
-- ----------------------------------------------------------

function UIPanelMahjongMainView:UpdateInfo()
    
    self:UpdateSkin()
    self:UpdatePlayerInfo()

    local bGameStart = MahjongData.GetGameStart()
    if bGameStart then

        self:InitAllCards()
        self:InitGameState()

        self:UpdateWordDirection()
        self:UpdateSurplusNum()
        self:ShowBankerIcon()
    end
    self:UpdateAgent()
    self:ShowCurrentOperatePlayer(GetCurOperatePlayer())
    self:UpdateHuTipsBtn()
    self:UpdateTime("")
    self:UpdateSurplusState()
    --self.script_ItemHint = UIHelper.AddPrefab(PREFAB_ID.WidgetGetItemHintArea , self.WidgetRewardShow)
end

function UIPanelMahjongMainView:UpdateSkin()
    local nSkinID = MahjongData.GetSkinInfoID("Panel")
    if nSkinID then
        UIHelper.SetVisible(self.WidgetBlackGoldBg, nSkinID == BLACK_GOLD_SKINID)
        UIHelper.SetVisible(self.WidgetMahjongBg, nSkinID == 1)
        UIHelper.SetVisible(self.WidgetMahjongBg_02, nSkinID == 2)--临时做法：WidgetMahjongBg部分节点有问题会压缩图片
    end
    -- if nSkinID ~= BLACK_GOLD_SKINID then
    --     local script = UIHelper.GetBindScript(self.WidgetMahjongBg)
    --     script:OnEnter(nSkinID)
    -- end
    self:UpdateSurPlusBG()
end

function UIPanelMahjongMainView:UpdateSurPlusBG()
    local szImgSurplusBg1 = MahjongData.GetBackCardImg(tUIPosIndex.Up)
    UIHelper.SetSpriteFrame(self.ImgSurplusBg1, szImgSurplusBg1)
end

function UIPanelMahjongMainView:InitAllCards()

    self:InitPlayerCards()
    self:InitWallCards()
    self:InitDisCards()
    self:InitPongKong()
    self:UpdateWinCards()
    self:UpadteMyGainCard()
end

function UIPanelMahjongMainView:InitGameState()
    local nGameState = MahjongData.GetGameData("nGameState")

    if nGameState == CONST_TABLE_STATE_EXCHANGE then
        self:UpdateSwapOutCard()
    elseif nGameState == CONST_TABLE_STATE_SET_LACK then
        self:ShowDingQueBtn(true, MahjongData.GetGameData("nOwnLackType"))
    end
end

---------------------------------------------------------更新玩家状态 Start------------------------------------------------

function UIPanelMahjongMainView:UpdatePlayerInfo(bChangeCard)
    if not bChangeCard then bChangeCard = false end
    local tbPlayerInfo = MahjongData.GetPlayerInfoData()
    local nGameState = MahjongData.GetGameData("nGameState")
    local tbDirection = {}
    for nDataDirection, tbData in pairs(tbPlayerInfo) do
        local nUIDirection = MahjongData.ConvertDataDirectionToUIDirection(nDataDirection)
        table.insert(tbDirection, nUIDirection)
        tbData[3] = MahjongData.GetPlayerCardInfo("nGrade", nDataDirection) or tbData[3]
        local nGameState = MahjongData.GetGameData("nGameState")
        tbData[5] = (nGameState and nGameState > CONST_TABLE_STATE_SET_LACK) and MahjongData.GetPlayerCardInfo("nLackType", nDataDirection) or nil
        tbData[6] = nGameState == CONST_TABLE_STATE_SET_LACK and (not bChangeCard)--定缺
        tbData[7] = nGameState == CONST_TABLE_STATE_EXCHANGE and (not bChangeCard)--选牌
        tbData[8] = bChangeCard --换牌
        tbData[9] = MahjongData.GetAgentState(nDataDirection)
        local scriptPlayer = self.tbPlayerInfoScript[nUIDirection]
        if not scriptPlayer then
            local nPreferb = (nUIDirection == tUIPosIndex.Left or nUIDirection == tUIPosIndex.Right) and PREFAB_ID.WidgetMahjongHeadLeft or PREFAB_ID.WidgetMahjongHeadUp
            scriptPlayer = UIHelper.AddPrefab(nPreferb, self.tbPlayerHead[nUIDirection], tbData, self)
            self.tbPlayerInfoScript[nUIDirection] = scriptPlayer
        else
            scriptPlayer:OnEnter(tbData, self)
        end
    end

    for nDataDirection, nValue in pairs(tUIPosIndex) do
        if (not table.contain_value(tbDirection, nValue)) and self.tbPlayerInfoScript[nValue] then
            UIHelper.RemoveFromParent(self.tbPlayerInfoScript[nValue]._rootNode, true)
            self.tbPlayerInfoScript[nValue] = nil
        end
    end
    self:UpdateReadyState()
end

function UIPanelMahjongMainView:ClosePlayerTips()
    for nUIDirection, scriptView in pairs(self.tbPlayerInfoScript) do
        scriptView:CloseGameInfo()
    end
end

function UIPanelMahjongMainView:UpdatePlayerInfoByDataDirection(nDataDirection)
    local nUIDirection = MahjongData.ConvertDataDirectionToUIDirection(nDataDirection)
    local tbPlayerInfo = MahjongData.GetPlayerInfoDataByDataDirection(nDataDirection)
    tbPlayerInfo[3] = MahjongData.GetPlayerCardInfo("nGrade", nDataDirection) or tbPlayerInfo[3]
    self.tbPlayerInfoScript[nUIDirection]:OnEnter(tbPlayerInfo)
end

function UIPanelMahjongMainView:UpdateReadyState()
    local tbPlayerInfo = MahjongData.GetPlayerInfoDataByDataDirection(MahjongData.GetPlayerDataDirection())
    local nReadyState = tbPlayerInfo[2]
    local bStartGame = MahjongData.GetGameStart()
    UIHelper.SetVisible(self.WidgetStartGame, not bStartGame)
    local bShowReadyBtn = (nReadyState == tPlayerState.nNotReady) or (nReadyState == tPlayerState.nDefault)  --是显示准备按钮
    UIHelper.SetVisible(self.BtnReady, bShowReadyBtn)
    UIHelper.SetVisible(self.BtnExit, bShowReadyBtn)
    UIHelper.SetVisible(self.BtnCancel, not bShowReadyBtn)
end
---------------------------------------------------------更新玩家状态 End------------------------------------------------

---------------------------------------------------------其它玩家手上的牌相关 Start------------------------------------------------
function UIPanelMahjongMainView:InitPlayerCards(bPlayAnimate, funcCallBack)
    local  nOwnDirection = MahjongData.GetPlayerDataDirection()
    for szDataDirection, nDataDirection in pairs(tDirectionType) do
        if nDataDirection == nOwnDirection then
            local tbCardList = MahjongData.GetMyHandCardInfo()
            local tbPlayAnimIndex = {}
            for nIndex = 1, #tbCardList do table.insert(tbPlayAnimIndex, nIndex) end
            self:UpdateMyCards(tbCardList, bPlayAnimate and tbPlayAnimIndex or nil, nil, funcCallBack)
        else
            self:InitOtherPlayerCards(nDataDirection, tbHandCardPrefab, bPlayAnimate)
        end
    end
end

--初始化其他玩家的牌
function UIPanelMahjongMainView:InitOtherPlayerCards(nDataDirection, tbPrefab, bPlayAnimate)
    if not self.tbScriptOtherPlayerCard then self.tbScriptOtherPlayerCard = {} end
    self.tbScriptOtherPlayerCard[nDataDirection] = {}
    local nUIDirection = MahjongData.ConvertDataDirectionToUIDirection(nDataDirection)
    local nHandCardNum = MahjongData.GetPlayerCardInfo("nHandCardNum", nDataDirection) or 0
    UIHelper.RemoveAllChildren(self.tbHandCardParent[nUIDirection])
    local tbNode = {}
    for nIndex = 1, nMaxHandCardNum do
        local scriptView = UIHelper.AddPrefab(tbPrefab[nUIDirection], self.tbHandCardParent[nUIDirection])
        table.insert(self.tbScriptOtherPlayerCard[nDataDirection], scriptView)
        UIHelper.SetVisible(scriptView._rootNode, nIndex <= nHandCardNum)
        if nIndex <= nHandCardNum then table.insert(tbNode, scriptView._rootNode) end
    end
    if bPlayAnimate then
        MahjongAnimHelper.PlayInitCardAnim(tbNode, self.tbHandCardParent[nUIDirection], nUIDirection)
    end
end


function UIPanelMahjongMainView:UpdateOtherPlayerCards(nDataDirection)
    local tbScriptList = self.tbScriptOtherPlayerCard[nDataDirection]
    local tbWins = MahjongData.GetPlayerWinsCardInfoByDirection(nDataDirection)
    local nUIDirection = MahjongData.ConvertDataDirectionToUIDirection(nDataDirection)
    local nHandCardNum =  #tbWins <= 0 and MahjongData.GetPlayerCardInfo("nHandCardNum", nDataDirection) or 0

    local tbOutAnimNode = {}
    local tbInAnimNode = {}

   for nIndex, scriptView in ipairs(tbScriptList) do
        local node = scriptView._rootNode
        local bVisible = UIHelper.GetVisible(node)
        if nIndex > nHandCardNum and bVisible then
            table.insert(tbOutAnimNode, node)
        elseif nIndex <= nHandCardNum and not bVisible then
            table.insert(tbInAnimNode, node)
        else
            UIHelper.SetVisible(node, nIndex <= nHandCardNum)
        end
   end


   local layout = self.tbHandCardParent[nUIDirection]

    MahjongAnimHelper.PlayCardOutAnim(tbOutAnimNode, nUIDirection, nil, function()
        MahjongAnimHelper.PlayCardInAnim(tbInAnimNode, layout, nUIDirection, nil, nil)
    end)
end


function UIPanelMahjongMainView:UpdateOtherOpenCards()
    local nOwnDirection = MahjongData.GetPlayerDataDirection()
    for szDataDirection, nDataDirection in pairs(tDirectionType) do
        if nDataDirection ~= nOwnDirection then
            self:UpdateOneOtherOpenCards(nDataDirection, false)
        end
    end
end

function UIPanelMahjongMainView:UpdateOneOtherOpenCards(nDataDirection, bHu)
    self:UpdateOtherPlayerCards(nDataDirection)
    local tbCardList = GetPlayerDebugPeepHand(nDataDirection) or {}
    local nUIDirection = MahjongData.ConvertDataDirectionToUIDirection(nDataDirection)
    local nLength = bHu and MahjongData.GetPlayerCardInfo("nHandCardNum", nDataDirection) or #tbCardList
    local nStart = (nUIDirection == tUIPosIndex.Up or nUIDirection == tUIPosIndex.Right) and nLength or 1
    local nEnd = (nUIDirection == tUIPosIndex.Up or nUIDirection == tUIPosIndex.Right) and 1 or nLength
    local nStep = (nUIDirection == tUIPosIndex.Up or nUIDirection == tUIPosIndex.Right) and -1 or 1
    local nPreferb = nUIDirection ~= tUIPosIndex.Up and PREFAB_ID.WidgetLeftRightOpen or PREFAB_ID.WidgetUpOpen
    UIHelper.RemoveAllChildren(self.tbOpenLayout[nUIDirection - 1])
    for i = nStart, nEnd, nStep do
        local nCard = bHu and nil or tbCardList[i]
        local tbCardInfo = nCard and MahjongData.Card16ToCardInfo(nCard) or {}
        tbCardInfo.bHu = bHu
        UIHelper.AddPrefab(nPreferb, self.tbOpenLayout[nUIDirection - 1], tbCardInfo, nUIDirection)
    end
    UIHelper.LayoutDoLayout(self.tbOpenLayout[nUIDirection - 1])
end


function UIPanelMahjongMainView:ClearAllOpenCards()
    for szDataDirection, nDataDirection in pairs(tDirectionType) do
        local nUIDirection = MahjongData.ConvertDataDirectionToUIDirection(nDataDirection)
        UIHelper.RemoveAllChildren(self.tbOpenLayout[nUIDirection - 1])
    end
end
---------------------------------------------------------其他玩家手上的牌相关 End------------------------------------------------

---------------------------------------------------------更新自己手上的牌相关 Start------------------------------------------------
--初始化自己的牌
function UIPanelMahjongMainView:UpdateMyCards(tbCardList, tbPlayInAnimIndex, tbPlayOutAnimIndex, funcAnimEnd)

    local tbOutNode = {}
    local tbInNode = {}
    self:RemoveAllMyCards()
    for nIndex, tbCardInfo in ipairs(tbCardList) do
        local scriptView = self.tbMyCards and self.tbMyCards[nIndex] or nil
        if not scriptView then
            scriptView = self:AddMyCard(tbCardInfo)
        else
            scriptView:OnEnter(tbCardInfo)
        end
        if tbPlayInAnimIndex and table.contain_value(tbPlayInAnimIndex, nIndex) then
            table.insert(tbInNode, scriptView._rootNode)
        end
        if tbPlayOutAnimIndex and table.contain_value(tbPlayOutAnimIndex, nIndex) then
            table.insert(tbOutNode, scriptView._rootNode)
        end
    end

    local nUIDirection = MahjongData.ConvertDataDirectionToUIDirection(MahjongData.GetPlayerDataDirection())

    --播完出牌动画再播进牌动画
    MahjongAnimHelper.PlayCardOutAnim(tbOutNode, nUIDirection, nil, function()
        MahjongAnimHelper.PlayInitCardAnim(tbInNode, self.LayoutMahjongDownMod, nUIDirection, funcAnimEnd)
    end)
end


function UIPanelMahjongMainView:UpdateSwapOutCard()
    local tbCardList = MahjongData.GetMyHandCardInfo()
    self:UpdateSwapCardTip(true)
    local tbSelectionSwapCard = MahjongData.GetSelectionSwapCard()
    local tbSelectionSwapCardInfo = tbSelectionSwapCard and clone(tbSelectionSwapCard.tbCard) or nil
    for nIndex, tbCardInfo in ipairs(tbCardList) do
        local nKey = MahjongData.CardCardInfoTo10(tbCardInfo)
        if tbSelectionSwapCardInfo and tbSelectionSwapCardInfo[nKey] and tbSelectionSwapCardInfo[nKey] > 0 then
            tbSelectionSwapCardInfo[nKey] = tbSelectionSwapCardInfo[nKey] - 1
            local scriptView = self.tbMyCards[nIndex]
            scriptView:CardUp()
        end
    end
end

function UIPanelMahjongMainView:RemoveAllMyCards()
    if self.tbMyCards then
        for index, scriptView in ipairs(self.tbMyCards) do
            UIHelper.SetVisible(scriptView._rootNode, false)
        end
    end
end




function UIPanelMahjongMainView:AddMyCard(tbCardInfo)
    if not self.tbMyCards then self.tbMyCards = {} end
    local scriptView =  UIHelper.AddPrefab(PREFAB_ID.WidgetMahjongDownMod, self.LayoutMahjongDownModChild, tbCardInfo)
    table.insert(self.tbMyCards, scriptView)
    return scriptView
end


---------------------------------------------------------更新自己手上的牌相关 End------------------------------------------------

---------------------------------------------------------定缺相关 Start------------------------------------------------
function UIPanelMahjongMainView:ShowDingQueBtn(bShow, nCardType)
    UIHelper.SetVisible(self.WidgetDingQue, bShow)
    if bShow then
        UIHelper.SetSelected(self.ToggleSlips, nCardType == 1, false)
        UIHelper.SetSelected(self.ToggleTube, nCardType == 2, false)
        UIHelper.SetSelected(self.ToggleWan, nCardType == 0, false)

        UIHelper.SetVisible(self.AniSlips, nCardType == 1)
        UIHelper.SetVisible(self.AniTube, nCardType == 2)
        UIHelper.SetVisible(self.AniWan, nCardType == 0)
    end
end

---------------------------------------------------------定缺相关 End------------------------------------------------

---------------------------------------------------------中间圆盘信息更新 Start------------------------------------------

function UIPanelMahjongMainView:ShowCurrentOperatePlayer(nDataDirection)
    local nUIDirection = MahjongData.ConvertDataDirectionToUIDirection(nDataDirection)
    for nIndex, Node in ipairs(self.tbOperateDirection) do
        UIHelper.SetVisible(Node, nIndex == nUIDirection)
    end
end

function UIPanelMahjongMainView:UpdateWordDirection()
    local nOwnDirection = MahjongData.GetPlayerDataDirection()
    local nCurDirection = nOwnDirection
    for nIndex, img in ipairs(self.tbWordImg) do
        UIHelper.SetSpriteFrame(img, tbDirectionWordImg[nCurDirection])
        UIHelper.SetSpriteFrame(self.tbWordImgHilight[nIndex], tbDirectionWordImg[nCurDirection])
        nCurDirection = (nCurDirection + 1) % 5
        if nCurDirection == 0 then
            nCurDirection = 1
        end
    end
    UIHelper.SetVisible(self.WidgetWord, true)
end

function UIPanelMahjongMainView:HideWordDirection()
    UIHelper.SetVisible(self.WidgetWord, false)
end

function UIPanelMahjongMainView:UpdateTime(szTime)
    UIHelper.SetString(self.TextCountDown, szTime)
end

function UIPanelMahjongMainView:ShowBankerIcon()
    local nBankerDirection = MahjongData.GetGameData("nBankerDirection")
    local nUIDirection = MahjongData.ConvertDataDirectionToUIDirection(nBankerDirection)
    UIHelper.SetVisible(self.tbImageBanker[nUIDirection], true)
end

function UIPanelMahjongMainView:HideBankerIcon()
    for szUIDirection, nUIDirection in pairs(tUIPosIndex) do
        UIHelper.SetVisible(self.tbImageBanker[nUIDirection], false)
    end
end

function UIPanelMahjongMainView:UpdateDiceEffect(bShow, funcCallBack)
    UIHelper.SetVisible(self.WidgetDice, bShow)
    if bShow then
        -- MahjongAnimHelper.PlayDiceEffects({self.ImgDice1, self.ImgDice2}, 2, function()
        --     if funcCallBack then funcCallBack() end
        -- end)
        UIHelper.SetVisible(self.ImgDice1, false)
        UIHelper.SetVisible(self.ImgDice2, false)
        UIHelper.SetVisible(self.AniDice1, true)
        UIHelper.SetVisible(self.AniDice2, true)
        -- UIHelper.PlaySFX(self.AniDice1)
        -- UIHelper.PlaySFX(self.AniDice2)
        MahjongData.DelayCall("OnDiceEffecEnd", nDiceNumTime, function()
            if funcCallBack then funcCallBack() end
        end)
    end

end

function UIPanelMahjongMainView:UpdateDiceNum()
    UIHelper.SetVisible(self.AniDice1, false)
    UIHelper.SetVisible(self.AniDice2, false)
    UIHelper.SetVisible(self.ImgDice1, true)
    UIHelper.SetVisible(self.ImgDice2, true)
    local szIconPath = tDiceNumImgPath.szIconPath
    local nIconFrame1 = MahjongData.GetGameData("nDieDot1")
    local nIconFrame2 = MahjongData.GetGameData("nDieDot2")
    local szFrameName1 = MahjongData.GetCardImg(szIconPath, nIconFrame1)
    local szFrameName2 = MahjongData.GetCardImg(szIconPath, nIconFrame2)
    if szFrameName1 ~= "" and szFrameName2 ~= "" then
        UIHelper.SetSpriteFrame(self.ImgDice1, szFrameName1)
        UIHelper.SetSpriteFrame(self.ImgDice2, szFrameName2)
    end
end
---------------------------------------------------------中间圆盘信息更新 End------------------------------------------

---------------------------------------------------------牌墙相关 Start--------------------------------------


--更新牌墙
function UIPanelMahjongMainView:ReduceWallCard()
    local nDataDirection, nStackPos, nIndex = MahjongData.GetSecondDrawPos()
    local nUIDirection = MahjongData.ConvertDataDirectionToUIDirection(nDataDirection)
    nStackPos = (nUIDirection == tUIPosIndex.Down or nUIDirection == tUIPosIndex.Left) and tDirection2CardStackNnm[nDataDirection] - nStackPos or nStackPos - 1
    local scriptWall = self.tbWallCardScript[nUIDirection][nStackPos + 1]
    scriptWall:SetVisible(nIndex, false)
end


function UIPanelMahjongMainView:InitOneDirectionWall(nDataDirection, tbWallList)
    local nUIDirection = MahjongData.ConvertDataDirectionToUIDirection(nDataDirection)
    if not self.tbWallCardScript[nUIDirection] then self.tbWallCardScript[nUIDirection] = {} end

    local nScriptIndex = 1
    local nLength = #tbWallList
    local nStart = (nUIDirection == tUIPosIndex.Down or nUIDirection == tUIPosIndex.Left) and nLength or 1
    local nEnd = (nUIDirection == tUIPosIndex.Down or nUIDirection == tUIPosIndex.Left) and 1 or nLength
    local nStep = (nUIDirection == tUIPosIndex.Down or nUIDirection == tUIPosIndex.Left) and -1 or 1
    local nPreferb = tbWallCardPrefab[nUIDirection]
    for nIndex = nStart, nEnd, nStep do
        local tbWallInfo = tbWallList[nIndex]
        local scriptView = self.tbWallCardScript[nUIDirection][nScriptIndex]
        if not scriptView then
            scriptView = UIHelper.AddPrefab(nPreferb, self.tbWallCardParent[nUIDirection], tbWallInfo, nUIDirection)
            table.insert(self.tbWallCardScript[nUIDirection], scriptView)
        else
            scriptView:OnEnter(tbWallInfo)
        end
        nScriptIndex = nScriptIndex + 1
    end
    self.tbWallCardLength[nUIDirection] = nScriptIndex - 1
    UIHelper.LayoutDoLayout(self.tbWallCardParent[nUIDirection])

end

--初始化牌墙
function UIPanelMahjongMainView:InitWallCards()

    if not self.tbWallCardScript then self.tbWallCardScript = {} end
    if not self.tbWallCardLength then self.tbWallCardLength = {} end
    local tbWalls = MahjongData.GetWalls()
    for szDataDirection, nDataDirection in pairs(tDirectionType) do
        if tbWalls and tbWalls[nDataDirection] then
            self:InitOneDirectionWall(nDataDirection, tbWalls[nDataDirection])
        end
    end
end

---------------------------------------------------------牌墙相关 End--------------------------------------


---------------------------------------------------------我刚获得的牌 Start------------------------------------

function UIPanelMahjongMainView:UpadteMyGainCard()
    local tbCardInfo = MahjongData.GetGameData("tbWaitCardInfo")
    if tbCardInfo then
        local scriptView = UIHelper.AddPrefab(PREFAB_ID.WidgetMahjongDownMod, self.WidgetMahjongDownMod, tbCardInfo)
        local nUIDirection = MahjongData.ConvertDataDirectionToUIDirection(MahjongData.GetPlayerDataDirection())
        MahjongAnimHelper.PlayCardInAnim({scriptView._rootNode}, self.LayoutMahjongDownMod, nUIDirection)
    end
end

function UIPanelMahjongMainView:RemoveMyGainCard()
    UIHelper.RemoveAllChildren(self.WidgetMahjongDownMod)
end
---------------------------------------------------------我刚获得的牌 Start------------------------------------


---------------------------------------------------------弃牌区的牌相关 Start--------------------------------------

function UIPanelMahjongMainView:UpdateOneDatairectionDisCards(nDataDirection, tbDisCards)

    for index, tbCardInfo in ipairs(tbDisCards) do
        self:AddDisCards(nDataDirection, tbCardInfo)
    end
    local nUIDirection = MahjongData.ConvertDataDirectionToUIDirection(nDataDirection)
    UIHelper.LayoutDoLayout(self.tbPassParent[nUIDirection])
end

function UIPanelMahjongMainView:RemoveOneDirectionDiscards(nDataDirection)
    if self.tbPassCardScript and self.tbPassCardScript[nDataDirection] then
        for index, scriptView in ipairs(self.tbPassCardScript[nDataDirection]) do
            -- UIHelper.SetVisible(scriptView._rootNode, false)
            scriptView:Hide()
        end
    end
    if self.tbLastDisCardScriptIndex and self.tbLastDisCardScriptIndex[nDataDirection] then
        self.tbLastDisCardScriptIndex[nDataDirection] = 0
    end
end

function UIPanelMahjongMainView:InitDisCards()
    local tbDisCardsInfo = MahjongData.GetPlayerDisCardInfo()
    for szDataDirection, nDataDirection in pairs(tDirectionType) do
        self:RemoveOneDirectionDiscards(nDataDirection)
        if tbDisCardsInfo and tbDisCardsInfo[nDataDirection] then
            self:UpdateOneDatairectionDisCards(nDataDirection, tbDisCardsInfo[nDataDirection])
        end
    end

    -- for nDataDirection, tbCardLidst in pairs(tbDisCardsInfo) do

    --     local nUIDirection = MahjongData.ConvertDataDirectionToUIDirection(nDataDirection)
    --     UIHelper.RemoveAllChildren(self.tbPassParent[nUIDirection])
    --     self.tbPassCardScript[nDataDirection] = {}

    --     for nIndex, tbInfo in ipairs(tbCardLidst) do
    --         self:AddDisCards(nDataDirection, tbInfo, false)
    --     end

    --     local nUIDirection = MahjongData.ConvertDataDirectionToUIDirection(nDataDirection)
    --     UIHelper.LayoutDoLayout(self.tbPassParent[nUIDirection])
    -- end
end


function UIPanelMahjongMainView:AddDisCards(nDataDirection, tbCardInfo, bPlayAnim)
    if not self.tbPassCardScript then self.tbPassCardScript = {} end
    if not self.tbPassCardScript[nDataDirection] then self.tbPassCardScript[nDataDirection] = {} end
    if not self.tbLastDisCardScriptIndex then self.tbLastDisCardScriptIndex = { 0,0,0,0} end
    local nScriptIndex = self.tbLastDisCardScriptIndex[nDataDirection]
    local nUIDirection = MahjongData.ConvertDataDirectionToUIDirection(nDataDirection)
    local scriptView = self.tbPassCardScript[nDataDirection][nScriptIndex + 1]
    if not scriptView then
        scriptView = UIHelper.AddPrefab(PREFAB_ID.WidgetDownPassMod, self.tbPassParent[nUIDirection], tbCardInfo)
        table.insert(self.tbPassCardScript[nDataDirection], scriptView)
        self.tbLastDisCardScriptIndex[nDataDirection] = #self.tbPassCardScript[nDataDirection]
    else
        scriptView:OnEnter(tbCardInfo)
        self.tbLastDisCardScriptIndex[nDataDirection] = nScriptIndex + 1
    end

    local function callback()
        scriptView:SetArrowVisible(true)
        LOG.INFO("=======SetArrowVisible  %s======", tostring(self.scriptLastDisCard))
        if self.scriptLastDisCard then
            self.scriptLastDisCard:SetArrowVisible(false)
        end
        self.scriptLastDisCard = scriptView
    end

    UIHelper.LayoutDoLayout(self.tbPassParent[nUIDirection])

    if bPlayAnim then
        MahjongAnimHelper.PlayDisCardAnim(scriptView._rootNode, nUIDirection, callback)
    else
        callback()
    end
end

function UIPanelMahjongMainView:RemoveLastDisCard()
    local tbLastDisCardInfo = MahjongData.GetLastDisCardInfo()
    if not tbLastDisCardInfo then return end
    local nDataDirection = tbLastDisCardInfo.nDataDirection
    local nLength = #self.tbPassCardScript[nDataDirection]
    -- UIHelper.SetVisible(self.tbPassCardScript[nDataDirection][nLength]._rootNode, false)
    self.tbPassCardScript[nDataDirection][nLength]:Hide()
    self.tbLastDisCardScriptIndex[nDataDirection] = self.tbLastDisCardScriptIndex[nDataDirection] - 1

    LOG.INFO("=======RemoveLastDisCard  %s======", debug.traceback())
    self.scriptLastDisCard = nil
    MahjongData.SetLastDisCardInfo(nil)
end


---------------------------------------------------------弃牌区的牌相关 End--------------------------------------

----------------------------------------------------------过碰杠胡按钮更新 Start----------------------------------

function UIPanelMahjongMainView:UpdateOperate(tbOperateInfo)
    if not tbOperateInfo or not next(tbOperateInfo) then
		UIHelper.SetVisible(self.WidgetOperate, false)
		return
	end
    local bPongBtn = tbOperateInfo[PLAYER_OPERATE_PENG] > 0
	UIHelper.SetVisible(self.BtnPeng, bPongBtn)
	local bKongBtn = tbOperateInfo[PLAYER_OPERATE_MING_GANG] > 0
	UIHelper.SetVisible(self.BtnGang, bKongBtn)
	local bWinBtn = tbOperateInfo[PLAYER_OPERATE_HU] > 0
	UIHelper.SetVisible(self.BtnHu, bWinBtn)
	local bPassBtn = tbOperateInfo[PLAYER_OPERATE_JUMP] and tbOperateInfo[PLAYER_OPERATE_JUMP] > 0
	UIHelper.SetVisible(self.BtnPass, bPassBtn)

	local bWndOperate = false
	if bPongBtn or bKongBtn or bWinBtn or bPassBtn then
		bWndOperate = true
	end
    UIHelper.SetVisible(self.WidgetOperate, bWndOperate)
    UIHelper.LayoutDoLayout(self.LayoutBtnOperate)
end

-----------------------------------------------------------过碰杠胡按钮更新 End----------------------------------

-----------------------------------------------------------HuTips更新 Start ---------------------------------------
function UIPanelMahjongMainView:UpdateHuTips(tbPoints)
    if not tbPoints or not next(tbPoints) then
        UIHelper.SetVisible(self.WidgetHuTips, false)
        return
    end
    self:UpdateHuTipsBtn(true)
    UIHelper.RemoveAllChildren(self.LayoutHuTip)
    for nCard, nPoints in pairs(tbPoints) do
        local tbCardInfo = MahjongData.Card16ToCardInfo(nCard)
        tbCardInfo.nCount = MahjongData.GetUnknownCount(nCard)
        tbCardInfo.nMultiple = nPoints
        UIHelper.AddPrefab(PREFAB_ID.WidgetHuTip, self.LayoutHuTip, tbCardInfo)
    end
    UIHelper.LayoutDoLayout(self.LayoutHuTip)
    UIHelper.SetVisible(self.WidgetHuTips, true)
end

-----------------------------------------------------------HuTips更新 End ---------------------------------------

-----------------------------------------------------------预胡牌信息按钮 Start ---------------------------------------

function UIPanelMahjongMainView:UpdateHuTipsBtn(bShow)
    if bShow == nil then
        local tbWins = MahjongData.GetPlayerWinsCardInfoByDirection(MahjongData.GetPlayerDataDirection()) or {}
		if #tbWins > 0 then
			bShow = true
		else
			local tPoints = MahjongData.GetFutureWinPoints() or {}
			bShow = next(tPoints) ~= nil
		end
	end
    UIHelper.SetVisible(self.BtnHuTips, bShow)
    UIHelper.LayoutDoLayout(self.LayoutOptionBtn)
end

function UIPanelMahjongMainView:CloseHuTips()
    UIHelper.SetVisible(self.BtnHuTips, false)
end

-----------------------------------------------------------预胡牌信息按钮 End ---------------------------------------

------------------------------------------------------------更新玩家碰杠牌区的牌 Start-----------------------------------------
function UIPanelMahjongMainView:InitPongKong()
    local tbPongKongList = MahjongData.GetPlayerPongKongCardInfo()

    for szDataDirection, nDataDirection in pairs(tDirectionType) do

        local nUIDirection = MahjongData.ConvertDataDirectionToUIDirection(nDataDirection)
        UIHelper.RemoveAllChildren(self.tbComboLayout[nUIDirection])

        local tbPongKongInfo = tbPongKongList and tbPongKongList[nDataDirection] or nil

        if tbPongKongInfo then
            for nIndex, tbCardInfo in ipairs(tbPongKongInfo) do
                local nModeIndex = 1
                if tbCardInfo.nMark == PLAYER_OPERATE_PENG then --碰
                    nModeIndex = self:GetPongModIndex(nIndex)
                elseif tbCardInfo.nMark == PLAYER_OPERATE_GANG_AFTER_PENG then --碰后杠
                    nModeIndex = self:GetPongModIndex(nIndex)
                elseif tbCardInfo.nMark == PLAYER_OPERATE_MING_GANG then
                    nModeIndex = 2
                elseif tbCardInfo.nMark == PLAYER_OPERATE_AN_GANG then --暗杠
                    nModeIndex = 1
                end
                self:ShowPongKongCard(nModeIndex, tbCardInfo, nDataDirection)
            end
        end
    end
end


function UIPanelMahjongMainView:GetPongModIndex(nIndex)
    nIndex = nIndex % nPongModNum
    return nIndex + 3
end

function UIPanelMahjongMainView:DeletePongKongCard(nUIDirection, nIndex)

    if not self.tbPongKongInfo or not self.tbPongKongInfo[nUIDirection] then return end

    local tbInfo = self.tbPongKongInfo[nUIDirection][nIndex]
    if not tbInfo then return end
    
    local scriptView = tbInfo.scriptView
    UIHelper.RemoveFromParent(scriptView._rootNode, true)
    table.remove(self.tbPongKongInfo[nUIDirection], nIndex)
end

function UIPanelMahjongMainView:AddPongKongCard(tbCardInfo, nDataDirection, nOperationType)

    local nModeIndex = 1
    local nUIDirection = MahjongData.ConvertDataDirectionToUIDirection(nDataDirection)
    local nLength = (self.tbPongKongInfo and self.tbPongKongInfo[nUIDirection]) and #self.tbPongKongInfo[nUIDirection] or 0
    if nOperationType == PLAYER_OPERATE_PENG then --碰
		nIndex = self:GetPongModIndex(nLength + 1)
        nModeIndex = nIndex
	elseif nOperationType == PLAYER_OPERATE_AN_GANG then --暗杠
		nModeIndex = 1
	elseif nOperationType == PLAYER_OPERATE_MING_GANG then --明杠
		nModeIndex = 2
	elseif nOperationType == PLAYER_OPERATE_GANG_AFTER_PENG then --碰后杠
        for nIndex, tbInfo in ipairs(self.tbPongKongInfo[nUIDirection]) do
            if MahjongData.CherckCardEqual(tbInfo.tbCardInfo, tbCardInfo) then
                nModeIndex = tbInfo.nModeIndex
                self:DeletePongKongCard(nUIDirection, nIndex)
                break
            end
        end
	end
    tbCardInfo.nMark = nOperationType
    self:ShowPongKongCard(nModeIndex, tbCardInfo, nDataDirection)
end

function UIPanelMahjongMainView:ShowPongKongCard(nModeIndex, tbCardInfo, nDataDirection)
    local nUIDirection = MahjongData.ConvertDataDirectionToUIDirection(nDataDirection)
    local nPreferbID = tPongCardImgInfo[nUIDirection][nModeIndex].nPreferb
    local tbInfo = tPongCardImgInfo[nUIDirection][nModeIndex].tbInfo
    local tbCardList = {}
    local nType, nNumber = tbCardInfo.nType, tbCardInfo.nNumber
    for nIndex = 1, nCardMaxNum do
        local tbCard = {}
        local tbImgInfo = tbInfo[nIndex]
        local bShow = true
        local szImgPosName = tbImgInfo and tbImgInfo.szImgPosName or nil
        if tbImgInfo and tbCardInfo.nMark == PLAYER_OPERATE_PENG then bShow = tbImgInfo.bShow end
        tbCard.bShow = bShow

        if szImgPosName then
            local tbImage = MahjongData.GetMahjongTileInfo(szImgPosName, nType, nNumber)
            local szImagePath =  MahjongData.GetCardImg(tbImage.szIconPath, tbImage.nIconFrame)
            tbCard.szImage = szImagePath
        else
            tbCard.szImage = MahjongData.GetBackCardImg(nUIDirection)
        end
        table.insert(tbCardList, tbCard)
    end
    local parent = self.tbComboLayout[nUIDirection]
    if not self.tbPongKongInfo then self.tbPongKongInfo = {} end
    if not self.tbPongKongInfo[nUIDirection] then self.tbPongKongInfo[nUIDirection] = {} end
    local scriptView = UIHelper.AddPrefab(nPreferbID, parent, tbCardList, nUIDirection)
    UIHelper.LayoutDoLayout(parent)

    table.insert(self.tbPongKongInfo[nUIDirection], {nModeIndex = nModeIndex, tbCardInfo = tbCardInfo, scriptView = scriptView})
end

------------------------------------------------------------更新玩家碰杠牌区的牌 End-----------------------------------------

-------------------------------------------------------------显示流水  Start------------------------------------------------

function UIPanelMahjongMainView:UpdateBill()

    local bShow = UIHelper.GetVisible(self.WidgetBill)
    UIHelper.SetVisible(self.WidgetBill, not bShow)
    if bShow then return end

    local tbOwnBillData = MahjongData.GetCashFlowData()[MahjongData.GetPlayerDataDirection()]
    local nGrade = MahjongData.GetThisGameGrade(tbOwnBillData)
    local szGrade = nGrade >= 0 and FormatString("+<D0>", nGrade) or FormatString("<D0>", nGrade)

    UIHelper.SetString(self.TextMyname, szGrade)
    UIHelper.LayoutDoLayout(self.LayoutMyMoney)

    UIHelper.RemoveAllChildren(self.ScrollViewMyInfoTotal)
    for key, tbBill in pairs(tbOwnBillData) do
        UIHelper.AddPrefab(PREFAB_ID.WidgetMyInfoTotal, self.ScrollViewMyInfoTotal, tbBill)
    end

    UIHelper.ScrollViewDoLayoutAndToTop(self.ScrollViewMyInfoTotal)

end

-------------------------------------------------------------显示流水  End------------------------------------------------

-------------------------------------------------------------托管状态 Start --------------------------------------------
function UIPanelMahjongMainView:UpdateAgent()
    local bAgent = MahjongData.GetAgentState(MahjongData.GetPlayerDataDirection())
    UIHelper.SetSelected(self.ToggleTrusteeship, bAgent, false)
    UIHelper.SetTouchEnabled(self.ToggleTrusteeship, MahjongData.GetGameStart())
end

-------------------------------------------------------------托管状态 End-------------------------------------------------

-------------------------------------------------------------牌数 Start---------------------------------------------------

function UIPanelMahjongMainView:UpdateSurplusNum()
    local nDealCardNum = MahjongData.GetGameData("nDealCardNum")
    UIHelper.SetString(self.TextSurplus, nAllCardNum - nDealCardNum)
end

function UIPanelMahjongMainView:UpdateSurplusState()
    local bGameStart = MahjongData.GetGameStart()
    UIHelper.SetVisible(self.WidgetSurplus, bGameStart)
end

-------------------------------------------------------------牌数 End---------------------------------------------------

-------------------------------------------------------------胡牌 Start---------------------------------------------------
function UIPanelMahjongMainView:UpdateWinCards()
    self.tbHuScript = {}
    for szDataDirection, nDataDirection in pairs(tDirectionType) do

        local tbWins = MahjongData.GetPlayerWinsCardInfoByDirection(nDataDirection)
        local nUIDirection = MahjongData.ConvertDataDirectionToUIDirection(nDataDirection)
        UIHelper.RemoveAllChildren(self.tbHuLayout[nUIDirection])
        self.tbHuScript[nDataDirection] = {}

        for index, tbCardInfo in pairs(tbWins) do
            self:AddWinCard(tbCardInfo, nDataDirection)
        end
    end
end


function UIPanelMahjongMainView:AddWinCard(tbCardInfo, nDataDirection)
    local nUIDirection = MahjongData.ConvertDataDirectionToUIDirection(nDataDirection)
    local nPreferb = (nUIDirection ~= tUIPosIndex.Up and nUIDirection ~= tUIPosIndex.Down) and PREFAB_ID.WidgetLeftRightOpen or PREFAB_ID.WidgetUpOpen
    local parent = self.tbHuLayout[nUIDirection]
    local scriptView = UIHelper.AddPrefab(nPreferb, parent, tbCardInfo, nUIDirection)
    UIHelper.LayoutDoLayout(parent)
    if not self.tbHuScript then self.tbHuScript = {} end
    if not self.tbHuScript[nDataDirection] then self.tbHuScript[nDataDirection] = {} end
    table.insert(self.tbHuScript[nDataDirection], scriptView)
end

-------------------------------------------------------------胡牌 End---------------------------------------------------

--------------------------------------------------------------换牌tip Start-----------------------------------------------

function UIPanelMahjongMainView:UpdateSwapCardTip(bShow)
    UIHelper.SetVisible(self.WidgetChange, bShow)
end


--------------------------------------------------------------换牌tip End-----------------------------------------------

--------------------------------------------------------------换牌转盘相关 Start-----------------------------------------------

function UIPanelMahjongMainView:UpdateExchangeOrder(bShow)
    UIHelper.SetVisible(self.WidgetExchangeOrder, bShow)
    local nDieDot = MahjongData.GetGameData("nDieDot2")
    local nOrderIndex = 1
    --骰子点数 1、2顺时针 3、4对换 5、6逆时针 order
	if nDieDot == 1 or nDieDot == 2 then
		nOrderIndex = 3
	elseif nDieDot == 3 or nDieDot == 4 then
		nOrderIndex = 2
	elseif nDieDot == 5 or nDieDot == 6 then
		nOrderIndex = 1
	end 

    for nIndex, widgetOrder in ipairs(self.tbOrderType) do
        UIHelper.SetVisible(widgetOrder, nOrderIndex == nIndex)
    end

end

--------------------------------------------------------------换牌转盘相关 End-----------------------------------------------

--------------------------------------------------------------加减金额等一些特效 Start-------------------------------------------------

function UIPanelMahjongMainView:UpdateWidgetAddNumber(nDataDirection, nAddNumber, nTitle)
    local nUIDirection = MahjongData.ConvertDataDirectionToUIDirection(nDataDirection)
    if not self.tbScriptAddNumer then self.tbScriptAddNumer = {} end
    local scriptView = self.tbScriptAddNumer[nUIDirection]
    local tbInfo = {}
    tbInfo.nAddNumber = nAddNumber
    tbInfo.nUIDirection = nUIDirection
    if not scriptView then
        self.tbScriptAddNumer[nUIDirection] = UIHelper.AddPrefab(PREFAB_ID.WidgetAddNumber, self.tbAddNumberWidget[nUIDirection], tbInfo)
    else
        scriptView:OnEnter(tbInfo)
    end
end

function UIPanelMahjongMainView:PlayEffects(nDataDirection, szSFXType)

    local nUIDirection = MahjongData.ConvertDataDirectionToUIDirection(nDataDirection)
    local szDirection = MahjongData.ConvertUIDirectionToStringDataDirection(nUIDirection)
    local szSFXName = "Ani"..szDirection..tbSFXName[szSFXType]
    UIHelper.SetVisible(self[szSFXName], true)
    UIHelper.PlaySFX(self[szSFXName])
end
--------------------------------------------------------------加减金额等一些特效  End---------------------------------------------------

return UIPanelMahjongMainView
