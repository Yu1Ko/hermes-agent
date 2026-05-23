-- ---------------------------------------------------------------------------------
-- Author: 陈计
-- Name: UIBenefitBPRewardDetailView
-- Date: 2024-03-20 11:23:11
-- Desc: 购买战令界面
-- Prefab: PanelBenefitBPRewardDetail
-- ---------------------------------------------------------------------------------

---@class UIBenefitBPRewardDetailView
local UIBenefitBPRewardDetailView = class("UIBenefitBPRewardDetailView")

---_LuaBindList 在这里对绑定的组件进行无意义自赋值，从而方便查询以及ide进行智能提示
function UIBenefitBPRewardDetailView:_LuaBindList()
    self.BtnClose                   = self.BtnClose --- 关闭按钮

    self.MiniScene                  = self.MiniScene --- 场景组件
    self.TouchContainer             = self.TouchContainer --- 用于实现模型旋转的组件

    -- 普通档
    self.WidgetNormalNotPurchased   = self.WidgetNormalNotPurchased --- 未购买
    self.WidgetNormalPurchased      = self.WidgetNormalPurchased --- 已购买
    self.BtnBuyNormal               = self.BtnBuyNormal --- 购买按钮

    self.ScrollViewRewardList       = self.ScrollViewRewardList --- 普通档代表奖励的scroll view

    -- 进阶档/补差价档
    self.WidgetAdvancedNotPurchased = self.WidgetAdvancedNotPurchased --- 未购买
    self.WidgetAdvancedPurchased    = self.WidgetAdvancedPurchased --- 已购买
    self.BtnBuyAdvanced             = self.BtnBuyAdvanced --- 购买按钮
    self.LabelNameAdvanced          = self.LabelNameAdvanced --- 名称

    self.BtnAdvancedItem            = self.BtnAdvancedItem --- 进阶档代表奖励道具的按钮

    self.WidgetRewardNormalPart     = self.WidgetRewardNormalPart --- 进阶档中普通档奖励部分
    self.ImgAdd                     = self.ImgAdd --- 进阶档中的+号
    self.LayoutReward               = self.LayoutReward --- 进阶档的layout

    self.WidgetBuyingMask           = self.WidgetBuyingMask --- 购买过程中的遮罩
end

---_LuaTypeList 在这里添加类型注解，从而方便查询以及ide进行智能提示
function UIBenefitBPRewardDetailView:_LuaTypeList()
    -- note: 为了方便写的时候IDE也能提示诸如 c++导出的枚举、临时定义的table列表 的字段，可以像下面示例一样，在这里定义对应类型的信息
    -- note: 定义完后在对应变量的定义处通过 ---@type 注解来标注类型即可
    -- note: 具体 class/type/array/table 格式参考 https://emmylua.github.io/annotation.html

end

function UIBenefitBPRewardDetailView:OnEnter()
    self.bBackUpPostRenderVignetteEnable = KG3DEngine.GetPostRenderVignetteEnable()

    if not self.bInit then
        self:RegEvent()
        self:BindUIEvent()
        self.bInit = true
    end

    self:UpdateInfo()
end

function UIBenefitBPRewardDetailView:OnExit()
    self.bInit = false
    self:UnRegEvent()

    UITouchHelper.UnBindModel()

    if self.hModelView then
        self.hModelView:release()
        self.hModelView = nil
    end

    KG3DEngine.SetPostRenderVignetteEnable(self.bBackUpPostRenderVignetteEnable)
end

