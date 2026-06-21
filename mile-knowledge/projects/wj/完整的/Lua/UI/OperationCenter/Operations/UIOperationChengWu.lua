-- ---------------------------------------------------------------------------------
-- Author: Unknown
-- Name: UIOperationChengWu
-- Date: 2026-04-13 10:11:40
-- Desc: ?
-- ---------------------------------------------------------------------------------

local UIOperationChengWu = class("UIOperationChengWu")

function UIOperationChengWu:OnEnter(nOperationID, nID, tComponentContext)
    if not self.bInit then
        self:RegEvent()
        self:BindUIEvent()
        self.bInit = true
    end

    self.nOperationID = nOperationID
    self.nID = nID
    self.tComponentContext = tComponentContext

    self.scriptTop = self.tComponentContext.tScriptLayoutTop[4]
    self.scriptCenter = tComponentContext.scriptCenter
    self:UpdateInfo()
end

function UIOperationChengWu:OnExit()
    self.bInit = false
    self:UnRegEvent()
end

function UIOperationChengWu:BindUIEvent()

end

function UIOperationChengWu:RegEvent()
    --Event.Reg(self, EventType.XXX, func)
end

function UIOperationChengWu:UnRegEvent()
    --Event.UnReg(self, EventType.XXX)
end

-- ----------------------------------------------------------
-- Please write your own code below  ↓↓↓
-- ----------------------------------------------------------

function UIOperationChengWu:UpdateInfo()
    self.tbScript = {}
    self.nSelectIndex = 1

    local tScriptTaskList = self.scriptTop.tScriptTaskList or {}

    self.scriptTop:SetVisibleTitle(false)

    local nConfigIndex = 1
    self.tConfig = self:GetOrangeWeaponConfig(self.nOperationID)
    for _, tbScriptWidgetTaskList in ipairs(tScriptTaskList) do
        local bHasContent = false
        local tSlots = {
            tbScriptWidgetTaskList.WidgetTaskList1,
            tbScriptWidgetTaskList.WidgetTaskList2,
        }

        for _, widget in ipairs(tSlots) do
            local tbWeaponInfo = self.tConfig[nConfigIndex]

            if tbWeaponInfo then
                UIHelper.SetVisible(widget, true)
                local tbScript = UIHelper.AddPrefab(PREFAB_ID.WidgetNewInfoChengWu, widget)
                if tbScript then
                    self:UpdateWeaponInfo(tbScript, tbWeaponInfo, nConfigIndex)
                    self.tbScript[nConfigIndex] = tbScript
                    bHasContent = true
                end
            else
                UIHelper.SetVisible(widget, false)
            end

            nConfigIndex = nConfigIndex + 1
        end

        UIHelper.SetVisible(tbScriptWidgetTaskList._rootNode, bHasContent)
    end

    if self.tbScript[self.nSelectIndex] then
        self:OnSelectWeapon(self.nSelectIndex)
    end
end

function UIOperationChengWu:UpdateWeaponInfo(tbScript, tbWeaponInfo, nIndex)
    local szBgPath = tbWeaponInfo.szMobileBgPath
    local szIconPath = tbWeaponInfo.szMobileIcon
    local szTitle = UIHelper.GBKToUTF8(tbWeaponInfo.szTitle)
    local bSelect = self.nSelectIndex == nIndex
    UIHelper.SetString(tbScript.LabelName, szTitle)
    UIHelper.SetSpriteFrame(tbScript.ImgIcon, szIconPath)
    UIHelper.SetSpriteFrame(tbScript.ImgBg, szBgPath)
    UIHelper.SetVisible(tbScript.ImgSelect, bSelect)

    UIHelper.BindUIEvent(tbScript.BtnChengWu, EventType.OnClick, function()
        self:OnSelectWeapon(nIndex)
    end)
end

function UIOperationChengWu:OnSelectWeapon(nIndex)
    local nSelectIndex = self.nSelectIndex
    UIHelper.SetVisible(self.tbScript[nSelectIndex].ImgSelect, false)
    self.nSelectIndex = nIndex
    UIHelper.SetVisible(self.tbScript[nIndex].ImgSelect, true)

    local tbWeaponInfo = self.tConfig[nIndex]
    if tbWeaponInfo and tbWeaponInfo.szMobileVideoPath ~= "" then
        if self.scriptCenter then
            self.scriptCenter:PlayVideo(nil, tbWeaponInfo.szMobileVideoPath)
        end
    end
end

function UIOperationChengWu:GetOrangeWeaponConfig(dwID)
    local tOrangeWeaponConfig = {}
    for _, tInfo in ipairs(Table_GetOperationOrangeWeaponInfo(dwID) or {}) do
        local tItem = {}
        for k, v in pairs(tInfo) do
            tItem[k] = v
        end
        if (not tItem.szTitle or tItem.szTitle == "") and tItem.nSchoolType then
            tItem.szTitle = g_tStrings.tSchoolTitle[tItem.nSchoolType] or ""
        end
        tItem.szMobileVideoPath = tItem.szMobileVideoPath or ""
        table.insert(tOrangeWeaponConfig, tItem)
    end

    table.sort(tOrangeWeaponConfig, function(a, b)
        return (a.nIndex or 0) < (b.nIndex or 0)
    end)

    return tOrangeWeaponConfig
end

return UIOperationChengWu