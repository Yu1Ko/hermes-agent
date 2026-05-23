-- ---------------------------------------------------------------------------------
-- Author: 陈计
-- Name: UIEquipSetView
-- Date: 2024-03-14 17:16:08
-- Desc: 列星虚境 出装设置
-- Prefab: PanelEquipSet / PanelEquipSetInterior
-- ---------------------------------------------------------------------------------

---@class UIEquipSetView
local UIEquipSetView = class("UIEquipSetView")

---_LuaBindList 在这里对绑定的组件进行无意义自赋值，从而方便查询以及ide进行智能提示
function UIEquipSetView:_LuaBindList()
    self.BtnClose                        = self.BtnClose --- 关闭按钮

    self.LabelPrePurchasePlanName        = self.LabelPrePurchasePlanName --- 当前选择的预购方案名称

    self.tEquipLabelEquipmentSubNameList = self.tEquipLabelEquipmentSubNameList --- 装备栏位的类别名称label列表
    self.tEquipBtnList                   = self.tEquipBtnList --- 装备按钮列表
    self.tEquipEmptyIconList             = self.tEquipEmptyIconList --- 装备空图标列表
    self.tEquipWidgetItemList            = self.tEquipWidgetItemList --- 装备道具组件列表

    self.BtnSelectPrePurchasePlan        = self.BtnSelectPrePurchasePlan --- 打开选择预购方案界面

    self.TogTabListWeapon                = self.TogTabListWeapon --- 武器tab
    self.TogTabListBoots                 = self.TogTabListBoots --- 鞋子tab
    self.TogTabListHelm                  = self.TogTabListHelm --- 帽子tab
    self.TogTabListChest                 = self.TogTabListChest --- 上衣tab
    self.TogTabListWaist                 = self.TogTabListWaist --- 腰带tab
    self.TogTabListBangle                = self.TogTabListBangle --- 护腕tab

    self.ScrollViewEquipRoadmap          = self.ScrollViewEquipRoadmap --- 装备路线图的scroll view
    self.tEquipRoadmapColumnLayoutList   = self.tEquipRoadmapColumnLayoutList --- 装备路线图的四个纵向layout列表

    -- ------------------------------- 局外商店 -------------------------------
    self.BtnEdit                         = self.BtnEdit --- 编辑按钮

    self.WidgetAnchorRightButton         = self.WidgetAnchorRightButton --- 右侧按钮区域 - 普通模式
    self.WidgetAnchorRightButtonEditMode = self.WidgetAnchorRightButtonEditMode --- 右侧按钮区域 - 编辑模式

    self.EditBoxPrePurchasePlanName      = self.EditBoxPrePurchasePlanName --- 修改预购方案名称 输入框
    self.BtnSave                         = self.BtnSave --- 保存编辑
    self.BtnCancel                       = self.BtnCancel --- 取消编辑

    self.BtnDefault                      = self.BtnDefault --- 将当前序号的预购方案重置为默认配置

    -- ------------------------------- 局内商店 -------------------------------
    self.LabelMobaShopMoney              = self.LabelMobaShopMoney --- 当前的星露
    self.LayoutMobaShopMoney             = self.LayoutMobaShopMoney --- 星露上方的layout

    self.BtnBuyDisabled                  = self.BtnBuyDisabled --- 不可购买时的购买按钮（需置灰）
    self.BtnBuy                          = self.BtnBuy --- 可购买时的购买按钮
    self.LayoutBuy                       = self.LayoutBuy --- 购买按钮的layout
    self.LabelBuyMoney                   = self.LabelBuyMoney --- 购买按钮的价格

    self.BtnBooking                      = self.BtnBooking --- 预购按钮
    self.LabelBooking                    = self.LabelBooking --- 预购按钮的label

    self.BtnSell                         = self.BtnSell --- 出售按钮
    self.LayoutSell                      = self.LayoutSell --- 出售按钮的layout
    self.LabelSellMoney                  = self.LabelSellMoney --- 出售按钮的价格
end

---_LuaTypeList 在这里添加类型注解，从而方便查询以及ide进行智能提示
function UIEquipSetView:_LuaTypeList()
    -- note: 为了方便写的时候IDE也能提示诸如 c++导出的枚举、临时定义的table列表 的字段，可以像下面示例一样，在这里定义对应类型的信息
    -- note: 定义完后在对应变量的定义处通过 ---@type 注解来标注类型即可
    -- note: 具体 class/type/array/table 格式参考 https://emmylua.github.io/annotation.html

    -- ---@class TypeDemo 示例类型
    -- ---@field NumberParam1 number 数字参数一
    -- ---@field StrParm2 string 字符串参数二
end

function UIEquipSetView:OnEnter(bInGame)
    --- 是否在游戏中，局内局外的逻辑会有所区别
    self.bInGame = bInGame

    --- 尝试初始化下moba相关的数据，确保后面流程使用到时已经有数据了
    if not self.bInit then
        LieXingXuJingData.InitPrePurchase(false)

        if self.bInGame then
            LieXingXuJingData.UpdatePlayerEquipment()
        end
    end

    --- tab组件 => 部位枚举
    self.tToggleToEquipmentSub = {
        [self.TogTabListWeapon] = EQUIPMENT_INVENTORY.MELEE_WEAPON,
        [self.TogTabListBoots] = EQUIPMENT_INVENTORY.BOOTS,
        [self.TogTabListHelm] = EQUIPMENT_INVENTORY.HELM,
        [self.TogTabListChest] = EQUIPMENT_INVENTORY.CHEST,
        [self.TogTabListWaist] = EQUIPMENT_INVENTORY.WAIST,
        [self.TogTabListBangle] = EQUIPMENT_INVENTORY.BANGLE,
    }

    self.nEquipmentSub         = self:GetDefaultSelectEquipmentSub()

    ---@type table<number, table<number, UIEquipSetCell>> x => y => WidgetEquipSetCell
    self.tItemGridIndex        = {}
    ---@type table<number, UIEquipSetCell> moba商店装备ID => WidgetEquipSetCell
    self.tItemIDIndex          = {}

    --- 是否处于编辑模式
    self.bInEditMode           = false

    ---@type UIEquipSetCell
    --- 当前的预购装备的格子
    self.hCurrentPrePurchase   = nil

    -- 局内相关参数
    do
        --- 当前选中的装备的格子
        --- @type UIEquipSetCell
        self.hSelectingItem    = nil

        --- 当前购买的装备的格子
        --- @type UIEquipSetCell
        self.hCurrentEquipment = nil
    end

    if not self.bInit then
        self:RegEvent()
        self:BindUIEvent()
        self.bInit = true
    end

    self:UpdateInfo()
