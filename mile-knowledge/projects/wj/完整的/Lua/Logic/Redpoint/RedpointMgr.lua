-- ---------------------------------------------------------------------------------
-- Author: huqing
-- Name: RedpointMgr
-- Date: 2023-05-15 15:28:39
-- Desc: 红点管理系统
-- ---------------------------------------------------------------------------------

RedpointMgr = RedpointMgr or {}
local self = RedpointMgr

self.tbMapNodeToIDs = {}            -- node -> id 的映射
self.tbMapIDToNodeList = {}         -- id -> nodelist 的映射
self.tbMapNodeToEventHandler = {}   -- 节点 -> 事件托管 的映射


function RedpointMgr.RegisterRedpoint(node, labelCount, tbIDs)
    if not safe_check(node) then
        return
    end

    if not tbIDs or #tbIDs == 0 then
        return
    end

    -- 加入到 NodeToIDs 的映射表
    self.AddNodeToIDs(node, tbIDs)

    -- 红点是否显示的检查函数，从头到尾遍历所配置的红点ID，遇到检查OK的就显示该红点
    local _onRedpoint = function()
        local bShow = false
        local nTotalCount = 0
        for _, nID in ipairs(tbIDs) do
            local condition = RedpoingConditions["Excute_"..nID]
            if IsFunction(condition) then
                local bResult, nCount = condition(nID)
                if bResult then
                    bShow = true
                    nTotalCount = nTotalCount + (nCount or 0)
                end

                -- if condition(nID) then
                --     bShow = true
                --     break
                -- end
            end
        end

        if bShow and not AppReviewMgr.IsReview() then
            UIHelper.SetVisible(node, true)
            if nTotalCount > 0 then
                --local labelCount = UIHelper.GetChildByName(node, "LabelRedPoint")
                if labelCount then
                    UIHelper.SetString(labelCount, nTotalCount)
                end
            end
        else
            UIHelper.SetVisible(node, false)
        end
    end

    -- 加入到 IDToNodeList 的映射表，并注册事件
    local tbEventHandler = self.GetEventHandler(node)
    for _, nID in ipairs(tbIDs) do
        local tbConf = UIRedpointTab[nID]
        if tbConf then
            local tbNodeList = self.GetIDToNodeList(nID)
            table.insert(tbNodeList, node)

            local tbEvents = tbConf.tbEvents or {}
            for idx, szEventName in ipairs(tbEvents) do
                if not string.is_nil(szEventName) then
                    self.tbDelayUpdateTimerID = self.tbDelayUpdateTimerID or {}
                    Event.Reg(tbEventHandler, szEventName, function ()
                        if self.tbDelayUpdateTimerID[node] then
                            Timer.DelTimer(RedpointMgr, self.tbDelayUpdateTimerID[node])
                            self.tbDelayUpdateTimerID[node] = nil
                        end
                        self.tbDelayUpdateTimerID[node] = Timer.Add(RedpointMgr, 0.5, function ()
                            if safe_check(node) then
                                _onRedpoint()
                            end

                            Timer.DelTimer(RedpointMgr, self.tbDelayUpdateTimerID[node])
                            self.tbDelayUpdateTimerID[node] = nil
                        end)
                    end)
                end
            end
        end
    end

    -- 刚注册进来时，也调用一次来决定是否显示红点
    _onRedpoint()
end

function RedpointMgr.UnRegisterRedpoint(node, tbIDs)
    if not safe_check(node) then
        return
    end

    if tbIDs == nil then
        tbIDs = self.GetIDsByNode(node)
    end

    if not tbIDs or #tbIDs == 0 then
        return
    end

    -- 移除 NodeToIDs 的映射表
    self.RemoveNodeToIDs(node)

    -- 反注册所有事件
    self.ClearEventHandler(node)

    -- 移除 IDToNodeList 的映射表
    for _, nID in ipairs(tbIDs) do
        local tbNodeList = self.GetIDToNodeList(nID)
        for k, v in ipairs(tbNodeList) do
            if v == node then
                table.remove(tbNodeList, k)
                break
            end
        end
    end
end











--tbMapNodeToIDs
function RedpointMgr.AddNodeToIDs(node, tbIDs)
    if not safe_check(node) then
        return
    end

    if not tbIDs or #tbIDs == 0 then
        return
    end

    self.tbMapNodeToIDs[node] = tbIDs
end

function RedpointMgr.RemoveNodeToIDs(node)
    if not safe_check(node) then
        return
    end

    self.tbMapNodeToIDs[node] = nil
end

function RedpointMgr.GetIDsByNode(node)
    if not safe_check(node) then
        return
    end

    return self.tbMapNodeToIDs[node]
end

-- tbMapIDToNodeList
function RedpointMgr.GetIDToNodeList(nID)
    if not self.tbMapIDToNodeList[nID] then
        self.tbMapIDToNodeList[nID] = {}
    end

    return self.tbMapIDToNodeList[nID]
end


-- tbMapNodeToEventHandler
function RedpointMgr.GetEventHandler(node)
    if not safe_check(node) then
        return
    end

    if not self.tbMapNodeToEventHandler[node] then
        self.tbMapNodeToEventHandler[node] = {}
    end

    return self.tbMapNodeToEventHandler[node]
end

function RedpointMgr.ClearEventHandler(node)
    if not safe_check(node) then
        return
    end

    local tbEventHandler = self.GetEventHandler(node)
    Event.UnRegAll(tbEventHandler)
    self.tbMapNodeToEventHandler[node] = nil
end