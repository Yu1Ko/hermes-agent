-- ---------------------------------------------------------------------------------
-- Author: luwenhao1
-- Name: UITaoguanView
-- Date: 2025-01-09 14:30:46
-- Desc: 年兽陶罐-自动砸罐界面 茗伊插件 PanelNianShouTaobaoGuanSetting
-- ---------------------------------------------------------------------------------

local UITaoguanView = class("UITaoguanView")

local tActivityMapID = { 6, 108, 194, 332 }
local tActivityLinkID = { 269 }

function UITaoguanView:OnEnter()
    if not self.bInit then
        self:RegEvent()
        self:BindUIEvent()
        self.bInit = true

        Timer.AddCycle(self, 0.5, function()
            self:UpdateLeftTime()
        end)
    end

    self:UpdateLeftTime()
    self:UpdateInfo()
    UIHelper.ScrollViewSetupArrow(self.ScrollViewCell, self.WidgetArrowParent)
    RemoteCallToServer("On_Activity_GetPotPoint")
end

function UITaoguanView:OnExit()
    self.bInit = false
    self:UnRegEvent()
end

function UITaoguanView:BindUIEvent()
    UIHelper.BindUIEvent(self.BtnClose, EventType.OnClick, function()
        UIMgr.Close(self)
    end)
    UIHelper.BindUIEvent(self.BtnNpc, EventType.OnClick, function()
        local tbTargetList = {}
        for _, nLinkID in pairs(tActivityLinkID) do
            local tAllLinkInfo = Table_GetCareerGuideAllLink(nLinkID)
            for _, tInfo in pairs(tAllLinkInfo) do
                table.insert(tbTargetList, tInfo)
            end
        end
        local tips, script = TipsHelper.ShowNodeHoverTipsInDir(PREFAB_ID.WidgetNPCGuideTips, self.BtnNpc, TipsLayoutDir.BOTTOM_LEFT, tbTargetList)
        local w, h = UIHelper.GetContentSize(script.LayoutLeaveForParent)
        tips:SetSize(w, h / 2)
        tips:Update()
    end)
    UIHelper.BindUIEvent(self.BtnGo, EventType.OnClick, function()
        --设置自动拾取
        UIMgr.Open(VIEW_ID.PanelAutoGetSettings, LootSetting, 3)
    end)
    UIHelper.BindUIEvent(self.BtnReset, EventType.OnClick, function()
        --恢复默认
        for k, v in pairs(MY_Taoguan.O_DEFAULT) do
            MY_Taoguan.O[k] = v
        end
        MY_Taoguan.O.Flush()
        self:UpdateInfo()
    end)
    UIHelper.BindUIEvent(self.BtnEquipShop, EventType.OnClick, function()
        ShopData.OpenSystemShopGroup(17, 88) --client\ui\Scheme\Case\SystemShopGroup.tab
    end)
    UIHelper.BindUIEvent(self.ToggleStart, EventType.OnSelectChanged, function(_, bSelected)
        if bSelected then
            MY_Taoguan.Start()
        else
            MY_Taoguan.Stop()
        end
    end)
    UIHelper.BindUIEvent(self.TogSettingsMultipleChoice, EventType.OnSelectChanged, function(_, bSelected)
        -- 停砸分数线
        local tip, script = TipsHelper.ShowNodeHoverTipsInDir(PREFAB_ID.WidgetSettingsMultipleChoicePop, self.TogSettingsMultipleChoice, TipsLayoutDir.LEFT_CENTER)
        local tBtnInfoList = {}

        for i = 2, MY_Taoguan.MAX_POINT_POW do
            local nScore = 10 * 2 ^ i
            local tInfo = {
                szName = tostring(nScore),
                func = function()
                    MY_Taoguan.O.nPausePoint = nScore
                    MY_Taoguan.O.Flush()
                    UIHelper.SetLabel(self.RichTextSettingsMultipleChoice, nScore)
                    TipsHelper.DeleteHoverTips(PREFAB_ID.WidgetSettingsMultipleChoicePop)
                end,
                fnSelected = function()
                    return nScore == MY_Taoguan.O.nPausePoint
                end,
                bScrollToIndex = true,
            }
            table.insert(tBtnInfoList, tInfo)
        end

        script:UpdateSingleChoice(tBtnInfoList)
        tip:SetOffset(20, 0)
        tip:Update()
    end)
    UIHelper.BindUIEvent(self.ToggleUseTaoguan, EventType.OnSelectChanged, function(_, bSelected)
        -- 必要时使用背包的陶罐
        MY_Taoguan.O.bUseTaoguan = bSelected
        MY_Taoguan.O.Flush()
    end)
    UIHelper.BindUIEvent(self.ToggleUsejinchui, EventType.OnSelectChanged, function(_, bSelected)
        -- 没小银锤时使用小金锤
        MY_Taoguan.O.bNoYinchuiUseJinchui = bSelected
        MY_Taoguan.O.Flush()
    end)
end

