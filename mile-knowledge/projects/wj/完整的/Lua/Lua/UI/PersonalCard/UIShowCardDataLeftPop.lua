-- ---------------------------------------------------------------------------------
-- Name: UIShowCardDataLeftPop
-- Desc: 名片形象 - 数据选择
-- ---------------------------------------------------------------------------------
local UIShowCardDataLeftPop = class("UIShowCardDataLeftPop")
-- ---------------------------------------------------------------------------------
-- Data
-- ---------------------------------------------------------------------------------
local SHOWCARDDATA_TYPE = {
    COOPERATION = 1, --协作
    AGAINST = 2, --对抗
    RELAX = 3, --休闲
    EXTERIOR = 4, --外观
    OTHER = 5, --其他
}

-- local FixShowDataNum = 6
-- ---------------------------------------------------------------------------------
-- UI
-- ---------------------------------------------------------------------------------

function UIShowCardDataLeftPop:OnEnter(fnCallBack, dwKey)
    if not self.bInit then
        self:InitData()
        self:BindUIEvent()
        self:RegEvent()
        self.bInit = true
    end
    self.fnCallBack = fnCallBack
    self.dwSelectedKey = dwKey -- 当前选中的数据的key
    self.nType = 1 -- 当前选中的类型
    self:GetChoiceData()
    self:UpdateView()
end

function UIShowCardDataLeftPop:OnExit()
    self:ResetCurrentShowData()
    self.tShowCardList = nil
    self.tScript = nil
    self.bInit = false
    self:UnRegEvent()
end

function UIShowCardDataLeftPop:BindUIEvent()
    UIHelper.BindUIEvent(self.BtnClose, EventType.OnClick , function()
        UIHelper.RemoveFromParent(self._rootNode)
    end)

    UIHelper.BindUIEvent(self.BtnCloseLeft, EventType.OnClick , function()
        UIHelper.RemoveFromParent(self._rootNode)
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
            self:UpdateInfo(self.nType)
        end)
    end

    UIHelper.BindUIEvent(self.BtnClear, EventType.OnClick , function()
        self:ClearCurrentShowData()
    end)

    UIHelper.BindUIEvent(self.BtnSave, EventType.OnClick , function()
        self:ChangeCurrentShowData()
        TipsHelper.ShowNormalTip("保存成功")
    end)
end

function UIShowCardDataLeftPop:RegEvent()
    Event.Reg(self, "OnPersonalCardGetAllDataRespond", function(tData)
        self.tShowCardList = PersonalCardData.GetSelfShowCardData(tData)
        self:RefreshData()
        self:UpdateInfo(self.nType)
    end)
end

function UIShowCardDataLeftPop:UnRegEvent()
    --Event.UnReg(self, EventType.XXX)
end


-- ----------------------------------------------------------
-- Please write your own code below  ↓↓↓
-- ----------------------------------------------------------
function UIShowCardDataLeftPop:InitData()
    self.tShowCardList = {}     -- 数据
    self.tScript = {}           -- cell的script
    self.nShowCardTime = nil    -- 加载cell的定时器
    self.tChoiceDataList = {}
    self.tChoiceDataKey = {}
    self.tSetDataList = {}
    self.tSetDataKey = {}
end

function UIShowCardDataLeftPop:ApplyData()
    RemoteCallToServer("On_ShowCard_GetAllOptions")
end

function UIShowCardDataLeftPop:RefreshData()
    local function fnADegree(a, b)
        if a.nGrade == b.nGrade then
            return a.dwKey > b.dwKey
        else
            return a.nGrade < b.nGrade
        end
    end

    local tData = {}
    for key, _ in pairs (self.tShowCardList) do
        local dwKey = self.tShowCardList[key].dwKey
        -- if dwKey == self.dwSelectedKey then
        --     self.tShowCardList[key].bSelect = true
        -- else
        --     self.tShowCardList[key].bSelect = false
        -- end

        if self.tSetDataKey[dwKey] and self.tSetDataKey[dwKey] == true then
            self.tShowCardList[key].bChoice = true
        else
            self.tShowCardList[key].bChoice = false
        end

        if self.tChoiceDataKey[dwKey] and self.tChoiceDataKey[dwKey] == true then
            -- self.tShowCardList[key].bChoice = true
            self.tShowCardList[key].bSelect = true
            table.insert(tData, self.tShowCardList[key])
        else
            self.tShowCardList[key].bSelect = false
            -- self.tShowCardList[key].bChoice = false
        end
    end

    table.sort(tData, fnADegree)

    return tData
