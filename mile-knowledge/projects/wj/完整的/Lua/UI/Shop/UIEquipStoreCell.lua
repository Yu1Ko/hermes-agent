local UIEquipStoreCell = class("UIEquipStoreCell")

function UIEquipStoreCell:OnEnter(tGroupList, nFullScreen)
    if not self.bInit then
        self:RegEvent()
        self:BindUIEvent()
        self.bInit = true
    end

    self.tGroupList = tGroupList
    self.nFullScreen = nFullScreen
    self.szGroupName = GBKToUTF8(tGroupList and tGroupList[1].szGroupName or "")

    local tbInfo = Const.Shop.EquipmentShopInfo[self.szGroupName]
    self.szImg = tbInfo and tbInfo.szImg or ""
    self.nSystemOpenID = tbInfo and tbInfo.nSystemOpenID or 0

    self:UpdateInfo()
end

function UIEquipStoreCell:OnExit()
    self.bInit = false
end

function UIEquipStoreCell:BindUIEvent()
    UIHelper.BindUIEvent(self.Button, EventType.OnClick, function ()
        if not SystemOpen.IsSystemOpen(self.nSystemOpenID, true) then
            return
        end
        if #self.tGroupList[1] == 0 then
            TipsHelper.ShowNormalTip("该分类暂无开放中的商店")
            return
        end
        --if UIMgr.GetView(VIEW_ID.PanelPlayStore) then
        --    UIMgr.CloseWithCallBack(VIEW_ID.PanelPlayStore, function ()
        --        local scriptView = UIMgr.Open(VIEW_ID.PanelPlayStore, 0, self.tGroupList[1], self.nFullScreen)
        --        if scriptView then
        --            UIHelper.SetSpriteFrame(scriptView.imgClose, ShopData.szReturnPrevPanel)
        --        end
        --    end)
        --else
        --    local scriptView =  UIMgr.Open(VIEW_ID.PanelPlayStore, 0, self.tGroupList[1], self.nFullScreen)
        --    if scriptView then
        --        UIHelper.SetSpriteFrame(scriptView.imgClose, ShopData.szReturnPrevPanel)
        --    end
        --end

        local scriptView = UIMgr.OpenSingleWithOnEnter(false, VIEW_ID.PanelPlayStore, 0, self.tGroupList[1], self.nFullScreen)
        if scriptView then
            UIHelper.SetSpriteFrame(scriptView.imgClose, ShopData.szReturnPrevPanel)
        end
    end)
end

function UIEquipStoreCell:RegEvent()
    Event.Reg(self, EventType.OnShopRedPointChanged, function ()
        UIHelper.SetVisible(self.ImgRedPoint, self:HasRedPoint())
    end)
end

function UIEquipStoreCell:UpdateInfo()
    UIHelper.SetVisible(self.Button, #self.tGroupList >= 1)

    local bIsSystemOpen = SystemOpen.IsSystemOpen(self.nSystemOpenID)
    local szTitle = SystemOpen.GetSystemOpenTitle(self.nSystemOpenID)
    if bIsSystemOpen then
        UIHelper.SetString(self.LabelStoreName, self.szGroupName)
        UIHelper.SetSpriteFrame(self.ImgStoreIcon, self.szImg)

        UIHelper.SetVisible(self.LabelStoreName, true)
        UIHelper.SetVisible(self.ImgStoreIcon, true)
        UIHelper.SetVisible(self.WidgetLocked, false)
    else
        UIHelper.SetString(self.LabelLevel, szTitle)
        UIHelper.SetString(self.LabelStoreName_Locked, self.szGroupName)
        UIHelper.SetSpriteFrame(self.ImgStoreIcon_Locked, self.szImg)

        UIHelper.SetVisible(self.LabelStoreName, false)
        UIHelper.SetVisible(self.ImgStoreIcon, false)
        UIHelper.SetVisible(self.WidgetLocked, true)
    end

    UIHelper.SetVisible(self.ImgRedPoint, self:HasRedPoint())
end

function UIEquipStoreCell:HasRedPoint()
    local bHasRedPoint = false
    for _, tGroup in ipairs(self.tGroupList or {}) do
        for _, tClass in ipairs(tGroup) do
            local bRedPoint = true
            for _, tShop in ipairs(tClass) do
                bRedPoint = bRedPoint and tShop.nShopID and RedpointHelper.SystemShop_HasRedPoint(tShop.nShopID)
            end
            bHasRedPoint = bHasRedPoint or bRedPoint
        end
    end

    return bHasRedPoint
end


return UIEquipStoreCell