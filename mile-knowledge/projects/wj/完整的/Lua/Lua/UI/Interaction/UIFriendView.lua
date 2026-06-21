-- ---------------------------------------------------------------------------------
-- Author: Unknown
-- Name: UIFriendView
-- Date: 2022-11-21 21:07:59
-- Desc: ?
-- ---------------------------------------------------------------------------------

local UIFriendView = class("UIFriendView")

local m_bGraduate = false
local tFilter2Force = {
    -1,
    FORCE_TYPE.JIANG_HU,
    FORCE_TYPE.SHAO_LIN,
    FORCE_TYPE.WAN_HUA,
    FORCE_TYPE.TIAN_CE,
    FORCE_TYPE.CHUN_YANG,
    FORCE_TYPE.QI_XIU,
    FORCE_TYPE.WU_DU,
    FORCE_TYPE.TANG_MEN,
    FORCE_TYPE.CANG_JIAN,
    FORCE_TYPE.GAI_BANG,
    FORCE_TYPE.MING_JIAO,
    FORCE_TYPE.CANG_YUN,
    FORCE_TYPE.CHANG_GE,
    FORCE_TYPE.BA_DAO,
    FORCE_TYPE.PENG_LAI,
    FORCE_TYPE.LING_XUE,
    FORCE_TYPE.YAN_TIAN,
    FORCE_TYPE.YAO_ZONG,
    FORCE_TYPE.DAO_ZONG,
    FORCE_TYPE.WAN_LING,
    FORCE_TYPE.DUAN_SHI,
}

local tContactsText = {
    "最近", "好友", "劲敌", "侠缘", "账号好友", "附近"
}

local tApprenticeText = {
    "师门", "徒弟"
}

local RECENT_CONTACT_MAX_NUM = 300

function UIFriendView:OnEnter(nIndex, ...)
    nIndex = nIndex or 1
    self.tbArgs = {...}
    if not self.bInit then
        self.nType = nIndex

        self:RegEvent()
        self:BindUIEvent()
        self:SetupFiterFunction()
        self.bInit = true
    end
    self.tFriendGroupSelected = {}
    self.tbTwoWayFriend = {}
    self:ResetSelectedGroup()

    self:InitUIPage()

    self:ApplyFellowshipInfo()

    self:EnableEditorMode(false)
    self:UpdateInfo()
end

function UIFriendView:OnExit()
    self.bInit = false
    self:UnRegEvent()
    self:UnInitScrollList()
    Timer.DelAllTimer(self)
    -- 红点反注册
    local imgRedpoint = self.tbToggleTab[1]:getChildByName("imgRedpoint")
    RedpointMgr.UnRegisterRedpoint(imgRedpoint)
end

function UIFriendView:TryBackGroundTouchClose()
    UIHelper.RemoveAllChildren(self.WidgetPlayerPop)

    if TipsHelper.IsHoverTipsExist(PREFAB_ID.WidgetPlayerPop) then
        TipsHelper.DeleteHoverTips(PREFAB_ID.WidgetPlayerPop)
        return false
    end

    return true
end

function UIFriendView:BindUIEvent()
    for i, ToggleTab in ipairs(self.tbToggleTab) do
        UIHelper.BindUIEvent(ToggleTab, EventType.OnSelectChanged, function (_, bSelected)
            if bSelected then
                local callbackFun = function()
                    if ChatRecentMgr.GetRecentLockState() then
                        return
                    end
                    UIHelper.SetSelected(self.tbToggleTab[1], true)
                end
                if i == 1 and self.nType == 2 and ChatRecentMgr.Check_WhisperIsLocked(true, callbackFun) then
                    Timer.AddFrame(self, 1, function ()
                        UIHelper.SetSelected(self.tbToggleTab[2], true)
                        ChatRecentMgr.SetCurContactsTab(2)
                    end)
                    return
                end
                self:EnableEditorMode(false)
                self:ResetSelectedGroup()
                self.nSelectedTab = i
                self:UpdateInfo()
            end
        end)
    end

    if self.nType == FellowshipData.tbRelationShowType.nContacts then
        -- 好友排名
        UIHelper.BindUIEvent(self.BtnRank, EventType.OnClick, function ()
            -- UIMgr.Close(VIEW_ID.PanelChatSocial)
            UIMgr.Open(VIEW_ID.PanelFengYunLu, FengYunLuCategory.Friend, 1)
        end)

        -- 编辑分组
        UIHelper.BindUIEvent(self.BtnEditGroup, EventType.OnClick, function ()
            self:EnableEditorMode(true)
            self:UpdateFellowshipList()
        end)

        -- 增加分组
        UIHelper.BindUIEvent(self.BtnAddGroup, EventType.OnClick, function ()
            local editBox = UIMgr.Open(VIEW_ID.PanelPromptPop, g_tStrings.STR_FRIEND_DEFAULT_FRIEND_GROUP_NAME, g_tStrings.STR_SET_FRIEND_GROUP_NAME_TIP_CONTENT, function (szText)
                if szText == "" then
                    TipsHelper.ShowNormalTip(g_tStrings.STR_MSG_GROUP_NAME_EMPTY)
                    return
                end
                if not FellowshipData.CheckGroupName(UIHelper.UTF8ToGBK(szText)) then
                    TipsHelper.ShowNormalTip(g_tStrings.STR_MSG_GROUP_EXIST)
                    return
                end

                local nResultCode = FellowshipData.AddFellowshipGroup(UIHelper.UTF8ToGBK(szText))
                if nResultCode ~= PLAYER_FELLOWSHIP_RESPOND.ADD_GROUP_SUCCESS then
                    Global.OnFellowshipMessage(nResultCode)
                end
            end)
            editBox:SetTitle(g_tStrings.STR_FRIEND_ADD_G)
            editBox:SetMaxLength(15)
        end)

        -- 退出编辑
        UIHelper.BindUIEvent(self.BtnExitEdit, EventType.OnClick, function ()
            self:EnableEditorMode(false)
            self:UpdateFellowshipList()
        end)

        -- 点击头像
        UIHelper.BindUIEvent(self.BtnPlayer, EventType.OnClick, function ()
            local tbRoleEntryInfo = FellowshipData.GetRoleEntryInfo(UI_GetClientPlayerGlobalID())
            local editBox = UIMgr.Open(VIEW_ID.PanelPromptPop, UIHelper.GBKToUTF8(tbRoleEntryInfo.szSignature), g_tStrings.STR_SET_SIGNATURE_TIP_CONTENT, function (szText)
                FellowshipData.SetSignature(UIHelper.UTF8ToGBK(szText))
            end)

            editBox:SetTitle(g_tStrings.STR_SIGNATURE_DEFAULT)
            editBox:SetMaxLength(31)
        end)

        -- 添加好友
        UIHelper.BindUIEvent(self.BtnAdd, EventType.OnClick, function ()
            if not UIMgr.GetView(VIEW_ID.PanelFriendRecommendPop) then
                UIMgr.Open(VIEW_ID.PanelFriendRecommendPop)
            end
        end)

        UIHelper.BindUIEvent(self.BtnFilter, EventType.OnClick, function ()
            TipsHelper.ShowNodeHoverTipsInDir(PREFAB_ID.WidgetFiltrateTip, self.BtnFilter, TipsLayoutDir.BOTTOM_CENTER, FilterDef.Friend)
        end)

        -- 玩家昵称过滤
        UIHelper.RegisterEditBoxChanged(self.EditFilter, function()
            local szText = UIHelper.GetString(self.EditFilter)
            self.tbFilter.szNameContain = nil
            if szText ~= "" then
                self.tbFilter.szNameContain = UIHelper.UTF8ToGBK(szText)
            end
            self:UpdateFellowshipList()
        end)

        --  编辑个性签名
        UIHelper.BindUIEvent(self.BtnSignature, EventType.OnClick, function ()
            local tbSelfFellowshipCard = FellowshipData.GetRoleEntryInfo(UI_GetClientPlayerGlobalID())
            local editBox = UIMgr.Open(VIEW_ID.PanelPromptPop, UIHelper.GBKToUTF8(tbSelfFellowshipCard.szSignature), g_tStrings.STR_SET_SIGNATURE_TIP_CONTENT, function (szText)
                FellowshipData.SetSignature(UIHelper.UTF8ToGBK(szText))
                Timer.Add(self, 1, function ()
                    FellowshipData.ApplyRoleEntryInfo({UI_GetClientPlayerGlobalID()})
                end)
            end)

            editBox:SetTitle(g_tStrings.STR_SIGNATURE_DEFAULT)
            editBox:SetMaxLength(31)
        end)

        -- 搜索侠客
        UIHelper.RegisterEditBoxChanged(self.EditBoxSetting_NPC, function()
            self:UpdateFellowshipList()
        end)

    elseif self.nType == FellowshipData.tbRelationShowType.nApprentice then

        --师徒转换
        UIHelper.BindUIEvent(self.BtnCut, EventType.OnClick, function ()
            if self.bCanBeDirectApprentice and g_pClientPlayer.nLevel < g_pClientPlayer.nMaxLevel then
                TipsHelper.ShowNormalTip(g_tStrings.MENTOR_MSG.ON_APPLY_TO_MASTER)
                return
            end
            if not UIMgr.GetView(VIEW_ID.PanelInteractionChangePop) then
                UIMgr.Open(VIEW_ID.PanelInteractionChangePop, self.bAccountDirectMentor, self.bFreeToDirectApprentice)
            end
        end)

        --师徒规则
        UIHelper.BindUIEvent(self.BtnHelp, EventType.OnClick, function ()
            if not UIMgr.GetView(VIEW_ID.PanelCurrentStatePop) then
                local nCanFindDirectMasterNum = FellowshipData.GetFindDirectMasterData(self.bAccountDirectMentor, self.tbMyDirectMaster or {})
                local nCanFindDirectAppNum = FellowshipData.GetFindDirectApprenticeData(self.bAccountDirectMentor, self.tbMyDirectApprentice or {})
                local nCanFindMasterNum = FellowshipData.GetFindMasterData(self.tbMyDirectApprentice or {}, self.tbMyApprentice or {}, self.tbMyMaster or {}, m_bGraduate)
                local nCanFindAppNum = FellowshipData.GetFindApprenticeData(self.tbMyMaster or {}, self.tbMyApprentice or {})
                UIMgr.Open(VIEW_ID.PanelCurrentStatePop, self.bCanBeDirectMentor, nCanFindDirectMasterNum, nCanFindDirectAppNum, nCanFindMasterNum, nCanFindAppNum)
            end
        end)

        --前往拜师收徒
        UIHelper.BindUIEvent(self.BtnTeach, EventType.OnClick, function ()
            if not UIMgr.GetView(VIEW_ID.PanelApprenticeNew) then
                UIMgr.Open(VIEW_ID.PanelApprenticeNew)
            end
        end)

        -- --师徒奖励
        -- UIHelper.BindUIEvent(self.BtnRward, EventType.OnClick, function ()
        --     if not UIMgr.GetView(VIEW_ID.PanelRuleRewardPop) then
        --         UIMgr.Open(VIEW_ID.PanelRuleRewardPop)
        --     end
        -- end)

    end

    UIHelper.BindUIEvent(self.TogTitle, EventType.OnSelectChanged, function (_, bSelected)
        self.bFriendSelected = bSelected
        self:UpdateFellowshipList()
    end)
