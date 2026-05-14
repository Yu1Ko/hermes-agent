-- ---------------------------------------------------------------------------------
-- Author: Unknown
-- Name: UIHomelandIdentityDetailPop
-- Date: 2024-01-18 10:56:03
-- Desc: ?
-- ---------------------------------------------------------------------------------

local UIHomelandIdentityDetailPop = class("UIHomelandIdentityDetailPop")
local DataModel = {}
function UIHomelandIdentityDetailPop:OnEnter(tbDataModel)
    if not self.bInit then
        self:RegEvent()
        self:BindUIEvent()
        self.bInit = true
    end
    DataModel = tbDataModel
end

function UIHomelandIdentityDetailPop:OnExit()
    self.bInit = false
    self:UnRegEvent()
end

function UIHomelandIdentityDetailPop:BindUIEvent()
    UIHelper.BindUIEvent(self.BtnCloseRight, EventType.OnClick, function ()
        Event.Dispatch(EventType.OnHomeIdentityCloseDetailsPop)
    end)

    UIHelper.BindUIEvent(self.BtnClose, EventType.OnClick, function ()
        Event.Dispatch(EventType.OnHomeIdentityCloseDetailsPop)
    end)

end

function UIHomelandIdentityDetailPop:RegEvent()
    -- Event.Reg(self, EventType.OnSceneTouchNothing, function ()
    --     Event.Dispatch(EventType.OnHomeIdentityCloseDetailsPop)
    -- end)
end

function UIHomelandIdentityDetailPop:UnRegEvent()
    --Event.UnReg(self, EventType.XXX)
end






-- ----------------------------------------------------------
-- Please write your own code below  ↓↓↓
-- ----------------------------------------------------------

function UIHomelandIdentityDetailPop:UpdateInfo()
    local nTypeIndex = self.nTypeIndex
    local tIdentityUIInfo   = DataModel.tIdentityInfo[nTypeIndex]
    local dwID              = tIdentityUIInfo.dwID
    local tExtList          = DataModel.GetExtList(dwID)
    local szName            = UIHelper.GBKToUTF8(tIdentityUIInfo.szName).."能力详情"

    
end

function UIHomelandIdentityDetailPop:OpenDetailsPop(nTypeIndex)
    UIHelper.SetVisible(self._rootNode, true)
    self.nTypeIndex = nTypeIndex
    self:UpdateInfo()
end

function UIHomelandIdentityDetailPop:CloseDetailsPop()
    UIHelper.SetVisible(self._rootNode, false)
end

return UIHomelandIdentityDetailPop