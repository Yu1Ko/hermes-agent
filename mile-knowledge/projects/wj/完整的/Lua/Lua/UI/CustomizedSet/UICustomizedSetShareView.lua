-- ---------------------------------------------------------------------------------
-- Author: Unknown
-- Name: UICustomizedSetShareView
-- Date: 2024-08-07 16:24:23
-- Desc: ?
-- ---------------------------------------------------------------------------------

local UICustomizedSetShareView = class("UICustomizedSetShareView")

local EquipEnum = {
    -- 普通近战武器
    EQUIPMENT_INVENTORY.MELEE_WEAPON,
    -- 远程武器
    EQUIPMENT_INVENTORY.RANGE_WEAPON,
    -- 重剑
    EQUIPMENT_INVENTORY.BIG_SWORD,

    -- 项链
    EQUIPMENT_INVENTORY.AMULET,
    -- 腰坠
    EQUIPMENT_INVENTORY.PENDANT,
    -- 戒指
    EQUIPMENT_INVENTORY.LEFT_RING,
    -- 戒指
    EQUIPMENT_INVENTORY.RIGHT_RING,

    -- 头部
    EQUIPMENT_INVENTORY.HELM,
    -- 护腕
    EQUIPMENT_INVENTORY.BANGLE,
    -- 上衣
    EQUIPMENT_INVENTORY.CHEST,
    -- 下装
    EQUIPMENT_INVENTORY.PANTS,
    -- 腰带
    EQUIPMENT_INVENTORY.WAIST,
    -- 鞋子
    EQUIPMENT_INVENTORY.BOOTS,
}

function UICustomizedSetShareView:OnEnter(bPreview, tEquip, tInfo, dwForceID, dwKungfuID)
    if not self.bInit then
        self:RegEvent()
        self:BindUIEvent()
        self.bInit = true
    end

    self.bPreview = bPreview
    self.tEquip = tEquip
    self.tInfo = tInfo
    self.dwForceID = dwForceID
    self.dwKungfuID = dwKungfuID

    if not self.bPreview and not tEquip then
        self.tEquip = EquipCodeData.tCurEquip
        self.tInfo = EquipCodeData.tCurInfo
        self.dwForceID = EquipCodeData.dwCurForceID
        self.dwKungfuID = EquipCodeData.dwCurKungfuID
    end
    self:UpdateInfo()
end

function UICustomizedSetShareView:OnExit()
    self.bInit = false
end

function UICustomizedSetShareView:BindUIEvent()
    UIHelper.BindUIEvent(self.BtnClose, EventType.OnClick, function(btn)
        UIMgr.Close(self)
    end)

    UIHelper.BindUIEvent(self.BtnImport, EventType.OnClick, function(btn)
        local hPlayer = GetClientPlayer()
        local bForceLegal = self.dwForceID == PlayerData.GetPlayerForceID() or (self.dwForceID == FORCE_TYPE.WU_XIANG and hPlayer.GetSkillLevel(102393) > 0)
        if not bForceLegal then
            TipsHelper.ShowNormalTip("当前配装方案与自身门派不一致或未学习该流派，无法保存")
            return
        end

        local tbSetData = EquipCodeData.ExportCustomizedSetEquip(self.tEquip, self.dwKungfuID)
        if not tbSetData then
            return
        end

        UIMgr.Open(VIEW_ID.PanelCustomSetInputPop, self.dwKungfuID, tbSetData)
        UIMgr.Close(self)
    end)

    UIHelper.BindUIEvent(self.BtnEdit, EventType.OnClick, function(btn)
        EquipCodeData.tCurEquip = self.tEquip
        EquipCodeData.tCurInfo = self.tInfo
        EquipCodeData.dwCurForceID = self.dwForceID or PlayerData.GetPlayerForceID(nil, true)
        EquipCodeData.dwCurKungfuID = self.dwKungfuID or PlayerData.GetPlayerMountKungfuID()
        Event.Dispatch(EventType.OnUpdateCustomizedSetEquipFilter)
        Event.Dispatch(EventType.OnUpdateCustomizedSetEquipList, nil)
        UIMgr.Open(VIEW_ID.PanelCustomizedSet)
        UIMgr.Close(self)
    end)

    UIHelper.BindUIEvent(self.BtnGeneratePic, EventType.OnClick, function(btn)
        EquipCodeData.tCurEquip = self.tEquip
        EquipCodeData.tCurInfo = self.tInfo
        EquipCodeData.dwCurForceID = self.dwForceID or PlayerData.GetPlayerForceID(nil, true)
        EquipCodeData.dwCurKungfuID = self.dwKungfuID or PlayerData.GetPlayerMountKungfuID()
        UIMgr.Open(VIEW_ID.PanelCustomizedSetSharePic)
    end)

    UIHelper.BindUIEvent(self.BtnShareSet, EventType.OnClick, function(btn)
        EquipCodeData.tCurEquip = self.tEquip
        EquipCodeData.tCurInfo = self.tInfo
        EquipCodeData.dwCurForceID = self.dwForceID or PlayerData.GetPlayerForceID(nil, true)
        EquipCodeData.dwCurKungfuID = self.dwKungfuID or PlayerData.GetPlayerMountKungfuID()
        UIMgr.Open(VIEW_ID.PanelCustomSetOutputPop)
    end)

    UIHelper.BindUIEvent(self.BtnCloudManage, EventType.OnClick, function(btn)
        UIMgr.Open(VIEW_ID.PanelSideCloudSetCodeList)
    end)
