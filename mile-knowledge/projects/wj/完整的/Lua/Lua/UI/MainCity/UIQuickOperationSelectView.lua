-- ---------------------------------------------------------------------------------
-- Author: Unknown
-- Name: UIQuickOperationSelectView
-- Date: 2023-03-30 19:58:45
-- Desc: PanelQuickOperationBagTab
-- ---------------------------------------------------------------------------------

local UIQuickOperationSelectView = class("UIQuickOperationSelectView")

function UIQuickOperationSelectView:OnEnter(nQuickOperationType, nSelectePart, tbPendantTypeToSpriteName, func)
    self.nTypeAction = nQuickOperationType
    self.nSelectePart = nSelectePart or 1
    self.tbPendantTypeToSpriteName = tbPendantTypeToSpriteName
    self.funcCallBack = func
    if not self.bInit then
        self:RegEvent()
        self:BindUIEvent()
        self.bInit = true
    end

    self:UpdateInfo()
    if self.nTypeAction == QuickOperation_Action_Type.HeadEmotion then
        HeadEmotionData.UpdateHeadEmotionCollectData()
    end
end

function UIQuickOperationSelectView:OnExit()
    self.bInit = false
    if self.funcCallBack then
        self.funcCallBack()
    end
    self:UnRegEvent()
end

function UIQuickOperationSelectView:BindUIEvent()
    for k, tog in ipairs(self.tbToggleList) do
        UIHelper.BindUIEvent(tog, EventType.OnSelectChanged, function(btn, bSelected)
            if bSelected then
                self:UpdateCellList(k)
                self.nSelectePart = k
            end
        end)
    end
end

function UIQuickOperationSelectView:RegEvent()
    --Event.Reg(self, EventType.XXX, func)
    Event.Reg(self, "SKILL_UPDATE", function(arg0, arg1)
        if self.nGroupID then
            self:UpdateQuickInfo()
        else
            self:UpdateActionInfo()
        end
    end)
    Event.Reg(self,"SET_MOBILE_EMOTION_ACTION_DIY_INFO_NOTIFY",function (bAdd, dwID)
        self:UpdateEmotionActionDeleteBtn(bAdd, dwID)
        self.bEmotionActionRecallClick = true
        self:UpdateEmotionActionDetails(EmotionData.GetEmotionAction(dwID), true)
    end)

    Event.Reg(self,"SET_MOBILE_HEAD_EMOTION_DIY_INFO_NOTIFY",function (bAdd, dwID)
        self:UpdateHeadEmotionDeleteBtn(bAdd, dwID)
        self.bHeadEmotionRecallClick = true
        self:UpdateHeadEmotionDetails(HeadEmotionData.GetHeadEmotion(dwID), true)
    end)

    Event.Reg(self, "ON_SELECT_PENDANT", function()
        self:UpdatePandentDetails()
    end)

    Event.Reg(self, "REMOTE_PREFER_HEADEMOTION_EVENT", function()
        HeadEmotionData.UpdateHeadEmotionCollectData()
        if self.scriptItemTip then
            UIHelper.RemoveFromParent(self.scriptItemTip._rootNode, true)
            self.scriptItemTip = nil
        end
        if self.nTypeAction == QuickOperation_Action_Type.HeadEmotion and self.nSelectePart == 2 then
            self:UpdateHeadEmotionCellList(2)
        end
    end)

    Event.Reg(self, "ON_EQUIP_PENDENT_PET_NOTIFY", function()
        self:UpdatePandentDetails()
    end)

end

function UIQuickOperationSelectView:UnRegEvent()
    --Event.UnReg(self, EventType.XXX)
end






-- ----------------------------------------------------------
-- Please write your own code below  ↓↓↓
-- ----------------------------------------------------------
function UIQuickOperationSelectView:UpdateInfo()
    if self.nTypeAction == QuickOperation_Action_Type.PendantAction then
        self:UpdatePendantInfo()
    elseif self.nTypeAction == QuickOperation_Action_Type.EmotionAction then
        self:UpdateEmotionActionInfo()
    elseif self.nTypeAction == QuickOperation_Action_Type.HeadEmotion then
        self:UpdateHeadEmotionInfo()
    elseif self.nTypeAction == QuickOperation_Action_Type.FaceMotion then
        self:UpdateFaceMotionInfo()
    end
end

