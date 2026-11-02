--!nonstrict
--[[
	ROBLOX — ORGANIC EVOLUTION & REGENERATIVE TENTACLES (V2 - MOBILE & RENDERSTEPPED FIX)
	Single LocalScript | 100% Client-Side | R6 & R15 Compatible
	Prioridade Absoluta: Animação Procedural Fluida, Física Orgânica e Controles Mobile Touch
]]

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local Workspace = game:GetService("Workspace")

local LocalPlayer = Players.LocalPlayer
local PlayerGui = LocalPlayer:WaitForChild("PlayerGui")

-- ============================================================================
-- 1. CONFIGURAÇÕES VISUAIS E ESTRUTURAIS (ORGÂNICO SOMBRIO - SEM NEON/BLOOM)
-- ============================================================================
local CONFIG = {
	TentacleCount = 4,
	SegmentsPerTentacle = 14,
	BaseSegmentLength = 0.76,
	BaseSegmentRadius = 0.44,

	-- Paleta de cores orgânica escura (Quitina, Biomassa, Músculo Denso)
	ColorChitinDark = Color3.fromRGB(22, 20, 24),
	ColorChitinMid = Color3.fromRGB(36, 31, 38),
	ColorMuscle = Color3.fromRGB(58, 36, 40),
	ColorClaw = Color3.fromRGB(14, 13, 16),
	ColorMembrane = Color3.fromRGB(45, 32, 36),
}

-- ============================================================================
-- 2. SOLUCIONADORES FÍSICOS DE MOLA (INÉRCIA REAL E MOVIMENTO SECUNDÁRIO)
-- ============================================================================
local function createScalarSpring(initial, freq, damp)
	return {
		Pos = initial or 0,
		Vel = 0,
		Target = initial or 0,
		Freq = freq or 8,
		Damp = damp or 0.75,
		Update = function(self, dt)
			local cDt = math.clamp(dt, 0.001, 0.05)
			local f = self.Freq * 6.2831853
			local offset = self.Pos - self.Target
			local accel = -(f * f) * offset - (2 * self.Damp * f) * self.Vel
			self.Vel = self.Vel + accel * cDt
			self.Pos = self.Pos + self.Vel * cDt
			return self.Pos
		end,
		Impulse = function(self, force)
			self.Vel = self.Vel + force
		end,
	}
end

local function createVector3Spring(initial, freq, damp)
	return {
		Pos = initial or Vector3.zero,
		Vel = Vector3.zero,
		Target = initial or Vector3.zero,
		Freq = freq or 7,
		Damp = damp or 0.65,
		Update = function(self, dt)
			local cDt = math.clamp(dt, 0.001, 0.05)
			local f = self.Freq * 6.2831853
			local offset = self.Pos - self.Target
			local accel = -(f * f) * offset - (2 * self.Damp * f) * self.Vel
			self.Vel = self.Vel + accel * cDt
			self.Pos = self.Pos + self.Vel * cDt
			return self.Pos
		end,
		Impulse = function(self, force)
			self.Vel = self.Vel + force
		end,
	}
end

local function smoothStep(edge0, edge1, x)
	local t = math.clamp((x - edge0) / math.max(0.0001, (edge1 - edge0)), 0, 1)
	return t * t * (3 - 2 * t)
end

-- ============================================================================
-- 3. CONSTRUTOR DE PEÇAS ORGÂNICAS (100% ROBLOX GEOMETRY)
-- ============================================================================
local function makePart(name, color, material, shape, parent)
	local p = Instance.new("Part")
	p.Name = name
	p.Size = Vector3.new(0.1, 0.1, 0.1)
	p.Color = color
	p.Material = material
	p.Shape = shape or Enum.PartType.Block
	p.TopSurface = Enum.SurfaceType.Smooth
	p.BottomSurface = Enum.SurfaceType.Smooth
	p.CanCollide = false
	p.CanTouch = false
	p.CanQuery = false
	p.Massless = true
	p.Anchored = true -- Anchored + CFrame direto no RenderStepped = 100% livre de bugs de Weld e física!
	p.CastShadow = true
	p.Transparency = 1
	p.Parent = parent
	return p
end

local function makeWedge(name, color, material, parent)
	local w = Instance.new("WedgePart")
	w.Name = name
	w.Size = Vector3.new(0.1, 0.1, 0.1)
	w.Color = color
	w.Material = material
	w.TopSurface = Enum.SurfaceType.Smooth
	w.BottomSurface = Enum.SurfaceType.Smooth
	w.CanCollide = false
	w.CanTouch = false
	w.CanQuery = false
	w.Massless = true
	w.Anchored = true
	w.CastShadow = true
	w.Transparency = 1
	w.Parent = parent
	return w
end

