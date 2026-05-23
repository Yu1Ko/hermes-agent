HomelandGroupBuyData = HomelandGroupBuyData or {className = "HomelandGroupBuyData"}
local self = HomelandGroupBuyData

local COLOR_STR_GREEN = "<color=#95ff95>%s</color>"
local COLOR_STR_GRAY = "<color=#86aeb6>%s</color>"

function HomelandGroupBuyData.Init(nMapID)
    self.nMapID = nMapID
    self.nPriceGoldBrick = 0
    self.nPriceGoldIngot = 0
    self.szMyName = nil
    self.tMemberInfo = {}
    self.nMyPlayerID = nil
    self.nMyGlobalRoleID = nil
    self.nLeaderId = nil
    self.nMaxLandIndex = nil
    self.nMyLandIndex = nil
    self.tBindPlayerWaitQueue = {}
    self.State = {
        bInGroupBuyState = nil,--是否进入团购
        nMyPlayerState = nil,
        bAscending = false,
        bInWaitResponse = nil,
        bAllReadyBuy = false,
    }
    self.GetGroupBuyData()
end

function HomelandGroupBuyData.UnInit()
    self.nPriceGoldBrick = nil
    self.nPriceGoldIngot = nil
    self.szMyName = nil
    self.tMemberInfo = nil
    self.nMyPlayerID = nil
    self.nMyGlobalRoleID = nil
    self.nLeaderId = nil
    self.dwMapID = nil
    self.nMaxLandIndex = nil
    self.nMyLandIndex = nil
    self.tBindPlayerWaitQueue = nil
    self.State = {
        bInGroupBuyState = nil,--是否进入团购
        nMyPlayerState = nil,
        bAscending = nil,
        bInWaitResponse = nil,
        bAllReadyBuy = nil,
    }
end

--是否按宅原地升序排序
function HomelandGroupBuyData.SortMemberInfoTable()
    if self.tMemberInfo ~= nil then
        local funcSort = function(tLeft, tRight)
            local szGlobalRoleID = g_pClientPlayer.GetGlobalID()
            if tLeft.GlobalRoleID == szGlobalRoleID then
                return true
            elseif tRight.GlobalRoleID == szGlobalRoleID then
                return false
            end

            if self.State.bAscending then
                return tLeft.LandIndex < tRight.LandIndex
            else
                local rightWeight = tRight.LandIndex
                local leftWeight = tLeft.LandIndex
                if tRight.LandIndex == 0 then
                    rightWeight = 999
                end
                if tLeft.LandIndex == 0 then
                    leftWeight = 999
                end
                return leftWeight > rightWeight
            end
        end
        table.sort(self.tMemberInfo, funcSort)
    end
end

function HomelandGroupBuyData.GetGroupBuyTable()
    local tGroupBuyInfo = GetHomelandMgr().GetBuyLandGrouponAll()
    if not tGroupBuyInfo then
        self.ReSetGroupBuyInfo()
        return
    end

    self.nLeaderId         = tGroupBuyInfo.LeaderID
    self.dwMapID           = tGroupBuyInfo.MapID
    self.tMemberInfo       = tGroupBuyInfo.PlayerInfo
    self.nMaxLandIndex     = tGroupBuyInfo.LandCount
    self.SortMemberInfoTable()
end

function HomelandGroupBuyData.GetGroupBuyData()
    self.GetGroupBuyTable()
    self.State.bInGroupBuyState = false
    if self.nLeaderId then
        self.State.bInGroupBuyState = true
    end
    local player = GetClientPlayer()
    if not player then
        return
    end
    self.szMyName = player.szName
    self.nMyGlobalRoleID = player.GetGlobalID()
    local tplayerInfo = GetHomelandMgr().GetBuyLandGrouponSingle(self.nMyGlobalRoleID)
    if tplayerInfo then
        self.nMyPlayerID           = tplayerInfo.PlayerID
        self.nMyLandIndex          = tplayerInfo.LandIndex
        self.State.nMyPlayerState  = tplayerInfo.State
    end
    self.UpdatePrice()
    self.State.bInWaitResponse = self.IsWaitForRespondse()
end

