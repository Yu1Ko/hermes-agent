-- ---------------------------------------------------------------------------------
-- Author: zeng zi peng
-- Name: UISelfieEmotionAction
-- Date: 2023-05-11 14:31:37
-- Desc: 幻境云图 -- 表情动作
-- ---------------------------------------------------------------------------------

local UISelfieEmotionAction = class("UISelfieEmotionAction")

local nFaceMotionIndex = 0
local nBackdropIndex = 0
local nPendantIndex = 0
local nPetIndex = 0
local nHorseIndex = 0
local nPostureIndex = 0
local nExteriorIndex = 0
local nCustomIndex = 0
local tbPendantTypeToSpriteName =
{
    ["Face"] = "UIAtlas2_Public_PublicSystemButton_PublicSystemButton_mianbuBtn.png",
    ["Glasses"] = "UIAtlas2_Public_PublicSystemButton_PublicSystemButton_peinangBtn.png",
    ["Bag"] = "UIAtlas2_Public_PublicSystemButton_PublicSystemButton_peinangBtn.png",
    ["Back"] = "UIAtlas2_Public_PublicSystemButton_PublicSystemButton_beiguaBtn.png",
    ["Waist"] = "UIAtlas2_Public_PublicSystemButton_PublicSystemButton_yaobuBtn.png",
    ["LHand"] = "UIAtlas2_Public_PublicSystemButton_PublicSystemButton_beiguaBtn.png",
    ["RHand"] = "UIAtlas2_Public_PublicSystemButton_PublicSystemButton_yaobuBtn.png",
    ["PendantPet"] = "UIAtlas2_Public_PublicSystemButton_PublicSystemButton_guachongBtn.png",
    ["BackCloak"] = "UIAtlas2_Public_PublicSystemButton_PublicSystemButton_pifengBtn.png",
    ["Head"] = "UIAtlas2_Public_PublicSystemButton_PublicSystemButton_toubuBtn.png",
}
local function RegActionTable()
    if not IsUITableRegister("EmotionActionTitle") then
        local path = "\\UI\\Scheme\\Case\\EmotionActionTitle.txt"
        local tTitle = {
            {f = "i", t = "typeid"},
            {f = "s", t = "name"}
        }
        RegisterUITable("EmotionActionTitle", path, tTitle)
    end
end



local function GetEmotionActionTitle()
    RegActionTable()
    local tab = g_tTable.EmotionActionTitle
    local count = tab:GetRowCount()

    local tRes, tLine = {}
    for i = 1, count, 1 do
        tLine = tab:GetRow(i)
        tRes[i] = tLine

        if nBackdropIndex == 0 and UIHelper.GBKToUTF8(tLine.name) == "幕景" then
            nBackdropIndex = i
        end
    end
    nPostureIndex = count + 1
    nPetIndex = nPostureIndex + 1
    nPendantIndex = nPetIndex + 1
    nExteriorIndex = nPendantIndex + 1
    nHorseIndex = nExteriorIndex + 1
    nFaceMotionIndex = nHorseIndex + 1
    nCustomIndex = nFaceMotionIndex + 1
    tRes[nPostureIndex] = {name = UIHelper.UTF8ToGBK("站姿")}
    tRes[nPetIndex] = {name = UIHelper.UTF8ToGBK("宠物")}
    tRes[nPendantIndex] = {name = UIHelper.UTF8ToGBK("挂件")}
    tRes[nExteriorIndex] = {name = UIHelper.UTF8ToGBK("外装")}
    tRes[nHorseIndex] = {name = UIHelper.UTF8ToGBK("马具")}
    tRes[nFaceMotionIndex] = {name = UIHelper.UTF8ToGBK("表情")}
    tRes[nCustomIndex] = {name = UIHelper.UTF8ToGBK("自定义")}
    return tRes
end

function UISelfieEmotionAction:OnEnter(onHideCallback)
    if not self.bInit then
        self:RegEvent()
        self:BindUIEvent()
        self.bInit = true
    end
    self.onHideCallback = onHideCallback
    self:Hide()
    self:UpdateInfo()
end

function UISelfieEmotionAction:OnExit()
    self.bInit = false
    self:UnRegEvent()
end

