-- ---------------------------------------------------------------------------------
-- Author: 陈计
-- Name: UIPartnerXunFangView
-- Date: 2024-02-27 17:24:52
-- Desc: 侠客抽卡
-- Prefab: PanelPartnerXunFang
-- ---------------------------------------------------------------------------------

---@class UIPartnerXunFangView
local UIPartnerXunFangView = class("UIPartnerXunFangView")

---_LuaBindList 在这里对绑定的组件进行无意义自赋值，从而方便查询以及ide进行智能提示
function UIPartnerXunFangView:_LuaBindList()
    self.BtnClose                       = self.BtnClose --- 关闭按钮

    self.LayoutPartnerList              = self.LayoutPartnerList --- 侠客小头像列表

    self.ImgRoleInfoBg                  = self.ImgRoleInfoBg --- 侠客名称的背景图片
    self.ImgRoleTag                     = self.ImgRoleTag --- 侠客心法类型
    self.LabelRoleName                  = self.LabelRoleName --- 名称
    self.LabelRoleInfo                  = self.LabelRoleInfo --- 描述
    self.LabelRoleMeetTimes             = self.LabelRoleMeetTimes --- 已喝茶次数

    self.ImgRoleNotMeet                 = self.ImgRoleNotMeet --- 侠客立绘-未结识
    self.ImgRoleInTaskOrMeet            = self.ImgRoleInTaskOrMeet --- 侠客立绘-侠缘任务中或已结识

    self.ImgRoleMeetState               = self.ImgRoleMeetState --- 侠客结缘状态的图片

    self.ImgGiftOn                      = self.ImgGiftOn --- 可领取免费茶饼
    self.ImgGiftOff                     = self.ImgGiftOff --- 不可领取免费茶饼
    self.LabelGift                      = self.LabelGift --- 免费茶饼提示语
    self.BtnTakeDailyFreeTea            = self.BtnTakeDailyFreeTea --- 领取每日免费茶饼的按钮

    self.BtnXunFang                     = self.BtnXunFang --- 开始喝茶 按钮

    self.WidgetAnchorRightTop           = self.WidgetAnchorRightTop --- 右上角区域
    self.WidgetAnchorContentInfo        = self.WidgetAnchorContentInfo --- 侠客信息组件
    self.WidgetAnchorGetRolePop         = self.WidgetAnchorGetRolePop --- 开启侠缘任务组件
    self.WidgetAnchorGetNormalPop       = self.WidgetAnchorGetNormalPop --- 抽卡失败组件

    self.TogXunFangContinuous           = self.TogXunFangContinuous --- 连续抽卡的toggle

    self.WidgetAnchorStartDraw          = self.WidgetAnchorStartDraw --- 开始抽卡的组件
    self.WidgetAnchorStopContinuousDraw = self.WidgetAnchorStopContinuousDraw --- 停止连抽的组件
    self.BtnStopContinuousDraw          = self.BtnStopContinuousDraw --- 停止连抽的按钮
    self.ProgressBarContinuousDraw      = self.ProgressBarContinuousDraw --- 连抽进度条
    self.LabelProgressContinuousDraw    = self.LabelProgressContinuousDraw --- 连抽进度label

    self.LabelDrawFailCloseTip          = self.LabelDrawFailCloseTip --- 抽卡失败时点击空白关闭的提示

    self.BtnContinuousTip               = self.BtnContinuousTip --- 连抽开关右侧的提示按钮
    self.WidgetTask                     = self.WidgetTask --- 寻访任务组件
    self.BtnTask                        = self.BtnTask --- 寻访任务按钮

    self.ImgStartTaskRole               = self.ImgStartTaskRole --- 开始侠客任务的角色图片
    self.ImgStartTaskRoleType           = self.ImgStartTaskRoleType --- 开始侠客任务的角色类型（攻击、治疗、守卫等）图片
    self.LabelStartTaskRoleName         = self.LabelStartTaskRoleName --- 开始侠客的角色名称

    self.LabelGetNormalTitle            = self.LabelGetNormalTitle --- 抽卡失败标题
    self.LabelGetNormalContent          = self.LabelGetNormalContent --- 抽卡失败内容

    self.AniAll                         = self.AniAll --- 动画节点

    self.LayoutMeetTeaCount             = self.LayoutMeetTeaCount --- 茶饼数量的layout

    self.ImgFrist                       = self.ImgFrist --- 首次寻访必得提示

    self.BtnLimit                       = self.BtnLimit --- 限定标记的按钮
