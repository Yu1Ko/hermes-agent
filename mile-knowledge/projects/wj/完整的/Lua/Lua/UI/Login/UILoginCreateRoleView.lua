-- ---------------------------------------------------------------------------------
-- Author: hanyu
-- Name: UILoginCreateRoleView
-- Date: 2022-11-07 10:44:01
-- Desc: ?
-- ---------------------------------------------------------------------------------

local BodyIndexToRoleType = {
    [1] =  ROLE_TYPE.STANDARD_MALE,
    [2] =  ROLE_TYPE.STANDARD_FEMALE,
    [3] =  ROLE_TYPE.LITTLE_GIRL,
    [4] =  ROLE_TYPE.LITTLE_BOY,
}

local BodyIndexToRoleTypeStr = {
    [1] =  "m2",
    [2] =  "f2",
    [3] =  "f1",
    [4] =  "m1",
}
local BgmMusicEventID =
{
    [KUNGFU_ID.BA_DAO] = "BGM_State_DengLuXuanJue_BaDao",
    [KUNGFU_ID.CANG_JIAN] = "BGM_State_DengLuXuanJue_CangJian",
    [KUNGFU_ID.CANG_YUN] = "BGM_State_DengLuXuanJue_CangYun",
    [KUNGFU_ID.CHANG_GE] = "BGM_State_DengLuXuanJue_ChangGe",
    [KUNGFU_ID.CHUN_YANG] = "BGM_State_DengLuXuanJue_ChunYang",
    [KUNGFU_ID.DAO_ZONG] = "BGM_State_DengLuXuanJue_DaoZong",
    [KUNGFU_ID.GAI_BANG] = "BGM_State_DengLuXuanJue_GaiBang",
    [KUNGFU_ID.LING_XUE] = "BGM_State_DengLuXuanJue_LingXue",
    [KUNGFU_ID.MING_JIAO] = "BGM_State_DengLuXuanJue_MingJiao",
    [KUNGFU_ID.PENG_LAI] = "BGM_State_DengLuXuanJue_PengLai",
    [KUNGFU_ID.QI_XIU] = "BGM_State_DengLuXuanJue_QiXiu",
    [KUNGFU_ID.SHAO_LIN] = "BGM_State_DengLuXuanJue_ShaoLin",
    [KUNGFU_ID.TANG_MEN] = "BGM_State_DengLuXuanJue_TangMen",
    [KUNGFU_ID.TIAN_CE] = "BGM_State_DengLuXuanJue_TianCe",
    [KUNGFU_ID.WAN_HUA] = "BGM_State_DengLuXuanJue_WanHua",
    [KUNGFU_ID.WAN_LING] = "BGM_State_DengLuXuanJue_WanLing",
    [KUNGFU_ID.WU_DU] = "BGM_State_DengLuXuanJue_WuDu",
    [KUNGFU_ID.YAN_TIAN] = "BGM_State_DengLuXuanJue_YanTian",
    [KUNGFU_ID.YAO_ZONG] = "BGM_State_DengLuXuanJue_YaoZong",
    [KUNGFU_ID.DUAN_SHI] = "BGM_State_DengLuXuanJue_DuanShi",--资源有无尚待验证
}


-- 默认是Const.fCreateVideoVolume 0.3,需要做额外的内容，直接在下列添加即可
local BgmMusicVolume =
{
    [KUNGFU_ID.CHANG_GE] = 0.6,
}

local bVideoChoose = true

local AUTO_KICK_TIME = 15 * 60 --15分钟

local UILoginCreateRoleView = class("UILoginCreateRoleView")


function UILoginCreateRoleView:OnEnter()
    if not self.bInit then
        self:RegEvent()
        self:BindUIEvent()
        self.bInit = true
    end
    XGSDK_TrackEvent("game.schoolselect.begin", "buileface", {})

    self:Init()
    LoginMgr.StartAutoKick(AUTO_KICK_TIME)
end

function UILoginCreateRoleView:OnExit()
    self.bInit = false
    self:UnRegEvent()
    if bVideoChoose then
         UIHelper.StopVideo(self.VideoPlayer)
    end
   -- SoundMgr.StopBgMusic(true)
    SoundMgr.PlayLastBgMusic()
    UIMgr.ShowLayer(UILayer.Scene)
    LoginMgr.ClearAutoKick()
    self:StopTimer()
    self:UnEnableFpsLimit()
end

