-- ---------------------------------------------------------------------------------
-- Author: zeng zi peng
-- Name: UIDdzPokerPlayer
-- Date: 2023-08-10 19:45:48
-- Desc: 斗地主玩家（分为左右下）
-- ---------------------------------------------------------------------------------

local UIDdzPokerPlayer = class("UIDdzPokerPlayer")
local TIAN_LAIZI = 1
local DI_LAIZI = 2
local DEFAULT_LAIZI_COLOR = 0
local SFX_SHOW_NUM = 2

-- 每行最大显示牌张数量
local RowMaxShowCardCount = 10

local function IsEqual(tInfoA, tInfoB)
	if (not tInfoA) or (not tInfoB) then
		return false
	end
	return (tInfoA[1] == tInfoB[1] and tInfoA[1] > 0) or 
	(tInfoA[1] == tInfoB[1] and tInfoA[2] == tInfoB[2] and 
	tInfoA[3] == tInfoB[3]) 
end
function UIDdzPokerPlayer:OnEnter()
    if not self.bInit then
        self:RegEvent()
        self:BindUIEvent()
        self.bInit = true
    end
end

function UIDdzPokerPlayer:OnExit()
    self.bInit = false
    self:UnRegEvent()
end

function UIDdzPokerPlayer:BindUIEvent()
    
end

function UIDdzPokerPlayer:RegEvent()
    --Event.Reg(self, EventType.XXX, func)
end

function UIDdzPokerPlayer:UnRegEvent()
    --Event.UnReg(self, EventType.XXX)
end


function UIDdzPokerPlayer:SetDirection(szPlayerDirection)
    self.szPlayerDirection = szPlayerDirection
end

-- ----------------------------------------------------------
-- 更新手牌
-- ----------------------------------------------------------

function UIDdzPokerPlayer:UpdateHandCards()
    if self.szPlayerDirection == DdzPokerData.tPlayerDirection.Down then
        self:_UpdateDownPlayerHandCards()
    else
        self:_UpdateOtherPlayerHandCards()
    end
end

function UIDdzPokerPlayer:_UpdateDownPlayerHandCards()
    if not self.tbHandCards then
        self.tbHandCards = {}
        for i = 1, DdzPokerData.nOnePlayerMaxCardCount do
            table.insert(self.tbHandCards , UIHelper.AddPrefab(PREFAB_ID.WidgetHandcardDown , self.LayoutHandcard))
        end
    end
	local tPlayerData = DdzPokerData.DataModel.tGameData[self.szPlayerDirection]
	local tCards = tPlayerData.tCards.tUIData
    local cardDesc = "CardCount:"..table.get_len(tCards)
    for i, v in ipairs(self.tbHandCards) do
        v.bIsClicked = false
        v:SetVisible(tCards[i] ~= nil)
        if tCards[i] ~= nil then
            local tbCardInfo = {
                tbCards = tCards[i],
                bIsDizhu = DdzPokerData.DownIsDiZhu(),
                bIsMingPai = tPlayerData.bIsMingPai,
                bIsHosting = tPlayerData.bIsHosting,
            }

            v:ShowHandCard(tbCardInfo)
            local nNum = tCards[i][3]
            local nCoolor = (tCards[i][1] == TIAN_LAIZI or tCards[i][1] == DI_LAIZI) and DEFAULT_LAIZI_COLOR or tCards[i][2]

            cardDesc = string.format("%s;(%d)%s|%s|",cardDesc,i , tostring(nNum) , tostring(nCoolor))
        end
    end
    LOG.DEBUG("UpdateDownPlayerHandCards:%s",cardDesc)

    UIHelper.LayoutDoLayout(self.LayoutHandcard)
    UIHelper.SetVisible(self.LayoutHandcard ,true)
end

