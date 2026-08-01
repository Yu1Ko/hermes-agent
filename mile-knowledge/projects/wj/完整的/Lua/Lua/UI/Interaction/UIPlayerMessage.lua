-- ---------------------------------------------------------------------------------
-- Author: Unknown
-- Name: UIPlayerMessage
-- Date: 2023-02-08 16:50:44
-- Desc: ?
-- ---------------------------------------------------------------------------------

local UIPlayerMessage = class("UIPlayerMessage")

local GOOD_MENTOR = 1

function UIPlayerMessage:OnEnter(nIndex,bMentor,v)
    if not self.bInit then
        self:RegEvent()
        self:BindUIEvent()
        self.bInit = true
    end
    self.nIndex  = nIndex
    self.bMentor = bMentor
    self:UpdateInfo(v)
end

function UIPlayerMessage:OnExit()
    self.bInit = false
    self:UnRegEvent()
end

function UIPlayerMessage:BindUIEvent()
    UIHelper.BindUIEvent(self.TogPlayerMessage,EventType.OnSelectChanged,function (_,bSelect)
        if bSelect then
            Event.Dispatch(EventType.OnSelectedPlayerMessage,self.nIndex,self.bMentor)
        end
    end)
end

function UIPlayerMessage:RegEvent()
    --Event.Reg(self, EventType.XXX, func)
    Event.Reg(self, EventType.OnSelectChangedMentor, function (nIndex,bMentor)
        if self.nIndex == nIndex and self.bMentor == bMentor then
            UIHelper.SetSelected(self.TogPlayerMessage,true)
        end
    end)

    Event.Reg(self, "APPLY_SOCIAL_INFO_RESPOND", function(tPlayerID)
        for _, dwPlayerID in ipairs(tPlayerID) do
            if self.dwRoleID == dwPlayerID then
                self.tSocialInfo = FellowshipData.GetSocialInfo(dwPlayerID)
                if self.tSocialInfo then
                    local  labels = self.tSocialInfo.Praiseinfo or {}
                    local count = labels[GOOD_MENTOR] or 0
                    if count == 0 then
                        UIHelper.SetString(self.LableLevel2,"Lv.1")
                    else
                        UIHelper.SetString(self.LableLevel2,"Lv."..PersonLabel_GetLevel(count, GOOD_MENTOR))
                    end
                end
            end
        end
	end)
end

function UIPlayerMessage:UnRegEvent()
    --Event.UnReg(self, EventType.XXX)
end






-- ----------------------------------------------------------
-- Please write your own code below  ↓↓↓
-- ----------------------------------------------------------

function UIPlayerMessage:UpdateInfo(table)
    local headScript = UIHelper.AddPrefab(PREFAB_ID.WidgetHead,self.WidgetPlayerHead)
    if headScript then
        headScript:SetHeadInfo(nil,table.dwMiniAvatorID,table.dwRoleType,table.dwForceID)
    end
    UIHelper.SetString(self.LableName,UIHelper.GBKToUTF8(table.szName))
    UIHelper.SetSpriteFrame(self.Imglevel, PlayerForceID2SchoolImg2[table.dwForceID])
    UIHelper.SetString(self.LableLevel1,table.nLevel.."级")

    UIHelper.SetString(self.LableCamp1,g_tStrings.STR_CAMP_TITLE[table.nCamp])
    UIHelper.SetVisible(self.ImgCamp,table.nCamp == CAMP.EVIL)
    UIHelper.SetVisible(self.ImgCamp2,table.nCamp == CAMP.GOOD)

    local szComment = string.gsub(table.szComment, "\n", " ")
    szComment = string.gsub(szComment, "\r", " ")

    UIHelper.SetString(self.LableIntroduce,UIHelper.GBKToUTF8(szComment))

    self.dwRoleID = table.dwRoleID

    self.tSocialInfo = FellowshipData.GetSocialInfo(table.dwRoleID)
    if not self.tSocialInfo then
        GetSocialManagerClient().ApplySocialInfo({table.dwRoleID})
    else
        local  labels = self.tSocialInfo.Praiseinfo or {}
        local count = labels[GOOD_MENTOR] or 0
        if count == 0 then
            UIHelper.SetString(self.LableLevel2,"Lv.1")
        else
            UIHelper.SetString(self.LableLevel2,"Lv."..PersonLabel_GetLevel(count, GOOD_MENTOR))
        end
    end
end


return UIPlayerMessage