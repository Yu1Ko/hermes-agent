-- ---------------------------------------------------------------------------------
-- Author: 陈计
-- Name: UIPartnerTravelListTog
-- Date: 2024-11-21 14:46:06
-- Desc: 侠客出行牌子
-- Prefab: WidgetPartnerTravelListTog
-- ---------------------------------------------------------------------------------

---@class UIPartnerTravelListTog
local UIPartnerTravelListTog = class("UIPartnerTravelListTog")

---_LuaBindList 在这里对绑定的组件进行无意义自赋值，从而方便查询以及ide进行智能提示
function UIPartnerTravelListTog:_LuaBindList()
    self.ToggleTravel              = self.ToggleTravel --- 组件的toggle
    self.ImgLock                   = self.ImgLock --- 锁定的图标
    self.LabelHintLock             = self.LabelHintLock --- 锁定的提示

    -- 选中
    self.LabelEmptyNameSelect      = self.LabelEmptyNameSelect --- 未设置出行类别时的牌子名
    self.LabelClassNameSelect      = self.LabelClassNameSelect --- 出行类别名称
    self.LabelClassCountInfoSelect = self.LabelClassCountInfoSelect --- 出行类别次数信息
    self.ImgIconSelect             = self.ImgIconSelect --- 牌子的图标
    self.WidgetSelect01            = self.WidgetSelect01 --- 选中时的顶层组件

    -- 未选中
    self.LabelEmptyName            = self.LabelEmptyName --- 未设置出行类别时的牌子名
    self.LabelClassName            = self.LabelClassName --- 出行类别名称
    self.LabelClassCountInfo       = self.LabelClassCountInfo --- 出行类别次数信息
    self.ImgIcon                   = self.ImgIcon --- 牌子的图标
    self.ImgBg                     = self.ImgBg --- 未选中时的顶层组件

    self.ImgRedPoint               = self.ImgRedPoint --- 有可领取奖励的槽位时显示红点
end

---_LuaTypeList 在这里添加类型注解，从而方便查询以及ide进行智能提示
function UIPartnerTravelListTog:_LuaTypeList()
    -- note: 为了方便写的时候IDE也能提示诸如 c++导出的枚举、临时定义的table列表 的字段，可以像下面示例一样，在这里定义对应类型的信息
    -- note: 定义完后在对应变量的定义处通过 ---@type 注解来标注类型即可
    -- note: 具体 class/type/array/table 格式参考 https://emmylua.github.io/annotation.html

    -- ---@class TypeDemo 示例类型
    -- ---@field NumberParam1 number 数字参数一
    -- ---@field StrParm2 string 字符串参数二
end

function UIPartnerTravelListTog:OnEnter(nBoard)
    self.nBoard = nBoard

    if not self.bInit then
        self:RegEvent()
        self:BindUIEvent()
        self.bInit = true
    end

    self:UpdateInfo()

    Timer.AddCycle(self, 1, function()
        self:UpdateRedPoint()
    end)
end

function UIPartnerTravelListTog:OnExit()
    self.bInit = false
    self:UnRegEvent()
end

function UIPartnerTravelListTog:BindUIEvent()

end

function UIPartnerTravelListTog:RegEvent()
    --Event.Reg(self, EventType.XXX, func)
end

function UIPartnerTravelListTog:UnRegEvent()
    --Event.UnReg(self, EventType.XXX)
end






-- ----------------------------------------------------------
-- Please write your own code below  ↓↓↓
-- ----------------------------------------------------------

function UIPartnerTravelListTog:UpdateInfo()
    UIHelper.SetToggleGroupIndex(self.ToggleTravel, ToggleGroupIndex.PartnerTravelList)

    local bUnlocked = PartnerData.IsTravelBoardUnlocked(self.nBoard)
    if bUnlocked then
        local nClass = PartnerData.GetBoardTravelQuestClass(self.nBoard)
        self:SetClass(nClass)

        self:UpdateRedPoint()
    else
        UIHelper.SetVisible(self.ImgLock, true)
        UIHelper.SetVisible(self.ToggleTravel, false)

        local tBoardInfo   = Table_GetPartnerTravelTeamInfo(self.nBoard)
        local szUnlockHint = UIHelper.GBKToUTF8(tBoardInfo.szUnlockTip)
        UIHelper.SetString(self.LabelHintLock, szUnlockHint)
    end
