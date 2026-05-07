-- ---------------------------------------------------------------------------------
-- Author: 陈计
-- Name: UIPartnerAccessoryView
-- Date: 2023-11-20 15:49:14
-- Desc: 侠客外观
-- Prefab: PanelPartnerAccessory
-- ---------------------------------------------------------------------------------

---@class UIPartnerAccessoryView
local UIPartnerAccessoryView = class("UIPartnerAccessoryView")

---_LuaBindList 在这里对绑定的组件进行无意义自赋值，从而方便查询以及ide进行智能提示
function UIPartnerAccessoryView:_LuaBindList()
    self.BtnClose               = self.BtnClose --- 关闭页面

    self.MiniScene              = self.MiniScene --- 摆放npc的场景组件

    self.ScrollViewExteriorList = self.ScrollViewExteriorList --- 当前选中类别和来源的已拥有外观列表的 scroll view

    self.TogTypeHair            = self.TogTypeHair --- 外观类型-发型 的toggle
    self.TogTypeChest           = self.TogTypeChest --- 外观类型-成衣 的toggle

    self.TogSourceNpcHave       = self.TogSourceNpcHave --- 外观来源-侠客衣橱 的toggle
    self.TogSourcePlayerGoods   = self.TogSourcePlayerGoods --- 外观来源-我的外观 的toggle
    self.TogSourcePlayerItem    = self.TogSourcePlayerItem --- 外观来源-我的背包 的toggle

    self.BtnSave                = self.BtnSave --- 保存形象 按钮
    self.LabelSave              = self.LabelSave --- 保存形象 按钮的label

    self.BtnBack                = self.BtnBack --- 取回到我的外观 按钮

    self.LayoutButtonList       = self.LayoutButtonList --- 按钮上层的layout

    self.BtnDownloadResource    = self.BtnDownloadResource --- 下载资源 按钮

    self.TouchContainer         = self.TouchContainer --- 用于实现模型旋转的组件

    self.WidgetEmpty            = self.WidgetEmpty --- 没有当前类别外观时的空状态

    self.BtnPreviousPage        = self.BtnPreviousPage --- 上一页
    self.BtnNextPage            = self.BtnNextPage --- 下一页
    self.EditCurrentPage        = self.EditCurrentPage --- 当前页输入框
    self.LabelTotalPage         = self.LabelTotalPage --- 总页数
    self.WidgetPaginate         = self.WidgetPaginate --- 分页组件

    self.EditKindSearch         = self.EditKindSearch --- 搜索框
end

---_LuaTypeList 在这里添加类型注解，从而方便查询以及ide进行智能提示
function UIPartnerAccessoryView:_LuaTypeList()
    -- note: 为了方便写的时候IDE也能提示诸如 c++导出的枚举、临时定义的table列表 的字段，可以像下面示例一样，在这里定义对应类型的信息
    -- note: 定义完后在对应变量的定义处通过 ---@type 注解来标注类型即可
    -- note: 具体 class/type/array/table 格式参考 https://emmylua.github.io/annotation.html
    ---@class NPC_EXTERIOR_TYPE 外观类型
    ---@field HAIR number 发型
    ---@field CHEST number 成衣

    ---@class NPC_EXTERIOR_SOURCE_TYPE 外观来源
    ---@field NPC_HAVE number 侠客衣橱
    ---@field PLAYER_GOODS number 我的外观
    ---@field PLAYER_ITEM number 我的背包

    ---@class TypeTog 外观类型toggle信息
    ---@field nType number 外观类型，枚举参考 NPC_EXTERIOR_TYPE
    ---@field tTog table toggle组件

    ---@class SourceTog 外观来源toggle信息
    ---@field nSource number 外观来源，枚举参考 NPC_EXTERIOR_SOURCE_TYPE
    ---@field tTog table toggle组件

    ---@class NpcExteriorInfo 外观信息
    ---@field nSource number 外观来源，枚举参考 NPC_EXTERIOR_SOURCE_TYPE
    ---@field tData NpcExteriorDataNpcHave | NpcExteriorDataPlayerGoodsHair | NpcExteriorDataPlayerGoodsChest | NpcExteriorDataPlayerItem 外观数据，不同来源和类型的数据格式可能不同

    ---@class NpcExteriorDataNpcHave 外观数据-侠客衣橱
    ---@field nType number 外观类型，枚举参考 NPC_EXTERIOR_TYPE
    ---@field szName string 外观名称
    ---@field dwID number 头发ID 或 外观ID

    ---@class NpcExteriorDataPlayerGoodsHair 外观数据-我的外观-头发
    ---@field nType number | "NPC_EXTERIOR_TYPE.HAIR" 外观类型，固定为头发
    ---@field szName string 外观名称
    ---@field nHairID number 头发ID

    ---@class NpcExteriorDataPlayerGoodsChest 外观数据-我的外观-成衣
    ---@field nType number | "NPC_EXTERIOR_TYPE.CHEST" 外观类型，固定为成衣
    ---@field szName string 外观名称
    ---@field tSub number[] 成衣包含的外观ID列表

    ---@class NpcExteriorDataPlayerItem 外观数据-我的背包
    ---@field nType number 外观类型，枚举参考 NPC_EXTERIOR_TYPE
    ---@field pItem KGItem 道具
