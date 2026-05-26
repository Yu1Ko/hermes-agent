AutoTestLog.Log("TestBuyNewExterior", "TestBuyNewExterior Start")

local TestBuyNewExterior = {}
TestBuyNewExterior.bSwitch = true
local list_RunMapTime = {}
local list_RunMapCMD = {}
local nNextTime = 30
local nCurrentTime = GetTickCount()
local nCurrentStep = 1
local bFlag = true

function TestBuyNewExterior.FrameUpdate()
    if not TestBuyNewExterior.bSwitch then
        return
    end
    if not SearchPanel.IsFromLoadingEnterGame() then
        return
    end

    if bFlag and GetTickCount() - nCurrentTime > nNextTime * 1000 then
        if nCurrentStep == #list_RunMapCMD then
            bFlag = false
        end
        local szCmd = list_RunMapCMD[nCurrentStep]
        local nTime = tonumber(list_RunMapTime[nCurrentStep])

        LOG.INFO("%s", szCmd)
        pcall(function()
            SearchPanel.RunCommand(szCmd)
        end)

        if string.find(szCmd, "perfeye_start") then
            SearchPanel.bPerfeye_Start = true
        elseif string.find(szCmd, "perfeye_stop") then
            SearchPanel.bPerfeye_Stop = true
        end

        LOG.INFO("%s", szCmd .. "===ok")
        OutputMessage("MSG_SYS", szCmd)
        LOG.INFO("%s", "TestBuyNewExterior :" .. szCmd .. " ok")
        nNextTime = nTime or nNextTime
        nCurrentTime = GetTickCount()
        nCurrentStep = nCurrentStep + 1
    end
end

local tbRunMapData = SearchPanel.LoadRunMapFile(SearchPanel.szCurrentInterfacePath .. "RunMap.tab", 2)
list_RunMapCMD = tbRunMapData[1]
list_RunMapTime = tbRunMapData[2]

Timer.AddFrameCycle(TestBuyNewExterior, 1, function()
    TestBuyNewExterior.FrameUpdate()
end)

AutoTestLog.Log("TestBuyNewExterior", "TestBuyNewExterior End")
return TestBuyNewExterior
