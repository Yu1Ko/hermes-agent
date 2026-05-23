-- ---------------------------------------------------------------------------------
-- Author: Unknown
-- Name: UIAddFriendView
-- Date: 2022-11-25 17:47:15
-- Desc: ?
-- ---------------------------------------------------------------------------------

local UIAddFriendView = class("UIAddFriendView")

function UIAddFriendView:OnEnter()
    self.tbDropItemSort = { FELLOW_SHIP_PUSH_TYPE.PUSH, FELLOW_SHIP_PUSH_TYPE.PVE, FELLOW_SHIP_PUSH_TYPE.PVP, FELLOW_SHIP_PUSH_TYPE.PVX, FELLOW_SHIP_PUSH_TYPE.AROUND, FELLOW_SHIP_PUSH_TYPE.IP }
    self.tbItems = {}
    self.nSelectPushType = FellowshipData.nDefaultPushType

    self.tbPushPlayerCardList = {}
    self.tbPushPlayerList = {}
    self.tbPushPlayerListPushType = {}

    for _, nType in ipairs(self.tbDropItemSort) do
        table.insert(self.tbItems, { nKey = nType, szText = g_tStrings.STR_FELLOW_SHIP_PUSH_TYPE_NAME[nType] })
    end

    if not self.bInit then
        self:RegEvent()
        self:BindUIEvent()
        self.bInit = true
    end

    self:UpdateInfo()
    self:ReadTable()
    self:InitServerInfo()
    self:UpdateServerInfo()
    self:OnClickRefresh()
end

function UIAddFriendView:OnExit()
    self.bInit = false
    self:UnRegEvent()
end

function UIAddFriendView:BindUIEvent()
    UIHelper.BindUIEvent(self.BtnClose, EventType.OnClick, function ()
        UIMgr.Close(VIEW_ID.PanelFriendRecommendPop)
    end)

    UIHelper.BindUIEvent(self.BtnAdd, EventType.OnClick, function ()
        local szName = UIHelper.GetString(self.WidgetEdit)
        if szName == "" then
            TipsHelper.ShowNormalTip(g_tStrings.STR_EMPTY_ADD_FRIEND)
        else
            FellowshipData.AddFriendByName(UIHelper.UTF8ToGBK(szName), self.dwCurCenterID)
        end
    end)

    UIHelper.BindUIEvent(self.BtnRefresh, EventType.OnClick, function ()
        self:OnClickRefresh()
    end)

    UIHelper.BindUIEvent(self.BtnEmpty, EventType.OnClick, function ()
        UIHelper.SetVisible(self.BtnEmpty, false)
        UIHelper.SetSelected(self.TogSelectQu, false)
        UIHelper.SetSelected(self.TogSelectFu, false)
    end)
end

function UIAddFriendView:RegEvent()
    Event.Reg(self, "GET_FELLOWSHIP_PREFER_OR_PUSH_LIST", function (nCount, nPreferList)
        if nCount ~= 0 then
            self.tbPushPlayerCardList = FellowshipData.GetFellowshipPushList(nPreferList)
            self:UpdatePushPlayerList()
        else
            -- TODO:tip no push player
        end
    end)

    Event.Reg(self, "APPLY_FELLOWSHIPTYPE_RESPOND", function (dwPlayerID, nPushType)
        local player = GetPlayer(dwPlayerID)
        if player then
            table.insert(self.tbPushPlayerList, player)
            table.insert(self.tbPushPlayerListPushType, nPushType)
            self:UpdatePushPlayerList()
        end
    end)

    Event.Reg(self, "ON_SYNC_FELLOWSHIP_PUSH_BEGIN", function (_nType)
        self.tbPushPlayerCardList = {}
    end)

    Event.Reg(self, "ON_SYNC_FELLOWSHIP_PUSH", function (_nType, dwID, nRoleType, szName, dwMiniAvatarID, dwMapID, dwForceID, nLevel, szCityName)
        -- print("ON_SYNC_FELLOWSHIP_PUSH", _nType, dwID, nRoleType, szName, dwMiniAvatarID, dwMapID, dwForceID, nLevel, szCityName)
        table.insert(self.tbPushPlayerCardList, {dwID = dwID, szName = szName, dwMapID = dwMapID, dwForceID = dwForceID, nLevel = nLevel, szCityName = szCityName })
    end)

    Event.Reg(self, "ON_SYNC_FELLOWSHIP_PUSH_END", function (_nType)
        self:UpdatePushPlayerList()
    end)
