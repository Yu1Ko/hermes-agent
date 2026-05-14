-- ---------------------------------------------------------------------------------
-- Author: Unknown
-- Name: UIWidgetWhoSeeMeList
-- Date: 2026-03-24 16:59:02
-- Desc: ?
-- ---------------------------------------------------------------------------------
local ListClassifyName = {
    [1] = "好友",
    [2] = "敌对",
    [3] = "陌生人"
}

local UIWidgetWhoSeeMeList = class("UIWidgetWhoSeeMeList")

function UIWidgetWhoSeeMeList:OnEnter(ballScript)
    self.ballScript = ballScript
    self.nCurType = 1
    self.tbPlayerList = { [1] = {}, [2] = {}, [3] = {} }
    self.tbPendingPlayerMap = self.tbPendingPlayerMap or {} 
    if not self.bInit then
        self:RegEvent()
        self:BindUIEvent()
        self.bInit = true
    end

    if self.tScrollList == nil then
        self:InitScrollList()
    end
    self:UpdateTitle()
    self:UpdateList()
    self:InitBgOpacity()
end

function UIWidgetWhoSeeMeList:OnExit()
    self.bInit = false
    self:UnRegEvent()
    self:UnInitScrollList()
    self.tbPendingPlayerMap = {}
end

function UIWidgetWhoSeeMeList:BindUIEvent()
    self.ballScript:BindDrag(self.BtnDrag)

    UIHelper.BindUIEvent(self.BtnLeft, EventType.OnClick, function()
        local nType = self.nCurType - 1
        if nType == 0 then
            nType = #ListClassifyName
        end
        self.nCurType = nType
        self:UpdateTitle()
        self:UpdateList()
    end)

    UIHelper.BindUIEvent(self.BtnRight, EventType.OnClick, function()
        local nType = self.nCurType + 1
        if nType > #ListClassifyName then
            nType = 1
        end
        self.nCurType = nType
        self:UpdateTitle()
        self:UpdateList()
    end)
end

function UIWidgetWhoSeeMeList:RegEvent()
    Event.Reg(self, "SYNC_SELECT_ME_PLAYER_NOTIFY", function ()
        local dwPlayerID, dwMiniAvatarID, bSelected, nState = arg0, arg1, arg2, arg3
        if dwPlayerID == UI_GetClientPlayerID() then
		    return
	    end
        local nCorrectType = self:GetPlayerType(dwPlayerID)
        local bFoundInCorrectList = false
        
        -- 遍历所有类型的列表，清除旧状态或在当前类型列表中更新
        for nType = 1, 3 do
            local tList = self.tbPlayerList[nType]
            for i = #tList, 1, -1 do
                local v = tList[i]
                if v.dwPlayerID == dwPlayerID then
                    if bSelected and nType == nCorrectType then
                        v.dwMiniAvatarID = dwMiniAvatarID
                        v.nState = nState
                        v.nTime = GetCurrentTime()
                        bFoundInCorrectList = true
                    else
                        table.remove(tList, i)
                    end
                end
            end
        end
        
        -- 如果在看我，并且在当前属性的列表中没找到（可能是新来的，也可能是从其他列表移过来的），则新增
        local player = GetPlayer(dwPlayerID)
        if bSelected and not bFoundInCorrectList then
            if player then
                table.insert(self.tbPlayerList[nCorrectType], {
                    dwPlayerID = dwPlayerID, 
                    dwMiniAvatarID = dwMiniAvatarID, 
                    nState = nState, 
                    nTime = GetCurrentTime(),
                    dwGlobalID = player.GetGlobalID()
                })
            else
                self.tbPendingPlayerMap[dwPlayerID] = {
                    dwPlayerID = dwPlayerID,
                    dwMiniAvatarID = dwMiniAvatarID,
                    nState = nState,
                    nTime = GetCurrentTime(),
                    nType = nCorrectType
                }
            end
        else
            self.tbPendingPlayerMap[dwPlayerID] = nil
        end
        self:UpdateTitle()
        self:UpdateList()
    end)

    Event.Reg(self, EventType.OnSetDragDpsBgOpacity, function(nOpacity)
        if nOpacity then
            UIHelper.SetOpacity(self.ImgListBg, nOpacity)
        end
    end)

    Event.Reg(self, "PLAYER_FELLOWSHIP_CHANGE", function()
        Timer.Add(self, 0.5, function ()
            self:RebuildPlayerClassifyList()
            self:UpdateTitle()
            self:UpdateList()
        end)
    end)

    Event.Reg(self, "ON_UPDATE_FELLOWSHIP_NOTIFY", function()
        Timer.Add(self, 0.5, function ()
            self:RebuildPlayerClassifyList()
            self:UpdateTitle()
            self:UpdateList()
        end)
    end)

    Event.Reg(self, "LOADING_END", function()
        self:ResolvePendingPlayers()
    end)
