-- ---------------------------------------------------------------------------------
-- Author: Unknown
-- Name: UICoinShopOutfitItem
-- Date: 2022-12-15 16:39:05
-- Desc: ?
-- ---------------------------------------------------------------------------------

local TOUCH_THRESHOLD = 400

local IMG_PET_QUATITY_BG =
{
    "",
	"UIAtlas2_Shopping_ShoppingPet_img_card_green.png",
    "UIAtlas2_Shopping_ShoppingPet_img_card_blue.png",
    "UIAtlas2_Shopping_ShoppingPet_img_card_violet.png",
    "UIAtlas2_Shopping_ShoppingPet_img_card_orange.png",
}

local IMG_PET_QUATITY_LEVEL = {
    "",
    "UIAtlas2_Shopping_Shopping1_img_Tab_green.png",
    "UIAtlas2_Shopping_Shopping1_img_Tab_blue.png",
    "UIAtlas2_Shopping_Shopping1_img_Tab_violet.png",
    "UIAtlas2_Shopping_Shopping1_img_Tab_orange.png",
}

local IMG_PET_CLASS = {
    "UIAtlas2_Shopping_ShoppingPet_img_fish.png",
    "UIAtlas2_Shopping_ShoppingPet_img_birds.png",
    "UIAtlas2_Shopping_ShoppingPet_img_beast.png",
    "UIAtlas2_Shopping_ShoppingPet_img_property.png",
}

local UICoinShopOutfitItem = class("UICoinShopOutfitItem")

function UICoinShopOutfitItem:OnEnter()
    if not self.bInit then
        self:RegEvent()
        self:BindUIEvent()
        self.bInit = true
    end
end

function UICoinShopOutfitItem:OnExit()
    self.bInit = false
    self:UnRegEvent()
    Timer.DelAllTimer(self)

    if self.nDownloadDynamicID then
        PakDownloadMgr.ReleaseDynamicPakInfo(self.nDownloadDynamicID)
        self.nDownloadDynamicID = nil
    end
end

function UICoinShopOutfitItem:BindUIEvent()
    UIHelper.BindUIEvent(self.TogOutfitItem, EventType.OnTouchBegan, function(node, x, y)
        self.nTouchBeganX = x
        self.nTouchBeganY = y
    end)


    UIHelper.BindUIEvent(self.TogOutfitItem, EventType.OnTouchEnded, function (node, x, y)
        if not self.nTouchBeganX or not self.nTouchBeganY then
            return
        end
        local dx = x - self.nTouchBeganX
		local dy = y - self.nTouchBeganY
		local dx2 = dx * dx
		local dy2 = dy * dy
		if dx2 + dy2 > TOUCH_THRESHOLD then
            return
        end

        if self.tbGoods then
            local dwGoodsID = self.tbGoods.dwGoodsID
            local eGoodsType = self.tbGoods.eGoodsType
            local bSet = self.tbGoods.bSet
            if bSet then
                FireUIEvent("PREVIEW_SET", self.tSub)
            else
                CoinShop_PreviewGoods(eGoodsType, dwGoodsID, true)
            end
            FireUIEvent("COINSHOP_OPEN_RECOMMEND_BY_GOODS", eGoodsType, dwGoodsID)
        elseif self.tbPet then
            --local bPreview = ExteriorCharacter.IsRewardsPreview(self.tbPet)
            ExteriorCharacter.PreviewRewardsItem(self.tbPet)
        elseif self.tbFoldList then
            if self.fnFoldCallback then
                self.fnFoldCallback()
            end
        end
    end)

    UIHelper.BindUIEvent(self.BtnVideo, EventType.OnClick, function ()
        if self.tbGoods then
            local dwGoodsID = self.tbGoods.dwGoodsID
            local tLine = CoinShop_GetLimitItemStoryDisplay(dwGoodsID)
            if tLine then
                Timer.Add(self, 0.5, function ()
                    self:OpenStoryDisplay(tLine)
                end)
            else
                local tbVideoList = CoinShop_GetAllLimitVideo(dwGoodsID)
                if #tbVideoList > 0 then
                    local tbConfig = {}
                    tbConfig.bNet = true
                    tbConfig.bShop = true
                    if Platform.IsMobile() and App_GetNetMode() ~= NET_MODE.WIFI then
                        UIHelper.ShowConfirm("当前为非Wi-Fi（正在使用非WiFi网络），播放将消耗流量   取消 / 继续播放？", function ()
                            MovieMgr.PlayVideo(tbVideoList[1].szUrl, tbConfig ,{})
                        end, nil)
                    else
                       MovieMgr.PlayVideo(tbVideoList[1].szUrl, tbConfig ,{})
                    end
                end
            end
        end
    end)
