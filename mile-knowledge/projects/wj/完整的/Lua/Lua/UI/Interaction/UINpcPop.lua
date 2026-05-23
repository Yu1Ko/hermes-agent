-- ---------------------------------------------------------------------------------
-- Author: Unknown
-- Name: UINpcPop
-- Date: 2024-12-25 19:44:30
-- Desc: ?
-- Prefab: UINpcPop
-- ---------------------------------------------------------------------------------

local UINpcPop = class("UINpcPop")

function UINpcPop:OnEnter(szTargetID)
    if not self.bInit then
        self:RegEvent()
        self:BindUIEvent()
        self.bInit = true
    end

    self:InitNpc(szTargetID)
    self:UpdateInfo()
end

function UINpcPop:OnExit()
    self.bInit = false
    self:UnRegEvent()

    -- 主界面退出时，将次级菜单的tips也给干掉
    TipsHelper.DeleteHoverTips(PREFAB_ID.WidgetInteractionMorePop)
    TipsHelper.DeleteHoverTips(PREFAB_ID.WidgetTipTargetgetMark)
    Timer.DelAllTimer(self)
end

function UINpcPop:BindUIEvent()
    UIHelper.BindUIEvent(self.BtnPlayerIcon, EventType.OnClick, function()
        self:ShowPlaceLabelTips(tbShowLabelTipIndex.PlayerIcon)
    end)

    UIHelper.BindUIEvent(self.ImgTwoway, EventType.OnClick, function()
        self:ShowPlaceLabelTips(tbShowLabelTipIndex.Twoway)
    end)

    UIHelper.BindUIEvent(self.BtnPlaceLabel, EventType.OnClick, function()
        self:ShowPlaceLabelTips(tbShowLabelTipIndex.PlaceLabel)
    end)

    UIHelper.BindUIEvent(self.BtnGotoLand, EventType.OnClick, function()
        UIMgr.Open(VIEW_ID.PanelHome, 1, self.tbPlayerCard.dwLandMapID, self.tbPlayerCard.nLandCopyIndex, self.tbPlayerCard.nLandIndex, self.tbRoleEntryInfo.dwPlayerID)
        TipsHelper.DeleteAllHoverTips()
    end)

    UIHelper.BindUIEvent(self.BtnGotoPrivateLand, EventType.OnClick, function()
        if not self.tbRoleEntryInfo then
            return
        end

        local tLine = Table_GetPrivateHomeSkin(self.tbPlayerCard.dwPHomeMapID, self.tbPlayerCard.dwPHomeSkin)
        local szText = FormatString(g_tStrings.STR_LINK_PRIVATE_CLICK_MSG, UIHelper.GBKToUTF8(self.tbRoleEntryInfo.szName), FormatString(g_tStrings.STR_LINK_PRIVATE, UIHelper.GBKToUTF8(tLine.szSkinName)))
        UIHelper.ShowConfirm(szText, function()
            if CheckPlayerIsRemote(nil, g_tStrings.STR_REMOTE_NOT_TIP) then
                return
            end
            local nMapID = self.tbPlayerCard.dwPHomeMapID
            local nCopyIndex = self.tbPlayerCard.nPHomeCopyIndex
            local dwSkinID = self.tbPlayerCard.dwPHomeSkin

            local function _goPrivateLand()
                HomelandData.GoPrivateLand(nMapID, nCopyIndex, dwSkinID, 3)
            end
            if PakDownloadMgr.UserCheckDownloadHomelandRes(nMapID, dwSkinID, _goPrivateLand) then
                _goPrivateLand()
            end
        end)
        TipsHelper.DeleteAllHoverTips()
    end)

    UIHelper.BindUIEvent(self.BtnPersonalCard, EventType.OnClick, function()
        self:SetPersonalVisible(true)
        TipsHelper.DeleteHoverTips(PREFAB_ID.WidgetInteractionMorePop)
        TipsHelper.DeleteHoverTips(PREFAB_ID.WidgetTipTargetgetMark)
    end)

    UIHelper.BindUIEvent(self.BtnShare, EventType.OnClick, function()
        ChatHelper.SendPlayerToChat(self.szName)
    end)
