-- ---------------------------------------------------------------------------------
-- Author: 陈计
-- Name: UIPartnerTravelTargetCellNew
-- Date: 2025-01-07 10:59:28
-- Desc: 侠客出行槽位 新版
-- Prefab: WidgetPartnerTravelTargetCell
-- ---------------------------------------------------------------------------------

---@class UIPartnerTravelTargetCellNew
local UIPartnerTravelTargetCellNew = class("UIPartnerTravelTargetCellNew")

---_LuaBindList 在这里对绑定的组件进行无意义自赋值，从而方便查询以及ide进行智能提示
function UIPartnerTravelTargetCellNew:_LuaBindList()
    self.ImgAdd         = self.ImgAdd --- 未设置时的添加图标
    self.WidgetAniIcon  = self.WidgetAniIcon --- 有设置时的图标上层组件

    self.BtnClick       = self.BtnClick --- 按钮，点击后不同状态下触发不同行为

    self.ImgBgTitle     = self.ImgBgTitle --- 标题的背景图
    self.LayoutTitle    = self.LayoutTitle --- 标题的layout
    self.ImgMark        = self.ImgMark --- 标题的事件类别图标
    self.LabelName      = self.LabelName --- 标题的信息
    self.ImgIcon        = self.ImgIcon --- 已配置的首个侠客的头像

    self.ImgLock        = self.ImgLock --- 用于展示未解锁信息时的锁图标

    self.ImgSelect      = self.ImgSelect --- 选中时显示的图标

    self.ImgMask        = self.ImgMask --- 不在筛选范围时的黑色遮罩

    self.ImgRedPoint    = self.ImgRedPoint --- 可领取的红点

    self.LabelNameTitle = self.LabelNameTitle --- 事件名称
end

---_LuaTypeList 在这里添加类型注解，从而方便查询以及ide进行智能提示
function UIPartnerTravelTargetCellNew:_LuaTypeList()
    -- note: 为了方便写的时候IDE也能提示诸如 c++导出的枚举、临时定义的table列表 的字段，可以像下面示例一样，在这里定义对应类型的信息
    -- note: 定义完后在对应变量的定义处通过 ---@type 注解来标注类型即可
    -- note: 具体 class/type/array/table 格式参考 https://emmylua.github.io/annotation.html

    -- ---@class TypeDemo 示例类型
    -- ---@field NumberParam1 number 数字参数一
    -- ---@field StrParm2 string 字符串参数二
end

---@param uiPartnerTravelNew UIPartnerTravelNew
function UIPartnerTravelTargetCellNew:OnEnter(nBoard, nQuestIndex, uiPartnerTravelNew, nCurrentTravelIndex, bReuseForLockedInfo)
    self.nBoard              = nBoard
    self.nQuestIndex         = nQuestIndex
    self.uiPartnerTravelNew  = uiPartnerTravelNew
    self.nCurrentTravelIndex = nCurrentTravelIndex

    --- 是否是用来专门显示未解锁信息
    if bReuseForLockedInfo then
        self:ReuseForLockedInfo()
        return
    end

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

function UIPartnerTravelTargetCellNew:OnExit()
    self.bInit = false
    self:UnRegEvent()
end

function UIPartnerTravelTargetCellNew:BindUIEvent()
    UIHelper.BindUIEvent(self.BtnClick, EventType.OnClick, function()
        self:OnClick()
    end)
end

function UIPartnerTravelTargetCellNew:RegEvent()
    --Event.Reg(self, EventType.XXX, func)
    Event.Reg(self, "PartnerTravel_SelectSlot", function(nBoard, nQuestIndex)
        UIHelper.SetVisible(self.ImgSelect, self.nBoard == nBoard and self.nQuestIndex == nQuestIndex)
    end)

    Event.Reg(self, "PartnerTravel_UnSelectAllSlot", function()
        UIHelper.SetVisible(self.ImgSelect, false)
    end)

    Event.Reg(self, "On_Partner_StartTravelCallBack", function(bSuccess)
        self:UpdateInfo()

        if bSuccess and UIHelper.GetVisible(self.ImgSelect) then
            self:OnClick()
        end
    end)

    Event.Reg(self, "REMOTE_HERO_TRAVEL_DATA_EVENT", function()
        self:UpdateInfo()

        if UIHelper.GetVisible(self.ImgSelect) then
            self:OnClick()
        end
    end)

    Event.Reg(self, "REMOTE_HERO_TRAVEL_CLASS_EVENT", function()
        self:UpdateInfo()
    end)

    Event.Reg(self, EventType.OnFilter, function(szKey, tbInfo)
        if szKey ~= FilterDef.PartnerTravelSlot.Key then
            return
        end

        local tDataIndexList      = PartnerData.ConvertToFilterValueList_TravelSlot_QuestType(tbInfo)
        self.tFilterDataIndexList = tDataIndexList

        self:UpdateFilterInfo()
    end)
end

function UIPartnerTravelTargetCellNew:UnRegEvent()
    --Event.UnReg(self, EventType.XXX)
end






