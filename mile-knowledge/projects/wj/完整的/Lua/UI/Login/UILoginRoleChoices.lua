
-- ---------------------------------------------------------------------------------
-- Author: Unknown
-- Name: UILoginRoleChoices
-- Date: 2022-11-09 11:43:53
-- Desc: ?
-- ---------------------------------------------------------------------------------

local UILoginRoleChoices = class("UILoginRoleChoices")

local AUTO_KICK_TIME = 15 * 60 --15分钟
local m_OnDetailRoleInfo = {}
function UILoginRoleChoices:OnEnter(szRoleName)
    if not self.bInit then
        self:Init(szRoleName)
        self:RegEvent()
        self:BindUIEvent()
        self.bInit = true
    end

    LoginMgr.StartAutoKick(AUTO_KICK_TIME)
end

function UILoginRoleChoices:OnExit()
    self.bInit = false
    self:UnRegEvent()

    if self.nDownloadDynamicID then
        PakDownloadMgr.ReleaseDynamicPakInfo(self.nDownloadDynamicID)
        self.nDownloadDynamicID = nil
    end

    WaitingTipsData.RemoveWaitingTips("LoadModel")
    LoginMgr.ClearAutoKick()
    self:UnLoadSceneSfx()
end

function UILoginRoleChoices:BindUIEvent()
    local function BindUIEvent(btn, nEventType, fnCallback)
        UIHelper.BindUIEvent(btn, nEventType, function()
            --避免同时按Enter和点按钮的情况
            if LoginMgr.IsWaiting() or not UIHelper.GetHierarchyVisible(btn) then
                return
            end
            if fnCallback then
                fnCallback()
            end
        end)
    end

    BindUIEvent(self.BtnClose, EventType.OnClick, function()
        LoginMgr.BackToLogin(true)
    end)

    BindUIEvent(self.BtnDelete, EventType.OnClick, function()
        self:DeleteRole()
    end)

    BindUIEvent(self.BtnStart, EventType.OnClick, function()
        self:EnterGame()
    end)

    BindUIEvent(self.BtnDefaultMap, EventType.OnClick, function()
        local dialog = UIHelper.ShowConfirm("是否返回无需下载资源的默认场景（侠客岛/百溪）？", function()
            self:EnterGame(true)
        end)
        dialog:SetConfirmButtonContent("返回默认场景")
    end)

    BindUIEvent(self.BtnServerChange, EventType.OnClick, function()
        self:OnServerChangeClick()
    end)


    BindUIEvent(self.BtnCompensate, EventType.OnClick, function()
        local bIsVisible = UIHelper.GetVisible(self.WidgetCompensateContent)
        UIHelper.SetVisible(self.WidgetCompensateContent, not bIsVisible)
    end)

    BindUIEvent(self.BtnShare, EventType.OnClick, function()
        self.nCaptureIndex = (self.nCaptureIndex or 0) + 1
        for k, v in pairs(self.tbShareHideWidget) do
            UIHelper.SetVisible(v, false)
        end
        UIHelper.SetVisible(self.WidgetShare, true)

        local moduleCamera = LoginMgr.GetModule(LoginModule.LOGIN_CAMERA)
        moduleCamera.SetCameraStatus(LoginCameraStatus.ROLE_CHOOSE_SHOW,m_OnDetailRoleInfo.nRoleType or 1)

        cc.utils:setIgnoreAgainCapture(true)
        local folder = GetStreamAdaptiveDirPath(UIHelper.GBKToUTF8(GetFullPath("dcim/")))
        local dt = TimeToDate(GetCurrentTime())
        CPath.MakeDir(folder)
        local fileName = string.format("%d_%04d%02d%02d%02d%02d%02d.png",self.nCaptureIndex,dt.year, dt.month, dt.day, dt.hour, dt.minute, dt.second)
        Timer.Add(self , 0.2 , function ()
            UIHelper.CaptureScreen(function (pRetTexture , pImage)
                if not UIMgr.GetView(VIEW_ID.PanelCameraPhotoShare) then
                    local shareScript = UIMgr.Open(VIEW_ID.PanelCameraPhotoShare , pRetTexture ,pImage , folder,fileName, function ()
                        for k, v in pairs(self.tbShareHideWidget) do
                            UIHelper.SetVisible(v, true)
                            UIHelper.SetVisible(self.WidgetShare, false)
                        end
                        moduleCamera.SetCameraStatus(LoginCameraStatus.ROLE_LIST,m_OnDetailRoleInfo.nRoleType or 1)
                    end,self.pMessageImage,true)
                    shareScript:SetLogoNotHide(true)
                    shareScript:SetPlayInfo(UIHelper.UTF8ToGBK(m_OnDetailRoleInfo.szRoleName) ,m_OnDetailRoleInfo.nRoleType , m_OnDetailRoleInfo.nForceID)
                end
            end, 1 , true)
        end)
    end)

    BindUIEvent(self.BtnH5, EventType.OnClick, function()
        BuildPresetData.OpenFreeUrl(m_OnDetailRoleInfo.szRoleName ,m_OnDetailRoleInfo.nRoleID , m_OnDetailRoleInfo.nForceID , m_OnDetailRoleInfo.nFreezeTime)
       -- WebUrl.OpenByID(37 , true , true , true)
    end)

    local WidgetAnchorRight = UIHelper.FindChildByName(self.WidgetShare , "WidgetAnchorRight")
    local WidgetAnchorRightBotom = UIHelper.FindChildByName(WidgetAnchorRight , "WidgetAnchorRightBotom")
    local ImgQRCode = UIHelper.FindChildByName(WidgetAnchorRightBotom , "ImgCode")
    UIHelper.SetVisible(ImgQRCode , AppReviewMgr.IsOpenShaderCode())
    UIHelper.SetSpriteFrame(ImgQRCode ,AppReviewMgr.GetShaderCodeImage() )