end

function UINpcPop:RegEvent()
end

function UINpcPop:UnRegEvent()
    --Event.UnReg(self, EventType.XXX)
end

-- ----------------------------------------------------------
-- Please write your own code below  ↓↓↓
-- ----------------------------------------------------------
function UINpcPop:InitNpc(szTargetID)
    if IsNumber(szTargetID) then
        self.dwTargetNpcId = szTargetID
        self.dwTargetNpc = GetNpc(szTargetID)
    end
end

function UINpcPop:UpdateInfo()
    --self.BtnPlayerIcon:setTouchDownHideTips(false)
    --self.ImgTwoway:setTouchDownHideTips(false)
    --self.BtnPlaceLabel:setTouchDownHideTips(false)
    --self.BtnGotoLand:setTouchDownHideTips(false)
    --self.BtnGotoPrivateLand:setTouchDownHideTips(false)
    --self.BtnEmpty:setTouchDownHideTips(false)
    --self.BtnPersonalCard:setTouchDownHideTips(false)
    --self.BtnShare:setTouchDownHideTips(false)
    --
    --local nTopHeight = UIHelper.GetHeight(self.WidgetTop)
    --local nBtnHeight = UIHelper.GetHeight(self.BtnPlayerIcon)
    --self.nTopHeight = nTopHeight
    --self.nHideBtnpHeight = nTopHeight - nBtnHeight

    -- 隐藏一些组件
    --UIHelper.SetVisible(self.LayoutSite, false)
    --UIHelper.SetVisible(self.ImgPlayerPopTipsBg, false)
    --UIHelper.SetVisible(self.WidgetLogInTime, false)
    --UIHelper.SetVisible(self.WidgetStudentNum1, false)
    --UIHelper.SetVisible(self.BtnPersonalCard, false)
    --
    --if self.bIsFromChat then
    --    UIHelper.SetVisible(self.LableGroup, not self.bIsFromChat)
    --    UIHelper.SetVisible(self.LableGroupTitle, not self.bIsFromChat)
    --    UIHelper.SetVisible(self.WidgetEquip, not self.bIsFromChat)
    --end
    --
    ---- 预制中默认隐藏，但我们这个界面中需要显示，先调整为可见
    --UIHelper.SetVisible(self.widgetPlayerMenu, true)
    --
    self:UpdateMenus()
    self:UpdatePlayerInfo()

    UIHelper.LayoutDoLayout(self.widgetPlayerMenu)
    UIHelper.LayoutDoLayout(self.LayoutPlayer)
end

function UINpcPop:UpdatePlayerInfo()
    local targetNpc = self.dwTargetNpc
    if not targetNpc then
        return
    end

    self.szName = UIHelper.GBKToUTF8(targetNpc.szName)
    local szUtf8Name = UIHelper.LimitUtf8Len(UIHelper.GBKToUTF8(targetNpc.szName), 8)

    UIHelper.SetString(self.LableName, szUtf8Name == "" and g_tStrings.MENTOR_DELETE_ROLE or szUtf8Name)

    UIHelper.LayoutDoLayout(self.LayoutPlayer)
end

