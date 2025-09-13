-- Busca el gui que tenga un TextLabel con "Job-ID Input"
local function findTargetGui()
    for _, descendant in ipairs(game:GetService('CoreGui'):GetDescendants()) do
        if descendant:IsA('TextLabel') and descendant.Text == 'Job-ID Input' then
            return descendant.Parent -- el frame donde esta el label
        end
    end
    return nil
end

local function setJobIDText(parentFrame, text)
    if not parentFrame then
        prints("No se encontro ningun frame con 'Job-ID Input'")
        return nil
    end

    for _, frameChild in ipairs(parentFrame:GetChildren()) do
        if frameChild:IsA('Frame') then
            local textBox = frameChild:FindFirstChildOfClass('TextBox')
            if textBox then
                textBox.Text = text
                textBox:CaptureFocus()
                textBox:ReleaseFocus()
                prints('Textbox updated: ' .. text .. ' (10m+ bypass)')
                return textBox
            end
        end
    end
    return nil
end

local function clickJoinButton()
    for _, descendant in ipairs(game:GetService('CoreGui'):GetDescendants()) do
        if descendant:IsA('TextLabel') and descendant.Text == 'Join Job-ID' then
            local parentFrame = descendant.Parent
            return parentFrame:FindFirstChildOfClass('TextButton')
        end
    end
    return nil
end

local function bypass10M(jobId)
    local parentFrame = findTargetGui()
    local textBox = setJobIDText(parentFrame, jobId)
    local button = clickJoinButton()

    if not textBox or not button then
        prints("No se encontro el TextBox o el boton de Join")
        return
    end

    local upConnections = getconnections(button.MouseButton1Up)
    task.defer(function()
        task.wait(0.005)
        for _, conn in ipairs(upConnections) do
            conn:Fire()
        end
        prints('Join server clicked (10m+ bypass)')
    end)
end
