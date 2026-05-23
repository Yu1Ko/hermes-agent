-- ---------------------------------------------------------------------------------
-- Author: 陈计
-- Name: UIReceiveFactionMessagePopView
-- Date: 2024-09-03 17:42:57
-- Desc: 帮会群密 - 无权限时展示的界面
-- Prefab: PanelReceiveFactionMessagePop
-- ---------------------------------------------------------------------------------

---@class UIReceiveFactionMessagePopView
local UIReceiveFactionMessagePopView = class("UIReceiveFactionMessagePopView")

---_LuaBindList 在这里对绑定的组件进行无意义自赋值，从而方便查询以及ide进行智能提示
function UIReceiveFactionMessagePopView:_LuaBindList()
    self.BtnClose                                   = self.BtnClose --- 关闭按钮
    self.BtnCancel                                  = self.BtnCancel --- 取消按钮
    self.BtnConfirm                                 = self.BtnConfirm --- 确认按钮
    self.ToggleShieldTongWhisperInThisLoginDuration = self.ToggleShieldTongWhisperInThisLoginDuration --- 本次登录期间屏蔽帮会群里消息的toggle
end

---_LuaTypeList 在这里添加类型注解，从而方便查询以及ide进行智能提示
function UIReceiveFactionMessagePopView:_LuaTypeList()
    -- note: 为了方便写的时候IDE也能提示诸如 c++导出的枚举、临时定义的table列表 的字段，可以像下面示例一样，在这里定义对应类型的信息
    -- note: 定义完后在对应变量的定义处通过 ---@type 注解来标注类型即可
    -- note: 具体 class/type/array/table 格式参考 https://emmylua.github.io/annotation.html

    -- ---@class TypeDemo 示例类型
    -- ---@field NumberParam1 number 数字参数一
    -- ---@field StrParm2 string 字符串参数二
end

function UIReceiveFactionMessagePopView:OnEnter()
    if not self.bInit then
        self:RegEvent()
        self:BindUIEvent()
        self.bInit = true
    end
    
    self:UpdateInfo()
end

function UIReceiveFactionMessagePopView:OnExit()
    self.bInit = false
    self:UnRegEvent()
end

function UIReceiveFactionMessagePopView:BindUIEvent()
    UIHelper.BindUIEvent(self.BtnClose, EventType.OnClick, function()
        UIMgr.Close(self)
    end)
    
    UIHelper.BindUIEvent(self.BtnCancel, EventType.OnClick, function()
        UIMgr.Close(self)
    end)
    
    UIHelper.BindUIEvent(self.BtnConfirm, EventType.OnClick, function()
        UIMgr.Close(self)
    end)
    
    UIHelper.BindUIEvent(self.ToggleShieldTongWhisperInThisLoginDuration, EventType.OnSelectChanged, function(_, selected)
        JX_TongWhisper.bWhisperQuiet = selected
    end)
end

function UIReceiveFactionMessagePopView:RegEvent()
    --Event.Reg(self, EventType.XXX, func)
end

function UIReceiveFactionMessagePopView:UnRegEvent()
    --Event.UnReg(self, EventType.XXX)
end






-- ----------------------------------------------------------
-- Please write your own code below  ↓↓↓
-- ----------------------------------------------------------

function UIReceiveFactionMessagePopView:UpdateInfo()
    UIHelper.SetSelected(self.ToggleShieldTongWhisperInThisLoginDuration, JX_TongWhisper.bWhisperQuiet)
end

return UIReceiveFactionMessagePopView