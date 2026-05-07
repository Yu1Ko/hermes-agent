-- ---------------------------------------------------------------------------------
-- Author: Unknown
-- Name: UIOperationCenterView
-- Date: 2026-03-18 17:04:14
-- Desc: ?
-- ---------------------------------------------------------------------------------

--[[
-- 新花萼楼，在旧花萼楼基础上加了一层分类
-- 逻辑应该是要从VK旧花萼楼挪过来，VK看起来有自己的配表和规则，应该都是要沿用的
-- 沿用旧花萼楼一个活动两个id, 基本的活动配置id是nOperationID, VK配置的id是nID

-- 组件预制如果他功能很独立，那么OnEnter后自行UpdateInfo
-- 否则应该开放一些接口，由更上层的脚本去设置，避免一直id if else
--]]

local UIOperationCenterView = class("UIOperationCenterView")

local SIGN_IN_ID = 16
local SIMPLE_BTN_ID = 146

function UIOperationCenterView:OnEnter(nOperationID)
    if not self.bInit then
        self:RegEvent()
        self:BindUIEvent()
        self.bInit = true

        OperationCenterData.InitOpenOperations()
    end

    Global.SetShowRewardListEnable(VIEW_ID.PanelOperationCenter, true)
    Global.SetShowLeftRewardTipsEnable(VIEW_ID.PanelOperationCenter, false)

    self:SetSelectedOperationID(nOperationID)
    self:UpdateInfo()
end

function UIOperationCenterView:OnExit()
    OperationCenterData.SetCurOperationID(self.nDisplayOperationID)
    Global.SetShowRewardListEnable(VIEW_ID.PanelOperationCenter, false)
    Global.SetShowLeftRewardTipsEnable(VIEW_ID.PanelOperationCenter, true)
    self.bInit = false
    self:UnRegEvent()

    self:ResetOperationPrefab()
end

function UIOperationCenterView:BindUIEvent()
    UIHelper.BindUIEvent(self.BtnClose, EventType.OnClick, function()
        UIMgr.Close(self)
    end)

    UIHelper.BindUIEvent(self.BtnChat, EventType.OnClick, function()
        UIMgr.Open(VIEW_ID.PanelChatSocial)
    end)
end

function UIOperationCenterView:RegEvent()
    Event.Reg(self, EventType.OnWindowsSizeChanged, function()
        self:AdjustVideoSize()
    end)
end

function UIOperationCenterView:UnRegEvent()
    --Event.UnReg(self, EventType.XXX)
end

-- ----------------------------------------------------------
-- Please write your own code below  ↓↓↓
-- ----------------------------------------------------------

function UIOperationCenterView:SetSelectedOperationID(nOperationID)
    self.nCurCategoryID = 1
    self.nCurOperationID = nil
    nOperationID = nOperationID or OperationCenterData.GetCurOperationID()
    if nOperationID and not HuaELouData.CheackActivityOpen(nOperationID) then
        return
    end
    if OperationCenterData.IsChildOperation(nOperationID) then
        local tParentInfo = OperationCenterData.GetParentOperation(nOperationID)
        if not tParentInfo or not HuaELouData.CheackActivityOpen(tParentInfo.dwID) then
            return
        end
        self.nCurOperationID = tParentInfo.dwID
        self.nDisplayOperationID = nOperationID
    else
        self.nCurOperationID = nOperationID
    end
    if self.nCurOperationID then
        local tOperationInfo = OperationCenterData.GetOperationInfo(self.nCurOperationID)
        self.nCurCategoryID = tOperationInfo.nCategoryID
    end
end

function UIOperationCenterView:UpdateInfo()
    self:UpdateCategoryList()
    self:UpdateOperationList()
    self:UpdateOperationInfo()
end