function UIBenefitBPRewardDetailView:BindUIEvent()
    UIHelper.BindUIEvent(self.BtnClose, EventType.OnClick, function()
        UIMgr.Close(self)
    end)

    UIHelper.BindUIEvent(self.BtnBuyNormal, EventType.OnClick, function()
        self:BuyBattlePass(HuaELouData.tBattlePassType.Normal)
    end)

    UIHelper.BindUIEvent(self.BtnBuyAdvanced, EventType.OnClick, function()
        local bNormalPurchased   = HuaELouData.IsGrandRewardUnlock()
        local bAdvancedPurchased = HuaELouData.IsExtralUnlock()

        local nType              = HuaELouData.tBattlePassType.Advanced
        if bNormalPurchased and not bAdvancedPurchased then
            -- 购买了普通档，尚未购买进阶档时，将进阶档的信息修改为补差价档
            nType = HuaELouData.tBattlePassType.Middle
        end

        self:BuyBattlePass(nType)
    end)

    UIHelper.BindUIEvent(self.BtnAdvancedItem, EventType.OnClick, function()
        local dwItemIndex = 86132
        TipsHelper.ShowItemTips(self.BtnAdvancedItem, ITEM_TABLE_TYPE.OTHER, dwItemIndex)
    end)

    Event.Reg(self, "XGSDK_OnPayResult", function(szResultType, nCode, szMsg, szChannelCode, szChannelMsg)
        if szResultType == "Progress" then
            -- 正在支付中的情况不需要隐藏遮罩
            return
        end

        -- 由于支付结果和战令状态同步之间有一定时间，这里等待一会，确保状态同步下来
        Timer.Add(self, 5, function()
            UIHelper.SetVisible(self.WidgetBuyingMask, false)
        end)
    end)
end

function UIBenefitBPRewardDetailView:RegEvent()
    Event.Reg(self, EventType.OnMiniSceneLoadProgress, function(nProcess)
        if nProcess >= 100 then
            local scene = self.hModelView.m_scene
            if scene and not QualityMgr.bDisableCameraLight then
                scene:OpenCameraLight(QualityMgr.szCameraLightForUI)
            end

            KG3DEngine.SetPostRenderVignetteEnable(false)
        end
    end)

    Event.Reg(self, "REMOTE_BATTLEPASS", function()
        HuaELouData.UpdateExp()

        self:UpdateRewardInfo()
    end)

    Event.Reg(self, "ON_HIDEMINISCENE_UNTILNEWVIEWCLOSE", function()
        UIHelper.TempHidePlayerMiniSceneUntilNewViewClose(self, self.MiniScene, self.hModelView, VIEW_ID.PanelOutfitPreview, function()
            UITouchHelper.BindModel(self.TouchContainer, self.hModelView)
        end)
    end)

    Event.Reg(self, "PLAYER_DISPLAY_DATA_UPDATE", function()
        if arg0 == g_pClientPlayer.dwID then
            self:UpdateDownloadEquipRes()
        end
    end)

    Event.Reg(self, EventType.OnEquipPakResourceDownload, function()
        self:UpdateDownloadEquipRes()
        self:UpdateModelInfo()
    end)
end

function UIBenefitBPRewardDetailView:UnRegEvent()
    --Event.UnReg(self, EventType.XXX)
end






-- ----------------------------------------------------------
-- Please write your own code below  ↓↓↓
-- ----------------------------------------------------------

function UIBenefitBPRewardDetailView:UpdateInfo()
    self:UpdateRewardInfo()

    self:UpdateMiniScene()
    self:UpdateDownloadEquipRes()
end

function UIBenefitBPRewardDetailView:UpdateRewardInfo()
    local bNormalPurchased   = HuaELouData.IsGrandRewardUnlock()
    local bAdvancedPurchased = HuaELouData.IsExtralUnlock()

    UIHelper.SetVisible(self.WidgetNormalNotPurchased, not bNormalPurchased)
    UIHelper.SetVisible(self.WidgetNormalPurchased, bNormalPurchased)

    UIHelper.SetVisible(self.WidgetAdvancedNotPurchased, not bAdvancedPurchased)
    UIHelper.SetVisible(self.WidgetAdvancedPurchased, bAdvancedPurchased)

    -- 仅在未购买普通档时，显示进阶档中包含普通档的部分
    UIHelper.SetVisible(self.WidgetRewardNormalPart, not bNormalPurchased)
    UIHelper.SetVisible(self.ImgAdd, not bNormalPurchased)
    UIHelper.LayoutDoLayout(self.LayoutReward)

    if bNormalPurchased and not bAdvancedPurchased then
        -- 购买了普通档，尚未购买进阶档时，将进阶档的信息修改为补差价档
        UIHelper.SetString(self.LabelNameAdvanced, "￥100")
    end

    self:UpdateGallantReward()
