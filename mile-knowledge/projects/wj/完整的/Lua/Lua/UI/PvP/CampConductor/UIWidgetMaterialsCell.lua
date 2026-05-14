-- ---------------------------------------------------------------------------------
-- Name: UIWidgetMaterialsCell
-- Desc: 物资cell
-- Prefab:WidgetCampMaterialCell
-- ---------------------------------------------------------------------------------

local UIWidgetMaterialsCell = class("UIWidgetMaterialsCell")

local Index2BgImg = {
    [1] = "UIAtlas2_Pvp_CampConductor_PVPMaterials_bg_cuichengche",
    [2] = "UIAtlas2_Pvp_CampConductor_PVPMaterials_bg_shenjiche",
    [3] = "UIAtlas2_Pvp_CampConductor_PVPMaterials_bg_shyenjitai",
    [4] = "UIAtlas2_Pvp_CampConductor_PVPMaterials_bg_tianhuoyin"
}

local Index2Img = {
    [1] = "UIAtlas2_Pvp_CampConductor_PVPMaterials_img_cuichengche",
    [2] = "UIAtlas2_Pvp_CampConductor_PVPMaterials_img_shenjiche",
    [3] = "UIAtlas2_Pvp_CampConductor_PVPMaterials_img_shenjitai",
    [4] = "UIAtlas2_Pvp_CampConductor_PVPMaterials_img_tianhuoyin"
}

function UIWidgetMaterialsCell:_LuaBindList()
    -- self.ImgIcon           = self.ImgIcon  --- 图片
    self.LabelMaterialName = self.LabelMaterialName --- 名字

    self.LabelMaterialNum  = self.LabelMaterialNum --- 已有/最大

    self.LabelAllotNum     = self.LabelAllotNum --- 剩余可分配

    self.LayoutDailyLimite = self.LayoutDailyLimite -- 今日使用layout

    self.LabelDailyLimiteNum = self.LabelDailyLimiteNum
end

function UIWidgetMaterialsCell:OnEnter()
    if not self.bInit then
        self:BindUIEvent()
        self:RegEvent()
        self.bInit = true
    end
end

function UIWidgetMaterialsCell:OnExit()
    self.bInit = false
    self:UnRegEvent()
end

function UIWidgetMaterialsCell:BindUIEvent()
    UIHelper.BindUIEvent(self._rootNode, EventType.OnSelectChanged, function (_, bSelected)
        if bSelected and self.func then
            self.func(self.nIndex)
        end
    end)
end

function UIWidgetMaterialsCell:RegEvent()
    
end

function UIWidgetMaterialsCell:UnRegEvent()

end






-- ----------------------------------------------------------
-- Please write your own code below  ↓↓↓
-- ----------------------------------------------------------
function UIWidgetMaterialsCell:SetMaterialsCallback(func)
	self.func = func
end

function UIWidgetMaterialsCell:UpdateCell(nIndex)
    self.nIndex = nIndex

    local tConstData = CommandBaseData.tGoodsInitSetting[nIndex]
    local tInfo = CommandBaseData.tGoodsSetting[nIndex]

    UIHelper.SetSpriteFrame(self.ImgBgMaterial, Index2BgImg[nIndex])
    UIHelper.SetSpriteFrame(self.ImgMaterial, Index2Img[nIndex])

    -- local itemInfo = GetItemInfo(5, tConstData.dwID)
    -- local szName = ItemData.GetItemNameByItemInfo(itemInfo)
    UIHelper.SetString(self.LabelMaterialName, CommandBaseData.tGoodsTypeToName[nIndex])

    local szBuy = tInfo.nBuy .. "/" .. tConstData.nMaxCount
    UIHelper.SetString(self.LabelMaterialNum, szBuy)

    local nCanAllot = tInfo.nBuy - tInfo.nAllot
    UIHelper.SetString(self.LabelAllotNum, nCanAllot)

    if tConstData.dwID == 24799 then	--大车有【今日使用数量】限制
        UIHelper.SetVisible(self.LayoutDailyLimite, true)
        local szUse = tInfo.nUse .. "/" .. tConstData.nMaxUseCount
        UIHelper.SetString(self.LabelDailyLimiteNum, szUse)
    else
        UIHelper.SetVisible(self.LayoutDailyLimite, false)
    end

    if tInfo.nBuy >= tConstData.nMaxCount then
        CommandBaseData.tGoodsSetting[nIndex].bCanBuy = false
    else
        CommandBaseData.tGoodsSetting[nIndex].bCanBuy = true
        CommandBaseData.tGoodsSetting[nIndex].nCanBuy = tConstData.nMaxCount - tInfo.nBuy
    end

    UIHelper.LayoutDoLayout(self.LayoutAllotNum)
end

return UIWidgetMaterialsCell