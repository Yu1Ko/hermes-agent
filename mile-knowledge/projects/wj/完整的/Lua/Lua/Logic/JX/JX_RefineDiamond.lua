JX_RefineDiamond = { className = "JX_RefineDiamond" }
local _JX_RefineDiamond = {}
local BAG_COUNT = 6              -- 背包数量
local DIAMOND_GENRE = 10         -- 五行石大类索引
local REFINE_FRAME_INTERVAL = 10 -- 精炼间隔 帧数
local DEFAULT_REFINE_COUNT = 100 -- 默认自动精炼次数
JX_RefineDiamond.bAutoContinue = false

function JX_RefineDiamond.Init()
    _JX_RefineDiamond.nRefineCount = 0 
    _JX_RefineDiamond.nRefineTotalCount = 0 
    
    JX_RefineDiamond.bAutoContinue = false
    Event.Reg(JX_RefineDiamond, "CASTING_PANEL_DESTROY", JX_RefineDiamond.StopRefine)
    Event.Reg(JX_RefineDiamond, "STOP_REFINE", JX_RefineDiamond.StopRefine)
    Event.Reg(JX_RefineDiamond, "DIAMON_UPDATE", JX_RefineDiamond.OnDiamondUpdate)
    --Event.Reg(JX_RefineDiamond, "UPDATE_COLOR_DIAMOND_RESPOND", JX_RefineDiamond.OnDiamondUpdate)
    --Event.Reg(JX_RefineDiamond, "DRAW_COMMON_REFINE_WND", JX_RefineDiamond.OnRefreshRefineWnd)
    Event.Reg(JX_RefineDiamond, "SYS_MSG",function(arg0, arg1)
        if arg0 == "UI_OME_ITEM_RESPOND" and arg1 == ITEM_RESULT_CODE.CANNOT_PUT_THAT_PLACE then
            JX_RefineDiamond.StopRefine()
        end
    end)
end

function JX_RefineDiamond.UnInit()
    Event.UnRegAll(JX_RefineDiamond)
    Timer.DelAllTimer(JX_RefineDiamond)
end

-- 停止自动合成（界面关闭/切换到快速合成分页时调用）
function JX_RefineDiamond.StopRefine()
    _JX_RefineDiamond.bStop = true

    if not JX_RefineDiamond.bAutoContinue then
        return
    end
    if not _JX_RefineDiamond.dwRefineBox then
        return
    end
    _JX_RefineDiamond.dwRefineBox = nil
end

function JX_RefineDiamond.IsStop()
    return _JX_RefineDiamond.bStop
end

-- 收到开始精炼事件
function JX_RefineDiamond.StartRefineDiamond(arg0, arg1, arg2, nRefineCount, bColorDiamond)
    if not JX_RefineDiamond.bAutoContinue then
        return
    end
    _JX_RefineDiamond.bStop = false
    _JX_RefineDiamond.bColorDiamond = bColorDiamond
    _JX_RefineDiamond.nRefineCount = nRefineCount or DEFAULT_REFINE_COUNT -- 默认五次
    _JX_RefineDiamond.nRefineTotalCount = _JX_RefineDiamond.nRefineCount -- 记录开始时的次数
    _JX_RefineDiamond:SaveRefineForMula(arg0, arg1, arg2)
end

function JX_RefineDiamond.GetRefineCount()
    local nProcessedCount = _JX_RefineDiamond.nRefineTotalCount - (_JX_RefineDiamond.nRefineCount - 1)
    return nProcessedCount, _JX_RefineDiamond.nRefineTotalCount
end

