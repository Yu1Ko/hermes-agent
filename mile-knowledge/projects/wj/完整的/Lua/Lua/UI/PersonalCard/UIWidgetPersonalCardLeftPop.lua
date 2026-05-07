-- ---------------------------------------------------------------------------------
-- Name: UIWidgetPersonalCardLeftPop
-- Desc: 名片形象 - 称号选择弹窗
-- ---------------------------------------------------------------------------------

local UIWidgetPersonalCardLeftPop = class("UIWidgetPersonalCardLeftPop")
-- ---------------------------------------------------------------------------------
-- Data
-- ---------------------------------------------------------------------------------

local DataModel = {}

function DataModel.Init()
    DataModel.tMyPrefixDesignation = {}
    DataModel.tMyPostfixDesignation = {}
    DataModel.tDesignationList = {}
    DataModel.tDesignationList[DESIGNATION_TYPE.ALL] = {}
    DataModel.tDesignationList[DESIGNATION_TYPE.WORLD] = {}
    DataModel.tDesignationList[DESIGNATION_TYPE.CAMP] = {}
    DataModel.tDesignationList[DESIGNATION_TYPE.PREFIX] = {}
    DataModel.tDesignationList[DESIGNATION_TYPE.POSTFIX] = {}
    DataModel.tDesignationList[DESIGNATION_TYPE.COURTESY] = {}
    DataModel.nEditPrefixID = 0
    DataModel.nEditPostfixID  = 0
    DataModel.nEditCourtesyID = 0
    DataModel.nEquipPrefixID = 0
    DataModel.nEquipPostfixID  = 0
    DataModel.nEquipCourtesyID = 0
end

function DataModel.UnInit()
    DataModel.tMyPrefixDesignation = nil
    DataModel.tMyPostfixDesignation = nil
    DataModel.tDesignationList = nil
end

function DataModel.UpdateMyPrefixDesignation()
    if not g_pClientPlayer then
        return
    end
    local tPrefixAll = g_pClientPlayer.GetAcquiredDesignationPrefix()
    for i, dwID in ipairs(tPrefixAll) do
        local tInfo
        if dwID ~= 0 then
            tInfo = GetDesignationPrefixInfo(dwID)
        end
        if tInfo then
            DataModel.tMyPrefixDesignation[dwID] = {}
            DataModel.tMyPrefixDesignation[dwID].nOwnDuration = tInfo.nOwnDuration
            DataModel.tMyPrefixDesignation[dwID].nType = tInfo.nType
        end
    end
end

function DataModel.UpdateMyPostfixDesignation()
    if not g_pClientPlayer then
        return
    end
    local tPostfixAll = g_pClientPlayer.GetAcquiredDesignationPostfix()
    for i, dwID in ipairs(tPostfixAll) do
        local tInfo
        if dwID ~= 0 then
            tInfo = GetDesignationPostfixInfo(dwID)
        end
        if tInfo then
            DataModel.tMyPostfixDesignation[dwID] = {}
            DataModel.tMyPostfixDesignation[dwID].nOwnDuration = tInfo.nOwnDuration
            DataModel.tMyPostfixDesignation[dwID].nType = tInfo.nType
        end

    end
end

function DataModel.GetGenerationDesignation()
    if not g_pClientPlayer then
        return
    end
    local tGen = g_tTable.Designation_Generation:Search(g_pClientPlayer.dwForceID, g_pClientPlayer.GetDesignationGeneration())
    if tGen then
        if tGen.szCharacter and tGen.szCharacter ~= "" and not tGen.bSetNewName then
            local tCharacter = g_tTable[tGen.szCharacter]:Search(g_pClientPlayer.GetDesignationByname())
            if tCharacter then
                tGen.szName = tGen.szName .. tCharacter.szName
                tGen.bSetNewName = true
            end
        end
    end
    return tGen
end

