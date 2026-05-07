local UIWidgetRichmanPlayer = class("UIWidgetRichmanPlayer")

local EXCHANGE_CD_TIME = 15000 -- 交换按钮 CD 时间 15 秒（毫秒）

local tRankingToImg = {
    [1] = "UIAtlas2_FengYunLu_Rank_icon_ranking01.png",
    [2] = "UIAtlas2_FengYunLu_Rank_icon_ranking02.png",
    [3] = "UIAtlas2_FengYunLu_Rank_icon_ranking03.png",
    [4] = "UIAtlas2_FengYunLu_Rank_Img_Title.png",
}
function UIWidgetRichmanPlayer:OnEnter()
    if not self.bInit then
        self:RegEvent()
        self:BindUIEvent()
        self.bInit = true
    end

    self:Init()
    self:UpdateInfo()
end

function UIWidgetRichmanPlayer:OnExit()
    self.bInit = false
    self:UnRegEvent()
end

function UIWidgetRichmanPlayer:BindUIEvent()
    UIHelper.BindUIEvent(self.BtnSwitch, EventType.OnClick, function ()
        local nCurrentTime = GetTickCount()
        if nCurrentTime - MonopolyData.m_nLastExchangeLaunchTime < EXCHANGE_CD_TIME then
            return -- 还在CD中
        end
        MonopolyData.m_nLastExchangeLaunchTime = nCurrentTime
        
        MonopolyData.SendServerOperate(MINI_GAME_OPERATE_TYPE.SERVER_OPERATE, DFW_OPERATE_UP_PREPARE_EXCHANGELAUNCH, self.nDfwIndex)
    end)

    UIHelper.BindUIEvent(self.BtnPreBuff, EventType.OnClick, function ()
        -- TODO:接入BuffTips
    end)

    UIHelper.BindUIEvent(self.BtnMainBuff, EventType.OnClick, function ()
        -- TODO:接入BuffTips
    end)
end

function UIWidgetRichmanPlayer:RegEvent()
    Event.Reg(self, "PLAYER_ENTER_SCENE", function(dwPlayerID)
        self:UpdateInfo()
    end)
end

function UIWidgetRichmanPlayer:UnRegEvent()
    Event.UnRegAll(self)
end

function UIWidgetRichmanPlayer:Init()
    
end

-- ----------------------------------------------------------
-- Please write your own code below  ↓↓↓
-- ----------------------------------------------------------
function UIWidgetRichmanPlayer:UpdateInfo()
    self:Refresh()
end

function UIWidgetRichmanPlayer:SetGameState(tIdentityInfo)
    if DFW_GetTableState() == DFW_CONST_TABLE_STATE_PREPARE then
        -- 准备阶段
        UIHelper.SetVisible(self.ImgRank, false)
        UIHelper.SetVisible(self.WidgetState_Inside, false)
        UIHelper.SetVisible(self.WidgetBuff_Outside, true)

        local nMyDfwIndex = MonopolyData.GetClientPlayerIndex()
        local bIsSelfRow = (nMyDfwIndex and nMyDfwIndex > 0 and self.nDfwIndex == nMyDfwIndex)
        
        -- 获取自己是否已准备
        local bAmIReady = false
        if nMyDfwIndex and nMyDfwIndex > 0 then
            bAmIReady = (DFW_GetPlayerReadyIndex(nMyDfwIndex) == 1)
        end

        if DFW_GetPlayerReadyIndex(self.nDfwIndex) == 1 then
            -- 目标玩家已准备
            UIHelper.SetVisible(self.WidgetReady, true)
            UIHelper.SetVisible(self.BtnSwitch, false)
        else
            -- 目标玩家未准备
            UIHelper.SetVisible(self.WidgetReady, false)
            -- 如果是自己这一行，或者自己已经准备了，则隐藏交换按钮
            UIHelper.SetVisible(self.BtnSwitch, not bIsSelfRow and not bAmIReady)
        end

        local szBuffName = UIHelper.GBKToUTF8(tIdentityInfo.szName)

        UIHelper.SetVisible(self.WidgetBuff_Outside, true)
        UIHelper.SetItemIconByIconID(self.ImgPreBuffIcon, tIdentityInfo.nIconID)
        UIHelper.SetString(self.LabelPreBuffName, szBuffName)
    else
        -- 游戏阶段
        UIHelper.SetVisible(self.ImgRank, true)
        UIHelper.SetVisible(self.WidgetState_Inside, true)
        UIHelper.SetVisible(self.WidgetBuff_Outside, false)
        UIHelper.SetVisible(self.WidgetReady, false)
        UIHelper.SetItemIconByIconID(self.ImgMainBuffIcon, tIdentityInfo.nIconID)
    end
end

-- 本座位指定 MonopolyStatusConfig.nID 的状态：1神仙 2行动 3入院或入狱；返回：是否拥有(Status==1)、剩余回合数(无效为0)
function UIWidgetRichmanPlayer:GetMonopolyStatusByID(nStatusType)
    local nDfwIndex = self.nDfwIndex
    
    -- -- 测试数据
    -- if nStatusID == 1 or nStatusID == 3 then
    --     return true, nStatusID
    -- end

    local nStatusVal = 0
    local nLeftRaw = nil
    
    if nStatusType == 1 then
        nStatusVal = DFW_GetPlayerGodStatus(nDfwIndex)
        nLeftRaw = DFW_GetPlayerGodLeftTime(nDfwIndex)
    elseif nStatusType == 2 then
        nStatusVal = DFW_GetPlayerMoveStatus(nDfwIndex)
        nLeftRaw = DFW_GetPlayerMoveLeftTime(nDfwIndex)
    elseif nStatusType == 3 then
        nStatusVal = DFW_GetPlayerHospitalStatus(nDfwIndex)
        nLeftRaw = DFW_GetPlayerHospitalLeftTime(nDfwIndex)
    else
        return false, 0
    end
    local bHas = (nStatusVal > 0)
    local nLeftRounds = 0
    if type(nLeftRaw) == "number" and nLeftRaw >= 0 then
        nLeftRounds = nLeftRaw
    end
    return bHas, nLeftRounds, nStatusVal
