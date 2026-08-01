-- ---------------------------------------------------------------------------------
-- Author: huqing
-- Name: UICommonFilterTips
-- Date: 2023-05-24 10:17:26
-- Desc: 通用筛选和排序tips
-- ---------------------------------------------------------------------------------

local UICommonFilterTips = class("UICommonFilterTips")

function UICommonFilterTips:OnEnter(tbFilterDef)
    self.tbFilterDef = tbFilterDef

    self.nHeight = UIHelper.GetHeight(self._rootNode)
    self.nSVHeight = UIHelper.GetHeight(self.ScrollViewType)
    self.nSVY = UIHelper.GetPositionY(self.ScrollViewType)
    self.nLayoutBtnY = UIHelper.GetPositionY(self.LayoutBtn)

    self.tbCompList = {}
    self.tbTitleList = {}
    self.tbTitleCompList = {}
    if not self.bInit then
        self:RegEvent()
        self:BindUIEvent()
        self.bInit = true
    end

    self:UpdateInfo()
end

function UICommonFilterTips:OnExit()
    self.bInit = false
    self:UnRegEvent()
end

function UICommonFilterTips:BindUIEvent()
    UIHelper.BindUIEvent(self.BtnFocusReset, EventType.OnClick, function()
        self:Reset()
    end)

    UIHelper.BindUIEvent(self.BtnReset, EventType.OnClick, function()
        self:Reset()
    end)

    UIHelper.BindUIEvent(self.BtnFocusConfirm, EventType.OnClick, function()
        if not self:Confirm() then
            return
        end

        Event.Dispatch(EventType.HideAllHoverTips)
    end)

    UIHelper.BindUIEvent(self.BtnConfirm, EventType.OnClick, function()
        if self.fnConfirm then
            self.fnConfirm()
        end
        if not self:Confirm() then
            return
        end

        Event.Dispatch(EventType.HideAllHoverTips)
    end)
end

function UICommonFilterTips:RegEvent()
    --Event.Reg(self, EventType.XXX, func)
end

function UICommonFilterTips:UnRegEvent()
    --Event.UnReg(self, EventType.XXX)
end






-- ----------------------------------------------------------
-- Please write your own code below  ↓↓↓
-- ----------------------------------------------------------
local function SetCompDisable(oneDef, oneComp, nSubIndex)
    local bDisable = false
    if oneDef.tbDisableList and oneDef.tbDisableList[nSubIndex] then bDisable = oneDef.tbDisableList[nSubIndex] end

    UIHelper.SetEnable(oneComp, not bDisable)
    UIHelper.SetNodeGray(oneComp, bDisable, true)

    local rootNode = UIHelper.GetParent(oneComp)
    local script = UIHelper.GetBindScript(rootNode)
    if script then
        UIHelper.SetVisible(script.ImgDisable, bDisable)
        if script.tbImgDisableList and #script.tbImgDisableList >= 2 then
            UIHelper.SetVisible(script.tbImgDisableList[(nSubIndex+1)%2 + 1], bDisable)
        end
    end
end