function DataModel.GetNowDesignation()
    if not g_pClientPlayer then
        return
    end
    DataModel.nEquipPrefixID = g_pClientPlayer.GetCurrentDesignationPrefix()
    DataModel.nEquipPostfixID = g_pClientPlayer.GetCurrentDesignationPostfix()
    DataModel.nEquipCourtesyID = g_pClientPlayer.GetDesignationBynameDisplayFlag() and g_pClientPlayer.GetDesignationGeneration() or 0

    DataModel.nEditPrefixID = DataModel.nEquipPrefixID
    DataModel.nEditPostfixID  = DataModel.nEquipPostfixID
    DataModel.nEditCourtesyID = DataModel.nEquipCourtesyID
end

function DataModel.Table_GetDesignationForce()
    if not g_pClientPlayer then
        return
    end
    return Table_GetDesignationForce(g_pClientPlayer.dwForceID)
end

function DataModel.GetDesignationList()
    DataModel.GetNowDesignation()
    DataModel.UpdateMyPrefixDesignation()
    DataModel.UpdateMyPostfixDesignation()
    local tDesignationPrefix = Table_GetDesignationPrefix()
    local tData = {}
    for _, tLine in pairs(tDesignationPrefix) do
        local dwID = tLine.dwID
        if DataModel.tMyPrefixDesignation[dwID] then
            if DataModel.tMyPrefixDesignation[dwID].nOwnDuration ~= 0 then
                tLine.bLimit = true
            end
            if DataModel.tMyPrefixDesignation[dwID].nType == DESIGNATION_PREFIX_TYPE.WORLD_DESIGNATION then
                tLine.nType = DESIGNATION_TYPE.WORLD
                tData = DataModel.SetDesignationData(tLine)
                table.insert(DataModel.tDesignationList[DESIGNATION_TYPE.WORLD], tData)
            elseif DataModel.tMyPrefixDesignation[dwID].nType == DESIGNATION_PREFIX_TYPE.MILITARY_RANK_DESIGNATION then
                tLine.nType = DESIGNATION_TYPE.CAMP
                tData = DataModel.SetDesignationData(tLine)
                table.insert(DataModel.tDesignationList[DESIGNATION_TYPE.CAMP], tData)
            else
                tLine.nType = DESIGNATION_TYPE.PREFIX
                tData = DataModel.SetDesignationData(tLine)
                table.insert(DataModel.tDesignationList[DESIGNATION_TYPE.PREFIX], tData)
            end
            table.insert(DataModel.tDesignationList[DESIGNATION_TYPE.ALL], tData)
        end
    end

    local tDesignationPostfix = Table_GetDesignationPostfix()
    for _, tLine in pairs(tDesignationPostfix) do
        local dwID = tLine.dwID
        if DataModel.tMyPostfixDesignation[dwID] then
            tLine.nType = DESIGNATION_TYPE.POSTFIX
            if DataModel.tMyPostfixDesignation[dwID].nOwnDuration ~= 0 then
                tLine.bLimit = true
            end
            tData = DataModel.SetDesignationData(tLine)
            if tData then
                table.insert(DataModel.tDesignationList[DESIGNATION_TYPE.POSTFIX], tData)
                table.insert(DataModel.tDesignationList[DESIGNATION_TYPE.ALL], tData)
            end
        end
    end

    local tGen = DataModel.GetGenerationDesignation()
    local tDesignationForce = DataModel.Table_GetDesignationForce()
    if tDesignationForce then
        for _, tLine in pairs(tDesignationForce) do
            if tGen and tLine.dwGeneration == tGen.dwGeneration then
                tGen.nQuality = 1
                tGen.dwID = tGen.dwGeneration
                tGen.nType = DESIGNATION_TYPE.COURTESY
                tData = DataModel.SetDesignationData(tLine)
                if tData then
                    table.insert(DataModel.tDesignationList[DESIGNATION_TYPE.COURTESY], tData)
                    table.insert(DataModel.tDesignationList[DESIGNATION_TYPE.ALL], tData)
                end
            end
        end
    end
