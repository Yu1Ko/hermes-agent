-- ---------------------------------------------------------------------------------
-- Author: Unknown
-- Name: UIHomelandBuildFurnitureStorageView
-- Date: 2023-06-20 19:49:37
-- Desc: ?
-- ---------------------------------------------------------------------------------

local UIHomelandBuildFurnitureStorageView = class("UIHomelandBuildFurnitureStorageView")

function UIHomelandBuildFurnitureStorageView:OnEnter()
    if not self.bInit then
        self:RegEvent()
        self:BindUIEvent()
        self.bInit = true
    end

    self:UpdateInfo()
end

function UIHomelandBuildFurnitureStorageView:OnExit()
    self.bInit = false
end

function UIHomelandBuildFurnitureStorageView:BindUIEvent()
    UIHelper.BindUIEvent(self.BtnClose, EventType.OnClick, function ()
        UIMgr.Close(self)
    end)

    UIHelper.BindUIEvent(self.BtnReceive, EventType.OnClick, function ()
        self:GetAllStorage()
    end)
end

function UIHomelandBuildFurnitureStorageView:RegEvent()
    Event.Reg(self, "ADD_STORAGE_GOODS", function ()
        local dwStorageID = arg0
        if FurnitureBuy.IsFurnitrueGoods(dwStorageID) then
            self:UpdateInfo()
        end
    end)

    Event.Reg(self, "DEL_STORAGE_GOODS", function ()
        self:UpdateInfo()
    end)
end

function UIHomelandBuildFurnitureStorageView:UpdateInfo()
    self.tbCells = self.tbCells or {}
    UIHelper.HideAllChildren(self.ScrollViewFurnitureStorageCell)

    local i = 1
    local tFurnitureStorageList = FurnitureBuy.GetFurnitureStorageList()
    for _, dwStorageID in ipairs(tFurnitureStorageList) do
        local tStorage = FurnitureBuy.GetStorageGoodsInfo(dwStorageID)
        if tStorage then
            local cell = self.tbCells[i]
            if not cell then
                cell = UIHelper.AddPrefab(PREFAB_ID.WidgetFurnitureStorageCell, self.ScrollViewFurnitureStorageCell)
                self.tbCells[i] = cell
            end

            UIHelper.SetVisible(cell._rootNode, true)
            cell:OnEnter(dwStorageID, tStorage.dwGoodsID)

            i = i + 1
        end
    end

    UIHelper.ScrollViewDoLayoutAndToTop(self.ScrollViewFurnitureStorageCell)

    if #tFurnitureStorageList > 0 then
        UIHelper.SetButtonState(self.BtnReceive, BTN_STATE.Normal)
        UIHelper.SetVisible(self.WidgetEmpty, false)
    else
        UIHelper.SetButtonState(self.BtnReceive, BTN_STATE.Disable, "暂无可领取家具")
        UIHelper.SetVisible(self.WidgetEmpty, true)
    end
end

function UIHomelandBuildFurnitureStorageView:GetAllStorage()
    local tFurnitureStorageList = FurnitureBuy.GetFurnitureStorageList()
    for _, dwStorageID in ipairs(tFurnitureStorageList) do
        local tStorage = FurnitureBuy.GetStorageGoodsInfo(dwStorageID)
        if tStorage then
            FurnitureBuy.StorageGet(dwStorageID)
        end
    end
end

return UIHomelandBuildFurnitureStorageView