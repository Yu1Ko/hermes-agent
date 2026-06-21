-- ---------------------------------------------------------------------------------
-- Author: 陈计
-- Name: UIPartnerMorphCell
-- Date: 2023-05-04 14:50:22
-- Desc: 侠客-共鸣小头像
-- Prefab: PanelMainCity/AniAll/WidgetMiddleInfo/WidgetMainCityDragInfoAnchor/WidgetPartner 下面的三个小头像
-- ---------------------------------------------------------------------------------
local MORPH_TYPE         = {
    --- 使用对应位置侠客进入幻化
    Enter = 1,
    --- 在已幻化状态下，切换为对应位置的侠客
    Ex = 2,
    --- 在已幻化状态下，切换为对应位置的侠客，且使用终极技能
    ExAndUlt = 3,
}

local ENDMORPH_SKILL     = 31335    --结束降临技能ID

local UIPartnerMorphCell = class("UIPartnerMorphCell")

---_LuaBindList 在这里对绑定的组件进行无意义自赋值，从而方便查询以及ide进行智能提示
function UIPartnerMorphCell:_LuaBindList()
    self.ImgPartner  = self.ImgPartner --- 侠客头像
    self.ImgType     = self.ImgType --- 心法图片

    self.ImgSkillCd  = self.ImgSkillCd --- 技能CD期间或者不可用时，显示该遮罩
    self.CdLabel     = self.CdLabel --- 技能CD时间

    self.BtnPartner  = self.BtnPartner --- 共鸣按钮

    self.SliderBlood = self.SliderBlood --- 开始共鸣时显示该圆圈图片，进度为血量
    self.ImgTime     = self.ImgTime --- 共鸣剩余时间图片
    self.labelTime   = self.labelTime --- 共鸣剩余时间label

    self.ImgBigSkill = self.ImgBigSkill --- 共鸣大招能量已满标记
end

function UIPartnerMorphCell:OnEnter(dwIndex, dwID)
    --- 配置的共鸣技能与槽位绑定，所以需要传入是第几个头像
    self.dwIndex  = dwIndex
    self.dwID     = dwID

    self.bInMorph = false

    if not self.bInit then
        self:RegEvent()
        self:BindUIEvent()
        self.bInit = true
    end

    self:UpdateInfo()

    Timer.AddCycle(self, 0.1, function()
        self:UpdateBloodSlider()
    end)
end

function UIPartnerMorphCell:OnExit()
    self.bInit = false
    self:UnRegEvent()
end

function UIPartnerMorphCell:BindUIEvent()
    UIHelper.BindUIEvent(self.BtnPartner, EventType.OnClick, function()
        self:OnBtnClick()
    end)

    Timer.AddCycle(self, 0.5, function()
        self:OnFrameBreathe()
    end)
end

function UIPartnerMorphCell:RegEvent()
    --Event.Reg(self, EventType.XXX, func)
    Event.Reg(self, "ON_NPC_ASSISTED_RESULT_CODE", function(nResultCode, nArg0, nArg1, nArg2)
        if nResultCode == NPC_ASSISTED_RESULT_CODE.MORPH_BEGIN then
            local dwPartnerID = nArg0

            if self.dwID == dwPartnerID then
                -- 开始共鸣
                PartnerData.bEnterHero = true

                self:UpdateMorphState(true)
            end
        elseif nResultCode == NPC_ASSISTED_RESULT_CODE.SWITCH_MORPH_SUCCESS then
            local dwOldPartnerID = nArg0
            local dwPartnerID    = nArg1

            if self.dwID == dwOldPartnerID then
                -- 旧的共鸣侠客
                self:UpdateMorphState(false)
            elseif self.dwID == dwPartnerID then
                -- 新的共鸣侠客
                self:UpdateMorphState(true)
            end

        elseif nResultCode == NPC_ASSISTED_RESULT_CODE.MORPH_END then
            local dwPartnerID = nArg0

            if self.dwID == dwPartnerID then
                -- 结束共鸣
                PartnerData.bEnterHero = false

                self:UpdateMorphState(false)
            end
        elseif nResultCode == NPC_ASSISTED_RESULT_CODE.ASSISTED_POWER_INFO_CHANGE then
            self:UpdateMorphNpcPower()
        end
    end)
    Event.Reg(self, EventType.OnActionBarBtnClick, function(nIndex, bIsDown)
        if nIndex == self.dwIndex and not bIsDown then
            self:OnBtnClick()
        end
    end)
end

function UIPartnerMorphCell:UnRegEvent()
    --Event.UnReg(self, EventType.XXX)
end






-- ----------------------------------------------------------
-- Please write your own code below  ↓↓↓
-- ----------------------------------------------------------

function UIPartnerMorphCell:UpdateInfo()
    local tInfo     = Table_GetPartnerNpcInfo(self.dwID)

    local szImgPath = tInfo.szSmallAvatarImg
    UIHelper.SetTexture(self.ImgPartner, szImgPath)

    local nKungfuIndex = tInfo.nKungfuIndex
    UIHelper.SetSpriteFrame(self.ImgType, PartnerKungfuIndexToImg[nKungfuIndex])

    UIHelper.SetVisible(self.SliderBlood, self.bInMorph)

    self:UpdateMorphNpcPower()
    self:UpdateBloodSlider()