end

function UIShowCardDataLeftPop:GetChoiceData()
    local tData = g_pClientPlayer.GetAllShowCardData()
    local FixShowDataNum = 0
    for _, v in ipairs(tData) do
        if v.bConstKey == true then
            FixShowDataNum = FixShowDataNum + 1
        end
    end
    if #tData > FixShowDataNum then
        for nIndex = 1, #tData - FixShowDataNum do
            local key = tData[nIndex + FixShowDataNum].dwKey
            local tSettingLine = Table_GetPersonalCardData(key)
            if tSettingLine.nLevelValue1 <= tData[nIndex + FixShowDataNum].nValue1 then
                table.insert(self.tChoiceDataList, key)
                table.insert(self.tSetDataList, key)
                self.tSetDataKey[key] = true
                self.tChoiceDataKey[key] = true
            end
        end
    end
end

function UIShowCardDataLeftPop:ChangeCurrentKey(nKey)
    if nKey ~= 0 then
        if self.tChoiceDataKey[nKey] == true then -- 已有选中取消
            for k, v in ipairs(self.tChoiceDataList) do
                if v == nKey then
                    table.remove(self.tChoiceDataList, k)
                    break
                end
            end
            self.tChoiceDataKey[nKey] = false
            self.dwSelectedKey = nKey
        else
            if #self.tChoiceDataList == 3 then
                return false
            else
                table.insert(self.tChoiceDataList, nKey)
                self.tChoiceDataKey[nKey] = true
                self.dwSelectedKey = nKey
            end
        end
    end
    return true
end

function UIShowCardDataLeftPop:ChangeCurrentShowData()
    if not g_pClientPlayer then
        return
    end
    g_pClientPlayer.SetShowCardData(self.tChoiceDataList)
    self.tSetDataKey = {}
    self.tSetDataList = {}
    for _, v in ipairs(self.tChoiceDataList) do
        table.insert(self.tSetDataList, v)
        self.tSetDataKey[v] = true
    end
    self:RefreshData()
    self:UpdateInfoOfSingle(self.nType)
    UIHelper.SetButtonState(self.BtnSave, BTN_STATE.Disable)
    UIHelper.SetButtonState(self.BtnClear, BTN_STATE.Normal)
end

function UIShowCardDataLeftPop:ClearCurrentShowData()
    if not g_pClientPlayer then
        return
    end
    self.tChoiceDataList = {}
    self.tChoiceDataKey = {}
    self.tSetDataList = {}
    self.tSetDataKey = {}
    g_pClientPlayer.SetShowCardData(self.tChoiceDataList)

    local ttData  = self:RefreshData()
    self:UpdateInfoOfSingle(self.nType)
    if self.fnCallBack then
        self.fnCallBack(ttData)
    end
    UIHelper.SetButtonState(self.BtnClear, BTN_STATE.Disable)
    UIHelper.SetButtonState(self.BtnSave, BTN_STATE.Disable)
end

function UIShowCardDataLeftPop:ResetCurrentShowData()
    self.tChoiceDataKey = self.tSetDataKey
    local ttData  = self:RefreshData()
    if self.fnCallBack then
        self.fnCallBack(ttData)
    end
end
-- ----------------------------------------------------------
-- page
-- ----------------------------------------------------------
function UIShowCardDataLeftPop:UpdateView()
    local player = g_pClientPlayer

    if not PersonalCardData.tSelfShowDataInfo then
        self:ApplyData()
    else
        self.tShowCardList = PersonalCardData.tSelfShowDataInfo
        self:RefreshData()
        self:UpdateInfo(self.nType)
    end
end

function UIShowCardDataLeftPop:UpdateInfo(nType)
    self.tScript = {}
    UIHelper.RemoveAllChildren(self.ScrollViewContentSelect)
    -- UIHelper.ToggleGroupRemoveAllToggle(self.ToggleGroupEquip)

    -- self:UpdateInfoOfEmpty()
    self:InitPage()
    self:UpdateInfoOfSingle(nType)
    self:UpdateButtonState()
end

function UIShowCardDataLeftPop:UpdateInfoOfEmpty()
    local scriptCell = UIHelper.AddPrefab(PREFAB_ID.WidgetContentSelectCell, self.ScrollViewContentSelect) assert(scriptCell)
    UIHelper.ToggleGroupAddToggle(self.ToggleGroupEquip, scriptCell.TogSkill)
    scriptCell:ShowEmpty()
    scriptCell:SetSelectedCallback(function(nKey) 
        self:UpdateSelected(nKey)
    end)