function UIOperationCenterView:UpdateCategoryList()
    local nSelectIndex = 1
    for nIndex, tog in ipairs(self.tTogFirst) do
        local script = UIHelper.GetBindScript(tog)
        local nCategroyID = script.nCategoryID and tonumber(script.nCategoryID) or 0
        local bShow = false
        if nCategroyID > 0 then
            local tInfo = OperationCenterData.GetCategoriesByID(nCategroyID)
            local tOpenOperations = OperationCenterData.GetOpenOperations(nCategroyID)
            if #tOpenOperations > 0 then
                bShow = true
                if self.nCurCategoryID == tInfo.nCategoryID then
                    nSelectIndex = nIndex
                end
                script:OnEnter(tInfo)
                UIHelper.SetSelected(script._rootNode, false, false)
                UIHelper.BindUIEvent(script._rootNode, EventType.OnSelectChanged, function(_, bSelected)
                    if bSelected and self.nCurCategoryID ~= tInfo.nCategoryID then
                        self.nCurCategoryID = tInfo.nCategoryID
                        self.nCurOperationID = nil
                        self:UpdateOperationList()
                        self:UpdateOperationInfo()
                    end
                end)
            end
        end
        UIHelper.SetVisible(tog, bShow)
    end

    UIHelper.ScrollViewDoLayoutAndToTop(self.ScrollViewTogFrist)
    UIHelper.SetSelected(self.tTogFirst[nSelectIndex], true, false)
end

function UIOperationCenterView:UpdateOperationList()
    local tOpenOperations = OperationCenterData.GetOpenOperations(self.nCurCategoryID)
    local scrollview = self.ScrollViewTogSecondOneLines
    local prefabID = PREFAB_ID.WidgetPublicTogSecond
    for _, tInfo in ipairs(tOpenOperations) do
        if tInfo.szTitle and tInfo.szTitle ~= "" then
            scrollview = self.ScrollViewTogSecondTwoLines
            prefabID = PREFAB_ID.WidgetPublicTogSecondTwoLines
            break
        end
    end
    UIHelper.RemoveAllChildren(scrollview)
    self.tTogSecondList = {}
    local nSelectIndex = 1
    local nIndex = 0
    for i, tInfo in ipairs(tOpenOperations) do
        if not OperationCenterData.IsChildOperation(tInfo.dwID) then
            nIndex = nIndex + 1
            if not self.nCurOperationID then
                self.nCurOperationID = tInfo.dwID
            end
            if self.nCurOperationID == tInfo.dwID then
                nSelectIndex = nIndex
            end
            local script = UIMgr.AddPrefab(prefabID, scrollview, tInfo)
            UIHelper.SetSelected(script.TogSecondNav, false, false)
            UIHelper.BindUIEvent(script.TogSecondNav, EventType.OnSelectChanged, function(_, bSelected)
                if bSelected and self.nCurOperationID ~= tInfo.dwID then
                    self.nCurOperationID = tInfo.dwID
                    self:CheckDisplayOperationID()
                    self:UpdateOperationInfo()
                    OperationCenterData.SetClickNew(tInfo.dwID)
                    script:SetNewVisible(false)
                end
            end)
            table.insert(self.tTogSecondList, script)
        end
    end
    UIHelper.ScrollViewDoLayoutAndToTop(scrollview)
    UIHelper.SetSelected(self.tTogSecondList[nSelectIndex].TogSecondNav, true, false)
    UIHelper.ScrollToIndex(scrollview, nSelectIndex - 1)
    self:CheckDisplayOperationID()
    OperationCenterData.SetClickNew(self.nCurOperationID)
    self.tTogSecondList[nSelectIndex]:SetNewVisible(false)

    local fnInitScrollView = function(scrollview, bVisible)
        local parent = UIHelper.GetParent(scrollview)
        UIHelper.SetVisible(parent, bVisible)
        if bVisible then
            parent._widgetArrow = UIHelper.GetChildByName(parent, "WidgetArrow")
            UIHelper.ScrollViewSetupArrow(scrollview, parent)
        end
    end
    fnInitScrollView(self.ScrollViewTogSecondOneLines, self.ScrollViewTogSecondOneLines == scrollview)
    fnInitScrollView(self.ScrollViewTogSecondTwoLines, self.ScrollViewTogSecondTwoLines == scrollview)
end

function UIOperationCenterView:CheckDisplayOperationID()
    local tChildren = OperationCenterData.GetOpenChildOperations(self.nCurOperationID)
    if not OperationCenterData.IsParentChild(self.nCurOperationID, self.nDisplayOperationID) then
        if not table.is_empty(tChildren) then
            self.nDisplayOperationID = tChildren[1].dwID
        else
            self.nDisplayOperationID = self.nCurOperationID
        end
    end
