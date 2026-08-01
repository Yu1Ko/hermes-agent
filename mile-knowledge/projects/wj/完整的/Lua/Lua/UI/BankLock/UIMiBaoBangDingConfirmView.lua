-- ---------------------------------------------------------------------------------
-- Author: 陈计
-- Name: UIMiBaoBangDingConfirmView
-- Date: 2024-04-13 17:23:09
-- Desc: 玲珑密保锁绑定设备确认框
-- Prefab: PanelMiBaoBangDingConfirm
-- ---------------------------------------------------------------------------------

---@class UIMiBaoBangDingConfirmView
local UIMiBaoBangDingConfirmView = class("UIMiBaoBangDingConfirmView")

---_LuaBindList 在这里对绑定的组件进行无意义自赋值，从而方便查询以及ide进行智能提示
function UIMiBaoBangDingConfirmView:_LuaBindList()
    self.BtnCalloff = self.BtnCalloff --- 取消
    self.BtnOk      = self.BtnOk --- 确认授权
end

---_LuaTypeList 在这里添加类型注解，从而方便查询以及ide进行智能提示
function UIMiBaoBangDingConfirmView:_LuaTypeList()
    -- note: 为了方便写的时候IDE也能提示诸如 c++导出的枚举、临时定义的table列表 的字段，可以像下面示例一样，在这里定义对应类型的信息
    -- note: 定义完后在对应变量的定义处通过 ---@type 注解来标注类型即可
    -- note: 具体 class/type/array/table 格式参考 https://emmylua.github.io/annotation.html

    -- ---@class TypeDemo 示例类型
    -- ---@field NumberParam1 number 数字参数一
    -- ---@field StrParm2 string 字符串参数二
end

function UIMiBaoBangDingConfirmView:OnEnter()
    if not self.bInit then
        self:RegEvent()
        self:BindUIEvent()
        self.bInit = true
    end
end

function UIMiBaoBangDingConfirmView:OnExit()
    self.bInit = false
    self:UnRegEvent()
end

function UIMiBaoBangDingConfirmView:BindUIEvent()
    UIHelper.BindUIEvent(self.BtnCalloff, EventType.OnClick, function()
        UIMgr.Close(self)
    end)

    UIHelper.BindUIEvent(self.BtnOk, EventType.OnClick, function()
        self:ConfirmBindDevice()

        UIMgr.Close(self)
    end)
end

function UIMiBaoBangDingConfirmView:RegEvent()
    --Event.Reg(self, EventType.XXX, func)
end

function UIMiBaoBangDingConfirmView:UnRegEvent()
    --Event.UnReg(self, EventType.XXX)
end






-- ----------------------------------------------------------
-- Please write your own code below  ↓↓↓
-- ----------------------------------------------------------

function UIMiBaoBangDingConfirmView:UpdateInfo()

end

function UIMiBaoBangDingConfirmView:ConfirmBindDevice()
    ---@type LoginSDK
    local moduleSDK  = LoginMgr.GetModule(LoginModule.LOGIN_SDK)
    local szAuthInfo = moduleSDK.GetAuthInfo() or ""

    LOG.DEBUG("XGSDK_BindSecurityApp szAuthInfo=%s", szAuthInfo)

    XGSDK_BindSecurityApp(szAuthInfo)

end

return UIMiBaoBangDingConfirmView