-- ---------------------------------------------------------------------------------
-- Author: Unknown
-- Name: UIApprenticeView
-- Date: 2023-02-08 16:00:51
-- Desc: 这个脚本是老板师徒的预制对应脚本 目前已经不用了
-- ---------------------------------------------------------------------------------

local UIApprenticeView = class("UIApprenticeView")

local m_CanFindDirectMasterNum = 0
local m_FindDirectMasterErrorCode
local m_CanFindMasterNum = 0
local m_CanFindAppNum = 0
local m_FindMasterErrorCode
local m_CanFindDirectAppNum = 0
local m_FindDirectAppErrorCode
local m_FindAppErrorCode
local DIRECT_MASTER_MAX_NUM = 1
local NORMAL_MASTER_MAX_NUM = 3
local DIRECT_APP_MAX_NUM = 2
local NORMAL_APP_MAX_NUM = 10
local ERROR_CODE = { --这个序号对应string.lua里tFindAppErrorCode等表格，来提示玩家为什么不能拜师或者收徒
	NORMAL = 0,
	ONE = 1,
	TWO = 2,
	THREE = 3,
}
local m_GongZhanJiangHuBuff = {--共战江湖buff
	nBuffID = 3219,
	nBuffLevel = 10
}
-- local m_bGraduate = false
-- local tFilter2Force = {
--     -1,
--     FORCE_TYPE.JIANG_HU,
--     FORCE_TYPE.SHAO_LIN,
--     FORCE_TYPE.WAN_HUA,
--     FORCE_TYPE.TIAN_CE,
--     FORCE_TYPE.CHUN_YANG,
--     FORCE_TYPE.QI_XIU,
--     FORCE_TYPE.WU_DU,
--     FORCE_TYPE.TANG_MEN,
--     FORCE_TYPE.CANG_JIAN,
--     FORCE_TYPE.GAI_BANG,
--     FORCE_TYPE.MING_JIAO,
--     FORCE_TYPE.CANG_YUN,
--     FORCE_TYPE.CHANG_GE,
--     FORCE_TYPE.BA_DAO,
--     FORCE_TYPE.PENG_LAI,
--     FORCE_TYPE.LING_XUE,
--     FORCE_TYPE.YAN_TIAN,
--     FORCE_TYPE.YAO_ZONG,
--     FORCE_TYPE.DAO_ZONG,
-- }
-- local tFilter2CampID = {
--     -1,
--     CAMP.NEUTRAL,
--     CAMP.GOOD,
--     CAMP.EVIL,
-- }

function UIApprenticeView:OnEnter(bCanBeDirectMentor,tbMyMaster,tbMyDirectMaster,tbMyApprentice,tbMyDirectApprentice)
    if not self.bInit then
        self:RegEvent()
        self:BindUIEvent()
        self.bInit = true
    end
    self.bFindMas = true --是true就是点拜师进来的，false就是点收徒进来的，决定了展示哪个部分 先默认进入拜师吧
    self.tbMyMaster = tbMyMaster
    self.tbMyDirectMaster = tbMyDirectMaster
    self.tbMyApprentice = tbMyApprentice
    self.tbMyDirectApprentice = tbMyDirectApprentice
    self.nIndex = 1
    self.nMasCampID = -1
    self.nAppCampID = -1
    self.nMasForceID = -1
    self.nAppForceID = -1
    -- JudgeNeedMentor()
    -- JudgeNeedApprentice()
    ApplyApprenticePushList(false, self.nAppCampID, self.nAppForceID)
	ApplyMentorPushList(false, self.nMasCampID, self.nMasForceID)
    RemoteCallToServer("OnIsAccountDirectApprentice")

    self:UpdateInfo()
end

function UIApprenticeView:OnExit()
    self.bInit = false
    Timer.DelAllTimer(self)
    self:UnRegEvent()
end

