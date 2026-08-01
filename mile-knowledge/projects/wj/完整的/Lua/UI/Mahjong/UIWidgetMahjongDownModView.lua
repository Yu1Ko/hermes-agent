-- ---------------------------------------------------------------------------------
-- Author: Unknown
-- Name: UIWidgetMahjongDownModView
-- Date: 2023-08-01 17:13:23
-- Desc: ?
-- ---------------------------------------------------------------------------------

local UIWidgetMahjongDownModView = class("UIWidgetMahjongDownModView")

function UIWidgetMahjongDownModView:OnEnter(tbCardInfo)
    if not self.bInit then
        self:RegEvent()
        self:BindUIEvent()
        self.bInit = true
        self.nBasePositionY = UIHelper.GetPositionY(self._rootNode)
    end
    self.tbCardInfo = tbCardInfo
    self:UpdateInfo()
end

function UIWidgetMahjongDownModView:OnExit()
    self.bInit = false
    self:UnRegEvent()
end

function UIWidgetMahjongDownModView:BindUIEvent()
    UIHelper.BindUIEvent(self.ButtonMahjongDownMod, EventType.OnClick, function()

        if MahjongData.GetGameData("bSwapCard") == true then --换牌
            local nPositionY = UIHelper.GetPositionY(self._rootNode)
            if nPositionY == self.nBasePositionY then
                if MahjongData.AddSwapCardInfo(self.tbCardInfo) then self:CardUp() end
            else
                self:CardDown()
                MahjongData.RemoveSwapCardInfo(self.tbCardInfo)
            end

        elseif MahjongData.CanDisCard()  then --出牌
            local nPositionY = UIHelper.GetPositionY(self._rootNode)
            if nPositionY ~= self.nBasePositionY then
                local nValue = MahjongData.CardCardInfoTo16(self.tbCardInfo)
                MahjongData.SendServerOperate(MINI_GAME_OPERATE_TYPE.SERVER_OPERATE, PLAYER_OPERATE_CS_SEND, nValue)
            end
            Event.Dispatch(EventType.OnSelectMyHandCard, nPositionY ~= self.nBasePositionY, self.tbCardInfo, self)
        end
    end)
end

function UIWidgetMahjongDownModView:RegEvent()
    --Event.Reg(self, EventType.XXX, func)
    Event.Reg(self, EventType.OnSelectMyHandCard, function(bOut, tbCardInfo, script)
        if not bOut then--选中一张牌时
            if tbCardInfo ~= self.tbCardInfo then
                self:CardDown()
            else
                self:CardUp()
            end
        end
    end)
end

function UIWidgetMahjongDownModView:UnRegEvent()
    --Event.UnReg(self, EventType.XXX)
end

function UIWidgetMahjongDownModView:CardUp()
    local nX, nY = self._rootNode:getPosition()
    MahjongAnimHelper.MoveNode(self._rootNode, {x = nX, y = nY}, {x = nX, y = nY + 20}, 0.2)
end

function UIWidgetMahjongDownModView:CardDown()
    UIHelper.SetPositionY(self._rootNode, self.nBasePositionY)
end

function UIWidgetMahjongDownModView:GetCardInfo()
    return self.tbCardInfo
end



-- ----------------------------------------------------------
-- Please write your own code below  ↓↓↓
-- ----------------------------------------------------------

function UIWidgetMahjongDownModView:UpdateInfo()
    local tbImage = MahjongData.GetMahjongTileInfo("Down1", self.tbCardInfo.nType, self.tbCardInfo.nNumber)
    local szImagePath = MahjongData.GetCardImg(tbImage.szIconPath, tbImage.nIconFrame)

    if szImagePath ~= "" then
        UIHelper.SetSpriteFrame(self.ImgMahjongDownMod, szImagePath)
        UIHelper.SetSpriteFrame(self.ImgMahjongDownOverMod, szImagePath)
    end

    --更新置灰
    local nOwnDirection = MahjongData.GetPlayerDataDirection()
    local tbMyWins = MahjongData.GetPlayerWinsCardInfoByDirection(nOwnDirection)
    local bShade = (#tbMyWins > 0) or (MahjongData.GetGameData("nOwnLackType") == self.tbCardInfo.nType) or MahjongData.GetPlayerCardInfo("nGrade", nOwnDirection) <= 0
    UIHelper.SetVisible(self.ImgMahjongDownShadeMod, bShade)

    UIHelper.SetVisible(self._rootNode, true)
    UIHelper.SetOpacity(self._rootNode, 255)

    self:CardDown()
end

return UIWidgetMahjongDownModView