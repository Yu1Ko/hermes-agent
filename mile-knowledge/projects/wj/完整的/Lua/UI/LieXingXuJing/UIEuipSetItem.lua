-- ---------------------------------------------------------------------------------
-- Author: 陈计
-- Name: UIEuipSetItem
-- Date: 2024-03-15 18:07:42
-- Desc: moba商店装备格子里的装备
-- Prefab: WidgetEuipSetItem
-- ---------------------------------------------------------------------------------

---@class UIEuipSetItem
local UIEuipSetItem           = class("UIEuipSetItem")

--- 端游的moba tag frame => 手游对应图片的路径
local tMobaEquipTagFrameToImg = {
    [19] = "UIAtlas2_Pvp_Moba_MobaTagYe.png", -- 野
    [20] = "UIAtlas2_Pvp_Moba_MobaTagFang.png", -- 防
    [21] = "UIAtlas2_Pvp_Moba_MobaTagFu.png", -- 辅
    [22] = "UIAtlas2_Pvp_Moba_MobaTagGong.png", -- 攻
}

---_LuaBindList 在这里对绑定的组件进行无意义自赋值，从而方便查询以及ide进行智能提示
function UIEuipSetItem:_LuaBindList()
    self.LabelName         = self.LabelName --- 名称
    self.LabelPrice        = self.LabelPrice --- 价格
    self.LabelDescription  = self.LabelDescription --- 描述
    self.ImgTag            = self.ImgTag --- 类别标签（野，防，辅，攻）
    self.WidgetItem        = self.WidgetItem --- 挂载道具图标的widget
    self.ImgBought         = self.ImgBought --- 已购买的图标
    self.ImgPrePurchase    = self.ImgPrePurchase --- 预购图标
    self.ToggleSelect      = self.ToggleSelect --- 选中状态的toggle

    self.ImgCanBuy         = self.ImgCanBuy --- 可购买时显示的高亮背景图

    self.ImgItemBgBlack    = self.ImgItemBgBlack --- 在局内快捷购买处展示时增加显示这个黑色背景
    self.Eff_lingQuJiangLi = self.Eff_lingQuJiangLi --- 在局内快捷购买处展示时增加显示这个特效
end

---_LuaTypeList 在这里添加类型注解，从而方便查询以及ide进行智能提示
function UIEuipSetItem:_LuaTypeList()
    -- note: 为了方便写的时候IDE也能提示诸如 c++导出的枚举、临时定义的table列表 的字段，可以像下面示例一样，在这里定义对应类型的信息
    -- note: 定义完后在对应变量的定义处通过 ---@type 注解来标注类型即可
    -- note: 具体 class/type/array/table 格式参考 https://emmylua.github.io/annotation.html

    -- ---@class TypeDemo 示例类型
    -- ---@field NumberParam1 number 数字参数一
    -- ---@field StrParm2 string 字符串参数二
end

---@param tItemInfo MobaShopItemInfo
function UIEuipSetItem:OnEnter(tItemInfo)
    ---@type MobaShopItemInfo 装备配置
    self.tItemInfo     = tItemInfo

    --- 是否是当前装备的后续装备
    self.bIsNextSeries = nil
    --- 是否可以购买
    self.bEnable       = nil

    --- 是否可以卖掉
    self.bSell         = nil

    if not self.bInit then
        self:RegEvent()
        self:BindUIEvent()
        self.bInit = true
    end

    self:UpdateInfo()
end

function UIEuipSetItem:OnExit()
    self.bInit = false
    self:UnRegEvent()
end

function UIEuipSetItem:BindUIEvent()
    UIHelper.SetToggleGroupIndex(self.ToggleSelect, ToggleGroupIndex.MobaEquipmentItem)
end

