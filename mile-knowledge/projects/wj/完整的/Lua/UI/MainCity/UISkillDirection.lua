-- ---------------------------------------------------------------------------------
-- Author: JiaYuRan
-- Name: UISkillDirection
-- Date: 2022-11-11 11:45:31
-- Desc: UISkillDirection 技能技能释放方向脚本
-- ---------------------------------------------------------------------------------

---@class UISkillDirection
---@field BoxDirection
local UISkillDirection = class("UISkillDirection")
local GetTickCount = GetTickCount
local kWarningBox = Const.kWarningBox
local kMetreLength, kMetreHeight, kZpointToXy = Const.kMetreLength, Const.kMetreHeight, Const.kZpointToXy
local kDirectionTouchMaxRadius = 100        -- 遥感最大滑动范围
local kDirectionTouchCancelRadius = 200     -- 遥感取消最小移动范围
local kMinEffectDuration = 0.20             -- 特效最少持续时间（秒，避免快速点击没有特效显示）
local kHeightOffset = 0.05 / kMetreHeight   -- 拖拽特效离地高端偏移，避免插入地下
local kDistanceAdjust = 0.5 / kMetreLength  -- 距离修正, 避免角色移动过程中技能释放超过最大距离
local kHeightTrackSpeed = 88 / kMetreHeight -- 高度追踪速度
local kLogicDirTrans = -2 * math.pi * 64 / GLOBAL.DIRECTION_COUNT
local kDragBgScaleDis = 20 / kMetreLength   -- 范围框放大距离（当技能范围超过设置值则放大UI范围框以降低操作灵敏度）
local kUnlockDragMinDisForXYZ = 5           -- 最小滑动距离（选点）
local kUnlockDragMinDisForXYZ_Repeat = 30   -- 最小滑动距离（选点） 持续按住类型技能的锁定距离
local kUnlockDragMinDisForDir = 10          -- 最小滑动距离（方向）

function UISkillDirection:OnEnter()
    if not self.bInit then
        self:RegEvent()
        self:BindUIEvent()
        self.bInit = true

        self.fDirectionTouchMaxRadius = 100
        self.fDirectionTouchCancelRadius = 200
        self.dwSelfID = g_pClientPlayer.dwID

        self.nOriginX, self.nOriginY = UIHelper.GetPosition(self.BoxDirection)
        self.nTouchX, self.nTouchY = 0, 0
        self.nPressX, self.nPressY = 0, 0
    end

    self.lastUpdateTime = GetTickCount()
    self.nTrackPlayerTimerID = 0    ---@type integer 追踪角色位置定时器ID
    self.nTimerEffect = nil         ---@type integer destory effect timer ID
    self.pDragEffect = nil
    self.pCircleEffect = nil
    self.nDragBgScale = 1           ---@type number UI上的范围拖拽框缩放系数
end

function UISkillDirection:OnExit()
    self.bInit = false
    self:UnRegEvent()
    self:destroyEffects()
    Timer.DelAllTimer(self)
end

function UISkillDirection:BindUIEvent()
    UIHelper.BindUIEvent(self.BoxDirection, EventType.OnTouchBegan, function(btn, nX, nY)
        self.bJoystickDrag = true
        self.bDirectionSkillBegin = true

        if self.bDirectionSkillBegin then
            self:OnJoystickDrag(nX, nY)
            return true
        end
    end)

    UIHelper.BindUIEvent(self.BoxDirection, EventType.OnTouchMoved, function(btn, nX, nY)
        self:OnJoystickDrag(nX, nY)
    end)

    UIHelper.BindUIEvent(self.BoxDirection, EventType.OnTouchEnded, function(btn, nX, nY)
        if self.bDirectionSkillBegin then
            self:OnJoystickDrag(nX, nY)
        end
    end)
end

function UISkillDirection:RegEvent()
    Event.Reg(self, EventType.OnClientPlayerLeave, function()
        self:destroyEffects()
        Timer.DelAllTimer(self)
    end)

    Event.Reg(self, "PLAYER_DEATH", function()
        self:OnDirectionSkillEnd(self.nSlotID)
    end)

    Event.Reg(self, EventType.OnSceneTouchWithoutMove, function(bLButtonUp, bRButtonUp)
        if self.bDirectionSkillBegin then
            if bRButtonUp then
                self:OnDirectionSkillEnd(self.nSlotID)
                return
            end

            if bLButtonUp then
                self:CastSkill()
                self:OnDirectionSkillEnd(self.nSlotID)
            end
        end
    end)

    Event.Reg(self, EventType.OnViewOpen, function()
        if self.bDirectionSkillBegin and Global.HaveFullScreenUI() then
            self:OnDirectionSkillEnd(self.nSlotID)
        end
    end)

    Event.Reg(self, EventType.OnSkillPressDown, function()
        if self.bDirectionSkillBegin and self.bUseMouse then
            self:OnDirectionSkillEnd(self.nSlotID)
        end
    end)
