-- ---------------------------------------------------------------------------------
-- Author: Unknown
-- Name: UIHomelandBuildLockView
-- Date: 2024-03-07 10:40:34
-- Desc: ?
-- ---------------------------------------------------------------------------------

local UIHomelandBuildLockView = class("UIHomelandBuildLockView")

function UIHomelandBuildLockView:OnEnter(szTitle, funcClickCallback)
    if not self.bInit then
        self:RegEvent()
        self:BindUIEvent()
        self.bInit = true
    end

    self.szTitle = szTitle
    self.funcClickCallback = funcClickCallback

    self.szPassword = ""
    self:UpdateInfo()

    UIHelper.PlayAni(self, self.AniAll, "AniInput")

    -- UIHelper.PlayAni(self, self.AniAll, "AniJieSuo")
end

function UIHomelandBuildLockView:OnExit()
    self.bInit = false
end

function UIHomelandBuildLockView:BindUIEvent()
    UIHelper.BindUIEvent(self.BtnClose, EventType.OnClick, function()
        UIMgr.Close(self)
    end)

    UIHelper.BindUIEvent(self.BtnUnlock, EventType.OnClick, function()
        if self.funcClickCallback then
            local tbPassword = {}
            for i = 1, string.len(self.szPassword), 1 do
                local szDigit = string.sub(self.szPassword, i, i)
                local nNum = tonumber(szDigit)
                table.insert(tbPassword, nNum)
            end
            self.funcClickCallback(tbPassword)
        end
        UIMgr.Close(self)
    end)

    if Platform.IsWindows then
        UIHelper.RegisterEditBoxEnded(self.EditBoxPassword, function()
            self:OnEditText()
        end)
    else
        UIHelper.RegisterEditBoxReturn(self.EditBoxPassword, function()
            self:OnEditText()
        end)
    end
end

function UIHomelandBuildLockView:RegEvent()
    Event.Reg(self, EventType.OnGameNumKeyboardClose, function (editBox, nCurNum)
        if editBox == self.EditBoxPassword then
            self:OnEditText()
        end
    end)
end

function UIHomelandBuildLockView:UpdateInfo()
    UIHelper.SetString(self.LabelTitleName, self.szTitle)

    for _, label in ipairs(self.tbLabelPassword) do
        UIHelper.SetVisible(label, false)
    end

    self:UpdateBtnState()
end

function UIHomelandBuildLockView:UpdateBtnState()
    if string.is_nil(self.szPassword) then
        UIHelper.SetButtonState(self.BtnUnlock, BTN_STATE.Disable, "请先输入4位数字")
    else
        UIHelper.SetButtonState(self.BtnUnlock, BTN_STATE.Normal)
    end
end

function UIHomelandBuildLockView:OnEditText()
    local szPassword = UIHelper.GetString(self.EditBoxPassword)
    local tbNum = {}
    for i = 1, #szPassword, 1 do
        local szNum = string.sub(szPassword, i, i)
        local nNum = tonumber(szNum)
        if nNum then
            table.insert(tbNum, szNum)
        end
    end
    if #tbNum ~= 4 then
        TipsHelper.ShowNormalTip("请正确输入4位数字")
        UIHelper.SetString(self.EditBoxPassword, "")
        return
    end

    -- 使用label列表来展现密码
    for i, label in ipairs(self.tbLabelPassword) do
        UIHelper.SetString(label, tbNum[i])
        UIHelper.SetVisible(label, true)
    end
    self.szPassword = szPassword
    UIHelper.SetString(self.EditBoxPassword, "")
    self:UpdateBtnState()
end

return UIHomelandBuildLockView