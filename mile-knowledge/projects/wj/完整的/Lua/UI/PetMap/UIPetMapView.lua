-- ---------------------------------------------------------------------------------
-- Author: Unknown
-- Name: UIPetMapView
-- Date: 2023-03-24 15:04:30
-- Desc: ?
-- ---------------------------------------------------------------------------------

local UIPetMapView = class("UIPetMapView")
local LUCKY_PET_SCORE     = 999
local REMOTE_PREFER_PET   = 1041
local SOURCE = {
    WORLD_ADVENTURE 	= 5,
    POINT_REWARD 		= 6,
    EXPLORE             = 7,
    FORCE               = 9,
    OPERATION_ACTIVITY	= 11,
}
local LUCKY_BUFF = {
    0, 15, 30, 50, 65, 80, 100
}

local tPetCamera = {0, 75, -304, 0, 75, 44, 1.78}
local tNpcRadius = {280, 700}
local tVerAngle = {-1, 0.1}-- 取值范围-pi~pi
local tHorAngle = {5.9, 1.1}
local nPagePetCount = 27

function UIPetMapView:OnEnter(dwPlayerID, nPetIndex, nTabType, nTabID)
    if not self.bInit then
        self:RegEvent()
        self:BindUIEvent()
        UIMgr.Open(VIEW_ID.PanelUID)
        self.bInit = true
    end

    self.dwPlayerID = dwPlayerID or g_pClientPlayer.dwID
    self.bMySelf = self.dwPlayerID == g_pClientPlayer.dwID
    self.bGather = true
    self.bShowPrefer = false
    self.nCurIndex = 1
    self.nCurLikeIndex = 1
    self.nPageIndex = 1
    self.nGroupID = 1
    self.nGroupIndex = 1
    self.tPets = {}
    self.scriptView = UIMgr.AddPrefab(PREFAB_ID.WidgetPublicLabelTips, self._rootNode)
    self.scriptQualityBar = UIHelper.AddPrefab(PREFAB_ID.WidgetQualityBar, self.WidgetTittle)
    UIHelper.SetVisible(self.scriptView._rootNode, false)
    UIHelper.SetEditboxTextHorizontalAlign(self.EditPaginate, TextHAlignment.CENTER)

    if self.bMySelf then
        self:InitMyPet()
        self:UpdateInfo()

        if nPetIndex then
            local tPet = Table_GetFellowPet(nPetIndex)
            self:MedalTipsOnClick(tPet)
        elseif nTabType and nTabID then
            local nPetIndex = GetFellowPetIndexByItemIndex(nTabType, nTabID)
            if nPetIndex then
                local tPet = Table_GetFellowPet(nPetIndex)
                self:MedalTipsOnClick(tPet)
            end
        end
    else
        self:InitOtherPet()
    end

    local tbFilterDefSelected = FilterDef.Pet.tbRuntime
    if tbFilterDefSelected then
        tbFilterDefSelected[1][1] = 1
        tbFilterDefSelected[2][1] = 1
        tbFilterDefSelected[3][1] = 1
        tbFilterDefSelected[4][1] = 1
    end
end

function UIPetMapView:OnExit()
    self.bInit = false
    self:UnRegEvent()

    local tbFrame = NpcModelPreview_GetRegisterFrame("NewPet", "NewPet")
    if tbFrame and tbFrame.hNpcModelView and tbFrame.hNpcModelView.m_scene then
        tbFrame.hNpcModelView.m_scene:RestoreCameraLight()
    end

    if self.hModelView then
        self.hModelView:release()
        self.hModelView = nil
    else
        local tbFrame = NpcModelPreview.tResisterFrame["NewPet"]["NewPet"]
        local scene = tbFrame and tbFrame.scene
        SceneHelper.Delete(scene)
    end

    Timer.DelAllTimer(self)
    UITouchHelper.UnBindModel()

    RedpointHelper.Pet_ClearAll()
    UIMgr.Close(VIEW_ID.PanelUID)
end

function UIPetMapView:BindUIEvent()
    UIHelper.BindUIEvent(self.BtnClose,EventType.OnClick,function ()
        UIMgr.Close(self)
    end)

    --查看卡牌
    UIHelper.BindUIEvent(self.BtnView,EventType.OnClick,function ()
        local nCurIndex = self.bShowPrefer and self.nCurLikeIndex or self.nCurIndex
        UIMgr.Open(VIEW_ID.PanelShowCardPop,self.tPets[nCurIndex])
    end)

    --宠物收集分页
    UIHelper.BindUIEvent(self.TogNavigation01,EventType.OnClick,function ()
        self.bGather = true
        self.bShowPrefer = false
        UIHelper.SetVisible(self.WidgetEmpty,self.bEmptyPets or false)
        self:UpdatePetList()
    end)

    --羁绊关系分页
    UIHelper.BindUIEvent(self.TogNavigation02,EventType.OnClick,function ()
        self.bGather = false
        self.bShowPrefer = false
        UIHelper.SetVisible(self.WidgetEmpty,self.bEmptyMedals or false)
        -- self:UpdateMedalCollect()

        local tbFrame = NpcModelPreview.tResisterFrame["NewPet"]["NewPet"]
        self.hModelView = tbFrame.hNpcModelView

        self.hModelView:UnloadModel()
    end)

    --我的喜爱分页
    UIHelper.BindUIEvent(self.ToglikeBtn,EventType.OnClick,function ()
        self.bGather = true
        self.bShowPrefer = true
        UIHelper.SetString(self.EditBoxSearch, "")
        UIHelper.SetVisible(self.WidgetEmpty,self.bEmptyMedals or false)
        self:UpdatePetList()
    end)

    --打开筛选
    UIHelper.BindUIEvent(self.TogSift, EventType.OnClick, function ()
        TipsHelper.ShowNodeHoverTipsInDir(PREFAB_ID.WidgetFiltrateTip, self.TogSift, TipsLayoutDir.BOTTOM_RIGHT, FilterDef.Pet)
    end)

    UIHelper.BindUIEvent(self.BtnLeft, EventType.OnClick, function ()
        if self.nPageIndex > 1 then
            self.nPageIndex = self.nPageIndex - 1
            UIHelper.SetString(self.EditPaginate, self.nPageIndex)
            self.nCurIndex = self.nPageIndex * nPagePetCount + 1
            self:UpdatePetShow()
        end
    end)

    UIHelper.BindUIEvent(self.BtnRight, EventType.OnClick, function ()
        if self.nPageIndex < self.nPageCount then
            self.nPageIndex = self.nPageIndex + 1
            UIHelper.SetString(self.EditPaginate, self.nPageIndex)
            self.nCurIndex = self.nPageIndex * nPagePetCount + 1
            self:UpdatePetShow()
        end
    end)

    UIHelper.RegisterEditBoxEnded(self.EditPaginate, function ()
        local nPageIndex = tonumber(UIHelper.GetString(self.EditPaginate))
        if nPageIndex ~= self.nPageIndex then
            if nPageIndex < 1 then
                self.nPageIndex = 1
            elseif nPageIndex > self.nPageCount then
                self.nPageIndex = self.nPageCount
            else
                self.nPageIndex = nPageIndex
            end
            if self.nPageIndex ~= nPageIndex then
                UIHelper.SetString(self.EditPaginate, self.nPageIndex)
            end
            self.nCurIndex = self.nPageIndex * nPagePetCount + 1
            self:UpdatePetShow()
        end
    end)

    --召唤
    UIHelper.BindUIEvent(self.BntCall,EventType.OnClick,function ()
        local nCurIndex = self.bShowPrefer and self.nCurLikeIndex or self.nCurIndex
        if self.nPetIndex == self.tPets[nCurIndex].dwPetIndex then
            RemoteCallToServer("On_FellowPet_Dissolution")
            JiangHuData.bOpenPet = false
        else
            local tPet = g_pClientPlayer.GetFellowPet()
            if tPet then
                RemoteCallToServer("On_FellowPet_Dissolution")
            end
            self:CallPet()
        end
    end)

    --前往
    UIHelper.BindUIEvent(self.BntGo,EventType.OnClick,function ()
        self:GoToAcquirePet()
    end)

    --喜爱
    UIHelper.BindUIEvent(self.Toglike,EventType.OnSelectChanged,function (_,bSelected)
        local nCurIndex = self.bShowPrefer and self.nCurLikeIndex or self.nCurIndex
        local dwPetIndex = self.tPets[nCurIndex].dwPetIndex
        local bPrefer = self:IsPreferPet(dwPetIndex)
        if not bPrefer then
            RemoteCallToServer("On_FellowPet_AddPreferPet", dwPetIndex)
        else
            RemoteCallToServer("On_FellowPet_DelPreferPet", dwPetIndex)
        end
    end)

    --福缘tips
    UIHelper.BindUIEvent(self.TogPetNeme,EventType.OnClick,function ()
        local nCurIndex = self.bShowPrefer and self.nCurLikeIndex or self.nCurIndex
        local tInfo = self.tPets[nCurIndex]
        local bLucky = self:IsLuckyPet(tInfo.dwPetIndex)
        if bLucky then
            local bVisible = UIHelper.GetVisible(self.WidgetTagTips)
            UIHelper.SetVisible(self.WidgetTagTips,not bVisible)
        end
    end)

    --搜索筛选
    if Platform.IsIos() then
        UIHelper.RegisterEditBoxEnded(self.EditBoxSearch, function()
            self.nCurIndex = 1
            self.nPageIndex = 1
            self:UpdatePetList()
        end)
    else
        UIHelper.RegisterEditBoxChanged(self.EditBoxSearch, function()
            self.nCurIndex = 1
            self.nPageIndex = 1
            self:UpdatePetList()
        end)
    end

    UIHelper.BindUIEvent(self.BtnClean,EventType.OnClick,function ()
        local szSearch = UIHelper.GetString(self.EditBoxSearch)
        if szSearch ~= "" then
            UIHelper.SetString(self.EditBoxSearch,"")
            self:UpdatePetList()
        end
    end)

    for k,v in ipairs(self.tbBtnSkill) do
        UIHelper.BindUIEvent(self.tbBtnSkill[k],EventType.OnClick,function ()
            self:OnClickPetTipsSkill(k)
        end)
    end

    for k,v in ipairs(self.tbBtnPetDes) do
        UIHelper.BindUIEvent(self.tbBtnPetDes[k],EventType.OnClick,function ()
            self:OnClickPetDes(k)
        end)
    end

    UIHelper.BindUIEvent(self.BtnRelationship,EventType.OnClick,function ()
        TipsHelper.ShowNodeHoverTips(PREFAB_ID.WidgetPublicLabelTips,nil,g_tStrings.STR_PET_FETTERS_DES)
    end)

    UIHelper.BindUIEvent(self.BtnSendToChat, EventType.OnClick, function ()
        if not self.tPets then return end
        local nCurIndex = self.bShowPrefer and self.nCurLikeIndex or self.nCurIndex
        if not nCurIndex then return end
        if not self.tPets[nCurIndex] then return end

        local nPetIndex = self.tPets[nCurIndex].dwPetIndex
        if nPetIndex then
            ChatHelper.SendPetToChat(nPetIndex)
        end
    end)

    UIHelper.BindUIEvent(self.BtnRanking, EventType.OnClick, function ()
        UIMgr.Open(VIEW_ID.PanelFengYunLu, FengYunLuCategory.Friend, 14)
    end)

    UIHelper.BindUIEvent(self.BtnTipDes1, EventType.OnClick, function ()
        TipsHelper.ShowNodeHoverTips(PREFAB_ID.WidgetPublicLabelTips,self.BtnTipDes1, g_tStrings.STR_PET_TIPS1)
    end)

    UIHelper.BindUIEvent(self.BtnTipDes2, EventType.OnClick, function ()
        TipsHelper.ShowNodeHoverTips(PREFAB_ID.WidgetPublicLabelTips,self.BtnTipDes2, g_tStrings.STR_PET_TIPS2)
    end)