function UIQuickOperationSelectView:UpdatePendantInfo()
    UIHelper.SetString(self.LabelTitle, "挂件")

    for k, v in ipairs(self.tbToggleList) do
        UIHelper.SetVisible(UIHelper.GetParent(v), false)
    end


    local tPendantList = CharacterPendantData.GetPendantTypeList()
    for k, v in ipairs(tPendantList) do
        local szSpriteName = self.tbPendantTypeToSpriteName[v.szType]
        if szSpriteName then
            local tog = self.tbToggleList[k]
            local imgIconNormal = tog:getChildByName("LayoutNormal/ImgIconNormal")
            local labelNormal = tog:getChildByName("LayoutNormal/LabelNormal")
            local imgIconSelect = tog:getChildByName("WidgetSelect/LayoutSelect/ImgIconSelect")
            local labelSelect = tog:getChildByName("WidgetSelect/LayoutSelect/LabelSelect")

            UIHelper.SetSpriteFrame(imgIconNormal, szSpriteName)
            UIHelper.SetSpriteFrame(imgIconSelect, szSpriteName)
            UIHelper.SetVisible(imgIconNormal, true)
            UIHelper.SetVisible(imgIconSelect, true)
            UIHelper.SetString(labelNormal, v.szName)
            UIHelper.SetString(labelSelect, v.szName)

            local layoutNormal = tog:getChildByName("LayoutNormal")
            local layoutSelect = tog:getChildByName("WidgetSelect/LayoutSelect")
            UIHelper.LayoutDoLayout(layoutNormal)
            UIHelper.LayoutDoLayout(layoutSelect)

            UIHelper.SetSelected(tog, self.nSelectePart == k)
            UIHelper.SetVisible(UIHelper.GetParent(tog), true)
            UIHelper.SetVisible(tog, true)
        end
    end

    UIHelper.ScrollViewDoLayout(self.ScrollViewTog)
    UIHelper.CascadeDoLayoutDoWidget(self.ScrollViewTog)
    if self.nSelectePart < 8 then
        UIHelper.ScrollToTop(self.ScrollViewTog, 0)
    else
        UIHelper.ScrollToBottom(self.ScrollViewTog, 0)
    end
end

function UIQuickOperationSelectView:UpdateCellList(k)
    if self.nTypeAction == QuickOperation_Action_Type.PendantAction then
        self:UpdatePendantCellList(k)
    elseif self.nTypeAction == QuickOperation_Action_Type.EmotionAction then
        self:UpdateEmotionActionCellList(k)
    elseif self.nTypeAction == QuickOperation_Action_Type.HeadEmotion then
        self:UpdateHeadEmotionCellList(k)
    elseif self.nTypeAction == QuickOperation_Action_Type.FaceMotion then
        self:UpdateFaceMotionCellList(k)
    end
end

function UIQuickOperationSelectView:UpdatePendantCellList(k)
    if self.nTimeID then
        Timer.DelTimer(self , self.nTimeID)
    end

    UIHelper.RemoveAllChildren(self.ScrollViewCell:getInnerContainer())
    if self.scriptPandentItemTip then
        UIHelper.SetVisible(self.scriptPandentItemTip._rootNode , false)
        self.scriptPandentItemTip = nil
    end
    if self.scriptItemTip then
        UIHelper.RemoveFromParent(self.scriptItemTip._rootNode, true)
        self.scriptItemTip = nil
    end
    local tPendentInfo, dwUsingPendantID, dwPendantListSize, tColorID = CharacterPendantData.GetPendentInfo(k)
    local nCount = 0
    self.tbPandentItems = {}
    if tPendentInfo then
        for key, v in ipairs(tPendentInfo) do
            local tColor
            if v.nColorID1 and v.nColorID2 and v.nColorID3 then
                tColor = {{nColorID1 = v.nColorID1, nColorID2 = v.nColorID2, nColorID3 = v.nColorID3}}
            end
            local tItemInfo = v.dwItemIndex > 0 and GetItemInfo(ITEM_TABLE_TYPE.CUST_TRINKET, v.dwItemIndex) or nil
            local bHasPendantSkill = tItemInfo and tItemInfo.dwSkillID and tItemInfo.dwSkillID > 0
            if not bHasPendantSkill then
                bHasPendantSkill = tItemInfo.nRepresentID > 0
            end
            if bHasPendantSkill  then
                local bIsUsing = dwUsingPendantID == v.dwItemIndex
                local scriptItem = UIHelper.AddPrefab(PREFAB_ID.WidgetAccessoryListItem, self.ScrollViewCell)
                scriptItem:OnEnter()
                UIHelper.SetVisible(scriptItem.MaskLight1, bIsUsing)
                UIHelper.SetString(scriptItem.LabelName, GBKToUTF8(ItemData.GetItemNameByItemInfo(tItemInfo)), 4)
                scriptItem:OnInitWithTabID(ITEM_TABLE_TYPE.CUST_TRINKET, v.dwItemIndex)
                scriptItem.dwItemIndex = v.dwItemIndex
                scriptItem:SetClickCallback(function()
                    self.tbSelectColor = tColor
                    self.PandentItemIndex = v.dwItemIndex
                    self:UpdatePandentDetails()
                end)

                UIHelper.ToggleGroupAddToggle(self.ToggleGroup , scriptItem.scriptItemIcon.ToggleSelect)
                UIHelper.SetVisible(scriptItem.scriptItemIcon.BtnRecall, bIsUsing)

                if bIsUsing then
                    UIHelper.SetSwallowTouches(scriptItem.scriptItemIcon.BtnRecall, true)
                end
                UIHelper.BindUIEvent(scriptItem.scriptItemIcon.BtnRecall,EventType.OnClick,function ()
                    CharacterPendantData.EquipPendant(v, self.nSelectePart, false)
                    UIHelper.SetSwallowTouches(scriptItem.scriptItemIcon.BtnRecall, true)
                    self:UpdatePandentDetails()
                end)
                nCount = nCount + 1
                table.insert(self.tbPandentItems, scriptItem)
            end
        end
    end

    UIHelper.ScrollViewDoLayoutAndToTop(self.ScrollViewCell)
    UIHelper.SetVisible(self.WidgetEmpty, nCount <= 0)