function UIApprenticeView:BindUIEvent()
    UIHelper.BindUIEvent(self.BtnClose,EventType.OnClick,function ()
        UIMgr.Close(self)
    end)

    UIHelper.BindUIEvent(self.BtnNews,EventType.OnClick,function ()
        if not UIMgr.GetView(VIEW_ID.PanelAddStudentPop) then
            UIMgr.Open(VIEW_ID.PanelAddStudentPop,self.bFindMas)
        end
    end)

    UIHelper.BindUIEvent(self.BtnRenovat,EventType.OnClick,function ()
        if self.nCountdown and self.nCountdown ~= 0 then
            TipsHelper.ShowNormalTip(FormatString (g_tStrings.MENTOR_FRESH_COLD,self.nCountdown))
            return
        end

        if self.bFindMas then --刷新拜师列表
            self.nMasForceID = -1
            ApplyMentorPushList(false, -1, self.nMasForceID)
        else --刷新收徒列表
            self.nAppForceID = -1
            ApplyApprenticePushList(false, -1, self.nAppForceID)
        end

        UIHelper.SetVisible(self.ImgBtn1,false)
        UIHelper.SetVisible(self.WidgetBtn2,true)

        self.nCountdown = 10
        Timer.AddCountDown(self, self.nCountdown, function ()
            self.nCountdown = self.nCountdown - 1--"10(秒)"
            UIHelper.SetString(self.LableGroup2, tostring(self.nCountdown).."(秒)")
        end,
        function ()
            UIHelper.SetVisible(self.ImgBtn1,true)
            UIHelper.SetVisible(self.WidgetBtn2,false)
            UIHelper.SetString(self.LableGroup2, "10(秒)")
        end)
    end)

    UIHelper.BindUIEvent(self.TogTabList,EventType.OnClick,function ()
        self.bFindMas = true
        self.nIndex = 1
        UIHelper.SetVisible(self.WidgetAddMessage,false)
        UIHelper.SetString(self.LabelDescibe, g_tStrings.MENTOR_NOT_INFO_1)
        UIHelper.SetVisible(self.WidgetAnchorMiddleEmpty, self.bVisibleM)
        UIHelper.SetVisible(self.WidgetEmptyLableM, true)
        UIHelper.SetVisible(self.WidgetEmptyLableA, false)
        Event.Dispatch(EventType.OnSelectChangedMentor, self.nIndex, true)
        self:UpdateButton()
        self:UpdatePushBtnState()
    end)

    UIHelper.BindUIEvent(self.TogTabList01,EventType.OnClick,function ()
        self.bFindMas = false
        self.nIndex = 1
        UIHelper.SetVisible(self.WidgetAddMessage,false)
        UIHelper.SetString(self.LabelDescibe, g_tStrings.MENTOR_NOT_INFO_2)
        UIHelper.SetVisible(self.WidgetAnchorMiddleEmpty, self.bVisibleA)
        UIHelper.SetVisible(self.WidgetEmptyLableA, true)
        UIHelper.SetVisible(self.WidgetEmptyLableM, false)
        Event.Dispatch(EventType.OnSelectChangedMentor, self.nIndex, false)
        self:UpdateButton()
        self:UpdatePushBtnState()
    end)

    UIHelper.BindUIEvent(self.BtnSeek,EventType.OnClick,function ()
        TipsHelper.ShowNodeHoverTipsInDir(PREFAB_ID.WidgetFiltrateTip, self.BtnSeek, TipsLayoutDir.BOTTOM_CENTER, FilterDef.Apprentice)
    end)

    UIHelper.BindUIEvent(self.BtnChat,EventType.OnClick,function ()
        --密聊
        self:OnClickChat()
    end)

    UIHelper.BindUIEvent(self.BtnEquipment,EventType.OnClick,function ()
        --查看装备
        local table
        if self.bFindMas then
            table = self.tPushMentorList[self.nIndex]
        else
            table = self.tPushApprenticeList[self.nIndex]
        end
        UIMgr.Open(VIEW_ID.PanelOtherPlayer, table.dwRoleID)
    end)

    UIHelper.BindUIEvent(self.BtnStudent,EventType.OnClick,function ()
        --收徒
        local szName = self.tPushApprenticeList[self.nIndex].szName
        RemoteCallToServer("OnApplyApprentice", szName) -- 申请收徒，后面是名字
    end)

    UIHelper.BindUIEvent(self.BtnTeacher,EventType.OnClick,function ()
        --拜师
        local szName = self.tPushMentorList[self.nIndex].szName
        RemoteCallToServer("OnApplyMentor", szName)
    end)

    UIHelper.BindUIEvent(self.BtnTeacher1,EventType.OnClick,function ()
        --拜亲传师父
        local szName = self.tPushMentorList[self.nIndex].szName
        RemoteCallToServer("OnApplyDirectMentor", szName)
    end)

    --社交栏
    UIHelper.BindUIEvent(self.BtnPlayerIcon, EventType.OnClick, function ()
        TipsHelper.ShowNodeHoverTips(PREFAB_ID.WidgetPraiseStatus, self.BtnPlayerIcon, self.tbPlayerCard.Praiseinfo or {})
    end)