end

function DataModel.SetDesignationData(tLine)
    if not g_pClientPlayer then
        return
    end

    local tData = {}

    local dwID = tLine.dwID
    local nType = tLine.nType

    tData.dwID = dwID
    tData.nType = nType
    tData.bDisable = not not tLine.bDisable --not not: nil -> false
    tData.bIsEffect = not not tLine.bIsEffect
    tData.szName = UIHelper.GBKToUTF8(tLine.szName)
    tData.nQuality = tLine.nQuality
    tData.bTimeLimit = false
    -- tData.bHave = true

    if nType ~= DESIGNATION_TYPE.COURTESY and dwID ~= 0 then
        local tInfo
        if nType == DESIGNATION_TYPE.POSTFIX then
            tInfo = GetDesignationPostfixInfo(dwID)
        else
            tInfo = GetDesignationPrefixInfo(dwID)
        end
        tData.dwID  = dwID
        if tInfo.nOwnDuration ~= 0 then
            tData.bTimeLimit = true
        end
    end

    return tData
end

function DataModel.UpdateDesignationListOfSel(nType)
    for index, tLine in ipairs(DataModel.tDesignationList[nType]) do
        local nType = tLine.nType
        local dwID = tLine.dwID
        local nEquipID, nSelID
        if nType == DESIGNATION_TYPE.POSTFIX then
            nEquipID = DataModel.nEquipPostfixID
            nSelID = DataModel.nEditPostfixID
        else
            nEquipID = DataModel.nEquipPrefixID
            nSelID = DataModel.nEditPrefixID
        end

        if nType == DESIGNATION_TYPE.COURTESY then
            DataModel.tDesignationList[nType][index].bEquip = g_pClientPlayer.GetDesignationBynameDisplayFlag()
            DataModel.tDesignationList[nType][index].bSel = DataModel.nEditCourtesyID == dwID
        else
            DataModel.tDesignationList[nType][index].bEquip = nEquipID == dwID
            DataModel.tDesignationList[nType][index].bSel = nSelID == dwID
        end
    end
end

local Type2Name = {
    [DESIGNATION_TYPE.WORLD] = "世界称号",
    [DESIGNATION_TYPE.CAMP] = "战阶称号",
    [DESIGNATION_TYPE.PREFIX] = "前缀称号",
    [DESIGNATION_TYPE.POSTFIX] = "后缀称号",
    [DESIGNATION_TYPE.COURTESY] = "门派称号"
}
-- ---------------------------------------------------------------------------------
-- UI
-- ---------------------------------------------------------------------------------

function UIWidgetPersonalCardLeftPop:OnEnter(fnCallBack)
    if not self.bInit then
        DataModel.Init()
        DataModel.GetDesignationList()
        self:InitPage()
        self.nTitleID = {}
        self:BindUIEvent()
        self.bInit = true
    end
    self.bShowFlitter = false
    self.fnCallBack = fnCallBack
    UIHelper.SetSelected(self.tbTogSelect[1], true, false)
    self.nType = DESIGNATION_TYPE.ALL
    self:UpdateInfo(DESIGNATION_TYPE.ALL, true)
end

function UIWidgetPersonalCardLeftPop:OnExit()
    local szName = self:GetDesignationInfo(DataModel.nEquipPrefixID, DataModel.nEquipPostfixID, DataModel.nEquipCourtesyID)
    if self.fnCallBack then
        self.fnCallBack(szName)
    end
    DataModel.UnInit()
    self.bInit = false
    self:UnRegEvent()
    for i = 2, 6 do
        if self.nTitleID and self.nTitleID[i] ~= nil then
            Timer.DelTimer(self, self.nTitleID[i])
        end
    end
end

