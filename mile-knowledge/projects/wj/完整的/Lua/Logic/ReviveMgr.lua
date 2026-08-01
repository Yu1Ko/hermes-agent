--- 复活管理器
---
--- 之前的写法是与端游一样，手动复活状态变动的事件时，根据传入参数，拉起复活界面。在玩家主动选择复活选项，或者不再是死亡状态后，关闭复活界面
--- 但是这样有一个问题，如果中途被其他模块强行关闭了页面，在新的复活状态变动的事件触发前，玩家会看不到复活页面，导致玩家只能重新登录后才能重新看到复活界面
---
--- 这里新增一个复活管理器，用于确保复活界面在其应开启的时候，即使被其他地方误关闭了，也能主动拉起
--- 机制如下
--- 1. 收到 SYNC_PLAYER_REVIVE 事件时，将复活状态参数保存到这里
--- 2. 模块定期检查
---     2.1 如果
---         2.1.1 管理器内有复活状态参数
---         2.1.2 玩家对象存在，且玩家处于死亡状态
---         2.1.3 复活界面被关闭了（hide的情况除外，因为部分页面开启时，需求复活页面暂时隐藏掉，其关闭时将自动恢复显示）
---     2.2 那么，基于这些参数，重新拉起复活界面
--- 3. 清除参数时机
---     3.1 玩家主动选择了任何一个复活选项，并成功复活后
---     3.2 玩家返回角色
---     3.3 玩家返回登录
---     3.4 玩家重新进入游戏
ReviveMgr  = ReviveMgr or { className = "ReviveMgr" }
local self = ReviveMgr

function ReviveMgr.Init()
    self.InvalidateParameters("模块初始化")

    self.RegEvent()

    Timer.AddCycle(self, 0.5, function()
        self:EnsureRevivePanel()
    end)
end

function ReviveMgr.UnInit()
    Event.UnRegAll(self)

    Timer.DelAllTimer(self)
end

function ReviveMgr.RegEvent()
    Event.Reg(self, EventType.OnAccountLogout, function(bBckeToRoleList)
        self.InvalidateParameters(bBckeToRoleList and "返回角色" or "返回登录")
    end)
    
    Event.Reg(self, EventType.OnRoleLogin, function()
        self.InvalidateParameters("角色进入游戏")
    end)
    
    Event.Reg(self, "PLAYER_REVIVE", function()
        self.InvalidateParameters("角色状态变为复活")
    end)
end

ReviveMgr.tSavedParameters = {
    --- 仅当该值为true时，data中保存的数据才实际有意义
    bValid = false,

    --- 保存数据时的时间点。因为保存的参数中有两个字段为对应选项剩余的等待帧数，重新拉起时，需要根据距离保存时已经过去的时间，将这部分帧数扣除
    nSaveTickCount = 0,

    --- 实际保存的上次复活事件的参数
    tData = {
        bReviveInSite = false,
        bReviveInAlter = true,
        bReviveByPlayer = false,
        bReviveByCustom = false,
        nLeftReviveFrame = 240,
        dwReviver = 0,
        nMessageID = 1,
        nReviveUIType = 0,
        nCustomData = 0,
    },
}

function ReviveMgr.SaveParameters(bReviveInSite, bReviveInAlter, bReviveByPlayer, bReviveByCustom, nLeftReviveFrame, dwReviver, nMessageID, nReviveUIType, nCustomData)
    local bOldState = self.tSavedParameters.bValid
    
    local tParams          = self.tSavedParameters

    tParams.bValid         = true
    tParams.nSaveTickCount = GetTickCount()

    local tData            = tParams.tData

    tData.bReviveInSite    = bReviveInSite
    tData.bReviveInAlter   = bReviveInAlter
    tData.bReviveByPlayer  = bReviveByPlayer
    tData.bReviveByCustom  = bReviveByCustom
    tData.nLeftReviveFrame = nLeftReviveFrame
    tData.dwReviver        = dwReviver
    tData.nMessageID       = nMessageID
    tData.nReviveUIType    = nReviveUIType
    tData.nCustomData      = nCustomData
    
    LOG.WARN("ReviveMgr 收到新的复活事件，保存下参数，方便后续以外关闭时拉起，参数如下 (bValid %s=>%s)", tostring(bOldState), tostring(self.tSavedParameters.bValid))
    LOG.TABLE(self.tSavedParameters)
