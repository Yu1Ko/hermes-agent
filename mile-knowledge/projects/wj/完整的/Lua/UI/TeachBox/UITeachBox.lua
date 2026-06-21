-- ---------------------------------------------------------------------------------
-- Author: liuyumin
-- Name: UITeachBox
-- Date: 2023-11-22 20:03:03
-- Desc: PanelTutorialCollection
-- ---------------------------------------------------------------------------------

local UITeachBox = class("UITeachBox")
local m_szAllDesc = "全部"
function UITeachBox:OnEnter()
	if not self.bInit then
		self:RegEvent()
		self:BindUIEvent()
		self.bInit = true
	end

	self.nImgIndex = 1
	self.nDescIndex = 1
	self.tbTeachList = {}
	self:UpdateInfo()

end

function UITeachBox:OnExit()
	self.bInit = false
	self:UnRegEvent()
	Event.Dispatch("OnUpdateTeachBoxRedPoint")
end

function UITeachBox:BindUIEvent()
	UIHelper.BindUIEvent(self.BtnClose, EventType.OnClick, function()
		UIMgr.Close(VIEW_ID.PanelTutorialCollection)
	end)

	UIHelper.BindUIEvent(self.BtnPrevious, EventType.OnClick, function()
		if self.nImgIndex > 1 then
			self.nImgIndex = self.nImgIndex - 1
			self:UpdateTeachDetailInfo()
			self:UpdatePageInfo()
		end
	end)

	UIHelper.BindUIEvent(self.BtnNext, EventType.OnClick, function()
		if self.nImgIndex < #TeachBoxData.tbImgList then
			self.nImgIndex = self.nImgIndex + 1
			self:UpdateTeachDetailInfo()
			self:UpdatePageInfo()
		end
	end)

	UIHelper.BindUIEvent(self.BtnClear, EventType.OnClick, function()
		UIHelper.SetText(self.EditKindSearch , "")
		self:UpdateSearchFiler()
    end)

	UIHelper.BindUIEvent(self.BtnGoto, EventType.OnClick, function()
		local teachConfig = UITeachBoxTab[self.nCurSelectTeachID]
		if not string.is_nil(teachConfig.szLink) then
			string.execute(teachConfig.szLink)
		end
    end)

	UIHelper.BindUIEvent(self.BtnService, EventType.OnClick, function()
		if Platform.IsWindows() or Platform.IsMac() then
			WebUrl.OpenByID(WEBURL_ID.WEB_CHATBOT_VK)
		else
			WebUrl.OpenByID(WEBURL_ID.WEB_CHATBOT_VK_MOBILE)
        end
    end)

	UIHelper.BindUIEvent(self.BtnFullScreen, EventType.OnClick, function()
		self:UpdateFullScreenInfo()
    end)
end

function UITeachBox:RegEvent()
	Event.Reg(self, "ON_CHANGETEACHTITLE", function(szName, nIndex)
		TeachBoxData.UpdateTeachInfo(nIndex)
		self.nImgIndex = 1

		self.nCurSelectTeachID = nIndex
		local teachConfig = UITeachBoxTab[nIndex]
		UIHelper.SetVisible(self.BtnGoto , (teachConfig.szLink and teachConfig.szLink ~= "") and true or false)

    end)

	Event.Reg(self, "ON_SHOWFIRSTTEACHINFO", function()
		self:UpdateTeachDetailInfo()
		self:UpdatePageInfo()
    end)

	Event.Reg(self, EventType.OnSearchTeachBox, function(szName)
		UIHelper.SetText(self.EditKindSearch , szName)
		self:UpdateSearchFiler()
	end)

	if Platform.IsWindows() or Platform.IsMac() then
        UIHelper.RegisterEditBoxEnded(self.EditKindSearch, function ()
            self:UpdateSearchFiler()
        end)
    else
        UIHelper.RegisterEditBoxReturn(self.EditKindSearch, function ()
            self:UpdateSearchFiler()
        end)
    end

	Event.Reg(self, EventType.OnWindowsSizeChanged, function()
		Timer.AddFrame(self, 1, function ()
			if not table.is_empty(TeachBoxData.tbDescList) then
				UIHelper.SetRichText(self.RichTextMessage, TeachBoxData.tbDescList[self.nImgIndex])
			end
		end)
    end)