end

function UIApprenticeView:RegEvent()
    --Event.Reg(self, EventType.XXX, func)
    Event.Reg(self,"ON_IS_ACCOUNT_DIRECT_APPRENTICE",function (bApprentice)
        --取账号亲传师徒权限
        self.bAccountDirectMentor = not bApprentice
        self:UpdateMasterNum()
        self:UpdateAppNum()
        self:UpdatePushBtnState()
    end)

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
    end)

    Event.Reg(self,EventType.OnSelectedPlayerMessage,function (nIndex,bMentor)
        if self.bFindMas == bMentor then
            self.nIndex = nIndex
            self:UpdateSelectedInfo()
        end
    end)

    Event.Reg(self,"ON_SYNC_MAX_APPRENTICE_NUM",function ()
        self:UpdateAppNum()
        self:UpdatePushBtnState()
    end)

    Event.Reg(self, "ON_PUSH_MENTOR_NOTIFY", function ()
        self:UpdateFindMaster()
        self.nIndex = 1
        Event.Dispatch(EventType.OnSelectChangedMentor,self.nIndex,true)
        --self:UpdateSelectedInfo()
    end)

    Event.Reg(self, "ON_PUSH_APPRENTICE_NOTIFY", function ()
        self:UpdateFindApprentice()
        self.nIndex = 1
        Event.Dispatch(EventType.OnSelectChangedMentor,self.nIndex,false)
        --self:UpdateSelectedInfo()
    end)

    Event.Reg(self, "ON_PUSH_MENTOR_NOTIFY_BY_FORCEID", function ()
         self:UpdateFindMaster()
         self.nIndex = 1
         Event.Dispatch(EventType.OnSelectChangedMentor,self.nIndex,true)
    end)

    Event.Reg(self, "ON_PUSH_APPRENTICE_NOTIFY_BY_FORCEID", function ()
         self:UpdateFindApprentice()
         self.nIndex = 1
         Event.Dispatch(EventType.OnSelectChangedMentor,self.nIndex,false)
    end)

    Event.Reg(self, "ON_PUSH_MENTOR_NOTIFY_INFO_SINGLE", function ()
        self:UpdateFindMaster()
    end)

    Event.Reg(self, "ON_PUSH_APPRENTICE_NOTIFY_INFO_SINGLE", function ()
        self:UpdateFindApprentice()
    end)

    --发布收徒结果
    Event.Reg(self, "ON_REGISTER_MENTOR_RESULT", function (bSuccess)
        if bSuccess then
            TipsHelper.ShowNormalTip(g_tStrings.MENTOR_MSG.ON_SEEK_APPRENTICE_YELL_SUCESS)
            ApplyMentorPushList(false, -1, self.nMasForceID)
        else
            TipsHelper.ShowNormalTip(g_tStrings.MENTOR_MSG.ON_SEEK_APPRENTICE_YELL_FAIL)
        end
    end)

    --发布拜师结果
    Event.Reg(self, "ON_REGISTER_APPRENTICE_RESULT", function (bSuccess)
        if bSuccess then
            TipsHelper.ShowNormalTip(g_tStrings.MENTOR_MSG.ON_SEEK_MENTOR_YELL_SUCESS)
            ApplyApprenticePushList(false, -1, self.nAppForceID)
        else
            TipsHelper.ShowNormalTip(g_tStrings.MENTOR_MSG.ON_SEEK_MENTOR_YELL_FAIL)
        end
    end)

    Event.Reg(self, "ON_SYNC_MENTOR_DATA", function ()
        self:UpdateMasterNum()
        self:UpdatePushBtnState()
    end)

    Event.Reg(self, "ON_SYNC_MAX_APPRENTICE_NUM", function ()
        self:UpdateAppNum()
        self:UpdatePushBtnState()
    end)

    Event.Reg(self, EventType.OnFilter, function(szKey, tbSelected)
        if szKey == FilterDef.Apprentice.Key then
            if self.bFindMas then
                self.nMasForceID = tFilter2Force[tbSelected[1][1]]
                self.nMasCampID = tFilter2CampID[tbSelected[2][1]]
                ApplyMentorPushList(false, self.nMasCampID, self.nMasForceID)
            else
                self.nAppForceID = tFilter2Force[tbSelected[1][1]]
                self.nAppCampID = tFilter2CampID[tbSelected[2][1]]
                ApplyApprenticePushList(false, self.nAppCampID, self.nAppForceID)
            end
        end
    end)

    Event.Reg(self, "UPDATE_FELLOWSHIP_CARD", function (tbGlobalID)

        local tbList
        if self.bFindMas then
            tbList = self.tPushMentorList
        else
            tbList = self.tPushApprenticeList
        end

        local table = tbList[self.nIndex]

        local player = GetPlayer(table.dwRoleID)
        if player then
            local szGlobalID = player.GetGlobalID()
            for _, gid in ipairs(tbGlobalID) do
                if szGlobalID == gid then
                    self.tbPlayerCard = FellowshipData.GetFellowshipCardInfo(szGlobalID)
                    if not self.tbPlayerCard then
                        FellowshipData.ApplyFellowshipCard(szGlobalID)
                    else
                        local  labels = self.tbPlayerCard.Praiseinfo or {}
                        local tRes = Table_GetAllPersonLabel()
                        for i, info in ipairs(tRes) do
                            local nCount = labels[info.id] or 0
                            UIHelper.SetString(self.tbPersonLabelNum[i], PersonLabel_GetLevel(nCount, info.id))
                        end
                    end
                end
            end
        end
    end)