end

function UIQuickOperationSelectView:IsExteriorPart(aRes ,nIndex,dwID)
    local bHasPart = false
    bHasPart = CharacterPendantData.IsPetInPendentPartInfo(nIndex)
    if not bHasPart then
        bHasPart = CharacterPendantData.IsLHandInPendentPartInfo(nIndex)
    end
    if not bHasPart then
        bHasPart = CharacterPendantData.IsRHandInPendentPartInfo(nIndex)
    end
    if not bHasPart then
        bHasPart = CharacterPendantData.IsGlassesInPendentPartInfo(nIndex)
    end
    return bHasPart
end

-- 表情动作

function UIQuickOperationSelectView:RegActionTable()
    if not IsUITableRegister("EmotionActionTitle") then
        local path = "\\UI\\Scheme\\Case\\EmotionActionTitle.txt"
        local tTitle = {
            {f = "i", t = "typeid"},
            {f = "s", t = "name"}
        }
        RegisterUITable("EmotionActionTitle", path, tTitle)
    end
end

function UIQuickOperationSelectView:GetEmotionActionTitle()
    self:RegActionTable()
    local tab = g_tTable.EmotionActionTitle
    local count = tab:GetRowCount()

    local tRes, tLine = {}
    for i = 1, count, 1 do
        tLine = tab:GetRow(i)
        tRes[tLine.typeid] = tLine
    end

    return tRes
end

function UIQuickOperationSelectView:UpdateEmotionActionInfo()
    UIHelper.SetString(self.LabelTitle, "表情动作")

    UIHelper.SetTabVisible(self.tbToggleList, false)

    local tActionTitle = self:GetEmotionActionTitle()
    for i, ActionTitle in pairs(tActionTitle) do
        local tog = self.tbToggleList[i]
        local labelNormal = tog:getChildByName("LayoutNormal/LabelNormal")
        local labelSelect = tog:getChildByName("WidgetSelect/LayoutSelect/LabelSelect")
        local imgIconNormal = tog:getChildByName("LayoutNormal/ImgIconNormal")
        local imgIconSelect = tog:getChildByName("WidgetSelect/LayoutSelect/ImgIconSelect")
        UIHelper.SetVisible(imgIconNormal, false)
        UIHelper.SetVisible(imgIconSelect, false)
        local layoutNormal = tog:getChildByName("LayoutNormal")
        local layoutSelect = tog:getChildByName("WidgetSelect/LayoutSelect")
        UIHelper.LayoutDoLayout(layoutNormal)
        UIHelper.LayoutDoLayout(layoutSelect)
        local ImgRedPoint = tog:getChildByName("ImgRedPoint")
        UIHelper.SetString(labelNormal, UIHelper.GBKToUTF8(ActionTitle.name))
        UIHelper.SetString(labelSelect, UIHelper.GBKToUTF8(ActionTitle.name))
        UIHelper.SetVisible(ImgRedPoint, RedpointHelper.Emotion_HasNewByType(i))
        UIHelper.SetSelected(tog, self.nSelectePart == i)
        UIHelper.SetVisible(UIHelper.GetParent(tog), true)
        UIHelper.SetVisible(tog, true)
    end

    for i = #tActionTitle + 1, #self.tbToggleList, 1 do
        local tog = self.tbToggleList[i]
        UIHelper.SetVisible(UIHelper.GetParent(tog), false)
    end

    UIHelper.ScrollViewDoLayout(self.ScrollViewTog)
    UIHelper.CascadeDoLayoutDoWidget(self.ScrollViewTog)
    UIHelper.ScrollToTop(self.ScrollViewTog, 0)
end

