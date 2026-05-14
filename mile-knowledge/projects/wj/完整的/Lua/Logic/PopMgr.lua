-- ---------------------------------------------------------------------------------
-- Author: huqing
-- Name: PopMgr
-- Date: 2024-10-31 10:53:30
-- Desc: 弹窗管理
-- ---------------------------------------------------------------------------------

PopMgr = PopMgr or {className = "PopMgr"}
local self = PopMgr


function PopMgr.Init()
    Event.Reg(self, "LOADING_END", function()
		PopMgr.Pop_130Level()
    end)

end

function PopMgr.UnInit()

end

function PopMgr.Pop_130Level()
    local bQuestFlag = QuestData.IsUnAccept(27251)
    local bLevelFlag = PlayerData.GetPlayerLevel() == 120

    if bQuestFlag and bLevelFlag then
        if not APIHelper.IsDid("Pop_130Level") then
            local script = UIMgr.OpenSingle(false, VIEW_ID.PanelNewLevelMap)
            if script then
                UIHelper.BindUIEvent(script.BtnClick, EventType.OnClick, function()
                    UIMgr.Close(script)
                    UIMgr.Open(VIEW_ID.PanelSwordMemories)
                end)
            end
            APIHelper.Do("Pop_130Level")
        end
    end
end