end

function UIEquipSetView:OnExit()
    self.bInit = false
    self:UnRegEvent()
end

function UIEquipSetView:BindUIEvent()
    UIHelper.BindUIEvent(self.BtnClose, EventType.OnClick, function()
        UIMgr.Close(self)
    end)

    UIHelper.BindUIEvent(self.BtnSelectPrePurchasePlan, EventType.OnClick, function()
        UIMgr.Open(VIEW_ID.PanelEquipSchemePop)
    end)

    for uiToggle, nEquipmentSub in pairs(self.tToggleToEquipmentSub) do
        UIHelper.SetToggleGroupIndex(uiToggle, ToggleGroupIndex.MobaEquipmentSubTab)

        --- 默认先把每个都取消选中 
        UIHelper.SetSelected(uiToggle, false)

        UIHelper.BindUIEvent(uiToggle, EventType.OnClick, function()
            self:SetEquipmentSub(nEquipmentSub)

            --- 切换tab时，先将装备栏全部取消高亮
            self:TryHighLightCurrentEquipment(nil)

            self:UpdateEquipRoadmap()
        end)
    end
    --- 然后选中当前默认选中的栏位
    for uiToggle, nEquipmentSub in pairs(self.tToggleToEquipmentSub) do
        if nEquipmentSub == self.nEquipmentSub then
            UIHelper.SetSelected(uiToggle, true)
            break
        end
    end

    UIHelper.BindUIEvent(self.BtnEdit, EventType.OnClick, function()
        self.bInEditMode     = true

        -- 备份一份编辑用的数据
        local tPrePurchase   = LieXingXuJingData.GetPrePurchase()
        --- @type MobaShopPrePurchase
        self.tEditEquipments = clone(tPrePurchase)

        self:UpdateInfo()
    end)

    UIHelper.BindUIEvent(self.BtnSave, EventType.OnClick, function()
        local tEquipments, tFlag, szHitText = self.tEditEquipments, {}, ""
        for i = 1, LieXingXuJingData.EQUIPMENT_TYPE_NUM do
            local nID = tEquipments["nEquipmentLocalID" .. tostring(i)]
            if nID and nID > 0 then
                local tItemInfo                = Table_GetMobaShopItemUIInfoByID(nID)
                tFlag[tItemInfo.nEquipmentSub] = true
            end
        end
        for _, nEquipmentSub in ipairs(LieXingXuJingData.tInGameEquipmentSubOrder) do
            if not tFlag[nEquipmentSub] then
                szHitText = szHitText .. string.format("[%s]", g_tStrings.tInventoryNameTable[nEquipmentSub])
            end
        end
        if szHitText == "" then
            szHitText = GetFormatText(g_tStrings.STR_MOBA_SHOP_SAVE_EDIT_CONFIRM1)
        else
            szHitText = GetFormatText(g_tStrings.STR_MOBA_SHOP_SAVE_EDIT_CONFIRM2) .. szHitText
        end

        UIHelper.ShowConfirm(szHitText, function()
            self.bInEditMode            = false

            local szPlanName            = UIHelper.GetString(self.EditBoxPrePurchasePlanName)
            self.tEditEquipments.szName = UIHelper.UTF8ToGBK(szPlanName)

            LieXingXuJingData.SetPrePurchase(self.tEditEquipments)

            self:UpdateInfo()

            TipsHelper.ShowNormalTip(g_tStrings.STR_MOBA_SHOP_SAVE_EDIT)
        end)
    end)

    UIHelper.BindUIEvent(self.BtnCancel, EventType.OnClick, function()
        self.bInEditMode = false

        self:UpdateInfo()
    end)

    UIHelper.BindUIEvent(self.BtnDefault, EventType.OnClick, function()
        UIHelper.ShowConfirm(g_tStrings.STR_MOBA_SHOP_EDIT_SET_DEFAULT_CONFIRM, function()
            LieXingXuJingData.SetDefaultPrePurchase()

            self:UpdateInfo()

            TipsHelper.ShowNormalTip(g_tStrings.STR_MOBA_SHOP_EDIT_SET_DEFAULT)
        end)
    end)

    UIHelper.BindUIEvent(self.BtnBuy, EventType.OnClick, function()
        if not self.hSelectingItem then
            return
        end

        local tItemInfo = self.hSelectingItem.tItemInfo

        RemoteCallToServer("On_Moba_EquipShopBuy", tItemInfo.nEquipmentSub, tItemInfo.nID)
    end)

    UIHelper.BindUIEvent(self.BtnSell, EventType.OnClick, function()
        if not self.hSelectingItem then
            return
        end

        local tItemInfo = self.hSelectingItem.tItemInfo

        local szMessage = string.format("出售价格：%d，是否出售？", tItemInfo.nSellingPrice)
        UIHelper.ShowConfirm(szMessage, function()
            RemoteCallToServer("On_Moba_EquipShopSell", tItemInfo.nEquipmentSub, tItemInfo.nItemType, tItemInfo.nItemID)
        end)
    end)

    UIHelper.BindUIEvent(self.BtnBooking, EventType.OnClick, function()
        if not self.hSelectingItem then
            return
        end

        local tItemInfo                     = self.hSelectingItem.tItemInfo

        --- 当前选择的是否是自定义预购装备
        local bIsSelectingCustomPrePurchase = self:IsSelectingCustomPrePurchase()
        if bIsSelectingCustomPrePurchase then
            -- 是的话，则取消预购
            LieXingXuJingData.nPlayerPrePurchaseID = nil
            RemoteCallToServer("On_Moba_EquipShopPlanCancel", tItemInfo.nEquipmentSub, tItemInfo.nID)
        else
            -- 否则，预购该装备
            --- 先取消预购之前选择的
            if LieXingXuJingData.nPlayerPrePurchaseID then
                local tLine = Table_GetMobaShopItemUIInfoByID(LieXingXuJingData.nPlayerPrePurchaseID)
                if tLine then
                    RemoteCallToServer("On_Moba_EquipShopPlanCancel", tLine.nEquipmentSub, tLine.nID)
                end
            end
            --- 然后更新为本次的
            LieXingXuJingData.nPlayerPrePurchaseID = tItemInfo.nID
            RemoteCallToServer("On_Moba_EquipShopPlanEquip", tItemInfo.nEquipmentSub, tItemInfo.nID)
        end

        --- 刷新下界面
        self:UpdateLines()
        self:SetPrePurchaseEquipment()
        self:UpdateInGameButtons()
    end)
