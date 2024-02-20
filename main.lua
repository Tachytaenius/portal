local mathsies = require("lib.mathsies")
local vec2 = mathsies.vec2
local vec3 = mathsies.vec3
local quat = mathsies.quat
local mat4 = mathsies.mat4

local vertexFormat = {
	{"VertexPosition", "float", 3},
	{"VertexTexCoord", "float", 2},
	{"VertexNormal", "float", 3},
	-- {"VertexTangent", "float", 3},
	-- {"VertexBitangent", "float", 3}
}

local tau = math.pi * 2

local portalShader

local camera, portal
local time
local portalWidth, portalHeight = 1, 2
local portalBobHeight = 0.05
local portalBobSpeed = 1.25

local swirlChangeFrequency = tau * 4
local swirlChangeAmplitude = 0.125
local swirlChangeSlope = 10
local swirlSpeedMultiplier = 0.125

local colour1ZShiftRate = 0.5
local colour2ZShiftRate = 0.75
local colour3ZShiftRate = 0.25

local colour1SwirlTimeMultiplier = 0.5
local colour1SwirlResetTime = 5
local colour1SwirlResetLerpLength = 2

local colour2SwirlResetTime = 4
local colour2SwirlResetLerpLength = 1.5

local function lerp(a, b, i)
	return a + i * (b - a)
end

-- Used to transform normals
local function normalMatrix(modelToWorld)
	local m = mat4.transpose(mat4.inverse(modelToWorld))
	return
		m._00, m._01, m._02,
		m._10, m._11, m._12,
		m._20, m._21, m._22
end

local function hsv2rgb(h, s, v)
	if s == 0 then
		return v, v, v
	end
	local _h = h / 60
	local i = math.floor(_h)
	local f = _h - i
	local p = v * (1 - s)
	local q = v * (1 - f * s)
	local t = v * (1 - (1 - f) * s)
	if i == 0 then
		return v, t, p
	elseif i == 1 then
		return q, v, p
	elseif i == 2 then
		return p, v, t
	elseif i == 3 then
		return p, q, v
	elseif i == 4 then
		return t, p, v
	elseif i == 5 then
		return v, p, q
	end
end

function love.load()
	-- love.graphics.setDepthMode("lequal", true)
	-- love.graphics.setFrontFaceWinding("ccw")

	camera = {
		position = vec3(0, 0, -2.5),
		orientation = quat(),
		verticalFov = math.rad(70),
		nearPlaneDistance = 0.001,
		farPlaneDistance = 1000,
		speed = 100,
		angularSpeed = tau * 0.5
	}
	local vertices = {}
	local numVertices = 256
	for i = 0, numVertices - 1 do
		local angle = i / numVertices * tau
		local s, c = math.sin(angle), math.cos(angle)
		local x = c * portalWidth / 2
		local y = s * portalHeight / 2
		local largestSide = math.max(portalWidth, portalHeight)
		vertices[#vertices + 1] = {
			x, y, 0,
			y / largestSide + 0.5, x / largestSide + 0.5,
			0, 0, 1
		}
	end
	local mesh = love.graphics.newMesh(vertexFormat, vertices, "fan", "static")
	portal = {
		mesh = mesh,
		position = vec3(),
		orientation = quat()
	}

	time = 0

	portalShader = love.graphics.newShader("shaders/portal.glsl")
end

