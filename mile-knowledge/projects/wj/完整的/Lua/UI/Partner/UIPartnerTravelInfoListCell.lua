-- ---------------------------------------------------------------------------------
-- Author: 陈计
-- Name: UIPartnerTravelInfoListCell
-- Date: 2024-11-21 16:56:29
-- Desc: 侠客出行事件信息
-- Prefab: WidgetPartnerTravelInfoListCell
-- ---------------------------------------------------------------------------------

---@class UIPartnerTravelInfoListCell
local UIPartnerTravelInfoListCell = class("UIPartnerTravelInfoListCell")

---_LuaBindList 在这里对绑定的组件进行无意义自赋值，从而方便查询以及ide进行智能提示
function UIPartnerTravelInfoListCell:_LuaBindList()
    self.ImgAdd         = self.ImgAdd --- 未配置时的加号图标
    self.LabelHint      = self.LabelHint --- 未配置时的提示
    self.LabelName      = self.LabelName --- 事件名称
    self.LabelTime      = self.LabelTime --- 状态（剩余时间/已完成/暂未出行)

    self.BtnClick       = self.BtnClick --- 用于点击的按钮

    self.ImgIcon        = self.ImgIcon --- 事件的图标
    self.ImgBg          = self.ImgBg --- 背景图片

    self.ImgHintState   = self.ImgHintState --- 状态的背景图
    self.LabelHintState = self.LabelHintState --- 状态的文字
end

---_LuaTypeList 在这里添加类型注解，从而方便查询以及ide进行智能提示
function UIPartnerTravelInfoListCell:_LuaTypeList()
    -- note: 为了方便写的时候IDE也能提示诸如 c++导出的枚举、临时定义的table列表 的字段，可以像下面示例一样，在这里定义对应类型的信息
    -- note: 定义完后在对应变量的定义处通过 ---@type 注解来标注类型即可
    -- note: 具体 class/type/array/table 格式参考 https://emmylua.github.io/annotation.html

    -- ---@class TypeDemo 示例类型
    -- ---@field NumberParam1 number 数字参数一
    -- ---@field StrParm2 string 字符串参数二
end

function UIPartnerTravelInfoListCell:OnEnter(tQuestInfo, nCurrentBoard, nQuestIndex, nClass)
    --- {}
    --- {nQuest, tHeroList, nStart, nMinute}
    self.tQuestInfo    = tQuestInfo

    --- 第几个牌子
    self.nCurrentBoard = nCurrentBoard
    --- 第几个出行位置
    self.nQuestIndex   = nQuestIndex
    --- 任务类型信息
    self.nClass        = nClass

    if not self.bInit then
        self:RegEvent()
        self:BindUIEvent()
        self.bInit = true
    end

    self:UpdateInfo()

    Timer.AddCycle(self, 0.1, function()
        self:UpdateState()
    end)
end

function UIPartnerTravelInfoListCell:OnExit()
    self.bInit = false
    self:UnRegEvent()
end

function UIPartnerTravelInfoListCell:BindUIEvent()
    UIHelper.BindUIEvent(self.BtnClick, EventType.OnClick, function()
        local nQuestState              = PartnerData.ParseTravelQuestInfo(self.tQuestInfo)

        local bNotHasConfig            = nQuestState == PartnerTravelState.NotHasConfig
        local bInTravel                = nQuestState == PartnerTravelState.InTravel
        local bFinished                = nQuestState == PartnerTravelState.Finished
        local bKeepConfigAfterFinished = nQuestState == PartnerTravelState.KeepConfigAfterFinished

        if bNotHasConfig or bKeepConfigAfterFinished then
            -- 未配置或保留配置的情况下，点击后打开配置界面
            ---@see UIPartnerTravelSettingView
            UIMgr.Open(VIEW_ID.PanelPartnerTravelSetting, self.nCurrentBoard, self.nQuestIndex, self.nClass)
        elseif bInTravel or bFinished then
            ---@see UIPartnerTravelInfoPopView
            UIMgr.Open(VIEW_ID.PanelPartnerTravelInfoPop, self.tQuestInfo, self.nCurrentBoard, self.nQuestIndex, self.nClass)
        end
    end)
end

function UIPartnerTravelInfoListCell:RegEvent()
    --Event.Reg(self, EventType.XXX, func)
end

function UIPartnerTravelInfoListCell:UnRegEvent()
    --Event.UnReg(self, EventType.XXX)
end