-- ----------------------------------------------------------
-- Please write your own code below  ↓↓↓
-- ----------------------------------------------------------
--- 五人秘境
local ClassID_WuRenMiJing             = 5
--- 团队秘境
local ClassID_TuanDuiMiJing           = 6

local tMiJingDifficulty               = {
    Normal = 1, -- 普通
    Challenge = 2, -- 挑战
    Hero = 3, -- 英雄
}

local tMiJingClassToDifficultyImgPath = {
    [ClassID_WuRenMiJing] = {
        [tMiJingDifficulty.Normal] = "UIAtlas2_Partner_ParterTravel_IconTeam2",
        [tMiJingDifficulty.Challenge] = "UIAtlas2_Partner_ParterTravel_IconTeam6",
        [tMiJingDifficulty.Hero] = "UIAtlas2_Partner_ParterTravel_IconTeam4",
    },
    [ClassID_TuanDuiMiJing] = {
        [tMiJingDifficulty.Normal] = "UIAtlas2_Partner_ParterTravel_IconTeam1",
        [tMiJingDifficulty.Challenge] = "UIAtlas2_Partner_ParterTravel_IconTeam5",
        [tMiJingDifficulty.Hero] = "UIAtlas2_Partner_ParterTravel_IconTeam3",
    },
}

function UIPartnerTravelTargetCellNew:UpdateInfo()
    local bHasConfig                                      = PartnerData.TravelQuestHaveConfig(self.nBoard, self.nQuestIndex)

    local nQuestState, nQuest, tHeroList, nStart, nMinute = PartnerData.GetTravelQuestInfo(self.nBoard, self.nQuestIndex)

    UIHelper.SetVisible(self.WidgetAniIcon, bHasConfig)
    UIHelper.SetVisible(self.ImgBgTitle, bHasConfig)
    UIHelper.SetVisible(self.LayoutTitle, bHasConfig)
    UIHelper.SetVisible(self.LabelName, bHasConfig)
    UIHelper.SetVisible(self.LabelNameTitle, bHasConfig)

    UIHelper.SetVisible(self.ImgAdd, not bHasConfig)

    if bHasConfig then
        local tInfo = Table_GetPartnerTravelTask(nQuest)

        UIHelper.SetString(self.LabelNameTitle, UIHelper.GBKToUTF8(tInfo.szName))

        local bIsMiJing = tInfo.nClass == ClassID_WuRenMiJing or tInfo.nClass == ClassID_TuanDuiMiJing

        local szIconPath
        if PartnerTravelClassToIconPath[tInfo.nClass] then
            szIconPath = PartnerTravelClassToIconPath[tInfo.nClass]
        end
        if bIsMiJing then
            -- 如果是秘境，则需要根据对应类别和难度来获取不同的图标
            ---@type DungeonRecord
            local tRecord       = Table_GetDungeonInfo(tInfo.dwMapID)
            local nDifficultyID = DungeonData.GetDungeonDifficultyID(UIHelper.GBKToUTF8(tRecord.szLayer3Name))

            szIconPath          = tMiJingClassToDifficultyImgPath[tInfo.nClass][nDifficultyID]
        end

        if szIconPath then
            UIHelper.SetSpriteFrame(self.ImgMark, szIconPath)
        end

        self:UpdateState()

        local szImgPath        = ""
        local dwFirstPartnerID = tHeroList[1]
        if dwFirstPartnerID then
            local tPartnerInfo = Table_GetPartnerNpcInfo(dwFirstPartnerID)
            szImgPath          = tPartnerInfo.szSmallAvatarImg
        end
        UIHelper.SetTexture(self.ImgIcon, szImgPath)
    else
        --- 未配置

    end

    self:UpdateFilterInfo()
end

function UIPartnerTravelTargetCellNew:UpdateState()
    local bHasConfig = PartnerData.TravelQuestHaveConfig(self.nBoard, self.nQuestIndex)
    if not bHasConfig then
        return
    end

    local szState
    local szFontColor                                     = "#aed9e0"

    local nQuestState, nQuest, tHeroList, nStart, nMinute = PartnerData.GetTravelQuestInfo(self.nBoard, self.nQuestIndex)

    local bNotHasConfig                                   = nQuestState == PartnerTravelState.NotHasConfig
    local bInTravel                                       = nQuestState == PartnerTravelState.InTravel
    local bFinished                                       = nQuestState == PartnerTravelState.Finished
    local bKeepConfigAfterFinished                        = nQuestState == PartnerTravelState.KeepConfigAfterFinished

    if bInTravel then
        local nCurTime       = GetCurrentTime()
        local nRemainingTime = nStart + nMinute * 60 - nCurTime
        local szTime         = TimeLib.GetTimeText(nRemainingTime, nil, true)
        szState              = string.format("%s", szTime)
        szFontColor          = "#ffe26e"
    elseif bFinished then
        szState     = "可领取"
        szFontColor = "#95ff95"
    else
        szState = "未出行"
    end
    UIHelper.SetString(self.LabelName, szState)
    UIHelper.SetColor(self.LabelName, UIHelper.ChangeHexColorStrToColor(szFontColor))
    UIHelper.LayoutDoLayout(self.LayoutTitle)

    UIHelper.SetVisible(self.ImgRedPoint, bFinished)