end

function ReviveMgr.LogReviveAction(szAction)
    LOG.DEBUG("ReviveMgr 玩家选择了复活选项：%s", szAction)
end

function ReviveMgr.InvalidateParameters(szReason)
    local bOldState = self.tSavedParameters.bValid
    
    self.tSavedParameters.bValid = false

    LOG.DEBUG("ReviveMgr 将参数标记为失效，原因为：%s (bValid %s=>%s)", szReason, tostring(bOldState), tostring(self.tSavedParameters.bValid))
end

function ReviveMgr.EnsureRevivePanel()
    --- 检查是否保存了参数
    if not self.tSavedParameters.bValid then
        return
    end

    --- 确保玩家对象存在，且处于死亡状态
    local bDead = g_pClientPlayer and g_pClientPlayer.nMoveState == MOVE_STATE.ON_DEATH
    if not bDead then
        return
    end

    --- 判断复活界面是否被关闭了
    if UIMgr.IsViewOpened(VIEW_ID.PanelRevive, true) then
        return
    end

    --- 需要重新拉起复活界面
    local tData = self.tSavedParameters.tData
    
    local nLeftReviveFrame = self.GetLeftFrame(tData.nLeftReviveFrame)
    local nCustomData = self.GetLeftFrame(tData.nCustomData)

    LOG.WARN("ReviveMgr 复活界面被意外关闭了，尝试重新拉起复活界面，参数如下")
    LOG.TABLE(self.tSavedParameters)
    LOG.INFO("ReviveMgr 当前TickCount=%d 其中两个剩余帧数参数经过重新计算后，新的值为 nLeftReviveFrame=%d nCustomData=%d",
             GetTickCount(), nLeftReviveFrame, nCustomData
    )
    
    self.OpenRevivePanel(
            tData.bReviveInSite,
            tData.bReviveInAlter,
            tData.bReviveByPlayer,
            tData.bReviveByCustom,
            nLeftReviveFrame,
            tData.dwReviver,
            tData.nMessageID,
            tData.nReviveUIType,
            nCustomData
    )
end

function ReviveMgr.GetLeftFrame(nLeftReviveFrameWhenSave)
    local nNowTickCount = GetTickCount()
    local nSaveTickCount = self.tSavedParameters.nSaveTickCount

    local nPassedFrame = math.floor((nNowTickCount - nSaveTickCount) / 1000 * GLOBAL.GAME_FPS)
    
    local nLeftFrame = nLeftReviveFrameWhenSave - nPassedFrame
    if nLeftFrame <= 0 then
        nLeftFrame = 0
    end

    return nLeftFrame
end

function ReviveMgr.OpenRevivePanel(bReviveInSite, bReviveInAlter, bReviveByPlayer, bReviveByCustom, nLeftReviveFrame, dwReviver, nMessageID, nReviveUIType, nCustomData)
    local viewId     = VIEW_ID.PanelRevive

    ---@param scriptView UIPanelReviveView
    local funcUpdate = function(scriptView)
        scriptView:UpdateParameters(bReviveInSite, bReviveInAlter, bReviveByPlayer, bReviveByCustom, nLeftReviveFrame, dwReviver, nMessageID, nReviveUIType, nCustomData)
        scriptView:UpdateReviveState()
    end

    -- 若界面已打开，则直接获取对应脚本
    ---@type UIPanelReviveView
    local scriptView = UIMgr.GetViewScript(viewId)
    if not scriptView then
        -- 否则打开对应界面
        scriptView = UIMgr.Open(viewId)
    end

    if scriptView then
        -- 若此时获得了脚本对象，则直接更新数据
        funcUpdate(scriptView)
    else
        -- note: 由于可能有其他界面正在打开中，若调用open后未获得界面信息，这里使用专门的接口确保复活界面完全打开后再更新数据
        -- note: 比如从高处跳下，快到地面时，打开地图、奇遇等界面，这时候新打开复活界面并尝试获取脚本，会得到nil，需要这样处理下才能正常执行
        CorHelper.Start(function()
            CorHelper.Wait_UIOpen(viewId)

            ---@type UIPanelReviveView
            scriptView = UIMgr.GetViewScript(viewId)
            funcUpdate(scriptView)
        end)
    end
end 