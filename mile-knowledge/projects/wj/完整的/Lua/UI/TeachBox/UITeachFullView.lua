-- ---------------------------------------------------------------------------------
-- Author: Unknown
-- Name: UITeachFullView
-- Date: 2024-07-11 17:48:40
-- Desc: ?
-- ---------------------------------------------------------------------------------

local UITeachFullView = class("UITeachFullView")

function UITeachFullView:OnEnter(bImg, szFileName)
	self.bImg = bImg
	self.szFileName = szFileName
	if not self.bInit then
		self:RegEvent()
		self:BindUIEvent()
		self.bInit = true
	end
	self:UpdateInfo()
end

function UITeachFullView:OnExit()
	self.bInit = false
	self:UnRegEvent()
end

function UITeachFullView:BindUIEvent()
	
end

function UITeachFullView:RegEvent()
	--Event.Reg(self, EventType.XXX, func)
end

function UITeachFullView:UnRegEvent()
	--Event.UnReg(self, EventType.XXX)
end






-- ----------------------------------------------------------
-- Please write your own code below  ↓↓↓
-- ----------------------------------------------------------

function UITeachFullView:UpdateInfo()
	Timer.AddFrame(self, 1, function ()
		if self.bImg then
			UIHelper.SetVisible(self.VideoPlayerTutorial, false)
			UIHelper.SetTexture(self.ImgTutorial, self.szFileName)
			UIHelper.SetVisible(self.ImgTutorial, true)
		else
			UIHelper.SetVisible(self.ImgTutorial, false)
			UIHelper.SetVisible(self.VideoPlayerTutorial, true)
			UIHelper.PlayVideo(self.VideoPlayerTutorial, self.szFileName, true, function(nVideoPlayerEvent, szMsg)
				if nVideoPlayerEvent == ccui.VideoPlayerEvent.COMPLETED then
				elseif nVideoPlayerEvent == ccui.VideoPlayerEvent.ERROR then
					TipsHelper.ShowNormalTip("视频播放错误："..tostring(szMsg))
				end
			end)
		end
	end)

end


return UITeachFullView