end

function UISkillDirection:UnRegEvent()
end

-- 避免手机上轻微的移动导致方向变化
function UISkillDirection:isDragLocked(nX, nY)
    if self.bLockDrag then
        local deltaX = (self.nPressX or 0) - nX
        local deltaY = (self.nPressY or 0) - nY
        local dis2 = deltaX * deltaX + deltaY * deltaY
        if self.bCastXYZ then
            local kUnlockDis = self.nCastType == UISkillCastType.Repeat and kUnlockDragMinDisForXYZ_Repeat or kUnlockDragMinDisForXYZ
            if dis2 < kUnlockDis * kUnlockDis then
                return true
            end
        else
            if dis2 < kUnlockDragMinDisForDir * kUnlockDragMinDisForDir then
                return true
            end
        end

        self.bLockDrag = false
        return false
    else
        return self.nTouchX == nX and self.nTouchY == nY
    end
end

function UISkillDirection:OnJoystickDrag(nX, nY)
    if self.bUseMouse or self.bCastToMySelf or not self.bDirectionSkillBegin or self:isDragLocked(nX, nY) then
        return  -- nothing need update, 避免覆盖初始目标位置
    end

    local nCursorX, nCursorY = UIHelper.ConvertToNodeSpace(self.BoxDirection, nX, nY)
    if nCursorX == 0 then
        nCursorX = 0.00001
    end

    local nNormalizeX, nNormalizeY = kmath.normalize2(nCursorX - self.nOriginX, nCursorY - self.nOriginY)
    self.nTouchX, self.nTouchY = nX, nY
    self.bTargetFloor = self.bCastXYZ   -- 如果选点技能，则开始贴地
    self:onProcessDrag(nCursorX, nCursorY, nNormalizeX, nNormalizeY)
end

function UISkillDirection:onProcessDrag(nCursorX, nCursorY, nNormalizeX, nNormalizeY)
    if not g_pClientPlayer then
        return
    end

    local nDistance = kmath.len2(nCursorX, nCursorY, self.nOriginX, self.nOriginY)
    local bInCancelArea = false
    if SkillData.bUseSkillDirectionCancel and self.lbSkillDirectionCancel then
        bInCancelArea = self.lbSkillDirectionCancel:IsDragIn()
    else
        bInCancelArea = nDistance > kDirectionTouchCancelRadius
    end

    nDistance = math.min(nDistance, kDirectionTouchMaxRadius * self.nDragBgScale)
    UIHelper.SetPosition(self.ImgTouch, nNormalizeX * nDistance, nNormalizeY * nDistance)
    UIHelper.SetActiveAndCache(self, self.WidgetRangeOut, self.bInCancelArea)

    local nLogicDistance = math.floor((nDistance / kDirectionTouchMaxRadius) / self.nDragBgScale * self.nMaxDistance)
    local nX, nY, nZ = SkillData.GetCastPointFromRL(g_pClientPlayer, nNormalizeX, nNormalizeY, nLogicDistance, self.bAreaBoxFollow)
    self:UpdateCastPoint(nX, nY, nZ, bInCancelArea)
end

function UISkillDirection:SetSkillCancelCtrl(script)
    self.lbSkillDirectionCancel = script ---@type UISkillCancel
end

