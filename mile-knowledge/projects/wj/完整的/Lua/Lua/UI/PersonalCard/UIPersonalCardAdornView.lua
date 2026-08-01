-- ---------------------------------------------------------------------------------
-- Author: Unknown
-- Name: UIPersonalCardAdornView
-- Date: 2024-02-02 16:29:38
-- Desc: ?
-- ---------------------------------------------------------------------------------

local UIPersonalCardAdornView = class("UIPersonalCardAdornView")

local nTogIndex2Decoration = {
    SHOW_CARD_DECORATION_TYPE.DECAL,
    SHOW_CARD_DECORATION_TYPE.SFX,
    SHOW_CARD_DECORATION_TYPE.FRAME,
}

local nTogIndex2PrefabID = {
    PREFAB_ID.WidgetAdornAppliqueCell,
    PREFAB_ID.WidgetAdornEffectCell,
    PREFAB_ID.WidgetAdornAppliqueCell,
}

local PIXEL_LIMIT = {602, 800} -- nWidth, nHeight
local SIZE_LIMIT = 2 * 1024 * 1024 -- MB
local tFittingCellIndex2UILayer = {
    [1] = 6,
    [2] = 5,
    [3] = 4,
    [4] = 3,
    [5] = 2,
    [6] = 1,
}

local nDecalMaxNum = 1
local nSFXMaxNum = 3
local MAX_LAYER = 6

-- local tInfo = {
--     bUseImage = true/false, -- true：不上传
--                             -- false:有picTexture & pImage, 用UIHelper.SetTextureWithBlur, 上传
--     picTexture = "xxx",
--     pImage = "xxx"
-- }
function UIPersonalCardAdornView:OnEnter(tInfo, nIndex)
    if not self.bInit then
        self:RegEvent()
        self:BindUIEvent()
        self.bInit = true
    end

    if tInfo then
        self.bUseImage = tInfo.bUseImage
        self.pRetTexture = tInfo.picTexture
        self.pImage = tInfo.pImage
    end

    self.nIndex = nIndex or 0
    self.bFilterHave = false -- 默认显示未解锁
    self.tDecorationPresetLogic = g_pClientPlayer.GetShowCardDecorationPreset(self.nIndex)
    -- local tDecorationPreset = g_pClientPlayer.GetAllShowCardDecorationPreset()

    self:InitUIPage()
    self:InitUIData()
    self:UpdateInfo()
end

function UIPersonalCardAdornView:OnExit()
    self.bInit = false
    Timer.DelAllTimer(self)
    self:UnRegEvent()
end

function UIPersonalCardAdornView:BindUIEvent()
    UIHelper.BindUIEvent(self.BtnClose, EventType.OnClick, function ()
        UIMgr.Close(self)
    end)

    for nIndex, v in ipairs(self.tbTog) do
        UIHelper.BindUIEvent(v, EventType.OnSelectChanged, function (_, bSelected)
            if bSelected then
                self.nTogSelIndex = nIndex

                local tDecoration = self:SelDecorationTab()
                if tDecoration then
                    self.bFilterHave = tDecoration.bAllUnlock
                    UIHelper.SetSelected(self.tbUnlockToggle[1], not tDecoration.bAllUnlock, false)
                    UIHelper.SetSelected(self.tbUnlockToggle[2], tDecoration.bAllUnlock, false)
                end
                self:UpdateInfo()
            end
        end)
    end

    for nIndex, v in ipairs(self.tbUnlockToggle) do
        UIHelper.BindUIEvent(v, EventType.OnSelectChanged, function (_, bSelected)
            if bSelected then
                self.bFilterHave = nIndex == 2
                self:UpdateInfo()
            end
        end)
    end

    --重新裁剪（保留装饰数据）
    UIHelper.BindUIEvent(self.BtnCropping, EventType.OnClick, function ()
        PersonalCardData.tDecorationPresetDataUI = clone(self.tDecorationPresetDataUI)
        UIMgr.Close(self)
    end)

    --重新拍摄
    UIHelper.BindUIEvent(self.BtnRevert, EventType.OnClick, function ()
        PersonalCardData.tDecorationPresetDataUI = clone(self.tDecorationPresetDataUI)
        UIMgr.Close(self)
        UIMgr.Close(VIEW_ID.PanelPersonalCardCropping)
    end)

    --重置
    UIHelper.BindUIEvent(self.BtnReset, EventType.OnClick, function ()
        UIHelper.ShowConfirm(g_tStrings.STR_SHOW_CARD_RESET, function ()
            self:InitUIData()
            self:UpdateInfo()
        end)
    end)

    --保存形象
    UIHelper.BindUIEvent(self.BtnSave, EventType.OnClick, function ()
        self:SetShowCardDecoration()
    end)

    --解锁
    UIHelper.BindUIEvent(self.BtnUnlock, EventType.OnClick, function ()
        self:BuyUnlockItem()
    end)

    UIHelper.BindUIEvent(self.TogEye, EventType.OnSelectChanged, function (_, bSelected)
        if self.tPersonalCard then
            self.tPersonalCard:HideAllDate(not bSelected)
        end
    end)
end

function UIPersonalCardAdornView:RegEvent()
    Event.Reg(self, "COIN_SHOP_BUY_RESPOND", function ()
        self:UpdateInfo()
    end)

    Event.Reg(self, PersonalCardData.Event.SelfUpdate, function ()
        UIMgr.Close(self)
        UIMgr.Close(VIEW_ID.PanelPersonalCardCropping)

        TipsHelper.ShowImportantYellowTip(g_tStrings.STR_SHOW_CARD_UPLOAD_SUCCESS, nil, 5)

        rlcmd(string.format("enable avoid fliter type %d %d", ACTOR_FLITER_TYPE.ACTOR_FLITER_TYPE_SCREEN_SHOOT, 0))

        local nViewID = VIEW_ID.PanelCamera
        UIMgr.Close(nViewID)
    end)

    Event.Reg(self, PersonalCardData.Event.SelfUpdateFailed, function (dwImageIndex)
        local tip = FormatString(g_tStrings.STR_SHOW_CARD_UPLOAD_FAILED, dwImageIndex + 1)
        TipsHelper.ShowNormalTip(tip)
    end)

    Event.Reg(self, "SYNC_REWARDS", function ()
        local nRewards = CoinShopData.GetRewards()
        self.RewardsScript:SetLableCount(nRewards)
    end)

    Event.Reg(self, "FACE_LIFT_VOUCHERS_CHANGE", function ()
        local nRewards = CoinShopData.GetRewards()
        self.RewardsScript:SetLableCount(nRewards)
    end)

    Event.Reg(self, "ON_COIN_SHOP_VOUCHER_CHANGED", function ()
        local nRewards = CoinShopData.GetRewards()
        self.RewardsScript:SetLableCount(nRewards)
    end)

    Event.Reg(self, "ON_CHANGE_SHOW_CARD_DECORATION_NOTIFY", function ()
        local wID = arg0
        if arg1 == SHOW_CARD_DECORATION_METHOD.ADD then
            local tInfo = Table_GetPersonalCardInfoByID(wID)
            if not tInfo then
                return
            end
            local nDecorationType = tInfo.nDecorationType
            local nSelType = nTogIndex2Decoration[self.nTogSelIndex]
            if nSelType == nDecorationType then
                UIHelper.SetSelected(self.tbUnlockToggle[2], true)
            end
        end
    end)

    Event.Reg(self, EventType.HideAllHoverTips, function ()
        for _, v in pairs(self.tPersonalCardAttachmentScript) do
            self:ChangeZoomRotateMode(v, false)
        end
    end)
