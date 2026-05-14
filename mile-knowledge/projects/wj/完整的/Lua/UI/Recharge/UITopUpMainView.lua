-- ---------------------------------------------------------------------------------
-- Author: Unknown
-- Name: UITopUpMainView
-- Date: 2022-12-21 11:22:37
-- Desc: 充值界面
-- Prefab: PanelTopUpMain
-- ---------------------------------------------------------------------------------

---@class UITopUpMainView
local UITopUpMainView = class("UITopUpMainView")

---_LuaBindList 在这里对绑定的组件进行无意义自赋值，从而方便查询以及ide进行智能提示
function UITopUpMainView:_LuaBindList()
    self.BtnClose                       = self.BtnClose --- 关闭界面
    self.TogCoin                        = self.TogCoin --- 通宝充值标签页
    self.TogPointCard                   = self.TogPointCard --- 点卡标签页
    self.TogMonthCard                   = self.TogMonthCard --- 月卡标签页
    self.BtnOpenConvertView             = self.BtnOpenConvertView --- 通宝兑换点卡按钮
    self.BtnCustomerService             = self.BtnCustomerService --- 客服按钮
    self.ImgMonthCard                   = self.ImgMonthCard --- 月卡截止 - 容器
    self.LabelMonthCardEndDate          = self.LabelMonthCardEndDate --- 月卡截止日期
    self.LabelMonthCardEndTime          = self.LabelMonthCardEndTime --- 月卡截止时间
    self.ImgPointCard                   = self.ImgPointCard --- 点卡截止 - 容器
    self.LabelPointCardEndDate          = self.LabelPointCardEndDate --- 点卡截止日期
    self.LabelPointCardEndTime          = self.LabelPointCardEndTime --- 点卡截止时间
    self.LabelCoin                      = self.LabelCoin --- 剩余通宝
    self.TabToggleGroup                 = self.TabToggleGroup --- 标签页互斥组
    self.LayoutCoin                     = self.LayoutCoin --- 通宝 - 容器
    self.LayoutRightTop                 = self.LayoutRightTop --- 右上角充值信息 - 容器

    self.WidgetPlural                   = self.WidgetPlural --- 多个充值的顶层组件
    self.WidgetSolo                     = self.WidgetSolo --- 单个充值的顶层组件
    self.WidgetTopUpSolo                = self.WidgetTopUpSolo --- 单个充值的挂载点

    self.WidgetBuyingMask               = self.WidgetBuyingMask --- 购买过程中的遮罩

    -- 一行最多3个的layout
    self.LayoutProductListRowOne        = self.LayoutProductListRowOne --- 商品列表容器 - 第一行
    self.LayoutProductListRowTwo        = self.LayoutProductListRowTwo --- 商品列表容器 - 第二行
    self.WidgetProductList              = self.WidgetProductList --- 商品列表容器的上层组件

    -- 一行最多2个的layout
    self.LayoutProductListRowOne_Little = self.LayoutProductListRowOne_Little --- 商品列表容器 - 第一行
    self.LayoutProductListRowTwo_Little = self.LayoutProductListRowTwo_Little --- 商品列表容器 - 第二行
    self.WidgetProductList_Little       = self.WidgetProductList_Little --- 商品列表容器的上层组件

    self.ImgPresent                     = self.ImgPresent --- 首充赠送的背景图 - 安卓（非抖音）、pc
    self.LabelPresent                   = self.LabelPresent --- 首充赠送的label - 安卓（非抖音）、pc
    self.ImgSend_Ios                    = self.ImgSend_Ios --- 首充赠送的背景图 - 安卓（抖音）、iOS
    self.LaberDescribe_Ios              = self.LaberDescribe_Ios --- 首充赠送的label - 安卓（抖音）、iOS

    self.BtnBenefits                    = self.BtnBenefits --- 打开福利返还界面

    self.WidgetDetailDescription        = self.WidgetDetailDescription --- 充值类别详细描述组件
    self.ImgDetailDescription           = self.ImgDetailDescription --- 充值类别详细描述图标
    self.RichTextDetailDescription      = self.RichTextDetailDescription --- 充值类别详细描述文本

    self.ImgLine01                      = self.ImgLine01 --- 充值条目tab的分隔符1
    self.ImgLine02                      = self.ImgLine02 --- 充值条目tab的分隔符2

    self.BtnCustomRecharge              = self.BtnCustomRecharge --- 打开自定义充值界面
end