end

function UIFriendView:RegEvent()

    if self.nType == FellowshipData.tbRelationShowType.nContacts then

        Event.Reg(self, "PLAYER_FELLOWSHIP_UPDATE", function()
            self:UpdateFellowshipList()
        end)

        Event.Reg(self, "PLAYER_FELLOWSHIP_LOGIN", function()
            self:UpdateFellowshipList()
        end)

        Event.Reg(self, "PLAYER_FELLOWSHIP_CHANGE", function()
            self:UpdateFellowshipList()
        end)

        Event.Reg(self, "PLAYER_ADD_FELLOWSHIP_ATTRACTION", function ()
            self:UpdateFellowshipList()
        end)

        Event.Reg(self, "APPLY_ROLE_ONLINE_FLAG_RESPOND", function ()
            self:UpdateFellowshipList()
        end)

        Event.Reg(self, "PLAYER_FEUD_UPDATE", function ()
            self:UpdateFellowshipList()
        end)

        Event.Reg(self,"FELLOWSHIP_ROLE_ENTRY_UPDATE",function (szGlobalID)
            if szGlobalID == UI_GetClientPlayerGlobalID() then
                self.tbRoleEntryInfo = FellowshipData.GetRoleEntryInfo(UI_GetClientPlayerGlobalID())
                self:UpdateSignature()
            else
                self:UpdateFellowshipList()
            end
        end)

        Event.Reg(self, EventType.OnFilter, function(szKey, tbSelected)
            self.tbFilter = {tForceID = nil, bOnline = nil, bIsTwoWayFriend = nil, szNameContain = nil}
            if szKey == FilterDef.Friend.Key then
                if tbSelected[1][1] ~= 1 then
                    self.tbFilter.bOnline = tbSelected[1][1] == 2 and true or false
                end
                self.tbFilter.bIsTwoWayFriend = tbSelected[2][1]
                self.tbFilter.dwForceID = tFilter2Force[tbSelected[3][1]]

                self:ResetSelectedGroup()
                self:UpdateFellowshipList()
            end
        end)

        Event.Reg(self, "SYS_MSG", function()
            if arg0 == "UI_OME_FELLOWSHIP_RESPOND" and arg1 == PLAYER_FELLOWSHIP_RESPOND.SET_FRIEND_REMARK_SUCCESS or
            arg0 == "UI_OME_FELLOWSHIP_RESPOND" and arg1 == PLAYER_FELLOWSHIP_RESPOND.ADD_GROUP_SUCCESS or
            arg0 == "UI_OME_FELLOWSHIP_RESPOND" and arg1 == PLAYER_FELLOWSHIP_RESPOND.RENAME_GROUP_SUCCESS then
                self:UpdateFellowshipList()
            elseif arg0 == "UI_OME_FELLOWSHIP_RESPOND" and arg1 == PLAYER_FELLOWSHIP_RESPOND.SIGNATURE_SUCCESS then
                self:UpdateSignature()
            end
        end)

        Event.Reg(self, "SET_MINI_AVATAR", function (dwID)
            self:UpdateAvatar()
        end)

        Event.Reg(self, "ON_UPDATE_FELLOWSHIP_NOTIFY", function (type, szGlobalID)
            -- if type == FELLOWSHIP_OPERATE_TYPE.DEL_FRIEND or type == FELLOWSHIP_OPERATE_TYPE.DEL_BLACK then
            -- elseif type == FELLOWSHIP_OPERATE_TYPE.DEL_FOE or type == FELLOWSHIP_OPERATE_TYPE.DEL_FEUD then
            -- end
            self:UpdateFellowshipList()
        end)

        Event.Reg(self, EventType.OnReceiveChat, function(tbData)
            if tbData and tbData.nChannel == PLAYER_TALK_CHANNEL.WHISPER and self.nSelectedTab == self.tbTab.RECENT then
                self:UpdateFellowshipList()
            end
        end)

    elseif self.nType == FellowshipData.tbRelationShowType.nApprentice then

        --获得师父列表
        Event.Reg(self, "ON_GET_MENTOR_LIST", function (dwDstPlayerID, MentorList, bGradute)
            if dwDstPlayerID == g_pClientPlayer.dwID then
                self.tbMyMaster = MentorList or {}
                m_bGraduate = false
                if not bGradute and #self.tbMyMaster == 0 then
                    m_bGraduate = true
                    self.tbMyMaster = {}
                else
                    table.sort(self.tbMyMaster, function (a, b) return a.nCreateTime < b.nCreateTime end)
                end
            end
            self.tbMyMaster = FellowshipData.GetMyMasterList(self.tbMyMaster or {}, false)

            self:UpdateFellowshipList()
            self:UpdateLableHelp()
        end)

        --获得亲传师父列表
        Event.Reg(self, "ON_GET_DIRECT_MENTOR_LIST", function (dwPlayerID,aMyDirectMaster)
            if g_pClientPlayer.dwID == dwPlayerID then
                self.tbMyDirectMaster = aMyDirectMaster
                table.sort(self.tbMyDirectMaster, function (a, b) return a.nCreateTime < b.nCreateTime end)
            end
            self.tbMyDirectMaster = FellowshipData.GetMyMasterList(self.tbMyDirectMaster or {}, true)

            self:UpdateFellowshipList()
            self:UpdateLableHelp()
        end)

        --获得徒弟列表
        Event.Reg(self, "ON_GET_APPRENTICE_LIST", function (dwPlayerID,aMyApprentice)
            if g_pClientPlayer.dwID == dwPlayerID then --你的徒弟的列表
                self.tbMyApprentice = aMyApprentice or {}
                table.sort(self.tbMyApprentice, function (a, b) return a.nCreateTime < b.nCreateTime end)
                self.tbMyApprentice = FellowshipData.GetMyApprenticeList(self.tbMyApprentice,false)
            else -- 你的同门的列表
                self.tbMyDirectMaster = FellowshipData.GetMasterApprenticeList(self.tbMyDirectMaster or {}, dwPlayerID,aMyApprentice,false)
                self.tbMyMaster = FellowshipData.GetMasterApprenticeList(self.tbMyMaster or {}, dwPlayerID,aMyApprentice,false)
            end

            self:UpdateFellowshipList()
            self:UpdateLableHelp()
        end)

        --获得亲传徒弟列表
        Event.Reg(self, "ON_GET_DIRECT_APPRENTICE_LIST", function (dwPlayerID,aMyDirectApprentice)
            if g_pClientPlayer.dwID == dwPlayerID then
                self.tbMyDirectApprentice = aMyDirectApprentice or {}
                table.sort(self.tbMyDirectApprentice, function (a, b) return a.nCreateTime < b.nCreateTime end)
                FellowshipData.GetMyApprenticeList(self.tbMyDirectApprentice,true)
            else
                self.tbMyDirectMaster = FellowshipData.GetMasterApprenticeList(self.tbMyDirectMaster or {}, dwPlayerID,aMyDirectApprentice,true)
                self.tbMyMaster = FellowshipData.GetMasterApprenticeList(self.tbMyMaster or {}, dwPlayerID,aMyDirectApprentice,true)
            end

            self:UpdateFellowshipList()
            self:UpdateLableHelp()
        end)

        --取角色亲传师徒权限
        Event.Reg(self,"ON_GET_DIRECT_MENTOR_RIGHT",function (bCanBeDirectMentor, bCanBeDirectApprentice)
            self.bCanBeDirectMentor = bCanBeDirectMentor
            self.bCanBeDirectApprentice = bCanBeDirectApprentice
        end)

        --取账号传师徒权限
        Event.Reg(self,"ON_IS_ACCOUNT_DIRECT_APPRENTICE",function (bApprentice)
            self.bAccountDirectMentor = not bApprentice
            if self.bAccountDirectMentor then
                UIHelper.SetString(self.LableCut,"当前账号身份：亲传师父")
            else
                UIHelper.SetString(self.LableCut,"当前账号身份：亲传徒弟")
            end
            RemoteCallToServer("OnIsFreeToDirectApprentice")
            self:UpdateLableHelp()
        end)

        Event.Reg(self, "TRANSFORM_TO_MASTER",function () --重置为亲传师傅状态成功后
            FellowshipData.ApplyMasterInfo()
        end)
        Event.Reg(self, "TRANSFORM_TO_APPRENTICE",function () --免费重置为亲传徒弟状态成功后
            FellowshipData.ApplyMasterInfo()
        end)
        Event.Reg(self, "ON_COIN_BUY_RESPOND", function (arg0)--重置亲传徒弟状态是否成功
            FellowshipData.ApplyMasterInfo()
        end)

        Event.Reg(self, "NEED_REQUAIRE_MENTOR_LIST", function ()
            RemoteCallToServer("OnGetMentorListRequest", g_pClientPlayer.dwID)
            RemoteCallToServer("OnGetApprenticeListRequest", g_pClientPlayer.dwID)
        end)

        Event.Reg(self, "NEED_REQUAIRE_APPRENTICE_LIST", function ()
            RemoteCallToServer("OnGetMentorListRequest", g_pClientPlayer.dwID)
            RemoteCallToServer("OnGetApprenticeListRequest", g_pClientPlayer.dwID)
        end)

        Event.Reg(self, "NEED_REQUAIRE_DIRECT_MENTOR_LIST", function ()
            RemoteCallToServer("OnGetDirectMentorListRequest", g_pClientPlayer.dwID)
            RemoteCallToServer("OnGetDirApprenticeListRequest", g_pClientPlayer.dwID)
        end)

        Event.Reg(self, "NEED_REQUAIRE_DIRECT_APPRENTICE_LIST", function ()
            RemoteCallToServer("OnGetDirectMentorListRequest", g_pClientPlayer.dwID)
            RemoteCallToServer("OnGetDirApprenticeListRequest", g_pClientPlayer.dwID)
        end)

        Event.Reg(self, "ON_BREAK_MENTOR_RESULT", function (arg0)
            if arg0.nState == 0 then
                RemoteCallToServer("OnGetMentorListRequest", g_pClientPlayer.dwID)
                RemoteCallToServer("OnGetApprenticeListRequest", g_pClientPlayer.dwID)
            end
        end)

        Event.Reg(self, "ON_BREAK_APPRENTICE_RESULT", function (arg0) --解除徒弟结果
            if arg0.nState == 0 then
                RemoteCallToServer("OnGetMentorListRequest", g_pClientPlayer.dwID)
        		RemoteCallToServer("OnGetApprenticeListRequest", g_pClientPlayer.dwID)
            end
        end)

        Event.Reg(self, "ON_CANCEL_BREAK_APPRENTICE_RESULT", function (arg0) --取消解除徒弟结果
            if arg0.nState == 0 then
                RemoteCallToServer("OnGetMentorListRequest", g_pClientPlayer.dwID)
        		RemoteCallToServer("OnGetApprenticeListRequest", g_pClientPlayer.dwID)
            end
        end)

        Event.Reg(self, "ON_CANCEL_BREAK_MENTOR_RESULT", function (arg0)
            if arg0.nState == 0 then
                RemoteCallToServer("OnGetMentorListRequest", g_pClientPlayer.dwID)
                RemoteCallToServer("OnGetApprenticeListRequest", g_pClientPlayer.dwID)
            end
        end)

        Event.Reg(self, "UPDATE_MENTOR_DATA", function (arg0)
            RemoteCallToServer("OnGetMentorListRequest", arg0)
        end)

        Event.Reg(self, "UPDATE_APPRENTICE_DATA", function (arg0)
            RemoteCallToServer("OnGetApprenticeListRequest", arg0)
        end)

        Event.Reg(self, "ON_IS_FREE_TO_DIRECT_APPRENTICE",function (bFree)  --能否免费转换为亲传徒弟
            self.bFreeToDirectApprentice = bFree
        end)

    elseif self.nType == FellowshipData.tbRelationShowType.nTong then
        Event.Reg(self, "UPDATE_TONG_ROSTER_FINISH", function ()
            self:UpdateFellowshipList()
        end)
    end

    Event.Reg(self, EventType.OnUpdateFellowShip, function ()
        self:UpdateFellowshipList()
    end)

    Event.Reg(self, EventType.HideAllHoverTips, function()
        if FellowshipData.nVisiblePlayerPop and FellowshipData.nVisiblePlayerPop == 1 then
            UIHelper.RemoveAllChildren(self.WidgetPlayerPop)
            self:ClearSelectedState()
        else
            FellowshipData.nVisiblePlayerPop = FellowshipData.nVisiblePlayerPop - 1
        end
    end)

    Event.Reg(self, EventType.DeletePlayerPop, function()
        UIHelper.RemoveAllChildren(self.WidgetPlayerPop)
    end)

    Event.Reg(self, EventType.OnUIScrollListScroll, function(UIScrollList)
        if UIScrollList == self.tScrollList then
            UIHelper.RemoveAllChildren(self.WidgetPlayerPop)
            self:ClearSelectedState()
        end
    end)

    Event.Reg(self, EventType.OnWindowsSizeChanged, function()
        Timer.AddFrame(self, 1, function ()
            UIHelper.LayoutDoLayout(self.LayOutChatContent)
        end)
    end)