end

function UIBenefitBPRewardDetailView:UpdateMiniScene()
    self.hModelView = PlayerModelView.CreateInstance(PlayerModelView)
    self.hModelView:ctor()
    self.hModelView:InitBy({
                               szName = "BattlePassPreview",
                               bExScene = true,
                               szExSceneFile = "data\\source\\maps\\MB商城_2023_001\\MB商城_2023_001.jsonmap",
                               bAPEX = false,
                           })

    self.MiniScene:SetScene(self.hModelView.m_scene)
    self:UpdateModelInfo()
end

local tRoleTypeToCameraInfo = {
    [ROLE_TYPE.STANDARD_MALE] = { -320, 24, -1000, 6, 72, -138, 0.17, 0, 20, 40000, true }, --rtStandardMale,     // 标准男
    [ROLE_TYPE.STANDARD_FEMALE] = { -320, 24, -1000, 6, 72, -138, 0.17, 0, 20, 40000, true }, --rtStandardFemale,   // 标准女
    [ROLE_TYPE.LITTLE_BOY] = { -320, 24, -1000, 6, 60, -108, 0.13, 0, 20, 40000, true }, --rtLittleBoy,        // 小男孩
    [ROLE_TYPE.LITTLE_GIRL] = { -320, 24, -1000, 6, 60, -138, 0.14, 0, 20, 40000, true }, --rtLittleGirl,       // 小孩女
}
function UIBenefitBPRewardDetailView:UpdateModelInfo()
    self.hModelView:UnloadModel()

    self.hModelView:LoadPlayerRes(UI_GetClientPlayerID(), false)
    self.hModelView:LoadModel()
    self.hModelView:SetWeaponSocketDynamic()
    self.hModelView:SetTranslation(Device.IsPad() and 80 or 70, 0, 300)
    self.hModelView:SetYaw(0.30)

    local nRoleType   = Player_GetRoleType(g_pClientPlayer)
    local tCameraInfo = tRoleTypeToCameraInfo[nRoleType]
    self.hModelView:SetCamera(tCameraInfo)

    -- 将预览模型的部分部位外观替换为策划指定的外观
    local tRepresentID    = Role_GetRepresentID(g_pClientPlayer)
    local tNewRepresentID = HuaELouData.tBattlePassPreviewRewardPlayerModelRepresentID
    for nIndex, nRepresentID in pairs(tNewRepresentID) do
        tRepresentID[nIndex] = nRepresentID
    end
    self.hModelView:LoadRes(UI_GetClientPlayerID(), tRepresentID)
    self.hModelView:PlayAnimation("Standard", "loop")

    UITouchHelper.BindModel(self.TouchContainer, self.hModelView)
end

