-- ---------------------------------------------------------------------------------
-- Author: Unknown
-- Name: UIAdventurePop
-- Date: 2023-05-09 14:30:17
-- Desc: ?
-- ---------------------------------------------------------------------------------

local UIAdventurePop = class("UIAdventurePop")

local m_tHideViews = {
    VIEW_ID.PanelHintTop,
    VIEW_ID.PanelPlotDialogue,
    VIEW_ID.PanelLuckyMeetingDialogue,
}

function UIAdventurePop:OnEnter(nAdvID, bFinish)
    if not self.bInit then
        self:RegEvent()
        self:BindUIEvent()
        self.bInit = true
    end
    self.nAdvID = nAdvID
    self.bFinish = bFinish
    self:UpdateInfo()

    self.scriptShare = UIHelper.GetBindScript(self.WidgetShare)
    self.scriptShare:OnEnter(nil, true)

    self.scriptShare:SetPrepareCaptureCallback(function()
        UIMgr.HideLayer(UILayer.Main)
        for _, nViewID in ipairs(m_tHideViews) do
            local view = UIMgr.GetView(nViewID)
            local node = view and view.node
            if node then
                node:setVisible(false)
            end
        end
    end)

    self.scriptShare:SetCloseCaptureCallback(function()
        UIMgr.ShowLayer(UILayer.Main)
        for _, nViewID in ipairs(m_tHideViews) do
            local view = UIMgr.GetView(nViewID)
            local node = view and view.node
            if node then
                node:setVisible(true)
            end
        end
    end)

    self.scriptDrag = UIHelper.GetBindScript(self.WidgetQiYuPop)
    UIHelper.BindFreeDrag(self.scriptDrag, self.BtnMove)

    Timer.AddCycle(self, 0.1, function()
        if self.scriptDrag.bDragging then
            UIHelper.SetVisible(self.ImgBubbleMove, false)
        end
    end)
end

function UIAdventurePop:OnExit()
    self.bInit = false
    self:UnRegEvent()
end

function UIAdventurePop:BindUIEvent()
    UIHelper.BindUIEvent(self.BtnClose, EventType.OnClick, function ()
        UIMgr.Close(self)
        -- 关界面刷新一下气泡
        if AdventureData.dwAdvID and AdventureData.dwAdvID == self.nAdvID then
            AdventureData.UpdateTaskMsg()
            Event.Dispatch("OpenAdventure")
        end
    end)
end

function UIAdventurePop:RegEvent()
    Event.Reg(self, EventType.OnWindowsSizeChanged, function()
        UIHelper.UpdateNodeInsideScreen(self.WidgetQiYuPop)
    end)
end

function UIAdventurePop:UnRegEvent()
    --Event.UnReg(self, EventType.XXX)
end

-- ----------------------------------------------------------
-- Please write your own code below  ↓↓↓
-- ----------------------------------------------------------

function UIAdventurePop:UpdateInfo()
    local nSchool = g_pClientPlayer.dwForceID
    local nCamp = g_pClientPlayer.nCamp
    local tAdvList = Table_GetAdventure()
    for k, v in pairs(tAdvList) do
        if v.dwID == self.nAdvID then
			local szType = v.szRewardType
			local szPath = v.szOpenRewardPath
            if szType ~= "" then
                local bHasSlash = string.sub(szPath, -1) == "/" or string.sub(szPath, -1) == "\\"
                if not bHasSlash then
                    szPath = szPath .. "/"
                end
            end
			if szType == "school" then
				szPath = szPath .. szType .. "_" .. nSchool .. "_Open" .. ".tga"
			elseif szType == "camp" then
				szPath = szPath .. szType .. "_" .. nCamp .. "_Open" .. ".tga"
			end
            szPath = string.gsub(szPath, "ui\\Image", "Resource/Adventure")
            szPath = string.gsub(szPath, "ui/Image", "Resource/Adventure")
            szPath = string.gsub(szPath, ".tga", ".png")
            UIHelper.SetTexture(self.ImgPop, szPath, false)
            UIHelper.SetTexture(self.ImgPopName, v.szMobileOpenNamePath, false)
			break
		end
    end
end

return UIAdventurePop