end

function UILoginRoleChoices:RegEvent()
    Event.Reg(self, EventType.Login_SelectServer, function(tbServer)
        if tbServer then
            self:UpdateServer(tbServer.szDisplayRegion, tbServer.szDisplayServer)
            CareerData.UpdateServerName(tbServer.szDisplayServer)
        end
    end)

    Event.Reg(self, "COMMON_CALL_BACK", function()
        if self.nLoadTimerID and arg0 == "GetSceneLoadingTaskCount" then
            local nTotalCount = tonumber(arg2);
            if nTotalCount <= 0 then
                self.nFinishCount = self.nFinishCount + 1;

                if self.nFinishCount > 10 then
                    WaitingTipsData.RemoveWaitingTips("LoadModel")
                    Timer.DelTimer(self, self.nLoadTimerID)
                    self.nLoadTimerID = nil
                end
            end
        end
    end)

    Event.Reg(self, EventType.OnEquipPakResourceDownload, function()
        self.moduleRoleList.UpdateRoleModel(self.nCurIndex)
        self:UpdateDownloadEquipRes(self.nCurIndex)
    end)

    Event.Reg(self, EventType.OnKeyboardDown, function(nKeyCode, szKeyName)
        if LoginMgr.IsWaiting() then
            return
        end

        if nKeyCode == cc.KeyCode.KEY_ENTER then
            if UIHelper.GetHierarchyVisible(self.BtnStart) and not UIMgr.IsViewOpened(VIEW_ID.PanelServerSelect) then
                self:EnterGame()
            end
        end
    end)
end

function UILoginRoleChoices:UnRegEvent()
    --Event.UnReg(self, EventType.XXX)
end