function UISelfieEmotionAction:BindUIEvent()
    UIHelper.BindUIEvent(self.BtnClose , EventType.OnClick , function ()
        self:Hide()
    end)

    UIHelper.BindUIEvent(self.BtnEdit , EventType.OnClick , function ()
        self.bEditorModel = true
        UIHelper.SetVisible(self.BtnExitEdit, true)
        UIHelper.SetVisible(self.BtnEdit, false)
        if self.nCurSelectOptionType == nCustomIndex then
           for k, v in pairs(self.tCustomActionScript) do
                v:SetDeletedVisible(true)
                v:SetPlayVisible(false)
           end
        end

    end)

    UIHelper.BindUIEvent(self.BtnExitEdit , EventType.OnClick , function ()
        self.bEditorModel = false
        UIHelper.SetVisible(self.BtnExitEdit, false)
        UIHelper.SetVisible(self.BtnEdit, true)

        if self.nCurSelectOptionType == nCustomIndex then
            for k, v in pairs(self.tCustomActionScript) do
                v:SetDeletedVisible(false)
                v:SetPlayVisible(true)
           end
        end
    end)

    for i, v in ipairs(self.tbTogOption) do
        UIHelper.BindUIEvent(v , EventType.OnClick , function ()
            self:UpdateTogOptionState(i)
        end)
        UIHelper.ToggleGroupAddToggle(self.WidgetAnchorActionTog, self.tbTogOption[i])
    end
end

function UISelfieEmotionAction:RegEvent()
    --Event.Reg(self, EventType.XXX, func)
end

function UISelfieEmotionAction:UnRegEvent()
    --Event.UnReg(self, EventType.XXX)
end



function UISelfieEmotionAction:Open(nIndex)
    self.bIsOpen = true
    UIHelper.SetVisible(self._rootNode , true)
    self.nCurSelectOptionType = 0
    EmotionData.QuickLoad()

    if self.curSelectTog == nil and nIndex ~= 1 then
        UIHelper.SetSelected(self.tbTogOption[1] , false)
    end

    self:UpdateTogOptionState(nIndex or 1)
    self:UpdateCameraCaptureStateChange()
    self:UpdateTogGroupState()
end

function UISelfieEmotionAction:Hide()
    self.bIsOpen = false
    EmotionData.UnQuickLoad()
    UIHelper.SetVisible(self._rootNode , false)

    Event.Dispatch("ON_SELFIE_EMOTION_ACTION_HIDE")

    if self.onHideCallback then
        self.onHideCallback()
    end
end

function UISelfieEmotionAction:IsOpen()
    return self.bIsOpen
end


-- ----------------------------------------------------------
-- Please write your own code below  ↓↓↓
-- ----------------------------------------------------------

function UISelfieEmotionAction:UpdateInfo()
    self.nSelectActionID = -1
    local tbTitle = GetEmotionActionTitle()
    for i, v in ipairs(self.tbTogNormalName) do
        UIHelper.SetVisible(self.tbTogOption[i] , tbTitle[i] ~= nil)
        if i == nPostureIndex then
            UIHelper.SetVisible(self.tbTogOption[i] , tbTitle[i] ~= nil and (IsDebugClient() or UI_IsActivityOn(ACTIVITY_ID.ACTION)))

        else
            UIHelper.SetVisible(self.tbTogOption[i] , tbTitle[i] ~= nil)
        end
        if tbTitle[i] then
            local szName = UIHelper.GBKToUTF8(tbTitle[i].name)
            UIHelper.SetString(v , szName)
            if self.tbTogSelectName then
                UIHelper.SetString(self.tbTogSelectName[i] , szName)
            end
        end
    end
    UIHelper.SetVisible(self.WidgetEmpty , false)
    self:UpdateTogGroupState()
end


function UISelfieEmotionAction:UpdateTogOptionState(togIndex)
    if self.nCurSelectOptionType == togIndex then
        return
    end
    self.nCurSelectOptionType = togIndex
    if self.curSelectTog then
        UIHelper.SetSelected(self.curSelectTog , false)
    end

    self.curSelectTog = self.tbTogOption[togIndex]
    UIHelper.SetSelected(self.curSelectTog , true)
    UIHelper.SetVisible(self.WidgetEmpty , false)
    self:UpdateEmotionAction()
end