end

function UITeachBox:UnRegEvent()
	Event.UnReg(self, "ON_CHANGETEACHTITLE")
end






-- ----------------------------------------------------------
-- Please write your own code below  ↓↓↓
-- ----------------------------------------------------------

function UITeachBox:UpdateInfo()
	self.szSearchFiler = ""
	RedpointHelper.TeachBox_ClearAll()
	self:UpdateLeftNavTabList()
end

function UITeachBox:UpdateTeachDetailInfo()
	UIHelper.SetRichText(self.RichTextMessage, TeachBoxData.tbDescList[self.nImgIndex])
	local szFileName = ""
	local tbPathInfo = {}
	for part in string.gmatch(TeachBoxData.tbImgList[self.nImgIndex], "[^%.]+") do
		table.insert(tbPathInfo, part)
	end
	UIHelper.SetVisible(self.ImgTutorial, false)
	UIHelper.SetVisible(self.VideoPlayerTutorial, false)
	if tbPathInfo[#tbPathInfo] == "png" then
		UIHelper.SetVisible(self.ImgTutorial, true)
		szFileName = string.format("Resource/%s", TeachBoxData.tbImgList[self.nImgIndex])
		UIHelper.SetTexture(self.ImgTutorial, szFileName)
	elseif tbPathInfo[#tbPathInfo] == "bk2" then
		UIHelper.SetVisible(self.VideoPlayerTutorial, true)
		szFileName = TeachBoxData.tbImgList[self.nImgIndex]
		self.VideoPlayerTutorial:setUserInputEnabled(false)  -- 禁止暂停
		UIHelper.SetVideoPlayerModel(self.VideoPlayerTutorial , VIDEOPLAYER_MODEL.BINK)
		szFileName = UIHelper.ParseVideoPlayerFile(szFileName , VIDEOPLAYER_MODEL.BINK)
		UIHelper.SetVideoLooping(self.VideoPlayerTutorial, true)
		if Platform.IsMobile() then
			szFileName = string.format(szFileName, "MOBILE")
		else
			szFileName = string.format(szFileName, "PC")
		end
		UIHelper.PlayVideo(self.VideoPlayerTutorial, szFileName, true, function(nVideoPlayerEvent, szMsg)
			if nVideoPlayerEvent == ccui.VideoPlayerEvent.COMPLETED then
			elseif nVideoPlayerEvent == ccui.VideoPlayerEvent.ERROR then
				TipsHelper.ShowNormalTip("视频播放错误："..tostring(szMsg))
			end
		end)
	end
	self.szFileName = szFileName
	UIHelper.ScrollViewDoLayoutAndToTop(self.ScrollViewDetail)
end

function UITeachBox:UpdatePageInfo()
	UIHelper.SetVisible(self.WidgetPaginate, #TeachBoxData.tbImgList ~= 1)
	UIHelper.SetString(self.LabelPage, string.format("%d/%d", self.nImgIndex, #TeachBoxData.tbImgList))
end

function UITeachBox:GetServiceScript()
	return UIHelper.GetBindScript(self.WidgetService)
end


function UITeachBox:UpdateSearchFiler()
	local szSearchFiler = UIHelper.GetText(self.EditKindSearch)
	if self.szSearchFiler ~= szSearchFiler then
		self.szSearchFiler = szSearchFiler
		self:UpdateLeftNavTabList()
		UIHelper.SetVisible(self.WidgetArrow, string.is_nil(szSearchFiler))
	end
end

function UITeachBox:UpdateLeftNavTabList()
	local tData = {}
	local bShowTitle = true
	for k, v in pairs(TeachBoxData.tbTeachBoxList) do
		local Info = {}
		bShowTitle = true
		if not string.is_nil(self.szSearchFiler) and v.szName ~= m_szAllDesc  then
			bShowTitle = false
		end
		if bShowTitle then
			Info.tArgs = {szName = v.szName, nChildCount = v.tbSub and table.get_len(v.tbSub) or 0}
			if v.tbSub and table.get_len(v.tbSub)  > 0 then
				Info.tItemList = {}
			end
			for Index, tbData in pairs(v.tbSub) do
				table.insert(Info.tItemList, {tArgs = {szName = tbData.szSubName, toggleGroup = self.ToggleGroup, bLast = Index == table.get_len(v.tbSub), funcCallBack = function(scriptSubNav, scriptContain, bSelect)
					if bSelect then
						if self.tbItemScript then
							UIHelper.SetSelected(self.tbItemScript.TogSubNav ,false)
						end
						self.tbItemScript = scriptSubNav
						UIHelper.SetSelected(self.tbItemScript.TogSubNav ,true)
						self:UpdateTeachInfo(tbData.tbContent)
					end
				end}})
			end

			Info.fnOnCickCallBack = function(bSelect, scriptContainer)
				if bSelect then
					local tbItemScripts =  scriptContainer:GetItemScript()
					if self.tbItemScript then
						UIHelper.SetSelected(self.tbItemScript.TogSubNav ,false)
					end
					if table.get_len(tbItemScripts) ~= 0 then
						self.tbItemScript = tbItemScripts[1]
						self.tbItemScript:OnSelectChanged(true)
						UIHelper.SetSelected(self.tbItemScript.TogSubNav ,true)
					else
						if v.szName == "全部" then
							self:UpdateTeachInfo(v.tbContent)
						end
					end
				end
			end
			table.insert(tData, Info)
		end
	end

	local func = function(scriptContainer, tArgs)
        UIHelper.SetString(scriptContainer.LabelNormalAll01, tArgs.szName)
        UIHelper.SetString(scriptContainer.LabelUpAll01, tArgs.szName)
		UIHelper.SetVisible(scriptContainer.WidgetSelecctImgTree, tArgs.nChildCount ~= 0)
        UIHelper.SetVisible(scriptContainer.ImgNormalIconTree, tArgs.nChildCount ~= 0)
        UIHelper.SetVisible(scriptContainer.WidgetSelecctImg, tArgs.nChildCount == 0)
        UIHelper.SetVisible(scriptContainer.ImgNormalIcon, tArgs.nChildCount == 0)
    end
	local scriptScrollViewTree = UIHelper.GetBindScript(self.WidgetAnchorLeft)
	scriptScrollViewTree:ClearContainer()
    UIHelper.SetupScrollViewTree(scriptScrollViewTree, PREFAB_ID.WidgetLeftNavTabList, PREFAB_ID.WidgetSubNav, func, tData)
	scriptScrollViewTree:SetScrollViewMovedCallback(function(eventType)
        if eventType == ccui.ScrollviewEventType.scrollToBottom then
            UIHelper.SetVisible(self.WidgetArrow, false)
        end
    end)
	local scriptContainer = scriptScrollViewTree.tContainerList[1].scriptContainer
	Timer.AddFrame(self, 1, function()
		scriptContainer.fnOnClickCallBack(true)
    end)
end

function UITeachBox:UpdateTeachInfo(tbContent)
	UIHelper.RemoveAllChildren(self.LayoutTaskTutorial)
	local tbScriptList = {}
	local bFiler = not string.is_nil(self.szSearchFiler)
	for k, v in pairs(tbContent) do
		local bAddChild = true
		if bFiler then
			local sourceDesc = v.szName..v.szDesc1..v.szDesc2..v.szDesc3..v.szDesc4..v.szGroupDesc
			bAddChild = string.find(sourceDesc, self.szSearchFiler) and true or false
		end
		if bAddChild then
			local Script = UIHelper.AddPrefab(PREFAB_ID.WidgetTutorialToggle, self.LayoutTaskTutorial, v.szName, v.nID)
			table.insert(tbScriptList, Script)
		end
	end
	UIHelper.SetVisible(self.WidgetSearchTitle , bFiler)
	UIHelper.LayoutDoLayout(self.LayoutTaskTutorial)
	UIHelper.ScrollViewDoLayoutAndToTop(self.ScrollViewTutorial)
	UIHelper.SetSelected(tbScriptList[1].ToggleTutorial, true)
end

function UITeachBox:UpdateFullScreenInfo()
	local bImg = UIHelper.GetVisible(self.ImgTutorial)
	if self.szFileName ~= "" then
		UIMgr.Open(VIEW_ID.PanelTutorialFullscreenPic, bImg, self.szFileName)
	end
end

return UITeachBox