function UILoginRoleChoices:Init(szRoleName)
    UIHelper.SetOpacity(self.AniAll, 0)
    self:InitValues(szRoleName)
    self:UpdateServer()
    self:UpdateInfo()
    self:UpdateLayoutTime()

    --local bShowGanPei = PayData.IsPlayerMeetCompensationCondition()
    --UIHelper.SetVisible(self.BtnCompensate, bShowGanPei)
    UIHelper.SetVisible(self.BtnCompensate, false)
    UIHelper.SetRichText(self.LabelCompensate01, [[您的账号现享受“敢赔服务”资格，现在充值游戏时间可享受：
1）充值任意金额点卡可<color=#f0dc82>额外赠送2000分钟。（永久有效）</color>
2）在完成充值游戏时长的24小时内，如您对游戏品质不满意，可随时申请<color=#f0dc82>人民币100%退款</color>
精品诚意之作，邀您仗剑江湖！]])

    -- 如果时间不够了，提示充值
    local nMonthEndTime, nPointLeftTime, nDayLeftTime = Login_GetTimeOfFee()
    local nCurrentTime = Login_GetLoginTime()
    local nMonthLeftTime = nMonthEndTime - nCurrentTime

    if nMonthLeftTime >= 60 and nMonthLeftTime <= 172800 and nDayLeftTime == 0 and nPointLeftTime == 0 then
        RemindRecharge()
    elseif nDayLeftTime >= 60 and nDayLeftTime <= 172800 and nMonthLeftTime <= 0 and nPointLeftTime == 0 then
        RemindRecharge()
    elseif nPointLeftTime >= 60 and nPointLeftTime <= 18000 and nMonthLeftTime <= 0 and nDayLeftTime == 0 then
        RemindRecharge()
    end

    --资源下载
    local scriptDownload = UIHelper.GetBindScript(self.WidgetDownload)
    --scriptDownload:OnInitBasic()

    local tConfig = { bShowTips = true }
    scriptDownload:OnInitTotal(tConfig)

    self:CheckHadCreateRoleFaceCache()


    UIHelper.SetVisible(self.BtnShare , not AppReviewMgr.IsReview() )
    UIHelper.SetVisible(self.BtnH5 , false)
    UIHelper.LayoutDoLayout(self.LayoutBtn)
end

function UILoginRoleChoices:UpdateServer(szDisplayRegion, szDisplayServer)
    if not szDisplayRegion or not szDisplayServer then
        local tbServer = self.moduleServerList.GetSelectServer()
        if tbServer then
            szDisplayRegion = tbServer.szDisplayRegion
            szDisplayServer = tbServer.szDisplayServer
        end
    end

    szDisplayRegion = szDisplayRegion or ""
    szDisplayServer = szDisplayServer or ""
    UIHelper.SetString(self.LabelServerChange, szDisplayRegion .. "·" .. szDisplayServer)
    UIHelper.LayoutDoLayout(self.LayoutServre)
end

function UILoginRoleChoices:InitValues(szRoleName)
    self.moduleRoleList = LoginMgr.GetModule(LoginModule.LOGIN_ROLELIST)
    self.moduleServerList = LoginMgr.GetModule(LoginModule.LOGIN_SERVERLIST)

    local nSelectIndex = 1
    if szRoleName then
        nSelectIndex = self.moduleRoleList.GetRoleIndex(szRoleName)
    end
    self:SetCurRoleIndex(nSelectIndex or 1, true)
end


function UILoginRoleChoices:UpdateTogSelect()
    local nRoleCount = self.moduleRoleList.GetRoleCount()

    UIHelper.RemoveAllChildren(self.ScrollViewRoleList)
    self.LayoutSlectList = {}
    for nIndex = 1, nRoleCount do
        local tbRoleInfoList = self.moduleRoleList.GetRoleInfoList()
        local tbRoleInfo = tbRoleInfoList[nIndex]
        tbRoleInfo.nIndex = nIndex
        local scriptView = UIHelper.AddPrefab(PREFAB_ID.WidgetRoleCell, self.ScrollViewRoleList, tbRoleInfo, self, self.ToggleGroupRoleList)
        table.insert(self.LayoutSlectList, scriptView)
    end

    for nIndex = nRoleCount + 1, 3, 1 do
        UIHelper.AddPrefab(PREFAB_ID.WidgetCreateRoleCell, self.ScrollViewRoleList)
    end
    Timer.DelTimer(self, self.nTimerID)
    self.nTimerID = Timer.AddFrame(self, 1, function()
        self.LayoutSlectList[self.nCurIndex]:SetSelect(true)
        UIHelper.ScrollViewDoLayout(self.ScrollViewRoleList)
        UIHelper.ScrollToTop(self.ScrollViewRoleList)
    end)

    --初始化选中角色模型显示
    self:OnSelectRole(self.nCurIndex)
end