end

function UIApprenticeView:UnRegEvent()
    --Event.UnReg(self, EventType.XXX)
end






-- ----------------------------------------------------------
-- Please write your own code below  ↓↓↓
-- ----------------------------------------------------------

function UIApprenticeView:UpdateInfo()
    UIHelper.ToggleGroupAddToggle(self.togglegroup,self.TogTabList)
    UIHelper.ToggleGroupAddToggle(self.togglegroup,self.TogTabList01)
    self:UpdateMasterNum()
    self:UpdateAppNum()
    self:UpdatePushBtnState()
end

function UIApprenticeView:UpdateButton()
    --更新按钮
    UIHelper.SetVisible(self.BtnTeacher,self.bFindMas)
    UIHelper.SetVisible(self.BtnTeacher1,self.bFindMas)
    UIHelper.SetVisible(self.BtnStudent,not self.bFindMas)
    UIHelper.LayoutDoLayout(self.LayoutButton)
end

function UIApprenticeView:UpdateSelectedInfo()
    UIHelper.SetVisible(self.WidgetAddMessage,false)

    local tbList
    if self.bFindMas then
        tbList = self.tPushMentorList
    else
        tbList = self.tPushApprenticeList
    end

    local table = tbList[self.nIndex]
    if table then
        UIHelper.SetVisible(self.WidgetAddMessage, true)

        UIHelper.RemoveAllChildren(self.WidgetPlayerHead)

        local headScript = UIHelper.AddPrefab(PREFAB_ID.WidgetHead,self.WidgetPlayerHead)
        if headScript then
            headScript:SetHeadInfo(nil,table.dwMiniAvatorID,table.dwRoleType,table.dwForceID)
        end

        UIHelper.SetString(self.LableName,UIHelper.GBKToUTF8(table.szName))
        UIHelper.SetSpriteFrame(self.Imglevel, PlayerForceID2SchoolImg[table.dwForceID])
        UIHelper.SetString(self.LableLevel1,table.nLevel.."级")
        UIHelper.SetString(self.LableCamp1,g_tStrings.STR_CAMP_TITLE[table.nCamp])
        if table.szTongName == "" then
            UIHelper.SetVisible(self.LayoutGroup,false)
        else
            UIHelper.SetString(self.LableGroup1,UIHelper.GBKToUTF8(table.szTongName))
        end
        UIHelper.SetString(self.LabelIntroduce,UIHelper.GBKToUTF8(table.szComment))

        local player = GetPlayer(table.dwRoleID)
        if player then
            local szGlobalID = player.GetGlobalID()
            self.tbPlayerCard = FellowshipData.GetFellowshipCardInfo(szGlobalID)
            if not self.tbPlayerCard then
                FellowshipData.ApplyFellowshipCard(szGlobalID)
            else
                local  labels = self.tbPlayerCard.Praiseinfo or {}
                local tRes = Table_GetAllPersonLabel()
                for i, info in ipairs(tRes) do
                    local nCount = labels[info.id] or 0
                    UIHelper.SetString(self.tbPersonLabelNum[i], PersonLabel_GetLevel(nCount, info.id))
                end
            end
        end

        if table.dwRoleID == g_pClientPlayer.dwID then
            UIHelper.SetButtonState(self.BtnChat,BTN_STATE.Disable)
            UIHelper.SetButtonState(self.BtnEquipment,BTN_STATE.Disable)
        else
            UIHelper.SetButtonState(self.BtnChat,BTN_STATE.Normal)
            UIHelper.SetButtonState(self.BtnEquipment,BTN_STATE.Normal)
        end
    end