end

---_LuaTypeList 在这里添加类型注解，从而方便查询以及ide进行智能提示
function UIPartnerXunFangView:_LuaTypeList()
    -- note: 为了方便写的时候IDE也能提示诸如 c++导出的枚举、临时定义的table列表 的字段，可以像下面示例一样，在这里定义对应类型的信息
    -- note: 定义完后在对应变量的定义处通过 ---@type 注解来标注类型即可
    -- note: 具体 class/type/array/table 格式参考 https://emmylua.github.io/annotation.html

    ---@class PartnerDrawInfo 侠客抽卡信息
    ---@field dwID number 侠客ID
    ---@field nMeetTimes number 已抽取的次数
    ---@field nState number 结识状态，0：未结识，1：侠缘任务中，2：已结识 @see PartnerDrawState
end

function UIPartnerXunFangView:OnEnter(tInfoList, nSelID)
    ---@type PartnerDrawInfo[]
    self.tInfoList               = tInfoList
    self.nSelID                  = nSelID

    --- 是否在连续抽卡过程中
    self.bInContinuousDraw       = false

    --- 连抽进度
    self.nContinuousDrawProgress = 0
    --- 连抽开始时的总茶饼数
    self.nContinuousDrawTotal    = 1

    --- 本次打开界面后，下次抽卡的序号，用于确定抽卡失败时显示哪段传记内容
    self.nShowStoryIndex         = 0

    --- 是否已收到本次抽卡的结果，默认为false，收到结果时设为true，播放动画完开始定期检查该标记，当该标记为true时，设为false，并展示结果
    self.bReceivedDrawResult     = false

    --- 结果动画是否已播放完毕
    self.bResultAniPlayFinished  = true

    if not self.bInit then
        self:RegEvent()
        self:BindUIEvent()
        self.bInit = true
    end

    self:UpdateInfo()
end

function UIPartnerXunFangView:OnExit()
    self.bInit = false
    self:UnRegEvent()

    -- todo: 先临时放在这里，停止连抽，确保定身buff被移除，可以正常移动，具体细化时再完善
    self:StopDraw(self.nSelID)
end

function UIPartnerXunFangView:BindUIEvent()
    UIHelper.BindUIEvent(self.BtnClose, EventType.OnClick, function()
        UIMgr.Close(self)
    end)

    UIHelper.BindUIEvent(self.BtnTakeDailyFreeTea, EventType.OnClick, function()
        local bDailyTeaTaken = PartnerData.IfGetHeroDailyTea()
        if bDailyTeaTaken then
            return
        end

        UIHelper.RemoteCallToServer("On_Hero_GetDailyTea")
    end)

    UIHelper.BindUIEvent(self.BtnXunFang, EventType.OnClick, function()
        local nTotalMeetTeaCount = self:GetTotalMeetTeaCount()
        if nTotalMeetTeaCount <= 0 then
            return
        end

        if not self:IsContinuousDraw() then
            self:DrawOnce()
        else
            self:DrawContinuous()
        end
    end)

    UIHelper.BindUIEvent(self.WidgetAnchorGetRolePop, EventType.OnClick, function()
        if self.bResultAniPlayFinished then
            self:ShowDrawResult(false)
        end
    end)

    UIHelper.BindUIEvent(self.WidgetAnchorGetNormalPop, EventType.OnClick, function()
        if not self:StillInContinuousDraw() then
            if self.bResultAniPlayFinished then
                self:ShowDrawResult(false)
            end
        elseif UIHelper.GetVisible(self.WidgetAnchorStopContinuousDraw) then
            self:StopContinuousDraw()
        end
    end)

    UIHelper.BindUIEvent(self.BtnStopContinuousDraw, EventType.OnClick, function()
        self:StopContinuousDraw()
    end)

    UIHelper.BindUIEvent(self.BtnTask, EventType.OnClick, function()
        RemoteCallToServer("On_Hero_GetTaskID", self.nSelID)
    end)

    UIHelper.BindUIEvent(self.BtnLimit, EventType.OnClick, function()
        local tInfo = Table_GetPartnerNpcInfo(self.nSelID)

        TipsHelper.ShowNodeHoverTipsInDir(PREFAB_ID.WidgetPublicLabelTips, self.BtnLimit, TipsLayoutDir.BOTTOM_LEFT, UIHelper.GBKToUTF8(tInfo.szLimitTip))
    end)