-- ----------------------------------------------------------
-- Please write your own code below  ↓↓↓
-- ----------------------------------------------------------

local tClassToIconPath = {
    [1] = "UIAtlas2_Partner_ParterTravel_IconQiyu.png", -- 摸宠
    [2] = "UIAtlas2_Partner_ParterTravel_IconMijing.png", -- 秘境
    [3] = "UIAtlas2_Partner_ParterTravel_IconMingwang.png", -- 名望
    [4] = "UIAtlas2_Partner_ParterTravel_IconTongjian.png", -- 公共任务
    [5] = "UIAtlas2_Partner_ParterTravel_IconXiuxian.png", -- 茶馆
}

function UIPartnerTravelInfoListCell:UpdateInfo()
    local nQuestState, nQuest, tHeroList, nStart, nMinute = PartnerData.ParseTravelQuestInfo(self.tQuestInfo)

    local bNotHasConfig                                   = nQuestState == PartnerTravelState.NotHasConfig
    local bInTravel                                       = nQuestState == PartnerTravelState.InTravel
    local bFinished                                       = nQuestState == PartnerTravelState.Finished
    local bKeepConfigAfterFinished                        = nQuestState == PartnerTravelState.KeepConfigAfterFinished

    local bHasConfig                                      = not bNotHasConfig

    UIHelper.SetVisible(self.LabelName, bHasConfig)
    UIHelper.SetVisible(self.LabelTime, bHasConfig)
    UIHelper.SetVisible(self.ImgBg, bHasConfig)
    UIHelper.SetVisible(self.ImgIcon, bHasConfig)

    UIHelper.SetVisible(self.ImgAdd, not bHasConfig)
    UIHelper.SetVisible(self.LabelHint, not bHasConfig)

    if bHasConfig then
        local tInfo         = Table_GetPartnerTravelTask(nQuest)
        local tSubClassInfo = Table_GetPartnerTravelClassToSubToInfo()[tInfo.nClass][tInfo.nSub]

        local szClassName   = tSubClassInfo.szSubName
        if szClassName == "" then
            szClassName = tSubClassInfo.szClassName
        end
        szClassName       = UIHelper.GBKToUTF8(szClassName)

        local szQuestName = UIHelper.GBKToUTF8(tInfo.szName)

        UIHelper.SetString(self.LabelName, szQuestName)

        self:UpdateState()

        if tClassToIconPath[tInfo.nClass] then
            local szIconPath = tClassToIconPath[tInfo.nClass]
            UIHelper.SetSpriteFrame(self.ImgIcon, szIconPath)
        end
    else
        --- 未配置

    end
end

function UIPartnerTravelInfoListCell:UpdateState()
    if not self.tQuestInfo then
        return
    end

    local szState
    local szFontColor                                     = "#aed9e0"

    local szDetail
    local szDetailImgPath

    local nQuestState, nQuest, tHeroList, nStart, nMinute = PartnerData.ParseTravelQuestInfo(self.tQuestInfo)

    local bNotHasConfig                                   = nQuestState == PartnerTravelState.NotHasConfig
    local bInTravel                                       = nQuestState == PartnerTravelState.InTravel
    local bFinished                                       = nQuestState == PartnerTravelState.Finished
    local bKeepConfigAfterFinished                        = nQuestState == PartnerTravelState.KeepConfigAfterFinished

    if bInTravel then
        local nCurTime       = GetCurrentTime()
        local nRemainingTime = nStart + nMinute * 60 - nCurTime
        local szTime         = TimeLib.GetTimeText(nRemainingTime, nil, true)
        szState              = string.format("剩余%s", szTime)
        szFontColor          = "#ffe26e"
        szDetail = "出行中"
        szDetailImgPath = "UIAtlas2_Partner_ParterTravel_shijian4.png"
    elseif bFinished then
        szState     = "已完成"
        szFontColor = "#95ff95"
        szDetail = "可领取"
        szDetailImgPath = "UIAtlas2_Partner_ParterTravel_shijian5.png"
    else
        szState = "暂未出行"
    end
    UIHelper.SetString(self.LabelTime, szState)
    UIHelper.SetColor(self.LabelTime, UIHelper.ChangeHexColorStrToColor(szFontColor))

    if szDetail then
        UIHelper.SetVisible(self.ImgHintState, true)
        
        UIHelper.SetString(self.LabelHintState, szDetail)
        UIHelper.SetSpriteFrame(self.ImgHintState, szDetailImgPath)
    end
end

return UIPartnerTravelInfoListCell