end

---@param dwID number 侠客ID
---@param tUIPartnerDetailsView UIPartnerDetailsView 侠客详情界面
function UIPartnerAccessoryView:OnEnter(dwID, tUIPartnerDetailsView)
    --- 侠客ID
    self.dwID                  = dwID
    --- 复用 UIPartnerDetailsView 的场景实例，从而无需再次创建，看起来更连贯
    self.tUIPartnerDetailsView = tUIPartnerDetailsView

    --- 外观类型 HAIR/CHEST
    --- @see NPC_EXTERIOR_TYPE
    self.nType                 = NPC_EXTERIOR_TYPE.CHEST
    --- 来源类型 NPC_HAVE/PLAYER_GOODS/PLAYER_ITEM
    --- @see NPC_EXTERIOR_SOURCE_TYPE
    self.nSource               = NPC_EXTERIOR_SOURCE_TYPE.NPC_HAVE

    ---@type TypeTog[]
    self.tTypeTogList          = {
        { nType = NPC_EXTERIOR_TYPE.HAIR, tTog = self.TogTypeHair, },
        { nType = NPC_EXTERIOR_TYPE.CHEST, tTog = self.TogTypeChest, },
    }

    ---@type SourceTog[]
    self.tSourceTogList        = {
        { nSource = NPC_EXTERIOR_SOURCE_TYPE.NPC_HAVE, tTog = self.TogSourceNpcHave, },
        { nSource = NPC_EXTERIOR_SOURCE_TYPE.PLAYER_GOODS, tTog = self.TogSourcePlayerGoods, },
        { nSource = NPC_EXTERIOR_SOURCE_TYPE.PLAYER_ITEM, tTog = self.TogSourcePlayerItem, },
    }

    self.nPage                 = 1
    self.nPageSize             = 20

    if not self.bInit then
        self:RegEvent()
        self:BindUIEvent()

        self:SetEquippedList()

        self.bInit = true
    end

    self:UpdateInfo()
end

function UIPartnerAccessoryView:OnExit()
    self.bInit = false

    UITouchHelper.UnBindModel()

    self:RevertAllPreviewExteriorToEquipped()
    self:CleanUpModelView()

    self:UnRegEvent()
end

