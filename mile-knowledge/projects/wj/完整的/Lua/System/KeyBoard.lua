-- 移动端是否支持键盘
local MOBILE_SUPPORT_KEYBOARD = true

local tbCCKeyCode2Name = {}
local tbCCKeyName2Code =
{
    ["Tab"] = cc.KeyCode.KEY_TAB,
    ["BackTAB"] = cc.KeyCode.KEY_BACK_TAB,
    ["Backspace"] = cc.KeyCode.KEY_BACKSPACE,
    ["Enter"] = cc.KeyCode.KEY_ENTER,
    ["Shift"] = cc.KeyCode.KEY_SHIFT,
    ["Ctrl"] = cc.KeyCode.KEY_CTRL,
    ["Alt"] =  cc.KeyCode.KEY_ALT,
    ["CapLock"] = cc.KeyCode.KEY_CAPS_LOCK,
    ["Esc"] = cc.KeyCode.KEY_ESCAPE,
    ["Space"] = cc.KeyCode.KEY_SPACE,
    ["PageUp"] = cc.KeyCode.KEY_PG_UP,
    ["PageDown"] = cc.KeyCode.KEY_PG_DOWN,
    ["End"] = cc.KeyCode.KEY_END,
    ["Home"] = cc.KeyCode.KEY_HOME,
    ["Left"] = cc.KeyCode.KEY_LEFT_ARROW,
    ["Up"] = cc.KeyCode.KEY_UP_ARROW,
    ["Right"] = cc.KeyCode.KEY_RIGHT_ARROW,
    ["Down"] = cc.KeyCode.KEY_DOWN_ARROW,
    ["Insert"] = cc.KeyCode.KEY_INSERT,
    ["Delete"] = cc.KeyCode.KEY_DELETE,
    ["0"] = cc.KeyCode.KEY_0,
    ["1"] = cc.KeyCode.KEY_1,
    ["2"] = cc.KeyCode.KEY_2,
    ["3"] = cc.KeyCode.KEY_3,
    ["4"] = cc.KeyCode.KEY_4,
    ["5"] = cc.KeyCode.KEY_5,
    ["6"] = cc.KeyCode.KEY_6,
    ["7"] = cc.KeyCode.KEY_7,
    ["8"] = cc.KeyCode.KEY_8,
    ["9"] = cc.KeyCode.KEY_9,
    ["A"] = cc.KeyCode.KEY_A,
    ["B"] = cc.KeyCode.KEY_B,
    ["C"] = cc.KeyCode.KEY_C,
    ["D"] = cc.KeyCode.KEY_D,
    ["E"] = cc.KeyCode.KEY_E,
    ["F"] = cc.KeyCode.KEY_F,
    ["G"] = cc.KeyCode.KEY_G,
    ["H"] = cc.KeyCode.KEY_H,
    ["I"] = cc.KeyCode.KEY_I,
    ["J"] = cc.KeyCode.KEY_J,
    ["K"] = cc.KeyCode.KEY_K,
    ["L"] = cc.KeyCode.KEY_L,
    ["M"] = cc.KeyCode.KEY_M,
    ["N"] = cc.KeyCode.KEY_N,
    ["O"] = cc.KeyCode.KEY_O,
    ["P"] = cc.KeyCode.KEY_P,
    ["Q"] = cc.KeyCode.KEY_Q,
    ["R"] = cc.KeyCode.KEY_R,
    ["S"] = cc.KeyCode.KEY_S,
    ["T"] = cc.KeyCode.KEY_T,
    ["U"] = cc.KeyCode.KEY_U,
    ["V"] = cc.KeyCode.KEY_V,
    ["W"] = cc.KeyCode.KEY_W,
    ["X"] = cc.KeyCode.KEY_X,
    ["Y"] = cc.KeyCode.KEY_Y,
    ["Z"] = cc.KeyCode.KEY_Z,
    ["Num0"] = cc.KeyCode.KEY_NUM_0,
    ["Num1"] = cc.KeyCode.KEY_NUM_1,
    ["Num2"] = cc.KeyCode.KEY_NUM_2,
    ["Num3"] = cc.KeyCode.KEY_NUM_3,
    ["Num4"] = cc.KeyCode.KEY_NUM_4,
    ["Num5"] = cc.KeyCode.KEY_NUM_5,
    ["Num6"] = cc.KeyCode.KEY_NUM_6,
    ["Num7"] = cc.KeyCode.KEY_NUM_7,
    ["Num8"] = cc.KeyCode.KEY_NUM_8,
    ["Num9"] = cc.KeyCode.KEY_NUM_9,
    ["F1"] = cc.KeyCode.KEY_F1,
    ["F2"] = cc.KeyCode.KEY_F2,
    ["F3"] = cc.KeyCode.KEY_F3,
    ["F4"] = cc.KeyCode.KEY_F4,
    ["F5"] = cc.KeyCode.KEY_F5,
    ["F6"] = cc.KeyCode.KEY_F6,
    ["F7"] = cc.KeyCode.KEY_F7,
    ["F8"] = cc.KeyCode.KEY_F8,
    ["F9"] = cc.KeyCode.KEY_F9,
    ["F10"] = cc.KeyCode.KEY_F10,
    ["F11"] = cc.KeyCode.KEY_F11,
    ["F12"] = cc.KeyCode.KEY_F12,
    ["OEM1"] = cc.KeyCode.OEM1, -- ';:' for US
    ["OEMPlus"] = cc.KeyCode.OEMPlus, -- '+' any country
    ["OEMComma"] = cc.KeyCode.OEMComma, -- ',' any country
    ["OEMMinus"] = cc.KeyCode.OEMMinus, -- '-' any country
    ["OEMPeriod"] = cc.KeyCode.OEMPeriod, -- '.' any country
    ["LBracket"] = cc.KeyCode.KEY_LEFT_BRACKET, -- '[' any country
    ["RBracket"] = cc.KeyCode.KEY_RIGHT_BRACKET, -- ']' any country
    ["OEM2"] = cc.KeyCode.OEM2, -- '/?' for US
    ["OEM3"] = cc.KeyCode.OEM3, -- '`~' for US
    ["KPPlus"] = cc.KeyCode.KEY_KP_PLUS, -- '+' any country
    ["KPMinus"] = cc.KeyCode.KEY_KP_MINUS, -- '-' any country

    --MouseButton
    ["LButton"] = cc.KeyCode.LButton,
    ["RButton"] = cc.KeyCode.RButton,
    ["MButton"] = cc.KeyCode.MButton,
    ["XButton1"] = cc.KeyCode.XButton1,
    ["XButton2"] = cc.KeyCode.XButton2,
    ["MouseWheelUp"] = cc.KeyCode.MouseWheelUp,
    ["MouseWheelDown"] = cc.KeyCode.MouseWheelDown,
}

