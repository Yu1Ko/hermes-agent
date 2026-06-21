-- ---------------------------------------------------------------------------------
-- Name: UIPanelAddMember
-- Desc: 添加核心成员
-- Prefab:PanelAddCampCrewPop
-- ---------------------------------------------------------------------------------

local UIPanelAddMember = class("UIPanelAddMember")

function UIPanelAddMember:OnEnter()
    if not self.bInit then
        self:BindUIEvent()
        self:RegEvent()
        self.bInit = true
    end
    self:UpdateInfo()
end

function UIPanelAddMember:OnExit()
    self.bInit = false
    self:UnRegEvent()
end

function UIPanelAddMember:BindUIEvent()
    UIHelper.BindUIEvent(self.BtnAdd, EventType.OnClick, function()
        self:SubmitFindPlayer()
        UIMgr.Close(self)
    end)

    UIHelper.BindUIEvent(self.TogConvert01, EventType.OnSelectChanged, function(_, bSelect)
        if bSelect then
            self:SetLimit(1)
        end
    end)

    UIHelper.BindUIEvent(self.TogConvert02, EventType.OnSelectChanged, function(_, bSelect)
        if bSelect then
            self:SetLimit(2)
        end
    end)

    UIHelper.BindUIEvent(self.TogConvert03, EventType.OnSelectChanged, function(_, bSelect)
        if bSelect then
            self:SetLimit(3)
        end
    end)

    UIHelper.BindUIEvent(self.BtnClose, EventType.OnClick, function(_, bSelect)
        UIMgr.Close(self)
    end)
end

function UIPanelAddMember:RegEvent()
    
end

function UIPanelAddMember:UnRegEvent()

end


function UIPanelAddMember:UpdateInfo()
    for nIndex, toggle in ipairs(self.tbToggle) do
        UIHelper.SetToggleGroupIndex(toggle, ToggleGroupIndex.MonsterBookSkillBook)
    end
    self:SetLimit(2, true)
end



-- ----------------------------------------------------------
-- Please write your own code below  ↓↓↓
-- ----------------------------------------------------------
function UIPanelAddMember:SubmitFindPlayer()
    local szName = UIHelper.UTF8ToGBK(UIHelper.GetText(self.EditPlayerName))
    RemoteCallToServer("On_Camp_GFAddMember1", szName, self.nLimit)
end

function UIPanelAddMember:SetLimit(nLimit, bUpdateToggleState)
    self.nLimit = nLimit
    if bUpdateToggleState then
        for nIndex, toggle in ipairs(self.tbToggle) do
            if nIndex == nLimit then
                UIHelper.SetSelected(toggle, true, false)
            end
        end
    end
end

return UIPanelAddMember