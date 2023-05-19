import "CoreLibs/object"
import "CoreLibs/graphics"
import 'CoreLibs/sprites'
import 'CoreLibs/timer'

local pd <const> = playdate
local gfx <const> = pd.graphics

-- Queue implementation 
Queue = {}

function Queue.new(size)
	local queue = table.create(size + 2, 0)
	queue.first = 0
	queue.last = -1
	return queue
end

---@param queue table
---@param value any
function Queue.push(queue, value)
	local last = queue.last + 1
	queue.last = last
	queue[last] = value
end

---@param queue table
---@return any
function Queue.pop(queue)
	local first = queue.first
	if first > queue.last then
		return nil
	end
	local value = queue[first]
	queue[first] = nil
	queue.first = first + 1
	return value
end

-- Particle system
ParticleManager = {}

local maxParticleCount <const> = 300
local queue <const> = Queue
local availableIndexes = nil
local activeIndexes = nil

local x <const> = table.create(maxParticleCount, 0)
local y <const> = table.create(maxParticleCount, 0)
local dX <const> = table.create(maxParticleCount, 0)
local dY <const> = table.create(maxParticleCount, 0)
local particleImage <const> = table.create(maxParticleCount, 0)

function ParticleManager.init()
    availableIndexes = queue.new(maxParticleCount)
    for i=1, maxParticleCount do
        queue.push(availableIndexes, i)
    end
    activeIndexes = table.create(maxParticleCount, 0)
end

function ParticleManager.update(dt)
    for i=#activeIndexes, 1, -1 do
        local pIndex <const> = activeIndexes[i]

        local pX, pY = x[pIndex] + dX[pIndex] * dt, y[pIndex] + dY[pIndex] * dt
        x[pIndex] = pX
        y[pIndex] = pY

        particleImage[pIndex]:draw(pX, pY)
    end
end

function ParticleManager.addParticle(spawnX, spawnY, speedX, speedY, image)
    if #activeIndexes >= maxParticleCount then
        return
    end

    local pIndex <const> = queue.pop(availableIndexes)
    table.insert(activeIndexes, pIndex)

    x[pIndex] = spawnX
    y[pIndex] = spawnY
    dX[pIndex] = speedX
    dY[pIndex] = speedY
    particleImage[pIndex] = image
end

function ParticleManager.removeParticle(pIndex)
    local activeTableIndex = table.indexOfElement(activeIndexes, pIndex)
    if activeTableIndex then
        table.remove(activeIndexes, activeTableIndex)
    end
    queue.push(availableIndexes, pIndex)
end

-- Init particles
local particleCount = 280

local img = gfx.image.new(10, 10)
gfx.pushContext(img)
  gfx.drawCircleAtPoint(5, 5, 4)
gfx.popContext()

local particleManager = ParticleManager
particleManager.init()

for _=1, particleCount do
    local dx, dy = math.random(-30, 30), math.random(-30, 30)
    ParticleManager.addParticle(200, 120, dx, dy, img)
end

-- Constants
local drawFPS = pd.drawFPS
local updateParticles = particleManager.update
local clear = gfx.clear

local getCurTimeMil = pd.getCurrentTimeMilliseconds
local previous_time = nil

function pd.update()
    -- Delta time calculation
    local dt = 0.033
    local current_time <const> = getCurTimeMil()
    if previous_time ~= nil then
        dt = (current_time - previous_time) / 1000.0
    end
    previous_time = current_time

    -- Draw
    clear()
    updateParticles(dt)
    drawFPS(0,0)
end
