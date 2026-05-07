-- ---------------------------------------------------------------------------------
-- Author: Unknown
-- Name: UIWidgetBahuangSkillCellView
-- Date: 2024-01-25 20:17:55
-- Desc: ?
-- ---------------------------------------------------------------------------------

local UIWidgetBahuangSkillCellView = class("UIWidgetBahuangSkillCellView")

function UIWidgetBahuangSkillCellView:OnEnter(tbSkillInfo, toggleGroup, szName, nIndex)
    if not self.bInit then
        self:RegEvent()
        self:BindUIEvent()
        self.bInit = true
    end
    self.tbSkillInfo = tbSkillInfo
    self.toggleGroup = toggleGroup
    self.szName = szName
    self.nIndex = nIndex
    self:UpdateInfo()
end

function UIWidgetBahuangSkillCellView:OnExit()
    self.bInit = false
    self:UnRegEvent()
end

function UIWidgetBahuangSkillCellView:BindUIEvent()
    UIHelper.BindUIEvent(self.TogSkill, EventType.OnSelectChanged, function(_, bSelect)
        if bSelect then
            TipsHelper.DeleteHoverTips(PREFAB_ID.WidgetSkillInfoTips)
            local tips, tipsScriptView = TipsHelper.ShowNodeHoverTipsInDir(PREFAB_ID.WidgetSkillInfoTips, self.TogSkill,
            TipsLayoutDir.TOP_LEFT, self.tbSkillInfo.dwSkillID, nil, nil, self.tbSkillInfo.nSkillLevel)
            tipsScriptView:SetBtnVisible(false)
        end
    end)

    UIHelper.BindUIEvent(self.TogSkill, EventType.OnTouchBegan, function()
        self.nOriginX, self.nOriginY = UIHelper.GetPosition(self._rootNode)
        Event.Dispatch(EventType.OnMoveBahungSkill, self.nIndex, true) 
    end)

    UIHelper.BindUIEvent(self.TogSkill, EventType.OnTouchMoved, function(btn, nX, nY)
        if not self.funcOnEndedCallBack then return end
        local parent = UIHelper.GetParent(self._rootNode)
        local nWidth = UIHelper.GetWidth(self._rootNode)
        nX, nY = UIHelper.ConvertToNodeSpace(parent, nX - nWidth / 2, nY)
        UIHelper.SetPosition(self._rootNode, nX, nY, parent)
    end)

    UIHelper.BindUIEvent(self.TogSkill, EventType.OnTouchEnded, function()
        if not self.funcOnEndedCallBack then return end
        Event.Dispatch(EventType.OnMoveBahungSkill, self.nIndex, false)
        if self.funcOnEndedCallBack(self.tbSkillInfo) then

        else
            UIHelper.SetPosition(self._rootNode, self.nOriginX, self.nOriginY)
        end
    end)

    UIHelper.BindUIEvent(self.TogSkill, EventType.OnTouchCanceled, function()
        if not self.funcOnEndedCallBack then return end
        Event.Dispatch(EventType.OnMoveBahungSkill, self.nIndex, false)
        if self.funcOnEndedCallBack(self.tbSkillInfo) then

        else
            UIHelper.SetPosition(self._rootNode, self.nOriginX, self.nOriginY)
        end
    end)
end

function UIWidgetBahuangSkillCellView:RegEvent()
    --Event.Reg(self, EventType.XXX, func)
    Event.Reg(self, EventType.OnTouchViewBackGround, function()
        TipsHelper.DeleteHoverTips(PREFAB_ID.WidgetSkillInfoTips)
    end)
end

function UIWidgetBahuangSkillCellView:UnRegEvent()
    --Event.UnReg(self, EventType.XXX)
end






-- ----------------------------------------------------------
-- Please write your own code below  ↓↓↓
-- ----------------------------------------------------------

function UIWidgetBahuangSkillCellView:UpdateInfo()
    local tbSkillInfo = self.tbSkillInfo
    UIHelper.SetTexture(self.ImgSkillIcon, tbSkillInfo ~= nil and TabHelper.GetSkillIconPathByIDAndLevel(tbSkillInfo.dwSkillID, tbSkillInfo.nSkillLevel) or "", true, function()
        UIHelper.UpdateMask(self.MaskSkill)
    end)
    UIHelper.SetString(self.LabelSkillName, tbSkillInfo ~= nil and UIHelper.GBKToUTF8(Table_GetSkillName(tbSkillInfo.dwSkillID, tbSkillInfo.nSkillLevel)) or self.szName)
    UIHelper.UpdateMask(self.MaskSkill)
end

function UIWidgetBahuangSkillCellView:GetSkillInfo()
    return self.tbSkillInfo
end

function UIWidgetBahuangSkillCellView:SetOnDragEndedCallBack(funcOnEndedCallBack)
    self.funcOnEndedCallBack = funcOnEndedCallBack
end

function UIWidgetBahuangSkillCellView:HitTest()
    local sceneNode = cc.Director:getInstance():getRunningScene()
    local camera = sceneNode:getDefaultCamera()

    local tbCursor = GetViewCursorPoint()
    local tbPoint = cc.p(tbCursor.x, tbCursor.y)    -- 鼠标位置的世界坐标
    if self.TogSkill.hitTest and self.TogSkill:hitTest(tbPoint, camera) then
        return true
    end
    return false
end

return UIWidgetBahuangSkillCellView