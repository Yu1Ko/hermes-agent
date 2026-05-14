-- ---------------------------------------------------------------------------------
-- Author: luwenhao1
-- Name: UIWinterFestivalNpcInfoView
-- Date: 2024-11-20 10:47:04
-- Desc: 冬至活动门客信息界面 PanelWinterCharacter
-- ---------------------------------------------------------------------------------

local UIWinterFestivalNpcInfoView = class("UIWinterFestivalNpcInfoView")

local SKILL_NUM = 3
local ATTRIBUTE_NUM = 7
local ENCHANT_NUM = 4

local HEAD_COLOR_FRAME = {
    [0] = "UIAtlas2_Activity_Winter_CharacterHead_jin2", --橙色
    [3] = "UIAtlas2_Activity_Winter_CharacterHead_lan2", --蓝色
    [5] = "UIAtlas2_Activity_Winter_CharacterHead_zi2", --紫色
}

local HEAD_COLOR_FRAME_BG = {
    [0] = "UIAtlas2_Activity_Winter_CharacterHead_jin1", --橙色
    [3] = "UIAtlas2_Activity_Winter_CharacterHead_lan1", --蓝色
    [5] = "UIAtlas2_Activity_Winter_CharacterHead_zi1", --紫色
}

local COLOR_ACTIVE = "#95ff95"
local COLOR_UNACTIVE = "#b5bcc1"

-----------------------------DataModel------------------------------
local DataModel = {}

function DataModel.Init(tRemoteInfo)
    DataModel.tTableInfo = Table_GetNPCInfo(tRemoteInfo.dwID)
    DataModel.tEnchantInfo = Table_GetNPCEnchantInfo(tRemoteInfo.dwEnchantID)
    DataModel.tRemoteInfo = tRemoteInfo
end

function DataModel.UnInit()
    DataModel.tTableInfo = nil
    DataModel.tRemoteInfo = nil
    DataModel.tEnchantInfo = nil
end

function DataModel.IsEnchantSuit()
    local bSet = false
    local dwCnt = 0
    local tEnchantSet = DataModel.tRemoteInfo.tEnchantSet
    if not tEnchantSet then
        return bSet
    end
    for i = 1, ENCHANT_NUM do
        if tEnchantSet[i] == 1 then
            dwCnt = dwCnt + 1
        end
    end
    if dwCnt == ENCHANT_NUM then
        bSet = true
    end
    return bSet
end

function DataModel.ShowEnchantSuit()
    local szTip = ""
    local tEnchantInfo = DataModel.tEnchantInfo
    local tEnchantSet = DataModel.tRemoteInfo.tEnchantSet

    if tEnchantInfo.dwEnchantID == 0 or not tEnchantSet then
        return szTip
    end

    szTip = szTip .. string.format("<img src='%s' width='44' height='44'/>", tEnchantInfo.szMobileFrame) .. " "
    szTip = szTip .. UIHelper.GBKToUTF8(tEnchantInfo.szSuitName) .. "\n"

    for i = 1, ENCHANT_NUM do
        local dwActive = tEnchantSet[i]
        local szEnchant = UIHelper.GBKToUTF8(tEnchantInfo["szEnchant"..i])
        local szColor = dwActive == 1 and COLOR_ACTIVE or COLOR_UNACTIVE
        szTip = szTip .. string.format("<color=%s>%s    %s</color>", szColor, szEnchant, g_tStrings.t_STR_NPCENCHANT_SUIT[dwActive])
    end

    return szTip
end

-----------------------------View-----------------------------------

function UIWinterFestivalNpcInfoView:OnEnter(tInfo)
    if not self.bInit then
        self:RegEvent()
        self:BindUIEvent()
        self.bInit = true
    end

    -- print_table(tInfo)

    DataModel.Init(tInfo)
    self:UpdateInfo()
end

function UIWinterFestivalNpcInfoView:OnExit()
    self.bInit = false
    self:UnRegEvent()

    DataModel.UnInit()
end

function UIWinterFestivalNpcInfoView:BindUIEvent()
    UIHelper.BindUIEvent(self.BtnClose, EventType.OnClick, function(btn)
        UIMgr.Close(self)
    end)
end

function UIWinterFestivalNpcInfoView:RegEvent()
    Event.Reg(self, EventType.OnSceneTouchBegan, function()
        UIMgr.Close(self)
    end)
end

function UIWinterFestivalNpcInfoView:UnRegEvent()
    --Event.UnReg(self, EventType.XXX)
end

function UIWinterFestivalNpcInfoView:UpdateInfo()
    self:UpdateNpcInfo()

    UIHelper.RemoveAllChildren(self.ScrollDetail)
    self:UpdateAttrib() --属性
    self:UpdateSkill() --技能
    self:UpdateEnchant() --附魔
    self:UpdateBuff() --稀世神兵

    UIHelper.ScrollViewDoLayoutAndToTop(self.ScrollDetail)