end

function UIPartnerXunFangView:RegEvent()
    --Event.Reg(self, EventType.XXX, func)
    Event.Reg(self, "On_Partner_IsGetDailyTeaSuccess", function(bFlag)
        if not bFlag then
            return
        end

        -- 获取了新的茶饼，刷新下界面
        self:UpdateDailyTeaInfo()
        self:UpdateMeetTeaCount()
    end)

    Event.Reg(self, "BAG_ITEM_UPDATE", function(nBox, nIndex, bNewAdd)
        local item = ItemData.GetItemByPos(nBox, nIndex)

        if item then
            local tDrawItemList = self:GetPartnerDrawItemList()
            for _, tDrawItem in ipairs(tDrawItemList) do
                if item.dwTabType == tDrawItem.dwItemType and item.dwIndex == tDrawItem.dwItemIndex then
                    self:UpdateMeetTeaCount()
                end
            end
        end
    end)

    Event.Reg(self, "On_Partner_EnableDraw", function(nMaxDrawCount)
        self:On_Partner_EnableDraw(nMaxDrawCount)
    end)

    Event.Reg(self, "On_Partner_UpdateMeetState", function(nHeroID, nMeetTimes, nState, bFinish)
        if nHeroID ~= self.nSelID then
            return
        end

        self:UpdateSelPartnerDrawInfo(self.nSelID, nState, nMeetTimes)

        if bFinish then
            self:On_Partner_StopDraw(nHeroID, nMeetTimes, nState)
            return
        end

        if not self:IsContinuousDraw() then
            -- 单抽，标记为已收到抽卡结果，在动画播完时去展示结果
            self.bReceivedDrawResult = true
        else
            if nState == PartnerDrawState.NotMeet then
                -- 连抽的情况下，若未抽中，则直接发起下一次抽卡
                self:AniFinishShowDrawResult()
            else
                -- 否则，等待最新的动画播完后，展示抽中动画
                self.bReceivedDrawResult = true
            end
        end
    end)

    Event.Reg(self, "On_Partner_StopDraw", function(dwPartnerID, nMeetTimes, nState)
        self:On_Partner_StopDraw(dwPartnerID, nMeetTimes, nState)
    end)

    Event.Reg(self, "On_Partner_GetTaskID", function(dwTaskID)
        QuestData.SetTracingQuestID(dwTaskID)
        QuestData.RemoveProhibitTraceQuestID(dwTaskID)

        UIMgr.Open(VIEW_ID.PanelTask)
        UIMgr.Close(self)
    end)
end

function UIPartnerXunFangView:UnRegEvent()
    --Event.UnReg(self, EventType.XXX)
end






-- ----------------------------------------------------------
-- Please write your own code below  ↓↓↓
-- ----------------------------------------------------------