end

function UIOperationCenterView:SelectOperation(nOperationID)
    if not HuaELouData.CheackActivityOpen(nOperationID) then
        TipsHelper.ShowNormalTip("该活动未开启。")
        return
    end

    self:SetSelectedOperationID(nOperationID)

    local nSelectIndex = 1
    for i, tog in ipairs(self.tTogFirst or {}) do
        local script = UIHelper.GetBindScript(tog)
        local tInfo = script.tInfo or {}
        if self.nCurCategoryID == tInfo.nCategoryID then
            nSelectIndex = i
        end
        UIHelper.SetSelected(script._rootNode, false, false)
    end
    UIHelper.SetSelected(self.tTogFirst[nSelectIndex], true, false)

    self:UpdateOperationList()
    self:UpdateOperationInfo()
end

-- 父活动里选子活动
function UIOperationCenterView:SetDisplayOperationID(nOperationID)
    local tOperationInfo = OperationCenterData.GetOperationInfo(nOperationID)
    if tOperationInfo.dwParentID ~= self.nCurOperationID then
        return
    end
    self.nDisplayOperationID = nOperationID

    -- 这个 self.bBottomWithoutHideAll 是用来控制只有当在选择子活动的时候，不隐藏scriptBottom里的所有节点
    -- 目的是为了不让下面一排 ScorllViewBotton 在点击的时候不去重复播放动画，因为这个动画是PlayOnVisible的
    self.bBottomWithoutHideAll = true
    self:UpdateOperationInfo()
    self.bBottomWithoutHideAll = false
end

function UIOperationCenterView:UpdateOperationInfo()
    self:SetRwardBlackList()
    self:ResetOperationPrefab()
    self:InitOperationPrefab()
end

function UIOperationCenterView:parseAndAddPrefab(szConf, parent, ...)
    local tScriptList = {}
    if not szConf or szConf == "" then
        return tScriptList
    end

    local tComponents = string.split(szConf, ",")
    for _, szComponentName in ipairs(tComponents) do
        local szTrimmed = string.trim(szComponentName, " ")
        if szTrimmed ~= "" then
            local nPrefabID = PREFAB_ID[szTrimmed]
            if nPrefabID then
                local script
                if nPrefabID == PREFAB_ID.WidgetAnchoreContentScrollWide then
                    -- 这个不能挂靠在layout下, 特殊处理一下
                    script = UIMgr.AddPrefab(nPrefabID, UIHelper.GetParent(parent), ...)
                    self.WidgetAnchoreContentScrollWide = script._rootNode
                else
                    script = UIMgr.AddPrefab(nPrefabID, parent, ...)
                end
                if script then
                    table.insert(tScriptList, script)
                    UIHelper.CascadeDoLayoutDoWidget(script._rootNode, true, true)
                end
            end
        end
    end
    return tScriptList
end

