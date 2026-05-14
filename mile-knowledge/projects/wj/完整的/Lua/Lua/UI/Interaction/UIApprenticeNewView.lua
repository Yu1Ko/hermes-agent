-- ---------------------------------------------------------------------------------
-- Author: Unknown
-- Name: UIApprenticeNewView
-- Date: 2024-03-18 20:45:50
-- Desc: ?
-- ---------------------------------------------------------------------------------

local UIApprenticeNewView = class("UIApprenticeNewView")

local tTogIndex = {
    nMyMaster = 1,
    nMyApprentice = 2,
    nFinds = 3,
    nReward = 4,
}

local m_FindDirectMasterErrorCode
local m_FindMasterErrorCode
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
local nLayoutMaxNum = 7

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
local tFilter2CampID = {
    -1,
    CAMP.NEUTRAL,
    CAMP.GOOD,
    CAMP.EVIL,
}

function UIApprenticeNewView:OnEnter()
    if not self.bInit then
        self:RegEvent()
        self:BindUIEvent()
        self.bInit = true
    end

    self.bSelectedTog = tTogIndex.nFinds
    self:InitPageData()
    self:ApplyInfo()

    self:GotoFindMas()
end

function UIApprenticeNewView:OnExit()
    self.bInit = false
    Timer.DelAllTimer(self)
    self:UnRegEvent()
end

function UIApprenticeNewView:BindUIEvent()
    UIHelper.BindUIEvent(self.BtnClose, EventType.OnClick, function ()
        UIMgr.Close(self)
    end)

    for k, v in ipairs(self.tbTogList) do
        UIHelper.BindUIEvent(self.tbTogList[k], EventType.OnSelectChanged, function (_, bSelected)
            if bSelected then
                if self.bSelectedTog == tTogIndex.nMyMaster then
                    FellowshipData.SetMentorRedpoint(false)
                elseif self.bSelectedTog == tTogIndex.nMyApprentice then
                    FellowshipData.SetAppremticeRedpoint(false)
                end

                self.bSelectedTog = k
                self:UpdatePageInfo()
                self:UpdateMasterList()
                UIHelper.LayoutDoLayout(self.LayoutNavigation)
                self:UpdateFindBtnState()
            end
        end)
    end

    UIHelper.BindUIEvent(self.BtnSeek, EventType.OnClick, function ()
        TipsHelper.ShowNodeHoverTipsInDir(PREFAB_ID.WidgetFiltrateTip, self.BtnSeek, TipsLayoutDir.BOTTOM_CENTER, FilterDef.Apprentice)
    end)

    UIHelper.BindUIEvent(self.BtnRenovat, EventType.OnClick, function ()
        if self.nCountdown and self.nCountdown ~= 0 then
            TipsHelper.ShowNormalTip(FormatString (g_tStrings.MENTOR_FRESH_COLD,self.nCountdown))
            return
        end

        if self.bFindMas then --刷新拜师列表
            -- self.nMasForceID = -1
            ApplyMentorPushList(false, -1, self.nForceID)
        else --刷新收徒列表
            -- self.nAppForceID = -1
            ApplyApprenticePushList(false, -1, self.nForceID)
        end

        UIHelper.SetVisible(self.ImgBtn1,false)
        UIHelper.SetVisible(self.WidgetBtn2,true)

        self.nCountdown = 10
        Timer.AddCountDown(self, self.nCountdown, function ()
            self.nCountdown = self.nCountdown - 1--"10(秒)"
            UIHelper.SetString(self.LableGroup2, tostring(self.nCountdown).."(秒)")
        end, function ()
            UIHelper.SetVisible(self.ImgBtn1,true)
            UIHelper.SetVisible(self.WidgetBtn2,false)
            UIHelper.SetString(self.LableGroup2, "10(秒)")
        end)
    end)

    UIHelper.BindUIEvent(self.TogNavigation031, EventType.OnClick, function ()
        self.bFindMas = true
        self.nFindIndex = 1
        self:UpdateFindMasterList()

        self:UpdateFindBtnState()
    end)

    UIHelper.BindUIEvent(self.TogNavigation032, EventType.OnClick, function ()
        self.bFindMas = false
        self.nFindIndex = 1
        self:UpdateFindMasterList()

        self:UpdateFindBtnState()
    end)

    UIHelper.BindUIEvent(self.BtnApprenticeAdd, EventType.OnClick, function ()
        local bCanPublish = self:CheckFindBtnCD()
        if bCanPublish then
            if not UIMgr.GetView(VIEW_ID.PanelAddStudentPop) then
                UIMgr.Open(VIEW_ID.PanelAddStudentPop,self.bFindMas)
            end
        end
    end)

    UIHelper.BindUIEvent(self.BtnApprenticeMy, EventType.OnClick, function ()
        if not UIMgr.GetView(VIEW_ID.PanelAddStudentPop) then
            UIMgr.Open(VIEW_ID.PanelAddStudentPop,self.bFindMas, true)
        end
    end)

    UIHelper.BindUIEvent(self.BtnDirectMaster, EventType.OnClick, function ()
        if self.tbMyDirectMaster and self.tbMyDirectMaster[1] then
            self:UpdateSelectedMaster(self.tbMyDirectMaster[1])
        else
            self:GotoFindMas(1)
        end
    end)

    for k, v in ipairs(self.tbFindMaster) do
        if k ~= 1 then
            UIHelper.BindUIEvent(self.tbFindMaster[k], EventType.OnClick, function ()
                if self.tbMyMaster and #self.tbMyMaster >= k - 1 then
                    self:UpdateSelectedMaster(self.tbMyMaster[k-1])
                else
                    self:GotoFindMas(k)
                end
            end)
        end
    end

    for k, v in ipairs(self.tbFindMasterEmpty) do
        UIHelper.BindUIEvent(self.tbFindMasterEmpty[k], EventType.OnClick, function ()
            self:GotoFindMas()
        end)
    end

    UIHelper.BindUIEvent(self.BtnApprentice, EventType.OnClick, function ()
        self:GotoFindMas()
    end)

    UIHelper.BindUIEvent(self.BtnStudent, EventType.OnClick, function ()
        self:GotoFindApp()
    end)

    UIHelper.BindUIEvent(self.BtnStageStore, EventType.OnClick, function ()
        ShopData.OpenSystemShopGroup(1, 1184)
    end)

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

