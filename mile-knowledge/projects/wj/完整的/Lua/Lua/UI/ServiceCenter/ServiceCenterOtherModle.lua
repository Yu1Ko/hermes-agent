-- ---------------------------------------------------------------------------------
-- Author: zengzipeng
-- Name: ServiceCenterOtherModle
-- Date: 2023-06-20 15:01:45
-- Desc: 客服中心 - 其他
-- ---------------------------------------------------------------------------------

local ServiceCenterOtherModle = class("ServiceCenterOtherModle")
local ModleType =
{
    ActivationCode   = 1,  -- 激活码
    Recharge         = 2,  -- 充值
    TongChangeName   = 3,  -- 帮派改名
    PlayerChangeName = 4,  -- 角色改名
    Service          = 5,  -- 客服专区
    OnLineCall       = 6,  -- 在线咨询
    PlayerReserve    = 7,  -- 角色转服
    BugReward        = 8,  -- BUG悬赏
    ClientBug        = 9,  -- 客户端问题
    GameBug          = 10, -- 游戏问题
    PassCancel       = 11, -- 通行证注销
}
function ServiceCenterOtherModle:OnEnter()
    if not self.bInit then
        self:RegEvent()
        self:BindUIEvent()
        self.bInit = true
    end
end

function ServiceCenterOtherModle:OnExit()
    self.bInit = false
    self:UnRegEvent()
end

function ServiceCenterOtherModle:BindUIEvent()
    for i, v in ipairs(self.tbModleList) do
        UIHelper.BindUIEvent(v , EventType.OnClick , function ()
           self:OnSelectModle(i)
        end)
        UIHelper.SetVisible(v , UIHelper.GetVisible(v) and (i ~= ModleType.BugReward and i~= ModleType.GameBug and i~= ModleType.ClientBug))
    end
end

function ServiceCenterOtherModle:RegEvent()

end

function ServiceCenterOtherModle:UnRegEvent()
    --Event.UnReg(self, EventType.XXX)
end






-- ----------------------------------------------------------
-- Please write your own code below  ↓↓↓
-- ----------------------------------------------------------
function ServiceCenterOtherModle:OnSelectModle(nModleType)
    if nModleType == ModleType.Service then
        WebUrl.OpenByID(WEBURL_ID.WEB_SERVICE_AREA)
    elseif nModleType == ModleType.BugReward then
        UIHelper.OpenWeb("https://xs.daily.xoyo.com")
    elseif nModleType == ModleType.PlayerReserve then
        APIHelper.OpenURL_PlayerReserve()
    elseif nModleType == ModleType.Recharge then
        UIMgr.Open(VIEW_ID.PanelTopUpMain)
        --UIHelper.OpenWeb(tUrl.Recharge)
    elseif nModleType == ModleType.ClientBug then
        UIHelper.OpenWeb(tUrl.ClientFAQ, false, true)
    elseif nModleType == ModleType.GameBug then
        UIHelper.OpenWeb(tUrl.ServiceInstruction)
    elseif nModleType == ModleType.PassCancel then
        UIHelper.OpenWeb(tUrl.Unregister , false , true)
    elseif nModleType == ModleType.ActivationCode then
        UIMgr.Open(VIEW_ID.PanelKeyExchangePop)
    elseif nModleType == ModleType.TongChangeName then
        local player = GetClientPlayer()
		if not player.dwTongID or player.dwTongID == 0 then
            TipsHelper.ShowNormalTip(g_tStrings.STR_CANNOT_GUILD_RENAME)
        else
            GetTongClient().ApplyTongInfo()
            UIMgr.Open(VIEW_ID.PanelFactionRenamePop)
		end
    elseif nModleType == ModleType.PlayerChangeName then
        UIMgr.Open(VIEW_ID.PanelChangeNamePop)
    end
end


return ServiceCenterOtherModle