function HomelandGroupBuyData.GetPlayerName(GlobalRoleID)
    for i, tbInfo in ipairs(self.tMemberInfo) do
        if tbInfo.GlobalRoleID == GlobalRoleID then
            return UIHelper.GBKToUTF8(tbInfo.Name)
        end
    end
end

function HomelandGroupBuyData.DeleteGroupBuyMember(szName)
    for i ,v in ipairs(self.tMemberInfo) do
        if v.Name == szName then
            table.remove(self.tMemberInfo, i)
            break
        end
    end
end

function HomelandGroupBuyData.UpdatePrice()
    if not self.nMyLandIndex or self.nMyLandIndex == 0 then
        self.nPriceGoldBrick = 0
        self.nPriceGoldIngot = 0
        return
    end

    local tLandInfo = Table_GetMapLandInfo(self.dwMapID, self.nMyLandIndex)
    local nLandPrice = tLandInfo.nPrice
    self.nPriceGoldBrick = math.floor(nLandPrice / 10000)
    self.nPriceGoldIngot = nLandPrice % 10000
end

function HomelandGroupBuyData.ReSetGroupBuyInfo()
    self.nPriceGoldBrick = 0
    self.nPriceGoldIngot = 0
    self.tMemberInfo = {}
    self.nMaxLandIndex = nil
    self.nMyLandIndex = nil
    self.nLeaderId = nil
    self.State.bInGroupBuyState = false
    self.State.nMyPlayerState = nil
    self.State.bInWaitResponse = nil
    self.State.bAllReadyBuy = nil
end

function HomelandGroupBuyData.IsGroupBuyOrganizer()
    if self.nLeaderId and self.nLeaderId == self.nMyGlobalRoleID then
        return true
    end
    return false
end

function HomelandGroupBuyData.SetSigleMemberData(tPlayerInfo, GlobalRoleId)
    for i ,v in ipairs(self.tMemberInfo) do
        if v.PlayerID == tPlayerInfo.PlayerID then
            v.LandIndex = tPlayerInfo.LandIndex
            local previousState = v.State
            v.State = tPlayerInfo.State
            if previousState == BUY_LAND_GROUPON_PLAYER_STATE.WAIT_READY_RESPOND and tPlayerInfo.State ~= previousState then
                self.State.bInWaitResponse = self.IsWaitForRespondse()
            end
            self.SortMemberInfoTable()
            return
        end
    end
    --如果表里没有就说明是新成员
    tPlayerInfo.GlobalRoleID = GlobalRoleId
    table.insert(self.tMemberInfo, tPlayerInfo)
    self.SortMemberInfoTable()
end

function HomelandGroupBuyData.IsWaitForRespondse()
    local cntReady = 0
    for i, player in pairs(self.tMemberInfo) do
        if player.State == BUY_LAND_GROUPON_PLAYER_STATE.READY then
            cntReady = cntReady + 1
        elseif player.State == BUY_LAND_GROUPON_PLAYER_STATE.WAIT_READY_RESPOND then
            return true
        end
    end
    if #self.tMemberInfo ~= 0 and cntReady == #self.tMemberInfo then
        self.State.bAllReadyBuy = true
    else
        self.State.bAllReadyBuy = false
    end
    return false
end

function HomelandGroupBuyData.ShowGroupBuyTeamSurePop(dwMapID, nLandIndex)
    local tLandInfo = Table_GetMapLandInfo(dwMapID, nLandIndex)
    local nLandPrice = tLandInfo.nPrice * 10000
    local szLandName = HomelandData.Homeland_GetHomeName(dwMapID, nLandIndex)
    local szTip = "请确认团购信息是否准确\n您被分到的房屋为".."["..szLandName.."]".."\n"
    local szMoney = "点击确认支付："..UIHelper.GetMoneyText(nLandPrice, 26, false, false)
    local szContent = szTip..szMoney

    local fnConfirm = function ()
        GetHomelandMgr().BuyLandGrouponReadyRespond(1, dwMapID)
    end
    local fnCancel = function ()
        GetHomelandMgr().BuyLandGrouponReadyRespond(0, dwMapID)
    end

    local scriptConfirm = UIHelper.ShowConfirm(szContent, fnConfirm, fnCancel, true)
    scriptConfirm:SetCancelNormalCountDownWithCallback(30, fnCancel)
end