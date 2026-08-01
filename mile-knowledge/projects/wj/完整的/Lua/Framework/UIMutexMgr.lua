--[[
    UI界面互斥 by huqing

    1.目前只做了侧面板的互斥，侧面板是通过 UISidePageViewTab 配置决定
    2.Page Layer的界面才适用此功能
    3.如果大家都是侧面板，但是一个是左一个是右，那就不互斥
]]




UIMutexMgr = UIMutexMgr or {}
local self = UIMutexMgr

local tbIgnoreViewIDMap =
{
    [VIEW_ID.PanelTeach_UIPageLayer] = true,
    [VIEW_ID.PanelRevive] = true,
    [VIEW_ID.PanelPostBattleOperation] = true,
}

local tbTouchSceneIgnoreViewIDs =
{
    VIEW_ID.PanelCharacter,
    VIEW_ID.PanelAccessory,
    VIEW_ID.PanelHalfBag,
}

function UIMutexMgr.Init()

    self.tbSidePageList = {}
    self.tbSidePageCounterMap = {}
    self.bCanCloseTopSidePageView = true

    Event.Reg(self, EventType.OnWindowsSizeChanged, function()
        self.bWindowsSizeChanged = true
    end)

    Event.Reg(self, EventType.OnViewOpen, function(nViewID)
        if not self.IsPageView(nViewID) then return end
        if self.IsIgnoreView(nViewID) then return end

        local conf = TabHelper.GetUIViewTab(nViewID)
        if not conf then return end

        local bImmediately = conf.nPlayMainCityAnimType <= 0
        local bIsSidePageView, bIsRightSidePage = self.IsSidePageView(nViewID)

        -- 隐藏Page界面里的 Bottom Bar及交互列表
        if bIsSidePageView then
            UIHelper.HidePageBottomBar(nil, bIsRightSidePage)
            UIHelper.HideInteract()
        end

        for k, v in ipairs(self.tbSidePageList) do
            if v._nViewID ~= nViewID then
                local _, _bIsRightSidePage = self.IsSidePageView(v._nViewID)

                local bNeedHide = false
                if bIsSidePageView then
                    -- 如果大家都是侧面板，同一边就隐藏
                    bNeedHide = bIsRightSidePage == _bIsRightSidePage
                else
                    -- 非侧面板直接隐藏
                    bNeedHide = true
                end

                if bNeedHide then
                    self.HideSidePage(v, bImmediately)
                end
            end
        end
    end)

    Event.Reg(self, EventType.OnViewClose, function(nViewID)
        if not self.IsPageView(nViewID) then return end
        if self.IsIgnoreView(nViewID) then return end

        local conf = TabHelper.GetUIViewTab(nViewID)
        if not conf then return end

        local bImmediately = conf.nPlayMainCityAnimType <= 0
        local bIsSidePageView, bIsRightSidePage = self.IsSidePageView(nViewID)

        -- 显示Page界面里的 Bottom Bar及交互列表
        if bIsSidePageView then
            UIHelper.ShowPageBottomBar(nil, bIsRightSidePage)
            UIHelper.ShowInteract()
        end

        for k, v in ipairs(self.tbSidePageList) do
            if v._nViewID ~= nViewID then
                local _, _bIsRightSidePage = self.IsSidePageView(v._nViewID)

                local bNeedShow = false
                if bIsSidePageView then
                    -- 如果大家都是侧面板，同一边就显示
                    bNeedShow = bIsRightSidePage == _bIsRightSidePage
                else
                    -- 非侧面板直接显示
                    bNeedShow = true
                end

                if bNeedShow then
                    self.ShowSidePage(v, bImmediately, self.bWindowsSizeChanged)
                end
            end
        end

        self.bWindowsSizeChanged = false
    end)

    -- 点击到场景后，关闭最后打开的 SidePageView
    Event.Reg(self, EventType.OnSceneTouchWithoutMove, function()
        self._closeTopSidePageView()
    end)
end

function UIMutexMgr.UnInit()

end


function UIMutexMgr.RegSidePageListener(scriptView)
    if not scriptView then return end

    local nViewID = scriptView._nViewID
    if not IsNumber(nViewID) then return end

    local bIsSidePageView, bIsRightSidePage = self.IsSidePageView(nViewID)
    if not bIsSidePageView then return end

    table.insert(self.tbSidePageList, scriptView)
    self.tbSidePageCounterMap[scriptView] = 0
end

function UIMutexMgr.UnRegSidePageListener(scriptView)
    if not scriptView then return end

    local nViewID = scriptView._nViewID
    if not IsNumber(nViewID) then return end

    local bIsSidePageView, bIsRightSidePage = self.IsSidePageView(nViewID)
    if not bIsSidePageView then return end

    for k, v in ipairs(self.tbSidePageList) do
        if v == scriptView then
            table.remove(self.tbSidePageList, k)
            self.tbSidePageCounterMap[scriptView] = nil
            break
        end
    end
end