function UISelfieEmotionAction:UpdateEmotionAction()
    UIHelper.SetVisible(self.BtnEdit, false)
    UIHelper.SetVisible(self.BtnExitEdit, false)
    self.bEditorModel = false
    UIHelper.RemoveAllChildren(self.ScrollViewContent)
    local tAction = {}
    if self.nCurSelectOptionType == nPendantIndex then
        self:UpdatePendantActions()
    elseif self.nCurSelectOptionType == nPetIndex then
        self:UpdatePetActionList()
    elseif self.nCurSelectOptionType == nHorseIndex then
        self:UpdateHorseActions()
    elseif self.nCurSelectOptionType == nPostureIndex then
        self:UpdatePosture()
    elseif self.nCurSelectOptionType == nExteriorIndex then
        self:UpdateExteriorActions()
    elseif self.nCurSelectOptionType == nFaceMotionIndex then
        self:UpdateFaceMotionActions()
    elseif self.nCurSelectOptionType == nCustomIndex then
        self:UpdateCustomActions()
    else
        local tAction = EmotionData.GetEmotionActionPackage(self.nCurSelectOptionType)
        for k, v in pairs(tAction) do
            local cell = UIHelper.AddPrefab(PREFAB_ID.WidgetQuickOperationBtn , self.ScrollViewContent)
            cell:OnEnter()
            UIHelper.BindUIEvent(cell.BtnQuickOperation , EventType.OnClick , function ()
                if cell.bCanClick then
                    if EmotionData.ProcessEmotionAction(cell.nDwID) then
                        if SelfieOneClickModeData.bOpenOneMode then
                            FireUIEvent("ON_ONE_CLICK_CHOOSE_BODY_ACTION", false, cell.nDwID)
                        else
                            self:Hide()
                        end
                    end
                end
            end)
            cell.bCanClick = true
            cell.nDwID = v.dwID
            local ea = EmotionData.GetEmotionAction(v.dwID)
            UIHelper.SetItemIconByIconID(cell.ImgIcon, ea.nIconID)
            local nCharCount,szUtfName = GetStringCharCountAndTopChars(UIHelper.GBKToUTF8(ea.szName),4)
            UIHelper.SetString(cell.LabelName,nCharCount > 4 and szUtfName.."..." or szUtfName)
            cell.bCanClick = ea.bLearned
            local bGray = not ea.bLearned
            UIHelper.SetNodeGray(cell.ImgIcon , bGray)
            UIHelper.SetNodeGray(cell.ImgBtn , bGray)
            UIHelper.SetNodeGray(cell.LabelName , bGray)
            if ea.bInteract then
                UIHelper.SetVisible(cell.ImgDoubleMark, true)
                UIHelper.SetSpriteFrame(cell.ImgDoubleMark, "UIAtlas2_Public_PublicIcon_PublicIcon1_OperationIcon1")
            elseif ea.bAniEdit then
                UIHelper.SetVisible(cell.ImgDoubleMark, true)
                UIHelper.SetSpriteFrame(cell.ImgDoubleMark, "UIAtlas2_Public_PublicIcon_PublicIcon1_OperationIcon2")
            elseif ea.nAniType ~= 0 and EMOTION_ACTION_ANI_TYPE[ea.nAniType] then
                UIHelper.SetVisible(cell.ImgDoubleMark, true)
                local path = "UIAtlas2_Public_PublicIcon_PublicIcon1_OperationIcon" .. EMOTION_ACTION_ANI_TYPE[ea.nAniType]
                UIHelper.SetSpriteFrame(cell.ImgDoubleMark, path)
            else
                UIHelper.SetVisible(cell.ImgDoubleMark, false)
            end
        end
    end

    UIHelper.ScrollViewDoLayoutAndToTop(self.ScrollViewContent)
end

function UISelfieEmotionAction:UpdateFaceMotionActions()
    local tFaceMotions = EmotionData.GetFaceMotions()
    for _, dwID in ipairs(tFaceMotions) do
        local tFaceMotion = EmotionData.GetFaceMotion(dwID)
        if tFaceMotion then
            local scriptBtn = UIHelper.AddPrefab(PREFAB_ID.WidgetQuickOperationBtn , self.ScrollViewContent)
            UIHelper.SetString(scriptBtn.LabelName, UIHelper.GBKToUTF8(tFaceMotion.szName) , 4)
            UIHelper.SetItemIconByIconID(scriptBtn.ImgIcon, tFaceMotion.nIconID)

            UIHelper.BindUIEvent(scriptBtn.BtnQuickOperation , EventType.OnClick , function ()
                if EmotionData.ProcessFaceMotion(tFaceMotion.dwID) then
                    if SelfieOneClickModeData.bOpenOneMode then
                        FireUIEvent("ON_ONE_CLICK_CHOOSE_FACE_ACTION", false, tFaceMotion.dwID)
                    else
                        self:Hide()
                    end
                end
            end)
        end
    end