end

function UICoinShopOutfitItem:RegEvent()
    Event.Reg(self, EventType.OnEquipPakResourceDownload, function()
        self:UpdateDownload()
    end)
end

function UICoinShopOutfitItem:UnRegEvent()
    Event.UnRegAll(self)
end

-- ----------------------------------------------------------
-- Please write your own code below  ↓↓↓
-- ----------------------------------------------------------

function UICoinShopOutfitItem:UpdateItemState()
    if self.tbGoods then
        local dwGoodsID = self.tbGoods.dwGoodsID
        local eGoodsType = self.tbGoods.eGoodsType
        local bPreview = CoinShop_IsGoodsPreview(eGoodsType, dwGoodsID)
        UIHelper.SetSelected(self.TogOutfitItem, bPreview, false)
    elseif self.tbPet then
        local bPreview = ExteriorCharacter.IsRewardsPreview(self.tbPet)
        UIHelper.SetSelected(self.TogOutfitItem, bPreview, false)
    end
end

function UICoinShopOutfitItem:UpdateCounterNum()
    if self.nCounterID and self.nCounterID > 0 then
        local nCount = GetCoinShopClient().GetGlobalCounterValue(self.nCounterID)
        UIHelper.SetString(self.LabelLimitNum, nCount)
    end
end