function UIDdzPokerPlayer:_UpdateOtherPlayerHandCards()
    if not self.tbHandCards then
        self.tbHandCards = {tbCardList = {} , tbShownList = {}}
        for i = 1, DdzPokerData.nOnePlayerMaxCardCount do
            table.insert(self.tbHandCards.tbCardList,UIHelper.AddPrefab(PREFAB_ID.WidgetHandcard , self.LayoutHandcard))
            table.insert(self.tbHandCards.tbShownList,UIHelper.AddPrefab(PREFAB_ID.WidgetHandcardDown , self.LayoutShown))
        end
        UIHelper.SetVisible(self.LayoutHandcard , false)
    end
    UIHelper.SetVisible(self.LayoutShown , false)
    UIHelper.SetVisible(self.LayoutHandcard , false)
    local tPlayerData = DdzPokerData.DataModel.tGameData[self.szPlayerDirection]
    local tCards = tPlayerData.tCards.tUIData
    if not tPlayerData.bIsMingPai and tPlayerData.tCards.nNum then
        UIHelper.SetVisible(self.LayoutHandcard , true)
        for i = 1, DdzPokerData.nOnePlayerMaxCardCount do
            self.tbHandCards.tbCardList[i]:SetVisible(i <= tPlayerData.tCards.nNum)
            self.tbHandCards.tbCardList[i]:ShowCardBack(DdzPokerData.GetPlayerBackbyDirection(self.szPlayerDirection))
        end
        UIHelper.LayoutDoLayout(self.LayoutHandcard)
    else
        UIHelper.SetVisible(self.LayoutShown , true)
        for i = 1, DdzPokerData.nOnePlayerMaxCardCount do
            self.tbHandCards.tbShownList[i]:SetVisible(i <= tPlayerData.tCards.nNum)
            if i <= tPlayerData.tCards.nNum then
                local tbCardInfo = 
                {
                    tbCards = tCards[i],
                    bIsDizhu = DdzPokerData.DataModel.nDiZhuIndex == tPlayerData.nIndex,
                    bIsMingPai = true,
                    bIsHosting = false,
                }
                self.tbHandCards.tbShownList[i]:ShowHandCard(tbCardInfo)
            end
        end
        if self.szPlayerDirection == DdzPokerData.tPlayerDirection.Right then
            self:UpdateRightCardsLayout(self.tbHandCards.tbShownList[1]._rootNode , tPlayerData.tCards.nNum , self.LayoutShown)
        end
        UIHelper.LayoutDoLayout(self.LayoutShown)
    end