function UIQuickOperationSelectView:UpdateEmotionActionCellList(k, tChooseEmotion)
    if self.nTimeID then
        Timer.DelTimer(self , self.nTimeID)
    end

    UIHelper.RemoveAllChildren(self.ScrollViewCell)
    self.preEmotionActionBtn = nil
    self.tEmotionActionBtns = {}
    local tEmotionActions = EmotionData.GetEmotionActionPackage(k)
    local loadIndex = 0
    local loadCount = #tEmotionActions
    local hPlayer = GetClientPlayer()

    if self.scriptItemTip then
        UIHelper.RemoveFromParent(self.scriptItemTip._rootNode, true)
        self.scriptItemTip = nil
    end
    if self.scriptPandentItemTip then
        UIHelper.SetVisible(self.scriptPandentItemTip._rootNode , false)
        self.scriptPandentItemTip = nil
    end

    if loadCount > 0 then
        UIHelper.SetVisible(self.WidgetEmpty, false)
    else
        UIHelper.SetVisible(self.WidgetEmpty, true)
        return
    end

    self.nTimeID = Timer.AddFrameCycle(self , 1 , function ()
        for i = 1,2, 1 do
            loadIndex = loadIndex + 1
            local actionData = tEmotionActions[loadIndex]
            local scriptBtn = UIHelper.AddPrefab(PREFAB_ID.WidgetQuickOperationBtn, self.ScrollViewCell) assert(scriptBtn)
            self.tEmotionActionBtns[actionData.dwID] = scriptBtn
            UIHelper.SetVisible(scriptBtn.ImgIcon, false)
            UIHelper.RemoveAllChildren(scriptBtn.WidgetContainer)
            local szName = actionData.szName
            local nCharCount,szUtfName = GetStringCharCountAndTopChars(UIHelper.GBKToUTF8(szName),4)
            UIHelper.SetString(scriptBtn.LabelName,nCharCount > 4 and szUtfName.."..." or szUtfName)

            if actionData.bInteract then
                UIHelper.SetVisible(scriptBtn.ImgDoubleMark, true)
                UIHelper.SetSpriteFrame(scriptBtn.ImgDoubleMark, "UIAtlas2_Public_PublicIcon_PublicIcon1_OperationIcon1")
            elseif actionData.bAniEdit then
                UIHelper.SetVisible(scriptBtn.ImgDoubleMark, true)
                UIHelper.SetSpriteFrame(scriptBtn.ImgDoubleMark, "UIAtlas2_Public_PublicIcon_PublicIcon1_OperationIcon2")
            elseif actionData.nAniType ~= 0 and EMOTION_ACTION_ANI_TYPE[actionData.nAniType] then
                UIHelper.SetVisible(scriptBtn.ImgDoubleMark, true)
                local path = "UIAtlas2_Public_PublicIcon_PublicIcon1_OperationIcon" .. EMOTION_ACTION_ANI_TYPE[actionData.nAniType]
                UIHelper.SetSpriteFrame(scriptBtn.ImgDoubleMark, path)
            else
                UIHelper.SetVisible(scriptBtn.ImgDoubleMark, false)
            end

            UIHelper.SetVisible(scriptBtn.ImgIcon, false)
            local itemScript = UIHelper.AddPrefab(PREFAB_ID.WidgetItem_100, scriptBtn.WidgetContainer) assert(itemScript)
            itemScript:OnInitWithIconID(actionData.nIconID)
            UIHelper.SetScale(itemScript._rootNode, 0.6, 0.6)
            -- UIHelper.SetVisible(itemScript.ToggleSelect, false)
            itemScript:SetSelectEnable(false)
            UIHelper.BindUIEvent(scriptBtn.BtnQuickOperation,EventType.OnClick,function ()
                UIHelper.SetVisible(scriptBtn.WidgetNewItem, false)
                self:UpdateEmotionActionChoosenType(scriptBtn)
                self:UpdateEmotionActionDetails(actionData)
            end)

            local bFavi = EmotionData.IsFaviEmotionAction(actionData.dwID)
            local bIsNew = RedpointHelper.Emotion_IsNew(actionData.dwID)
            if bFavi and not bIsNew then
                UIHelper.SetSwallowTouches(scriptBtn.BtnRecall, true)
                UIHelper.SetVisible(scriptBtn.BtnRecall, true)
                UIHelper.BindUIEvent(scriptBtn.BtnRecall,EventType.OnClick,function ()
                    self.bEmotionActionRecallClick = true
                    self:UpdateEmotionActionChoosenType(scriptBtn)
                    hPlayer.SetMobileEmotionActionDIYInfo(false, actionData.dwID)
                end)
            end

            UIHelper.SetNodeGray(scriptBtn._rootNode, not actionData.bLearned, true)

            --if tChooseEmotion and actionData.dwID == tChooseEmotion then
                --self:UpdateEmotionActionChoosenType(scriptBtn)
                --self:UpdateEmotionActionDetails(actionData)
            --end

            -- 新
            if bIsNew then
                -- itemScript:SetNewItemFlag(true)
                UIHelper.SetVisible(scriptBtn.WidgetNewItem, true)
                RedpointHelper.Emotion_SetNew(actionData.dwID, false)
            end

            if loadIndex == loadCount then
                Timer.DelTimer(self, self.nTimeID)
                RedpointHelper.Emotion_ClearByType(k)
                UIHelper.SetVisible(self.tbToggleList[k]:getChildByName("ImgRedPoint"), false)
                break
            end
        end
        UIHelper.ScrollViewDoLayoutAndToTop(self.ScrollViewCell)
    end)
