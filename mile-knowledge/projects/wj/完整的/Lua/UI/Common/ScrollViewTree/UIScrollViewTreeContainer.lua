-- ---------------------------------------------------------------------------------
-- Author: luwenhao1
-- Name: UIScrollViewTreeContainer
-- Date: 2023-03-02 14:48:40
-- Desc:
-- ---------------------------------------------------------------------------------

---@class UIScrollViewTreeContainer
local UIScrollViewTreeContainer = class("UIScrollViewTreeContainer")

--[[

Require Lua Bind:
self.LayoutContent
self.ToggleSelect

@ tArgs: 自定义参数，外部调用Container初始化函数时传入
@ tItemList = {
    { nPrefabID = XXX, tArgs = {...} },
    { nPrefabID = XXX, tArgs = {...} },
    { nPrefabID = XXX, tArgs = {...} },
    ...
}
若tItemList为空，则表示无次级导航

--]]

function UIScrollViewTreeContainer:OnEnter(tArgs, tItemList, bDelayLoad)
    self.tArgs = tArgs
    self.tItemList = tItemList
    self.bDelayLoad = bDelayLoad
    self.tItemScripts = {}

    if not self.bInit then
        self:RegEvent()
        self:BindUIEvent()
        self.bInit = true

        self.bIgnoreCallback = false
    end

    if not bDelayLoad then
        self:UpdateInfo(true)
    end
    self:SetSelected(false)
end

function UIScrollViewTreeContainer:OnExit()
    self.bInit = false
    self:UnRegEvent()
end

function UIScrollViewTreeContainer:BindUIEvent()
    UIHelper.BindUIEvent(self.ToggleSelect, EventType.OnSelectChanged, function(_, bSelected)
        if self.fnBeforeSelectedCallback then
            self.fnBeforeSelectedCallback(bSelected)
        end

        UIHelper.SetVisible(self.LayoutContent, bSelected)
        self:FoldItems(not bSelected)
        if self.fnSelectedCallback and not self.bIgnoreCallback then
            self.fnSelectedCallback(bSelected)
        end
    end)

    UIHelper.BindUIEvent(self.ToggleSelect, EventType.OnClick, function()
        if self.fnOnClickCallBack then
            local bSelected = UIHelper.GetSelected(self.ToggleSelect)
            self.fnOnClickCallBack(bSelected)
        end
    end)
end

function UIScrollViewTreeContainer:RegEvent()
    --Event.Reg(self, EventType.XXX, func)
end

function UIScrollViewTreeContainer:UnRegEvent()
    --Event.UnReg(self, EventType.XXX)
end

function UIScrollViewTreeContainer:UpdateInfo(bReload)
    if bReload then
        UIHelper.RemoveAllChildren(self.LayoutContent)
        self.tItemScripts = {}
    end

    if not self.tItemList then
        return
    end

    for i, v in ipairs(self.tItemList) do
        if not v.bLoaded or bReload then
            local script = UIMgr.AddPrefab(v.nPrefabID, self.LayoutContent, v.tArgs)
            table.insert(self.tItemScripts, script)

            self.tItemList[i].bLoaded = true
        end
    end
end

function UIScrollViewTreeContainer:SetBeforeSelectedCallBack(fnCallback)
    self.fnBeforeSelectedCallback = fnCallback
end

function UIScrollViewTreeContainer:SetSelectedCallBack(fnCallback)
    self.fnSelectedCallback = fnCallback
end

function UIScrollViewTreeContainer:SetOnClickCallBack(fnCallback)
    self.fnOnClickCallBack = fnCallback
end

--临时处理一下点击TopContainer时，触发当前选中container的OnClick回调
function UIScrollViewTreeContainer:CallOnClickCallBack(bSelect)
    if self.fnOnClickCallBack then
        self.fnOnClickCallBack(bSelect)
    end
end

--折叠/展开
function UIScrollViewTreeContainer:FoldItems(bFold)
    if self.bDelayLoad and not bFold then
        self:UpdateInfo()
    end

    local items = UIHelper.GetChildren(self.LayoutContent)
    for i, v in ipairs(items) do
        UIHelper.SetVisible(v, not bFold)
    end
    UIHelper.CascadeDoLayoutDoWidget(self._rootNode, true, false)

    --刷新动画
    if not bFold then
        UIHelper.SetVisible(self.LayoutContent, false)
        UIHelper.SetVisible(self.LayoutContent, true)
    end
end

function UIScrollViewTreeContainer:SetSelected(bSelected, bIgnoreCallback)
    self.bIgnoreCallback = bIgnoreCallback or false
    UIHelper.SetSelected(self.ToggleSelect, bSelected)
    self.bIgnoreCallback = false
end

function UIScrollViewTreeContainer:GetSelected()
    return UIHelper.GetSelected(self.ToggleSelect)
end

function UIScrollViewTreeContainer:SetEffectVisible(bVisible)
    if self.Eff_MenuSelect then
        UIHelper.SetVisible(self.Eff_MenuSelect, bVisible)
    end
end

function UIScrollViewTreeContainer:GetItemScript()
    return self.tItemScripts
end

function UIScrollViewTreeContainer:SetCanSelect(bCanSelect)
    UIHelper.SetCanSelect(self.ToggleSelect, bCanSelect,nil,false)
end

return UIScrollViewTreeContainer