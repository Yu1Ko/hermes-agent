-- ---------------------------------------------------------------------------------
-- Author: Unknown
-- Name: UIDomesticateView
-- Date: 2022-12-23 10:55:15
-- Desc: ?
-- ---------------------------------------------------------------------------------

local UIDomesticateView = class("UIDomesticateView")

local DomesticateState = {
    NoDomesticate = 1,      -- 未驯养
    Domesticating = 2,      -- 驯养中
    DomesticateComplete = 3,-- 驯养完成
}

local nEventID2IconPath = {
    [1] = "Resource/icon/item/Drug/potion30.png",
    [2] = "Resource/icon/skill/Common/skill_wanhua_jiedu.png",
    [3] = "Resource/icon/item/AnimalAndOrgan/m4new17.png",
    [4] = "Resource/icon/skill/Common/skill_wanhua_huixinyiji.png",
    [5] = "Resource/icon/skill/Common/Skill_jianghu19.png",
    [6] = "Resource/icon/skill/Common/Skill_jianghu19.png",
    [7] = "Resource/icon/skill/TianCe/skill_tiance12.png",
    [8] = "Resource/icon/skill/Common/skill_31.png"
}

local m_tPackageIndex = {
    INVENTORY_INDEX.PACKAGE,
    INVENTORY_INDEX.PACKAGE1,
    INVENTORY_INDEX.PACKAGE2,
    INVENTORY_INDEX.PACKAGE3,
    INVENTORY_INDEX.PACKAGE4,
    INVENTORY_INDEX.PACKAGE_MIBAO,
}

local tPos              = {133422, 4118, 35932}
local tManger           = {
    dwModelID           = 70932,
    dwFeedModelID       = 70931,
    tPos                = {-100, -60, 130},
    fScale              = 0.3,
}
local EAT_GRASS_TIME    = 8000
local PLAY_BELL_TIME    = 1200
local ANI_NAME          = "EatGrass"
local LOOP_TYPE         = "once"
local PAGE_COUNT        = 3
local bInEat            = false

function UIDomesticateView:OnEnter(dwBox, dwIndex)
    if not self.bInit then
        self:RegEvent()
        self:BindUIEvent()
        self.bInit = true
        
        UIHelper.PlayAni(self, self.AniAll, "AniIn02", function ()
            local nFadeoutDelay = Platform.IsMobile() and 0.7 or 0.2
            Timer.Add(self, nFadeoutDelay, function ()
                self:ShowWidget(dwBox, dwIndex)
                Timer.Add(self, 0.2, function ()
                    UIHelper.PlayAni(self, self.AniAll, "AniOut02")
                end)
            end)
        end)
    else
        self:ShowWidget(dwBox, dwIndex)
    end
end

function UIDomesticateView:OnExit()
    self.bInit = false
    self:UnRegEvent()
    Timer.DelAllTimer(self)
    if self.tCustomData then
        CustomData.Register(CustomDataType.Role, "DomesticateCustomData", self.tCustomData)
    end
    UITouchHelper.UnBindModel()
    if self.hModelViewHorse then
		self.hModelViewHorse:release()
		self.hModelViewHorse = nil
	end

    if self.hModelViewNpc then
		self.hModelViewNpc:release()
		self.hModelViewNpc = nil
	end
end