-- 收到上次精炼结束的事件
function JX_RefineDiamond.OnDiamondUpdate(arg0)
    if _JX_RefineDiamond.bStop then
        return
    end

    if _JX_RefineDiamond.nRefineCount == 0 then
        JX_RefineDiamond.StopRefine() -- 到达最大精炼次数后停止精炼
        return
    end

    if not JX_RefineDiamond.bAutoContinue then
        return
    end
    if not _JX_RefineDiamond.dwRefineBox then
        return
    end
    if _JX_RefineDiamond.clientPlayer and _JX_RefineDiamond.clientPlayer.nMoveState == MOVE_STATE.ON_DEATH then
        TipsHelper.ShowNormalTip("auto refine death stop")
        return
    end

    local bLastRet = arg0 --上次精炼结果，实际表示的是精炼操作是否成功。即使概率问题导致合成失败时也是1
    Timer.AddFrame(JX_RefineDiamond, 2, function()
        --延迟准备下次精炼
        if _JX_RefineDiamond.bStop then
            return
        end
        if bLastRet == DIAMOND_RESULT_CODE.SUCCESS and _JX_RefineDiamond:PrepareRefine() then
            Timer.AddFrame(JX_RefineDiamond, REFINE_FRAME_INTERVAL, function()
                --延迟开始下次精炼，此处决定了精炼间隔
                if _JX_RefineDiamond.bStop then
                    return
                end
                _JX_RefineDiamond.nRefineCount = _JX_RefineDiamond.nRefineCount - 1
                if _JX_RefineDiamond.bColorDiamond then
                    RemoteCallToServer("OnUpdateColorDiamond", _JX_RefineDiamond.dwRefineBox, _JX_RefineDiamond.dwRefineX
                    , _JX_RefineDiamond.tNewMaterial)
                else
                    RemoteCallToServer("OnUpdateDiamond", _JX_RefineDiamond.dwRefineBox, _JX_RefineDiamond.dwRefineX
                    , _JX_RefineDiamond.tNewMaterial)
                end
            end)
        else
            JX_RefineDiamond.StopRefine()
        end
    end)
end

-- 收到打开精炼界面事件
function JX_RefineDiamond.OnRefreshRefineWnd()

end

-- 收到开始精炼事件时存储上次精炼的方案
function _JX_RefineDiamond:SaveRefineForMula(dwRefineBox, dwRefineX, tMaterial)
    self.dwRefineBox = dwRefineBox --精炼基材的背包Box
    self.dwRefineX = dwRefineX     --精炼基材的背包X
    self.tMaterial = tMaterial     --精炼消耗材料{{道具1Box,道具1X},{道具2Box,道具2X}...}
    self.clientPlayer = GetClientPlayer()
    local refineItem = self.clientPlayer.GetItem(dwRefineBox, dwRefineX)
    self.dwRefineItemIndex = refineItem.dwIndex --精炼基材的道具Index
    self.nRefineLevel = refineItem.nDetail      --精炼基材的五行石等级

    self.tRefineMaterial = {}                   --精炼基材的相同道具Index的数量
    for k, v in pairs(tMaterial) do
        local item = self.clientPlayer.GetItem(unpack(v))
        if item then
            local dwIndex = item.dwIndex
            self.tRefineMaterial[dwIndex] = self.tRefineMaterial[dwIndex] or 0
            self.tRefineMaterial[dwIndex] = self.tRefineMaterial[dwIndex] + 1
        end
    end
    --AddUILockItem("CastingPanel", dwRefineBox, dwRefineX) --锁定精炼基材的背包格子
end

-- 遍历背包，获取所有五行石的背包位置/堆叠数（排除基材的背包位置）、空背包位置
function _JX_RefineDiamond:Cache()
    self.tEmptyBox = {}
    self.tDiamond = {}
    for dwBox = 1, BAG_COUNT do
        for dwX = 0, self.clientPlayer.GetBoxSize(dwBox) - 1 do
            local item = self.clientPlayer.GetItem(dwBox, dwX)
            if item then
                if item.nGenre == DIAMOND_GENRE and not (dwBox == self.dwRefineBox and dwX == self.dwRefineX) then
                    table.insert(self.tDiamond,
                            { dwBox = dwBox, dwX = dwX, dwIndex = item.dwIndex, nStackNum = item.nStackNum,
                              nMaxStackNum = item.nMaxStackNum })
                end
            else
                table.insert(self.tEmptyBox, { dwBox = dwBox, dwX = dwX })
            end
        end
    end
end