function UIOperationCenterView:InitOperationPrefab()
    self.tComponentContext = {}
    local tActivity = TabHelper.GetHuaELouActivityByOperationID(self.nDisplayOperationID)
    if not tActivity then
        return
    end

    local tContext = self.tComponentContext
    tContext.scriptCenter = self

    if tActivity.nLayoutStyle ~= 0 then
        local layoutTop, layoutBottom
        if tActivity.nLayoutStyle == 1 then
            layoutTop, layoutBottom = self.LayoutContentTopWide420, self.LayoutContentBottonWide420
            UIHelper.SetVisible(self.WidgetAnchoreContentPublicWide420, true)
        elseif tActivity.nLayoutStyle == 2 then
            layoutTop, layoutBottom = self.LayoutContentTopWide540, self.LayoutContentBottonWide540
            UIHelper.SetVisible(self.WidgetAnchoreContentPublicWide540, true)
        end
        local tScriptLayoutTop =  self:parseAndAddPrefab(tActivity.szLayoutTop, layoutTop, tActivity.dwOperatActID, tActivity.nID)
        local tScriptLayoutBottom = self:parseAndAddPrefab(tActivity.szLayoutBottom, layoutBottom, tActivity.dwOperatActID, tActivity.nID)

        Timer.DelTimer(self, self.nTimerLayout)
        self.nTimerLayout = Timer.AddFrameCycle(self, 1, function()
            UIHelper.LayoutDoLayout(layoutTop)
            UIHelper.LayoutDoLayout(layoutBottom)
        end)

        local tSimpleBtnConfig = OperationSimpleTmplData.GetButtonList(self.nDisplayOperationID)
        for i, btn in ipairs(self:GetButton() or {}) do
            local nBtnID = self:GetBtnInfo(i, tActivity)
            if nBtnID ~= 0 then
                self:UpdateButton(i, nBtnID)
            elseif tSimpleBtnConfig[i] then
                self:UpdateButton(i, SIMPLE_BTN_ID, function()
                    if tSimpleBtnConfig[i].szLink and tSimpleBtnConfig[i].szLink ~= "" then
                        Event.Dispatch("EVENT_LINK_NOTIFY", tSimpleBtnConfig[i].szLink)
                    else
                        Event.Dispatch("OperationOnClickBtn", self.nDisplayOperationID)
                    end
                end, UIHelper.GBKToUTF8(tSimpleBtnConfig[i].szText))
            else
                self:UpdateButton(i, 0)
            end
        end

        tContext.tScriptLayoutTop = tScriptLayoutTop
        tContext.tScriptLayoutBottom = tScriptLayoutBottom
    end

    local scriptBottom = UIHelper.GetBindScript(self.WidgetAnchoreBottonScorllView)
    if tActivity.szBottom ~= "" then
        scriptBottom:OnEnter(tActivity.dwOperatActID, tActivity.nID, PREFAB_ID[tActivity.szBottom])
    elseif OperationCenterData.IsChildOperation(tActivity.dwOperatActID) then
        local tParentInfo = OperationCenterData.GetParentOperation(tActivity.dwOperatActID)
        local tParentActivity = TabHelper.GetHuaELouActivityByOperationID(tParentInfo.dwID)
        if tParentActivity.szBottom ~= "" then
            scriptBottom:OnEnter(tParentActivity.dwOperatActID, tParentActivity.nID, PREFAB_ID[tParentActivity.szBottom], self.bBottomWithoutHideAll)
            scriptBottom:UpdateParentChildrenList(self.nDisplayOperationID)
        end
    else
        scriptBottom:OnEnter(tActivity.dwOperatActID, tActivity.nID)
    end
    tContext.scriptBottom = scriptBottom

    if tActivity.szPrefab ~= "" then
        local nPrefabID = PREFAB_ID[tActivity.szPrefab]
        local scriptContent = UIMgr.AddPrefab(nPrefabID, self.WidgetAnchoreContent, tActivity.dwOperatActID, tActivity.nID)
        tContext.scriptContent = scriptContent
    end

    -- 背景底图
    local szImgPath = string.find(tActivity.szbgImgPath, "OperationCenter") and tActivity.szbgImgPath or ""
    self:ShowBg(szImgPath)

    -- 视频和特效
    self:PlayVideo(tActivity)
    self:PlaySfx(tActivity)

    -- 中间的PageView，用来切图的
    self:SetMiddlePageView()

    -- 商店
    local tShopInfo = Table_GetOperatActShopByID(self.nDisplayOperationID)
    if tShopInfo then
        if tShopInfo.bShowShop and tShopInfo.nShopGroupID ~= 0 and  tShopInfo.nShopID ~= 0 then
            self:InitShop(function() ShopData.OpenSystemShopGroup(tShopInfo.nShopGroupID, tShopInfo.nShopID) end)
        end
        if (tShopInfo.szCurrency and tShopInfo.szCurrency ~= "")
        or (tShopInfo.szItemCurrency and tShopInfo.szItemCurrency ~= "") then
            self:InitCurrency(tShopInfo.szCurrency, tShopInfo.szItemCurrency)
        end
    end

    -- 对应的脚本
    local szScriptName = tActivity.szScript ~= "" and tActivity.szScript or "Common"
    local szScriptPath = string.format("Lua/UI/OperationCenter/Operations/UIOperation%s.lua", szScriptName)
    self.scriptOperation = require(szScriptPath):CreateInstance()
    self.scriptOperation.szScriptPath = szScriptPath

    Timer.DelTimer(self, self.nTimerScript)
    self.nTimerScript = Timer.AddFrame(self, 1, function()
        -- 延迟一帧等context内的组件都初始化好，解决首次打开界面很多safe_check error的问题
        self.scriptOperation:OnEnter(tActivity.dwOperatActID, tActivity.nID, tContext)
    end)