end

function UIQuickOperationSelectView:UpdateEmotionActionChoosenType(nowBtn)
    if self.preEmotionActionBtn then
        UIHelper.SetVisible(self.preEmotionActionBtn.ImgSelect , false)
    end
    UIHelper.SetVisible(nowBtn.ImgSelect , true)
    self.preEmotionActionBtn = nowBtn
end

function UIQuickOperationSelectView:UpdateEmotionActionDetails(tEmotionAction, bUpdate)
    if self.bEmotionActionRecallClick then
        self.bEmotionActionRecallClick = nil
        if self.scriptItemTip then
            UIHelper.RemoveFromParent(self.scriptItemTip._rootNode, true)
            self.scriptItemTip = nil
        end
    else
        if not self.scriptItemTip then
            self.scriptItemTip = UIHelper.AddPrefab(PREFAB_ID.WidgetItemTip, self.WidgetAniLeft)
            local nPosition = UIHelper.GetPositionX(self.scriptItemTip._rootNode)
            UIHelper.SetPositionX(self.scriptItemTip._rootNode, nPosition + 40)
        end
        self.scriptItemTip:OnInitEmotionActionTip(tEmotionAction, bUpdate)
    end
end

function UIQuickOperationSelectView:UpdateEmotionActionDeleteBtn(bAdd, dwID)
    local scriptBtn = self.tEmotionActionBtns[dwID]
    UIHelper.SetVisible(scriptBtn.BtnRecall, bAdd == 1)
    if bAdd == 1 then
        UIHelper.SetSwallowTouches(scriptBtn.BtnRecall, true)
        UIHelper.BindUIEvent(scriptBtn.BtnRecall,EventType.OnClick,function ()
            self.bEmotionActionRecallClick = true
            self:UpdateEmotionActionChoosenType(scriptBtn)
            GetClientPlayer().SetMobileEmotionActionDIYInfo(false, dwID)
        end)
    end
end

-- 头顶表情

function UIQuickOperationSelectView:RegHeadEmotionTable()
    if not IsUITableRegister("HeadEmotionTitle") then
        local path = "\\UI\\Scheme\\Case\\BrightMarkTitle.txt"
        local tTitle = {
            {f = "i", t = "nPageID"},
            {f = "s", t = "szName"},
            {f = "b", t = "bShow"}
        }
        RegisterUITable("HeadEmotionTitle", path, tTitle)
    end
end

function UIQuickOperationSelectView:GetHeadEmotionTitle()
    -- self:RegHeadEmotionTable()
    -- local tab = g_tTable.HeadEmotionTitle
    -- local count = tab:GetRowCount()

    -- local tRes, tLine = {}
    -- for i = 1, count, 1 do
    --     tLine = tab:GetRow(i)
    --     tRes[tLine.nPageID] = tLine
    -- end
    local tRes = {}
    table.insert(tRes, {szName = UIHelper.UTF8ToGBK("全部")})
    table.insert(tRes, {szName = UIHelper.UTF8ToGBK("收藏")})

    return tRes
end