function UILoginCreateRoleView:OnShow()
    UIMgr.Close(VIEW_ID.PanelZhuanChang)
    UIMgr.HideLayer(UILayer.Scene)
    LoginMgr.StartAutoKick(AUTO_KICK_TIME)
    self:StartTimer()
    if self.szLastAudioName then
        SoundMgr.PlayBgMusic(self.szLastAudioName, 0 ,nil ,true)
    end

    self:EnableFpsLimit()

end

function UILoginCreateRoleView:OnHide()
    UIMgr.ShowLayer(UILayer.Scene)
    LoginMgr.ClearAutoKick()
    self:StopTimer()
    SoundMgr.PlayLastBgMusic()
    self:UnEnableFpsLimit()
end

function UILoginCreateRoleView:BindUIEvent()
    -- for nIndex,toggle in ipairs(self.tbScrollViewSchoolSelectChildList) do
    --         UIHelper.BindUIEvent(toggle, EventType.OnClick, function()
    --             self:SelectSchool(nIndex)
    --         end)
    -- end
    -- children = UIHelper.GetChildren(self.LayoutBodilyForm)
    for nIndex, child in ipairs(self.tbLayoutBodilyFormChildList) do
        UIHelper.BindUIEvent(child, EventType.OnClick, function()
            self:SelectBody(nIndex)
        end)
    end

    UIHelper.BindUIEvent(self.BtnConfirm, EventType.OnClick, function(btn)
        XGSDK_TrackEvent("game.schoolselect.end", "buileface", {})

        self:InitRoleModel()
        self:UpdateRoleModel()
        -- 在这一步先请求主城列表
        self.moduleGateway.QueryHometownList()

        self:UpdateUIAnimation(0 , "AniRightHide")
        self:PlayZhuanChangSFX()
        -- self:CreateRole()
        -- self:StartBuildFace()

        -- UIMgr.Open(VIEW_ID.PanelInputName, false, BodyIndexToRoleType[self.nBodyIndex])
    end)

    UIHelper.BindUIEvent(self.BtnClose, EventType.OnClick, function(btn)
        self.moduleRole.BackToPrevStep()
    end)

    UIHelper.BindUIEvent(self.BtnStory, EventType.OnClick, function(btn)
        self.storyTipsView = UIHelper.AddPrefab(PREFAB_ID.WidgetSchoolStoryLabelTips, self.WidgetStoryTip, self.nKungfuID)
        UIHelper.SetPositionY(self.storyTipsView._rootNode, UIHelper.GetHeight(self.WidgetStoryTip) / 2)
    end)

    UIHelper.BindUIEvent(self.BtnTestSchool, EventType.OnClick, function(btn)
        UIMgr.Open(VIEW_ID.PanelTestPop)
    end)

    UIHelper.BindUIEvent(self.BtnDown, EventType.OnClick, function(btn)
        UIHelper.ScrollToPercent(self.ScrollViewSchoolSelect, 100, 0)
    end)

    UIHelper.BindUIEvent(self.BtnPageUp, EventType.OnClick, function(btn)
        UIHelper.ScrollToPercent(self.ScrollViewSchoolSelect, 0, 0)
    end)

     
    for i, toggle in pairs(self.tbCombatTypeList) do
        UIHelper.BindUIEvent(toggle, EventType.OnSelectChanged, function (_, bSelected)
            self:UpdateGroupSchoolState(i, bSelected)
        end)
    end
end

function UILoginCreateRoleView:RegEvent()
    Event.Reg(self, EventType.OnCreateRoleName, function(szRoleName)
        self:SetRoleName(szRoleName)
        self:CreateRole()
    end)
    Event.Reg(self, EventType.OnTestSchoolConfirm, function(nKungFuID)
        local nSchoolIndex = 1
        for nIndex, kungfuID in pairs(Login_SchoolIndexTopForceID) do
            if kungfuID == nKungFuID then
                nSchoolIndex = nIndex
                break
            end
        end
        local scriptView = self.tbSchoolScript[math.ceil(nSchoolIndex / 2)]
        scriptView:SelectSchool(nKungFuID)

    end)

    Event.Reg(self, EventType.OnRestoreBuildFaceCacheData, function(tbData)
        self:SelectSchool(tbData.nKungfuID)
        self:SelectBody(table.get_key(BodyIndexToRoleType, tbData.nRoleType))

        self:InitRoleModel()
        self:UpdateRoleModel()
        -- 在这一步先请求主城列表
        self.moduleGateway.QueryHometownList()

        -- self:StartBuildFace()
		self:UpdateUIAnimation(0 , "AniRightHide")
        self:PlayZhuanChangSFX()
    end)

    Event.Reg(self, EventType.OnWindowsSizeChanged, function()
        Timer.AddFrame(self, 1, function()
            UIHelper.ScrollViewDoLayout(self.ScrollViewSchoolSelect)
        end)
    end)

    Event.Reg(self, EventType.OnCreateRole, function()
        self:CreateRole()
    end)

    Event.Reg(self, EventType.HideAllHoverTips, function()
        if self.storyTipsView then
            UIHelper.RemoveFromParent(self.storyTipsView._rootNode, true)
            self.storyTipsView = nil
        end
    end)