end

function UIOperationCenterView:GetBtnInfo(k, tActivity)
    local nBtnID
    if k == 1 then
        nBtnID = tActivity.nBtnID
    elseif k == 2 then
        nBtnID = tActivity.nBtnID2
    elseif k ==3 then
        nBtnID = tActivity.nBtnID3
    end
    return nBtnID
end

function UIOperationCenterView:SetContentNameTitle(szName, szImgPath)
    UIHelper.SetVisible(self.WidgetAnchorNameTitle, true)
    UIHelper.SetString(self.LabelPartMark, szName or "")
    UIHelper.SetSpriteFrame(self.ImgPartMark, szImgPath)
    UIHelper.SetVisible(self.ImgPartMark, szImgPath ~= "")
end

function UIOperationCenterView:ShowModelInfo(dwTabType, dwItemID)
    local script = UIHelper.GetBindScript(self.MiniScene)
    script:SetSceneVisible(true)
    script:UpdateModelInfo(dwTabType, dwItemID)
end

function UIOperationCenterView:ShowItemBg(szImgPath, bUseImgSize)
    if not self.ImgItemBgSize then
        self.ImgItemBgSize = {UIHelper.GetContentSize(self.ImgItemBg)}
    end
    UIHelper.SetTexture(self.ImgItemBg, szImgPath, false)

    if bUseImgSize then
        local pTexture = UIHelper.GetTexture(self.ImgItemBg)
        local tImgSize = {UIHelper.GetContentSize(pTexture)}

        UIHelper.SetContentSize(self.ImgItemBg, tImgSize[1], tImgSize[2])
    else
        UIHelper.SetContentSize(self.ImgItemBg, self.ImgItemBgSize[1], self.ImgItemBgSize[2])
    end
end

function UIOperationCenterView:ShowBg(szImgPath)
    if string.is_nil(szImgPath) then
        UIHelper.SetVisible(self.ImgBg, false)
    else
        UIHelper.SetVisible(self.ImgBg, true)
        UIHelper.SetTexture(self.ImgBg, szImgPath)
    end
end

function UIOperationCenterView:SetSceneVisible(bVisible)
    local script = UIHelper.GetBindScript(self.MiniScene)
    script:SetSceneVisible(bVisible)
end

function UIOperationCenterView:HideButton()
    for _, v in ipairs(self:GetButton() or {}) do
        UIHelper.SetVisible(v, false)
    end
end

function UIOperationCenterView:GetButton()
    if self.nDisplayOperationID then
        local tActivity = TabHelper.GetHuaELouActivityByOperationID(self.nDisplayOperationID)
        if tActivity.nLayoutStyle == 1 then
            return self.tButton420
        else
            return self.tButton540
        end
    end
    return {}
end

function UIOperationCenterView:UpdateButton(nIndex, nBtnID, fnCallback, szName)
    local btn = self:GetButton()[nIndex]
    if not btn then return end
    local scriptBtn = UIHelper.GetBindScript(btn)
    if nBtnID and nBtnID > 0 then
        scriptBtn:OnEnter(nBtnID, fnCallback)
        if szName and szName ~= "" then
            scriptBtn:UpdateBtnDes(szName)
        end
    end
    UIHelper.SetVisible(btn, nBtnID ~= 0)
    UIHelper.SetEnable(btn, nBtnID ~= 0)
    UIHelper.LayoutDoLayout(UIHelper.GetParent(btn))
end