end

function UIPetMapView:RegEvent()
    --Event.Reg(self, EventType.XXX, func)
    Event.Reg(self,EventType.OnTouchViewBackGround,function ()
        UIHelper.SetVisible(self.WidgetSiftTips,false)
        UIHelper.SetVisible(self.WidgetTagTips,false)
    end)

    Event.Reg(self, EventType.HideAllHoverTips, function ()
        UIHelper.SetVisible(self.scriptView._rootNode, false)
    end)

    Event.Reg(self,"ADD_PREFER_FELLOW_PET",function (nPetIndex)
        if nPetIndex == 0 then
            TipsHelper.ShowNormalTip(g_tStrings.STR_PREFER_PET_TOO_MUCH)
        elseif nPetIndex == -1 then
            TipsHelper.ShowNormalTip(g_tStrings.STR_PREFER_PET_FAILED)
        else
            TipsHelper.ShowNormalTip(g_tStrings.STR_PREFER_PET_ADD_SUCCESS)
            self:AddOrDelPreferPet(nPetIndex)
        end
    end)

    Event.Reg(self,"DEL_PREFER_FELLOW_PET",function (nPetIndex)
        if nPetIndex == 0 then
            TipsHelper.ShowNormalTip(g_tStrings.STR_PREFER_PET_TOO_MUCH)
        elseif nPetIndex == -1 then
            TipsHelper.ShowNormalTip(g_tStrings.STR_PREFER_PET_FAILED)
        else
            self:AddOrDelPreferPet(nPetIndex)
        end
    end)

    Event.Reg(self,"ON_FELLOW_PET_DATEUPDATAE",function ()
        self:UpdateInfo()
    end)

    Event.Reg(self,"UPDATE_FELLOW_PET_DATA_TO_OTHER_PLAYER",function ()
        self:UpdateInfo()
    end)

    --召唤成功
    Event.Reg(self,"UPDATE_FELLOW_PET_INDEX",function (nPetIndex)
        self.nPetIndex = nPetIndex
        TipsHelper.ShowNormalTip("已成功召回宠物")
        self:UpdatePetTipsInfo()
    end)

    Event.Reg(self,EventType.OnSelectPetMedal,function (k,v)
        self.nGroupID = k
        self.nGroupIndex = v
        self:UpdateMedalInfo()
    end)

    Event.Reg(self, EventType.OnFilter, function(szKey, tbSelected)
        if szKey == FilterDef.Pet.Key then
            self.nCurFilterGenre = tbSelected[1][1] - 1
            self.nCurFilterType = tbSelected[2][1] - 1
            self.nCurFilterSource = tbSelected[3][1] - 1
            self.nSortWay = tbSelected[4][1]
            self.nCurIndex = 1
            self.nPageIndex = 1
            self:UpdatePetList()
        end
    end)

    Event.Reg(self, EventType.OnMiniSceneLoadProgress, function(nProcess)
        if nProcess >= 100 then
            local tbFrame = NpcModelPreview_GetRegisterFrame("NewPet", "NewPet")
            if tbFrame and tbFrame.hNpcModelView and
                tbFrame.hNpcModelView.m_scene and
                not QualityMgr.bDisableCameraLight
             then
                tbFrame.hNpcModelView.m_scene:OpenCameraLight(QualityMgr.szCameraLightForUI)
            end
        end
    end)

    Event.Reg(self, EventType.OnGameNumKeyboardOpen, function(editbox)
        if editbox ~= self.EditPaginate then return end
        UIHelper.SetEditBoxGameKeyboardRange(self.EditPaginate, 1, self.nPageCount)
    end)

    Event.Reg(self, EventType.OnGameNumKeyboardChanged, function(editbox, num)
        if editbox ~= self.EditPaginate then return end

        local nPageIndex = tonumber(UIHelper.GetString(self.EditPaginate))
        if nPageIndex ~= self.nPageIndex then
            if nPageIndex < 1 then
                self.nPageIndex = 1
            elseif nPageIndex > self.nPageCount then
                self.nPageIndex = self.nPageCount
            else
                self.nPageIndex = nPageIndex
            end
            if self.nPageIndex ~= nPageIndex then
                UIHelper.SetString(self.EditPaginate, self.nPageIndex)
            end
            self.nCurIndex = self.nPageIndex * nPagePetCount + 1
            self:UpdatePetShow()
        end
    end)

    Event.Reg(self, EventType.OnGetAdventurePetTryBook, function (tPetTryMap)
        self.tPetTryMap = tPetTryMap
        self:UpdatePetTipsInfo()
    end)

    Event.Reg(self, EventType.OnGuideItemSource, function(nIndex)
        local nCurIndex = self.bShowPrefer and self.nCurLikeIndex or self.nCurIndex
        local tInfo = self.tPets[nCurIndex]

        for i, v in pairs(SplitString(tInfo.szSourceList, ";")) do
            if i == nIndex then
                local nSource = tonumber(v)
                if nSource == SOURCE.POINT_REWARD or nSource == SOURCE.OPERATION_ACTIVITY then
                    local bEnableBuy = _G.CoinShop_PetIsInShop(tInfo.dwPetIndex)
                    if bEnableBuy then
                        UIHelper.TempHideMiniSceneUntilNewViewClose(self, self.MiniScene, self.hModelView, VIEW_ID.PanelExteriorMain,nil)
                    end
                end
            end

        end
    end)

    Event.Reg(self, EventType.OnViewOpen, function (nViewID)
        if nViewID == VIEW_ID.PanelDungeonInfo then
            UIHelper.SetVisible(self.MiniScene, false)
        end
    end)

    Event.Reg(self, EventType.OnViewClose, function (nViewID)
        if nViewID == VIEW_ID.PanelDungeonInfo then
            UIHelper.SetVisible(self.MiniScene, true)
        end
    end)

    Event.Reg(self, EventType.OnWindowsSizeChanged, function ()
        Timer.AddFrame(self, 1, function ()
            UIHelper.LayoutDoLayout(self.LayoutInteoduce)
            UIHelper.ScrollViewDoLayoutAndToTop(self.ScrollViewContent)
        end)
    end)