end

function UILoginCreateRoleView:UnRegEvent()
    --Event.UnReg(self, EventType.XXX)
end


------------点击后的响应事件----------------
function UILoginCreateRoleView:SelectSchool(nIndex, toggle)

    if Platform.IsMobile() then
        if self.bIsStartPlayVideo then
            Timer.Add(self, 0.3, function ()
                UIHelper.SetSelected(self.curSelectToggle, true)
                UIHelper.SetSelected(toggle, false)
            end)
            return
        end
        if self.curSelectToggle then
            UIHelper.SetSelected(self.curSelectToggle, false)
        end
       
        self.curSelectToggle = toggle
    end


    self:SetKungfuID(nIndex)
    -- self:SetBodyIndex(2)
    self:UpdateBodyIndex()
    self:UpdateGroupBody()
    self:UpdateSchoolIntroduce()
    self:UpdateCharacterModle()
end

function UILoginCreateRoleView:SelectBody(nIndex)
    self:SetBodyIndex(nIndex)
    self:UpdateGroupBody()
    self:UpdateCharacterModle()
end

function UILoginCreateRoleView:StartBuildFace()
    UIMgr.HideView(VIEW_ID.PanelSchoolSelect)
    UIMgr.Close(VIEW_ID.PanelResourcesDownload)
    UIMgr.Open(VIEW_ID.PanelBuildFace, BodyIndexToRoleType[self.nBodyIndex], self.nKungfuID)
    --UIMgr.Open(VIEW_ID.PanelBuildFace_Step2, BodyIndexToRoleType[self.nBodyIndex], self.nKungfuID)
    XGSDK_TrackEvent("game.buileface.begin", "buileface", {})
    BuildFaceData.SetStartBuildFaceTime()
end

function UILoginCreateRoleView:CreateRole()
    self.moduleRole.CreateRole(BodyIndexToRoleType[self.nBodyIndex], self.nKungfuID ,self.szRoleName)
end

function UILoginCreateRoleView:InitRoleModel()
    self.moduleRole.InitRoleModel(self.nKungfuID, BodyIndexToRoleType[self.nBodyIndex])
end

function UILoginCreateRoleView:UpdateRoleModel()
    self.moduleRole.UpdateRoleModel()
end

-- ----------------------------------------------------------
-- Please write your own code below  ↓↓↓
-- ----------------------------------------------------------

function UILoginCreateRoleView:UpdateInfo()

end


---------------------------初始化--------------------------------

function UILoginCreateRoleView:StartTimer()
    self:StopTimer()
    self.nUpdateTimer = Timer.AddFrameCycle(self, 1, function()
        self:OnUpdate()
    end)
end

function UILoginCreateRoleView:StopTimer()
    if self.nUpdateTimer then
        Timer.DelTimer(self, self.nUpdateTimer)
        self.nUpdateTimer = nil
    end
end

function UILoginCreateRoleView:Init()
    self:InitValues()
    self:InitUI()
end

function UILoginCreateRoleView:InitValues()
    self.szVideoRootPath = "mui\\Video\\PC\\CharacterCreation\\"
    self.szLastAudioName = nil
    if Platform.IsMobile() then
        self.szVideoRootPath = "mui\\Video\\MOBILE\\CharacterCreation\\"
    end

    self.moduleRole = LoginMgr.GetModule(LoginModule.LOGIN_ROLE)
    self.moduleGateway = LoginMgr.GetModule(LoginModule.LOGIN_GATEWAY)
    self:SetRoleName("")
    self:SetKungfuID(Login_SchoolIndexTopForceID[1])

    self:SetBodyIndex(2)
    self:UpdateBodyIndex()

    UIHelper.SetVideoPlayerModel(self.videoPlayer , VIDEOPLAYER_MODEL.BINK)
    UIHelper.SetVideoPlayerVolume(self.videoPlayer ,Const.fCreateVideoVolume)
    self:UpdateCharacterModle()

    self:StartTimer()

