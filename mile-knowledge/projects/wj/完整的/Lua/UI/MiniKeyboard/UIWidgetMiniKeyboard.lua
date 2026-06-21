-- ---------------------------------------------------------------------------------
-- Author: Unknown
-- Name: UIWidgetMiniKeyboard
-- Date: 2024-02-19 09:59:56
-- Desc: ?
-- ---------------------------------------------------------------------------------

local UIWidgetMiniKeyboard = class("UIWidgetMiniKeyboard")

function UIWidgetMiniKeyboard:OnEnter(EditBox, nMinNum, nMaxNum)
    Event.Dispatch(EventType.OnGameNumKeyboardOpen, EditBox)

    if not self.bInit then
        self:RegEvent()
        self:BindUIEvent()
        self.bInit = true
    end

    self.EditBox = EditBox
    self.bPassWord = safe_check(EditBox) and EditBox:getGameNumKeyboardIsPassword() or false
    self.nMinNum = IsNumber(nMinNum) and nMinNum or (safe_check(EditBox) and EditBox:getGameNumKeyboardMin() or 0)
    self.nMaxNum = IsNumber(nMaxNum) and nMaxNum or (safe_check(EditBox) and EditBox:getGameNumKeyboardMax() or 999999999)
    self.nMaxLen = safe_check(EditBox) and EditBox:getMaxLength() or 20
    if self.nMinNum < 0 then self.nMinNum = 0 end
    if self.nMaxNum < 0 then self.nMaxNum = 999999999 end

    self.nCurNum = 0

    if self.bPassWord then
        self.szNum = ""
    end
    self:UpdateInfo()
end

function UIWidgetMiniKeyboard:OnExit()
    Event.Dispatch(EventType.OnGameNumKeyboardClose, self.EditBox)

    self.bInit = false
    self:UnRegEvent()
end

function UIWidgetMiniKeyboard:BindUIEvent()
    for nIndex, btn in ipairs(self.tbBtnNum) do
        UIHelper.BindUIEvent(btn, EventType.OnClick, function()
            if self.bPassWord then
                self.szNum = self.szNum .. tostring(nIndex - 1)
                UIHelper.SetText(self.EditBox, self.szNum)
                Event.Dispatch(EventType.OnGameNumKeyboardChanged, self.EditBox, self.szNum)
                return 
            end
            local szCurNum = tostring(self.nCurNum)
            local nCurNum = self.nCurNum
            if string.len(szCurNum) < self.nMaxLen then--限制输入长度
                nCurNum = self.nCurNum * 10 + (nIndex - 1)
            end
            if nCurNum >= self.nMaxNum then
                TipsHelper.ShowNormalTip("输入已达最大数量")
            end
            self.nCurNum = math.min(nCurNum, self.nMaxNum)
            if self.nCurNum == 0 then self.nCurNum = self.nMinNum end--不允许输入0个
            UIHelper.SetText(self.EditBox, tostring(self.nCurNum))

            Event.Dispatch(EventType.OnGameNumKeyboardChanged, self.EditBox, self.nCurNum)
        end)
    end

    UIHelper.BindUIEvent(self.BtnCancel, EventType.OnClick, function()
        if self.bPassWord then
            self.szNum = string.sub(self.szNum, 1, -2)
            UIHelper.SetText(self.EditBox, self.szNum)
            Event.Dispatch(EventType.OnGameNumKeyboardChanged, self.EditBox, self.szNum)
            return 
        end

        local nCurNum = tonumber(UIHelper.GetText(self.EditBox)) or 0
        nCurNum = math.floor(nCurNum / 10)
        self.nCurNum = math.max(nCurNum, self.nMinNum)
        UIHelper.SetText(self.EditBox, tostring(self.nCurNum))
        if self.nCurNum == self.nMinNum then self.nCurNum = 0 end--撤销到最小值后，下一次输入覆盖

        Event.Dispatch(EventType.OnGameNumKeyboardChanged, self.EditBox, self.nCurNum)
    end)

    UIHelper.BindUIEvent(self.BtnConfirm, EventType.OnClick, function()
        Event.Dispatch(EventType.OnGameNumKeyboardConfirmed, self.EditBox, self.nCurNum)
        TipsHelper.DeleteHoverTips(PREFAB_ID.WidgetMiniKeyboard)
    end)
end

function UIWidgetMiniKeyboard:RegEvent()
    --Event.Reg(self, EventType.XXX, func)
end

function UIWidgetMiniKeyboard:UnRegEvent()
    --Event.UnReg(self, EventType.XXX)
end






-- ----------------------------------------------------------
-- Please write your own code below  ↓↓↓
-- ----------------------------------------------------------

function UIWidgetMiniKeyboard:UpdateInfo()
    for nIndex, btn in ipairs(self.tbBtnNum) do
        UIHelper.SetTouchDownHideTips(btn, false)
        UIHelper.SetClickInterval(btn, 0)
    end
    UIHelper.SetTouchDownHideTips(self.LayoutKeyboard, false)
    UIHelper.SetTouchDownHideTips(self._rootNode, false)
    UIHelper.SetTouchDownHideTips(self.BtnCancel, false)
    UIHelper.SetTouchDownHideTips(self.BtnConfirm, false)
    UIHelper.SetSwallowTouches(self.BtnNone, true)
    UIHelper.LayoutDoLayout(self.LayoutKeyboard)

    UIHelper.SetClickInterval(self.BtnCancel, 0)
    UIHelper.SetClickInterval(self.BtnConfirm, 0)
end


return UIWidgetMiniKeyboard