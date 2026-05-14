
SkillMgr = SkillMgr or {className = "SkillMgr"}

function SkillMgr.Init()
    SkillMgr.RegEvent()
end

function SkillMgr.RegEvent()
    --Event.Reg(SkillMgr, EventType.OnKeyboardDown, function(nKeyCode, szKeyName)
    --    if nKeyCode == cc.KeyCode.KEY_L then
    --        LOG.INFO("SkillMgr.Init KEY_L Pressed")
    --
    --    end
    --
    --    if nKeyCode == cc.KeyCode.KEY_O then
    --        OutputMessage("MSG_ANNOUNCE_NORMAL", string.format("最大怒气 %d 当前怒气 %d ",g_pClientPlayer.nMaxRage, g_pClientPlayer.nCurrentRage))
    --    end
    --    if nKeyCode == cc.KeyCode.KEY_T then
    --        print("SkillMgr.Init KEY_L Pressed")
    --        SearchEnemyVer2()
    --        local player = GetClientPlayer()
    --        local dwTargetType, dwTargetID = player.GetTarget()
    --
    --        LOG.INFO(TARGET.NO_TARGET)
    --        if dwTargetType ~= TARGET.NO_TARGET then
    --            LOG.INFO(dwTargetType .. " " .. dwTargetID)
    --            TargetSelection_AttachSceneObject(dwTargetID, dwTargetType)
    --            SceneObject_SetBrightness(dwTargetType, dwTargetID, 1)
    --            OnTargetSelectionShowSFX(player, dwTargetID, dwTargetType)
    --        else
    --            LOG.INFO('Target not found')
    --        end
    --    end
    --
    --    if nKeyCode == cc.KeyCode.KEY_Z then
    --        --local a1,a2,a3,a4,a5,a6,x,y,z = Camera_GetRTParams()
    --        --local player = GetControlPlayer()
    --        --local f,g,h = player.GetAbsoluteCoordinate()
    --        --local trueX = x - a4
    --        --local trueY = z - a6
    --        --local distance = kmath.len2(0, 0,trueX,trueY)
    --        --local nNormalizeX, nNormalizeY = kmath.normalize2(trueX, trueY)
    --        --
    --        --local forward = cc.p(nNormalizeX,nNormalizeY)
    --        --
    --        --local up = cc.p(0,1)
    --        --local deg_45 = cc.p(0.70710678118655,0.70710678118655)
    --        --local radius = cc.pGetAngle(up,deg_45) -- 向量夹角：弧度
    --        --local angle = radius/math.pi * 180 -- 向量夹角：弧度
    --        --
    --        ----local newTe =  cc.pRotateByAngle(up, cc.p(0, 0), cc.degreesToRadians(45))
    --        --local calculated = cc.pForAngle(radius)
    --        --local newTe =  cc.pRotate( forward,calculated)
    --        --print(newTe)
    --        --
    --        -- CastSkillXYZ(100012, 1, f + newTe.x *distance,  g + newTe.y *distance, h)
    --        ---- LOG.INFO("Camera Direction %f %f",CameraMgr.tDirectionVector.nX,CameraMgr.tDirectionVector.nY )
    --        --SkillMgr.AutoRun(true)
    --    end
    --end)
end

function SkillMgr.UnRegEvent()
    LOG.INFO("SkillMgr.Init UnInit UnReg All.")
    Event.UnRegAll(SkillMgr)
end

function SkillMgr.UnInit()
    SkillMgr.UnRegEvent()
end

function SkillMgr.OnReload()
    SkillMgr.UnRegEvent()
    SkillMgr.RegEvent()
end

----------------------------------------------------------

---@note 自动跑步
---@param bState boolean
function SkillMgr.AutoRun(bState)
    Camera_EnableControl(CONTROL_AUTO_RUN, bState)
end

---@note 切换跑/走
function SkillMgr.ToggleRun()
    ToggleRun()
end

---@note 大轻功
function SkillMgr.Sprint()
    StartSprint()
end

---@note 扶摇
function SkillMgr.FuYao()
    OnUseSkill(FUYAO_SKILL_ID, 1)
end

---@note 冲刺
function SkillMgr.Dash()
    OnUseSkill(100005, 1)
end

function SkillMgr.GetDashSkillID()
    return 100005
end

function SkillMgr.GetFuYaoSkillID()
    return FUYAO_SKILL_ID
end