function UILoginRoleChoices:UpdateLayoutTime()
    do
        UIHelper.SetVisible(self.LayoutTime, false)
        return
    end

    --包月
    local nMonthEndTime = self.moduleRoleList.GetMonthEndTime()
    UIHelper.SetString(self.LabelMonthCard02, string.format("%d-%02d-%02d", nMonthEndTime.year, nMonthEndTime.month, nMonthEndTime.day))
    UIHelper.SetString(self.LabelMonthCard03, string.format("%02d:%02d", nMonthEndTime.hour, nMonthEndTime.minute))

    --点卡
    local szPointLeftTime = self.moduleRoleList.GetStringPointLeftTime()
    UIHelper.SetString(self.LabelTimeCard02, szPointLeftTime)
	if self.moduleRoleList.nPointLeftTime < 0 then
		UIHelper.SetColor(self.LabelTimeCard02, cc.c3b(255, 0, 0))
	end
    UIHelper.SetVisible(self.LabelTimeCard03, false)

    local nLastLoginYear, nLastLoginMonth, nLastLoginDay, nLastLoginHour, nLastLoginMinute = self.moduleRoleList.GetLastLoginTime()
    local szLastLoginTime1 = string.format("%d-%02d-%02d", nLastLoginYear, nLastLoginMonth, nLastLoginDay)--年月日
    local szLastLoginTime2 = string.format("%02d:%02d", nLastLoginHour, nLastLoginMinute)--时分
    UIHelper.SetString(self.LabelLastTimeLogin02, szLastLoginTime1)
    UIHelper.SetString(self.LabelLastTimeLogin03, szLastLoginTime2)

    local nLoginTime = self.moduleRoleList.GetLoginTime()
    local szLoginTime1 = string.format("%d-%02d-%02d", nLoginTime.year, nLoginTime.month, nLoginTime.day)--年月日
    local szLoginTime2 = string.format("%02d:%02d", nLoginTime.hour, nLoginTime.minute)--时分
    UIHelper.SetString(self.LabelThisTimeLogin02, szLoginTime1)
    UIHelper.SetString(self.LabelThisTimeLogin03, szLoginTime2)

    local nCurrentTime = GetCurrentTime()
    local nNumberMonthEndTime = DateToTime(nMonthEndTime.year, nMonthEndTime.month, nMonthEndTime.day, nMonthEndTime.hour, nMonthEndTime.minute, nMonthEndTime.second)
    UIHelper.SetVisible(self.WidgetMonthCard, nCurrentTime < nNumberMonthEndTime)

    local nPointLeftTime = self.moduleRoleList.GetNumberPointLeftTime()
    UIHelper.SetVisible(self.WidgetTimeCard, nPointLeftTime ~= 0)

    UIHelper.SetVisible(self.WidgetLastTimeSite, false)--目前没办法获得上次登录IP，先隐藏

    UIHelper.LayoutDoLayout(self.LayoutTime)
end



function UILoginRoleChoices:UpdateBtnDeleteState()
    UIHelper.SetNodeGray(self.BtnDelete, self.tbCurRoleInfo.nDeleteTime ~= 0, true)
    UIHelper.SetEnable(self.BtnDelete, self.tbCurRoleInfo.nDeleteTime == 0)
end


function UILoginRoleChoices:SetRoleName(szRoleName)
    self.szRoleName = szRoleName
end

function UILoginRoleChoices:SetCurRoleIndex(nIndex, bForceUpdate)
    if self.nCurIndex == nIndex and not bForceUpdate then
        return
    end

    -- body
    local tbRoleInfoList = self.moduleRoleList.GetRoleInfoList()
    local nRoleCount = self.moduleRoleList.GetRoleCount()

    local tbCurRoleInfo = (nIndex >= 1 and nIndex <= nRoleCount) and tbRoleInfoList[nIndex] or nil
    local szRoleName = tbCurRoleInfo and tbCurRoleInfo.RoleName or nil

    self.nCurIndex = nIndex
    self:SetCurRoleInfo(tbCurRoleInfo)
    self:SetRoleName(szRoleName)
    self:UpdateBtnDeleteState()
    self:OnSelectRole(self.nCurIndex)

    self:UpdateDownloadEquipRes(nIndex)
    self:UpdateDefalutMapBtnState()
end


