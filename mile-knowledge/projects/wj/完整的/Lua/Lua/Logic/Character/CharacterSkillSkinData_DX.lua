-- ---------------------------------------------------------------------------------
-- Author: Unknown
-- Name: CharacterSkillSkinData_DX
-- Date: 2024-10-23 20:00:09
-- Desc: ?
-- ---------------------------------------------------------------------------------
---@class CharacterSkillSkinData_DX
CharacterSkillSkinData_DX = CharacterSkillSkinData_DX or {className = "CharacterSkillSkinData_DX"}
local self = CharacterSkillSkinData_DX

local EACH_PAGE_MAX_COUNT = 9
local MAX_SKIN_LIKE_NUM = 20
local DX_FUYAO_SKILL_ID = 9002    -- dx端扶摇id

function CharacterSkillSkinData_DX.GetGroupID(nSkillID)
    local bFuYao = nSkillID == 100004
    return Table_GetSkillSkinGroup(bFuYao and DX_FUYAO_SKILL_ID or nSkillID)
end

function CharacterSkillSkinData_DX.GetSkinItemIndex(nSkillID, nSkinID)
    local nItemIndex
    if UISkillSkinTab[nSkillID] and UISkillSkinTab[nSkillID][nSkinID] then
        nItemIndex = UISkillSkinTab[nSkillID][nSkinID]["nItemIndex"]
    end
    return nItemIndex
end

---------------------界面相关------------------------
function CharacterSkillSkinData_DX.Init()
    local hPlayer = GetClientPlayer()
    if not hPlayer then
        return
    end

    self.nSkillSkinPage = 1
    self.dwSelectType = 1
    self.tSkillSkinList = {}
    self.tAllSkinList = {}
    self.UpdateLikeInfo()

    local nCurrentKungFuID = hPlayer.GetActualKungfuMountID()
    local tKungfu = Table_GetMKungfuList(nCurrentKungFuID)
    for nIndex, dwID in ipairs(tKungfu) do
        local dwLevel = hPlayer.GetSkillLevel(dwID)
        local dwShowLevel = dwLevel
        if dwLevel == 0 then
            dwShowLevel = 1
        end
        if Table_IsSkillShow(dwID, dwShowLevel) then
            local lst = SkillData.GetDXSkillList(nCurrentKungFuID, dwID)
            for nIndex, tGroup in ipairs(lst) do
                for _, tSkill in pairs(tGroup) do
					local tbInfo = {}
                    local dwID = tSkill[1]
                    local bCommon, bCurrent, bMelee = SkillData.IsCommonDXSkill(dwID)
                    local bShow = self.IsSkillCanShow(dwID, dwShowLevel)
                    if bShow and (not bCommon or bCurrent) then
                        local dwSkinGroup = Table_GetSkillSkinGroup(dwID)
                        local tbAllSkin = GetSkillSkinByGroupID(dwSkinGroup)
                        for index, nSkinID in ipairs(tbAllSkin) do
                            local bHave = self.IsHaveSkillSkin(nSkinID)
                            table.insert(tbInfo, {nSkillID = dwID, nSkinID = nSkinID, bHave = bHave})
                        end
                    end
					if #tbInfo > 0 then
						tbInfo.nSkillID = dwID
						table.insert(self.tAllSkinList, tbInfo)
					end
                end
            end
        end
    end

	table.sort(self.tAllSkinList, function(a, b)
		return a.nSkillID < b.nSkillID
	end)

    self.EmptyAllFilter()
    self.SortSkillSkin()
    self.FilterList()
end

function CharacterSkillSkinData_DX.UnInit()
    self.szSearchText = nil
    self.dwSelectType = nil
    self.nSkillSkinPage = nil
    self.nFilterSkinCount = nil
    self.nFilterHave = 0
    self.tSkillSkinList = nil
    self.tAllSkinList = nil
    self.tSkillSkinList = nil
    self.tFilterSkillSkinList = nil
end

function CharacterSkillSkinData_DX.UpdateLikeInfo(bUpdateCheck)
    local tbSkillSkinLike = {}
    self.tbSkillSkinLike = {}

    for i = 1, MAX_SKIN_LIKE_NUM, 1 do
        local nLikeSkinID = Storage_Server.GetData("SkillSkinLike", i)
        if nLikeSkinID and nLikeSkinID > 0 then
            tbSkillSkinLike[i] = nLikeSkinID
        end
    end

    for _, nSkinID in pairs(tbSkillSkinLike) do
        self.tbSkillSkinLike[nSkinID] = true
    end

    if bUpdateCheck then
        Event.Dispatch(EventType.OnUpdateSkillSkinLike)
    end