end

function UIPersonalCardAdornView:UnRegEvent()
    --Event.UnReg(self, EventType.XXX)
end






-- ----------------------------------------------------------
-- Please write your own code below  ↓↓↓
-- ----------------------------------------------------------

-- 初始化ui界面
function UIPersonalCardAdornView:InitUIPage()
    self.RewardsScript = UIMgr.AddPrefab(PREFAB_ID.WidgetOtherCurrency, self.WidgetCurrency)
    self.RewardsScript:SetCurrencyType(CurrencyType.StorePoint)
    local nRewards = CoinShopData.GetRewards()
    self.RewardsScript:SetLableCount(nRewards)
    UIMgr.AddPrefab(PREFAB_ID.WidgetCoin, self.WidgetCurrency, CurrencyType.Coin, false, nil, true)
    UIHelper.LayoutDoLayout(self.WidgetCurrency)

    self.tPersonalCard = UIHelper.AddPrefab(PREFAB_ID.WidgetPersonalCard, self.WidgetPersonalCard, nil, {bDecoration = true})
    self.tPersonalCard:SetPlayerId(g_pClientPlayer.dwID)
    UIHelper.SetVisible(self.tPersonalCard.BtnPersonalCardNew, false)
    if self.pRetTexture then
        UIHelper.SetTextureWithBlur(self.tPersonalCard.tbWidgetAllAttachment[1], self.pRetTexture)
    end
    self.tPersonalCard:SetTouchEnabled(false)

    self.tPersonalCardAttachmentScript = {}

    self.bFittingScript = {}
    for i = 1, MAX_LAYER, 1 do
        local tScript = UIHelper.AddPrefab(PREFAB_ID.WidgetFittingCell, self.ScrollViewFitting)
        if tScript then
            UIHelper.BindUIEvent(tScript.BtnDisboard, EventType.OnClick, function ()
                self.tDecorationPresetDataUI[tFittingCellIndex2UILayer[i]] = nil
                self:UpdateShowPage()
            end)

            UIHelper.BindUIEvent(tScript.BtnRenovate, EventType.OnClick, function ()
                local tDecorationPresetDataUI = PersonalCardData.LogicLayer2UILayer(self.tDecorationPresetLogic)
                self.tDecorationPresetDataUI[tFittingCellIndex2UILayer[i]] = tDecorationPresetDataUI[tFittingCellIndex2UILayer[i]]
                self:UpdateShowPage()
            end)

            UIHelper.BindUIEvent(tScript.BtnUp, EventType.OnClick, function ()
                if i > 2 and i <= 6 then
                    self:MoveFitting(tFittingCellIndex2UILayer[i], tFittingCellIndex2UILayer[i] + 1)
                    self:UpdateShowPage()
                end
            end)

            UIHelper.BindUIEvent(tScript.BtnDown, EventType.OnClick, function ()
                if i >= 2 and i < 5 then
                    self:MoveFitting(tFittingCellIndex2UILayer[i], tFittingCellIndex2UILayer[i] - 1)
                    self:UpdateShowPage()
                end
            end)

            UIHelper.BindUIEvent(tScript.TogFitting, EventType.OnClick, function ()
                if self.tPersonalCardAttachmentScript[tFittingCellIndex2UILayer[i]] then
                    if UIHelper.GetSelected(tScript.TogFitting) then
                        UIHelper.SetSelected(self.tPersonalCardAttachmentScript[tFittingCellIndex2UILayer[i]].WidgetZoom, true)
                    end
                else
                    self:ClearSelected()
                    TipsHelper.ShowNormalTip(g_tStrings.STR_SHOW_CARD_CELL_EMPTY)
                end
            end)

            UIHelper.BindUIEvent(tScript.WidgetItem, EventType.OnClick, function ()
                self:OnClickDecorationItem(i, tScript.WidgetItem._rootNode)
            end)

            UIHelper.BindUIEvent(tScript.BtnBuy, EventType.OnClick, function ()
                self:OnClickBuyItem(i, tScript.WidgetItem._rootNode)
            end)

            if i == MAX_LAYER then
                UIHelper.SetSpriteFrame(tScript.ImgItem, "UIAtlas2_MainCity_SystemMenu_IconSysteam8.png")
            end
            UIHelper.SetTouchEnabled(tScript.TogFitting, i ~= MAX_LAYER and i ~= 1)

            table.insert(self.bFittingScript, tScript)
        end
    end

    UIHelper.ScrollViewDoLayoutAndToTop(self.ScrollViewFitting)

    UIHelper.SetVisible(self.BtnCropping, not self.bUseImage)
    UIHelper.SetVisible(self.BtnRevert, not self.bUseImage)
    UIHelper.LayoutDoLayout(self.LayoutBtn)
end

local fnSort = function (tLeft, tRight)
    if tLeft.dwDecorationID == 0 then
        return true
    end

    if tRight.dwDecorationID == 0 then
        return false
    end

    if tLeft.bIsHave and tRight.bIsHave then
        return tLeft.dwDecorationID > tRight.dwDecorationID
    end

    if tLeft.bIsHave then
        return true
    end

    if tRight.bIsHave then
        return false
    end

    if tLeft.nSource ~= tRight.nSource then
        return tLeft.nSource < tRight.nSource
    end

    return tLeft.dwDecorationID > tRight.dwDecorationID