function UILoginRoleChoices:OnSelectRole(nIndex)
    --模型加载提示
    local tMsg = {
        szType = "LoadModel",
        szWaitingMsg = "正在加载角色模型中，请稍候...",
    }
    WaitingTipsData.PushWaitingTips(tMsg)

    self.nFinishCount = 0;
    if not self.nLoadTimerID then
        self.nLoadTimerID = Timer.AddFrameCycle(self, 1, function()
            GetSceneLoadingTaskCount(SceneMgr.GetCurSceneID())
        end)
    end

    self.moduleRoleList.SelectRole(self.nCurIndex)
end

function UILoginRoleChoices:SetCurRoleInfo(tbRoleInfo)
    self.tbCurRoleInfo = tbRoleInfo
end

function UILoginRoleChoices:DeleteRole()
    if self.tbCurRoleInfo then
        self.moduleRoleList.ConfirmDeleteRole(self.tbCurRoleInfo)
    end
end

function UILoginRoleChoices:OnDeleteRoleSuccess()


    --删除角色后，先默认将选中角色设为第一个
    local nRoleCount = self.moduleRoleList.GetRoleCount()
    if nRoleCount > 0 then
        self:SetCurRoleIndex(1, true)
    else
        --角色删完进创角界面
        LoginMgr.SwitchStep(LoginModule.LOGIN_ROLE)
        return
    end

    self:UpdateInfo()


end

function UILoginRoleChoices:OnDeleteRoleFail()
    self:SetCurRoleIndex(self.nCurIndex, true)--为了更新页面数据
    self:UpdateInfo()
end

function UILoginRoleChoices:OnReName()
    self:SetCurRoleIndex(self.nCurIndex, true)--为了更新页面数据
    self:UpdateInfo()
end

function UILoginRoleChoices:OnServerChangeClick()
    g_tbLoginData.bReLoginToRoleListFlag = true
    UIMgr.Open(VIEW_ID.PanelServerSelect, true)
end