KeyBoard = {}
local self = KeyBoard

function KeyBoard.Init()
    if Platform.IsMobile() and not KeyBoard.MobileSupportKeyboard() then
        return
    end

    -- 设置界面会忽略按键，这里做白名单处理 18:Alt，37:→, 38:↑, 39:←, 40:↓，120:F9
    self.tbIngoreOnGameSetting = {} --Config.bGM and {18, 37, 38, 39, 40, 120} or {} --可用GM命令禁用

    self.mapHotKey = {}
    self.listHotKey = {}

    self.mapKeyDownToIndex = {}
    self.listKeyDownKeyCodes = {}
    self.nKeyDownCount = 0

    self.bEnable = true
    self.bEnableGameSetting = false
    self.tbIgnoreOnDisable = {}
    self.bKeyOrder = false --组合键顺序要求

    self.tbKeyDown = {}

    self.bCustom = false

    for k, v in pairs(tbCCKeyName2Code) do
        tbCCKeyCode2Name[v] = k
    end

    Event.Reg(self, EventType.SetKeyBoardEnable, function(bEnable, tbIgnoreOnDisable)
        self.bEnable = bEnable
        self.tbIgnoreOnDisable = tbIgnoreOnDisable or {}
    end)

    Event.Reg(self, EventType.SetKeyBoardGameSettingEnable, function(bEnable)
        self.bEnableGameSetting = bEnable
        if not bEnable then
            self.nKeyDownCount = 0
            self.mapKeyDownToIndex = {}
            self.listKeyDownKeyCodes = {}
            self.tbKeyDown = {}
        end
    end)

    Event.Reg(self, EventType.SetKeyBoardEnableByCustomState, function(bCustom)
        self.bCustom = bCustom
    end)

    Event.Reg(self, "OnCCKeyUp", function(nKeyCode)
        if not self._check(nKeyCode) or self.bCustom then return end

        local szKeyName = tbCCKeyCode2Name[nKeyCode]
        if szKeyName then
           -- LOG.DEBUG("[KeyBoard] Up\t\t%s", szKeyName)
            self.CheckPauseGamepadInput(nKeyCode)
            
            if self.bEnableGameSetting and not table.contain_value(self.tbIngoreOnGameSetting, nKeyCode) then
                Event.Dispatch(EventType.OnKeyboardUpForGameSetting, nKeyCode, szKeyName)
            else
                self._handleKeyBoardEvent(nKeyCode, false)
                Event.Dispatch(EventType.OnKeyboardUp, nKeyCode, szKeyName)
            end
            self.tbKeyDown[nKeyCode] = false
        end
    end)

    Event.Reg(self, "OnCCKeyDown", function(nKeyCode)
        if not self._check(nKeyCode) or self.bCustom then return end

        local szKeyName = tbCCKeyCode2Name[nKeyCode]
        if szKeyName then
            self.CheckPauseGamepadInput(nKeyCode)
           -- LOG.DEBUG("[KeyBoard] Down\t%s", szKeyName)
            if self.bEnableGameSetting and not table.contain_value(self.tbIngoreOnGameSetting, nKeyCode) then
                Event.Dispatch(EventType.OnKeyboardDownForGameSetting, nKeyCode, szKeyName)
            else
                self._handleKeyBoardEvent(nKeyCode, true)
                Event.Dispatch(EventType.OnKeyboardDown, nKeyCode, szKeyName)
            end
            self.tbKeyDown[nKeyCode] = true
        end
    end)

    Event.Reg(self, "OnWindowsLostFocus", function()
        self.nKeyDownCount = 0
        self.mapKeyDownToIndex = {}
        self.listKeyDownKeyCodes = {}
        self.tbKeyDown = {}
    end)

    Event.Reg(self, "OnMobileKeyboardConnected", function()
        LOG.INFO("[KeyBoard] OnMobileKeyboardConnected")
        TipsHelper.ShowNormalTip("蓝牙键盘已连接")
    end)

    Event.Reg(self, "OnMobileKeyboardDisConnected", function()
        LOG.INFO("[KeyBoard] OnMobileKeyboardDisConnected")
        TipsHelper.ShowNormalTip("蓝牙键盘已断开")
    end)

    Event.Reg(self, "OnGamepadSimulateCCKeyDown", function(nKeyCode)
        if not self._check(nKeyCode) or self.bCustom then return end
        local szKeyName = tbCCKeyCode2Name[nKeyCode]
        if szKeyName then
            self._handleKeyBoardEvent(nKeyCode, true)
            Event.Dispatch(EventType.OnKeyboardDown, nKeyCode, szKeyName)
            self.tbKeyDown[nKeyCode] = true
        end
    end)

    Event.Reg(self, "OnGamepadSimulateCCKeyUp", function(nKeyCode)
        if not self._check(nKeyCode) or self.bCustom then return end

        local szKeyName = tbCCKeyCode2Name[nKeyCode]
        if szKeyName then
            self._handleKeyBoardEvent(nKeyCode, false)
            Event.Dispatch(EventType.OnKeyboardUp, nKeyCode, szKeyName)
            self.tbKeyDown[nKeyCode] = false
        end
    end)


    if Config.bGM then
        require("Lua/Debug/Hotkey.lua")
    end
