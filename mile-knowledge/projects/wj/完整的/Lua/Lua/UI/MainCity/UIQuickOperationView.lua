-- ---------------------------------------------------------------------------------
-- Author: Unknown
-- Name: UIQuickOperationView
-- Date: 2023-03-17 17:38:02
-- Desc: ?
-- ---------------------------------------------------------------------------------

local UIQuickOperationView = class("UIQuickOperationView")

local tGroupID2Desc = {
    [1] = "常用功能",
    [2] = "队伍功能",
    [3] = "玩法功能",
    [4] = "侠客功能",
}

local MAP_TYPE = {
	COMMON = 1,
	ATHLETICS = 2,
	SECRETAREA = 3
}
local tSettingLabel = {
    [1] = "常用快捷（应对主城和野外）",
    [2] = "竞技快捷（应对竞技类玩法）",
    [3] = "秘境快捷（应对秘境玩法）",
    [4] = "侠客快捷（应对侠客玩法）"
}

local tSettingTips = {
    [1] = "常用快捷",
    [2] = "竞技快捷",
    [3] = "秘境快捷",
    [4] = "侠客快捷",
}

--对应地图情况下快捷分组的展示顺序调整
local tGroupIndexByMapType = {
    [MAP_TYPE.SECRETAREA] = {1, 2, 4, 3},
    [MAP_TYPE.COMMON] = {1, 2, 3, 4},
    [MAP_TYPE.ATHLETICS] = {1, 2, 3, 4},
}

local tbPendantTypeToSpriteName =
{
    ["Head"] = "UIAtlas2_Public_PublicSystemButton_PublicSystemButton_toubuBtn.png",
    ["Face"] = "UIAtlas2_Public_PublicSystemButton_PublicSystemButton_mianbuBtn.png",
    ["Glasses"] = "UIAtlas2_Public_PublicSystemButton_PublicSystemButton_yanbuBtn.png",
    ["Bag"] = "UIAtlas2_Public_PublicSystemButton_PublicSystemButton_peinangBtn.png",
    ["Back"] = "UIAtlas2_Public_PublicSystemButton_PublicSystemButton_beiguaBtn.png",
    ["Waist"] = "UIAtlas2_Public_PublicSystemButton_PublicSystemButton_yaobuBtn.png",
    ["LHand"] = "UIAtlas2_Public_PublicSystemButton_PublicSystemButton_youshouBtn.png",
    ["RHand"] = "UIAtlas2_Public_PublicSystemButton_PublicSystemButton_zuoshouBtn.png",
    ["PendantPet"] = "UIAtlas2_Public_PublicSystemButton_PublicSystemButton_guachongBtn.png",
    ["BackCloak"] = "UIAtlas2_Public_PublicSystemButton_PublicSystemButton_pifengBtn.png",
}

function UIQuickOperationView:OnEnter(nIndex)
    if not self.bInit then
        self:RegEvent()
        self:BindUIEvent()
        self.bInit = true
    end

    self.bOnEdit = false
    self.tbPendantBtnList = {}
    self.tbExteriorBtnList = {}
    self.tbHorseBtnList = {}
    self.tbPendantOtherBtnList = {
        Pet = {},
        LHand = {},
        RHand = {},
        Glasses = {},
        Skill = {}
    }
    self.bSelecteQuickOperation = true
    UIHelper.SetVisible(self.ScrollViewQuickOperation,true)
    UIHelper.SetVisible(self.ScrollViewActionOperation,false)
    UIHelper.SetVisible(self.BtnQuickSetting, true)
    UIHelper.SetVisible(self.BtnModeSelect, true)
    self:InitQuickTab()
    self:UpdateList()

    if nIndex == 2 then
        Timer.Add(self, 0.1, function()
            UIHelper.SetSelected(self.TogActionOperation, true)
            UIHelper.SetString(self.LabelTitle, "动作表情")
            UIHelper.SetVisible(self.BtnQuickSetting, false)
            UIHelper.SetVisible(self.BtnModeSelect, false)
            Event.Dispatch("ON_HIDE_LEFT_CHANGE_BTN", false)
        end)
    end
end

function UIQuickOperationView:OnExit()
    self.bInit = false
    self:UnRegEvent()
    EmotionData.UnQuickLoad()
    Timer.DelAllTimer(self)
    Event.Dispatch("ON_HIDEORSHOW_LEFTBTN", true)
    Event.Dispatch("ON_HIDE_LEFT_CHANGE_BTN", true)
    --Event.Dispatch(EventType.OnUpdateMainCityLeftBottom, nil)
    self:UnRegAllRedpoint()
end

function UIQuickOperationView:BindUIEvent()
    --点击快捷操作
    UIHelper.BindUIEvent(self.TogQuickOperation,EventType.OnSelectChanged,function ()

    end)
    --动作表情
    UIHelper.BindUIEvent(self.TogActionOperation, EventType.OnSelectChanged,function (btn, bSelected)
        if bSelected then
            self:UpdateActionAndFaceList()
        end
    end)
    --关闭
    UIHelper.BindUIEvent(self.BtnBg, EventType.OnClick, function()
		UIMgr.Close(self)
	end)

    UIHelper.BindUIEvent(self.BtnModeSelect, EventType.OnClick, function()  --操作模式
		UIMgr.Open(VIEW_ID.PanelHintSelectMode)
        UIMgr.Close(self)
	end)

    UIHelper.BindUIEvent(self.BtnQuickSetting, EventType.OnClick, function()  --编辑快捷指令
        if g_pClientPlayer.nLevel >= 103 then
            self:UpdateModifyStateInfo(true)
        else
            TipsHelper.ShowNormalTip("侠士达到103级后方可编辑快捷指令")
        end

	end)

    UIHelper.BindUIEvent(self.BtnBack, EventType.OnClick, function()  --退出编辑快捷指令
        self:UpdateModifyStateInfo(false)
	end)

    UIHelper.BindUIEvent(self.BtnSkillSetClose, EventType.OnClick, function()
        UIHelper.SetSelected(self.TogSettingGroup, false)
	end)

end

