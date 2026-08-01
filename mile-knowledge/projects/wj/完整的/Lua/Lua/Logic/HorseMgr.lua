-- ---------------------------------------------------------------------------------
-- Author: Unknown
-- Name: HorseMgr
-- Date: 2024-06-07 15:25:30
-- Desc: ?
-- ---------------------------------------------------------------------------------

HorseMgr = HorseMgr or {className = "HorseMgr"}
local self = HorseMgr
-------------------------------- 消息定义 --------------------------------
HorseMgr.Event = {}
HorseMgr.Event.XXX = "HorseMgr.Msg.XXX"

-- 饲料配表 在这个表里的才会自动喂
HorseMgr.tForage = {
    {dwTabType = 5,	dwIndex = 17030, bDefaultBan = false}, -- [百脉根]
    {dwTabType = 5,	dwIndex = 17159, bDefaultBan = false}, -- [百脉根·绑]
    {dwTabType = 5,	dwIndex = 17031, bDefaultBan = false}, -- [紫花苜蓿]
    {dwTabType = 5,	dwIndex = 17158, bDefaultBan = false}, -- [紫花苜蓿·绑]
    {dwTabType = 5,	dwIndex = 17032, bDefaultBan = false}, -- [甜象草]
    {dwTabType = 5,	dwIndex = 18448, bDefaultBan = false}, -- [甜象草·绑]
    {dwTabType = 5,	dwIndex = 17029, bDefaultBan = false}, -- [皇竹草]
    {dwTabType = 5,	dwIndex = 18449, bDefaultBan = false}, -- [皇竹草·绑]
    --{dwTabType = 5,	dwIndex = 17429, bDefaultBan = false}, -- 杂粮谷物
    --{dwTabType = 5,	dwIndex = 35983, bDefaultBan = false}, -- 杂粮谷物·精制
    --{dwTabType = 5,	dwIndex = 17428, bDefaultBan = false}, -- 小鱼虾
    --{dwTabType = 5,	dwIndex = 35981, bDefaultBan = false}, -- 小鱼虾·精品

    {dwTabType = 5,	dwIndex = 35973, bDefaultBan = false}, -- [封家小块肉排]
    {dwTabType = 5,	dwIndex = 17430, bDefaultBan = false}, -- [封家肉排]
    {dwTabType = 5,	dwIndex = 22558, bDefaultBan = false}, -- [封家精致肉排]
    {dwTabType = 5,	dwIndex = 22559, bDefaultBan = false}, -- [封家秘制肉排]

    {dwTabType = 5,	dwIndex = 35974, bDefaultBan = false}, -- [机关组装零件·边角料]
    {dwTabType = 5,	dwIndex = 21045, bDefaultBan = false}, -- [机关组装零件]
    {dwTabType = 5,	dwIndex = 35985, bDefaultBan = false}, -- [机关组装零件·精工]
    {dwTabType = 5,	dwIndex = 35986, bDefaultBan = false}, -- [机关组装零件·大师]

    {dwTabType = 5,	dwIndex = 19325, bDefaultBan = true}, -- [赏钱封·八金发]
    {dwTabType = 5,	dwIndex = 19326, bDefaultBan = true}, -- [赏钱封·六六顺]
    {dwTabType = 5,	dwIndex = 19895, bDefaultBan = false}, -- [维修锤·一斤三]
}

function HorseMgr.Init()
    Event.Reg(self, "LOADING_END", function ()
        local horse = g_pClientPlayer and g_pClientPlayer.GetEquippedHorse()
        if not horse then
            return
        end

        local dwBox, dwX = g_pClientPlayer.GetEquippedHorsePos()
        local nCurrent = horse.GetHorseFullMeasure()

        if nCurrent == 0 and g_pClientPlayer.bOnHorse then
            HorseMgr.PushMsgWithType(nCurrent)
        end

        HorseMgr.OnTryFeed()
    end)

    Event.Reg(self, "HORSE_ITEM_UPDATE", function (dwBox, dwX)
        local horse = g_pClientPlayer and g_pClientPlayer.GetEquippedHorse()
        if not horse then
            return
        end

        local dwCurBox, dwCurX = g_pClientPlayer.GetEquippedHorsePos()
        local nCurrent = horse.GetHorseFullMeasure()

        if dwCurBox == dwBox and dwCurX == dwX then
            HorseMgr.PushMsgWithType(nCurrent)
        end
    end)

    Event.Reg(self, "EQUIP_HORSE", function (dwBox, dwX)
        local horse = g_pClientPlayer and g_pClientPlayer.GetEquippedHorse()
        if not horse then
            return
        end

        local dwCurBox, dwCurX = g_pClientPlayer.GetEquippedHorsePos()
        local nCurrent = horse.GetHorseFullMeasure()

        if dwCurBox == dwBox and dwCurX == dwX then
            HorseMgr.PushMsgWithType(nCurrent)
        end
    end)

    Event.Reg(self, "EXCHANGE_ITEM", function (dwSrcBox, dwSrcX, dwDestBox, dwDestX)
        HorseMgr.UpdateExchangeItem(dwSrcBox, dwSrcX, dwDestBox, dwDestX)
    end)

    HorseMgr.tForage_KV = {}
    for _, v in ipairs(HorseMgr.tForage) do
        HorseMgr.tForage_KV[v.dwIndex] = true
    end
