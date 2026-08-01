-- ---------------------------------------------------------------------------------
-- Author: zeng zi peng
-- Name: UIConveneInteractionCell
-- Date: 2023-12-01 11:37:02
-- Desc: 召请子列表节点
-- ---------------------------------------------------------------------------------

local UIConveneInteractionCell = class("UIConveneInteractionCell")

function UIConveneInteractionCell:OnEnter(nIndex , tbEvkeInfo , selectCallback , bFriend)
    self.nIndex = nIndex
    self.tbEvkeInfo = tbEvkeInfo
    self.selectCallback = selectCallback
    self.bFriend = bFriend
    if not self.bInit then
        self:RegEvent()
        self:BindUIEvent()
        self.bInit = true
    end
    self:UpdateInfo()
end

function UIConveneInteractionCell:OnExit()
    self.bInit = false
    self:UnRegEvent()
end

function UIConveneInteractionCell:BindUIEvent()
    UIHelper.BindUIEvent(self.WidgetConvenePlayerTog , EventType.OnClick , function ()
        self.bSelect = not self.bSelect
        UIHelper.SetVisible(self.WidgetSelect , self.bSelect)
        UIHelper.SetVisible(self.WidgetMessage , not self.bSelect)
        if self.selectCallback then
            self.selectCallback(self.nIndex, self , self.bSelect)
        end
    end)
end

function UIConveneInteractionCell:RegEvent()
    --Event.Reg(self, EventType.XXX, func)
end

function UIConveneInteractionCell:UnRegEvent()
    --Event.UnReg(self, EventType.XXX)
end





-- ----------------------------------------------------------
-- Please write your own code below  ↓↓↓
-- ----------------------------------------------------------

function UIConveneInteractionCell:UpdateInfo()
    UIHelper.SetString(self.LabelLevel , FormatString(g_tStrings.STR_FRIEND_WTHAT_LEVEL, self.tbEvkeInfo.nLevel))
    UIHelper.SetString(self.LabelPlayerName , UIHelper.GBKToUTF8(self.tbEvkeInfo.szName))
    PlayerData.SetSchoolImg(self.ImgSect, self.tbEvkeInfo)

    UIHelper.SetString(self.LabelLevel_Select , FormatString(g_tStrings.STR_FRIEND_WTHAT_LEVEL, self.tbEvkeInfo.nLevel))
    UIHelper.SetString(self.LabelPlayerName_Select , UIHelper.GBKToUTF8(self.tbEvkeInfo.szName))
    PlayerData.SetSchoolImg(self.ImgSect_Select, self.tbEvkeInfo)

    UIHelper.SetVisible(self.WidgetMessage , not self.bSelect)
    UIHelper.SetVisible(self.WidgetSelect , self.bSelect)
    UIHelper.SetVisible(self.WidgetImgStar , self.bFriend)

    local nLevel, fP = self:GetAttractionLevel(self.tbEvkeInfo.nAttraction)
    for k, v in pairs(self.tbStar) do
        UIHelper.SetVisible(v , k <= nLevel)
        if k == nLevel then
            UIHelper.SetProgressBarPercent(v,fP*100)
        else
            UIHelper.SetProgressBarPercent(v,100)
        end
    end
end

function UIConveneInteractionCell:CancelSelect()
    UIHelper.SetSelected(self.WidgetConvenePlayerTog , false)
end

function UIConveneInteractionCell:GetData()
    return self.tbEvkeInfo
end

function UIConveneInteractionCell:GetAttractionLevel(attraction)
	local nLevel, fP = 1, 0
	if attraction <= 100 then
		nLevel, fP = 1, math.max(attraction / 100, 0)
	elseif attraction <= 200 then
		nLevel, fP = 2, (attraction - 100) / 100
	elseif attraction <= 300 then
		nLevel, fP = 3, (attraction - 200) / 100
	elseif attraction <= 500 then
		nLevel, fP = 4, (attraction - 300) / 200
	elseif attraction <= 800 then
		nLevel, fP = 5, (attraction - 500) / 300
	else
		nLevel, fP = 6, math.min(1, (attraction - 800) / 200)
	end
	return nLevel, fP
end


return UIConveneInteractionCell