function UIQuickOperationView:RegEvent()
    Event.Reg(self, "REMOTE_DATA_PREFER_PENDANT", function()
        self:UpdatePendantList()
    end)

    Event.Reg(self, "ON_EQUIP_PENDENT_PET_NOTIFY", function()
        self:UpdatePendantList()
    end)

    Event.Reg(self, "ON_SELECT_PENDANT", function()
        self:UpdatePendantList()
    end)

    --emotion action add or delete
    Event.Reg(self,"SET_MOBILE_EMOTION_ACTION_DIY_INFO_NOTIFY",function (bAdd, dwID)
        self:UpdateEmotionActionBtn(bAdd, dwID)
    end)

    Event.Reg(self,"SET_MOBILE_HEAD_EMOTION_DIY_INFO_NOTIFY",function (bAdd, dwID)
        self:UpdateHeadEmotionBtn(bAdd, dwID)
    end)

    Event.Reg(self,"PLAYER_DISPLAY_DATA_UPDATE",function ()
        if arg0 ==  UI_GetClientPlayerID() then
            self:UpdatePendantList()
            self:UpdateExteriorList()
        end
    end)

    Event.Reg(self,"SYNC_HIDE_BACKCLOAK_SPRINT_SFX_FLAG",function ()
        if arg0 ==  UI_GetClientPlayerID() then
            self:UpdatePendantList()
            self:UpdateExteriorList()
        end
    end)


    Event.Reg(self,"ON_OPEN_ACTIONOPERATION",function ()
        self:UpdateActionAndFaceList()
        UIHelper.SetString(self.LabelTitle, "动作表情")
        UIHelper.SetVisible(self.ScrollViewActionOperation, true)
        UIHelper.SetVisible(self.ScrollViewQuickOperation, false)
        UIHelper.SetVisible(self.BtnQuickSetting, false)
        UIHelper.SetVisible(self.BtnModeSelect, false)
        Event.Dispatch("ON_HIDE_LEFT_CHANGE_BTN", false)
    end)

    Event.Reg(self,"ON_QUICKMENU_SCROLLVIEW_DOLAYOUT",function ()
        Timer.AddFrame(self, 1, function ()
            UIHelper.ScrollViewDoLayoutAndToTop(self.ScrollViewQuickOperation)
        end)

    end)

    Event.Reg(self, "ON_EXTERIOR_SUBSET_HIDE_FLAG_UPDATE", function()
        self:UpdateExteriorList()
    end)

    Event.Reg(self, "ON_HAIR_SUBSET_HIDE_FLAG_UPDATE", function()
        self:UpdateExteriorList()
    end)
end

function UIQuickOperationView:UnRegEvent()
    --Event.UnReg(self, EventType.XXX)
end






-- ----------------------------------------------------------
-- Please write your own code below  ↓↓↓
-- ----------------------------------------------------------

function UIQuickOperationView:InitQuickTab()
    self.nGroupCount = 0
    for i, v in ipairs(UIQuickMenuTab) do
        if self.nGroupCount < v.nGroupID then
            self.nGroupCount = v.nGroupID
        end
    end
end

function UIQuickOperationView:UpdateList()
    UIHelper.RemoveAllChildren(self.ScrollViewQuickOperation)

    --for i = 1,self.nGroupCount,1 do
    --    local TitleScript = UIHelper.AddPrefab(PREFAB_ID.WidgetQuickOperationTitle, self.ScrollViewQuickOperation) assert(TitleScript)
    --    UIHelper.SetString(TitleScript.LabelQuickOperationTitle,tGroupID2Desc[i])
    --    TitleScript = UIHelper.AddPrefab(PREFAB_ID.WidgetQuickOperationLayout, self.ScrollViewQuickOperation,i) assert(TitleScript)
    --    UIHelper.LayoutDoLayout(TitleScript.WidgetQuickOperationLayout)
    --end

    local bTeam = TeamData.IsInParty() or TeamData.IsInRaid()
    local nMapType = self:GetMapType()

    for _, nGroupID in ipairs(tGroupIndexByMapType[nMapType]) do
        local szTitle = tGroupID2Desc[nGroupID]
        if nGroupID == 2 and not bTeam then
        else
            local TitleScript = UIHelper.AddPrefab(PREFAB_ID.WidgetQuickOperationTitle, self.ScrollViewQuickOperation) assert(TitleScript)
            UIHelper.SetString(TitleScript.LabelQuickOperationTitle, szTitle)

            --宠物交互放里面了，侠客交互先删掉了
            TitleScript = UIHelper.AddPrefab(PREFAB_ID.WidgetQuickOperationLayout, self.ScrollViewQuickOperation, nGroupID) assert(TitleScript)
            UIHelper.LayoutDoLayout(TitleScript.WidgetQuickOperationLayout)
        end
    end

    Timer.AddFrame(self,1,function ()
        UIHelper.ScrollViewDoLayout(self.ScrollViewQuickOperation)
	    UIHelper.ScrollToTop(self.ScrollViewQuickOperation, 0, false)
    end)
end

function UIQuickOperationView:UpdateActionAndFaceList()
    -- UIHelper.RemoveAllChildren(self.ScrollViewActionOperation)
    HeadEmotionData.Init()
    self:UpdatePendantList()
    self:UpdateExteriorList()
    self:UpdateHorseList()
    self:UpdateEmotionActionList()
    self:UpdateHeadEmotionList()
    self:UpdateFaceMotionList()
end

function UIQuickOperationView:UpdatePendantList()
    -- 挂件动作
    if not self.scriptPendantTitle then
        self.scriptPendantTitle = UIHelper.AddPrefab(PREFAB_ID.WidgetQuickOperationTitle, self.ScrollViewActionOperation)
        UIHelper.SetString(self.scriptPendantTitle.LabelQuickOperationTitle, "挂件动作")
        UIHelper.SetVisible(self.scriptPendantTitle.BtnSetting, true)
        UIHelper.BindUIEvent(self.scriptPendantTitle.BtnSetting, EventType.OnClick, function()
            self:SetBtnEditState(true)
            UIMgr.OpenSingleWithOnEnter(false, VIEW_ID.PanelQuickOperationBagTab, QuickOperation_Action_Type.PendantAction, 1, tbPendantTypeToSpriteName, function()
                self:SetBtnEditState(false)
            end)
        end)
    end

    if not self.scriptPendantLayout then
        self.scriptPendantLayout = UIHelper.AddPrefab(PREFAB_ID.WidgetQuickOperationLayout, self.ScrollViewActionOperation)
        UIHelper.RemoveAllChildren(self.scriptPendantLayout.WidgetQuickOperationLayout)
    end
    local petIndex = 0
    local LHandIndex = 0
    local RHandIndex = 0
    local GlassesIndex = 0
    self.tHavePendant = {}
    for k, v in ipairs(CharacterPendantData.GetPendantTypeList()) do
        local szSpriteName = tbPendantTypeToSpriteName[v.szType]
        if szSpriteName then
            -- 特判左右首饰
            self:CreateOnePendentPart(k , v)
            if CharacterPendantData.IsPetInPendentPartInfo(k) then
                petIndex = k
            elseif CharacterPendantData.IsLHandInPendentPartInfo(k) then
                LHandIndex = k
            elseif CharacterPendantData.IsRHandInPendentPartInfo(k) then
                RHandIndex = k
            elseif CharacterPendantData.IsGlassesInPendentPartInfo(k) then
                GlassesIndex = k
            end
        end
    end
    self:UpdatePetPart(petIndex)
    self.tbLHandSkill = {}
    self.tbRHandSkill = {}
    self:UpdateLHandPart(LHandIndex)
    self:UpdateRHandPart(RHandIndex)
    self:UpdateGlassesPart(GlassesIndex)
    UIHelper.LayoutDoLayout(self.scriptPendantLayout.WidgetQuickOperationLayout)
    UIHelper.ScrollViewDoLayoutAndToTop(self.ScrollViewActionOperation)
end