function UIDomesticateView:BindUIEvent()
    UIHelper.SetSwallowTouches(self.BtnClose, false)
    UIHelper.BindUIEvent(self.BtnClose, EventType.OnClick, function ()
        --UIMgr.Close(self)
    end)

    UIHelper.BindUIEvent(self.BtnBagClose, EventType.OnClick, function ()
        UIHelper.SetVisible(self.WidgetEmpty, true)
        UIHelper.SetVisible(self.WidgetInformationEmpty, true)
        self:CloseBag()
    end)

    UIHelper.BindUIEvent(self.BtnCloseRightBag, EventType.OnClick, function ()
        UIHelper.SetVisible(self.WidgetEmpty, true)
        UIHelper.SetVisible(self.WidgetInformationEmpty, true)
        self:CloseBag()
    end)

    UIHelper.BindUIEvent(self.BtnPutIn, EventType.OnClick, function ()
        if PropsSort.IsBagInSort() then
            TipsHelper.ShowNormalTip(g_tStrings.DOMETICATE_CUB_CAN_NOT_START_INSERT)
            return
        end
        self:OpenBag()
    end)

    UIHelper.BindUIEvent(self.BtnStop, EventType.OnClick, function ()
        self:StopDomesticate()
    end)

    UIHelper.BindUIEvent(self.BtnHarvest, EventType.OnClick, function ()
        self:StopDomesticate()
    end)

    UIHelper.BindUIEvent(self.BtnEvoke, EventType.OnClick, function ()
        self:EvokeDomesticate()
    end)

    UIHelper.BindUIEvent(self.BtnEvokeComplete, EventType.OnClick, function ()
        self:EvokeDomesticate()
    end)

    UIHelper.BindUIEvent(self.BtnAddSatiety, EventType.OnClick, function ()
        if PropsSort.IsBagInSort() then
            TipsHelper.ShowNormalTip(g_tStrings.DOMETICATE_FEED_CAN_NOT_START_INSERT)
            return
        end
        self:OnAddSatietyButtonClick()
    end)

    UIHelper.BindUIEvent(self.TogEventTips, EventType.OnSelectChanged, function (_, bSelected)
        self.tCustomData.bNeedRedDot = false
        UIHelper.SetVisible(self.ImgEventRedDot, self.tCustomData.bNeedRedDot)
        UIHelper.ScrollToTop(self.ScrollViewEvent, 0)
    end)

    UIHelper.BindUIEvent(self.TouchContainer, EventType.OnTouchBegan, function (_, x, y)
        if self.bShowHorse then
            FireUIEvent("RIDE_TOUCH_UPDATE", "Domesticate_view", "DomesticatePanel", true, x, y)
        else
            self:NpcModelTouchUpdate(true, x, y)
        end
    end)

    UIHelper.BindUIEvent(self.TouchContainer, EventType.OnTouchMoved, function (_, x, y)
        if self.bShowHorse then
            FireUIEvent("RIDE_TOUCH_UPDATE", "Domesticate_view", "DomesticatePanel", true, x, y)
        else
            self:NpcModelTouchUpdate(true, x, y)
        end
    end)

    UIHelper.BindUIEvent(self.TouchContainer, EventType.OnTouchEnded, function (_, x, y)
        if self.bShowHorse then
            FireUIEvent("RIDE_TOUCH_UPDATE", "Domesticate_view", "DomesticatePanel", false, x, y)
        else
            self:NpcModelTouchUpdate(false, x, y)
        end
    end)

    UIHelper.BindUIEvent(self.TouchContainer, EventType.OnTouchCanceled, function (_btn)
        if self.bShowHorse then
            FireUIEvent("RIDE_TOUCH_UPDATE", "Domesticate_view", "DomesticatePanel", false, 0, 0)
        else
            self:NpcModelTouchUpdate(false, 0, 0)
        end
    end)

    UIHelper.BindUIEvent(self.BtnSendToChat, EventType.OnClick, function()
        local player = GetClientPlayer()
        local tDomesticate = player.GetDomesticate()
        if not tDomesticate then
            return
        end
        ChatHelper.SendItemInfoToChat(nil, tDomesticate.dwCubTabType, tDomesticate.dwCubTabIndex)
	end)
end

function UIDomesticateView:RegEvent()
    Event.Reg(self, "START_DOMESTICATE", function ()
        self:UpdateInfo()
    end)
    Event.Reg(self, "STOP_DOMESTICATE", function ()
        self:UpdateInfo()
    end)
    Event.Reg(self, "UPDATE_DOMESTICATE", function ()
        self:UpdateInfo()
    end)
    Event.Reg(self, EventType.HideAllHoverTips, function ()
        if UIHelper.GetVisible(self.WidgetTip) then
            UIHelper.SetVisible(self.WidgetTip, false)            
        else
            UIHelper.SetVisible(self.WidgetEventTips, false)
            UIHelper.SetSelected(self.TogEventTips, false)
        end
        UIHelper.SetVisible(self.WidgetItemTip, false)
    end)
end

function UIDomesticateView:UnRegEvent()
    --Event.UnReg(self, EventType.XXX)
end

function UIDomesticateView:ShowWidget(dwBox, dwIndex)
    self.bIsRemote = IsRemotePlayer(UI_GetClientPlayerID())
    
    self:Init()
    self:UpdateInfo()
    self:OnFrameBreathe()

    if dwBox and dwIndex then
        self:StartDomesticate(dwBox, dwIndex)
    end
end

function UIDomesticateView:Init()
    self.tCustomData = CustomData.GetData(CustomDataType.Role, "DomesticateCustomData")
    if not self.tCustomData then
        self.tCustomData = {}
    end
    UIHelper.SetTouchDownHideTips(self.TogEventTips, false)
    UIHelper.SetTouchDownHideTips(self.BtnHoverTipsMask, false)
    UIHelper.SetTouchDownHideTips(self.ScrollViewEvent, false)
end

function UIDomesticateView:OnFrameBreathe()
    self:UpdateEventTime()
    Timer.AddFrame(self, 5, function ()
        self:OnFrameBreathe()
    end)
end

function UIDomesticateView:UpdateInfo()
    self:ComfirmState()
    if self.bIsRemote then return end

    if self.eState == DomesticateState.Domesticating then
        self:UpdateBaseInfo()
        self:UpdateAttrInfo(self.ScrollViewDomesticateProperty)
        self:UpdateEmotionInfo()
        self:UpdateEventInfo()
    elseif self.eState == DomesticateState.DomesticateComplete then
        self:UpdateCompleteInfo()
        self:UpdateAttrInfo(self.ScrollViewAdultProperty)
        self:UpdateEmotionInfo()
        self:UpdateEventInfo()
    end    
    self:UpdateHorseModelInfo()
    self:UpdateNPCModelInfo()
end