end

function UICustomizedSetShareView:RegEvent()
    --Event.Reg(self, EventType.XXX, func)
end

function UICustomizedSetShareView:UpdateInfo()
    self:UpdateBaseInfo()
    self:UpdateEquipAttributeInfo()
    self:UpdateEquipSlotInfo()
    self:UpdateEquipColorMountAttribInfo()

    self:CaptureScreenByMessage()
end

function UICustomizedSetShareView:UpdateBaseInfo()
    if self.bPreview then
        UIHelper.SetVisible(self.WidgetPlayerName, false)
        UIHelper.SetVisible(self.WidgetAniRightTop, true)

        local bRoleData = self.tInfo ~= nil
        UIHelper.SetVisible(self.WidgetBtnEdit, bRoleData)
        UIHelper.SetVisible(self.WidgetBtnImportCurrent, not bRoleData)
        UIHelper.LayoutDoLayout(self.LayoutRightTopContent)

        local szImg = PlayerForceIDToCustomizedSetShareSchoolNameImg[self.dwForceID] or ""
        UIHelper.SetSpriteFrame(self.ImgSchoolName, szImg, false)

        local szBgImg = PlayerForceIDToCustomizedSetShareSchoolImg[self.dwForceID]
        UIHelper.SetSpriteFrame(self.ImgSchoolBg, szBgImg, false)
    else
        UIHelper.SetVisible(self.WidgetPlayerName, true)
        UIHelper.SetVisible(self.WidgetAniRightTop, false)

        local nPlayerID = PlayerData.GetPlayerID()
        self.scriptHead = self.scriptHead or UIHelper.GetBindScript(self.WidgetHead)
        self.scriptHead:OnEnter(nPlayerID)

        local szImg = PlayerForceIDToCustomizedSetShareSchoolNameImg[self.dwForceID] or ""
        UIHelper.SetSpriteFrame(self.ImgSchoolName, szImg, false)

        local szBgImg = PlayerForceIDToCustomizedSetShareSchoolImg[self.dwForceID]
        UIHelper.SetSpriteFrame(self.ImgSchoolBg, szBgImg, false)

        UIHelper.SetString(self.LabelPlayerName, UIHelper.GBKToUTF8(PlayerData.GetPlayerName()))

        local _, szUserSever = WebUrl.GetServerName()
        UIHelper.SetString(self.LabelServer, szUserSever)
    end
end

