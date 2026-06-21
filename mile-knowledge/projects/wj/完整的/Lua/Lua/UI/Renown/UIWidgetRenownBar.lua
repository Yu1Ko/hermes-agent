local UIWidgetRenownBar = class("UIWidgetRenownBar")


function UIWidgetRenownBar:OnEnter(nDlcID, tStat, fCallBack)
    if not self.bInit then
        self:RegEvent()
        self:BindUIEvent()
        self.bInit = true
    end

    self.nDlcID = nDlcID
    self.fCallBack = fCallBack
    self:UpdateInfo(nDlcID, tStat)
end

function UIWidgetRenownBar:OnExit()
    self.bInit = false
end

function UIWidgetRenownBar:BindUIEvent()
    UIHelper.BindUIEvent(self.ToggleSelect, EventType.OnSelectChanged, function (_, bSelected)
        if bSelected then
            self.fCallBack()
        end
    end)
end

function UIWidgetRenownBar:RegEvent()
end

function UIWidgetRenownBar:UpdateInfo(nDlcID, tStat)
    local szName = UIHelper.GBKToUTF8(Table_GetDLCInfo(nDlcID).szDLCName)
    local szDlcName = nDlcID == 0 and g_tStrings.STR_ALL_FORCE_REPUTATIONS or szName
    local szStat = string.format("%d/%d", tStat[1], tStat[2])

    UIHelper.SetString(self.LabelUsualTitle, szDlcName)
    UIHelper.SetString(self.LabelBrightTitle, szDlcName)
    UIHelper.SetString(self.LabelUsualNum, szStat)
    UIHelper.SetString(self.LabelBrightNum, szStat)
end

return UIWidgetRenownBar