end

function CharacterSkillSkinData_DX.SortSkillSkin()
    local function fnDegree(a, b)
        if self.tbSkillSkinLike[a.nSkinID] == self.tbSkillSkinLike[b.nSkinID] then
            if a.bHave == b.bHave then
                return a.nSkinID > b.nSkinID
            elseif a.bHave then
                return true
            else
                return false
            end
        elseif self.tbSkillSkinLike[a.nSkinID] then
            return true
        else
            return false
        end
    end

    local tRes = {}
    if self.dwSelectType == 0 then
        for nSkinID, _ in pairs(self.tbSkillSkinLike) do
            if nSkinID and nSkinID > 0 then
                local nSkillID = Table_GetSkillSkinInfo(nSkinID).dwSkillID
                local bHave = self.IsHaveSkillSkin(nSkinID)
                table.insert(tRes, {nSkillID = nSkillID, nSkinID = nSkinID, bHave = bHave})
            end
        end
    else
        tRes = clone(self.tAllSkinList[self.dwSelectType])
    end

    if tRes == nil then
        tRes = {}
    end

    table.sort(tRes, fnDegree)

    if self.dwSelectType ~= 0 then    -- 收藏不显示默认
        local tbConfSkin = {nSkillID = self.GetSkillID(), bConfSkin = true, szName = "默认", bHave = true, nSkinID = 0}
        table.insert(tRes, 1, tbConfSkin)
    end

    self.tSkillSkinList = tRes
end

function CharacterSkillSkinData_DX.GetSkinInfo(dwSkinID)
    local tSkin = Table_GetSkillSkinInfo(dwSkinID)
    return tSkin
end

function CharacterSkillSkinData_DX.FilterList()
    local tHaveList = {}
    if (not self.nFilterHave) or (self.nFilterHave == 0) then
        tHaveList = self.tSkillSkinList
    else
        for _, tbSkinInfo in ipairs(self.tSkillSkinList) do
            if (self.nFilterHave == 1 and tbSkinInfo.bHave) or (self.nFilterHave == 2 and not tbSkinInfo.bHave) then
                table.insert(tHaveList, tbSkinInfo)
            end
        end
    end

    local tSearchList = {}
    if (not self.szSearchText) or (self.szSearchText == "") then
        tSearchList = tHaveList
    else
        for k, tbSkinInfo in ipairs(tHaveList) do
            local dwSkinID = tbSkinInfo.nSkinID
            local tSkin = self.GetSkinInfo(dwSkinID)
            local szSkinName = tbSkinInfo.szName and UIHelper.UTF8ToGBK(tbSkinInfo.szName) or tSkin.szName
            if string.find(UIHelper.GBKToUTF8(szSkinName), self.szSearchText) then
                table.insert(tSearchList, tbSkinInfo)
            end
        end
    end

    self.tFilterSkillSkinList = tSearchList
    self.nFilterSkinCount = #self.tFilterSkillSkinList
    for _, tbSkinInfo in ipairs(tSearchList) do
        if tbSkinInfo.bConfSkin then
            self.nFilterSkinCount = #self.tFilterSkillSkinList - 1
            break
        end
    end
end

function CharacterSkillSkinData_DX.GetSkillID(nIndex)
    nIndex = nIndex or self.dwSelectType
	if not self.tAllSkinList then
        return
	end

    if not nIndex then
        return
    end

    if self.tAllSkinList[nIndex] then
        return self.tAllSkinList[nIndex].nSkillID
    end

    return nil
end

function CharacterSkillSkinData_DX.IsShowByRelayOn(tSkill)
    local hPlayer = GetClientPlayer()
    if not hPlayer then
        return
    end

    local tSkillRelyOnShow = tSkill.tSkillRelyOnShow
    if not tSkillRelyOnShow or #tSkillRelyOnShow <= 0 then
        return true
    end

    for _, dwID in ipairs(tSkillRelyOnShow) do
        local dwRelyOnShowLevel = hPlayer.GetSkillLevel(dwID)
        if dwRelyOnShowLevel > 0 then
            return true
        end
    end

    return false
end

function CharacterSkillSkinData_DX.IsShowByRelayOnNot(tSkill)
    local hPlayer = GetClientPlayer()
    if not hPlayer then
        return
    end

    local tSkillRelyOnNotShow = tSkill.tSkillRelyOnNotShow
    if not tSkillRelyOnNotShow or #tSkillRelyOnNotShow <= 0 then
        return true
    end

    for _, dwID in ipairs(tSkillRelyOnNotShow) do
        local dwRelyOnNotShowLevel = hPlayer.GetSkillLevel(dwID)
        if dwRelyOnNotShowLevel > 0 then
            return false
        end
    end

    return true