function UIDomesticateView:UpdateBaseInfo()
    if self.eState ~= DomesticateState.Domesticating then
        return
    end
    local player = GetClientPlayer()
    if not player then
        return
    end
    local tDomesticate = player.GetDomesticate()
    if not tDomesticate then
        return
    end
    local tCubItemInfo = tDomesticate.GetCubItemInfo()
    if not tCubItemInfo then
        return
    end
    local tAdultItemInfo = tDomesticate.GetAdultItemInfo()
    if not tAdultItemInfo then
        return
    end
    local tShowWord = Table_GetShowWord(tCubItemInfo.nSub)
    local tCubInfo = Table_GetCubInfo(tAdultItemInfo.dwID)

    local tItemInfo = GetItemInfo(tDomesticate.dwCubTabType, tDomesticate.dwCubTabIndex)
    local szName = ItemData.GetItemNameByItemInfo(tItemInfo)
    szName = UIHelper.GBKToUTF8(szName)
    --local nDiamondR, nDiamondG, nDiamondB = GetItemFontColorByQuality(tItemInfo.nQuality)
    --szName = GetFormatText(szName, nil, nDiamondR, nDiamondG, nDiamondB)
    --UIHelper.SetRichText(self.LabelCubName, szName)
    UIHelper.AddPrefab(PREFAB_ID.WidgetQualityBar, self.WidgetTitleGrowth, tItemInfo.nQuality)
    UIHelper.SetString(self.LabelCubName, szName)

    local szGrowthState, szStopText, bCanHarvest = GetGrowthState(tDomesticate, tShowWord)
    UIHelper.SetString(self.LabelStop, szStopText)

    local szCubLevel = tostring(tDomesticate.nGrowthLevel)
    local szCubLevelLimit = "/"..tostring(tDomesticate.nMaxGrowthLevel)
    local szCubExp = tostring(tDomesticate.nGrowthExp)
    local szCubExpLimit = "/"..tostring(tDomesticate.nMaxGrowthExp)
    local nExpPercent = tDomesticate.nGrowthExp/tDomesticate.nMaxGrowthExp*100
    local szCubSatiety = tostring(tDomesticate.nFullMeasure)
    local szCubSatietyLimit = "/"..tostring(tDomesticate.nMaxFullMeasure)
    local nSatietyPercent = tDomesticate.nFullMeasure/tDomesticate.nMaxFullMeasure*100
    UIHelper.SetString(self.LabelCubLevel, szCubLevel)
    UIHelper.SetString(self.LabelCubLevelLimit, szCubLevelLimit)
    UIHelper.SetString(self.LabelCubExp, szCubExp)
    UIHelper.SetString(self.LabelCubExpLimit, szCubExpLimit)
    UIHelper.SetString(self.LabelSatiety, szCubSatiety)
    UIHelper.SetString(self.LabelSatietyLimit, szCubSatietyLimit)
    UIHelper.SetProgressBarPercent(self.ProgressBarExp, nExpPercent)
    UIHelper.SetProgressBarPercent(self.ProgressBarSatiety, nSatietyPercent)
    local szState = UIHelper.GBKToUTF8(tShowWord.szFullMeasure3)
    local color = cc.c3b(0x95, 0xff, 0x95)
    if nSatietyPercent < tShowWord.nFullMeasureDegree1 then
        szState = UIHelper.GBKToUTF8(tShowWord.szFullMeasure1)
        color = cc.c3b(0xff, 0x76, 0x76)
    elseif nSatietyPercent < tShowWord.nFullMeasureDegree2 then
        szState = UIHelper.GBKToUTF8(tShowWord.szFullMeasure2)
        color = cc.c3b(0xff, 0xe2, 0x6e)
    end
    UIHelper.SetString(self.LabelSatietyState, szState)
    UIHelper.SetColor(self.LabelSatietyState, color)

    local szDesc = UIHelper.GBKToUTF8(tCubInfo.szDesc)
    szDesc = ParseTextHelper.ParseNormalText(szDesc, false)
    local _, szTopChars = GetStringCharCountAndTopChars(szDesc, 15)
    UIHelper.SetRichText(self.LabelFoldWord, szTopChars.."...")
    UIHelper.SetRichText(self.LabelUnFoldWord, szDesc)
    UIHelper.LayoutDoLayout(self.LayoutGrade)
    UIHelper.LayoutDoLayout(self.LayoutDes1)
    UIHelper.LayoutDoLayout(self.LayoutDes2)
end

