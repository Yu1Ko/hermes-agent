-- ---------------------------------------------------------------------------------
-- Author: 陈计
-- Name: UISchemeListCell
-- Date: 2024-03-13 20:01:18
-- Desc: 列星虚境的单个预设方案
-- Prefab: WidgetSchemeListCell
-- ---------------------------------------------------------------------------------

---@class UISchemeListCell
local UISchemeListCell = class("UISchemeListCell")

---_LuaBindList 在这里对绑定的组件进行无意义自赋值，从而方便查询以及ide进行智能提示
function UISchemeListCell:_LuaBindList()
    self.LabelName            = self.LabelName --- 方案名称

    -- 当前选中
    self.LabelCurrently       = self.LabelCurrently --- 当前选中时显示的label
    self.ImgSelectLight       = self.ImgSelectLight --- 当前选中时显示的高亮图片

    -- 未选中
    self.BtnSelect            = self.BtnSelect --- 未选中时的选择按钮

    self.LabelScheme          = self.LabelScheme --- 方案序号

    self.tEquipBtnList        = self.tEquipBtnList --- 装备按钮列表
    self.tEquipEmptyIconList  = self.tEquipEmptyIconList --- 装备空图标列表
    self.tEquipWidgetItemList = self.tEquipWidgetItemList --- 装备道具组件列表
end

---_LuaTypeList 在这里添加类型注解，从而方便查询以及ide进行智能提示
function UISchemeListCell:_LuaTypeList()
    -- note: 为了方便写的时候IDE也能提示诸如 c++导出的枚举、临时定义的table列表 的字段，可以像下面示例一样，在这里定义对应类型的信息
    -- note: 定义完后在对应变量的定义处通过 ---@type 注解来标注类型即可
    -- note: 具体 class/type/array/table 格式参考 https://emmylua.github.io/annotation.html

    -- ---@class TypeDemo 示例类型
    -- ---@field NumberParam1 number 数字参数一
    -- ---@field StrParm2 string 字符串参数二
end

function UISchemeListCell:OnEnter(nPrePurchaseIndex, nKungfuMountID)
    --- 预设方案序号
    self.nPrePurchaseIndex = nPrePurchaseIndex
    self.nKungfuMountID    = nKungfuMountID

    if not self.bInit then
        self:RegEvent()
        self:BindUIEvent()
        self.bInit = true
    end

    self:UpdateInfo()
end

function UISchemeListCell:OnExit()
    self.bInit = false
    self:UnRegEvent()
end

function UISchemeListCell:BindUIEvent()
    UIHelper.BindUIEvent(self.BtnSelect, EventType.OnClick, function()
        local tPrePurchase   = Storage.MobaShop_tPrePurchase.tPlans[self.nKungfuMountID][self.nPrePurchaseIndex]

        local szPlanName     = UIHelper.GBKToUTF8(tPrePurchase.szName)
        local szChineseIndex = g_tStrings.STR_NUMBER[self.nPrePurchaseIndex]

        local szTips         = string.format("确认选择 方案%s %s 吗？", szChineseIndex, szPlanName)
        UIHelper.ShowConfirm(szTips, function()
            self:SelectCurrentPlan()
        end)
    end)
end

function UISchemeListCell:RegEvent()
    --Event.Reg(self, EventType.XXX, func)
    Event.Reg(self, "Moba_SelectPrePurchasePlan", function()
        self:UpdateSelectState()
    end)
end

function UISchemeListCell:UnRegEvent()
    --Event.UnReg(self, EventType.XXX)
end






-- ----------------------------------------------------------
-- Please write your own code below  ↓↓↓
-- ----------------------------------------------------------

