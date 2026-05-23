-- ---------------------------------------------------------------------------------
-- Author: zeng zi peng
-- Name: UIDdzPokerCard
-- Date: 2023-08-08 10:56:55
-- Desc: 斗地主卡牌信息
-- ---------------------------------------------------------------------------------

local UIDdzPokerCard = class("UIDdzPokerCard")
local USE_ALPHA = 150
local NORMAL_ALPHA = 255
local tbColorMap = 
{
    [0] = "Spade",
	[1] = "Heart",
	[2] = "Club",
	[3] = "Diamond",
    [4] = ""
}

function UIDdzPokerCard:OnEnter()
    if not self.bInit then
        self:RegEvent()
        self:BindUIEvent()
        self.bInit = true
    end
    self.tCard = {}
end

function UIDdzPokerCard:OnExit()
    self.bInit = false
    self:UnRegEvent()
end

function UIDdzPokerCard:BindUIEvent()
    if self.btnTouch then
        UIHelper.BindUIEvent(self.btnTouch , EventType.OnClick , function ()
            if DdzPokerData.bLockHandCard then
                return
            end
            self:UpdateCardClick()
        end)

        UIHelper.BindUIEvent(self.WidgetHandcardUp , EventType.OnClick , function ()
            if DdzPokerData.bLockHandCard then
                return
            end
            self:UpdateCardClick()
        end)
    end
   
end

function UIDdzPokerCard:RegEvent()
    --Event.Reg(self, EventType.XXX, func)
end

function UIDdzPokerCard:UnRegEvent()
    --Event.UnReg(self, EventType.XXX)
end


-- ----------------------------------------------------------
-- Please write your own code below  ↓↓↓
-- ----------------------------------------------------------

function UIDdzPokerCard:UpdateInfo()
    
end

function UIDdzPokerCard:UpdateCardType(nCardType)
    self.nCardType = nCardType
    local szSkin = DdzPokerData.GetCardSkin()
    UIHelper.SetSpriteFrame(self.ImgCard, string.format("UIAtlas2_Ddz_PokerCounter%s_CounterNum"..DdzPokerData.tbPokerNumAtlasSymbol[nCardType], szSkin))
end

function UIDdzPokerCard:InitLaiziIcon(nDiCardNum , nTianCardNum )
    local bShow = self.nCardType == nDiCardNum or self.nCardType  == nTianCardNum
    if bShow  then
        UIHelper.SetVisible(self.ImgTian , DdzPokerData.DataModel.nTableType == DdzPokerData.TABLE_TYPE.DOUBLE_LAIZI and self.nCardType == nTianCardNum)
        UIHelper.SetVisible(self.ImgDi , DdzPokerData.DataModel.nTableType == DdzPokerData.TABLE_TYPE.DOUBLE_LAIZI and self.nCardType == nDiCardNum)
        UIHelper.SetVisible(self.ImgSingle , DdzPokerData.DataModel.nTableType == DdzPokerData.TABLE_TYPE.SINGLE_LAIZI)
    else
        UIHelper.SetVisible(self.ImgTian , false)
        UIHelper.SetVisible(self.ImgDi ,false)
        UIHelper.SetVisible(self.ImgSingle , false)
    end
end

function UIDdzPokerCard:UpdateLaiziState(bVisible)
    if self.nCardType == DdzPokerData.LittleJokerSymbol or self.nCardType == DdzPokerData.BigJokerSymbol then
        UIHelper.SetVisible(self.WidgetLaiZi , false)
    else
        UIHelper.SetVisible(self.WidgetLaiZi , bVisible)
    end
end

function UIDdzPokerCard:ShowCardCount(nCardStats)
    UIHelper.SetString(self.TextCardStats , nCardStats)
    if nCardStats == 0 then
        UIHelper.SetOpacity(self.ImgCard, USE_ALPHA)
        UIHelper.SetOpacity(self.TextCardStats, USE_ALPHA)
    else
        UIHelper.SetOpacity(self.ImgCard, NORMAL_ALPHA)
        UIHelper.SetOpacity(self.TextCardStats, NORMAL_ALPHA)
    end
