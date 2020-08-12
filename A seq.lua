--seq prototype

include('midigrid/config/launchpadmini_config')
include('midigrid/lib/midigrid')
local grid = include('midigrid/lib/mg_128')
local g = grid.connect()
music = require 'musicutil'

function go()
  norns.script.load(norns.state.script)
end

function init()
m = midi.connect(1)
view = 1
flash = 1
mode = 2
scale = music.generate_scale_of_length(60, music.SCALES[mode].name,7)
test=1

-- a bunch of nested tables as to use multiple voices
midi_out_channel = {
  1,
  2,
  3,
  4
}
stepcount = {
  7,
  3,
  5,
  8
}
steps = {
  {},
  {},
  {},
  {}
}
active_notes = {
  {},
  {},
  {},
  {}
}
-- used to make each channel a different brightness
-- should rename to something more fitting
ch = {
  5,
  6,
  9,
  14
} 
position = {
  1,
  1,
  1,
  1
}
-- generate random seq on startup
for n=1,4 do
  for i=1,stepcount[n] do 
    for s = 1,4 do
      table.insert(steps[s], math.random(7))
    end  
   end
  end
end

g.key = function(x,y,z)
-- select whitch channel is being displayed on grid
-- 1=all, 2=1, 3=2, etc..
  for i = 1,5 do
    if z == 1 and x == i and y == 8 then
      view = x
    end
  end
-- create new seq in the current selected channel
  for i = 2,5 do
    if view == i then
      if z == 1 and y <= 7 then
      steps[i-1][x] = y
      g:refresh()
      end
    end 
  end  
end

function g_redraw()
  g:all(0)
-- if view = 1 display all channels
  if view == 1 then
    for v=1,4 do
     for i=1,stepcount[v] do
     g:led(i,steps[v][i],i==position[v] and 15 or ch[v])
        end
     end
-- else display only selected channel
  elseif view >= 2 and view <= 5 then
      for i=1,stepcount[view-1] do
    g:led(i,steps[view-1][i],i==position[view-1] and 15 or ch[view-1])
      end
  end  
  -- indicate all channels being displayed
  if view == 1 then  
    if flash == 1 then
     g:led(1,8,13)
    else
      g:led(1,8,0)
    end
  else
    g:led(1,8,13)
  end  
  -- indicate current displayed channel 
  for i = 2, 5 do
    if view == i then
      if flash == 1 then
      g:led(i,8,12)
    else
      g:led(i,8,0)  
      end
    else
      g:led(i,8,test)
    end  
  end  
  g:refresh()
end
-- create blinking light that can be used to show active buttons
function indicate()
  if flash == 0 then flash = 1
  else flash = 0
  end
end
-- Thanks Awake!
function all_notes_off(target)
    for _, a in pairs(active_notes[target]) do
      m:note_off(a, nil, midi_out_channel[target])
    end
  active_notes[target] = {}
end

function iterate()
-- clear voices & play steps
-- instead of creating a thousand voices, I used nested tables to hold the information for each voice and just ittarating through them
-- i = 1,4 can be canged to i = 1,#of_voices and a function can be mabe to nest a new table to each of the necessary tables creating a new voice   
  for i = 1,4 do
    all_notes_off(i)
    m:note_on(scale[steps[i][position[i]]] ,127,midi_out_channel[i])
    table.insert(active_notes[i],scale[steps[i][position[i]]] )
    position[i] = (position[i] % stepcount[i]) + 1
  end
  indicate()
  g_redraw()
  g:refresh()
end

function pulse()
   while true do
    clock.sync(1/1)
    iterate()
  end
end

clock.run(pulse)
-- cleanup not working propperly yet
function cleanup()
  all_notes_off(1)
  all_notes_off(2)
  all_notes_off(3)
  all_notes_off(4)
  
  g:all(0)
  g:refresh()
  
end
