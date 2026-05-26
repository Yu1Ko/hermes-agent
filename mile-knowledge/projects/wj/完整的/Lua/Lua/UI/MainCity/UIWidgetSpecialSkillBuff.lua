-- ---------------------------------------------------------------------------------
-- Author: Unknown
-- Name: UIWidgetSpecialSkillBuff
-- Date: 2025-08-25 14:48:05
-- Desc: ?
-- ---------------------------------------------------------------------------------
--10225, 10224, 10015
local UIWidgetSpecialSkillBuff = class("UIWidgetSpecialSkillBuff")
local tbKungFuID2Widget = {
    [10021] = "WidgetWanHuaSanDu",
    [10585] = "WidgetLingXue",
    [10627] = "WidgetYaoZong",
    -- [10224] = "WidgetTangMen"
    [10225] = "WidgetTianLuoTianNv",
    [10224] = "WidgetJingYuHuaXue",
    [10015] = "WidgetChunYang",
}

function UIWidgetSpecialSkillBuff:OnEnter(bCustom)
    if not self.bInit then
        self:RegEvent()
        self:BindUIEvent()
        self.bInit = true
    end
    self:UpdateInfo(bCustom)
end

function UIWidgetSpecialSkillBuff:OnExit()
    self.bInit = false
    self:UnRegEvent()
end

function UIWidgetSpecialSkillBuff:BindUIEvent()
    
end

function UIWidgetSpecialSkillBuff:RegEvent()
    --Event.Reg(self, EventType.XXX, func)
end

function UIWidgetSpecialSkillBuff:UnRegEvent()
    --Event.UnReg(self, EventType.XXX)
end






-- ----------------------------------------------------------
-- Please write your own code below  ↓↓↓
-- ----------------------------------------------------------

function UIWidgetSpecialSkillBuff:UpdateInfo(bCustom)
    self:RemoveUseLessWidget(bCustom)
end

function UIWidgetSpecialSkillBuff:RemoveUseLessWidget(bCustom)
    local hPlayer = GetClientPlayer()
    if not hPlayer then
        return false
    end

    local nCurKungFuID = hPlayer.GetActualKungfuMountID()

    for nKungFuID, szWidget in pairs(tbKungFuID2Widget) do
        if nCurKungFuID and nCurKungFuID == nKungFuID then
            local node = self[szWidget]
            if node then
                local tbScript = UIHelper.GetBindScript(node)
                if tbScript then
                    tbScript:OnEnter(bCustom)
                end
            end
        else
            UIHelper.RemoveFromParent(self[szWidget])
        end
    end

    if bCustom then
        UIHelper.BindUIEvent(self.BtnSelectZoneLight, EventType.OnClick, function()  --进入黑框,maincity加载新的
            Event.Dispatch("ON_ENTER_SINGLENODE_CUSTOM", CUSTOM_RANGE.FULL, CUSTOM_TYPE.SPECIALSKILLBUFF, self.nMode)
        end)
    end
end

function UIWidgetSpecialSkillBuff:UpdateCustomState()
    if SkillData.IsDXSpecialSkillBuffShow() then
        self:UpdateCustomNodeState(CUSTOM_BTNSTATE.EDIT)
    end
end

function UIWidgetSpecialSkillBuff:UpdatePrepareState(nMode, bStart)
    if SkillData.IsDXSpecialSkillBuffShow() then
        self:UpdateCustomNodeState(bStart and CUSTOM_BTNSTATE.ENTER or CUSTOM_BTNSTATE.COMMON)
        self.nMode = nMode
    end
end

function UIWidgetSpecialSkillBuff:UpdateCustomNodeState(nState)
    if not SkillData.IsDXSpecialSkillBuffShow() then
        return
    end
    local szFrame = nState == CUSTOM_BTNSTATE.CONFLICT and "UIAtlas2_MainCity_MainCity1_maincitykuang3" or "UIAtlas2_MainCity_MainCity1_maincitykuang4"
    UIHelper.SetSpriteFrame(self.ImgSelectZone, szFrame)
    UIHelper.SetVisible(self.ImgSelectZone, nState == CUSTOM_BTNSTATE.CONFLICT or nState == CUSTOM_BTNSTATE.EDIT)
    UIHelper.SetVisible(self.BtnSelectZoneLight, nState == CUSTOM_BTNSTATE.ENTER or nState == CUSTOM_BTNSTATE.CONFLICT or nState == CUSTOM_BTNSTATE.OTHER)
    UIHelper.SetVisible(self.ImgSelectZoneLight, nState == CUSTOM_BTNSTATE.ENTER)
    self.nState = nState
end


return UIWidgetSpecialSkillBuff