function UIDomesticateView:UpdateAttrInfo(nodeScrollView)
    local player = GetClientPlayer()
    if not player then
        return
    end
    local tDomesticate = player.GetDomesticate()
    if not tDomesticate then
        return
    end
    local tCubItemInfo = tDomesticate.GetCubItemInfo()
    if not tCubItemInfo then
        return
    end
    local tAdultItemInfo = tDomesticate.GetAdultItemInfo()
    if not tAdultItemInfo then
        return
    end
    local tCubInfo = Table_GetCubInfo(tAdultItemInfo.dwID)
    UIHelper.RemoveAllChildren(nodeScrollView)

    local bVisible = false
    local tBaseAttib = tAdultItemInfo.GetBaseAttrib()
    if tBaseAttib then
        for k, v in pairs(tBaseAttib) do
            local tCubAttribute
            if v.nID then
                tCubAttribute = Table_GetCubAttribute(v.nID)
            end
            if tCubAttribute then
                UIHelper.AddPrefab(PREFAB_ID.WidgetDomesticateProperty, nodeScrollView, tCubAttribute, v, tDomesticate)
                bVisible = true
            end
        end
    end
    local tMagicAttrib = GetItemMagicAttrib(tAdultItemInfo.GetMagicAttribIndexList())
    if tMagicAttrib then
        for k, v in pairs(tMagicAttrib) do
            local tCubAttribute
            if v.nID then
                tCubAttribute = Table_GetCubAttribute(v.nID)
            end
            if tCubAttribute then
                UIHelper.AddPrefab(PREFAB_ID.WidgetDomesticateProperty, nodeScrollView, tCubAttribute, v, tDomesticate)
                bVisible = true
            end
        end
    end
    if bVisible then
        UIHelper.ScrollViewDoLayout(nodeScrollView)
        UIHelper.ScrollToTop(nodeScrollView)
    end
    UIHelper.SetVisible(nodeScrollView, bVisible)
end

function UIDomesticateView:UpdateEmotionInfo()
    local player = GetClientPlayer()
    if not player then
        return
    end
    local tDomesticate = player.GetDomesticate()
    if not tDomesticate then
        return
    end
    local tCubItemInfo = tDomesticate.GetCubItemInfo()
    if not tCubItemInfo then
        return
    end

    local tLine = Table_GetCubEmotion(tDomesticate.dwEmotion)
    local szTips = UIHelper.GBKToUTF8(tLine.szTip)
    local szSplits = string.split(szTips, "：")
    if #szSplits > 1 then
        szTips = string.split(szTips, "：")[2]
    end
    UIHelper.SetString(self.LabelMood, szTips)
    self.szAnimationName = tLine.szAnimationName
end

function UIDomesticateView:UpdateEventInfo()
    local player = GetClientPlayer()
    if not player then
        return
    end
    local tDomesticate = player.GetDomesticate()
    if not tDomesticate then
        return
    end
    local tCubItemInfo = tDomesticate.GetCubItemInfo()
    if not tCubItemInfo then
        return
    end

    local nEventID = tDomesticate.dwEventID
    local bNoEvent = not nEventID or nEventID == 0
    if not bNoEvent then
        local tEvent = Table_GetDomesticateEvent(nEventID)
        local szName = UIHelper.GBKToUTF8(tEvent.szName)
        local szDesc = UIHelper.GBKToUTF8(tEvent.szDesc)
        szDesc = string.pure_text(szDesc)
        local szSolution = UIHelper.GBKToUTF8(tEvent.szSolution)
        --szSolution = string.pure_text(szSolution)
        szSolution = ParseTextHelper.ParseNormalText(szSolution, false)
        local szAward = UIHelper.GBKToUTF8(tEvent.szAward)
        local szEventOverdueTime = UIHelper.GetDeltaTimeText(tDomesticate.nEventOverdueTime - os.time())

        UIHelper.SetString(self.LabelEventState, szName)
        UIHelper.SetString(self.LabelEventIntroduce, szDesc)
        UIHelper.SetRichText(self.RichTextEventSolution, szSolution)
        UIHelper.SetString(self.LabelEventRestTime, szEventOverdueTime)
        UIHelper.SetTexture(self.ImgStateIcon, nEventID2IconPath[nEventID])

		local szType, szID = szAward:match("ItemLinkInfo/(%w+)/(%w+)")
		local dwType = tonumber(szType)
		local dwID = tonumber(szID)
        local tItemInfo = ItemData.GetItemInfo(dwType, dwID)
        local szItemName = ItemData.GetItemNameByItemInfo(tItemInfo)
        szItemName = UIHelper.GBKToUTF8(szItemName)
        UIHelper.RemoveAllChildren(self.LayoutEventAward)
        local scriptItem = UIHelper.AddPrefab(PREFAB_ID.WidgetAwardItem1, self.LayoutEventAward, szItemName, 0, dwType, dwID, false)
        if scriptItem then
            UIHelper.SetTouchDownHideTips(scriptItem.TogItem, false)
            scriptItem:SetSingleClickCallback(function (nTabType, nTabID)
                self.scriptAwardTip = self.scriptAwardTip or UIHelper.AddPrefab(PREFAB_ID.WidgetItemTip, self.WidgetTip)
                self.scriptAwardTip:SetFunctionButtons({})
                self.scriptAwardTip:OnInitWithTabID(nTabType, nTabID)                
                UIHelper.SetVisible(self.WidgetTip, true)
            end)
            Timer.AddFrame(self, 1, function ()
                scriptItem:SetLabelText("")
                UIHelper.SetTouchDownHideTips(scriptItem.scriptItemIcon.ToggleSelect, false)
            end)
        end

        if not self.tCustomData.nCurEventID or self.tCustomData.nCurEventID ~= nEventID then
            self.tCustomData.nCurEventID = nEventID
            self.tCustomData.bNeedRedDot = true
        end
    end
    UIHelper.SetVisible(self.TogEventTips, not bNoEvent)
    UIHelper.SetVisible(self.ImgEventRedDot, self.tCustomData.bNeedRedDot)
    UIHelper.ScrollViewDoLayout(self.ScrollViewEvent)
    UIHelper.ScrollToTop(self.ScrollViewEvent, 0)