---comment 遥感技能按下
---@param nTouchX integer 屏幕坐标
---@param nTouchY integer 屏幕坐标
---@param nSlotID integer 技能插槽
---@param nSkillID integer 技能ID
---@param tSkillConfig table 技能配置
---@param tTarget table 初始化目标
---@param castSkillFunc function 技能释放回调
---@param canCastSkillFunc function 技能释放检测条件
function UISkillDirection:OnPressDown(nTouchX, nTouchY, nSlotID, nSkillID, tSkillConfig, tTarget, castSkillFunc, canCastSkillFunc)
    local pPlayer = g_pClientPlayer

    if self.nTimerEffect then
        -- 清理上次创建的特效
        self:destroyEffects()
    end

    SkillData.SetCastPoint(0, 0, 0)

    self.nSlotID = nSlotID
    self.nSkillID = nSkillID
    self.nTouchX, self.nTouchY = nTouchX, nTouchY
    self.nPressX, self.nPressY = nTouchX, nTouchY
    self.bLockDrag = true                                   -- 锁住遥感，滑动超过阈值才解锁
    self.bDirectionSkillBegin = true
    self.bInCancelArea = false                              -- 是否在取消范围
    self.bCanCast = true
    self.bAssignTarget = tTarget ~= nil
    self.nPressStartTime = Timer.GetPassTime()
    self.nLastTrackTime = self.nPressStartTime
    self.nMouseTimerID = nil
    self.bCastToMySelf = IsSkillCastToMe(nSkillID)
    self.bUseMouse = not self.bCastToMySelf and (SkillData.IsUsingHDKungFu() and SkillData.UsePCSkillReleaseMode())
    self.tSkillConfig = tSkillConfig

    self.castSkillFunc = castSkillFunc
    self.canCastSkillFunc = canCastSkillFunc

    local bShowDirectionBox = not self.bUseMouse and not self.bCastToMySelf and nTouchX ~= nil and nTouchY ~= nil -- 非触屏方式使用技能时不出现滑圈选点
    local parent = UIHelper.GetParent(self.BoxDirection)
    local nLocalX, nLocalY = UIHelper.ConvertToNodeSpace(parent, nTouchX, nTouchY)

    UIHelper.SetPosition(self.BoxDirection, nLocalX, nLocalY)
    UIHelper.SetPosition(self.WidgetRangeOut, nLocalX, nLocalY)
    UIHelper.SetPosition(self.ImgTouch, self.nOriginX, self.nOriginY)
    UIHelper.SetActiveAndCache(self, self.BoxDirection, bShowDirectionBox)

    self:SetCastPoint(nSkillID, tSkillConfig, tTarget)
    if self.bCastToMySelf then
        return
    end

    if self.bCastXYZ and self.nMaxDistance > kDragBgScaleDis then
        UIHelper.SetScale(self.ImgRangeInBg, 2, 2)
        UIHelper.SetScale(self.ImgRangeOutBg, 2, 2)
        self.nDragBgScale = 2
    else
        UIHelper.SetScale(self.ImgRangeInBg, 1, 1)
        UIHelper.SetScale(self.ImgRangeOutBg, 1, 1)
        self.nDragBgScale = 1
    end

    local pSkill = GetPlayerSkill(nSkillID, 1, pPlayer.dwID)
    if self.bCastXYZ then
        self:createDragEffect(pSkill, self.bAreaBoxFollow)
        if self.canCastSkillFunc then
            -- 检测默认技能释放状态
            local bCanCast = self.canCastSkillFunc(self.tTarget.nX, self.tTarget.nY, self.tTarget.nZ)
            self:updateCanCastState(bCanCast, self.bInCancelArea)
        end
    else
        self:createWarningBox(pSkill, self.nWarningBoxType)
    end

    if self.bUseMouse then
        if SkillData.IsUseSkillDirectionCancel() and self.lbSkillDirectionCancel then
            self.lbSkillDirectionCancel:Hide()
        end
        self:UpdateMousePosition()
    end
end

--技能按钮抬起
function UISkillDirection:OnPressUp(nSlotID)
    if self.nSlotID ~= nSlotID or self.bUseMouse then
        return
    end

    self:CastSkill()
    self:OnDirectionSkillEnd(self.nSlotID)
end

