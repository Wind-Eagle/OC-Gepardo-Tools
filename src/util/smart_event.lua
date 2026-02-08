local smart_event = {}

local event = require("event")

local smart_require = require("util.smart_require")
local smart_event_data = require("util.smart_event_data")

local pid = smart_require.reload("util.pid")

smart_event.event_listener_event_type = "event_listener_event"
smart_event.main_thread_interrupted = "main_thread_interrupted"

local function eventHandlerCallback(eventHandlerFunction, exitOnError)
    return function(...)
        local _ = xpcall(eventHandlerFunction, function(err)
            if exitOnError then
                event.push(smart_event.main_thread_interrupted, false, err)
            else
                print(err)
                print(debug.traceback())
            end
        end, ...)
    end
end

local processId = pid.getPid()
smart_event_data.registerPid(processId)

local event_listeners = smart_event_data.event_listeners[processId]
local event_timers = smart_event_data.event_timers[processId]

local registered_event_listeners = smart_event_data.registered_event_listeners[processId]
local registered_event_timers = smart_event_data.registered_event_timers[processId]

function smart_event.listen(eventName, callback, exitOnError)
    event_listeners[#event_listeners + 1] = {eventName, callback, exitOnError}
    event.push(smart_event.event_listener_event_type)
end

function smart_event.timer(eventTime, callback, exitOnError)
    event_timers[#event_timers + 1] = {eventTime, callback, exitOnError}
    event.push(smart_event.event_listener_event_type)
end

function smart_event.drain()
    local listeners = event_listeners
    event_listeners = {}
    for _, pair in ipairs(listeners) do
        local eventName, callback, exitOnError = pair[1], pair[2], pair[3]
        local callbackProtected = eventHandlerCallback(callback, exitOnError)
        event.listen(eventName, callbackProtected)
        registered_event_listeners[#registered_event_listeners + 1] = {eventName, callbackProtected}
    end

    local timers = event_timers
    event_timers = {}

    for _, pair in ipairs(timers) do
        local eventTime, callback, exitOnError = pair[1], pair[2], pair[3]
        local timerId = event.timer(eventTime, eventHandlerCallback(callback, exitOnError), math.huge)
        registered_event_timers[#registered_event_timers + 1] = timerId
    end
end

function smart_event.unregister()
    for _, pair in ipairs(registered_event_listeners) do
        local eventName, callback = pair[1], pair[2]
        event.ignore(eventName, callback)
    end

    for _, timerId in ipairs(registered_event_timers) do
        event.cancel(timerId)
    end

    smart_event_data.unregisterPid(processId)
end

return smart_event