end

function UISelfieEmotionAction:UpdateHorseActions()
    local tRepresentIDs = GetClientPlayer().GetRepresentID()
    local aRes = CharacterExteriorData.FindMatchedExteriorInfo(tRepresentIDs)
    local nCount = 0
    for resIndex, resInfo in pairs(aRes) do
        if CharacterExteriorData.IsHorse(resInfo.aRepresentIDGroups1) then
            local scriptBtn = UIHelper.AddPrefab(PREFAB_ID.WidgetQuickOperationBtn, self.ScrollViewContent)
            UIHelper.SetString(scriptBtn.LabelName, UIHelper.GBKToUTF8(resInfo.szName) , 4)
            UIHelper.SetVisible(scriptBtn.ImgIconAdd, false)

            UIHelper.RemoveAllChildren(scriptBtn.WidgetContainer)
            local scriptItemIcon = UIHelper.AddPrefab(PREFAB_ID.WidgetItem_100, scriptBtn.WidgetContainer)
            scriptItemIcon:OnInitSkill(resInfo.dwSkillID, resInfo.dwSkillLevel)

            UIHelper.SetItemIconByIconID(scriptItemIcon.ImgIcon, resInfo.dwIconID)

            UIHelper.SetNodeGray(scriptItemIcon.ImgIcon , false)

            UIHelper.SetEnable(scriptItemIcon.ToggleSelect, false)
            UIHelper.SetScale(scriptItemIcon._rootNode, 0.7, 0.7)
            UIHelper.SetVisible(scriptBtn.WidgetContainer, true)

            UIHelper.BindUIEvent(scriptBtn.BtnQuickOperation, EventType.OnClick, function()
                OnUseSkill(resInfo.dwSkillID, (resInfo.dwSkillID * (resInfo.dwSkillID % 10 + 1)))
            end)
            nCount = nCount + 1
        end
    end
    local bIsEmpty = nCount == 0

    UIHelper.SetVisible(self.WidgetEmpty , bIsEmpty)
    if bIsEmpty then
        UIHelper.SetString(self.LabelDescibe01 ,"暂无马具")
    end
end

function UISelfieEmotionAction:UpdatePendantOneActions(nCount, v, dwPendantID)
    local tItemInfo = dwPendantID > 0 and GetItemInfo(ITEM_TABLE_TYPE.CUST_TRINKET, dwPendantID) or nil
    local bHasPendantID = tItemInfo and tItemInfo.dwSkillID and tItemInfo.dwSkillID > 0
    local szName = bHasPendantID and GBKToUTF8(tItemInfo.szName) or v.szName
    if bHasPendantID then
        local scriptBtn = UIHelper.AddPrefab(PREFAB_ID.WidgetQuickOperationBtn, self.ScrollViewContent)
        UIHelper.SetString(scriptBtn.LabelName, szName, 4)
        UIHelper.SetVisible(scriptBtn.ImgIconAdd, false)
        UIHelper.RemoveAllChildren(scriptBtn.WidgetContainer)
        local scriptItemIcon = UIHelper.AddPrefab(PREFAB_ID.WidgetItem_100, scriptBtn.WidgetContainer)
        scriptItemIcon:OnInitWithTabID(ITEM_TABLE_TYPE.CUST_TRINKET, dwPendantID)
        UIHelper.SetEnable(scriptItemIcon.ToggleSelect, false)
        UIHelper.SetScale(scriptItemIcon._rootNode, 0.7, 0.7)
        UIHelper.SetVisible(scriptBtn.WidgetContainer, true)

        UIHelper.BindUIEvent(scriptBtn.BtnQuickOperation, EventType.OnClick, function()
            if bHasPendantID then
                OnUseSkill(tItemInfo.dwSkillID, 1)
            end
        end)
        nCount = nCount + 1
    end
end

function UISelfieEmotionAction:UpdatePendantActions()
    local nCount = 0
    for k, v in ipairs(CharacterPendantData.GetPendantTypeList()) do
        local szSpriteName = tbPendantTypeToSpriteName[v.szType]
        if szSpriteName then
            local dwPendantID, tUsingPendent = CharacterPendantData.GetUsingPendantID(k)
            if tUsingPendent and not IsEmpty(tUsingPendent) then
                for _, dwID in ipairs(tUsingPendent) do
                    self:UpdatePendantOneActions(nCount, v, dwID)
                end
            else
                self:UpdatePendantOneActions(nCount, v, dwPendantID)
            end
        end
    end
    if self:UpdateRepresentPart() then
        nCount = nCount + 1
    end

    local bIsEmpty = nCount == 0

    UIHelper.SetVisible(self.WidgetEmpty , bIsEmpty)
    if bIsEmpty then
        UIHelper.SetString(self.LabelDescibe01 ,"暂无挂件")
    end