end

function UIEquipSetView:RegEvent()
    --Event.Reg(self, EventType.XXX, func)
    Event.Reg(self, "Moba_SelectPrePurchasePlan", function()
        self:UpdateInfo()

        --- 切换预购方案后，由于装备栏顺序可能变了，这里将左侧tab修改为栏位第一个，确保其被选中
        local nDefaultEquipmentSub = self:GetDefaultSelectEquipmentSub()
        self:SwitchToTab(nDefaultEquipmentSub)
    end)

    Event.Reg(self, "UPDATE_ACTIVITYAWARD", function(nOldMoney)
        self:UpdateMobaMoney()
    end)

    Event.Reg(self, "EQUIP_ITEM_UPDATE", function(nBox, nIndex, bNewAdd)
        LieXingXuJingData.UpdatePlayerEquipment()

        self:UpdateInfo()
    end)
end

function UIEquipSetView:UnRegEvent()
    --Event.UnReg(self, EventType.XXX)
end






-- ----------------------------------------------------------
-- Please write your own code below  ↓↓↓
-- ----------------------------------------------------------

function UIEquipSetView:UpdateInfo()
    local tPrePurchase = LieXingXuJingData.GetPrePurchase()

    local szPlanName   = UIHelper.GBKToUTF8(tPrePurchase.szName)
    UIHelper.SetString(self.LabelPrePurchasePlanName, szPlanName)

    UIHelper.SetButtonState(self.BtnSelectPrePurchasePlan, not self.bInEditMode and BTN_STATE.Normal or BTN_STATE.Disable)

    UIHelper.SetVisible(self.WidgetAnchorRightButton, not self.bInEditMode)
    UIHelper.SetVisible(self.WidgetAnchorRightButtonEditMode, self.bInEditMode)

    if self.bInEditMode then
        UIHelper.SetString(self.EditBoxPrePurchasePlanName, szPlanName)
        UIHelper.SetPlaceHolder(self.EditBoxPrePurchasePlanName, szPlanName)
    end

    self:UpdateEquipListInfo()

    self:UpdateEquipRoadmap()

    if self.bInGame then
        self:UpdateMobaMoney()
        self:UpdateInGameButtons()
    end
end