-- ============================================================================
-- 4. INTERFACE MOBILE & PC (BOTÕES TOUCH RESPONSIVOS ACIMA DO BOTÃO DE PULO)
-- ============================================================================
local function createMobileTouchUI(callbacks)
	-- Limpar GUI antiga caso exista
	local old = PlayerGui:FindFirstChild("EvolutionMobileHUD")
	if old then
		old:Destroy()
	end

	local sg = Instance.new("ScreenGui")
	sg.Name = "EvolutionMobileHUD"
	sg.ResetOnSpawn = false
	sg.IgnoreGuiInset = true
	sg.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
	sg.DisplayOrder = 50
	sg.Parent = PlayerGui

	-- Painel posicionado na direita da tela, ergonômico para o polegar no celular
	local touchPanel = Instance.new("Frame")
	touchPanel.Name = "MobileTouchCluster"
	touchPanel.AnchorPoint = Vector2.new(1, 0.5)
	touchPanel.Position = UDim2.new(1, -18, 0.48, 0)
	touchPanel.Size = UDim2.new(0, 150, 0, 230)
	touchPanel.BackgroundTransparency = 1
	touchPanel.Parent = sg

	-- Função auxiliar para conectar Toque Mobile (Touch) e Clique (PC) sem falhas
	local function bindTouchAndClick(button, action)
		local lastTrigger = 0
		local function trigger()
			local now = os.clock()
			if now - lastTrigger < 0.15 then
				return
			end
			lastTrigger = now
			-- Feedback tátil visual rápido de compressão do botão
			button.Size = button:GetAttribute("BaseSize") - UDim2.new(0, 4, 0, 3)
			task.delay(0.08, function()
				if button and button.Parent then
					button.Size = button:GetAttribute("BaseSize")
				end
			end)
			action()
		end

		button.InputBegan:Connect(function(input)
			if input.UserInputType == Enum.UserInputType.Touch or input.UserInputType == Enum.UserInputType.MouseButton1 then
				trigger()
			end
		end)
		button.Activated:Connect(trigger)
	end

	-- BOTÃO PRINCIPAL MINIMALISTA "EVOLUTION"
	local evoBtn = Instance.new("TextButton")
	evoBtn.Name = "EvolutionMainBtn"
	evoBtn.AnchorPoint = Vector2.new(1, 0)
	evoBtn.Position = UDim2.new(1, 0, 0, 0)
	evoBtn.Size = UDim2.new(0, 136, 0, 42)
	evoBtn:SetAttribute("BaseSize", UDim2.new(0, 136, 0, 42))
	evoBtn.BackgroundColor3 = Color3.fromRGB(20, 19, 23)
	evoBtn.BackgroundTransparency = 0.1
	evoBtn.BorderSizePixel = 0
	evoBtn.AutoButtonColor = false
	evoBtn.Font = Enum.Font.GothamBold
	evoBtn.Text = "   EVOLUTION"
	evoBtn.TextColor3 = Color3.fromRGB(205, 200, 210)
	evoBtn.TextSize = 13
	evoBtn.Parent = touchPanel

	local evoCorner = Instance.new("UICorner")
	evoCorner.CornerRadius = UDim.new(0, 6)
	evoCorner.Parent = evoBtn

	local evoStroke = Instance.new("UIStroke")
	evoStroke.Color = Color3.fromRGB(58, 52, 64)
	evoStroke.Thickness = 1.5
	evoStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
	evoStroke.Parent = evoBtn

	-- Ponto discreto indicador de estado
	local statusDot = Instance.new("Frame")
	statusDot.AnchorPoint = Vector2.new(0, 0.5)
	statusDot.Position = UDim2.new(0, 12, 0.5, 0)
	statusDot.Size = UDim2.new(0, 7, 0, 7)
	statusDot.BackgroundColor3 = Color3.fromRGB(80, 75, 85)
	statusDot.BorderSizePixel = 0
	statusDot.Parent = evoBtn

	local dotCorner = Instance.new("UICorner")
	dotCorner.CornerRadius = UDim.new(1, 0)
	dotCorner.Parent = statusDot

	bindTouchAndClick(evoBtn, function()
		callbacks.OnToggleEvolution()
	end)

	-- CONTAINER DE HABILIDADES DOS TENTÁCULOS (Aparece abaixo do botão EVOLUTION quando ativo)
	local subCluster = Instance.new("Frame")
	subCluster.Name = "TentacleSkillPad"
	subCluster.AnchorPoint = Vector2.new(1, 0)
	subCluster.Position = UDim2.new(1, 0, 0, 50)
	subCluster.Size = UDim2.new(0, 136, 0, 175)
	subCluster.BackgroundTransparency = 1
	subCluster.Visible = false
	subCluster.Parent = touchPanel

	local subButtons = {}
	local buttonDefs = {
		{ Id = "STRIKE", Text = "ATAQUE", Pos = UDim2.new(0, 0, 0, 0), Size = UDim2.new(1, 0, 0, 38), Call = callbacks.OnStrike },
		{ Id = "SPREAD", Text = "ABRIR", Pos = UDim2.new(0, 0, 0, 44), Size = UDim2.new(0.48, 0, 0, 36), Call = function() callbacks.OnMode("SPREAD") end },
		{ Id = "COIL", Text = "ENROLAR", Pos = UDim2.new(0.52, 0, 0, 44), Size = UDim2.new(0.48, 0, 0, 36), Call = function() callbacks.OnMode("COIL") end },
		{ Id = "RETRACT", Text = "RETRAIR", Pos = UDim2.new(0, 0, 0, 86), Size = UDim2.new(0.48, 0, 0, 36), Call = function() callbacks.OnMode("RETRACT") end },
		{ Id = "REGEN", Text = "REGEN", Pos = UDim2.new(0.52, 0, 0, 86), Size = UDim2.new(0.48, 0, 0, 36), Call = callbacks.OnRegen },
		{ Id = "IDLE", Text = "LIVRE", Pos = UDim2.new(0, 0, 0, 128), Size = UDim2.new(1, 0, 0, 32), Call = function() callbacks.OnMode("IDLE") end },
	}

	for _, def in ipairs(buttonDefs) do
		local b = Instance.new("TextButton")
		b.Name = def.Id
		b.Position = def.Pos
		b.Size = def.Size
		b:SetAttribute("BaseSize", def.Size)
		b.BackgroundColor3 = Color3.fromRGB(24, 22, 27)
		b.BackgroundTransparency = 0.14
		b.BorderSizePixel = 0
		b.AutoButtonColor = false
		b.Font = Enum.Font.GothamMedium
		b.Text = def.Text
		b.TextColor3 = Color3.fromRGB(175, 170, 180)
		b.TextSize = 11
		b.Parent = subCluster

		local c = Instance.new("UICorner")
		c.CornerRadius = UDim.new(0, 5)
		c.Parent = b

		local st = Instance.new("UIStroke")
		st.Color = Color3.fromRGB(48, 44, 54)
		st.Thickness = 1
		st.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
		st.Parent = b

		bindTouchAndClick(b, def.Call)
		subButtons[def.Id] = { Btn = b, Stroke = st }
	end

	return {
		ScreenGui = sg,
		Refresh = function(isEvolved, isTransitioning, currentMode)
			if not isEvolved and not isTransitioning then
				evoBtn.Text = "   EVOLUTION"
				evoBtn.BackgroundColor3 = Color3.fromRGB(20, 19, 23)
				evoStroke.Color = Color3.fromRGB(58, 52, 64)
				statusDot.BackgroundColor3 = Color3.fromRGB(80, 75, 85)
				subCluster.Visible = false
			elseif isTransitioning then
				evoBtn.Text = "   MUTATING..."
				evoBtn.BackgroundColor3 = Color3.fromRGB(32, 24, 28)
				evoStroke.Color = Color3.fromRGB(110, 65, 72)
				statusDot.BackgroundColor3 = Color3.fromRGB(160, 70, 78)
				subCluster.Visible = true
			else
				evoBtn.Text = "   ACTIVE [ON]"
				evoBtn.BackgroundColor3 = Color3.fromRGB(28, 22, 26)
				evoStroke.Color = Color3.fromRGB(125, 68, 75)
				statusDot.BackgroundColor3 = Color3.fromRGB(185, 62, 70)
				subCluster.Visible = true
			end

			for id, data in pairs(subButtons) do
				if id == currentMode then
					data.Btn.BackgroundColor3 = Color3.fromRGB(46, 32, 37)
					data.Btn.TextColor3 = Color3.fromRGB(235, 225, 228)
					data.Stroke.Color = Color3.fromRGB(130, 75, 82)
				else
					data.Btn.BackgroundColor3 = Color3.fromRGB(24, 22, 27)
					data.Btn.TextColor3 = Color3.fromRGB(175, 170, 180)
					data.Stroke.Color = Color3.fromRGB(48, 44, 54)
				end
			end
		end,
	}
