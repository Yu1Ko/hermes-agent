-- 表现逻辑相关配置开关

---@class tVisibleCtrlMeta
local tVisibleCtrlMeta = tVisibleCtrlMeta or {}
local isActiveCtrl, applyVisibleCtrl

---@class RLEnv
RLEnv = RLEnv or {
    tVisibleCtrlStack = {
        setmetatable({
            tHeadFlags = {
                -- LIFE  GUILD  TITLE NAME   MARK
                { false, false, true, false, true },    -- client player
                { true , true , true, true , true },    -- other player
                { false, false, true, true , true },    -- npc
            },
            bShowNpc = true,                -- 是否显示Npc
            bShowSelf = true,               -- 是否显示自己
            nShowPlayerMode = 1,            -- 玩家显示模式（PLAYER_SHOW_MODE）
            nHDFaceCount = 0,               -- 高清脸个数
        }, { __index = tVisibleCtrlMeta})
    },
}
local this = RLEnv

---comment 获取控制器栈层数（默认1）
---@return integer
function RLEnv.GetCtrlStackNum()
    return #this.tVisibleCtrlStack
end

---comment 获取当前激活的显示控制器
---@return tVisibleCtrlMeta
function RLEnv.GetActiveVisibleCtrl()
    return this.tVisibleCtrlStack[#this.tVisibleCtrlStack]
end

---comment 获取最底层的显示控制器
---@return tVisibleCtrlMeta
function RLEnv.GetLowerVisibleCtrl()
    return this.tVisibleCtrlStack[1]
end

---comment 压入一个显示控制器
---@return tVisibleCtrlMeta
function RLEnv.PushVisibleCtrl()
    local nCount = #this.tVisibleCtrlStack
    local tCtrl = setmetatable(Lib.copyTab(this.tVisibleCtrlStack[nCount]), {__index = tVisibleCtrlMeta})
    this.tVisibleCtrlStack[nCount+1] = tCtrl
    return tCtrl
end

---comment 移除一个显示控制器
---@param ctrl tVisibleCtrlMeta
function RLEnv.RemoveVisibleCtrl(ctrl)
    local idx = table.get_key(this.tVisibleCtrlStack, ctrl)
    if not idx or idx == 1 then
        return
    end

    local bApply = #this.tVisibleCtrlStack == idx
    table.remove(this.tVisibleCtrlStack, idx)

    if bApply then
        applyVisibleCtrl(this.tVisibleCtrlStack[idx-1])
    end
end

---comment 作用默认显示设置
function RLEnv.ApplyDefaultVisible()
    applyVisibleCtrl(this.GetLowerVisibleCtrl())
end

---comment 重载支持
function RLEnv.OnReload()
    for _, tCtrl in ipairs(this.tVisibleCtrlStack) do
        setmetatable(tCtrl, {__index = tVisibleCtrlMeta})
    end
end

-----------------------------------------------------------------------------
-- 控制器元表

---comment 设置是否显示Npc
---@param bShow boolean 是否显示
function tVisibleCtrlMeta:ShowNpc(bShow)
    if self.bShowNpc == bShow then
        return
    end

    self.bShowNpc = bShow
    if isActiveCtrl(self) then
        if bShow then
            rlcmd("show npc")
        else
            rlcmd("hide npc")
        end
    end
end

---comment 设置是否显示自己
---@param bShow boolean
function tVisibleCtrlMeta:ShowSelf(bShow)
    if self.bShowSelf == bShow then
        return
    end

    self.bShowSelf = bShow
    if isActiveCtrl(self) then
        if bShow then
            rlcmd("show self")
        else
            rlcmd("hide self")
        end
    end
end

---comment 设置角色的显示模式
---@param nMode PLAYER_SHOW_MODE 显示模式
function tVisibleCtrlMeta:ShowPlayer(nMode)
    if self.nShowPlayerMode == nMode then
        return
    end

    self.nShowPlayerMode = nMode
    if isActiveCtrl(self) then
        if nMode == PLAYER_SHOW_MODE.kAll then
            rlcmd("show player")
        elseif nMode == PLAYER_SHOW_MODE.kParter then
            rlcmd("hide player")
            rlcmd("show or hide party player 1")
        elseif nMode == PLAYER_SHOW_MODE.kNone then
            rlcmd("hide player")
            rlcmd("show or hide party player 0")
        end
    end
end

---comment 获取头顶显示开关
---@param nObjType HEAD_FLAG_OBJ 角色类型
---@param nHeadType HEAD_FLAG_TYPE 头顶内容
---@return boolean
function tVisibleCtrlMeta:GetHeadFlag(nObjType, nHeadType)
    return self.tHeadFlags[nObjType][nHeadType]
end

---comment 设置角色头顶显示内容
---@param nObjType HEAD_FLAG_OBJ 角色类型
---@param nHeadType HEAD_FLAG_TYPE 头顶内容
---@param bShow boolean 是否显示
function tVisibleCtrlMeta:ShowHeadFlag(nObjType, nHeadType, bShow)
    bShow = not not bShow   -- 将nil转换为false
    if self.tHeadFlags[nObjType][nHeadType] == bShow then
        return
    end

    self.tHeadFlags[nObjType][nHeadType] = bShow
    if isActiveCtrl(self) then
        Global_SetTopHeadFlag(nObjType - 1, nHeadType - 1, bShow)
    end
end

---comment 设置显示指定Npc的头顶信息
---@param nObjType HEAD_FLAG_OBJ npc类型
---@param bVisible boolean 是否显示
function tVisibleCtrlMeta:ShowObjHeadFlags(nObjType, bVisible)
    local bActive = isActiveCtrl(self)
    local tFlags = self.tHeadFlags[nObjType]
    bVisible = not not bVisible
    for nType, bShow in ipairs(tFlags) do
        if bShow ~= bVisible then
            tFlags[nType] = bVisible
            if bActive then
                Global_SetTopHeadFlag(nObjType - 1, nType - 1, bVisible)
            end
        end
    end
end

---comment 隐藏所有头顶信息
---@param bVisible boolean 是否显示
function tVisibleCtrlMeta:ShowAllHeadFlags(bVisible)
    local bActive = isActiveCtrl(self)
    bVisible = not not bVisible
    for nObj, tFlags in ipairs(self.tHeadFlags) do
        for nType, bShow in ipairs(tFlags) do
            if bShow ~= bVisible then
                tFlags[nType] = bVisible
                if bActive then
                    Global_SetTopHeadFlag(nObj - 1, nType - 1, bVisible)
                end
            end
        end
    end
end

---comment 恢复所有设置的头顶显示状态
function tVisibleCtrlMeta:RestoreHeadFlags()
    local idx = table.get_key(RLEnv.tVisibleCtrlStack, self)
    if idx < 2 then
        return  -- the lowerest ctrl is the main ctrl
    end

    local bActive = isActiveCtrl(self)
    local tLower = RLEnv.tVisibleCtrlStack[idx - 1].tHeadFlags
    for nObj, tFlags in ipairs(self.tHeadFlags) do
        for nType, bShow in ipairs(tFlags) do
            local bVisible = tLower[nObj][nType]
            if bShow ~= bVisible then
                tFlags[nType] = bVisible
                if bActive then
                    Global_SetTopHeadFlag(nObj - 1, nType - 1, bVisible)
                end
            end
        end
    end
end

---comment 设置可显示捏脸个数
---@param nCount integer|nil 个数
function tVisibleCtrlMeta:SetHDFaceCount(nCount)
    self.nHDFaceCount = nCount or 0
    if isActiveCtrl(self) then
        rlcmd(string.format("set HD face count %d", self.nHDFaceCount))
    end
end

function isActiveCtrl(tCtrl)
    return RLEnv.tVisibleCtrlStack[#RLEnv.tVisibleCtrlStack] == tCtrl
end

function applyVisibleCtrl(tCtrl)
    if tCtrl.bShowNpc then
        rlcmd("show npc")
    else
        rlcmd("hide npc")
    end

    if tCtrl.bShowSelf then
        rlcmd("show self")
    else
        rlcmd("hide self")
    end

    if tCtrl.nShowPlayerMode == PLAYER_SHOW_MODE.kAll then
        rlcmd("show player")
    elseif tCtrl.nShowPlayerMode == PLAYER_SHOW_MODE.kParter then
        rlcmd("hide player")
        rlcmd("show or hide party player 1")
    elseif tCtrl.nShowPlayerMode == PLAYER_SHOW_MODE.kNone then
        rlcmd("hide player")
        rlcmd("show or hide party player 0")
    end

    for nObj, tFlags in ipairs(tCtrl.tHeadFlags) do
        for nType, bShow in ipairs(tFlags) do
            Global_SetTopHeadFlag(nObj - 1, nType - 1, bShow)
        end
    end
    Global_UpdateHeadTopPosition()

    rlcmd(string.format("set HD face count %d", tCtrl.nHDFaceCount))
end
