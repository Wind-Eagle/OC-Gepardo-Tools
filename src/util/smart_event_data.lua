local smart_event_data = {}

smart_event_data.event_listeners = {}
smart_event_data.event_timers = {}

smart_event_data.registered_event_listeners = {}
smart_event_data.registered_event_timers = {}

function smart_event_data.registerPid(pid)
    if smart_event_data.event_listeners[pid] == nil then
        smart_event_data.event_listeners[pid] = {}
        smart_event_data.event_timers[pid] = {}
        smart_event_data.registered_event_listeners[pid] = {}
        smart_event_data.registered_event_timers[pid] = {}
    end
end

function smart_event_data.unregisterPid(pid)
    smart_event_data.event_listeners[pid] = nil
    smart_event_data.event_timers[pid] = nil
    smart_event_data.registered_event_listeners[pid] = nil
    smart_event_data.registered_event_timers[pid] = nil
end

return smart_event_data