function UISkillDirection:CastSkill()
     self.bInCancelArea = self.lbSkillDirectionCancel and self.lbSkillDirectionCancel:IsDragIn() or false
    if self.bCastToMySelf then
        self:SetCastPoint(self.nSkillID, self.tSkillConfig) -- 对自己释放的技能 刷新玩家当前位置为释放点
    end
    if self.castSkillFunc and not self.bInCancelArea and self.bDirectionSkillBegin then
        local tCastPoint = SkillData.GetCastPoint()
        local tTarget = { nX = tCastPoint.x, nY = tCastPoint.y, nZ = tCastPoint.z, nDir = self.tTarget.nDir }
        if self.bCastXYZ then
            local pSkill = GetSkill(self.nSkillID, 1)
            if pSkill and pSkill.nPlatformType ~= SkillPlatformType.Mobile then
                --NOTE: 释放DX端技能时不能完全贴地
                self.castSkillFunc(tTarget.nX, tTarget.nY, tTarget.nZ)
            else
                --NOTE: 客户端技能KCharacter::CastSkillXYZ中将Z值加了512, 这里减510是担心浮点误差导致坐标点在地底
                self.castSkillFunc(tTarget.nX, tTarget.nY, tTarget.nZ - 510)
            end
        else
            -- 处理频繁快速释放技能角色动作鬼畜的情况（冲刺技能）
            -- 主要产生原因为：角色按按下技能到抬起释放的过程中有拖动遥感改变角色面向，这里如果在很短时间内释放技能则重新取角色当前面向
            local bRedirection = self.bLockDrag and not self.bAssignTarget
            if bRedirection then
                if g_pClientPlayer.bJoystickHold then
                    tTarget.nDir = math.pi * 2 * g_pClientPlayer.nJoystickDirection / GLOBAL.DIRECTION_COUNT
                else
                    tTarget.nDir = math.pi * 2 * g_pClientPlayer.nFaceDirection / GLOBAL.DIRECTION_COUNT
                end
            end

            local nX, nY, nZ = g_pClientPlayer.GetAbsoluteCoordinate()
            nX = nX + math.cos(tTarget.nDir) * self.nMaxDistance
            nY = nY + math.sin(tTarget.nDir) * self.nMaxDistance
            self.castSkillFunc(nX, nY, nZ)
        end
    end
end

function UISkillDirection:OnDirectionSkillEnd(nSlotID)
    if self.nSlotID ~= nSlotID or not self.bDirectionSkillBegin then
        return
    end

    if SkillData.IsUseSkillDirectionCancel() and self.lbSkillDirectionCancel then
        self.lbSkillDirectionCancel:Hide()
    end

    Timer.DelTimer(self, self.nTrackPlayerTimerID)
    self.nTrackPlayerTimerID = 0
    self.bDirectionSkillBegin = false

    UIHelper.SetActiveAndCache(self, self.BoxDirection, false)
    UIHelper.SetActiveAndCache(self, self.WidgetRangeOut, false)

    if self.AdjustStartFaceDirectionTimerID then
        UIHelper.DelTimer(self, self.AdjustStartFaceDirectionTimerID)
        self.AdjustStartFaceDirectionTimerID = nil
    end

    if self.ComponentUpdate then
        UIHelper.SetEnable(self.ComponentUpdate, false)
    end

    local pressDuration = Timer.GetPassTime() - self.nPressStartTime
    if pressDuration >= kMinEffectDuration then
        self:destroyEffects()
    else
        self.nTimerEffect = Timer.Add(self, kMinEffectDuration - pressDuration + 0.001, function()
            self:destroyEffects()
            self.nTimerEffect = nil
        end)
    end

    if self.nMouseTimerID then
        Timer.DelTimer(self, self.nMouseTimerID)
        self.nMouseTimerID = nil
    end
end