function UIQuickOperationView:UpdateExteriorList()
    if not self.scriptExteriorTitle then
        self.scriptExteriorTitle = UIHelper.AddPrefab(PREFAB_ID.WidgetQuickOperationTitle, self.ScrollViewActionOperation)
        UIHelper.SetString(self.scriptExteriorTitle.LabelQuickOperationTitle, "外装动作")
    end

    if not self.scriptExteriorLayout then
        self.scriptExteriorLayout = UIHelper.AddPrefab(PREFAB_ID.WidgetQuickOperationLayout, self.ScrollViewActionOperation)
        UIHelper.RemoveAllChildren(self.scriptExteriorLayout.WidgetQuickOperationLayout)
    end
    local tRepresentIDs = GetClientPlayer().GetRepresentID()
    local aRes = CharacterExteriorData.FindMatchedExteriorInfo(tRepresentIDs)
    local bHasExterior = false
    if self.tbExteriorBtnList then
        for _, script in pairs(self.tbExteriorBtnList) do
            UIHelper.SetVisible(script._rootNode , false)
        end
    end
    for resIndex, resInfo in pairs(aRes) do
       -- LOG.INFO(string.format("UpdateAllExteriorSkills  %s,%s,%s",tostring(resInfo.dwSkillID),tostring(resInfo.dwSkillLevel),tostring(UIHelper.GBKToUTF8(resInfo.szDes))))
        if CharacterExteriorData.IsExtrior(resInfo.aRepresentIDGroups1) then
            bHasExterior = true
            self:CreateOneExteriorPart(resIndex , resInfo ,table.get_len(resInfo.aRepresentIDGroups1) > 2, self.tbExteriorBtnList , self.scriptExteriorLayout.WidgetQuickOperationLayout)
            UIHelper.SetVisible(self.tbExteriorBtnList[resIndex]._rootNode , true)
        elseif CharacterExteriorData.IsBackPandent(resInfo.aRepresentIDGroups1) then
            self:CreateOneExteriorPart(resIndex , resInfo ,false, self.tbPendantOtherBtnList.Skill , self.scriptPendantLayout.WidgetQuickOperationLayout)
        elseif CharacterExteriorData.IsLRHandPandent(resInfo.aRepresentIDGroups1) then
            self:CreateOneExteriorPart(resIndex , resInfo ,false, self.tbPendantOtherBtnList.Skill , self.scriptPendantLayout.WidgetQuickOperationLayout)
        end
    end

    -- 外装发型subset多部件玩家自定义隐藏
    local aSubsetHideSkill = CharacterExteriorData.GetAllSubsetHideExteriorSkills()
    for i, tSkill in ipairs(aSubsetHideSkill) do
        bHasExterior = true
        local resIndex = #aRes + i
        self:CreateOneExteriorPart(resIndex , tSkill , false, self.tbExteriorBtnList , self.scriptExteriorLayout.WidgetQuickOperationLayout)
        UIHelper.SetVisible(self.tbExteriorBtnList[resIndex]._rootNode , true)
    end

    UIHelper.LayoutDoLayout(self.scriptPendantLayout.WidgetQuickOperationLayout)
    UIHelper.LayoutDoLayout(self.scriptExteriorLayout.WidgetQuickOperationLayout)

    if self.scriptExteriorTitle then
       UIHelper.SetVisible(self.scriptExteriorTitle._rootNode, bHasExterior)
       UIHelper.SetVisible(self.scriptExteriorLayout._rootNode, bHasExterior)
    end
    UIHelper.ScrollViewDoLayoutAndToTop(self.ScrollViewActionOperation)
end

function UIQuickOperationView:UpdateHorseList()
    if not self.scriptHorseTitle then
        self.scriptHorseTitle = UIHelper.AddPrefab(PREFAB_ID.WidgetQuickOperationTitle, self.ScrollViewActionOperation)
        UIHelper.SetString(self.scriptHorseTitle.LabelQuickOperationTitle, "马具动作")
    end

    if not self.scriptHorseLayout then
        self.scriptHorseLayout = UIHelper.AddPrefab(PREFAB_ID.WidgetQuickOperationLayout, self.ScrollViewActionOperation)
        UIHelper.RemoveAllChildren(self.scriptHorseLayout.WidgetQuickOperationLayout)
    end
    local tRepresentIDs = GetClientPlayer().GetRepresentID()
    local aRes = CharacterExteriorData.FindMatchedExteriorInfo(tRepresentIDs)
    local bHasHorse = false
    if self.tbHorseBtnList then
        for _, script in pairs(self.tbHorseBtnList) do
            UIHelper.SetVisible(script._rootNode , false)
        end
    end
    for resIndex, resInfo in pairs(aRes) do
        if CharacterExteriorData.IsHorse(resInfo.aRepresentIDGroups1) then
            bHasHorse = true
            self:CreateOneExteriorPart(resIndex , resInfo ,true, self.tbHorseBtnList , self.scriptHorseLayout.WidgetQuickOperationLayout)
            UIHelper.SetVisible(self.tbHorseBtnList[resIndex]._rootNode , true)
        end
    end
    UIHelper.LayoutDoLayout(self.scriptHorseLayout.WidgetQuickOperationLayout)
    UIHelper.ScrollViewDoLayoutAndToTop(self.ScrollViewActionOperation)
    if self.scriptHorseTitle then
       UIHelper.SetVisible(self.scriptHorseTitle._rootNode , bHasHorse)
       UIHelper.SetVisible(self.scriptHorseLayout._rootNode , bHasHorse)
    end
end

function UIQuickOperationView:UpdateLHandPart(LHandIndex)
    local tRepresentIDs = GetClientPlayer().GetRepresentID()
    local aRes = CharacterExteriorData.FindMatchedExteriorInfo(tRepresentIDs)
    if self.tbPendantOtherBtnList.LHand then
        for _, script in pairs(self.tbPendantOtherBtnList.LHand) do
            UIHelper.SetVisible(script._rootNode , false)
        end
    end

    local bHasPart = false
    for resIndex, resInfo in pairs(aRes) do
        if CharacterExteriorData.IsLHandPandent(resInfo.aRepresentIDGroups1) then
            bHasPart = true
            if not table.contain_value(self.tbRHandSkill , resInfo.dwSkillID) then
                table.insert(self.tbLHandSkill , resInfo.dwSkillID)
                self:CreateOneExteriorPart(resIndex , resInfo ,false, self.tbPendantOtherBtnList.LHand , self.scriptPendantLayout.WidgetQuickOperationLayout, LHandIndex)
                UIHelper.SetVisible(self.tbPendantOtherBtnList.LHand[resIndex]._rootNode , true)
            end
        end
    end
    if self.tbPendantBtnList[LHandIndex] then
        UIHelper.SetVisible(self.tbPendantBtnList[LHandIndex]._rootNode , not bHasPart)
    end
end

function UIQuickOperationView:UpdateRHandPart(RHandIndex)
    local tRepresentIDs = GetClientPlayer().GetRepresentID()
    local aRes = CharacterExteriorData.FindMatchedExteriorInfo(tRepresentIDs)
    if self.tbPendantOtherBtnList.RHand then
        for _, script in pairs(self.tbPendantOtherBtnList.RHand) do
            UIHelper.SetVisible(script._rootNode , false)
        end
    end

    local bHasPart = false
    for resIndex, resInfo in pairs(aRes) do
        if CharacterExteriorData.IsRHandPandent(resInfo.aRepresentIDGroups1) then
            bHasPart = true
            if not table.contain_value(self.tbRHandSkill , resInfo.dwSkillID) then
                table.insert(self.tbRHandSkill , resInfo.dwSkillID)
                self:CreateOneExteriorPart(resIndex , resInfo ,false, self.tbPendantOtherBtnList.RHand , self.scriptPendantLayout.WidgetQuickOperationLayout, RHandIndex)
                UIHelper.SetVisible(self.tbPendantOtherBtnList.RHand[resIndex]._rootNode , true)
            end
        end
    end
    if self.tbPendantBtnList[RHandIndex] then
        UIHelper.SetVisible(self.tbPendantBtnList[RHandIndex]._rootNode , not bHasPart)
    end