end

function UILoginCreateRoleView:InitUI()
    self:InitGroupCombatType()
    self:InitSchoolData()
    self:InitGroupSchool()
    self:InitGroupBody()
    self:UpdateSchoolIntroduce()
    UIHelper.SetVisible(self.videoPlayer , bVideoChoose)
    --资源下载
    local scriptDownload = UIHelper.GetBindScript(self.WidgetDownload)
    --scriptDownload:OnInitBasic()
    scriptDownload:OnInitTotal()

    -- local nState, _, _ = PakDownloadMgr.GetBasicPackState()
    -- UIHelper.SetVisible(self.WidgetDownload, nState ~= DOWNLOAD_OBJECT_STATE.DOWNLOADED)
    UIHelper.LayoutDoLayout(self.LayoutBtn)
end

function UILoginCreateRoleView:InitGroupCombatType()
    UIHelper.SetToggleGroupAllowedNoSelection(self.ToggleGroupCombatType, true)
    for _, tog in ipairs(self.tbCombatTypeList) do
        UIHelper.ToggleGroupAddToggle(self.ToggleGroupCombatType, tog)
    end
end

function UILoginCreateRoleView:InitSchoolData()
    self.tbSchoolList = {}
    for nIndex, nKungfuID in ipairs(Login_SchoolIndexTopForceID) do
        local tbData = {}
        local tInfo = Table_GetCreateRoleTable(nKungfuID)
        tbData.nIndex = nIndex
        tbData.nKungfuID = nKungfuID
        tbData.tInfo = tInfo
        tbData.bHighLight = false
        table.insert(self.tbSchoolList, tbData)
    end
end