end

function UIShowCardDataLeftPop:UpdateInfoOfSingle(nType)
    if self.nShowCardTime then
        Timer.DelTimer(self, self.nShowCardTime)
    end

    local loadIndex = 0
    local scriptIndex = 0
    local loadCount = #self.tShowCardList
    self.nShowCardTime = Timer.AddFrameCycle(self, 1, function ()
        for i = 1, 2, 1 do
            loadIndex = loadIndex + 1
            if nType == 1 or (nType ~= 1 or self.tShowCardList[loadIndex].nType == nType) then
                scriptIndex = scriptIndex + 1
                local scriptCell = self:Alloc(scriptIndex) assert(scriptCell)
                scriptCell:UpdateInfo(self.tShowCardList[loadIndex])
                UIHelper.SetVisible(scriptCell._rootNode, true)
                scriptCell:SetSelectedCallback(function(nKey) 
                    self:UpdateSelected(nKey)
                end)
            end
            if loadIndex == loadCount then
                self:Clear(scriptIndex + 1)
                Timer.DelTimer(self, self.nShowCardTime)
                UIHelper.ScrollViewDoLayoutAndToTop(self.ScrollViewContentSelect)
                break
            end
        end
    end)
end

function UIShowCardDataLeftPop:UpdateSelected(nKey)
    local bChange = self:ChangeCurrentKey(nKey)
    local ttData  = self:RefreshData()
    self:UpdateInfoOfSingle(self.nType)
    if bChange == true then
        if self.fnCallBack then
            self.fnCallBack(ttData)
        end
    else
        local STR_PERSONAL_CARD_DATA_SELECT_FULL = "选择的徽章数量已达上限3个，请先取消勾选\n"
        TipsHelper.ShowNormalTip(STR_PERSONAL_CARD_DATA_SELECT_FULL)
    end
    self:UpdateButtonState()
end

function UIShowCardDataLeftPop:UpdateButtonState()
    local nChoiceDataSize = #self.tChoiceDataList
    local nSetDataSize = #self.tSetDataList

    if nSetDataSize > 0 then
        UIHelper.SetButtonState(self.BtnClear, BTN_STATE.Normal)
    else
        UIHelper.SetButtonState(self.BtnClear, BTN_STATE.Disable)
    end

    local bDiff = false
    if nChoiceDataSize ~= nSetDataSize then
        bDiff = true
    end
    if not bDiff then
        for _, v in ipairs(self.tChoiceDataList) do
            local bFind = false
            for _, k in ipairs(self.tSetDataList) do
                if v == k then
                    bFind = true
                    break
                end
            end
            if not bFind then
                bDiff = true
                break
            end
        end
    end

    if bDiff then
        UIHelper.SetButtonState(self.BtnSave, BTN_STATE.Normal)
    else
        UIHelper.SetButtonState(self.BtnSave, BTN_STATE.Disable)
    end
end

-- ----------------------------------------------------------
-- cell alloc
-- ----------------------------------------------------------
function UIShowCardDataLeftPop:InitPage()
    for i = 1, 23 do
        local script = UIHelper.AddPrefab(PREFAB_ID.WidgetContentSelectCell, self.ScrollViewContentSelect) assert(script)
        -- UIHelper.ToggleGroupAddToggle(self.ToggleGroupEquip, script.TogSkill)
        table.insert(self.tScript, script)
        UIHelper.SetVisible(self.tScript[i]._rootNode, false)
    end

    local LabelTitle = UIHelper.GetChildByName(self.BtnClear, "LabelClear")
    UIHelper.SetString(LabelTitle, "卸下当前")
end

function UIShowCardDataLeftPop:Alloc(nIndex)
    if #self.tScript < nIndex then
        local script = UIHelper.AddPrefab(PREFAB_ID.WidgetContentSelectCell, self.ScrollViewContentSelect) assert(script)
        -- UIHelper.ToggleGroupAddToggle(self.ToggleGroupEquip, script.TogSkill)
        table.insert(self.tScript, script)
        UIHelper.SetVisible(self.tScript[nIndex]._rootNode, false)
    end
    return self.tScript[nIndex]
end

function UIShowCardDataLeftPop:Clear(nIndex)
    assert(self.tScript)
    for i = nIndex, #self.tScript do
        UIHelper.SetVisible(self.tScript[i]._rootNode, false)
    end
end

return UIShowCardDataLeftPop