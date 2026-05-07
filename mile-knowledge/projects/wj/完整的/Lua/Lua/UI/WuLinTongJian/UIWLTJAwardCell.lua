-- ---------------------------------------------------------------------------------
-- Author: Unknown
-- Name: UIWLTJAwardCell
-- Date: 2023-05-22 16:44:05
-- Desc: ?
-- ---------------------------------------------------------------------------------

local UIWLTJAwardCell = class("UIWLTJAwardCell")

function UIWLTJAwardCell:OnEnter(tAwardInfo)
    if not self.bInit then
        self:RegEvent()
        self:BindUIEvent()
        self.bInit = true
    end

    self.tAwardInfo = tAwardInfo
    UIHelper.SetString(self.LabelAwardName,tAwardInfo.szTitle)
    UIHelper.SetString(self.LabelPrograss,tAwardInfo.nFinishNum.."/"..tAwardInfo.tRewardInfo.nRewardScore)
    UIHelper.SetVisible(self.ImgDone,tAwardInfo.bDone)
    UIHelper.SetVisible(self.WidgetGet, (not tAwardInfo.bDone) and (tAwardInfo.nFinishNum >= tAwardInfo.tRewardInfo.nRewardScore))
    self.ImgAward:setTexture(UIHelper.UTF8ToGBK(tAwardInfo.szPath), false)
    if tAwardInfo.dwAvatarID and tAwardInfo.dwAvatarID > 0 then
        UIHelper.SetVisible(self.ImgAward, false)
        UIHelper.SetVisible(self.WidgetPlayerNormal, true)
     
        local dwAvatarID = tAwardInfo.dwAvatarID
        local line = g_tTable.RoleAvatar:Search(dwAvatarID)
        local itemicon = UIHelper.AddPrefab(PREFAB_ID.WidgetCustomAvatarContent, self.WidgetHeadFrameShell, dwAvatarID, line, false)
        UIHelper.SetNodeSwallowTouches(itemicon._rootNode, false, true)
        itemicon:OnlyShow()
    else
        UIHelper.SetVisible(self.ImgAward, true)
        UIHelper.SetVisible(self.WidgetPlayerNormal, false)
    end
end

function UIWLTJAwardCell:OnExit()
    self.bInit = false
    self:UnRegEvent()
end

function UIWLTJAwardCell:BindUIEvent()
    UIHelper.BindUIEvent(self.BtnGet,EventType.OnClick,function ()
        if not self.tAwardInfo.bDone and self.tAwardInfo.nFinishNum >= self.tAwardInfo.tRewardInfo.nRewardScore then
            RemoteCallToServer("On_DLC_GetDLCReward", self.tAwardInfo.nCurrentDLCID, self.tAwardInfo.nRewardNum)
        end
    end)
end

function UIWLTJAwardCell:RegEvent()
    --Event.Reg(self, EventType.XXX, func)
    Event.Reg(self, "QUEST_FINISHED", function ()
        self:UpdateQuestState()
    end)

    Event.Reg(self, "SET_QUEST_STATE", function ()
        self:UpdateQuestState()
    end)
end

function UIWLTJAwardCell:UnRegEvent()
    --Event.UnReg(self, EventType.XXX)
end






-- ----------------------------------------------------------
-- Please write your own code below  ↓↓↓
-- ----------------------------------------------------------

function UIWLTJAwardCell:UpdateQuestState()
    local nAwardState = g_pClientPlayer.GetQuestPhase(self.tAwardInfo.tRewardInfo.nRewardQuestID)
    self.tAwardInfo.bDone = nAwardState == QUEST_PHASE.FINISH
    UIHelper.SetVisible(self.ImgDone, self.tAwardInfo.bDone)
    UIHelper.SetVisible(self.WidgetGet, (not self.tAwardInfo.bDone) and (self.tAwardInfo.nFinishNum >= self.tAwardInfo.tRewardInfo.nRewardScore))
end


return UIWLTJAwardCell