-- ---------------------------------------------------------------------------------
-- Author: Unknown
-- Name: UICustomizedSetImportView
-- Date: 2024-08-27 14:09:56
-- Desc: ?
-- ---------------------------------------------------------------------------------

local UICustomizedSetImportView = class("UICustomizedSetImportView")

function UICustomizedSetImportView:OnEnter(dwKungfuID, tbSetData)
    if not self.bInit then
        self:RegEvent()
        self:BindUIEvent()
        self.bInit = true
    end

    self.dwKungfuID = dwKungfuID
    self.tbSetData = tbSetData
    self:UpdateInfo()
end

function UICustomizedSetImportView:OnExit()
    self.bInit = false
end

function UICustomizedSetImportView:BindUIEvent()
    UIHelper.BindUIEvent(self.BtnClose, EventType.OnClick, function(btn)
        UIMgr.Close(self)
    end)

    UIHelper.BindUIEvent(self.BtnOutPut, EventType.OnClick, function(btn)
        local szKungFuName = PlayerKungfuName[self.dwKungfuID] or ""
        local szKungFuChineseName = PlayerKungfuChineseName[self.dwKungfuID] or ""
        local nTotalScore = CalculateTotalEquipsScore(szKungFuName, Lib.copyTab(self.tbSetData))

        local scriptView = UIMgr.Open(VIEW_ID.PanelPromptPop, "", "请输入方案名", function (szTitle)
            if not TextFilterCheck(UIHelper.UTF8ToGBK(szTitle)) then --过滤文字
                TipsHelper.ShowNormalTip("您输入的方案名中含有敏感字词。")
                return
            end

            if self.nCurIndex then
                local tRoleEquips = EquipCodeData.GetRoleEquipData()
                local tData = tRoleEquips[self.nCurIndex]
                EquipCodeData.ReqUpdateRoleEquips(tData.id, szTitle, szKungFuChineseName, nTotalScore, self.tbSetData)
            else
                EquipCodeData.ReqUploadRoleEquips(szTitle, szKungFuChineseName, nTotalScore, self.tbSetData)
            end
            UIMgr.Close(self)
        end)
        scriptView:SetTitle("设置配装方案名")
        scriptView:SetPlaceHolder("字数不能超过4个字")
        scriptView:SetMaxLength(4)
    end)
end

function UICustomizedSetImportView:RegEvent()
    Event.Reg(self, EventType.OnSelectCustomizedSetImportCell, function (nIndex, tData)
        if tData then
            self.nCurIndex = nIndex
        else
            self.nCurIndex = nil
        end
    end)
end

function UICustomizedSetImportView:UpdateInfo()
    local tRoleEquips = EquipCodeData.GetRoleEquipData()

    self.tbSetCells = self.tbSetCells or {}
    UIHelper.HideAllChildren(self.ScrollViewOptionList)
    self.nCurIndex = nil
    if tRoleEquips and #tRoleEquips > 0 then
        for i, tData in ipairs(tRoleEquips) do
            if not self.tbSetCells[i] then
                self.tbSetCells[i] = UIHelper.AddPrefab(PREFAB_ID.WidgetCustomSetInputCell, self.ScrollViewOptionList)
            end

            UIHelper.SetVisible(self.tbSetCells[i]._rootNode, true)
            self.tbSetCells[i]:OnEnter(i, tData)
        end
        self.nCurIndex = 1
    end

    if not tRoleEquips or #tRoleEquips < EquipCodeData.nMaxRoleSetCount then
        local nIndex = EquipCodeData.nMaxRoleSetCount + 1
        if not self.tbSetCells[nIndex] then
            self.tbSetCells[nIndex] = UIHelper.AddPrefab(PREFAB_ID.WidgetCustomSetInputCell, self.ScrollViewOptionList)
        end

        UIHelper.SetVisible(self.tbSetCells[nIndex]._rootNode, true)
        self.tbSetCells[nIndex]:OnEnter(nIndex)
    end

    UIHelper.ScrollViewDoLayoutAndToTop(self.ScrollViewOptionList)
end


return UICustomizedSetImportView