end

function UIAddFriendView:UnRegEvent()
    --Event.UnReg(self, EventType.XXX)
end



-- ----------------------------------------------------------
-- Please write your own code below  ↓↓↓
-- ----------------------------------------------------------

function UIAddFriendView:UpdateInfo()
    UIHelper.RemoveAllChildren(self.ScrollViewDropList)

    for _, tbItem in ipairs(self.tbItems) do
        local scriptItem = UIHelper.AddPrefab(PREFAB_ID.WidgetSelectTog358X86, self.ScrollViewDropList)
        scriptItem:OnEnter(tbItem.nKey, tbItem.szText, function (nKey, szText)
            self.nSelectPushType = nKey
            UIHelper.SetSelected(self.TogDropList, false)
            UIHelper.SetString(self.LabelDropList, szText)
        end, tbItem.nKey == self.nSelectPushType)

        if tbItem.nKey == self.nSelectPushType then
            UIHelper.SetString(self.LabelDropList, tbItem.szText)
        end

        UIHelper.ToggleGroupAddToggle(self.ToggleGroupDropList, scriptItem.ToggleSelect)
    end

    UIHelper.ScrollViewDoLayout(self.ScrollViewDropList)
    UIHelper.ScrollToTop(self.ScrollViewDropList, 0)

    if not self.tbScriptPlayerAdd then
        self.tbScriptPlayerAdd = {}

        for i, WidgetPlayer in ipairs(self.tbWidgetPlayerAdd) do
            table.insert(self.tbScriptPlayerAdd, UIHelper.AddPrefab(PREFAB_ID.WidgetPlayerMessageAdd, WidgetPlayer))
        end
    end
end

function UIAddFriendView:UpdatePushPlayerList()
    local tbPlayerCardInfoList = #self.tbPushPlayerCardList > 0 and self.tbPushPlayerCardList or self.tbPushPlayerList
    local tRandomNum = {}
    for i = 1, 3, 1 do
        local tbPlayerCard = tbPlayerCardInfoList[i]
        if tbPlayerCard then
            self.tbScriptPlayerAdd[i]:OnEnter(FellowshipData.tbRelationType.nPush, {id = tbPlayerCard.dwID or tbPlayerCard.dwPlayerID}, SOCIALPANEL_NAME_DISPLAY.NICKNAME, tbPlayerCard, self.nSelectPushType)
            if #self.tbPushPlayerListPushType ~= 0 then
                local dwSubType = self:SelectSubType(self.tbPushPlayerListPushType[i])
                local nRandom = self:SelectRandomNum(self.tTypeMessage[dwSubType],tRandomNum,dwSubType)
                table.insert(tRandomNum, {dwSubType = dwSubType, nRandom = nRandom})
                self.tbScriptPlayerAdd[i]:UpdateSignature(UIHelper.GBKToUTF8(self.tTypeMessage[dwSubType][nRandom]))
                self.tbScriptPlayerAdd[i]:SetPlayerPushSubType(dwSubType, self.tSubType2BigType[dwSubType])
            else
                local nRandom = self:SelectRandomNum(self.tTypeMessage[tbPlayerCard.dwSubType],tRandomNum,tbPlayerCard.dwSubType)
                self.tbScriptPlayerAdd[i]:UpdateSignature(UIHelper.GBKToUTF8(self.tTypeMessage[tbPlayerCard.dwSubType][nRandom]))
                self.tbScriptPlayerAdd[i]:SetPlayerPushSubType(tbPlayerCard.dwSubType, self.tSubType2BigType[tbPlayerCard.dwSubType])
            end
            UIHelper.SetVisible(self.tbScriptPlayerAdd[i].BtnDialogue, self.nSelectPushType ~= FELLOW_SHIP_PUSH_TYPE.IP)
        end
        UIHelper.SetVisible(self.tbScriptPlayerAdd[i]._rootNode, tbPlayerCard and true or false)
    end