end

function UIPartnerTravelTargetCellNew:ShowSelectQuestClassPage()
    UIHelper.RemoveAllChildren(self.uiPartnerTravelNew.widgetCardInfoAnchor)
    ---@see UITravelInfoSelectType#OnEnter
    UIHelper.AddPrefab(PREFAB_ID.WidgetTravelInfoSelectType, self.uiPartnerTravelNew.widgetCardInfoAnchor, self.nBoard, self.nQuestIndex)
end

function UIPartnerTravelTargetCellNew:ShowTravelInfoPage()
    UIHelper.RemoveAllChildren(self.uiPartnerTravelNew.widgetCardInfoAnchor)
    ---@see UITravelInfoPopNew#OnEnter
    UIHelper.AddPrefab(PREFAB_ID.WidgetTravelInfoPop1, self.uiPartnerTravelNew.widgetCardInfoAnchor, self.nBoard, self.nQuestIndex, self)
end

function UIPartnerTravelTargetCellNew:ReuseForLockedInfo()
    UIHelper.SetVisible(self.WidgetAniIcon, false)
    UIHelper.SetVisible(self.ImgBgTitle, false)
    UIHelper.SetVisible(self.LayoutTitle, false)
    UIHelper.SetVisible(self.ImgAdd, false)
    UIHelper.SetVisible(self.LabelName, false)
    UIHelper.SetVisible(self.LabelNameTitle, false)

    UIHelper.SetVisible(self.ImgLock, true)

    UIHelper.BindUIEvent(self.BtnClick, EventType.OnClick, function()
        local tUnlockTipsList  = {  }

        local tBoardToInfoList = GDAPI_HeroTravelGetAllInfo()

        -- 展示牌子列表
        local nSlotCount       = 0
        for nBoard, tInfoList in pairs(tBoardToInfoList) do
            local tBoardInfo = Table_GetPartnerTravelTeamInfo(nBoard)
            if tBoardInfo.dwQuestID == -1 then
                --- 任务设置为-1的牌子表示尚未开放，不做处理
            else
                nSlotCount = nSlotCount + #tInfoList

                local szTips
                if PartnerData.IsTravelBoardUnlocked(nBoard) then
                    szTips = string.format("<color=%s>%d个槽位：已解锁</c>", FontColorID.ImportantGreen, nSlotCount)
                else
                    szTips = string.format("%d个槽位：%s", nSlotCount, UIHelper.GBKToUTF8(tBoardInfo.szUnlockTip))
                end

                table.insert(tUnlockTipsList, szTips)
            end
        end

        local szUnlockTips = table.concat(tUnlockTipsList, "\n")

        ---@see UIPublicLabelTips
        TipsHelper.ShowNodeHoverTipsInDir(PREFAB_ID.WidgetPublicLabelTips, self.BtnClick, TipsLayoutDir.LEFT_CENTER, szUnlockTips)
    end)
end

function UIPartnerTravelTargetCellNew:OnClick()
    local bHasConfig = PartnerData.TravelQuestHaveConfig(self.nBoard, self.nQuestIndex)
    if not bHasConfig then
        -- 未配置，点击选择事件类别
        self:ShowSelectQuestClassPage()
    else
        --- 已配置
        local nQuestState              = PartnerData.GetTravelQuestInfo(self.nBoard, self.nQuestIndex)

        local bNotHasConfig            = nQuestState == PartnerTravelState.NotHasConfig
        local bInTravel                = nQuestState == PartnerTravelState.InTravel
        local bFinished                = nQuestState == PartnerTravelState.Finished
        local bKeepConfigAfterFinished = nQuestState == PartnerTravelState.KeepConfigAfterFinished

        if bInTravel or bFinished or bKeepConfigAfterFinished then
            self:ShowTravelInfoPage()
        end
    end

    self.uiPartnerTravelNew:SwitchTravelRightSidePageView(true, self.nCurrentTravelIndex)
    Event.Dispatch("PartnerTravel_SelectSlot", self.nBoard, self.nQuestIndex)
end

function UIPartnerTravelTargetCellNew:UpdateFilterInfo()
    local nSelfDataIndex                                  = 0
    local nQuestState, nQuest, tHeroList, nStart, nMinute = PartnerData.GetTravelQuestInfo(self.nBoard, self.nQuestIndex)
    if nQuestState ~= PartnerTravelState.NotHasConfig then
        local tInfo    = Table_GetPartnerTravelTask(nQuest)
        nSelfDataIndex = tInfo.nDataIndex
    end

    -- 如果设置了筛选类别，且当前类别不在其中，则需要置灰
    local bShowBlackMask = table.get_len(self.tFilterDataIndexList) > 0 and not table.contain_value(self.tFilterDataIndexList, nSelfDataIndex)
    UIHelper.SetVisible(self.ImgMask, bShowBlackMask)
end

return UIPartnerTravelTargetCellNew