-- ---------------------------------------------------------------------------------
-- Author: 陈计
-- Name: UIFactionTransferConfirmView
-- Date: 2024-07-26 15:32:18
-- Desc: 帮会转换阵营提示
-- Prefab: PanelFactionTransferConfirm
-- ---------------------------------------------------------------------------------

---@class UIFactionTransferConfirmView
local UIFactionTransferConfirmView = class("UIFactionTransferConfirmView")

---_LuaBindList 在这里对绑定的组件进行无意义自赋值，从而方便查询以及ide进行智能提示
function UIFactionTransferConfirmView:_LuaBindList()
    self.LabelMessage   = self.LabelMessage --- 提示消息
    self.LabelCountDown = self.LabelCountDown --- 倒计时
    self.BtnSure        = self.BtnSure --- 确定转换的按钮
    self.BtnLeaveGuild  = self.BtnLeaveGuild --- 退出帮会的按钮
end

---_LuaTypeList 在这里添加类型注解，从而方便查询以及ide进行智能提示
function UIFactionTransferConfirmView:_LuaTypeList()
    -- note: 为了方便写的时候IDE也能提示诸如 c++导出的枚举、临时定义的table列表 的字段，可以像下面示例一样，在这里定义对应类型的信息
    -- note: 定义完后在对应变量的定义处通过 ---@type 注解来标注类型即可
    -- note: 具体 class/type/array/table 格式参考 https://emmylua.github.io/annotation.html

    -- ---@class TypeDemo 示例类型
    -- ---@field NumberParam1 number 数字参数一
    -- ---@field StrParm2 string 字符串参数二
end

function UIFactionTransferConfirmView:OnEnter(nCamp, nCountDownTime)
    self.nCamp          = nCamp
    self.nCountDownTime = nCountDownTime

    if not self.bInit then
        self:RegEvent()
        self:BindUIEvent()
        self.bInit = true
        
        self.dwStartTime = GetTickCount()
    end

    self:UpdateInfo()

    Timer.AddFrameCycle(self, 1, function() 
        self:UpdateCountDown()
    end)
end

function UIFactionTransferConfirmView:OnExit()
    self.bInit = false
    self:UnRegEvent()
end

function UIFactionTransferConfirmView:BindUIEvent()
    UIHelper.BindUIEvent(self.BtnSure, EventType.OnClick, function()
        RemoteCallToServer("TongCampReverse", self.nCamp)
        
        LOG.DEBUG("帮会阵营变更提示 选择转换阵容 %d", self.nCamp)
        UIMgr.Close(self)
    end)
    
    UIHelper.BindUIEvent(self.BtnLeaveGuild, EventType.OnClick, function()
        if BankLock.CheckHaveLocked(SAFE_LOCK_EFFECT_TYPE.TONG_OPERATE, "Tong") then
            return
        end
        
        GetTongClient().Quit()
        
        LOG.DEBUG("帮会阵营变更提示 退出帮会")
        UIMgr.Close(self)
    end)
end

function UIFactionTransferConfirmView:RegEvent()
    --Event.Reg(self, EventType.XXX, func)
end

function UIFactionTransferConfirmView:UnRegEvent()
    --Event.UnReg(self, EventType.XXX)
end






-- ----------------------------------------------------------
-- Please write your own code below  ↓↓↓
-- ----------------------------------------------------------

function UIFactionTransferConfirmView:UpdateInfo()
    local szMessage = FormatString(g_tStrings.CAMP_REVERSE_SHOW, g_tStrings.STR_CAMP_TITLE[self.nCamp])
    
    UIHelper.SetString(self.LabelMessage, szMessage)
    
    self:UpdateCountDown()
end

function UIFactionTransferConfirmView:UpdateCountDown()
    local dwTime = GetTickCount() - self.dwStartTime
    if dwTime < self.nCountDownTime * 1000 then
        local nTime = self.nCountDownTime - dwTime/ 1000
        local dwMinutes = nTime / 60 - nTime / 60 % 1
        local dwSeconds = nTime % 60 - nTime % 60 % 1
        
        local szCountDown = FormatString(g_tStrings.CAMP_REVERSE_COUNT_DOWN, dwMinutes .. ":" .. dwSeconds)
        UIHelper.SetString(self.LabelCountDown, szCountDown)
    else
        UIHelper.SetString(self.LabelCountDown, "")

        LOG.DEBUG("帮会阵营变更提示 倒计时到了")
        UIMgr.Close(self)
    end
end

return UIFactionTransferConfirmView