function UISkillDirection:SetCastPoint(nSkillID, tSkillConfig, tTarget)
    local pPlayer = g_pClientPlayer
    local pScene = pPlayer.GetScene()

    if tSkillConfig then
        self.nCastType = tSkillConfig.nCastType
        self.bCastXYZ = tSkillConfig.bCastXYZ                   -- 释放方向技
        self.nWarningBoxType = tSkillConfig.nWarningBoxType     -- 警告框类型
        self.bAreaBoxFollow = tSkillConfig.bAreaBoxHeightFollow -- 范围框是否跟随玩家
        self.nAreaBoxType = tSkillConfig.nAreaBoxType or 1      -- 选单框类型
        self.bDynamicSkill = tSkillConfig.bDynamicSkill         -- 是否动态技能栏技能
    else
        self.bCastXYZ = true
        self.nAreaBoxType = 1
    end

    -- 最大距离减少一定距离，避免因浮点误差、角色移动导致技能无法释放
    self.nMaxDistance = pPlayer.GetSkillMaxRadius(nSkillID, 1) - kDistanceAdjust
    if tSkillConfig and tSkillConfig.nUIRadius and tSkillConfig.nUIRadius > 0 then
        -- 使用UI指定的滑选半径
        self.nMaxDistance = math.min(self.nMaxDistance, tSkillConfig.nUIRadius / kMetreLength)
    end

    local nPlayerX, nPlayerY, nPlayerZ = pPlayer.GetAbsoluteCoordinate()
    self.bTargetFloor = (tTarget == nil) and self.bCastXYZ -- 有目标则延迟贴地
    self.tTarget = (tTarget and not self.bCastToMySelf) and
            { nX = tTarget.nX, nY = tTarget.nY, nZ = tTarget.nZ } or
            { nX = nPlayerX, nY = nPlayerY, nZ = nPlayerZ }

    if self.bCastXYZ then
        if self.bCastXYZ and not self.bCastToMySelf and tTarget and tTarget.nType == TARGET.NPC then
            local pTarget = Global.GetCharacter(tTarget.dwID)
            if pTarget then
                -- 修正默认目标点到目标角色的被击框的边缘
                local nTouch = math.max(128, pTarget.nTouchRange)   -- 2024.4.26 蕉说需要一个最小距离
                local nX, nY, nZ = pTarget.GetAbsoluteCoordinate()
                local nDeltaZ = pScene.GetFloor(nX, nY, nZ) - nZ

                nX = nX - nPlayerX
                nY = nY - nPlayerY
                nZ = (nZ - nPlayerZ) / kZpointToXy

                local nLen = math.sqrt(nX * nX + nY * nY + nZ * nZ)
                if nLen < nTouch then
                    self.tTarget.nX, self.tTarget.nY, self.tTarget.nZ = nPlayerX, nPlayerY, nPlayerZ
                elseif nLen > 0.01 and nLen < self.nMaxDistance + nTouch then
                    local nDis = nLen - nTouch
                    self.tTarget.nX, self.tTarget.nY, self.tTarget.nZ = nPlayerX + nDis * nX / nLen,
                    nPlayerY + nDis * nY / nLen,
                    nPlayerZ + nDis * nZ / nLen * kZpointToXy
                    local nFloorZ = pScene.GetFloor(self.tTarget.nX, self.tTarget.nY, self.tTarget.nZ + 512) or self.tTarget.nZ
                    if math.abs(nDeltaZ) < 128 then
                        -- 0.25米
                        self.tTarget.nZ = nFloorZ   -- 2024.4.30 目标在地面则目标点也贴地
                    else
                        self.tTarget.nZ = math.max(self.tTarget.nZ, nFloorZ) -- 修正计算坐标可能在地底的问题
                    end
                end
            end
        end

        if self.bTargetFloor and (not tSkillConfig or not tSkillConfig.bAreaBoxHeightFollow) then
            self.tTarget.nZ = pScene.GetFloor(self.tTarget.nX, self.tTarget.nY, self.tTarget.nZ)
                    or self.tTarget.nZ -- 贴地
        end
    else
        -- 方向技初始化默认方向
        local nDisX = self.tTarget.nX - nPlayerX
        local nDisY = self.tTarget.nY - nPlayerY
        local nDis = kmath.metre_len(nDisX, nDisY);
        _, self.tTarget.nYaw = Camera_GetRTParams()
        if nDis < 0.02 then
            -- 距离过近则使用角色面向
            self.tTarget.nDir = math.pi * 2 * pPlayer.nFaceDirection / GLOBAL.DIRECTION_COUNT
        else
            self.tTarget.nDir = math.pi * 2 * GetLogicDirection(nDisX, nDisY) / GLOBAL.DIRECTION_COUNT
        end
    end

    local nLogicDis = kmath.logic_len(nPlayerX - self.tTarget.nX, nPlayerY - self.tTarget.nY, 0)
    if nLogicDis >= self.nMaxDistance then
        -- 限定目标点范围
        local nFactor = self.nMaxDistance / nLogicDis
        self.tTarget.nX = nPlayerX + (self.tTarget.nX - nPlayerX) * nFactor
        self.tTarget.nY = nPlayerY + (self.tTarget.nY - nPlayerY) * nFactor
    end

    if nSkillID == 41242 then -- 寻宝模式-瞬步 技能特判
        local nDir = math.pi * 2 * pPlayer.nFaceDirection / GLOBAL.DIRECTION_COUNT
        self.tTarget.nX = self.tTarget.nX + math.cos(nDir) * self.nMaxDistance
        self.tTarget.nY = self.tTarget.nY + math.sin(nDir) * self.nMaxDistance
        SkillData.SetCastPoint(self.tTarget.nX, self.tTarget.nY, self.tTarget.nZ)
        return
    end

    if self.tTarget.nDir then
        local nX, nY, nZ = pPlayer.GetAbsoluteCoordinate()
        nX = nX + math.cos(self.tTarget.nDir) * self.nMaxDistance
        nY = nY + math.sin(self.tTarget.nDir) * self.nMaxDistance

        --nZ = pScene.GetFloor(nX, nY, nZ + 1/ kMetreHeight) +100-- 坐标贴地
        SkillData.SetCastPoint(nX, nY, nZ)
    else
        SkillData.SetCastPoint(self.tTarget.nX, self.tTarget.nY, self.tTarget.nZ)
    end