function UITaoguanView:RegEvent()
    Event.Reg(self, EventType.OnMYTaoguanStateChanged, function(bStart)
        UIHelper.SetSelected(self.ToggleStart, bStart, false)
    end)
    Event.Reg(self, "On_Activity_GetPotPoint", function(nPoint)
        UIHelper.SetLabel(self.LabelProgress, nPoint)
        UIHelper.LayoutDoLayout(self.LayoutAchievementProgress)
    end)
    Event.Reg(self, EventType.ShowImportantTip, function(Color, Text, bRichText, nTime)
        UIHelper.SetLabel(self.LabelProgress, MY_Taoguan.D.nPoint)
        UIHelper.LayoutDoLayout(self.LayoutAchievementProgress)
    end)
    Event.Reg(self, EventType.OnSelectLeaveForBtn, function(tbInfo)
        local tbPoint = tbInfo.tPoint or { tbInfo.fX, tbInfo.fY, tbInfo.fZ }
        MapMgr.SetTracePoint(UIHelper.GBKToUTF8(tbInfo.szNpcName), tbInfo.dwMapID, tbPoint)
        UIMgr.Open(VIEW_ID.PanelMiddleMap, tbInfo.dwMapID, 0)
        Event.Dispatch(EventType.HideAllHoverTips)

        UIMgr.Close(self)
        UIMgr.Close(VIEW_ID.PanelHalfBag)
    end)
end

function UITaoguanView:UnRegEvent()
    --Event.UnReg(self, EventType.XXX)
end






-- ----------------------------------------------------------
-- Please write your own code below  ↓↓↓
-- ----------------------------------------------------------

function UITaoguanView:UpdateInfo()
    local dwMapID = MapHelper.GetMapID()
    if not table.contain_value(tActivityMapID, dwMapID) then
        UIHelper.SetCanSelect(self.ToggleStart, false, "只能在扬州、成都、太原、侠客岛，主城使用")
    end

    UIHelper.SetLabel(self.LabelProgress, MY_Taoguan.D.nPoint or "-")
    UIHelper.SetSelected(self.ToggleStart, MY_Taoguan.D.bEnable, false)
    UIHelper.SetSelected(self.ToggleUseTaoguan, MY_Taoguan.O.bUseTaoguan, false)
    UIHelper.SetSelected(self.ToggleUsejinchui, MY_Taoguan.O.bNoYinchuiUseJinchui, false)
    UIHelper.SetLabel(self.RichTextSettingsMultipleChoice, MY_Taoguan.O.nPausePoint)
    UIHelper.LayoutDoLayout(self.LayoutAchievementProgress)

    UIHelper.RemoveAllChildren(self.Layout2)

    for _, p in ipairs(MY_Taoguan.D.aUseItemPS) do
        local szID = p.szID
        local szTitleScore = "使用" .. p.szName
        local nScoreLimit = MY_Taoguan.O['nUse' .. szID]
        local szTitleStop = "若缺停砸"
        local bStopEnable  = MY_Taoguan.O['bPauseNo' .. szID]

        local scriptScore = UIHelper.AddPrefab(PREFAB_ID.WidgetScoreLimit, self.Layout2, szTitleScore, nScoreLimit)
        scriptScore:SetID(szID)
        scriptScore:SetItemIcon(5, p.dwItemIndex)
        scriptScore:BindCallback(function()
            local tip, script = TipsHelper.ShowNodeHoverTipsInDir(PREFAB_ID.WidgetSettingsMultipleChoicePop, self.TogSettingsMultipleChoice, TipsLayoutDir.LEFT_CENTER)
            local tBtnInfoList = {}

            for i = 2, MY_Taoguan.MAX_POINT_POW - 1 do
                local nScore = 10 * 2 ^ i
                local tInfo = {
                    szName = tostring(nScore),
                    func = function()
                        MY_Taoguan.O['nUse' .. szID] = nScore
                        MY_Taoguan.O.Flush()
                        Event.Dispatch(EventType.OnMYTaoguanScoreLimitChanged, szID, nScore)
                        TipsHelper.DeleteHoverTips(PREFAB_ID.WidgetSettingsMultipleChoicePop)
                    end,
                    fnSelected = function()
                        return nScore == MY_Taoguan.O['nUse' .. szID]
                    end,
                    bScrollToIndex = true,
                }
                table.insert(tBtnInfoList, tInfo)
            end

            script:UpdateSingleChoice(tBtnInfoList)
            tip:SetOffset(20, 0)
            tip:Update()
        end)

        local scriptStop = UIHelper.AddPrefab(PREFAB_ID.WidgetActivitySwitch, self.Layout2, szTitleStop, bStopEnable)
        scriptStop:BindCallback(function(bSelected)
            MY_Taoguan.O['bPauseNo' .. szID] = bSelected
            MY_Taoguan.O.Flush()
        end)
    end

    UIHelper.LayoutDoLayout(self.Layout2)
    UIHelper.ScrollViewDoLayoutAndToTop(self.ScrollViewCell)
end

function UITaoguanView:UpdateLeftTime()
    local szTime = ""
    if MY_Taoguan.D.nPoint > 0 then
        local tBuffTimeData = Buffer_GetTimeData(1659)
        if not tBuffTimeData then
            MY_Taoguan.D.nPoint = 0
            UIHelper.SetLabel(self.LabelProgress, 0)
            UIHelper.LayoutDoLayout(self.LayoutAchievementProgress)
            return
        end
        local nLeftTime = tBuffTimeData.nEndFrame and (BuffMgr.GetLeftFrame(tBuffTimeData) / GLOBAL.GAME_FPS) or tBuffTimeData.nLeftTime
        local nH, nM, nS = TimeLib.GetTimeToHourMinuteSecond(nLeftTime)
        if nH >= 1 then
            szTime = string.format("（%s后清空）", Timer.FormatInChineseComplete(nLeftTime))
        else
            szTime = string.format("（<color=#ff9696>%s</color>后清空）", Timer.FormatInChineseComplete(nLeftTime))
        end
    end
    UIHelper.SetLabel(self.LabelTime, szTime)
    UIHelper.LayoutDoLayout(self.LayoutAchievementProgress)
end

return UITaoguanView