function UIEquipSetView:UpdateEquipListInfo()
    local tEquipments = LieXingXuJingData.GetPrePurchase()
    if self.bInEditMode then
        tEquipments = self.tEditEquipments
    end

    local tEquipmentSubOrderList = LieXingXuJingData.GetEquipListTypeOrderList(self.bInGame, self.bInEditMode, self.tEditEquipments)
    for nIndex, nType in ipairs(tEquipmentSubOrderList) do
        ---@type MobaPlayerEquippedItemInfo | MobaShopItemInfo
        local tItemInfo = nil
        if self.bInGame then
            tItemInfo = LieXingXuJingData.tPlayerEquipment[nType]
        else
            local nID = tEquipments["nEquipmentLocalID" .. tostring(nIndex)]
            if nID and nID > 0 then
                tItemInfo = Table_GetMobaShopItemUIInfoByID(nID)
            end
        end

        local labelEquipmentSubName = self.tEquipLabelEquipmentSubNameList[nIndex]
        local widgetBtn             = self.tEquipBtnList[nIndex]
        local widgetImgEmptyIcon    = self.tEquipEmptyIconList[nIndex]
        local widgetItem            = self.tEquipWidgetItemList[nIndex]

        local szEquipmentSubName    = g_tStrings.tInventoryNameTable[nType]
        UIHelper.SetString(labelEquipmentSubName, szEquipmentSubName)

        local szEmptyIcon = LieXingXuJingData.tEquipmentEmptyIcon[nType]
        UIHelper.SetSpriteFrame(widgetImgEmptyIcon, szEmptyIcon)

        UIHelper.RemoveAllChildren(widgetItem)

        if table.get_len(tItemInfo) > 0 then
            local dwItemType, dwItemIndex = tItemInfo.nItemType, tItemInfo.nItemID

            ---@type UIItemIcon
            local scriptItem              = UIHelper.AddPrefab(PREFAB_ID.WidgetItem_80, widgetItem)

            scriptItem:OnInitWithTabID(dwItemType, dwItemIndex)
            UIHelper.SetToggleGroupIndex(scriptItem.ToggleSelect, ToggleGroupIndex.MobaEquipmentListItem)

            scriptItem:SetClickCallback(function(nItemType, nItemIndex)
                Timer.AddFrame(self, 1, function()
                    local _, scriptItemTips = TipsHelper.ShowItemTips(scriptItem._rootNode, dwItemType, dwItemIndex)
                    scriptItemTips:HidePreviewBtn(true)
                    UIHelper.SetVisible(scriptItemTips.WidgetEquipCompare, false)
                    UIHelper.SetVisible(scriptItemTips.WidgetItemShare, false)

                    local tBtnList = {}

                    if self.bInEditMode then
                        tBtnList = {
                            {
                                szName = "卸下预设",
                                OnClick = function()
                                    self:DeleteEquipmentInEditMode(nIndex)
                                    self:UpdateEquipListInfo()

                                    self:UpdateLines()
                                    self:SetPrePurchaseEquipment()

                                    TipsHelper.DeleteAllHoverTips()
                                end,
                            }
                        }
                    end

                    scriptItemTips:SetBtnState(tBtnList)

                    -- 同时切换到对应分页
                    self:SwitchToTab(tItemInfo.nEquipmentSub)
                    
                    -- 并尝试选中当前装备
                    self:OnClickEquipCell(self.hCurrentEquipment)

                    for nID, cell in pairs(self.tItemIDIndex) do
                        UIHelper.SetSelected(cell.scriptEuipSetItem.ToggleSelect, cell == self.hCurrentEquipment)
                    end
                end)
            end)

            if self.bInEditMode then
                --- ----------------- 编辑模式下拖拽到其他位置来交换栏位装备 -----------------
                --- 开始触摸该道具组件时，记录起始位置
                UIHelper.BindUIEvent(scriptItem.ToggleSelect, EventType.OnTouchBegan, function(btn, x, y)
                    scriptItem.nStartX = x
                    scriptItem.nStartY = y
                end)

                --- 按住开始移动时，若超过一定距离，则创建一个相同的组件，跟随触摸位置去实时移动
                UIHelper.BindUIEvent(scriptItem.ToggleSelect, EventType.OnTouchMoved, function(btn, x, y)
                    if not scriptItem.bMoving then
                        --- 开始移动时，先尝试将装备的道具tips移除
                        if TipsHelper.IsHoverTipsExist(PREFAB_ID.WidgetItemTip) then
                            TipsHelper.DeleteHoverTips(PREFAB_ID.WidgetItemTip)
                        end
                        --- 判断下移动的距离是否足够远，避免太过灵敏
                        local nWidth, _ = UIHelper.GetContentSize(scriptItem._rootNode)
                        local dist      = math.sqrt(math.abs(x - scriptItem.nStartX) ^ 2 + math.abs(y - scriptItem.nStartY) ^ 2)
                        if dist > nWidth / 8 then
                            scriptItem.bMoving = true
                        end
                    else
                        -- 已经在移动中了，则尝试创建移动组件，并更新位置
                        self:OnEquipmentCellTouchMoved(nIndex, dwItemType, dwItemIndex, x, y)
                    end
                end)

                --- 放开手时，定位到六个槽位中与当前移动组件相交，且最近的一个，并交换它
                for _, szEndEvent in ipairs({ EventType.OnTouchEnded, EventType.OnTouchCanceled }) do
                    UIHelper.BindUIEvent(scriptItem.ToggleSelect, szEndEvent, function(btn, x, y)
                        if scriptItem.bMoving then
                            scriptItem.bMoving = false
                            self:OnEquipmentCellTouchEnded()
                        end
                    end)
                end
            end
        else
            UIHelper.BindUIEvent(widgetBtn, EventType.OnClick, function()
                self:SwitchToTab(nType)

                TipsHelper.ShowImportantYellowTip("请选择对应装备进行添加")
            end)
        end

        local bHasEquip = tItemInfo ~= nil
        UIHelper.SetVisible(widgetImgEmptyIcon, not bHasEquip)
        UIHelper.SetVisible(widgetItem, bHasEquip)
    end
end

function UIEquipSetView:SwitchToTab(nTargetEquipmentSub)
    for uiToggle, nEquipmentSub in pairs(self.tToggleToEquipmentSub) do
        if nEquipmentSub == nTargetEquipmentSub then
            UIHelper.SetSelected(uiToggle, true)
            self:SetEquipmentSub(nEquipmentSub)

            self:UpdateEquipRoadmap()
            break
        end
    end
end

function UIEquipSetView:SetEquipmentSub(nEquipmentSub)
    self.nEquipmentSub = nEquipmentSub

    if self.hSelectingItem and self.hSelectingItem.tItemInfo and self.hSelectingItem.tItemInfo.nEquipmentSub ~= self.nEquipmentSub then
        --- 如果切换到了别的类别，则清除当前选中装备
        self.hSelectingItem = nil
        self:UpdateInGameButtons()
    end
end

--- 横向为4格
local MAX_X_COLUMN = 4
--- 纵向为5格
local MAX_Y_ROW    = 5

