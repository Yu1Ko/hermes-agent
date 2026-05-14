-- ---------------------------------------------------------------------------------
-- Author: Unknown
-- Name: UIInstrumentPlayerTipsCell
-- Date: 2023-10-18 19:59:01
-- Desc: ?
-- ---------------------------------------------------------------------------------

local UIInstrumentPlayerTipsCell = class("UIInstrumentPlayerTipsCell")

function UIInstrumentPlayerTipsCell:OnEnter(tbData)
    self.tbData = tbData

    if not self.bInit then
        self:RegEvent()
        self:BindUIEvent()
        self.bInit = true
    end

    self:UpdateInfo()
end

function UIInstrumentPlayerTipsCell:OnExit()
    self.bInit = false
end

function UIInstrumentPlayerTipsCell:BindUIEvent()
    UIHelper.BindUIEvent(self.ToggleSelectMusic, EventType.OnSelectChanged, function (_, bSelected)
        if self.funcCallback then
            self.funcCallback(bSelected)
        end
    end)
end

function UIInstrumentPlayerTipsCell:RegEvent()
    --Event.Reg(self, EventType.XXX, func)
end

function UIInstrumentPlayerTipsCell:UpdateInfo()
    local tbData = self.tbData
    local szFileName = tbData.szFileName
    local szName = szFileName and szFileName or "未知曲谱"
    local szMaxTime = InstrumentData.GetMaxTime(tbData)
    local szTitle = Table_GetInstrumentName(tbData.szType or "sanxian")
    if szTitle and szTitle ~= "" then
        szTitle = UIHelper.GBKToUTF8(szTitle)
        szTitle = "(" .. szTitle .. ")"
    end
    UIHelper.SetString(self.LabelConfirmType, szTitle)
    UIHelper.SetString(self.LabelConfirmType2, szTitle)
    UIHelper.SetString(self.LabelConfirm1, szName)
    UIHelper.SetString(self.LabelConfirm2, szMaxTime)
    UIHelper.SetString(self.LabelConfirm1_Up, szName)
    UIHelper.SetString(self.LabelConfirm2_Up, szMaxTime)
end

function UIInstrumentPlayerTipsCell:SetSelectedCallback(funcCallback)
    self.funcCallback = funcCallback
end

function UIInstrumentPlayerTipsCell:SetToggleGroupIndex(nIndex)
    UIHelper.SetToggleGroupIndex(self.ToggleSelectMusic, nIndex)
end

function UIInstrumentPlayerTipsCell:SetSelected(bSelected)
    UIHelper.SetSelected(self.TogBluePrintListCell, bSelected)
end

return UIInstrumentPlayerTipsCell