function love.update(dt)
	local speed = 5
	local translation = vec3()
	if love.keyboard.isDown("w") then translation.z = translation.z + speed end
	if love.keyboard.isDown("s") then translation.z = translation.z - speed end
	if love.keyboard.isDown("a") then translation.x = translation.x - speed end
	if love.keyboard.isDown("d") then translation.x = translation.x + speed end
	if love.keyboard.isDown("q") then translation.y = translation.y + speed end
	if love.keyboard.isDown("e") then translation.y = translation.y - speed end
	camera.position = camera.position + vec3.rotate(translation, camera.orientation) * dt

	local angularSpeed = tau / 4
	local rotation = vec3()
	if love.keyboard.isDown("j") then rotation.y = rotation.y - angularSpeed end
	if love.keyboard.isDown("l") then rotation.y = rotation.y + angularSpeed end
	if love.keyboard.isDown("i") then rotation.x = rotation.x + angularSpeed end
	if love.keyboard.isDown("k") then rotation.x = rotation.x - angularSpeed end
	if love.keyboard.isDown("u") then rotation.z = rotation.z - angularSpeed end
	if love.keyboard.isDown("o") then rotation.z = rotation.z + angularSpeed end
	camera.orientation = quat.normalise(camera.orientation * quat.fromAxisAngle(rotation * dt))

	local posXY = vec2.fromAngle(time * portalBobSpeed) * vec2(0.0, portalBobHeight / 2)
	portal.position = vec3(posXY.x, posXY.y, 0)

	time = time + dt
end

function love.draw()
	love.graphics.setShader(portalShader)

	local baseTextureColour = {hsv2rgb((time * 30) % 360, 0.6, 2)}
	baseTextureColour[4] = 1
	local projectionMatrix = mat4.perspectiveLeftHanded(
		love.graphics.getWidth() / love.graphics.getHeight(),
		camera.verticalFov,
		camera.farPlaneDistance,
		camera.nearPlaneDistance
	)
	local cameraMatrix = mat4.camera(camera.position, camera.orientation)

	portalShader:send("time", time)
	portalShader:send("aspectRatio", portalHeight / portalWidth)

	portalShader:send("swirlChangeFrequency", swirlChangeFrequency)
	portalShader:send("swirlChangeAmplitude", swirlChangeAmplitude)
	portalShader:send("swirlChangeSlope", swirlChangeSlope)
	portalShader:send("swirlSpeedMultiplier", swirlSpeedMultiplier)

	portalShader:send("colour1ZShiftRate", colour1ZShiftRate)
	portalShader:send("colour2ZShiftRate", colour2ZShiftRate)
	portalShader:send("colour3ZShiftRate", colour3ZShiftRate)

	portalShader:send("colour1SwirlTimeMultiplier", colour1SwirlTimeMultiplier)
	portalShader:send("colour1SwirlResetTime", colour1SwirlResetTime)
	portalShader:send("colour1SwirlResetLerpLength", colour1SwirlResetLerpLength)

	portalShader:send("colour2SwirlResetTime", colour2SwirlResetTime)
	portalShader:send("colour2SwirlResetLerpLength", colour2SwirlResetLerpLength)

	-- love.graphics.setColor(0.125, 0.125, 1, 0.5)
	-- portalShader:send("modelToScreen", {mat4.components(projectionMatrix * cameraMatrix * mat4.transform(portal.position + vec3(0, 0, -0.1), portal.orientation, vec3(1.1)))})
	-- love.graphics.draw(portal.mesh)

	-- love.graphics.setColor(0.125, 1, 0.125, 0.5)
	-- portalShader:send("modelToScreen", {mat4.components(projectionMatrix * cameraMatrix * mat4.transform(portal.position + vec3(0, 0, -0.15), portal.orientation, vec3(1.2)))})
	-- love.graphics.draw(portal.mesh)

	-- love.graphics.setColor(1, 0.125, 0.125, 0.5)
	-- portalShader:send("modelToScreen", {mat4.components(projectionMatrix * cameraMatrix * mat4.transform(portal.position + vec3(0, 0, -0.175), portal.orientation, vec3(1.3)))})
	-- love.graphics.draw(portal.mesh)

	love.graphics.setColor(1, 1, 1)
	portalShader:send("modelToScreen", {mat4.components(projectionMatrix * cameraMatrix * mat4.transform(portal.position, portal.orientation))})
	love.graphics.draw(portal.mesh)

	love.graphics.setShader()
end
