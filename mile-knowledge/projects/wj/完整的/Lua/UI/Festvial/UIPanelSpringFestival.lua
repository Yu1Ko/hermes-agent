-- ---------------------------------------------------------------------------------
-- Author: Unknown
-- Name: UIPanelSpringFestival
-- Date: 2026-1-13 20:41:58
-- Desc: ?
-- ---------------------------------------------------------------------------------

local COLLECTION_SET_ID = 622
local COLLECTION_ACTIVE_ID = 5

local function ParseItem(szReward)
    if not szReward then
        return
    end

    local tRes = {}
    local tList = SplitString(szReward, ";")
    for _, v in ipairs(tList) do
        local t = SplitString(v, "_")
        table.insert(tRes, { dwTabType = tonumber(t[1]), dwIndex = tonumber(t[2]), nCount = tonumber(t[3]) })
    end
    return tRes
end

-----------------------------DataModel------------------------------
local DataModel = {}

function DataModel.Init(nType)
    DataModel.nActivityType = 0
    DataModel.bPlayedMovie = false
    DataModel.tTypeList = Table_GetSpecialActivityType()
    DataModel.tActivityList = {}
    DataModel.tAllActivityList = Table_GetSpecialActivityInfo()
    DataModel.nSelectTeachImage = 0
    DataModel.nWaitAniCount = 0
    DataModel.tUnlockCouplet = {}
    DataModel.bPlayingAni = false
    DataModel.bPlayedEnterAni = false
    DataModel.bEnterFinish = false
    DataModel.SetActivityType(nType)
end

function DataModel.SetActivityType(nType)
    DataModel.nActivityType = nType
    DataModel.tActivityList = {}
    DataModel.tCoupletData = {}
    DataModel.tActivityState = {}
    for _, tActivity in pairs(DataModel.tAllActivityList) do
        tActivity.tRewardList = ParseItem(tActivity.szReward)
        tActivity.tTeachImgList = SplitString(tActivity.szImgBgPath, ";")
        tActivity.tCoupletList = {}
        local t = SplitString(tActivity.szCustomData, ";")
        for _, v in pairs(t) do
            if not DataModel.tCoupletData[v] then
                DataModel.tCoupletData[v] = {}
            end
            table.insert(DataModel.tCoupletData[v], tActivity.dwID)
            table.insert(tActivity.tCoupletList, tonumber(v))
        end
        table.insert(DataModel.tActivityList, tActivity)
    end
    DataModel.UpdateActivityState()
    --local tData = GetSpecialActivityData(nType) or {}
    --DataModel.szTweenFile = tData.szTweenFile
end

function DataModel.GetActivityTypeInfo(nType)
    if not nType then
        nType = DataModel.nActivityType
    end
    for _, tType in ipairs(DataModel.tTypeList) do
        if tType.nType == nType then
            return tType
        end
    end
end

function DataModel.GetActivityInfo(dwID)
    if not dwID then
        return
    end
    for _, tActivity in ipairs(DataModel.tActivityList) do
        if tActivity.dwID == dwID then
            return tActivity
        end
    end
end

function DataModel.GetTeachImageList(dwID)
    local tActivity = DataModel.GetActivityInfo(dwID)
    if not tActivity then
        return
    end
    return tActivity.tTeachImgList
end

function DataModel.GetCoupletStateByActivity(dwID)
    if not dwID then
        return
    end
    return DataModel.tCoupletData[dwID]
end

function DataModel.UpdateActivityState()
    DataModel.tCoupletState = DataModel.tCoupletState or {}
    DataModel.tActivityState = {}
    for _, v in pairs(DataModel.tAllActivityList) do
        if v.tCoupletList then
            local bFinish = true
            for _, nCoupletID in pairs(v.tCoupletList) do
                if not DataModel.tCoupletState[nCoupletID] then
                    bFinish = false -- 需要所有对联解锁才算完成
                    break
                end
            end
            DataModel.tActivityState[v.dwID] = bFinish and not IsTableEmpty(v.tCoupletList)
        end
    end
end

function DataModel.UnInit()
end

-----------------------------------------------------------------

local MIN_SCALE = 1
local MAX_SCALE = 4

