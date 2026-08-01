-- ---------------------------------------------------------------------------------
-- Author: Unknown
-- Name: UIPanelMiniGameAim
-- Date: 2024-03-04 15:16:23
-- Desc: ?
-- ---------------------------------------------------------------------------------

local UIPanelMiniGameAim = class("UIPanelMiniGameAim")

function UIPanelMiniGameAim:OnEnter(bAutolost, bNotify_server, nType, bAutoSearch)
    if not self.bInit then
        self:RegEvent()
        self:BindUIEvent()
        self.bInit = true
    end
    self.bAutolost = bAutolost
    self.bNotify_server = bNotify_server

    if not bAutoSearch then bAutoSearch = true end
    self.bAutoSearch = bAutoSearch

    self.nSelectType = TARGET.NO_TARGET
    self.nSelectID = 0

    local nX, nY = UIHelper.GetWorldPosition(self.ImgAim)
    -- local w, h = UIHelper.GetContentSize(self.ImgAim)

    TargetMgr.Scene_SetAutoSearch(bAutoSearch, nX, nY)
end

function UIPanelMiniGameAim:OnExit()
    self.bInit = false
    self:UnRegEvent()
    TargetMgr.Scene_SetAutoSearch(false)
end

function UIPanelMiniGameAim:BindUIEvent()
    
end

function UIPanelMiniGameAim:RegEvent()
    Event.Reg(self, "HOVER_ON_MODEL", function(nSelectType, nSelectID)
        nSelectType = nSelectType or TARGET.NO_TARGET
        nSelectID = nSelectID or 0
        self:UpdateTarget(nSelectType, nSelectID)
    end)
end

function UIPanelMiniGameAim:UnRegEvent()
    --Event.UnReg(self, EventType.XXX)
end






-- ----------------------------------------------------------
-- Please write your own code below  ↓↓↓
-- ----------------------------------------------------------

function UIPanelMiniGameAim:PlayAnim()
    UIHelper.PlayAni(self, self.WidgetAniAim, "MiniGameAim")
end

function UIPanelMiniGameAim:UpdateTarget(nSelectType, nSelectID)
    if self.nSelectID and self.nSelectType ~= TARGET.NO_TARGET and nSelectType == TARGET.NO_TARGET then
        if self.bAutolost then
            TargetMgr.doSelectTarget(nSelectID, nSelectType)
			self.nSelectType = nSelectType
			self.nSelectID = nSelectID

			if self.bNotify_server then 
				RemoteCallToServer("On_Jail_FPSLeaveTarget")
			end
        end
    elseif self.nSelectType ~= nSelectType or self.nSelectID ~= nSelectID then
        TargetMgr.doSelectTarget(nSelectID, nSelectType)
        self.nSelectType = nSelectType
		self.nSelectID = nSelectID

        self:PlayAnim()

        if self.bNotify_server then 
            RemoteCallToServer("On_Jail_FPSGetTarget")
        end
    end
end

return UIPanelMiniGameAim