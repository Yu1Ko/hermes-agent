require("Lua/Debug/GM/ServerRobotControl/ServerRobotArena.lua")
require("Lua/Debug/GM/ServerRobotControl/ServerRobotBuffSetting.lua")
require("Lua/Debug/GM/ServerRobotControl/ServerRobotCampInfo.lua")
require("Lua/Debug/GM/ServerRobotControl/ServerRobotFightSettings.lua")
require("Lua/Debug/GM/ServerRobotControl/ServerRobotTeamManager.lua")
require("Lua/Debug/GM/ServerRobotControl/ServerRobotGangManager.lua")
require("Lua/Debug/GM/ServerRobotControl/ServerRobotAIChat.lua")

if not SearchRobot then
    SearchRobot = {
        className = "SearchRobot",
        text = '服务端机器人',
        szRobotIndex = "",
        szRobotCount = "",
        szRobotSuffixName = "",
        szLabelTextTip = "",
        szControlMode = "指定机器人",
        nChannel = PLAYER_TALK_CHANNEL.WHISPER,
        tbRobot = {}
    }
end



function SearchRobot:FillAll()
end

-- 重开GM 显示子面板操作
function SearchRobot:ShowSubWindow(tbGMView)
    tbGMView.PanelRightView:setVisible(false)
    if not UIMgr.GetView(VIEW_ID.PanelRobotItem) then
        UIMgr.Open(VIEW_ID.PanelRobotItem, SearchRobot)
    end
end

-- 私聊指定机器人接口
function SearchRobot:WhisperToRobot(szName, szMsg)
    local szReciver = UIHelper.UTF8ToGBK(szName)
    local tbMsg = {{type = "text", text = szMsg}}
    ChatData.Send(PLAYER_TALK_CHANNEL.WHISPER, szReciver, tbMsg)
end

-- 合并聊天接口逻辑
function SearchRobot:SendCustomMessage(szMsg, nDelayTime)
    local tbMsg = {{type = "text", text = szMsg}}
    if self.nChannel == PLAYER_TALK_CHANNEL.WHISPER then
        for index, szName in ipairs(SearchRobot.tbRobot) do
            Timer.AddFrame(SearchRobot, index*nDelayTime, function ()
                SearchRobot:WhisperToRobot(szName, szMsg)
            end)
        end
    else
        local player = GetClientPlayer()
        Player_Talk(player, self.nChannel, "", tbMsg)
    end
end

-- 指令均分的聊天方式
function SearchRobot:SendCustomMessageAvg(tCustomMessage1,tCustomMessage2,nDelayTime)
    if self.nChannel == PLAYER_TALK_CHANNEL.WHISPER then
        -- 这里要均分聊天对象
        local nRobotNum = #SearchRobot.tbRobot
        for index, szName in ipairs(SearchRobot.tbRobot) do
            if index <= math.modf((nRobotNum-1)/2) then
                Timer.AddFrame(SearchRobot, index*nDelayTime, function ()
                    SearchRobot:WhisperToRobot(szName, tCustomMessage1)
                end)
            else
                Timer.AddFrame(SearchRobot, index*nDelayTime, function ()
                    SearchRobot:WhisperToRobot(szName, tCustomMessage2)
                end)
            end
        end
    else
        local player = GetClientPlayer()
        if player.CanUseNewChatSystem(self.nChannel) then
			player.PushChat(self.nChannel, "",0, 0, 0, 0, true, tCustomMessage1)
		end
        Player_Talk(player, self.nChannel, "", tCustomMessage1)
    end

end

function SearchRobot:OnClick(tbGMView)
    SearchRobot:ShowSubWindow(tbGMView)
    tbGMView.tbGMPanelRight = SearchRobot
end

function SearchRobot:BtnOperate(tbData)
end

function SearchRobot:BtnExecute(tbGMView)
end

function SearchRobot:GetAllData(tbGMView)
end