function UIPartnerAccessoryView:BindUIEvent()
    UIHelper.BindUIEvent(self.BtnClose, EventType.OnClick, function()
        UIMgr.Close(self)
    end)

    for idx, tTypeTog in ipairs(self.tTypeTogList) do
        UIHelper.SetToggleGroupIndex(tTypeTog.tTog, ToggleGroupIndex.PartnerExteriorType)
        UIHelper.BindUIEvent(tTypeTog.tTog, EventType.OnClick, function()
            self.nType = tTypeTog.nType

            self:UpdateExteriorList()

            -- 手游版仅限预览当前选中的类别和来源中的外观，因此切换时重置为当前穿着的外观
            self:RevertAllPreviewExteriorToEquipped()
        end)
    end

    -- 与端游一样，默认选中 成衣
    for idx, tTypeTog in ipairs(self.tTypeTogList) do
        local bDefaultSelect = tTypeTog.nType == NPC_EXTERIOR_TYPE.CHEST
        if bDefaultSelect then
            self.nType = tTypeTog.nType
        end
        UIHelper.SetSelected(tTypeTog.tTog, bDefaultSelect)
    end

    for idx, tSourceTog in ipairs(self.tSourceTogList) do
        UIHelper.SetToggleGroupIndex(tSourceTog.tTog, ToggleGroupIndex.PartnerExteriorSource)
        UIHelper.BindUIEvent(tSourceTog.tTog, EventType.OnClick, function()
            self.nSource = tSourceTog.nSource

            self:UpdateExteriorList()
            self:UpdateBtnList()

            -- 手游版仅限预览当前选中的类别和来源中的外观，因此切换时重置为当前穿着的外观
            self:RevertAllPreviewExteriorToEquipped()
        end)
    end

    -- 与端游一样，默认选中 侠客衣橱
    for idx, tSourceTog in ipairs(self.tSourceTogList) do
        local bDefaultSelect = tSourceTog.nSource == NPC_EXTERIOR_SOURCE_TYPE.NPC_HAVE
        if bDefaultSelect then
            self.nSource = tSourceTog.nSource
        end
        UIHelper.SetSelected(tSourceTog.tTog, bDefaultSelect)
    end

    UIHelper.BindUIEvent(self.BtnSave, EventType.OnClick, function()
        self:SavePreview()
    end)

    UIHelper.BindUIEvent(self.BtnBack, EventType.OnClick, function()
        self:OnExteriorRecovery()
    end)

    UIHelper.BindUIEvent(self.BtnDownloadResource, EventType.OnClick, function()
        -- todo: 等商城那边下载资源的接口弄好再接入
    end)

    UIHelper.BindUIEvent(self.BtnPreviousPage, EventType.OnClick, function()
        self.nPage = self.nPage - 1
        self:UpdateExteriorList()
    end)

    UIHelper.BindUIEvent(self.BtnNextPage, EventType.OnClick, function()
        self.nPage = self.nPage + 1
        self:UpdateExteriorList()
    end)

    UIHelper.RegisterEditBoxEnded(self.EditCurrentPage, function()
        local szPage = UIHelper.GetString(self.EditCurrentPage)
        self.nPage   = tonumber(szPage)
        self:UpdateExteriorList()
    end)

    UIHelper.RegisterEditBoxEnded(self.EditKindSearch, function()
        self:UpdateExteriorList()
    end)
end

function UIPartnerAccessoryView:RegEvent()
    --Event.Reg(self, EventType.XXX, func)
    Event.Reg(self, "ON_CHANGE_NPC_EXTERIOR_NOTIFY", function(dwAssistedNpcID, dwType, dwID, nMethod)
        self:OnNpcExteriorChange(dwAssistedNpcID, dwType, nMethod)
    end)

    Event.Reg(self, "ADD_PARTNER_EXTERIOR_CLOSED", function()
        self:UpdateExteriorList()
    end)

    Event.Reg(self, "BAG_ITEM_UPDATE", function()
        self:OnBagItemUpdate()
    end)
end

function UIPartnerAccessoryView:UnRegEvent()
    --Event.UnReg(self, EventType.XXX)
end






-- ----------------------------------------------------------
-- Please write your own code below  ↓↓↓
-- ----------------------------------------------------------

function UIPartnerAccessoryView:UpdateInfo()
    self:UpdateExteriorList()
    self:UpdateBtnList()

    self:UpdateMiniScene(nil, true)
end

function UIPartnerAccessoryView:CleanUpModelView()
    if self.hModelView then
        self.hModelView:release()
        self.hModelView = nil
    end

    self.m_scene = nil
end

function UIPartnerAccessoryView:UpdateMiniScene(tPreviewRepresentID, bUpdate)
    -- 直接使用详情页的场景和model view 实例即可
    self.MiniScene:SetScene(self.tUIPartnerDetailsView.hModelView.m_scene)

    if tPreviewRepresentID or bUpdate then
        -- 预览外观也使用详情页的接口，避免重复代码
        local scriptDownload = UIHelper.GetBindScript(self.WidgetDownloadBtnShell)
        self.tUIPartnerDetailsView:UpdateMiniScene(tPreviewRepresentID, scriptDownload)
    end

    -- 重新绑定转动，避免上面调用侠客详情的代码时覆盖了绑定流程
    UITouchHelper.BindModel(self.TouchContainer, self.tUIPartnerDetailsView.hModelView, nil, nil)
end

function UIPartnerAccessoryView:GetExteriorName(nType, dwID)
    local szName = ""
    if nType == NPC_EXTERIOR_TYPE.HAIR then
        szName = CoinShopHair.GetHairText(dwID)
    elseif nType == NPC_EXTERIOR_TYPE.CHEST then
        local tInfo = GetExterior().GetExteriorInfo(dwID)
        local tLine = Table_GetExteriorSet(tInfo.nSet)
        szName      = tLine.szSetName
    end
    return UIHelper.GBKToUTF8(szName)
end