end

function KeyBoard.UnInit()

end

function KeyBoard.BindKeyDown(tbKeyCodes, szBindDes, callback)
    if Platform.IsMobile() and not KeyBoard.MobileSupportKeyboard() then
        --LOG.ERROR("KeyBoard.BindKeyDown, only in windows platform.")
        return
    end

    if not IsTable(tbKeyCodes) then
        LOG.ERROR("KeyBoard.BindKeyDown, tbKeyCodes is not table!")
        return
    end

    self._bind(tbKeyCodes, szBindDes, callback, true)
end

function KeyBoard.UnBindKeyDown(tbKeyCodes)
    if Platform.IsMobile() and not KeyBoard.MobileSupportKeyboard() then
        --LOG.ERROR("KeyBoard.UnBindKeyDown, only in windows platform.")
        return
    end

    self._unbind(tbKeyCodes, true)
end

function KeyBoard.BindKeyUp(nKeyCode, szBindDes, callback)
    if Platform.IsMobile() and not KeyBoard.MobileSupportKeyboard() then
        --LOG.ERROR("KeyBoard.BindKeyUp, only in windows platform.")
        return
    end

    if not IsNumber(nKeyCode) then
        LOG.ERROR("KeyBoard.BindKeyUp, nKeyCode is not a number!")
        return
    end

    self._bind({nKeyCode}, szBindDes, callback, false)