function UINpcPop:GenerateMenuConfig()
    local targetNpc = self.dwTargetNpc
    if not targetNpc then
        return
    end

    self.tbAllMenuConfig = {
        { szName = "跟随", bCloseOnClick = true, callback = function()
            if OBDungeonData.IsPlayerInOBDungeon() then
                TipsHelper.ShowNormalTip("当前状态无法跟随")
                return
            end

            FollowTarget(TARGET.NPC, self.dwTargetPlayerId)
            OnCheckAddAchievement(1002, "Fellow")
        end, fnDisable = function()
            return targetNpc and targetNpc.dwEmployer ~= 0 -- 不能跟随玩家的宠物、侠客等玩家相关的NPC
        end }
    }

    local player = GetClientPlayer()
    if player and player.IsInParty() then
        local hTeam = GetClientTeam()
        local dwMark = hTeam.GetAuthorityInfo(TEAM_AUTHORITY_TYPE.MARK)
        if dwMark == player.dwID then
            table.insert(self.tbAllMenuConfig, { szName = g_tStrings.STR_MARK_TARGET,
                                                 bTeamMark = true,
                                                 dwMemberID = self.dwTargetNpcId })
        end
    end

    table.insert_tab(self.tbAllMenuConfig, JX_TargetList.GenerateMenuConfig(self.dwTargetNpcId
    , UIHelper.GBKToUTF8(targetNpc.szName), false, true))
end

function UINpcPop:UpdateMenus()
    if not self.tbAllMenuConfig then
        self:GenerateMenuConfig()
    end

    if self.tbAllMenuConfig and #self.tbAllMenuConfig == 0 then
        UIHelper.SetVisible(self.widgetPlayerMenu, false)
    end
    self:CreateMenus(self.tbAllMenuConfig, self.LayoutMenu)
end