function UIEuipSetItem:RegEvent()
    --Event.Reg(self, EventType.XXX, func)

    Event.Reg(self, "UPDATE_ACTIVITYAWARD", function(nOldMoney)
        --- 如果是当前装备的后续系列装备，当金币变化时，看看现在是否变成可购买了
        if self.bIsNextSeries then
            local nReallyCost = tonumber(UIHelper.GetString(self.LabelPrice))
            local bCanBuy     = nReallyCost <= g_pClientPlayer.nActivityAward
            self:UpdateCanBuy(bCanBuy)
        end

        self:CheckMoneyEnough()
    end)
end

function UIEuipSetItem:UnRegEvent()
    --Event.UnReg(self, EventType.XXX)
end






-- ----------------------------------------------------------
-- Please write your own code below  ↓↓↓
-- ----------------------------------------------------------

function UIEuipSetItem:UpdateInfo()
    local tItemInfo = self.tItemInfo
    local pItemInfo = ItemData.GetItemInfo(tItemInfo.nItemType, tItemInfo.nItemID)

    UIHelper.SetString(self.LabelName, UIHelper.GBKToUTF8(pItemInfo.szName))

    local nDiamondR, nDiamondG, nDiamondB = GetItemFontColorByQuality(pItemInfo.nQuality)
    UIHelper.SetTextColor(self.LabelName, cc.c3b(nDiamondR, nDiamondG, nDiamondB))
    
    self:UpdatePrice(tItemInfo.nCost)

    local szDescription = ""
    if tItemInfo.szDescription ~= "" then
        --szDescription = string.format("（%s）", UIHelper.GBKToUTF8(tItemInfo.szDescription))
        szDescription = UIHelper.TruncateStringReturnOnlyResult(UIHelper.GBKToUTF8(tItemInfo.szDescription), 7)
    end
    UIHelper.SetString(self.LabelDescription, szDescription)

    UIHelper.SetVisible(self.ImgTag, tItemInfo.nTagFrame ~= 0)
    if tItemInfo.nTagFrame ~= 0 then
        UIHelper.SetSpriteFrame(self.ImgTag, tMobaEquipTagFrameToImg[tItemInfo.nTagFrame])
    end

    do
        local dwItemType, dwItemIndex = tItemInfo.nItemType, tItemInfo.nItemID

        UIHelper.RemoveAllChildren(self.WidgetItem)

        ---@type UIItemIcon
        local scriptItem = UIHelper.AddPrefab(PREFAB_ID.WidgetItem_80, self.WidgetItem)

        scriptItem:OnInitWithTabID(dwItemType, dwItemIndex)
        scriptItem:SetClickNotSelected(true)

        self.scriptItem = scriptItem
    end
end

function UIEuipSetItem:UpdatePrice(nPrice)
    UIHelper.SetString(self.LabelPrice, nPrice)

    self:CheckMoneyEnough()
end

function UIEuipSetItem:CheckMoneyEnough()
    if not BattleFieldData.IsInMobaBattleFieldMap() then
        return
    end

    local nReallyCost = tonumber(UIHelper.GetString(self.LabelPrice))
    local bCanBuy     = nReallyCost <= g_pClientPlayer.nActivityAward

    --- 钱不够的显示红色，其他的显示白色
    if bCanBuy then
        UIHelper.SetTextColor(self.LabelPrice, cc.c3b(255, 255, 255))
    else
        UIHelper.SetTextColor(self.LabelPrice, cc.c3b(255, 118, 118))
    end
end

function UIEuipSetItem:UpdateCanBuy(bEnable)
    self.bEnable = bEnable

    UIHelper.SetVisible(self.ImgCanBuy, self.bEnable)
end

function UIEuipSetItem:UpdateSell(bSell)
    self.bSell = bSell

    UIHelper.SetVisible(self.ImgBought, self.bSell)
end

function UIEuipSetItem:SetPrePurchase(bPrePurchase)
    UIHelper.SetVisible(self.ImgPrePurchase, bPrePurchase)
end

return UIEuipSetItem