end
-- 显示卡牌信息
-- tbCardInfo = 
-- {
--     tCard = {state , color , number},
--     bIsDizhu = false,
--     bIsMingPai = false,
--     bIsHosting = false,
-- }
function UIDdzPokerCard:ShowHandCard(tbCardInfo)
    if tbCardInfo.tbCards == nil then
        return
    end
    self.tCard = tbCardInfo.tbCards
    UIHelper.SetVisible(self.ImgDiZhu , tbCardInfo.bIsDizhu)
    UIHelper.SetVisible(self.ImgDiZhu_up , tbCardInfo.bIsDizhu)
    UIHelper.SetVisible(self.ImgShown , tbCardInfo.bIsMingPai)
    UIHelper.SetVisible(self.ImgShown_up , tbCardInfo.bIsMingPai)
    UIHelper.SetVisible(self.ImgCardShade , tbCardInfo.bIsHosting)
    UIHelper.SetVisible(self.WidgetHandcardUp , false)
    local szIconPath = DdzPokerData.GetCardIconPath(self.tCard)
    UIHelper.SetSpriteFrame(self.ImgHandcard, szIconPath)
    UIHelper.SetSpriteFrame(self.ImgHandcard_up, szIconPath)
    UIHelper.SetVisible(self.ImgHandcard , true)
end 

function UIDdzPokerCard:ShowPassedCard(tbCardInfo)
    local tbCards = tbCardInfo.tbCards
    UIHelper.SetVisible(self.ImgDiZhu , tbCardInfo.bIsDizhu)
    UIHelper.SetVisible(self.ImgShown , tbCardInfo.bIsMingPai)
    UIHelper.SetVisible(self.ImgCardShade , tbCardInfo.bIsHosting)
    UIHelper.SetVisible(self.WidgetHandcardUp , false)
    local szIconPath = DdzPokerData.GetCardIconPath(tbCards)
    UIHelper.SetSpriteFrame(self.ImgHandcard, szIconPath)
end 

function UIDdzPokerCard:ShowCardBack(szIconPath)
    UIHelper.SetSpriteFrame(self.ImgHandcard, szIconPath)
end

function UIDdzPokerCard:ShowDiCard(tCard)
    local nNum = tCard[3]
    local nColor = tCard[2]
    local szColorSymbol = ""
    if not DdzPokerData.IsJoker(nNum) then
        szColorSymbol = tbColorMap[nColor]
    end
    local szSkin = DdzPokerData.GetCardSkin()
    UIHelper.SetSpriteFrame(self.ImgNoRemain,  string.format("UIAtlas2_Ddz_PokerCounter%s_Gray"..szColorSymbol..DdzPokerData.tbPokerNumAtlasSymbol[nNum], szSkin))
    UIHelper.SetSpriteFrame(self.ImgRemain, string.format("UIAtlas2_Ddz_PokerCounter%s_Counter"..szColorSymbol..DdzPokerData.tbPokerNumAtlasSymbol[nNum], szSkin))
end


function UIDdzPokerCard:SetVisible(bVisible)
    UIHelper.SetVisible(self._rootNode, bVisible)
end

function UIDdzPokerCard:GetVisible()
    return UIHelper.GetVisible(self._rootNode)
end

function UIDdzPokerCard:UpdateCardClick()
    UIHelper.SetVisible(self.WidgetHandcardUp , not self.bIsClicked)
    UIHelper.SetVisible(self.ImgHandcard , self.bIsClicked)
    if UIHelper.GetVisible(self.ImgCardShade) then
        UIHelper.SetVisible(self.ImgCardShade , self.bIsClicked)
    end
   
    self.bIsClicked = not self.bIsClicked
    SoundMgr.PlaySound(SOUND.UI_SOUND , DdzPokerData.GetSoundPath("szChooseCard"))
end


function UIDdzPokerCard:InitLaiziCard(eState)
    UIHelper.SetVisible(self.ImgLaiziTagTian , eState == DdzPokerData.LaiZiState.Tian)
    UIHelper.SetVisible(self.ImgLaiziTagDi , eState == DdzPokerData.LaiZiState.Di)
    UIHelper.SetVisible(self.ImgLaiziTagSIngle , eState == DdzPokerData.LaiZiState.Single)

    local tCards = DdzPokerData.DataModel.tDiLaiZi.tUIData
    if eState == DdzPokerData.LaiZiState.Tian then
		tCards = DdzPokerData.DataModel.tTianLaiZi.tUIData
	end
    local szIconPath = DdzPokerData.GetCardIconPath(tCards , true)
    UIHelper.SetSpriteFrame(self.ImgLaizicard, szIconPath)
end

return UIDdzPokerCard