end

function UIAddFriendView:ReadTable()
    local nRowCount = g_tTable.FriendPreference:GetRowCount()
    local tFriendType = {}
    self.tTypeMessage = {}
    self.tSubType2BigType = {}
    for i = 1, nRowCount do
        local tSubFriendType = {}
        local tLine = g_tTable.FriendPreference:GetRow(i)
        tSubFriendType.dwID 		= tLine.dwID
        tSubFriendType.szType 		= tLine.szType
        tSubFriendType.dwType 		= tLine.dwType
        tSubFriendType.szSubType 	= tLine.szSubType
        tSubFriendType.dwSubType 	= tLine.dwSubType
        tSubFriendType.bShow 		= tLine.bShow
        tSubFriendType.szMessage 	= tLine.szMessage
        tFriendType[i] = tSubFriendType
    end
    local nRowCount = #tFriendType
    for i = 1, nRowCount, 1 do
        local tLine = tFriendType[i]
        --self.tTypeMessage[tLine.dwSubType] = SplitString(UIHelper.GBKToUTF8(tLine.szMessage), ";")
        self.tTypeMessage[tLine.dwSubType] = SplitString(tLine.szMessage, ";")
        self.tSubType2BigType[tLine.dwSubType] = tLine.dwType
    end
end

function UIAddFriendView:InitServerInfo()
    self.tAddFriendServer = {}
    local tAllServerInfo = Table_GetAllSwitchServerInfo()
    local tAddFriendServerName = {}
    local nIndex = 0

    self.nCurRegionName, self.szCurServerName = WebUrl.GetServerName()

    for _, tInfo in ipairs(tAllServerInfo) do
        if tInfo.bAddFriend then
            if UIHelper.GBKToUTF8(tInfo.szRegionName) == self.nCurRegionName and
            UIHelper.GBKToUTF8(tInfo.szBindCenter) == self.szCurServerName then
                self.dwCurCenterID = tInfo.dwCenterID
            end

            if not tAddFriendServerName[UIHelper.GBKToUTF8(tInfo.szRegionName)] then
                nIndex = nIndex + 1
                tAddFriendServerName[UIHelper.GBKToUTF8(tInfo.szRegionName)] = true
                self.tAddFriendServer[nIndex] = {}
                table.insert(self.tAddFriendServer[nIndex], UIHelper.GBKToUTF8(tInfo.szRegionName))
            end

            table.insert(self.tAddFriendServer[nIndex], tInfo)
        end
    end

    UIHelper.SetString(self.LabelSelectQu, self.nCurRegionName)
    UIHelper.SetString(self.LabelSelectFu, self.szCurServerName)
end

function UIAddFriendView:UpdateServerInfo()
    UIHelper.RemoveAllChildren(self.LayoutRegion)

    for _, v in ipairs(self.tAddFriendServer) do
        UIHelper.AddPrefab(PREFAB_ID.WidgetSelectTog126X50, self.LayoutRegion, nil, v[1], function ()
            UIHelper.SetVisible(self.BtnEmpty, true)
            UIHelper.RemoveAllChildren(self.LayoutServer)
            if self.nCurRegionName ~= v[1] then
                self.nCurRegionName = v[1]
                UIHelper.SetString(self.LabelSelectQu, self.nCurRegionName)
                self.szCurServerName = UIHelper.GBKToUTF8(v[2].szBindCenter)
                UIHelper.SetString(self.LabelSelectFu, self.szCurServerName)
            end

            for i, tServerInfo in ipairs(v) do
                if i ~= 1 then
                    local scriptTog = UIHelper.AddPrefab(PREFAB_ID.WidgetSelectTog160X50, self.LayoutServer, nil, UIHelper.GBKToUTF8(tServerInfo.szBindCenter), function ()
                        UIHelper.SetVisible(self.BtnEmpty, true)
                        self.dwCurCenterID = tServerInfo.dwCenterID
                        self.szCurServerName = UIHelper.GBKToUTF8(tServerInfo.szBindCenter)
                        UIHelper.SetString(self.LabelSelectFu, self.szCurServerName)
                    end, self.szCurServerName == UIHelper.GBKToUTF8(tServerInfo.szBindCenter)) assert(scriptTog)
                    scriptTog:SetClickCallback(function ()
                        UIHelper.SetVisible(self.BtnEmpty, false)
                        UIHelper.SetSelected(self.TogSelectQu, false)
                        UIHelper.SetSelected(self.TogSelectFu, false)
                    end)
                end
            end

            UIHelper.LayoutDoLayout(self.LayoutServer)
            UIHelper.LayoutDoLayout(self.LayoutServerImg)
        end, self.nCurRegionName == v[1])
    end

    UIHelper.LayoutDoLayout(self.LayoutServer)
    UIHelper.LayoutDoLayout(self.LayoutRegion)