end

function UIWidgetWhoSeeMeList:UnRegEvent()
    --Event.UnReg(self, EventType.XXX)
end






-- ----------------------------------------------------------
-- Please write your own code below  ↓↓↓
-- ----------------------------------------------------------
local function fnSortPlayers(tLeft, tRight)
	return tLeft.nTime > tRight.nTime
end

function UIWidgetWhoSeeMeList:InitScrollList()
    self:UnInitScrollList()

    self.tScrollList = UIScrollList.Create({
        listNode = self.LayoutScrollList,
        nReboundScale = 1,
        nSpace = 5,
        bSlowRebound = true,
        fnGetCellType = function(nIndex)
            return PREFAB_ID.WidgetWhoSeeMeListCell
        end,
        fnUpdateCell = function(cell, nIndex)
            self:UpdateOneCell(cell, nIndex)
        end,
    })
end

function UIWidgetWhoSeeMeList:UnInitScrollList()
    if self.tScrollList then
        self.tScrollList:Destroy()
        self.tScrollList = nil
    end
end

function UIWidgetWhoSeeMeList:BuildCurShowList()
    local tCurTypeData = self.tbPlayerList[self.nCurType] or {}
    table.sort(tCurTypeData, fnSortPlayers)

    local tShowList = {}
    for i = #tCurTypeData, 1, -1 do
        local tPlayer = tCurTypeData[i]
        local player = GetPlayer(tPlayer.dwPlayerID)
        if player then
            table.insert(tShowList, tPlayer)
        else
            table.remove(tCurTypeData, i)
        end
    end

    table.sort(tShowList, fnSortPlayers)
    self.tCurShowList = tShowList
end

function UIWidgetWhoSeeMeList:UpdateOneCell(script, nIndex)
    if not script then
        return
    end

    local tPlayer = self.tCurShowList and self.tCurShowList[nIndex]
    if not tPlayer then
        return
    end

    local nPlayerID = tPlayer.dwPlayerID
    local player = GetPlayer(nPlayerID)
    if not player then
        return
    end

    local nCamp = PlayerData.GetPlayerCamp(player)
    local szCampIcon = CampData.GetCampImgPath(nCamp, nil, true)
    local dwForceID = player.dwForceID

    local dwMiniAvatarID = tPlayer.dwMiniAvatarID or player.dwMiniAvatarID or 0
    local nRoleType = player.nRoleType or 0
    UIHelper.RoleChange_UpdateAvatar(script.ImgPlayerSchool, dwMiniAvatarID, script.SFXPlayerIcon, script.AnimatePlayer, nRoleType, dwForceID, true)
    UIHelper.SetSpriteFrame(script.ImgPlayerCamp, szCampIcon)
    UIHelper.SetString(script.LabelPlayerName, UIHelper.LimitUtf8Len(UIHelper.GBKToUTF8(player.szName), 6))
    UIHelper.SetSpriteFrame(script.ImgPlayerSect, PlayerForceID2SchoolImg2[dwForceID])

    UIHelper.BindUIEvent(script.TogWhoSeeMeListCell, EventType.OnClick, function()
        SetTarget(TARGET.PLAYER, nPlayerID)
    end)
end

function UIWidgetWhoSeeMeList:UpdateList()
    self:BuildCurShowList()

    if not self.tScrollList then
        self:InitScrollList()
    end

    local nDataLen = #(self.tCurShowList or {})
    if nDataLen == 0 then
        self.tScrollList:Reset(0)
    else
        local nMinIndex = self.tScrollList:GetIndexRangeOfLoadedCells()
        self.tScrollList:ReloadWithStartIndex(nDataLen, nMinIndex)
    end