end

function UIWinterFestivalNpcInfoView:UpdateNpcInfo()
    UIHelper.SetSpriteFrame(self.ImgBg, HEAD_COLOR_FRAME_BG[DataModel.tTableInfo.nColorFrame])
    UIHelper.SetSpriteFrame(self.ImgRank, HEAD_COLOR_FRAME[DataModel.tTableInfo.nColorFrame])
    -- UIHelper.SetTexture(self.ImgNPCHead, DataModel.tTableInfo.szMobileAvatarPath)
    UIHelper.SetSpriteFrame(self.ImgNPCHead, "UIAtlas2_ToyPuzzle_ToyDongzhi_" .. DataModel.tTableInfo.nFrame) -- 2025.12.17改为直接读转出来的图by策划需求wenjianhao

    local szName = UIHelper.GBKToUTF8(DataModel.tTableInfo.szName)
    local szTitle = UIHelper.GBKToUTF8(DataModel.tTableInfo.szTitle)
    UIHelper.SetString(self.LabelDetail, string.format("%s (%s)", szName, szTitle))

    UIHelper.SetString(self.Labellevel, DataModel.tRemoteInfo.nLevel .. "/" .. DataModel.tTableInfo.nMaxLevel)
    UIHelper.SetString(self.LabellevelPrograss, DataModel.tRemoteInfo.nExp .. "/" .. DataModel.tRemoteInfo.nMaxExp)
    UIHelper.SetProgressBarPercent(self.SliderTarget, DataModel.tRemoteInfo.nExp / DataModel.tRemoteInfo.nMaxExp * 100)
end

function UIWinterFestivalNpcInfoView:UpdateAttrib()
    UIHelper.AddPrefab(PREFAB_ID.WidgetWinterTitle, self.ScrollDetail, "门客属性")

    for i = 1, ATTRIBUTE_NUM do
        if DataModel.tRemoteInfo["nAttribute" .. i] then
            local szAttrib = UIHelper.GBKToUTF8(DataModel.tTableInfo["szAttribute" .. i])
            local szValue = DataModel.tRemoteInfo["nAttribute" .. i]
            local nFrame = DataModel.tTableInfo["nAttribute" .. i .. "IconFrame"]
            UIHelper.AddPrefab(PREFAB_ID.WidgetCharacterAttrib, self.ScrollDetail, szAttrib, szValue, nFrame)
        end
    end
end

function UIWinterFestivalNpcInfoView:UpdateSkill()
    UIHelper.AddPrefab(PREFAB_ID.WidgetWinterTitle, self.ScrollDetail, "门客技能")

    local tSkillInfo = {}
    for i = 1, SKILL_NUM do
        local tInfo = {
            nSkillID = DataModel.tTableInfo["nSkillID" .. i],
            nSkillLevel = DataModel.tRemoteInfo["nSkillID" .. i .. "Level"],
            szSkillTip = UIHelper.GBKToUTF8(DataModel.tTableInfo["szSkill" .. i .. "Tip"]),
        }
        table.insert(tSkillInfo, tInfo)
    end

    UIHelper.AddPrefab(PREFAB_ID.WidgetCharacterSkill, self.ScrollDetail, tSkillInfo)
end

function UIWinterFestivalNpcInfoView:UpdateEnchant()
    UIHelper.AddPrefab(PREFAB_ID.WidgetWinterTitle, self.ScrollDetail, "门客附魔")

    local bIsEnchantSuit = DataModel.IsEnchantSuit()
    local szTip = DataModel.ShowEnchantSuit()
    UIHelper.AddPrefab(PREFAB_ID.WidgetCharacterSkill2, self.ScrollDetail, DataModel.tEnchantInfo.dwEnchantID, bIsEnchantSuit, szTip)
end

function UIWinterFestivalNpcInfoView:UpdateBuff()
    UIHelper.AddPrefab(PREFAB_ID.WidgetWinterTitle, self.ScrollDetail, "门客稀世神兵")

    local nBuffID = DataModel.tRemoteInfo.BuffID
    if nBuffID then
        local szIcon = TabHelper.GetBuffIconPath(nBuffID, 1)
        local szPath = szIcon and string.format("Resource/icon/%s", szIcon)
        local szTip = BuffMgr.GetBuffDesc(nBuffID, 1)
        szTip = string.gsub(szTip, "\n(.*)", "\n<color=" .. COLOR_ACTIVE .. ">%1</color>")
        UIHelper.AddPrefab(PREFAB_ID.WidgetCharacterSkill3, self.ScrollDetail, szTip, szPath)
    else
        UIHelper.AddPrefab(PREFAB_ID.WidgetCharacterSkill3, self.ScrollDetail, "")
    end
end

return UIWinterFestivalNpcInfoView