end

function UISelfieEmotionAction:UpdateExteriorActions()
    local nCount = 0
    if self:UpdateRepresentPart(true) then
        nCount = 1
    end
    local bIsEmpty = nCount == 0

    UIHelper.SetVisible(self.WidgetEmpty , bIsEmpty)
    if bIsEmpty then
        UIHelper.SetString(self.LabelDescibe01 ,"暂无外装")
    end
end


function UISelfieEmotionAction:UpdateRepresentPart(IsExtrior)
    local tRepresentIDs = GetClientPlayer().GetRepresentID()
    local aRes = CharacterExteriorData.FindMatchedExteriorInfo(tRepresentIDs)

    local bHasPart = false
    local tbRHandSkill = {}
    local tbLHandSkill = {}

    local onCreatePart = function(resInfo)
        local scriptBtn = UIHelper.AddPrefab(PREFAB_ID.WidgetQuickOperationBtn, self.ScrollViewContent)
        UIHelper.SetString(scriptBtn.LabelName, UIHelper.GBKToUTF8(resInfo.szName), 4)
        UIHelper.SetVisible(scriptBtn.ImgIconAdd, false)
        UIHelper.RemoveAllChildren(scriptBtn.WidgetContainer)
        local scriptItemIcon = UIHelper.AddPrefab(PREFAB_ID.WidgetItem_100, scriptBtn.WidgetContainer)
        scriptItemIcon:OnInitSkill(resInfo.dwSkillID, resInfo.dwSkillLevel)
        UIHelper.SetItemIconByIconID(scriptItemIcon.ImgIcon, resInfo.dwIconID)
        UIHelper.SetNodeGray(scriptItemIcon.ImgIcon , GetClientPlayer().bOnHorse)

        UIHelper.SetEnable(scriptItemIcon.ToggleSelect, false)
        UIHelper.SetScale(scriptItemIcon._rootNode, 0.7, 0.7)
        UIHelper.SetVisible(scriptBtn.WidgetContainer, true)

        UIHelper.BindUIEvent(scriptBtn.BtnQuickOperation, EventType.OnClick, function()
            OnUseSkill(resInfo.dwSkillID, (resInfo.dwSkillID * (resInfo.dwSkillID % 10 + 1)))
        end)
    end

    for resIndex, resInfo in pairs(aRes) do
        if IsExtrior then
            if CharacterExteriorData.IsExtrior(resInfo.aRepresentIDGroups1) then
                bHasPart = true
                onCreatePart(resInfo)
            end
        else
            if CharacterExteriorData.IsLHandPandent(resInfo.aRepresentIDGroups1) then
                bHasPart = true
                if not table.contain_value(tbRHandSkill , resInfo.dwSkillID) then
                    table.insert(tbLHandSkill , resInfo.dwSkillID)
                    onCreatePart(resInfo)
                end
            elseif CharacterExteriorData.IsRHandPandent(resInfo.aRepresentIDGroups1) then
                bHasPart = true
                if not table.contain_value(tbLHandSkill , resInfo.dwSkillID) then
                    table.insert(tbRHandSkill , resInfo.dwSkillID)
                    onCreatePart(resInfo)
                end
            elseif CharacterExteriorData.IsPet(resInfo.aRepresentIDGroups1) then
                bHasPart = true
                onCreatePart(resInfo)
            elseif CharacterExteriorData.IsGlassesPandent(resInfo.aRepresentIDGroups1) then
                bHasPart = true
                onCreatePart(resInfo)
            end
        end

    end
    return bHasPart
end

function UISelfieEmotionAction:UpdatePetActionList()
    --判断一下玩家有没有召唤出宠物
    local tPet = g_pClientPlayer.GetFellowPet()
    local hPetIndex
    if tPet then
        hPetIndex = GetFellowPetIndexByNpcTemplateID(tPet.dwTemplateID)
    end
    if hPetIndex and hPetIndex ~= 0 then
        self:UpdatePetAction(hPetIndex)
    else
        UIHelper.SetVisible(self.WidgetEmpty , true)
        UIHelper.SetString(self.LabelDescibe01 ,"暂无宠物")
    end