function UILoginRoleChoices:EnterGame(bDefaultMap)
    local function _openResourcesView()
        local viewScript = UIMgr.GetViewScript(VIEW_ID.PanelResourcesDownload)
        if not viewScript then
            UIMgr.Open(VIEW_ID.PanelResourcesDownload, RESOURCES_PAGE.DOWNLOADING, 1) --跳转到资源管理界面-正在下载-主要
        else
            viewScript:SetPageSelect(RESOURCES_PAGE.DOWNLOADING, 1)
        end
    end

    --基础资源包
    local nBasicState, _, _ = PakDownloadMgr.GetBasicPackState()
    if nBasicState ~= DOWNLOAD_OBJECT_STATE.DOWNLOADED then
        TipsHelper.ShowNormalTip("无法登录游戏，基础资源下载完成才可进入")
        _openResourcesView()
        return
    end

    local nMapID = self.tbCurRoleInfo.dwMapID
    local dwForceID = self.tbCurRoleInfo.dwForceID
    local nLevel = self.tbCurRoleInfo.RoleLevel

    --核心包
    local tCorePackIDList = PakDownloadMgr.NeedDownloadCorePack(nMapID, dwForceID) and PakDownloadMgr.GetCorePackIDList() or {}
    local tCoreStateInfo = PakDownloadMgr.GetStateInfoByPackIDList(tCorePackIDList)
    if tCoreStateInfo.nState ~= DOWNLOAD_STATE.COMPLETE then
        if tCoreStateInfo.nState == DOWNLOAD_STATE.DOWNLOADING then
            TipsHelper.ShowNormalTip("无法登录游戏，核心资源下载完成才可进入")
            _openResourcesView()
        else
            local nNetMode = App_GetNetMode()
            local szLeftDownloadSize = PakDownloadMgr.FormatSize(tCoreStateInfo.dwTotalSize - tCoreStateInfo.dwDownloadedSize)
            if nNetMode == NET_MODE.WIFI then
                PakDownloadMgr.DownloadPackListImmediately(tCorePackIDList)
                TipsHelper.ShowNormalTip("无法登录游戏，核心资源下载完成才可进入")
                _openResourcesView()
            elseif nNetMode == NET_MODE.CELLULAR then
                UIHelper.ShowSystemConfirm("登录游戏需要下载" .. szLeftDownloadSize .. "的核心资源，当前处于移动网络，是否使用流量进行下载？", function()
                    PakDownloadMgr.DownloadPackListImmediately(tCorePackIDList)
                    local tCoreStateInfo = PakDownloadMgr.GetStateInfoByPackIDList(tCorePackIDList)
                    if tCoreStateInfo.nState == DOWNLOAD_STATE.DOWNLOADING then
                        TipsHelper.ShowNormalTip("核心资源已开始下载")
                    end
                    _openResourcesView()
                end)
            else
                --无网络
            end
        end
        return
    end

    --门派场景
    local tForceMapID = ForceIDToMapID[dwForceID]
    tForceMapID = IsTable(tForceMapID) and tForceMapID or {tForceMapID}
    if nLevel < 120 and table.contain_value(tForceMapID, nMapID) then
        local tForcePackIDList = {}
        for _, nMapID in ipairs(tForceMapID) do
            local nPackID = PakDownloadMgr.GetMapResPackID(nMapID)
            table.insert(tForcePackIDList, nPackID)
        end
        local tForceStateInfo = PakDownloadMgr.GetStateInfoByPackIDList(tForcePackIDList)
        if tForceStateInfo.nState ~= DOWNLOAD_STATE.COMPLETE then
            if tForceStateInfo.nState == DOWNLOAD_STATE.DOWNLOADING then
                TipsHelper.ShowNormalTip("无法登录游戏，门派场景资源下载完成才可进入")
                _openResourcesView()
            else
                local nNetMode = App_GetNetMode()
                local szLeftDownloadSize = PakDownloadMgr.FormatSize(tForceStateInfo.dwTotalSize - tForceStateInfo.dwDownloadedSize)
                if nNetMode == NET_MODE.WIFI then
                    PakDownloadMgr.DownloadPackListImmediately(tForcePackIDList)
                    TipsHelper.ShowNormalTip("无法登录游戏，门派场景资源下载完成才可进入")
                    _openResourcesView()
                elseif nNetMode == NET_MODE.CELLULAR then
                    UIHelper.ShowSystemConfirm("登录游戏需要下载" .. szLeftDownloadSize .. "的门派场景资源，当前处于移动网络，是否使用流量进行下载？", function()
                        PakDownloadMgr.DownloadPackListImmediately(tForcePackIDList)
                        local tForceStateInfo = PakDownloadMgr.GetStateInfoByPackIDList(tForcePackIDList)
                        if tForceStateInfo.nState == DOWNLOAD_STATE.DOWNLOADING then
                            TipsHelper.ShowNormalTip("门派场景资源已开始下载")
                        end
                        _openResourcesView()
                    end)
                else
                    --无网络
                end
            end
            return
        end
    end

    if self.szRoleName then
        self:ClearRoleData()
        if self.tbCurRoleInfo.nDeleteTime == 0 then
            self.moduleRoleList.EnterGame(self.szRoleName, bDefaultMap)
        else
            local scriptView = UIHelper.ShowConfirm(g_tStrings.STR_LOGIN_DELETED_ROLE_TIP, function()
                self.moduleRoleList.EnterGame(self.szRoleName, bDefaultMap)
            end)
            scriptView:SetButtonContent("Confirm", "确定")
        end
    end
end

-- ----------------------------------------------------------
-- Please write your own code below  ↓↓↓
-- ----------------------------------------------------------

function UILoginRoleChoices:UpdateInfo()
    self:UpdateTogSelect()
    self:UpdateBtnDeleteState()
    self:UnLoadSceneSfx()
    local moduleScene = LoginMgr.GetModule(LoginModule.LOGIN_SCENE)
    local tInfo =
    {
        nID = 0 ,
        szMapName = UIHelper.UTF8ToGBK("测试_默认")
    }
    if tInfo then
        moduleScene.SceneChange(tInfo , true)
        local tbEffect = TabHelper.GetUILoginScenePresetEffectTab("测试_默认")
        for k, v in pairs(tbEffect) do
            if v.szEffectPath ~= "" then
                moduleScene.LoadScenePresetSFX(UIHelper.UTF8ToGBK(v.szEffectPath),v.vPosition,v.vRotation,v.vScale)
            end
        end
    end