function UIPartnerAccessoryView:GetPartnerAllExterior(nType)
    local dwPlayerID      = UI_GetClientPlayerID()
    local dwPartnerID     = self.dwID
    local hNpcExteriorMgr = GetNpcExteriorManager()
    local tExteriorList   = hNpcExteriorMgr.GetNpcAllExterior(dwPlayerID, dwPartnerID)
    local szSearchText    = self:GetSearchText()
    local tRes            = {}
    if not tExteriorList then
        return tRes
    end
    for i = #tExteriorList, 1, -1 do
        local tExterior = tExteriorList[i]
        if tExterior.eType == nType then
            local dwID       = tExterior.dwID
            local szName     = self:GetExteriorName(nType, dwID)
            tExterior.szName = szName
            if szSearchText == "" or string.find(szName, szSearchText) then
                table.insert(tRes, tExterior)
            end
        end
    end
    return tRes
end

function UIPartnerAccessoryView:IsExteriorNpcAlreadyHave(nType, dwID)
    local hNpcExteriorMgr = GetNpcExteriorManager()
    if not hNpcExteriorMgr then
        return
    end
    local dwPlayerID  = UI_GetClientPlayerID()
    local dwPartnerID = self.dwID
    local bHave       = hNpcExteriorMgr.CheckAlreadyHave(dwPlayerID, dwPartnerID, nType, dwID)
    return bHave
end

function UIPartnerAccessoryView:GetAllMyExterior(nType)
    local pPlayer = GetClientPlayer()
    if not pPlayer then
        return
    end
    local tMyExterior = {}
    local nStart      = 0
    local nEnd        = 0
    local nAdd        = 1
    if nType == NPC_EXTERIOR_TYPE.CHEST then
        local tMyExteriorList = CoinShopData.GetMyExterior(true, true)
        tMyExterior           = tMyExteriorList.tSetList
        for _, tExterior in ipairs(tMyExterior) do
            local tFilterSub = clone(tExterior.tSub)
            for _, dwID in pairs(tExterior.tSub) do
                local tInfo          = GetExterior().GetExteriorInfo(dwID)
                local bChest         = tInfo.nSubType == EQUIPMENT_SUB.CHEST
                local bCanDressToNpc = tInfo.bCanDressToNpc
                if bCanDressToNpc and bChest then
                    local nTimeType          = pPlayer.GetExteriorTimeLimitInfo(dwID)
                    tExterior.bCanDressToNpc = bCanDressToNpc
                    tExterior.bTimeLimit     = nTimeType and nTimeType ~= COIN_SHOP_TIME_LIMIT_TYPE.PERMANENT
                    tExterior.bHave          = self:IsExteriorNpcAlreadyHave(nType, dwID)

                    local tLine              = Table_GetExteriorSet(tInfo.nSet)
                    tExterior.szName         = UIHelper.GBKToUTF8(tLine.szSetName)
                else
                    RemoveTableValue(tFilterSub, dwID)
                end
            end
            tExterior.tSub = tFilterSub
        end
        local nCount = #tMyExterior
        nStart       = 1
        nEnd         = nCount
        nAdd         = 1
    elseif nType == NPC_EXTERIOR_TYPE.HAIR then
        tMyExterior = pPlayer.GetAllHair(HAIR_STYLE.HAIR)
        for _, tHairInfo in ipairs(tMyExterior) do
            local nHairID            = tHairInfo.dwID
            local tPriceInfo         = GetHairShop().GetHairPrice(pPlayer.nRoleType, HAIR_STYLE.HAIR, nHairID)
            tHairInfo.bCanDressToNpc = tPriceInfo.bCanDressToNpc
            tHairInfo.bHave          = self:IsExteriorNpcAlreadyHave(nType, nHairID)
            tHairInfo.szName         = self:GetExteriorName(nType, nHairID)
        end
        local nCount = #tMyExterior
        nStart       = nCount
        nEnd         = 1
        nAdd         = -1
    end
    local szSearchText = self:GetSearchText()
    local tRes         = {}
    for i = nStart, nEnd, nAdd do
        local tInfo = tMyExterior[i]
        local bShow = tInfo.bCanDressToNpc and not tInfo.bTimeLimit and not tInfo.bHave
        if bShow and (szSearchText == "" or string.find(tInfo.szName, szSearchText)) then
            table.insert(tRes, tInfo)
        end
    end
    return tRes
end

local m_tPackageIndex = {
    INVENTORY_INDEX.PACKAGE,
    INVENTORY_INDEX.PACKAGE1,
    INVENTORY_INDEX.PACKAGE2,
    INVENTORY_INDEX.PACKAGE3,
    INVENTORY_INDEX.PACKAGE4,
    INVENTORY_INDEX.PACKAGE_MIBAO,
}

