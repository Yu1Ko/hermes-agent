-- ---------------------------------------------------------------------------------
-- Author: Unknown
-- Name: UITreasureBattleFieldSkin
-- Date: 2024-04-01 14:49:22
-- Desc: ?
-- ---------------------------------------------------------------------------------

local REMOTE_CHICKENSKIN_COUNT = 1158
local REMOTE_CHICKENSKIN_CHOOSE = 1159
local REMOTE_CHICKENSKIN_UNLOCK = 1160
local EMPTY_COUNT = 6

local function IsSkinDataReady()
	local hPlayer = GetClientPlayer()
	if not hPlayer then
		return
	end
	if not hPlayer.HaveRemoteData(REMOTE_CHICKENSKIN_COUNT)
		or not hPlayer.HaveRemoteData(REMOTE_CHICKENSKIN_CHOOSE)
		or not hPlayer.HaveRemoteData(REMOTE_CHICKENSKIN_UNLOCK) then
		return
	end
	return true
end

local DataModel = {}

function DataModel.Init()
	DataModel.tSkinData      = GDAPI_GetDesertStormSkinInfo()
	DataModel.tSkinType      = Table_GetDesertStormSkinType()
	DataModel.tSkinInfo      = Table_GetDesertStormSkinInfo()
	DataModel.nCurrentSelect = 0
end

function DataModel.Update()
	DataModel.tSkinData = GDAPI_GetDesertStormSkinInfo()
end

function DataModel.GetSkinType(nType)
	for _, v in pairs(DataModel.tSkinType) do
		if v.nType == nType then
			return v
		end
	end
end

function DataModel.GetSkinDataByID(dwSkinID)
	for nType, tData in pairs(DataModel.tSkinData) do
		for _, v in pairs(tData) do
			if v.dwSkinID == dwSkinID then
				return v
			end
		end
	end
end

function DataModel.GetSkinInfo(dwSkinID)
	for _, v in pairs(DataModel.tSkinInfo) do
		if v.dwID == dwSkinID then
			return v
		end
	end
end

function DataModel.GetSkinInfoByType(nType)
	local tRes = {}
	for _, v in pairs(DataModel.tSkinInfo) do
		if v.nType == nType then
			table.insert(tRes, v)
		end
	end
	return tRes
end

local UITreasureBattleFieldSkin = class("UITreasureBattleFieldSkin")

function UITreasureBattleFieldSkin:OnEnter()
    if not self.bInit then
        self:RegEvent()
        self:BindUIEvent()
        self.bInit = true
    end

    self.bSyncSkinData = false
    self.tScriptItemList = {}

    GDAPI_ApplyDesertStormSkinData()
	DataModel.Init()
    self:UpdateInfo()
end

function UITreasureBattleFieldSkin:OnExit()
    self.bInit = false
    self:UnRegEvent()
end

function UITreasureBattleFieldSkin:BindUIEvent()
end

function UITreasureBattleFieldSkin:RegEvent()
    Event.Reg(self, "UPDATE_DESERT_STORM_SKIN_COUNT", function()
        if IsSkinDataReady() and not self.bSyncSkinData then
			self.bSyncSkinData = true
			self:UpdateSkin()
		end
    end)

    Event.Reg(self, "UPDATE_DESERT_STORM_SKIN_CHOOSE", function()
        if IsSkinDataReady() and not self.bSyncSkinData then
			self.bSyncSkinData = true
			self:UpdateSkin()
		end
    end)

    Event.Reg(self, "UPDATE_DESERT_STORM_SKIN_UNLOCK", function()
        if IsSkinDataReady() and not self.bSyncSkinData then
			self.bSyncSkinData = true
			self:UpdateSkin()
        end
    end)

    Event.Reg(self, EventType.UpdateTreasureBattleFieldSkin, function()
        self:UpdateSkin()
    end)
end

function UITreasureBattleFieldSkin:UnRegEvent()
    --Event.UnReg(self, EventType.XXX)
end

-- ----------------------------------------------------------
-- Please write your own code below  ↓↓↓
-- ----------------------------------------------------------

function UITreasureBattleFieldSkin:UpdateSkin()
    if not IsSkinDataReady() then
		return
	end
    DataModel.Update()
    self:UpdateInfo()
end

function UITreasureBattleFieldSkin:UpdateInfo()
    UIHelper.ToggleGroupRemoveAllToggle(self.ToggleGroup)
    local nTypeCount = #DataModel.tSkinType
    for i = 1, nTypeCount do
        self:UpdateSkinList(i)
    end
    self:UpdateSkinDetail()
    UIHelper.ScrollViewDoLayoutAndToTop(self.ScrollViewSkillList)
end