end

function UILoginRoleChoices:Test()
    UIHelper.PlayAni(self, self.AniAll, "Ani_L_R_Show")
end

function UILoginRoleChoices:ClearRoleData()
    CareerData.ClearData()
    PersonalCardData.ClearData()
    CommandBaseData.InitConductorData()
    -- CoinShopData.SetClickSchoolActivityState(false)
end

function UILoginRoleChoices:UpdateDownloadEquipRes(nIndex)
    if not PakDownloadMgr.IsEnabled() then
        return
    end
    local moduleScene = LoginMgr.GetModule(LoginModule.LOGIN_SCENE)
    local modelView = moduleScene.GetModel(LoginModel.ROLE)
    if not modelView then
        return
    end
    local nRoleType, tEquipList, tEquipSfxList = modelView:GetPakEquipResource()
    local scriptDownload = UIHelper.GetBindScript(self.WidgetDownloadBtnShell)
    local tConfig = {}
    tConfig.bLong = true
    local bRemoteNotExist
    self.nDownloadDynamicID, bRemoteNotExist = PakDownloadMgr.UserCheckDownloadEquipRes(nRoleType, tEquipList, tEquipSfxList, self.nDownloadDynamicID)
    CoinShopPreview.UpdateSimpleDownloadBtn(scriptDownload, self.nDownloadDynamicID, bRemoteNotExist, tConfig)
end

function UILoginRoleChoices:CheckHadCreateRoleFaceCache()
    NewFaceData.CheckHadCreateRoleFaceCache()
end

function UILoginRoleChoices:UnLoadSceneSfx()
    local moduleScene = LoginMgr.GetModule(LoginModule.LOGIN_SCENE)
    if moduleScene then
        moduleScene.UnLoadScenePresetSFX()
    end
end

function UILoginRoleChoices:SetRoleTypeAndForceID(tbRoleInfo)
    m_OnDetailRoleInfo =
    {
        nRoleType = 1,
        nForceID = 1,
        nFreezeTime = 0,
        byFreezeType = 0,
        nRoleID = 0,
        szRoleName = "",
        szGlobalID = ""
    }

    if tbRoleInfo then
        m_OnDetailRoleInfo.nRoleType = tbRoleInfo.RoleType
        m_OnDetailRoleInfo.nForceID = tbRoleInfo.dwForceID
        m_OnDetailRoleInfo.nFreezeTime = tbRoleInfo.nFreezeTime
        m_OnDetailRoleInfo.byFreezeType = tbRoleInfo.byFreezeType
        m_OnDetailRoleInfo.nRoleID = tbRoleInfo.RoleID
        m_OnDetailRoleInfo.szRoleName = UIHelper.GBKToUTF8(tbRoleInfo.RoleName)
        m_OnDetailRoleInfo.szGlobalID = tbRoleInfo.GlobalID
    end
    local tbServer = LoginMgr.GetModule(LoginModule.LOGIN_SERVERLIST).GetSelectServer()
    UIHelper.SetString(self.LabelServer , tbServer.szRealServer)
    UIHelper.SetString(self.LabelPlayerName , m_OnDetailRoleInfo.szRoleName)
    local compLuaBind = self.WidgetHead:getComponent("LuaBind")
	local scriptView = compLuaBind and compLuaBind:getScriptObject()
    if scriptView then
        scriptView:SetHeadInfo(0,0,m_OnDetailRoleInfo.nRoleType,m_OnDetailRoleInfo.nForceID)
    end
end

function UILoginRoleChoices:UpdateDefalutMapBtnState()
    local bVisible = false
    local moduleEnterGame = LoginMgr.GetModule(LoginModule.LOGIN_ENTERGAME)
    if moduleEnterGame.GetRoleLoginRealMap(self.szRoleName) then
        bVisible = true
    end
    UIHelper.SetVisible(self.BtnDefaultMap, bVisible)
    if bVisible then
        local sfx = UIHelper.GetChildByName(self.BtnDefaultMap, "Eff_btn")
        UIHelper.PlaySFX(sfx)
    end
end

return UILoginRoleChoices