function UICoinShopOutfitItem:UpdateLimitTime()
    if not self.tbGoods then
        return
    end
    local dwGoodsID = self.tbGoods.dwGoodsID
    local eGoodsType = self.tbGoods.eGoodsType
    local tbInfo = CoinShop_GetPriceInfo(dwGoodsID, eGoodsType)
    local nStartTime = CoinShop_GetStartTime(tbInfo)
    local nEndTime = CoinShop_GetEndTime(tbInfo)
    local bDis, szDisCount, szDisTime = CoinShop_GetDisInfo(tbInfo)
    local nHaveType = GetCoinShopClient().CheckAlreadyHave(eGoodsType, dwGoodsID)
    local bHave = nHaveType ~= COIN_SHOP_OWN_TYPE.NOT_HAVE
    local nTime = GetGSCurrentTime()
    -- 测试代码start
    -- if not self.nEndTime then
    --     self.nEndTime = GetGSCurrentTime() + 20
    -- end
    -- nEndTime = self.nEndTime
    -- if not self.nStartTime then
    --     self.nStartTime = GetGSCurrentTime() + 10
    -- end
    -- nStartTime = self.nStartTime
    -- bDis = true
    -- szDisCount = "7.7折"
    -- szDisTime = "(2天)"
    -- 测试代码end
    if self.bLimitTime then
        local bLimitItem = tbInfo.nGlobalCounterID and tbInfo.nGlobalCounterID > 0
        local szTime = ""
        local szStatus = ""
        if nStartTime ~= -1 and nTime <= nStartTime then
            szTime = CoinShop_GetTimeText(nStartTime)
            szStatus = "后开售"
        elseif nEndTime ~= -1 and nTime <= nEndTime then
            szTime = CoinShop_GetTimeText(nEndTime)
            szStatus = "后结售"
        elseif nEndTime ~=-1 and nTime > nEndTime then
            szStatus = "已结售"
        end
        if bLimitItem then
            local nCount = GetCoinShopClient().GetGlobalCounterValue(tbInfo.nGlobalCounterID)
            if nCount <= 0 then
                szStatus = "已售罄"
            end
        end
        UIHelper.SetVisible(self.LabelEndTime, szTime ~= "")
        UIHelper.SetVisible(self.LabelEnd, szStatus ~= "")
        UIHelper.SetString(self.LabelEndTime, szTime)
        UIHelper.SetString(self.LabelEnd, szStatus)
        UIHelper.SetVisible(self.WidgetSellTime, szTime ~= "" or szStatus ~= "")
    else
        UIHelper.SetVisible(self.LabelEndTime, false)
        UIHelper.SetVisible(self.LabelEnd, false)
        UIHelper.SetVisible(self.WidgetSellTime, false)
    end
    UIHelper.LayoutDoLayout(self.WidgetSellTime)

    -- 折扣刷新
    local bShowDisTime = (nStartTime == -1 or nTime >= nStartTime) and (nEndTime == -1 or nTime <= nEndTime)
    UIHelper.SetVisible(self.ImgDiscountTimeBg, bDis and not bHave)
    UIHelper.SetString(self.LabelDiscount, szDisCount)
    UIHelper.SetString(self.LabelDiscountTime, szDisTime)
    UIHelper.SetVisible(self.LabelDiscountTime,  szDisTime ~= "" and bShowDisTime)
    UIHelper.LayoutDoLayout(self.LayoutDiscount)

    Timer.DelTimer(self, self.nTimer)
    if self.tbGoods and self.bLimitTime then
        self.nTimer = Timer.Add(self, 0.1, function()
            self:UpdateLimitTime()
        end)
    end
end

function UICoinShopOutfitItem:Update()
    if not self.bInit then
        return
    end
    if self.tbGoods then
        self:UpdateGoods()
    end
end

function UICoinShopOutfitItem:OnInitWithGoods(tbGoods)
    if not self.bInit then
        self:RegEvent()
        self:BindUIEvent()
        self.bInit = true
    end

    self.tbGoods = tbGoods

    local dwGoodsID = tbGoods.dwGoodsID
    local eGoodsType = tbGoods.eGoodsType
    if tbGoods.bSet then
        self:UpdateSets(true)
    else
        self:UpdateGoods(true)
    end
    self:UpdateDownloadEquipRes({{nSource=COIN_SHOP_GOODS_SOURCE.COIN_SHOP, dwID=dwGoodsID, dwType=eGoodsType}})
end