end

function UISkillDirection:updateCanCastState(bCanCast, bInCancelArea)
    if self.bCanCast == bCanCast and self.bInCancelArea == bInCancelArea then
        return
    end

    self.bCanCast = bCanCast
    self.bInCancelArea = bInCancelArea

    if bCanCast and not bInCancelArea then
        if self.pDragEffect then
            self.pDragEffect:SetSFXColor(1.0, 1.0, 1.0, false)      -- 白色
        end
        if self.pCircleEffect then
            self.pCircleEffect:SetSFXColor(1.0, 1.0, 1.0, false)    -- 白色
        end
    else
        if self.pDragEffect then
            self.pDragEffect:SetSFXColor(1.0, 0, 0, true)           -- 红色
        end
        if self.pCircleEffect then
            self.pCircleEffect:SetSFXColor(1.0, 0, 0, true)         -- 红色
        end
    end
end

function UISkillDirection:UpdateCastPoint(nX, nY, nZ, bInCancelArea)
    nX = math.max(math.floor(nX), 0)     -- 向下取整避免浮点误差
    nY = math.max(math.floor(nY), 0)
    nZ = math.floor(nZ)

    if not g_pClientPlayer then
        return
    end

    local bCanCast = self.bCanCast
    if self.bCastXYZ then
        if self.canCastSkillFunc then
            bCanCast = self.canCastSkillFunc(nX, nY, nZ)
        end

        self.tTarget.nX = nX
        self.tTarget.nY = nY
        self.tTarget.nZ = nZ
    else
        local nDisX = nX - g_pClientPlayer.nX
        local nDisY = nY - g_pClientPlayer.nY
        local nDis = kmath.metre_len(nDisX, nDisY)
        _, self.tTarget.nYaw = Camera_GetRTParams()
        if nDis >= 0.02 then
            -- 避免0方向问题
            self.tTarget.nDir = math.pi * 2 * GetLogicDirection(nDisX, nDisY) / GLOBAL.DIRECTION_COUNT

            local nX, nY, nPlayerZ = g_pClientPlayer.GetAbsoluteCoordinate()
            nX = nX + math.cos(self.tTarget.nDir) * self.nMaxDistance
            nY = nY + math.sin(self.tTarget.nDir) * self.nMaxDistance
            self.tTarget.nX = nX
            self.tTarget.nY = nY
            self.tTarget.nZ = nPlayerZ
        end
    end

    self:updateCanCastState(bCanCast, bInCancelArea)
    SkillData.SetCastPoint(self.tTarget.nX, self.tTarget.nY, self.tTarget.nZ)
end

function UISkillDirection:UpdateMousePosition()
    local pPlayer = g_pClientPlayer
    local DoSelect = function(x, y, z)
        if x and y and z and pPlayer then
            local nPlayerX, nPlayerY, nPlayerZ = pPlayer.GetAbsoluteCoordinate()
            local nLogicDis = kmath.logic_len(nPlayerX - x, nPlayerY - y, 0)
            if nLogicDis >= self.nMaxDistance then
                -- 限定目标点范围
                local nFactor = self.nMaxDistance / nLogicDis
                x = nPlayerX + (x - nPlayerX) * nFactor
                y = nPlayerY + (y - nPlayerY) * nFactor

                z = pPlayer.GetScene().GetFloor(x, y, z + 1 / kMetreHeight)
            end

            if self.bAreaBoxFollow then
                z = nPlayerZ
            end

            self:UpdateCastPoint(x, y, z, false)
        end
    end
    if self.nMouseTimerID then
        Timer.DelTimer(self, self.nMouseTimerID)
        self.nMouseTimerID = nil
    end

    self.nMouseTimerID = Timer.AddFrameCycle(self, 1, function()
        local nScaleX, nScaleY = UIHelper.GetScreenToResolutionScale()
        local tCursor = Platform.IsWindows() and GetViewCursorPoint() or GetCursorPoint()
        local tPos = cc.Director:getInstance():convertToGL({ x = tCursor.x, y = tCursor.y })

        --if bRangePutOpti then
        --    PostThreadCall(DoSelect, nil, "Scene_SelectRayGround", x, y, hSkillInfo.MaxRadius - 1) ---由于表现是浮点数计算，逻辑是整数计算，存在精度问题，导致最后给的坐标的还是不合法的，要把技能释放距离减1
        --else
        PostThreadCall(DoSelect, nil, "Scene_SelectGround", tPos.x * nScaleX, tPos.y * nScaleY)
        --end
    end)

