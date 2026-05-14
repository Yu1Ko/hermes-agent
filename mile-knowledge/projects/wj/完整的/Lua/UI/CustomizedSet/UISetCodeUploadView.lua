-- ---------------------------------------------------------------------------------
-- Author: Unknown
-- Name: UISetCodeUploadView
-- Date: 2024-07-30 09:50:44
-- Desc: ?
-- ---------------------------------------------------------------------------------

local UISetCodeUploadView = class("UISetCodeUploadView")

local MAX_NAME_LEN = 4
function UISetCodeUploadView:OnEnter()
    if not self.bInit then
        self:RegEvent()
        self:BindUIEvent()
        self.bInit = true
    end

    EquipCodeData.LoginAccount(false)
    self:UpdateInfo()
end

function UISetCodeUploadView:OnExit()
    self.bInit = false
end

function UISetCodeUploadView:BindUIEvent()
    UIHelper.RegisterEditBoxChanged(self.EditBox, function()
        self:UpdateInfo()
    end)

    UIHelper.BindUIEvent(self.BtnClose, EventType.OnClick, function(btn)
        UIMgr.Close(self)
    end)

    UIHelper.BindUIEvent(self.BtnOutPut, EventType.OnClick, function(btn)
        local szTitle = UIHelper.GetText(self.EditBox)
        if not TextFilterCheck(UIHelper.UTF8ToGBK(szTitle)) then --过滤文字
            TipsHelper.ShowNormalTip("您输入的方案名中含有敏感字词。")
            return
        end

        local szKungFuChineseName = PlayerKungfuChineseName[EquipCodeData.dwCurKungfuID]
        local tbData = EquipCodeData.ExportCustomizedSetEquip()

        local szKungFu = PlayerKungfuName[EquipCodeData.dwCurKungfuID] or ""
        local nTotalScore = CalculateTotalEquipsScore(szKungFu, Lib.copyTab(tbData))
        local dwBelongSchoolID = Table_ForceToSchool(EquipCodeData.dwCurForceID)
        local szSchoolName = Table_GetSkillSchoolName(dwBelongSchoolID, true)
        EquipCodeData.ReqUploadEquip(szTitle, EquipCodeData.dwCurKungfuID, szKungFuChineseName, szSchoolName, nTotalScore, self.nCurTag, tbData)
    end)
end

function UISetCodeUploadView:RegEvent()
    Event.Reg(self, EventType.OnEquipCodeRsp, function (szKey, tInfo)
        if szKey == "LOGIN_ACCOUNT_EQUIPCODE" then
            if EquipCodeData.szSessionID then
                self.bLoginWeb = true
                self:UpdateInfo()
            else
                TipsHelper.ShowNormalTip("连接云端服务器失败，请稍候重试")
                UIMgr.Close(self)
            end
        elseif szKey == "UPLOAD_EQUIPS_BY_GAME" then
            Timer.AddFrame(self, 1, function ()
                UIMgr.Close(self)
            end)
        end
    end)

    Event.Reg(self, "LOGIN_NOTIFY", function(nEvent)
		if nEvent == LOGIN.REQUEST_LOGIN_GAME_SUCCESS or nEvent == LOGIN.MISS_CONNECTION then
			Timer.Add(self, 0.3, function ()
                UIMgr.Close(self)
            end)
		end
    end)
end

function UISetCodeUploadView:UpdateInfo()
    self:UpdateBaseInfo()
    self:UpdateTagsInfo()
end

function UISetCodeUploadView:UpdateBaseInfo()
    local szTitle = UIHelper.GetText(self.EditBox)
    szTitle = Lib.FilterSpecString(szTitle)
    UIHelper.SetText(self.EditBox, szTitle)

    UIHelper.SetButtonState(self.BtnOutPut, BTN_STATE.Normal)
    if not self.bLoginWeb then
        UIHelper.SetButtonState(self.BtnOutPut, BTN_STATE.Disable, "正在登录云端服务器，请稍候")
    elseif not string.is_nil(szTitle) then
        UIHelper.SetButtonState(self.BtnOutPut, BTN_STATE.Normal)
    else
        UIHelper.SetButtonState(self.BtnOutPut, BTN_STATE.Disable, "请输入配装方案名称")
    end

    if string.is_nil(szTitle) then
        UIHelper.SetString(self.LabelLimit, string.format("%d/%d", 0, MAX_NAME_LEN))
    else
        UIHelper.SetString(self.LabelLimit, string.format("%d/%d", string.getCharLen(szTitle), MAX_NAME_LEN))
    end
end

