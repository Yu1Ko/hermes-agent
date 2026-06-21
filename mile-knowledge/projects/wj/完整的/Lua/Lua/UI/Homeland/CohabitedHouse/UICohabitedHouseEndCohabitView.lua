-- ---------------------------------------------------------------------------------
-- Author: Unknown
-- Name: UICohabitedHouseEndCohabitView
-- Date: 2023-07-26 15:00:04
-- Desc: ?
-- ---------------------------------------------------------------------------------

local UICohabitedHouseEndCohabitView = class("UICohabitedHouseEndCohabitView")

local MAX_COHABIT_PLAYERS = 3

function UICohabitedHouseEndCohabitView:OnEnter(dwMapID, nCopyIndex, nLandIndex, funcGetStringTerminateCohabitLeftTime)
    if not self.bInit then
        self:RegEvent()
        self:BindUIEvent()
        self.bInit = true
    end

    self.dwMapID = dwMapID
    self.nCopyIndex = nCopyIndex
    self.nLandIndex = nLandIndex
    self.funcGetStringTerminateCohabitLeftTime = funcGetStringTerminateCohabitLeftTime

    self:UpdateInfo()
end

function UICohabitedHouseEndCohabitView:OnExit()
    self.bInit = false
end

function UICohabitedHouseEndCohabitView:BindUIEvent()
    UIHelper.BindUIEvent(self.BtnClose, EventType.OnClick, function ()
        UIMgr.Close(self)
    end)

    UIHelper.BindUIEvent(self.BtnCancel, EventType.OnClick, function ()
        UIMgr.Close(self)
    end)

    UIHelper.BindUIEvent(self.BtnSure, EventType.OnClick, function ()
        if not self.tbSelectedInfo or table.is_empty(self.tbSelectedInfo) then
            return
        end

        if not BankLock.CheckHaveLocked(SAFE_LOCK_EFFECT_TYPE.SHOP) then
            GetHomelandMgr().LandKickOutAllied(self.dwMapID, self.nCopyIndex, self.nLandIndex, self.tbSelectedInfo.PlayerID, false)
        end

        UIMgr.Close(self)
    end)
end

function UICohabitedHouseEndCohabitView:RegEvent()
    --Event.Reg(self, EventType.XXX, func)
end

function UICohabitedHouseEndCohabitView:UpdateInfo()
    local aCohabitPlayerInfos = GetHomelandMgr().GetLandAlliedInfo(self.dwMapID, self.nCopyIndex, self.nLandIndex)
	aCohabitPlayerInfos = aCohabitPlayerInfos or {}

    self.tbCells = self.tbCells or {}
    for i = 1, MAX_COHABIT_PLAYERS do
        local tbInfo = aCohabitPlayerInfos[i]
        if tbInfo then
            if not self.tbCells[i] then
                self.tbCells[i] = UIHelper.AddPrefab(PREFAB_ID.WidgetHouseholdEndPopCell, self.LayoutRoleName)
                UIHelper.ToggleGroupAddToggle(self.TogGroupRoleName, self.tbCells[i].TogRoleName)
            end
            self.tbCells[i]:OnEnter(tbInfo, self.funcGetStringTerminateCohabitLeftTime, function (tbSelectedInfo)
                self.tbSelectedInfo = tbSelectedInfo
                self:UpdateBtnState()
            end)

            -- if not self.tbSelectedInfo and (not tbInfo.KickOutTime or tbInfo.KickOutTime <= 0) then
            --     self.tbSelectedInfo = tbInfo
            --     self:UpdateBtnState()
            -- end
        end
    end

    for _, cell in ipairs(self.tbCells) do
        UIHelper.SetSelected(cell.TogRoleName, false)
    end

    UIHelper.LayoutDoLayout(self.LayoutRoleName)

    self:UpdateBtnState()
end

function UICohabitedHouseEndCohabitView:UpdateBtnState()
    if self.tbSelectedInfo then
        UIHelper.SetButtonState(self.BtnSure, BTN_STATE.Normal)
    else
        UIHelper.SetButtonState(self.BtnSure, BTN_STATE.Disable, "请先选择需要请离的门客")
    end
end


return UICohabitedHouseEndCohabitView