end

function UIWidgetWhoSeeMeList:UpdateTitle()
    local nType = self.nCurType
    local szClassifyName = ListClassifyName[nType] or ""
    local nCount = table.get_len(self.tbPlayerList[nType])
    UIHelper.SetString(self.LabelTitleNum, string.format("（%d）", nCount))
    UIHelper.SetString(self.LabelSwtich, szClassifyName)
end

function UIWidgetWhoSeeMeList:IsFriend(nPlayerID)
    local player = GetPlayer(nPlayerID)
    if not player then
        return false
    end
    local szGlobalID = player.GetGlobalID()
    return FellowshipData.IsFriend(szGlobalID)
end

function UIWidgetWhoSeeMeList:IsFoe(nPlayerID)
    local player = GetPlayer(nPlayerID)
    if not player then
        return false
    end

    local szGlobalID = player.GetGlobalID()
    local tFoeInfo = GetSocialManagerClient().GetFoeInfo()
    for _, tInfo in ipairs(tFoeInfo) do
        if tInfo.id == szGlobalID then
            return true
        end
    end
    return false
end

function UIWidgetWhoSeeMeList:GetPlayerType(nPlayerID)
    if self:IsFriend(nPlayerID) then
        return 1
    elseif self:IsFoe(nPlayerID) then
        return 2
    else
        return 3
    end
end

function UIWidgetWhoSeeMeList:InitBgOpacity()
    self:SaveDefaultBgOpacity()
    local nOpacity = MainCityCustomData.GetHurtBgOpacity() or Storage.MainCityNode.tbDpsBgOpcity.nOpacity
    if nOpacity then
        UIHelper.SetOpacity(self.ImgListBg, nOpacity)
    else
        UIHelper.SetOpacity(self.ImgListBg, Storage.MainCityNode.tbDpsBgOpcity.nDefault)
    end
end

function UIWidgetWhoSeeMeList:SaveDefaultBgOpacity()
    if not Storage.MainCityNode.tbDpsBgOpcity.nDefault then
        local nOpacity = UIHelper.GetOpacity(self.ImgListBg)
        Storage.MainCityNode.tbDpsBgOpcity.nDefault = nOpacity
    end
end

function UIWidgetWhoSeeMeList:RebuildPlayerClassifyList()
    local tbUniqPlayer = {}

    for nType = 1, 3 do
        local tList = self.tbPlayerList[nType] or {}
        for _, tPlayer in ipairs(tList) do
            if tPlayer and tPlayer.dwPlayerID then
                local tOld = tbUniqPlayer[tPlayer.dwPlayerID]
                if not tOld or (tPlayer.nTime or 0) > (tOld.nTime or 0) then
                    tbUniqPlayer[tPlayer.dwPlayerID] = tPlayer
                end
            end
        end
    end

    local tbNewList = { [1] = {}, [2] = {}, [3] = {} }
    for dwPlayerID, tPlayer in pairs(tbUniqPlayer) do
        local player = GetPlayer(dwPlayerID)
        if player then
            tPlayer.dwGlobalID = player.GetGlobalID()
            local nType = self:GetPlayerType(dwPlayerID)
            table.insert(tbNewList[nType], tPlayer)
        end
    end

    self.tbPlayerList = tbNewList
end

function UIWidgetWhoSeeMeList:ResolvePendingPlayers()
    if not self.tbPendingPlayerMap then
        return
    end

    for dwPlayerID, tPending in pairs(self.tbPendingPlayerMap) do
        local player = GetPlayer(dwPlayerID)
        if player then
            local nType = self:GetPlayerType(dwPlayerID)
            table.insert(self.tbPlayerList[nType], {
                dwPlayerID = tPending.dwPlayerID,
                dwMiniAvatarID = tPending.dwMiniAvatarID,
                nState = tPending.nState,
                nTime = tPending.nTime or GetCurrentTime(),
                dwGlobalID = player.GetGlobalID()
            })
            self.tbPendingPlayerMap[dwPlayerID] = nil
        end
    end

    self:RebuildPlayerClassifyList()
    self:UpdateTitle()
    self:UpdateList()
end

return UIWidgetWhoSeeMeList