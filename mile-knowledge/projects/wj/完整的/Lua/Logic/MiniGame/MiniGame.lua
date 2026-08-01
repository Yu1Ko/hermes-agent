MiniGame = MiniGame or {}
local self = MiniGame

function MiniGame.SetDebugMode(bEnable)
    MiniGame.bDebugMode = bEnable
end

--小游戏开始
function MiniGame.Start(tInfo)
    Event.Dispatch(EventType.OnMiniGameStart, tInfo)
end

--显示小游戏指引（操作说明）
function MiniGame.OpenGuide(dwGameID)

    Event.Dispatch(EventType.OnMiniGameOpenGuide, dwGameID)
end

--关闭小游戏指引
function MiniGame.CloseGuide()
    Event.Dispatch(EventType.OnMiniGameCloseGuide)
end

--小游戏结算
function MiniGame.OpenResult(tInfo)
    UIMgr.OpenSingleWithOnEnter(false, VIEW_ID.PanelMapGameSettlement, tInfo)
end

--关闭小游戏结算
function MiniGame.CloseResult()
    UIMgr.Close(VIEW_ID.PanelMapGameSettlement)
end

--打开关卡选择
function MiniGame.OpenSelectLevel(tInfo)
    UIMgr.Open(VIEW_ID.PanelLevelSelect, tInfo)
end

--打开拼图
function MiniGame.OpenJigsaw(tInfo)
    UIMgr.OpenSingle(true, VIEW_ID.PanelPuzzleGame, tInfo)
end

--刷新拼图
function MiniGame.UpdateJigsaw(tInfo)
    -- MiniGameJigsaw.Update(tInfo)
    Event.Dispatch(EventType.OnMiniGameUpdateJigsaw, tInfo)
end

function MiniGame.CloseJigsaw()
    UIMgr.Close(VIEW_ID.PanelPuzzleGame)
end

--打开诗歌
function MiniGame.OpenPoetry(tInfo)
    UIMgr.OpenSingle(true, VIEW_ID.PanelPoetry, tInfo)
end

--关闭诗歌
function MiniGame.ClosePoetry()
    UIMgr.CloseImmediately(VIEW_ID.PanelPoetry)
end