end

function UISelfieEmotionAction:UpdatePetAction(hPetIndex)
    local tSkill = Table_GetFellowPetSkill(hPetIndex)
	if not tSkill then
		return
	end
    self.tPetActionScriptBtn = {}
    local nCount = #tSkill
    for i,tSkillData in ipairs(tSkill) do
        local scriptBtn = UIHelper.AddPrefab(PREFAB_ID.WidgetQuickOperationBtn,  self.ScrollViewContent)
        if scriptBtn then
            local nSkillID = tSkillData[1]
	        local nLevel = tSkillData[2]

            if nSkillID and nSkillID ~= 0 then
                UIHelper.RemoveAllChildren(scriptBtn.WidgetContainer)

                local szName = Table_GetSkillName(nSkillID,nLevel)
                local nCharCount,szUtfName = GetStringCharCountAndTopChars(UIHelper.GBKToUTF8(szName),4)
                UIHelper.SetString(scriptBtn.LabelName,nCharCount > 4 and szUtfName.."..." or szUtfName)

                local nIconID = Table_GetSkillIconID(nSkillID, nLevel)
                UIHelper.SetItemIconByIconID(scriptBtn.ImgIcon, nIconID)

                UIHelper.BindUIEvent(scriptBtn.BtnQuickOperation,EventType.OnClick,function ()
                    if self.nAllCDTimer then return end
                    local hBox = {}
                    hBox.nSkillLevel = nLevel
                    OnUseSkill(nSkillID, (nSkillID * (nSkillID % 10 + 1)), hBox)
                    self.nAllCDTimer = Timer.AddCycle(self, 1, function()
                        self:UpdateSkillCoolDown(nSkillID)
                    end)
                    self:Hide()
                end)

            end
            table.insert(self.tPetActionScriptBtn,{["scriptBtn"] = scriptBtn,["nSkillID"] = nSkillID})
        end
    end
end
function UISelfieEmotionAction:UpdateCustomActions()
    local bIsEmpty = true
    local tCustomMotionList = AiBodyMotionData.GetAllCustomFile()
    local tFilter = {}
    self.tCustomActionScript = {}
    if SelfieOneClickModeData.bOpenOneMode and SelfieOneClickModeData.nCustomMotionType then
        for _, v in ipairs(tCustomMotionList) do
            if v.nType == SelfieOneClickModeData.nCustomMotionType then
                table.insert(tFilter, v)
            end
        end
    else
        tFilter = tCustomMotionList
    end
    if #tFilter > 0 then
        for nIndex, v in ipairs(tFilter) do

            local _onSelectedFun = function(motionType, bSelected)
                
            end

            local _onDeletedFun = function(motionType, szName)
                AiBodyMotionData.DeleteCustomFile(motionType, szName)
                UIHelper.RemoveAllChildren(self.ScrollViewContent)
                self:UpdateCustomActions()
                UIHelper.ScrollViewDoLayoutAndToTop(self.ScrollViewContent)
            end
        
            local _onPlayFun = function(motionType)
                if motionType == AI_MOTION_TYPE.BODY then
                    AiBodyMotionData.ProcessAIAction(v.szMotionFilePath, false)
                    FireUIEvent("ON_ONE_CLICK_CHOOSE_BODY_ACTION", true, v.szMotionFilePath, v.szName)
                elseif motionType == AI_MOTION_TYPE.FACE then
                    AiBodyMotionData.ProcessFaceMotion(v.szMotionFilePath)
                    FireUIEvent("ON_ONE_CLICK_CHOOSE_FACE_ACTION", true, v.szMotionFilePath, v.szName)
                end
            end
            local item =UIHelper.AddPrefab(PREFAB_ID.WidgetCameraAIGeneratedModule, self.ScrollViewContent, v.nType, _onSelectedFun, _onPlayFun, _onDeletedFun)
            item:SetTogCheckBoxVisible(false)
            item:SetLabelName(v.szName)
            item:SetDeletedVisible(self.bEditorModel)
            item:SetPlayVisible(not self.bEditorModel)
            self.tCustomActionScript[tostring(v.nType)..v.szName] = item
        end
        bIsEmpty = false
    end

    if not bIsEmpty then
        UIHelper.SetVisible(self.BtnEdit, not self.bEditorModel and not SelfieOneClickModeData.bOpenOneMode)
        UIHelper.SetVisible(self.BtnExitEdit, self.bEditorModel and not SelfieOneClickModeData.bOpenOneMode)
    else
        self.bEditorModel = false
        UIHelper.SetVisible(self.BtnEdit, false)
        UIHelper.SetVisible(self.BtnExitEdit, false)
    end
    
    UIHelper.SetVisible(self.WidgetEmpty , bIsEmpty)
    if bIsEmpty then
        UIHelper.SetString(self.LabelDescibe01 ,"暂无自定义内容")
    end
