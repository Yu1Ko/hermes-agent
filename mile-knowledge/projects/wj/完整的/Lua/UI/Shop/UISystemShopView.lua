local UISystemShopView = class("UISystemShopView")


function UISystemShopView:OnEnter(tSystemShopInfo)
    if not self.bInit then
        self:RegEvent()
        self:BindUIEvent()
        self.bInit = true
    end

    self.tSystemShopInfo = tSystemShopInfo
    self:UpdateInfo()
end

function UISystemShopView:OnExit()
    self.bInit = false
    if self.fExitCallBack then
        self.fExitCallBack()
    end    
end

function UISystemShopView:BindUIEvent()
    UIHelper.BindUIEvent(self.BtnClose, EventType.OnClick, function ()
        UIMgr.Close(self)
    end)
end

function UISystemShopView:RegEvent()
    --Event.Reg(self, EventType.XXX, func)
end

function UISystemShopView:UpdateInfo()
    local tGroupList = {}
    local nFullScreen = self.tSystemShopInfo.nFullScreen
    for i, tGroup in ipairs(self.tSystemShopInfo) do       
        table.insert(tGroupList, tGroup) 
        if i <= math.ceil(#self.tSystemShopInfo / 2) then
            UIHelper.AddPrefab(PREFAB_ID.WidgetEquipStoreCell, self.LayoutEquipStoreCell1, tGroupList, nFullScreen)
        else
            UIHelper.AddPrefab(PREFAB_ID.WidgetEquipStoreCell, self.LayoutEquipStoreCell2, tGroupList, nFullScreen)
        end
        tGroupList = {}     
	end
    UIHelper.LayoutDoLayout(self.LayoutEquipStoreCell1)
    UIHelper.LayoutDoLayout(self.LayoutEquipStoreCell2)
end

function UISystemShopView:SetExitCallBack(fExitCallBack)
    self.fExitCallBack = fExitCallBack
end

return UISystemShopView