function UIMutexMgr.ShowSidePage(scriptView, bImmediately, bWindowsSizeChanged)
    if not scriptView then return end
    if not self.tbSidePageCounterMap[scriptView] then return end

    local nCount = self.tbSidePageCounterMap[scriptView]
    if nCount == 1 then
        self._doShowSidePage(scriptView, bImmediately, bWindowsSizeChanged)
    end

    -- 引用计数 -1
    self.tbSidePageCounterMap[scriptView] = nCount - 1
    if self.tbSidePageCounterMap[scriptView] < 0 then
        self.tbSidePageCounterMap[scriptView] = 0
    end
end

function UIMutexMgr._doShowSidePage(scriptView, bImmediately, bWindowsSizeChanged)
    if not scriptView then return end

    local nViewID = scriptView._nViewID
    if not IsNumber(nViewID) then return end

    local conf = UISidePageViewTab[nViewID]
    if not conf then return end

    local doAlign = function()
        if bWindowsSizeChanged or Platform.IsWindows() or Platform.IsMac() then
            UIHelper.WidgetFoceDoAlign(scriptView)
        end
    end

    local szShowAnim = conf.szShowAnim
    if string.is_nil(szShowAnim) then
        UIHelper.SetVisible(scriptView._rootNode, true)

        doAlign()
    else
        local fadeInOutInfo = scriptView._fadeInOutInfo
        local animNode = fadeInOutInfo and fadeInOutInfo.animNode
        if animNode then
            local bToEndFrame = bImmediately
            Event.Dispatch(EventType.OnViewMutexPlayShowAnimBegin, nViewID)
            UIHelper.SetVisible(scriptView._rootNode, true)
            UIHelper.PlayAni(scriptView, animNode, szShowAnim, function()
                doAlign()
                Event.Dispatch(EventType.OnViewMutexPlayShowAnimFinish, nViewID)
            end, nil, bToEndFrame, 2)
        end
    end
end

function UIMutexMgr.HideSidePage(scriptView, bImmediately)
    if not scriptView then return end
    if not self.tbSidePageCounterMap[scriptView] then return end

    local nCount = self.tbSidePageCounterMap[scriptView]
    if nCount <= 0 then
        self._doHideSidePage(scriptView, bImmediately)
    end

    -- 引用计数 +1
    self.tbSidePageCounterMap[scriptView] = nCount + 1
end

function UIMutexMgr._doHideSidePage(scriptView, bImmediately)
    if not scriptView then return end

    local nViewID = scriptView._nViewID
    if not IsNumber(nViewID) then return end

    local conf = UISidePageViewTab[nViewID]
    if not conf then return end

    local szHideAnim = conf.szHideAnim
    if string.is_nil(szHideAnim) then
        UIHelper.SetVisible(scriptView._rootNode, false)
    else
        local fadeInOutInfo = scriptView._fadeInOutInfo
        local animNode = fadeInOutInfo and fadeInOutInfo.animNode
        if animNode then
            local bToEndFrame = bImmediately
            Event.Dispatch(EventType.OnViewMutexPlayHideAnimBegin, nViewID)
            UIHelper.PlayAni(scriptView, animNode, szHideAnim, function()
                UIHelper.SetVisible(scriptView._rootNode, false)
                Event.Dispatch(EventType.OnViewMutexPlayHideAnimFinish, nViewID)
            end, nil, bToEndFrame, 2)
        end
    end
end

function UIMutexMgr._closeTopSidePageView()
    if not self.bCanCloseTopSidePageView then return end
    if not self.tbSidePageList then return end

    for _, nViewID in ipairs(tbTouchSceneIgnoreViewIDs) do
        if UIMgr.GetView(nViewID) then
            return
        end
    end

    -- 有tips 先关Tips
    if UIMgr.GetView(VIEW_ID.PanelHoverTips) then
        return
    end

    local nLen = #self.tbSidePageList
    local scriptView = self.tbSidePageList[nLen]
    if scriptView then
        UIMgr.Close(scriptView)
    end
end

function UIMutexMgr.IsPageView(nViewID)
    local bResult = false
    local tbConf = TabHelper.GetUIViewTab(nViewID)
    if tbConf then
        if UILayer[tbConf.szLayerName] == UILayer.Page then
            bResult = true
        end
    end
    return bResult
end

function UIMutexMgr.IsSidePageView(nViewID)
    local tbConf = self.GetSidePageConf(nViewID)
    local bIsSidePageView = tbConf ~= nil
    local bIsRightSidePage = tbConf and tbConf.bRight or false
    return bIsSidePageView, bIsRightSidePage
end

function UIMutexMgr.GetSidePageConf(nViewID)
    return UISidePageViewTab[nViewID]
end

function UIMutexMgr.IsIgnoreView(nViewID)
    return tbIgnoreViewIDMap[nViewID]
end

function UIMutexMgr.SetCanCloseTopSidePageView(bValue)
    self.bCanCloseTopSidePageView = bValue
end
