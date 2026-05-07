-- ---------------------------------------------------------------------------------
-- Author: 陈计
-- Name: UIConstraintRenamePopView
-- Date: 2024-06-20 11:43:54
-- Desc: 帮会强制改名
-- Prefab: PanelConstraintRenamePop
-- ---------------------------------------------------------------------------------

---@class UIConstraintRenamePopView
local UIConstraintRenamePopView = class("UIConstraintRenamePopView")

---_LuaBindList 在这里对绑定的组件进行无意义自赋值，从而方便查询以及ide进行智能提示
function UIConstraintRenamePopView:_LuaBindList()
    self.BtnClose             = self.BtnClose --- 关闭页面
    self.LabelFactionTransfer = self.LabelFactionTransfer --- 描述
    self.BtnCancel            = self.BtnCancel --- 取消
    self.BtnConfirm           = self.BtnConfirm --- 确定
    self.EditBox              = self.EditBox --- 输入框
end

---_LuaTypeList 在这里添加类型注解，从而方便查询以及ide进行智能提示
function UIConstraintRenamePopView:_LuaTypeList()
    -- note: 为了方便写的时候IDE也能提示诸如 c++导出的枚举、临时定义的table列表 的字段，可以像下面示例一样，在这里定义对应类型的信息
    -- note: 定义完后在对应变量的定义处通过 ---@type 注解来标注类型即可
    -- note: 具体 class/type/array/table 格式参考 https://emmylua.github.io/annotation.html

    -- ---@class TypeDemo 示例类型
    -- ---@field NumberParam1 number 数字参数一
    -- ---@field StrParm2 string 字符串参数二
end

function UIConstraintRenamePopView:OnEnter()
    if not self.bInit then
        self:RegEvent()
        self:BindUIEvent()
        self.bInit = true
    end
    
    self:UpdateInfo()
end

function UIConstraintRenamePopView:OnExit()
    self.bInit = false
    self:UnRegEvent()
end

function UIConstraintRenamePopView:BindUIEvent()
    UIHelper.BindUIEvent(self.BtnClose, EventType.OnClick, function()
        UIMgr.Close(self)
    end)
    
    UIHelper.BindUIEvent(self.BtnCancel, EventType.OnClick, function()
        UIMgr.Close(self)
    end)
    
    UIHelper.BindUIEvent(self.BtnConfirm, EventType.OnClick, function()
        local szNewName = UIHelper.GetString(self.EditBox)
        
        self:ConfirmTongRename(szNewName)
    end)
end

function UIConstraintRenamePopView:RegEvent()
    --Event.Reg(self, EventType.XXX, func)
    Event.Reg(self, "TONG_EVENT_NOTIFY", function ()
        if arg0 == TONG_EVENT_CODE.RENAME_SUCCESS then
            GetTongClient().ApplyTongInfo()
            
            UIMgr.Close(self)
        end
    end)
end

function UIConstraintRenamePopView:UnRegEvent()
    --Event.UnReg(self, EventType.XXX)
end






-- ----------------------------------------------------------
-- Please write your own code below  ↓↓↓
-- ----------------------------------------------------------

function UIConstraintRenamePopView:UpdateInfo()
    UIHelper.SetPlaceHolder(self.EditBox, UIHelper.GBKToUTF8(TongData.GetName()))
end

function UIConstraintRenamePopView:ConfirmTongRename(szNewName)
    if BankLock.CheckHaveLocked(SAFE_LOCK_EFFECT_TYPE.TONG_OPERATE, "TongRename") then
        return
    end

    local szMsg = ""
    if not szNewName or UIHelper.GetUtf8RichTextWidth(szNewName) == 0 then
        szMsg = g_tStrings.tGuildRenameError["NAME_CANNOT_EMPTY"]
    end
    if szMsg ~= "" then
        TipsHelper.ShowImportantRedTip(szMsg)
        return
    end

    UIHelper.ShowConfirm(string.format("确定要修改帮会名称为【%s】吗？", szNewName), function()
        RemoteCallToServer("OnRenameTong", UIHelper.UTF8ToGBK(szNewName))
    end)
end

return UIConstraintRenamePopView