function UIPartnerXunFangView:UpdateInfo()
    -- note: 左侧的小头像暂时不需要了，先注释掉
    ---- 左侧小头像列表
    --UIHelper.RemoveAllChildren(self.LayoutPartnerList)
    --
    --for _, tDrawInfo in ipairs(self.tInfoList) do
    --    ---@type UIPartnerXunFangFrameTog
    --    local script = UIHelper.AddPrefab(PREFAB_ID.WidgetPartnerXunFangFrameTog, self.LayoutPartnerList, tDrawInfo)
    --    UIHelper.SetToggleGroupIndex(script.ToggleSelect, ToggleGroupIndex.PartnerSelectXunFangRole)
    --    UIHelper.SetSelected(script.ToggleSelect, tDrawInfo.dwID == self.nSelID)
    --
    --    UIHelper.SetAnchorPoint(script._rootNode, -0.15, 0)
    --
    --    UIHelper.BindUIEvent(script.ToggleSelect, EventType.OnClick, function()
    --        self.nSelID = tDrawInfo.dwID
    --        self:UpdateSelPartnerInfo()
    --    end)
    --end
    --
    --UIHelper.LayoutDoLayout(self.LayoutPartnerList)

    self:UpdateSelPartnerInfo()
end

function UIPartnerXunFangView:UpdateSelPartnerInfo()
    local tInfo     = Table_GetPartnerNpcInfo(self.nSelID)
    local tDrawInfo = self:GetSelPartnerDrawInfo()

    UIHelper.SetSpriteFrame(self.ImgRoleTag, PartnerKungfuIndexToImg[tInfo.nKungfuIndex])
    UIHelper.SetString(self.LabelRoleName, UIHelper.GBKToUTF8(tInfo.szName))
    UIHelper.SetString(self.LabelRoleInfo, UIHelper.GBKToUTF8(tInfo.szIntroduce))

    UIHelper.SetString(self.LabelRoleMeetTimes, string.format("喝茶次数：%d次", tDrawInfo.nMeetTimes))

    UIHelper.SetVisible(self.BtnLimit, PartnerData.NeedShowLimitedTips(self.nSelID))

    local szImgPath = tInfo.szBigAvatarImg
    UIHelper.SetTexture(self.ImgRoleNotMeet, szImgPath)
    UIHelper.SetTexture(self.ImgRoleInTaskOrMeet, szImgPath)

    self:UpdateRoleImg(false)

    local bInTaskOrMeet = tDrawInfo.nState == PartnerDrawState.InTask or tDrawInfo.nState == PartnerDrawState.Meet

    local szMeetStateImg
    if bInTaskOrMeet then
        szMeetStateImg = "UIAtlas2_Partner_PartnerTips_xunfangMark2.png"
    else
        szMeetStateImg = "UIAtlas2_Partner_PartnerTips_xunfangMark1.png"
    end
    UIHelper.SetSpriteFrame(self.ImgRoleMeetState, szMeetStateImg)

    local bFirstDrawMustHit = PartnerData.IsFirstDrawMustMeet(self.nSelID)
    UIHelper.SetVisible(self.ImgFrist, bFirstDrawMustHit)

    self:UpdateDailyTeaInfo()
    self:UpdateMeetTeaCount()

    local bNotMeet = tDrawInfo.nState == PartnerDrawState.NotMeet
    local bInTask  = tDrawInfo.nState == PartnerDrawState.InTask
    UIHelper.SetVisible(self.BtnXunFang, bNotMeet)
    -- 仅当茶饼数目大于1时，才显示自动喝茶，避免因为动画与实际抽卡分开处理，1个时会播放两个动画（默认的与最后展示实际抽到的），导致看起来很怪
    UIHelper.SetVisible(self.TogXunFangContinuous, bNotMeet and self:GetTotalMeetTeaCount() > 1)
    --UIHelper.SetVisible(self.BtnContinuousTip, bNotMeet and self:GetTotalMeetTeaCount() > 1)
    UIHelper.SetVisible(self.BtnContinuousTip, false)
    UIHelper.SetVisible(self.LabelRoleMeetTimes, bNotMeet)
    UIHelper.SetVisible(self.WidgetTask, bInTask)
end