-- 下次精炼前的准备工作，移走上次精炼的成品，放入下次精炼配方
function _JX_RefineDiamond:PrepareRefine()
    self:Cache()
    self.produceItem = self.clientPlayer.GetItem(self.dwRefineBox, self.dwRefineX) --这里上次精炼结束了，格子变成了精炼产物的位置
    if not self.produceItem then
        return
    end

    if self.produceItem.dwIndex ~= self.dwRefineItemIndex then
        --上次精炼失败就继续用上次的基材进行下次精炼，否则挪走上次产物
        -- 先判断还能不能继续精炼，不能就不移走已经精炼完的结果了
        if not self:GetMoveItem2RefinePos() then
            return
        end
        -- 移走上次精炼完生成的五行石
        if not self:TryStackProduceItem() and not self:TryMoveProduceItem2EmpatyX() then
            TipsHelper.ShowImportantRedTip(UIHelper.GBKToUTF8(JX.LoadLangPack["refine product exchange failed"]))
            return
        end
        -- 重新选一个精炼基材放到精炼框中f
        if not self:TryMoveItem2RefinePos() then
            return
        end
    end
    -- 选择精炼消耗材料，要放在最后，因为基材可能会先扣一个
    self.tNewMaterial = self:GetNewMaterial()
    if not self.tNewMaterial then
        return
    end
    return true
end

--获取指定五行石Index的背包中的所有数量
function _JX_RefineDiamond:GetLeftDiamondCount(dwIndex)
    local nLeft = 0
    for k, v in pairs(self.tDiamond) do
        if v.dwIndex == dwIndex then
            nLeft = v.nStackNum + nLeft
        end
    end
    return nLeft
end

--获取精炼实际所需要消耗的材料的背包位置
function _JX_RefineDiamond:GetNewMaterial()
    -- 取材料
    local tMaterial = {}
    for dwIndex, nCount in pairs(self.tRefineMaterial) do
        local nLeftCount = self:GetLeftDiamondCount(dwIndex)
        if nLeftCount >= nCount then
            local nNeedCount = nCount
            for k, v in pairs(self.tDiamond) do
                if v.dwIndex == dwIndex then
                    for i = 1, v.nStackNum do
                        if nNeedCount > 0 then
                            table.insert(tMaterial, { v.dwBox, v.dwX })
                            nNeedCount = nNeedCount - 1
                        else
                            break
                        end
                    end
                end
            end
        else
            return nil
        end
    end
    return tMaterial
end

-- 将精炼产物堆叠到同Index的背包格子里
function _JX_RefineDiamond:TryStackProduceItem()
    for k, v in pairs(self.tDiamond) do
        if v.nStackNum < v.nMaxStackNum and v.dwIndex == self.produceItem.dwIndex then
            if self.clientPlayer.CanExchange(self.dwRefineBox, self.dwRefineX, v.dwBox, v.dwX) ~= 1 then
                return false
            end
            self.clientPlayer.ExchangeItem(self.dwRefineBox, self.dwRefineX, v.dwBox, v.dwX, 1)
            return true
        end
    end
end

-- 将精炼产物移到空背包格子里（优先执行上面的堆叠操作，无法堆叠才会移到空格子）
function _JX_RefineDiamond:TryMoveProduceItem2EmpatyX()
    if #self.tEmptyBox == 0 then
        return
    end
    local empty = self.tEmptyBox[1]
    if empty then
        if self.clientPlayer.CanExchange(self.dwRefineBox, self.dwRefineX, empty.dwBox, empty.dwX) ~= 1 then
            return false
        end
        self.clientPlayer.ExchangeItem(self.dwRefineBox, self.dwRefineX, empty.dwBox, empty.dwX, 1)
        return true
    end
end

-- 当前背包中还有精炼基材
function _JX_RefineDiamond:GetMoveItem2RefinePos()
    local key = nil
    for k, v in pairs(self.tDiamond) do
        if v.dwIndex == self.dwRefineItemIndex then
            key = k
            break
        end
    end
    return key
end

function _JX_RefineDiamond:TryMoveItem2RefinePos()
    local key = _JX_RefineDiamond:GetMoveItem2RefinePos()
    local diamond = self.tDiamond[key]
    if diamond then
        self.clientPlayer.ExchangeItem(diamond.dwBox, diamond.dwX, self.dwRefineBox, self.dwRefineX, 1)
        if diamond.nStackNum > 1 then
            diamond.nStackNum = diamond.nStackNum - 1
        else
            table.remove(self.tDiamond, key)
        end
        return true
    end
end

function JX_RefineDiamond.OnReload()
end