end

function UIDomesticateView:UpdateEventTime()
    local player = GetClientPlayer()
    if not player then
        return
    end
    local tDomesticate = player.GetDomesticate()
    if not tDomesticate then
        return
    end
    local tCubItemInfo = tDomesticate.GetCubItemInfo()
    if not tCubItemInfo then
        return
    end
    local nEventID = tDomesticate.dwEventID
    local bNoEvent = not nEventID or nEventID == 0
    local nRestTime = tDomesticate.nEventOverdueTime - os.time()
    local szRestTime = UIHelper.GetDeltaTimeText(nRestTime)
    if not bNoEvent and nRestTime >= 0 then
        UIHelper.SetString(self.LabelEventRestTime, szRestTime)
    else
        self.tCustomData.nEventID = 0
        self.tCustomData.bNeedRedDot = false
    end
end

function UIDomesticateView:UpdateCompleteInfo()
    local player = GetClientPlayer()
    if not player then
        return
    end
    local tDomesticate = player.GetDomesticate()
    if not tDomesticate then
        return
    end
    local tCubItemInfo = tDomesticate.GetCubItemInfo()
    if not tCubItemInfo then
        return
    end
    local tAdultItemInfo = tDomesticate.GetAdultItemInfo()
    if not tAdultItemInfo then
        return
    end

    local tItemInfo = GetItemInfo(tDomesticate.dwCubTabType, tDomesticate.dwCubTabIndex)
    local szName = ItemData.GetItemNameByItemInfo(tItemInfo)
    szName = UIHelper.GBKToUTF8(szName)
    UIHelper.SetString(self.LabelAdultName, szName)

    UIHelper.AddPrefab(PREFAB_ID.WidgetQualityBar, self.WidgetTitleComplete, tItemInfo.nQuality)
end

function UIDomesticateView:UpdateHorseModelInfo()
    local player = GetClientPlayer()
    if not player then
        return
    end
    local tDomesticate = player.GetDomesticate()
    if not tDomesticate then
        return
    end

    if not self.hModelViewHorse then
		self.hModelViewHorse = RidesModelView.CreateInstance(RidesModelView)
		self.hModelViewHorse:ctor()
		self.hModelViewHorse:init(nil, Const.COMMON_SCENE, "DomesticatePanel")
		self.hModelViewHorse:SetCamera(Const.MiniScene.DomesticateView.tbRideCamare)
		self.MiniSceneHorse:SetScene(self.hModelViewHorse.m_scene)
        UITouchHelper.BindModel(self.TouchContainer, self.hModelViewHorse)
	end

    local tItemInfo = tDomesticate.GetAdultItemInfo()
    if not tItemInfo then
        return
    end
    self.bShowHorse = tItemInfo.nGenre == ITEM_GENRE.EQUIPMENT and tItemInfo.nSub == EQUIPMENT_SUB.HORSE
    UIHelper.SetVisible(self.MiniSceneHorse, self.bShowHorse)
    local tbRepresentID = player.GetRepresentID()

    if self.bShowHorse then
        tbRepresentID[EQUIPMENT_REPRESENT.HORSE_STYLE] = tItemInfo.nRepresentID
	else
		tbRepresentID[EQUIPMENT_REPRESENT.HORSE_STYLE] = 0
    end

    for i = 1,HORSE_ADORNMENT_COUNT do
        local nRepresentID = EQUIPMENT_REPRESENT["HORSE_ADORNMENT" .. i]
        tbRepresentID[nRepresentID] = 0
    end

    self.hModelViewHorse:UnloadRidesModel()
    if tbRepresentID[EQUIPMENT_REPRESENT.HORSE_STYLE] == 0 then
        return
    end

    self.hModelViewHorse:LoadResByRepresent(tbRepresentID, false)
    self.hModelViewHorse:LoadRidesModel()
    self.hModelViewHorse:PlayRidesAnimation("Idle", "loop")
    self.hModelViewHorse:SetTranslation(table.unpack(Const.MiniScene.DomesticateView.tbRidePos))

    local fScale = Const.MiniScene.RideScale
    self.hModelViewHorse:SetScaling(fScale, fScale, fScale)
    RidesModelPreview.RegisterHorse(self.MiniSceneHorse, self.hModelViewHorse, "Domesticate_view", "DomesticatePanel")
end