function UIPartnerXunFangView:UpdateDailyTeaInfo()
    -- 今日免费茶饼是否已领取
    local bDailyTeaTaken = PartnerData.IfGetHeroDailyTea()
    UIHelper.SetVisible(self.ImgGiftOn, not bDailyTeaTaken)
    UIHelper.SetVisible(self.ImgGiftOff, bDailyTeaTaken)
    UIHelper.SetString(self.LabelGift, bDailyTeaTaken and "今日已领" or "点击领取")
    UIHelper.SetButtonState(self.BtnTakeDailyFreeTea, not bDailyTeaTaken and BTN_STATE.Normal or BTN_STATE.Disable)
end

---@class DrawItem
---@field dwItemType number
---@field dwItemIndex number

---@return DrawItem[]
function UIPartnerXunFangView:GetPartnerDrawItemList()
    local tInfo         = Table_GetPartnerNpcInfo(self.nSelID)
    local tDrawItemList = SplitString(tInfo.szDrawItemList, ";")
    local tList         = {}
    for _, szDrawItem in ipairs(tDrawItemList) do
        local t = StringParse_PointList(szDrawItem)
        if t[1] and t[2] then
            table.insert(tList, { dwItemType = t[1], dwItemIndex = t[2] })
        end
    end

    return tList
end

function UIPartnerXunFangView:UpdateMeetTeaCount()
    local tDrawItemList = self:GetPartnerDrawItemList()

    UIHelper.RemoveAllChildren(self.LayoutMeetTeaCount)

    --- 这里的layout是从右向左展示的，所以这里逆序一下
    tDrawItemList = Lib.ReverseTable(tDrawItemList)

    for _, tDrawItem in ipairs(tDrawItemList) do
        ---@see UISingleCurrency
        UIHelper.AddPrefab(PREFAB_ID.WidgetSingleCurrency, self.LayoutMeetTeaCount, tDrawItem.dwItemType, tDrawItem.dwItemIndex, true)
    end

    UIHelper.CascadeDoLayoutDoWidget(self.LayoutMeetTeaCount, true, true)

    local nTotalMeetTeaCount = self:GetTotalMeetTeaCount()
    UIHelper.SetButtonState(self.BtnXunFang, nTotalMeetTeaCount > 0 and BTN_STATE.Normal or BTN_STATE.Disable)
end

function UIPartnerXunFangView:GetTotalMeetTeaCount()
    local nTotalMeetTeaCount = 0

    local tDrawItemList      = self:GetPartnerDrawItemList()
    for _, tDrawItem in ipairs(tDrawItemList) do
        local nTeaCount    = ItemData.GetItemAmountInPackage(tDrawItem.dwItemType, tDrawItem.dwItemIndex)

        nTotalMeetTeaCount = nTotalMeetTeaCount + nTeaCount
    end

    return nTotalMeetTeaCount
end

---@return PartnerDrawInfo
function UIPartnerXunFangView:GetSelPartnerDrawInfo(nSelID)
    if nSelID == nil then
        nSelID = self.nSelID
    end

    for _, tDrawInfo in ipairs(self.tInfoList) do
        if tDrawInfo.dwID == nSelID then
            return tDrawInfo
        end
    end

    return nil
end

---@return PartnerDrawInfo
function UIPartnerXunFangView:UpdateSelPartnerDrawInfo(nSelID, nState, nMeetTimes)
    local tDrawInfo = self:GetSelPartnerDrawInfo(nSelID)
    if tDrawInfo then
        tDrawInfo.nState = nState
        if nMeetTimes > tDrawInfo.nMeetTimes then
            --- 仅当服务器传回的值大于当前值时，才更新已喝茶次数，从而方便抽到时也可以显示喝茶次数，避免被服务器传过来的0覆盖
            tDrawInfo.nMeetTimes = nMeetTimes
        end
    end
end