function UICustomizedSetShareView:UpdateEquipAttributeInfo()
    self.scriptEquipAttribute = self.scriptEquipAttribute or UIHelper.GetBindScript(self.WidgetAttriList)

    local dwKungfuID = self.dwKungfuID
    local tEquipDatas = self.tEquip

    local szKungfu = PlayerKungfuName[dwKungfuID] or ""
    local tShowItem, tMatchDetail, nTotalScore = EquipCodeData.GetAttributeData(szKungfu, tEquipDatas, true)
    self.scriptEquipAttribute:OnEnter(tShowItem, nTotalScore, PREFAB_ID.WidgetShareAttriCell)
end

function UICustomizedSetShareView:UpdateEquipSlotInfo()
    self.tbEquipCell = {}
    for i, nType in ipairs(EquipEnum) do
		self.tbEquipCell[nType] = UIHelper.AddPrefab(PREFAB_ID.WidgetShareEquipItemCell, self.tbWidgetEquipShell[i])

        local tEquipData = self:GetEquipData(nType)
        local tPowerUpInfo = self:GetPowerUpInfo(nType)
        self.tbEquipCell[nType]:OnEnter(nType, self.bPreview, tEquipData, tPowerUpInfo)
    end

    local bHadBigSword = self.dwForceID == FORCE_TYPE.CANG_JIAN
    UIHelper.SetVisible(self.WidgetWeapon, bHadBigSword)
    UIHelper.LayoutDoLayout(self.LayoutRight)
end

function UICustomizedSetShareView:UpdateEquipColorMountAttribInfo()
    self.scriptColorStoneMain = self.scriptColorStoneMain or UIHelper.GetBindScript(self.WidgetShellWeaponMainWuCai)
    self.scriptColorStoneSecond = self.scriptColorStoneSecond or UIHelper.GetBindScript(self.WidgetShellWeaponSecondaryWuCai)

    self:UpdateEquipColorMountAttribCellInfo(self.scriptColorStoneMain, EQUIPMENT_INVENTORY.MELEE_WEAPON)
    self:UpdateEquipColorMountAttribCellInfo(self.scriptColorStoneSecond, EQUIPMENT_INVENTORY.BIG_SWORD)
end

function UICustomizedSetShareView:UpdateEquipColorMountAttribCellInfo(scriptCell, nType)
    local tbPowerUpInfo = self:GetPowerUpInfo(nType) or {}

    local nEnchantID = 0
    local tbColorStone = tbPowerUpInfo.tbColorStone or {}
    if not tbColorStone.nID then
        UIHelper.SetVisible(scriptCell.WidgetEmpty, true)
        UIHelper.SetVisible(scriptCell.WidgetContent, false)
    else
        nEnchantID = tbColorStone.nID

        local dwTabType, dwIndex = GetColorDiamondInfoFromEnchantID(nEnchantID)
        local itemInfo = ItemData.GetItemInfo(dwTabType, dwIndex)

        local tbInfo = {}
        tbInfo.szAttr = ""

        local aAttr = GetFEAInfoByEnchantID(nEnchantID)
        local skillEvent_tab = g_tTable.SkillEvent
        for k, v in pairs(aAttr) do
            EquipData.FormatAttributeValue(v)
            local szPText = ""
            if v.nID == ATTRIBUTE_TYPE.SKILL_EVENT_HANDLER then
                local skillEvent = skillEvent_tab:Search(v.nValue1)
                if skillEvent then
                    szPText = FormatString(skillEvent.szDesc, v.nValue1, v.nValue2)
                else
                    szPText = "unknown skill event id:"..v.nValue1
                end
            else
                szPText = FormatString(Table_GetMagicAttributeInfo(v.nID, true), v.nValue1, v.nValue2, MAGIC_ATTRI_DEF, MAGIC_ATTRI_DEF)
            end

            szPText = UIHelper.GBKToUTF8(szPText)
            szPText = string.pure_text(szPText)

            szPText = string.format("属性%d：%s", k, szPText)

            if tbInfo.szAttr ~= "" then
                tbInfo.szAttr = tbInfo.szAttr .. "\n"
            end
            tbInfo.szAttr = tbInfo.szAttr .. szPText
        end

        self.tbWuCaiItem = self.tbWuCaiItem or {}
        if not self.tbWuCaiItem[nType] then
            self.tbWuCaiItem[nType] = UIHelper.AddPrefab(PREFAB_ID.WidgetItem_80, scriptCell.WidgetWuCaiItem)
        end

        UIHelper.SetVisible(scriptCell.WidgetWuCaiItem, true)
        self.tbWuCaiItem[nType]:OnInitWithTabID(dwTabType, dwIndex)
        self.tbWuCaiItem[nType]:SetSelectEnable(false)

        szName = ItemData.GetItemNameByItem(itemInfo)
        szName = UIHelper.GBKToUTF8(szName)
        UIHelper.SetString(scriptCell.LabelWuCaiName, szName)

        local szItemDesc = ItemData.GetItemDesc(itemInfo.nUiId)
        szDesc = ParseTextHelper.ParseNormalText(szItemDesc, true)

        UIHelper.SetRichText(scriptCell.RichTextWuCaiAttri, tbInfo.szAttr)

        UIHelper.SetVisible(scriptCell.WidgetEmpty, false)
        UIHelper.SetVisible(scriptCell.WidgetContent, true)
    end