function UIPartnerAccessoryView:GetAllExteriorItemInMyBag(nType)
    local pPlayer = GetClientPlayer()
    if not pPlayer then
        return
    end
    local szSearchText = self:GetSearchText()
    local tRes         = {}
    local tItemExist   = {}
    for _, dwBox2 in pairs(m_tPackageIndex) do
        local nSize = pPlayer.GetBoxSize(dwBox2) - 1
        for dwX2 = 0, nSize, 1 do
            local item = ItemData.GetPlayerItem(pPlayer, dwBox2, dwX2)
            if item and item.nGenre == ITEM_GENRE.COIN_SHOP_QUANTITY_LIMIT_ITEM then
                if nType == NPC_EXTERIOR_TYPE.CHEST and item.nSub == QUANTITY_LIMIT_ITEM_SUB_TYPE.EXTERIOR or
                        nType == NPC_EXTERIOR_TYPE.HAIR and item.nSub == QUANTITY_LIMIT_ITEM_SUB_TYPE.HAIR then
                    local tInfo          = {
                        nType = nType,
                        pItem = item,
                    }
                    local dwExteriorID   = item.nDetail
                    local bCanDressToNpc = Partner_IsExteriorCanDressToNpc(nType, dwExteriorID)
                    local bHave          = self:IsExteriorNpcAlreadyHave(nType, dwExteriorID)
                    local bExist         = CheckIsInTable(tItemExist, item.dwIndex)
                    if bCanDressToNpc and not bHave and not bExist and (szSearchText == "" or string.find(item.szName, szSearchText)) then
                        table.insert(tRes, tInfo)
                        table.insert(tItemExist, item.dwIndex)
                    end
                end
            end
        end
    end
    return tRes
end

function UIPartnerAccessoryView:SetEquippedList()
    local dwPlayerID        = UI_GetClientPlayerID()
    local dwPartnerID       = self.dwID
    local tEquippedExterior = Partner_GetEquippedExteriorList(dwPlayerID, dwPartnerID)

    --- 当前已装备的外观map
    ---@type table<number, PreviewNpcExteriorInfo>
    self.tEquippedList      = clone(tEquippedExterior)

    --- 用于实现预览功能的外观map
    ---@type table<number, PreviewNpcExteriorInfo>
    self.tSettlementList    = clone(tEquippedExterior)
end

---@param nType number 外观类型，枚举参考 NPC_EXTERIOR_TYPE
---@param tInfo PreviewNpcExteriorInfo 预览外观信息
function UIPartnerAccessoryView:SetSettlementExterior(nType, tInfo)
    self.tSettlementList[nType] = tInfo
    local dwPartnerID           = self.dwID
    self:UpdatePartnerExterior(dwPartnerID, self.tSettlementList)
end

---@param dwPartnerID number 侠客ID
---@param tSettlementList table<number, PreviewNpcExteriorInfo> 外观类别 -> 预览信息
function UIPartnerAccessoryView:UpdatePartnerExterior(dwPartnerID, tSettlementList)
    if dwPartnerID ~= self.dwID then
        return
    end
    local tNpcRepresentID = GetNpcAssistedTemplateRepresentID(dwPartnerID)
    local tRepresentID    = PartnerView.NPCRepresentToPlayerRepresent(tNpcRepresentID)
    for nType, tInfo in pairs(tSettlementList) do
        PartnerExterior.UpdateRepresentID(tRepresentID, nType, tInfo)
    end

    self:UpdateMiniScene(tRepresentID)
end

function UIPartnerAccessoryView:RevertAllPreviewExteriorToEquipped()
    --- 回滚为已装备的外观
    self.tSettlementList = clone(self.tEquippedList)
    local dwPartnerID    = self.dwID
    self:UpdatePartnerExterior(dwPartnerID, self.tSettlementList)
end

