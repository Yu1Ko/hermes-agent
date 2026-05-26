-- ---------------------------------------------------------------------------------
-- Author: 陈计
-- Name: UIPartnerMorph
-- Date: 2023-04-28 16:26:08
-- Desc: 侠客-共鸣组件
-- Prefab: PanelMainCity/AniAll/WidgetMiddleInfo/WidgetMainCityDragInfoAnchor/WidgetPartner
-- ---------------------------------------------------------------------------------

local UIPartnerMorph = class("UIPartnerMorph")

---_LuaBindList 在这里对绑定的组件进行无意义自赋值，从而方便查询以及ide进行智能提示
function UIPartnerMorph:_LuaBindList()
    self.BtnTogglePartnerList  = self.BtnTogglePartnerList --- 展开/收起共鸣列表

    self.SliderMorphPower      = self.SliderMorphPower --- 共鸣能量进度条

    self.LayoutDynamicWidthImg = self.LayoutDynamicWidthImg --- 展开的共鸣列表的动态宽度的背景图片的layout容器
    self.LayoutPartnerList     = self.LayoutPartnerList --- 展开的共鸣列表的layout
    self.tPartnerWidgetList    = self.tPartnerWidgetList --- 共鸣侠客头像组件列表

    self.ImgSkillCd            = self.ImgSkillCd --- 遮罩
    self.CdLabel               = self.CdLabel --- 显示共鸣剩余时间

    self.ImgArrow1             = self.ImgArrow1 --- 未展开时的右箭头
end

function UIPartnerMorph:OnEnter()
    if not self.bInit then
        self:RegEvent()
        self:BindUIEvent()

        Timer.AddFrameCycle(self, 1, function()
            self:OnFrameBreathe()
        end)

        self.bInit = true
    end

    self:UpdateInfo()
end

function UIPartnerMorph:OnExit()
    self.bInit = false
    self:UnRegEvent()
end

function UIPartnerMorph:BindUIEvent()
    UIHelper.BindUIEvent(self.BtnTogglePartnerList, EventType.OnClick, function()
        local bVisible = UIHelper.GetVisible(self.LayoutDynamicWidthImg)
        local bShowRightPart = not bVisible
        
        UIHelper.SetVisible(self.LayoutDynamicWidthImg, bShowRightPart)
        UIHelper.SetVisible(self.ImgArrow1, not bShowRightPart)
    end)
end

function UIPartnerMorph:RegEvent()
    --Event.Reg(self, EventType.XXX, func)
    Event.Reg(self, "ON_NPC_ASSISTED_RESULT_CODE", function(nResultCode, nArg0, nArg1, nArg2)
        if nResultCode == NPC_ASSISTED_RESULT_CODE.MORPH_BEGIN then
            UIHelper.SetVisible(self.ImgSkillCd, true)
            UIHelper.SetVisible(self.CdLabel, true)
            self:UpdateMorphEndTime()

            self.nMorphEndTimeTimer = Timer.AddCycle(self, 0.5, function()
                self:UpdateMorphEndTime()
            end)
        elseif nResultCode == NPC_ASSISTED_RESULT_CODE.SWITCH_MORPH_SUCCESS then

        elseif nResultCode == NPC_ASSISTED_RESULT_CODE.MORPH_END then
            UIHelper.SetVisible(self.ImgSkillCd, false)
            UIHelper.SetVisible(self.CdLabel, false)
            if self.nMorphEndTimeTimer then
                Timer.DelTimer(self, self.nMorphEndTimeTimer)
                self.nMorphEndTimeTimer = nil
            end
        elseif nResultCode == NPC_ASSISTED_RESULT_CODE.SET_MORPH_LIST_SUCCESS
                or nResultCode == NPC_ASSISTED_RESULT_CODE.RESET_MORPH_LIST_SUCCESS
                or nResultCode == NPC_ASSISTED_RESULT_CODE.SET_ASSISTED_LIST_SUCCESS
        then
            self:UpdateInfo()
        end
    end)
end

function UIPartnerMorph:UnRegEvent()
    --Event.UnReg(self, EventType.XXX)
end






-- ----------------------------------------------------------
-- Please write your own code below  ↓↓↓
-- ----------------------------------------------------------

function UIPartnerMorph:UpdateInfo()
    self:UpdateNpcMorphPower()
    self:UpdatePartnerList()
end

function UIPartnerMorph:OnFrameBreathe()
    self:UpdateNpcMorphPower()
end

function UIPartnerMorph:UpdateNpcMorphPower()
    local nPowerNum = g_pClientPlayer and g_pClientPlayer.GetMorphPower() * 3 or 0
    local fPercent  = nPowerNum / PartnerData.nMaxPowerNum

    UIHelper.SetProgressBarPercent(self.SliderMorphPower, 100 * fPercent)
end

function UIPartnerMorph:UpdateMorphEndTime()
    local nTimeBuffID             = 23338    --倒计时buff及最大事件

    local tBuffInfo               = Buffer_GetTimeData(nTimeBuffID)
    local nLeftFrame              = Buffer_GetLeftFrame(tBuffInfo)
    local nHour, nMinute, nSecond = TimeLib.GetTimeToHourMinuteSecondTenthSec(nLeftFrame, true)

    UIHelper.SetString(self.CdLabel, nSecond)
end

function UIPartnerMorph:UpdatePartnerList()
    local tMorphIDList = PartnerData.GetMorphList()

    for idx, tPartnerWidget in ipairs(self.tPartnerWidgetList) do
        local bShouldShow = idx <= #tMorphIDList
        UIHelper.SetVisible(tPartnerWidget, bShouldShow)

        if idx <= #tMorphIDList then
            local dwPartnerID = tMorphIDList[idx]

            local tScript     = UIHelper.GetBindScript(tPartnerWidget)
            tScript:OnEnter(idx, dwPartnerID)
        end
    end

    UIHelper.CascadeDoLayoutDoWidget(self.LayoutDynamicWidthImg, true, true)
end

return UIPartnerMorph