end

function UIFriendView:UnRegEvent()
    --Event.UnReg(self, EventType.XXX)
end






-- ----------------------------------------------------------
-- Please write your own code below  ↓↓↓
-- ----------------------------------------------------------

function UIFriendView:InitUIPage()
    if self.nType == FellowshipData.tbRelationShowType.nContacts then
        self:InitContactsUIPage()
    elseif self.nType == FellowshipData.tbRelationShowType.nApprentice then
        self:InitApprenticeUIPage()
    elseif self.nType == FellowshipData.tbRelationShowType.nTong then
        self:InitTongUIPage()
    end
    UIHelper.ScrollViewDoLayoutAndToTop(self.ScrollViewTab)
end

function UIFriendView:InitContactsUIPage()
    self.tbTab = {
        RECENT = 1,
        FRIEND = 2,
        FOE    = 3,
        NPC    = 4,
        --ACCOUNT = 5,   -- 账号好友屏蔽，等端游兼容
        AROUND = 6,
    }
    self.bInEditor = false
    self.tbFilter = {tForceID = nil, bOnline = nil, bIsTwoWayFriend = nil, szNameContain = nil}


    for i, _ in ipairs(self.tbWidgetTog) do
        UIHelper.SetString(self.tbLabelUsual[i], tContactsText[i])
        UIHelper.SetString(self.tbLabelUp[i], tContactsText[i])
        UIHelper.SetToggleGroupIndex(self.tbToggleTab[i], ToggleGroupIndex.Contacts)
        UIHelper.SetSelected(self.tbToggleTab[self.nSelectedTab], false)
    end

    local nTab = ChatRecentMgr.GetCurContactsTab()
    self.nSelectedTab = self.tbArgs and self.tbArgs[1] or nTab or self.tbTab.FRIEND
    UIHelper.SetSelected(self.tbToggleTab[self.nSelectedTab], true)
    self.WidgetEmptyState = self.WidgetEmptyState1

    --先屏蔽最近
    --UIHelper.SetVisible(self.tbWidgetTog[1], false)
    --先屏蔽账号好友 等端游兼容
    UIHelper.SetVisible(self.tbWidgetTog[5], false)
    UIHelper.SetVisible(self.tbWidgetTog[self.tbTab.NPC], ChatAINpcMgr.IsOpen()) -- AI聊天是否开放

    local bTreasureBF = BattleFieldData.IsInTreasureBattleFieldMap()
    local togAround = self.tbToggleTab[self.tbTab.AROUND]
    UIHelper.SetCanSelect(togAround, not bTreasureBF, "绝境战场不支持查看附近的玩家列表", true)