end

-- ============================================================================
-- 5. SISTEMA PRINCIPAL DE EVOLUÇÃO E TENTÁCULOS ARTICULADOS
-- ============================================================================
local activeRigFolder = nil
local renderConnection = nil
local isEvolved = false
local isTransitioning = false
local currentMode = "IDLE"
local strikeTimer = 0
local isStriking = false
local elapsedTime = 0

-- Molas globais de evolução corporal
local growthSpring = createScalarSpring(0, 5.5, 0.76)
local postureSpring = createScalarSpring(0, 7.0, 0.72)
local extensionSpring = createScalarSpring(1.0, 8.0, 0.75)

-- Estruturas de dados da anatomia procedural
local armorPieces = {}
local tentacles = {}
local uiController = nil

-- Constrói toda a anatomia orgânica para o personagem atual
local function buildEvolutionAnatomy(character)
	if activeRigFolder then
		activeRigFolder:Destroy()
		activeRigFolder = nil
	end
	table.clear(armorPieces)
	table.clear(tentacles)

	local rigFolder = Instance.new("Model")
	rigFolder.Name = "OrganicEvolutionAnatomy"
	rigFolder.Parent = character
	activeRigFolder = rigFolder

	-- 1. Construir Placas da Coluna Dorsal, Costelas, Ombros Expandidos e Braços Robustos
	for v = 1, 5 do
		local yOff = 0.82 - (v - 1) * 0.40
		local sFactor = 1.15 - (v - 1) * 0.09
		-- Vértebra quitinosa nas costas
		table.insert(armorPieces, {
			Part = makeWedge("Vertebra_" .. v, CONFIG.ColorChitinDark, Enum.Material.Slate, rigFolder),
			LimbType = "Torso",
			RetractedCF = CFrame.new(0, yOff * 0.5, 0.15),
			TargetCF = CFrame.new(0, yOff, 0.64) * CFrame.Angles(math.rad(-20), 0, 0),
			TargetSize = Vector3.new(0.76 * sFactor, 0.44 * sFactor, 0.58 * sFactor),
			Delay = (v - 1) * 0.06,
		})

		-- Costelas exoesqueléticas laterais
		for _, side in ipairs({ -1, 1 }) do
			table.insert(armorPieces, {
				Part = makeWedge("Rib_" .. v .. "_" .. side, CONFIG.ColorChitinMid, Enum.Material.Pebble, rigFolder),
				LimbType = "Torso",
				RetractedCF = CFrame.new(side * 0.2, yOff * 0.5, 0.1),
				TargetCF = CFrame.new(side * 0.72, yOff - 0.04, 0.36)
					* CFrame.Angles(math.rad(8), side * math.rad(-34), side * math.rad(14)),
				TargetSize = Vector3.new(0.28, 0.24 * sFactor, 0.85 * sFactor),
				Delay = 0.08 + (v - 1) * 0.05,
			})
		end
	end

	-- Núcleo central de biomassa nas costas
	table.insert(armorPieces, {
		Part = makePart("DorsalBiomassCore", CONFIG.ColorChitinDark, Enum.Material.Slate, Enum.PartType.Block, rigFolder),
		LimbType = "Torso",
		RetractedCF = CFrame.new(0, 0.1, 0.1),
		TargetCF = CFrame.new(0, 0.15, 0.58),
		TargetSize = Vector3.new(1.58, 1.48, 0.65),
		Delay = 0.02,
	})

	-- Expansão dos Ombros e Robustez dos Braços (Esquerdo e Direito)
	for _, side in ipairs({ -1, 1 }) do
		local upperLimb = (side == 1) and "RightUpperArm" or "LeftUpperArm"
		local lowerLimb = (side == 1) and "RightLowerArm" or "LeftLowerArm"

		-- Ombreira Superior de Quitina (Expande os ombros visualmente)
		table.insert(armorPieces, {
			Part = makePart("ShoulderBulk_" .. side, CONFIG.ColorChitinDark, Enum.Material.Slate, Enum.PartType.Block, rigFolder),
			LimbType = upperLimb,
			RetractedCF = CFrame.new(0, 0.2, 0),
			TargetCF = CFrame.new(side * 0.28, 0.56, 0) * CFrame.Angles(0, 0, side * math.rad(-20)),
			TargetSize = Vector3.new(1.32, 0.94, 1.30),
			Delay = 0.14,
		})

		-- Crista Afiada do Ombro
		table.insert(armorPieces, {
			Part = makeWedge("ShoulderSpike_" .. side, CONFIG.ColorClaw, Enum.Material.Slate, rigFolder),
			LimbType = upperLimb,
			RetractedCF = CFrame.new(0, 0.3, 0),
			TargetCF = CFrame.new(side * 0.46, 0.84, 0.04) * CFrame.Angles(0, side * math.pi * 0.5, math.rad(-26)),
			TargetSize = Vector3.new(0.88, 0.82, 1.22),
			Delay = 0.20,
		})

		-- Fibra Muscular do Braço
		table.insert(armorPieces, {
			Part = makePart("ArmMuscle_" .. side, CONFIG.ColorMuscle, Enum.Material.SmoothPlastic, Enum.PartType.Block, rigFolder),
			LimbType = upperLimb,
			RetractedCF = CFrame.identity,
			TargetCF = CFrame.new(side * 0.16, 0.14, 0) * CFrame.Angles(0, 0, side * math.rad(-8)),
			TargetSize = Vector3.new(1.18, 0.88, 1.18),
			Delay = 0.18,
		})

		-- Antebraço Robusto Blindado
		table.insert(armorPieces, {
			Part = makePart("ForearmMass_" .. side, CONFIG.ColorChitinMid, Enum.Material.Slate, Enum.PartType.Block, rigFolder),
			LimbType = lowerLimb,
			RetractedCF = CFrame.identity,
			TargetCF = CFrame.new(side * 0.14, -0.16, 0.04),
			TargetSize = Vector3.new(1.25, 1.28, 1.26),
			Delay = 0.26,
		})

		-- Lâmina Óssea Retrógrada no Cotovelo
		table.insert(armorPieces, {
			Part = makeWedge("ElbowBlade_" .. side, CONFIG.ColorClaw, Enum.Material.SmoothPlastic, rigFolder),
			LimbType = lowerLimb,
			RetractedCF = CFrame.new(0, 0.1, 0),
			TargetCF = CFrame.new(side * 0.50, 0.36, 0.44) * CFrame.Angles(math.rad(-145), 0, 0),
			TargetSize = Vector3.new(0.38, 1.02, 0.62),
			Delay = 0.32,
		})
	end

	-- 2. Construir os 4 Tentáculos Regenerativos Articulados nas Costas
	local socketDefinitions = {
		{ Side = -1, Layer = 1, RootOffset = CFrame.new(-0.56, 0.54, 0.72) }, -- Superior Esquerdo
		{ Side = 1, Layer = 1, RootOffset = CFrame.new(0.56, 0.54, 0.72) },  -- Superior Direito
		{ Side = -1, Layer = -1, RootOffset = CFrame.new(-0.46, -0.28, 0.72) }, -- Inferior Esquerdo
		{ Side = 1, Layer = -1, RootOffset = CFrame.new(0.46, -0.28, 0.72) },  -- Inferior Direito
	}

	for tIdx, def in ipairs(socketDefinitions) do
		local socketBulb = makePart("SocketBulb_" .. tIdx, CONFIG.ColorChitinMid, Enum.Material.Slate, Enum.PartType.Ball, rigFolder)
		local segments = {}
		local numSegs = CONFIG.SegmentsPerTentacle

		for s = 1, numSegs do
			local alpha = (s - 1) / (numSegs - 1)
			local bulge = math.sin(alpha * math.pi) * 0.07
			local baseRadius = CONFIG.BaseSegmentRadius * (1 - alpha * 0.75) + bulge
			local baseLen = CONFIG.BaseSegmentLength * (1 - alpha * 0.22)

			local corePart = makePart(
				string.format("T%d_Seg%d", tIdx, s),
				(s % 2 == 0) and CONFIG.ColorChitinDark or CONFIG.ColorChitinMid,
				Enum.Material.Slate,
				Enum.PartType.Block,
				rigFolder
			)
			local dorsalWedge = makeWedge("DorsalPlate", CONFIG.ColorChitinDark, Enum.Material.Pebble, rigFolder)
			local ventralPart = makePart("VentralMuscle", CONFIG.ColorMuscle, Enum.Material.SmoothPlastic, Enum.PartType.Block, rigFolder)

			local spineWedge = nil
			if s % 2 == 1 and s < numSegs - 1 then
				spineWedge = makeWedge("SpineRidge", CONFIG.ColorClaw, Enum.Material.Slate, rigFolder)
			end

			local tipClaw = nil
			if s == numSegs then
				tipClaw = makeWedge("ApexClaw", CONFIG.ColorClaw, Enum.Material.SmoothPlastic, rigFolder)
			end

			table.insert(segments, {
				Index = s,
				Alpha = alpha,
				BaseRadius = baseRadius,
				BaseLength = baseLen,
				Core = corePart,
				Dorsal = dorsalWedge,
				Ventral = ventralPart,
				Spine = spineWedge,
				Claw = tipClaw,
				RegenFactor = 1.0,
			})
		end

		table.insert(tentacles, {
			Index = tIdx,
			Side = def.Side,
			Layer = def.Layer,
			RootOffset = def.RootOffset,
			SocketBulb = socketBulb,
			Segments = segments,
			SwaySpring = createVector3Spring(Vector3.zero, 6.2, 0.58),
			PhaseOffset = tIdx * 1.35 + def.Side * 0.45,
			SpeedMult = 0.94 + tIdx * 0.05,
		})
	end