end

function KeyBoard.UnBindKeyUp(nKeyCode)
    if Platform.IsMobile() and not KeyBoard.MobileSupportKeyboard() then
        --LOG.ERROR("KeyBoard.UnBindKeyUp, only in windows platform.")
        return
    end

    self._unbind({nKeyCode}, false)
end

function KeyBoard.GetKeyCodeFromName(szName)
    return tbCCKeyName2Code[szName]
end

function KeyBoard.IsKeyDown(nKeyCode)
    if Platform.IsMobile() and not KeyBoard.MobileSupportKeyboard() then
        return false
    end

    return nKeyCode and self.tbKeyDown[nKeyCode]
end

function KeyBoard.GetKeyName(keyCode)
    return tbCCKeyCode2Name[keyCode]
end

-- 移动端是否支持键盘
function KeyBoard.MobileSupportKeyboard()
    return MOBILE_SUPPORT_KEYBOARD
end

-- 移动端是否连接了键盘
function KeyBoard.MobileHasKeyboard()
    if not KeyBoard.MobileSupportKeyboard() then
        return false
    end

    return IsMobileConnectKeyboard()
end

function KeyBoard.CheckPauseGamepadInput(nKeyCode)
    if  nKeyCode == cc.KeyCode.LButton or 
        nKeyCode == cc.KeyCode.RButton or 
        nKeyCode == cc.KeyCode.MButton or 
        nKeyCode == cc.KeyCode.XButton1 or 
        nKeyCode == cc.KeyCode.XButton2 or 
        nKeyCode == cc.KeyCode.MouseWheelUp or 
        nKeyCode == cc.KeyCode.MouseWheelDown then    
        return
    end
    GamepadData.PauseInput()
end

function KeyBoard._handleKeyBoardEvent(nKeyCode, bIsKeyDown)
    if bIsKeyDown then
        self.nKeyDownCount = self.nKeyDownCount + 1
        self.mapKeyDownToIndex[nKeyCode] = self.nKeyDownCount
        table.insert(self.listKeyDownKeyCodes, nKeyCode)

        --self._excute(self.listKeyDownKeyCodes, true)

        if #self.listKeyDownKeyCodes == 1 then
            self._excute(self.listKeyDownKeyCodes, true)
        elseif not self._isCombinationKey(nKeyCode) then
            local tbKeyCodes = {nKeyCode}
            for i, c in ipairs(self.listKeyDownKeyCodes) do
                if self._isCombinationKey(c) then
                    table.insert(tbKeyCodes, c)
                end
            end
            self._excute(tbKeyCodes, true)
        end
    else
        local nIndex = self.mapKeyDownToIndex[nKeyCode]
        if not nIndex then return end

        for i, c in ipairs(self.listKeyDownKeyCodes) do
            if c == nKeyCode then
                table.remove(self.listKeyDownKeyCodes, i)
                break
            end
        end

        --table.remove(self.listKeyDownKeyCodes, nIndex)
        self.mapKeyDownToIndex[nKeyCode] = nil
        self.nKeyDownCount = self.nKeyDownCount - 1

        self._excute({nKeyCode}, false)
    end
end

function KeyBoard._isCombinationKey(nKeyCode)
    return nKeyCode == cc.KeyCode.KEY_CTRL or nKeyCode == cc.KeyCode.KEY_ALT or nKeyCode == cc.KeyCode.KEY_SHIFT
end