function UISetCodeUploadView:UpdateTagsInfo()
    local nPosType = PlayerKungfuPosition[EquipCodeData.dwCurKungfuID] or KUNGFU_POSITION.DPS
    local tbTags = PlayerKungfuPosition2EquipTags[nPosType]

    UIHelper.HideAllChildren(self.LayoutFilterSection01)
    UIHelper.HideAllChildren(self.LayoutFilterSection02)

    for i = 1, 2, 1 do
        local tbTag = tbTags[i]
        if i == 1 then
            self.tbCell1 = self.tbCell1 or {}
            for j, szName in ipairs(tbTag) do
                if not self.tbCell1[j] then
                    self.tbCell1[j] = UIHelper.AddPrefab(PREFAB_ID.WidgetExpertFilterTagCell, self.LayoutFilterSection01)
                    UIHelper.ToggleGroupAddToggle(self.TogGroupTag1, self.tbCell1[j].TogCell)
                end
                self.tbCell1[j]:OnEnter(szName, true, function ()
                    local szNewTags = self:GetCurTagsString()
                    self:SetCurTagsString(szNewTags)
                end)
                UIHelper.SetVisible(self.tbCell1[j]._rootNode, true)
            end
            UIHelper.SetVisible(self.WidgetSection01, #tbTag > 0)
        elseif i == 2 then
            self.tbCell2 = self.tbCell2 or {}
            for j, szName in ipairs(tbTag) do
                if not self.tbCell2[j] then
                    self.tbCell2[j] = UIHelper.AddPrefab(PREFAB_ID.WidgetExpertFilterTagCell, self.LayoutFilterSection02)
                end
                self.tbCell2[j]:OnEnter(szName, false, function ()
                    local szNewTags = self:GetCurTagsString()
                    self:SetCurTagsString(szNewTags)
                end)
                UIHelper.SetVisible(self.tbCell2[j]._rootNode, true)
            end
            UIHelper.SetVisible(self.WidgetSection02, #tbTag > 0)
        end
    end

    UIHelper.LayoutDoLayout(self.LayoutFilterSection01)
    UIHelper.LayoutDoLayout(self.LayoutFilterSection02)
    UIHelper.LayoutDoLayout(self.LayoutContent)

    if not self.nCurTag then
        self:SetCurTagsString(tbTags["Default"])
    end
end

function UISetCodeUploadView:GetCurTagsString()
    local nPosType = PlayerKungfuPosition[EquipCodeData.dwCurKungfuID] or KUNGFU_POSITION.DPS
    local tbTags = PlayerKungfuPosition2EquipTags[nPosType]

    local szTag = ""
    for i = 1, 2, 1 do
        local tbTag = tbTags[i]
        if i == 1 then
            self.tbCell1 = self.tbCell1 or {}
            for j, szName in ipairs(tbTag) do
                if self.tbCell1[j] then
                    local bSelected = UIHelper.GetSelected(self.tbCell1[j].TogCell)
                    if bSelected then
                        szTag = szName
                        break
                    end
                end
            end
        elseif i == 2 then
            self.tbCell2 = self.tbCell2 or {}
            for j, szName in ipairs(tbTag) do
                if self.tbCell2[j] then
                    local bSelected = UIHelper.GetSelected(self.tbCell2[j].TogCell)
                    if bSelected then
                        if szTag ~= "" then
                            szTag = szTag .. "," .. szName
                        else
                            szTag = szName
                        end
                    end
                end
            end
        end
    end

    return szTag
end

function UISetCodeUploadView:SetCurTagsString(szTags)
    if szTags == self.nCurTag then
        return
    end

    self.nCurTag = szTags
    local tbCurTags = string.split(self.nCurTag, ",")

    local nPosType = PlayerKungfuPosition[EquipCodeData.dwCurKungfuID] or KUNGFU_POSITION.DPS
    local tbTags = PlayerKungfuPosition2EquipTags[nPosType]

    for i = 1, 2, 1 do
        local tbTag = tbTags[i]
        if i == 1 then
            self.tbCell1 = self.tbCell1 or {}
            local nSelectedIndex = -1
            for j, szName in ipairs(tbTag) do
                if table.contain_value(tbCurTags, szName) then
                    nSelectedIndex = j - 1
                    break
                end
            end
            if nSelectedIndex ~= -1 then
                UIHelper.SetToggleGroupSelected(self.TogGroupTag1, nSelectedIndex)
            end
        elseif i == 2 then
            self.tbCell2 = self.tbCell2 or {}
            for j, szName in ipairs(tbTag) do
                if table.contain_value(tbCurTags, szName) then
                    if self.tbCell2[j] then
                        UIHelper.SetSelected(self.tbCell2[j].TogCell, true)
                    end
                end
            end
        end
    end
end


return UISetCodeUploadView