function UIBenefitBPRewardDetailView:BuyBattlePass(nBattlePassType)
    local hPlayer = GetClientPlayer()
    if not hPlayer or BankLock.CheckHaveLocked(SAFE_LOCK_EFFECT_TYPE.EXTERIOR, "CoinShop") then
        return
    end

    if self:IsAnyBattlePassInStorageArea() then
        LOG.DEBUG("当前保管区内有战令商品，不允许再购买任何战令，需要先去保管区内领取")
        TipsHelper.ShowImportantRedTip("当前保管区内有江湖行记商品未领取，请先前往商城-保管领取后再尝试购买", false, 5)
        return
    end

    local nCoin = ItemData.GetCoin()
    if nCoin < 0 then
        TipsHelper.ShowNormalTip("当前通宝数量不符合购买条件", false)
        return
    end

    local tBattlePassItem = HuaELouData.GetBattlePassItemTable()
    local tBattlePassInfo = tBattlePassItem[nBattlePassType]

    local nPassTabIndex   = tBattlePassInfo.dwIndex
    local nPassGoodsId    = tBattlePassInfo.dwGoodsID

    LOG.DEBUG("购买战令 rmb=%s nBattlePassType=%d nPassTabIndex=%d nPassGoodsId=%d", tostring(HuaELouData.PASS_USE_RMB), nBattlePassType, nPassTabIndex, nPassGoodsId)

    local szMsgTemplate = g_tStrings.Reward.REWARDSR_BUY_SURE1
    if HuaELouData.PASS_USE_RMB then
        szMsgTemplate = g_tStrings.Reward.REWARDSR_BUY_SURE_RMB
        LOG.DEBUG("[BP直购] 战令使用实物道具来实现直购流程 nPassTabIndex=%d nPassGoodsId=%d", nPassTabIndex, nPassGoodsId)

        local tInfo = CoinShop_GetPriceInfo(nPassGoodsId, COIN_SHOP_GOODS_TYPE.ITEM)
        if not tInfo.bIsReal then
            LOG.ERROR("[BP直购] nPassGoodsId=%d 不是实物道具", nPassGoodsId)
        end
    end

    local itemInfo = GetItemInfo(ITEM_TABLE_TYPE.OTHER, nPassTabIndex)
    local nBookInfo
    if itemInfo.nGenre == ITEM_GENRE.BOOK then
        nBookInfo = itemInfo.nDurability
    end
    local szName           = ItemData.GetItemNameByItemInfo(itemInfo, nBookInfo)
    szName                 = UIHelper.GBKToUTF8(szName)
    local nPrice           = CoinShop_GetPrice(nPassGoodsId, COIN_SHOP_GOODS_TYPE.ITEM)
    local szMsg            = string.format(szMsgTemplate, szName, nPrice)
    local _, scriptConfirm = UIHelper.ShowConfirm(szMsg, function()
        if HuaELouData.PASS_USE_RMB then
            local tData = g_pClientPlayer.GetBuyItemOrderList() or {}
            for _, tOrder in pairs(tData) do
                if tOrder.nState == BUY_ITEM_ORDER_STATE.WAITING_FOR_PAYMENT then
                    -- 目前实物订单最多只能有一个处于未支付状态，这里需要特殊处理下
                    LOG.DEBUG("[BP直购] 已有未支付的实物订单 szOrderSN=%s dwItemType=%d dwItemIndex=%d",
                              tOrder.szOrderSN, tOrder.dwItemType, tOrder.dwItemIndex
                    )
                    if tOrder.dwItemType == ITEM_TABLE_TYPE.OTHER and tOrder.dwItemIndex == nPassTabIndex then
                        -- 是战令，则跳过下订单流程，走签名步骤
                        UIHelper.SetVisible(self.WidgetBuyingMask, true)
                        g_pClientPlayer.ApplyWebDataSign(WEB_DATA_SIGN_RQST.REAL_ITEM_ORDER, tOrder.szOrderSN)
                    else
                        -- 是其他道具，则提示一下
                        TipsHelper.ShowImportantRedTip("侠士在30分钟内存在同类型订单未支付，请在冷却时间（30分钟）后再尝试购买")
                    end

                    --- hack: #C720592 之前准备这里删除任何已有的战令订单，但后面实际测试发现不可行，因为服务器那边从很多年前开始就限定不允许删除处于等待支付状态的订单，为了避免影响过大，回滚了这个改动
                    ---     协作可搜索：这个方案好像不太行，看了下服务器代码，现在不允许删除未付款状态的订单

                    -- 这种情况不再触发实物订单下单流程
                    return
                end
            end
        end

        UIHelper.SetVisible(self.WidgetBuyingMask, true)
        ---@see 搜索：实物订单通知 ，在Global.lua中可找到实物订单后续流程的逻辑
        local nRetCode = CoinShop_BuyItem(nPassGoodsId, COIN_SHOP_GOODS_TYPE.ITEM, 1)
        if nRetCode ~= COIN_SHOP_ERROR_CODE.SUCCESS then
            UIHelper.SetVisible(self.WidgetBuyingMask, false)
        end
    end, function()

    end, true)
    if scriptConfirm then
        UIHelper.SetWidth(scriptConfirm.LabelHint, UIHelper.GetWidth(scriptConfirm.LabelHint) + 50) -- 测试要求动态拓展宽度以容纳多余的问号
    end