function KeyBoard._bind(tbKeyCodes, szBindDes, callback, bIsKeyDown)
    if not IsTable(tbKeyCodes) then
        return
    end

    if table.get_len(tbKeyCodes) == 0 then
        return
    end

    local szKeyCodeValue, szKeyCodeName = self._getKeyCodeString(tbKeyCodes, bIsKeyDown)

    --print("[KeyBoard] BindKey", szKeyCodeName, debug.traceback())

    -- 冲突检测，有冲突的时候还是会让你加进去，但是会覆盖之前的
    if self._isExist(tbKeyCodes, bIsKeyDown) then
        --LOG.ERROR(string.format("KeyBoard._bind, [%s] has already been registered!", tostring(szKeyCodeName)))
        print(string.format("KeyBoard._bind, [%s] has already been registered!", tostring(szKeyCodeName)))
    end

    local tbHotKey =
    {
        ["szKeyCodeValue"] = szKeyCodeValue,
        ["szKeyCodeName"] = szKeyCodeName,
        ["szBindDes"] = szBindDes,
        ["tbKeyCodes"] = tbKeyCodes,
        ["callback"] = callback,
        ["bIsKeyDown"] = bIsKeyDown,
    }

    self.mapHotKey[szKeyCodeValue] = tbHotKey
    table.insert(self.listHotKey, tbHotKey)
end

function KeyBoard._unbind(tbKeyCodes, bIsKeyDown)
    if IsTable(tbKeyCodes) then
        local szKeyCodeValue = self._getKeyCodeString(tbKeyCodes, bIsKeyDown)
        self.mapHotKey[szKeyCodeValue] = nil
    end
end

function KeyBoard._getKeyCodeString(tbKeyCodes, bIsKeyDown)
    local szKeyCodeValue = ""
    local szKeyCodeName = ""
    local nLen = tbKeyCodes and #tbKeyCodes or 0
    local szType = bIsKeyDown and "Down" or "Up"

    if not self.bKeyOrder then
        table.sort(tbKeyCodes)
    end

    for k, v in ipairs(tbKeyCodes or {}) do
        if string.is_nil(szKeyCodeValue) then
            szKeyCodeValue = v
        else
            szKeyCodeValue = string.format("%s,%s", szKeyCodeValue, v)
        end
        if string.is_nil(szKeyCodeName) then
            szKeyCodeName = self._getKeyCodeNameByValue(v)
        else
            szKeyCodeName = string.format("%s,%s", szKeyCodeName, self._getKeyCodeNameByValue(v))
        end
    end

    szKeyCodeValue = string.format("[%s]%s", szType, szKeyCodeValue)
    szKeyCodeName = string.format("[%s]%s", szType, szKeyCodeName)

    return szKeyCodeValue, szKeyCodeName
end

function KeyBoard._getKeyCodeNameByValue(nKeyCode)
    return tbCCKeyCode2Name[nKeyCode]
end

-- 快捷键是否已经被注册
function KeyBoard._isExist(tbKeyCodes, bIsKeyDown)
    local bResult = false

    local szKeyCodeValue, szKeyCodeName = self._getKeyCodeString(tbKeyCodes, bIsKeyDown)

    -- 冲突检测
    if self.mapHotKey[szKeyCodeValue] ~= nil then
        bResult = true
    end

    return bResult
end

function KeyBoard._getHotKeyByKeyCodes(tbKeyCodes, bIsKeyDown)
    local szKeyCodeValue = self._getKeyCodeString(tbKeyCodes, bIsKeyDown)
    local tbHotKey = self.mapHotKey[szKeyCodeValue]

    return tbHotKey
end

function KeyBoard._excute(tbKeyCodes, bIsKeyDown)
    --print("KeyBoard._excute", select(2, self._getKeyCodeString(tbKeyCodes, bIsKeyDown)))
    local tbHotKey = self._getHotKeyByKeyCodes(tbKeyCodes, bIsKeyDown)
    if tbHotKey == nil then
        --LOG.ERROR("KeyBoard._excute, tbHotKey is nil!")
        return
    end

    local szKeyCodeValue = tbHotKey.szKeyCodeValue
    local szKeyCodeName = tbHotKey.szKeyCodeName or ""
    local szBindDes = tbHotKey.szBindDes or ""
    local tbKeyCodes = tbHotKey.tbKeyCodes
    local callback = tbHotKey.callback
    local bIsKeyDown = tbHotKey.bIsKeyDown

    if not IsFunction(callback) then
        LOG.ERROR("self._excute, callback is not function!")
        return
    end

    callback()

    -- LOG.INFO(string.format("self._excute, hotkey %s[%s] excute success", szBindDes, szKeyCodeName))
end

function KeyBoard._check(nKeyCode)
    if self.bEnable then
        return true
    end

    if tbCCKeyCode2Name[nKeyCode] then
        if table.contain_value(self.tbIgnoreOnDisable, nKeyCode) then
            return true
        end
    end

    return false
end