end

-- Funções de Ação Acionadas pelo Mobile Touch ou Teclado
local function toggleEvolutionState()
	if isTransitioning then
		return
	end
	isTransitioning = true

	if not isEvolved then
		isEvolved = true
		currentMode = "IDLE"
		growthSpring.Target = 1.0
		growthSpring:Impulse(1.5)
		postureSpring.Target = 1.0
		postureSpring:Impulse(2.0)
	else
		isEvolved = false
		currentMode = "RETRACT"
		growthSpring.Target = 0.0
		growthSpring:Impulse(-1.0)
		postureSpring.Target = 0.0
	end

	if uiController then
		uiController.Refresh(isEvolved, isTransitioning, currentMode)
	end

	task.delay(1.1, function()
		isTransitioning = false
		if uiController then
			uiController.Refresh(isEvolved, isTransitioning, currentMode)
		end
	end)
end

local function setTentacleBehavior(modeName)
	if not isEvolved then
		return
	end
	if currentMode == modeName and modeName ~= "IDLE" then
		currentMode = "IDLE"
	else
		currentMode = modeName
	end
	if uiController then
		uiController.Refresh(isEvolved, isTransitioning, currentMode)
	end
end

local function triggerTentacleStrike()
	if not isEvolved or isStriking then
		return
	end
	isStriking = true
	strikeTimer = 0
	postureSpring:Impulse(3.2)
	if uiController then
		uiController.Refresh(isEvolved, isTransitioning, "STRIKE")
	end