function UIOperationCenterView:ResetOperationPrefab()
    UIHelper.RemoveAllChildren(self.WidgetAnchoreContent)
    UIHelper.SetVisible(self.WidgetAnchoreBottonScorllView, false)

    UIHelper.RemoveAllChildren(self.LayoutContentTopWide420)
    UIHelper.RemoveAllChildren(self.LayoutContentBottonWide420)
    UIHelper.SetVisible(self.WidgetAnchoreContentPublicWide420, false)

    UIHelper.RemoveAllChildren(self.LayoutContentTopWide540)
    UIHelper.RemoveAllChildren(self.LayoutContentBottonWide540)
    UIHelper.SetVisible(self.WidgetAnchoreContentPublicWide540, false)

    UIHelper.SetVisible(self.WidgetAnchorNameTitle, false)

    self:SetSceneVisible(false)

    self:ShowItemBg("")

    -- 重置左上角
    self:ResetRightTop()

    if self.scriptOperation then
        self.scriptOperation:OnExit()
        package.loaded[self.scriptOperation.szScriptPath] = nil
        self.scriptOperation = nil
    end

    if self.WidgetAnchoreContentScrollWide then
        UIHelper.RemoveFromParent(self.WidgetAnchoreContentScrollWide, true)
        self.WidgetAnchoreContentScrollWide = nil
    end
end

-- 播放视频
function UIOperationCenterView:PlayVideo(tActivity, szVideoPath, bUseVideoSize)
    self:SetVideoVisible(false)

    if not tActivity and not szVideoPath then
        self:StopVideo()
        return
    end

    local szVideoPath = tActivity and tActivity.szVideoPath or szVideoPath
    if string.is_nil(szVideoPath) then
        self:StopVideo()
        return
    end

    self.scriptVideoPlayer = self.scriptVideoPlayer or UIHelper.AddPrefab(PREFAB_ID.WidgetNewVideo, self.WidgetVideoPlayer)
    self.VideoPlayer = self.scriptVideoPlayer.WidgetVideo
    UIHelper.SetPosition(self.VideoPlayer, 0, 0)

    self.bIsPlayingVideo = true
    self.bUseVideoSize = bUseVideoSize
    self:AdjustVideoSize()

    local szPlatform = Platform.IsWindows() and "PC" or "MOBILE"
    local szPath = string.format("mui/Video/%s/%s", szPlatform, szVideoPath)
    szPath = UIHelper.ParseVideoPlayerFile(szPath , VIDEOPLAYER_MODEL.BINK)

    UIHelper.SetVideoPlayerModel(self.VideoPlayer , VIDEOPLAYER_MODEL.BINK)
    UIHelper.SetVideoLooping(self.VideoPlayer, true)

    UIHelper.StopVideo(self.VideoPlayer)
    UIHelper.PlayVideo(self.VideoPlayer, szPath, true, function (nVideoPlayerEvent, szMsg)
        if nVideoPlayerEvent == ccui.VideoPlayerEvent.PLAYING then
            self:SetVideoVisible(true)
        end
    end)
end

-- 停止视频
function UIOperationCenterView:StopVideo()
    if self.VideoPlayer then
        UIHelper.StopVideo(self.VideoPlayer)
        UIHelper.RemoveAllChildren(self.WidgetVideoPlayer)
        self.VideoPlayer = nil
        self.scriptVideoPlayer = nil
    end

    self:SetVideoVisible(false)
    self.bIsPlayingVideo = false
    self.bUseVideoSize = false
end

function UIOperationCenterView:SetVideoVisible(bVisible)
    UIHelper.SetVisible(self.WidgetVideoPlayer, bVisible)
end

function UIOperationCenterView:AdjustVideoSize()
    if not self.bIsPlayingVideo then
        return
    end

    if not self.VideoPlayer then
        return
    end

    if self.bUseVideoSize then
        UIHelper.SetContentSize(self.VideoPlayer, 2560, 1440)
        return
    end

    local tReslutionSize = UIHelper.GetCurResolutionSize()
    local nodeW, nodeH = tReslutionSize.width, tReslutionSize.height --UIHelper.GetContentSize(self._rootNode)
    local fVideoRatio = 16 / 9
    local fScreenRatio = nodeW / nodeH
    local nVideoW, nVideoH
    if fScreenRatio > fVideoRatio then
        -- 屏幕更宽，以屏幕宽度为基准，高度等比放大（cover）
        nVideoW = nodeW
        nVideoH = nodeW / fVideoRatio
    else
        -- 屏幕更高，以屏幕高度为基准，宽度等比放大（cover）
        nVideoH = nodeH
        nVideoW = nodeH * fVideoRatio
    end
    UIHelper.SetContentSize(self.VideoPlayer, nVideoW, nVideoH)