local tFestivalName = {
    ["砸年兽"] = "zanianshou",
    ["接财纳福"] = "jiecai",
    ["年年有鱼"] = "ruixue",
    ["戏雪迎春"] = "xueren",
    ["焰火巡游"] = "huadeng",
    ["年夜盛宴"] = "nianyefan",
    ["更多活动"] = "more",
    ["上元团圆"] = "shangyuantuanyuan",
    ["鱼龙舞街"] = "yulongwujie",
    ["飞鸢续线"] = "feiyuanxuxian",
    ["喜乐连连"] = "xilelianlian",
    ["悠然闲居"] = "youranxianju",
}
local nScaleValue = 1.6
local nMaxSpeed = 0.03
local nTweenTime = 0.3
local nButtonXOffset = 100
local szImgPathFormat = "UIAtlas2_Festival_SpringFestivalBtn_btn_%s.png"
local szLabelPathFormat = "UIAtlas2_Festival_SpringFestivalBtn_label_%s.png"
local szLabelPathFormat_YuanXiao = "UIAtlas2_Festival_LanternFestivalBtn_label_%s.png"
local szImgPathFormat_YuanXiao = "UIAtlas2_Festival_LanternFestivalBtn_btn_%s.png"

local nSpringFestivalItemID = 6038
local nLanternFestivalItemID = 27910

local UIPanelSpringFestival = class("UIPanelSpringFestival")

function UIPanelSpringFestival:OnEnter(nType)
    if not self.bInit then
        self:RegEvent()
        self:BindUIEvent()
        self.bInit = true
        self.bStartMove = true
        self.bFirstEnter = true
    end
    Timer.DelAllTimer(self)
    DataModel.Init(nType)

    self:InitPanel()
    self:CheckReward()
end

function UIPanelSpringFestival:OnExit()
    self.bInit = false
    self:UnRegEvent()
    SoundMgr.PlaySound(SOUND.UI_SOUND, "Stop_UI_ChunJie_Amb")
    SoundMgr.PlayLastBgMusic()
end

function UIPanelSpringFestival:BindUIEvent()
    UIHelper.BindUIEvent(self.BtnClose, EventType.OnClick, function()
        UIMgr.Close(self)
    end)

    UIHelper.BindUIEvent(self.BtnEquipShop, EventType.OnClick, function()
        local tInfo = DataModel.GetActivityTypeInfo()
        ShopData.OpenSystemShopGroup(tInfo.dwShopGroupID, tInfo.dwDefaultShopID)
    end)
end

function UIPanelSpringFestival:RegEvent()
    Event.Reg(self, EventType.OnSelectLeaveForBtn, function(tbInfo)
        TipsHelper.DeleteAllHoverTips()
        ActivityData.Teleport_Go(tbInfo)
    end)

    Event.Reg(self, "DO_CUSTOM_OTACTION_PROGRESS", function()
        UIMgr.Close(VIEW_ID.PanelSpringFestivalRightSide)
        UIMgr.Close(self)
    end)

    Event.Reg(self, "ON_SYNC_SET_COLLECTION_TO_AWARD_ACTIVE", function()
        local nActiveID = arg0
        if nActiveID == COLLECTION_ACTIVE_ID then
            self:CheckReward()
        end
        self:UpdateCouplet()
    end)

    Event.Reg(self, "OnUnlockCouplet", function(tInfo)
        DataModel.tUnlockCouplet = tInfo
        self:UnlockCoupletSFX()
        self:UpdateCouplet()
        self:PlayFireworksSFX()
    end)

    Event.Reg(self, "Test", function(tInfo)
        UIHelper.SetVisible(self.WidgetSFXDone, true)
        --UIHelper.PlaySFX(self.WidgetSFXDone, false)
    end)
end

function UIPanelSpringFestival:UnRegEvent()
    --Event.UnReg(self, EventType.XXX)
end

-- ----------------------------------------------------------
-- Please write your own code below  ↓↓↓
-- ----------------------------------------------------------

