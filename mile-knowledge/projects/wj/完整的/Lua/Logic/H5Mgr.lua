-- ---------------------------------------------------------------------------------
-- Author: huqing
-- Name: H5Mgr
-- Date: 2026-04-14 15:59:46
-- Desc: H5 小游戏管理类
-- ---------------------------------------------------------------------------------

H5Mgr = H5Mgr or {className = "H5Mgr"}
local self = H5Mgr

local MINIGAME_CACHE_FILE = "temp/h5_minigame_info.data"
local MINIGAME_SRC_DIR = "ui/H5Host/MiniGame/"
local MINIGAME_DST_DIR = "ui/H5Host/MiniGame/"

local tbGameList = {
    "KiteFly",
}


function H5Mgr.Init()
    -- LOG.INFO("H5Mgr.Init -------------------------------")

    -- for _, sMiniGameName in ipairs(tbGameList) do
    --     LOG.INFO("Copying mini game: %s", sMiniGameName)
    --     H5Mgr.CopyMiniGame(sMiniGameName)
    -- end
end

function H5Mgr.UnInit()

end

function H5Mgr.OnLogin()

end

function H5Mgr.OnFirstLoadEnd()

end

function H5Mgr.GetRootPath()
    return MINIGAME_DST_DIR
end

local function LoadMiniGameHashes()
    local szContent = Lib.GetStringFromFile(GetFullPath(MINIGAME_CACHE_FILE))
    local tbHash = {}
    if not szContent or #szContent == 0 then
        return tbHash
    end
    for szLine in string.gmatch(szContent, "[^\r\n]+") do
        local szKey, szValue = string.match(szLine, "^(.+)=(%d+)$")
        if szKey then
            tbHash[szKey] = tonumber(szValue)
        end
    end
    return tbHash
end

local function SaveMiniGameHashes(tbHash)
    local tbLines = {}
    for szKey, nValue in pairs(tbHash) do
        table.insert(tbLines, string.format("%s=%d", szKey, nValue))
    end
    table.sort(tbLines)
    Lib.WriteStringToFile(table.concat(tbLines, "\n"), GetFullPath(MINIGAME_CACHE_FILE))
end

function H5Mgr.CopyMiniGame(sMiniGameName)
    local szSrcDir = MINIGAME_SRC_DIR .. sMiniGameName
    local szDstDir = MINIGAME_DST_DIR .. sMiniGameName

    -- 读取 file_list.txt 获取文件列表
    local szFileListPath = szSrcDir .. "/file_list.txt"
    local szFileList = Lib.GetStringFromFile(GetFullPath(szFileListPath))
    if not szFileList or #szFileList == 0 then
        LOG.INFO("[H5Mgr] CopyMiniGame file_list.txt not found: %s", szFileListPath)
        return
    end

    -- 按行解析文件列表
    local tbLines = {}
    for szLine in string.gmatch(szFileList, "[^\r\n]+") do
        --LOG.INFO("[H5Mgr] CopyMiniGame file_list.txt line: %s", szLine)
        szLine = string.gsub(szLine, "\\", "/")
        table.insert(tbLines, szLine)
    end

    if #tbLines == 0 then
        LOG.INFO("[H5Mgr] CopyMiniGame file_list.txt is empty: %s", szFileListPath)
        return
    end

    -- 最后一行是否为 0，是则删除目标目录
    local szLastLine = tbLines[#tbLines]
    if szLastLine == "0" then
        LOG.INFO("[H5Mgr] CopyMiniGame file_list.txt indicates to clear directory: %s", szDstDir)
        table.remove(tbLines, #tbLines)
        local szFullDstDir = GetFullPath(szDstDir)
        if Lib.IsDirectoryExist(szFullDstDir) then
            Lib.RemoveDirectory(szFullDstDir)
            LOG.INFO("[H5Mgr] CopyMiniGame removed directory: %s", szDstDir)
        end

        -- 清空该小游戏相关的哈希缓存
        local tbOldHash = LoadMiniGameHashes()
        local bDirty = false
        for szOldPath, _ in pairs(tbOldHash) do
            if string.find(szOldPath, szSrcDir, 1, true) then
                tbOldHash[szOldPath] = nil
                bDirty = true
            end
        end
        if bDirty then
            SaveMiniGameHashes(tbOldHash)
        end
        return
    end

    -- 加载哈希缓存
    local tbOldHash = LoadMiniGameHashes()
    local tbNewHash = {}

    local nCopyCount = 0

    for _, szFileName in ipairs(tbLines) do
        if #szFileName > 0 then
            local szSrcPath = szSrcDir .. "/" .. szFileName
            local szDstPath = szDstDir .. "/" .. szFileName
            local nNewHash = GetFileContentHash(szSrcPath)
            -- LOG.INFO("[H5Mgr] CopyMiniGame szSrcPath: %s, hash = %s", szSrcPath, tostring(nNewHash))
            if nNewHash ~= 0 then
                tbNewHash[szSrcPath] = nNewHash

                local nOldHash = tbOldHash[szSrcPath]
                if nOldHash ~= nNewHash then
                    if CopyPakFile(szSrcPath, szDstPath) then
                        nCopyCount = nCopyCount + 1
                        LOG.INFO("[H5Mgr] CopyMiniGame updated: %s", szFileName)
                    else
                        LOG.INFO("[H5Mgr] CopyMiniGame failed: %s", szSrcPath)
                    end
                end
            else
                LOG.INFO("[H5Mgr] CopyMiniGame source not found: %s", szSrcPath)
            end
        end
    end

    -- 清理目标目录中不再在 file_list 中的旧文件
    for szOldPath, _ in pairs(tbOldHash) do
        if not tbNewHash[szOldPath] and string.find(szOldPath, szSrcDir, 1, true) then
            local szOldRelative = string.sub(szOldPath, #szSrcDir + 1)
            local szOldDstPath = szDstDir .. szOldRelative
            Lib.RemoveFile(szOldDstPath)
            LOG.INFO("[H5Mgr] CopyMiniGame removed: %s", szOldRelative)
        end
    end

    -- 保存哈希缓存
    SaveMiniGameHashes(tbNewHash)
    LOG.INFO("[H5Mgr] CopyMiniGame done: %s, copied: %d", sMiniGameName, nCopyCount)
end