end

--初始化ui数据
function UIPersonalCardAdornView:InitUIData()
    self.tDecal = {}
    self.tSFX = {}
    self.tFrame = {}
    self.nTogSelIndex = self.nTogSelIndex or 1

    self:GetTypeList(self.tDecal, SHOW_CARD_DECORATION_TYPE.DECAL, self.bFilterHave)
    self:GetTypeList(self.tSFX, SHOW_CARD_DECORATION_TYPE.SFX, self.bFilterHave)
    self:GetTypeList(self.tFrame, SHOW_CARD_DECORATION_TYPE.FRAME, self.bFilterHave)

    --初始化右边列的层级
    self.tDecorationLayer = {
        [1] = SHOW_CARD_DECORATION_TYPE.PLAYER,
        [6] = SHOW_CARD_DECORATION_TYPE.FRAME
    }

    table.sort(self.tDecal, fnSort)
    table.sort(self.tSFX, fnSort)
    table.sort(self.tFrame, fnSort)

    local tDecoration = self:SelDecorationTab()
    if tDecoration then
        self.bFilterHave = tDecoration.bAllUnlock
        UIHelper.SetSelected(self.tbUnlockToggle[1], not tDecoration.bAllUnlock, false)
        UIHelper.SetSelected(self.tbUnlockToggle[2], tDecoration.bAllUnlock, false)
    end

    self:LogicDateLayer2UIData()
end

function UIPersonalCardAdornView:UpdatePersonalCardTab()
    self.tDecal = {}
    self.tSFX = {}
    self.tFrame = {}

    self:GetTypeList(self.tDecal, SHOW_CARD_DECORATION_TYPE.DECAL, self.bFilterHave)
    self:GetTypeList(self.tSFX, SHOW_CARD_DECORATION_TYPE.SFX, self.bFilterHave)
    self:GetTypeList(self.tFrame, SHOW_CARD_DECORATION_TYPE.FRAME, self.bFilterHave)

    table.sort(self.tDecal, fnSort)
    table.sort(self.tSFX, fnSort)
    table.sort(self.tFrame, fnSort)
end

function UIPersonalCardAdornView:GetTypeList(tInfo, nDecorationType, bFilterHave)
    local tPersonalCard = Table_GetPersonalCardTab()
    local nTime = GetCurrentTime()

    local bAllUnlock = true -- 是否已全部解锁
    for _, v in ipairs(tPersonalCard) do
        if v.nDecorationType == nDecorationType then
            if v.dwDecorationID then
                local bIsHave = v.dwDecorationID == 0 or g_pClientPlayer.IsHaveShowCardDecoration(v.dwDecorationID)
                v.bIsHave = bIsHave
                if bIsHave == bFilterHave then
                    if bIsHave then
                        table.insert(tInfo, v)
                    elseif v.nSource == PERSONAL_CARD_SOURCE.COIN_SHOP and not bIsHave then
                        local tShopInfo = GetRewardsShop().GetRewardsShopInfo(v.dwLogicID)
                        local nEndTime = CoinShop_GetEndTime(tShopInfo)
                        if nEndTime == -1 or nTime < nEndTime then
                            v.nEndTime = nEndTime
                            table.insert(tInfo, v)
                        end
                    elseif v.bShowWhenNotGot then
                        table.insert(tInfo, v)
                    end
                end

                if not bIsHave then
                    if v.nSource == PERSONAL_CARD_SOURCE.COIN_SHOP then
                        if v.nEndTime then
                            bAllUnlock = false
                        end
                    elseif v.bShowWhenNotGot then
                        bAllUnlock = false
                    end
                end
            end
        end
    end
    tInfo.bAllUnlock = bAllUnlock
end

-- 逻辑数据转化成ui数据和ui层级数据
function UIPersonalCardAdornView:LogicDateLayer2UIData()
    if table_is_empty(PersonalCardData.tDecorationPresetDataUI) then
        self.tDecorationPresetDataUI = PersonalCardData.LogicLayer2UILayer(self.tDecorationPresetLogic)
    else
        self.tDecorationPresetDataUI = clone(PersonalCardData.tDecorationPresetDataUI)
        PersonalCardData.tDecorationPresetDataUI = {}
    end

    --装饰数量
    local tDecorationNum = {
        [SHOW_CARD_DECORATION_TYPE.DECAL] = 0,
        [SHOW_CARD_DECORATION_TYPE.SFX] = 0,
    }

    for _, v in ipairs(self.tDecorationPresetLogic) do
        if v.nDecorationType ~= SHOW_CARD_DECORATION_TYPE.BACK_GROUND and
        v.nDecorationType ~= SHOW_CARD_DECORATION_TYPE.FRAME then
            self.tDecorationLayer[v.byLayer] = v.nDecorationType
            tDecorationNum[v.nDecorationType] = tDecorationNum[v.nDecorationType] + 1
        end
    end

    for i = 1, MAX_LAYER, 1 do
        if not self.tDecorationLayer[i] then
            if tDecorationNum[SHOW_CARD_DECORATION_TYPE.DECAL] + tDecorationNum[SHOW_CARD_DECORATION_TYPE.SFX] < nDecalMaxNum + nSFXMaxNum then
                self.tDecorationLayer[i] = SHOW_CARD_DECORATION_TYPE.DECAL
                tDecorationNum[SHOW_CARD_DECORATION_TYPE.DECAL] = tDecorationNum[SHOW_CARD_DECORATION_TYPE.DECAL] + 1
            end
        end
    end
end

function UIPersonalCardAdornView:MoveFitting(nIndex1, nIndex2)
    local nDecorationType = self.tDecorationLayer[nIndex1]
    local tDecorationPresetDataUI = clone(self.tDecorationPresetDataUI[nIndex1])

    self.tDecorationLayer[nIndex1] = self.tDecorationLayer[nIndex2]
    self.tDecorationLayer[nIndex2] = nDecorationType
    self.tDecorationPresetDataUI[nIndex1] = self.tDecorationPresetDataUI[nIndex2]
    self.tDecorationPresetDataUI[nIndex2] = tDecorationPresetDataUI

    if self.tDecorationPresetDataUI[nIndex1] then
        self.tDecorationPresetDataUI[nIndex1].byLayer = nIndex1
    end
    if self.tDecorationPresetDataUI[nIndex2] then
        self.tDecorationPresetDataUI[nIndex2].byLayer = nIndex2
    end
