-- ---------------------------------------------------------------------------------
-- Author: 陈计
-- Name: UIPartnerTravelSettingListTask
-- Date: 2024-11-22 11:21:36
-- Desc: 侠客出行配置界面 出行事件
-- Prefab: WidgetPartnerTravelSettingListTask
-- ---------------------------------------------------------------------------------

---@class UIPartnerTravelSettingListTask
local UIPartnerTravelSettingListTask = class("UIPartnerTravelSettingListTask")

---_LuaBindList 在这里对绑定的组件进行无意义自赋值，从而方便查询以及ide进行智能提示
function UIPartnerTravelSettingListTask:_LuaBindList()
    self.ImgFuYuan        = self.ImgFuYuan --- 宠物福缘的图标
    self.ImgLock          = self.ImgLock --- 未解锁的图标

    --- 未选中
    self.LabelNomal       = self.LabelNomal --- 事件名称
    self.LabelNomalCount  = self.LabelNomalCount --- 事件次数与上限信息
    self.LabelNomalPet    = self.LabelNomalPet --- 宠物名

    --- 选中
    self.LabelSelect      = self.LabelSelect --- 事件名称
    self.LabelSelectCount = self.LabelSelectCount --- 事件次数与上限信息
    self.LabelSelectPet   = self.LabelSelectPet --- 宠物名

    self.ToggleTask       = self.ToggleTask --- toggle
end

---_LuaTypeList 在这里添加类型注解，从而方便查询以及ide进行智能提示
function UIPartnerTravelSettingListTask:_LuaTypeList()
    -- note: 为了方便写的时候IDE也能提示诸如 c++导出的枚举、临时定义的table列表 的字段，可以像下面示例一样，在这里定义对应类型的信息
    -- note: 定义完后在对应变量的定义处通过 ---@type 注解来标注类型即可
    -- note: 具体 class/type/array/table 格式参考 https://emmylua.github.io/annotation.html

    -- ---@class TypeDemo 示例类型
    -- ---@field NumberParam1 number 数字参数一
    -- ---@field StrParm2 string 字符串参数二
end

function UIPartnerTravelSettingListTask:OnEnter(tQuest, bDungeon, tRecord)
    ---@type PartnerTravelTask
    self.tQuest = tQuest
    
    self.bDungeon = bDungeon
    self.tRecord = tRecord

    if not self.bInit then
        self:RegEvent()
        self:BindUIEvent()
        self.bInit = true
    end

    if not self.tRecord then
        self:UpdateInfo()
    else
        self:UpdateDungeonInfo()
    end
end

function UIPartnerTravelSettingListTask:OnExit()
    self.bInit = false
    self:UnRegEvent()
end

function UIPartnerTravelSettingListTask:BindUIEvent()

end

function UIPartnerTravelSettingListTask:RegEvent()
    --Event.Reg(self, EventType.XXX, func)
end

function UIPartnerTravelSettingListTask:UnRegEvent()
    --Event.UnReg(self, EventType.XXX)
end






-- ----------------------------------------------------------
-- Please write your own code below  ↓↓↓
-- ----------------------------------------------------------

function UIPartnerTravelSettingListTask:UpdateInfo()
    local bLock      = PartnerData.IsTravelQuestLocked(self.tQuest)
    local szName     = UIHelper.GBKToUTF8(self.tQuest.szName)

    local bHasFuYuan = false
    local szPetName  = ""
    local szCount    = ""

    local bIsPet     = self.tQuest.dwAdventureID ~= 0
    if bIsPet then
        bHasFuYuan, szPetName, szCount = PartnerData.GetAdvantureInfo(self.tQuest.dwAdventureID)
    end

    self.bHasTrigger = PartnerData.IsTravelQuestTriggered(self.tQuest)
    if self.bHasTrigger then
        szCount = "已触发"
    end

    UIHelper.SetVisible(self.ImgFuYuan, bHasFuYuan)

    UIHelper.SetVisible(self.ImgLock, bLock)
    UIHelper.SetVisible(self.LabelNomalCount, not bLock)
    UIHelper.SetVisible(self.LabelSelectCount, not bLock)

    UIHelper.SetVisible(self.LabelNomalPet, bIsPet)
    UIHelper.SetVisible(self.LabelSelectPet, bIsPet)

    UIHelper.SetString(self.LabelNomal, szName)
    UIHelper.SetString(self.LabelNomalCount, szCount)
    UIHelper.SetString(self.LabelNomalPet, szPetName)

    UIHelper.SetString(self.LabelSelect, szName)
    UIHelper.SetString(self.LabelSelectCount, szCount)
    UIHelper.SetString(self.LabelSelectPet, szPetName)
end

function UIPartnerTravelSettingListTask:UpdateDungeonInfo()
    -- 作为秘境列表展示时，隐藏部分元素
    UIHelper.SetVisible(self.ImgFuYuan, false)
    UIHelper.SetVisible(self.ImgLock, false)
    
    UIHelper.SetVisible(self.LabelNomalCount, false)
    UIHelper.SetVisible(self.LabelSelectCount, false)

    UIHelper.SetVisible(self.LabelNomalPet, false)
    UIHelper.SetVisible(self.LabelSelectPet, false)
    
    -- 显示副本名称
    local szName = UIHelper.GBKToUTF8(self.tRecord.szName)
    UIHelper.SetString(self.LabelNomal, szName)
    UIHelper.SetString(self.LabelSelect, szName)
end

return UIPartnerTravelSettingListTask