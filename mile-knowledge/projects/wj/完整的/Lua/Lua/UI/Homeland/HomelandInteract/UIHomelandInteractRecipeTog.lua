-- ---------------------------------------------------------------------------------
-- Author: Unknown
-- Name: UIHomelandInteractRecipeTog
-- Date: 2023-08-31 15:32:45
-- Desc: ?
-- ---------------------------------------------------------------------------------
local tbFoodFilter = {
	[6] = {
		szCheck    = "CheckBox_HouseKeep",
		DATAMANAGE = 1155,
		ITEMSTART  = 0,
		BYTE_NUM   = 2,
	},
	[7] = {
		szCheck    = "CheckBox_ShopKeeper",
		DATAMANAGE = 1157,
		ITEMSTART  = 0,
		BYTE_NUM   = 1,
	},
}
local UIHomelandInteractRecipeTog = class("UIHomelandInteractRecipeTog")

function UIHomelandInteractRecipeTog:OnEnter(item, bDIY, tbRecipeInfo, bBrew)
    if not self.bInit then
        self:RegEvent()
        self:BindUIEvent()
        self.bInit = true
    end

    self.item = item
    self.bDIY = bDIY or false
    self.bBrew = bBrew or false
    self:UpdateInfo(item, tbRecipeInfo)
end

function UIHomelandInteractRecipeTog:OnExit()
    self.bInit = false
end

function UIHomelandInteractRecipeTog:BindUIEvent()
    UIHelper.BindUIEvent(self.ToggleHomeRecipeCell, EventType.OnClick, function()
        self.funcCallBack()
    end)
end

function UIHomelandInteractRecipeTog:RegEvent()
    --Event.Reg(self, EventType.XXX, func)
end

function UIHomelandInteractRecipeTog:UpdateInfo(item, tbRecipeInfo)
    local nMakeCount = 0
    local nHadCount = 0
    local szFoodName = UIHelper.GBKToUTF8(item.szName)

    local bShowRedDot = UIHelper.GetVisible(self.ImgRedDot)
    UIHelper.SetVisible(self.LabelCookTime, false)

    if tbRecipeInfo then
        if tbRecipeInfo.nNeedTime and tbRecipeInfo.nNeedTime > 0 then
            UIHelper.SetVisible(self.LabelCookTime, not bShowRedDot)
            UIHelper.SetString(self.LabelCookTime, string.format("需要%d小时", tbRecipeInfo.nNeedTime))
        end

        if self.bBrew then
            nMakeCount = self:GetMakeCount(tbRecipeInfo.tRecipe)
        else
            nMakeCount = self:GetMakeCount(tbRecipeInfo)
        end
    end

    nHadCount = ItemData.GetItemAllStackNum(item, false)
    if nHadCount > 0 then
        szFoodName = szFoodName..string.format("(%d)", nHadCount)
    end
    UIHelper.SetString(self.LabelTittle, szFoodName)
    UIHelper.SetString(self.LabelTittleSelected, szFoodName)
end

local function GetHouseBagNum(nItemID)
    local nClassBagNum = 0
    for nClassType, tFilter in pairs(tbFoodFilter) do
        local tHomeLandClassBag = Table_GetHomelandLockerInfoByClass(nClassType)
        for _, v in pairs(tHomeLandClassBag) do
            if v and v.dwItemID == nItemID then
                nClassBagNum = GetClientPlayer().GetRemoteArrayUInt(tFilter.DATAMANAGE, tFilter.ITEMSTART + (v.dwDataIndex - 1) * tFilter.BYTE_NUM, tFilter.BYTE_NUM)
                return nClassBagNum
            end
        end
    end
    return nClassBagNum
end

function UIHomelandInteractRecipeTog:GetMakeCount(tbRecipeInfo)
    local nMaxCount
    for index, tbInfo in ipairs(tbRecipeInfo) do
        local nItemID = self.bBrew and tbInfo[2] or tbInfo[1]
        local nCostNum = self.bBrew and tbInfo[3] or tbInfo[2]
        local nHaveCount = ItemData.GetItemAmountInPackage(ITEM_TABLE_TYPE.OTHER, nItemID) + GetHouseBagNum(nItemID)

        local nMaxMakeCount = math.floor(nHaveCount / nCostNum)
        nMaxCount = nMaxCount and math.min(nMaxMakeCount, nMaxCount) or nMaxMakeCount
    end
    return nMaxCount or 0
end

function UIHomelandInteractRecipeTog:SetSelected(bSelect)
    UIHelper.SetSelected(self.ToggleHomeRecipeCell, bSelect)
end

function UIHomelandInteractRecipeTog:GetSelected()
    return UIHelper.GetSelected(self.ToggleHomeRecipeCell)
end

function UIHomelandInteractRecipeTog:SetfuncCallBack(funcCallBack)
    self.funcCallBack = funcCallBack
end

function UIHomelandInteractRecipeTog:SetRedDotVisible(bVisible)
    UIHelper.SetVisible(self.ImgRedDot, bVisible)
    if bVisible then
        UIHelper.SetVisible(self.LabelCookTime, false)
    end
end

--教学用
function UIHomelandInteractRecipeTog:GetItemIDInfo()
    return self.item and {
        dwTabType = ITEM_TABLE_TYPE.OTHER,
        dwIndex = self.item.dwID,
    }
end

return UIHomelandInteractRecipeTog