function UICommonFilterTips:UpdateInfo()
    UIHelper.RemoveAllChildren(self.ScrollViewType)
    for nIndex, oneDef in ipairs(self.tbFilterDef or {}) do
        -- 动态生成列表
        if oneDef.szDynMakeListFuncName then
            local funcMakeList = FilterDef[oneDef.szDynMakeListFuncName]
            if funcMakeList then
                oneDef.tbList = funcMakeList()
            end
        end

        local szType = oneDef.szType
        local funcCheckVis = oneDef.funcCheckVis
        if not funcCheckVis or funcCheckVis() then
            if szType == FilterType.CheckBox then
                self:AddTitle(nIndex, oneDef)
                self:AddCheckBox(nIndex, oneDef)
            elseif szType == FilterType.RangeInput then
                self:AddTitle(nIndex, oneDef)
                self:AddRangeInput(nIndex, oneDef)
            elseif szType == FilterType.RadioButton then
                self:AddTitle(nIndex, oneDef)
                self:AddRadioButton(nIndex, oneDef)
            end
        end
        if oneDef.nMaxSelectedCount then
            self:CheckTogSeletedLimit(nIndex)
        end
    end

    UIHelper.ScrollViewDoLayoutAndToTop(self.ScrollViewType)

    local _, nSVInnerHeight = UIHelper.GetInnerContainerSize(self.ScrollViewType)
    local nDelta = self.nSVHeight - nSVInnerHeight

    if nDelta > 0 then
        UIHelper.SetHeight(self._rootNode, self.nHeight - nDelta)

        UIHelper.SetHeight(self.ImgBg, self.nHeight - nDelta)
        UIHelper.SetPositionY(self.ImgBg, 0)
        UIHelper.SetHeight(self.ScrollViewType, self.nSVHeight - nDelta)
        UIHelper.SetPositionY(self.ScrollViewType, self.nSVY)
        UIHelper.SetPositionY(self.LayoutBtn, self.nLayoutBtnY + nDelta)
    end

    if self.tbFilterDef.bHideConfirmBtn then
        UIHelper.SetVisible(self.BtnConfirm, false)
        UIHelper.LayoutDoLayout(self.LayoutBtn)
    end
end