end

local function triggerTentacleRegen()
	if not isEvolved then
		return
	end
	growthSpring:Impulse(-2.2)
	for _, tent in ipairs(tentacles) do
		for s = 4, #tent.Segments do
			tent.Segments[s].RegenFactor = 0.05
		end
	end
	if uiController then
		uiController.Refresh(isEvolved, isTransitioning, "REGEN")
	end
	task.delay(0.65, function()
		if uiController and isEvolved then
			uiController.Refresh(isEvolved, isTransitioning, currentMode)
		end
	end)
end

-- Criar Interface Mobile & PC
uiController = createMobileTouchUI({
	OnToggleEvolution = toggleEvolutionState,
	OnMode = setTentacleBehavior,
	OnStrike = triggerTentacleStrike,
	OnRegen = triggerTentacleRegen,
})

-- Atalhos de Teclado para PC (Complementar aos botões Touch Mobile)
UserInputService.InputBegan:Connect(function(input, gp)
	if gp then
		return
	end
	if input.KeyCode == Enum.KeyCode.G then
		toggleEvolutionState()
	elseif isEvolved then
		if input.KeyCode == Enum.KeyCode.Q then
			triggerTentacleStrike()
		elseif input.KeyCode == Enum.KeyCode.E then
			setTentacleBehavior("COIL")
		elseif input.KeyCode == Enum.KeyCode.R then
			setTentacleBehavior("SPREAD")
		elseif input.KeyCode == Enum.KeyCode.F then
			setTentacleBehavior("RETRACT")
		elseif input.KeyCode == Enum.KeyCode.X then
			triggerTentacleRegen()
		end
	end
end)

