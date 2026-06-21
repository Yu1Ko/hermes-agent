-- ---------------------------------------------------------------------------------
-- Author: Unknown
-- Name: UIInstrumentPlayerTipsCell_Cloud
-- Date: 2023-10-18 19:59:01
-- Desc: ?
-- ---------------------------------------------------------------------------------

local UIInstrumentPlayerTipsCell_Cloud = class("UIInstrumentPlayerTipsCell_Cloud")

function UIInstrumentPlayerTipsCell_Cloud:OnEnter(tbData, szCode)
    self.tbData = tbData
    self.szCode = szCode
    if not self.bInit then
        self:RegEvent()
        self:BindUIEvent()
        self.bInit = true
    end

    self:UpdateInfo()
end

function UIInstrumentPlayerTipsCell_Cloud:OnExit()
    self.bInit = false
end

function UIInstrumentPlayerTipsCell_Cloud:BindUIEvent()
    UIHelper.SetSwallowTouches(self.BtnCopy, true)
    UIHelper.SetSwallowTouches(self.BtnImport, true)
    UIHelper.BindUIEvent(self.BtnCopy, EventType.OnClick, function (_, bSelected)
        if self.szCode then
            SetClipboard(self.szCode)
        end
        TipsHelper.ShowNormalTip("已复制曲谱码至剪切板")
    end)

    UIHelper.BindUIEvent(self.BtnImport, EventType.OnClick, function () -- 原单个删除，现在改为云端导入曲谱
        if self.funcImportCallBack then
            self.funcImportCallBack()
        end
    end)

    UIHelper.BindUIEvent(self.ToggleSelectMusic, EventType.OnSelectChanged, function (_, bSelected)
        if self.funcCallback then
            self.funcCallback(bSelected)
        end
    end)
end

function UIInstrumentPlayerTipsCell_Cloud:RegEvent()
    --Event.Reg(self, EventType.XXX, func)
end

function UIInstrumentPlayerTipsCell_Cloud:UpdateInfo()
    local tbData = self.tbData
    local szCode = self.szCode
    local szFileName = tbData.szFileName
    local szName = szFileName and szFileName or "未知曲谱"
    local szTitle = Table_GetInstrumentName(tbData.szType or "sanxian")
    if szTitle and szTitle ~= "" then
        szTitle = UIHelper.GBKToUTF8(szTitle)
        szTitle = "(" .. szTitle .. ")"
    end
    UIHelper.SetString(self.LabelConfirmType, szTitle)
    UIHelper.SetString(self.LabelConfirmType2, szTitle)
    UIHelper.SetString(self.LabelConfirm1, szName)
    UIHelper.SetString(self.LabelConfirm2, szCode)
    UIHelper.SetString(self.LabelConfirm1_Up, szName)
    UIHelper.SetString(self.LabelConfirm2_Up, szCode)
end

function UIInstrumentPlayerTipsCell_Cloud:SetSelectedCallback(funcCallback)
    self.funcCallback = funcCallback
end

function UIInstrumentPlayerTipsCell_Cloud:SetImportCallBack(funcCallback)
    self.funcImportCallBack = funcCallback
end

function UIInstrumentPlayerTipsCell_Cloud:SetToggleGroupIndex(nIndex)
    UIHelper.SetToggleGroupIndex(self.ToggleSelectMusic, nIndex)
end

function UIInstrumentPlayerTipsCell_Cloud:SetSelected(bSelected)
    UIHelper.SetSelected(self.ToggleSelectMusic, bSelected)
end

return UIInstrumentPlayerTipsCell_Cloud