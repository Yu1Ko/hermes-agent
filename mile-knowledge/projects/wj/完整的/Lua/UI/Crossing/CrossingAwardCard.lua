-- ---------------------------------------------------------------------------------
-- Author: Liu yu min
-- Name: CrossingAwardCard
-- Date: 2023-03-22 20:21:56
-- Desc: ?
-- ---------------------------------------------------------------------------------

local CrossingAwardCard = class("CrossingAwardCard")

function CrossingAwardCard:OnEnter(nIndex, selectCallback)
    self.index = nIndex
    self.selectCallback = selectCallback
    if not self.bInit then
        self:RegEvent()
        self:BindUIEvent()
        self.bInit = true
    end
    self:UpdateInfo()
end

function CrossingAwardCard:OnExit()
    self.bInit = false
    self:UnRegEvent()
end

function CrossingAwardCard:BindUIEvent()
    UIHelper.BindUIEvent(self._rootNode, EventType.OnClick, function()
        self.selectCallback(self.index)
    end)
end

function CrossingAwardCard:RegEvent()
    
end

function CrossingAwardCard:UnRegEvent()
    Event.UnReg(self, EventType.On_Activity_FlopCardReturn)
end

-- ----------------------------------------------------------
-- Please write your own code below  ↓↓↓
-- ----------------------------------------------------------

function CrossingAwardCard:UpdateInfo()
    UIHelper.SetVisible( self.ImgCardSelect , false)
    UIHelper.SetVisible( self.ImgCardSelectLight , false)
    UIHelper.SetVisible( self.LayoutItem , false)
end

function CrossingAwardCard:UpdateCardAwardInfo(tbCardContentData , bIgnoreSelect)
    UIHelper.SetVisible(self.ImgCardSelect , not bIgnoreSelect)
    UIHelper.SetVisible(self.ImgCardSelectLight , not bIgnoreSelect)
    UIHelper.SetVisible(self.LayoutItem , true)
    --local nCardContentCount = #tbCardContentData
    --for k, v in pairs(self.tbAwardList) do
    --    if k <= nCardContentCount then
    --        local itemLua = UIHelper.GetBindScript(v)
    --        local itemData = tbCardContentData[k]
    --        itemLua:OnInitWithTabID(itemData[1], itemData[2], itemData[3])
    --        itemLua:SetClickCallback(function(nTabType, nTabID)
    --            TipsHelper.ShowItemTips(itemLua._rootNode, nTabType, nTabID)
    --        end)
    --    end
    --    UIHelper.SetVisible(self , v , k <= nCardContentCount)
    --end
    UIHelper.RemoveAllChildren(self.LayoutItem)
    if tbCardContentData then
        for i, itemData in pairs(tbCardContentData) do
            if i <= 3 then
                local itemScript = UIHelper.AddPrefab(PREFAB_ID.WidgetItem_80, self.LayoutItem)
                itemScript:OnInitWithTabID(itemData[1], itemData[2], itemData[3])
                itemScript:SetClickCallback(function(nTabType, nTabID)
                    TipsHelper.ShowItemTips(itemScript._rootNode, nTabType, nTabID)
                end)
            end
        end
    end

    UIHelper.LayoutDoLayout(self.LayoutItem)
end

return CrossingAwardCard
