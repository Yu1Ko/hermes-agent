-- ---------------------------------------------------------------------------------
-- Author: Unknown
-- Name: UIInstrumentSaveMusicPop
-- Date: 2025-07-13 16:32:18
-- Desc: ?
-- ---------------------------------------------------------------------------------
local nMaxNum = 8
local UIInstrumentSaveMusicPop = class("UIInstrumentSaveMusicPop")

function UIInstrumentSaveMusicPop:OnEnter(bLocal, fnCallBack)
    if not self.bInit then
        self:RegEvent()
        self:BindUIEvent()
        self.bInit = true
    end
    self.bLocal = bLocal
    self.fnCallBack = fnCallBack
    if bLocal then
        UIHelper.SetString(self.LabelPrint, "保存")
        UIHelper.SetString(self.LabelTitle, "保存曲谱到本地")
        UIHelper.SetVisible(self.LabelBluePrintCodeTip, false)
    end
    self:UpdateInfo()
end

function UIInstrumentSaveMusicPop:OnExit()
    self.bInit = false
    self:UnRegEvent()
end

function UIInstrumentSaveMusicPop:BindUIEvent()
    UIHelper.RegisterEditBoxChanged(self.EditBox, function()
        self:UpdateInfo()
    end)

    UIHelper.BindUIEvent(self.BtnClose, EventType.OnClick, function(btn)
        UIMgr.Close(self)
    end)

    UIHelper.BindUIEvent(self.BtnCancel, EventType.OnClick, function(btn)
        UIMgr.Close(self)
    end)

    UIHelper.BindUIEvent(self.BtnPrint, EventType.OnClick, function(btn)
        if self.fnCallBack then
            self.fnCallBack(UIHelper.GetText(self.EditBox))
        end
    end)
end

function UIInstrumentSaveMusicPop:RegEvent()
    --Event.Reg(self, EventType.XXX, func)
end

function UIInstrumentSaveMusicPop:UnRegEvent()
    --Event.UnReg(self, EventType.XXX)
end






-- ----------------------------------------------------------
-- Please write your own code below  ↓↓↓
-- ----------------------------------------------------------

function UIInstrumentSaveMusicPop:UpdateInfo()
    local szText = UIHelper.GetText(self.EditBox) or ""
    local szLimit = "%d/%d"
    if szText and UIHelper.GetUtf8Len(szText) > nMaxNum then
        szText = UIHelper.GetUtf8SubString(szText, 1, nMaxNum)
        UIHelper.SetText(self.EditBox, szText)
    end
    UIHelper.SetString(self.LabelLimit, string.format(szLimit, UIHelper.GetUtf8Len(szText), nMaxNum))
end


return UIInstrumentSaveMusicPop