function UIWidgetPersonalCardLeftPop:BindUIEvent()
    UIHelper.BindUIEvent(self.BtnClose, EventType.OnClick , function()
        UIHelper.RemoveFromParent(self._rootNode)
    end)

    UIHelper.BindUIEvent(self.BtnCloseLeft, EventType.OnClick , function()
        UIHelper.RemoveFromParent(self._rootNode)
    end)

    UIHelper.BindUIEvent(self.BtnSave, EventType.OnClick, function()
        DataModel.nEquipPrefixID = DataModel.nEditPrefixID
        DataModel.nEquipPostfixID = DataModel.nEditPostfixID
        DataModel.nEquipCourtesyID = DataModel.nEditCourtesyID
        self:ChangeCurrentDesignation()
        self:UpdateInfo(self.nType)
        TipsHelper.ShowNormalTip("保存成功")
    end)

    UIHelper.BindUIEvent(self.BtnClear, EventType.OnClick, function()
        DataModel.nEquipPrefixID = 0
        DataModel.nEquipPostfixID = 0
        DataModel.nEquipCourtesyID = 0
        DataModel.nEditPrefixID = 0
        DataModel.nEditPostfixID = 0
        DataModel.nEditCourtesyID = 0
        if self.fnCallBack then
            self.fnCallBack()
        end
        self:ChangeCurrentDesignation()
        self:UpdateInfo(self.nType)
    end)

    UIHelper.BindUIEvent(self.TogQuality, EventType.OnClick , function()
        self.bShowFlitter = not self.bShowFlitter
        UIHelper.SetVisible(self.WidgetAnchorRepeatedTips, self.bShowFlitter)
    end)

    for index, tog in ipairs(self.tbTogSelect) do
        UIHelper.ToggleGroupAddToggle(self.TogGroupQuality, tog)
        UIHelper.BindUIEvent(tog, EventType.OnSelectChanged, function(btn, bSelected)
            if not bSelected then return end
            self.nType = index
            self:HideTitle()
            self:UpdateInfo(index, true)
        end)
    end
end

function UIWidgetPersonalCardLeftPop:RegEvent()
    --Event.Reg(self, EventType.XXX, func)
end

function UIWidgetPersonalCardLeftPop:UnRegEvent()
    --Event.UnReg(self, EventType.XXX)
end






-- ----------------------------------------------------------
-- Please write your own code below  ↓↓↓
-- ----------------------------------------------------------

function UIWidgetPersonalCardLeftPop:UpdateInfo(nType, bShowTop)
    if #DataModel.tDesignationList[nType] == 0 then
        self:UpdateInfoOfEmpty(true)
        return
    end

    self:UpdateInfoOfEmpty(false)
    if nType == DESIGNATION_TYPE.ALL then
        for i = 2, 6 do
            if #DataModel.tDesignationList[i] > 0 then
                DataModel.UpdateDesignationListOfSel(i)
                self:UpdateInfoOfSingle(i, bShowTop)
            end
        end
    else
        DataModel.UpdateDesignationListOfSel(nType)
        self:UpdateInfoOfSingle(nType, bShowTop)
    end

    self:UpdateButtonState()
end

function UIWidgetPersonalCardLeftPop:UpdateInfoOfSingle(nType, bShowTop)
    if self.nTitleID[nType] then
        Timer.DelTimer(self , self.nTitleID[nType])
    end

    local scriptTitle = self.tscriptTitle[nType]
    UIHelper.SetVisible(scriptTitle._rootNode, true)

    local loadIndex = 0
    local loadCount = #DataModel.tDesignationList[nType]
    self.nTitleID[nType] = Timer.AddFrameCycle(self, 1, function ()
        for i = 1, 2, 1 do
            loadIndex = loadIndex + 1
            local scriptCell = self:Alloc(nType, loadIndex) assert(scriptCell)
            scriptCell:UpdateInfo(DataModel.tDesignationList[nType][loadIndex])
            scriptCell:SetSelectedCallback(function(tData)
                self:UpdateSelected(tData)
                self:UpdateInfo(self.nType)
            end)

            if loadIndex == loadCount then
                UIHelper.CascadeDoLayoutDoWidget(scriptTitle._rootNode, true)
                if bShowTop then
                    UIHelper.ScrollViewDoLayoutAndToTop(self.ScrollViewTitle)
                else
                    UIHelper.ScrollViewDoLayout(self.ScrollViewTitle)
                end
                Timer.DelTimer(self, self.nTitleID[nType])
                break
            end
        end
    end)
