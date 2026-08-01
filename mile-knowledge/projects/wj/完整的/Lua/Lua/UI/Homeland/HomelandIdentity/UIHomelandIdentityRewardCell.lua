-- ---------------------------------------------------------------------------------
-- Author: Unknown
-- Name: UIHomelandIdentityRewardCell
-- Date: 2024-01-23 09:49:54
-- Desc: ?
-- ---------------------------------------------------------------------------------
local REWARD_STATE = {
    NOT_GET = 0,
    CAN_GET = 1,
    ALREADY = 2,
}
local UIHomelandIdentityRewardCell = class("UIHomelandIdentityRewardCell")

function UIHomelandIdentityRewardCell:OnEnter(tbInfo)
    if not self.bInit then
        self:RegEvent()
        self:BindUIEvent()
        self.bInit = true
    end
    self.tbInfo = tbInfo
    self:UpdateInfo()
end

function UIHomelandIdentityRewardCell:OnExit()
    self.bInit = false
    self:UnRegEvent()
end

function UIHomelandIdentityRewardCell:BindUIEvent()
    UIHelper.BindUIEvent(self.BtnReward, EventType.OnClick, function ()
        local bAlready = self.tbInfo.nRewardState == REWARD_STATE.ALREADY
        if bAlready then
            OutputMessage("MSG_ANNOUNCE_YELLOW", g_tStrings.STR_HOMELAND_REWARD_AUTOGET)
        end
    end)
end

function UIHomelandIdentityRewardCell:RegEvent()
    --Event.Reg(self, EventType.XXX, func)
end

function UIHomelandIdentityRewardCell:UnRegEvent()
    --Event.UnReg(self, EventType.XXX)
end






-- ----------------------------------------------------------
-- Please write your own code below  ↓↓↓
-- ----------------------------------------------------------

function UIHomelandIdentityRewardCell:UpdateInfo()
    local tInfo     = self.tbInfo.tRewardInfo
    local szName    = UIHelper.GBKToUTF8(tInfo.szName)
    local szDesc    = UIHelper.GBKToUTF8(tInfo.szDesc)
    local szImgPath = UIHelper.FixDXUIImagePath(tInfo.szImagePath)
    local nState    = self.tbInfo.nRewardState.nState
    local bCompleted = nState == REWARD_STATE.ALREADY
    UIHelper.SetString(self.LabelTitle, szName)
    UIHelper.SetString(self.LabelLevelTip, szDesc)
    UIHelper.SetTexture(self.ImgReward, szImgPath)
    UIHelper.SetVisible(self.ImgGot, bCompleted)
    -- if tInfo.bAutoGet then --无需领取
    --     hTextBtn:SetText(g_tStrings.STR_HOMELAND_REWARD_AUTOGET)
    -- elseif nState == REWARD_STATE.ALREADY then --已领取
    --     hTextBtn:SetText(g_tStrings.STR_HOMELAND_REWARD_ALREADY)
    -- else
    --     hTextBtn:SetText(g_tStrings.STR_HOMELAND_REWARD_CANGET)
    -- end
end


return UIHomelandIdentityRewardCell