end

function UIPersonalCardAdornView:UpdateInfo()
    self:UpdatePersonalCardTab()
    self:UpdateShowPage()
end

--更新左边的列表
function UIPersonalCardAdornView:UpdateDecorationTab()
    local bEmpty = true
    UIHelper.RemoveAllChildren(self.ScrollViewAdorn)

    local tDecoration = self:SelDecorationTab()
    for _, v in ipairs(tDecoration) do
        bEmpty = false
        local tCellScript = UIHelper.AddPrefab(nTogIndex2PrefabID[self.nTogSelIndex], self.ScrollViewAdorn)
        if tCellScript then
            local bHave = v.dwDecorationID == 0 or g_pClientPlayer.IsHaveShowCardDecoration(v.dwDecorationID)
            UIHelper.SetVisible(tCellScript.BtnLock, not bHave)
            UIHelper.SetVisible(tCellScript.WidgetPrice, not bHave or v.dwDecorationID == 0)

            UIHelper.SetVisible(tCellScript.LabelExplain, v.dwDecorationID == 0)

            --通宝购买
            UIHelper.SetVisible(tCellScript.LayoutPrice, v.nSource == PERSONAL_CARD_SOURCE.SHOP)
            if v.nSource == PERSONAL_CARD_SOURCE.SHOP then
                local hPriceInfoBase = GetShowCardDecorationSettings().GetPriceInfo(v.dwDecorationID)
                local nPrice = hPriceInfoBase and self:GetPrice(hPriceInfoBase) or 0
                UIHelper.SetString(tCellScript.LabelPrice, nPrice)
            end

            --商城购买
            UIHelper.SetVisible(tCellScript.LabelExplain01, v.nSource == PERSONAL_CARD_SOURCE.COIN_SHOP)
            UIHelper.SetVisible(tCellScript.ImgLimitedTime, v.nSource == PERSONAL_CARD_SOURCE.COIN_SHOP)

            --其他途径解锁
            UIHelper.SetVisible(tCellScript.LabelExplain02, v.nSource == PERSONAL_CARD_SOURCE.OTHER)

            UIHelper.SetTexture(tCellScript.ImgRoleCard, v.szVKSmallPath)

            local nSelectedCount = self:SetTogSelected(v)
            UIHelper.SetSelected(tCellScript.TogAdornBg, nSelectedCount > 0)
            UIHelper.SetVisible(tCellScript.WidgetChooseNum, nSelectedCount > 0)
            UIHelper.SetString(tCellScript.LabelChooseNum, nSelectedCount)

            UIHelper.BindUIEvent(tCellScript.TogAdornBg, EventType.OnClick, function ()
                self:SetDecoration(v)
                if v.nDecorationType == SHOW_CARD_DECORATION_TYPE.FRAME and not UIHelper.GetSelected(self.TogEye) then
                    UIHelper.SetSelected(self.TogEye, true)
                end
            end)
        end
    end

    UIHelper.ScrollViewDoLayoutAndToTop(self.ScrollViewAdorn)
    UIHelper.SetVisible(self.WidgetEmpty, bEmpty)
    UIHelper.SetString(self.LabelEmpty, self.bFilterHave and "暂无已解锁的装饰" or "暂无未解锁的装饰")
end

function UIPersonalCardAdornView:SetTogSelected(v)
    local nSelectedCount = 0
    for nIndex = 1, MAX_LAYER, 1 do
        if self.tDecorationPresetDataUI[nIndex] then
            if v.dwDecorationID == self.tDecorationPresetDataUI[nIndex].wID then
                nSelectedCount = nSelectedCount + 1
            end
        end
    end

    return nSelectedCount
end

function UIPersonalCardAdornView:SelDecorationTab()
    local nDecorationType = nTogIndex2Decoration[self.nTogSelIndex]

    if nDecorationType == SHOW_CARD_DECORATION_TYPE.DECAL then
        return self.tDecal
    elseif nDecorationType == SHOW_CARD_DECORATION_TYPE.SFX then
        return self.tSFX
    elseif nDecorationType == SHOW_CARD_DECORATION_TYPE.FRAME then
        return self.tFrame
    end

    return {}
end

function UIPersonalCardAdornView:GetPrice(tInfo)
    local ePayType = COIN_SHOP_PAY_TYPE.COIN
    local eTimeLimitType = COIN_SHOP_TIME_LIMIT_TYPE.PERMANENT
    local tThePrice = tInfo.tPrice[ePayType][eTimeLimitType]
    local nPrice = tThePrice.nPrice

    return nPrice, tThePrice
end

--设置数据
function UIPersonalCardAdornView:SetDecoration(tData)
    local nDecorationType = nTogIndex2Decoration[self.nTogSelIndex]
    local bFull = true

    if nDecorationType == SHOW_CARD_DECORATION_TYPE.SFX or
    nDecorationType == SHOW_CARD_DECORATION_TYPE.DECAL then
        for i = #self.tDecorationLayer, 1, -1 do
            if self.tDecorationLayer[i] == SHOW_CARD_DECORATION_TYPE.DECAL or
            self.tDecorationLayer[i] == SHOW_CARD_DECORATION_TYPE.SFX  then
                if not self.tDecorationPresetDataUI[i] then
                    self.tDecorationLayer[i] = nDecorationType
                    self:SetDecorationData(i, tData)
                    self.nSelectLayer = i
                    bFull = false
                    break
                end
            end
        end
        if bFull then
            TipsHelper.ShowNormalTip(g_tStrings.STR_SHOW_CARD_SFX_MAX)

            if tData.nSource == PERSONAL_CARD_SOURCE.COIN_SHOP then
                -- 商城解锁且未收集显示Tips指引跳转
                local dwDecorationID = tData.dwDecorationID
                local bHave = dwDecorationID == 0 and true or g_pClientPlayer.IsHaveShowCardDecoration(dwDecorationID)
                if not bHave then
                    local tips, tipsView = TipsHelper.ShowNodeHoverTips(PREFAB_ID.WidgetItemTip, self.ScrollViewAdorn)
                    if tipsView then
                        tipsView:OnInitPersonalDecoration(dwDecorationID)
                        tipsView:SetBtnState({})
                    end
                end
            end
        end
    elseif nDecorationType == SHOW_CARD_DECORATION_TYPE.FRAME then
        self:SetDecorationData(MAX_LAYER, tData)
    end

    self:UpdateShowPage()
