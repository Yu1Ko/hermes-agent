-- ---------------------------------------------------------------------------------
-- Author: Unknown
-- Name: UIHomelandBuildFurnitureStorageCell
-- Date: 2023-06-25 10:40:53
-- Desc: ?
-- ---------------------------------------------------------------------------------

local UIHomelandBuildFurnitureStorageCell = class("UIHomelandBuildFurnitureStorageCell")

function UIHomelandBuildFurnitureStorageCell:OnEnter(dwStorageID, dwFurnitureID)
    if not self.bInit then
        self:RegEvent()
        self:BindUIEvent()
        self.bInit = true
    end

    self.dwStorageID = dwStorageID
    self.dwFurnitureID = dwFurnitureID

    self:UpdateInfo()
end

function UIHomelandBuildFurnitureStorageCell:OnExit()
    self.bInit = false
end

function UIHomelandBuildFurnitureStorageCell:BindUIEvent()

end

function UIHomelandBuildFurnitureStorageCell:RegEvent()


end

function UIHomelandBuildFurnitureStorageCell:UpdateInfo()
    local tStorage = FurnitureBuy.GetStorageGoodsInfo(self.dwStorageID)


    local tFurnitureInfo =  FurnitureData.GetFurnInfoByTypeAndID(HS_FURNITURE_TYPE.FURNITURE, self.dwFurnitureID)
    if not tFurnitureInfo then
        return
    end
    local szName = UIHelper.GBKToUTF8(tFurnitureInfo.szName)
    local dwFurnitureUiId = GetHomelandMgr().MakeFurnitureUIID(HS_FURNITURE_TYPE.FURNITURE, self.dwFurnitureID)
    local tAddInfo = Table_GetFurnitureAddInfo(dwFurnitureUiId)
    local szType = g_tStrings.tGoodsType[tStorage.eGoodsType]

    UIHelper.SetTexture(self.ImgFurnitureIcon, UIHelper.FixDXUIImagePath(tAddInfo.szPath))

    UIHelper.SetString(self.LabelName, szName, 8)
    UIHelper.SetString(self.LabelClassify, szType)
    UIHelper.SetString(self.LabelNum, tostring(tStorage.nBuyCount))
    UIHelper.SetString(self.LabelRemarks, "")

end


return UIHomelandBuildFurnitureStorageCell