end

function UIPartnerMorphCell:OnBtnClick()
    local nMorphType

    if PartnerData.bEnterHero then
        --- 已幻化，切换角色
        nMorphType = MORPH_TYPE.Ex
    else
        --- 未幻化，使用对应位置角色入场
        nMorphType = MORPH_TYPE.Enter
    end

    self:MorphNpc(nMorphType)
end

function UIPartnerMorphCell:MorphNpc(dwType)
    local tSkillInfo   = Table_GetPartnerMorphSkill(self.dwIndex)

    local dwSkillID
    local dwAssistedID = self.dwID
    if dwAssistedID and tSkillInfo then
        if dwType == MORPH_TYPE.Enter then
            dwSkillID = tSkillInfo.dwEnterSkillID
        elseif dwType == MORPH_TYPE.Ex then
            dwSkillID = tSkillInfo.dwExSkillID
        elseif dwType == MORPH_TYPE.ExAndUlt then
            dwSkillID = tSkillInfo.dwExAndUltSkillID
        end
        OnUseSkill(dwSkillID, (dwSkillID * (dwSkillID % 10 + 1)))
    end
end

function UIPartnerMorphCell:EndMorph()
    local dwSkillID = ENDMORPH_SKILL
    OnUseSkill(dwSkillID, dwSkillID * (dwSkillID + 1))
end

function UIPartnerMorphCell:OnFrameBreathe()
    if not PartnerData.bShowMorphInMainCity then
        return
    end

    self:UpdateSkillCoolDown()
    self:UpdateMorphEndTime()
end

function UIPartnerMorphCell:UpdateSkillCoolDown()
    local tSkillInfo   = Table_GetPartnerMorphSkill(self.dwIndex)

    local nSkillID
    local dwAssistedID = self.dwID
    if dwAssistedID and tSkillInfo then
        if PartnerData.bEnterHero then
            nSkillID = tSkillInfo.dwExSkillID
        else
            nSkillID = tSkillInfo.dwEnterSkillID
        end
    end

    local _, nLeft, nTotal = SkillData.GetSkillCDProcess(g_pClientPlayer, nSkillID)
    nLeft                  = math.ceil(nLeft / GLOBAL.GAME_FPS)
    nTotal                 = math.ceil(nTotal / GLOBAL.GAME_FPS)

    if nLeft ~= 0 then
        UIHelper.SetString(self.CdLabel, nLeft)
    else
        UIHelper.SetString(self.CdLabel, "")
    end

    local bInCD           = nLeft ~= 0

    local bPowerNotEnough = false
    if not PartnerData.bEnterHero then
        -- 尚未共鸣时，根据能量条数值，控制共鸣头像是否显示不可用遮罩
        local nPowerNum = g_pClientPlayer.GetMorphPower() * 3
        bPowerNotEnough = nPowerNum * 3 < PartnerData.nMaxPowerNum
    end

    UIHelper.SetVisible(self.ImgSkillCd, bInCD or bPowerNotEnough)
    UIHelper.SetVisible(self.CdLabel, bInCD)
end

function UIPartnerMorphCell:UpdateMorphEndTime()
    UIHelper.SetVisible(self.ImgTime, self.bInMorph)
    if not self.bInMorph then
        return
    end

    local nTimeBuffID             = 23338    --倒计时buff及最大事件

    local tBuffInfo               = Buffer_GetTimeData(nTimeBuffID)
    local nLeftFrame              = Buffer_GetLeftFrame(tBuffInfo)
    local nHour, nMinute, nSecond = TimeLib.GetTimeToHourMinuteSecondTenthSec(nLeftFrame, true)

    UIHelper.SetString(self.labelTime, nSecond)
end

function UIPartnerMorphCell:UpdateMorphState(bInMorph)
    self.bInMorph = bInMorph

    UIHelper.SetVisible(self.SliderBlood, bInMorph)
    UIHelper.SetVisible(self.ImgTime, bInMorph)

    if bInMorph then
        local tInfo = Table_GetPartnerCombatInfo(self.dwID)
        PartnerData.UpdateData(self.dwID, tInfo)
        self:UpdateMorphEndTime()
    end
end

function UIPartnerMorphCell:UpdateMorphNpcPower()
    local dwCurPower, dwMaxPower = g_pClientPlayer.GetAssistedPower(self.dwID)
    dwCurPower = dwCurPower or 0
    dwMaxPower = dwMaxPower or 1
    local bPowerEnough           = dwCurPower > 0 and dwCurPower >= dwMaxPower

    UIHelper.SetVisible(self.ImgBigSkill, bPowerEnough)
end

function UIPartnerMorphCell:UpdateBloodSlider()
    if not g_pClientPlayer then
        return
    end

    -- 共鸣后的侠客血量其实就是玩家当前的血量，共鸣后会修改该值
    local fBloodPercent               = g_pClientPlayer.nCurrentLife / g_pClientPlayer.nMaxLife
    if self.fBloodPercent == fBloodPercent then
        -- 未发生变化，则不需要更新进度条
        return
    end
    self.fBloodPercent = fBloodPercent

    UIHelper.SetProgressBarPercent(self.SliderBlood, 100 * fBloodPercent)
end

return UIPartnerMorphCell