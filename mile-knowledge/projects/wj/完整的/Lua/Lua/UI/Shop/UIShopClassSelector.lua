local UIShopClassSelector = class("UIShopClassSelector")


function UIShopClassSelector:OnEnter(nShopID, szName, tClass)
    if not self.bInit then
        self:RegEvent()
        self:BindUIEvent()
        self.bInit = true
    end

    self:UpdateInfo(nShopID, szName, tClass)
end

function UIShopClassSelector:OnExit()
    self.bInit = false
end

function UIShopClassSelector:BindUIEvent()
    UIHelper.BindUIEvent(self.TogTab, EventType.OnSelectChanged, function (_, bSelected)
        if self.bIsClass then
            Event.Dispatch(EventType.OnShopClassSelectChanged, self.nShopID, self, bSelected)
        else            
            Event.Dispatch(EventType.OnSubShopSelectChanged, self.nShopID, self, bSelected)
        end        
    end)
end

function UIShopClassSelector:RegEvent()
    Event.Reg(self, EventType.OnShopRedPointChanged, function ()
        UIHelper.SetVisible(self.ImgRedPoint, self:HasRedPoint())
    end)
end

function UIShopClassSelector:UpdateInfo(nShopID, szName, tClass)
    local bIsClass = tClass ~= nil
    self.nShopID = nShopID
    self.bIsClass = bIsClass
    self.tClass = tClass

    UIHelper.SetString(self.LabelName1, szName)
    UIHelper.SetString(self.LabelName2, szName)
    UIHelper.SetVisible(self.ImgRedPoint, self:HasRedPoint())
end

function UIShopClassSelector:HasRedPoint()
    local bHasRedPoint = self.bIsClass

    for _, tShop in ipairs(self.tClass or {}) do
        bHasRedPoint = bHasRedPoint and (tShop.nShopID and RedpointHelper.SystemShop_HasRedPoint(tShop.nShopID))
    end
    
    return bHasRedPoint
end

return UIShopClassSelector