TaskRead = {
    tbTask = {},
    tbTargetPointTable = {},
    tbCustom = {},
    tbCoordinate = {},
    tbTaskState = {},
    nTaskStateLine = 1,
    nTaskMove = false,
    szBtnCmd = nil,
    nSleeTime = 0,
    szKeyGM = nil,
    nTaskLine = 2,
}

-- 读取任务ID对应的文件
function TaskRead.GetTaskID(nQuestID)
    TaskRead.tbTask = {}
    local path = SearchPanel.szCurrentInterfacePath .."/TaskProcess/".. tostring(nQuestID) .. ".tab"
    for line in io.lines(path) do
        if line:find("%[") then
            table.insert(TaskRead.tbTask, TaskRead.tbTargetPointTable)
            TaskRead.tbTargetPointTable = {}
        else
            local tData = SearchPanel.StringSplit(line, " ")
            table.insert(TaskRead.tbTargetPointTable, tData)
        end
    end
    -- 防止最后一段未插入
    if #TaskRead.tbTargetPointTable > 0 then
        table.insert(TaskRead.tbTask, TaskRead.tbTargetPointTable)
        TaskRead.tbTargetPointTable = {}
    end
end

-- 通用分割流程
function TaskRead.SplitState(nLine)
    TaskRead.tbTaskState = {}
    TaskRead.tbCustom = {}
    TaskRead.nTaskMove = false
    TaskRead.szBtnCmd = nil
    TaskRead.nSleeTime = 0
    TaskRead.szKeyGM = nil
    local keywords = {
        Btn = "Btn",
        Sleep = "Sleep",
        Dialogue = "Dialogue",
        Fight = "Fight",
        TaskGM = "TaskGM"
    }

    for _, value in ipairs(TaskRead.tbTask[nLine] or {}) do
        for _, v in ipairs(value) do
            if not v:find("x") then
                local isSpecial = false
                for key, word in pairs(keywords) do
                    if v:find(word) then
                        isSpecial = true
                        if word == "Btn" then
                            table.insert(TaskRead.tbTaskState, "Btn")
                            TaskRead.szBtnCmd = v:sub(5)
                        elseif word == "Sleep" then
                            table.insert(TaskRead.tbTaskState, "Sleep")
                            TaskRead.nSleeTime = tonumber(v:sub(7))
                        elseif word == "Dialogue" then
                            table.insert(TaskRead.tbTaskState, "Dialogue")
                        elseif word == "Fight" then
                            table.insert(TaskRead.tbTaskState, "Fight")
                        elseif word == "TaskGM" then
                            table.insert(TaskRead.tbTaskState, "TaskGM")
                            TaskRead.szKeyGM = v:sub(8)
                        end
                        break
                    end
                end
                if not isSpecial then
                    local coordinate = SearchPanel.StringSplit(v, "%s")
                    TaskRead.tbCoordinate = {coordinate[1], coordinate[2], coordinate[3]}
                    table.insert(TaskRead.tbCustom, TaskRead.tbCoordinate)
                    if not TaskRead.nTaskMove then
                        table.insert(TaskRead.tbTaskState, "Move")
                        TaskRead.nTaskMove = true
                    end
                end
            end
        end
    end
end

-- 重载任务
function TaskRead.Reset()
    TaskRead.tbTask = {}
    TaskRead.tbTargetPointTable = {}
    TaskRead.tbCustom = {}
    TaskRead.tbCoordinate = {}
    TaskRead.tbTaskState = {}
    TaskRead.nTaskStateLine = 1
    TaskRead.nTaskMove = false
    TaskRead.szBtnCmd = nil
    TaskRead.nSleeTime = 0
    TaskRead.szKeyGM = nil
    TaskRead.nTaskLine = 2
end

return TaskRead