-- WidgetCareerCollect

local UICareerCollect = class("UICareerCollect")

local REMOTE_PREFER_EFFECT = 1132

local Name2Index = {
    Pendant             = 1, --C++中用的是拼错版本的pendent
    Exterior            = 2,
    Transfiguration     = 3,
    Mounts              = 4,
    Pets                = 5,
    Playthings          = 6,
    HomeLand            = 7,
}

local Index2Name = {
    [1] = "挂件",
    [2] = "外观",
    [3] = "易容",
    [4] = "坐骑",
    [5] = "宠物",
    [6] = "小玩意",
    [7] = "家具",
}

function UICareerCollect:OnEnter()
    self.player = GetClientPlayer()
    if not self.bInit then
        self:RegEvent()
        self:BindUIEvent()
        self.bInit = true
        self.totalScript = {}
    end
    self:UpdateData()
    self:UpdateInfo()
end

function UICareerCollect:OnExit()
    self.bInit = false
    self:UnRegEvent()
end

function UICareerCollect:BindUIEvent()
    --
end

function UICareerCollect:RegEvent()
    Event.Reg(self, "CareerCollectCellClick", function(nIndex)
        UIMgr.Open(VIEW_ID.PanelCollectDetailed, self.tData, nIndex)
    end)

    Event.Reg(self,"SYNC_MINI_AVATAR_DATA",function ()
        self:UpdateDataOfAvatarInPlaythings()
        self:UpdateInfo()
    end)
end

function UICareerCollect:UnRegEvent()
    --Event.UnReg(self, EventType.XXX)
end

function UICareerCollect:UpdateData()
    if not self.player then
        return
    end
    self.tData = {}

    local AvatarMgr = g_pClientPlayer.GetMiniAvatarMgr()
	if not AvatarMgr.bDataSynced then
		AvatarMgr.ApplyMiniAvatarData()
	end

    self.tData = self.player.GetCareerCollect()
    self.tData[Name2Index.Exterior].detail[1] = self:UpdateDataOfExteriorClothesInExterior()
    self.tData[Name2Index.Exterior].detail[2] = self:UpdateDataOfExteriorSetInExterior()
    self.tData[Name2Index.Exterior].total = self.tData[Name2Index.Exterior].detail[1] + self.tData[Name2Index.Exterior].detail[2] 
        + self.tData[Name2Index.Exterior].detail[3]

    self.tData[Name2Index.Mounts].detail[1] = self:UpdateDataOfHorseInMounts()
    self.tData[Name2Index.Mounts].total = self.tData[Name2Index.Mounts].total + self.tData[Name2Index.Mounts].detail[1]

    self.tData[Name2Index.Mounts].detail[2] = self:UpdateDataOfQiQuInMounts()
    self.tData[Name2Index.Mounts].total = self.tData[Name2Index.Mounts].total + self.tData[Name2Index.Mounts].detail[2]

    self.tData[Name2Index.Pets].detail[1] = self:UpdateDataOfAdventurePetInPet()
    self.tData[Name2Index.Pets].detail[2], self.tData[Name2Index.Pets].detail[3], self.tData[Name2Index.Pets].detail[4] = 
        self:UpdateDataOfPetMedalInPet()
    
    self.tData[Name2Index.Playthings].detail[1] = self:UpdateDataOfToyBoyInPlaythings()
    self.tData[Name2Index.Playthings].total = self.tData[Name2Index.Playthings].total + self.tData[Name2Index.Playthings].detail[1]

    self.tData[Name2Index.Playthings].detail[2] = self:UpdateDataOfEffectInPlaythings()
    self.tData[Name2Index.Playthings].total = self.tData[Name2Index.Playthings].total + self.tData[Name2Index.Playthings].detail[2]

    self:UpdateDataOfAvatarInPlaythings()

    self.tData[Name2Index.HomeLand].detail[1] = self:UpdateDataOfFurnitureInHomeLand(1)
    self.tData[Name2Index.HomeLand].detail[2] = self:UpdateDataOfFurnitureInHomeLand(2)
    self.tData[Name2Index.HomeLand].detail[3] = self:UpdateDataOfFurnitureInHomeLand(3)
    self.tData[Name2Index.HomeLand].total = self.tData[Name2Index.HomeLand].total + self.tData[Name2Index.HomeLand].detail[1] + 
        self.tData[Name2Index.HomeLand].detail[2] + self.tData[Name2Index.HomeLand].detail[3]
end

function UICareerCollect:UpdateDataOfExteriorClothesInExterior()
    local tAllExterior = self.player.GetAllExterior()
    local hExteriorClient = GetExterior()
    local nHave = 0
    for _, tExterior in ipairs(tAllExterior) do
        local dwID = tExterior.dwExteriorID
        local tInfo = hExteriorClient.GetExteriorInfo(dwID)
        local tLine = Table_GetExteriorSet(tInfo.nSet)
        if tLine.nClass == 1 then
            nHave = nHave + 1
        end
    end
    return nHave
end