end

function UIApprenticeView:OnClickChat()
    local tbList
    if self.bFindMas then
        tbList = self.tPushMentorList
    else
        tbList = self.tPushApprenticeList
    end
    local table = tbList[self.nIndex]
    local szName = UIHelper.GBKToUTF8(table.szName)
    local dwTalkerID = table.dwID
    local dwForceID = table.dwForceID
    local dwMiniAvatarID = table.dwMiniAvatorID
    local nRoleType = table.dwRoleType
    local nLevel = table.nLevel
    local szGlobalID = table.szGlobalID
    local tbData = {szName = szName, dwTalkerID = dwTalkerID, dwForceID = dwForceID, dwMiniAvatarID = dwMiniAvatarID, nRoleType = nRoleType, nLevel = nLevel, szGlobalID = szGlobalID}

    ChatHelper.WhisperTo(szName, tbData)
end

function UIApprenticeView:UpdateMasterNum()
	self:UpdateFindMasterData()
    self:UpdateFindDirectMasterData()
    local bHaveBuff = g_pClientPlayer.IsHaveBuff(m_GongZhanJiangHuBuff.nBuffID, m_GongZhanJiangHuBuff.nBuffLevel)

    if m_CanFindDirectMasterNum == -2 then
        UIHelper.SetString(self.LableTipsNum1M,0)
        UIHelper.SetString(self.LableTipsNumMaster1M,0)
	elseif m_CanFindDirectMasterNum == 0 or m_CanFindDirectMasterNum > 0 then
		UIHelper.SetString(self.LableTipsNum1M,m_CanFindDirectMasterNum)
		UIHelper.SetString(self.LableTipsNumMaster1M,m_CanFindDirectMasterNum)
	end

    if m_CanFindMasterNum == -1 then
		UIHelper.SetVisible(self.LableTips1M,false)
		UIHelper.SetVisible(self.LayoutTips1,false)
        UIHelper.SetVisible(self.LableTips2M,true)
        UIHelper.SetVisible(self.LableTips2,true)
	elseif m_CanFindMasterNum > 0 or m_CanFindMasterNum == 0 then
		UIHelper.SetString(self.LableTipsNum2M, m_CanFindMasterNum)
		UIHelper.SetString(self.LableTipsNumStudent2M, m_CanFindMasterNum)
	else
		UIHelper.SetString(self.LableTipsNum2M, 0)
		UIHelper.SetString(self.LableTipsNumStudent2M, 0)
	end