end

function UIPersonalCardAdornView:SetDecorationData(nLayer, tData)
    local fOffsetX, fOffsetY, fScale = 65, 95, 1
    if self.tDecorationPresetDataUI[nLayer] then
        fOffsetX, fOffsetY, fScale = self.tDecorationPresetDataUI[nLayer].fOffsetX, self.tDecorationPresetDataUI[nLayer].fOffsetY, self.tDecorationPresetDataUI[nLayer].fScale
    elseif tData.nDecorationType == SHOW_CARD_DECORATION_TYPE.FRAME then
        fOffsetX, fOffsetY, fScale = 0, 0, 1
    end

    self.tDecorationPresetDataUI[nLayer] = {
        ["wID"] = tData.dwDecorationID, ["fOffsetX"] = fOffsetX, ["fOffsetY"] = fOffsetY, ["fScale"] = fScale, ["byLayer"] = nLayer, ["byRotation"] = 0,
    }
end

function UIPersonalCardAdornView:UpdateShowPage()
    self:UpdateDecorationTab()
    self:UpdateDecorationPreset()
    self:UpdateShowCard()
    self:UpdateBtnState()
end

-- 更新右边的列表
function UIPersonalCardAdornView:UpdateDecorationPreset()
    for nIndex = 1, MAX_LAYER, 1 do
        local tScript = self.bFittingScript[tFittingCellIndex2UILayer[nIndex]]
        if tScript then
            if self.tDecorationPresetDataUI[nIndex] then
                local tData = Table_GetPersonalCardByDecorationID(self.tDecorationPresetDataUI[nIndex].wID)

                --加载现有的装饰物
                if self.tDecorationLayer[nIndex] == SHOW_CARD_DECORATION_TYPE.FRAME then
                    local tDecorationPresetDataUI = PersonalCardData.LogicLayer2UILayer(self.tDecorationPresetLogic)
                    UIHelper.SetVisible(tScript.BtnRenovate, not IsTableEqual(self.tDecorationPresetDataUI[nIndex], tDecorationPresetDataUI[nIndex]))
                elseif self.tDecorationLayer[nIndex] == SHOW_CARD_DECORATION_TYPE.DECAL or
                    self.tDecorationLayer[nIndex] == SHOW_CARD_DECORATION_TYPE.SFX then
                    UIHelper.SetVisible(tScript.BtnDisboard, true)
                end

                UIHelper.SetTexture(tScript.ImgItem, tData.szVKSmallPath)

                local bHave = self.tDecorationPresetDataUI[nIndex].wID == 0 or g_pClientPlayer.IsHaveShowCardDecoration(self.tDecorationPresetDataUI[nIndex].wID)

                if tData.nSource == PERSONAL_CARD_SOURCE.SHOP then
                    local hPriceInfoBase = GetShowCardDecorationSettings().GetPriceInfo(self.tDecorationPresetDataUI[nIndex].wID)
                    local nPrice, tPrice = self:GetPrice(hPriceInfoBase)
                    UIHelper.SetString(tScript.LabelMoney_Jin, nPrice)
                end

                UIHelper.SetVisible(tScript.BtnBuy,  not bHave and tData.nSource == PERSONAL_CARD_SOURCE.COIN_SHOP)
                UIHelper.SetVisible(tScript.WidgetMoney, not bHave and tData.nSource == PERSONAL_CARD_SOURCE.SHOP)
                UIHelper.SetVisible(tScript.Widgetother, not bHave and tData.nSource == PERSONAL_CARD_SOURCE.OTHER)
                UIHelper.SetVisible(tScript.WidgetLock, not bHave)
                Timer.AddFrame(self, 1, function ()
                    UIHelper.LayoutDoLayout(tScript.LayoutCurrency)
                end)
                UIHelper.SetVisible(tScript.LabelNone, false)
                UIHelper.SetVisible(tScript.WidgetArrow, self.tDecorationLayer[nIndex] ~= SHOW_CARD_DECORATION_TYPE.FRAME and self.tDecorationLayer[nIndex] ~= SHOW_CARD_DECORATION_TYPE.PLAYER)
                UIHelper.SetString(tScript.LabelTitleName, g_tStrings.STR_SHOW_CARD_DECORATION[self.tDecorationLayer[nIndex]])
            else
                UIHelper.ClearTexture(tScript.ImgItem)
                UIHelper.SetVisible(tScript.WidgetLock, false)
                UIHelper.SetVisible(tScript.LabelLock, false)
                UIHelper.SetVisible(tScript.WidgetMoney, false)
                UIHelper.SetVisible(tScript.Widgetother, false)
                UIHelper.SetVisible(tScript.BtnBuy, false)
                UIHelper.SetVisible(tScript.BtnDisboard, false)
                UIHelper.SetVisible(tScript.BtnRenovate, false)
                UIHelper.SetVisible(tScript.LabelNone, true)
                UIHelper.SetVisible(tScript.WidgetArrow, false)
                UIHelper.SetString(tScript.LabelTitleName, g_tStrings.STR_SHOW_CARD_DECORATION_NORMAL[self.tDecorationLayer[nIndex]])
            end

            UIHelper.SetVisible(tScript.ImgUp01, nIndex >= 2 and nIndex < 5)
            UIHelper.SetVisible(tScript.ImgDown01, nIndex > 2 and nIndex <= 5)
            UIHelper.SetVisible(tScript.ImgUp, not (nIndex >= 2 and nIndex < 5))
            UIHelper.SetVisible(tScript.ImgDown, not (nIndex > 2 and nIndex <= 5))
        end
    end
end