end

-- 本座位三类状态格：MonopolyStatusConfig nID 1/2/3 对应 1神仙 2行动 3入院或入狱
function UIWidgetRichmanPlayer:RefreshNormalBuffs()
    self.tMainBuffList = {}
    UIHelper.RemoveAllChildren(self.LayoutMainBuff)
    for i = 1, 3, 1 do
        self.tMainBuffList[i] = self.tMainBuffList[i] or UIHelper.AddPrefab(PREFAB_ID.WidgetMainCityBuff, self.LayoutMainBuff)
        local script = self.tMainBuffList[i]
        local bHasBuff, nRounds, nID = self:GetMonopolyStatusByID(i)
        local tRowBuff = nil
        if bHasBuff then
            tRowBuff = Table_GetMonopolyStatusConfigByTypeID(i, nID)
        end
        if bHasBuff and tRowBuff then
            UIHelper.SetItemIconByIconID(script.ImgBuffIcon, tRowBuff.nIconID)
            UIHelper.SetString(script.LabelBuffLevel, nRounds)

            UIHelper.SetVisible(script.ImgBuffIcon, true)
        else
            UIHelper.SetVisible(script.ImgBuffIcon, false)
        end
        UIHelper.SetVisible(script.ImgBuffMark, false)
        UIHelper.SetVisible(script.LabelBuffLevel, true)
    end
end

-- 公共接口，判断本机是否正在交换申请 CD 中
function UIWidgetRichmanPlayer:IsExchangeCDRunning()
    local nCurrentTime = GetTickCount()
    return (nCurrentTime - MonopolyData.m_nLastExchangeLaunchTime) < EXCHANGE_CD_TIME
end

-- 界面心跳：负责驱动本玩家专属的各提示动画播放
function UIWidgetRichmanPlayer:OnFrameBreathe()
    -- 刷新交换按钮 CD 状态
    local bBtnSwitchVisable = UIHelper.GetVisible(self.BtnSwitch)
    if bBtnSwitchVisable then
        local nCurrentTime = GetTickCount()
        local nPassedTime = nCurrentTime - MonopolyData.m_nLastExchangeLaunchTime
        if nPassedTime < EXCHANGE_CD_TIME then
            UIHelper.SetButtonState(self.BtnSwitch, BTN_STATE.Disable, g_tStrings.STR_HAVE_CD, true)

            local nLeftSeconds = math.ceil((EXCHANGE_CD_TIME - nPassedTime) / 1000)
            UIHelper.SetString(self.LabelSwitchCD, nLeftSeconds)
        else
            UIHelper.SetButtonState(self.BtnSwitch, BTN_STATE.Normal)
        end
    end
end

-- 刷新金币和排名
function UIWidgetRichmanPlayer:RefreshMoneyAndRank()
    local nDfwIndex = self.nDfwIndex

    local dwPlayerID = DFW_GetPlayerDWID(nDfwIndex)
    if not dwPlayerID or dwPlayerID == 0 then
        return
    end

    local szMoney = tostring(DFW_GetPlayerMoney(nDfwIndex))
    UIHelper.SetString(self.LabelMoney, szMoney)

    local nRank = MonopolyData.GetPlayerMoneyRankByDfwIndex(nDfwIndex)
    local szIcon = tRankingToImg[nRank]
    UIHelper.SetString(self.ImgRank, szIcon)
end

function UIWidgetRichmanPlayer:Refresh()
    local nDfwIndex = self.nDfwIndex
    local nClientPlayerIndex = MonopolyData.GetClientPlayerIndex()

    local dwPlayerID = DFW_GetPlayerDWID(nDfwIndex)
    if not dwPlayerID or dwPlayerID == 0 then
        LOG("[PlayerView:Refresh] dwPlayerID is nil or 0, nDfwIndex=" .. tostring(nDfwIndex))
        return
    end

    local tIdentityInfo = MonopolyData.GetIdentityInfoByDfwIndex(nDfwIndex)
    if not tIdentityInfo then
        LOG("[PlayerView:Refresh] dwPlayerID is nil or 0, nDfwIndex=" .. tostring(nDfwIndex))
        return
    end

    MonopolyData.SetPlayerBaseInfo(self, nDfwIndex)

    -- 金币和排名
    self:RefreshMoneyAndRank()

    local szPoints = tostring(DFW_GetPlayerPointNum(nDfwIndex))
    UIHelper.SetString(self.LabelPoints, szPoints)

    self:SetGameState(tIdentityInfo)
    self:RefreshNormalBuffs()
    UIHelper.SetString(self.LabelCardNum, 1) -- TODO: 显示卡牌数量

    UIHelper.SetVisible(self.ImgMine, nDfwIndex == nClientPlayerIndex)
end

function UIWidgetRichmanPlayer:SetName(szName)
    UIHelper.SetString(self.LabelPlayerName, szName)
end

return UIWidgetRichmanPlayer