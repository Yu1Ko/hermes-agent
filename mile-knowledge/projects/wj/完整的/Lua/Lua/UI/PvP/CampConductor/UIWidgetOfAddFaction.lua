-- ---------------------------------------------------------------------------------
-- Name: UIWidgetOfAddFaction
-- Desc: 阵营指挥管理--批量添加帮会分页
-- Prefab:PanelCampConductor--WidgetManageFaction
-- ---------------------------------------------------------------------------------

local UIWidgetOfAddFaction = class("UIWidgetOfAddFaction")

function UIWidgetOfAddFaction:_LuaBindList()
    self.BtnClose           = self.BtnClose 
    self.BtnCloseRight      = self.BtnCloseRight

    self.ScrollView         = self.ScrollView --- 加载帮会cell的Scroll WidgeManageCampFactionCell

    self.LabelNotice          = self.LabelNotice --- 已选择:9
    self.BtnCancel            = self.BtnCancel --- 取消移除btn
    self.BtnComfirm           = self.BtnComfirm --- 确认移除btn
end

function UIWidgetOfAddFaction:OnEnter()
    if not self.bInit then
        self:BindUIEvent()
        self:RegEvent()
        self.bInit = true
        self.cellPool = PrefabPool.New(PREFAB_ID.WidgeManageCampFactionCell)
    end
end

function UIWidgetOfAddFaction:OnExit()
    self.bInit = false
    if self.cellPool then
        self.cellPool:Dispose()
        self.cellPool = nil
    end
    self:UnRegEvent()
end

function UIWidgetOfAddFaction:BindUIEvent()
    UIHelper.BindUIEvent(self.BtnClose, EventType.OnClick, function()
        UIHelper.SetVisible(self._rootNode, false)
    end)

    UIHelper.BindUIEvent(self.BtnCloseRight, EventType.OnClick, function()
        UIHelper.SetVisible(self._rootNode, false)
    end)

    UIHelper.BindUIEvent(self.BtnCancel, EventType.OnClick, function()
        
    end)

    UIHelper.BindUIEvent(self.BtnConfirm, EventType.OnClick, function()
        CommandBaseData.RemoteAddNewTong()
    end)
end

function UIWidgetOfAddFaction:RegEvent()
    
end

function UIWidgetOfAddFaction:UnRegEvent()

end

function UIWidgetOfAddFaction:RemoveAllCamp()
    if self.tbNode then
        for nIndex, tbInfo in ipairs(self.tbNode) do
            self.cellPool:Recycle(tbInfo.node)
        end
    end
    self.tbNode = {}
end

--什么时候加载？
function UIWidgetOfAddFaction:UpdateInfo()
    local tbGangRankList = CommandBaseData.GetGangRankList()
    local tbWhiteTongID = CommandBaseData.GetCoreTongList()
    self:RemoveAllCamp()
    for nIndex, tbInfo in ipairs(tbGangRankList) do
        if nIndex <= 50 and not table.contain_value(tbWhiteTongID, tbInfo.dwID) then
            local node, script = self.cellPool:Allocate(self.ScrollView, tbInfo.dwID, true, function(bSelect)
                if bSelect then
                    CommandBaseData.AddNewTong(tbInfo.dwID)
                else
                    CommandBaseData.DeleteNewTong(tbInfo.dwID)
                end
            end)
            table.insert(self.tbNode, {node = node, scriptView = script})
        end
    end

    UIHelper.ScrollViewDoLayoutAndToTop(self.ScrollView)
end



-- ----------------------------------------------------------
-- Please write your own code below  ↓↓↓
-- ----------------------------------------------------------



return UIWidgetOfAddFaction