end

function UIAddFriendView:SelectSubType(dwFellowshipType)
    local tSubType = {}
   if dwFellowshipType == 0 then
       return 0
   end
   for  i = 1, 32 do
       local nFree = GetNumberBit(dwFellowshipType, i)
       if nFree then
           table.insert(tSubType, i)
       end
   end
   local nMessageNum = #tSubType
   local nRandom = math.random(1, nMessageNum)
   return tSubType[nRandom]
end

function UIAddFriendView:SelectRandomNum(tMessage, tRandomNum, dwSubType)
	local nMessageNum = #tMessage
   	local bNotRepeat = true
   	local nRandom = 0
    local RANDOM_TIME = 1000

   	for i = 0, RANDOM_TIME do
   		bNotRepeat = false
   		nRandom = math.random(1, nMessageNum)
   		for i, v in ipairs(tRandomNum) do
   			if v.dwSubType == dwSubType and v.nRandom == nRandom then
   				bNotRepeat = true
   				break
   			end
   		end
   		if not bNotRepeat then
   			break
   		end
   	end

   	return nRandom
end

function UIAddFriendView:OnClickRefresh()
    if self.nCountdown and self.nCountdown ~= 0 then
        if not self.bCountDownTip then
            TipsHelper.ShowNormalTip(g_tStrings.MENTOR_FRESH_COLD_NOT_SECOND)
            self.bCountDownTip = true
        end
        return
    end
    self.tbPushPlayerCardList = {}
    self.tbPushPlayerList = {}
    self.tbPushPlayerListPushType = {}
    self:UpdatePushPlayerList()

    if self.nSelectPushType == FELLOW_SHIP_PUSH_TYPE.IP and not FellowshipData.GetRegisterIPToFellowByLoginFlag() then
        local ScriptConfirm = UIHelper.ShowConfirm(g_tStrings.FELLOW_SHIP_MSG, function (bOptionChecked)
            FellowshipData.SetRegisterIPToFellowByLoginFlag(bOptionChecked)
            FellowshipData.GetFellowshipPush(self.nSelectPushType)
        end)
        ScriptConfirm:ShowTogOption(g_tStrings.STR_AUTO_PUSH_BY_IP, true)
    else
        FellowshipData.GetFellowshipPush(self.nSelectPushType)
    end

    UIHelper.SetVisible(self.WidgetReciprocal,true)
    UIHelper.SetVisible(self.BtnRefresh,false)

    self.nCountdown = 3
    self.bCountDownTip = false
    Timer.AddCountDown(self, self.nCountdown, function ()
        self.nCountdown = self.nCountdown - 1--"2(秒)"
        UIHelper.SetString(self.LabelReciprocal, tostring(self.nCountdown-1).."(秒)")
    end,
    function ()
        UIHelper.SetVisible(self.BtnRefresh,true)
        UIHelper.SetVisible(self.WidgetReciprocal,false)
        UIHelper.SetString(self.LabelReciprocal, "2(秒)")
    end)
end

return UIAddFriendView