function UIPartnerXunFangView:ShowDrawResult(bShowResult)
    local nState
    local tDrawInfo = self:GetSelPartnerDrawInfo(self.nSelID)
    if tDrawInfo then
        nState = tDrawInfo.nState
    end

    local bMainViewWidgets = not bShowResult

    UIHelper.SetVisible(self.LayoutPartnerList, bMainViewWidgets)
    UIHelper.SetVisible(self.BtnTakeDailyFreeTea, bMainViewWidgets)

    UIHelper.SetVisible(self.WidgetAnchorRightTop, bMainViewWidgets)

    local bForceHideImg = bShowResult
    self:UpdateRoleImg(bForceHideImg)

    UIHelper.SetVisible(self.ImgRoleInfoBg, bMainViewWidgets)
    UIHelper.SetVisible(self.ImgRoleTag, bMainViewWidgets)
    UIHelper.SetVisible(self.LabelRoleName, bMainViewWidgets)
    UIHelper.SetVisible(self.ImgRoleMeetState, bMainViewWidgets)
    UIHelper.SetVisible(self.LabelRoleInfo, bMainViewWidgets)
    UIHelper.SetVisible(self.WidgetAnchorStartDraw, bMainViewWidgets)

    UIHelper.SetVisible(self.LabelRoleMeetTimes, bMainViewWidgets)

    local bGetRole = bShowResult and nState ~= PartnerDrawState.NotMeet
    if bGetRole then
        local tPartnerInfo = Table_GetPartnerNpcInfo(tDrawInfo.dwID)
        if tPartnerInfo then
            local szImgPath = tPartnerInfo.szBigAvatarImg
            UIHelper.SetTexture(self.ImgStartTaskRole, szImgPath)

            local nKungfuIndex = tPartnerInfo.nKungfuIndex
            UIHelper.SetSpriteFrame(self.ImgStartTaskRoleType, PartnerKungfuIndexToImg[nKungfuIndex])

            UIHelper.SetString(self.LabelStartTaskRoleName, UIHelper.GBKToUTF8(tPartnerInfo.szName))
        end

        -- 播放动画，展示抽卡成功内容
        --UIHelper.SetVisible(self.WidgetAnchorGetRolePop, bGetRole)
        self.bResultAniPlayFinished = false
        UIHelper.PlayAni(self, self.AniAll, "AniGetRolePop", function()
            self.bResultAniPlayFinished = true

            LOG.DEBUG("获得新侠客，尝试触发教学")
            if TeachEvent.CheckCondition(40) then
                TeachEvent.TeachStart(40)
            end
        end)
    else
        UIHelper.SetVisible(self.WidgetAnchorGetRolePop, false)
    end

    local bDrawFailed = bShowResult and nState == PartnerDrawState.NotMeet
    if bDrawFailed then
        if not self:StillInContinuousDraw() then
            -- 单抽，或连抽结束的时候，播放动画，展示抽卡失败内容
            --UIHelper.SetVisible(self.WidgetAnchorGetNormalPop, true)
            self:UpdateDrawFailInfo()
            self.bResultAniPlayFinished = false
            UIHelper.PlayAni(self, self.AniAll, "AniGetNormalPop", function()
                self.bResultAniPlayFinished = true
            end)
        else
            -- 连抽过程中的失败界面刷新和动画在 BtnXunFang 的回调中去另外处理，以实现连抽时动画和逻辑各自独立执行
        end
    else
        UIHelper.SetVisible(self.WidgetAnchorGetNormalPop, false)
    end

    UIHelper.SetVisible(self.LabelDrawFailCloseTip, not self:StillInContinuousDraw())

    if not bShowResult then
        -- 播放动画，隐藏抽卡结果，回到初始页面
        UIHelper.PlayAni(self, self.AniAll, "AniVisitFadeOut", nil)
    end
end

function UIPartnerXunFangView:DrawOnce()
    self:Draw(self.nSelID, 1)
end

function UIPartnerXunFangView:DrawContinuous()
    self:Draw(self.nSelID, nil)
end