--更新名片上的展示
function UIPersonalCardAdornView:UpdateShowCard()
    if not self.tPersonalCard then
        return
    end

    for i = 1, MAX_LAYER, 1 do
        if self.tDecorationPresetDataUI[i] then
            local tData = Table_GetPersonalCardByDecorationID(self.tDecorationPresetDataUI[i].wID)

            if self.tDecorationLayer[i] == SHOW_CARD_DECORATION_TYPE.FRAME then
                if tData.szVKPath and tData.szVKPath ~= "" then
                    UIHelper.SetVisible(self.tPersonalCard.tbWidgetAllAttachment[i], false)
                    UIHelper.SetVisible(self.tPersonalCard.ImgFrame_Special, true)
                    UIHelper.SetTexture(self.tPersonalCard.ImgFrame_Special, tData.szVKPath)
                else
                    UIHelper.SetVisible(self.tPersonalCard.tbWidgetAllAttachment[i], true)
                    UIHelper.SetVisible(self.tPersonalCard.ImgFrame_Special, false)
                end
                
                self.tPersonalCard:SetPersonalFrame(tData.szVKSmallPath)
            elseif self.tDecorationLayer[i] == SHOW_CARD_DECORATION_TYPE.SFX or
            self.tDecorationLayer[i] == SHOW_CARD_DECORATION_TYPE.DECAL then
                UIHelper.RemoveAllChildren(self.tPersonalCard.tbWidgetAllAttachment[i])
                local Zoom = UIHelper.AddPrefab(PREFAB_ID.WidgetZoom, self.tPersonalCard.tbWidgetAllAttachment[i])

                if Zoom then
                    UIHelper.SetScale(Zoom._rootNode, self.tDecorationPresetDataUI[i].fScale, self.tDecorationPresetDataUI[i].fScale)
                    local fOffsetX, fOffsetY = self:DXOffsetTranslate2VK(i, Zoom._rootNode)
                    UIHelper.SetPosition(Zoom._rootNode, fOffsetX, fOffsetY)

                    if self.tDecorationLayer[i] == SHOW_CARD_DECORATION_TYPE.DECAL then
                        UIHelper.SetTexture(Zoom.ImgZoomBg, tData.szVKPath)
                    else
                        UIHelper.SetSFXPath(Zoom.sfxBg, tData.szSFX, true)
                    end

                    self:UpdateRotation(Zoom, self.tDecorationPresetDataUI[i].byRotation or 0)
                    UIHelper.SetVisible(Zoom.BtnRotate, true)

                    UIHelper.SetTouchDownHideTips(Zoom.BtnRotate, false)
                    UIHelper.SetTouchDownHideTips(Zoom.BtnReset, false)
                    UIHelper.SetTouchDownHideTips(Zoom.BtnRotateAntiwise, false) -- 逆时针
                    UIHelper.SetTouchDownHideTips(Zoom.BtnRotateClockwise, false) -- 顺时针
                    UIHelper.BindUIEvent(Zoom.BtnRotate, EventType.OnClick, function (_, x, y)
                        self:ChangeZoomRotateMode(Zoom, true)
                    end)

                    UIHelper.BindUIEvent(Zoom.BtnReset, EventType.OnClick, function ()
                        self:UpdateRotation(Zoom, 0)
                    end)

                    UIHelper.BindUIEvent(Zoom.BtnRotateAntiwise, EventType.OnTouchBegan, function ()
                        self:StartRotateTimer(Zoom, i, -1)
                    end)
                    
                    UIHelper.BindUIEvent(Zoom.BtnRotateAntiwise, EventType.OnTouchEnded, function ()
                        self:StopRotateTimer()
                    end)
                    
                    UIHelper.BindUIEvent(Zoom.BtnRotateAntiwise, EventType.OnTouchCanceled, function ()
                        self:StopRotateTimer()
                    end)

                    UIHelper.BindUIEvent(Zoom.BtnRotateClockwise, EventType.OnTouchBegan, function ()
                        self:StartRotateTimer(Zoom, i, 1)
                    end)
                    
                    UIHelper.BindUIEvent(Zoom.BtnRotateClockwise, EventType.OnTouchEnded, function ()
                        self:StopRotateTimer()
                    end)
                    
                    UIHelper.BindUIEvent(Zoom.BtnRotateClockwise, EventType.OnTouchCanceled, function ()
                        self:StopRotateTimer()
                    end)

                    UIHelper.BindUIEvent(Zoom.BtnScale, EventType.OnTouchMoved, function (_, x, y)
                        local fLocalX, flocalY = UIHelper.ConvertToNodeSpace(self.tPersonalCard.tbWidgetAllAttachment[1], x, y)
                        local nLocalX, nlocalY = UIHelper.GetPosition(Zoom._rootNode)

                        local nWidth = UIHelper.GetWidth(Zoom._rootNode)
                        local fScaleX = (fLocalX - nLocalX)/(nWidth)
                        local fScaleY = (nlocalY - flocalY)/(nWidth)

                        self:CheckScaleRange(fScaleX, fScaleY, i, Zoom._rootNode)
                    end)

                    UIHelper.BindUIEvent(Zoom.BtnFrame, EventType.OnTouchBegan, function (_, x, y)
                        local fLocalX, flocalY = UIHelper.ConvertToNodeSpace(self.tPersonalCard.tbWidgetAllAttachment[1], x, y)
                        local nX, nY = UIHelper.GetPosition(Zoom._rootNode)
                        self.offsetX = nX - fLocalX
                        self.offsetY = nY - flocalY
                        self:ChangeZoomRotateMode(Zoom, false)
                    end)

                    UIHelper.BindUIEvent(Zoom.BtnFrame, EventType.OnTouchMoved, function (_, x, y)
                        local fLocalX, flocalY = UIHelper.ConvertToNodeSpace(self.tPersonalCard.tbWidgetAllAttachment[1], x, y)
                        local fDXOffsetX, fDXOffsetY = self:VKOffsetTranslate2DX(fLocalX + self.offsetX, flocalY + self.offsetY, i, Zoom._rootNode)
                        self:CheckOffsetRange(fDXOffsetX, fDXOffsetY, i, Zoom._rootNode)
                    end)

                    UIHelper.BindUIEvent(Zoom.WidgetZoom, EventType.OnSelectChanged, function (_, bSelected)
                        if bSelected then
                            UIHelper.SetSelected(self.bFittingScript[tFittingCellIndex2UILayer[i]].TogFitting, true)
                        end
                        self:ChangeZoomRotateMode(Zoom, false)
                    end)

                    if self.nSelectLayer == i then
                        self.nSelectLayer = nil
                        Timer.AddFrame(self, 1, function()
                            UIHelper.SetSelected(Zoom.WidgetZoom, true)
                        end)
                    end

                    self.tPersonalCardAttachmentScript[i] = Zoom
                end
            end
        else
            if self.tDecorationLayer[i] == SHOW_CARD_DECORATION_TYPE.FRAME then
                UIHelper.ClearTexture(self.tPersonalCard.tbWidgetAllAttachment[i])
                self.tPersonalCard:SetPersonalFrame()
            else
                UIHelper.RemoveAllChildren(self.tPersonalCard.tbWidgetAllAttachment[i])
                self.tPersonalCardAttachmentScript[i] = nil
            end
        end
    end

    self:ClearSelected()