-- ============================================================================
-- 6. LOOP DE SIMULAÇÃO EM TEMPO REAL (RENDERSTEPPED - GARANTIDO 100% FUNCIONAL)
-- ============================================================================
renderConnection = RunService.RenderStepped:Connect(function(rawDt)
	local dt = tonumber(rawDt) or (1 / 60)
	dt = math.clamp(dt, 0.001, 0.05)
	elapsedTime = elapsedTime + dt

	local character = LocalPlayer.Character
	if not character or not character.Parent then
		return
	end

	local rootPart = character:FindFirstChild("HumanoidRootPart")
	local torso = character:FindFirstChild("UpperTorso") or character:FindFirstChild("Torso")
	if not rootPart or not torso then
		return
	end

	-- Se a pasta da anatomia foi perdida ou ainda não foi criada para este personagem, constrói na hora
	if not activeRigFolder or activeRigFolder.Parent ~= character then
		buildEvolutionAnatomy(character)
	end

	-- Atualizar valores das molas
	local growth = math.clamp(growthSpring:Update(dt), 0, 1.15)
	local posture = math.clamp(postureSpring:Update(dt), 0, 1.35)

	-- Atualizar fase de ataque (Strike)
	local strikePhase = 0
	if isStriking then
		strikeTimer = strikeTimer + dt
		strikePhase = math.clamp(strikeTimer / 0.62, 0, 1)
		if strikeTimer >= 0.62 then
			isStriking = false
			if uiController then
				uiController.Refresh(isEvolved, isTransitioning, currentMode)
			end
		end
	end

	-- Se estiver 100% desativado e recolhido, ocultar tudo e economizar bateria no celular
	if not isEvolved and growth <= 0.01 then
		for _, item in ipairs(armorPieces) do
			item.Part.Transparency = 1
		end
		for _, tent in ipairs(tentacles) do
			tent.SocketBulb.Transparency = 1
			for _, seg in ipairs(tent.Segments) do
				seg.Core.Transparency = 1
				seg.Dorsal.Transparency = 1
				seg.Ventral.Transparency = 1
				if seg.Spine then seg.Spine.Transparency = 1 end
				if seg.Claw then seg.Claw.Transparency = 1 end
			end
		end
		return
	end

	-- Localizar membros para acoplamento R15 e R6
	local rUpper = character:FindFirstChild("RightUpperArm") or character:FindFirstChild("Right Arm") or torso
	local lUpper = character:FindFirstChild("LeftUpperArm") or character:FindFirstChild("Left Arm") or torso
	local rLower = character:FindFirstChild("RightLowerArm") or rUpper
	local lLower = character:FindFirstChild("LeftLowerArm") or lUpper

	local limbMap = {
		Torso = torso.CFrame,
		RightUpperArm = rUpper.CFrame,
		LeftUpperArm = lUpper.CFrame,
		RightLowerArm = rLower.CFrame,
		LeftLowerArm = lLower.CFrame,
	}

	-- 1. ATUALIZAR PLACAS DE ARMADURA ORGÂNICA, OMBROS E BRAÇOS
	local breathScale = 1 + math.sin(elapsedTime * 2.5) * 0.03 * growth
	for _, item in ipairs(armorPieces) do
		local localAlpha = smoothStep(item.Delay, item.Delay + 0.55, growth)
		if localAlpha <= 0.02 then
			item.Part.Transparency = 1
		else
			item.Part.Transparency = 0
			item.Part.Size = item.TargetSize * localAlpha * breathScale
			local baseLimbCF = limbMap[item.LimbType] or torso.CFrame
			local offsetCF = item.RetractedCF:Lerp(item.TargetCF, localAlpha)
			item.Part.CFrame = baseLimbCF * offsetCF
		end
	end

	-- 2. APLICAR POSTURA CORPORAL ADITIVA (MOTOR6D.TRANSFORM)
	for _, desc in ipairs(character:GetDescendants()) do
		if desc:IsA("Motor6D") then
			local mName = desc.Name
			if mName == "Root" or mName == "Waist" then
				local lean = math.rad(-7) * posture + math.sin(elapsedTime * 2.2) * math.rad(2.5) * posture
				desc.Transform = desc.Transform * CFrame.Angles(lean, 0, 0)
			elseif mName == "RightShoulder" then
				desc.Transform = desc.Transform * CFrame.Angles(math.rad(8 * posture), 0, math.rad(14 * posture))
			elseif mName == "LeftShoulder" then
				desc.Transform = desc.Transform * CFrame.Angles(math.rad(8 * posture), 0, math.rad(-14 * posture))
			end
		end
	end

	-- 3. CALCULAR FÍSICA SECUNDÁRIA E DIREÇÃO DO OLHAR PARA OS 4 TENTÁCULOS
	local torsoCF = torso.CFrame
	local localVel = torsoCF:VectorToObjectSpace(rootPart.AssemblyLinearVelocity)
	local localAng = torsoCF:VectorToObjectSpace(rootPart.AssemblyAngularVelocity)

	local cam = Workspace.CurrentCamera
	local lookLocal = Vector3.new(0, 0, -1)
	if cam then
		lookLocal = torsoCF:VectorToObjectSpace(cam.CFrame.LookVector)
	end

	local activeMode = isStriking and "STRIKE" or currentMode
	if activeMode == "STRIKE" then
		extensionSpring.Target = 1.28
	elseif activeMode == "SPREAD" then
		extensionSpring.Target = 1.16
	elseif activeMode == "COIL" then
		extensionSpring.Target = 0.88
	elseif activeMode == "RETRACT" then
		extensionSpring.Target = 0.42
	else
		extensionSpring.Target = 1.0
	end
	local extScale = extensionSpring:Update(dt)

	-- 4. ATUALIZAR CINEMÁTICA ARTICULADA DOS 4 TENTÁCULOS REGENERATIVOS
	for _, tent in ipairs(tentacles) do
		-- Mola de inércia individual reagindo ao movimento e rotação do jogador
		tent.SwaySpring.Target = Vector3.new(
			-localVel.X * 0.048 - localAng.Y * 0.15,
			-localVel.Y * 0.055,
			-localVel.Z * 0.045
		)
		local sway = tent.SwaySpring:Update(dt)

		-- Posicionar Bulbo Basal nas costas
		local bulbScale = math.clamp(growth * 1.1, 0.05, 1.0)
		tent.SocketBulb.Transparency = (growth < 0.02) and 1 or 0
		tent.SocketBulb.Size = Vector3.new(0.65, 0.65, 0.55) * bulbScale

		-- Orientação inicial saindo das costas (+Z do Torso é para trás no Roblox)
		local baseYaw = tent.Side * math.rad(36 + (tent.Layer > 0 and 10 or -6))
		local basePitch = math.rad(tent.Layer > 0 and 28 or -16)

		-- Acompanhamento orgânico da câmera
		local camYaw = math.atan2(-lookLocal.X, -lookLocal.Z) * 0.25
		local camPitch = math.asin(math.clamp(lookLocal.Y, -0.8, 0.8)) * 0.28

		-- O CFrame inicial aponta para trás das costas (Angles(0, math.pi, 0)) e abre lateralmente
		local currentChainCF = torsoCF
			* tent.RootOffset
			* CFrame.Angles(0, math.pi, 0)
			* CFrame.Angles(basePitch + camPitch, baseYaw + camYaw, 0)

		tent.SocketBulb.CFrame = currentChainCF

		local t = elapsedTime * tent.SpeedMult + tent.PhaseOffset
		local numSegs = #tent.Segments

		for i = 1, numSegs do
			local seg = tent.Segments[i]
			local a = seg.Alpha

			-- Regeneração progressiva dos segmentos
			if seg.RegenFactor < 1.0 then
				seg.RegenFactor = math.min(1.0, seg.RegenFactor + dt * (2.5 - a * 1.0))
			end

			local segStart = (i - 1) / numSegs
			local segGrowth = smoothStep(segStart * 0.65, segStart * 0.65 + 0.35, growth) * seg.RegenFactor

			if segGrowth <= 0.02 then
				seg.Core.Transparency = 1
				seg.Dorsal.Transparency = 1
				seg.Ventral.Transparency = 1
				if seg.Spine then seg.Spine.Transparency = 1 end
				if seg.Claw then seg.Claw.Transparency = 1 end
			else
				seg.Core.Transparency = 0
				seg.Dorsal.Transparency = 0
				seg.Ventral.Transparency = 0
				if seg.Spine then seg.Spine.Transparency = 0 end
				if seg.Claw then seg.Claw.Transparency = 0 end

				local r = seg.BaseRadius * segGrowth
				local l = seg.BaseLength * segGrowth * extScale

				-- Ondas senoidais multi-frequência para movimento vivo contínuo
				local wave1 = math.sin(t * 2.25 - i * 0.45)
				local wave2 = math.cos(t * 1.45 - i * 0.32)

				local pitch = 0
				local yaw = 0
				local roll = 0

				if activeMode == "IDLE" then
					-- Curva ameaçadora arqueando por cima dos ombros em direção à frente do personagem
					local arch = (i <= 5) and math.rad(14) or math.rad(-9)
					pitch = arch + wave1 * math.rad(6.8 * (0.35 + a)) + sway.Y * (0.2 + a * 0.35)
					yaw = tent.Side * math.rad(8 - a * 15) + wave2 * math.rad(8.5 * (0.3 + a)) + sway.X * (0.2 + a * 0.4)
					roll = tent.Side * math.rad(4) + wave1 * math.rad(4)

				elseif activeMode == "SPREAD" then
					-- Abertura larga predatória
					pitch = math.rad(tent.Layer * 4) + wave1 * math.rad(5 * a) + sway.Y * 0.25
					yaw = tent.Side * math.rad(12 - a * 18) + wave2 * math.rad(6 * a) + sway.X * 0.25
					roll = tent.Side * math.rad(7 * a)

				elseif activeMode == "COIL" then
					-- Enrolamento protetor em espiral ao redor do corpo
					pitch = math.rad(-16 - a * 22) + wave1 * math.rad(3.5)
					yaw = tent.Side * math.rad(-18 - a * 16) + wave2 * math.rad(3.5)
					roll = tent.Side * math.rad(14 + a * 12)

				elseif activeMode == "RETRACT" then
					-- Recolhimento articulado compacto contra as costas
					local fold = (i % 2 == 0) and 1 or -1
					pitch = math.rad(-25) + fold * math.rad(9)
					yaw = tent.Side * math.rad(-22)
					roll = tent.Side * math.rad(16)

				elseif activeMode == "STRIKE" then
					-- Golpe perfurante frontal sincronizado
					local windup = math.sin(math.clamp(strikePhase / 0.32, 0, 1) * math.pi * 0.5)
					local lash = smoothStep(0.25, 0.58, strikePhase) * (1 - smoothStep(0.72, 1.0, strikePhase))

					local strikePitch = (i <= 3) and math.rad(20) or math.rad(-15 * (1 - a * 0.5))
					local strikeYaw = -tent.Side * math.rad(14 * (0.3 + a * 0.5))

					pitch = math.rad(16 * (1 - a)) * windup * (1 - lash) + strikePitch * lash + wave1 * math.rad(2.5)
					yaw = tent.Side * math.rad(8) * (1 - lash) + strikeYaw * lash
					roll = tent.Side * math.rad(5) * (1 - lash)
				end

				-- Efeito orgânico de desenrolar enquanto o tentáculo cresce
				pitch = pitch + (1 - segGrowth) * math.rad(-28)

				-- Avançar a articulação na cadeia cinemática
				currentChainCF = currentChainCF
					* CFrame.Angles(pitch, yaw, roll)
					* CFrame.new(0, 0, -l * 0.46)

				-- Posicionar o segmento principal e suas sub-estruturas anatômicas
				seg.Core.Size = Vector3.new(r * 1.85, r * 1.65, l)
				seg.Core.CFrame = currentChainCF

				seg.Dorsal.Size = Vector3.new(r * 1.45, r * 0.72, l * 0.92)
				seg.Dorsal.CFrame = currentChainCF * CFrame.new(0, r * 0.75, 0) * CFrame.Angles(0, math.pi, 0)

				seg.Ventral.Size = Vector3.new(r * 1.15, r * 0.55, l * 1.04)
				seg.Ventral.CFrame = currentChainCF * CFrame.new(0, -r * 0.58, 0)

				if seg.Spine then
					seg.Spine.Size = Vector3.new(r * 0.52, r * 0.98, l * 0.55)
					seg.Spine.CFrame = currentChainCF * CFrame.new(0, r * 1.02, -l * 0.1) * CFrame.Angles(math.rad(-22), 0, 0)
				end

				if seg.Claw then
					seg.Claw.Size = Vector3.new(r * 1.22, r * 1.32, l * 1.55)
					seg.Claw.CFrame = currentChainCF * CFrame.new(0, 0, -l * 0.85) * CFrame.Angles(math.rad(14), 0, 0)
				end

				-- Mover o cursor da cadeia para a extremidade final deste segmento para conectar o próximo
				currentChainCF = currentChainCF * CFrame.new(0, 0, -l * 0.46)
			end
		end
	end
end)

-- ============================================================================
-- 7. DETECÇÃO AUTOMÁTICA DE RESPAWN E LIMPEZA DE OBJETOS TEMPORÁRIOS
-- ============================================================================
LocalPlayer.CharacterAdded:Connect(function(newChar)
	isEvolved = false
	isTransitioning = false
	isStriking = false
	currentMode = "IDLE"
	growthSpring.Pos = 0
	growthSpring.Vel = 0
	growthSpring.Target = 0
	postureSpring.Pos = 0
	postureSpring.Vel = 0
	postureSpring.Target = 0

	if uiController then
		uiController.Refresh(false, false, "IDLE")
	end

	task.wait(0.2)
	buildEvolutionAnatomy(newChar)
end)
