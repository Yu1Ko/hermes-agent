-- ---------------------------------------------------------------------------------
-- Author: Unknown
-- Name: UIOperationToggle
-- Date: 2026-03-20
-- Desc: ?
-- ---------------------------------------------------------------------------------

local UIOperationToggle = class("UIOperationToggle")

function UIOperationToggle:OnEnter()
    if not self.bInit then
        self:RegEvent()
        self:BindUIEvent()
        self.bInit = true
    end

    self:UpdateInfo()
end

function UIOperationToggle:OnExit()
    self.bInit = false
    self:UnRegEvent()
end

function UIOperationToggle:BindUIEvent()
    self.nSelectIndex = 1

    UIHelper.ToggleGroupRemoveAllToggle(self.ToggleGroup)
    for nIndex, tog in ipairs(self.tTog) do
        UIHelper.ToggleGroupAddToggle(self.ToggleGroup, tog)

        UIHelper.BindUIEvent(tog, EventType.OnClick, function ()
            self.nSelectIndex = nIndex
            self:UpdateInfo()
            if self.fnSelectCallback then
                self.fnSelectCallback(self.nSelectIndex)
            end
        end)
    end
    UIHelper.SetToggleGroupSelected(self.ToggleGroup, self.nSelectIndex - 1)
end

function UIOperationToggle:RegEvent()
    --Event.Reg(self, EventType.XXX, func)
end

function UIOperationToggle:UnRegEvent()
    --Event.UnReg(self, EventType.XXX)
end






-- ----------------------------------------------------------
-- Please write your own code below  ---------------------------------------------------------

function UIOperationToggle:UpdateInfo()

end

------------------------------------------------------------
-- 设置指定Toggle的标题文本
-- nIndex: Toggle索引(从1开始)
-- szLabel: 标题文本
------------------------------------------------------------
function UIOperationToggle:SetLabel(nIndex, szLabel)
    if not nIndex or not self.tTog then
        return
    end
    local tog = self.tTog[nIndex]
    if tog then
        UIHelper.SetString(UIHelper.GetChildByName(tog, "Label1"), szLabel)
        UIHelper.SetString(UIHelper.GetChildByName(tog, "Label1up"), szLabel)
        UIHelper.SetString(UIHelper.GetChildByPath(tog, "ImgNormal/Label1"), szLabel)
        UIHelper.SetString(UIHelper.GetChildByPath(tog, "ImgUP/Label1up"), szLabel)
    end
end

------------------------------------------------------------
-- 设置选中切换回调
-- fnCallback(index): 选中时的回调，index为选中的索引(从1开始)
------------------------------------------------------------
function UIOperationToggle:SetSelectCallback(fnCallback)
    self.fnSelectCallback = fnCallback
end

------------------------------------------------------------
-- 获取当前选中的索引
------------------------------------------------------------
function UIOperationToggle:GetSelectIndex()
    return self.nSelectIndex or 1
end

------------------------------------------------------------
-- 设置选中的索引
------------------------------------------------------------
function UIOperationToggle:SetSelectIndex(nIndex, bForce)
    if self.nSelectIndex == nIndex and not bForce then
        return
    end
    self.nSelectIndex = nIndex
    UIHelper.SetToggleGroupSelected(self.ToggleGroup, self.nSelectIndex - 1)
    if self.fnSelectCallback then
        self.fnSelectCallback(self.nSelectIndex)
    end
end


return UIOperationToggle