function UIEquipSetView:UpdateEquipRoadmap()
    for _, uiLayout in ipairs(self.tEquipRoadmapColumnLayoutList) do
        UIHelper.RemoveAllChildren(uiLayout)
    end

    local nKungfuMountID = LieXingXuJingData.GetKungFuMountID()
    --- moba装备配置的list
    ---@type MobaShopItemInfo[]
    local tItemInfos     = Table_GetMobaShopItemInfos(nKungfuMountID)[self.nEquipmentSub]

    -- 先把 4x5 每个格子都填上一个空的占位
    self.tItemGridIndex  = {}
    for x = 1, MAX_X_COLUMN do
        local uiColumnLayout   = self.tEquipRoadmapColumnLayoutList[x]
        self.tItemGridIndex[x] = {}

        for y = 1, MAX_Y_ROW do
            ---@type UIEquipSetCell
            local scriptItem = UIHelper.AddPrefab(PREFAB_ID.WidgetEquipSetCell, uiColumnLayout)
            -- hack: 这里主动调下隐藏线的接口，因为直接默认用里面自动触发的OnEnter/UpdateInfo 表现会很怪，看起来有时序问题，先绕过去
            scriptItem:HideAllLines()
            self.tItemGridIndex[x][y] = scriptItem
        end
    end

    -- 然后开始填充实际的格子
    self.tItemIDIndex = {}
    for _, tItemInfo in ipairs(tItemInfos) do
        local pItemInfo = ItemData.GetItemInfo(tItemInfo.nItemType, tItemInfo.nItemID)
        if pItemInfo then
            local hItem                      = self.tItemGridIndex[tItemInfo.nIndexX][tItemInfo.nIndexY]

            self.tItemIDIndex[tItemInfo.nID] = hItem

            hItem:SetMobaItemInfo(tItemInfo)
            hItem:UpdateInfo()

            -- 默认设置为非当前装备
            hItem.scriptEuipSetItem:UpdateSell(nil)

            hItem.scriptEuipSetItem.scriptItem:SetToggleSwallowTouches(false)

            UIHelper.BindUIEvent(hItem.scriptEuipSetItem.ToggleSelect, EventType.OnClick, function()
                self:OnClickEquipCell(hItem)
            end)

            hItem.scriptEuipSetItem.scriptItem:SetClickCallback(function(nItemType, nItemIndex)
                Timer.AddFrame(self, 1, function()
                    local _, scriptItemTips = TipsHelper.ShowItemTips(hItem.scriptEuipSetItem.scriptItem._rootNode, tItemInfo.nItemType, tItemInfo.nItemID)
                    scriptItemTips:HidePreviewBtn(true)
                    UIHelper.SetVisible(scriptItemTips.WidgetEquipCompare, false)
                    UIHelper.SetVisible(scriptItemTips.WidgetItemShare, false)

                    local tBtnList = {}

                    if self.bInEditMode then
                        local nIndex = 0
                        for i = 1, LieXingXuJingData.EQUIPMENT_TYPE_NUM do
                            local nID = self.tEditEquipments["nEquipmentLocalID" .. tostring(i)]
                            if nID == tItemInfo.nID then
                                nIndex = i
                                break
                            end
                        end

                        local bIsPrePurchase = nIndex > 0

                        if not bIsPrePurchase then
                            tBtnList = {
                                {
                                    szName = "设为预设",
                                    OnClick = function()
                                        self:InsertEquipmentInEditMode(tItemInfo)
                                        self:UpdateEquipListInfo()

                                        self:UpdateLines()
                                        self:SetPrePurchaseEquipment()

                                        TipsHelper.DeleteAllHoverTips()
                                    end,
                                }
                            }
                        else
                            tBtnList = {
                                {
                                    szName = "卸下预设",
                                    OnClick = function()
                                        self:DeleteEquipmentInEditMode(nIndex)
                                        self:UpdateEquipListInfo()

                                        self:UpdateLines()
                                        self:SetPrePurchaseEquipment()

                                        TipsHelper.DeleteAllHoverTips()
                                    end,
                                }
                            }
                        end
                    end

                    scriptItemTips:SetBtnState(tBtnList)
                end)
            end)
        end
    end

    -- 一些局内时特有的流程
    if self.bInGame then
        -- 定位当前已购买的装备
        self:FindUsingEquipment()

        -- 根据已购买情况，更新价格
        self:UpdateEquipmentMsg()
    end

    self:SetPrePurchaseEquipment()

    -- 尝试选中预购装备
    if self.hCurrentPrePurchase then
        self:OnClickEquipCell(self.hCurrentPrePurchase)

        for nID, cell in pairs(self.tItemIDIndex) do
            UIHelper.SetSelected(cell.scriptEuipSetItem.ToggleSelect, cell == self.hCurrentPrePurchase)
        end
    end

    -- 开始绘制连线
    self:UpdateLines()

    for _, uiLayout in ipairs(self.tEquipRoadmapColumnLayoutList) do
        UIHelper.LayoutDoLayout(uiLayout)
    end
    UIHelper.ScrollViewDoLayoutAndToTop(self.ScrollViewEquipRoadmap)
end

function UIEquipSetView:UpdateLines()
    -- 先隐藏所有连线，恢复初始状态
    for nID, uiEquipSetCell in pairs(self.tItemIDIndex) do
        uiEquipSetCell:HideAllLines()
    end

    -- 然后根据逻辑关系绘制连线
    for nID, uiEquipSetCell in pairs(self.tItemIDIndex) do
        self:ShowItemRelation(uiEquipSetCell, LieXingXuJingData.tLineColorStyle.Black)
    end

    -- 默认点亮部分连线，以后面点亮的优先
    -- 当前选中的装备
    if self.hSelectingItem then
        self:HighlightEquipLevelUpPath(self.hSelectingItem.tItemInfo.nID, LieXingXuJingData.tLineColorStyle.Yellow)
    end
    if self.bInGame then
        -- 局内高亮当前购买装备
        if self.hCurrentEquipment then
            self:HighlightEquipLevelUpPath(self.hCurrentEquipment.tItemInfo.nID, LieXingXuJingData.tLineColorStyle.Green)
        end
    end
end

