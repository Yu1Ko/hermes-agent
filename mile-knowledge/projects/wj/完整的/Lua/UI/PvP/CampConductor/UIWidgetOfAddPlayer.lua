-- ---------------------------------------------------------------------------------
-- Name: UIWidgetOfAddPlayer
-- Desc: 阵营指挥管理--批量添加玩家分页
-- Prefab:PanelCampConductor--WidgetAddCampCrew
-- ---------------------------------------------------------------------------------

local UIWidgetOfAddPlayer = class("UIWidgetOfAddPlayer")

function UIWidgetOfAddPlayer:_LuaBindList()
    self.BtnClose           = self.BtnClose 
    self.BtnCloseRight      = self.BtnCloseRight

    self.ScrollView         = self.ScrollView --- 加载玩家cell的Scroll WidgeAddCrewPlayerCell

    self.TogTypeFriend      = self.TogTypeFriend --- 好友分页
    self.TogTypeFaction     = self.TogTypeFaction --- 帮会分页

    self.WidgetEmpty        = self.WidgetEmpty --- 空白widget
end

function UIWidgetOfAddPlayer:OnEnter()
    if self.bExit then return end
    if not self.bInit then
        self:BindUIEvent()
        -- self:RegEvent()
        self.bInit = true
    end
    self.cellPool = PrefabPool.New(PREFAB_ID.WidgeAddCrewPlayerCell)
    UIHelper.SetToggleGroupIndex(self.TogTypeFriend, ToggleGroupIndex.MonsterBookActiveSkill)
    UIHelper.SetToggleGroupIndex(self.TogTypeFaction, ToggleGroupIndex.MonsterBookActiveSkill)
end

function UIWidgetOfAddPlayer:OnExit()
    self.bExit = true
    self.bInit = false
    self:UnRegEvent()
    if self.cellPool then self.cellPool:Dispose() end
    self.cellPool = nil
end

function UIWidgetOfAddPlayer:BindUIEvent()
    UIHelper.BindUIEvent(self.BtnClose, EventType.OnClick, function()
        self:Close()
    end)

    -- UIHelper.BindUIEvent(self.BtnCloseRight, EventType.OnClick, function()
    --     self:Close()
    -- end)

    UIHelper.BindUIEvent(self.TogTypeFriend, EventType.OnSelectChanged, function(_, bSelect)
        if bSelect then
            self:SetPageType(1)
        end
    end)

    UIHelper.BindUIEvent(self.TogTypeFaction, EventType.OnSelectChanged, function(_, bSelect)
        if bSelect then
            self:SetPageType(2)
        end
    end)
end

function UIWidgetOfAddPlayer:RegEvent()
    Event.Reg(self, "CMDSETTING_MEMBER_CHANGE", function()
        CommandBaseData.InitPlayerDataList()
        self:UpdateInfo()
    end)
    Event.Reg(self, EventType.On_Camp_GFGetCampInTong, function()
        self:UpdateInfo()
    end)
end

function UIWidgetOfAddPlayer:UnRegEvent()

end






-- ----------------------------------------------------------
-- Please write your own code below  ↓↓↓
-- ----------------------------------------------------------

function UIWidgetOfAddPlayer:Open()
    self:RegEvent()
    CommandBaseData.InitPlayerDataList()
    UIHelper.SetVisible(self._rootNode, true)
    UIHelper.SetSelected(self.TogTypeFriend, true)
end

function UIWidgetOfAddPlayer:Close()
    self:UnRegEvent()
    UIHelper.SetVisible(self._rootNode, false)
end

function UIWidgetOfAddPlayer:IsOpen()
    return UIHelper.GetVisible(self._rootNode)
end

function UIWidgetOfAddPlayer:RemoveAllChildren()
    for nIndex, node in ipairs(self.tbChildList) do
        self.cellPool:Recycle(node)
    end
    self.tbChildList = {}
end

function UIWidgetOfAddPlayer:UpdateInfo()
    local nType = self.nType
    local tbMemberList = {}
    if nType == 1 then --好友
        tbMemberList = CommandBaseData.GetFriendList()
    else--帮会
        tbMemberList = CommandBaseData.GetGuildMemberList()
    end

    self:RemoveAllChildren()
    for nIndex, tbPlayer in ipairs(tbMemberList) do
        local node, script = self.cellPool:Allocate(self.ScrollView, tbPlayer)
        table.insert(self.tbChildList, node)
    end

    UIHelper.ScrollViewDoLayoutAndToTop(self.ScrollView)
    UIHelper.SetVisible(self.WidgetEmpty, #tbMemberList == 0)
end

function UIWidgetOfAddPlayer:SetPageType(nType)
    self.nType = nType
    self:UpdateInfo()
end

return UIWidgetOfAddPlayer