function UIQuickOperationSelectView:UpdateHeadEmotionInfo()
    UIHelper.SetString(self.LabelTitle, "头顶表情")

    UIHelper.SetTabVisible(self.tbToggleList, false)

    local tHeadEmotionTitle = self:GetHeadEmotionTitle()
    --local tTypeIsBlank = HeadEmotionData.GetTypeIsHave()
    --local nBlank = 0
    for i, HeadEmotionTitle in pairs(tHeadEmotionTitle) do
        --if tTypeIsBlank[i] == false then
            --local tog = self.tbToggleList[i - nBlank]
            local tog = self.tbToggleList[i]
            local labelNormal = tog:getChildByName("LayoutNormal/LabelNormal")
            local labelSelect = tog:getChildByName("WidgetSelect/LayoutSelect/LabelSelect")
            local ImgRedPoint = tog:getChildByName("ImgRedPoint")
            local imgIconNormal = tog:getChildByName("LayoutNormal/ImgIconNormal")
            local imgIconSelect = tog:getChildByName("WidgetSelect/LayoutSelect/ImgIconSelect")
            UIHelper.SetVisible(imgIconNormal, false)
            UIHelper.SetVisible(imgIconSelect, false)
            local layoutNormal = tog:getChildByName("LayoutNormal")
            local layoutSelect = tog:getChildByName("WidgetSelect/LayoutSelect")
            UIHelper.LayoutDoLayout(layoutNormal)
            UIHelper.LayoutDoLayout(layoutSelect)
            UIHelper.SetString(labelNormal, UIHelper.GBKToUTF8(HeadEmotionTitle.szName))
            UIHelper.SetString(labelSelect, UIHelper.GBKToUTF8(HeadEmotionTitle.szName))
            UIHelper.SetVisible(ImgRedPoint, RedpointHelper.BrightMark_HasNewByType(i))
            UIHelper.SetSelected(tog, self.nSelectePart == i)
            UIHelper.SetVisible(UIHelper.GetParent(tog), true)
            UIHelper.SetVisible(tog, true)
        --else
            --nBlank = nBlank + 1
        --end
    end

    --for i = #tHeadEmotionTitle + 1 - nBlank, #self.tbToggleList, 1 do
    for i = #tHeadEmotionTitle + 1, #self.tbToggleList, 1 do
        local tog = self.tbToggleList[i]
        UIHelper.SetVisible(UIHelper.GetParent(tog), false)
    end

    UIHelper.ScrollViewDoLayout(self.ScrollViewTog)
    UIHelper.CascadeDoLayoutDoWidget(self.ScrollViewTog)
    UIHelper.ScrollToTop(self.ScrollViewTog, 0)
end

function UIQuickOperationSelectView:UpdateHeadEmotionCellList(k, tChooseEmotion)
    if self.nTimeID then
        Timer.DelTimer(self , self.nTimeID)
    end

    UIHelper.RemoveAllChildren(self.ScrollViewCell)
    self.preHeadEmotionBtn = nil
    self.tHeadEmotionBtns = {}
    local tHeadEmotions = {}
    if k == 2 then
        local tLikeID = HeadEmotionData.UpdateHeadEmotionCollectData()
        for dwID, _ in pairs(tLikeID) do
            local tInfo = HeadEmotionData.GetHeadEmotion(dwID)
            table.insert(tHeadEmotions, tInfo)
        end
    else
        tHeadEmotions = HeadEmotionData.GetHeadEmotionPackage(k)
    end
    local loadIndex = 0
    local loadCount = #tHeadEmotions

    if self.scriptItemTip then
        UIHelper.RemoveFromParent(self.scriptItemTip._rootNode, true)
        self.scriptItemTip = nil
    end
    if self.scriptPandentItemTip then
        UIHelper.SetVisible(self.scriptPandentItemTip._rootNode , false)
        self.scriptPandentItemTip = nil
    end

    if loadCount > 0 then
        UIHelper.SetVisible(self.WidgetEmpty, false)
    else
        UIHelper.SetVisible(self.WidgetEmpty, true)
        return
    end

    local tTypeIsBlank = HeadEmotionData.GetTypeIsHave()
    if tTypeIsBlank[k] == true then
        UIHelper.SetVisible(self.WidgetEmpty, true)
        return
    end

    self.nTimeID = Timer.AddFrameCycle(self , 1 , function ()
        for i = 1,2, 1 do
            loadIndex = loadIndex + 1
            local headEmotion = tHeadEmotions[loadIndex]
            local scriptBtn = UIHelper.AddPrefab(PREFAB_ID.WidgetQuickOperationBtn, self.ScrollViewCell) assert(scriptBtn)
            self.tHeadEmotionBtns[headEmotion.dwID] = scriptBtn
            UIHelper.SetVisible(scriptBtn.ImgIcon, false)
            UIHelper.RemoveAllChildren(scriptBtn.WidgetContainer)
            local szName = headEmotion.szName
            local nCharCount,szUtfName = GetStringCharCountAndTopChars(UIHelper.GBKToUTF8(szName),4)
			--UIHelper.SetString(scriptBtn.LabelName,nCharCount > 4 and szUtfName.."..." or szUtfName)
            UIHelper.SetString(scriptBtn.LabelName, szUtfName)

            local itemScript = UIHelper.AddPrefab(PREFAB_ID.WidgetItem_100, scriptBtn.WidgetContainer) assert(itemScript)
            itemScript:OnInitWithIconID(headEmotion.nIconID)
            UIHelper.SetScale(itemScript._rootNode, 0.6, 0.6)
            -- UIHelper.SetVisible(itemScript.ToggleSelect, false)
            itemScript:SetSelectEnable(false)
            UIHelper.BindUIEvent(scriptBtn.BtnQuickOperation,EventType.OnClick,function ()
                UIHelper.SetVisible(scriptBtn.WidgetNewItem, false)
                self:UpdateHeadEmotionChoosenType(scriptBtn)
                self:UpdateHeadEmotionDetails(headEmotion)
            end)

            local bFavi = HeadEmotionData.IsFaviHeadEmotion(headEmotion.dwID)
            local bIsNew = RedpointHelper.BrightMark_IsNew(headEmotion.dwID)
            if bFavi and not bIsNew then
                UIHelper.SetVisible(scriptBtn.BtnRecall, true)
                UIHelper.SetSwallowTouches(scriptBtn.BtnRecall, true)
                UIHelper.BindUIEvent(scriptBtn.BtnRecall,EventType.OnClick,function ()
                    self.bHeadEmotionRecallClick = true
                    self:UpdateHeadEmotionChoosenType(scriptBtn)
                    GetClientPlayer().SetMobileHeadEmotionDIYInfo(false, headEmotion.dwID)
                end)
            end

            --if tChooseEmotion and headEmotion.dwID == tChooseEmotion then
                --self:UpdateHeadEmotionChoosenType(scriptBtn)
                --self:UpdateHeadEmotionDetails(headEmotion)
            --end

            -- 新
            if bIsNew then
                -- itemScript:SetNewItemFlag(true)
                UIHelper.SetVisible(scriptBtn.WidgetNewItem, true)
                RedpointHelper.BrightMark_SetNew(headEmotion.dwID, false)
            end

            local bLearned = g_pClientPlayer.IsHaveBrightMark(headEmotion.dwID)
            UIHelper.SetNodeGray(scriptBtn._rootNode, not bLearned, true)

            if loadIndex == loadCount then
                Timer.DelTimer(self , self.nTimeID)
                RedpointHelper.BrightMark_ClearByType(k)
                UIHelper.SetVisible(self.tbToggleList[k]:getChildByName("ImgRedPoint"), false)
                break
            end
        end
        UIHelper.ScrollViewDoLayoutAndToTop(self.ScrollViewCell)
    end)