end

function UIWidgetPersonalCardLeftPop:UpdateInfoOfEmpty(bVisible)
    UIHelper.SetVisible(self.WidgetEmpty, bVisible)
    UIHelper.SetVisible(self.BtnSave, not bVisible)
    UIHelper.SetVisible(self.BtnClear, not bVisible)
end

function UIWidgetPersonalCardLeftPop:UpdateButtonState()
    if DataModel.nEquipPrefixID == 0 and DataModel.nEquipPostfixID  == 0 and DataModel.nEquipCourtesyID == 0 then
        UIHelper.SetButtonState(self.BtnClear, BTN_STATE.Disable)
    else
        UIHelper.SetButtonState(self.BtnClear, BTN_STATE.Normal)
    end

    if DataModel.nEquipPrefixID == DataModel.nEditPrefixID and DataModel.nEquipPostfixID  == DataModel.nEditPostfixID
        and DataModel.nEquipCourtesyID == DataModel.nEditCourtesyID then
        UIHelper.SetButtonState(self.BtnSave, BTN_STATE.Disable)
    else
        UIHelper.SetButtonState(self.BtnSave, BTN_STATE.Normal)
    end
end

function UIWidgetPersonalCardLeftPop:UpdateSelected(tData)
    if not tData then return end

    local dwID = tData.dwID
    local nSelDesignationType = tData.nType
    local bDelete = false

    if nSelDesignationType == DESIGNATION_TYPE.POSTFIX then
        DataModel.nSelDesignationTitle = DESIGNATION_TITLE.COMPOSE
        if DataModel.nEditPostfixID == dwID then
            DataModel.nEditPostfixID = 0
            bDelete = true
        else
            DataModel.nEditPostfixID = dwID
        end
    elseif nSelDesignationType == DESIGNATION_TYPE.COURTESY then
        DataModel.nSelDesignationTitle = DESIGNATION_TITLE.COMPOSE
        if DataModel.nEditCourtesyID == dwID then
            bDelete = true
            DataModel.nEditCourtesyID = 0
        else
            DataModel.nEditCourtesyID = dwID
        end
    else
        if nSelDesignationType == DESIGNATION_TYPE.WORLD or nSelDesignationType == DESIGNATION_TYPE.CAMP then
            DataModel.nSelDesignationTitle = DESIGNATION_TITLE.UNIQUE
        elseif nSelDesignationType == DESIGNATION_TYPE.PREFIX then
            DataModel.nSelDesignationTitle = DESIGNATION_TITLE.COMPOSE
        end
        if DataModel.nEditPrefixID == dwID then
            bDelete = true
            DataModel.nEditPrefixID = 0
        else
            DataModel.nEditPrefixID = dwID
        end
    end

    if DataModel.nSelDesignationTitle == DESIGNATION_TITLE.UNIQUE and not bDelete then
        DataModel.nEditPostfixID  = 0
        DataModel.nEditCourtesyID = 0
    elseif DataModel.nSelDesignationTitle == DESIGNATION_TITLE.COMPOSE then
        local nEditPrefixID = DataModel.nEditPrefixID
        if nEditPrefixID ~= 0 then
            local tInfo = GetDesignationPrefixInfo(nEditPrefixID)
            if tInfo.nType ~= DESIGNATION_PREFIX_TYPE.NORMAL_PREFIX then
                DataModel.nEditPrefixID = 0
            end
        end
    end

    local szName = self:GetDesignationInfo(DataModel.nEditPrefixID, DataModel.nEditPostfixID, DataModel.nEditCourtesyID)

    if self.fnCallBack then
        self.fnCallBack(szName)
    end
