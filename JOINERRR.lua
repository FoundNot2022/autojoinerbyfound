(function()
    repeat wait() until game:IsLoaded()
    local WebSocketURL = "ws://127.0.0.1:51948"

    local ws -- variable global del WebSocket
    local connected = false

    local function prints(str)
        print("[AutoJoiner]: " .. str)
    end

    -- 🔎 Encuentra el cuadro de texto correcto (InputText)
    local function findJobIDBox()
        for _, d in ipairs(gethui():GetDescendants()) do
            if d:IsA("TextBox") and d.Name == "InputText" then
                prints("✅ Detectado cuadro de texto Job-ID Input (InputText)")
                return d
            end
        end
        return nil
    end

    -- 🔎 Encuentra el botón Join Job-ID
    local function findJoinButton()
        for _, d in ipairs(gethui():GetDescendants()) do
            if d:IsA("TextLabel") and d.Text == "Join Job-ID" then
                local parent = d.Parent
                for _, c in ipairs(parent:GetChildren()) do
                    if c:IsA("TextButton") then
                        prints("✅ Detectado botón Join Job-ID")
                        return c
                    end
                end
            end
        end
        return nil
    end

 local function bypass10M(jobId)
    local inputBox = findJobIDBox()
    local joinBtn = findJoinButton()

    if not inputBox or not joinBtn then
        prints("❌ No se encontró el Input o el Join Job-ID")
        return
    end

    -- Poner el texto y forzar evento
    inputBox.Text = jobId
    inputBox:CaptureFocus()
    task.wait(0.05)
    inputBox:ReleaseFocus()

    -- 🔥 Forzar FocusLost para que el sistema lo reconozca
    pcall(function()
        inputBox.FocusLost:Fire(true) -- true = enter presionado
    end)

    prints("✅ JobID colocado en Input: " .. jobId)

    -- Simular click en el botón
    local conns = getconnections(joinBtn.MouseButton1Up)
    if #conns > 0 then
        for _, c in ipairs(conns) do
            c:Fire()
        end
        prints("✅ Join Job-ID clickeado con conexiones")
    else
        joinBtn:Activate()
        prints("✅ Join Job-ID activado directamente")
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

    -- 🎨 Crear interfaz gráfica
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

    -- Solo conectamos al WebSocket al inyectar, no hacemos teleport automático
    connect()
end)()