function UICommonFilterTips:AddTitle(nIndex, oneDef)
    local script = UIHelper.AddPrefab(PREFAB_ID.WidgetTittleCell, self.ScrollViewType, oneDef.bCanSelectAll)
    script:RegisterSelectAllEvent(function (bSelected)
        self:SelectAll(nIndex, bSelected)
    end)
    self.tbTitleList[nIndex] = script
    self.tbTitleCompList[nIndex] = script.TogSelectedAll
    UIHelper.SetString(script.LabelTittle, oneDef.szTitle)

    local bVisible = not (oneDef.bHideSingleOption and #oneDef.tbList == 1)
    UIHelper.SetVisible(script._rootNode, bVisible)

    if oneDef.szSubTitle then
        UIHelper.SetString(script.LabelSubTittle, oneDef.szSubTitle)
        UIHelper.SetVisible(script.LabelSubTittle, true)
    else
        UIHelper.SetVisible(script.LabelSubTittle, false)
    end
end

function UICommonFilterTips:AddRangeInput(nIndex, oneDef)
    local script = UIHelper.AddPrefab(PREFAB_ID.WidgetRange, self.ScrollViewType)
    self:UpdateOneEditBox(nIndex, oneDef, script.EditLow, script.EditHigh, true, false)
end

function UICommonFilterTips:AddCheckBox(nIndex, oneDef)
    self:AddToggle(nIndex, oneDef, true)
end

function UICommonFilterTips:AddRadioButton(nIndex, oneDef)
    self:AddToggle(nIndex, oneDef, false)
end

function UICommonFilterTips:AddToggle(nIndex, oneDef, bCheckBox)
    local bIsSmall = (oneDef.szSubType == FilterSubType.Small)
    local nPrefabID = bIsSmall and PREFAB_ID.WidgetTogTypeSingle_S or PREFAB_ID.WidgetTogTypeSingle_L
    if bCheckBox then
        nPrefabID = bIsSmall and PREFAB_ID.WidgetTogTypeMulti_S or PREFAB_ID.WidgetTogTypeMulti_L
    end

    local nLen = #oneDef.tbList
    local nIterLen = bIsSmall and math.ceil(nLen / 2) or nLen

    for i = 1, nIterLen do
        local script = UIHelper.AddPrefab(nPrefabID, self.ScrollViewType)
        if bIsSmall then
            for j = 1, 2 do
                self:UpdateOneTog(nIndex, ((i-1)*2+j), oneDef, script.tbToggleList[j], script.tbLabelList[j], nil, true, false)
            end
        else
            self:UpdateOneTog(nIndex, i, oneDef, script.TogType, script.LabelTogName, script.LabelProgress, true, false)
        end

        local bVisible = not (oneDef.bHideSingleOption and nLen == 1)
        UIHelper.SetVisible(script._rootNode, bVisible)
    end
end

function UICommonFilterTips:UpdateOneTog(nIndex, nSubIndex, oneDef, tog, label, labelProgress, bAdd, bUseDefault)
    local nLen = #oneDef.tbList
    local bVisible = nSubIndex <= nLen
    UIHelper.SetVisible(tog, bVisible)
    if not bVisible then return end

    local bIsRadioButton = oneDef.szType == FilterType.RadioButton
    local tbSeletedIdx = self.tbFilterDef[nIndex].tbDefault
    if not bUseDefault then
        local bStorage = self.tbFilterDef.bStorage
        local bRuntime = self.tbFilterDef.bRuntime
        if bStorage then
            local tbStorage = self.tbFilterDef.ReadFromStorage()
            if tbStorage and tbStorage[nIndex] then
                tbSeletedIdx = tbStorage[nIndex]
            end
        elseif bRuntime then
            local tbRuntime = self.tbFilterDef.GetRunTime()
            if tbRuntime and tbRuntime[nIndex] then
                tbSeletedIdx = tbRuntime[nIndex]
            end
        end
    end

    SetCompDisable(oneDef, tog, nSubIndex)

    local bSelected = table.contain_value(tbSeletedIdx, nSubIndex)
    UIHelper.SetSelected(tog, bSelected)
    UIHelper.SetString(label, oneDef.tbList[nSubIndex])
    if oneDef.tbColorList and oneDef.tbColorList[nSubIndex] then
        UIHelper.SetTextColor(label, oneDef.tbColorList[nSubIndex])
    end
    if oneDef.nFontSize then UIHelper.SetFontSize(label, oneDef.nFontSize) end

    if labelProgress and oneDef.tbProgressList and oneDef.tbProgressList[nSubIndex] then
        UIHelper.SetVisible(labelProgress, true)
        UIHelper.SetString(labelProgress, oneDef.tbProgressList[nSubIndex])
        if oneDef.nFontSize then UIHelper.SetFontSize(labelProgress, oneDef.nFontSize) end
    end
    if not bSelected then
        UIHelper.SetSelected(self.tbTitleCompList[nIndex], false)
    end
    -- 单选 要设置GroupIndex
    if bIsRadioButton then
        tog:setGroupIndex(tog:getGroupIndex() + nIndex)
    end

    if bAdd then
        if not self.tbCompList[nIndex] then
            self.tbCompList[nIndex] = {}
        end

        table.insert(self.tbCompList[nIndex], tog)
    end

    -- 修改后是否立即变化
    UIHelper.BindUIEvent(tog, EventType.OnSelectChanged, function(btn, bSelected)
        Timer.AddFrame(self, 1, function ()
            self:UpdateToggleSelectAll(nIndex)
            if oneDef.bDispatchChangedEvent then
                local tSelected = self:GetSelectedMap()
                Event.Dispatch(EventType.OnFilterSelectChanged, self.tbFilterDef.Key, tSelected)
            end

            if oneDef.nMaxSelectedCount then
                self:CheckTogSeletedLimit(nIndex)
            end
        end)

        if oneDef.bResponseImmediately then
            if self.bIsReset or (bIsRadioButton and not bSelected) then
                return
            end

            Timer.DelTimer(self, self.nTimerID)
            self.nTimerID = Timer.AddFrame(self, 1, function()
                self:Confirm()
            end)
            self.nLastChoosedIndex = nIndex
            self.nLastChoosedSubIndex = nSubIndex
        end
    end)
end

function UICommonFilterTips:UpdateOneEditBox(nIndex, oneDef, editLow, editHigh, bAdd, bUseDefault)
    local tbSeletedIdx = self.tbFilterDef[nIndex].tbDefault
    if not bUseDefault then
        local bStorage = self.tbFilterDef.bStorage
        local bRuntime = self.tbFilterDef.bRuntime
        if bStorage then
            local tbStorage = self.tbFilterDef.ReadFromStorage()
            if tbStorage and tbStorage[nIndex] then
                tbSeletedIdx = tbStorage[nIndex]
            end
        elseif bRuntime then
            local tbRuntime = self.tbFilterDef.GetRunTime()
            if tbRuntime and tbRuntime[nIndex] then
                tbSeletedIdx = tbRuntime[nIndex]
            end
        end
    end

    UIHelper.SetPlaceHolder(editLow, oneDef.tbList[1])
    UIHelper.SetPlaceHolder(editHigh, oneDef.tbList[2])

    local nMin, nMax = tbSeletedIdx[1], tbSeletedIdx[2]

    if IsNumber(nMin) and IsNumber(nMax) and nMax > nMin then
        UIHelper.SetString(editLow, nMin)
        UIHelper.SetString(editHigh, nMax)
    else
        UIHelper.SetString(editLow, "")
        UIHelper.SetString(editHigh, "")
    end

    if bAdd then
        if not self.tbCompList[nIndex] then
            self.tbCompList[nIndex] = {}
        end

        table.insert(self.tbCompList[nIndex], editLow)
        table.insert(self.tbCompList[nIndex], editHigh)
    end
end

function UICommonFilterTips:UpdateToggleSelectAll(nIndex)
    local TogSelectedAll = self.tbTitleCompList[nIndex]
    local bSelectAll = true
    for _, tog in ipairs(self.tbCompList[nIndex]) do
        if not UIHelper.GetSelected(tog) then
            bSelectAll = false
            break
        end
    end

    UIHelper.SetSelected(TogSelectedAll, bSelectAll, false)
end

function UICommonFilterTips:CheckTogSeletedLimit(nIndex)
    local oneDef = self.tbFilterDef[nIndex]
    local nMaxSelectCount = oneDef and oneDef.nMaxSelectedCount
    if not nMaxSelectCount then
        return
    end

    local nSelectedCount = 0
    for _, tog in ipairs(self.tbCompList[nIndex]) do
        if UIHelper.GetSelected(tog) then
            nSelectedCount = nSelectedCount + 1
        end
    end

    if nSelectedCount >= nMaxSelectCount then
        for nSubIndex, tog in ipairs(self.tbCompList[nIndex]) do
            if not UIHelper.GetSelected(tog) then
                UIHelper.SetEnable(tog, false)
                UIHelper.SetNodeGray(tog, true, true)
            else
                UIHelper.SetEnable(tog, true)
                UIHelper.SetNodeGray(tog, false, true)
            end
        end
    else
        for nSubIndex, tog in ipairs(self.tbCompList[nIndex]) do
            local bDisable = false
            if oneDef.tbDisableList and oneDef.tbDisableList[nSubIndex] then
                bDisable = oneDef.tbDisableList[nSubIndex]
            end
            UIHelper.SetEnable(tog, not bDisable)
            UIHelper.SetNodeGray(tog, bDisable, true)
        end
    end
    UIHelper.SetString(self.tbTitleList[nIndex].LabelSubTittle, string.format("%d/%d", nSelectedCount, nMaxSelectCount))
    UIHelper.SetVisible(self.tbTitleList[nIndex].LabelSubTittle, true)
end

function UICommonFilterTips:Reset()
    self.bIsReset = true
    local bResponseImmediately = false

    for nIndex, tbOneCompList in pairs(self.tbCompList) do
        local oneDef = self.tbFilterDef[nIndex]
        local szType = oneDef and oneDef.szType

        if szType == FilterType.CheckBox or
            szType == FilterType.RadioButton then
            for nSubIndex, oneComp in ipairs(tbOneCompList) do
                self:UpdateOneTog(nIndex, nSubIndex, oneDef, oneComp, nil, nil, false, true)
            end
        elseif szType == FilterType.RangeInput then
            local editLow, editHigh = tbOneCompList[1], tbOneCompList[2]
            self:UpdateOneEditBox(nIndex, oneDef, editLow, editHigh, false, true)
        end

        if oneDef.bResponseImmediately then
            bResponseImmediately = true
        end
    end

    if bResponseImmediately then
        self:Confirm()
    end

    self.bIsReset = false
end

function UICommonFilterTips:Refresh()
    for nIndex, tbOneCompList in ipairs(self.tbCompList) do
        local oneDef = self.tbFilterDef[nIndex]
        local szType = oneDef and oneDef.szType

        if szType == FilterType.CheckBox or
            szType == FilterType.RadioButton then
            for nSubIndex, oneComp in ipairs(tbOneCompList) do
                SetCompDisable(oneDef, oneComp, nSubIndex)
            end
        elseif szType == FilterType.RangeInput then
            local editLow, editHigh = tbOneCompList[1], tbOneCompList[2]
            SetCompDisable(oneDef, editLow, 1)
            SetCompDisable(oneDef, editHigh, 2)
        end
    end
end

function UICommonFilterTips:Check()
    for nIndex, tbOneCompList in ipairs(self.tbCompList) do
        local oneDef = self.tbFilterDef[nIndex]
        local szType = oneDef and oneDef.szType
        local szTitle = oneDef and oneDef.szTitle or ""

        if szType == FilterType.CheckBox then
            local nCheckCount = 0
            for nSubIndex, oneComp in ipairs(tbOneCompList) do
                if UIHelper.GetSelected(oneComp) then
                    nCheckCount = nCheckCount + 1
                end
            end

            if not oneDef.bAllowAllOff and nCheckCount == 0 then
                TipsHelper.ShowNormalTip(string.format("[%s] 至少要选择一项", szTitle))
                return false
            end
        elseif szType == FilterType.RangeInput then
            local editLow, editHigh = tbOneCompList[1], tbOneCompList[2]
            local szLow, szHigh = UIHelper.GetString(editLow), UIHelper.GetString(editHigh)
            local nLow, nHigh = tonumber(szLow), tonumber(szHigh)
            local szLowDesc, szHighDesc = oneDef.tbList[1], oneDef.tbList[2]

            if not string.is_nil(szLow) and not string.is_nil(szHigh) and (not nLow or not nHigh) then
                TipsHelper.ShowNormalTip(string.format("[%s] 不正确，请按正确的内容填写", szTitle))
                return false
            end

            if nLow and nHigh and nLow > nHigh then
                TipsHelper.ShowNormalTip(string.format("[%s] %s不能大于%s", szTitle, szLowDesc, szHighDesc))
                return false
            end
        end
    end

    return true
end

function UICommonFilterTips:Confirm()
    local bCheckFlag = self:Check()
    if not bCheckFlag then
        return false
    end

    local bStorage = self.tbFilterDef.bStorage
    local bRuntime = self.tbFilterDef.bRuntime

    local tbTemp = self:GetSelectedMap()
    for nIndex, _ in ipairs(self.tbCompList) do
        UIHelper.SetSelected(self.tbTitleCompList[nIndex], #self.tbFilterDef[nIndex].tbList == #tbTemp[nIndex])
    end

    if bStorage or bRuntime then
        if bStorage then
            self.tbFilterDef.WriteToStorage(tbTemp)
        elseif bRuntime then
            self.tbFilterDef.SetRunTime(tbTemp)
        end
    end

    Event.Dispatch(EventType.OnFilter, self.tbFilterDef.Key, tbTemp, self.nLastChoosedIndex, self.nLastChoosedSubIndex)

    return true
end

function UICommonFilterTips:SelectAll(nTargetIndex, bSelectAll)
    if not self.tbFilterDef[nTargetIndex].bCanSelectAll then
        return false
    end

    local bStorage = self.tbFilterDef.bStorage
    local bRuntime = self.tbFilterDef.bRuntime

    local tbTemp = {}
    for nIndex, tbOneCompList in pairs(self.tbCompList) do
        tbTemp[nIndex] = {}

        local szType = self.tbFilterDef[nIndex].szType
        if szType == FilterType.CheckBox or szType == FilterType.RadioButton then
            for nSubIndex, oneComp in ipairs(tbOneCompList) do
                local bOldSelect = UIHelper.GetSelected(oneComp)
                local bNewSelect = bSelectAll
                if nIndex == nTargetIndex then
                    if bOldSelect ~= bNewSelect then
                        UIHelper.SetSelected(oneComp, bNewSelect)
                    end
                    if bNewSelect then
                        table.insert(tbTemp[nIndex], nSubIndex)
                    end
                elseif bOldSelect then
                    table.insert(tbTemp[nIndex], nSubIndex)
                end
            end
        elseif szType == FilterType.RangeInput then
            local editLow, editHigh = tbOneCompList[1], tbOneCompList[2]
            local szLow, szHigh = UIHelper.GetString(editLow), UIHelper.GetString(editHigh)
            local nLow, nHigh = tonumber(szLow), tonumber(szHigh)
            tbTemp[nIndex][1] = nLow or -1
            tbTemp[nIndex][2] = nHigh or -1
        end
    end

    if bStorage or bRuntime then
        if bStorage then
            self.tbFilterDef.WriteToStorage(tbTemp)
        elseif bRuntime then
            self.tbFilterDef.SetRunTime(tbTemp)
        end
    end

    if self.tbFilterDef[nTargetIndex].bResponseImmediately then
        Event.Dispatch(EventType.OnFilter, self.tbFilterDef.Key, tbTemp, self.nLastChoosedIndex, self.nLastChoosedSubIndex)
    end

    return true
end

function UICommonFilterTips:GetSelectedMap()
    local tbTemp = {}
    for nIndex, tbOneCompList in pairs(self.tbCompList) do
        tbTemp[nIndex] = {}

        local szType = self.tbFilterDef[nIndex].szType
        if szType == FilterType.CheckBox or szType == FilterType.RadioButton then
            for nSubIndex, oneComp in ipairs(tbOneCompList) do
                if UIHelper.GetSelected(oneComp) then
                    table.insert(tbTemp[nIndex], nSubIndex)
                end
            end
        elseif szType == FilterType.RangeInput then
            local editLow, editHigh = tbOneCompList[1], tbOneCompList[2]
            local szLow, szHigh = UIHelper.GetString(editLow), UIHelper.GetString(editHigh)
            local nLow, nHigh = tonumber(szLow), tonumber(szHigh)
            tbTemp[nIndex][1] = nLow or -1
            tbTemp[nIndex][2] = nHigh or -1
        end
    end

    return tbTemp
end

function UICommonFilterTips:BindFocusMoreCallBack(fnMore)
    UIHelper.BindUIEvent(self.BtnMore, EventType.OnClick, fnMore)
    UIHelper.SetVisible(self.LayoutBtn, false)
    UIHelper.SetVisible(self.LayoutFocusBtn, true)
end

function UICommonFilterTips:SetBtnResetVis(bShow)
    UIHelper.SetVisible(self.BtnReset, bShow)
    UIHelper.LayoutDoLayout(self.LayoutBtn)
end

function UICommonFilterTips:SetBtnConfirmFunc(fnConfirm, szTitle)
    self.fnConfirm = fnConfirm
    if szTitle then
        UIHelper.SetString(self.LabelConfirm, szTitle)
    end
end


function UICommonFilterTips:SetBtnConfirmState(nState)
    UIHelper.SetButtonState(self.BtnConfirm, nState)
end

return UICommonFilterTips