end

function UIQuickOperationSelectView:UpdateHeadEmotionChoosenType(nowBtn)
    if self.preHeadEmotionBtn then
        UIHelper.SetVisible(self.preHeadEmotionBtn.ImgSelect , false)
    end
    UIHelper.SetVisible(nowBtn.ImgSelect , true)
    self.preHeadEmotionBtn = nowBtn
end

function UIQuickOperationSelectView:UpdateHeadEmotionDetails(tHeadEmotion, bUpdate)
    if self.bHeadEmotionRecallClick then
        self.bHeadEmotionRecallClick = nil
        if self.scriptItemTip then
            UIHelper.RemoveFromParent(self.scriptItemTip._rootNode, true)
            self.scriptItemTip = nil
        end
    else
        if not self.scriptItemTip then
            self.scriptItemTip = UIHelper.AddPrefab(PREFAB_ID.WidgetItemTip, self.WidgetAniLeft)
            local nPosition =UIHelper.GetPositionX(self.scriptItemTip._rootNode)
            UIHelper.SetPositionX(self.scriptItemTip._rootNode, nPosition + 40)
        end
        self.scriptItemTip:OnInitHeadEmotionTip(tHeadEmotion, bUpdate)
    end
end

function UIQuickOperationSelectView:UpdateHeadEmotionDeleteBtn(bAdd, dwID)
    local scriptBtn = self.tHeadEmotionBtns[dwID]
    UIHelper.SetVisible(scriptBtn.BtnRecall, bAdd == 1)
    if bAdd == 1 then
        UIHelper.SetSwallowTouches(scriptBtn.BtnRecall, true)
        UIHelper.BindUIEvent(scriptBtn.BtnRecall,EventType.OnClick,function ()
            self.bHeadEmotionRecallClick = true
            self:UpdateHeadEmotionChoosenType(scriptBtn)
            GetClientPlayer().SetMobileHeadEmotionDIYInfo(false, dwID)
        end)
    end
end

function UIQuickOperationSelectView:UpdatePandentDetails()
    if not self.scriptPandentItemTip then
        self.scriptPandentItemTip = UIHelper.AddPrefab(PREFAB_ID.WidgetItemTip, self.WidgetAniLeft)
        local nPosition =UIHelper.GetPositionX(self.scriptPandentItemTip._rootNode)
        UIHelper.SetPositionX(self.scriptPandentItemTip._rootNode, nPosition + 40)
    end
    self.scriptPandentItemTip:OnInitPandentActionTip(self.PandentItemIndex , self.nSelectePart, self.tbSelectColor)
    local _, dwUsingPendantID = CharacterPendantData.GetPendentInfo(self.nSelectePart)
    for k, v in pairs(self.tbPandentItems) do
        UIHelper.SetVisible(v.scriptItemIcon.BtnRecall, v.dwItemIndex == dwUsingPendantID)
    end