function UIDomesticateView:UpdateNPCModelInfo()
    local player = GetClientPlayer()
    if not player then
        return
    end
    local tDomesticate = player.GetDomesticate()
    if not tDomesticate then
        return
    end
    local tCubItemInfo = tDomesticate.GetCubItemInfo()
    local dwCubTabIndex = tDomesticate.dwCubTabIndex
	local tPet = Table_GetDomesticatePetModel(dwCubTabIndex)
    self.bShowNpc = tCubItemInfo ~= nil and tPet ~= nil
    UIHelper.SetVisible(self.MiniSceneNpc, self.bShowNpc)

	if not self.hModelViewNpc then
		self.hModelViewNpc = NpcModelView.CreateInstance(NpcModelView)
		self.hModelViewNpc:ctor()
		self.hModelViewNpc:init(nil, false, true, Const.COMMON_SCENE, "DomesticateNpc")
		self.hModelViewNpc:SetCamera(Const.MiniScene.DomesticateView.tbPetCamare)
		self.MiniSceneNpc:SetScene(self.hModelViewNpc.m_scene)
	end

    if not tPet then
        return
    end
	self.hModelViewNpc:LoadNpcRes(tPet.dwModelID, false)
	self.hModelViewNpc:UnloadModel()
	self.hModelViewNpc:LoadModel()
	self.hModelViewNpc:PlayAnimation("Idle", "loop")
	self.hModelViewNpc:SetTranslation(table.unpack(Const.MiniScene.DomesticateView.tbPetPos))
	self.hModelViewNpc:SetYaw(Const.MiniScene.DomesticateView.fPetYaw)
	self.hModelViewNpc:SetScaling(tPet.fModelScaleMB)
end

local CHARACTER_ROLE_TURN_YAW = math.pi / 54

local function RoleYawTurn(tFrame)
    if not tFrame.fNpcYaw then
        tFrame.fNpcYaw = math.pi / 2
    end
    if tFrame.bTurnRight then
        tFrame.fNpcYaw = (tFrame.fNpcYaw - CHARACTER_ROLE_TURN_YAW) % (2 * math.pi)
        tFrame.m_NpcMDL["MDL"]:SetYaw(tFrame.fNpcYaw)
    elseif tFrame.bTurnLeft then
        tFrame.fNpcYaw = (tFrame.fNpcYaw + CHARACTER_ROLE_TURN_YAW) % (2 * math.pi)
        tFrame.m_NpcMDL["MDL"]:SetYaw(tFrame.fNpcYaw)
    end
end

function UIDomesticateView:NpcModelTouchUpdate(bTouch, x, y)
    if not self.hModelViewNpc then
        return
    end

    if not self.hModelViewNpc.bTouch and bTouch then
        self.hModelViewNpc.nCX = x
    end
    self.hModelViewNpc.bTouch = bTouch

    self.hModelViewNpc.bTurnRight = bTouch and x > self.hModelViewNpc.nCX
    self.hModelViewNpc.bTurnLeft = bTouch and x < self.hModelViewNpc.nCX
    RoleYawTurn(self.hModelViewNpc)
end

function UIDomesticateView:ComfirmState()
    self.eState = DomesticateState.NoDomesticate
    self:CloseBag()
    UIHelper.SetVisible(self.WidgetEmpty, true)
    UIHelper.SetVisible(self.WidgetInformationEmpty, true)
    UIHelper.SetVisible(self.WidgetMoodEvent, false)
    UIHelper.SetVisible(self.WidgetInformationBase, false)
    UIHelper.SetVisible(self.WidgetInformationComplete, false)
    UIHelper.SetVisible(self.TogWord, false)
    UIHelper.SetVisible(self.BtnSendToChat, false)

    if self.bIsRemote then
        UIHelper.SetString(self.LabelEmpty, "正在跨服中，无法获取对应的数据")
        UIHelper.SetVisible(self.WidgetInformationEmpty, false)
        return
    end

    local player = GetClientPlayer()
    if not player then
        return
    end
    local tDomesticate = player.GetDomesticate()
    if not tDomesticate then
        return
    end
    local tCubItemInfo = tDomesticate.GetCubItemInfo()
    if not tCubItemInfo then
        return
    end
    self:SwitchToDomesticating()
    local tShowWord = Table_GetShowWord(tCubItemInfo.nSub)
    local _, _, bCanHave = GetGrowthState(tDomesticate, tShowWord)
    if bCanHave then
        self:SwitchToDomesticateComplete()
    end
end