end

function UIFriendView:InitApprenticeUIPage()
    self.tbTab = {
        nMaster = 1,
        nApprentice = 2
    }
    for i, _ in ipairs(self.tbWidgetTog) do
        UIHelper.SetVisible(self.tbWidgetTog[i], tApprenticeText[i] and true or false)
        UIHelper.SetString(self.tbLabelUsual[i], tApprenticeText[i])
        UIHelper.SetString(self.tbLabelUp[i], tApprenticeText[i])
        UIHelper.SetToggleGroupIndex(self.tbToggleTab[i], ToggleGroupIndex.Apprentice)
        UIHelper.SetSelected(self.tbToggleTab[self.nSelectedTab], false)
    end
    self.nSelectedTab = self.tbTab.nMaster
    UIHelper.SetSelected(self.tbToggleTab[self.nSelectedTab], true)
    self.WidgetEmptyState = self.WidgetEmptyState1

    UIHelper.SetVisible(self.LayOutChatContent, false)
    UIHelper.SetVisible(self.WidgetEmptyState, true)
    if CrossMgr.IsCrossing() then
        UIHelper.SetString(self.LableEmptyGuide, g_tStrings.STR_REMOTE_NOT_TIP1)
    else
        UIHelper.SetString(self.LableEmptyGuide, "师徒信息加载中")

        self.bLayOutChatContent = true
        Timer.Add(self, 0.5, function ()
            self.bLayOutChatContent = false
            self:SetEmptyState()
            UIHelper.SetVisible(self.LayOutChatContent, true)
        end)
    end
end

function UIFriendView:InitTongUIPage()
    UIHelper.SetVisible(self.ScrollViewTab, false)
    UIHelper.SetVisible(self.LayOutChatContent, false)
    UIHelper.SetVisible(self.ImgBg1, false)
    UIHelper.SetVisible(self.WidgetSocietyList, true)

    if CrossMgr.IsCrossing() then
        UIHelper.SetVisible(self.BtnJoinSociety, false)
    end

    -- self.WidgetScript = UIHelper.AddPrefab(PREFAB_ID.WidgetSocietyList, self.WidgetAnchorLeft)
    -- UIHelper.LayoutDoLayout(self.WidgetAnchorLeft)
    ---帮会页的脚本
    ---@type UISocietyList
    self.WidgetScript = UIHelper.GetBindScript(self.WidgetSocietyList)
    self.WidgetEmptyState = self.WidgetEmptyState2
end

function UIFriendView:UpdateSelectedTabBtn()
    if self.nType ~= FellowshipData.tbRelationShowType.nTong then
        local bIsContacts = self.nType == FellowshipData.tbRelationShowType.nContacts
        local bIsContacts_Friend = bIsContacts and self.nSelectedTab == self.tbTab.FRIEND
        local bIsContacts_NPC = bIsContacts and self.nSelectedTab == self.tbTab.NPC
        local bIsContacts_Recent = bIsContacts and self.nSelectedTab == self.tbTab.RECENT

        local bIsApprentice = self.nType == FellowshipData.tbRelationShowType.nApprentice

        -- 顶部显示
        local bShowSetting = bIsContacts_Friend or bIsContacts_NPC
        UIHelper.SetVisible(self.WidgetSetting, bShowSetting)
        UIHelper.SetVisible(self.WidgetSetting_Friend, bIsContacts_Friend)
        UIHelper.SetVisible(self.WidgetSetting_NPC, bIsContacts_NPC)
        UIHelper.SetVisible(self.EditBoxSetting_NPC, bIsContacts_NPC)

        UIHelper.SetVisible(self.WidgetPlayerMassage, bIsContacts_Friend)

        UIHelper.SetVisible(self.WidgetAnchorMessage, bIsApprentice)
        UIHelper.LayoutDoLayout(self.LayOutChatContent)
        UIHelper.SetVisible(self.LayoutBtnLeftDownTeach, bIsApprentice)
        UIHelper.SetVisible(self.LayoutBtnLeftDownFirend, bIsContacts_Friend)
        UIHelper.SetVisible(self.LayoutContent_FriendList, false)
        UIHelper.SetVisible(self.LayoutContent_Apprentice, false)
        UIHelper.SetVisible(self.LayoutContent_Normal, false)
        UIHelper.SetVisible(self.LayoutContent_NpcList, false)
        UIHelper.SetVisible(self.WidgetRecentContacts, bIsContacts_Recent)

        if bIsContacts_Friend then
            self.LayoutContent = self.LayoutContent_FriendList
        elseif bIsApprentice then
            self.LayoutContent = self.LayoutContent_Apprentice
        elseif bIsContacts_Recent then
            self.LayoutContent = self.LayoutRecentContacts
        elseif bIsContacts_NPC then
            self.LayoutContent = self.LayoutContent_NpcList
        else
            self.LayoutContent = self.LayoutContent_Normal
        end
    else
        self.LayoutContent = self.WidgetScript.LayoutContent_Big
    end

    UIHelper.SetVisible(self.LayoutContent, true)
end

function UIFriendView:ApplyFellowshipInfo()
    if self.nType == FellowshipData.tbRelationShowType.nApprentice then
        FellowshipData.ApplyMasterInfo()
    elseif self.nType == FellowshipData.tbRelationShowType.nTong then
        GetTongClient().ApplyTongRoster()
    end
end

function UIFriendView:ResetSelectedGroup()
    for i = 1, 10 do
        self.tFriendGroupSelected[i] = true
    end
end

function UIFriendView:UpdateInfo()
    self:UpdateMessage()

    self:UpdateSelectedTabBtn()
    self:UpdateFellowshipList()

    -- UIHelper.LayoutDoLayout(self.LayOutChatContent)
    self:UdpateRedPointState()
end

function UIFriendView:UdpateRedPointState()
    local tbChannelList = ChatData.GetUIChannelList()
    local nLen = #tbChannelList
    local nFirstSelectIdx = nil

    local imgRedpoint = self.tbToggleTab[1]:getChildByName("imgRedpoint")
    local labelRedpoint = imgRedpoint and imgRedpoint:getChildByName("LabelRedPoint")
    UIHelper.SetVisible(imgRedpoint, false)
    RedpointMgr.UnRegisterRedpoint(imgRedpoint)

    --local tbOneChannel = tbChannelList[3]
    --if tbOneChannel then
        -- 红点注册
        --local tbRedPoints = tbOneChannel.tbRedPoints
        --if not table.is_empty(tbRedPoints) then
            --RedpointMgr.RegisterRedpoint(imgRedpoint, labelRedpoint, {2, 4})
        --end
    --end
end

function UIFriendView:UpdateMessage()
    if self.nType == FellowshipData.tbRelationShowType.nContacts then
        self:UpdateName()
        self:UpdateAvatar()
        self:UpdateSignature()
    elseif self.nType == FellowshipData.tbRelationShowType.nTong then
        self:UpdateTongInfo()
    end
end

function UIFriendView:UpdateName()
    if self.nSelectedTab == self.tbTab.FRIEND then
        UIHelper.SetString(self.LabelName, UIHelper.GBKToUTF8(PlayerData.GetPlayerName()))
    end
end

function UIFriendView:UpdateAvatar()
    UIHelper.RemoveAllChildren(self.WidgetHead)
    if self.nSelectedTab == self.tbTab.FRIEND then
        self:UpdateMineAvatar()
    end
end