function UICoinShopOutfitItem:UpdateGoods(bInit)
    local tbGoods = self.tbGoods

    local dwGoodsID = tbGoods.dwGoodsID
    local eGoodsType = tbGoods.eGoodsType
    local tbInfo = CoinShop_GetPriceInfo(dwGoodsID, eGoodsType)
    local szName = CoinShop_GetGoodsName(eGoodsType, dwGoodsID)
    local bDis, szDisCount, szDisTime = CoinShop_GetDisInfo(tbInfo)
    local nPrice, nOriginalPrice = CoinShop_GetShowPrice(tbInfo)
    local bSecondDis = CoinShop_IsSecondDis(tbInfo)
    local nHaveType = GetCoinShopClient().CheckAlreadyHave(eGoodsType, dwGoodsID)
    local bHave = nHaveType ~= COIN_SHOP_OWN_TYPE.NOT_HAVE
    local szOwn = g_tStrings.tCoinShopOwnType[nHaveType]
    local nEndTime = CoinShop_GetEndTime(tbInfo)
    local bLimitTime = nEndTime ~= -1
    local bGlobalCounter = false
    local nLeftCount = 0
    local bGameWorldStart = tbInfo.nGameWorldStartInDuration > 0

    if bInit then
        local szBgPath = CoinShop_GetGoodsBG(tbGoods)
        if szBgPath then
            szBgPath = string.gsub(szBgPath, "ui\\Image", "Resource")
            szBgPath = string.gsub(szBgPath, "ui/Image", "Resource")
            szBgPath = string.gsub(szBgPath, ".tga", ".png")
            UIHelper.SetTexture(self.ImgRoleCard, szBgPath, false)
        end
        local szTitle = UIHelper.LimitUtf8Len(UIHelper.GBKToUTF8(szName), 8)
        UIHelper.SetString(self.LabelClothesName, szTitle)
        UIHelper.SetVisible(self.LabelClothesName, bHave)
        UIHelper.SetString(self.LabelClothesTitle, bHave and "已拥有" or szTitle)
    end

    UIHelper.SetString(self.LabelPrice, nPrice)
    UIHelper.SetVisible(self.LabelOriginalPrice, bDis and not bHave)
    UIHelper.SetString(self.LabelOriginalPrice, nOriginalPrice)
    UIHelper.SetVisible(self.ImgCollectStatus, false)
    UIHelper.SetVisible(self.LayoutPrice, not bHave)

    local bLimit3 = false
    if eGoodsType == COIN_SHOP_GOODS_TYPE.ITEM then
        local nCounterID = tbInfo.nGlobalCounterID
        bGlobalCounter = nCounterID and nCounterID > 0
        local tbRewardsItem = Table_GetRewardsItem(dwGoodsID)
        local bShowBeforeTime = CoinShop_ShowBeforeTime(COIN_SHOP_GOODS_TYPE.ITEM, tbRewardsItem.nClass)
        bLimitTime = (bLimitTime or bShowBeforeTime or bGameWorldStart or bGlobalCounter)
        nLeftCount = GetCoinShopClient().GetGlobalCounterValue(nCounterID)
        self.nCounterID = nCounterID
        bLimit3 = CoinShop_RewardsShowLimit3(dwGoodsID)
    end
    UIHelper.SetVisible(self.ImgLimitBg, bGlobalCounter and not bLimit3)
    UIHelper.SetString(self.LabelLimitNum, nLeftCount)
    if bLimit3 then
        UIHelper.SetSpriteFrame(self.ImgLimitedTime, "UIAtlas2_Shopping_ShoppingIcon_img_promotion04", false)
    elseif bLimitTime and not bGlobalCounter then
        UIHelper.SetSpriteFrame(self.ImgLimitedTime, "UIAtlas2_Shopping_ShoppingIcon_img_promotion02", false)
    end
    UIHelper.SetVisible(self.ImgLimitedTime, bLimitTime and not bGlobalCounter or bLimit3)
    UIHelper.LayoutDoLayout(self.LayoutDiscountTime)

    self.bLimitTime = bLimitTime
    self:UpdateLimitTime()

    local bCanUseDis = CoinShop_CheckHaveDisCouponForGoods(eGoodsType, dwGoodsID)
    UIHelper.SetVisible(self.WidgetDiscountTicket, bCanUseDis)
    if bCanUseDis then
        UIHelper.PlaySFX(self.Eff_DiscountTicket, 1)
    end
    UIHelper.LayoutDoLayout(self.LayoutDiscountTime)

    UIHelper.SetVisible(self.WidgetStacking, false)

    local tbVideoList = CoinShop_GetAllLimitVideo(dwGoodsID)
    UIHelper.SetVisible(self.BtnVideo, #tbVideoList > 0)

    local bPreview = CoinShop_IsGoodsPreview(eGoodsType, dwGoodsID)
    UIHelper.SetSelected(self.TogOutfitItem, bPreview, false)
end

function UICoinShopOutfitItem:UpdateDownloadEquipRes(tList)
    if not PakDownloadMgr.IsEnabled() then
        return
    end
    local tEquipList, tEquipSfxList = PakEquipResData.GetPakResource(g_pClientPlayer.nRoleType, tList)
    self.tEquipList, self.tEquipSfxList = tEquipList, tEquipSfxList
    self:UpdateDownload()
end

function UICoinShopOutfitItem:UpdateDownload()
    local tEquipList, tEquipSfxList = self.tEquipList, self.tEquipSfxList
    if not tEquipList or not tEquipSfxList then
        return
    end
    local tConfig = {}
    local bRemoteNotExist
    self.nDownloadDynamicID, bRemoteNotExist = PakDownloadMgr.UserCheckDownloadEquipRes(g_pClientPlayer.nRoleType, tEquipList, tEquipSfxList, self.nDownloadDynamicID)
    local scriptMask = UIHelper.GetBindScript(self.WidgetDownloadShell)
    scriptMask:SetInfo(self.nDownloadDynamicID, bRemoteNotExist, tConfig)
end

function UICoinShopOutfitItem:UpdateSets(bInit)
    local tbGoods = self.tbGoods

    local hExteriorClient = GetExterior()
    if not hExteriorClient then
        return
    end
    local hCoinShopClient = GetCoinShopClient()
    if not hCoinShopClient then
        return
    end

    local hPlayer = GetClientPlayer()
    if not hPlayer then
        return hPlayer
    end

    local tbExteriorInfo = hExteriorClient.GetExteriorInfo(tbGoods.dwGoodsID)
    local tbSetInfo = Table_GetExteriorSet(tbExteriorInfo.nSet)
    local tbSub = tbSetInfo.tSub
    self.tSub = tbSetInfo.tSub
    local nCount = tbSetInfo.nCount or #tbSub

    local nHave, nCoin, bShop, nCollected, nOriginalCoin, nDelete, bStorage = CoinShopExterior.GetSetInfo(tbSub)
    local bHave = nHave == nCount
    local bDis, szDisCount, szDisTime = CoinShop_GetDisInfo(tbExteriorInfo)

    if bInit then
        local szBgPath = CoinShop_GetGoodsBG(tbGoods)
        if szBgPath then
            szBgPath = string.gsub(szBgPath, "ui\\Image", "Resource")
            szBgPath = string.gsub(szBgPath, "ui/Image", "Resource")
            szBgPath = string.gsub(szBgPath, ".tga", ".png")
            UIHelper.SetTexture(self.ImgRoleCard, szBgPath, false)
        end
    end

    local szTitle = UIHelper.LimitUtf8Len(UIHelper.GBKToUTF8(tbSetInfo.szSetName), 8)
    if bHave then
        UIHelper.SetString(self.LabelClothesTitle, "已拥有")
        UIHelper.SetVisible(self.LabelClothesName, true)
        UIHelper.SetString(self.LabelClothesName, szTitle)
        Timer.AddFrame(this, 5, function()
            UIHelper.SetString(self.LabelClothesName, szTitle)
        end)

        UIHelper.SetVisible(self.LayoutPrice, false)
    else
        UIHelper.SetString(self.LabelClothesTitle, szTitle)

        UIHelper.SetVisible(self.LayoutPrice, true)
        UIHelper.SetString(self.LabelPrice, nCoin)
        UIHelper.SetVisible(self.LabelOriginalPrice, bDis)
        UIHelper.SetString(self.LabelOriginalPrice, nOriginalCoin)
    end

    UIHelper.SetVisible(self.ImgLimitBg, false)
    UIHelper.SetVisible(self.ImgCollectStatus, false)
    UIHelper.SetVisible(self.LabelEndTime, false)
    UIHelper.SetVisible(self.LabelEnd, false)
    UIHelper.SetVisible(self.WidgetStacking, false)

    UIHelper.SetVisible(self.ImgDiscountTimeBg, bDis and not bHave)

    UIHelper.SetString(self.LabelDiscount, szDisCount)
    UIHelper.SetString(self.LabelDiscountTime, szDisTime)

    local tbVideoList = CoinShop_GetAllLimitVideo(tbGoods.dwGoodsID)
    UIHelper.SetVisible(self.BtnVideo, #tbVideoList > 0)

    UIHelper.SetVisible(self.LabelKeepTip, bStorage)

    local bPreview = CoinShop_IsGoodsPreview(tbGoods.eGoodsType, tbGoods.dwGoodsID)
    UIHelper.SetSelected(self.TogOutfitItem, bPreview, false)
end

function UICoinShopOutfitItem:UpdateFoldLimitTime()
    if not self.tbFoldList then
        return
    end

    local nEarlyStart, nEarlyEnd
    local nLatestStart, nLatestEnd
    for k, tbGoods in ipairs(self.tbFoldList) do
        local dwGoodsID = tbGoods.dwGoodsID
        local eGoodsType = tbGoods.eGoodsType
        local tInfo = CoinShop_GetPriceInfo(dwGoodsID, eGoodsType)
        local nStartTime = CoinShop_GetStartTime(tInfo)
        local nEndTime = CoinShop_GetEndTime(tInfo)
        if nStartTime and (not nEarlyStart or nEarlyStart == -1 or (nStartTime ~= -1 and nStartTime < nEarlyStart)) then
            nEarlyStart = nStartTime
        end
        if nStartTime and (not nLatestStart or nLatestStart == -1 or (nStartTime ~= -1 and nStartTime > nLatestStart)) then
            nLatestStart = nStartTime
        end
        if nEndTime and (not nEarlyEnd or nEarlyEnd == -1 or (nEndTime ~= -1 and nEndTime < nEarlyEnd)) then
            nEarlyEnd = nEndTime
        end
        if nEndTime and (not nLatestEnd or nLatestEnd == -1 or (nEndTime ~= -1 and nEndTime > nLatestEnd)) then
            nLatestEnd = nEndTime
        end
    end
    local nTime = GetGSCurrentTime()
    local szTime = ""
    local szStatus = ""
    if nEarlyStart ~= -1 and nTime <= nEarlyStart then
        szTime = CoinShop_GetTimeText(nEarlyStart, true)
        if nEarlyStart ~= nLatestStart then
            szTime = "最早" .. szTime
        end
        szStatus = "开售"
    elseif nEarlyEnd ~= -1 then
        szTime = CoinShop_GetTimeText(nEarlyEnd, true)
        if nEarlyEnd ~= nLatestEnd then
            szTime = "最早" .. szTime
        end
        szStatus = "结售"
    end
    UIHelper.SetVisible(self.LabelEndTime, szTime ~= "")
    UIHelper.SetVisible(self.LabelEnd, szStatus ~= "")
    UIHelper.SetString(self.LabelEndTime, szTime)
    UIHelper.SetString(self.LabelEnd, szStatus)
    UIHelper.SetVisible(self.WidgetSellTime, szTime ~= "" or szStatus ~= "")
    UIHelper.LayoutDoLayout(self.WidgetSellTime)

    Timer.DelTimer(self, self.nTimer)
    self.nTimer = Timer.Add(self, 0.1, function()
        self:UpdateFoldLimitTime()
    end)
end

function UICoinShopOutfitItem:OnInitWithFold(tbFoldList, fnCallback)
    if not self.bInit then
        self:RegEvent()
        self:BindUIEvent()
        self.bInit = true
    end

    self.tbFoldList = tbFoldList
    self.fnFoldCallback = fnCallback

    local tbGoods = tbFoldList[1]
    local dwGoodsID = tbGoods.dwGoodsID

    local nMin, nMax
    for _, tbGoods in ipairs(tbFoldList) do
        local dwGoodsID = tbGoods.dwGoodsID
        local eGoodsType = tbGoods.eGoodsType
        local tInfo = CoinShop_GetPriceInfo(dwGoodsID, eGoodsType)
        local nPrice, nOriginalPrice = CoinShop_GetShowPrice(tInfo)
        if not nMin or nPrice < nMin then
            nMin = nPrice
        end
        if not nMax or nPrice > nMax then
            nMax = nPrice
        end
    end

    UIHelper.SetVisible(self.LayoutPrice, true)
    UIHelper.SetString(self.LabelPrice, nMin)
    UIHelper.SetVisible(self.LabelOriginalPrice, false)
    UIHelper.SetVisible(self.Labelmini, nMin ~= nMax)
    UIHelper.LayoutDoLayout(self.LayoutPrice)

    local tbFoldInfo = CoinShop_GetHomeFoldInfoByID(self.tbFoldList.nFoldID)
    local szName = UIHelper.GBKToUTF8(tbFoldInfo.szName)
    UIHelper.SetString(self.LabelClothesTitle, szName)

    local szBgPath
    if tbFoldInfo.szImagePath and tbFoldInfo.szImagePath ~= "" then
        szBgPath = tbFoldInfo.szImagePath
    else
        szBgPath = CoinShop_GetGoodsBG(tbGoods)
    end
    if szBgPath then
        szBgPath = string.gsub(szBgPath, "ui\\Image", "Resource")
        szBgPath = string.gsub(szBgPath, "ui/Image", "Resource")
        szBgPath = string.gsub(szBgPath, ".tga", ".png")
        UIHelper.SetTexture(self.ImgRoleCard, szBgPath, false)
    end

    UIHelper.SetVisible(self.ImgBgFrame, false)
    UIHelper.SetVisible(self.ImgBgFrame_Stack, true)
    UIHelper.SetVisible(self.ImgDiscountTimeBg, false)
    UIHelper.SetVisible(self.ImgLimitBg, false)
    UIHelper.SetVisible(self.ImgLimitedTime, true)
    UIHelper.LayoutDoLayout(self.LayoutDiscountTime)
    UIHelper.SetVisible(self.ImgStack, true)

    UIHelper.SetVisible(self.BtnVideo, false)
    UIHelper.SetVisible(self.WidgetStacking, false)
    UIHelper.SetVisible(self.LabelKeepTip, false)

    UIHelper.SetSelected(self.TogOutfitItem, false, false)

    self:UpdateFoldLimitTime()

    local bCanUseDis = CoinShop_CheckHaveDisCouponForGoodList(self.tbFoldList)
    UIHelper.SetVisible(self.WidgetDiscountTicket, bCanUseDis)
    if bCanUseDis then
        UIHelper.PlaySFX(self.Eff_DiscountTicket, 1)
    end
    UIHelper.LayoutDoLayout(self.LayoutDiscountTime)

end

local function HoldRepresent(aRepresent, tRepresentID, szKey)
    if szKey == "" then
        return
    end
    local tPlayHoldRepresent = string.split(szKey, ";")
    for _, szID in pairs(tPlayHoldRepresent) do
        local nID = tonumber(szID)
        aRepresent[nID] = tRepresentID[nID]
    end
end

function UICoinShopOutfitItem:OpenStoryDisplay(tStoryInfo)
    local hPlayer = GetClientPlayer()
    if not hPlayer then
        return
    end
    local tCoinRepresentID = ExteriorCharacter.GetRoleRes()
    local tPlayRepresentID = hPlayer.GetRepresentID()
   	local aRepresent       = {} 
    for i = 0, EQUIPMENT_REPRESENT.TOTAL - 1 do
        aRepresent[i] = 0
    end

    HoldRepresent(aRepresent, tCoinRepresentID, tStoryInfo.szCoinshopHoldRepresent)
    HoldRepresent(aRepresent, tPlayRepresentID, tStoryInfo.szPlayHoldRepresent)

    MovieMgr.PlayCoinShopMovie(tStoryInfo.nStoryID, aRepresent)
end
return UICoinShopOutfitItem