end

function UIPersonalCardAdornView:UpdateRotation(Zoom, byRotation)
    local nRotation = byRotation * 360 / 255
    for index, node in ipairs(Zoom.tbRotateNode) do
        UIHelper.SetRotation(node, nRotation)
    end
    UIHelper.Set2DRotation(Zoom.sfxBg, -nRotation * math.pi / 180)
end

function UIPersonalCardAdornView:StartRotateTimer(Zoom, i, nDirection)
    self:StopRotateTimer()

    local function _fnDoRotate()
        local nCurrentRotation = self.tDecorationPresetDataUI[i].byRotation
        local nTargetRotation = nCurrentRotation + nDirection

        if nTargetRotation < 0 then
            nTargetRotation = 255
        elseif nTargetRotation > 255 then
            nTargetRotation = 0
        end

        self:UpdateRotation(Zoom, nTargetRotation)
        self.tDecorationPresetDataUI[i].byRotation = nTargetRotation
    end

    -- 延迟0.2秒后开始旋转
    self.nTimerRef = Timer.Add(self, 0.2, function()
        -- 创建连续旋转定时器，每3帧旋转一次，约10次/秒
        self.nTimerRef = Timer.AddFrameCycle(self, 3, function()
            _fnDoRotate()
        end)
    end)

    _fnDoRotate()
end

function UIPersonalCardAdornView:StopRotateTimer()
    if self.nTimerRef then
        Timer.DelTimer(self, self.nTimerRef)
        self.nTimerRef = nil
    end
end

function UIPersonalCardAdornView:ClearSelected()
    for i = 1, MAX_LAYER, 1 do
        if self.tPersonalCardAttachmentScript[i] and UIHelper.GetSelected(self.tPersonalCardAttachmentScript[i].WidgetZoom) then
            UIHelper.SetSelected(self.tPersonalCardAttachmentScript[i].WidgetZoom, false)
        end
        if UIHelper.GetSelected(self.bFittingScript[i].TogFitting) then
            UIHelper.SetSelected(self.bFittingScript[i].TogFitting)
        end
    end
end

function UIPersonalCardAdornView:UpdateBtnState()
    local bHave = true
    local bLock = false
    for i = 1, MAX_LAYER, 1 do
        if self.tDecorationPresetDataUI[i] then
            local dwDecorationID = self.tDecorationPresetDataUI[i].wID
            if dwDecorationID ~= 0 and not g_pClientPlayer.IsHaveShowCardDecoration(dwDecorationID) then
                bHave = false
                local tData = Table_GetPersonalCardByDecorationID(dwDecorationID)
                if tData.nSource == PERSONAL_CARD_SOURCE.SHOP then
                    bLock = true
                end
            end
        end
    end

    UIHelper.SetVisible(self.BtnSave, bHave)
    UIHelper.SetVisible(self.BtnUnlock, not bHave)
    UIHelper.SetButtonState(self.BtnUnlock, bLock and BTN_STATE.Normal or BTN_STATE.Disable, g_tStrings.STR_SHOW_CARD_BTN_TIP)
end

function UIPersonalCardAdornView:SetShowCardDecoration()
    local tDataUI = {}
    for i = 1, MAX_LAYER, 1 do
        if self.tDecorationPresetDataUI[i] and self.tDecorationPresetDataUI[i].wID ~= 0 then
            table.insert(tDataUI, self.tDecorationPresetDataUI[i])
        end
    end

    local nResult = g_pClientPlayer.SetShowCardDecorationPreset(self.nIndex, tDataUI)
    if nResult ~= SHOW_CARD_DECORATION_ERROR_CODE.SUCCESS then
        TipsHelper.ShowImportantRedTip(g_tStrings.STR_PERSONAL_CARD_ERROR[nResult])
        return
    end

    FellowshipData.ApplyRoleEntryInfo({UI_GetClientPlayerGlobalID()})

    if self.pRetTexture and not self.bUseImage then
        self:UploadImageDataNotSave(self.pImage)
    else
        UIMgr.Close(self)
    end
end

function UIPersonalCardAdornView:UploadImageDataNotSave(pImage)
    local fnUpload = function (pData, nSize, funCallBack)
        local hManager = GetShowCardCacheManager()
        if hManager then
            hManager.CacheUploadImageDataForMobile(1, pData, nSize)
            hManager.UploadShowCardImage(self.nIndex)
            if funCallBack then
                funCallBack()
            end
        end
    end

    UIHelper.GetPngDataFromImage(function(pData, nSize)
        if nSize > SIZE_LIMIT then
            UIHelper.CompressImage(function (pCompressData)
                UIHelper.GetPngDataFromImage(function(pData, nSize)
                    fnUpload(pData, nSize, function ()
                        if safe_check(pImage) then
                            pImage:release()
                        end
                        if safe_check(pCompressData) then
                            pCompressData:release()
                        end
                    end)
                end, pCompressData)
            end, pImage, unpack(PIXEL_LIMIT))
        else
            fnUpload(pData, nSize, function ()
                if safe_check(pImage) then
                    pImage:release()
                end
            end)
        end
    end, pImage)
end

function UIPersonalCardAdornView:BuyUnlockItem(nIndex)
    local tBuy = {}

    for i = 1, MAX_LAYER, 1 do
        if self.tDecorationPresetDataUI[i] then
            local dwDecorationID = self.tDecorationPresetDataUI[i].wID
            local tData = Table_GetPersonalCardByDecorationID(dwDecorationID)
            if tData.nSource == PERSONAL_CARD_SOURCE.SHOP and not g_pClientPlayer.IsHaveShowCardDecoration(dwDecorationID) and self:IsNotHave(tBuy, dwDecorationID) then
                local hPriceInfoBase = GetShowCardDecorationSettings().GetPriceInfo(tData.dwDecorationID)
                local nPrice, tPrice = self:GetPrice(hPriceInfoBase)
                -- local nPrice = 0
                local tNewTable = {
                    eGoodsType = COIN_SHOP_GOODS_TYPE.SHOW_CARD_DECORATION,
                    dwGoodsID = dwDecorationID,
                    nDecorationType = tData.nDecorationType,
                    nPrice = nPrice,
                    nBuyCount = 1,
                    ePayType = COIN_SHOP_PAY_TYPE.COIN,
                    eTimeLimitType = COIN_SHOP_TIME_LIMIT_TYPE.PERMANENT,
                    nDiscount = tPrice.nDiscount,
                    nSubType = 1,
                    dwSetID = 1,
                    tBaseInfo = tData,
                }
                if not nIndex then
                    table.insert(tBuy, tNewTable)
                else
                    if i == nIndex then
                        table.insert(tBuy, tNewTable)
                    end
                end
            end
        end
    end

    UIMgr.Open(VIEW_ID.PanelPersonalAccounts, tBuy)
