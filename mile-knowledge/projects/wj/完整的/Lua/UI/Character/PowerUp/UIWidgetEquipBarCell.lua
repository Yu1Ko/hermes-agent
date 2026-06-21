-- ---------------------------------------------------------------------------------
-- Author: Jiayuran
-- Name: UICharacterWidgetEquipRefine
-- Date: 2022-12-06 14:39
-- Desc: UICharacterWidgetEquipRefine
-- ---------------------------------------------------------------------------------

local UIWidgetEquipBarCell = class("UIWidgetEquipBarCell")
local MAX_SLOT_NUM = 3 --最大熔嵌孔数量

local tStoneIcon = {
    [1] = "UIAtlas2_Character_PowerUp_Common_Img_Wuxing01.png",
    [2] = "UIAtlas2_Character_PowerUp_Common_Img_Wuxing02.png",
    [3] = "UIAtlas2_Character_PowerUp_Common_Img_Wuxing03.png",
    [4] = "UIAtlas2_Character_PowerUp_Common_Img_Wuxing04.png",
    [5] = "UIAtlas2_Character_PowerUp_Common_Img_Wuxing05.png",
    [6] = "UIAtlas2_Character_PowerUp_Common_Img_Wuxing06.png",
    [7] = "UIAtlas2_Character_PowerUp_Common_Img_Wuxing07.png",
    [8] = "UIAtlas2_Character_PowerUp_Common_Img_Wuxing08.png",
}

local szNoRefine = "#FFFFFF"
local szNotFull = "#95FF95"
local szFull = "#FFE26E"

function UIWidgetEquipBarCell:OnEnter(nEquip, dwTabType, dwIndex, bIsFusion)
    if not self.bInit then
        self:RegEvent()
        self:BindUIEvent()
        self.bInit = true
    end

    self.nEquip = nEquip
    self.dwTabType = dwTabType
    self.dwIndex = dwIndex
    self.bIsFusion = bIsFusion

    self:UpdateInfo()
    self:UpdateEffective()
end

function UIWidgetEquipBarCell:InitExtractEquip(nEquip, tbPos)
    if not self.bInit then
        self:RegEvent()
        self:BindUIEvent()
        self.bInit = true
    end

    self.nEquip = nEquip
    self.tbPos = tbPos
    self.GetItemInfo = function(self)
        return self.tbPos
    end

    self:UpdateInfo()
end

function UIWidgetEquipBarCell:OnExit()
    self.bInit = false
end

function UIWidgetEquipBarCell:BindUIEvent()
end

function UIWidgetEquipBarCell:RegEvent()
    Event.Reg(self, "FE_STRENGTH_EQUIP", function(arg0)
        if arg0 == DIAMOND_RESULT_CODE.SUCCESS then
            self:UpdateInfo()
        end
    end)

    Event.Reg(self, "MOUNT_DIAMON", function(arg0)
        if arg0 == DIAMOND_RESULT_CODE.SUCCESS then
            self:UpdateInfo()
            self:UpdateEffective()
        end
    end)

    Event.Reg(self, "EQUIP_UNSTRENGTH", function(arg0, arg1)
        if arg0 == DIAMOND_RESULT_CODE.SUCCESS then
            self:UpdateInfo()
            self:UpdateEffective()
        end
    end)

    Event.Reg(self, "WEAPON_BIND_COLOR_DIAMOND", function(arg0, arg1)
        self:UpdateEffective()
    end)

    Event.Reg(self, "DELETE_WEAPON_BIND_COLOR_DIAMOND", function(arg0, arg1)
        self:UpdateEffective()
    end)
end

local function GetRefineBoxInfo(nEquip)
    if nEquip == EQUIPMENT_INVENTORY.BIG_SWORD then
        --藏剑重剑对应轻剑装备栏
        nEquip = EQUIPMENT_INVENTORY.MELEE_WEAPON
    end

    local nBoxLevel, nBoxQuality = g_pClientPlayer.GetEquipBoxStrength(nEquip)
    local nBoxMaxLevel, nBoxMaxQuality = GetEquipBoxMaxStrengthInfo(nEquip)
    return {
        nLevel = nBoxLevel,
        nMaxLevel = nBoxMaxLevel,
        nQuality = nBoxQuality,
        nMaxQuality = nBoxMaxQuality,
    }