function UINpcPop:CreateMenus(tbAllMenuConfig, layoutParent, morePopParent)
    local tbShowMenuConfig = {}

    for _, tbMenuConfig in ipairs(tbAllMenuConfig or {}) do
        if not tbMenuConfig.fnCheckShow or tbMenuConfig.fnCheckShow() then
            table.insert(tbShowMenuConfig, tbMenuConfig)
        end
    end

    local nMididx = math.ceil(#tbShowMenuConfig / 2) % 2 ~= 0 and math.ceil(#tbShowMenuConfig / 2) or math.ceil(#tbShowMenuConfig / 2) + 1

    for idx, tbMenuConfig in ipairs(tbShowMenuConfig) do
        if tbMenuConfig.bTeamMark then
            self:CreateTeamMarkMenu(tbMenuConfig, layoutParent)
        elseif not tbMenuConfig.bNesting then
            -- 判断是否设置了不满足条件时隐藏窗口
            local bHide = tbMenuConfig.bHideIfDisable and IsFunction(tbMenuConfig.fnDisable) and tbMenuConfig.fnDisable()

            if not bHide then
                -- 普通按钮
                local btnScript = UIHelper.AddPrefab(PREFAB_ID.WidgetInteractionMoreBtn, layoutParent)

                UIHelper.SetString(btnScript.LableMpore, tbMenuConfig.szName)

                if not morePopParent and nMididx == idx then
                    morePopParent = btnScript._rootNode
                end

                UIHelper.SetTouchDownHideTips(btnScript.Btn, false)

                UIHelper.BindUIEvent(btnScript.Btn, EventType.OnClick, function(btnClicked)
                    if IsFunction(tbMenuConfig.fnDisable) and tbMenuConfig.fnDisable() then
                        -- 如果按钮禁用的时候能有明显ui表现，这里可以挪到上面，并调整为将按钮禁用
                        TipsHelper.ShowNormalTip(tbMenuConfig.szName .. " 不符合条件，无法操作")
                        return
                    end

                    if tbMenuConfig.bCloseOnClick then
                        TipsHelper.DeleteHoverTips(PREFAB_ID.WidgetNPCPop)
                        --Event.Dispatch(EventType.DeletePlayerPop)
                    end

                    if IsFunction(tbMenuConfig.callback) then
                        tbMenuConfig.callback()
                    end
                end)

                if IsFunction(tbMenuConfig.fnDisable) then
                    local fnCheckDisable = function()
                        local nState = tbMenuConfig.fnDisable() and BTN_STATE.Disable or BTN_STATE.Normal
                        UIHelper.SetButtonState(btnScript.Btn, nState)
                    end

                    -- 初始先检查一次
                    fnCheckDisable()

                    -- 如果设置了检查间隔，就定时检查
                    if tbMenuConfig.nCheckDisableInterval then
                        Timer.AddCycle(self, tbMenuConfig.nCheckDisableInterval, function()
                            fnCheckDisable()
                        end)
                    end
                end
            end
        else
            local toggleScript = UIHelper.AddPrefab(PREFAB_ID.WidgetInteractionMoreTog, layoutParent)
            self.tbTogMenu = self.tbTogMenu or {}
            table.insert(self.tbTogMenu, toggleScript)

            if not morePopParent and nMididx == idx then
                morePopParent = toggleScript._rootNode
            end

            local nIndex = #self.tbTogMenu
            UIHelper.SetString(toggleScript.LableMpore, tbMenuConfig.szName)
            UIHelper.SetSelected(toggleScript.Toggle, false)
            UIHelper.ToggleGroupAddToggle(self.TogGroupMenu, toggleScript.Toggle)

            toggleScript.Toggle:setTouchDownHideTips(false)
            UIHelper.BindUIEvent(toggleScript.Toggle, EventType.OnClick, function()
                local bSelected = UIHelper.GetSelected(toggleScript.Toggle)
                if bSelected then
                    -- 记录自己的序号，用于后续判定是否需要在被取消勾选时删除按钮
                    self.nCurSelectTogIndex = nIndex

                    local fnOnMorePopClose = function()
                        -- 展开的子菜单被关闭时，取消自己的勾选状态
                        UIHelper.SetSelected(toggleScript.Toggle, false)
                    end
                    -- 移除现有的三级菜单
                    if self.nCurSelectTogIndex <= 6 or self.dwTargetNpcId == GetClientPlayer().dwID then
                        --原来没准备多一级菜单的判断，这里6个是指二级菜单的moreBtn数量
                        TipsHelper.DeleteHoverTips(PREFAB_ID.WidgetInteractionMorePop)
                    end
                    -- 创建自己的三级菜单
                    -- 子菜单的上层节点默认是调用时传入的指定节点，未若指定，则使用当前层。这样可实现后续更深层的子菜单也以第一层节点为父节点
                    -- 记录了一个中间的位置，中间节点后面节点的三级菜单以中间节点位置为准
                    local parent = toggleScript._rootNode
                    if idx >= math.ceil(#tbShowMenuConfig / 2) then
                        parent = morePopParent
                    end
                    local tips, tipsScriptView = TipsHelper.ShowNodeHoverTipsInDir(PREFAB_ID.WidgetInteractionMorePop, parent, TipsLayoutDir.BOTTOM_LEFT, fnOnMorePopClose)

                    -- 调整tips位置，与右上角对齐
                    local nRootHeight = UIHelper.GetHeight(parent)
                    tips:SetOffset(0, -nRootHeight)
                    tips:ShowNodeTips(parent)
                    -- 添加按钮
                    if #tbMenuConfig.tbSubMenus >= 6 then
                        self:CreateMenus(tbMenuConfig.tbSubMenus, tipsScriptView.ScrollviewMore, parent)
                        UIHelper.AddPrefab(PREFAB_ID.WidgetArrow, tipsScriptView.WidgetArrow)
                        UIHelper.SetVisible(tipsScriptView.ScrollviewMore, true)
                    else
                        self:CreateMenus(tbMenuConfig.tbSubMenus, tipsScriptView.LayoutMore, parent)
                        UIHelper.SetVisible(tipsScriptView.ScrollviewMore, false)
                    end
                    -- 调整背景色高度
                    local nWidgetHeight = UIHelper.GetHeight(tipsScriptView.ScrollviewMore)
                    UIHelper.SetHeight(tipsScriptView.ImgPopBg, nWidgetHeight)
                    UIHelper.ScrollViewDoLayoutAndToTop(tipsScriptView.ScrollviewMore)
                    UIHelper.LayoutDoLayout(tipsScriptView.LayoutMore)
                    UIHelper.SetTouchDownHideTips(tipsScriptView.ScrollviewMore, false)
                    FellowshipData.nVisiblePlayerPop = 2
                elseif self.nCurSelectTogIndex == nIndex then
                    -- 当自己被取消勾选时，移除自己的按钮
                    TipsHelper.DeleteHoverTips(PREFAB_ID.WidgetInteractionMorePop)
                end
            end)
        end
    end

    UIHelper.LayoutDoLayout(layoutParent)
end

function UINpcPop:CreateTeamMarkMenu(tbMenuConfig, layoutParent)
    local toggleScript = UIHelper.AddPrefab(PREFAB_ID.WidgetInteractionMoreTog, layoutParent)
    UIHelper.SetString(toggleScript.LableMpore, tbMenuConfig.szName)
    UIHelper.SetSelected(toggleScript.Toggle, false)
    UIHelper.ToggleGroupAddToggle(self.TogGroupMenu, toggleScript.Toggle)

    toggleScript.Toggle:setTouchDownHideTips(false)
    UIHelper.BindUIEvent(toggleScript.Toggle, EventType.OnSelectChanged, function(_, bSelected)
        if bSelected then
            local fnTipsClose = function()
                UIHelper.SetSelected(toggleScript.Toggle, false)
            end
            TipsHelper.DeleteHoverTips(PREFAB_ID.WidgetInteractionMorePop)
            local tips, tipsScriptView = TipsHelper.ShowNodeHoverTipsInDir(PREFAB_ID.WidgetTipTargetgetMark, toggleScript._rootNode, TipsLayoutDir.BOTTOM_LEFT, tbMenuConfig.dwMemberID, fnTipsClose)

            local _, nHeight = UIHelper.GetContentSize(tipsScriptView._rootNode)
            local _, _, nRootYMin = UIHelper.GetNodeEdgeXY(self.LayoutPlayer)
            local _, _, nToggleYMin = UIHelper.GetNodeEdgeXY(toggleScript._rootNode)
            tips:SetOffset(0, -(nHeight - (nToggleYMin - nRootYMin)))
            tips:ShowNodeTips(toggleScript._rootNode)
        else
            TipsHelper.DeleteHoverTips(PREFAB_ID.WidgetTipTargetgetMark)
        end
    end)
end

function UINpcPop:ShowTop(bVisible)
    UIHelper.SetVisible(self.WidgetTop, bVisible)
    UIHelper.LayoutDoLayout(self.LayoutPlayer)
end

function UINpcPop:ShowTopSimple(bVisible, szName)
    UIHelper.SetString(self.LableNameSimple, szName or "", 12)
    UIHelper.SetVisible(self.WidgetTopSimple, bVisible)
    UIHelper.LayoutDoLayout(self.LayoutPlayer)

    UIHelper.BindUIEvent(self.BtnSendNameSimple, EventType.OnClick, function()
        ChatHelper.SendPlayerToChat(szName)
    end)
end

function UINpcPop:AdjustPos()
    --Timer.Add(self, 0.3, function()
    local nWorldPosX = UIHelper.GetWorldPositionX(self.WidgetPraiseStatus)
    local nWidth = UIHelper.GetWidth(self.WidgetPraiseStatus)
    local nPos = nWorldPosX + nWidth / 2
    local nScreenWidth = UIHelper.GetDesignResolutionSize().width

    if nPos > nScreenWidth then
        local nDelta = nPos - nScreenWidth - 10
        LOG.INFO("QH, nDelta = " .. nDelta)
        UIHelper.SetPositionX(self._rootNode, UIHelper.GetPositionX(self._rootNode) - nDelta)
    end
    --end)
end

return UINpcPop