function UICareerCollect:UpdateDataOfExteriorSetInExterior()
    local tAllExterior = self.player.GetAllExterior()
    local hExteriorClient = GetExterior()

    local fnIsHave = function(nSet)
        local tSet = Table_GetExteriorSet(nSet)
        if tSet.nClass ~= 2 then
            return
        end

        local tSub = tSet.tSub
        for _, dwID in ipairs(tSub) do
            local bHave = self.player.IsExistExterior(dwID)
            if not bHave then
                return false
            end
        end

        return true
    end

    local nHave = 0
    local tSetMap = {}
    for _, tExterior in ipairs(tAllExterior) do
        local dwID = tExterior.dwExteriorID
        local tInfo = hExteriorClient.GetExteriorInfo(dwID)
        if not tSetMap[tInfo.nSet] then
            if fnIsHave(tInfo.nSet) then
                nHave = nHave + 1
            end
            tSetMap[tInfo.nSet] = true
        end
    end
    return nHave
end

function UICareerCollect:UpdateDataOfHorseInMounts()
    local nHave = 0
    for nIndex = 0, 19, 1 do
        local item = ItemData.GetItemByPos(INVENTORY_INDEX.HORSE, nIndex)
        if item then
            nHave = nHave + 1
        end
    end
    return nHave
end

function UICareerCollect:UpdateDataOfQiQuInMounts()
    local tRareHorseList = GetRareHorseInfoList()
    local nHave = 0

    for _, v in pairs(tRareHorseList) do
		local item = ItemData.GetPlayerItem(self.player, v.dwBox, v.dwX)
		if item then
			nHave = nHave + 1
		end
	end
    return nHave
end

function UICareerCollect:UpdateDataOfAdventurePetInPet()
    local nHave = 0
	local tPets = Table_GetAllFellowPet()
	for _, tInfo in pairs(tPets) do
		local tSource = SplitString(tInfo.szSourceList, ";")
		for _, v in pairs(tSource) do
			if tonumber(v) == 5 then
                if self.player.IsFellowPetAcquired(tInfo.dwPetIndex) then
					nHave = nHave + 1
				end
			end
		end
	end
	return nHave
end

function UICareerCollect:UpdateDataOfPetMedalInPet()
    local tHave = {
        [1] = 0,
        [2] = 0,
        [3] = 0,
    }

    local dwForceID = self.player.dwForceID
    local tMedal = self.player.GetAllFellowPetMedalInfos()

    for _, value in pairs(tMedal) do
        local nMedalIndex = value.nMedalIndex
        local tInfo = Table_GetFellowPet_Medal(nMedalIndex)
        if tInfo.dwForceID == -1 or tInfo.dwForceID == dwForceID then
            local nType = value.dwMedalType
            if value.bMedalAcquired then
                tHave[nType] = tHave[nType] + 1
            end
        end
    end

    return tHave[1], tHave[2], tHave[3]
end

function UICareerCollect:UpdateDataOfToyBoyInPlaythings()
    -- local tToyBoxInfo = Table_GetToyBoxInfo()
    -- local REMOTE_TOY_BOX = 1066
    -- local nHave = 0
    -- for k, v in ipairs(tToyBoxInfo) do
    --     if self.player.GetRemoteBitArray(REMOTE_TOY_BOX, tToyBoxInfo.dwID) then
	-- 		nHave = nHave + 1
	-- 	end
	-- end
    ToyBoxData.Init()
    return ToyBoxData.GetHaveToyNum()
end

function UICareerCollect:UpdateDataOfEffectInPlaythings()
    if not self.player.HaveRemoteData(REMOTE_PREFER_EFFECT) then
        self.player.ApplyRemoteData(REMOTE_PREFER_EFFECT)
    end

    local nHave = 0
    local nCount = g_tTable.PendantEffect:GetRowCount()
    for i = 2, nCount do
        local tLine = g_tTable.PendantEffect:GetRow(i)
        if self.player.IsSFXAcquired(tLine.dwEffectID) then
            nHave = nHave + 1
        end
    end
    return nHave
end

function UICareerCollect:UpdateDataOfAvatarInPlaythings()
    local AvatarMgr = g_pClientPlayer.GetMiniAvatarMgr()
    local tmp = self.tData[Name2Index.Playthings].detail[3]
    self.tData[Name2Index.Playthings].detail[3] = #AvatarMgr.GetAllMiniAvatar() + 1
    self.tData[Name2Index.Playthings].total = self.tData[Name2Index.Playthings].total + self.tData[Name2Index.Playthings].detail[3] - tmp
end

function UICareerCollect:UpdateDataOfFurnitureInHomeLand(nType)
    local nHave = 0
    local hlMgr = GetHomelandMgr()
    local ttFurnInfos = FurnitureData.GetFurnListByCatg1(nType)
    for _ , tFurnInfos in pairs(ttFurnInfos) do
        local nNum = #tFurnInfos
        for i = 1, nNum do
            local tInfo = tFurnInfos[i]
            local nFurnitureType, dwFurnitureID = tInfo.nFurnitureType, tInfo.dwFurnitureID
            if nFurnitureType == HS_FURNITURE_TYPE.FURNITURE then
                local nAmount = hlMgr.GetFurniture(dwFurnitureID)
                if nAmount > 0 then
                    nHave = nHave + 1
                end
            end
        end
    end
    return nHave
end

function UICareerCollect:UpdateInfo()
    for i = 1, 7 do
        local totalInfoInfo = {szName = Index2Name[i], nNum = self.tData[i].total}
        if self.totalScript[i] then
            self.totalScript[i]:OnEnter(totalInfoInfo, i)
        else
            self.totalScript[i] = UIHelper.AddPrefab(PREFAB_ID.WidgetCareerCollectCell, self.tbWidgetCollect[i], totalInfoInfo, i)
        end
    end
end

return UICareerCollect