function UIFriendView:UpdateMineAvatar()
    local headscript = UIHelper.AddPrefab(PREFAB_ID.WidgetHead, self.WidgetHead, g_pClientPlayer.dwID)
    if headscript then
        headscript:SetClickCallback(function()
            UIHelper.AddPrefab(PREFAB_ID.WidgetPlayerPop, self.WidgetPlayerPop, UI_GetClientPlayerGlobalID() ,nil,nil,true)
            FellowshipData.nVisiblePlayerPop = 1
            if UIMgr.GetView(VIEW_ID.PanelSystemMenu) then
                UIMgr.Close(VIEW_ID.PanelSystemMenu)
            end
            self:ClearSelectedState()
        end)
        local tbRoleEntryInfo = FellowshipData.GetRoleEntryInfo(UI_GetClientPlayerGlobalID())
        local tData = tbRoleEntryInfo and Table_GetPersonalCardInfo(2, tbRoleEntryInfo.ShowCardDecorationFrameID)
        local szFrame = tData and tData.dwDecorationID ~= 0 and tData.szVKSmallPath or ""
        headscript:SetPersonalFrame(szFrame)
    end
end

function UIFriendView:UpdateSignature()
    self:UpdateMineSignature()
    UIHelper.LayoutDoLayout(self.LayoutSignature)
end

function UIFriendView:UpdateTongInfo()
    if self.WidgetScript then
        UIHelper.SetString(self.WidgetScript.LableHelp, TongData.GetLevel().."级")
        UIHelper.SetString(self.WidgetScript.LableCut, UIHelper.GBKToUTF8(TongData.GetName()))
        local szCampImage = CampData.GetCampImgPath(TongData.GetCamp())
        UIHelper.SetSpriteFrame(self.WidgetScript.ImgCamp, szCampImage)
    end
end

function UIFriendView:UpdateMineSignature()
    UIHelper.SetVisible(self.ImgIconSignature,true)
    local tbSelfFellowshipCard = FellowshipData.GetRoleEntryInfo(UI_GetClientPlayerGlobalID()) or {}
    if tbSelfFellowshipCard.szSignature == "" then
        UIHelper.SetString(self.LabelSignature, g_tStrings.STR_SIGNATURE_DEFAULT)
    else
        UIHelper.SetString(self.LabelSignature, UIHelper.GBKToUTF8(tbSelfFellowshipCard.szSignature), 14)
    end
    if self.tbRoleEntryInfo then
        local tLine = UINameCardTab[self.tbRoleEntryInfo.SkinID]
        if tLine then
            UIHelper.SetTexture(self.ImgNameCard,tLine.szVisitCardPath)
            UIHelper.UpdateMask(self.MaskImgNameCard)
        end
    end
end

function UIFriendView:UpdateLableHelp()
    local tbTitle = {}
    local nCanFindDirectMasterNum = FellowshipData.GetFindDirectMasterData(self.bAccountDirectMentor, self.tbMyDirectMaster or {})
    local nCanFindDirectAppNum = FellowshipData.GetFindDirectApprenticeData(self.bAccountDirectMentor, self.tbMyDirectApprentice or {})
    if self.bCanBeDirectApprentice and self.bAccountDirectMentor then
        table.insert(tbTitle, g_tStrings.MENTOR_FIND_INFO[1])
    elseif self.bCanBeDirectApprentice and not self.bAccountDirectMentor then
        table.insert(tbTitle, g_tStrings.MENTOR_FIND_INFO[2])
    elseif self.bCanBeDirectMentor and nCanFindDirectAppNum ~= 0 then
        table.insert(tbTitle, g_tStrings.MENTOR_FIND_INFO[3])
    elseif self.bCanBeDirectMentor then
        table.insert(tbTitle, g_tStrings.MENTOR_FIND_INFO[4])
    end

    local nCanFindMasterNum = FellowshipData.GetFindMasterData(self.tbMyDirectApprentice or {}, self.tbMyApprentice or {}, self.tbMyMaster or {}, m_bGraduate)
    if nCanFindMasterNum == 0 then
        table.insert(tbTitle, g_tStrings.MENTOR_FIND_INFO[5])
    else
        table.insert(tbTitle, g_tStrings.MENTOR_FIND_INFO[6])
    end

    local nCanFindAppNum = FellowshipData.GetFindApprenticeData(self.tbMyMaster or {}, self.tbMyApprentice or {})
    if nCanFindAppNum == 0 then
        table.insert(tbTitle, g_tStrings.MENTOR_FIND_INFO[7])
    else
        table.insert(tbTitle, g_tStrings.MENTOR_FIND_INFO[8])
    end

    local szHelp = table.concat(tbTitle, ",")

    UIHelper.SetString(self.LableHelp, szHelp)

    UIHelper.LayoutDoLayout(self.LayoutMessage1)
    UIHelper.LayoutDoLayout(self.LayoutMessage2)
    UIHelper.SetVisible(self.ImgTeacher, self.bAccountDirectMentor)
    UIHelper.SetVisible(self.ImgStudent, not self.bAccountDirectMentor)
end

function UIFriendView:InitScrollList()
    self:UnInitScrollList()
    local tbPlayerCellList = self:GetCellType()

	self.tScrollList = UIScrollList.Create({
		listNode = self.LayoutContent,
		fnGetCellType = function(nIndex)
            return tbPlayerCellList[nIndex] and tbPlayerCellList[nIndex].nPrefabID or nil
        end,
		fnUpdateCell = function(cell, nIndex)
            self:UpdateOneCell(cell, nIndex, tbPlayerCellList)
		end,
	})
    --self.tScrollList:SetScrollBarEnabled(true)
end

function UIFriendView:UnInitScrollList()
	if self.tScrollList then
		self.tScrollList:Destroy()
		self.tScrollList = nil
	end
end

function UIFriendView:SetCellTab(tbPlayerCellList, tbPlayerInfo, tbPlayerIDList, id)
    if tbPlayerCellList and tbPlayerInfo then
        table.insert(tbPlayerCellList, tbPlayerInfo)
    end
    if tbPlayerIDList and id then
        table.insert(tbPlayerIDList, id)
    end
end

function UIFriendView:UpdateFellowshipListInfo()
    if self.nType == FellowshipData.tbRelationShowType.nContacts and self.nSelectedTab == self.tbTab.FRIEND and self.bInEditor then
        self:UpdateFellowshipInfoInEditor()
    else
        self:UpdateFellowshipInfo()
    end
    if not self.bLayOutChatContent then
        self:SetEmptyState()
    end
end

function UIFriendView:UpdateFellowshipInfoInEditor()
    local tbPlayerCellList = {}
    local tbGroup = FellowshipData.GetFellowshipGroupInfo() or {}
    for i, tbGroupInfo in ipairs(tbGroup) do
        if tbGroupInfo.id ~= 0 then
            table.insert(tbPlayerCellList, {nPrefabID = PREFAB_ID.WidgetFriendListNew, szTitle = UIHelper.GBKToUTF8(tbGroupInfo.name), bInEditor = true, id = tbGroupInfo.id})
        end
    end
    self.tbPlayerCellList = tbPlayerCellList
end

function UIFriendView:UpdateFellowshipInfo()
    if self.nType == FellowshipData.tbRelationShowType.nContacts then
        self:UpdateFellowshipContantsInfo()
    elseif self.nType == FellowshipData.tbRelationShowType.nApprentice then
        self:UpdateFellowshipApprenticeInfo()
    elseif self.nType == FellowshipData.tbRelationShowType.nTong then
        self:UpdateFellowshipTongInfo()
    end
end

function UIFriendView:UpdateFellowshipContantsInfo()
    local tbPlayerCellList = {}
    local tbPlayerIDList = {}

    if self.nSelectedTab == self.tbTab.FRIEND then
        tbPlayerCellList, tbPlayerIDList = self:UpdateFriendCellList(tbPlayerCellList, tbPlayerIDList)
    elseif self.nSelectedTab == self.tbTab.FOE then
        tbPlayerCellList, tbPlayerIDList = self:UpdateFOECellList(tbPlayerCellList, tbPlayerIDList)
    elseif self.nSelectedTab == self.tbTab.NPC then
        tbPlayerCellList, tbPlayerIDList = self:UpdateNPCCellList(tbPlayerCellList, tbPlayerIDList)
    elseif self.nSelectedTab == self.tbTab.AROUND then
        tbPlayerCellList, tbPlayerIDList = self:UpdateAroundCellList(tbPlayerCellList, tbPlayerIDList)
    elseif self.nSelectedTab == self.tbTab.RECENT then
        if ChatRecentMgr.Check_WhisperIsLocked(true) then
            tbPlayerCellList, tbPlayerIDList = {}, {}
        else
            tbPlayerCellList, tbPlayerIDList = self:UpdateRecentCellList(tbPlayerCellList, tbPlayerIDList)
        end
    end

    if self.nSelectedTab == self.tbTab.FRIEND then
        if FellowshipData.GetEntryInfoCD(self.nSelectedTab) then
            FellowshipData.ApplyRoleEntryInfo(tbPlayerIDList)
            FellowshipData.ApplyRoleOnlineFlag(tbPlayerIDList)
        end
    end

    self.tbPlayerCellList = tbPlayerCellList