end

function UIQuickOperationView:UpdateGlassesPart(nGlassesIndex)
    local tRepresentIDs = GetClientPlayer().GetRepresentID()
    local aRes = CharacterExteriorData.FindMatchedExteriorInfo(tRepresentIDs)
    if self.tbPendantOtherBtnList.Glasses then
        for _, script in pairs(self.tbPendantOtherBtnList.Glasses) do
            UIHelper.SetVisible(script._rootNode , false)
        end
    end

    local bHasPart = false
    for resIndex, resInfo in pairs(aRes) do
        if CharacterExteriorData.IsGlassesPandent(resInfo.aRepresentIDGroups1) then
            bHasPart = true
            self:CreateOneExteriorPart(resIndex , resInfo ,false, self.tbPendantOtherBtnList.Glasses , self.scriptPendantLayout.WidgetQuickOperationLayout, nGlassesIndex)
            UIHelper.SetVisible(self.tbPendantOtherBtnList.Glasses[resIndex]._rootNode , true)
        end
    end
    if self.tbPendantBtnList[nGlassesIndex] then
        UIHelper.SetVisible(self.tbPendantBtnList[nGlassesIndex]._rootNode , not bHasPart)
    end
end

function UIQuickOperationView:UpdatePetPart(petIndex)
    local tRepresentIDs = GetClientPlayer().GetRepresentID()
    local aRes = CharacterExteriorData.FindMatchedExteriorInfo(tRepresentIDs)
    if self.tbPendantOtherBtnList.Pet then
        for _, script in pairs(self.tbPendantOtherBtnList.Pet) do
            UIHelper.SetVisible(script._rootNode , false)
        end
    end
    local bHasPet = false
    for resIndex, resInfo in pairs(aRes) do
        if CharacterExteriorData.IsPet(resInfo.aRepresentIDGroups1) then
            bHasPet = true
            self:CreateOneExteriorPart(resIndex , resInfo ,false, self.tbPendantOtherBtnList.Pet , self.scriptPendantLayout.WidgetQuickOperationLayout, petIndex)
            UIHelper.SetVisible(self.tbPendantOtherBtnList.Pet[resIndex]._rootNode , true)
        end
    end
    if self.tbPendantBtnList[petIndex] then
        UIHelper.SetVisible(self.tbPendantBtnList[petIndex]._rootNode , not bHasPet)
    end
end

function UIQuickOperationView:CreateOnePendentPart(index , pendantInfo)
    local dwPendantID = CharacterPendantData.GetUsingPendantID(index)
    local tItemInfo = dwPendantID > 0 and GetItemInfo(ITEM_TABLE_TYPE.CUST_TRINKET, dwPendantID) or nil
    local bHasPendantID = tItemInfo and tItemInfo.dwSkillID and tItemInfo.dwSkillID > 0
    local szName = bHasPendantID and GBKToUTF8(tItemInfo.szName) or pendantInfo.szName

    local scriptBtn = self.tbPendantBtnList[index] or UIHelper.AddPrefab(PREFAB_ID.WidgetQuickOperationBtn, self.scriptPendantLayout.WidgetQuickOperationLayout)
    self.tbPendantBtnList[index] = scriptBtn
    UIHelper.SetString(scriptBtn.LabelName, szName, 4)
    UIHelper.SetVisible(scriptBtn.ImgIconAdd, false)--not bHasPendantID)

    if bHasPendantID then
        table.insert(self.tHavePendant, index)
        UIHelper.RemoveAllChildren(scriptBtn.WidgetContainer)
        local scriptItemIcon = UIHelper.AddPrefab(PREFAB_ID.WidgetItem_100, scriptBtn.WidgetContainer)
        scriptItemIcon:OnInitWithTabID(ITEM_TABLE_TYPE.CUST_TRINKET, dwPendantID)
        --UIHelper.SetVisible(scriptItemIcon.ToggleSelect, false)
        UIHelper.SetEnable(scriptItemIcon.ToggleSelect, false)
        UIHelper.SetScale(scriptItemIcon._rootNode, 0.7, 0.7)
        UIHelper.SetVisible(scriptBtn.WidgetContainer, true)

        UIHelper.SetVisible(scriptBtn.BtnRecall, true and self.bOnEdit)
        UIHelper.BindUIEvent(scriptBtn.BtnRecall, EventType.OnClick, function ()
            CharacterPendantData.EquipPendant({ dwItemIndex = dwPendantID }, index, false)
        end)
    else
        --UIHelper.ClearTexture(scriptBtn.ImgIcon)
        if string.is_nil(tbPendantTypeToSpriteName[pendantInfo.szType]) then
            UIHelper.SetVisible(scriptBtn._rootNode, false)
        else
            UIHelper.SetSpriteFrame(scriptBtn.ImgIcon, tbPendantTypeToSpriteName[pendantInfo.szType])
            UIHelper.SetVisible(scriptBtn.WidgetContainer, false)

            UIHelper.SetVisible(scriptBtn.BtnRecall, false)
        end

    end
    UIHelper.BindUIEvent(scriptBtn.BtnQuickOperation, EventType.OnClick, function()
        if bHasPendantID then
            OnUseSkill(tItemInfo.dwSkillID, 1)
            APIHelper.SetUsePendantAction()
        else
            self:SetBtnEditState(true)
            UIMgr.OpenSingleWithOnEnter(false, VIEW_ID.PanelQuickOperationBagTab, QuickOperation_Action_Type.PendantAction, index, tbPendantTypeToSpriteName, function()
                self:SetBtnEditState(false)
            end)
        end
    end)
end

function UIQuickOperationView:CreateOneExteriorPart(index , resInfo , isHorsePart , tbBtnList , widgetLayout , nType)

    local scriptBtn = tbBtnList[index] or UIHelper.AddPrefab(PREFAB_ID.WidgetQuickOperationBtn, widgetLayout)
    tbBtnList[index] = scriptBtn
    UIHelper.SetString(scriptBtn.LabelName, UIHelper.GBKToUTF8(resInfo.szName) , 4)
    UIHelper.SetVisible(scriptBtn.ImgIconAdd, false)

    UIHelper.RemoveAllChildren(scriptBtn.WidgetContainer)
    local scriptItemIcon = UIHelper.AddPrefab(PREFAB_ID.WidgetItem_100, scriptBtn.WidgetContainer)
    scriptItemIcon:OnInitSkill(resInfo.dwSkillID, resInfo.dwSkillLevel)

    UIHelper.SetItemIconByIconID(scriptItemIcon.ImgIcon, resInfo.dwIconID)

    UIHelper.SetNodeGray(scriptItemIcon.ImgIcon , GetClientPlayer().bOnHorse and (not isHorsePart))

    UIHelper.SetEnable(scriptItemIcon.ToggleSelect, false)
    UIHelper.SetScale(scriptItemIcon._rootNode, 0.7, 0.7)
    UIHelper.SetVisible(scriptBtn.WidgetContainer, true)

    UIHelper.BindUIEvent(scriptBtn.BtnQuickOperation, EventType.OnClick, function()
        local box = {nSkillLevel = resInfo.dwSkillLevel}
        OnUseSkill(resInfo.dwSkillID, (resInfo.dwSkillID * (resInfo.dwSkillID % 10 + 1)), box)
    end)

    if nType then
        UIHelper.SetVisible(scriptBtn.BtnRecall, true and self.bOnEdit)
        UIHelper.BindUIEvent(scriptBtn.BtnRecall, EventType.OnClick, function ()
            CharacterPendantData.EquipPendant({ dwItemIndex = resInfo.dwItemIndex }, nType, false)
        end)
    end
