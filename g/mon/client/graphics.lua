local graphics = {}

local times = require('g.core.times')
local timeseries = require('g.mon.lib.timeseries')

function graphics.clearScreen(gpu)
  local w, h = gpu.getResolution()
  gpu.fill(1, 1, w, h, " ")
end

function graphics.init(gpu, screen)
  gpu.bind(screen)
  graphics.clearScreen(gpu)

  local w, h = gpu.getResolution()
  gpu.setResolution(w / 2, h / 2)
end

local function drawProgressBar(gpu, px, py, pw, percent)
    percent = math.min(1, math.max(0, percent))
    local fillWidth = math.floor(pw * percent)
    local color
    if percent < 0.1 then color = 0xFF0000
    elseif percent < 0.2 then color = 0xFFFF00
    else color = 0x00FF00 end

    local foreground = gpu.getForeground()
    local background = gpu.getBackground()
    gpu.setForeground(color)
    gpu.setBackground(0x000000)

    for i = 1, pw do
        local char = (i <= fillWidth) and "█" or "·"
        gpu.set(px + i - 1, py, char)
    end

    gpu.setForeground(foreground)
    gpu.setBackground(background)
end

local function drawBorder(gpu, x, y, w, h)
  gpu.set(x, y, "╔")
  gpu.set(x + w - 1, y, "╗")
  gpu.set(x, y + h - 1, "╚")
  gpu.set(x + w - 1, y + h - 1, "╝")
  for i = x + 1, x + w - 2 do
      gpu.set(i, y, "═")
      gpu.set(i, y + h - 1, "═")
  end
  for i = y + 1, y + h - 2 do
      gpu.set(x, i, "║")
      gpu.set(x + w - 1, i, "║")
  end
end

local function drawEnergy(gpu, data, x, y)
  local energy = timeseries.last(data[1]).value
  local capacity = timeseries.last(data[2]).value
  local perc = timeseries.last(data[1]).value / timeseries.last(data[2]).value
  local euT = timeseries.deriv(timeseries.tail(data[1], 10))

  drawBorder(gpu, x, y, 60, 9)
  gpu.set(x + 22, y + 2, 'Energy storage')
  gpu.set(x + 5, y + 4, string.format('EU: %.3fM / %.3fM (%.3f%%), %.3f EU/t', energy / 1000000, capacity / 1000000, perc * 100, euT))
  drawProgressBar(gpu, x + 5, y + 6, 50, perc)
end

local function drawEnvironment(gpu, data, x, y)
  drawBorder(gpu, x, y, 29, 6)

  local ticks = math.fmod(times.ticksFromEpoch() - 6000, 24000)
  local isRain = false

  local nightPointLeft = (isRain) and 12010 or 12542
  local nightPointRight = (isRain) and 23998 or 23477
  local timeName = (ticks >= nightPointLeft and ticks <= nightPointRight) and 'night' or 'day'
  gpu.set(x + 3, y + 2, string.format('Day %.0f, tick %.0f (%s)', times.daysFromEpoch(), ticks, timeName))
  gpu.set(x + 3, y + 3, 'Weather: clear')
end

function graphics.draw(gpu, data)
  graphics.clearScreen(gpu)
  local w, h = gpu.getResolution()
  drawEnergy(gpu, data, 11, 1)
  drawEnvironment(gpu, data, 26, h - 6)
end

return graphics