end

function UIFriendView:UpdateFellowshipApprenticeInfo()
    local tbPlayerCellList = {}
    local tbPlayerIDList = {}

    if self.nSelectedTab == self.tbTab.nMaster then
        tbPlayerCellList, tbPlayerIDList = self:UpdateMentorCellList(tbPlayerCellList, tbPlayerIDList)
    elseif self.nSelectedTab == self.tbTab.nApprentice then
        tbPlayerCellList, tbPlayerIDList = self:UpdateApprenticeCellList(tbPlayerCellList, tbPlayerIDList)
    end

    self.tbPlayerCellList = tbPlayerCellList
end

function UIFriendView:UpdateFellowshipTongInfo()
    local tbPlayerCellList = {}
    local tbPlayerIDList = {}

    if not CrossMgr.IsCrossing() then
        tbPlayerCellList, tbPlayerIDList = self:UpdateTongCellList(tbPlayerCellList, tbPlayerIDList)
    end

    self.tbPlayerCellList = tbPlayerCellList
end

local fnSortFriend = function (lh, rh)
	local nLh = lh.bOnLine and 2 or (lh.bAppOnline and 1 or 0)
	local nRh = rh.bOnLine and 2 or (rh.bAppOnline and 1 or 0)
	if nLh ~= nRh then
		return nLh > nRh
	end

	if lh.attraction ~= rh.attraction then
		return (lh.attraction > rh.attraction)
	else
		return false
	end
end

