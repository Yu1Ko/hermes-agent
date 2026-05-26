-- ---------------------------------------------------------------------------------
-- Author: Unknown
-- Name: UIOperationMonthlyPurchase
-- Date: 2026-04-02 21:00:00
-- Desc: 月度充消活动控制器（OperationCenter 框架）
-- ---------------------------------------------------------------------------------

local UIOperationMonthlyPurchase = class("UIOperationMonthlyPurchase")

-----------------------------DataModel------------------------------

local m_tCurPageInfos = nil     -- 当前期奖励数据列表（从索引2开始是奖励项）
local m_dwMonthID = nil         -- 当前显示页的月度ID
local m_nLevels = 0             -- 奖励档位数量
local m_tAllMonthData = nil      -- 完整排序后的月度数据
local m_nMaxIssue = 0            -- 最大期数
local m_tPrevPageInfos = nil     -- 上一期数据

local ItemType = {
    -- 背部挂件
    BackPendant = 1,
    -- 跟宠
    Pet = 2,
    -- 马具
    HorseEquip = 3,
    -- 马饰
    HorseOrnament = 4,
    -- 奇趣坐骑
    QiquHorse = 5,
    -- 玩具
    Toy = 6,
    -- 腰部挂件
    WaistPendant = 7,
    -- 坐骑
    Horse = 8,
}

local ItemType2TitleImg = {
    [ItemType.BackPendant]   = "UIAtlas2_OperationCenter_PublicModelTitle_BeiBu.png",
    [ItemType.Pet]           = "UIAtlas2_OperationCenter_PublicModelTitle_GengChong.png",
    [ItemType.HorseEquip]    = "UIAtlas2_OperationCenter_PublicModelTitle_MaJu.png",
    [ItemType.HorseOrnament] = "UIAtlas2_OperationCenter_PublicModelTitle_MaShi.png",
    [ItemType.QiquHorse]     = "UIAtlas2_OperationCenter_PublicModelTitle_QiQuZuoQi.png",
    [ItemType.Toy]           = "UIAtlas2_OperationCenter_PublicModelTitle_WanJu.png",
    [ItemType.WaistPendant]  = "UIAtlas2_OperationCenter_PublicModelTitle_YaoBu.png",
    [ItemType.Horse]         = "UIAtlas2_OperationCenter_PublicModelTitle_ZuoQi.png",
}

local function GetItemType(dwTabType, dwIndex)
    local itemInfo = GetItemInfo(dwTabType, dwIndex)
    if not itemInfo then
        return nil
    end

    local szName = ItemData.GetItemNameByItemInfoIndex(dwTabType, dwIndex)
    szName = UIHelper.GBKToUTF8(szName)

    -- 玩具: nGenre == igToy
    if itemInfo.nGenre == ITEM_GENRE.TOY then
        return ItemType.Toy
    end

    -- 装备类: nGenre == igEquipment
    if itemInfo.nGenre == ITEM_GENRE.EQUIPMENT then
        -- 背部挂件
        if itemInfo.nSub == EQUIPMENT_SUB.BACK_EXTEND then
            return ItemType.BackPendant
        -- 腰部挂件
        elseif itemInfo.nSub == EQUIPMENT_SUB.WAIST_EXTEND then
            return ItemType.WaistPendant
        -- 跟宠
        elseif itemInfo.nSub == EQUIPMENT_SUB.PET then
            return ItemType.Pet
        -- 马具
        elseif itemInfo.nSub == EQUIPMENT_SUB.HORSE_EQUIP then
            return ItemType.HorseEquip
        -- 坐骑
        elseif itemInfo.nSub == EQUIPMENT_SUB.HORSE then
            -- 奇趣坐骑: 通过 GetRareHorseInfoList 查询
            local tRareHorseList = GetRareHorseInfoList()
            if tRareHorseList then
                for _, v in pairs(tRareHorseList) do
                    if v.dwItemTabIndex == dwIndex then
                        return ItemType.QiquHorse
                    end
                end
            end
            return ItemType.Horse
        end
    else
        if string.find(szName, "马具") then
            return ItemType.HorseEquip
        end
    end

    return nil
end