function UIDomesticateView:OpenBag()
    local player = GetClientPlayer()
    if not player then
        return
    end
    UIHelper.SetVisible(self.WidgetEmpty, false)
    UIHelper.SetVisible(self.WidgetInformationEmpty, false)
    UIHelper.SetVisible(self.WidgetBag, true)

    local scriptLifePage = UIMgr.GetViewScript(VIEW_ID.PanelLifePage)
    if scriptLifePage then
        UIHelper.SetVisible(scriptLifePage.BtnClose, false)
    end

    UIHelper.ToggleGroupRemoveAllToggle(self.ToggleGroupScrollBag)
    UIHelper.RemoveAllChildren(self.ScrollViewDomesticateBag)

    local bNeedSelectFirst = true
    local bEmpty = true
    for _ , dwBox in pairs(m_tPackageIndex) do
        local nSize = player.GetBoxSize(dwBox) - 1
        for dwX = 0, nSize, 1 do
            local item = PlayerData.GetPlayerItem(player, dwBox, dwX)
            if item and item.nGenre == ITEM_GENRE.CUB then
                local scriptItem = UIHelper.AddPrefab(PREFAB_ID.WidgetHorseBagItem, self.ScrollViewDomesticateBag, dwBox, dwX)
                if scriptItem then
                    bEmpty = false
                    scriptItem:SetClickCallback(function ()
                        self:OnSelectHorseItem(dwBox, dwX)
                    end)
                    UIHelper.ToggleGroupAddToggle(self.ToggleGroupScrollBag, scriptItem.ToggleSelect)
                    if bNeedSelectFirst then
                        bNeedSelectFirst = false
                        self:OnSelectHorseItem(dwBox, dwX)
                    end
                end
            end
        end
    end

    UIHelper.ScrollViewDoLayout(self.ScrollViewDomesticateBag)
    UIHelper.ScrollToTop(self.ScrollViewDomesticateBag, 0)

    UIHelper.SetVisible(self.WidgetBagEmpty, bEmpty)
    if self.fOnOpenBag then self.fOnOpenBag(true) end
end

function UIDomesticateView:CloseBag()
    UIHelper.SetVisible(self.WidgetBag, false)

    local scriptLifePage = UIMgr.GetViewScript(VIEW_ID.PanelLifePage)
    if scriptLifePage then
        UIHelper.SetVisible(scriptLifePage.BtnClose, true)
    end
    if self.fOnOpenBag then self.fOnOpenBag(false) end
end

function UIDomesticateView:OnSelectHorseItem(dwBox, dwX)
    self.scriptItemTip = self.scriptItemTip or UIHelper.AddPrefab(PREFAB_ID.WidgetItemTip, self.WidgetItemTip)
    local tFunctionButton = {
        szName = "放入",
        OnClick = function ()
            self:StartDomesticate(dwBox, dwX)
        end
    }
    self.scriptItemTip:SetFunctionButtons({tFunctionButton})
    self.scriptItemTip:OnInit(dwBox, dwX)
    UIHelper.SetVisible(self.WidgetItemTip, true)
end

function UIDomesticateView:OnSelectFeedItem(dwBox, dwIndex)
    local player = GetClientPlayer()
    if not player then
        return
    end
    local tDomesticate = player.GetDomesticate()
    if not tDomesticate then
        return
    end
    local tItem = ItemData.GetPlayerItem(player, dwBox, dwIndex)
    if not tItem then
        return
    end

    local nResult = tDomesticate.Feed(dwBox, dwIndex)
    if nResult ~= DOMESTICATE_OPERATION_RESULT_CODE.SUCCESS then
        TipsHelper.ShowNormalTip(g_tStrings.tDometicateError[nResult])
        return
    end

    Timer.AddFrame(self, 5, function ()
        self.hModelViewHorse:PlayRidesAnimation("EatGrass", "LOOP_TYPE")
        Timer.Add(self, EAT_GRASS_TIME/1000, function ()
            self.hModelViewHorse:PlayRidesAnimation("Idle", "loop")
        end)
    end)
end

function UIDomesticateView:OnAddSatietyButtonClick()
    local player = GetClientPlayer()
    if not player then
        return
    end
    local tDomesticate = player.GetDomesticate()
    if not tDomesticate then
        return
    end
    local tCubItemInfo = tDomesticate.GetCubItemInfo()
    if not tCubItemInfo then
        return
    end
    local tAdultItemInfo = tDomesticate.GetAdultItemInfo()
    if not tAdultItemInfo then
        return
    end
    self.scriptFeeding = self.scriptFeeding or UIHelper.AddPrefab(PREFAB_ID.WidgetClickFeeding, self.WidgetClickFeeding)
    UIHelper.SetVisible(self.scriptFeeding._rootNode, true)
    self.scriptFeeding:OnEnter(tDomesticate.dwCubTabType, tDomesticate.dwCubTabIndex)
    self.scriptFeeding:SetClickCallback(function (nBox, nIndex)
        self:OnSelectFeedItem(nBox, nIndex)
    end)
end

function UIDomesticateView:StartDomesticate(dwBox, dwIndex)
    local player = GetClientPlayer()
    if not player then
        return
    end
    local tDomesticate = player.GetDomesticate()
    if not tDomesticate then
        return
    end

    if not DomesticatePanel_CheckPlayerState() then
        TipsHelper.ShowNormalTip(g_tStrings.tDometicateError[DOMESTICATE_OPERATION_RESULT_CODE.STATE_CAN_NOT_START])
        return
    end

    local item = PlayerData.GetPlayerItem(player, dwBox, dwIndex)
    local szName = ShopData.GetItemNameWithColor(item.dwID)
    local szMsg = string.format(g_tStrings.Dometicate.DOMETICATE_START_SURE, szName)
    UIHelper.ShowConfirm(szMsg, function ()
        if PropsSort.IsBagInSort() then
            TipsHelper.ShowNormalTip(g_tStrings.DOMETICATE_CUB_CAN_NOT_START_INSERT)
            return
        end
        local nResult = tDomesticate.Start(dwBox, dwIndex)
        if nResult ~= DOMESTICATE_OPERATION_RESULT_CODE.SUCCESS then
            TipsHelper.ShowNormalTip(g_tStrings.tDometicateError[nResult])
            return
        end
        self:SwitchToDomesticating()
    end,function ()

    end,true)