function UIFriendView:UpdateFriendCellList(tbPlayerCellList, tbPlayerIDList)
    local tbGroup = FellowshipData.GetFellowshipGroupInfo() or {}

    for nGroupID, tbGroupInfo in ipairs(tbGroup) do
        local tbPlayerInfoList = FellowshipData.GetFellowshipInfoListByGroup(tbGroupInfo.id) or {}
        for i, aInfo in ipairs(tbPlayerInfoList) do
            aInfo.bOnLine, aInfo.bAppOnline = FellowshipData.IsOnline(aInfo.id)
            self.tbTwoWayFriend[aInfo.id] = aInfo.istwoway
        end
        table.sort(tbPlayerInfoList, fnSortFriend)

        if tbGroupInfo.id == 0 then
            local tbPlayerList1, tbPlayerList2 = {}, {}
            for _, tbPlayerInfo in ipairs(tbPlayerInfoList) do
                if FellowshipData.IsRemoteFriend(tbPlayerInfo.id) then
                    table.insert(tbPlayerList2, tbPlayerInfo)
                else
                    table.insert(tbPlayerList1, tbPlayerInfo)
                end
            end
            self:SetCellTab(tbPlayerCellList, {nPrefabID = PREFAB_ID.WidgetFriendListNew, bSelected = self.tFriendGroupSelected[nGroupID], szTitle = UIHelper.GBKToUTF8(tbGroupInfo.name), nGroupID = nGroupID})
            self:SetPlayerInfoCellTab(tbPlayerCellList, tbPlayerIDList, tbPlayerList1, FellowshipData.tbRelationType.nFriend, 0, 0)
            self:SetCellTab(tbPlayerCellList, {nPrefabID = PREFAB_ID.WidgetFriendListNew, bSelected = self.tFriendGroupSelected[nGroupID + 1], szTitle = "跨服好友", nGroupID = nGroupID + 1})
            self:SetPlayerInfoCellTab(tbPlayerCellList, tbPlayerIDList, tbPlayerList2, FellowshipData.tbRelationType.nFriend, 0, 0)
        else
            self:SetCellTab(tbPlayerCellList, {nPrefabID = PREFAB_ID.WidgetFriendListNew, bSelected = self.tFriendGroupSelected[nGroupID + 1], szTitle = UIHelper.GBKToUTF8(tbGroupInfo.name), nGroupID = nGroupID + 1})
            self:SetPlayerInfoCellTab(tbPlayerCellList, tbPlayerIDList, tbPlayerInfoList, FellowshipData.tbRelationType.nFriend, 0, 0)
        end
    end

    self:SetCellTab(tbPlayerCellList, {nPrefabID = PREFAB_ID.WidgetFriendListNew, bSelected = self.tFriendGroupSelected[#tbGroup + 2], szTitle = g_tStrings.STR_FRIEND_BLACK_GROUP_NAME, nGroupID = #tbGroup + 2})
    local tbPlayerInfoList = FellowshipData.GetBlackListInfo() or {}
    for i, aInfo in ipairs(tbPlayerInfoList) do
        aInfo.bOnLine, aInfo.bAppOnline = FellowshipData.IsOnline(aInfo.id)
    end
    table.sort(tbPlayerInfoList, fnSortFriend)
    self:SetPlayerInfoCellTab(tbPlayerCellList, tbPlayerIDList, tbPlayerInfoList, FellowshipData.tbRelationType.nBlack, 0, 0)

    return tbPlayerCellList, tbPlayerIDList
end

function UIFriendView:SetPlayerInfoCellTab(tbPlayerCellList, tbPlayerIDList, tbPlayerInfoList, nRelationType, nOnlineCount, nAllCount)
    for _, tbPlayerInfo in ipairs(tbPlayerInfoList) do
        local PlayerCellList = {nPrefabID = PREFAB_ID.WidgetPlayerMessageTogNew, nRelationType = nRelationType, tbPlayerInfo = tbPlayerInfo}
        if self:CheckMatchFilter(nRelationType, tbPlayerInfo) then
            local function IsCountOnline(id)
                local bOnLine, bAppOnline
                if id then
                    bOnLine, bAppOnline = FellowshipData.IsOnline(id)
                end
                return bOnLine or bAppOnline
            end

            if IsCountOnline(tbPlayerInfo.id) or tbPlayerInfo.bOnLine or tbPlayerInfo.bIsOnline then
                nOnlineCount = nOnlineCount + 1
            end
            nAllCount = nAllCount + 1
            self:SetCellTab(tbPlayerCellList, PlayerCellList, tbPlayerIDList, tbPlayerInfo.id or tbPlayerInfo.dwID)
        end
    end

    if not table.is_empty(tbPlayerCellList) and tbPlayerCellList[#tbPlayerCellList - nAllCount].nPrefabID == PREFAB_ID.WidgetFriendListNew then
        if nRelationType == FellowshipData.tbRelationType.nFriend or
        nRelationType == FellowshipData.tbRelationType.nTong then
            tbPlayerCellList[#tbPlayerCellList - nAllCount].szNum = "("..nOnlineCount.."/"..#tbPlayerInfoList..")"
        elseif nRelationType == FellowshipData.tbRelationType.nBlack or
        nRelationType == FellowshipData.tbRelationType.nFoe or
        nRelationType == FellowshipData.tbRelationType.nFeud or
        nRelationType == FellowshipData.tbRelationType.nAroundPlayer or
        nRelationType == FellowshipData.tbRelationType.nNpc then
            tbPlayerCellList[#tbPlayerCellList - nAllCount].szNum = "("..#tbPlayerInfoList..")"
        end
    end

    return nOnlineCount, nAllCount
end

function UIFriendView:UpdateMentorCellList(tbPlayerCellList, tbPlayerIDList)
    local nGroupID = 1
    local nOnlineCount, nAllCount = 0, 0

    self.tbMyDirectMaster = self.tbMyDirectMaster or {}
    if #self.tbMyDirectMaster ~= 0 then
        self:SetCellTab(tbPlayerCellList, {nPrefabID = PREFAB_ID.WidgetFriendListNew, bSelected = self.tFriendGroupSelected[nGroupID], szTitle = g_tStrings.STR_MY_DIRECT_MASTER, nGroupID = nGroupID})

        nGroupID = nGroupID + 1
        nOnlineCount, nAllCount = self:SetPlayerInfoCellTab(tbPlayerCellList, tbPlayerIDList, self.tbMyDirectMaster, FellowshipData.tbRelationType.nMaster, nOnlineCount, nAllCount)

        for _, tbMyDirectMaster in ipairs(self.tbMyDirectMaster) do
            if tbMyDirectMaster.aDirectApprentice then
                nOnlineCount, nAllCount = self:SetPlayerInfoCellTab(tbPlayerCellList, tbPlayerIDList, tbMyDirectMaster.aDirectApprentice, FellowshipData.tbRelationType.nSameApp, nOnlineCount, nAllCount)
            end

            if tbMyDirectMaster.aApprentice then
                nOnlineCount, nAllCount = self:SetPlayerInfoCellTab(tbPlayerCellList, tbPlayerIDList, tbMyDirectMaster.aApprentice, FellowshipData.tbRelationType.nSameApp, nOnlineCount, nAllCount)
            end
        end

        if tbPlayerCellList[#tbPlayerCellList - nAllCount].nPrefabID == PREFAB_ID.WidgetFriendListNew then
            tbPlayerCellList[#tbPlayerCellList - nAllCount].szNum = "("..nOnlineCount.."/"..nAllCount..")"
        end
    end

    self.tbMyMaster = self.tbMyMaster or {}
    for i, tbGroupInfo in ipairs(self.tbMyMaster) do
        self:SetCellTab(tbPlayerCellList, {nPrefabID = PREFAB_ID.WidgetFriendListNew, bSelected = self.tFriendGroupSelected[nGroupID], szTitle = g_tStrings.STR_MY_MASTER[i], nGroupID = nGroupID})
        nGroupID = nGroupID + 1

        nOnlineCount, nAllCount = 0, 0
        if tbGroupInfo.bOnLine then
            nOnlineCount = nOnlineCount + 1
        end
        nAllCount = nAllCount + 1

        local PlayerCellList = {nPrefabID = PREFAB_ID.WidgetPlayerMessageTogNew, nRelationType = FellowshipData.tbRelationType.nMaster, tbPlayerInfo = tbGroupInfo}
        self:SetCellTab(tbPlayerCellList, PlayerCellList, tbPlayerIDList, tbGroupInfo.dwID)

        if tbGroupInfo.aDirectApprentice then
            nOnlineCount, nAllCount = self:SetPlayerInfoCellTab(tbPlayerCellList, tbPlayerIDList, tbGroupInfo.aDirectApprentice, FellowshipData.tbRelationType.nSameApp, nOnlineCount, nAllCount)
        end

        if tbGroupInfo.aApprentice then
            nOnlineCount, nAllCount = self:SetPlayerInfoCellTab(tbPlayerCellList, tbPlayerIDList, tbGroupInfo.aApprentice, FellowshipData.tbRelationType.nSameApp, nOnlineCount, nAllCount)
        end

        if not table.is_empty(tbPlayerCellList) and tbPlayerCellList[#tbPlayerCellList - nAllCount].nPrefabID == PREFAB_ID.WidgetFriendListNew then
            tbPlayerCellList[#tbPlayerCellList - nAllCount].szNum = "("..nOnlineCount.."/"..nAllCount..")"
        end
    end

    return tbPlayerCellList, tbPlayerIDList
end

function UIFriendView:UpdateApprenticeCellList(tbPlayerCellList, tbPlayerIDList)
    --我的徒弟 (亲传和普通都在这个里面)
    local nGroupID = 1
    local nOnlineCount, nAllCount = 0, 0

    self.tbMyDirectApprentice = self.tbMyDirectApprentice or {}
    self.tbMyApprentice = self.tbMyApprentice or {}
    if #self.tbMyDirectApprentice ~= 0 or #self.tbMyApprentice ~= 0 then
        self:SetCellTab(tbPlayerCellList, {nPrefabID = PREFAB_ID.WidgetFriendListNew, bSelected = self.tFriendGroupSelected[nGroupID], szTitle = g_tStrings.STR_MY_APPRENTICE, nGroupID = nGroupID})

        nOnlineCount, nAllCount = self:SetPlayerInfoCellTab(tbPlayerCellList, tbPlayerIDList, self.tbMyDirectApprentice, FellowshipData.tbRelationType.nApprentice, nOnlineCount, nAllCount)

        nOnlineCount, nAllCount = self:SetPlayerInfoCellTab(tbPlayerCellList, tbPlayerIDList, self.tbMyApprentice, FellowshipData.tbRelationType.nApprentice, nOnlineCount, nAllCount)
    end

    if not table.is_empty(tbPlayerCellList) and tbPlayerCellList[#tbPlayerCellList - nAllCount].nPrefabID == PREFAB_ID.WidgetFriendListNew then
        tbPlayerCellList[#tbPlayerCellList - nAllCount].szNum = "("..nOnlineCount.."/"..nAllCount..")"
    end

    return tbPlayerCellList, tbPlayerIDList
end

function UIFriendView:UpdateFOECellList(tbPlayerCellList, tbPlayerIDList)
    self:SetCellTab(tbPlayerCellList, {nPrefabID = PREFAB_ID.WidgetFriendListNew, bSelected = self.tFriendGroupSelected[1], szTitle = g_tStrings.NOTE_ENEMY, nGroupID = 1})
    local tbPlayerInfoList = FellowshipData.GetFoeInfo() or {}
    self:SetPlayerInfoCellTab(tbPlayerCellList, tbPlayerIDList, tbPlayerInfoList, FellowshipData.tbRelationType.nFoe, 0, 0)

    self:SetCellTab(tbPlayerCellList, {nPrefabID = PREFAB_ID.WidgetFriendListNew, bSelected = self.tFriendGroupSelected[2], szTitle = g_tStrings.NOTE_FEUD, nGroupID = 2})
    tbPlayerInfoList = FellowshipData.GetFeudInfo() or {}
    self:SetPlayerInfoCellTab(tbPlayerCellList, tbPlayerIDList, tbPlayerInfoList, FellowshipData.tbRelationType.nFeud, 0, 0)

    return tbPlayerCellList, tbPlayerIDList
end

function UIFriendView:UpdateNPCCellList(tbPlayerCellList, tbPlayerIDList)
    local tbPlayerInfoList = {}
    local szSearchNpc = UIHelper.GetString(self.EditBoxSetting_NPC)
    for k, v in ipairs(ChatAINpcMgr.GetNpcList()) do
        if szSearchNpc == "" or string.find(GBKToUTF8(v.szName), szSearchNpc) then
            table.insert(tbPlayerInfoList, v)
        end
    end

    self:SetCellTab(tbPlayerCellList, {nPrefabID = PREFAB_ID.WidgetFriendListNew, bSelected = self.tFriendGroupSelected[1], szTitle = g_tStrings.NOTE_NPC, nGroupID = 1})
    self:SetPlayerInfoCellTab(tbPlayerCellList, tbPlayerIDList, tbPlayerInfoList, FellowshipData.tbRelationType.nNpc, 0, 0)

    return tbPlayerCellList, tbPlayerIDList
end

function UIFriendView:UpdateTongCellList(tbPlayerCellList, tbPlayerIDList)
    -- local bIncludeOffline = (self.tbFilter.bOnline == false or self.tbFilter.bOnline == nil)
    local bIncludeOffline = true
    local tbMemberIDList = TongData.GetMemberList(bIncludeOffline, TongData.tbSortType.Score, false, -1, -1)

    local tbPlayerInfoList = {}
    for _, dwID in ipairs(tbMemberIDList) do
        local tbPlayerInfo = TongData.GetMemberInfo(dwID)
        table.insert(tbPlayerInfoList, tbPlayerInfo)
    end

    if #tbPlayerInfoList ~= 0 then
        self:SetCellTab(tbPlayerCellList, {nPrefabID = PREFAB_ID.WidgetFriendListNew, bSelected = self.tFriendGroupSelected[1], szTitle = g_tStrings.GUILD, nGroupID = 1})
        self:SetPlayerInfoCellTab(tbPlayerCellList, tbPlayerIDList, tbPlayerInfoList, FellowshipData.tbRelationType.nTong, 0, 0)
    end

    return tbPlayerCellList, tbPlayerIDList
end

function UIFriendView:UpdateAroundCellList(tbPlayerCellList, tbPlayerIDList)
    local tbPlayerList = g_pClientPlayer.GetAroundPlayerID()
    local tbPlayerInfoList = {}

    for _, dwID in ipairs(tbPlayerList) do
        if dwID ~= PlayerData.GetPlayerID() then
            local tbInfo = {}
            tbInfo.dwID = dwID
            tbInfo.bOnline = true
            table.insert(tbPlayerInfoList, tbInfo)
        end
    end

    self:SetCellTab(tbPlayerCellList, {nPrefabID = PREFAB_ID.WidgetFriendListNew, bSelected = self.tFriendGroupSelected[1], szTitle = g_tStrings.STR_AROUND_PLAYER_GROUP_NAME, nGroupID = 1})
    self:SetPlayerInfoCellTab(tbPlayerCellList, tbPlayerIDList, tbPlayerInfoList, FellowshipData.tbRelationType.nAroundPlayer, 0, 0)

    return tbPlayerCellList, tbPlayerIDList
end

function UIFriendView:UpdateRecentCellList(tbPlayerCellList, tbPlayerIDList)    --密聊
    local tbPlayerInfoList = {}
    local tbPlayerInfo = {}

    local tbPlayerList = ChatRecentMgr.GetRecentWhisperPlayerList()
    tbPlayerList = ChatRecentMgr.SortPlayerList(tbPlayerList)

    for k, tbInfo in ipairs(tbPlayerList) do
        if not self.bFriendSelected or self.bFriendSelected and FellowshipData.IsFriend(tbInfo.szGlobalID) and k <= RECENT_CONTACT_MAX_NUM then
            tbInfo.id = tbInfo.szGlobalID
            local PlayerCellList = {nPrefabID = PREFAB_ID.WidgetPlayerMessageTogNew, nRelationType = FellowshipData.tbRelationType.nRecent, tbPlayerInfo = tbInfo}
            self:SetCellTab(tbPlayerCellList, PlayerCellList)
        end
    end

    return tbPlayerCellList, tbPlayerIDList
end

function UIFriendView:GetCellType()
    local tPlayerCellList = {}
    local nFriendGroupIndex = 0
    for k, tbPlayerCell in ipairs(self.tbPlayerCellList) do
        if tbPlayerCell.nPrefabID == PREFAB_ID.WidgetFriendListNew then
            table.insert(tPlayerCellList, tbPlayerCell)
            nFriendGroupIndex = nFriendGroupIndex + 1
        elseif tbPlayerCell.nRelationType == FellowshipData.tbRelationType.nRecent then
            table.insert(tPlayerCellList, tbPlayerCell)
        else
            if self.tFriendGroupSelected[nFriendGroupIndex] then
                table.insert(tPlayerCellList, tbPlayerCell)
            end
        end
    end

    return tPlayerCellList
end


function UIFriendView:UpdateOneCell(cell, nIndex, tbPlayerCellList)
    cell._keepmt = true

    local tbPlayerCell = tbPlayerCellList[nIndex]

    cell:OnEnter(nIndex, tbPlayerCell, self.WidgetPlayerPop)
    if tbPlayerCell.nPrefabID == PREFAB_ID.WidgetFriendListNew then
        cell:SetToggleCallback(function (bSelected, nFriendGroupIndex, nFriendListIndex)
            self.tFriendGroupSelected[nFriendGroupIndex] = bSelected

            self:UpdateFellowshipList(nFriendListIndex)
        end)
    end
end

function UIFriendView:UpdateFellowshipList(nFriendListIndex)
    self:UpdateFellowshipListInfo()
    self:InitScrollList()
    local tbPlayerCellList = self:GetCellType()

    if #tbPlayerCellList ~= 0 then
        if nFriendListIndex and nFriendListIndex < 8 then
            nFriendListIndex = 1
        end
        self.tScrollList:ResetWithStartIndex(#tbPlayerCellList, nFriendListIndex or 1)
    end

    UIHelper.LayoutDoLayout(self.LayoutContent)
    if self.nType == FellowshipData.tbRelationShowType.nTong then
        UIHelper.LayoutDoLayout(self.WidgetScript.WidgetSocietyList)
    else
        UIHelper.LayoutDoLayout(self.LayOutChatContent)
    end

    if (not nFriendListIndex) then
        Timer.AddFrame(self, 1, function()
            UIHelper.SetPositionY(self.tScrollList.m.contentNode, 0)
        end)
    end
end

function UIFriendView:SetEmptyState()
    UIHelper.SetVisible(self.WidgetEmptyState, #self.tbPlayerCellList == 0)
    UIHelper.SetVisible(self.LayoutContent, #self.tbPlayerCellList ~= 0)
    if self.nType == FellowshipData.tbRelationShowType.nContacts and self.nSelectedTab == self.tbTab.FRIEND and self.bInEditor then
        UIHelper.SetString(self.LableEmptyGuide, g_tStrings.STR_EMPTY_FRIEND_GROUP_TIP)
    elseif self.nType == FellowshipData.tbRelationShowType.nApprentice and self.nSelectedTab == self.tbTab.nMaster then
        if CrossMgr.IsCrossing() then
        else
            UIHelper.SetString(self.LableEmptyGuide, g_tStrings.STR_EMPTY_MENTOR_GROUP_TIP)
        end
    elseif self.nType == FellowshipData.tbRelationShowType.nContacts and self.nSelectedTab == self.tbTab.RECENT then
        UIHelper.SetString(self.LableEmptyGuide, "暂无最近联系人")
    end

    if self.nType == FellowshipData.tbRelationShowType.nTong then
        UIHelper.SetVisible(self.WidgetScript.WidgetSocietyMessage, #self.tbPlayerCellList ~= 0)
        if CrossMgr.IsCrossing() then
            UIHelper.SetString(self.WidgetScript.LableEmptyGuide, g_tStrings.STR_REMOTE_NOT_TIP1)
        end
        UIHelper.BindUIEvent(self.WidgetScript.WidgetSocietyMessage, EventType.OnClick, function ()
            UIMgr.Open(VIEW_ID.PanelFactionManagement)
        end)

        UIHelper.SetVisible(self.WidgetScript.BtnOpenTongWhisper, #self.tbPlayerCellList ~= 0)

        UIHelper.BindUIEvent(self.BtnJoinSociety, EventType.OnClick, function ()
            UIMgr.Open(VIEW_ID.PanelFactionList)
        end)
    end
end

function UIFriendView:IsForceExpandGroup()
    return not self.bInEditor
end

function UIFriendView:EnableEditorMode(bEditorMode)
    self.bInEditor = bEditorMode

    UIHelper.SetVisible(self.WidgetEditBtnList, bEditorMode)
end

function UIFriendView:ClearSelectedState()
    Event.Dispatch(EventType.OnClearSelectedState)
end

function UIFriendView:SetupFiterFunction()
    self.tbFilterFunc = {
        Online = function(tbPlayerInfo)
            local bOnLine, bAppOnline = FellowshipData.IsOnline(tbPlayerInfo.id)
            local bIsOnline = bOnLine or bAppOnline
            return (self.tbFilter.bOnline == nil or self.tbFilter.bOnline == bIsOnline)
        end,

        IsTwoWayFriend = function(tbPlayerInfo)
            local bResult = self.tbFilter.bIsTwoWayFriend == nil or self.tbFilter.bIsTwoWayFriend == 1
            if not bResult then
                local nFilter = self.tbFilter.bIsTwoWayFriend == 2 and 1 or 0
                bResult = nFilter == self.tbTwoWayFriend[tbPlayerInfo.id]
            end
            return bResult
        end,

        ForceID = function(tbPlayerInfo)
            if self.tbFilter.dwForceID == nil or self.tbFilter.dwForceID == -1  then return true end

            local tbRoleEntryInfo = FellowshipData.GetRoleEntryInfo(tbPlayerInfo.id) or {}
            local dwForceID = tbRoleEntryInfo.nForceID or 0
            return dwForceID == self.tbFilter.dwForceID
        end,

        Name = function(tbPlayerInfo)
            if not self.tbFilter.szNameContain then return true end

            local tbRoleEntryInfo = FellowshipData.GetRoleEntryInfo(tbPlayerInfo.id) or {}

            if tbRoleEntryInfo.szName and string.find(tbRoleEntryInfo.szName, self.tbFilter.szNameContain) then
                return true
            end

            if tbPlayerInfo.remark and string.find(tbPlayerInfo.remark, self.tbFilter.szNameContain) then
                return true
            end

            return false
        end
    }
end

function UIFriendView:CheckMatchFilter(nRelationType, tbPlayerInfo)
    if self.nType == FellowshipData.tbRelationShowType.nContacts and self.nSelectedTab == self.tbTab.FRIEND then
        local tbFilterFunc = {}
        if nRelationType == FellowshipData.tbRelationType.nFriend then
            tbFilterFunc = {self.tbFilterFunc.Online, self.tbFilterFunc.ForceID, self.tbFilterFunc.Name, self.tbFilterFunc.IsTwoWayFriend}
        elseif nRelationType == FellowshipData.tbRelationType.nBlack then
            tbFilterFunc = {self.tbFilterFunc.Online, self.tbFilterFunc.ForceID, self.tbFilterFunc.Name}
        end

        for _, func in ipairs(tbFilterFunc) do
            if not func(tbPlayerInfo) then
                return false
            end
        end
    end

    return true
end

return UIFriendView