end

function UIApprenticeNewView:RegEvent()
    --Event.Reg(self, EventType.XXX, func)
    --获得师父列表
    Event.Reg(self, "ON_GET_MENTOR_LIST", function (dwDstPlayerID, MentorList, bGradute)
        if dwDstPlayerID == g_pClientPlayer.dwID then
            self.tbMyMaster = MentorList or {}
            self.bGraduate = false
            if not bGradute and #self.tbMyMaster == 0 then
                self.bGraduate = true
                self.tbMyMaster = {}
            else
                table.sort(self.tbMyMaster, function (a, b) return a.nCreateTime < b.nCreateTime end)
            end
        end
        self.tbMyMaster = FellowshipData.GetMyMasterList(self.tbMyMaster or {}, false)

        self:UpdateMasterList()
        self:UpdateMasterNum()
        self:UpdateAppNum()
        self:UpdateFindBtnState()
    end)

    --获得亲传师父列表
    Event.Reg(self, "ON_GET_DIRECT_MENTOR_LIST", function (dwPlayerID,aMyDirectMaster)
        if g_pClientPlayer.dwID == dwPlayerID then
            self.tbMyDirectMaster = aMyDirectMaster
            table.sort(self.tbMyDirectMaster, function (a, b) return a.nCreateTime < b.nCreateTime end)
        end
        self.tbMyDirectMaster = FellowshipData.GetMyMasterList(self.tbMyDirectMaster or {}, true)

        self:UpdateMasterList()
        self:UpdateMasterNum()
        self:UpdateAppNum()
        self:UpdateFindBtnState()
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

        self:UpdateMasterList()
        self:UpdateMasterNum()
        self:UpdateAppNum()
        self:UpdateFindBtnState()
        self:UpdateMentorAward()
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

        self:UpdateMasterList()
        self:UpdateMasterNum()
        self:UpdateAppNum()
        self:UpdateFindBtnState()
    end)

    --取角色亲传师徒权限
    Event.Reg(self,"ON_GET_DIRECT_MENTOR_RIGHT",function (bCanBeDirectMentor, bCanBeDirectApprentice)
        self.bCanBeDirectMentor = bCanBeDirectMentor
        self.bCanBeDirectApprentice = bCanBeDirectApprentice
    end)

    --取账号传师徒权限
    Event.Reg(self,"ON_IS_ACCOUNT_DIRECT_APPRENTICE",function (bApprentice)
        self.bAccountDirectMentor = not bApprentice
        self:UpdateMasterNum()
        self:UpdateAppNum()

        if self.bAccountDirectMentor then
            UIHelper.SetString(self.LableCut,"当前账号身份：亲传师父")
        else
            UIHelper.SetString(self.LableCut,"当前账号身份：亲传徒弟")
        end
        RemoteCallToServer("OnIsFreeToDirectApprentice")
        UIHelper.SetVisible(self.ImgTeacher, self.bAccountDirectMentor)
        UIHelper.SetVisible(self.ImgStudent, not self.bAccountDirectMentor)
        UIHelper.LayoutDoLayout(self.LayoutMessage1)
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

    Event.Reg(self, "UPDATE_MENTORAWARD", function (arg0)
        self:UpdateMentorAward()
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

    Event.Reg(self, "ON_SYNC_MENTOR_DATA", function ()
        self:UpdateMasterNum()
        self:UpdateFindBtnState()
    end)

    Event.Reg(self,"ON_SYNC_MAX_APPRENTICE_NUM",function ()
        self:UpdateAppNum()
        self:UpdateFindBtnState()
    end)

    Event.Reg(self, "ON_PUSH_MENTOR_NOTIFY", function ()
        self.nFindIndex = 1
        self:UpdateFindMasterList()
        self:UpdateFindBtnState()
    end)

    Event.Reg(self, "ON_PUSH_APPRENTICE_NOTIFY", function ()
        self.nFindIndex = 1
        self:UpdateFindMasterList()
        self:UpdateFindBtnState()
    end)

    Event.Reg(self, "ON_PUSH_MENTOR_NOTIFY_BY_FORCEID", function ()
        self.nFindIndex = 1
        self:UpdateFindMasterList()
    end)

    Event.Reg(self, "ON_PUSH_APPRENTICE_NOTIFY_BY_FORCEID", function ()
        self.nFindIndex = 1
        self:UpdateFindMasterList()
    end)

    Event.Reg(self,EventType.OnSelectedPlayerMessage,function (nIndex,bMentor)
        if self.bFindMas == bMentor then
            self.nFindIndex = nIndex
            self:UpdateSelectedInfo()
        end
    end)

    Event.Reg(self, EventType.OnFilter, function(szKey, tbSelected)
        if szKey == FilterDef.Apprentice.Key then
            self.nForceID = tFilter2Force[tbSelected[1][1]]
            self.nCampID = tFilter2CampID[tbSelected[2][1]]
            -- if self.bFindMas then
                ApplyMentorPushList(false, self.nCampID, self.nForceID)
            -- else
                ApplyApprenticePushList(false, self.nCampID, self.nForceID)
            -- end
        end

        local bDefault = self.nForceID == -1 and self.nCampID == -1
        UIHelper.SetSpriteFrame(self.ImgScreen, bDefault and ShopData.szScreenImgDefault or ShopData.szScreenImgActiving)
    end)

    --发布收徒结果
    Event.Reg(self, "ON_REGISTER_MENTOR_RESULT", function (nResultCode)
        if nResultCode == 1 then
            TipsHelper.ShowNormalTip(g_tStrings.MENTOR_MSG.ON_SEEK_APPRENTICE_YELL_SUCESS)
            ApplyApprenticePushList(false, -1, self.nForceID)
            ApplyMentorPushList(false, -1, self.nForceID)
        else
            FellowshipData.dwFindApp = 0
            TipsHelper.ShowNormalTip(g_tStrings.MENTOR_MSG.ON_SEEK_APPRENTICE_YELL_FAIL)
        end
    end)

    --发布拜师结果
    Event.Reg(self, "ON_REGISTER_APPRENTICE_RESULT", function (nResultCode)
        if nResultCode == 1 then
            TipsHelper.ShowNormalTip(g_tStrings.MENTOR_MSG.ON_SEEK_MENTOR_YELL_SUCESS)
            ApplyApprenticePushList(false, -1, self.nForceID)
            ApplyMentorPushList(false, -1, self.nForceID)
        else
            FellowshipData.dwFindMas = 0
            TipsHelper.ShowNormalTip(g_tStrings.MENTOR_MSG.ON_SEEK_MENTOR_YELL_FAIL)
        end
    end)

    Event.Reg(self, EventType.OnSelectedAppprenticeMessage, function (tIndex)
        if self.bSelectedTog == tTogIndex.nMyMaster then
            for k, v in ipairs(self.tbFindMaster) do
                if UIHelper.GetSelected(self.tbFindMaster[k]) then
                    if k == 1 then
                        if tIndex[1] then
                            self:UpdateAppprenticeMessage(self.tbMyDirectMaster[1].aDirectApprentice[tIndex[2]], FellowshipData.tbRelationType.nSameApp)
                        else
                            self:UpdateAppprenticeMessage(self.tbMyDirectMaster[1].aApprentice[tIndex[2]], FellowshipData.tbRelationType.nSameApp)
                        end
                    else
                        if tIndex[1] then
                            self:UpdateAppprenticeMessage(self.tbMyMaster[k - 1].aDirectApprentice[tIndex[2]], FellowshipData.tbRelationType.nSameApp)
                        else
                            self:UpdateAppprenticeMessage(self.tbMyMaster[k - 1].aApprentice[tIndex[2]], FellowshipData.tbRelationType.nSameApp)
                        end
                    end
                end
            end
        elseif self.bSelectedTog == tTogIndex.nMyApprentice then
            if tIndex[1] then
                if self.tbMyDirectApprentice[tIndex[2]] then
                    self:UpdateAppprenticeMessage(self.tbMyDirectApprentice[tIndex[2]], FellowshipData.tbRelationType.nApprentice)
                else
                    self:GotoFindApp()
                end

            else
                if self.tbMyApprentice[tIndex[2]] then
                    self:UpdateAppprenticeMessage(self.tbMyApprentice[tIndex[2]], FellowshipData.tbRelationType.nApprentice)
                else
                    self:GotoFindApp()
                end
            end
        end
    end)

    Event.Reg(self, EventType.OnUpdateFellowShip, function ()
        self:UpdateMasterList()
    end)

    Event.Reg(self, EventType.OnMentorRecall, function ()
        --这里刷新相反的
        if self.bFindMas then --刷新拜师列表
            ApplyApprenticePushList(false, -1, self.nForceID)
        else --刷新收徒列表
            ApplyMentorPushList(false, -1, self.nForceID)
        end
    end)
end

function UIApprenticeNewView:UnRegEvent()
    --Event.UnReg(self, EventType.XXX)
end






-- ----------------------------------------------------------
-- Please write your own code below  ↓↓↓
-- ----------------------------------------------------------

function UIApprenticeNewView:InitPageData()
    self.tbMyMaster = {}
    self.tbMyDirectMaster = {}
    self.tbMyApprentice = {}
    self.tbMyDirectApprentice = {}
    self.nFindIndex = 1
    self.nCampID = -1
    self.nForceID = -1

    self.bFindMas = true
    self.bHasInitCheckPage = false

    local nSizeW = UIHelper.GetWidth(self.ScrollViewApprenticeList1)
    self.nLayoutMaxNum = math.floor(nSizeW/112)

    UIHelper.AddPrefab(PREFAB_ID.WidgetCoin, self.WidgetPVPMoney, CurrencyType.MentorAward)
    self:UpdateMentorAward()
    -- UIHelper.SetString(self.LabelMentorNum, tostring(g_pClientPlayer.nMentorAward) .." / ".. tostring(g_pClientPlayer.GetMaxMentorAward()))

    local tbFilterDefSelected = FilterDef.Apprentice.tbRuntime
    if tbFilterDefSelected then
        tbFilterDefSelected[1][1] = 1
        tbFilterDefSelected[2][1] = 1
    end
end

function UIApprenticeNewView:UpdateMentorAward()
    local nValue = g_pClientPlayer.GetMentorAwardRemainSpace()
    UIHelper.SetString(self.LableMoneyMessage, string.format(g_tStrings.MENTOR_VALUE_DESCRIBE, tostring(g_pClientPlayer.nAcquiredMentorValue), tostring(nValue)))
    UIHelper.LayoutDoLayout(self.WIdgetRightTop)
end

function UIApprenticeNewView:UpdatePageInfo()
    UIHelper.SetVisible(self.WidgetListBg, self.bSelectedTog ~= tTogIndex.nFinds)
    UIHelper.SetVisible(self.WidgetAnchorMid, self.bSelectedTog ~= tTogIndex.nFinds)
    UIHelper.SetVisible(self.LableMoneyMessage, self.bSelectedTog ~= tTogIndex.nFinds)
    UIHelper.SetVisible(self.ImgLeftLine, self.bSelectedTog ~= tTogIndex.nReward)
    UIHelper.SetVisible(self.ImgRightBg, self.bSelectedTog ~= tTogIndex.nReward)

    for k, v in ipairs(self.tbWidgetbg) do
        UIHelper.SetVisible(v, self.bSelectedTog == tTogIndex.nMyMaster or self.bSelectedTog == tTogIndex.nMyApprentice)
    end

    for k, v in ipairs(self.tbWidgetFind) do
        UIHelper.SetVisible(v, self.bSelectedTog == tTogIndex.nFinds)
    end

    for k, v in ipairs(self.tbWidgetReward) do
        UIHelper.SetVisible(v, self.bSelectedTog == tTogIndex.nReward)
    end

    for k, v in ipairs(self.tbWidgetMaster) do
        UIHelper.SetVisible(v, self.bSelectedTog == tTogIndex.nMyMaster)
    end

    UIHelper.SetVisible(self.ScrollViewApprenticeList2, self.bSelectedTog == tTogIndex.nMyApprentice)
    UIHelper.LayoutDoLayout(self.WIdgetRightTop)
end

function UIApprenticeNewView:UpdateEmptyInfo()
    if self.bSelectedTog == tTogIndex.nMyMaster then
        for k, v in ipairs(self.tbWidgetMasterEmpty) do
            UIHelper.SetVisible(v, #self.tbMyDirectMaster == 0 and #self.tbMyMaster == 0)
        end

        for k, v in ipairs(self.tbWidgetMasterNotEmpty) do
            UIHelper.SetVisible(v, #self.tbMyDirectMaster ~= 0 or #self.tbMyMaster ~= 0)
        end
    elseif self.bSelectedTog == tTogIndex.nMyApprentice then
        UIHelper.SetVisible(self.WidgetApprenticeListEmpty, #self.tbMyApprentice == 0 and #self.tbMyDirectApprentice == 0)
        UIHelper.SetVisible(self.ImgTipBg2, #self.tbMyDirectApprentice ~= 0 or #self.tbMyApprentice ~= 0)
        UIHelper.SetVisible(self.ImgRightBg, #self.tbMyDirectApprentice ~= 0 or #self.tbMyApprentice ~= 0)
        UIHelper.SetVisible(self.WidgetAppprenticeMessage, #self.tbMyDirectApprentice ~= 0 or #self.tbMyApprentice ~= 0)
    end

    UIHelper.SetVisible(self.LableApprentice, self.bSelectedTog == tTogIndex.nMyMaster)
    UIHelper.SetVisible(self.LableStudent, self.bSelectedTog == tTogIndex.nMyApprentice)
    UIHelper.SetVisible(self.BtnApprentice, self.bSelectedTog == tTogIndex.nMyMaster)
    UIHelper.SetVisible(self.BtnStudent, self.bSelectedTog == tTogIndex.nMyApprentice)
    UIHelper.SetVisible(self.WidgetAnchorApprentice1, false)
end

function UIApprenticeNewView:ApplyInfo()
    FellowshipData.ApplyMasterInfo()
    ApplyApprenticePushList(false, self.nCampID, self.nForceID)
	ApplyMentorPushList(false, self.nCampID, self.nForceID)
end

function UIApprenticeNewView:UpdateMasterList()
    self:UpdateSelected()
    self:UpdateEmptyInfo()

    if self.bSelectedTog == tTogIndex.nMyMaster then
        self:UpdateMyMaster()
    elseif self.bSelectedTog == tTogIndex.nMyApprentice then
        self:UpdateMyApprentice()
    elseif self.bSelectedTog == tTogIndex.nFinds then
        self:UpdateFindMasterList()
    end
end

function UIApprenticeNewView:UpdateSelected()
    if not self.bHasInitCheckPage then
        if (self.tbMyDirectMaster and #self.tbMyDirectMaster ~= 0 ) or (self.tbMyMaster and #self.tbMyMaster ~= 0) then
            self.bHasInitCheckPage = true
            UIHelper.SetSelected(self.tbTogList[tTogIndex.nMyMaster], true)
        elseif (self.tbMyDirectApprentice and #self.tbMyDirectApprentice ~= 0 ) or (self.tbMyApprentice and #self.tbMyApprentice ~= 0) then
            self.bHasInitCheckPage = true
            UIHelper.SetSelected(self.tbTogList[tTogIndex.nMyApprentice], true)
        end
    end
end

function UIApprenticeNewView:UpdateFindMasterList()
    if self.bFindMas then
        self:UpdateFindMaster()
        self:UpdateMasterNum()
    else
        self:UpdateFindApprentice()
        self:UpdateAppNum()
    end

    UIHelper.SetVisible(self.WidgetAnchorMiddleM, self.bFindMas)
    UIHelper.SetVisible(self.WidgetAnchorMiddleA, (not self.bFindMas))
    UIHelper.SetVisible(self.WidgetAddMessage, false)
    UIHelper.SetVisible(self.LabelApprenticeAdd, self.bFindMas)
    UIHelper.SetVisible(self.LabelApprenticeMy, self.bFindMas)
    UIHelper.SetVisible(self.LabelStudentsAdd, not self.bFindMas)
    UIHelper.SetVisible(self.LabelStudentsMy, not self.bFindMas)

    Event.Dispatch(EventType.OnSelectChangedMentor, self.nFindIndex, self.bFindMas)
end

function UIApprenticeNewView:UpdateFindMaster()
    UIHelper.RemoveAllChildren(self.ScollViewListM)
    self.tPushMentorList = GetPushMentorList() or {} -- 只能获得此时在线的列表

    for k, v in pairs(self.tPushMentorList) do
        UIHelper.AddPrefab(PREFAB_ID.WidgetPlayerMessage,self.ScollViewListM,k,true,v)
	end

    UIHelper.SetVisible(self.WidgetAnchorMiddleEmptyM, #self.tPushMentorList == 0)
    UIHelper.SetVisible(self.WidgetApprenticeListEmpty, #self.tPushMentorList == 0)

    UIHelper.SetVisible(self.ImgRightBg, #self.tPushMentorList ~= 0)
    UIHelper.SetVisible(self.BtnApprentice, false)
    UIHelper.SetVisible(self.BtnStudent, false)
    UIHelper.SetVisible(self.LableApprentice, true)
    UIHelper.SetVisible(self.LableStudent, false)

    UIHelper.SetVisible(self.ScollViewListM, #self.tPushMentorList ~= 0)
    UIHelper.ScrollViewDoLayoutAndToTop(self.ScollViewListM)
end

function UIApprenticeNewView:UpdateFindApprentice()
    UIHelper.RemoveAllChildren(self.ScollViewListA)
    self.tPushApprenticeList = GetPushApprenticeList() or {} -- 只能获得此时在线的列表

	for k, v in pairs(self.tPushApprenticeList) do
        UIHelper.AddPrefab(PREFAB_ID.WidgetPlayerMessage,self.ScollViewListA,k,false,v)
	end

    UIHelper.SetVisible(self.WidgetAnchorMiddleEmptyA, #self.tPushApprenticeList == 0)
    UIHelper.SetVisible(self.WidgetApprenticeListEmpty, #self.tPushApprenticeList == 0)

    UIHelper.SetVisible(self.ImgRightBg, #self.tPushApprenticeList ~= 0)
    UIHelper.SetVisible(self.BtnApprentice, false)
    UIHelper.SetVisible(self.BtnStudent, false)
    UIHelper.SetVisible(self.LableApprentice, false)
    UIHelper.SetVisible(self.LableStudent, true)

    UIHelper.SetVisible(self.ScollViewListA, #self.tPushApprenticeList ~= 0)
    UIHelper.ScrollViewDoLayoutAndToTop(self.ScollViewListA)
end

function UIApprenticeNewView:UpdateMasterNum()
    local nCanFindDirectMasterNum = FellowshipData.GetFindDirectMasterData(self.bAccountDirectMentor, self.tbMyDirectMaster or {})
    local nCanFindMasterNum = FellowshipData.GetFindMasterData(self.tbMyDirectApprentice or {}, self.tbMyApprentice or {}, self.tbMyMaster or {}, self.bGraduate)

    local bCanFindMaster = FellowshipData.m_FindMasterErrorCode == ERROR_CODE.NORMAL or FellowshipData.m_FindDirectMasterErrorCode == ERROR_CODE.NORMAL
    UIHelper.SetVisible(self.LayoutTipsM, bCanFindMaster)
    UIHelper.SetVisible(self.LableTipsNotFindMaster, not bCanFindMaster)
    UIHelper.SetString(self.LableTipsNotFindMaster, g_tStrings.tFindMasterErrorCode[FellowshipData.m_FindMasterErrorCode])
    UIHelper.SetString(self.LableDirectMasterNum, nCanFindDirectMasterNum)
    UIHelper.SetString(self.LableMasterNum, nCanFindMasterNum)

    if self.bFindMas then
        UIHelper.SetButtonState(self.BtnApprenticeAdd, (nCanFindMasterNum > 0 or nCanFindDirectMasterNum > 0) and BTN_STATE.Normal or BTN_STATE.Disable)
    end
end

function UIApprenticeNewView:UpdateAppNum()
    local nCanFindDirectAppNum = FellowshipData.GetFindDirectApprenticeData(self.bAccountDirectMentor, self.tbMyDirectApprentice or {})
    local nCanFindAppNum = FellowshipData.GetFindApprenticeData(self.tbMyMaster or {}, self.tbMyApprentice or {})

    local bCanFindApprentice = FellowshipData.m_FindAppErrorCode == ERROR_CODE.NORMAL or FellowshipData.m_FindDirectAppErrorCode == ERROR_CODE.NORMAL
    UIHelper.SetVisible(self.LayoutTipsA, bCanFindApprentice)
    UIHelper.SetVisible(self.LableTipsNotFindApp,not bCanFindApprentice)
    if FellowshipData.m_FindAppErrorCode ~= ERROR_CODE.NORMAL then
        UIHelper.SetString(self.LableTipsNotFindApp, g_tStrings.tFindAppErrorCode[FellowshipData.m_FindAppErrorCode])
    else
        UIHelper.SetString(self.LableTipsNotFindApp, g_tStrings.tFindDirectAppErrorCode[FellowshipData.m_FindAppErrorCode])
    end
    UIHelper.SetString(self.LableDirectAppNum, nCanFindDirectAppNum)
    UIHelper.SetString(self.LableFindAppNum, nCanFindAppNum)

    if not self.bFindMas then
        UIHelper.SetButtonState(self.BtnApprenticeAdd, (nCanFindAppNum > 0 or nCanFindDirectAppNum > 0) and BTN_STATE.Normal or BTN_STATE.Disable)
    end
end

function UIApprenticeNewView:UpdateSelectedInfo()
    UIHelper.SetVisible(self.WidgetAddMessage, false)

    local tbList
    if self.bFindMas then
        tbList = self.tPushMentorList
    else
        tbList = self.tPushApprenticeList
    end
    local table = tbList[self.nFindIndex]

    local tAddMessageScript = UIHelper.GetBindScript(self.WidgetAddMessage)
    if tAddMessageScript and table then
        UIHelper.SetVisible(self.WidgetAddMessage, true)
        tAddMessageScript:SetMessageInfo(table, self.bFindMas)
    end
end

function UIApprenticeNewView:UpdateMyMaster()
    self:UpdateMasterBtn()
    if self.tbMyDirectMaster and self.tbMyDirectMaster[1] then
        UIHelper.SetSelected(self.BtnDirectMaster, true)
        self:UpdateSelectedMaster(self.tbMyDirectMaster[1])
    elseif self.tbMyMaster and self.tbMyMaster[1] then
        UIHelper.SetSelected(self.tbFindMaster[2], true)
        self:UpdateSelectedMaster(self.tbMyMaster[1])
    end
end

function UIApprenticeNewView:UpdateMasterBtn()
    if self.tbMyDirectMaster and #self.tbMyDirectMaster ~= 0 then
        UIHelper.RemoveAllChildren(self.WidgetDirectMasterHead_108)
        local headScript = UIHelper.AddPrefab(PREFAB_ID.WidgetHead_108, self.WidgetDirectMasterHead_108)
        local tInfo = self.tbMyDirectMaster[1]
        if headScript then
            local tSocialInfo = FellowshipData.tApplySocialList[tInfo.dwID] or FellowshipData.GetSocialInfo(tInfo.dwID) or {}
            headScript:SetHeadInfo(tInfo.dwID, tSocialInfo.MiniAvatarID or 0, tInfo.nRoleType or 0, tInfo.dwForceID or 0)
            headScript:SetOfflineState(tInfo.bOnLine == false)
            UIHelper.SetTouchEnabled(headScript.BtnHead, false)
        end
        UIHelper.SetVisible(self.ImgDirectMasterHeadEmpty, false)
        if tInfo.bDelete then
            UIHelper.SetString(self.LableMasterName, tInfo.szName)
            UIHelper.SetString(self.LableMasterSelect, tInfo.szName)
        else
            UIHelper.SetString(self.LableMasterName, UIHelper.GBKToUTF8(tInfo.szName))
            UIHelper.SetString(self.LableMasterSelect, UIHelper.GBKToUTF8(tInfo.szName))
        end
    end

    if self.tbMyMaster and #self.tbMyMaster ~= 0 then
        for k = 1, 3, 1 do
            UIHelper.RemoveAllChildren(self.tbWidgetMasterHead[k])
            local tInfo = self.tbMyMaster[k]
            if tInfo then
                local headScript = UIHelper.AddPrefab(PREFAB_ID.WidgetHead_108, self.tbWidgetMasterHead[k])
                if headScript then
                    local tSocialInfo = FellowshipData.tApplySocialList[tInfo.dwID] or FellowshipData.GetSocialInfo(tInfo.dwID) or {}
                    headScript:SetHeadInfo(tInfo.dwID, tSocialInfo.MiniAvatarID or 0, tInfo.nRoleType or 0, tInfo.dwForceID or 0)
                    headScript:SetOfflineState(tInfo.bOnLine == false)
                    UIHelper.SetTouchEnabled(headScript.BtnHead, false)
                end
                UIHelper.SetVisible(self.tbImgMasterHeadEmpty[k], false)
                if tInfo.bDelete then
                    UIHelper.SetString(self.tbWidgetMasterName[k], tInfo.szName)
                    UIHelper.SetString(self.tbWidgetMasterNameSelect[k], tInfo.szName)
                else
                    UIHelper.SetString(self.tbWidgetMasterName[k], UIHelper.GBKToUTF8(tInfo.szName))
                    UIHelper.SetString(self.tbWidgetMasterNameSelect[k], UIHelper.GBKToUTF8(tInfo.szName))
                end
            else
                UIHelper.SetString(self.tbWidgetMasterName[k], "")
                UIHelper.SetString(self.tbWidgetMasterNameSelect[k], "")
                UIHelper.SetVisible(self.tbImgMasterHeadEmpty[k], true)
            end
        end
    end
end

function UIApprenticeNewView:UpdateMyApprentice()
    UIHelper.SetString(self.LableTip02, "我的徒弟")
    UIHelper.SetVisible(self.ImgTipBg2, false)
    self:UpdateMyApprenticeList(self.tbMyApprentice)
end

function UIApprenticeNewView:UpdateMyApprenticeList(tList1)
    UIHelper.RemoveAllChildren(self.ScrollViewApprenticeList2)
    local bSelected = false

    for i = 1, DIRECT_APP_MAX_NUM, 1 do
        bSelected = (i == 1) and (#self.tbMyDirectApprentice ~= 0)
        if self.tbMyDirectApprentice[i] then
            self:UpdateApprenticePrefab(true, self.tbMyDirectApprentice[i], i, self.ScrollViewApprenticeList2, PREFAB_ID.WidgetMasterTip, bSelected)
        else
            self:UpdateApprenticePrefab(true, self.tbMyDirectApprentice[i], i, self.ScrollViewApprenticeList2, PREFAB_ID.WidgetMasterEmptyTip, bSelected)
        end
    end

    for i = 1, NORMAL_APP_MAX_NUM, 1 do
        bSelected = (i == 1) and (#self.tbMyDirectApprentice == 0) and (#tList1 ~= 0)
        if tList1[i] then
            self:UpdateApprenticePrefab(false, tList1[i], i, self.ScrollViewApprenticeList2, PREFAB_ID.WidgetMasterTip, bSelected)
        else
            self:UpdateApprenticePrefab(false, tList1[i], i, self.ScrollViewApprenticeList2, PREFAB_ID.WidgetMasterEmptyTip, bSelected)
        end
    end

    UIHelper.ScrollViewDoLayoutAndToTop(self.ScrollViewApprenticeList2)

    if self.tbMyDirectApprentice[1] then
        self:UpdateAppprenticeMessage(self.tbMyDirectApprentice[1], FellowshipData.tbRelationType.nApprentice)
    elseif self.tbMyApprentice[1] then
        self:UpdateAppprenticeMessage(self.tbMyApprentice[1], FellowshipData.tbRelationType.nApprentice)
    end
end

function UIApprenticeNewView:UpdateApprenticeList(tList1, tList2)
    UIHelper.RemoveAllChildren(self.ScrollViewApprenticeList1)
    UIHelper.RemoveAllChildren(self.LayoutApprenticeList1)

    local nCount = 0
    if tList1 then
        nCount = nCount + #tList1
    end
    if tList2 then
        nCount = nCount + #tList2
    end

    local parent = self.LayoutApprenticeList1
    if nCount > self.nLayoutMaxNum then
        parent = self.ScrollViewApprenticeList1
    end

    self:UpdateApprentice(tList1, tList2, parent, PREFAB_ID.WidgetApprenticeTip)

    UIHelper.SetVisible(self.LayoutApprenticeList1, nCount <= self.nLayoutMaxNum)
    UIHelper.SetVisible(self.ScrollViewApprenticeList1, nCount > self.nLayoutMaxNum)
    UIHelper.LayoutDoLayout(self.LayoutApprenticeList1)
    UIHelper.ScrollViewDoLayoutAndToTop(self.ScrollViewApprenticeList1)
end

function UIApprenticeNewView:UpdateApprentice(tList1, tList2, parent, nPrefabID)
    if tList1 and #tList1 ~= 0 then
        for k, v in ipairs(tList1) do
            if tList1 and #tList1 ~= 0 then
                self:UpdateApprenticePrefab(true, v, k, parent, nPrefabID)
            else
                self:UpdateApprenticePrefab(false, v, k, parent, nPrefabID)
            end
        end
    end

    if tList2 and #tList2 ~= 0 then
        for k, v in ipairs(tList2) do
            self:UpdateApprenticePrefab(false, v, k, parent, nPrefabID)
        end
    end
end

function UIApprenticeNewView:UpdateApprenticePrefab(bDirect, tInfo, nIndex, parent, nPrefabID, bSelected)
    local scriptView = UIHelper.AddPrefab(nPrefabID, parent)
    if scriptView then
        scriptView:SetAppInfo(tInfo, {bDirect, nIndex})
        if bSelected then
            UIHelper.SetSelected(scriptView.TogApprenticeTip, true)
        end
    end
end

function UIApprenticeNewView:UpdateAppprenticeMessage(Info, nRelationType)
    local tAddMessageScript = UIHelper.GetBindScript(self.WidgetAppprenticeMessage)
    if tAddMessageScript and Info then
        UIHelper.SetVisible(self.WidgetAppprenticeMessage, true)
        tAddMessageScript:SetAppprenticeMessageInfo(Info, nRelationType)
    end
end

function UIApprenticeNewView:UpdateSelectedMaster(tbMyMaster)
    if tbMyMaster.bDelete then
        UIHelper.SetString(self.LableTip02, tbMyMaster.szName.."师门")
    else
        UIHelper.SetString(self.LableTip02, UIHelper.GBKToUTF8(tbMyMaster.szName).."师门")
    end
    UIHelper.SetVisible(self.ImgTipBg2, true)

    UIHelper.SetVisible(self.WidgetAnchorApprentice1, (not tbMyMaster.aDirectApprentice) and (not tbMyMaster.aApprentice) )
    self:UpdateApprenticeList(tbMyMaster.aDirectApprentice, tbMyMaster.aApprentice)
    self:UpdateAppprenticeMessage(tbMyMaster, FellowshipData.tbRelationType.nMaster)
end

function UIApprenticeNewView:GotoFindMas(nIndex)
    self.bFindMas = true
    UIHelper.SetSelected(self.tbTogList[tTogIndex.nFinds], true)
    UIHelper.SetSelected(self.TogNavigation031, true)

    if nIndex then
        UIHelper.SetSelected(self.tbFindMaster[nIndex], false)
    end

    self:UpdateFindBtnState()
end

function UIApprenticeNewView:GotoFindApp(nIndex)
    self.bFindMas = false
    UIHelper.SetSelected(self.tbTogList[tTogIndex.nFinds], true)
    Timer.AddFrame(self, 1, function ()
        UIHelper.SetSelected(self.TogNavigation032, true)
    end)

    self:UpdateFindBtnState()
end

function UIApprenticeNewView:UpdateFindBtnState()
    if self.bSelectedTog == tTogIndex.nFinds then
        if self.bFindMas then
            local bNeedMentorInfo = JudgeNeedMentor()
            UIHelper.SetVisible(self.BtnApprenticeAdd, bNeedMentorInfo ~= 1)
            UIHelper.SetVisible(self.BtnApprenticeMy, bNeedMentorInfo == 1)
        else
            local bNeedAppInfo = JudgeNeedApprentice()
            UIHelper.SetVisible(self.BtnApprenticeAdd, bNeedAppInfo ~= 1)
            UIHelper.SetVisible(self.BtnApprenticeMy, bNeedAppInfo == 1)
        end
    end
end

function UIApprenticeNewView:CheckFindBtnCD()
    local dwNow = GetTickCount()
    local bCanPublish = false
    if self.bFindMas  then
        if dwNow - FellowshipData.dwFindMas > 60 * 1000 then
            bCanPublish = true
        end
    else
        if dwNow - FellowshipData.dwFindApp > 60 * 1000 then
            bCanPublish = true
        end
    end

    if not bCanPublish then
        local szTip
        if self.bFindMas then
            szTip = g_tStrings.MENTOR_MSG.ON_SEEK_MENTOR_YELL_LIMIT
        else
            szTip = g_tStrings.MENTOR_MSG.ON_SEEK_APPRENTICE_YELL_LIMIT
        end

        TipsHelper.ShowNormalTip(szTip)
    end

    return bCanPublish
end

return UIApprenticeNewView