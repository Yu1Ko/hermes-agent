local UIWidgetMonopolyCardList = class("UIWidgetMonopolyCardList")

local CARD_UNSELECTED_Y = 0
local CARD_SELECTED_Y   = 20

function UIWidgetMonopolyCardList:OnEnter()
    if not self.bInit then
        self:RegEvent()
        self:BindUIEvent()
        self.bInit = true
    end

    self:InitData()
    self:UpdateInfo()
end

function UIWidgetMonopolyCardList:OnExit()
    self.bInit = false
    self:UnRegEvent()
end

function UIWidgetMonopolyCardList:BindUIEvent()
    
end

function UIWidgetMonopolyCardList:RegEvent()
    Event.Reg(self, EventType.OnMonopolyOperateDownCountDown, function ()
        
    end)
end

function UIWidgetMonopolyCardList:UnRegEvent()
    --Event.UnReg(self, EventType.XXX)
end


-- ----------------------------------------------------------
-- Please write your own code below  ↓↓↓
-- ----------------------------------------------------------
function UIWidgetMonopolyCardList:InitData()
    self.nPlayerIndex    = MonopolyData.GetClientPlayerIndex() or 0
    self.nSelectedCardID = 0  -- 当前选中的手牌ID，0表示未选中

    self:GetHandCard()
end

function UIWidgetMonopolyCardList:GetHandCard()
    self.tHandCards = DFW_GetPlayerHandCard(self.nPlayerIndex) or {}
end

function UIWidgetMonopolyCardList:SetSelectedCard(nSelectedCardID)
    self.nSelectedCardID = nSelectedCardID or 0
end

function UIWidgetMonopolyCardList:IsCardSelected(nCardID)
    return self.nSelectedCardID ~= 0 and self.nSelectedCardID == nCardID
end

function UIWidgetMonopolyCardList:SetName(szName)
    if not self.scriptName then return end

    self.scriptName:SetName(szName)
end

function UIWidgetMonopolyCardList:UpdateInfo()
    self:GetHandCard()

    -- 选中牌若已不在手牌中，则重置为未选中
    if self.nSelectedCardID and self.nSelectedCardID ~= 0 then
        local bFound = false
        for _, nCardID in ipairs(self.tHandCards) do
            if nCardID == self.nSelectedCardID then
                bFound = true
                break
            end
        end
        if not bFound then
            self.nSelectedCardID = 0
        end
    end

    self:UpdateHeadInfo()
    self:UpdateCardList()
end

function UIWidgetMonopolyCardList:UpdateHeadInfo()
    self.scriptName = self.scriptName or UIHelper.AddPrefab(PREFAB_ID.WidgetPlayerName_Color, self.WidgetPlayerName)
    
    MonopolyData.SetPlayerBaseInfo(self, self.nPlayerIndex)
end

function UIWidgetMonopolyCardList:BuildCardItem(scriptCard, tCardInfo)
    -- 可用性
    UIHelper.SetVisible(scriptCard.BtnBuy, false)
    UIHelper.SetVisible(scriptCard.ImgNone, false)
    UIHelper.SetVisible(scriptCard.TogCard, true)
    -- 卡牌图片 VK_TODO
    -- UIHelper.SetSpriteFrame(scriptCard.ImgCardIcon, "")

    -- 卡牌名称
    local szName = UIHelper.GBKToUTF8(tCardInfo.szName)
    UIHelper.SetString(scriptCard.LabelCardTitle, szName)

    -- 是否锁定
    UIHelper.SetVisible(scriptCard.ImgNotAvailable, tCardInfo.bNeedUnlock == 1)
    UIHelper.SetVisible(scriptCard.ImgCost, false)

    scriptCard:SetSelectedCallback(function()
        local nCardID = scriptCard.nCardID
        if not nCardID then return end
        if not self:EnableOperation() then return end

        if self.nSelectedCardID == nCardID then
            -- 再次点击同一张牌：取消选中
            self:SetSelectedCard(0)
            MonopolyData.SendServerOperate(MINI_GAME_OPERATE_TYPE.SERVER_OPERATE, DFW_OPERATE_UP_ACTION_CANCELCARD, nCardID)
        else
            -- 选中一张牌
            self.SetSelectedCard(nCardID)
            MonopolyData.SendServerOperate(MINI_GAME_OPERATE_TYPE.SERVER_OPERATE, DFW_OPERATE_UP_ACTION_SELECTCARD, nCardID)
        end

        self:OnUpdateCardState(scriptCard)
    end)
end

function UIWidgetMonopolyCardList:BuildEmptyItem(scriptCard)
    UIHelper.SetVisible(scriptCard.BtnBuy, false)
    UIHelper.SetVisible(scriptCard.ImgNone, true)
    UIHelper.SetVisible(scriptCard.TogCard, false)
end

function UIWidgetMonopolyCardList:UpdateCardList()
    self.tScriptCards = {}
    UIHelper.RemoveAllChildren(self.LayoutCard)
    for i = 1, DFW_PLAYERCARD_INITNUM do
        local nCardID   = self.tHandCards[i]
        local scriptCard = UIHelper.AddPrefab(PREFAB_ID.WidgetCard, self.LayoutCard)
        if scriptCard then
            local tCardInfo = nCardID and Table_GetMonopolyCardInfoByID(nCardID)
            scriptCard.nCardID = nCardID
            if tCardInfo and nCardID ~= 0 then
                self:BuildCardItem(scriptCard, tCardInfo)
            else
                self:BuildEmptyItem(scriptCard)
            end
            self:OnUpdateCardState(scriptCard)
            self.tScriptCards[nCardID] = scriptCard
        end
    end

    UIHelper.CascadeDoLayoutDoWidget(self._rootNode, true, true)
end

function UIWidgetMonopolyCardList:SetCardRelY(scriptCard, nY)
    UIHelper.SetPositionY(scriptCard.TogCard, nY)
end

function UIWidgetMonopolyCardList:OnUpdateCardState(scriptCard)
    if not scriptCard then
        return
    end

    local nCardID = scriptCard.nCardID
    local bSelected = self:IsCardSelected(nCardID)

    if bSelected then
        self:SetCardRelY(scriptCard, CARD_SELECTED_Y)
    else
        self:SetCardRelY(scriptCard, CARD_UNSELECTED_Y)
    end
end

function UIWidgetMonopolyCardList:UpdateSelectCard(nCardID)
    if nCardID == nil then
        nCardID = arg4
    end

    self.SetSelectedCard(nCardID)

    for _, scriptCard in pairs(self.tScriptCards) do
        self:OnUpdateCardState(scriptCard)
    end

    -- VK_TODO：根据卡牌信息中的 bShowRemove 决定是否打开 MonopolyRemoveObstacles
    if nCardID ~= 0 then
        local tCardInfo = Table_GetMonopolyCardInfoByID(nCardID)
        if tCardInfo and tCardInfo.bShowRemove then
            --MonopolyRemoveObstacles.Open(nCardID)
        else
            --MonopolyRemoveObstacles.Close()
        end
    else
        --MonopolyRemoveObstacles.Close()
    end
end

function UIWidgetMonopolyCardList:EnableOperation()
    local nState = MonopolyData.GetGameState()
    if DFW_CONST_TABLE_STATE_ACTION == nState and MonopolyData.IsMyRound() then
        return true
    end

    return false
end

function UIWidgetMonopolyCardList:GetSelectedCardID()
    return self.nSelectedCardID or 0
end

return UIWidgetMonopolyCardList