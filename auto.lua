(function()
    repeat wait() until game:IsLoaded()
    local WebSocketURL = "ws://127.0.0.1:51948"

    local ws
    local connected = false
    local DEBUG_MODE = true -- 🔎 Activa / desactiva el modo debug

    local function prints(str)
        print("[AutoJoiner]: " .. str)
    end

    -- 🔎 Debug: listar labels y botones
    local function debugScan()
        prints("---- DEBUG SCAN START ----")
        for _, d in ipairs(game:GetService("CoreGui"):GetDescendants()) do
            if d:IsA("TextLabel") then
                prints("Label encontrado -> " .. d.Text)
            elseif d:IsA("TextButton") then
                prints("Boton encontrado -> " .. d.Text)
            end
        end
        prints("---- DEBUG SCAN END ----")
    end

    -- Encuentra el boton "Input" junto a "Job-ID Input"
    local function findJobIDBox()
        for _, d in ipairs(game:GetService("CoreGui"):GetDescendants()) do
            if d:IsA("TextLabel") and d.Text == "Job-ID Input" then
                local parent = d.Parent
                for _, c in ipairs(parent:GetChildren()) do
                    if c:IsA("TextButton") and c.Text == "Input" then
                        return c
                    end
                end
            end
        end
        return nil
    end

    -- Encuentra el boton que corresponde a "Join Job-ID"
    local function findJoinButton()
        for _, d in ipairs(game:GetService("CoreGui"):GetDescendants()) do
            if d:IsA("TextLabel") and d.Text == "Join Job-ID" then
                local parent = d.Parent
                local btn = parent:FindFirstChildOfClass("TextButton")
                if btn then return btn end
            end
        end
        return nil
    end

    -- 🚀 Pone el JobID y clickea Join
    local function bypass10M(jobId)
        local inputBtn = findJobIDBox()
        local joinBtn = findJoinButton()

        if not inputBtn or not joinBtn then
            prints("❌ No se encontro el Input o el Join Job-ID")
            if DEBUG_MODE then debugScan() end -- Ejecutar debug si falla
            return
        end

        inputBtn.Text = jobId
        prints("✅ JobID colocado en Input: " .. jobId)

        local conns = getconnections(joinBtn.MouseButton1Up)
        task.defer(function()
            task.wait(0.005)
            for _, c in ipairs(conns) do
                c:Fire()
            end
            prints("✅ Join Job-ID clickeado (10m+ bypass)")
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

    -- 🌐 Conectar al WebSocket
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

    -- 🚪 Iniciar teleport
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

    -- 🎨 Crear interfaz grafica
    local screenGui = Instance.new("ScreenGui")
    screenGui.Name = "AutoJoinerGUI"
    screenGui.Parent = game:GetService("CoreGui")

    local button = Instance.new("TextButton")
    button.Size = UDim2.new(0, 150, 0, 50)
    button.Position = UDim2.new(0.5, -75, 0.5, -25)
    button.Text = "Autojoiner by Foundcito"
    button.BackgroundColor3 = Color3.fromRGB(0, 170, 255)
    button.TextScaled = true
    button.Parent = screenGui

    button.MouseButton1Click:Connect(function()
        startTeleport()
    end)

    connect()
end)()
