-- ---------------------------------------------------------------------------------
-- Author: Unknown
-- Name: UIInteractActivityPopView
-- Date: 2023-02-15 17:23:56
-- Desc: ?
-- ---------------------------------------------------------------------------------

local UIInteractActivityPopView = class("UIInteractActivityPopView")

local LIST_MAX_NUM 				= 4

function UIInteractActivityPopView:OnEnter(szName,nRelationType,dwPlayerID,tbPlayerInfo,MiniAvatarID)
    if not self.bInit then
        self:RegEvent()
        self:BindUIEvent()
        self.bInit = true
    end
    self.szName = szName
    self.nRelationType = nRelationType  -- 7
    self.dwPlayerID = dwPlayerID
    self.tbPlayerInfo = tbPlayerInfo
    self.MiniAvatarID = MiniAvatarID
    RemoteCallToServer("OnGetMentorActivity", dwPlayerID)
    self:UpdateInfo()
end

function UIInteractActivityPopView:OnExit()
    self.bInit = false
    self:UnRegEvent()
end

function UIInteractActivityPopView:BindUIEvent()
    UIHelper.BindUIEvent(self.BtnClose,EventType.OnClick,function ()
        UIMgr.Close(self)
    end)
end

function UIInteractActivityPopView:RegEvent()
    --Event.Reg(self, EventType.XXX, func)
    Event.Reg(self,EventType.MentorActivityDetail,function ()
        UIMgr.Close(self)
        UIMgr.Close(VIEW_ID.PanelStudentInteraction)
    end)
    Event.Reg(self,"ON_GET_MENTOR_ACTIVITY",function (arg0,arg1)
        if arg0 == self.dwPlayerID then
            self:UpdateTack(arg1)
        end
    end)
    Event.Reg(self, EventType.OnClientPlayerEnter, function()
        UIMgr.Close(self)
    end)
end

function UIInteractActivityPopView:UnRegEvent()
    --Event.UnReg(self, EventType.XXX)
end






-- ----------------------------------------------------------
-- Please write your own code below  ↓↓↓
-- ----------------------------------------------------------


function UIInteractActivityPopView:UpdateInfo()
    local szStatus = ""
    if self.nRelationType == FellowshipData.tbRelationType.nMaster then
		szStatus = g_tStrings.STR_MENTORMESSAGE_MENTOR
	elseif self.nRelationType == FellowshipData.tbRelationType.nApprentice then
		szStatus = g_tStrings.STR_MENTORMESSAGE_APPRENTICE
	elseif self.nRelationType == FellowshipData.tbRelationType.nSameApp then
		szStatus = g_tStrings.STR_MENTORMESSAGE_MENTOR_APPRENTICE
	end
    UIHelper.SetString(self.LabelDescribe,"你和"..szStatus.." "..self.szName.." 拥有共同参与的活动，何不携手共闯江湖呢？")
end

function UIInteractActivityPopView:UpdateTack(tActivityList)
    if not tActivityList then
		return
	end

    UIHelper.RemoveAllChildren(self.ScrollView)
    local nCount = 0
	for k, v in pairs(tActivityList) do
		local tInfo = Table_GetCalenderActivity(v)
		if tInfo then
			nCount = nCount + 1
			UIHelper.AddPrefab(PREFAB_ID.WidgetInteractActivity,self.ScrollView,v,tInfo.szName,MentorActivityImg[v],tInfo.nStar,self.nRelationType,self.szName, self.tbPlayerInfo,self.MiniAvatarID)
		end
		if nCount >= LIST_MAX_NUM then
			break
		end
	end

    UIHelper.ScrollViewDoLayout(self.ScrollView)
    UIHelper.ScrollToTop(self.ScrollView,0)
end

return UIInteractActivityPopView