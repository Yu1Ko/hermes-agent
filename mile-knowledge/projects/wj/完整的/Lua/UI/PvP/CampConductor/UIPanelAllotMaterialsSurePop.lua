-- ---------------------------------------------------------------------------------
-- Name: UIPanelAllotMaterialsSurePop
-- Desc: 分配装置确认弹出框 RemoteFunction.On_Camp_GFAssignItem 不用这个页面
-- Prefab: 
-- ---------------------------------------------------------------------------------

local UIPanelAllotMaterialsSurePop = class("UIPanelAllotMaterialsSurePop")

function UIPanelAllotMaterialsSurePop:_LuaBindList()
    self.BtnClose          = self.BtnClose

    self.LabelMaterialName = self.LabelMaterialName -- 装备name

    self.ScrollView        = self.ScrollView -- 加载 WidgettAllotPlayerListCell
    self.WidgetEmpty       = self.WidgetEmpty -- 空白widget

    self.BtnCancel         = self.BtnCancel -- 分配取消
    self.BtnAccept         = self.BtnAccept -- 分配确认
end

function UIPanelAllotMaterialsSurePop:OnEnter()
    if not self.bInit then
        self:BindUIEvent()
        self:RegEvent()
        self.bInit = true
    end
end

function UIPanelAllotMaterialsSurePop:OnExit()
    self.bInit = false
    self:UnRegEvent()
end

function UIPanelAllotMaterialsSurePop:BindUIEvent()
    UIHelper.BindUIEvent(self.BtnClose, EventType.OnClick, function()
        UIMgr.Close(self)
    end)

    UIHelper.BindUIEvent(self.BtnCancel, EventType.OnClick, function()
        UIMgr.Close(self)
    end)

    UIHelper.BindUIEvent(self.BtnAccept, EventType.OnClick, function()
        RemoteCallToServer("On_Camp_GFDoAssignItem", self.nType, self.tOKList)
		UIMgr.Close(self)
    end)
end

function UIPanelAllotMaterialsSurePop:RegEvent()
    
end

function UIPanelAllotMaterialsSurePop:UnRegEvent()

end


-- ----------------------------------------------------------
-- Please write your own code below  ↓↓↓
-- ----------------------------------------------------------

function UIPanelAllotMaterialsSurePop:UpdateInfo(nType, tOKList, tNotMemberFail, tInDifMapFail, tOtherFail)
    self.nType = nType
    self.tOKList = tOKList
    self:UpdateList(tOKList, 1)
    self:UpdateList(tNotMemberFail, 2)
    self:UpdateList(tInDifMapFail, 3)
    self:UpdateList(tOtherFail, 4)
end

function UIPanelAllotMaterialsSurePop:UpdateList(tInfo, nType)
    if nType == 1 then
    else
        if nType == 2 then
            -- g_tStrings.STR_COMMAND_NOT_MEMBER
        elseif  nType == 3 then
            -- g_tStrings.STR_COMMAND_NOT_IN_THIS_MAP
        elseif  nType == 4 then
            -- g_tStrings.STR_COMMANMD_FAILD_BAG
        end
    end
end


return UIPanelAllotMaterialsSurePop