end

function UISelfieEmotionAction:UpdateSkillCoolDown(nSkillID)
    local _, nLeft, nTotal = SkillData.GetSkillCDProcess(g_pClientPlayer, nSkillID)
    nLeft = nLeft or 0
    nTotal = nTotal or 1
    nLeft = math.ceil(nLeft / GLOBAL.GAME_FPS)
    nTotal = math.ceil(nTotal / GLOBAL.GAME_FPS)
    if nLeft and nLeft ~= 0 then
        self.nPetSkillCDTimer = self.nPetSkillCDTimer or Timer.AddCycle(self, 1, function()
            self:UpdateSkillCoolDown(nSkillID)
        end)
        Timer.DelTimer(self , self.nAllCDTimer)
        self.nAllCDTimer = nil
    else
        if self.nPetSkillCDTimer then
            Timer.DelAllTimer(self)
            self.nPetSkillCDTimer = nil
            self.nAllCDTimer = nil
        end
    end
    for k,v in ipairs(self.tPetActionScriptBtn) do
        UIHelper.SetNodeGray(v.scriptBtn.ImgIcon , nLeft ~= 0)
    end
end

function UISelfieEmotionAction:UpdateCameraCaptureStateChange()
    UIHelper.SetCanSelect(self.tbTogOption[nBackdropIndex], GetCameraCaptureState() ~= CAMERA_CAPTURE_STATE.Capturing, "增强现实模式下暂未开放", true)
end

function UISelfieEmotionAction:UpdatePosture()
    local nCount = 0
    self.tSelectCurActionCell = nil
    if not self.tPostureData then
        self.tPostureData = {}
        local hPlayer     = GetClientPlayer()
        if hPlayer then
            self.tPostureData.nRoleType = hPlayer.nRoleType
            self:UpdateCollectionData()
            self:SortIdleAction()
            self:GetIdleActionRepresent(hPlayer)
            self:GetIdleActionCameraData()
        end
    end
    nCount = self.tPostureData.nActionCount
    local hIdleActionSettings	= GetPlayerIdleActionSettings()
    for nIndex = 1, nCount, 1 do
        local tInfo 			= self.tPostureData.tIdleActionList[nIndex]
        local dwID 				= tInfo.dwID
        local scriptCell =  UIHelper.AddPrefab(PREFAB_ID.WidgetAccessoryEffect, self.ScrollViewContent)
        scriptCell:InitWithIdleAction(tInfo)
        scriptCell:SetClickCallback(function (tSelectCell)

            if self.tSelectCurActionCell then
                self.tSelectCurActionCell:SetSelected(false)
            end

            if not tInfo then
                return
            end

            local hPlayer = GetClientPlayer()
            if not hPlayer then
                return
            end
            if not hPlayer.bSheathFlag then
                local bOK = ToggleSheath()
                if not bOK then
                    return
                end
            end

            if self.tSelectCurActionCell and self.tSelectCurActionCell.tbInfo.dwID == tSelectCell.tbInfo.dwID  then
                self.tSelectCurActionCell = nil
                self.nSelectActionID = -1
                rlcmd("set local offline idle action id -1")
                return
            end

            self.tSelectCurActionCell = tSelectCell
            self.nSelectActionID = tSelectCell.tbInfo.dwID
            rlcmd(string.format("set local offline idle action id %d", tSelectCell.tbInfo.dwID))
        end)
        if dwID == self.nSelectActionID then
            scriptCell:SetSelected(true)
            self.tSelectCurActionCell = scriptCell
        end
	end

    local bIsEmpty = nCount == 0
    UIHelper.SetVisible(self.WidgetEmpty , bIsEmpty)
    if bIsEmpty then
        UIHelper.SetString(self.LabelDescibe01 ,"暂无站姿")
    end
end