---@param hItem UIEquipSetCell
function UIEquipSetView:ShowItemRelation(hItem, nLineStyle)
    local tItemInfo   = hItem.tItemInfo
    local nPreviousID = tonumber(SplitString(tItemInfo.szUpgradeScheme, ';')[1])
    if not nPreviousID then
        return
    end
    local hPreviousItem     = self.tItemIDIndex[nPreviousID]
    local tPreviousItemInfo = hPreviousItem.tItemInfo

    -- 显示前一个的 右线
    hPreviousItem:ShowLine(LieXingXuJingData.tLineDirection.Right, nLineStyle)

    -- 显示自己的 左线和中点
    hItem:ShowLine(LieXingXuJingData.tLineDirection.Left, nLineStyle)
    hItem:ShowLine(LieXingXuJingData.tLineDirection.Middle, nLineStyle)

    -- 处理当前装备和其前序装备的y轴区间内的连线
    local nMinY, nMaxY
    if tPreviousItemInfo.nIndexY > tItemInfo.nIndexY then
        nMinY, nMaxY = tItemInfo.nIndexY, tPreviousItemInfo.nIndexY
    else
        nMinY, nMaxY = tPreviousItemInfo.nIndexY, tItemInfo.nIndexY
    end
    if nMinY ~= nMaxY then
        -- 区间最上方的装备显示 下线和中点
        local topCell = self.tItemGridIndex[tItemInfo.nIndexX][nMinY]
        topCell:ShowLine(LieXingXuJingData.tLineDirection.Down, nLineStyle)
        topCell:ShowLine(LieXingXuJingData.tLineDirection.Middle, nLineStyle)

        -- 区间最下方的装备显示 上线和中点
        local bottomCell = self.tItemGridIndex[tItemInfo.nIndexX][nMaxY]
        bottomCell:ShowLine(LieXingXuJingData.tLineDirection.Up, nLineStyle)
        bottomCell:ShowLine(LieXingXuJingData.tLineDirection.Middle, nLineStyle)

        for i = nMinY + 1, nMaxY - 1, 1 do
            -- 中间的装备则显示 上线、中点和下线
            local middleCell = self.tItemGridIndex[tItemInfo.nIndexX][i]
            middleCell:ShowLine(LieXingXuJingData.tLineDirection.Down, nLineStyle)
            middleCell:ShowLine(LieXingXuJingData.tLineDirection.Up, nLineStyle)
            middleCell:ShowLine(LieXingXuJingData.tLineDirection.Middle, nLineStyle)
        end
    end

    self:ShowItemRelation(hPreviousItem, nLineStyle)
end

function UIEquipSetView:HighlightEquipLevelUpPath(nID, nLineColorStyle)
    local uiEquipSetCell = self.tItemIDIndex[nID]

    self:ShowItemRelation(uiEquipSetCell, nLineColorStyle)
end

---@param tItemInfo MobaShopItemInfo
function UIEquipSetView:InsertEquipmentInEditMode(tItemInfo)
    local nIndex, nEmptyIndex
    for i = 1, LieXingXuJingData.EQUIPMENT_TYPE_NUM do
        local nID = self.tEditEquipments["nEquipmentLocalID" .. tostring(i)]
        if nID then
            if nID > 0 then
                local tInfo = Table_GetMobaShopItemUIInfoByID(nID)
                if tInfo.nEquipmentSub == tItemInfo.nEquipmentSub then
                    nIndex = i
                end
            else
                if -1 * nID == tItemInfo.nEquipmentSub then
                    nIndex = i
                end
            end
        else
            nEmptyIndex = nEmptyIndex or i
        end
    end
    if nIndex then
        self.tEditEquipments["nEquipmentLocalID" .. tostring(nIndex)] = tItemInfo.nID
    elseif nEmptyIndex then
        self.tEditEquipments["nEquipmentLocalID" .. tostring(nEmptyIndex)] = tItemInfo.nID
    end
end

function UIEquipSetView:DeleteEquipmentInEditMode(nIndex)
    local nID = self.tEditEquipments["nEquipmentLocalID" .. tostring(nIndex)]
    if nID and nID > 0 then
        local tInfo = Table_GetMobaShopItemUIInfoByID(nID)
        -- 清空时，这样填写，是为了方便后续判断该空格子实际对应哪个部位
        nID         = -1 * tInfo.nEquipmentSub
    end
    self.tEditEquipments["nEquipmentLocalID" .. tostring(nIndex)] = nID
end

function UIEquipSetView:UpdateMobaMoney()
    if not g_pClientPlayer then
        return
    end
    if not BattleFieldData.IsInMobaBattleFieldMap() then
        return
    end

    UIHelper.SetString(self.LabelMobaShopMoney, g_pClientPlayer.nActivityAward)
    UIHelper.LayoutDoLayout(self.LayoutMobaShopMoney)
end

function UIEquipSetView:UpdateInGameButtons()
    UIHelper.SetButtonState(self.BtnBuyDisabled, BTN_STATE.Disable)

    UIHelper.SetVisible(self.BtnBooking, false)
    UIHelper.SetVisible(self.BtnBuyDisabled, false)

    UIHelper.SetVisible(self.BtnSell, false)
    UIHelper.SetVisible(self.BtnBuy, false)

    if self.hSelectingItem then
        local bCanBuy = self.hSelectingItem.scriptEuipSetItem.bEnable
        local bSell   = self.hSelectingItem == self.hCurrentEquipment or self.hSelectingItem.scriptEuipSetItem.bSell

        if bCanBuy then
            -- 可购买
            local szReallyCost = UIHelper.GetString(self.hSelectingItem.scriptEuipSetItem.LabelPrice)
            UIHelper.SetString(self.LabelBuyMoney, szReallyCost)
            UIHelper.LayoutDoLayout(self.LayoutBuy)
        end

        if bSell then
            -- 可出售
            local tItemInfo = self.hSelectingItem.tItemInfo
            UIHelper.SetString(self.LabelSellMoney, tItemInfo.nSellingPrice)
            UIHelper.LayoutDoLayout(self.LayoutSell)
        else
            -- 不可出售则显示预购或取消预购
            if self:IsSelectingCustomPrePurchase() then
                UIHelper.SetString(self.LabelBooking, g_tStrings.STR_MOBA_PREPURCHASE_CANCEL)
            else
                UIHelper.SetString(self.LabelBooking, g_tStrings.STR_MOBA_PREPURCHASE)
            end
        end

        UIHelper.SetVisible(self.BtnBuy, bCanBuy)
        UIHelper.SetVisible(self.BtnBuyDisabled, not bCanBuy)

        UIHelper.SetVisible(self.BtnSell, bSell)
        UIHelper.SetVisible(self.BtnBooking, not bSell)
    end