end

function HorseMgr.UnInit()
    Timer.DelAllTimer(self)
end

function HorseMgr.OnLogin()

end

function HorseMgr.PushMsgWithType(nCurrent)
    if nCurrent == 0 then
        BubbleMsgData.PushMsgWithType("HorseFullMeasure",{
            szContent = "坐骑属性衰减, 通过喂食可以提高饱食度", 		-- 显示在信息列表项中的内容
            nBarTime = 60, 			-- 显示在气泡栏的时长, 单位为秒
            szAction = function ()
                UIMgr.Open(VIEW_ID.PanelSaddleHorse)
            end,
        })
    else
        BubbleMsgData.RemoveMsg("HorseFullMeasure")
    end

end

function HorseMgr.IsHorseBag(dwBox)
    if dwBox == INVENTORY_INDEX.HORSE or
        dwBox == INVENTORY_INDEX.RARE_HORSE1 or
        dwBox == INVENTORY_INDEX.RARE_HORSE2 or
        dwBox == INVENTORY_INDEX.RARE_HORSE3 or
        dwBox == INVENTORY_INDEX.RARE_HORSE4 or
        dwBox == INVENTORY_INDEX.RARE_HORSE5 then
        return true
    end
    return false
end

function HorseMgr.UpdateExchangeItem(dwSrcBox, dwSrcX, dwDestBox, dwDestX)
    local dwBox, dwX = -1, -1
    if HorseMgr.IsHorseBag(dwSrcBox) and not HorseMgr.IsHorseBag(dwDestBox) then
        dwBox, dwX = dwSrcBox, dwSrcX
    elseif not HorseMgr.IsHorseBag(dwSrcBox) and HorseMgr.IsHorseBag(dwDestBox) then
        dwBox, dwX = dwDestBox, dwDestX
    else
        return
    end

    local item = g_pClientPlayer.GetItem(dwBox, dwX)
    if not item then
        return
    end

    TipsHelper.ShowNormalTip(g_tStrings.STR_PUT_HORSE_SUCCESS)
    g_pClientPlayer.EquipHorse(dwBox, dwX)
end

function HorseMgr.EquipHorseAndRideHorse(dwBox, dwX)
    Event.Reg(self, "PLAYER_DISPLAY_DATA_UPDATE", function ()
        if not g_pClientPlayer.bOnHorse then
            Event.UnReg(self, "PLAYER_DISPLAY_DATA_UPDATE")
            local nRet =  g_pClientPlayer.EquipHorse(dwBox, dwX)
            if nRet ~= ITEM_RESULT_CODE.SUCCESS then
                OutputMessage("MSG_ANNOUNCE_NORMAL", g_tStrings.tItem_Msg[nRet])
            else
                TipsHelper.ShowNormalTip(g_tStrings.STR_EQUIP_HORSE_SUCCESS)
            end

            self.bSetEquipHorse = true
            self.nTimerID = Timer.AddFrameCycle(self, 1, function ()
                if not self.bSetEquipHorse then
                    Timer.DelTimer(self, self.nTimerID)
                    self.nTimerID = nil
                else
                    if g_pClientPlayer.nJumpCount == 0 then
                        self.bSetEquipHorse = false

                        Timer.Add(self, 1, function ()
                            RideHorse()
                        end)
                    end
                end
            end)
        end
    end, true)
end