function UIPartnerAccessoryView:RevertPreviewExteriorToEquipped(nType)
    if not nType then
        nType = self.nType
    end

    local nSource                    = self.tSettlementList[nType].nSource
    local tEquippedList              = self.tEquippedList

    --- 判断下是否是当前装备的外观（只可能是侠客衣橱中的）
    local bIsCurrentEquippedExterior = false
    if nSource == NPC_EXTERIOR_SOURCE_TYPE.NPC_HAVE and tEquippedList[nType] then
        local dwSellID             = self.tSettlementList[nType].tData.dwID

        local tInfo                = tEquippedList[nType]
        local tData                = tInfo.tData
        bIsCurrentEquippedExterior = tInfo.nSource == nSource and tData.dwID == dwSellID
    end

    local tEquippedInfo
    if nSource == NPC_EXTERIOR_SOURCE_TYPE.NPC_HAVE and bIsCurrentEquippedExterior then
        -- 如果此时点的是侠客衣橱中当前侠客装备的外观，则脱下
        tEquippedInfo = {
            nSource = nSource,
            tData = {
                dwType = nType,
                dwID = 0
            }
        }
    else
        tEquippedInfo = tEquippedList[nType]
    end
    self:SetSettlementExterior(nType, tEquippedInfo)
end

function UIPartnerAccessoryView:SaveCurrentPreviewExterior()
    local hNpcExteriorMgr = GetNpcExteriorManager()
    if not hNpcExteriorMgr then
        return
    end
    local dwPlayerID      = UI_GetClientPlayerID()
    local dwPartnerID     = self.dwID
    local tSettlementList = self.tSettlementList
    for nType, tInfo in pairs(tSettlementList) do
        local tData = tInfo.tData
        local dwID  = tData.dwID
        if dwID == 0 or hNpcExteriorMgr.CheckAlreadyHave(dwPlayerID, dwPartnerID, nType, dwID) then
            local nRetCode = hNpcExteriorMgr.Save({ [1] = { eType = nType, dwID = dwID } }, dwPartnerID)
            if nRetCode ~= NPC_EXTERIOR_ERROR_CODE.SUCCESS then
                local szMsg = Partner_GetChangeExteriorFailTip(nRetCode, dwPartnerID)
                OutputMessage("MSG_ANNOUNCE_NORMAL", szMsg)
                self:OnNpcExteriorChange(dwPartnerID, nType)
            end
        end
    end
end

function UIPartnerAccessoryView:OnNpcExteriorChange(dwPartnerID, dwType, nMethod)
    local dwSelPartnerID = self.dwID
    if dwPartnerID ~= dwSelPartnerID then
        return
    end
    self:SetEquippedList()
    local nType = self.nType
    if dwType == nType then
        self:UpdateExteriorList()
    end
    self:UpdateBtnList()
    self:UpdateMiniScene(nil, true)
end

function UIPartnerAccessoryView:UpdateBtnList()
    self:UpdateSaveBtnState()

    self:UpdateBackBtnState()

    UIHelper.LayoutDoLayout(self.LayoutButtonList)
end

function UIPartnerAccessoryView:UpdateSaveBtnState()
    -- 保存按钮

    local bNeedAddToNpc = self:IsNeedAddToNpc()
    local bChange       = false

    if bNeedAddToNpc then
        -- 需要从其他来源转换，则必定有变动
        bChange = true
    else
        -- 到这里说明预览的装备都是侠客衣橱的，判断下是否与当前穿的不一样
        local tEquippedExterior = self.tEquippedList
        for nType, tInfo in pairs(self.tSettlementList) do
            local tEquipInfo = tEquippedExterior[nType]

            if tEquipInfo and tEquipInfo.nSource == NPC_EXTERIOR_SOURCE_TYPE.NPC_HAVE then
                local tData1 = tEquipInfo.tData
                local tData2 = tInfo.tData
                if tData1.dwID ~= tData2.dwID then
                    bChange = true
                    break
                end
            else
                bChange = true
                break
            end
        end
    end

    UIHelper.SetString(self.LabelSave, bNeedAddToNpc and "添加并保存形象" or "保存形象")
    UIHelper.SetButtonState(self.BtnSave, bChange and BTN_STATE.Normal or BTN_STATE.Disable)
end

function UIPartnerAccessoryView:OpenSettlementPanel()
    local dwPartnerID     = self.dwID
    local tSettlementList = self.tSettlementList
    local tEquippedList   = self.tEquippedList

    self:AddPartnerExterior(dwPartnerID, tSettlementList, tEquippedList)
end

---@param tSettlementList table<number, PreviewNpcExteriorInfo>
function UIPartnerAccessoryView:AddPartnerExterior(dwPartnerID, tSettlementList, tEquippedList)
    if BankLock.CheckHaveLocked(SAFE_LOCK_EFFECT_TYPE.BANK, "") then
        return
    end

    UIMgr.Open(VIEW_ID.PanelPartnerConfirmation, dwPartnerID, tSettlementList, tEquippedList)
end