function UISchemeListCell:UpdateInfo()
    local tPrePurchase = Storage.MobaShop_tPrePurchase.tPlans[self.nKungfuMountID][self.nPrePurchaseIndex]

    local szPlanName   = UIHelper.GBKToUTF8(tPrePurchase.szName)
    UIHelper.SetString(self.LabelName, szPlanName)

    local szChineseIndex = g_tStrings.STR_NUMBER[self.nPrePurchaseIndex]
    UIHelper.SetString(self.LabelScheme, string.format("方案%s", szChineseIndex))

    self:UpdateSelectState()

    local tEquipments = tPrePurchase

    for nIndex = 1, LieXingXuJingData.EQUIPMENT_TYPE_NUM do
        ---@type MobaShopItemInfo
        local tItemInfo = nil
        local nType

        local nID       = tEquipments["nEquipmentLocalID" .. tostring(nIndex)]
        if nID > 0 then
            tItemInfo = Table_GetMobaShopItemUIInfoByID(nID)
            nType     = tItemInfo.nEquipmentSub
        else
            nType = -1 * nID
        end

        local widgetBtn          = self.tEquipBtnList[nIndex]
        local widgetImgEmptyIcon = self.tEquipEmptyIconList[nIndex]
        local widgetItem         = self.tEquipWidgetItemList[nIndex]

        local szEmptyIcon = LieXingXuJingData.tEquipmentEmptyIcon[nType]
        UIHelper.SetSpriteFrame(widgetImgEmptyIcon, szEmptyIcon)

        UIHelper.RemoveAllChildren(widgetItem)

        if tItemInfo then
            --- 该位置有装备
            local dwItemType, dwItemIndex = tItemInfo.nItemType, tItemInfo.nItemID

            ---@type UIItemIcon
            local scriptItem = UIHelper.AddPrefab(PREFAB_ID.WidgetItem_80, widgetItem)
            UIHelper.SetAnchorPoint(scriptItem._rootNode, 0, 0)

            scriptItem:OnInitWithTabID(dwItemType, dwItemIndex)
            scriptItem:SetClickNotSelected(true)

            scriptItem:SetClickCallback(function(nItemType, nItemIndex)
                Timer.AddFrame(self, 1, function()
                    TipsHelper.ShowItemTips(scriptItem._rootNode, dwItemType, dwItemIndex)
                end)
            end)
        end

        local bHasEquip = tItemInfo ~= nil
        UIHelper.SetVisible(widgetImgEmptyIcon, not bHasEquip)
        UIHelper.SetVisible(widgetItem, bHasEquip)
    end
end

function UISchemeListCell:SelectCurrentPlan()
    Storage.MobaShop_tPrePurchase.tSelectingPlan[self.nKungfuMountID] = self.nPrePurchaseIndex
    Storage.MobaShop_tPrePurchase.Dirty()

    LieXingXuJingData.nPlayerPrePurchaseID = nil

    if BattleFieldData.IsInMobaBattleFieldMap() then
        -- 在moba玩法中时，选择新的预设方案后，需要告知服务器新的方案信息，方便后续提示购买时使用新的配置
        local tPlans = Storage.MobaShop_tPrePurchase.tPlans[self.nKungfuMountID][self.nPrePurchaseIndex]

        RemoteCallToServer("On_Moba_EquipShopPlanSet",
                           tPlans.nEquipmentLocalID1,
                           tPlans.nEquipmentLocalID2,
                           tPlans.nEquipmentLocalID3,
                           tPlans.nEquipmentLocalID4,
                           tPlans.nEquipmentLocalID5,
                           tPlans.nEquipmentLocalID6
        )
    end

    Event.Dispatch("Moba_SelectPrePurchasePlan")
end

function UISchemeListCell:UpdateSelectState()
    local bCurrentSelected = self.nPrePurchaseIndex == Storage.MobaShop_tPrePurchase.tSelectingPlan[self.nKungfuMountID]
    UIHelper.SetVisible(self.LabelCurrently, bCurrentSelected)
    UIHelper.SetVisible(self.ImgSelectLight, bCurrentSelected)
    UIHelper.SetVisible(self.BtnSelect, not bCurrentSelected)
end

return UISchemeListCell