end

-- 播放背景特效
function UIOperationCenterView:PlaySfx(tActivity)
    UIHelper.SetVisible(self.SfxBg, false)

    if not tActivity then
        return
    end

    local szSfxPath = tActivity.szSfxPath
    if string.is_nil(szSfxPath) then
        return
    end

    UIHelper.SetVisible(self.SfxBg, true)
    UIHelper.SetSFXPath(self.SfxBg, UTF8ToGBK(szSfxPath))
    UIHelper.PlaySFX(self.SfxBg)
end

-- 停止背景特效
function UIOperationCenterView:StopSfx()
    UIHelper.SetVisible(self.SfxBg, false)
end

function UIOperationCenterView:SetRwardBlackList()
    if self.nCurOperationID == SIGN_IN_ID then
        Global.SetShowRewardListEnable(VIEW_ID.PanelOperationCenter, false)
        Global.SetShowLeftRewardTipsEnable(VIEW_ID.PanelOperationCenter, true)
    else
        Global.SetShowRewardListEnable(VIEW_ID.PanelOperationCenter, true)
        Global.SetShowLeftRewardTipsEnable(VIEW_ID.PanelOperationCenter, false)
    end
end

function UIOperationCenterView:InitCurrency(szCurrency, szItemCurrency)
    local script = UIHelper.GetBindScript(self.WidgetAniRightTop)
    script:InitCurrency(szCurrency, szItemCurrency)
end

function UIOperationCenterView:InitShop(fnClickShop)
    local script = UIHelper.GetBindScript(self.WidgetAniRightTop)
    script:InitShop(fnClickShop)
end


function UIOperationCenterView:ResetRightTop()
    local script = UIHelper.GetBindScript(self.WidgetAniRightTop)
    script:Reset()
end

function UIOperationCenterView:SetMiddlePageView(tbImagePath, nSelectIdx)
    local nLen = tbImagePath and #tbImagePath or 0
    if nLen == 0 then
        UIHelper.SetVisible(self.WidgetPublicMiddlePicShow, false)
        return
    end

    UIHelper.SetVisible(self.WidgetPublicMiddlePicShow, true)

    UIHelper.BindUIEvent(self.PageViewPicShow, EventType.OnTurningPageView, function ()
        local nPageIndex = UIHelper.GetPageIndex(self.PageViewPicShow)
        self.bNeedScrollPage = false
        UIHelper.SetSelected(self.tbTogMiddlePicShow[nPageIndex + 1], true)
    end)

    UIHelper.SetVisible(self.TogGroupPicShow, nLen > 1)
    UIHelper.SetEnable(self.PageViewPicShow, nLen > 1)
    UIHelper.SetScrollViewMouseWheelEnabled(self.PageViewPicShow, false)

    for k, tog in ipairs(self.tbTogMiddlePicShow or {}) do
        UIHelper.SetVisible(tog, k <= nLen)
        if k <= nLen then
            UIHelper.BindUIEvent(tog, EventType.OnSelectChanged, function(_, bSelected)
                if bSelected then
                    if self.bNeedScrollPage == false then
                        self.bNeedScrollPage = true
                        return
                    end

                    UIHelper.ScrollToPage(self.PageViewPicShow, k - 1, 0.25)
                end
            end)
        end
    end

    for i = 1, 4 do
        local item = UIHelper.GetItem(self.PageViewPicShow, i - 1)
        local img = UIHelper.GetChildByName(item, string.format("WidgetPicShow%d/ImgPage%d", i, i))
        if img then
            if i <= nLen then
                UIHelper.SetVisible(img, true)
                UIHelper.SetTexture(img, tbImagePath[i])
            else
                UIHelper.SetVisible(img, false)
            end
        end
    end

    nSelectIdx = nSelectIdx or 1
    UIHelper.SetSelected(self.tbTogMiddlePicShow[nSelectIdx], true)
end

function UIOperationCenterView:GetCurActivityConf()
    local tActivityConf = TabHelper.GetHuaELouActivityByOperationID(self.nDisplayOperationID)
    return tActivityConf
end

return UIOperationCenterView