function UILoginCreateRoleView:InitGroupSchool()
    UIHelper.RemoveAllChildren(self.ScrollViewSchoolSelect)

    self.tbSchoolScript = {}
    local nStartIndex = 1
    for nIndex = 1, math.ceil(#self.tbSchoolList / 2) do
        local tbKungfuID = {}
        local tbData = {}

        for j = nStartIndex, nStartIndex + 1 do
            if self.tbSchoolList[j] then
                local tData = self.tbSchoolList[j]
                table.insert(tbKungfuID, tData.nKungfuID)
                table.insert(tbData, tData)
            end
        end
        nStartIndex = nStartIndex + 2
        
        local scriptView = UIHelper.AddPrefab(PREFAB_ID.WidgetSchool, self.ScrollViewSchoolSelect, tbKungfuID, self.ToggleGroupSchool, self, tbData)
        table.insert(self.tbSchoolScript, scriptView)
    end


    UIHelper.ScrollViewDoLayout(self.ScrollViewSchoolSelect)
    UIHelper.ScrollToTop(self.ScrollViewSchoolSelect)
end

function UILoginCreateRoleView:UpdateGroupSchoolState(nCombatType, bSelected)
    if bSelected then
        self.nCombatType = nCombatType
    else
        if self.nCombatType == nCombatType then
            self.nCombatType = nil
        end
    end

    for _, tbData in ipairs(self.tbSchoolList) do
        local tInfo = tbData.tInfo
        local bHighLight = false
        if self.nCombatType then
            bHighLight = tInfo.tCombatType and tInfo.tCombatType[self.nCombatType] or false
        end
        tbData.bHighLight = bHighLight
    end

    table.sort(self.tbSchoolList, function(a, b)
        if a.bHighLight == b.bHighLight then
            return a.nIndex < b.nIndex
        else
            return a.bHighLight and not b.bHighLight
        end
    end)

    self:InitGroupSchool()
    for k, v in pairs(self.tbSchoolScript) do
        local scriptView = self.tbSchoolScript[k]
        scriptView:UpdateSchoolState(self:GetKungfuID())
    end
end

function  UILoginCreateRoleView:InitGroupBody()
    for nIndex,toggle in ipairs(self.tbLayoutBodilyFormChildList) do
        UIHelper.ToggleGroupAddToggle(self.ToggleGroupBodilyForm, toggle)
        --UIHelper.SetSelected(toggle, SchoolIndexTopForceID[nIndex] == self.nKungfuID)
    end
    self:UpdateGroupBody()
end


--------------------------------------更新UI---------------------------------

function UILoginCreateRoleView:UpdateGroupBody()
    for nIndex, toggle in ipairs(self.tbLayoutBodilyFormChildList) do
        local bShow = self.moduleRole.JudgeSchoolHasRoleType(KUNGFU_IDToSchool[self.nKungfuID], BodyIndexToRoleType[nIndex])
        UIHelper.SetVisible(toggle, bShow)
        if nIndex == self.nBodyIndex then
            UIHelper.SetToggleGroupSelected(self.ToggleGroupBodilyForm, nIndex - 1)
        end
    end
    UIHelper.LayoutDoLayout(self.LayoutBodilyForm)
end

function UILoginCreateRoleView:UpdateSchoolIntroduce()
    -- body
    -- local szContent, szContent2 = self.moduleRole.GetSchoolSpecialty(self.nKungfuID)

    -- UIHelper.SetString(self.LabelIntroduce, szContent)
    -- UIHelper.SetString(self.LabelIntroduce2, szContent2)

    local scriptView = UIHelper.GetBindScript(self.WidgetSchoolIntroduce)
    if scriptView then
        scriptView:OnEnter(self.nKungfuID)
    end
end

function UILoginCreateRoleView:UpdateSchoolAttribute()
    local scriptView = UIHelper.GetBindScript(self.WidgetSchoolIntroduce)
    if scriptView then
        scriptView:UpdateAttribute()
    end
end

function UILoginCreateRoleView:UpdateArrow()
    local nPercent = UIHelper.GetScrollPercent(self.ScrollViewSchoolSelect)
    UIHelper.SetVisible(self.WidgetArrow, nPercent <= 90)
    UIHelper.SetVisible(self.WidgetArrowTop, nPercent >= 10)
end

function UILoginCreateRoleView:OnUpdate()
    self:UpdateArrow()
end

---------------------------------------更新数据-------------------------------
function UILoginCreateRoleView:SetKungfuID(nKungfuID)
    self.nKungfuID = nKungfuID
end

function UILoginCreateRoleView:GetKungfuID()
    return self.nKungfuID
end

function UILoginCreateRoleView:SetBodyIndex(nIndex)
    self.nBodyIndex = nIndex
end

function UILoginCreateRoleView:SetRoleName(szRoleName)
    self.szRoleName = szRoleName
end

--更新体型数据,防止更新门派后，当前门派没有选中的体型
function UILoginCreateRoleView:UpdateBodyIndex()

    -- local tbBodyData = self.moduleRole._getBodyData()
    -- local tbCurSchoolBodyData  = tbBodyData[KUNGFU_IDToSchool[self.nKungfuID]]
    local bUpdate = not self.moduleRole.JudgeSchoolHasRoleType(KUNGFU_IDToSchool[self.nKungfuID], BodyIndexToRoleType[self.nBodyIndex])

    if not bUpdate then return end

    for nIndex, toggle in ipairs(self.tbLayoutBodilyFormChildList) do
        if self.moduleRole.JudgeSchoolHasRoleType(KUNGFU_IDToSchool[self.nKungfuID], nIndex) then
            self:SetBodyIndex(nIndex)
            break
        end
    end
end

function UILoginCreateRoleView:UpdateCharacterModle()
    if bVideoChoose then
        if self.bIsStartPlayVideo then
            return
        end
        local nBodyType = self.moduleRole.convertBodyType(BodyIndexToRoleTypeStr[self.nBodyIndex])
        local tbSchoolData = self.moduleRole._getSchoolData(KUNGFU_IDToSchool[self.nKungfuID] , nBodyType)
        if self.szLastVideoPath ~= tbSchoolData.videoEnterPath then
            self.szLastAudioName = BgmMusicEventID[self.nKungfuID]
            SoundMgr.PlayBgMusic(BgmMusicEventID[self.nKungfuID], 0 ,nil ,true)
            local volume = BgmMusicVolume[self.nKungfuID] or Const.fCreateVideoVolume
            if tbSchoolData.videoEnterPath ~= "" then
                local rootPath = self.szVideoRootPath
                tbSchoolData.videoEnterPath = UIHelper.ParseVideoPlayerFile( tbSchoolData.videoEnterPath , VIDEOPLAYER_MODEL.BINK)
                tbSchoolData.videoLoopPath = UIHelper.ParseVideoPlayerFile( tbSchoolData.videoLoopPath , VIDEOPLAYER_MODEL.BINK)
                self.bIsStartPlayVideo = true
                self.bIsUpdateUIAni = true
                UIHelper.StopVideo(self.videoPlayer)
                self.videoPlayer:clearFileQueue()
                self.videoPlayer:addFileQueue(rootPath..tbSchoolData.videoLoopPath)
                self.bWaitAniStop = false
                local videoPath = rootPath..tbSchoolData.videoEnterPath--""--
                UIHelper.SetVideoLooping(self.videoPlayer, true)
                UIHelper.PlayVideo(self.videoPlayer, videoPath, true, function(nVideoPlayerEvent, szMsg)
                    if nVideoPlayerEvent == ccui.VideoPlayerEvent.ERROR then
                        TipsHelper.ShowNormalTip("视频播放错误："..tostring(szMsg))
                        Timer.DelTimer(self , self.nShowUITimerID)
                        self.bIsStartPlayVideo = false
                        self:UpdateUIAnimation(tbSchoolData.showUIFps / 30 , "AniSchoolSelectShow")
                    elseif nVideoPlayerEvent == ccui.VideoPlayerEvent.PLAYING then
                        if not self.bIsUpdateUIAni then return end
                        if not self.bHideSceneLayer then
                            self.bHideSceneLayer = true
                            self:UpdateUIAnimation(tbSchoolData.showUIFps / 30 , "AniSchoolSelectShow")
                        else
                            if not self.bWaitAniStop then
                                self:UpdateUIAnimation(0 , "AniRightHide")
                                self:UpdateUIAnimation(tbSchoolData.showUIFps / 30 , "AniRightShow")
                            end
                        end
                    end
                end , true ,volume)

            else
                TipsHelper.ShowNormalTip("没有视频资源")
                if not self.bHideSceneLayer then
                    self.bHideSceneLayer = true
                    self:UpdateUIAnimation(0 , "AniSchoolSelectShow")
                end
            end
            self.szLastVideoPath = tbSchoolData.videoEnterPath
        end
    end
end

function UILoginCreateRoleView:UpdateUIAnimation(fTime , szClipName)
    Timer.DelTimer(self , self.nShowUITimerID)
    if fTime == 0 then
        UIHelper.PlayAni(self , self.AniAll , szClipName)
    else
        self.bWaitAniStop = true
        self.bIsUpdateUIAni = false
        UIHelper.ShowTouchMask()
        self.nShowUITimerID = Timer.Add(self , fTime , function ()
            UIHelper.PlayAni(self , self.AniAll , szClipName, function()
                self.bIsStartPlayVideo = false
                UIHelper.HideTouchMask()
                self:UpdateSchoolAttribute()
            end)
            self.bWaitAniStop = false
        end)
    end
end

function UILoginCreateRoleView:PlayZhuanChangSFX()
    local scriptView = UIMgr.Open(VIEW_ID.PanelZhuanChang)
    scriptView:PlayAnim("AniIn", function()
        scriptView:PlayAnim("AniOut", function()
            UIMgr.Close(VIEW_ID.PanelZhuanChang)
        end)

        if self.nTimer then
            Timer.DelTimer(self, self.nTimer)
            self.nTimer = nil
        end

        self.nTimer = Timer.Add(self, 3, function()
            UIHelper.SetVisible(scriptView._scriptBG._rootNode, false)--三秒后关掉转场的widgettouchbackground，否则会导致捏脸已打开但不能点击的局面
        end)

        self:StartBuildFace()
    end)
end


function UILoginCreateRoleView:EnableFpsLimit()
    if FrameMgr.nDynamicFpsTimerID then
        self.bIsEnableDynamicFps = true
    else
        self.bIsEnableDynamicFps = false
    end
    self.nOldFpsLimit = GetFpsLimit()
    FrameMgr.StopDynamicFps()
    FrameMgr.SetFrameLimit(45)
end

function UILoginCreateRoleView:UnEnableFpsLimit()
    if self.bIsEnableDynamicFps then
        FrameMgr.StartDynamicFps()
        self.bIsEnableDynamicFps = false
    end
    if self.nOldFpsLimit then
        FrameMgr.SetFrameLimit(self.nOldFpsLimit)
    end
end

return UILoginCreateRoleView