end

function UISkillDirection:createDragEffect(pSkill, bAreaBoxHeightFollow)
    self:destroyEffects()
    if self.nTrackPlayerTimerID ~= 0 then
        Timer.DelTimer(self, self.nTrackPlayerTimerID)
        self.nTrackPlayerTimerID = 0
    end

    local tAreaSfx = Const.kAreaSelectSfxs[self.nAreaBoxType]
    local szEffectFile, nEffectScaleX, nEffectScaleZ
    if self.bDynamicSkill then
        -- 动态技能栏走自己的技能特效配置
        local nEffectScale
        szEffectFile, nEffectScale = Player_GetAOESelectionSfxFile(g_pClientPlayer.nRoleType, self.nSkillID, 1)
        nEffectScaleX = nEffectScale
        nEffectScaleZ = nEffectScale
    end
    if not szEffectFile then
        szEffectFile = tAreaSfx.szDragSfx

        if tAreaSfx.bBoxArea then
            local nAreaLong
            local nAreaWidth
            if pSkill then
                nAreaLong = pSkill.nRectWidth
                nAreaWidth = pSkill.nAreaRadius
            end
            nEffectScaleX = nAreaLong and nAreaLong / tAreaSfx.nDragSfxLong or 1.0
            nEffectScaleZ = nAreaWidth and nAreaWidth / tAreaSfx.nDragSfxWidth or 1.0
        else
            local nRadius
            if pSkill and pSkill.nAreaRadius > 0 then
                nRadius = pSkill.nAreaRadius
            end

            nEffectScaleX = nRadius and nRadius / tAreaSfx.nDragSfxRadius or 1.0
            nEffectScaleZ = nEffectScaleX
        end
    end

    local nCircleScale = self.nMaxDistance / tAreaSfx.nCircleSfxRadius
    local pDrag = SceneMgr.CreateModel(szEffectFile)
    local pCircle = SceneMgr.CreateModel(tAreaSfx.szCircleSfx)
    pDrag:SetScaling(nEffectScaleX, nEffectScaleZ, nEffectScaleZ)
    pCircle:SetScaling(nCircleScale, 1.0, nCircleScale)

    local tTarget = self.tTarget
    local nTargetZ = tTarget.nZ
    local nLastTime = Timer.GetPassTime()
    local fnTimer = function()
        local nRlX, nRlY, nRlZ = Player_GetLocalRTParam()
        local nPlayerX, nPlayerY, nPlayerZ = g_pClientPlayer.GetAbsoluteCoordinate()
        local nLogicDis = kmath.logic_len(nPlayerX - tTarget.nX, nPlayerY - tTarget.nY, 0)
        if nLogicDis >= self.nMaxDistance then
            -- 限定目标点范围
            local nFactor = self.nMaxDistance / nLogicDis
            tTarget.nX = nPlayerX + (tTarget.nX - nPlayerX) * nFactor
            tTarget.nY = nPlayerY + (tTarget.nY - nPlayerY) * nFactor
        end

        local nX, nY, nZ
        if bAreaBoxHeightFollow then
            -- 是否跟随玩家
            tTarget.nZ = nPlayerZ

            nY = nRlY + kHeightOffset * kMetreHeight
            nX, _, nZ = SceneMgr.LogicPosToScenePos(tTarget.nX, tTarget.nY, tTarget.nZ + kHeightOffset)
        else
            if self.bTargetFloor then
                --tTarget.nZ = g_pClientPlayer.GetScene().GetFloor(tTarget.nX, tTarget.nY, tTarget.nZ + 1 / kMetreHeight)
                --    or tTarget.nZ                   -- 坐标贴地
                --tTarget.nZ = self:queryCastFloor(tTarget.nX, tTarget.nY, tTarget.nZ)
            end

            local nTime = Timer.GetPassTime()
            local nDeltaTime = nTime - nLastTime
            nLastTime = nTime
            if tTarget.nZ > nTargetZ then
                -- 线性位置跟随
                nTargetZ = math.min(tTarget.nZ, nTargetZ + nDeltaTime * kHeightTrackSpeed)
            else
                nTargetZ = math.max(tTarget.nZ, nTargetZ - nDeltaTime * kHeightTrackSpeed)
            end

            nX, nY, nZ = SceneMgr.LogicPosToScenePos(tTarget.nX, tTarget.nY, nTargetZ + kHeightOffset)
        end

        if self.canCastSkillFunc then
            self:updateCanCastState(self.canCastSkillFunc(tTarget.nX, tTarget.nY, tTarget.nZ), self.bInCancelArea)
        end
        pDrag:SetTranslation(nX, nY, nZ)

        if tAreaSfx.bRotate then
            -- 根据目标点与角色的方位做旋转
            local nDir = math.pi * 2 * GetLogicDirection(tTarget.nX - nPlayerX, tTarget.nY - nPlayerY) / GLOBAL.DIRECTION_COUNT
            local tQua = kmath.fromEuler(0, kLogicDirTrans - nDir, 0)
            pDrag:SetRotation(tQua.x, tQua.y, tQua.z, tQua.w)
        end

        if not bAreaBoxHeightFollow then
            -- 是否跟随玩家
            nPlayerZ = g_pClientPlayer.GetScene().GetFloor(nPlayerX, nPlayerY, nPlayerZ) or nPlayerZ
            _, nY = SceneMgr.LogicPosToScenePos(nPlayerX, nPlayerY, nPlayerZ + kHeightOffset)
        end
        pCircle:SetTranslation(nRlX, nY, nRlZ)
    end

    self.pDragEffect = pDrag
    self.pCircleEffect = pCircle
    self.nTrackPlayerTimerID = Timer.AddFrameCycle(self, 1, fnTimer)
    fnTimer()