end

function UIPersonalCardAdornView:IsNotHave(tBuy, wID)
    for k, v in pairs(tBuy) do
        if v.dwGoodsID == wID then
            return false
        end
    end
    return true
end

function UIPersonalCardAdornView:DXOffsetTranslate2VK(i, node)
    local nWidgetWidth = UIHelper.GetWidth(self.tPersonalCard.tbWidgetAllAttachment[i])
    local nWidgetHeight = UIHelper.GetHeight(self.tPersonalCard.tbWidgetAllAttachment[i])

    return PersonalCardData.DXOffsetTranslate2VK(self.tDecorationPresetDataUI, i, nWidgetWidth, nWidgetHeight)
end


function UIPersonalCardAdornView:VKOffsetTranslate2DX(fOffsetX, fOffsetY, i, node, fVKScale)
    local fScale = fVKScale or self.tDecorationPresetDataUI[i].fScale

    local nWidgetWidth = UIHelper.GetWidth(self.tPersonalCard.tbWidgetAllAttachment[i])
    local nWidgetHeight = UIHelper.GetHeight(self.tPersonalCard.tbWidgetAllAttachment[i])
    local nWidth = UIHelper.GetWidth(node)
    local nHeight = UIHelper.GetHeight(node)

    local fDXOffsetX = (fOffsetX + nWidgetWidth / 2) / 2
    local fDXOffsetY = ((nWidgetHeight / 2) - fOffsetY) / 2

    return fDXOffsetX, fDXOffsetY
end

function UIPersonalCardAdornView:CheckScaleRange(fScaleX, fScaleY, i, node)
    local nDecorationType = self.tDecorationLayer[i]
    local tRange = GetShowCardDecorationSettings().GetRangeInfo(nDecorationType)

    local fScale = fScaleX > fScaleY and fScaleX or fScaleY
    fScale = fScale < tRange.MinScale and tRange.MinScale or fScale
    fScale = fScale > tRange.MaxScale and tRange.MaxScale or fScale

    self.tDecorationPresetDataUI[i].fScale = fScale
    UIHelper.SetScale(node, fScale, fScale)
end

function UIPersonalCardAdornView:CheckOffsetRange(fOffsetX, fOffsetY, i, node)
    local nDecorationType = self.tDecorationLayer[i]
    local tRange = GetShowCardDecorationSettings().GetRangeInfo(nDecorationType)

    if fOffsetX > tRange.MaxOffsetX then
        fOffsetX = tRange.MaxOffsetX
    elseif fOffsetX < tRange.MinOffsetX then
        fOffsetX = tRange.MinOffsetX
    end

    if fOffsetY > tRange.MaxOffsetY then
        fOffsetY = tRange.MaxOffsetY
    elseif fOffsetY < tRange.MinOffsetY then
        fOffsetY = tRange.MinOffsetY
    end

    self.tDecorationPresetDataUI[i].fOffsetX = fOffsetX
    self.tDecorationPresetDataUI[i].fOffsetY = fOffsetY

    local fVKOffsetX, fVKOffsetY = self:DXOffsetTranslate2VK(i, node)

    UIHelper.SetPosition(node, fVKOffsetX, fVKOffsetY)
end

function UIPersonalCardAdornView:OnClickDecorationItem(i, node)
    if self.tDecorationPresetDataUI[tFittingCellIndex2UILayer[i]] then
        local dwDecorationID = self.tDecorationPresetDataUI[tFittingCellIndex2UILayer[i]].wID
        local tips, tipsView = TipsHelper.ShowNodeHoverTips(PREFAB_ID.WidgetItemTip, node)
        if tipsView then
            tipsView:OnInitPersonalDecoration(dwDecorationID)
            local tData = Table_GetPersonalCardByDecorationID(dwDecorationID)
            local bHave = dwDecorationID == 0 and true or g_pClientPlayer.IsHaveShowCardDecoration(dwDecorationID)
            local tBtnList = {}
            if not bHave then
                if tData.nSource == PERSONAL_CARD_SOURCE.SHOP then
                    tBtnList = {{
                        szName = "购买",
                        OnClick = function ()
                            self:BuyUnlockItem(tFittingCellIndex2UILayer[i])
                        end
                    }}
                elseif tData.nSource == PERSONAL_CARD_SOURCE.COIN_SHOP then
                    tBtnList = {{
                        szName = "前往",
                        OnClick = function ()
                            --还没有这个类型，
                        end
                    }}
                end
            end
            tipsView:SetBtnState({})
        end
    end
end

function UIPersonalCardAdornView:OnClickBuyItem(i, node)
    if self.tDecorationPresetDataUI[tFittingCellIndex2UILayer[i]] then
        local dwDecorationID = self.tDecorationPresetDataUI[tFittingCellIndex2UILayer[i]].wID
        local tData = Table_GetPersonalCardByDecorationID(dwDecorationID)
        if tData.dwLogicID then
            local szLink = string.format("%d/%d", HOME_TYPE.REWARDS, tData.dwLogicID)
            CoinShopData.LinkGoods(szLink, true)
        end
    end
end

function UIPersonalCardAdornView:ChangeZoomRotateMode(scriptZoom, bEnter)
    UIHelper.SetVisible(scriptZoom.BtnRotate, not bEnter)
    UIHelper.SetVisible(scriptZoom.BtnScale, not bEnter)
    UIHelper.SetVisible(scriptZoom.BtnReset, bEnter)
    UIHelper.SetVisible(scriptZoom.LayoutRotate, bEnter)
end
return UIPersonalCardAdornView