function UIPanelSpringFestival:PlayOnEnter()
    if not self.bFirstEnter then
        return
    end
    self.bFirstEnter = false
    local tTypeInfo = DataModel.GetActivityTypeInfo()

    local fnEnterAnim = function()
        SoundMgr.PlaySound(SOUND.UI_SOUND, "UI_ChunJie_Amb")
        SoundMgr.PlaySound(SOUND.UI_SOUND, "UI_ChunJie_PaperOpen")

        UIHelper.PlayAni(self, self.AniAll, "AniSpringFestivalShow", function()
            UIHelper.SetVisible(self.WidgetSFX1, true)
            UIHelper.SetVisible(self.WidgetSFX2, true)
            self:PlayFireworksSFX()
        end)
        Timer.Add(self, 0.05, function()
            MovieMgr.StopVideo()
        end)
    end

    if not Storage.SpringFestivalFirstEnter[tTypeInfo.nType] then
        local szPath = Platform.IsWindows() and "mui/Video/PC/chunjie_opening.bk2" or "mui/Video/MOBILE/chunjie_opening.bk2"
        MovieMgr.PlayVideo(szPath, { bNet = false, bHideSkip = true, bKeepSound = true }, { szMoviePath = szPath }, false)

        Timer.Add(self, 4.7, fnEnterAnim)
        Storage.SpringFestivalFirstEnter[tTypeInfo.nType] = true
        CustomData.Dirty(CustomDataType.Role)
        SoundMgr.PlayBgMusic("BGM_State_SiHaiTongGe_ChunJie_Intra", 0, nil, true)
    else
        fnEnterAnim()
        SoundMgr.PlayBgMusic("BGM_State_SiHaiTongGe_ChunJie", 0, nil, true)
    end
end