function HorseMgr.OnTryFeed()
    if not Storage.HorseFeed.bAutoFeed then
        return
    end

    if not g_pClientPlayer or JX.IsTreasureBFMap(g_pClientPlayer.GetMapID()) then
        return
    end

    local dwHorseBox, dwHorseX = g_pClientPlayer.GetEquippedHorsePos()
    if not dwHorseBox or not dwHorseX then
        return
    end

    local horse = g_pClientPlayer.GetItem(dwHorseBox, dwHorseX)
    if not horse then
        return
    end

    if horse.nQuality < Storage.HorseFeed.nQuality then
        return
    end

    local nMax = horse.GetHorseMaxFullMeasure()--最大饱食度
    local nCurrent = horse.GetHorseFullMeasure()--当前饱食度

    if nCurrent == nMax or nCurrent > nMax * Storage.HorseFeed.nPercent then
        return
    end

    if not g_pClientPlayer.CheckSafeLock(SAFE_LOCK_EFFECT_TYPE.EQUIP) then -- 需要判断一下解锁
        OutputMessage("MSG_SYS", "当前坐骑饱食度过低，自动喂食坐骑失败，密保锁未解除\n")
        return
    end

    local tFeedList = {{}, {}} -- 1为绑定饲料，2为不绑定饲料
    for dwBox = 1, 6 do
        local nSize = g_pClientPlayer.GetBoxSize(dwBox)
        for dwX = 0, nSize - 1 do
            local pItem = g_pClientPlayer.GetItem(dwBox, dwX)
            if pItem and HorseMgr.tForage_KV[pItem.dwIndex] and pItem.nDetail and pItem.nGenre == ITEM_GENRE.FODDER then
                local bCanUse = true

                if Storage.HorseFeed.bBindLimit and not pItem.bBind then
                    bCanUse = false
                end
                if bCanUse and Storage.HorseFeed.tBanFeedItem[pItem.dwIndex] then
                    bCanUse = false
                end
                if bCanUse and not IsHorseFodderMatch(horse.nDetail, pItem.nSub) then
                    bCanUse = false
                end

                if bCanUse then
                    if pItem.bBind then
                        table.insert(tFeedList[1], {dwBox, dwX, UIHelper.GBKToUTF8(pItem.szName)})
                    else
                        table.insert(tFeedList[2], {dwBox, dwX, UIHelper.GBKToUTF8(pItem.szName)})
                    end
                end
            end
        end
    end

    local dwUseBox, dwUseX, szFeedName
    if #tFeedList[1] > 0 then
        dwUseBox, dwUseX, szFeedName = unpack(tFeedList[1][1]) -- 这里可以加个排序
    elseif #tFeedList[2] > 0 then
        dwUseBox, dwUseX, szFeedName = unpack(tFeedList[2][1])
    end

    if dwUseBox and dwUseX then
        -- /gm player.CostHorseFullMeasure(21, 0, 1000)
        -- /gm player.CostHorseFullMeasure(28, 0, 1000)--奇趣
        -- Output(dwHorseBox, dwHorseX, dwBox, dwX,nCurrent,nMax)
        local nResult = g_pClientPlayer.FeedHorse(dwHorseBox, dwHorseX, dwUseBox, dwUseX)
        if nResult == DOMESTICATE_OPERATION_RESULT_CODE.SUCCESS then
            OutputMessage("MSG_SYS", "消耗饲料["..szFeedName.."]自动喂食坐骑成功。".."\n")
        else
            OutputMessage("MSG_SYS", "消耗饲料["..szFeedName.."]自动喂食坐骑失败。[".. g_tStrings.tDometicateError[nResult] .."]\n")
        end
    else
        OutputMessage("MSG_SYS", "当前坐骑饱食度过低，自动喂食坐骑失败，没有合适的饲料" .. "\n")
    end
end

function HorseMgr.IsShowHorse(szTabType, szTabID)
    local tHorseList = HorseMgr.GetAllQiQuList()
    local nTabType = IsString(szTabType) and tonumber(szTabType) or szTabType
    local nTabID = IsString(szTabID) and tonumber(szTabID) or szTabID

    for k, v in ipairs(tHorseList) do
        if v.dwItemTabType == nTabType and v.dwItemTabIndex == nTabID then
            return true
        end
    end

    return false
end


function HorseMgr.IsShowQiqu(tTrolltechList, nItemIndex)
    for _, v in pairs(tTrolltechList) do
        if v.nItemTabIndex == nItemIndex then
            return v.nNoneHide
        end
    end
    return nil
end


function HorseMgr.GetAllQiQuList()
    local tRereHorseList = GetRareHorseInfoList()
    local tTrolltechList = Table_GetTrolltechHorse()
    local tNewQiqu = {}

    for _, v in pairs(tRereHorseList) do
        local item = ItemData.GetPlayerItem(g_pClientPlayer, v.dwBox, v.dwX)
        if not item then
            local nNoneHide = HorseMgr.IsShowQiqu(tTrolltechList, v.dwItemTabIndex)
            if nNoneHide ~= 1 then
                table.insert(tNewQiqu, v)
            end
        else
            table.insert(tNewQiqu, v)
        end
    end

    for _, v in pairs(tNewQiqu) do
        local item = ItemData.GetPlayerItem(g_pClientPlayer, v.dwBox, v.dwX)
        v.nHave = item and 1 or 0
    end

    local fnSort = function(tLeft, tRight)
        local bIsNewL = RedpointHelper.Horse_Qiqu_IsNew(tLeft.dwBox, tLeft.dwX) or false
        local bIsNewR = RedpointHelper.Horse_Qiqu_IsNew(tRight.dwBox, tRight.dwX) or false
        if bIsNewL == bIsNewR then
            if tLeft.nHave == tRight.nHave then
                return tLeft.dwID > tRight.dwID
            end
            return tLeft.nHave > tRight.nHave
        elseif bIsNewL then
            return true
        else
            return false
        end
    end
    table.sort(tNewQiqu, fnSort)

    for k, v in pairs(tNewQiqu) do
        local tLine = Table_GetGrowInfo(v.dwItemTabIndex)
        if tLine then
            v.nShowGrow = tLine.nShowGrow
        end
    end

    return tNewQiqu
end