end

function UIPetMapView:UnRegEvent()
    --Event.UnReg(self, EventType.XXX)
end






-- ----------------------------------------------------------
-- Please write your own code below  ↓↓↓
-- ----------------------------------------------------------

function UIPetMapView:InitMyPet()
    self:InitLuckyTable()
    self:InitSearch()
    self:InitPreferPet()
    self:InitPetModel()
    self.nPetIndex = 0
    local tPet = g_pClientPlayer.GetFellowPet()
    if tPet then
        self.nPetIndex = GetFellowPetIndexByNpcTemplateID(tPet.dwTemplateID)
    end
    UIHelper.ScrollViewDoLayoutAndToTop(self.ScrollViewSiftTips)

    self:ApplyPetTryList()
end

function UIPetMapView:ApplyPetTryList()
    local tAdventureList = Table_GetAdventure()
    local tPetTryList = {}

    for _, v in ipairs(tAdventureList) do
        v.bCanSee = false
        local nCamp = g_pClientPlayer.nCamp
		if kmath.bit_and(2^nCamp, v.nCampCanSee) ~= 0 then
			v.bCanSee = true
		end

        if v.nClassify == 1 then
            local tTryBook = Table_GetAdventureTryBook(v.dwID)
            if tTryBook and #tTryBook ~= 0 and v.bCanSee then
                table.insert(tPetTryList, v.dwID)
            end
        end
    end

    RemoteCallToServer("On_QiYu_PetTryList", tPetTryList)
end

function UIPetMapView:InitOtherPet()
    PeekOtherPetList(self.dwPlayerID)
    self:InitSearch()
    UIHelper.SetString(self.LabelBeltPetTittle, "他的称号：")
    UIHelper.SetString(self.LabelMyPet, "他的宠物：")
    UIHelper.SetVisible(self.BtnRanking)
    UIHelper.SetVisible(self.ToglikeBtn,false)
end

function UIPetMapView:InitPetModel()
    local scene = SceneHelper.Create(Const.COMMON_SCENE, true, true, true)

    local tPos = UICameraTab["Pet"]["default"]["tbModelTranslation"]
    local tCamera = clone(tPetCamera)
    ExteriorCharacter.AddCameraPos(tCamera, tPos)
    local tNpcParam =
    {
        szName = "NewPet",
        szFrameName = "NewPet",
        szFramePath = "Normal/NewPet",
        Viewer = self.MiniScene,
        scene = scene,
        bNotMgrScene = false,
        tPos = tPos,
        tCamera = tCamera,
        tRadius = tNpcRadius,
        tHorAngle = tHorAngle,
        tVerAngle = tVerAngle,
    }
    RegisterNpcModelPreview(tNpcParam)

    self:UpdateCamera()
end

function UIPetMapView:UpdateCamera(dwPetIndex)
    if not NpcModelPreview.tResisterFrame then return end
    if not NpcModelPreview.tResisterFrame["NewPet"] then return end

    local tbFrame = NpcModelPreview.tResisterFrame["NewPet"]["NewPet"]
    if not tbFrame then return end

    local hModelView = tbFrame.hNpcModelView
    if not hModelView then return end

    local tbCamera = dwPetIndex and UICameraTab["Pet"][dwPetIndex] or UICameraTab["Pet"]["default"]
    NpcModelPreview_SetCameraPosition("NewPet", "NewPet",{
        tbCamera.tbCameraPos[1], tbCamera.tbCameraPos[2],tbCamera.tbCameraPos[3],
        tbCamera.tbCameraLookPos[1],tbCamera.tbCameraLookPos[2],tbCamera.tbCameraLookPos[3]})

    hModelView:SetCameraPos(unpack(tbCamera.tbCameraPos))
    hModelView:SetCameraLookPos(unpack(tbCamera.tbCameraLookPos))
    hModelView:SetCameraPerspective(unpack(tbCamera.tbCameraPerspective))
    hModelView:SetTranslation(unpack(tbCamera.tbModelTranslation))
    hModelView:SetYaw(tbCamera.nModelYaw)
end

function UIPetMapView:InitSearch()
    local tSearchList = Table_GetFellowPet_SearchList()
    local tType = {}
    for i = 1, #tSearchList[1] do
        table.insert(tType, tSearchList[1][i][2])
    end
    self.tFilterType = tType
    self.nCurFilterType = 0  --筛选种类
    local tSource = {}
    for i = 1, #tSearchList[2] do
        table.insert(tSource, tSearchList[2][i])
    end
    self.tFilterSource = tSource
    self.nCurFilterSource = 0 --筛选途径
    self.tFilterGenre = {true,false}
    self.nCurFilterGenre = 0 -- 筛选类型

    self.nSortWay = 1
    -- local tSortList = Table_GetFellowPet_SortList()
end

function UIPetMapView:InitLuckyTable()
    self._tLuckyScore = {}
    local tTime = TimeLib.GetTodayTime()
    local szMonth = tTime.month
    local szDay = string.format("%02d", tTime.day)
    local szDate = szMonth .. szDay
    local tLuckyPet = GetLuckyFellowPet(szDate)
    for _, dwLuckyPetIndex in pairs(tLuckyPet) do
        self._tLuckyScore[dwLuckyPetIndex] = LUCKY_PET_SCORE
    end
end

function UIPetMapView:InitPreferPet()
    local nPreferCount = self:GetPreferPetCount()
    self.tPreferPetList = {}
    for i = 1,nPreferCount,1 do
        local dwPetIndex = self:GetPreferPetIndex(i)
        table.insert(self.tPreferPetList,dwPetIndex)
    end
end

function UIPetMapView:UpdateInfo()
    self:UpdateScore()
    self:UpdatePetList()
    self:UpdateMedalCollect()
end

function UIPetMapView:UpdateScore()
    --宠物分数
    local nPetScore = self:GetAcquiredFellowPetScore()
    local nMedalScore = self:GetAcquiredFellowPetMedalScore()
    local num = nPetScore + nMedalScore
    local szName = Table_GetFellowPet_Achievement(num)
    UIHelper.SetString(self.LabelBeltPet1,UIHelper.GBKToUTF8(szName))
    UIHelper.SetString(self.LabelBeltPet01,num)
    --我的宠物数量
    local nPetCount = self:GetFellowPetCount()
    UIHelper.SetString(self.LabelMyPet01,nPetCount)
    --奇遇宠物
    local nAdvPetAll, nAdvPetAcquired = self:GetAdventurePetCount()
    UIHelper.SetString(self.LabelAdventurePet01,nAdvPetAcquired.."/"..nAdvPetAll)
    --探索宠物
    nAdvPetAll, nAdvPetAcquired = self:GetExplorePetCount()
    UIHelper.SetString(self.LabelTanSuoPet01,nAdvPetAcquired.."/"..nAdvPetAll)
    UIHelper.SetString(self.LabelBeltPet2,UIHelper.GBKToUTF8(szName))
    UIHelper.SetString(self.LabelBeltPet02,num)

    Timer.AddFrame(self, 1, function ()
        UIHelper.LayoutDoLayout(self.LayoutRightTop)
        UIHelper.LayoutDoLayout(self.LayoutRightTop1)
    end)
end

function UIPetMapView:GetAdventurePetCount()
    local nAll, nAcquired = 0, 0
    local tPets = Table_GetAllFellowPet()
    for _, tInfo in pairs(tPets) do
        local tSource = SplitString(tInfo.szSourceList, ";")
        for _, v in pairs(tSource) do
            if tonumber(v) == SOURCE.WORLD_ADVENTURE or tonumber(v) == SOURCE.POINT_REWARD then
                nAll = nAll + 1
                if self:IsFellowPetAcquired(tInfo.dwPetIndex) then
                    nAcquired = nAcquired + 1
                end
            end
        end
    end
    return nAll, nAcquired
end

function UIPetMapView:GetExplorePetCount()
    local nAll, nAcquired = 0, 0
    local tPets = Table_GetAllFellowPet()
    for _, tInfo in pairs(tPets) do
        local tSource = SplitString(tInfo.szSourceList, ";")
        for _, v in pairs(tSource) do
            local nSource = tonumber(v)
            if nSource == SOURCE.EXPLORE then
                nAll = nAll + 1
                if self:IsFellowPetAcquired(tInfo.dwPetIndex) then
                    nAcquired = nAcquired + 1
                end
            end
        end
    end
    return nAll, nAcquired
end