end

local MAX_LEVEL = 60

function UIBenefitBPRewardDetailView:UpdateGallantReward()
    UIHelper.RemoveAllChildren(self.ScrollViewRewardList)

    for nLevel = 0, MAX_LEVEL do
        local tLine   = HuaELouData.tRewardList[nLevel]
        local dwSetID = tLine.dwSetID2
        if dwSetID > 0 then
            local tRewardDetail = HuaELouData.GetRewardDetatil(dwSetID)
            if dwSetID and tRewardDetail and tRewardDetail.AwardItem then
                for nIndex, tItemInfo in pairs(tRewardDetail.AwardItem) do
                    ---@see UIWidgetBPRewardDetailCell#OnEnter
                    UIHelper.AddPrefab(PREFAB_ID.WidgetBPRewardDetailCell, self.ScrollViewRewardList, nLevel, tItemInfo)
                end
            end
        end
    end

    UIHelper.ScrollViewDoLayout(self.ScrollViewRewardList)
end

--- 是否有任意的战令类型的商品已在保管区内
function UIBenefitBPRewardDetailView:IsAnyBattlePassInStorageArea()
    local tBattlePassType = { HuaELouData.tBattlePassType.Normal, HuaELouData.tBattlePassType.Advanced, HuaELouData.tBattlePassType.Middle }

    local bInStorage      = false

    local tStorageList    = CoinShopData.GetStorageGoodsList()

    for _, nBattlePassType in ipairs(tBattlePassType) do
        local tBattlePassItem = HuaELouData.GetBattlePassItemTable()
        local tBattlePassInfo = tBattlePassItem[nBattlePassType]

        local nPassGoodsId    = tBattlePassInfo.dwGoodsID

        for _, dwStorageID in ipairs(tStorageList) do
            local tStorage = GetCoinShopClient().GetStorageGoodsInfo(dwStorageID)

            if tStorage and tStorage.eGoodsType == COIN_SHOP_GOODS_TYPE.ITEM and tStorage.dwGoodsID == nPassGoodsId then
                bInStorage = true
                LOG.DEBUG("战令类型=%d dwGoodsID=%d 在保管区内", nBattlePassType, nPassGoodsId)
                break
            end
        end
    end

    return bInStorage
end

function UIBenefitBPRewardDetailView:UpdateDownloadEquipRes()
    if not PakDownloadMgr.IsEnabled() then
        return
    end
    if not g_pClientPlayer then
        return
    end
    local tRepresentID = Role_GetRepresentID(g_pClientPlayer)
    local nRoleType = g_pClientPlayer.nRoleType
    local tNewRepresentID = HuaELouData.tBattlePassPreviewRewardPlayerModelRepresentID
    for nIndex, nRepresentID in pairs(tNewRepresentID) do
        tRepresentID[nIndex] = nRepresentID
    end
    local tEquipList, tEquipSfxList = Player_GetPakEquipResource(nRoleType, tRepresentID.nHatStyle, tRepresentID)
    local scriptDownload = UIHelper.GetBindScript(self.WidgetDownloadBtnShell)
    local tConfig = {}
    tConfig.bLong = true
    local bRemoteNotExist
    self.nDownloadDynamicID, bRemoteNotExist = PakDownloadMgr.UserCheckDownloadEquipRes(nRoleType, tEquipList, tEquipSfxList, self.nDownloadDynamicID)
    CoinShopPreview.UpdateSimpleDownloadBtn(scriptDownload, self.nDownloadDynamicID, bRemoteNotExist, tConfig)
end

return UIBenefitBPRewardDetailView