end

function UIWidgetPersonalCardLeftPop:GetDesignationInfo(nPrefixID, nPostfixID, nCourtesyID, dwForceID)
    local szName

    local tPrefixInfo = nPrefixID and nPrefixID ~= 0 and GetDesignationPrefixInfo(nPrefixID)
    if tPrefixInfo and tPrefixInfo.nType ~= DESIGNATION_PREFIX_TYPE.NORMAL_PREFIX then
        local t = Table_GetDesignationPrefixByID(nPrefixID, dwForceID)
        szName = t and UIHelper.GBKToUTF8(t.szName) or ""
    else
        local szPrefixName    = ""
        local szPostfixName   = ""
        local szCourtesyName  = ""
        if nPrefixID and nPrefixID ~= 0 then
            if tPrefixInfo.nType == DESIGNATION_PREFIX_TYPE.NORMAL_PREFIX then
                local t = Table_GetDesignationPrefixByID(nPrefixID, dwForceID)
                szPrefixName = t and t.szName or ""
            end
        end
        if nPostfixID and nPostfixID ~= 0 then
            szPostfixName = g_tTable.Designation_Postfix:Search(nPostfixID).szName
        end
        if nCourtesyID and nCourtesyID ~= 0 then
            local tGen = DataModel.GetGenerationDesignation()
            szCourtesyName = tGen.szName
        end
        szName = UIHelper.GBKToUTF8(szPrefixName .. szPostfixName .. szCourtesyName)
    end
    if szName == ""  then
        szName = nil
    end
    return szName
end

function UIWidgetPersonalCardLeftPop:ChangeCurrentDesignation()
    if not g_pClientPlayer then
        return
    end
    g_pClientPlayer.SetCurrentDesignation(DataModel.nEquipPrefixID, DataModel.nEquipPostfixID, DataModel.nEquipCourtesyID ~= 0)
end

-- ----------------------------------------------------------
-- cell alloc
-- ----------------------------------------------------------
function UIWidgetPersonalCardLeftPop:InitPage()
    self.tscriptTitle = {}
    self.tScriptCell = {}
    for nType = 2, 6 do
        if #DataModel.tDesignationList[nType] > 0 then
            local scriptTitle = UIHelper.AddPrefab(PREFAB_ID.WidgetLeftPopPersonalTitleTitleCell, self.ScrollViewTitle) assert(scriptTitle)
            UIHelper.SetString(scriptTitle.LabelTitle, Type2Name[nType])
            self.tscriptTitle[nType] = scriptTitle
            UIHelper.SetVisible(scriptTitle._rootNode, false)

            self.tScriptCell[nType] = {}
            local nCount = #DataModel.tDesignationList[nType]
            for i = 1, nCount do
                local scriptCell = UIHelper.AddPrefab(PREFAB_ID.WidgetLeftPopPersonalTitleCell, scriptTitle.LayoutLeftPopPersonalTitle) assert(scriptCell)
                table.insert(self.tScriptCell[nType], scriptCell)
                UIHelper.SetVisible(self.tScriptCell[nType][i]._rootNode, false)
                UIHelper.SetSwallowTouches(scriptCell.TogPersonalTitleVontent, false)
            end
        end
    end
end

function UIWidgetPersonalCardLeftPop:Alloc(nType, nIndex)
    if self.tScriptCell and self.tScriptCell[nType] then
        UIHelper.SetVisible(self.tScriptCell[nType][nIndex]._rootNode, true)
        return self.tScriptCell[nType][nIndex]
    end
end

function UIWidgetPersonalCardLeftPop:HideTitle()
    for _, v in pairs(self.tscriptTitle) do
        UIHelper.SetVisible(v._rootNode, false)
    end
end

return UIWidgetPersonalCardLeftPop