end

function UIDomesticateView:StopDomesticate()
    local player = GetClientPlayer()
    if not player then
        return
    end
    local tDomesticate = player.GetDomesticate()
    if not tDomesticate then
        return
    end
    local tCubItemInfo = tDomesticate.GetCubItemInfo()
    if not tCubItemInfo then
        return
    end
    local tAdultItemInfo = tDomesticate.GetAdultItemInfo()
    if not tAdultItemInfo then
        return
    end
    local tShowWord = Table_GetShowWord(tCubItemInfo.nSub)
    local tCubInfo = Table_GetCubInfo(tAdultItemInfo.dwID)
    local szGrowthState, szStopText, bCanHarvest = GetGrowthState(tDomesticate, tShowWord)

    if not DomesticatePanel_CheckPlayerState() then
        if bCanHarvest then
            TipsHelper.ShowNormalTip(g_tStrings.DOMETICATE_CAN_NOT_HAVE)
        else
            TipsHelper.ShowNormalTip(g_tStrings.tDometicateError[DOMESTICATE_OPERATION_RESULT_CODE.STATE_CAN_NOT_STOP])
        end
        return
    end

    local szName = UIHelper.GBKToUTF8(tCubInfo.szName)
    local szText = ""
    if bCanHarvest then
        szText = string.format(g_tStrings.Dometicate.DOMETICATE_HAVE_SURE, szName)
    else
        szText = string.format(g_tStrings.Dometicate.DOMETICATE_STOP_SURE, szName)
    end
    UIHelper.ShowConfirm(szText, function ()
        local nResult = DOMESTICATE_OPERATION_RESULT_CODE.SUCCESS
        nResult = tDomesticate.Stop()

        if nResult ~= DOMESTICATE_OPERATION_RESULT_CODE.SUCCESS then
            if nResult == DOMESTICATE_OPERATION_RESULT_CODE.STATE_CAN_NOT_STOP and bCanHarvest then
                TipsHelper.ShowNormalTip(g_tStrings.DOMETICATE_CAN_NOT_HAVE)
            else
                TipsHelper.ShowNormalTip(g_tStrings.tDometicateError[nResult])
            end
        else
            self.hModelViewHorse:UnloadRidesModel()
        end
    end)
end

function UIDomesticateView:EvokeDomesticate()
    local player = GetClientPlayer()
    if not player then
        return
    end

    local tDomesticate = player.GetDomesticate()
    if not tDomesticate then
        return
    end

    local nResult = tDomesticate.Evoke()
    if nResult ~= DOMESTICATE_OPERATION_RESULT_CODE.SUCCESS then
        TipsHelper.ShowNormalTip(g_tStrings.tDometicateError[nResult])
        return
    end
    
    TipsHelper.ShowNormalTip("召唤成功！")
    UIMgr.Close(VIEW_ID.PanelLifePage)
    UIMgr.Close(VIEW_ID.PanelLifeMain)
    UIMgr.Close(VIEW_ID.PanelSystemMenu)
end

function UIDomesticateView:SwitchToDomesticating()
    self.eState = DomesticateState.Domesticating
    self:CloseBag()
    UIHelper.SetVisible(self.WidgetEmpty, false)
    UIHelper.SetVisible(self.WidgetInformationEmpty, false)
    UIHelper.SetVisible(self.WidgetMoodEvent, true)
    UIHelper.SetVisible(self.WidgetInformationBase, true)
    UIHelper.SetVisible(self.TogWord, true)
    UIHelper.SetVisible(self.BtnSendToChat, true)
end

function UIDomesticateView:SwitchToDomesticateComplete()
    self.eState = DomesticateState.DomesticateComplete
    UIHelper.SetVisible(self.WidgetInformationBase, false)
    UIHelper.SetVisible(self.WidgetInformationComplete, true)
end

function UIDomesticateView:SetOnOpenBag(fOnOpenBag)
    self.fOnOpenBag = fOnOpenBag
end

function _G.DomesticatePanel_CheckPlayerState()
    local hPlayer = GetClientPlayer()
    if not hPlayer then
        return false
    end

    if hPlayer.bOnHorse or
       hPlayer.bFightState or
       hPlayer.bSprintFlag or
       hPlayer.nMoveState == MOVE_STATE.ON_DEATH
    then
        return false
    end

    return true
end

function _G.GetGrowthState(hDomesticate, tShowWord)
    if hDomesticate.nGrowthLevel < hDomesticate.nMaxGrowthLevel then
        return tShowWord.szCubText, g_tStrings.DOMETICATE_STOP, false
    else
        return tShowWord.szAdultText, g_tStrings.DOMETICATE_HAVE, true
    end
end

return UIDomesticateView