function UIPetMapView:UpdatePetList()
    self.tPets = self:GetSearchPetList()

    if self.bMySelf then
        self.nCurIndex = self.nCurIndex or 1
        self.nCurLikeIndex = self.nCurLikeIndex or 1
    else
        if not self.bLoadPetModel then
            if #self.tPets == 0 then
                self.bEmptyPets = true
                UIHelper.SetVisible(self.WidgetEmpty,true)
                UIHelper.SetString(self.LabelDescibe, "对方暂未拥有宠物")
                UIHelper.SetVisible(self.WidgetBtn,false)
                UIHelper.SetVisible(self.WidgetAnchorLeft,false)
                UIHelper.SetVisible(self.WidgetAnchorRightBotton,false)
            end
            -- if not self.bEmptyPets then
                self:InitPetModel()
            -- end
            self.bLoadPetModel = true
        end
    end

    self.nPageCount = math.ceil(#self.tPets/nPagePetCount) or 0
    UIHelper.SetString(self.LabelPaginate, "/"..self.nPageCount)

    UIHelper.SetString(self.EditPaginate, self.nPageIndex)
    self:UpdatePetShow()
end



function UIPetMapView:GetSearchPetList()
    local tPets = self:GetPetList()
    tPets = self:SortPetLiat(tPets)
    local tSearchPets = self:GetSearchPet(tPets)
    return tSearchPets
end

function UIPetMapView:GetPetList()
    local tPets = {}
    if self.bShowPrefer then
        for _, dwPetIndex in ipairs(self.tPreferPetList) do
            local tPet = Table_GetFellowPet(dwPetIndex)
            table.insert(tPets, tPet)
        end
    elseif self.bMySelf then
        tPets = Table_GetAllFellowPet()
    else
        local tAllPets = Table_GetAllFellowPet()
        for _,tInfo in ipairs(tAllPets) do
            local bHave = self:IsFellowPetAcquired(tInfo.dwPetIndex)
            if bHave then
                table.insert(tPets,tInfo)
            end
        end
    end
    return tPets
end

function UIPetMapView:GetSearchPet(tPets)
    local szSearch = UIHelper.GetString(self.EditBoxSearch)

    local tSearchPets = {}
    for _k,tInfo in ipairs(tPets) do
        local bCondition1 , bCondition2, bCondition3, bCondition4 = false, false, false, false
        local bCondition5 = false
        local tClass = SplitString(tInfo.szTypeList, ";")
        local tSource = SplitString(tInfo.szSourceList, ";")
        if szSearch ~= "" then
            if string.find( UIHelper.GBKToUTF8(tInfo.szName), szSearch) then
                bCondition1 = true
            end
        else
            bCondition1 = true
        end
        if self.nCurFilterGenre ~= 0 then
            if self.nCurFilterGenre == 3 then
                bCondition2 = self:IsLuckyPet(tInfo.dwPetIndex)
            else
                local bHave = self:IsFellowPetAcquired(tInfo.dwPetIndex)
                if bHave == self.tFilterGenre[self.nCurFilterGenre] then
                    bCondition2 = true
                end
            end
        else
            bCondition2 = true
        end
        if self.nCurFilterType ~= 0 then
            for _, v in pairs(tClass) do
                if tonumber(v) == self.nCurFilterType then
                    bCondition3 = true
                    break
                end
            end
        else
            bCondition3 = true
        end
        if self.nCurFilterSource ~= 0 then
            for _, v in pairs(tSource) do
                if tonumber(v) == self.tFilterSource[self.nCurFilterSource][1] then
                    if tonumber(v) == SOURCE.FORCE then
                        bCondition4 = g_pClientPlayer.dwForceID == tInfo.dwForceID
                    else
                        bCondition4 = true
                    end
                    break
                end
            end
        else
            bCondition4 = true
        end
        local bHave = self:IsFellowPetAcquired(tInfo.dwPetIndex)
        if not bHave then
            if not tInfo.bOnlyHaveShow then
                bCondition5 = true
            end
        else
            bCondition5 = true
        end
        if bCondition1 and bCondition2 and bCondition3 and bCondition4 and bCondition5 then
            table.insert(tSearchPets, tInfo)
        end
    end
    return tSearchPets
end

function UIPetMapView:UpdatePetShow()
    UIHelper.RemoveAllChildren(self.ScrollViewList)
    local tPetIconItem = {}
    local nPageIndex = self.bShowPrefer and 1 or self.nPageIndex
    local nIndex1 = nPagePetCount * (nPageIndex - 1) + 1
    local nIndex2 = nIndex1 + nPagePetCount - 1

    for nIndex = nIndex1, nIndex2, 1 do
        local tPetInfo = self.tPets[nIndex]
        if tPetInfo then
            local bHave = self:IsFellowPetAcquired(tPetInfo.dwPetIndex)
            local PetIconItem = UIHelper.AddPrefab(PREFAB_ID.WidgetPetIcon_80, self.ScrollViewList, tPetInfo.dwPetIndex, self.tPetTryMap, bHave)
            if PetIconItem then
                UIHelper.SetString(PetIconItem.LabelPetName, UIHelper.GBKToUTF8(tPetInfo.szName))
                UIHelper.SetVisible(PetIconItem.ImgTag, self:IsLuckyPet(tPetInfo.dwPetIndex))
                UIHelper.SetVisible(PetIconItem.ImglRemind, tPetInfo.bIdentityYS)
                UIHelper.SetVisible(PetIconItem.ImgTime, tPetInfo.bLimitTime)
                UIHelper.SetSpriteFrame(PetIconItem.ImgPolishCountBG, ItemQualityBGColor[tPetInfo.nQuality + 1])

                local tPet = Table_GetFellowPet(tPetInfo.dwPetIndex)
                UIHelper.SetItemIconByIconID(PetIconItem.ImgPetIcon80, tPet.nIconID)

                UIHelper.BindUIEvent(PetIconItem.BtnPetDes, EventType.OnSelectChanged, function (btn, bSelected)
                    if PetIconItem.BtnPetDes == btn and bSelected then
                        if self.bShowPrefer then
                            self.nCurLikeIndex  = nIndex
                        else
                            self.nCurIndex = nIndex
                        end

                        self:UpdatePetInfo()
                        UIHelper.SetVisible(self.WidgetTagTips,false)

                        local bIsNew = RedpointHelper.Pet_IsNew(tPet.dwPetIndex)
                        UIHelper.SetVisible(PetIconItem.ImgNew, bIsNew)
                    end
                end)

                UIHelper.SetNodeGray(PetIconItem.ImgPetIcon80, not bHave, true)
                UIHelper.SetOpacity(PetIconItem.ImgPetIcon80, bHave and 255 or 120)
                table.insert(tPetIconItem, PetIconItem)

                -- 新
                local bIsNew = RedpointHelper.Pet_IsNew(tPet.dwPetIndex)
                UIHelper.SetVisible(PetIconItem.ImgNew, bIsNew)
            end
        end
    end

    UIHelper.ScrollViewDoLayoutAndToTop(self.ScrollViewList)
    UIHelper.SetVisible(self.ScrollViewList, #self.tPets ~= 0)

    UIHelper.ScrollViewSetupArrow(self.ScrollViewList, self.WidgetArrow)
    UIHelper.SetVisible(self.WidgetArrow, #self.tPets > 12)

    local nCurIndex = self.bShowPrefer and self.nCurLikeIndex or self.nCurIndex
    local nIndex = nCurIndex > nPagePetCount and nCurIndex % nPagePetCount or nCurIndex
    if nIndex == 0 then nIndex = nPagePetCount end
    if tPetIconItem[nIndex] then
        UIHelper.SetSelected(tPetIconItem[nIndex].BtnPetDes, true)
        if nIndex > (nPagePetCount / 2) then
            Timer.AddFrame(self, 1, function ()
                UIHelper.ScrollToIndex(self.ScrollViewList, nIndex - 1)
            end)
        end
    else
        self:UpdatePetInfo()
    end

    if RedpointHelper.Pet_HasRedPoint() then
        RedpointHelper.Pet_ClearAll()
    end
end

function UIPetMapView:UpdatePetInfo()
    if UIMgr.GetView(VIEW_ID.PanelSentTaskDetails) then
        UIMgr.Close(VIEW_ID.PanelSentTaskDetails)
    end
    self:UpdatePetTipsInfo()
    self:UpdatePetModel()
end

local function BigIntSub(nLeft, nRight)
    return nLeft - nRight
end

function UIPetMapView:UpdatePetTipsInfo()
    local nCurIndex = self.bShowPrefer and self.nCurLikeIndex or self.nCurIndex
    local tInfo = self.tPets[nCurIndex]

    UIHelper.SetVisible(self.WidgetPaginate,(tInfo and true or false) and (not self.bShowPrefer))
    UIHelper.SetVisible(self.WidgetAnchorRightBotton,tInfo and true or false)
    UIHelper.SetVisible(self.WidgetBtn,tInfo and true or false)
    UIHelper.SetVisible(self.WidgetEmpty,not tInfo)

    if not tInfo then
        return
    end

    --福缘
    local bLucky = self:IsLuckyPet(tInfo.dwPetIndex)
    UIHelper.SetVisible(self.WidgetTag,bLucky)
    --名字
    UIHelper.SetString(self.LabelPetNeme,UIHelper.GBKToUTF8(tInfo.szName))
    Timer.AddFrame(self, 1, function ()
        UIHelper.LayoutDoLayout(self.LayoutPetNeme)
    end)
    --喜爱
    local bPrefer =  table.contain_value(self.tPreferPetList, tInfo.dwPetIndex)
    UIHelper.SetVisible(self.Imglike,bPrefer)
    UIHelper.SetVisible(self.Imglike01, not bPrefer)
    UIHelper.SetVisible(self.Toglike, self.bMySelf)
    --品质
    self.scriptQualityBar = self.scriptQualityBar or UIHelper.AddPrefab(PREFAB_ID.WidgetQualityBar, self.WidgetTittle, (tInfo.nQuality or 1) + 1)
    Timer.AddFrame(self, 1, function ()
        if self.scriptQualityBar then
            self.scriptQualityBar:OnEnter((tInfo.nQuality or 1) + 1)
        end
    end)
    --分数
    local nScore = GetFellowPetScore(tInfo.dwPetIndex)
    UIHelper.SetString(self.LabelBeltPetScore,nScore)
    --星级
    for i = 1,5,1 do
        UIHelper.SetVisible(self.tbImgStarLight[i], i <= tInfo.nStar)
    end
    --类型
    local tClass = SplitString(tInfo.szTypeList, ";")
    for _, v in pairs(tClass) do
        if self.tFilterType[tonumber(v)] then
            UIHelper.SetRichText(self.RichTextInteoduce01,UIHelper.GBKToUTF8(self.tFilterType[tonumber(v)]))
        end
    end
    --驭兽
    UIHelper.SetVisible(self.RichTextInteoduce02,tInfo.bIdentityYS)
    UIHelper.SetRichText(self.RichTextInteoduce02,"<img src='UIAtlas2_Pet_PetRelationship_XuShou' width='28' height='33'/> "..UIHelper.GBKToUTF8(tInfo.szYSDes))
    --tips
    local szTip = ParseTextHelper.ParseNormalText(UIHelper.GBKToUTF8(tInfo.szDesc), false)
    local bHave = self:IsFellowPetAcquired(tInfo.dwPetIndex)
    local tTimeLimit = nil
    if bHave then
        tTimeLimit = g_pClientPlayer.GetFellowPetTimeLimit(tInfo.dwPetIndex)--判断是否限时（没有拥有的宠物会报错）
    end
    if tTimeLimit then
        local nExistTime = BigIntSub(GetCurrentTime(), tTimeLimit.nGenTime)
        if tTimeLimit.nExistType == ITEM_EXIST_TYPE.OFFLINE then
            local nLeftTime = tTimeLimit.nMaxExistTime
            szTip = szTip .. GetFormatText("\n")
            if nLeftTime > 0 then
                local szTime = Timer.FormatInChinese4(nLeftTime)
                szTip = szTip .. FormatString(g_tStrings.STR_ITEM_OFF_LINE_TIME_OVER, szTime)
            else
                szTip = szTip .. GetFormatText(g_tStrings.STR_ITEM_TIME_TYPE1.."\n", 107)
            end
        elseif tTimeLimit.nExistType == ITEM_EXIST_TYPE.ONLINE then
            szTip = szTip .. GetFormatText("\n")
            local nLeftTime = BigIntSub(tTimeLimit.nMaxExistTime , nExistTime)
            if nLeftTime > 0 then
                local szTime = Timer.FormatInChinese4(nLeftTime)
                szTip = szTip..FormatString(g_tStrings.STR_ITEM_ON_LINE_TIME_OVER, szTime)
            else
                szTip = szTip..GetFormatText(g_tStrings.STR_ITEM_TIME_TYPE2.."\n", 107)
            end
        elseif tTimeLimit.nExistType ==  ITEM_EXIST_TYPE.ONLINEANDOFFLINE or tTimeLimit.nExistType == ITEM_EXIST_TYPE.TIMESTAMP then
            local nLeftTime
            if tTimeLimit.nExistType == ITEM_EXIST_TYPE.ONLINEANDOFFLINE then
                nLeftTime = BigIntSub(tTimeLimit.nMaxExistTime, nExistTime)
            else
                nLeftTime = BigIntSub(tTimeLimit.nMaxExistTime, tTimeLimit.nGenTime)
                nLeftTime = BigIntSub(nLeftTime, nExistTime)
            end
            szTip = szTip .. GetFormatText("\n")
            if nLeftTime > 0 then
                local szTime = Timer.FormatInChinese4(nLeftTime)
                szTip = szTip..string.format(g_tStrings.STR_ITEM_TIME_OVER, szTime)
            else
                szTip = szTip..GetFormatText(g_tStrings.STR_ITEM_TIME_TYPE3.."\n", 107)
            end
        end
    end

    UIHelper.SetRichText(self.RichTextInteoduce03,szTip)
    --线索
    self:UpdatePetSourceTip(tInfo)
    --技能
    self:UpdatePetTipsSkill(tInfo)
    --按钮
    self:UpdatePetTipsBtn(tInfo)

    Timer.AddFrame(self, 1, function ()
        UIHelper.LayoutDoLayout(self.LayoutInteoduce)
        UIHelper.ScrollViewDoLayoutAndToTop(self.ScrollViewContent)
    end)
end

function UIPetMapView:UpdatePetSourceTip(tInfo)
    local szTip = ParseTextHelper.ParseNormalText(UIHelper.GBKToUTF8(tInfo.szOutputDes), false)
    UIHelper.SetRichText(self.RichTextInteoduce05, szTip)

    if self.bMySelf then
        local nTabType, nTabIndex = GetItemIndexByFellowPetIndex(tInfo.dwPetIndex)
        local tSource = ItemData.GetItemSourceList(nTabType, nTabIndex)
        local bHave = self:IsFellowPetAcquired(tInfo.dwPetIndex)

        if tSource then
            self:UpdateItemSource(tSource, nTabType, nTabIndex, tInfo)
            UIHelper.SetVisible(self.WidgetQiYuPetTag, #tSource.tAdventure ~= 0)
            UIHelper.SetVisible(self.WidgetQiYuDes, #tSource.tAdventure ~= 0 and not bHave)

            --奇遇
            if #tSource.tAdventure ~= 0 then
                self:UpdateAdventure(tSource.tAdventure[1])
            end
        else
            UIHelper.SetVisible(self.LayoutTrace, false)
            UIHelper.SetVisible(self.WidgetTraceDesTitle, false)
            UIHelper.SetVisible(self.WidgetQiYuDes, false)
            UIHelper.SetVisible(self.WidgetQiYuPetTag, false)
            UIHelper.SetVisible(self.RichTextInteoduce05, szTip and szTip ~= "")
        end
    end
end

function UIPetMapView:UpdateItemSource(tSource, dwItemType, dwItemIndex, tInfo)
    local bIsActivityOn = false
	if tSource.tActivity and tSource.tActivity[1] then
		local dwActivityID = tSource.tActivity[1]
		bIsActivityOn = UI_IsActivityOn(dwActivityID) or ActivityData.IsActivityOn(dwActivityID)
	else
		bIsActivityOn = true
	end

    local tbInfo = {}
    tbInfo[1] = {}

    ItemData.GetItemSourceActivity(tSource.tActivity, tbInfo)
    if bIsActivityOn then
		ItemData.GetItemSourceShop(tSource.tShop, tbInfo, dwItemType, dwItemIndex)
		if not tSource.tShop or #tSource.tShop == 0 then
			ItemData.GetSourceShopNpcTip(tSource.tSourceNpc, tbInfo)
		end
		ItemData.GetSourceQuestTip(tSource.tQuests, tbInfo, g_pClientPlayer)
	end

    if tSource.bTrades then
		if tSource.tLinkItem and #tSource.tLinkItem > 0 then
			local tLinkItemInfo = tSource.tLinkItem[1]
			if tLinkItemInfo then
                ItemData.GetSourceTradeTip(tSource.bTrades, tbInfo, tLinkItemInfo[1], tLinkItemInfo[2])
			end
		else
            ItemData.GetSourceTradeTip(tSource.bTrades, tbInfo, dwItemType, dwItemIndex)
		end
	end

    ItemData.GetSourceProduceTip(tSource.tSourceProduce, tbInfo)
    ItemData.GetSourceCollectD(tSource.tSourceCollectD, tbInfo)
    ItemData.GetSourceCollectN(tSource.tSourceCollectN, tbInfo)
    ItemData.GetSourceBossTip(tSource.tBoss, tbInfo)
    ItemData.GetSourceFromItemTip(tSource.tItems, tbInfo)
	ItemData.GetItemSourceCoinShop(tSource.tCoinShop, tbInfo)
    ItemData.GetItemSourceReputation(tSource.tReputation, tbInfo)
	ItemData.GetItemSourceAchievement(tSource.tAchievement, tbInfo)
	ItemData.GetItemSourceAdventure(tSource.tAdventure, tbInfo)
	ItemData.GetSourceOpenPanelTip(tSource.tFunction, tSource.tEventLink, tbInfo)

    UIHelper.RemoveAllChildren(self.LayoutTrace)
    if tbInfo[1] then
        for k, v in ipairs(tbInfo[1]) do
            local scriptItemSourceInfo = UIHelper.AddPrefab(PREFAB_ID.WidgetItemTipContent10TraceCell, self.LayoutTrace)
            if scriptItemSourceInfo then
                scriptItemSourceInfo:OnEnter(v, k)
                if v then
                    local szLinkInfo = v.szLinkInfo
                    if string.is_nil(szLinkInfo) then
                        return
                    end
                    local szLinkEvent, szLinkArg = szLinkInfo:match("(%w+)/(.*)")
                    if szLinkEvent == "Exterior" then
                        UIHelper.BindUIEvent(scriptItemSourceInfo.BtnTrace, EventType.OnClick, function()
                            Event.Dispatch("EVENT_LINK_NOTIFY", szLinkInfo)
                            Event.Dispatch(EventType.HideAllHoverTips)
                            Event.Dispatch(EventType.OnGuideItemSource, k)
                            UIHelper.TempHideMiniSceneUntilNewViewClose(self, self.MiniScene, self.hModelView, VIEW_ID.PanelExteriorMain,nil)
                        end)
                    end
                end
            end
        end
    end

    UIHelper.SetVisible(self.LayoutTrace, (tbInfo[1] and tbInfo[1][1]) and true or false)
    UIHelper.SetVisible(self.WidgetTraceDesTitle, (tbInfo[1] and tbInfo[1][1]) and true or false)
    UIHelper.SetVisible(self.RichTextInteoduce05, (not (tbInfo[1] and tbInfo[1][1])) and true or false)
end

function UIPetMapView:UpdateAdventure(dwAdvID)
    local tAdventureInfo = Table_GetAdventureByID(dwAdvID)
    local eType = 0
    if tAdventureInfo.nClassify == 2 then
        if tAdventureInfo.bPerfect then
            eType = 2
        else
            eType = 1
        end
    end

    local nChanceState = GDAPI_IfAdvenCanTry(tAdventureInfo.dwID, eType)

    if nChanceState == ADVENTURE_CHANCE_STATE.OK and self.tPetTryMap then
        if self.tPetTryMap[tonumber(dwAdvID)] then
            local tTryBook = Table_GetAdventureTryBook(tAdventureInfo.dwID)
            UIHelper.SetRichText(self.RichTextQiYuCount, self.tPetTryMap[tonumber(dwAdvID)] .. "/" .. tTryBook[1].nTryMax)

            local tDaily = {}
            for _, tTry in ipairs(tTryBook) do
                if tTry.nFreshType == 1 then
                    table.insert(tDaily, tTry)
                end
            end

            for _, tTry in ipairs(tDaily) do
                UIHelper.SetRichText(self.RichTextQiYuContent, UIHelper.GBKToUTF8(tTry.szDesc))
            end
        else
            UIHelper.SetRichText(self.RichTextQiYuCount, "")
        end
    else
        UIHelper.SetRichText(self.RichTextQiYuContent, g_tStrings.STR_PET_ADVEBTURE_TIPS)
        UIHelper.SetRichText(self.RichTextQiYuCount, "")
    end
end

function UIPetMapView:UpdatePetTipsSkill(tInfo)
    local tSkill = Table_GetFellowPetSkill(tInfo.dwPetIndex) or {}
    for k,_ in ipairs(self.tbImgItem) do
        if tSkill[k] then
            local nIconID = Table_GetSkillIconID(tSkill[k][1], tSkill[k][2])
            UIHelper.SetItemIconByIconID(self.tbImgItem[k], nIconID)
            UIHelper.SetVisible(self.tbImgItem[k],true)
        else
            UIHelper.SetVisible(self.tbImgItem[k],false)
        end
    end
end

function UIPetMapView:OnClickPetTipsSkill(i)
    local nCurIndex = self.bShowPrefer and self.nCurLikeIndex or self.nCurIndex
    local tSkill = Table_GetFellowPetSkill(self.tPets[nCurIndex].dwPetIndex) or {}
    if tSkill[i] then
        local nSkillID,nLevel= tSkill[i][1],tSkill[i][2]
        local tSkillInfo = Table_GetSkill(nSkillID,nLevel)
        local szText = UIHelper.GBKToUTF8(tSkillInfo.szName).."\n"..UIHelper.GBKToUTF8(tSkillInfo.szDesc)
        local nX,nY = UIHelper.GetWorldPosition(self.LayoutItem)
        if self.scriptView then
            UIHelper.SetVisible(self.scriptView._rootNode, true)
            self.scriptView:OnEnter(szText)
            local nSizeW,nSizeH = UIHelper.GetContentSize(self.scriptView._rootNode)
            UIHelper.SetWorldPosition(self.scriptView._rootNode, nX-nSizeW, nY-nSizeH/2)
        end
    end
end

function UIPetMapView:OnClickPetDes(i)
    local tPetTable = self.tMedal[self.nGroupID][self.nGroupIndex].tPetTable
    local nIndex = tPetTable["nFellowPetIndex" .. i]
    local tPet = Table_GetFellowPet(nIndex)
    if tPet then
        local _, scriptTips = TipsHelper.ShowClickHoverTips(PREFAB_ID.WidgetItemTip)
        --用了公用的预制，但是逻辑跟道具完全不同，手动设置一下内容
        self:UpdateMedalTipsBase(scriptTips,tPet)
        self:UpdateMedalTipsTop(scriptTips,tPet)
        self:UpdateMedalTipsInfo(scriptTips,tPet,nIndex)
        if self.bMySelf then
            scriptTips:SetBtnState({{
                szName = g_tStrings.STR_LOOK,
                OnClick = function ()
                    self:MedalTipsOnClick(tPet)
                end
            }})
        else
            scriptTips:SetBtnState({})
        end
        scriptTips:PlayAni()
    end
    UIHelper.SetString(self.LabelPetNeme,UIHelper.GBKToUTF8(tPet.szName))
end

function UIPetMapView:UpdateMedalTipsBase(scriptTips,tPet)
    UIHelper.SetString(scriptTips.LabelItemName,UIHelper.GBKToUTF8(tPet.szName)) -- 名字
    UIHelper.SetSpriteFrame(scriptTips.ImgQuality, ItemTipQualityBGColor[tPet.nQuality + 1]) -- 颜色栏
    UIHelper.AddPrefab(PREFAB_ID.WidgetQualityBar, scriptTips.WidgetPublicQualityBar, (tPet.nQuality or 1) + 1)

    UIHelper.SetVisible(scriptTips.LabelAttachStatus,false) -- 右上角隐藏
    local scriptItem = UIHelper.AddPrefab(PREFAB_ID.WidgetItem_100,scriptTips.WidgetItemIcon)
    scriptItem:OnInitWithIconID(tPet.nIconID,tPet.nQuality)  -- 小图标
end

function UIPetMapView:UpdateMedalTipsTop(scriptTips,tPet)
    local scriptEquipDescInfo = UIHelper.AddPrefab(PREFAB_ID.WidgetItemTipTopContent1, scriptTips.WidgetTopContent)
    if not scriptEquipDescInfo then return end
    UIHelper.SetString(scriptEquipDescInfo.LabelEquipType1,g_tStrings.tEquipTypeNameTable[EQUIPMENT_SUB.PET]) --类型
    UIHelper.SetVisible(scriptEquipDescInfo.LabelEquipType2,false)
    UIHelper.SetString(scriptEquipDescInfo.LabelEquipType3, "")
    UIHelper.SetVisible(scriptEquipDescInfo.ImgPlayType,false)
    local tLine = Table_GetFellowPet_Class(tPet.nClass)
    UIHelper.SetString(scriptEquipDescInfo.LabelPlayType,UIHelper.GBKToUTF8(tLine.szName))
    UIHelper.LayoutDoLayout(scriptEquipDescInfo.scriptEquipDescInfo)
    for k, _ in ipairs(scriptEquipDescInfo.tbImgStarEmpty) do
        UIHelper.SetVisible(scriptEquipDescInfo.tbImgStarLight[k], k <= tPet.nStar)
    end
end

function UIPetMapView:UpdateMedalTipsInfo(scriptTips,tPet,nIndex)
    local scriptEquipDescInfo = UIHelper.AddPrefab(PREFAB_ID.WidgetItemTipContent2, scriptTips.ScrollViewContent) --tips内容
    -- local tLine = Table_GetFellowPet_Class(tPet.nClass)
    local nScore = GetFellowPetScore(nIndex)
    local szTip = g_tStrings.STR_SCORE .. g_tStrings.STR_COLON .. nScore ..  "\n"
    szTip = szTip..ParseTextHelper.ParseNormalText(UIHelper.GBKToUTF8(tPet.szDesc)).."\n"
    szTip = szTip..ParseTextHelper.ParseNormalText(UIHelper.GBKToUTF8(tPet.szOutputDes)).."\n"
    scriptEquipDescInfo:OnEnter({szTip})
    UIHelper.ScrollViewDoLayoutAndToTop(scriptTips.ScrollViewContent)
end

function UIPetMapView:MedalTipsOnClick(tPet)
    UIHelper.SetSelected(self.TogNavigation01,true)
    self.bGather = true

    self:ClearFilterCondition()
    self:UpdatePetList()

    for k, v in ipairs(self.tPets) do
        if v.dwPetIndex == tPet.dwPetIndex then
            self.nCurIndex = k
            self.nPageIndex = math.ceil(self.nCurIndex / nPagePetCount)
            break
        end
    end

    UIHelper.SetString(self.EditPaginate, self.nPageIndex)
    self:UpdatePetShow()

    TipsHelper.DeleteAllHoverTips()
end

function UIPetMapView:ClearFilterCondition()
    self.nCurFilterGenre = 0
    self.nCurFilterType = 0
    self.nCurFilterSource = 0
    self.nSortWay = 1
    UIHelper.SetString(self.EditBoxSearch, "")
end

function UIPetMapView:UpdatePetTipsBtn(tInfo)
    if self.bMySelf then
        local bHave = self:IsFellowPetAcquired(tInfo.dwPetIndex)
        local bGoTo = self:IsGoToAcquirePet()
        local bEnable = self:IsGoToAcquirePetEnable()
        -- if not bHave and not bGoTo then bHave = true end
        UIHelper.SetString(self.LabelCell, tInfo.dwPetIndex == self.nPetIndex and g_tStrings.STR_CALL_BACK or g_tStrings.STR_CALL)
        UIHelper.SetVisible(self.BntCall, bHave)
        UIHelper.SetVisible(self.BntGo, not bHave and bGoTo and bEnable)
    else
        UIHelper.SetVisible(self.BntCall,false)
        UIHelper.SetVisible(self.BntGo, false)
    end
end

function UIPetMapView:UpdatePetModel()
    if self.bGather then
        if self.bEmptyPets then
            return
        end

        local tbFrame = NpcModelPreview.tResisterFrame["NewPet"]["NewPet"]
        self.hModelView = tbFrame.hNpcModelView

        self.hModelView:UnloadModel()

        local nCurIndex = self.bShowPrefer and self.nCurLikeIndex or self.nCurIndex
        local tPet = self.tPets[nCurIndex]
        if not tPet then return end
        local tbCamera = UICameraTab["Pet"][tPet.dwPetIndex] or UICameraTab["Pet"]["default"]

        self.hModelView:LoadNpcRes(tPet.dwModelID, false)
        APIHelper.SetNpcLODLvl(0)
        self.hModelView:LoadModel()
        APIHelper.SetNpcLODLvl()
        self.hModelView:SetDetail(tPet.nColorChannelTable, tPet.nColorChannel)
        self.hModelView:SetScaling(tPet.fModelScaleMB)
        self.hModelView:PlayAnimation("Idle", "loop")

        self:UpdateCamera(tPet.dwPetIndex)

        local model = tbFrame.hNpcModelView
        local camera = tbFrame.camera
        camera:set_mainplayer_pos(unpack(tbCamera.tbModelTranslation))
        UITouchHelper.BindModel(self.TouchContainer, model, camera, {tbFrame = tbFrame, bCanZoom = false})
    end
end

function UIPetMapView:CallPet()
    local nCurIndex = self.bShowPrefer and self.nCurLikeIndex or self.nCurIndex
    local dwPetIndex = self.tPets[nCurIndex].dwPetIndex
    local hPlayer = g_pClientPlayer
    if not hPlayer or dwPetIndex <= 0 then
        return
    end
    local bHave = self:IsFellowPetAcquired(dwPetIndex)
    if bHave then
        hPlayer.CreateFellowPetRequest(dwPetIndex)
        JiangHuData.bPeFirstCall = true
        UIMgr.Close(self)
    else
        OutputMessage("MSG_ANNOUNCE_NORMAL", g_tStrings.STR_CALL_PET_FAILED)
    end
end

function UIPetMapView:GoToAcquirePet()
    local nCurIndex = self.bShowPrefer and self.nCurLikeIndex or self.nCurIndex
    local tSource = SplitString(self.tPets[nCurIndex].szSourceList, ";")
    for _, v in pairs(tSource) do
        local nSource = tonumber(v)
        if nSource == SOURCE.WORLD_ADVENTURE then
            local nMapID = self.tPets[nCurIndex].nMapID
            local nLinkID = self.tPets[nCurIndex].nLinkID

            if HomelandData.CheckIsHomelandMapTeleportGo(nLinkID, nMapID, nil, nil, function ()
                UIMgr.Close(self)
                end) then
                return
            end

            if nMapID == 0 then
                TipsHelper.ShowNormalTip(g_tStrings.STR_FIND_PET_FAILED)
            else
                MapMgr.CheckTransferCDExecute(function()
                    RemoteCallToServer("On_Teleport_Go", nLinkID, nMapID)
                    UIMgr.Close(self)
                end, nMapID)
            end
        elseif nSource == SOURCE.POINT_REWARD or nSource == SOURCE.OPERATION_ACTIVITY then
            local bEnableBuy = _G.CoinShop_PetIsInShop(self.tPets[nCurIndex].dwPetIndex)
            if bEnableBuy then
                local szMsg = FormatString(g_tStrings.STR_GO_TO_PET_SHOP, UIHelper.GBKToUTF8(self.tPets[nCurIndex].szName))
                UIHelper.ShowConfirm(szMsg,function ()
                    local dwLogicID = Table_GetRewardsPetGoodID(self.tPets[nCurIndex].dwPetIndex)
                    local szLink = "Exterior/4/" .. dwLogicID
                    Event.Dispatch("EVENT_LINK_NOTIFY", szLink)
                    UIHelper.TempHideMiniSceneUntilNewViewClose(self, self.MiniScene, self.hModelView, VIEW_ID.PanelExteriorMain,nil)
                end)
                break
            else
                TipsHelper.ShowNormalTip(g_tStrings.STR_BUY_PET_UNABLE)
            end
        end
    end
end

function UIPetMapView:AddOrDelPreferPet(nPetIndex)
    self:InitPreferPet()
    local bPrefer =  table.contain_value(self.tPreferPetList, nPetIndex)
    UIHelper.SetVisible(self.Imglike,bPrefer)
    UIHelper.SetVisible(self.Imglike01, not bPrefer)
    if self.bShowPrefer then
        self:UpdatePetList()
    end
end

function UIPetMapView:UpdateMedalCollect()
    local tAllMedalInfo = self:GetAllFellowPetMedalInfos()
    self.tMedal = {
        [1] = {},
        [2] = {},
        [3] = {},
    }
    local tAcquiredNum = {
        [1] = 0,
        [2] = 0,
        [3] = 0,
    }
    local tAllNum = 0
    for _, v in ipairs(tAllMedalInfo) do
        local nType = v.dwMedalType
        table.insert(self.tMedal[nType], v)
        if v.bMedalAcquired then
            tAcquiredNum[nType] = tAcquiredNum[nType] + 1
            tAllNum = tAllNum + 1
        end
    end
    UIHelper.SetString(self.LabelGather01, tAllNum.."/"..#tAllMedalInfo)
    self:UpdateMedalList(tAcquiredNum)
end

function UIPetMapView:GetAllFellowPetMedalInfos()
    local hPlayer = self:GetPanelPlayer()
    local dwForceID = hPlayer.dwForceID
    local tMedal = hPlayer.GetAllFellowPetMedalInfos()
    local tMedalShow = {}
    for _, value in pairs(tMedal) do
        local nMedalIndex = value.nMedalIndex
        local tInfo = Table_GetFellowPet_Medal(nMedalIndex)
        if tInfo.dwForceID == -1 or tInfo.dwForceID == dwForceID then
            table.insert(tMedalShow, value)
        end
    end
    return tMedalShow
end

function UIPetMapView:UpdateMedalList(tAcquiredNum)
    local tbData = {}
    for k,v in ipairs(self.tMedal) do
        local Info = {}
        local szTitle = g_tStrings.tMedalType[k].."("..tAcquiredNum[k].."/"..#v..")"
        Info.tArgs = {szTitle = szTitle}
        Info.tItemList = {}
        for i,m in ipairs(v) do
            local nMedalIndex = m.nMedalIndex
            local szMedalName = Table_GetFellowPet_Medal(nMedalIndex).szName
            local nMedalPetAcquired = 0
            for _, nMedalPetIndex in pairs(m.tPetTable) do
                local bHave = self:IsFellowPetAcquired(nMedalPetIndex)
                if bHave then
                    nMedalPetAcquired = nMedalPetAcquired + 1
                end
            end
            szTitle = UIHelper.GBKToUTF8(szMedalName).."("..nMedalPetAcquired.."/"..m.dwPetCount..")"
            -- table.insert(Info.tItemList,{tArgs = {szTitle = szTitle,nGroupID = k,nGroupIndex = i}})
            table.insert(Info.tItemList,{tArgs = {szTitle,k,i,nMedalPetAcquired == m.dwPetCount}})

            Info.fnSelectedCallback = function(bSelected, scriptContainer)
                if bSelected then
                    local scriptScrollViewTree = UIHelper.GetBindScript(self.WidgetNavigation)
                    UIHelper.ScrollViewDoLayoutAndToTop(scriptScrollViewTree.ScrollViewContent)
                end
            end
        end
        table.insert(tbData, Info)
    end
    self.scriptScrollViewTree = UIHelper.GetBindScript(self.WidgetNavigation)
    self.scriptScrollViewTree:ClearContainer()
    UIHelper.SetupScrollViewTree(self.scriptScrollViewTree, PREFAB_ID.WidgetNavigation, PREFAB_ID.WidgetChilNavigation,
    function(scriptContainer, tArgs)
        UIHelper.SetString(scriptContainer.LabelNormalTitle, tArgs.szTitle)
        UIHelper.SetString(scriptContainer.LabelSelectTitle, tArgs.szTitle)
    end, tbData)
    Timer.AddFrame(self, 8, function()
        local scriptContainer = self.scriptScrollViewTree.tContainerList[1].scriptContainer
        UIHelper.SetSelected(scriptContainer.ToggleSelect, true)
    end)
end

function UIPetMapView:UpdateMedalInfo()
    local tMedalInfo = self.tMedal[self.nGroupID][self.nGroupIndex]
    local tLine = Table_GetFellowPet_Medal(tMedalInfo.nMedalIndex)

    UIHelper.SetString(self.LabelTilte,UIHelper.GBKToUTF8(tLine.szName))
    UIHelper.SetString(self.LabelBeltPet03,tMedalInfo.dwMedalScore)
    local szDes = ParseTextHelper.ParseNormalText(UIHelper.GBKToUTF8(tLine.szDes),true)
    UIHelper.SetString(self.LabelRelationInfo, szDes)

    local nMedalPetAcquired = 0
    local tbMedalInfoDes = {}
    for nIndex,v in ipairs(self.tbPetItemIcon) do
        if nIndex <= tMedalInfo.dwPetCount then
            local nMedalPetIndex = tMedalInfo.tPetTable["nFellowPetIndex" .. nIndex]
            local bHave = self:IsFellowPetAcquired(nMedalPetIndex)
            if bHave then
                nMedalPetAcquired = nMedalPetAcquired + 1
            end
            UIHelper.SetVisible(self.tbWidgetNone[nIndex],not bHave)
            table.insert(tbMedalInfoDes,1,{nMedalPetIndex,bHave})

            local tPet = Table_GetFellowPet(nMedalPetIndex)
            UIHelper.SetItemIconByIconID(self.tbPetItemIcon[nIndex], tPet.nIconID)
            UIHelper.SetSpriteFrame(self.tbPetItemQuality[nIndex], ItemQualityBGColor[tPet.nQuality + 1]) -- 颜色栏
            UIHelper.SetString(self.tbLabelPetName[nIndex], UIHelper.GBKToUTF8(tPet.szName))
            UIHelper.SetVisible(self.tbPetFrame[nIndex],true)
            UIHelper.SetNodeGray(self.tbPetItemIcon[nIndex], not bHave, true)
            UIHelper.SetOpacity(self.tbPetItem[nIndex], bHave and 225 or 120)
        else
            UIHelper.SetVisible(self.tbPetFrame[nIndex],false)
        end
    end

    local nProcess = math.floor(nMedalPetAcquired * 100 / tMedalInfo.dwPetCount + 0.5)
    local nIndex = 0
    for i, nRight in pairs(LUCKY_BUFF) do
        if nProcess >= nRight then
            nIndex = i
        end
    end
    UIHelper.SetSpriteFrame(self.ImgRelationship, PetRelationshipIcon[nIndex])
end

function UIPetMapView:SortPetLiat(tPets)
    if self.nSortWay == 1 then
        table.sort(tPets, function (left, right)
            local id_l = left.dwPetIndex
            local id_r = right.dwPetIndex

            local bIsNewL = RedpointHelper.Pet_IsNew(id_l)
            local bIsNewR = RedpointHelper.Pet_IsNew(id_r)
            if bIsNewL ~= bIsNewR then
                return bIsNewL
            end

            local bHave_l = self:IsFellowPetAcquired(id_l)
            local bHave_r = self:IsFellowPetAcquired(id_r)
            if bHave_l ~= bHave_r then
                return bHave_l
            end

            local lucky_l = self:IsLuckyPet(id_l) and 1 or 0
            local lucky_r = self:IsLuckyPet(id_r) and 1 or 0
            if lucky_l == lucky_r then
                local limit_l = left.bLimitTime and 1 or 0
                local limit_r = right.bLimitTime and 1 or 0
                if limit_l == limit_r then
                    if left.nGainDifficulty == right.nGainDifficulty then
                        if left.nQuality == right.nQuality then
                            return id_l < id_r
                        end
                        return left.nQuality < right.nQuality
                    end
                    return left.nGainDifficulty < right.nGainDifficulty
                end
                return limit_l < limit_r
            end
            return lucky_l > lucky_r
        end)
    else
        table.sort(tPets, function (left, right)
            local id_l = left.dwPetIndex
            local id_r = right.dwPetIndex

            local bHave_l = self:IsFellowPetAcquired(id_l)
            local bHave_r = self:IsFellowPetAcquired(id_r)
            if bHave_l ~= bHave_r then
                return bHave_l
            end

            local lucky_l = self:IsLuckyPet(id_l) and 1 or 0
            local lucky_r = self:IsLuckyPet(id_r) and 1 or 0
            if lucky_l == lucky_r then
                local limit_l = left.bLimitTime and 1 or 0
                local limit_r = right.bLimitTime and 1 or 0
                if limit_l == limit_r then
                    local score_l = GetFellowPetScore(id_l)
                    local score_r = GetFellowPetScore(id_r)
                    if score_l == score_r then
                        if left.nQuality == right.nQuality then
                            return id_l < id_r
                        end
                        return left.nQuality < right.nQuality
                    end
                    return score_l > score_r
                end
                return limit_l < limit_r
            end
            return lucky_l > lucky_r
        end)
    end

    return tPets
end

function UIPetMapView:GetPanelPlayer()
    local hPlayer
    if self.dwPlayerID then
        hPlayer = GetPlayer(self.dwPlayerID)
    else
        hPlayer = g_pClientPlayer
    end
    return hPlayer
end

function UIPetMapView:GetAcquiredFellowPetScore()
    local hPlayer = self:GetPanelPlayer()
    return hPlayer.GetAcquiredFellowPetScore()
end

function UIPetMapView:GetAcquiredFellowPetMedalScore()
    local hPlayer = self:GetPanelPlayer()
    return hPlayer.GetAcquiredFellowPetMedalScore()
end

function UIPetMapView:GetFellowPetCount()
    local hPlayer = self:GetPanelPlayer()
    return hPlayer.GetFellowPetCount()
end

function UIPetMapView:IsFellowPetAcquired(dwPetIndex)
    local hPlayer = self:GetPanelPlayer()
    return hPlayer.IsFellowPetAcquired(dwPetIndex)
end

function  UIPetMapView:IsPreferPet(nPetIndex)
    local hPlayer = g_pClientPlayer
    return hPlayer.HaveRemoteSet(REMOTE_PREFER_PET, nPetIndex)
end

function UIPetMapView:GetPreferPetCount()
    local hPlayer = g_pClientPlayer
    return hPlayer.GetRemoteSetSize(REMOTE_PREFER_PET)
end

function UIPetMapView:GetPreferPetIndex(nIndex)
    local hPlayer = g_pClientPlayer
    return hPlayer.GetRemoteDWordArray(REMOTE_PREFER_PET, nIndex - 1)
end

function UIPetMapView:IsLuckyPet(dwPetIndex)
    if not self.bMySelf then
        return
    end
    if self._tLuckyScore[dwPetIndex] then
        return true
    else
        return false
    end
end

function UIPetMapView:IsGoToAcquirePet()
    local nCurIndex = self.bShowPrefer and self.nCurLikeIndex or self.nCurIndex
    local szSourceList = self.tPets[nCurIndex].szSourceList
    local tSource = SplitString(szSourceList, ";")
    for _, v in pairs(tSource) do
        local nSource = tonumber(v)
        if nSource == SOURCE.WORLD_ADVENTURE or
            nSource == SOURCE.POINT_REWARD or
            nSource == SOURCE.OPERATION_ACTIVITY then
            return true
        end
    end
    return false
end

function UIPetMapView:IsGoToAcquirePetEnable()
    local nCurIndex = self.bShowPrefer and self.nCurLikeIndex or self.nCurIndex
    local szSourceList = self.tPets[nCurIndex].szSourceList
    local dwPetIndex = self.tPets[nCurIndex].dwPetIndex
    local tSource = SplitString(szSourceList, ";")
    for _, v in pairs(tSource) do
        local nSource = tonumber(v)
        if (nSource == SOURCE.POINT_REWARD or nSource == SOURCE.OPERATION_ACTIVITY) and (not CoinShop_PetIsInShop(dwPetIndex)) then
            return false
        end
    end
    return true
end

return UIPetMapView