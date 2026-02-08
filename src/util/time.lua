local time = {}

function time.getTicksFromEpoch()
    return math.floor(os.time() / 60 / 60 * 1000 + 0.5)
end

return time