function UITopUpMainView:OnEnter(bHideCoinTab, bDafaultSelectPointCard)
    self.bHideCoinTab            = bHideCoinTab or false
    self.bDafaultSelectPointCard = bDafaultSelectPointCard or false

    self.tTogInfoList            = {
        { szType = PayData.RechargeTypeEnum.szCoin, uiTog = self.TogCoin, },
        { szType = PayData.RechargeTypeEnum.szPointCard, uiTog = self.TogPointCard, },
        { szType = PayData.RechargeTypeEnum.szMonthCard, uiTog = self.TogMonthCard, },
    }

    if not self.bInit then
        self:RegEvent()
        self:BindUIEvent()
        self.bInit = true
    end

    self:UpdateInfo()
end

function UITopUpMainView:OnExit()
    self.bInit = false
    self:UnRegEvent()
end

function UITopUpMainView:BindUIEvent()
    UIHelper.BindUIEvent(self.BtnClose, EventType.OnClick, function()
        UIMgr.Close(self)
    end)

    for _, tTogInfo in ipairs(self.tTogInfoList) do
        local uiTog = tTogInfo.uiTog

        UIHelper.BindUIEvent(uiTog, EventType.OnClick, function()
            self:UpdateRechargeItems()
        end)
        UIHelper.ToggleGroupAddToggle(self.TabToggleGroup, uiTog)
    end

    UIHelper.BindUIEvent(self.BtnOpenConvertView, EventType.OnClick, function()
        if BankLock.CheckHaveLocked(SAFE_LOCK_EFFECT_TYPE.COIN, "COIN") then
            return
        end

        UIMgr.Open(VIEW_ID.PanelConvertPop)
    end)

    UIHelper.BindUIEvent(self.BtnCustomerService, EventType.OnClick, function()
        TipsHelper.ShowNormalTip("客服功能暂未实现，等系统设置页面的客服按钮接入后，调用相同接口即可")
    end)
    UIHelper.BindUIEvent(self.LayoutCoin, EventType.OnClick, function()
        CurrencyData.ShowCurrencyHoverTips(self.LayoutCoin, CurrencyType.Coin)
    end)
    UIHelper.SetTouchEnabled(self.LayoutCoin, true)

    UIHelper.BindUIEvent(self.BtnBenefits, EventType.OnClick, function()
        if BankLock.CheckHaveLocked(SAFE_LOCK_EFFECT_TYPE.COIN, "") then
            return
        end
        UIMgr.Open(VIEW_ID.PanelWelfareReturnPop)
    end)

    UIHelper.BindUIEvent(self.BtnCustomRecharge, EventType.OnClick, function()
        ---@see UICustomRechargeCoinView
        UIMgr.Open(VIEW_ID.PanelQuickPop, PayData.tCustomRechargeMode.Custom)
    end)
end

function UITopUpMainView:RegEvent()
    --Event.Reg(self, EventType.XXX, func)

    Event.Reg(self, "SYNC_COIN", function()
        self:UpdateTimeOfFee()
    end)

    Event.Reg(self, EventType.OnSyncRechargeInfo, function(nRechargeType, nPointsAmount, nRMBAmount, nEndTimeOfFee)
        self:UpdateTimeOfFee()
    end)

    Event.Reg(self, "XGSDK_OnPayResult", function(szResultType, nCode, szMsg, szChannelCode, szChannelMsg)
        if szResultType == "Progress" then
            -- 正在支付中的情况不需要隐藏遮罩
            return
        end

        UIHelper.SetVisible(self.WidgetBuyingMask, false)
    end)
end

function UITopUpMainView:UnRegEvent()
    --Event.UnReg(self, EventType.XXX)
end






-- ----------------------------------------------------------
-- Please write your own code below  ↓↓↓
-- ----------------------------------------------------------