end

function UIApprenticeView:UpdateAppNum()
    self:UpdateFindApprenticeData()
    self:UpdateFindDirectApprenticeData()

    if  m_CanFindDirectAppNum > 0 or m_CanFindDirectAppNum == 0 then
		UIHelper.SetString(self.LableTipsNum1A, m_CanFindDirectAppNum)
		UIHelper.SetString(self.LableTipsNumMaster1A, m_CanFindDirectAppNum)
	elseif m_CanFindDirectAppNum == -2 then
		UIHelper.SetString(self.LableTipsNum1A, 0)
		UIHelper.SetString(self.LableTipsNumMaster1A, 0)

	end

    if  m_CanFindAppNum > 0 or m_CanFindAppNum == 0 then
        UIHelper.SetString(self.LableTipsNum2A, m_CanFindAppNum)
        UIHelper.SetString(self.LableTipsNumStudent2A, m_CanFindAppNum)
	elseif m_CanFindAppNum == -2 then
		UIHelper.SetString(self.LableTipsNum2A, 0)
		UIHelper.SetString(self.LableTipsNumStudent2A, 0)
	end
end

function UIApprenticeView:UpdatePushBtnState()
    if self.bFindMas then
        UIHelper.SetButtonState(self.BtnNews, m_CanFindMasterNum > 0 or m_CanFindDirectMasterNum > 0 and BTN_STATE.Normal or BTN_STATE.Disable)
    else
        UIHelper.SetButtonState(self.BtnNews, m_CanFindAppNum > 0 or m_CanFindDirectAppNum > 0 and BTN_STATE.Normal or BTN_STATE.Disable)
    end
end

function UIApprenticeView:UpdateFindDirectMasterData()
    if self.bAccountDirectMentor then
        m_CanFindDirectMasterNum = 0
        m_FindDirectMasterErrorCode = ERROR_CODE.ONE
    elseif self.tbMyDirectMaster and #self.tbMyDirectMaster > 0 then
        m_CanFindDirectMasterNum = -2 --已满
        m_FindDirectMasterErrorCode = ERROR_CODE.TWO
    else
        m_CanFindDirectMasterNum = DIRECT_MASTER_MAX_NUM
        m_FindDirectMasterErrorCode = ERROR_CODE.NORMAL
    end
end

function UIApprenticeView:UpdateFindMasterData()
    if self.tbMyDirectApprentice and #self.tbMyDirectApprentice > 0 then
        m_CanFindMasterNum = 0
        m_FindMasterErrorCode = ERROR_CODE.ONE
    elseif not self.tbMyApprentice or #self.tbMyApprentice > 0 then
        m_CanFindMasterNum = 0
        m_FindMasterErrorCode = ERROR_CODE.ONE
    elseif self.tbMyMaster and #self.tbMyMaster == NORMAL_MASTER_MAX_NUM then
        m_CanFindMasterNum = -2
        m_FindMasterErrorCode = ERROR_CODE.TWO
    elseif m_bGraduate then --满级且已经出师
        m_CanFindMasterNum = -1
        m_FindMasterErrorCode = ERROR_CODE.THREE
    else
        m_CanFindMasterNum = NORMAL_MASTER_MAX_NUM - #self.tbMyMaster
        m_FindMasterErrorCode = ERROR_CODE.NORMAL
    end