end

-- 面部表情
function UIQuickOperationSelectView:GetFaceMotionTitle()
    local tRes = {}
    table.insert(tRes, {szName = UIHelper.UTF8ToGBK("全部")})

    return tRes
end

function UIQuickOperationSelectView:UpdateFaceMotionInfo()
    UIHelper.SetString(self.LabelTitle, "面部表情")

    UIHelper.SetTabVisible(self.tbToggleList, false)

    local tFaceMotionTitle = self:GetFaceMotionTitle()
    for i, FaceMotionTitle in pairs(tFaceMotionTitle) do
        local tog = self.tbToggleList[i]
        local labelNormal = tog:getChildByName("LayoutNormal/LabelNormal")
        local labelSelect = tog:getChildByName("WidgetSelect/LayoutSelect/LabelSelect")
        local ImgRedPoint = tog:getChildByName("ImgRedPoint")
        local imgIconNormal = tog:getChildByName("LayoutNormal/ImgIconNormal")
        local imgIconSelect = tog:getChildByName("WidgetSelect/LayoutSelect/ImgIconSelect")
        UIHelper.SetVisible(imgIconNormal, false)
        UIHelper.SetVisible(imgIconSelect, false)
        local layoutNormal = tog:getChildByName("LayoutNormal")
        local layoutSelect = tog:getChildByName("WidgetSelect/LayoutSelect")
        UIHelper.LayoutDoLayout(layoutNormal)
        UIHelper.LayoutDoLayout(layoutSelect)
        UIHelper.SetString(labelNormal, UIHelper.GBKToUTF8(FaceMotionTitle.szName))
        UIHelper.SetString(labelSelect, UIHelper.GBKToUTF8(FaceMotionTitle.szName))
        UIHelper.SetVisible(ImgRedPoint, false)
        UIHelper.SetSelected(tog, self.nSelectePart == i)
        UIHelper.SetVisible(UIHelper.GetParent(tog), true)
        UIHelper.SetVisible(tog, true)
    end

     for i = #tFaceMotionTitle + 1, #self.tbToggleList, 1 do
        local tog = self.tbToggleList[i]
        UIHelper.SetVisible(UIHelper.GetParent(tog), false)
    end

    UIHelper.ScrollViewDoLayout(self.ScrollViewTog)
    UIHelper.CascadeDoLayoutDoWidget(self.ScrollViewTog)
    UIHelper.ScrollToTop(self.ScrollViewTog, 0)
end

function UIQuickOperationSelectView:UpdateFaceMotionCellList(k, tChooseEmotion)
    if self.nTimeID then
        Timer.DelTimer(self , self.nTimeID)
    end

    UIHelper.RemoveAllChildren(self.ScrollViewCell)
    self.tFaceMotionBtns = {}
    UIHelper.SetVisible(self.WidgetEmpty, false)

    local tFaceMotions = EmotionData.GetFaceMotions()
    local loadIndex = 0
    local loadCount = #tFaceMotions

    if self.scriptItemTip then
        UIHelper.RemoveFromParent(self.scriptItemTip._rootNode, true)
        self.scriptItemTip = nil
    end
    if self.scriptPandentItemTip then
        UIHelper.SetVisible(self.scriptPandentItemTip._rootNode , false)
        self.scriptPandentItemTip = nil
    end

    if loadCount > 0 then
        UIHelper.SetVisible(self.WidgetEmpty, false)
    else
        UIHelper.SetVisible(self.WidgetEmpty, true)
        return
    end

    self.nTimeID = Timer.AddFrameCycle(self, 1, function ()
        for i = 1,2, 1 do
            loadIndex = loadIndex + 1
            local dwID = tFaceMotions[loadIndex]
            local tFaceMotion = EmotionData.GetFaceMotion(dwID)
            if tFaceMotion then
                local scriptBtn = UIHelper.AddPrefab(PREFAB_ID.WidgetQuickOperationBtn, self.ScrollViewCell) assert(scriptBtn)
                self.tFaceMotionBtns[dwID] = scriptBtn

                UIHelper.SetString(scriptBtn.LabelName, UIHelper.GBKToUTF8(tFaceMotion.szName) , 4)
                UIHelper.SetItemIconByIconID(scriptBtn.ImgIcon, tFaceMotion.nIconID)

                UIHelper.BindUIEvent(scriptBtn.BtnQuickOperation , EventType.OnClick , function ()
                    EmotionData.ProcessFaceMotion(dwID)
                end)
            end

            if loadIndex == loadCount then
                Timer.DelTimer(self, self.nTimeID)
                break
            end
        end
        UIHelper.ScrollViewDoLayoutAndToTop(self.ScrollViewCell)
    end)
end

return UIQuickOperationSelectView