function UIPartnerXunFangView:On_Partner_EnableDraw(nMaxDrawCount)
    if self:IsContinuousDraw() then
        self.bInContinuousDraw = true

        UIHelper.SetVisible(self.WidgetAnchorStartDraw, false)

        --- 连抽时禁用抽取失败的全屏按钮
        UIHelper.SetEnable(self.WidgetAnchorGetNormalPop, false)

        -- 先隐藏停止按钮，1.5秒后再显示，确保第一次抽卡基本上可以完成
        UIHelper.SetVisible(self.WidgetAnchorStopContinuousDraw, false)
        Timer.Add(self, 1.5, function()
            UIHelper.SetVisible(self.WidgetAnchorStopContinuousDraw, true)
        end)

        self.nContinuousDrawProgress = 0
        self.nContinuousDrawTotal    = nMaxDrawCount
        self:UpdateContinuousDrawProgress()
    end

    -- 动画顺序说明
    -- 1. 单抽
    --      AniVisitFadeIn -> AniOnce -> AniGetNormalPop | AniGetRolePop -> AniVisitFadeOut
    -- 2. 连抽
    --      AniVisitFadeIn -> AniOnce
    --                      未抽到：    -> AniGetNormalPop -> AniMany -> AniGetNormalPop ... (按停止结束） -> AniVisitFadeOut
    --                      已抽到：    -> AniGetRolePop -> AniVisitFadeOut

    -- 先切入
    UIHelper.PlayAni(self, self.AniAll, "AniVisitFadeIn", function() end)
    -- 然后隔一小会播放抽卡动画
    Timer.Add(self, 0.2, function()
        -- 然后抽卡
        local fnTryShowResult
        local fnPlayDrawAni

        fnTryShowResult = function()
            if not self.bReceivedDrawResult then
                --- 还未收到结果，则下一帧再试试
                Timer.AddFrame(self, 1, fnTryShowResult)
                return
            end

            self.bReceivedDrawResult = false
            self:AniFinishShowDrawResult()
        end

        fnPlayDrawAni   = function(szAniName)
            UIHelper.PlayAni(self, self.AniAll, szAniName, function()
                if not self:StillInContinuousDraw() then
                    -- 单抽等待动画播放结束后再展示结果
                    fnTryShowResult()
                else
                    -- 连抽
                    local tDrawInfo = self:GetSelPartnerDrawInfo(self.nSelID)
                    if tDrawInfo.nState == PartnerDrawState.NotMeet then
                        -- 未抽中，则展示结果后，播放下一个动画
                        self:UpdateDrawFailInfo()
                        self.bResultAniPlayFinished = false
                        UIHelper.PlayAni(self, self.AniAll, "AniGetNormalPop", function()
                            -- 抽卡失败的动画等待8秒，其中动画本身持续4秒，后续代码等待4秒。在后面这四秒中，若抽到了，则停止等待，开始进入抽到的流程
                            local nWaitUntil = GetCurrentTime() + 4
                            local nTimerID
                            nTimerID         = Timer.AddCycle(self, 0.1, function()
                                local bStopWait    = false

                                local nCurrentTime = GetCurrentTime()
                                if nCurrentTime < nWaitUntil then
                                    local nLatestDrawInfo = self:GetSelPartnerDrawInfo(self.nSelID)
                                    if nLatestDrawInfo.nState ~= PartnerDrawState.NotMeet then
                                        -- 抽到了
                                        bStopWait = true
                                    end
                                else
                                    bStopWait = true
                                end

                                if not bStopWait then
                                    return
                                end

                                Timer.DelTimer(self, nTimerID)

                                self.bResultAniPlayFinished = true

                                UIHelper.SetVisible(self.WidgetAnchorGetNormalPop, false)
                                fnPlayDrawAni("AniMany")
                            end)
                        end)
                    else
                        -- 已抽中，则展示结果
                        fnTryShowResult()
                    end
                end
            end)
        end

        fnPlayDrawAni("AniOnce")
    end)
end

function UIPartnerXunFangView:Draw(dwPartnerID, nCount)
    local nTotalMeetTeaCount = self:GetTotalMeetTeaCount()
    if nTotalMeetTeaCount <= 0 then
        return
    end

    UIHelper.RemoteCallToServer("On_Hero_UiDrawStart", dwPartnerID, nCount)
end

function UIPartnerXunFangView:StopDraw(dwPartnerID)
    UIHelper.RemoteCallToServer("On_Hero_UiDrawStart", dwPartnerID, 0)
end

--- 当前是否设置为连续抽卡模式
function UIPartnerXunFangView:IsContinuousDraw()
    return UIHelper.GetSelected(self.TogXunFangContinuous)
end

--- 当前是否正在连续抽卡的过程中
function UIPartnerXunFangView:StillInContinuousDraw()
    return self:IsContinuousDraw() and self.bInContinuousDraw
end

function UIPartnerXunFangView:UpdateContinuousDrawProgress()
    UIHelper.SetProgressBarPercent(self.ProgressBarContinuousDraw, 100 * self.nContinuousDrawProgress / self.nContinuousDrawTotal)
    UIHelper.SetString(self.LabelProgressContinuousDraw, string.format("正在寻访 %d/%d", self.nContinuousDrawProgress, self.nContinuousDrawTotal))
end

function UIPartnerXunFangView:UpdateRoleImg(bForceHide)
    local tDrawInfo     = self:GetSelPartnerDrawInfo()

    local bInTaskOrMeet = tDrawInfo.nState == PartnerDrawState.InTask or tDrawInfo.nState == PartnerDrawState.Meet
    UIHelper.SetVisible(self.ImgRoleNotMeet, not bForceHide and not bInTaskOrMeet)
    UIHelper.SetVisible(self.ImgRoleInTaskOrMeet, not bForceHide and bInTaskOrMeet)
end

function UIPartnerXunFangView:StopContinuousDraw()
    self:StopDraw(self.nSelID)
end

function UIPartnerXunFangView:On_Partner_StopDraw(dwPartnerID, nMeetTimes, nState)
    if dwPartnerID ~= self.nSelID then
        UIMgr.Close(self)
        return
    end

    self:UpdateSelPartnerDrawInfo(self.nSelID, nState, nMeetTimes)

    if self:IsContinuousDraw() then
        self.bInContinuousDraw = false

        UIHelper.SetVisible(self.WidgetAnchorStopContinuousDraw, false)

        --- 连抽结束时重新启用抽取失败的全屏按钮
        UIHelper.SetEnable(self.WidgetAnchorGetNormalPop, true)
    end

    UIHelper.StopAllAni(self)

    self:UpdateInfo()

    self:ShowDrawResult(true)
end

function UIPartnerXunFangView:AniFinishShowDrawResult()
    local tDrawInfo = self:GetSelPartnerDrawInfo(self.nSelID)

    local nState    = tDrawInfo.nState

    self:UpdateInfo()

    self:ShowDrawResult(true)

    if self:IsContinuousDraw() then
        -- 连抽
        if nState == PartnerDrawState.NotMeet then
            -- 刷新进度
            self.nContinuousDrawProgress = self.nContinuousDrawProgress + 1
            self:UpdateContinuousDrawProgress()
        else
            -- 抽到了，隐藏停止喝茶按钮
            UIHelper.SetVisible(self.WidgetAnchorStopContinuousDraw, false)
        end
    end
end

function UIPartnerXunFangView:UpdateDrawFailInfo()
    local tDrawInfo    = self:GetSelPartnerDrawInfo()
    local tPartnerInfo = Table_GetPartnerNpcInfo(tDrawInfo.dwID)
    if tPartnerInfo then
        -- 使用下一个传记内容
        self.nShowStoryIndex = self.nShowStoryIndex + 1

        local tStoryList     = Table_GetPartnerDrawStory(tDrawInfo.dwID)
        if table.get_len(tStoryList) > 0 then
            local nStoryIndex = (self.nShowStoryIndex - 1) % #tStoryList + 1
            local tStory      = tStoryList[nStoryIndex]

            local szTitle     = UIHelper.GBKToUTF8(tStory.szTitle)

            local szContent   = ParseTextHelper.ParseNormalText(UIHelper.GBKToUTF8(tStory.szStory))
            szContent         = UIHelper.TruncateStringReturnOnlyResult(szContent, 256)

            UIHelper.SetString(self.LabelGetNormalTitle, szTitle)
            UIHelper.SetString(self.LabelGetNormalContent, szContent)
        end
    end
end

return UIPartnerXunFangView