function UIPanelSpringFestival:InitPanel()
    self:InitBackgroundMovement()
    self:InitCouplet()
    self:InitTypeSwitchTog()

    self.tActivityScript = {}
    self.tYuanXiaoTogScript = {}

    for _, tActInfo in ipairs(DataModel.tActivityList) do
        local bYuanXiao = tActInfo.nType == 2
        local tScriptList = bYuanXiao and self.tYuanXiaoTogScript or self.tActivityScript
        local tParentList = bYuanXiao and self.tYuanXiaoToggleParents or self.tActivityToggleParents
        local tRangeWidget = bYuanXiao and self.ImgMapMaskLanternFestival or self.ImgMapMask

        local togScript = UIHelper.AddPrefab(PREFAB_ID.WidgetSpringFestivalActivityTog, tParentList[#tScriptList + 1])
        togScript.dwID = tActInfo.dwID
        self:SetupToggle(togScript, DataModel.GetActivityInfo(tActInfo.dwID), tRangeWidget)
        table.insert(tScriptList, togScript)
    end

    self:PlayOnEnter()
    self:SwitchPanel()
    self:UpdateBtnFinishState()
end

function UIPanelSpringFestival:InitBackgroundMovement()
    self.tTouchListSpringFestival = {}
    self.tTouchListYuanXiao = {}

    local tMovableInfoList = {
        {
            node = self.WidgetAnchorMidWide,
            nSpeedFactor = nMaxSpeed,
        },
        {
            node = self.WidgetBgDeco1,
            nSpeedFactor = 0.1,
        },
        {
            node = self.Cloud,
            nSpeedFactor = 0.06,
        },
        {
            node = self.Bridge,
            nSpeedFactor = 0.04,
        },
        {
            node = self.WidgetBgDeco2,
            nSpeedFactor = 0.04,
        },
        {
            node = self.Buildings,
            nSpeedFactor = 0.02,
        },
        {
            node = self.Mountains,
            nSpeedFactor = 0.01,
        },
    }

    local tYuanXiaoMovableList = {
        {
            node = self.LanternToggles,
            nSpeedFactor = nMaxSpeed,
        },
        {
            node = self.LanternFestivalWidgetBgDeco1,
            nSpeedFactor = 0.1,
        },
        {
            node = self.LanternFestivalCloud,
            nSpeedFactor = 0.06,
        },
        {
            node = self.LanternFestivalBridge,
            nSpeedFactor = 0.04,
        },
        {
            node = self.LanternFestivalWidgetBgDeco2,
            nSpeedFactor = 0.04,
        },
        {
            node = self.LanternFestivalBuildings,
            nSpeedFactor = 0.02,
        },
        {
            node = self.LanternFestivalMountains,
            nSpeedFactor = 0.01,
        },
    }

    local fnGenerate = function(tMoveList, tRangeWidget, tTouchList)
        for _, tInfo in ipairs(tMoveList) do
            local node = tInfo.node
            local nSpeedFactor = tInfo.nSpeedFactor
            local TouchComponent = require("Lua/UI/Map/Component/UIMapTouchComponent"):CreateInstance()
            TouchComponent:Init(node)

            local nodeW, nodeH = UIHelper.GetContentSize(node)
            TouchComponent:SetMoveRegion(-nodeW / 2, nodeW / 2, -nodeH / 2, nodeH / 2)
            TouchComponent:SetRangeWidget(tRangeWidget)
            TouchComponent:SetMoveSpeed(nSpeedFactor, nMaxSpeed)
            TouchComponent:SetScaleLimit(MIN_SCALE, MAX_SCALE)
            TouchComponent:Scale(1)
            TouchComponent:SetTweenTime(nTweenTime)
            TouchComponent:RegisterPosEvent(function(x, y)
            end)
            table.insert(tTouchList, TouchComponent)
        end
    end

    fnGenerate(tMovableInfoList, self.ImgMapMask, self.tTouchListSpringFestival)
    fnGenerate(tYuanXiaoMovableList, self.ImgMapMaskLanternFestival, self.tTouchListYuanXiao)
end

function UIPanelSpringFestival:SwitchPanel()
    local bYuanXiao = DataModel.nActivityType ~= 1
    UIHelper.SetVisible(self.WidgetChunLianRight, not bYuanXiao)
    UIHelper.SetVisible(self.WidgetChunLianLeft, not bYuanXiao)

    UIHelper.SetVisible(self.ImgMapMask, not bYuanXiao)

    UIHelper.SetVisible(self.ImgMapMaskLanternFestival, bYuanXiao)

    UIHelper.RemoveAllChildren(self.LayoutRightTopCurrency)
    UIHelper.AddPrefab(PREFAB_ID.WidgetCurrency, self.LayoutRightTopCurrency)
    UIHelper.AddPrefab(PREFAB_ID.WidgetSingleCurrency, self.LayoutRightTopCurrency, 5, bYuanXiao and nLanternFestivalItemID or nSpringFestivalItemID, true)

    local tType = DataModel.GetActivityTypeInfo()
    local nDiff = tType.nEndTime - GetCurrentTime()
    local nDay = UIHelper.GetHeightestTimeText(nDiff, false)
    local szText = nDay .. "后结束"
    UIHelper.SetString(self.LabelRemainDay, szText)
    UIHelper.SetColor(self.LabelRemainDay, nDiff < 3 * 24 * 3600 and cc.c3b(255, 234, 136) or cc.c3b(255, 255, 255)) -- 小于三天变为黄色
    UIHelper.SetVisible(self.LayoutLabelCount, nDiff > 0)
    UIHelper.LayoutDoLayout(self.LayoutLabelCount)
    UIHelper.LayoutDoLayout(self.WidgetContentRightTop)

    -- 背景跟随鼠标移动效果
    if Platform.IsWindows() or KeyBoard.MobileHasKeyboard() then
        local tScriptList = bYuanXiao and self.tTouchListYuanXiao or self.tTouchListSpringFestival
        for _, script in ipairs(tScriptList) do
            script.nTouchX = 0 -- 不使用TouchBegin 因为里面有不正确的ConvertToNodeSpace
            script.nTouchY = 0
        end

        if self.nMouseMoveTimerID then
            Timer.DelTimer(self, self.nMouseMoveTimerID)
        end
        self.nMouseMoveTimerID = Timer.AddCycle(self, 0.01, function()
            if not self.bStartMove then
                return
            end
            local nCursorX, nCursorY = self:GetConvertedCursorPos()
            local bXCanMove, bYCanMove = true, true -- 当有一个背景到达边缘时，其余背景不再移动 而仅仅是更新触控位置
            for _, script in ipairs(tScriptList) do
                local bXCanMove1, bYCanMove1 = script:TouchMovedXY(nCursorX, nCursorY, bXCanMove, bYCanMove)
                bXCanMove = bXCanMove and bXCanMove1
                bYCanMove = bYCanMove and bYCanMove1
            end
        end)
    end
end

function UIPanelSpringFestival:InitTypeSwitchTog()
    local nEnabledActivityCount = 0
    local lst = { self.TogChunJie, self.TogYuanXiao }
    local nCurrentTime = GetCurrentTime()
    for _, tType in ipairs(DataModel.tTypeList) do
        local tog = lst[_]
        UIHelper.ToggleGroupAddToggle(self.TogGroupLeftBotton, tog)
        UIHelper.BindUIEvent(tog, EventType.OnSelectChanged, function(btn, bSel)
            if bSel then
                DataModel.SetActivityType(tType.nType)
                self:SwitchPanel()
            end
        end)

        if DataModel.nActivityType == tType.nType then
            UIHelper.SetToggleGroupSelectedToggle(self.TogGroupLeftBotton, tog) -- 选中对用导航Toggle
        end
        if not DataModel.nActivityType or DataModel.nActivityType == 0 then
            DataModel.SetActivityType(tType.nType)
        end
        
        local bEnabled = nCurrentTime >= tType.nStartTime and nCurrentTime <= tType.nEndTime
        nEnabledActivityCount = nEnabledActivityCount + (bEnabled and 1 or 0)
    end

    UIHelper.SetVisible(self.TogGroupLeftBotton, nEnabledActivityCount == 2) -- 两个活动同时存在时才显示
end

function UIPanelSpringFestival:SetupToggle(togScript, tActivity, tScaleParent)
    local fnMoveNode = function(node, x, y, fnScale)
        local parent = UIHelper.GetParent(node)
        if parent then
            local px, py = UIHelper.GetAnchorPoint(parent)
            local pw, ph = UIHelper.GetContentSize(parent)
            x = x + px * pw
            y = y + py * ph
        end

        local movetoEnd = cc.MoveTo:create(nTweenTime, cc.p(x, y))
        local sequence = cc.Sequence:create(movetoEnd, fnScale)
        node:runAction(sequence)
    end

    local bYuanXiao = tActivity.nType == 2
    local tNodeScript = UIHelper.GetBindScript(bYuanXiao and togScript.WidgetYuanXiaoParent or togScript.WidgetSpringFestivalParent)
    UIHelper.SetVisible(togScript.WidgetSpringFestivalParent, not bYuanXiao)
    UIHelper.SetVisible(togScript.WidgetYuanXiaoParent, bYuanXiao)

    local node = togScript._rootNode
    local parentNode = UIHelper.GetParent(node)
    local nX, nY = node:getPosition()
    local wX, wY = UIHelper.ConvertToWorldSpace(parentNode, nX, nY)

    local fnPlaySfx = function()
        if togScript.bPlayingSfx == nil then
            togScript.bPlayingSfx = false
        end

        if not togScript.bPlayingSfx then
            togScript.bPlayingSfx = true
            UIHelper.PlaySFX(togScript.Eff_Button, false)
            Timer.Add(togScript, 1, function()
                togScript.bPlayingSfx = false
            end)
        end

    end

    local szConvert = tFestivalName[UIHelper.GBKToUTF8(tActivity.szName)]
    if szConvert then
        UIHelper.SetSpriteFrame(tNodeScript.ImgActivity, string.format(bYuanXiao and szImgPathFormat_YuanXiao or szImgPathFormat, szConvert), false, false)
        UIHelper.SetSpriteFrame(tNodeScript.ImgLabel, string.format(bYuanXiao and szLabelPathFormat_YuanXiao or szLabelPathFormat, szConvert), false, false)
    end

    local nCurrentTime = GetCurrentTime()
    local nStartTime = tActivity.nStartTime or 0
    local bStarted = nCurrentTime >= nStartTime
    togScript.bStarted = bStarted
    if not bStarted then
        local nDiff = nStartTime - nCurrentTime
        local nDay = UIHelper.GetHeightestTimeText(nDiff, false)
        local szText = nDay .. "后开启"
        UIHelper.SetString(tNodeScript.LabelDay, szText)
    end
    UIHelper.SetVisible(tNodeScript.ImgTime, not bStarted)

    UIHelper.BindUIEvent(togScript.BtnActivity, EventType.OnDragOver, function()
        fnPlaySfx()
        SoundMgr.PlaySound(SOUND.UI_SOUND, "UI_ChunJie_Hover")
        self:ActiveCouplet(tActivity.dwID, true)
    end)
    UIHelper.BindUIEvent(togScript.BtnActivity, EventType.OnDragOut, function()
        self:ActiveCouplet(tActivity.dwID, false)
    end)

    UIHelper.BindUIEvent(togScript.BtnActivity, EventType.OnClick, function()
        self.bStartMove = false
        self:SetOtherNodeVisible(togScript, false)
        fnPlaySfx()
        SoundMgr.PlaySound(SOUND.UI_SOUND, "UI_ChunJie_Click")

        local bDone1 = DataModel.tActivityState[tActivity.dwID]
        UIMgr.Open(VIEW_ID.PanelSpringFestivalRightSide, {
            tActivityData = tActivity,
            bDone = bDone1,
            DataModel = DataModel,
            nQuestItemIndex = DataModel.GetActivityTypeInfo().nQuestItemIndex,
            fnClose = function()
                self:SetOtherNodeVisible(togScript, true)
                local nCursorX, nCursorY = self:GetConvertedCursorPos()
                for _, script in ipairs(self.tTouchListSpringFestival) do
                    script:TweenToPos(nCursorX, nCursorY)
                end
                local callfunc = cc.CallFunc:create(function()
                    self.bStartMove = true -- 允许背景移动
                end)

                local seq = cc.Sequence:create(cc.ScaleTo:create(nTweenTime, 1), callfunc)
                tScaleParent:runAction(seq)
                fnMoveNode(tScaleParent, 0, 0)
            end
        })

        local s1, s2 = UIHelper.ConvertToNodeSpace(UIHelper.GetParent(tScaleParent), wX, wY)
        local seq = cc.Sequence:create(cc.ScaleTo:create(nTweenTime, nScaleValue))
        tScaleParent:runAction(seq)
        fnMoveNode(tScaleParent, -s1 * nScaleValue - nButtonXOffset, -s2 * nScaleValue)
    end)
end

function UIPanelSpringFestival:SetOtherNodeVisible(script, bState)
    UIHelper.SetVisible(self.WidgetlAniMid, bState)
    for _, togScript in ipairs(self.tActivityScript) do
        if togScript ~= script then
            local seq = cc.Sequence:create(cc.FadeTo:create(nTweenTime, bState and 255 or 0), nil)
            togScript._rootNode:runAction(seq)
        end
    end
end

function UIPanelSpringFestival:GetConvertedCursorPos()
    local tCursor = Platform.IsWindows() and GetViewCursorPoint() or GetCursorPoint()
    local tPos = cc.Director:getInstance():convertToGL({ x = tCursor.x, y = tCursor.y })
    local nCursorX, nCursorY = UIHelper.ConvertToNodeSpace(self._rootNode, tPos.x, tPos.y)
    return -nCursorX, nCursorY, tPos.x, tPos.y
end

function UIPanelSpringFestival:InitCouplet()
    self.tCoupletScripts = {}
    local fnAddCoupletTog = function(list, szPrefix, nStartIndex)
        for nIndex, parent in ipairs(list) do
            local script = UIHelper.AddPrefab(PREFAB_ID.WidgetChunLianLabelTog, parent)
            UIHelper.SetVisible(script.SFX_Unlock, false)
            UIHelper.SetSpriteFrame(script.ImgLabel, string.format(szPrefix, nIndex), false, false)
            UIHelper.BindUIEvent(script.TogChunLianLabel, EventType.OnDragOver, function(btn, nX, nY)
                UIHelper.SetVisible(script.ImgLabelBg, true)
                self:ActiveCoupletButton(nIndex + nStartIndex)
            end)
            UIHelper.BindUIEvent(script.TogChunLianLabel, EventType.OnDragOut, function(btn, nX, nY)
                UIHelper.SetVisible(script.ImgLabelBg, false)
            end)
            UIHelper.BindUIEvent(script.TogChunLianLabel, EventType.OnClick, function(btn, nX, nY)
                self:ShowUnlockCoupletTip(nIndex + nStartIndex, script.TogChunLianLabel)
            end)

            table.insert(self.tCoupletScripts, script)
        end
    end

    fnAddCoupletTog(self.tChunLianRightParents, "UIAtlas2_Festival_Duilian_Left_%d.png", 0)
    fnAddCoupletTog(self.tChunLianLeftParents, "UIAtlas2_Festival_Duilian_Right_%d.png", 7)

    self:UpdateCouplet()
end

function UIPanelSpringFestival:UpdateCouplet()
    local hPlayer = GetClientPlayer()
    if not hPlayer then
        return
    end

    if not hPlayer.HaveSetCollectionData() then
        return
    end

    local tData = hPlayer.GetSetCollection(COLLECTION_SET_ID)
    if not tData or not tData.tSetUnit then
        return
    end

    local bAllGet = true
    local tState = tData.tSetUnit
    DataModel.tCoupletState = {}
    for nPos, nState in pairs(tState) do
        local script = self.tCoupletScripts[nPos]
        script.bGet = nState == 1
        UIHelper.SetVisible(script.ImgLabel, nState == 1)
        --UIHelper.SetVisible(script.SFX_Unlock, nState == 1)
        if nState ~= 1 then
            bAllGet = false
        end
        DataModel.tCoupletState[nPos] = nState == 1
    end

    DataModel.UpdateActivityState()
    DataModel.bCoupletAllGet = bAllGet
    self:UpdateBtnFinishState()
end

function UIPanelSpringFestival:UnlockCoupletSFX()
    for _, nCoupletID in pairs(DataModel.tUnlockCouplet) do
        if not nCoupletID then
            return
        end
        local script = self.tCoupletScripts[nCoupletID]
        UIHelper.SetVisible(script.SFX_Unlock, true)
        UIHelper.PlaySFX(script.SFX_Unlock, false)
    end

    DataModel.tUnlockCouplet = {}
end

function UIPanelSpringFestival:ActiveCoupletButton(nCoupletID)
    if not nCoupletID then
        return
    end
    local t = DataModel.tCoupletData
    local tList = t[tostring(nCoupletID)]
    if not tList then
        return
    end

    for _, v in pairs(tList) do
        local script = self.tActivityScript[v]
        UIHelper.PlaySFX(script.Eff_Button, false)
    end
end

function UIPanelSpringFestival:ActiveCouplet(dwActivityID, bActive)
    local tInfo = DataModel.GetActivityInfo(dwActivityID)
    if not tInfo then
        return
    end
    local tCoupletList = tInfo.tCoupletList
    if not tCoupletList then
        return
    end
    for _, nCoupletIndex in pairs(tCoupletList) do
        local hCouplet = self.tCoupletScripts[nCoupletIndex]
        if hCouplet and not hCouplet.bGet then
            UIHelper.SetVisible(hCouplet.ImgLabelBg, bActive)
        end
    end
end

function UIPanelSpringFestival:UpdateBtnFinishState()
    for _, togScript in pairs(self.tActivityScript) do
        local dwID = togScript.dwID
        local bGet = DataModel.tActivityState[dwID]
        local tData = DataModel.GetActivityInfo(dwID)
        local bHasCost = tData.nQuestItemCost ~= 0
        if UIHelper.GetVisible(togScript.ImgDone) == false and bGet then
            UIHelper.PlaySFX(togScript.SFX_Unlock, false)
        end

        UIHelper.SetVisible(togScript.ImgDone, bHasCost and togScript.bStarted and bGet)
        UIHelper.SetVisible(togScript.ImgDeco, bHasCost and togScript.bStarted and not bGet)
    end
end

function UIPanelSpringFestival:PlayFireworksSFX()
    UIHelper.SetVisible(self.WidgetSFXDone, DataModel.bCoupletAllGet)
end

function UIPanelSpringFestival:ShowUnlockCoupletTip(nCoupletID, btn)
    if not nCoupletID then
        return
    end

    local t = DataModel.tCoupletData
    local tList = t[tostring(nCoupletID)]
    if not tList then
        return
    end

    local dwActivityID = tList[1]
    if not dwActivityID then
        return
    end

    local tInfo = DataModel.GetActivityInfo(dwActivityID)
    if not tInfo then
        return
    end
    local szText = FormatString(g_tStrings.STR_UNLOCK_COUPLET_TIP, UIHelper.GBKToUTF8(tInfo.szName))
    local tips, script = TipsHelper.ShowNodeHoverTipsInDir(PREFAB_ID.WidgetPublicLabelTips, btn,
            nCoupletID > 7 and TipsLayoutDir.BOTTOM_RIGHT or TipsLayoutDir.BOTTOM_LEFT, szText)
    tips:SetOffset(0, 0)
    tips:Update()
end

function UIPanelSpringFestival:CheckReward()
    local hPlayer = GetClientPlayer()
    if not hPlayer then
        return
    end
    local tData = hPlayer.GetSetCollection(COLLECTION_SET_ID)
    if not tData then
        return
    end
    if tData.eType == SET_COLLECTION_STATE_TYPE.TO_AWARD then
        hPlayer.ApplySetCollectionAward(COLLECTION_SET_ID)
    end
end

return UIPanelSpringFestival