end

function UIApprenticeView:UpdateFindDirectApprenticeData()
    if  g_pClientPlayer.nLevel < g_pClientPlayer.nMaxLevel then
        m_CanFindDirectAppNum = 0
        m_FindDirectAppErrorCode = ERROR_CODE.ONE
    elseif not self.bAccountDirectMentor then
        m_CanFindDirectAppNum = 0
        m_FindDirectAppErrorCode = ERROR_CODE.TWO
    elseif #(self.tbMyDirectApprentice) == g_pClientPlayer.GetMaxDirectApprenticeNum() then
        m_CanFindDirectAppNum = -2 --已满
        m_FindDirectAppErrorCode = ERROR_CODE.THREE
    else
        m_CanFindDirectAppNum = DIRECT_APP_MAX_NUM - #self.tbMyDirectApprentice
        m_FindDirectAppErrorCode = ERROR_CODE.NORMAL
    end
end

function UIApprenticeView:UpdateFindApprenticeData()
    if  g_pClientPlayer.nLevel < g_pClientPlayer.nMaxLevel then
        m_CanFindAppNum = 0
        m_FindAppErrorCode = ERROR_CODE.ONE
    elseif not self.tbMyMaster or #self.tbMyMaster > 0  then
        m_CanFindAppNum = 0
        m_FindAppErrorCode = ERROR_CODE.TWO
    elseif #self.tbMyApprentice == NORMAL_APP_MAX_NUM then
        m_CanFindAppNum = -2 --已满
        m_FindAppErrorCode = ERROR_CODE.THREE
    else
        m_CanFindAppNum = NORMAL_APP_MAX_NUM - #self.tbMyApprentice
        m_FindAppErrorCode = ERROR_CODE.NORMAL
    end
end

function UIApprenticeView:UpdateFindMaster()
    UIHelper.RemoveAllChildren(self.ScollViewListM)
    self.tPushMentorList = GetPushMentorList() or {} -- 只能获得此时在线的列表

    self.bVisibleM = true
	for k, v in pairs(self.tPushMentorList) do
        self.bVisibleM = false
        UIHelper.AddPrefab(PREFAB_ID.WidgetPlayerMessage,self.ScollViewListM,k,true,v)
	end
    if self.bFindMas then
        UIHelper.SetVisible(self.WidgetAnchorMiddleEmpty, self.bVisibleM)
        UIHelper.SetVisible(self.WidgetEmptyLableM, self.bVisibleM)
        UIHelper.SetVisible(self.WidgetAddMessage, not self.bVisibleM)
    end

    UIHelper.SetVisible(self.WidgetAnchorLableM, not self.bVisibleM)
    UIHelper.ScrollViewDoLayout(self.ScollViewListM)
    UIHelper.ScrollToTop(self.ScollViewListM,0)
end

function UIApprenticeView:UpdateFindApprentice()
    UIHelper.RemoveAllChildren(self.ScollViewListA)
    self.tPushApprenticeList = GetPushApprenticeList() or {} -- 只能获得此时在线的列表

    self.bVisibleA = true
	for k, v in pairs(self.tPushApprenticeList) do
        self.bVisibleA = false
        UIHelper.AddPrefab(PREFAB_ID.WidgetPlayerMessage,self.ScollViewListA,k,false,v)
	end
    if not self.bFindMas then
        UIHelper.SetVisible(self.WidgetAnchorMiddleEmpty, self.bVisibleA)
        UIHelper.SetVisible(self.WidgetEmptyLableA, self.bVisibleA)
        UIHelper.SetVisible(self.WidgetAddMessage, not self.bVisibleA)
    end

    UIHelper.SetVisible(self.WidgetAnchorLableA, not self.bVisibleA)
    UIHelper.ScrollViewDoLayout(self.ScollViewListA)
    UIHelper.ScrollToTop(self.ScollViewListA,0)
end

return UIApprenticeView