end

function UISkillDirection:createWarningBox(pSkill, nWarningBoxType)
    self:destroyEffects()
    if self.nTrackPlayerTimerID ~= 0 then
        Timer.DelTimer(self, self.nTrackPlayerTimerID)
        self.nTrackPlayerTimerID = 0
    end

    local szEffect = kWarningBox.tSfxs[nWarningBoxType]
    if not szEffect then
        return
    end

    --local nRotation, nOffset = 0, 0
    local nScaleX, nScaleZ
    if nWarningBoxType == 1 or nWarningBoxType == 6 then
        -- 方形
        --nRotation = -2 * math.pi * (pSkill.nRectRotation + 64) / GLOBAL.DIRECTION_COUNT
        --nOffset = -pSkill.nRectOffset * 100 / kMetreLength
        nScaleX = pSkill.nRectWidth / kWarningBox.nBoxSfxWidth          -- 全宽
        nScaleZ = pSkill.nAreaRadius / kWarningBox.nBoxSfxWidth         -- 半长
    else
        nScaleX = pSkill.nAreaRadius / kWarningBox.nCircleSfxRadius
        nScaleZ = nScaleX
    end

    local pEffect = SceneMgr.CreateModel(szEffect)
    pEffect:SetScaling(nScaleX, 1.0, nScaleZ)

    local tTarget = self.tTarget
    local fnTimer = function()
        local _, nYaw = Camera_GetRTParams()
        tTarget.nDir = tTarget.nDir + tTarget.nYaw - nYaw               -- 修正角色移动过程中摄像机转动引起的转动
        tTarget.nYaw = nYaw

        local nPlayerX, nPlayerY, nPlayerZ = g_pClientPlayer.GetAbsoluteCoordinate()
        local nX, nY, nZ = Player_GetLocalRTParam()
        if self.bAreaBoxFollow then
            -- 是否跟随玩家
            nY = nY + kHeightOffset * kMetreHeight
        else
            nPlayerZ = g_pClientPlayer.GetScene().GetFloor(nPlayerX, nPlayerY, nPlayerZ)
                    or nPlayerZ
            _, nY = SceneMgr.LogicPosToScenePos(0, 0, nPlayerZ + kHeightOffset)
        end
        pEffect:SetTranslation(nX, nY, nZ)

        local tQua = kmath.fromEuler(0, kLogicDirTrans - tTarget.nDir, 0)
        pEffect:SetRotation(tQua.x, tQua.y, tQua.z, tQua.w)
    end

    self.pDragEffect = pEffect
    self.nTrackPlayerTimerID = Timer.AddFrameCycle(self, 1, fnTimer)
    fnTimer()
end

function UISkillDirection:destroyEffects()
    self.nTimerEffect = nil
    if self.pDragEffect then
        self.pDragEffect:SetSFXColor(1.0, 1.0, 1.0, false)
        SceneMgr.DestoryModel(self.pDragEffect, true)
        self.pDragEffect = nil
    end

    if self.pCircleEffect then
        self.pCircleEffect:SetSFXColor(1.0, 1.0, 1.0, false)
        SceneMgr.DestoryModel(self.pCircleEffect, true)
        self.pCircleEffect = nil
    end
end

return UISkillDirection
