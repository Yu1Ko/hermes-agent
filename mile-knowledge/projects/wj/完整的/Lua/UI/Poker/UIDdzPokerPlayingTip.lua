-- ---------------------------------------------------------------------------------
-- Author: zeng zi peng
-- Name: UIDdzPokerPlayingTip
-- Date: 2023-08-11 17:56:21
-- Desc: 斗地主玩家提示
-- ---------------------------------------------------------------------------------

local UIDdzPokerPlayingTip = class("UIDdzPokerPlayingTip")

function UIDdzPokerPlayingTip:OnEnter()
    if not self.bInit then
        self:RegEvent()
        self:BindUIEvent()
        self.bInit = true
    end
end

function UIDdzPokerPlayingTip:OnExit()
    self.bInit = false
    self:UnRegEvent()
end

function UIDdzPokerPlayingTip:BindUIEvent()
    
end

function UIDdzPokerPlayingTip:RegEvent()
    --Event.Reg(self, EventType.XXX, func)
end

function UIDdzPokerPlayingTip:UnRegEvent()
    --Event.UnReg(self, EventType.XXX)
end



-- ----------------------------------------------------------
-- Please write your own code below  ↓↓↓
-- ----------------------------------------------------------

function UIDdzPokerPlayingTip:ShowDizhuPlayingTip(bShow , nState)
    self:HideWidget()
    UIHelper.SetVisible(self.Dizhu , bShow)
    if bShow then
        UIHelper.SetVisible(self.ImgJiaoDiZhu , nState == DdzPokerData.PLAYER_STATE.CALL_ISDIZHU)
        UIHelper.SetVisible(self.ImgBuJiao , nState ==  DdzPokerData.PLAYER_STATE.BU_CALL)
        UIHelper.SetVisible(self.ImgQiangDizhu , nState ==  DdzPokerData.PLAYER_STATE.QIANG_ISDIZHU)
        UIHelper.SetVisible(self.ImgBuQiang , nState ==  DdzPokerData.PLAYER_STATE.BU_QIANG)
    end
end

function UIDdzPokerPlayingTip:ShowJiaBeiPlayingTip(bShow , nDoubleType)
    self:HideWidget()
    UIHelper.SetVisible(self.BeiShu , bShow)
    if bShow then
        local bPreVis = UIHelper.GetVisible(self.AniJiaBei)
        local bNowVis = nDoubleType ==DdzPokerData.DOUBLE.JIABEI
        UIHelper.SetVisible(self.AniJiaBei , bNowVis)
        if bNowVis ~= bPreVis then
            SoundMgr.PlaySound(SOUND.UI_SOUND , DdzPokerData.GetSoundPath("szJiaBei"))
        end
        bPreVis = UIHelper.GetVisible(self.AniSuperJiaBei)
        bNowVis = nDoubleType ==DdzPokerData.DOUBLE.SUPER_JIABEI
        UIHelper.SetVisible(self.AniSuperJiaBei , bNowVis)
        if bNowVis ~= bPreVis then
            SoundMgr.PlaySound(SOUND.UI_SOUND , DdzPokerData.GetSoundPath("szSuperJiaBei"))
        end
        UIHelper.SetVisible(self.ImgBuJiaBei , nDoubleType ==DdzPokerData.DOUBLE.BU_JIABEI)
    end
end

function UIDdzPokerPlayingTip:ShowYaoBuQiPlayingTip(bShow)
    self:HideWidget()
    UIHelper.SetVisible(self.YaoBuQi , bShow)
end

function UIDdzPokerPlayingTip:HideWidget()
    UIHelper.SetVisible(self.Dizhu , false)
    UIHelper.SetVisible(self.BeiShu , false)
    UIHelper.SetVisible(self.YaoBuQi , false)
end

return UIDdzPokerPlayingTip