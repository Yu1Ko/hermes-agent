-- ---------------------------------------------------------------------------------
-- Author: 陈计
-- Name: UIHistoryMessageCell
-- Date: 2024-09-05 17:29:44
-- Desc: 帮会群密历史消息
-- Prefab: WidgetHistoryMessageCell
-- ---------------------------------------------------------------------------------

---@class UIHistoryMessageCell
local UIHistoryMessageCell = class("UIHistoryMessageCell")

---_LuaBindList 在这里对绑定的组件进行无意义自赋值，从而方便查询以及ide进行智能提示
function UIHistoryMessageCell:_LuaBindList()
    self.LabelHistoryMessage      = self.LabelHistoryMessage --- 历史消息内容
    self.BtnDelete                = self.BtnDelete --- 删除该条历史消息
    self.BtnUseThisHistoryMessage = self.BtnUseThisHistoryMessage --- 使用本条历史消息
end

---_LuaTypeList 在这里添加类型注解，从而方便查询以及ide进行智能提示
function UIHistoryMessageCell:_LuaTypeList()
    -- note: 为了方便写的时候IDE也能提示诸如 c++导出的枚举、临时定义的table列表 的字段，可以像下面示例一样，在这里定义对应类型的信息
    -- note: 定义完后在对应变量的定义处通过 ---@type 注解来标注类型即可
    -- note: 具体 class/type/array/table 格式参考 https://emmylua.github.io/annotation.html

    -- ---@class TypeDemo 示例类型
    -- ---@field NumberParam1 number 数字参数一
    -- ---@field StrParm2 string 字符串参数二
end

---@param uiFactionMessagePopView UIFactionMessagePopView
function UIHistoryMessageCell:OnEnter(szHistory, uiFactionMessagePopView)
    self.szHistory = szHistory
    self.uiFactionMessagePopView = uiFactionMessagePopView

    if not self.bInit then
        self:RegEvent()
        self:BindUIEvent()
        self.bInit = true
    end

    self:UpdateInfo()
end

function UIHistoryMessageCell:OnExit()
    self.bInit = false
    self:UnRegEvent()
end

function UIHistoryMessageCell:BindUIEvent()
    UIHelper.BindUIEvent(self.BtnDelete, EventType.OnClick, function()
        JX_TongWhisper.DeleteWhisperHistory(self.szHistory)
    end)
    
    UIHelper.BindUIEvent(self.BtnUseThisHistoryMessage, EventType.OnClick, function()
        self.uiFactionMessagePopView:UseHistoryMessage(self.szHistory)
    end)
end

function UIHistoryMessageCell:RegEvent()
    --Event.Reg(self, EventType.XXX, func)
end

function UIHistoryMessageCell:UnRegEvent()
    --Event.UnReg(self, EventType.XXX)
end






-- ----------------------------------------------------------
-- Please write your own code below  ↓↓↓
-- ----------------------------------------------------------

function UIHistoryMessageCell:UpdateInfo()
    UIHelper.SetString(self.LabelHistoryMessage, self.szHistory, 12)
end

return UIHistoryMessageCell