end

--- 当前选择的装备是否是游戏内的自定义预购装备
function UIEquipSetView:IsSelectingCustomPrePurchase()
    return self.hSelectingItem == self.hCurrentPrePurchase and self.hSelectingItem.scriptEuipSetItem.tItemInfo.nID == LieXingXuJingData.nPlayerPrePurchaseID
end

function UIEquipSetView:FindUsingEquipment()
    local tCurrent         = LieXingXuJingData.tPlayerEquipment[self.nEquipmentSub]

    self.hCurrentEquipment = nil

    for nID, uiEquipSetCell in pairs(self.tItemIDIndex) do
        local tItemInfo = uiEquipSetCell.tItemInfo
        if tItemInfo.nItemType == tCurrent.nItemType and tItemInfo.nItemID == tCurrent.nItemID then
            -- 当前购买的装备
            self.hCurrentEquipment = uiEquipSetCell

            uiEquipSetCell.scriptEuipSetItem:UpdateSell(true)
            self:OnClickEquipCell(uiEquipSetCell)
        else
            uiEquipSetCell.scriptEuipSetItem:UpdateSell(nil)
        end
    end
end

---@param uiEquipSetCell UIEquipSetCell
function UIEquipSetView:OnClickEquipCell(uiEquipSetCell)
    local tItemInfo     = uiEquipSetCell.tItemInfo

    --- 更新选中装备
    self.hSelectingItem = uiEquipSetCell

    --- 更新连线
    self:UpdateLines()

    --- 更新下方按钮状态
    self:UpdateInGameButtons()

    --- 如果是当前装备栏中的对应装备，将装备栏对应装备点亮
    self:TryHighLightCurrentEquipment(tItemInfo)
end

function UIEquipSetView:TryHighLightCurrentEquipment(tItemInfo)
    do
        for _, widgetItem in pairs(self.tEquipWidgetItemList) do
            local uiItemList = UIHelper.GetChildren(widgetItem)
            if table.get_len(uiItemList) > 0 then
                ---@type UIItemIcon
                local scriptItem      = UIHelper.GetBindScript(uiItemList[1])

                local tWidgetItemInfo = Table_GetMobaShopItemInfo(scriptItem.nTabType, scriptItem.nTabID)
                UIHelper.SetSelected(scriptItem.ToggleSelect, tItemInfo and tWidgetItemInfo.nItemType == tItemInfo.nItemType and tWidgetItemInfo.nItemID == tItemInfo.nItemID)
            end
        end
    end
end

--- 更新每件装备最新的购买所需价格
function UIEquipSetView:UpdateEquipmentMsg()
    --- 初始化每件装备的价格
    for nID, uiEquipSetCell in pairs(self.tItemIDIndex) do
        local tItemInfo = uiEquipSetCell.tItemInfo

        uiEquipSetCell.scriptEuipSetItem:UpdatePrice(tItemInfo.nCost)
        uiEquipSetCell.scriptEuipSetItem.bIsNextSeries = nil
        uiEquipSetCell.scriptEuipSetItem:UpdateCanBuy(nil)
    end

    --- 根据当前购买的装备的信息，刷新其后续系列装备的价格
    if self.hCurrentEquipment then
        self:UpdateItemMsg(self.hCurrentEquipment, self.hCurrentEquipment.tItemInfo.nCost)
    else
        if self.tItemGridIndex[1] then
            for _, hItem in pairs(self.tItemGridIndex[1]) do
                if hItem.tItemInfo and hItem.tItemInfo.nCost <= g_pClientPlayer.nActivityAward then
                    hItem.scriptEuipSetItem.bIsNextSeries = true
                    hItem.scriptEuipSetItem:UpdateCanBuy(true)
                    self:UpdateItemMsg(hItem, 0)
                end
            end
        end
    end
end

---@param hLastItem UIEquipSetCell 上一级装备
---@param nUsedMoney number 前序装备已经花掉的钱
function UIEquipSetView:UpdateItemMsg(hLastItem, nUsedMoney)
    local tItemInfo    = hLastItem.tItemInfo
    local tNextItemIDs = SplitString(tItemInfo.szNextItemIDs, ';')
    for _, szID in ipairs(tNextItemIDs) do
        local hItem       = self.tItemIDIndex[tonumber(szID)]
        local nReallyCost = hItem.tItemInfo.nCost - nUsedMoney

        hItem.scriptEuipSetItem:UpdatePrice(nReallyCost)
        hItem.scriptEuipSetItem.bIsNextSeries = true
        hItem.scriptEuipSetItem:UpdateCanBuy(nReallyCost <= g_pClientPlayer.nActivityAward)
        self:UpdateItemMsg(hItem, nUsedMoney)
    end
end

function UIEquipSetView:SetPrePurchaseEquipment()
    -- 高亮预设装备的升级路径
    local nPrePurchaseID     = self:GetPrePurchaseID()

    self.hCurrentPrePurchase = nil

    for nID, uiEquipSetCell in pairs(self.tItemIDIndex) do
        local tItemInfo    = uiEquipSetCell.tItemInfo

        local bPrePurchase = tItemInfo.nID == nPrePurchaseID

        if bPrePurchase then
            self.hCurrentPrePurchase = uiEquipSetCell
        end
        uiEquipSetCell.scriptEuipSetItem:SetPrePurchase(bPrePurchase)
    end
end

