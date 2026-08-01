-- ---------------------------------------------------------------------------------
-- Author: zeng zi peng
-- Name: UIDdzPokerCardCCList
-- Date: 2023-08-23 10:53:52
-- Desc: 斗地主癞子多选择牌型节点列表
-- ---------------------------------------------------------------------------------

local UIDdzPokerCardCCList = class("UIDdzPokerCardCCList")

function UIDdzPokerCardCCList:OnEnter()
    if not self.bInit then
        self:RegEvent()
        self:BindUIEvent()
        self.bInit = true
    end
end

function UIDdzPokerCardCCList:OnExit()
    self.bInit = false
    self:UnRegEvent()
end

function UIDdzPokerCardCCList:BindUIEvent()
    UIHelper.BindUIEvent(self.ToggleCCList , EventType.OnClick , function ()
        if self.selectCallback then
            self.selectCallback(self)
        end
    end)
end

function UIDdzPokerCardCCList:RegEvent()
    --Event.Reg(self, EventType.XXX, func)
end

function UIDdzPokerCardCCList:UnRegEvent()
    --Event.UnReg(self, EventType.XXX)
end






-- ----------------------------------------------------------
-- Please write your own code below  ↓↓↓
-- ----------------------------------------------------------

function UIDdzPokerCardCCList:UpdateInfo(nType , tInfoItem)
    self.tInfoItem = tInfoItem
    UIHelper.SetString(self.LabelCCTitle , g_tStrings.STR_DDZ_CARD_TYPE[nType])
    for k, v in pairs(self.tbCards) do
        UIHelper.SetVisible(v , tInfoItem[k] ~= nil)
        if tInfoItem[k] ~= nil then
            UIHelper.SetVisible(UIHelper.FindChildByName(v , "ImgDiZhu") , DdzPokerData.DownIsDiZhu())
            UIHelper.SetVisible(UIHelper.FindChildByName(v , "ImgShown") , DdzPokerData.DataModel.tGameData["Down"].bIsMingPai)
            LOG.TABLE(tInfoItem[k])
            UIHelper.SetSpriteFrame(UIHelper.FindChildByName(v , "ImgHandcard") , DdzPokerData.GetCardIconPath(tInfoItem[k]))
        end
    end
    self:SetSelectState(false)
end

function UIDdzPokerCardCCList:SetSelectCallback(callback)
    self.selectCallback = callback
end

function UIDdzPokerCardCCList:SetSelectState(bSelect)
    UIHelper.SetVisible(self.ImgChosenBg , bSelect)
end

return UIDdzPokerCardCCList