end

function UIQuickOperationView:UpdateSkillCoolDown(nSkillID)
    local _, nLeft, nTotal = SkillData.GetSkillCDProcess(g_pClientPlayer, nSkillID)
    nLeft = nLeft or 0
    nTotal = nTotal or 1
    nLeft = math.ceil(nLeft / GLOBAL.GAME_FPS)
    nTotal = math.ceil(nTotal / GLOBAL.GAME_FPS)
    if nLeft and nLeft ~= 0 then
        self.nPetSkillCDTimer = self.nPetSkillCDTimer or Timer.AddCycle(self, 1, function()
            self:UpdateSkillCoolDown(nSkillID)
        end)
        for k,v in ipairs(self.tPetActionScriptBtn) do
            UIHelper.SetString(v.scriptBtn.CdLabel,nLeft)
            UIHelper.SetProgressBarPercent(v.scriptBtn.SliderSkillCd,  nLeft * 100 / nTotal)
        end
    else
        if self.nPetSkillCDTimer then
            Timer.DelAllTimer(self)
            self.nPetSkillCDTimer = nil
            self.nAllCDTimer = nil
        end
    end
    for k,v in ipairs(self.tPetActionScriptBtn) do
        UIHelper.SetVisible(v.scriptBtn.SliderSkillCd, nLeft ~= 0)
        UIHelper.SetVisible(v.scriptBtn.CdLabel, nLeft ~= 0)
    end
end

--表情动作
local FaviEmotionAction_Count = 5

QuickOperation_Action_Type = {
    PendantAction = 1,
    EmotionAction = 2,
    HeadEmotion = 3,
    FaceMotion = 4,
}

function UIQuickOperationView:UpdateEmotionActionList()
    EmotionData.QuickLoad()

    if not self.scriptEmotionActionTitle then
        self.scriptEmotionActionTitle = UIHelper.AddPrefab(PREFAB_ID.WidgetQuickOperationTitle, self.ScrollViewActionOperation)
        UIHelper.SetString(self.scriptEmotionActionTitle.LabelQuickOperationTitle, "表情动作")
        UIHelper.SetVisible(self.scriptEmotionActionTitle.BtnSetting, true)
        UIHelper.BindUIEvent(self.scriptEmotionActionTitle.BtnSetting, EventType.OnClick, function()
            --self:DrawEmotionActionDelete(true)
            self:SetBtnEditState(true)
            UIMgr.OpenSingleWithOnEnter(false, VIEW_ID.PanelQuickOperationBagTab, QuickOperation_Action_Type.EmotionAction, nil, nil, function()
                self:SetBtnEditState(false)
            end)
        end)

        RedpointMgr.RegisterRedpoint(self.scriptEmotionActionTitle.ImgRedPoint, nil, {1602})
    end

    if not self.scriptEmotionActionLayout then
        self.scriptEmotionActionLayout = UIHelper.AddPrefab(PREFAB_ID.WidgetQuickOperationLayout, self.ScrollViewActionOperation)
        UIHelper.RemoveAllChildren(self.scriptEmotionActionLayout.WidgetQuickOperationLayout)

        self.tBtnEmotionAction = {}
        for i = 1, FaviEmotionAction_Count, 1 do
            local tmpBtn = UIHelper.AddPrefab(PREFAB_ID.WidgetQuickOperationBtn, self.scriptEmotionActionLayout.WidgetQuickOperationLayout)
            self.tBtnEmotionAction[i] = tmpBtn
        end
    end

    self.tPreFaviEmotionActions = {}
    self:UpdateEmotionActionBtn()
end