function UITopUpMainView:UpdateInfo()
    -- 动态设置显示的tab
    UIHelper.SetVisible(self.TogCoin, not self.bHideCoinTab)
    UIHelper.SetVisible(self.TogMonthCard, PayData.GetServerType() == PayData.ServerTypeEnum.DianYueKa)

    -- 没时间提示而打开充值界面，此时不显示通宝相关元素
    UIHelper.SetVisible(self.LayoutCoin, not self.bHideCoinTab)
    UIHelper.SetVisible(self.BtnOpenConvertView, not self.bHideCoinTab)

    -- 没进游戏时，不显示福利返回和通宝兑换时间
    UIHelper.SetVisible(UIHelper.GetParent(self.BtnBenefits), Global.bIsEnterGame)


    -- 仅当当前标签已是可见（未被之前的规则隐藏），而且配置了对应类型的商品时，才显示
    for _, tTogInfo in ipairs(self.tTogInfoList) do
        local uiTog        = tTogInfo.uiTog

        local bVisibleNow  = UIHelper.GetVisible(uiTog)
        local tProductList = PayData.GetAllPayConfigOfType(tTogInfo.szType)
        local bShouldShow  = bVisibleNow and not IsTableEmpty(tProductList)
        if not bShouldShow then
            -- 不满足该条件，则隐藏
            UIHelper.SetVisible(uiTog, false)
        end
    end

    -- 处理下分隔符的显示
    local bShowCoin      = UIHelper.GetVisible(self.TogCoin)
    local bShowPointCard = UIHelper.GetVisible(self.TogPointCard)
    local bShowMonthCard = UIHelper.GetVisible(self.TogMonthCard)
    UIHelper.SetVisible(self.ImgLine01, bShowCoin and (bShowPointCard or bShowMonthCard))
    UIHelper.SetVisible(self.ImgLine02, bShowMonthCard and bShowPointCard)

    -- 重新设置互斥组
    UIHelper.ToggleGroupRemoveAllToggle(self.TabToggleGroup)
    local tTogIndex = self.tTogInfoList

    --要求默认选中点卡
    if self.bDafaultSelectPointCard then
        tTogIndex = {}
        for _, tTogInfo in ipairs(self.tTogInfoList) do
            if tTogInfo.szType == PayData.RechargeTypeEnum.szPointCard then
                table.insert(tTogIndex, 1, tTogInfo)
            else
                table.insert(tTogIndex, tTogInfo)
            end
        end
    end

    for _, tTogInfo in ipairs(tTogIndex) do
        local uiTog = tTogInfo.uiTog

        if UIHelper.GetVisible(uiTog) then
            UIHelper.ToggleGroupAddToggle(self.TabToggleGroup, uiTog)
        end
    end

    self:UpdateRechargeItems()
    self:UpdateTimeOfFee()
end

function UITopUpMainView:UpdateTimeOfFee()
    local nMonthEndTime, nPointLeftTime, nDayLeftTime, nFeeEndTime = Login_GetTimeOfFee()

    nPointLeftTime                                                 = PayData.GetActualPointLeftTime(nPointLeftTime, nMonthEndTime)

    LOG.DEBUG(string.format("UpdateTimeOfFee nMonthEndTime=%d nPointLeftTime=%d nDayLeftTime=%d nFeeEndTime=%d",
                            nMonthEndTime, nPointLeftTime, nDayLeftTime, nFeeEndTime
    ))

    -- 月卡截止时间
    local dateMonthEndTime = TimeToDate(nMonthEndTime)
    UIHelper.SetString(self.LabelMonthCardEndDate, string.format("%d-%02d-%02d", dateMonthEndTime.year, dateMonthEndTime.month, dateMonthEndTime.day))
    UIHelper.SetString(self.LabelMonthCardEndTime, string.format("%02d:%02d", dateMonthEndTime.hour, dateMonthEndTime.minute))
    -- 未充值时的默认值为 2004-01-01 00:00:00，在这种情况下不予显示
    UIHelper.SetVisible(self.ImgMonthCard, nMonthEndTime > 1072886400)

    -- 点卡截止时间
    local szPointLeftTime = PayData.FormatPointTime(nPointLeftTime)
    UIHelper.SetString(self.LabelPointCardEndDate, szPointLeftTime)
    UIHelper.SetVisible(self.LabelPointCardEndTime, false)

    UIHelper.SetVisible(self.ImgPointCard, nPointLeftTime ~= 0)

    -- 通宝
    UIHelper.SetString(self.LabelCoin, ItemData.GetCoin())

    UIHelper.LayoutDoLayout(self.LayoutCoin)
    -- 不知道为啥这里直接调用位置会偏左，后面多次调用会固定在稍右的一个位置，暂时没空查这个，先延迟一帧处理绕过去
    Timer.AddFrame(self, 1, function() UIHelper.LayoutDoLayout(self.LayoutRightTop) end)
end

function UITopUpMainView:UpdateRechargeItems()
    -- 目前iOS只显示单个条目，需要分别处理
    local bShowPlural = Platform.IsAndroid() or (Platform.IsWindows() and not Platform.WLCloudIsIos()) or Platform.IsMac()

    UIHelper.SetVisible(self.WidgetPlural, bShowPlural)
    UIHelper.SetVisible(self.WidgetSolo, not bShowPlural)

    if bShowPlural then
        self:UpdateRechargeItemPlural()
    else
        self:UpdateRechargeItemSolo()
    end

    self:UpdateIntroduction()

    --- 只在有通宝充值的端，且在通宝页面，才显示自定义充值按钮
    local bIsCoinTab                  = self:GetCurrentRechargeType() == PayData.RechargeTypeEnum.szCoin
    local bShowCustomRechargePlatform = (Platform.IsAndroid() and not Channel.Is_dylianyunyun()) or (Platform.IsWindows() and not Platform.WLCloudIsIos()) or Platform.IsMac()
    local bShowCustomRecharge         = bIsCoinTab and bShowCustomRechargePlatform
    UIHelper.SetVisible(self.BtnCustomRecharge, bShowCustomRecharge)