end

local function GetSlotBoxInfo(nEquip, nSlotIndex, pPlayer)
    if not pPlayer then
        pPlayer = g_pClientPlayer
    end
    if nEquip == EQUIPMENT_INVENTORY.BIG_SWORD then
        --藏剑重剑对应轻剑装备栏
        nEquip = EQUIPMENT_INVENTORY.MELEE_WEAPON
    end
    local dwEnchantID, nBoxQuality = pPlayer.GetEquipBoxMountDiamondEnchantID(nEquip, nSlotIndex)
    local nMaxQuality, bCanMount = GetEquipBoxDiamondSlotInfo(nEquip, nSlotIndex)
    return {
        dwEnchantID = dwEnchantID,
        nQuality = nBoxQuality,
        nMaxQuality = nMaxQuality,
        bCanMount = bCanMount,
    }
end

function UIWidgetEquipBarCell:UpdateInfo()
    local szPath = EquipToDefaultIcon[self.nEquip]
    local tEquipBoxInfo = GetRefineBoxInfo(self.nEquip)
    -- local pItem = DataModel.GetEquipItem(self.nEquip)
    UIHelper.SetSpriteFrame(self.ImgEquipBarIcon, szPath)

    local szColor = szNoRefine
    if tEquipBoxInfo.nLevel == tEquipBoxInfo.nMaxLevel then
        szColor = szFull
    elseif tEquipBoxInfo.nLevel > 0 then
        szColor = szNotFull
    end

    UIHelper.SetRichText(self.LabelEquipSlotLevel,
        string.format("<color=%s>%d/%d</color>", szColor, tEquipBoxInfo.nLevel, tEquipBoxInfo.nMaxLevel))
    UIHelper.SetVisible(self.ImgMaxFrame, tEquipBoxInfo.nLevel >= 6)

    for i = 1, MAX_SLOT_NUM, 1 do
        local tInfo = GetSlotBoxInfo(self.nEquip, i - 1)
        if tInfo and tInfo.bCanMount then
            UIHelper.SetVisible(self.WidgetWuXings[i], true)

            local dwTabType, dwTabIndex = GetDiamondInfoFromEnchantID(tInfo.dwEnchantID)
            if dwTabType and dwTabIndex then
                local pItemInfo = ItemData.GetItemInfo(dwTabType, dwTabIndex)
                local nSlotLevel = pItemInfo.nDetail
                UIHelper.SetSpriteFrame(self.WuXingIcons[i], tStoneIcon[nSlotLevel])
            else
                UIHelper.SetSpriteFrame(self.WuXingIcons[i], nil)
            end
        end
    end

    UIHelper.LayoutDoLayout(self.LayoutInlayHat)
end

function UIWidgetEquipBarCell:UpdateEffective()
    local bEquipRefineNotEffective, bFusionNotEffective = DataModel.CheckIsRefineOrFusionIneffective(self.nEquip)
    local item = DataModel.GetEquipItem(self.nEquip)

    if self.bIsFusion then
        if self.nEquip == EQUIPMENT_INVENTORY.BIG_SWORD or self.nEquip == EQUIPMENT_INVENTORY.MELEE_WEAPON and item then
            bFusionNotEffective = bFusionNotEffective or
                EquipData.CheckIsWeaponNotActiveSlot(g_pClientPlayer, item, self.nEquip)
        end

        UIHelper.SetVisible(self.WidgetNotEffective, bFusionNotEffective)
        UIHelper.SetOpacity(self.ImgMaxFrame, bFusionNotEffective and 120 or 255)
    else
        UIHelper.SetVisible(self.WidgetNotEffective, bEquipRefineNotEffective)
        UIHelper.SetOpacity(self.ImgMaxFrame, bEquipRefineNotEffective and 120 or 255)
    end
end

return UIWidgetEquipBarCell