end

local tClassToIconPath = {
    [1] = "UIAtlas2_Partner_ParterTravel_CardIconQiyu.png", -- 摸宠
    [2] = "UIAtlas2_Partner_ParterTravel_CardIconMijing.png", -- 秘境
    [3] = "UIAtlas2_Partner_ParterTravel_CardIconMingwang.png", -- 名望
    [4] = "UIAtlas2_Partner_ParterTravel_CardIconTongjian.png", -- 公共任务
    [5] = "UIAtlas2_Partner_ParterTravel_CardIconXiuxian.png", -- 茶馆
}

function UIPartnerTravelListTog:SetClass(nClassID)
    local szIconPath = "UIAtlas2_Partner_ParterTravel_CardIconNormal.png"

    if nClassID then
        local tInfo       = Table_GetPartnerTravelClass(nClassID)

        local szName      = UIHelper.GBKToUTF8(tInfo.szClassName)

        local szCountInfo = self:GetTaskSlotUsedInfo()

        UIHelper.SetString(self.LabelClassNameSelect, szName)
        UIHelper.SetString(self.LabelClassCountInfoSelect, szCountInfo)

        UIHelper.SetString(self.LabelClassName, szName)
        UIHelper.SetString(self.LabelClassCountInfo, szCountInfo)

        if tClassToIconPath[nClassID] then
            szIconPath = tClassToIconPath[nClassID]
        end
    end

    UIHelper.SetSpriteFrame(self.ImgIconSelect, szIconPath)
    UIHelper.SetSpriteFrame(self.ImgIcon, szIconPath)

    self:ShowClass(nClassID ~= nil)
end

function UIPartnerTravelListTog:ShowClass(bShowClass)
    UIHelper.SetVisible(self.LabelEmptyNameSelect, not bShowClass)
    UIHelper.SetVisible(self.LabelClassNameSelect, bShowClass)
    UIHelper.SetVisible(self.LabelClassCountInfoSelect, bShowClass)

    UIHelper.SetVisible(self.LabelEmptyName, not bShowClass)
    UIHelper.SetVisible(self.LabelClassName, bShowClass)
    UIHelper.SetVisible(self.LabelClassCountInfo, bShowClass)
end

function UIPartnerTravelListTog:UpdateRedPoint()
    local bHasFinishedQuest = false

    local tBoardToInfoList  = GDAPI_HeroTravelGetAllInfo()
    local tQuestInfoList    = tBoardToInfoList[self.nBoard]

    for nQuestIndex, tQuestInfo in ipairs(tQuestInfoList) do
        local nQuestState, nQuest      = PartnerData.ParseTravelQuestInfo(tQuestInfo)

        local bNotHasConfig            = nQuestState == PartnerTravelState.NotHasConfig
        local bInTravel                = nQuestState == PartnerTravelState.InTravel
        local bFinished                = nQuestState == PartnerTravelState.Finished
        local bKeepConfigAfterFinished = nQuestState == PartnerTravelState.KeepConfigAfterFinished

        if bFinished then
            bHasFinishedQuest = true
        end
    end

    UIHelper.SetVisible(self.ImgRedPoint, bHasFinishedQuest)
end

--- 获取出行位置的已使用情况
function UIPartnerTravelListTog:GetTaskSlotUsedInfo()
    local nUsedCount       = 0
    local nMaxCount        = 0

    local tBoardToInfoList = GDAPI_HeroTravelGetAllInfo()
    local tQuestInfoList   = tBoardToInfoList[self.nBoard]

    nMaxCount              = table.get_len(tQuestInfoList)

    for nQuestIndex, tQuestInfo in ipairs(tQuestInfoList) do
        local nQuestState, nQuest      = PartnerData.ParseTravelQuestInfo(tQuestInfo)

        local bNotHasConfig            = nQuestState == PartnerTravelState.NotHasConfig
        local bInTravel                = nQuestState == PartnerTravelState.InTravel
        local bFinished                = nQuestState == PartnerTravelState.Finished
        local bKeepConfigAfterFinished = nQuestState == PartnerTravelState.KeepConfigAfterFinished

        if bInTravel or bFinished then
            nUsedCount = nUsedCount + 1
        end
    end

    return string.format("已出行 %d/%d", nUsedCount, nMaxCount)
end

return UIPartnerTravelListTog