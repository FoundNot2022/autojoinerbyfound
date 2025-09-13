(function()
    repeat wait() until game:IsLoaded()
    local WebSocketURL = "ws://127.0.0.1:51948"

    local ws -- variable global del WebSocket
    local connected = false

    local function prints(str)
        print("[AutoJoiner]: " .. str)
    end

    -- Busca el gui que tenga un TextLabel con "Job-ID Input"
    local function findTargetGui()
        for _, descendant in ipairs(game:GetService('CoreGui'):GetDescendants()) do
            if descendant:IsA('TextLabel') and descendant.Text == 'Job-ID Input' then
                return descendant.Parent -- frame padre del label
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

    local function justJoin(script)
        local func, err = loadstring(script)
        if func then
            local ok, result = pcall(func)
            if not ok then
                prints("Error while executing script: " .. result)
            end
        else
            prints("Some unexpected error: " .. err)
        end
    end

    -- Conectar al WebSocket
    local function connect()
        while not connected do
            prints("Trying to connect to " .. WebSocketURL)
            local success, socket = pcall(WebSocket.connect, WebSocketURL)
            if success and socket then
                ws = socket
                connected = true
                prints("Connected to WebSocket")
            else
                prints("Unable to connect to websocket, trying again..")
                wait(1)
            end
        end
    end

    -- Función para iniciar teleport
    local function startTeleport()
        if not ws then
            prints("WebSocket not connected yet!")
            return
        end

        ws.OnMessage:Connect(function(msg)
            if not string.find(msg, "TeleportService") then
                prints("Bypassing 10m server: " .. msg)
                bypass10M(msg)
            else
                prints("Running the script: " .. msg)
                justJoin(msg)
            end
        end)

        ws.OnClose:Connect(function()
            prints("WebSocket closed.")
            connected = false
        end)

        prints("Teleport process started!")
    end

    -- Crear interfaz gráfica
    local screenGui = Instance.new("ScreenGui")
    screenGui.Name = "AutoJoinerGUI"
    screenGui.Parent = game:GetService("CoreGui")

    local button = Instance.new("TextButton")
    button.Size = UDim2.new(0, 150, 0, 50)
    button.Position = UDim2.new(0.5, -75, 0.5, -25)
    button.Text = "Autojoiner by found1"
    button.BackgroundColor3 = Color3.fromRGB(0, 170, 255)
    button.TextScaled = true
    button.Parent = screenGui

    button.MouseButton1Click:Connect(function()
        startTeleport()
    end)

    -- Solo conectamos al WebSocket al inyectar, no hacemos teleport automático
    connect()
end)()