end

function UICustomizedSetShareView:GetEquipData(nType)
    local tEquipData
    if self.tEquip then
        tEquipData = self.tEquip[nType] and self.tEquip[nType].tEquip
    else
        tEquipData = EquipCodeData.GetCustomizedSetEquip(nType)
    end

    return tEquipData
end

function UICustomizedSetShareView:GetPowerUpInfo(nType)
    local tPowerUpInfo
    if self.tEquip then
        tPowerUpInfo = self.tEquip[nType] and self.tEquip[nType].tPowerUpInfo
    else
        tPowerUpInfo = EquipCodeData.GetCustomizedSetEquipPowerUpInfo(nType)
    end

    return tPowerUpInfo
end

function UICustomizedSetShareView:CaptureScreenByMessage()
    if self.bPreview then
        return
    end

    -- 此时在截一张带信息的全屏图
    UIHelper.SetVisible(self.WidgetPlayerName , true)
    Timer.Add(self , 0.8 , function ()
        UIHelper.CaptureScreen(function (pRetTexture , pImage)
            if safe_check(pRetTexture) then
                pRetTexture:retain()
            end
            self.pMessageTexture = pRetTexture
            self.pMessageImage = pImage
            UIHelper.SetVisible(self.WidgetPlayerName , false)
            self:CaptureScreenNoMessage()
        end, 1 , true)
    end)
end

function UICustomizedSetShareView:CaptureScreenNoMessage()
    if self.bPreview then
        return
    end

    -- 此时在截一张不带信息的全屏图
    Timer.AddFrame(self , 2 , function ()
        local folder = GetFullPath("dcim/")
        local dt = TimeToDate(GetCurrentTime())
        CPath.MakeDir(folder)
        local fileName = string.format("%04d%02d%02d%02d%02d%02d.png",dt.year, dt.month, dt.day, dt.hour, dt.minute, dt.second)
        UIHelper.CaptureScreen(function (pRetTexture , pImage)
            self.nPhotoshareViewID = VIEW_ID.PanelCameraPhotoShare
            if not UIMgr.GetView(self.nPhotoshareViewID) then
                local shareScript = UIMgr.Open(self.nPhotoshareViewID, pRetTexture, pImage, folder, fileName, function ()
                    UIMgr.Close(self)
                end, self.pMessageImage)
                shareScript:SetChangeTexture(self.pMessageTexture)
                shareScript:EnableScaleSave(false)
                shareScript:HidePlayerInfoToggle()
            end
        end, 1 , true)
    end)
end

function UICustomizedSetShareView:SetCode(szCode)
    UIHelper.SetString(self.LabelEquipID, szCode)
    UIHelper.SetVisible(self.LabelEquipID, true)
end


return UICustomizedSetShareView