function UIEquipSetView:GetPrePurchaseID()
    local nPrePurchaseID = LieXingXuJingData.GetInGamePlayerPrePurchaseIDOrPresetID(self.nEquipmentSub)

    if self.bInEditMode then
        for i = 1, LieXingXuJingData.EQUIPMENT_TYPE_NUM do
            local nID = self.tEditEquipments["nEquipmentLocalID" .. tostring(i)]
            if nID then
                if nID > 0 then
                    local tInfo = Table_GetMobaShopItemUIInfoByID(nID)
                    if tInfo.nEquipmentSub == self.nEquipmentSub then
                        nPrePurchaseID = nID
                        break
                    end
                else
                    if -1 * nID == self.nEquipmentSub then
                        nPrePurchaseID = nID
                        break
                    end
                end
            end
        end
    end

    return nPrePurchaseID
end

--- 编辑模式下，拖动装备栏的时候，创建一个用于预览的可拖动组件
function UIEquipSetView:OnEquipmentCellTouchMoved(nIndex, dwItemType, dwItemIndex, x, y)
    if not self.bInEditMode then return end

    local uiMovingCellParent = self._rootNode

    --- 创建一个长得一样的组件，用来移动时预览
    if not self.movingCell then
        ---@type UIItemIcon
        self.movingCell = UIHelper.AddPrefab(PREFAB_ID.WidgetItem_80, uiMovingCellParent)
        self.movingCell:OnInitWithTabID(dwItemType, dwItemIndex)
        UIHelper.SetAnchorPoint(self.movingCell._rootNode, 0.5, 0.5)

        --- 记录下当前移动的装备的装备栏序号
        self.nMoveCellIndex = nIndex
    end

    --- 更新移动组件的位置
    local nLocalX, nLocalY = UIHelper.ConvertToNodeSpace(uiMovingCellParent, x, y)
    UIHelper.SetPosition(self.movingCell._rootNode, nLocalX, nLocalY, uiMovingCellParent)

    -- 如果当前移动到了其他装备栏位上，则将其高亮
    local dstCellIndex = self:CheckMovingCellPosEquipCellIndex()
    if dstCellIndex then
        local nID = self.tEditEquipments["nEquipmentLocalID" .. tostring(dstCellIndex)]
        if nID and nID > 0 then
            local tItemInfo = Table_GetMobaShopItemUIInfoByID(nID)
            self:TryHighLightCurrentEquipment(tItemInfo)
        else
            -- todo: 如果空位也让它高亮的话，可能需要交互在栏位本身上加一个高亮的组件，而不是道具框里的
            self:TryHighLightCurrentEquipment(nil)
        end
    end
end

--- 编辑模式下，拖动装备栏结束时，交换栏位
function UIEquipSetView:OnEquipmentCellTouchEnded()
    if not self.bInEditMode then return end

    if not self.movingCell then
        return
    end

    --- 定位到与预览移动格子相交且最近的装备栏位，并与其交互案
    local dstCellIndex = self:CheckMovingCellPosEquipCellIndex()
    if dstCellIndex then
        if self.nMoveCellIndex == dstCellIndex then
            TipsHelper.ShowNormalTip("编辑模式下，可拖动装备来交换栏位")
        else
            local szKeySrc                                                 = "nEquipmentLocalID" .. tostring(self.nMoveCellIndex)
            local szKeyDst                                                 = "nEquipmentLocalID" .. tostring(dstCellIndex)

            -- 将两个栏位交换
            self.tEditEquipments[szKeySrc], self.tEditEquipments[szKeyDst] = self.tEditEquipments[szKeyDst], self.tEditEquipments[szKeySrc]

            self:UpdateEquipListInfo()
            if self.movingCell then
                local tItemInfo = Table_GetMobaShopItemInfo(self.movingCell.nTabType, self.movingCell.nTabID)
                if tItemInfo then
                    self:TryHighLightCurrentEquipment(tItemInfo)
                end
            end

            LOG.DEBUG("交换装备栏位 %d <=> %d", self.nMoveCellIndex, dstCellIndex)
        end
    end

    --- 清理移动状态
    self.movingCell._rootNode:removeFromParent(true)
    self.movingCell     = nil
    self.nMoveCellIndex = nil
end

--- 检查移动的装备的当前位置是否与某个装备栏位重叠，若是，则返回该栏位的序号（若有多个，则返回最近的那个），否则返回nil
function UIEquipSetView:CheckMovingCellPosEquipCellIndex()
    if not self.movingCell then
        return nil
    end

    local dstCellIndex = nil
    local nMinDist     = 2 ^ 30

    local nX, nY       = UIHelper.GetPosition(self.movingCell._rootNode)
    local nW, nH       = UIHelper.GetContentSize(self.movingCell._rootNode)
    local rect1        = cc.rect(nX, nY, nW, nH)

    for nIndex, uiEquipBtn in ipairs(self.tEquipBtnList) do
        local nX2, nY2 = UIHelper.GetWorldPosition(uiEquipBtn)
        nX2, nY2       = UIHelper.ConvertToNodeSpace(self._rootNode, nX2, nY2)
        local rect2    = cc.rect(nX2, nY2, rect1.width, rect1.height)

        if cc.rectIntersectsRect(rect1, rect2) then
            local nCurDist = math.sqrt(math.abs(rect1.x - rect2.x) ^ 2 + math.abs(rect1.y - rect2.y) ^ 2)
            if nCurDist < nMinDist then
                nMinDist     = nCurDist
                dstCellIndex = nIndex
            end
        end
    end

    return dstCellIndex
end

function UIEquipSetView:GetDefaultSelectEquipmentSub()
    -- 默认选中装备栏第一个位置对应装备的装备类别的tab
    local tEquipmentSubOrderList = LieXingXuJingData.GetEquipListTypeOrderList(self.bInGame, self.bInEditMode, self.tEditEquipments)
    local nDefaultEquipmentSub   = tEquipmentSubOrderList[1]

    return nDefaultEquipmentSub
end

return UIEquipSetView
