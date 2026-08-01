-- ---------------------------------------------------------------------------------
-- Author: Jiayuran
-- Name: UISkillCancel
-- Date: 2022-11-11 11:45:31
-- Desc: UISkillCancel 技能取消按钮脚本
-- ---------------------------------------------------------------------------------

---@class UISkillCancel
local UISkillCancel = class("UISkillCancel")

function UISkillCancel:OnEnter()
    if not self.bInit then
        self:RegEvent()
        self:BindUIEvent()
        self.bInit = true
    end
end

function UISkillCancel:OnExit()
    self.bInit = false
    self:UnRegEvent()
end

function UISkillCancel:BindUIEvent()
    -- UIHelper.BindUIEvent(self.BtnNewCancel, EventType.OnDragOver, function(btn, nX, nY)
    --     LOG.INFO("self.BtnNewCancel OnDragOver")
    --     if UIHelper.GetVisible(self.BtnNewCancel) then
    --         self.bDragIn = true
    --         UIHelper.SetActiveAndCache(self,self.ImgSelected,true)
    --     end
    -- end)

    -- UIHelper.BindUIEvent(self.BtnNewCancel, EventType.OnDragOut, function(btn, nX, nY)
    --     LOG.INFO("self.BtnNewCancel OnDragOut")
    --     self.bDragIn = false
    --     UIHelper.SetActiveAndCache(self,self.ImgSelected,false)
    -- end)
end

function UISkillCancel:RegEvent()
    Event.Reg(self, EventType.OnHideSkillCancel, function()
        self:Hide()
    end)
end

function UISkillCancel:UnRegEvent()
    Event.UnRegAll(self)
end

function UISkillCancel:IsDragIn()
    return self.bDragIn
end

-- ----------------------------------------------------------
-- Please write your own code below  ↓↓↓
-- ----------------------------------------------------------

function UISkillCancel:Hide()
    UIHelper.SetActiveAndCache(self, self.ImgSelected, false)
    UIHelper.SetActiveAndCache(self, self.BtnNewCancel, false)
    UIHelper.SetActiveAndCache(self, self.ImgNormal, false)
end

function UISkillCancel:Show()
    UIHelper.SetActiveAndCache(self, self.BtnNewCancel, true)
    UIHelper.SetActiveAndCache(self, self.ImgSelected, false)
    UIHelper.SetActiveAndCache(self, self.ImgNormal, true)

    self.nBtnWidth, self.nBtnHeight = UIHelper.GetContentSize(self.BtnNewCancel)
    self.nBtnX, self.nBtnY = UIHelper.GetPosition(self.BtnNewCancel)
end

function UISkillCancel:Tick(x, y)
    self.bDragIn = false

    if not self.nBtnWidth or not self.nBtnHeight or not self.nBtnX or not self.nBtnY then
        UIHelper.SetActiveAndCache(self, self.ImgSelected, true)
        return
    end

    local nCursorX, nCursorY = UIHelper.ConvertToNodeSpace(self._rootNode, x, y)

    if nCursorX > -self.nBtnWidth / 2 and nCursorY > -self.nBtnHeight / 2 and nCursorX < self.nBtnWidth / 2 and nCursorY < self.nBtnHeight / 2 then
        self.bDragIn = true
        UIHelper.SetActiveAndCache(self, self.ImgSelected, true)
    else
        self.bDragIn = false
        UIHelper.SetActiveAndCache(self, self.ImgSelected, false)
    end
end

function UISkillCancel:Reset()
    self.bDragIn = false
end

return UISkillCancel