function UISelfieEmotionAction:UpdateCollectionData()
    local pPlayer = GetClientPlayer()
    if not pPlayer then
		return
	end

	if pPlayer then
        local REMOTE_PREFER_ROLEAVATAR 	= 1171
        local PREFER_REMOTE_DATA_START 	= 0
        local PREFER_REMOTE_DATA_END 	= 3
        local PREFER_REMOTE_DATA_LEN 	= 1
		local dwPlayerID = pPlayer.dwID
        if IsRemotePlayer(dwPlayerID) then
            self.tPostureData.tCollection 		= {}
            return
        end
        if not pPlayer.HaveRemoteData(REMOTE_PREFER_ROLEAVATAR) then
            pPlayer.ApplyRemoteData(REMOTE_PREFER_ROLEAVATAR)
        end
        local tCollection = {}
        for i = PREFER_REMOTE_DATA_START, PREFER_REMOTE_DATA_END, PREFER_REMOTE_DATA_LEN do
            local dwActionID = pPlayer.GetRemoteArrayUInt(REMOTE_PREFER_ROLEAVATAR, i, PREFER_REMOTE_DATA_LEN)
            if dwActionID and dwActionID ~= 0 then
                tCollection[dwActionID] = true
            end
        end
        self.tPostureData.tCollection 		= tCollection
    end
end


function UISelfieEmotionAction:GetAllIdleAction()
	local hPlayer = GetClientPlayer()
	if not hPlayer then
		return
	end
	if self.tPostureData.tOriginalList then
		return self.tPostureData.tOriginalList
	end
	local tRes 			= {}
	local nRow 			= g_tTable.IdleAction:GetRowCount()
	for i = 2, nRow do
		local tLine 	= g_tTable.IdleAction:GetRow(i)
		if tLine then
			local bHave = hPlayer.IsHaveIdleAction(tLine.dwID)
			if bHave then
				table.insert(tRes, tLine)
			end
		end
	end
	self.tPostureData.tOriginalList = tRes
	return tRes
end

function UISelfieEmotionAction:SortIdleAction()
	local function fnDegree(a, b)
		if self.tPostureData.tCollection[a.dwID] == self.tPostureData.tCollection[b.dwID] then
			return a.dwID > b.dwID
		elseif self.tPostureData.tCollection[a.dwID] then
			return true
		else
			return false
		end
	end

	local tRes 					= clone(self:GetAllIdleAction())
	table.sort(tRes, fnDegree)
	self.tPostureData.nActionCount 		= #tRes
	self.tPostureData.tIdleActionList 	= tRes
end

function UISelfieEmotionAction:GetIdleActionRepresent(hPlayer)
    local tView =
    {
        EQUIPMENT_REPRESENT.FACE_STYLE,
        EQUIPMENT_REPRESENT.HAIR_STYLE,
    }
    self.tPostureData.aRepresent            	= {}
	local tRepresentID 					= hPlayer.GetRepresentID()
    for i = 0, EQUIPMENT_REPRESENT.TOTAL do
        self.tPostureData.aRepresent[i] = 0
    end
	for _, nRepresentSub in ipairs(tView) do
        self.tPostureData.aRepresent[nRepresentSub] = tRepresentID[nRepresentSub]
    end
    local bUseLiftedFace                = hPlayer.bEquipLiftedFace
    local tFaceData                     = hPlayer.GetEquipLiftedFaceData()
    self.tPostureData.aRepresent.bUseLiftedFace = bUseLiftedFace
    self.tPostureData.aRepresent.tFaceData      = tFaceData
end

function UISelfieEmotionAction:GetIdleActionCameraData()
	if self.tPostureData.aCameraData then
		return self.tPostureData.aCameraData
	end
	local tEnv = {}
	LoadScriptFile("ui/string/roleviewdata.lua", tEnv)
	self.tPostureData.aCameraData = tEnv.g_tRolePostureView
end

function UISelfieEmotionAction:UpdateTogGroupState()
    local bShow = not SelfieOneClickModeData.bOpenOneMode
    UIHelper.SetVisible(self.tbTogOption[nPostureIndex], bShow)
    UIHelper.SetVisible(self.tbTogOption[nPetIndex], bShow)
    UIHelper.SetVisible(self.tbTogOption[nPendantIndex], bShow)
    UIHelper.SetVisible(self.tbTogOption[nExteriorIndex], bShow)
    UIHelper.SetVisible(self.tbTogOption[nHorseIndex], bShow)
    UIHelper.ScrollViewDoLayoutAndToTop(UIHelper.GetChildByName(self.WidgetAnchorActionTog, "ScrollViewActionList"))
end

function UISelfieEmotionAction:GetFaceMotionIndex()
    return nFaceMotionIndex
end

return UISelfieEmotionAction