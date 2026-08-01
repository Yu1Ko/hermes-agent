-- ---------------------------------------------------------------------------------
-- Name: UIPanelElectionForeman
-- Prefab: PanelCampaignCommand
-- Desc: 阵营 - 指挥竞选 - 头像点击 - 团长战绩
-- DX:ui\Config\Default\CommandDataPanel.lua
-- ---------------------------------------------------------------------------------
local UIPanelElectionForeman = class("UIPanelElectionForeman")

function UIPanelElectionForeman:OnEnter(dwID, szName)
    if not self.bInit then
        self:BindUIEvent()
        self:RegEvent()
        self.bInit = true
    end
    self:UpdateData(dwID, szName)
end

function UIPanelElectionForeman:OnExit()
    self.bInit = false
end

function UIPanelElectionForeman:BindUIEvent()
    UIHelper.BindUIEvent(self.BtnClose, EventType.OnClick, function()
        UIMgr.Close(self)
    end)
end

function UIPanelElectionForeman:RegEvent()
    Event.Reg(self, "ON_CAMP_PLANT_APPLY_EXPLOIT_RESPOND", function()
        self:UpdatePage()
    end)
end

function UIPanelElectionForeman:UpdateData(dwID, szName)
    local CP = GetCampPlantManager()
	CP.ApplyExploit(dwID)
    self.dwID = dwID
    
    local tDataList = Table_GetCmdHistoryData()
    self.tShowList = {}
    local hPlayer = GetClientPlayer()
	for _, v in pairs(tDataList) do
		if v.dwID == 1 or
           v.dwID == 2 or
           ((v.nCamp == 0 or v.nCamp == hPlayer.nCamp) and v.dwID ~= 1 and v.dwID ~= 2) then 
            table.insert(self.tShowList, v)
		end
	end

    UIHelper.SetString(self.LabelTitle, UIHelper.GBKToUTF8(szName))
end

function UIPanelElectionForeman:UpdatePage()
    local hPlayer = GetClientPlayer()
	local CP = GetCampPlantManager()

    local Id2Img = {
        [3] = "UIAtlas2_Pvp_PVPCampaign_Img_5",
        [4] = "UIAtlas2_Pvp_PVPCampaign_Img_4",
        [5] = "UIAtlas2_Pvp_PVPCampaign_Img_4",
        [6] = "UIAtlas2_Pvp_PVPCampaign_Img_3",
        [7] = "UIAtlas2_Pvp_PVPCampaign_Img_5",
        [8] = "UIAtlas2_Pvp_PVPCampaign_Img_4",
        [9] = "UIAtlas2_Pvp_PVPCampaign_Img_1",
        [10] = "UIAtlas2_Pvp_PVPCampaign_Img_2",
        [11] = "UIAtlas2_Pvp_PVPCampaign_Img_2",
    }
	for _, v in pairs(self.tShowList) do
        local nValue = CP.GetExploit(self.dwID, v.dwIndex)
		if v.dwID == 1 then 
            UIHelper.SetString(self.LabelCommandNum1, UIHelper.GBKToUTF8(nValue))
        elseif v.dwID == 2 then
            UIHelper.SetString(self.LabelCommandNum2, UIHelper.GBKToUTF8(nValue))
        else
            local tInfo = {}
            tInfo.szName = UIHelper.GBKToUTF8(v.szName)
            tInfo.nValue = nValue
            tInfo.Img = Id2Img[v.dwID]
            tInfo.szTips = UIHelper.GBKToUTF8(v.szTips)
            UIHelper.AddPrefab(PREFAB_ID.WidgetCommandNum, self.LayoutCommand, tInfo)
		end
	end
    UIHelper.LayoutDoLayout(self.LayoutCommand)
end

return UIPanelElectionForeman