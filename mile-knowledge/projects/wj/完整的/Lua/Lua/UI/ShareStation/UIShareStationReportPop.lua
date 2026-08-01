-- ---------------------------------------------------------------------------------
-- Author: Unknown
-- Name: UIShareStationReportPop
-- Date: 2025-07-21 09:43:05
-- Desc: ?
-- ---------------------------------------------------------------------------------

local UIShareStationReportPop = class("UIShareStationReportPop")

function UIShareStationReportPop:OnEnter(bLogin, nDataType, tbData)
    if not self.bInit then
        self:RegEvent()
        self:BindUIEvent()
        self.bInit = true
    end
    self.bLogin = bLogin
    self.nDataType = nDataType
    self.szShareCode = tbData.szShareCode
    self.szReason = nil
    self:UpdateInfo()
end

function UIShareStationReportPop:OnExit()
    self.bInit = false
    self:UnRegEvent()
end

function UIShareStationReportPop:BindUIEvent()
    UIHelper.BindUIEvent(self.BtnAccept, EventType.OnClick, function(btn)
        ShareCodeData.ReportData(self.bLogin, self.nDataType, self.szShareCode, self.szReason)
        UIMgr.Close(self)
    end)

    UIHelper.BindUIEvent(self.BtnCancel, EventType.OnClick, function(btn)
        UIMgr.Close(self)
    end)

    UIHelper.BindUIEvent(self.BtnClose, EventType.OnClick, function(btn)
        UIMgr.Close(self)
    end)
end

function UIShareStationReportPop:RegEvent()
    --Event.Reg(self, EventType.XXX, func)
end

function UIShareStationReportPop:UnRegEvent()
    --Event.UnReg(self, EventType.XXX)
end






-- ----------------------------------------------------------
-- Please write your own code below  ↓↓↓
-- ----------------------------------------------------------

function UIShareStationReportPop:UpdateInfo()
    local tList = Table_GetShareStationReportReason()
    for _, v in ipairs(tList) do
        local scriptCell = UIHelper.AddPrefab(PREFAB_ID.WidgetReportReasonCell, self.ScrollViewReportReasonList)
        UIHelper.SetSelected(scriptCell.TogType, false)
        UIHelper.SetString(scriptCell.LabelTogName, UIHelper.GBKToUTF8(v.szDesc))
        UIHelper.SetToggleGroupIndex(scriptCell.TogType, ToggleGroupIndex.HintSelectModeItem)
        UIHelper.BindUIEvent(scriptCell.TogType, EventType.OnSelectChanged, function(tog, bSelected)
            if not bSelected then
                return
            end
            self.szReason = UIHelper.GBKToUTF8(v.szDesc)
            self:UpdateBtnState()
        end)
    end

    UIHelper.ScrollViewDoLayoutAndToTop(self.ScrollViewReportReasonList)
    self:UpdateBtnState()
end

function UIShareStationReportPop:UpdateBtnState()
    local bEnable = not string.is_nil(self.szReason)
    UIHelper.SetButtonState(self.BtnAccept, bEnable and BTN_STATE.Normal or BTN_STATE.Disable)
end


return UIShareStationReportPop