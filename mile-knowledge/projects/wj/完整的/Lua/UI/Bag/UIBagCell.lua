-- ---------------------------------------------------------------------------------
-- Author: Unknown
-- Name: UIBagCell
-- Date: 2022-11-10 09:14:27
-- Desc: ?
-- ---------------------------------------------------------------------------------

local UIBagCell = class("UIBagCell")
local tbIconList = {
    [1] = "UIAtlas2_Bag_SpecialBag_Book",
    [2] = "UIAtlas2_Bag_SpecialBag_Medicine",
    [3] = "UIAtlas2_Bag_SpecialBag_Stone",
    [4] = "UIAtlas2_Bag_SpecialBag_Linglongmibao"
}

function UIBagCell:OnEnter(nBox, nIndex, bAccountWareHouseItem, dwASPSource)
    if not self.bInit then
        self:RegEvent()
        self:BindUIEvent()
        self.bInit = true
    end

    self.nBox = nBox
    self.nIndex = nIndex
    self.bAccountWareHouseItem = bAccountWareHouseItem or false
    self.dwASPSource = dwASPSource

    self:UpdateInfo()
end

function UIBagCell:OnInitWithTabID(nTabType, nTabID, nStackNum)
    self.nTabType = nTabType
    self.nTabID = nTabID
    self.nStackNum = nStackNum
    self:UpdateInfoByTabType()
end

function UIBagCell:OnExit()
    self.bInit = false
    if self.itemScript then
        self.itemScript:SetSelectChangeCallback(nil) -- 防止触发回调
        ItemData.GetItemPrefabPool():Recycle(self.itemScript._rootNode)
        self.itemScript = nil
    end
end

function UIBagCell:OnPoolRecycled()
    self.bInit = false
    self.bAccountWareHouseItem = false
    self.dwASPSource = nil

    self:SetClickCallBack(nil)
    self:SetLockVis(false)
    self:SetSelectedVis(false)
    UIHelper.SetVisible(self._rootNode, true)
    self:UpdateBagImgType(-1)
    if self.itemScript then
        ItemData.GetItemPrefabPool():Recycle(self.itemScript._rootNode)
        self.itemScript = nil
    end
end

function UIBagCell:BindUIEvent()
    UIHelper.BindUIEvent(self.BtmBagBottom, EventType.OnClick, function()
        if self.fnCallback then
            self.fnCallback(self)
        end
    end)
end

function UIBagCell:RegEvent()
    Event.Reg(self, EventType.OnBoxSelectChanged, function(bSelect, nBox, nIndex)
        if nBox and nIndex and self.nBox and self.nIndex and self.nBox == nBox and self.nIndex == nIndex then
           self:SetSelectedVis(bSelect)
        elseif not nBox and not nIndex then
           self:SetSelectedVis(bSelect)
        end
    end)

    Event.Reg(self, EventType.OnBoxLockChanged, function(bSelect, nBox, nIndex)
        if self.nBox and self.nIndex then
            self:SetLockVis(BagViewData.IsLockBox(self.nBox, self.nIndex))
        end
    end)
end

function UIBagCell:UpdateInfo()
    local item = ItemData.GetPlayerItem(g_pClientPlayer, self.nBox, self.nIndex
        , self.bAccountWareHouseItem and UI_BOX_TYPE.SHAREPACKAGE or nil, self.dwASPSource)

    local prefabPool = ItemData.GetItemPrefabPool()

    if item then
        local bLoadImgAsync = not Platform.IsWindows() -- windows平台下因为可使用鼠标滚轮移动列表，需要同步加载才能保证图片的及时刷新效果
        self.itemScript = self.itemScript or select(2, prefabPool:Allocate(self.WidgetBagItem)) ---@type UIItemIcon
        self.itemScript:OnInit(self.nBox, self.nIndex, false, self.bAccountWareHouseItem, self.dwASPSource, bLoadImgAsync)
        self.itemScript:ShowEquipScoreArrow(true)
        self.itemScript:UpdatePVPImg(item)
        UIHelper.SetNodeSwallowTouches(self.itemScript._rootNode, false, true)
    elseif self.itemScript then
        prefabPool:Recycle(self.itemScript._rootNode)
        self.itemScript = nil
    end
    UIHelper.SetSwallowTouches(self.BtmBagBottom , false)
end

function UIBagCell:UpdateInfoByTabType()
    local hItemInfo = GetItemInfo(self.nTabType, self.nTabID)
    local prefabPool = ItemData.GetItemPrefabPool()

    if hItemInfo then
        self.itemScript = self.itemScript or select(2, prefabPool:Allocate(self.WidgetBagItem)) ---@type UIItemIcon
        self.itemScript:OnInitWithTabID(self.nTabType, self.nTabID, self.nStackNum)
        self.itemScript:ShowEquipScoreArrow(true)
        UIHelper.SetNodeSwallowTouches(self.itemScript._rootNode, false, true)

    elseif self.itemScript then
        prefabPool:Recycle(self.itemScript._rootNode)
        self.itemScript = nil
    end
    UIHelper.SetSwallowTouches(self.BtmBagBottom , false)
end

function UIBagCell:GetItemScript()
    return self.itemScript
end

function UIBagCell:UpdateBagImgType(nType)
    local szPath = tbIconList[nType]
    if szPath then
        UIHelper.SetVisible(self.ImgType, true)
        UIHelper.SetSpriteFrame(self.ImgType, szPath)
    else
        UIHelper.SetVisible(self.ImgType, false)
    end
end

function UIBagCell:SetTouchDownHideTips(bHideTips)
    UIHelper.SetTouchDownHideTips(self._rootNode, bHideTips)
end

function UIBagCell:SetClickCallBack(fnCallback)
    self.fnCallback = fnCallback
end

function UIBagCell:GetBagIndex()
    return self.nBox, self.nIndex
end

function UIBagCell:SetSelectedVis(bShow)
    if UIHelper.GetVisible(self.ImgSelectedFrame) == bShow then
        return
    end
    UIHelper.SetVisible(self.ImgSelectedFrame, bShow)
end

function UIBagCell:SetLockVis(bShow)
    if UIHelper.GetVisible(self.ImgBagLock) == bShow then
        return
    end
    UIHelper.SetVisible(self.ImgBagLock, bShow)
end

return UIBagCell