end

function UITopUpMainView:UpdateRechargeItemPlural()
    local szCurrentRechargeType = self:GetCurrentRechargeType()

    local nRowItemSize          = 3
    local layoutRowOne          = self.LayoutProductListRowOne
    local layoutRowTwo          = self.LayoutProductListRowTwo

    local bMonthCard            = szCurrentRechargeType == PayData.RechargeTypeEnum.szMonthCard
    if bMonthCard then
        --- 月卡现在只有4档，布局变成2x2，需要特殊处理下
        nRowItemSize = 2
        layoutRowOne = self.LayoutProductListRowOne_Little
        layoutRowTwo = self.LayoutProductListRowTwo_Little
    end

    UIHelper.SetVisible(self.WidgetProductList, not bMonthCard)
    UIHelper.SetVisible(self.WidgetProductList_Little, bMonthCard)

    UIHelper.RemoveAllChildren(layoutRowOne)
    UIHelper.RemoveAllChildren(layoutRowTwo)

    for idx, tRechargeConfig in ipairs(PayData.GetAllPayConfigOfType(szCurrentRechargeType)) do
        local layout = layoutRowOne
        if idx > nRowItemSize then
            layout = layoutRowTwo
        end

        ---@type UITopUpBtn
        local uiTopUpBtn = UIHelper.AddPrefab(PREFAB_ID.WidgetTopUpBtn, layout, tRechargeConfig, false, self)
    end

    UIHelper.LayoutDoLayout(layoutRowOne)
    UIHelper.LayoutDoLayout(layoutRowTwo)

    self:UpdatePresentInfo(true)
end

function UITopUpMainView:UpdateRechargeItemSolo()
    --UIHelper.RemoveAllChildren(self.WidgetTopUpSolo)
    --
    --local tAllPayConfig = PayData.GetAllPayConfig()
    --local tSolo         = tAllPayConfig[1]
    --
    -----@type UITopUpBtn
    --UIHelper.AddPrefab(PREFAB_ID.WIdgetTopUpSoloBtn, self.WidgetTopUpSolo, tSolo, true, self)

    UIHelper.RemoveAllChildren(self.WidgetTopUpSolo)

    local szCurrentRechargeType = self:GetCurrentRechargeType()
    for idx, tRechargeConfig in ipairs(PayData.GetAllPayConfigOfType(szCurrentRechargeType)) do
        ---@type UITopUpBtn
        local uiTopUpBtn = UIHelper.AddPrefab(PREFAB_ID.WidgetTopUpBtn, self.WidgetTopUpSolo, tRechargeConfig, false, self)
    end

    UIHelper.LayoutDoLayout(self.WidgetTopUpSolo)

    self:UpdatePresentInfo(false)
end

function UITopUpMainView:UpdatePresentInfo(bPlural)
    local szCurrentRechargeType = self:GetCurrentRechargeType()

    local szDescription         = PayData.tbTypeToFirstRechargePresentDescription[szCurrentRechargeType]
    --local szDescription = ""

    UIHelper.SetRichText(self.LabelPresent, szDescription)
    UIHelper.SetRichText(self.LaberDescribe_Ios, szDescription)

    UIHelper.SetVisible(self.LabelPresent, bPlural)
    UIHelper.SetVisible(self.ImgPresent, szDescription ~= "" and bPlural)

    UIHelper.SetVisible(self.LaberDescribe_Ios, not bPlural)
    UIHelper.SetVisible(self.ImgSend_Ios, szDescription ~= "" and not bPlural)
end

function UITopUpMainView:UpdateIntroduction()
    local szCurrentRechargeType = self:GetCurrentRechargeType()

    local tIntroduction         = PayData.tbTypeToRechargeTypeIntroduction[szCurrentRechargeType]

    local bHasIntroduction      = tIntroduction ~= nil
    UIHelper.SetVisible(self.WidgetDetailDescription, bHasIntroduction and not AppReviewMgr.IsReview())

    if bHasIntroduction then
        UIHelper.SetSpriteFrame(self.ImgDetailDescription, tIntroduction.szTitleImgPath)
        UIHelper.SetRichText(self.RichTextDetailDescription, string.trim(tIntroduction.szRichText, " "))
    end
end

function UITopUpMainView:GetCurrentRechargeType()
    -- todo: 目前预制里的toggle互斥组件上面挂了个layout组件，导致ui这边取不到这个互斥组件，先手动山寨下
    for _, tTogInfo in ipairs(self.tTogInfoList) do
        local bSelected = UIHelper.GetSelected(tTogInfo.uiTog)

        if bSelected then
            return tTogInfo.szType
        end
    end

    return ""
end

return UITopUpMainView