function UITreasureBattleFieldSkin:UpdateSkinList(nType)
    local widget = self.tWidgetTitle[nType]
    local tList  = DataModel.GetSkinInfoByType(nType)

    self.tScriptItemList[nType] = self.tScriptItemList[nType] or {}
    for _, script in ipairs(self.tScriptItemList[nType]) do
        UIHelper.RemoveFromParent(script._rootNode, true)
    end
    self.tScriptItemList[nType] = {}
    local nCount = #tList
    for _, v in pairs(tList) do
        local tInfo = DataModel.GetSkinInfo(v.dwID)
		local tData = DataModel.GetSkinDataByID(v.dwID) or {}
        local script = UIHelper.AddPrefab(PREFAB_ID.WidgetImpasseSkillSkin, widget)

        UIHelper.SetString(script.LabelSkillName, UIHelper.GBKToUTF8(tInfo.szName))
        UIHelper.SetString(script.LabelSkillName01, UIHelper.GBKToUTF8(tInfo.szName))
        UIHelper.SetVisible(script.ImgLock, not tData.bCanUse)
        UIHelper.SetVisible(script.ImgSelect, tData.bUsing)
        UIHelper.ToggleGroupAddToggle(self.ToggleGroup, script.TogImpasseSkillSkin)
        if not DataModel.nCurrentSelect or DataModel.nCurrentSelect == 0 then
			DataModel.nCurrentSelect = v.dwID
		end
        if DataModel.nCurrentSelect == v.dwID then
            UIHelper.SetToggleGroupSelectedToggle(self.ToggleGroup, script.TogImpasseSkillSkin)
        end
        script:SetSelectedCallback(function()
            DataModel.nCurrentSelect = v.dwID
            self:UpdateSkinDetail()
        end)
        table.insert(self.tScriptItemList[nType], script)
    end

    if nCount < EMPTY_COUNT then
        for i = nCount + 1, EMPTY_COUNT do
            local script = UIHelper.AddPrefab(PREFAB_ID.WidgetImpasseSkillSkin, widget)
            UIHelper.SetVisible(script.ImgNoneBg, true)
            UIHelper.SetVisible(script.TogImpasseSkillSkin, false)
            table.insert(self.tScriptItemList[nType], script)
        end
    end

    UIHelper.LayoutDoLayout(widget)
end

function UITreasureBattleFieldSkin:ApplySkin()
	local hPlayer = GetClientPlayer()
	if not hPlayer then
		return
	end
	local dwMapID = hPlayer.GetMapID()
	local _, nMapType = GetMapParams_UIEx(dwMapID)
	if nMapType == MAP_TYPE.BATTLE_FIELD then
		OutputMessage("MSG_ANNOUNCE_RED", g_tStrings.STR_SYSTEM_BAN_MAP)
		return
	end
	if DataModel.nCurrentSelect and DataModel.nCurrentSelect > 0 then
		RemoteCallToServer("On_JueJing_ApplySkin", DataModel.nCurrentSelect)
	end
end

function UITreasureBattleFieldSkin:SetSkinDetailScript(script)
    self.skinDetailScript = script
end

function UITreasureBattleFieldSkin:UpdateSkinDetail()
    local script = self.skinDetailScript
    if not script then
        return
    end

    script:SetClickCallback(function()
        self:ApplySkin()
    end)

    UIHelper.SetVisible(script.WidgetImgBg, true)
    UIHelper.SetVisible(script.WidgetImgDead, true)
    UIHelper.SetVisible(script.WidgetImgFly, false)
    UIHelper.SetVisible(script.WidgetImgBroadcast, false)


    local dwSkinID = DataModel.nCurrentSelect
	local tData = DataModel.GetSkinDataByID(dwSkinID) or {}
	local tInfo = DataModel.GetSkinInfo(dwSkinID) or {}
	local tTypeInfo = DataModel.GetSkinType(tInfo.nType)

	if IsTableEmpty(tInfo) or not tTypeInfo then
		return
	end

    if tInfo.szImagePath ~= "" then
        local szImgPath = tInfo.szImagePath
        szImgPath = string.gsub(szImgPath, "\\", "/")
        szImgPath = string.gsub(szImgPath, "ui/Image/DesertStormMaks/", "UIAtlas2_Pvp_PVPImpasse_")
        szImgPath = string.gsub(szImgPath, ".tga", ".png")
        UIHelper.SetSpriteFrame(script.ImgImpasseDead1, szImgPath)
    end

    if tTypeInfo.szImagePath ~= "" then
		local szBgPath = tTypeInfo.szImagePath
        szBgPath = string.gsub(szBgPath, "\\", "/")
        szBgPath = string.gsub(szBgPath, "ui/Image/DesertStormMaks/", "UIAtlas2_Pvp_PVPImpasse_")
        szBgPath = string.gsub(szBgPath, ".tga", ".png")
        UIHelper.SetSpriteFrame(script.ImgImpasseBg, szBgPath)
	end

    if tData.bCanUse then
        UIHelper.SetVisible(script.LabelDesc, false)
    else
        if tData.tValue and not IsTableEmpty(tData.tValue) then
            UIHelper.SetString(script.LabelDesc, string.pure_text(FormatString(UIHelper.GBKToUTF8(tInfo.szTask), unpack(tData.tValue))))
        else
            UIHelper.SetString(script.LabelDesc, string.pure_text(UIHelper.GBKToUTF8(tInfo.szTask)))
        end
        UIHelper.SetVisible(script.LabelDesc, true)
    end

    UIHelper.SetVisible(script.ImgLock, not tData.bCanUse)
    UIHelper.SetString(script.LabelTitle, UIHelper.GBKToUTF8(tInfo.szName))
    UIHelper.SetButtonState(script.BtnMatching, tData.bCanUse and not tData.bUsing and BTN_STATE.Normal or BTN_STATE.Disable)
    if tData.bUsing then
        UIHelper.SetString(script.LabelMatching, g_tStrings.STR_BTN_USING)
    else
        UIHelper.SetString(script.LabelMatching, g_tStrings.STR_BTN_USE)
    end
end

return UITreasureBattleFieldSkin