function UIQuickOperationView:UpdateEmotionActionBtn(bAdd, dwID)
    local tFaviEmotionActions = GetClientPlayer().GetMobileEmotionActionDIYList() or {}

    if not bAdd and not dwID then
        self.nActionPos = math.min(#tFaviEmotionActions, FaviEmotionAction_Count)
        self:DrawEmotionActionBtn(tFaviEmotionActions, 1, self.nActionPos)

        self.nActionPos = self.nActionPos + 1
        self:DrawEmptyEmotionActionBtn(self.nActionPos, FaviEmotionAction_Count)

        UIHelper.LayoutDoLayout(self.scriptEmotionActionLayout.WidgetQuickOperationLayout)
        UIHelper.ScrollViewDoLayoutAndToTop(self.ScrollViewActionOperation)
        self.tPreFaviEmotionActions = tFaviEmotionActions
        return
    end

    if bAdd == 1 and dwID then
        if self.nActionPos > FaviEmotionAction_Count then
            return
        end
        local tEmotionData = EmotionData.GetEmotionAction(dwID)
        if tEmotionData then
            if tEmotionData.bShow then
                local nTargetPos = 0
                for i = 1, #tFaviEmotionActions do
                    if tFaviEmotionActions[i] == dwID then
                        nTargetPos = i
                        break
                    end
                end
                self:DrawEmotionActionBtn(tFaviEmotionActions, nTargetPos, self.nActionPos)
                self.nActionPos = self.nActionPos + 1

                UIHelper.LayoutDoLayout(self.scriptEmotionActionLayout.WidgetQuickOperationLayout)
                UIHelper.ScrollViewDoLayoutAndToTop(self.ScrollViewActionOperation)
                self.tPreFaviEmotionActions = tFaviEmotionActions
            end
        end
        return
    end

    if bAdd == 0 and dwID then
        local tlens = #tFaviEmotionActions
        local bFound = false
        for i = 1, tlens, 1 do
            if tFaviEmotionActions[i] ~= self.tPreFaviEmotionActions[i] then
                bFound = true
                self.nActionPos = i
                break
            end
        end

        if bFound == true then
            local endPos = math.min(tlens, FaviEmotionAction_Count)
            self:DrawEmotionActionBtn(tFaviEmotionActions, self.nActionPos, endPos)
        end

        self.nActionPos = tlens + 1
        self:DrawEmptyEmotionActionBtn(self.nActionPos, self.nActionPos)

        UIHelper.LayoutDoLayout(self.scriptEmotionActionLayout.WidgetQuickOperationLayout)
        UIHelper.ScrollViewDoLayoutAndToTop(self.ScrollViewActionOperation)
        self.tPreFaviEmotionActions = tFaviEmotionActions
    end
end

function UIQuickOperationView:DrawEmotionActionBtn(tEmotionActions, nBegin, nEnd)
    if nBegin > 0 and nEnd > 0 and tEmotionActions then
        nEnd = math.min(nEnd, FaviEmotionAction_Count)
        for i = nBegin, nEnd, 1 do
            local tEmotionData = EmotionData.GetEmotionAction(tEmotionActions[i])
            if tEmotionData  and tEmotionData.bShow then
                -- DX:UpdateEmotionActionBoxObject
                local scriptBtn = self.tBtnEmotionAction[i]
                UIHelper.SetVisible(scriptBtn.ImgIcon, false)
                UIHelper.RemoveAllChildren(scriptBtn.WidgetContainer)
                UIHelper.SetVisible(scriptBtn.ImgIconAdd, false)
                local szName = tEmotionData.szName
                local nCharCount,szUtfName = GetStringCharCountAndTopChars(UIHelper.GBKToUTF8(szName),4)
                UIHelper.SetString(scriptBtn.LabelName, nCharCount > 4 and szUtfName.."..." or szUtfName)
                UIHelper.SetVisible(scriptBtn.LabelName, true)
                if tEmotionData.bInteract then
                    UIHelper.SetVisible(scriptBtn.ImgDoubleMark, true)
                    UIHelper.SetSpriteFrame(scriptBtn.ImgDoubleMark, "UIAtlas2_Public_PublicIcon_PublicIcon1_OperationIcon1")
                elseif tEmotionData.bAniEdit then
                    UIHelper.SetVisible(scriptBtn.ImgDoubleMark, true)
                    UIHelper.SetSpriteFrame(scriptBtn.ImgDoubleMark, "UIAtlas2_Public_PublicIcon_PublicIcon1_OperationIcon2")
                elseif tEmotionData.nAniType ~= 0 and EMOTION_ACTION_ANI_TYPE[tEmotionData.nAniType] then
                    UIHelper.SetVisible(scriptBtn.ImgDoubleMark, true)
                    local path = "UIAtlas2_Public_PublicIcon_PublicIcon1_OperationIcon" .. EMOTION_ACTION_ANI_TYPE[tEmotionData.nAniType]
                    UIHelper.SetSpriteFrame(scriptBtn.ImgDoubleMark, path)
                else
                    UIHelper.SetVisible(scriptBtn.ImgDoubleMark, false)
                end

                local itemScript = UIHelper.AddPrefab(PREFAB_ID.WidgetItem_100, scriptBtn.WidgetContainer) assert(itemScript)
                itemScript:OnInitWithIconID(tEmotionData.nIconID)
                UIHelper.SetScale(itemScript._rootNode, 0.6, 0.6)
                --UIHelper.SetVisible(itemScript.ToggleSelect, false)
                itemScript:SetSelectEnable(false)

                UIHelper.BindUIEvent(scriptBtn.BtnQuickOperation, EventType.OnClick, function ()
                    --EmotionData.ProcessEmotionAction(tEmotionData.dwID, true)
                    EmotionData.ProcessEmotionActionTemp(tEmotionData.dwID, true)
                end)

                UIHelper.SetVisible(scriptBtn.BtnRecall, true and self.bOnEdit)
                UIHelper.BindUIEvent(scriptBtn.BtnRecall, EventType.OnClick, function ()
                    local hPlayer = GetClientPlayer()
                    hPlayer.SetMobileEmotionActionDIYInfo(false, tEmotionData.dwID)
                end)
            end
        end
    end
end

function UIQuickOperationView:DrawEmptyEmotionActionBtn(nBegin, nEnd)
    if nBegin > 0 and nEnd > 0 then
        nEnd = math.min(nEnd, FaviEmotionAction_Count)
        for i = nBegin, nEnd ,1 do
            local scriptEmptyBtn = self.tBtnEmotionAction[i]
            UIHelper.RemoveAllChildren(scriptEmptyBtn.WidgetContainer)
            UIHelper.SetVisible(scriptEmptyBtn.ImgIcon, false)
            UIHelper.SetVisible(scriptEmptyBtn.LabelName, false)
            UIHelper.SetVisible(scriptEmptyBtn.ImgIconAdd, true)
            UIHelper.BindUIEvent(scriptEmptyBtn.BtnQuickOperation, EventType.OnClick, function ()
                --self:DrawEmotionActionDelete(true)
                self:SetBtnEditState(true)
                UIMgr.OpenSingleWithOnEnter(false, VIEW_ID.PanelQuickOperationBagTab, QuickOperation_Action_Type.EmotionAction, nil, nil, function()
                    self:SetBtnEditState(false)
                end)
            end)
            UIHelper.SetVisible(scriptEmptyBtn.ImgDoubleMark, false)
            UIHelper.SetVisible(scriptEmptyBtn.BtnRecall, false)
        end
    end
end

function UIQuickOperationView:DrawEmotionActionDelete(bSet)
    for i = 1, self.nActionPos - 1, 1 do
        local scriptBtn = self.tBtnEmotionAction[i]
        UIHelper.SetVisible(scriptBtn.BtnRecall, bSet)
    end
end

--- 头顶表情

function UIQuickOperationView:UpdateHeadEmotionList()
    if not self.scriptHeadEmotionTitle then
        self.scriptHeadEmotionTitle = UIHelper.AddPrefab(PREFAB_ID.WidgetQuickOperationTitle, self.ScrollViewActionOperation)
        UIHelper.SetString(self.scriptHeadEmotionTitle.LabelQuickOperationTitle, "头顶表情")
        UIHelper.SetVisible(self.scriptHeadEmotionTitle.BtnSetting, true)
        UIHelper.BindUIEvent(self.scriptHeadEmotionTitle.BtnSetting, EventType.OnClick, function()
            --self:DrawHeadEmotionDelete(true)
            self:SetBtnEditState(true)
            UIMgr.OpenSingleWithOnEnter(false, VIEW_ID.PanelQuickOperationBagTab, QuickOperation_Action_Type.HeadEmotion, nil, nil, function()
                self:SetBtnEditState(false)
            end)
        end)

        RedpointMgr.RegisterRedpoint(self.scriptHeadEmotionTitle.ImgRedPoint, nil, {1603})
    end

    if not self.scriptHeadEmotionLayout then
        self.scriptHeadEmotionLayout = UIHelper.AddPrefab(PREFAB_ID.WidgetQuickOperationLayout, self.ScrollViewActionOperation)
        UIHelper.RemoveAllChildren(self.scriptHeadEmotionLayout.WidgetQuickOperationLayout)
        self.tBtnHeadEmotion = {}
        for i = 1, FaviEmotionAction_Count, 1 do
            local tmpBtn = UIHelper.AddPrefab(PREFAB_ID.WidgetQuickOperationBtn, self.scriptHeadEmotionLayout.WidgetQuickOperationLayout)
            self.tBtnHeadEmotion[i] = tmpBtn
        end
    end

    self.tPreFaviHeadEmotions = {}
    self:UpdateHeadEmotionBtn()
end

function UIQuickOperationView:UpdateHeadEmotionBtn(bAdd, dwID)
    local tFaviHeadEmotions = HeadEmotionData.GetFaviHeadEmotions()

    if not bAdd and not dwID then
        self.nHeadEmotionPos = math.min(#tFaviHeadEmotions, FaviEmotionAction_Count)
        self:DrawHeadEmotionBtn(tFaviHeadEmotions, 1, self.nHeadEmotionPos)

        self.nHeadEmotionPos = self.nHeadEmotionPos + 1
        self:DrawEmptyHeadEmotionBtn(self.nHeadEmotionPos, FaviEmotionAction_Count)

        UIHelper.LayoutDoLayout(self.scriptHeadEmotionLayout.WidgetQuickOperationLayout)
        UIHelper.ScrollViewDoLayoutAndToTop(self.ScrollViewActionOperation)
        self.tPreFaviHeadEmotions = tFaviHeadEmotions
        return
    end

    if bAdd == 1 and dwID then
        if self.nHeadEmotionPos > FaviEmotionAction_Count then
            return
        end
        local tHeadEmotion = HeadEmotionData.GetHeadEmotion(dwID)
        if tHeadEmotion then
            local nTargetPos = 0
            for i = 1, #tFaviHeadEmotions do
                if tFaviHeadEmotions[i] == dwID then
                    nTargetPos = i
                    break
                end
            end
            self:DrawHeadEmotionBtn(tFaviHeadEmotions, nTargetPos, self.nHeadEmotionPos)
            self.nHeadEmotionPos = self.nHeadEmotionPos + 1

            UIHelper.LayoutDoLayout(self.scriptHeadEmotionLayout.WidgetQuickOperationLayout)
            UIHelper.ScrollViewDoLayoutAndToTop(self.ScrollViewActionOperation)
            self.tPreFaviHeadEmotions = tFaviHeadEmotions
        end
        return
    end

    if bAdd == 0 and dwID then
        local tlens = #tFaviHeadEmotions
        local bFound = false
        for i = 1, tlens, 1 do
            if tFaviHeadEmotions[i] ~= self.tPreFaviHeadEmotions[i] then
                bFound = true
                self.nHeadEmotionPos = i
                break
            end
        end

        if bFound == true then
            local endPos = math.min(tlens, FaviEmotionAction_Count)
            self:DrawHeadEmotionBtn(tFaviHeadEmotions, self.nHeadEmotionPos, endPos)
        end

        self.nHeadEmotionPos = tlens + 1
        self:DrawEmptyHeadEmotionBtn(self.nHeadEmotionPos, self.nHeadEmotionPos)

        UIHelper.LayoutDoLayout(self.scriptHeadEmotionLayout.WidgetQuickOperationLayout)
        self.tPreFaviHeadEmotions = tFaviHeadEmotions
    end
end

function UIQuickOperationView:DrawHeadEmotionBtn(tHeadEmotions, nBegin, nEnd)
    if nBegin > 0 and nEnd > 0 and tHeadEmotions then
        nEnd = math.min(nEnd, FaviEmotionAction_Count)
        for i = nBegin, nEnd, 1 do
            local tHeadEmotion = HeadEmotionData.GetHeadEmotion(tHeadEmotions[i])
            if tHeadEmotion then
                -- DX:UpdateBrightMarkBoxObject
                local scriptBtn = self.tBtnHeadEmotion[i]
                UIHelper.SetVisible(scriptBtn.ImgIcon, false)
                UIHelper.RemoveAllChildren(scriptBtn.WidgetContainer)
                UIHelper.SetVisible(scriptBtn.ImgIconAdd, false)
                local szName = tHeadEmotion.szName
                local nCharCount,szUtfName = GetStringCharCountAndTopChars(UIHelper.GBKToUTF8(szName),4)
                --UIHelper.SetString(scriptBtn.LabelName,nCharCount > 4 and szUtfName.."..." or szUtfName)
                UIHelper.SetString(scriptBtn.LabelName, szUtfName)
                UIHelper.SetVisible(scriptBtn.LabelName, true)

                local itemScript = UIHelper.AddPrefab(PREFAB_ID.WidgetItem_100, scriptBtn.WidgetContainer)
                itemScript:OnInitWithIconID(tHeadEmotion.nIconID, nil, true)
                UIHelper.SetScale(itemScript._rootNode, 0.6, 0.6)
                --UIHelper.SetVisible(itemScript.ToggleSelect, false)
                itemScript:SetSelectEnable(false)

                UIHelper.BindUIEvent(scriptBtn.BtnQuickOperation, EventType.OnClick, function ()
                    HeadEmotionData.ProcessHeadEmotion(tHeadEmotion.dwID)
                end)

                UIHelper.SetVisible(scriptBtn.BtnRecall, true and self.bOnEdit)
                UIHelper.BindUIEvent(scriptBtn.BtnRecall, EventType.OnClick, function ()
                    local hPlayer = GetClientPlayer()
                    hPlayer.SetMobileHeadEmotionDIYInfo(false, tHeadEmotion.dwID)
                end)
            end
        end
    end
end

function UIQuickOperationView:DrawEmptyHeadEmotionBtn(nBegin, nEnd)
    if nBegin > 0 and nEnd > 0 then
        nEnd = math.min(nEnd, FaviEmotionAction_Count)
        for i = nBegin, nEnd ,1 do
            local scriptEmptyBtn = self.tBtnHeadEmotion[i]
            UIHelper.RemoveAllChildren(scriptEmptyBtn.WidgetContainer)
            UIHelper.SetVisible(scriptEmptyBtn.ImgIcon, false)
            UIHelper.SetVisible(scriptEmptyBtn.LabelName, false)
            UIHelper.SetVisible(scriptEmptyBtn.ImgIconAdd, true)
            UIHelper.SetVisible(scriptEmptyBtn.BtnRecall, false)
            UIHelper.BindUIEvent(scriptEmptyBtn.BtnQuickOperation, EventType.OnClick, function ()
                --self:DrawHeadEmotionDelete(true)
                self:SetBtnEditState(true)
                UIMgr.OpenSingleWithOnEnter(false, VIEW_ID.PanelQuickOperationBagTab, QuickOperation_Action_Type.HeadEmotion, nil, nil, function()
                    self:SetBtnEditState(false)
                end)
            end)
        end
    end
end

function UIQuickOperationView:DrawHeadEmotionDelete(bSet)
    for i = 1, self.nHeadEmotionPos - 1, 1 do
        local scriptBtn = self.tBtnHeadEmotion[i]
        UIHelper.SetVisible(scriptBtn.BtnRecall, bSet)
    end
end

--捏脸表情
function UIQuickOperationView:UpdateFaceMotionList()
    if not self.scriptFaceMotionTitle then
        self.scriptFaceMotionTitle = UIHelper.AddPrefab(PREFAB_ID.WidgetQuickOperationTitle, self.ScrollViewActionOperation)
        UIHelper.SetString(self.scriptFaceMotionTitle.LabelQuickOperationTitle, "面部表情")
        UIHelper.SetVisible(self.scriptFaceMotionTitle.BtnSetting, true)
        UIHelper.BindUIEvent(self.scriptFaceMotionTitle.BtnSetting, EventType.OnClick, function()
            self:SetBtnEditState(true)
            UIMgr.OpenSingleWithOnEnter(false, VIEW_ID.PanelQuickOperationBagTab, QuickOperation_Action_Type.FaceMotion, 1, nil , function()
                self:SetBtnEditState(false)
            end)
        end)
    end

    if not self.scriptFaceMotionLayout then
        self.scriptFaceMotionLayout = UIHelper.AddPrefab(PREFAB_ID.WidgetQuickOperationLayout, self.ScrollViewActionOperation)
        UIHelper.RemoveAllChildren(self.scriptFaceMotionLayout.WidgetQuickOperationLayout)
        local scriptBtn = UIHelper.AddPrefab(PREFAB_ID.WidgetQuickOperationBtn, self.scriptFaceMotionLayout.WidgetQuickOperationLayout)
        UIHelper.SetString(scriptBtn.LabelName, "面部表情")
        UIHelper.SetSpriteFrame(scriptBtn.ImgIcon, "UIAtlas2_Public_PublicSystemButton_PublicSystemButton_QuickBtn45.png")
        UIHelper.SetVisible(scriptBtn.WidgetContainer, false)
        UIHelper.SetVisible(scriptBtn.ImgIconAdd, false)

        UIHelper.BindUIEvent(scriptBtn.BtnQuickOperation, EventType.OnClick, function()
            self:SetBtnEditState(true)
            UIMgr.OpenSingleWithOnEnter(false, VIEW_ID.PanelQuickOperationBagTab, QuickOperation_Action_Type.FaceMotion, 1, nil , function()
                self:SetBtnEditState(false)
            end)
        end)

        UIHelper.LayoutDoLayout(self.scriptFaceMotionLayout.WidgetQuickOperationLayout)
        UIHelper.ScrollViewDoLayoutAndToTop(self.ScrollViewActionOperation)
    end
end

function UIQuickOperationView:UnRegAllRedpoint()
    if self.scriptEmotionActionTitle then
        RedpointMgr.UnRegisterRedpoint(self.scriptEmotionActionTitle.ImgRedPoint)
    end

    if self.scriptHeadEmotionTitle then
        RedpointMgr.UnRegisterRedpoint(self.scriptHeadEmotionTitle.ImgRedPoint)
    end
end

function UIQuickOperationView:GetMapType()
    local tbCommonMapType = {0, 3, 4, 5}
    local tbAthleticsMapType = {2}
    local tbSecretAreaMapType = {1}
    local player = GetClientPlayer()
	if player then
		local dwMapID = player.GetMapID()
		local _, nMapType = GetMapParams(dwMapID)
        if table.contain_value(tbCommonMapType, nMapType) then
            return MAP_TYPE.COMMON
        elseif table.contain_value(tbAthleticsMapType, nMapType) then
            return MAP_TYPE.ATHLETICS
        elseif table.contain_value(tbSecretAreaMapType, nMapType) then
            return MAP_TYPE.SECRETAREA
        end
	end
end

function UIQuickOperationView:UpdateSettingTitle()
    local nMapType = self:GetStorageCustomBtnType()
    UIHelper.SetString(self.LabelSetting, tSettingLabel[nMapType])
end

function UIQuickOperationView:UpdateModifyStateInfo(bModify)
    UIHelper.SetVisible(self.WidgetSettingTitle, bModify)
    UIHelper.SetVisible(self.LabelTitle, not bModify)
    UIHelper.SetVisible(self.BtnCloseRight, not bModify)
    UIHelper.SetVisible(self.WidgetLeftButtomAnchor, bModify)
    UIHelper.SetVisible(self.LabelSettingHint, bModify)
    UIHelper.SetVisible(self.BtnQuickSetting, not bModify)
    UIHelper.SetVisible(self.BtnModeSelect, not bModify)
    if bModify then
        for i, node in ipairs(self.tbGroupWidgetList) do
            local script = UIHelper.GetBindScript(node)
            script:BindClickEvent(function()
                local szTips = tSettingTips[i]
                TipsHelper.ShowNormalTip(string.format("已切换为%s", szTips))
                UIHelper.SetString(self.LabelSetting, tSettingLabel[i])
                UIHelper.SetSelected(self.TogSettingGroup, false)
                Event.Dispatch("ON_STARTMODIFY_OPERATIONBTN", true, i)
                Event.Dispatch(EventType.OnUpdateMainCityLeftBottom, i)
                self:SetStorageCustomBtnType(i)
                self:UpdateCustomImgBgSelectState()
            end)
        end
        --隐藏主界面左下角
        Event.Dispatch("ON_HIDEORSHOW_LEFTBTN", false)
        Event.Dispatch("ON_STARTMODIFY_OPERATIONBTN", true)
        --Event.Dispatch(EventType.OnUpdateMainCityLeftBottom, nil)
        self:UpdateSettingTitle()
        self:UpdateCustomImgBgSelectState()
    else
        --显示主界面左下角
        Event.Dispatch("ON_HIDEORSHOW_LEFTBTN", true)
        Event.Dispatch("ON_STARTMODIFY_OPERATIONBTN", false)
        --Event.Dispatch(EventType.OnUpdateMainCityLeftBottom, nil)
        UIHelper.SetSelected(self.TogSettingGroup, false)
    end
    Timer.AddFrame(self, 1, function ()
        UIHelper.LayoutDoLayout(self.LayoutBtn)
    end)
end

--教学用，根据UIQuickMenuTab表ID获取对应Btn
function UIQuickOperationView:GetBtnQuickOperationByID(nID)
    local children = UIHelper.GetChildren(self.ScrollViewQuickOperation)
    for _, child in ipairs(children) do
        local scriptChild = UIHelper.GetBindScript(child)
        for _, tInfo in ipairs(scriptChild and scriptChild.tCellScript or {}) do
            if tInfo.tCellInfo and tInfo.tCellInfo.nID == nID then
                return tInfo.tScript and tInfo.tScript.BtnQuickOperation
            end
        end
    end
end

function UIQuickOperationView:SetStorageCustomBtnType(nType)
    local nType = nType or 1
    Storage.CustomBtn.nCurType = nType
    Storage.CustomBtn.Flush()
end

function UIQuickOperationView:GetStorageCustomBtnType()
    return clone(Storage.CustomBtn.nCurType)
end

function UIQuickOperationView:UpdateCustomImgBgSelectState()
    local nMapType = self:GetStorageCustomBtnType()
    for i, node in ipairs(self.tbGroupWidgetList) do
        local script = UIHelper.GetBindScript(node)
        if script.ImgBgSelect then
            UIHelper.SetVisible(script.ImgBgSelect, nMapType == i)
        end
    end
end

-- 编辑状态设置
function UIQuickOperationView:SetBtnEditState(bOnEdit)
    self.bOnEdit = bOnEdit
    self:DrawPendantDelete(bOnEdit)
    self:DrawEmotionActionDelete(bOnEdit)
    self:DrawHeadEmotionDelete(bOnEdit)
end

function UIQuickOperationView:DrawPendantDelete(bSet)
    for _, tbScript in pairs(self.tbPendantOtherBtnList) do
        for _, scriptBtn in pairs(tbScript) do
            UIHelper.SetVisible(scriptBtn.BtnRecall, bSet)
        end
    end

    for _, index in pairs(self.tHavePendant) do
        local scriptBtn = self.tbPendantBtnList and self.tbPendantBtnList[index]
        if scriptBtn then
            UIHelper.SetVisible(scriptBtn.BtnRecall, bSet)
        end
    end
end

return UIQuickOperationView