local function DataModel_Init()
    local tChongXiaoMon, nMaxIssue = Table_GetChongXiaoMonthly()
    table.sort(tChongXiaoMon, function(tLeft, tRight)
        return tLeft[1].nEndTime < tRight[1].nStartTime
    end)
    m_tAllMonthData = tChongXiaoMon
    m_nMaxIssue = nMaxIssue

    local tPrevPageInfos, tCurPageInfos, tNextPageInfos = HuaELouData.GetDisplayPageInfo(tChongXiaoMon, nMaxIssue)
    m_tCurPageInfos = tCurPageInfos
    m_tPrevPageInfos = tPrevPageInfos
    m_dwMonthID = tCurPageInfos and tCurPageInfos[1] and tCurPageInfos[1].dwID
    m_nLevels = tCurPageInfos and (#tCurPageInfos - 1) or 0
end

local function DataModel_UnInit()
    m_tCurPageInfos = nil
    m_tPrevPageInfos = nil
    m_dwMonthID = nil
    m_nLevels = 0
    m_tAllMonthData = nil
    m_nMaxIssue = 0
end

local function DataModel_SwitchToCurrent()
    local tPrevPageInfos, tCurPageInfos, tNextPageInfos = HuaELouData.GetDisplayPageInfo(m_tAllMonthData, m_nMaxIssue)
    m_tCurPageInfos = tCurPageInfos
    m_dwMonthID = tCurPageInfos and tCurPageInfos[1] and tCurPageInfos[1].dwID
    m_nLevels = tCurPageInfos and (#tCurPageInfos - 1) or 0
end

local function DataModel_SwitchToPast()
    m_tCurPageInfos = m_tPrevPageInfos
    m_dwMonthID = m_tPrevPageInfos and m_tPrevPageInfos[1] and m_tPrevPageInfos[1].dwID
    m_nLevels = m_tPrevPageInfos and (#m_tPrevPageInfos - 1) or 0
end

local function DataModel_GetMonthID()
    return m_dwMonthID
end

local function DataModel_GetRewardInfos()
    return m_tCurPageInfos
end

local function DataModel_GetLevelCount()
    return m_nLevels
end

local function DataModel_GetRewardState(nSubID)
    if not m_dwMonthID then
        return OPERACT_REWARD_STATE.NON_GET
    end
    local tRecharge = HuaELouData.tMonthlyRecharge
    if not tRecharge or not tRecharge[m_dwMonthID] then
        return OPERACT_REWARD_STATE.NON_GET
    end
    return HuaELouData.GetLevelRewardStateOfPlayerByLevel(tRecharge[m_dwMonthID].tRewardInfo, nSubID)
end

local function DataModel_GetMoney()
    local tRecharge = HuaELouData.tMonthlyRecharge
    if tRecharge and m_dwMonthID and tRecharge[m_dwMonthID] then
        return tRecharge[m_dwMonthID].nMoney
    end
    return 0
end

local function DataModel_HasCanGetReward()
    if not m_tCurPageInfos then
        return false
    end
    for i = 2, #m_tCurPageInfos do
        local tInfo = m_tCurPageInfos[i]
        if tInfo.nSubID ~= 0 and tInfo.bShow then
            local nState = DataModel_GetRewardState(tInfo.nSubID)
            if nState == OPERACT_REWARD_STATE.CAN_GET then
                return true
            end
        end
    end
    return false
end

local function DataModel_HasCanGetRewardForPage(tPageInfos)
    if not tPageInfos or not tPageInfos[1] then
        return false
    end
    local nMonthID = tPageInfos[1].dwID
    local tRecharge = HuaELouData.tMonthlyRecharge
    if not tRecharge or not tRecharge[nMonthID] then
        return false
    end
    local tRewardInfo = tRecharge[nMonthID].tRewardInfo
    for i = 2, #tPageInfos do
        local tInfo = tPageInfos[i]
        if tInfo.nSubID ~= 0 and tInfo.bShow then
            local nState = HuaELouData.GetLevelRewardStateOfPlayerByLevel(tRewardInfo, tInfo.nSubID)
            if nState == OPERACT_REWARD_STATE.CAN_GET then
                return true
            end
        end
    end
    return false
end

-----------------------------Controller------------------------------

function UIOperationMonthlyPurchase:OnEnter(nOperationID, nID, tComponentContext)
    if not self.bInit then
        self:RegEvent()
        self:BindUIEvent()
        self.bInit = true
    end

    self.nOperationID = nOperationID
    self.nID = nID
    self.tComponentContext = tComponentContext

    DataModel_Init()

    OperationMonthlyPurchaseData.SetIsCurrent(true)

    self.scriptInfo = tComponentContext and tComponentContext.tScriptLayoutTop and tComponentContext.tScriptLayoutTop[2]
    self.scriptGoto = tComponentContext and tComponentContext.tScriptLayoutTop and tComponentContext.tScriptLayoutTop[3]
    UIHelper.SetPositionX(self.scriptGoto._rootNode, 0)

    local scriptBottom = tComponentContext and tComponentContext.scriptBottom
    if scriptBottom then
        UIHelper.SetSelected(scriptBottom.ToggleSwitch, false, false)
    end

    self:UpdateInfo()

    local nMonthID = DataModel_GetMonthID()
    if nMonthID and nMonthID ~= -1 then
        RemoteCallToServer("On_Recharge_CheckOnSaleMonthly", OPERACT_ID.CHARGE_MONTHLY, nMonthID)
    end
end

function UIOperationMonthlyPurchase:OnExit()
    self.bInit = false
    self.bToggleBound = nil
    self.bGetAllBound = nil

    local tContext = OperationCenterData.GetViewComponentContext()
    local scriptCenter = tContext and tContext.scriptCenter
    if scriptCenter then
        scriptCenter:ShowItemBg("")
    end

    local scriptBottom = tContext and tContext.scriptBottom
    if scriptBottom then
        scriptBottom:Reset()
    end
    DataModel_UnInit()
    self:UnRegEvent()
end

function UIOperationMonthlyPurchase:BindUIEvent()

end

function UIOperationMonthlyPurchase:RegEvent()
    Event.Reg(self, "On_Recharge_CheckOnSaleMonthly_CallBack", function (dwID, tRewardInfo, nMoney, bCanDo, nMonthId)
        if nMonthId == DataModel_GetMonthID() then
            self:UpdateRewardState()
        end
    end)

    Event.Reg(self, "On_Recharge_GetOnSaleMonthlyRwd_CallBack", function (nMonthId, tLevelInfo)
        self:UpdateRewardState()
    end)

    Event.Reg(self, EventType.OnOperationMonthlyPurchaseSelectReward, function(tParam)
        self:OnSelectChange(tParam.nCellIndex, tParam.nRewardIndex)
    end)
end

function UIOperationMonthlyPurchase:UnRegEvent()
    --Event.UnReg(self, EventType.XXX)
end

-- ----------------------------------------------------------
-- Please write your own code below  ↓↓↓
-- ----------------------------------------------------------

function UIOperationMonthlyPurchase:UpdateInfo()
    local scriptBottom = self.tComponentContext and self.tComponentContext.scriptBottom
    if not scriptBottom or not m_tCurPageInfos then
        return
    end

    scriptBottom:SetTitle("充时奖励")
    UIHelper.SetVisible(scriptBottom.ToggleSwitch, true)

    -- 绑定 ToggleSwitch 事件（仅首次绑定）
    if not self.bToggleBound then
        UIHelper.BindUIEvent(scriptBottom.ToggleSwitch, EventType.OnSelectChanged, function(_, bSelected)
            if bSelected then
                DataModel_SwitchToPast()
                OperationMonthlyPurchaseData.SetIsCurrent(false)
            else
                DataModel_SwitchToCurrent()
                OperationMonthlyPurchaseData.SetIsCurrent(true)
            end
            self:UpdateInfo()
            local nMonthID = DataModel_GetMonthID()
            if nMonthID and nMonthID ~= -1 then
                RemoteCallToServer("On_Recharge_CheckOnSaleMonthly", OPERACT_ID.CHARGE_MONTHLY, nMonthID)
            end
        end)
        self.bToggleBound = true
    end

    -- 绑定 BtnBottonNormal1 一键领取（仅首次绑定）
    UIHelper.SetVisible(scriptBottom.BtnBottonNormal1, true)
    if not self.bGetAllBound then
        UIHelper.BindUIEvent(scriptBottom.BtnBottonNormal1, EventType.OnClick, function()
            self:GetAllCallServer()
        end)
        self.bGetAllBound = true
    end

    local nCount = DataModel_GetLevelCount()
    local parent = scriptBottom:GetPrefabParent(nCount)
    UIHelper.SetVisible(parent, true)
    UIHelper.RemoveAllChildren(parent)

    self.tbRewardCell = {}
    local nCellIndex = 0

    for i = #m_tCurPageInfos, 2, -1 do
        local tInfo = m_tCurPageInfos[i]
        if tInfo.nSubID ~= 0 and tInfo.bShow then
            local RewardCell = UIHelper.AddPrefab(scriptBottom.nPrefabID, parent)
            assert(RewardCell)

            nCellIndex = nCellIndex + 1

            local k = nCellIndex
            local tItemInfos = {}
            local tItemSplit = string.split(tInfo.szItems, ";")
            for j = 1, #tItemSplit do
                tItemSplit[j] = string.trim(tItemSplit[j], " ")
                local tBoxInfo = string.split(tItemSplit[j], "_")
                local dwTabType, dwIndex, nStackNum = tonumber(tBoxInfo[2]), tonumber(tBoxInfo[3]), tonumber(tBoxInfo[4])
                if dwTabType and dwIndex and nStackNum then
                    table.insert(tItemInfos, {dwTabType = dwTabType, dwIndex = dwIndex, szRewardTextureFile = tInfo.szRewardTextureFile, szItemPath1 = tInfo.szItemPath1, szItemPath2 = tInfo.szItemPath2})

                    local itemScript = UIHelper.AddPrefab(PREFAB_ID.WidgetItem_80, RewardCell.LayoutItem)
                    if itemScript then
                        itemScript:OnInitWithTabID(dwTabType, dwIndex, nStackNum)
                        itemScript:SetClickNotSelected(true)
                        itemScript:SetToggleSwallowTouches(false)
                        itemScript:SetClickCallback(function (nTabType, nTabID)
                            if nTabType and nTabID then
                                local tips, scriptItemTip = TipsHelper.ShowNodeHoverTipsInDir(PREFAB_ID.WidgetItemTip, RewardCell._rootNode, TipsLayoutDir.AUTO)
                                scriptItemTip:OnInitWithTabID(nTabType, nTabID)
                                scriptItemTip:SetBtnState({})
                            end
                            Event.Dispatch(EventType.OnOperationMonthlyPurchaseSelectReward, {nCellIndex = k, nRewardIndex = j})
                        end)
                    end
                end
            end

            local bTwoItems = #tItemInfos == 2
            UIHelper.SetVisible(RewardCell.BtnChosen, bTwoItems)
            UIHelper.SetVisible(RewardCell.BtnChosen1, bTwoItems)
            UIHelper.SetVisible(RewardCell.BtnChosen2, not bTwoItems)
            UIHelper.SetVisible(RewardCell.ImgChosen, false)
            UIHelper.SetVisible(RewardCell.ImgChosen1, false)
            UIHelper.SetVisible(RewardCell.ImgChosen2, false)
            UIHelper.SetVisible(RewardCell.ImgLine, bTwoItems)

            if bTwoItems then
                UIHelper.BindUIEvent(RewardCell.BtnChosen, EventType.OnClick, function()
                    Event.Dispatch(EventType.OnOperationMonthlyPurchaseSelectReward, {nCellIndex = k, nRewardIndex = 1})
                end)
                UIHelper.BindUIEvent(RewardCell.BtnChosen1, EventType.OnClick, function()
                    Event.Dispatch(EventType.OnOperationMonthlyPurchaseSelectReward, {nCellIndex = k, nRewardIndex = 2})
                end)
            else
                UIHelper.BindUIEvent(RewardCell.BtnChosen2, EventType.OnClick, function()
                    Event.Dispatch(EventType.OnOperationMonthlyPurchaseSelectReward, {nCellIndex = k, nRewardIndex = 1})
                end)
            end

            local szTitle = string.format("%d元", tInfo.nMoney)
            if bTwoItems then
                szTitle = szTitle .. "(二选一)"
            end
            UIHelper.SetString(RewardCell.LabelPurchaseConsunption, szTitle)

            local nSubID = tInfo.nSubID
            UIHelper.BindUIEvent(RewardCell.BtnGetItem, EventType.OnClick, function()
                UIHelper.ShowConfirm(g_tStrings.STR_GET_REWARD_SRUE, function ()
                    local nMonthId = DataModel_GetMonthID()
                    if not nMonthId or -1 == nMonthId then
                        return
                    end
                    RemoteCallToServer("On_Recharge_GetOnSaleMonthlyRwd", OPERACT_ID.CHARGE_MONTHLY, nMonthId, nSubID)
                end)
            end)

            table.insert(self.tbRewardCell, { cell = RewardCell, nSubID = tInfo.nSubID, tItemInfos = tItemInfos })
        end
    end


    if nCount > 3 then
        UIHelper.ScrollViewDoLayout(parent)
        UIHelper.ScrollToLeft(parent, 0)

        local bCanSlide = UIHelper.GetScrollViewSlide(parent)
        if bCanSlide then
            UIHelper.SetVisible(scriptBottom.WidgetArrow, true)
            UIHelper.BindUIEvent(parent, EventType.OnScrollingScrollView, function(_, eventType)
                if eventType == ccui.ScrollviewEventType.containerMoved then
                    UIHelper.SetVisible(scriptBottom.WidgetArrow, false)
                end
                UIHelper.UnBindUIEvent(parent, EventType.OnScrollingScrollView)
            end)
        else
            UIHelper.SetVisible(scriptBottom.WidgetArrow, false)
        end
    else
        UIHelper.LayoutDoLayout(parent)
        UIHelper.SetVisible(scriptBottom.WidgetArrow, false)
    end

    self:UpdateRewardState()

    -- 默认选中第一档第一个道具的场景模型
    if self.tbRewardCell and self.tbRewardCell[#self.tbRewardCell] then
        Event.Dispatch(EventType.OnOperationMonthlyPurchaseSelectReward, {nCellIndex = #self.tbRewardCell, nRewardIndex = 1})
    end
end

function UIOperationMonthlyPurchase:OnSelectChange(nCellIndex, nRewardIndex)
    for k, tEntry in ipairs(self.tbRewardCell) do
        local cell = tEntry.cell
        local bIsSelected = (k == nCellIndex)

        if #tEntry.tItemInfos == 2 then
            UIHelper.SetVisible(cell.ImgChosen, bIsSelected and nRewardIndex == 1)
            UIHelper.SetVisible(cell.ImgChosen1, bIsSelected and nRewardIndex == 2)
            UIHelper.SetVisible(cell.ImgChosen2, false)
        else
            UIHelper.SetVisible(cell.ImgChosen, false)
            UIHelper.SetVisible(cell.ImgChosen1, false)
            UIHelper.SetVisible(cell.ImgChosen2, bIsSelected)
        end
    end

    local tContext = OperationCenterData.GetViewComponentContext()
    local scriptCenter = tContext and tContext.scriptCenter

    -- 展示奖励图片
    if self.tbRewardCell[nCellIndex] then
        local tEntry = self.tbRewardCell[nCellIndex]
        local tItemInfo = tEntry.tItemInfos[nRewardIndex]

        if tItemInfo then
            local szName = ItemData.GetItemNameByItemInfoIndex(tItemInfo.dwTabType, tItemInfo.dwIndex)
            local nItemType = GetItemType(tItemInfo.dwTabType, tItemInfo.dwIndex)
            local szTitleImg = nItemType and ItemType2TitleImg[nItemType] or ""
            scriptCenter:SetContentNameTitle(UIHelper.GBKToUTF8(szName), szTitleImg)

            local szPath = ""
            if not string.is_nil(tItemInfo["szItemPath" .. nRewardIndex]) then
                szPath = tItemInfo["szItemPath" .. nRewardIndex]
                szPath = string.gsub(szPath, "ui/Image/UItimate/OperationCenter/NewChargeGiftMonthly", "Resource/OperationCenter/MonthlyPurchase")
                szPath = string.gsub(szPath, "ui/Image/UItimate/OperationCenter/SinglePicture/MonthlyPurchase", "Resource/OperationCenter/MonthlyPurchase")
                szPath = string.gsub(szPath, "tga", "png")
            elseif tItemInfo.szRewardTextureFile then
                szPath = tItemInfo.szRewardTextureFile
                szPath = string.gsub(szPath, "ui/Image/OperationActivity3/Gift_ChargeGiftMonthly", "Texture/HuaELouReward/MonthlyPurchaseGift")
                szPath = string.gsub(szPath, "tga", "png")
            end
            scriptCenter:ShowItemBg(szPath, true)

            -- scriptCenter:ShowModelInfo(tItemInfo.dwTabType, tItemInfo.dwIndex)
        end
    end
end

function UIOperationMonthlyPurchase:UpdateRewardState()
    if not self.tbRewardCell or not m_tCurPageInfos then
        return
    end

    for k, tEntry in ipairs(self.tbRewardCell) do
        local RewardCell = tEntry.cell
        local nState = DataModel_GetRewardState(tEntry.nSubID)
        UIHelper.SetVisible(RewardCell.LabelNotAchieved, nState == OPERACT_REWARD_STATE.NON_GET)
        UIHelper.SetVisible(RewardCell.LabelAchieved, nState == OPERACT_REWARD_STATE.CAN_GET)
        UIHelper.SetVisible(RewardCell.BtnGetItem, nState == OPERACT_REWARD_STATE.CAN_GET)
        UIHelper.SetVisible(RewardCell.LabelReceived, nState == OPERACT_REWARD_STATE.ALREADY_GOT)
    end

    -- 控制一键领取按钮状态
    local bHasCanGet = DataModel_HasCanGetReward()
    local scriptBottom = self.tComponentContext and self.tComponentContext.scriptBottom
    if scriptBottom then
        UIHelper.SetButtonState(scriptBottom.BtnBottonNormal1, bHasCanGet and BTN_STATE.Normal or BTN_STATE.Disable)
    end

    -- 通知信息区更新
    if self.scriptInfo then
        self.scriptInfo:OnEnter({
            nMoney = DataModel_GetMoney(),
            bHasCanGet = bHasCanGet,
            nMonthID = DataModel_GetMonthID(),
        })
    end

    if self.scriptGoto then
        self.scriptGoto:SetVisibleTitle(false)

        local tbGotoInfos = {
            {
                szTitle = "充值时间",
                clickCallback = function ()
                    UIHelper.OpenWeb(tUrl.Recharge)
                end
            },
            {
                szTitle = "前往商城",
                clickCallback = function ()
                    UIMgr.Open(VIEW_ID.PanelExteriorMain)
                end
            },
        }


        for i = 1, 4, 1 do
            local tbGotoInfo = tbGotoInfos[i]
            if tbGotoInfo then
                self.scriptGoto:SetVisibleTaskCell(i, true)
                self.scriptGoto.tScriptTaskList[i]:UpdateTaskTitle(tbGotoInfo.szTitle, "")
                self.scriptGoto.tScriptTaskList[i]:UpdateTaskHint("")
                self.scriptGoto.tScriptTaskList[i]:UpdateTaskMark("")
                self.scriptGoto.tScriptTaskList[i]:SetfnCallBack(tbGotoInfo.clickCallback)
            else
                self.scriptGoto:SetVisibleTaskCell(i, false)
            end
        end
        UIHelper.LayoutDoLayout(self.scriptGoto.WidgetLayOutTaskList)


    end

    -- 更新当期/往期红点
    local scriptBottom = self.tComponentContext and self.tComponentContext.scriptBottom
    if scriptBottom and scriptBottom.tbImgTogRedPoint then
        local tPrevPageInfos, tCurPageInfos = HuaELouData.GetDisplayPageInfo(m_tAllMonthData, m_nMaxIssue)
        UIHelper.SetVisible(scriptBottom.tbImgTogRedPoint[1], DataModel_HasCanGetRewardForPage(tCurPageInfos))
        UIHelper.SetVisible(scriptBottom.tbImgTogRedPoint[2], DataModel_HasCanGetRewardForPage(tPrevPageInfos))
    end
end

function UIOperationMonthlyPurchase:GetAllCallServer()
    UIHelper.ShowConfirm(g_tStrings.STR_GET_REWARD_SRUE, function ()
        local nMonthId = DataModel_GetMonthID()
        if not nMonthId or -1 == nMonthId then
            return
        end
        RemoteCallToServer("On_Recharge_GetOnSaleMonthlyRwd", OPERACT_ID.CHARGE_MONTHLY, nMonthId)
    end)
end

return UIOperationMonthlyPurchase