end

function CharacterSkillSkinData_DX.IsSkillCanShow(dwID, dwLevel)
    local nShowLevel = math.max(1, dwLevel)
    local tSkill = Table_GetSkill(dwID, nShowLevel)
    if not tSkill then
        return
    end

    local bShow = self.IsShowByRelayOn(tSkill)
    if not bShow then
        return false
    end

    bShow = self.IsShowByRelayOnNot(tSkill)
    if not bShow then
        return false
    end

    if not tSkill.IsShowNotLearn and dwLevel <= 0 then
        return false
    end

    return true
end

function CharacterSkillSkinData_DX.IsHaveSkillSkin(nSkinID)
    local pPlayer = GetClientPlayer()
    if not pPlayer then
        return
    end

    return pPlayer.IsHaveSkillSkin(nSkinID)
end

function CharacterSkillSkinData_DX.SetFilterHave(nFilterHave)
    self.nFilterHave = nFilterHave
end

function CharacterSkillSkinData_DX.GetSkillSkinList()
    local tbRes = {}
    local nStart = (self.nSkillSkinPage - 1) * EACH_PAGE_MAX_COUNT + 1
    for i = 0, EACH_PAGE_MAX_COUNT - 1, 1 do
        local nIndex = nStart + i
        local tbInfo = self.tFilterSkillSkinList and self.tFilterSkillSkinList[nIndex]
        if tbInfo then
            table.insert(tbRes, tbInfo)
        end
    end

    return tbRes
end

function CharacterSkillSkinData_DX.GetAllSkinList()
    return self.tAllSkinList
end
-----------------------收藏相关-------------------------
function CharacterSkillSkinData_DX.GetSkinLike(nSkinID)
    if not self.tbSkillSkinLike then
        self.UpdateLikeInfo()
    end

    return self.tbSkillSkinLike[nSkinID]
end

function CharacterSkillSkinData_DX.SetSkinLike(nSkinID, bDel)
    local bChange = false
    for i = 1, MAX_SKIN_LIKE_NUM, 1 do
        local nLikeSkinID = Storage_Server.GetData("SkillSkinLike", i)
        if bDel then
            if nLikeSkinID == nSkinID then
                Storage_Server.SetData("SkillSkinLike", i, nil)
                bChange = true
            end
        else
            if not nLikeSkinID or nLikeSkinID <= 0 then
                Storage_Server.SetData("SkillSkinLike", i, nSkinID)
                bChange = true
            end
        end

        if bChange then
            self.UpdateLikeInfo(true)
            return
        end
    end

    TipsHelper.ShowNormalTip("已达到收藏上限")
end

---------------------挂饰秘鉴通用界面配置函数-----------------------

function CharacterSkillSkinData_DX.SetCurrentPage(dwCurrentPage)
    CharacterSkillSkinData_DX.dwCurrentPage = dwCurrentPage
end

function CharacterSkillSkinData_DX.SetSelectType(dwPart)
    CharacterSkillSkinData_DX.dwSelectType = dwPart
    CharacterSkillSkinData_DX.EmptyAllFilter()
end

function CharacterSkillSkinData_DX.SetSearchText(szSearchText)
    CharacterSkillSkinData_DX.szSearchText = szSearchText
end

function CharacterSkillSkinData_DX.GetSearchText()
    return CharacterSkillSkinData_DX.szSearchText
end

function CharacterSkillSkinData_DX.GetCollectionProgressTips()
    local nTotalNum = self.nFilterSkinCount
    local nHaveNum = 0
    for _, tbInfo in ipairs(self.tFilterSkillSkinList) do
        if tbInfo.bHave and not tbInfo.bConfSkin then
            nHaveNum = nHaveNum + 1
        end
    end
    return nTotalNum, nHaveNum
end

function CharacterSkillSkinData_DX.GetCollectedNum()
    local nTotalNum = MAX_SKIN_LIKE_NUM
    local nHaveNum = table.get_len(self.tbSkillSkinLike)

    return nTotalNum, nHaveNum
end

function CharacterSkillSkinData_DX.GetCurPageInfo()
    local nTotalPage = math.ceil(#self.tFilterSkillSkinList / EACH_PAGE_MAX_COUNT)
    return nTotalPage, self.nSkillSkinPage
end

function CharacterSkillSkinData_DX.EmptyAllFilter()
    CharacterSkillSkinData_DX.szSearchText = ""
    CharacterSkillSkinData_DX.nFilterHave = 0
end

function CharacterSkillSkinData_DX.UpdateFilterList()
    self.SortSkillSkin()
    self.FilterList()
end