-- ---------------------------------------------------------------------------------
-- Author: 陈计
-- Name: UIEquipSetCell
-- Date: 2024-03-15 16:55:21
-- Desc: moba商店的装备格子
-- Prefab: WidgetEquipSetCell
-- ---------------------------------------------------------------------------------

---@class UIEquipSetCell
local UIEquipSetCell = class("UIEquipSetCell")

---_LuaBindList 在这里对绑定的组件进行无意义自赋值，从而方便查询以及ide进行智能提示
function UIEquipSetCell:_LuaBindList()
    -- 五条线，具体颜色通过设置img为 LieXingXuJingData.tLineImage 中的两种图片来实现
    self.ImgLineUpBlack     = self.ImgLineUpBlack --- 上-暗
    self.ImgLineUpLight     = self.ImgLineUpLight --- 上-光
    self.ImgLineDownBlack   = self.ImgLineDownBlack --- 下-暗
    self.ImgLineDownLight   = self.ImgLineDownLight --- 下-光
    self.ImgLineLeftBlack   = self.ImgLineLeftBlack --- 左-暗
    self.ImgLineLeftLight   = self.ImgLineLeftLight --- 左-光
    self.ImgLineRightBlack  = self.ImgLineRightBlack --- 右-暗
    self.ImgLineRightLight  = self.ImgLineRightLight --- 右-光
    self.ImgLinePointBlack  = self.ImgLinePointBlack --- 中-暗
    self.ImgLinePointLight  = self.ImgLinePointLight --- 中-光

    self.WidgetEquipSetItem = self.WidgetEquipSetItem --- 挂载装备的widget
end

---_LuaTypeList 在这里添加类型注解，从而方便查询以及ide进行智能提示
function UIEquipSetCell:_LuaTypeList()
    -- note: 为了方便写的时候IDE也能提示诸如 c++导出的枚举、临时定义的table列表 的字段，可以像下面示例一样，在这里定义对应类型的信息
    -- note: 定义完后在对应变量的定义处通过 ---@type 注解来标注类型即可
    -- note: 具体 class/type/array/table 格式参考 https://emmylua.github.io/annotation.html

    ---@class MobaShopItemInfo moba商店装备信息
    ---@field nID number 装备ID
    ---@field nEquipmentSub number 部位枚举
    ---@field nItemType number 道具类别
    ---@field nItemID number 道具Index
    ---@field szKungfuMountID string 适用的心法列表，以 ; 分隔
    ---@field nIndexX number 路线图横向X轴序号（左到右）
    ---@field nIndexY number 路线图纵向Y轴序号（上到下）
    ---@field nCost number 购买价格
    ---@field nSellingPrice number 出售价格
    ---@field szUpgradeScheme string 前序装备列表，以 ; 分隔，从左到右对应该装备上一级，直至最低级装备
    ---@field szNextItemIDs string 后续装备列表，以 ; 分隔，对应下一级升级分支的所有装备ID
    ---@field szDescription string 装备效果简介
    ---@field nTagFrame number 装备定位tag的frame（19-野，20-防，21-辅，22-攻）
    ---@field szNote string 策划备注
end

function UIEquipSetCell:OnEnter()
    ---@type MobaShopItemInfo 装备配置信息，默认为空，这样填充界面时默认隐藏元素，用于占位
    self.tItemInfo = self.tItemInfo

    if not self.bInit then
        self:RegEvent()
        self:BindUIEvent()
        self.bInit = true
    end
end

function UIEquipSetCell:OnExit()
    self.bInit = false
    self:UnRegEvent()
end

function UIEquipSetCell:BindUIEvent()

end

function UIEquipSetCell:RegEvent()
    --Event.Reg(self, EventType.XXX, func)
end

function UIEquipSetCell:UnRegEvent()
    --Event.UnReg(self, EventType.XXX)
end






-- ----------------------------------------------------------
-- Please write your own code below  ↓↓↓
-- ----------------------------------------------------------

function UIEquipSetCell:UpdateInfo()
    if self.tItemInfo == nil then
        self:HideAllLines()
        return
    end

    UIHelper.RemoveAllChildren(self.WidgetEquipSetItem)
    ---@type UIEuipSetItem
    self.scriptEuipSetItem = UIHelper.AddPrefab(PREFAB_ID.WidgetEuipSetItem, self.WidgetEquipSetItem)
    self.scriptEuipSetItem:OnEnter(self.tItemInfo)
end

function UIEquipSetCell:HideAllLines()
    UIHelper.SetVisible(self.ImgLineUpBlack, false)
    UIHelper.SetVisible(self.ImgLineUpLight, false)
    UIHelper.SetVisible(self.ImgLineDownBlack, false)
    UIHelper.SetVisible(self.ImgLineDownLight, false)
    UIHelper.SetVisible(self.ImgLineLeftBlack, false)
    UIHelper.SetVisible(self.ImgLineLeftLight, false)
    UIHelper.SetVisible(self.ImgLineRightBlack, false)
    UIHelper.SetVisible(self.ImgLineRightLight, false)
    UIHelper.SetVisible(self.ImgLinePointBlack, false)
    UIHelper.SetVisible(self.ImgLinePointLight, false)
end

function UIEquipSetCell:ShowLine(nLineDirection, nLineStyle)
    --- color_style => direction => img
    local tStyleToDirectionToLineImg = {
        [LieXingXuJingData.tLineColorStyle.Black] = {
            [LieXingXuJingData.tLineDirection.Up] = self.ImgLineUpBlack,
            [LieXingXuJingData.tLineDirection.Down] = self.ImgLineDownBlack,
            [LieXingXuJingData.tLineDirection.Left] = self.ImgLineLeftBlack,
            [LieXingXuJingData.tLineDirection.Right] = self.ImgLineRightBlack,
            [LieXingXuJingData.tLineDirection.Middle] = self.ImgLinePointBlack,
        },
        [LieXingXuJingData.tLineColorStyle.Yellow] = {
            [LieXingXuJingData.tLineDirection.Up] = self.ImgLineUpLight,
            [LieXingXuJingData.tLineDirection.Down] = self.ImgLineDownLight,
            [LieXingXuJingData.tLineDirection.Left] = self.ImgLineLeftLight,
            [LieXingXuJingData.tLineDirection.Right] = self.ImgLineRightLight,
            [LieXingXuJingData.tLineDirection.Middle] = self.ImgLinePointLight,
        },
        [LieXingXuJingData.tLineColorStyle.Green] = {
            [LieXingXuJingData.tLineDirection.Up] = self.ImgLineUpLight,
            [LieXingXuJingData.tLineDirection.Down] = self.ImgLineDownLight,
            [LieXingXuJingData.tLineDirection.Left] = self.ImgLineLeftLight,
            [LieXingXuJingData.tLineDirection.Right] = self.ImgLineRightLight,
            [LieXingXuJingData.tLineDirection.Middle] = self.ImgLinePointLight,
        },
    }
    local imgLine                    = tStyleToDirectionToLineImg[nLineStyle][nLineDirection]
    local ccLineColor                = LieXingXuJingData.tLineColorStyleToColor[nLineStyle]

    UIHelper.SetColor(imgLine, ccLineColor)
    UIHelper.SetVisible(imgLine, true)
end

---@param tItemInfo MobaShopItemInfo
function UIEquipSetCell:SetMobaItemInfo(tItemInfo)
    self.tItemInfo = tItemInfo
end

return UIEquipSetCell