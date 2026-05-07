-- ---------------------------------------------------------------------------------
-- Author: zhengjianqiang
-- Name: UIWidgetTongInfo
-- Date: 2023-01-06
-- Desc: 帮会信息页
-- Prefab: WidgetFactionManagementFaction
-- ---------------------------------------------------------------------------------

---@class UIWidgetTongInfo
local UIWidgetTongInfo = class("UIWidgetTongInfo")

---_LuaBindList 在这里对绑定的组件进行无意义自赋值，从而方便查询以及ide进行智能提示
function UIWidgetTongInfo:_LuaBindList()
    self.LayoutFactionName  = self.LayoutFactionName --- 帮会名称的layout
    self.LayoutMenberAndTip = self.LayoutMenberAndTip --- 帮众上限的layout
    self.LayoutFactionMoney = self.LayoutFactionMoney --- 帮会资金的layout
    self.LayoutBranAndTip   = self.LayoutBranAndTip --- 战功牌数的layout
end

local g2u = UIHelper.GBKToUTF8
local u2g = UIHelper.UTF8ToGBK

function UIWidgetTongInfo:Init()
    self.m = {}
    self:RegEvent()
    self:BindUIEvent()

    self:RequestData()
end

function UIWidgetTongInfo:UnInit()
    self:UnRegEvent()
    UIHelper.RemoveFromParent(self._rootNode)
    self.m = nil
end

function UIWidgetTongInfo:BindUIEvent()
    UIHelper.BindUIEvent(self.TogMemberCeiling, EventType.OnClick, function()
        UIHelper.SetTouchLikeTips(self.WidgetTips01, UIMgr.GetLayer(UILayer.Page), function()
            UIHelper.SetSelected(self.TogMemberCeiling, false)
        end)
    end)
    UIHelper.BindUIEvent(self.TogBrand, EventType.OnClick, function()
        UIHelper.SetTouchLikeTips(self.WidgetTips02, UIMgr.GetLayer(UILayer.Page), function()
            UIHelper.SetSelected(self.TogBrand, false)
        end)
    end)
    UIHelper.BindUIEvent(self.BtnModify, EventType.OnClick, function()
        UIMgr.Open(VIEW_ID.PanelFactionRenamePop)
    end)
    UIHelper.RegisterEditBoxEnded(self.EditBox, function()
        self:OnEditBoxEnded()
    end)

end

function UIWidgetTongInfo:RegEvent()
    Event.Reg(self, "UPDATE_TONG_INFO_FINISH", function()
        self:InitUI()
    end)
    Event.Reg(self, "TONG_EVENT_NOTIFY", function()
        if arg0 == TONG_EVENT_CODE.MODIFY_INTRODUCTION_SUCCESS
                or arg0 == TONG_EVENT_CODE.RENAME_SUCCESS
                or arg0 == TONG_EVENT_CODE.ILLEGAL_TONG_INFO
        then
            GetTongClient().ApplyTongInfo()
        end
    end)
end

function UIWidgetTongInfo:UnRegEvent()
    Event.UnRegAll(self)
end






-- ----------------------------------------------------------
-- Please write your own code below  ↓↓↓
-- ----------------------------------------------------------

function UIWidgetTongInfo:RequestData()
    GetTongClient().ApplyTongInfo()
end

function UIWidgetTongInfo:InitUI()
    local tong = GetTongClient()
    assert(tong)

    -- 帮会名称
    UIHelper.SetString(self.LabelFactionName, g2u(tong.szTongName))
    -- 帮主名称
    local tMasterInfo = TongData.GetMasterInfo()
    if tMasterInfo then
        UIHelper.SetString(self.LabelFactionMasterName, g2u(tMasterInfo.szName))
    end
    -- 帮众数量
    local nTotal, nOnline = TongData.GetMemberCount()
    UIHelper.SetString(self.LabelMemberNum, string.format("%d/%d", nOnline, nTotal))
    -- 帮众人数上限
    UIHelper.SetString(self.LabelMemberCeilingNum, tostring(tong.nMaxMemberCount))
    -- 帮会资金
    UIHelper.SetString(self.LabelMemberFundNum, tostring(tong.nFund))
    -- 阵营转换
    --UIHelper.SetString(self.LabelCampConversion01, "")
    -- 帮众据点
    local szStronghold = g_tStrings.STR_NONE
    local dwCastleID   = tonumber(TableGet(TongData.GetCustomData(), "DW_CASTLE_ID"))
    if dwCastleID then
        local tLine = Table_GetCastleInfo(dwCastleID)
        if tLine and tLine.szCastleName and tLine.szCastleName ~= "" then
            szStronghold = tLine.szCastleName
        end
    end
    UIHelper.SetString(self.LabelMemberStronghold01, szStronghold)
    -- 战功奖牌
    local nNum = TableGet(TongData.GetCustomData(), "DW_CASTLE_PIECE")
    UIHelper.SetString(self.LabelBrandNum, nNum)
    -- 战勋牌数
    local nMeritBrandNum = tong.nTongLeagueToken or 0
    UIHelper.SetString(self.LabelMeritBrandNum, nMeritBrandNum)
    -- 阵营
    UIHelper.SetString(self.LabelCamp, g_tStrings.STR_GUILD_CAMP_T[TongData.GetCamp()])

    -- 简介
    self.m.szIntroduction = g2u(tong.szIntroduction)
    UIHelper.SetString(self.EditBox, self.m.szIntroduction)
    local bCanOperate = TongData.CanBaseOperate(g_pClientPlayer.dwID, TONG_OPERATION_INDEX.MODIFY_INTRODUCTION)
    UIHelper.SetVisible(self.BtnClose03, not bCanOperate)

    -- 把几个layout重新排版下
    UIHelper.CascadeDoLayoutDoWidget(self.LayoutFactionName, true, true)
    UIHelper.CascadeDoLayoutDoWidget(self.LayoutMenberAndTip, true, true)
    UIHelper.CascadeDoLayoutDoWidget(self.LayoutFactionMoney, true, true)
    UIHelper.CascadeDoLayoutDoWidget(self.LayoutBranAndTip, true, true)
end

function UIWidgetTongInfo:OnEditBoxEnded()
    if self.m.bDoNothing then return end

    local sz = UIHelper.GetString(self.EditBox)
    if sz ~= self.m.szIntroduction then
        if BankLock.CheckHaveLocked(SAFE_LOCK_EFFECT_TYPE.TONG_OPERATE, "Tong") then
            self.m.bDoNothing = true
            UIHelper.SetString(self.EditBox, self.m.szIntroduction)
            self.m.bDoNothing = false
            return
        end

        -- 延时弹出, 立即弹出会因为触发Ended的点击事件导致对话框的关闭
        Timer.Add(self, 0.1, function()
            UIHelper.ShowConfirm("确认保存修改吗?",
                                 function()
                                     GetTongClient().ApplyModifyIntroduction(u2g(sz))
                                 end,
                                 function()
                                     self.m.bDoNothing = true
                                     UIHelper.SetString(self.EditBox, self.m.szIntroduction)
                                     self.m.bDoNothing = false
                                 end,
                                 false)
        end)
    end
end

return UIWidgetTongInfo