end
-- ----------------------------------------------------------
-- 更新出牌
-- ----------------------------------------------------------
function UIDdzPokerPlayer:UpdatePassedCards()
    if not self.tbPassedCards then
        self.tbPassedCards = {}
        for i = 1, DdzPokerData.nOnePlayerMaxCardCount do
            table.insert(self.tbPassedCards , UIHelper.AddPrefab(PREFAB_ID.WidgetHandcardDown , self.LayoutPassed))
        end
    end
   
	local tPlayerData = DdzPokerData.DataModel.tGameData[self.szPlayerDirection]
	local tPassedCards = tPlayerData.tPassedCards.tUIData
    local cardDesc = "CardCount:"..table.get_len(tPassedCards)
    for i, v in ipairs(self.tbPassedCards) do
        v:SetVisible(tPassedCards[i] ~= nil)
        if tPassedCards[i] ~= nil then
            local tbCardInfo = 
            {
                tbCards = tPassedCards[i],
                bIsDizhu = DdzPokerData.DataModel.tGameData[self.szPlayerDirection].nIndex == DdzPokerData.DataModel.nDiZhuIndex,
                bIsMingPai = DDZ_GetPublicMingPaiState(tPlayerData.nIndex) > 0,
                bIsHosting = false,
            }
            v:ShowPassedCard(tbCardInfo)
            
            local nNum = tPassedCards[i][3]
            local nCoolor = (tPassedCards[i][1] == TIAN_LAIZI or tPassedCards[i][1] == DI_LAIZI) and DEFAULT_LAIZI_COLOR or tPassedCards[i][2]

            cardDesc = string.format("%s;(%d)%s|%s|",cardDesc,i , tostring(nNum) , tostring(nCoolor))
        end
    end
    LOG.DEBUG("UpdatePassedCards:%s,%s",self.szPlayerDirection , cardDesc)
    if self.szPlayerDirection == DdzPokerData.tPlayerDirection.Right then
        self:UpdateRightCardsLayout(self.tbPassedCards[1]._rootNode , #tPassedCards , self.LayoutPassed)
    end
    UIHelper.LayoutDoLayout(self.LayoutPassed)
end

-- ----------------------------------------------------------
-- 更新牌张数
-- ----------------------------------------------------------
function UIDdzPokerPlayer:UpdateCardNum()
    if self.LabelCardNum then
        local tCards = DdzPokerData.DataModel.tGameData[self.szPlayerDirection].tCards
        local nNum = tCards.nNum or #tCards.tUIData
        UIHelper.SetString(self.LabelCardNum , nNum)
        UIHelper.SetVisible(self.WidgetCardNum ,nNum > 0 and (not DdzPokerData.DataModel.tGameData[self.szPlayerDirection].bIsMingPai) )
		if nNum <= SFX_SHOW_NUM then
            -- 显示特效
        end
        if  DdzPokerData.DataModel.tGameData[self.szPlayerDirection].bLessCard then
            SoundMgr.PlaySound(SOUND.UI_SOUND , DdzPokerData.GetSoundPath("szLessCard"))
		end
    end
end
-- ----------------------------------------------------------
-- 更新右边玩家卡牌排序：Layout目前不支持节点增加层级显示
-- ----------------------------------------------------------
function UIDdzPokerPlayer:UpdateRightCardsLayout(itemCell , nNum , layout)
    nNum = math.min(nNum , RowMaxShowCardCount)
    local cellWidth = UIHelper.GetWidth(itemCell) 
    local layoutSpacingX = UIHelper.LayoutGetSpacingX(layout)
    local sumWidth = nNum * (cellWidth + layoutSpacingX) - layoutSpacingX
    UIHelper.SetWidth(layout , sumWidth)
end

-- ----------------------------------------------------------
-- 更新角色信息
-- 包含头像，欢乐豆
-- ----------------------------------------------------------
function UIDdzPokerPlayer:UpdatePlayerInfo()
    self:checkHeadPrefab()
    local tPlayer = DdzPokerData.DataModel.tGameData[self.szPlayerDirection]
    self.script_playerHeadInfo:UpdateHeadInfo(tPlayer)
end


function UIDdzPokerPlayer:UpdateMoney(nMoney)
    self.script_playerHeadInfo:UpdateMoney(nMoney)
end

function UIDdzPokerPlayer:UpdatePlayerState()
    self:checkHeadPrefab()
    local tPlayer = DdzPokerData.DataModel.tGameData[self.szPlayerDirection]
    self.script_playerHeadInfo:UpdatePlayerState(tPlayer , self.szPlayerDirection == DdzPokerData.tPlayerDirection.Down)
end

function UIDdzPokerPlayer:UpdateJiaBeiState()
    self:checkHeadPrefab()
    local tPlayer = DdzPokerData.DataModel.tGameData[self.szPlayerDirection]
    self.script_playerHeadInfo:UpdateJiaBeiState(tPlayer)
end

function UIDdzPokerPlayer:ShowDizhuPlayingTip(bShow)
    self:checkPlayingTip()
    local tPlayer = DdzPokerData.DataModel.tGameData[self.szPlayerDirection]
    bShow = bShow and (DdzPokerData.DataModel.nTableState == DDZ_CONST_TABLE_STATE_CALL_CHAIRMAN or DdzPokerData.DataModel.nTableState == DDZ_CONST_TABLE_STATE_SET_CHAIRMAN)
    self.script_playerTipInfo:ShowDizhuPlayingTip(bShow , tPlayer.nState)
end

function UIDdzPokerPlayer:ShowJiaBeiPlayingTip(bShow)
    self:checkPlayingTip()
    local tPlayer = DdzPokerData.DataModel.tGameData[self.szPlayerDirection]
    self.script_playerTipInfo:ShowJiaBeiPlayingTip(bShow , tPlayer.nDoubleType)
end

function UIDdzPokerPlayer:ShowYaoBuQiPlayingTip()
    self:checkPlayingTip()
    local tPlayer = DdzPokerData.DataModel.tGameData[self.szPlayerDirection]
    self.script_playerTipInfo:ShowYaoBuQiPlayingTip(tPlayer.bIsJump)
end

function UIDdzPokerPlayer:checkHeadPrefab()
    if not self.script_playerHeadInfo then
        if self.szPlayerDirection == DdzPokerData.tPlayerDirection.Down then
            self.script_playerHeadInfo = UIHelper.AddPrefab(PREFAB_ID.WidgetPokerPlayerDown , self.WidgetPokerPlayer , self.szPlayerDirection)
        else
            self.script_playerHeadInfo = UIHelper.AddPrefab(PREFAB_ID.WidgetPokerPlayer , self.WidgetPokerPlayer , self.szPlayerDirection)
        end
    end
end

function UIDdzPokerPlayer:checkPlayingTip()
    if not self.script_playerTipInfo then
        self.script_playerTipInfo = UIHelper.AddPrefab(PREFAB_ID.WidgetPlayingTips , self.WidgetPlayingTips)
    end
end

function UIDdzPokerPlayer:UpdateCardClick()
   for k, v in pairs(self.tbHandCards) do
        if v.bIsClicked then
            v:UpdateCardClick()
        end
   end
end

function UIDdzPokerPlayer:ThreeCardstoDown()
    local tCards = DdzPokerData.DataModel.tThreeCards.tUIData
	for k, v in pairs(self.tbHandCards) do
        if v:GetVisible() then
            local bIsEqual = false
            for j = 1, #tCards do
                if IsEqual(v.tCard, tCards[j]) then
                    bIsEqual = true
                    break
                end
            end
            if bIsEqual then
                if not v.bIsClicked then
                    v:UpdateCardClick()
                end
            else
                if v.bIsClicked then
                    v:UpdateCardClick()
                end
            end
        end
    end
end


function UIDdzPokerPlayer:UpdateDiZhuState(bIsDizhu)
    self.script_playerHeadInfo:UpdateDiZhuState(bIsDizhu)
end

function UIDdzPokerPlayer:GetChuPaiCrad()
    local tChuPaiCards = {}
    local tPlayerData = DdzPokerData.DataModel.tGameData[DdzPokerData.tPlayerDirection.Down]
	local tCards = tPlayerData.tCards.tUIData
    local szLog = ""
    for i, v in ipairs(self.tbHandCards) do
        if v:GetVisible() and v.bIsClicked then
            table.insert(tChuPaiCards, tCards[i])
        end
    end
    return tChuPaiCards
end

function UIDdzPokerPlayer:SetCardNum()
    local tPlayerData = DdzPokerData.DataModel.tGameData[self.szPlayerDirection]
    local nNum = tPlayerData.tCards.nNum or #tPlayerData.tCards.tUIData
    UIHelper.SetString(self.LabelCardNum , nNum)
end

function UIDdzPokerPlayer:UpdateTishi()
    local tPlayerData = DdzPokerData.DataModel.tGameData[self.szPlayerDirection]
    if tPlayerData.tUITipCards and table_is_empty(tPlayerData.tUITipCards) then
		return
	end
	if tPlayerData.nTipCount > #tPlayerData.tUITipCards then
		tPlayerData.nTipCount = tPlayerData.nTipCount - #tPlayerData.tUITipCards
	end
	local nCount = tPlayerData.nTipCount
	local tCards = tPlayerData.tUITipCards[nCount]
	local tTemp = tCards[1]
	local nPos = 1
    for k, v in pairs(self.tbHandCards) do
        if v:GetVisible() then
            if IsEqual(v.tCard, tTemp) then
                if not v.bIsClicked then
                    v:UpdateCardClick()
                end
                nPos = nPos + 1
                if nPos <= #tCards then
                    tTemp = tCards[nPos]
                else
                    tTemp = nil
                end
            else
                if v.bIsClicked then
                    v:UpdateCardClick()
                end
            end
        end
		
    end
	tPlayerData.nTipCount = tPlayerData.nTipCount + 1
end

function UIDdzPokerPlayer:UpdatePlayerHostingSfx()
    self:checkHeadPrefab()
    local tPlayerData = DdzPokerData.DataModel.tGameData[self.szPlayerDirection]
    self.script_playerHeadInfo:UpdatePlayerHostingSfx(tPlayerData.bIsHosting)
end

function UIDdzPokerPlayer:PlayCardTypeSfx(sfxCell)
    UIHelper.SetVisible(self[sfxCell] , true)
	UIHelper.PlaySFX(self[sfxCell])
end

function UIDdzPokerPlayer:PlayMingPaiSfx()
    local tPlayerData = DdzPokerData.DataModel.tGameData[self.szPlayerDirection]
    if tPlayerData.bShowMingPaiSfx then
        self:PlayCardTypeSfx("AniMP")
    else
        UIHelper.SetVisible(self["AniMP"] , false)
    end
    
end

function UIDdzPokerPlayer:HideHandCardState()
    UIHelper.SetVisible(self.LayoutHandcard ,false)
end

return UIDdzPokerPlayer