function UIPartnerAccessoryView:UpdateExteriorList()
    -- 分页
    local tAllSourceExteriorInfoList = self:GetCurrentSourceAndTypeExteriorInfoList()

    self.nTotalPage                  = math.ceil(#tAllSourceExteriorInfoList / self.nPageSize)

    if self.nPage < 1 then
        self.nPage = 1
    end

    if self.nPage > self.nTotalPage then
        self.nPage = self.nTotalPage
    end

    local nStartIndex             = (self.nPage - 1) * self.nPageSize + 1
    local nEndIndex               = self.nPage * self.nPageSize

    ---@type NpcExteriorInfo[]
    local tSourceExteriorInfoList = {}

    for i = nStartIndex, nEndIndex do
        if i >= 1 and i <= #tAllSourceExteriorInfoList then
            table.insert(tSourceExteriorInfoList, tAllSourceExteriorInfoList[i])
        end
    end

    UIHelper.SetVisible(self.WidgetPaginate, self.nTotalPage > 0)
    UIHelper.SetString(self.EditCurrentPage, self.nPage)
    UIHelper.SetString(self.LabelTotalPage, string.format("/%d", self.nTotalPage))

    UIHelper.SetButtonState(self.BtnPreviousPage, self.nPage > 1 and BTN_STATE.Normal or BTN_STATE.Disable)
    UIHelper.SetButtonState(self.BtnNextPage, self.nPage < self.nTotalPage and BTN_STATE.Normal or BTN_STATE.Disable)

    local szSearchPlaceHolder = ""
    if self.nType == NPC_EXTERIOR_TYPE.HAIR then
        szSearchPlaceHolder = "搜索发型"
    else
        szSearchPlaceHolder = "搜索成衣"
    end
    UIHelper.SetPlaceHolder(self.EditKindSearch, szSearchPlaceHolder)

    -- 实际展示
    UIHelper.RemoveAllChildren(self.ScrollViewExteriorList)

    for idx, tExteriorInfo in ipairs(tSourceExteriorInfoList) do
        local nWidgetID
        if tExteriorInfo.tData.nType == NPC_EXTERIOR_TYPE.CHEST then
            nWidgetID = PREFAB_ID.WidgetPartnerAccessoryItem
        else
            nWidgetID = PREFAB_ID.WidgetPartnerHairCell
        end

        ---@see UIPartnerAccessoryItem
        UIHelper.AddPrefab(nWidgetID, self.ScrollViewExteriorList, idx, tExteriorInfo, self)
    end

    UIHelper.ScrollViewDoLayoutAndToTop(self.ScrollViewExteriorList)

    UIHelper.SetVisible(self.WidgetEmpty, table.is_empty(tSourceExteriorInfoList))
end

--- @return NpcExteriorInfo[] 返回当前来源和类别的外观信息列表
function UIPartnerAccessoryView:GetCurrentSourceAndTypeExteriorInfoList()
    local tSourceExteriorInfoList = {}

    local nSource                 = self.nSource
    local nType                   = self.nType

    -- 不同来源的数据格式有所不同，在这里进行处理
    local tDataList               = {}
    if nSource == NPC_EXTERIOR_SOURCE_TYPE.NPC_HAVE then
        -- npc拥有
        local tInfoList = self:GetPartnerAllExterior(nType)
        for _, tInfo in ipairs(tInfoList) do
            table.insert(tDataList, {
                nType = nType,
                szName = tInfo.szName,
                dwID = tInfo.dwID,
            })
        end
    elseif nSource == NPC_EXTERIOR_SOURCE_TYPE.PLAYER_GOODS then
        -- 玩家拥有
        local tInfoList = self:GetAllMyExterior(nType)
        for _, tInfo in ipairs(tInfoList) do
            if nType == NPC_EXTERIOR_TYPE.HAIR then
                table.insert(tDataList, {
                    nType = nType,
                    szName = tInfo.szName,
                    nHairID = tInfo.dwID,
                })
            elseif nType == NPC_EXTERIOR_TYPE.CHEST then
                table.insert(tDataList, {
                    nType = nType,
                    szName = tInfo.szName,
                    tSub = tInfo.tSub,
                })
            end
        end
    elseif nSource == NPC_EXTERIOR_SOURCE_TYPE.PLAYER_ITEM then
        -- 背包道具
        local tInfoList = self:GetAllExteriorItemInMyBag(nType)
        for _, tInfo in ipairs(tInfoList) do
            local pItem = tInfo.pItem
            table.insert(tDataList, {
                nType = nType,
                pItem = tInfo.pItem,
            })
        end
    end

    -- 外层的格式差不多，在这里处理下
    for _, tData in ipairs(tDataList) do
        table.insert(tSourceExteriorInfoList, {
            nSource = nSource,
            tData = tData,
        })
    end

    return tSourceExteriorInfoList
end

function UIPartnerAccessoryView:SavePreview()
    local bNeedAddToNpc = self:IsNeedAddToNpc()
    if bNeedAddToNpc then
        -- 结算界面
        self:OpenSettlementPanel()
    else
        -- 直接保存
        self:SaveCurrentPreviewExterior()
    end
end

function UIPartnerAccessoryView:IsNeedAddToNpc()
    -- 判断是否需要从 我的外观 或 我的背包 转换到 侠客衣橱中
    local bNeedAddToNpc = false

    for _, tPreviewInfo in pairs(self.tSettlementList) do
        if tPreviewInfo.nSource ~= NPC_EXTERIOR_SOURCE_TYPE.NPC_HAVE then
            bNeedAddToNpc = true
            break
        end
    end

    return bNeedAddToNpc
end

function UIPartnerAccessoryView:UpdateBackBtnState()
    -- 取回到我的外观 按钮
    local nType       = self.nType
    local tSettlement = self.tSettlementList[nType]

    -- 当前类别预览的是侠客衣橱中的外观的话，则显示取回按钮
    -- note: 目前外观放回去后（实际放到玩家身上），只有一个侠客外观变更的事件，但此时 我的外观 中的条目的还是之前的状态
    --       而之后外观服务器实际修改完成并同步到客户端时，并不会发事件给UI，所以这里强制仅在选择侠客衣橱的时候允许取回外观，避免 我的外观 界面没有显示出新的外观
    local bShow       = tSettlement and tSettlement.nSource == NPC_EXTERIOR_SOURCE_TYPE.NPC_HAVE and self.nSource == NPC_EXTERIOR_SOURCE_TYPE.NPC_HAVE
    UIHelper.SetVisible(self.BtnBack, bShow)
    if bShow then
        -- 当该部分预览的是非默认外观的话，则启用按钮
        local bEnable = tSettlement.tData.dwID ~= 0
        UIHelper.SetButtonState(self.BtnBack, bEnable and BTN_STATE.Normal or BTN_STATE.Disable)
    end
end

function UIPartnerAccessoryView:OnExteriorRecovery()
    if BankLock.CheckHaveLocked(SAFE_LOCK_EFFECT_TYPE.BANK) then
        return
    end

    local nType       = self.nType
    local tSettlement = self.tSettlementList[nType]
    if tSettlement.nSource ~= NPC_EXTERIOR_SOURCE_TYPE.NPC_HAVE then
        return
    end

    local dwExteriorID = tSettlement.tData.dwID
    if dwExteriorID == 0 then
        return
    end

    local szExteriorName = self:GetExteriorName(nType, dwExteriorID)
    local dwPartnerID    = self.dwID

    local szMessage      = FormatString(g_tStrings.STR_PARTNER_EXTERIOR_RECOVERY, szExteriorName)
    UIHelper.ShowConfirm(szMessage, function()
        local hNpcExteriorMgr = GetNpcExteriorManager()
        local nRetCode        = hNpcExteriorMgr.Retrieve(dwPartnerID, nType, dwExteriorID)
        if nRetCode ~= NPC_EXTERIOR_ERROR_CODE.SUCCESS then
            local szMsg = Partner_GetChangeExteriorFailTip(nRetCode)
            OutputMessage("MSG_ANNOUNCE_NORMAL", szMsg)
        end
    end)
end

function UIPartnerAccessoryView:OnBagItemUpdate()
    local pPlayer = g_pClientPlayer
    if not pPlayer then
        return
    end

    local nSource = self.nSource
    if nSource == NPC_EXTERIOR_SOURCE_TYPE.PLAYER_ITEM then
        self:UpdateExteriorList()
    end

    local tSettlementList = self.tSettlementList
    for nType, tInfo in pairs(tSettlementList) do
        if tInfo.nSource == NPC_EXTERIOR_SOURCE_TYPE.PLAYER_ITEM then
            local tData      = tInfo.tData
            local dwID       = tData.dwID
            local dwBox, dwX = pPlayer.GetItemPos(dwID)
            if not dwBox or not dwX then
                self:RevertPreviewExteriorToEquipped(nType)
                self:UpdateBtnList()
            end
        end
    end
end

function UIPartnerAccessoryView:GetSearchText()
    local szSearchText = UIHelper.GetString(self.EditKindSearch)
    return szSearchText
end

return UIPartnerAccessoryView