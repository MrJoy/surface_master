#!/usr/bin/env ruby
# https://github.com/arirusso/topaz
# https://github.com/arirusso/micromidi
require "unimidi"
input = UniMIDI::Input.find { |device| device.name.match(/Numark ORBIT/) }.open
output = UniMIDI::Output.find { |device| device.name.match(/Numark ORBIT/) }.open
# output = UniMIDI::Output.find_by_name("- Numark ORBIT").open

msg1 = [0xF0,
        0x00, 0x01, 0x3F, 0x2B,
        0x03, 0x01, 0x70,

        0x00, 0x00, 0x00,
        0x00, 0x04, 0x04,
        0x00, 0x08, 0x08,
        0x00, 0x0C, 0x0C,
        0x00, 0x01, 0x01,
        0x00, 0x05, 0x05,
        0x00, 0x09, 0x09,
        0x00, 0x0D, 0x0D,
        0x00, 0x02, 0x02,
        0x00, 0x06, 0x06,
        0x00, 0x0A, 0x0A,
        0x00, 0x0E, 0x0E,
        0x00, 0x03, 0x03,
        0x00, 0x07, 0x07,
        0x00, 0x0B, 0x0B,
        0x00, 0x0F, 0x0F,

        0x01, 0x00, 0x10,
        0x01, 0x04, 0x14,
        0x01, 0x08, 0x18,
        0x01, 0x0C, 0x1C,
        0x01, 0x01, 0x11,
        0x01, 0x05, 0x15,
        0x01, 0x09, 0x19,
        0x01, 0x0D, 0x1D,
        0x01, 0x02, 0x12,
        0x01, 0x06, 0x16,
        0x01, 0x0A, 0x1A,
        0x01, 0x0E, 0x1E,
        0x01, 0x03, 0x13,
        0x01, 0x07, 0x17,
        0x01, 0x0B, 0x1B,
        0x01, 0x0F, 0x1F,

        0x02, 0x00, 0x20,
        0x02, 0x04, 0x24,
        0x02, 0x08, 0x28,
        0x02, 0x0C, 0x2C,
        0x02, 0x01, 0x21,
        0x02, 0x05, 0x25,
        0x02, 0x09, 0x29,
        0x02, 0x0D, 0x2D,
        0x02, 0x02, 0x22,
        0x02, 0x06, 0x26,
        0x02, 0x0A, 0x2A,
        0x02, 0x0E, 0x2E,
        0x02, 0x03, 0x23,
        0x02, 0x07, 0x27,
        0x02, 0x0B, 0x2B,
        0x02, 0x0F, 0x2F,

        0x03, 0x00, 0x30,
        0x03, 0x04, 0x34,
        0x03, 0x08, 0x38,
        0x03, 0x0C, 0x3C,
        0x03, 0x01, 0x31,
        0x03, 0x05, 0x35,
        0x03, 0x09, 0x39,
        0x03, 0x0D, 0x3D,
        0x03, 0x02, 0x32,
        0x03, 0x06, 0x36,
        0x03, 0x0A, 0x3A,
        0x03, 0x0E, 0x3E,
        0x03, 0x03, 0x33,
        0x03, 0x07, 0x37,
        0x03, 0x0B, 0x3B,
        0x03, 0x0F, 0x3F,

        0x00, 0x00, 0x01,
        0x00, 0x02, 0x00,
        0x03, 0x00, 0x00,
        0x01, 0x01, 0x01,
        0x02, 0x01, 0x03,
        0x01, 0x00, 0x02,
        0x01, 0x02, 0x02,
        0x02, 0x03, 0x02,
        0x00, 0x03, 0x01,
        0x03, 0x02, 0x03,
        0x03, 0x03, 0x0C,
        0x00, 0x0D, 0x00,
        0x0C, 0x00, 0x0D,
        0x00, 0x0C, 0x00,
        0x0D, 0x00, 0x0C,
        0x00, 0x0D, 0x00,
        0xF7]
msg2 = [0xF0,
        0x00, 0x01, 0x3F, 0x2B,
        0x01, 0x00, 0x00,
        0xF7]
# Skip Sysex begin, vendor header, command code, aaaaand sysex end.
expected_state = msg1[6..-2]
output.puts(msg1)
# sleep 0.05
output.puts(msg2)
current_state = nil
started_at    = Time.now.to_f
attempts      = 1
loop do
  if input.buffer.length == 0
    elapsed = Time.now.to_f - started_at
    if elapsed > 4.0
      puts "\nGiving up!  Your controller may be in a bad way!"
      break
    elsif elapsed > (1.0 * attempts)
      puts "\nTrying again!"
      attempts += 1
      output.puts(msg2)
      next
    end
    printf "."
    sleep 0.01
    next
  end
  raw             = input.gets
  current_state   = raw.find { |ii| ii[:data][0] == 0xF0 }
  break unless current_state.nil?
end

if current_state
  current_state = current_state[:data][6..-2].dup
  puts "\nGot state info from controller!"
  if expected_state != current_state
    puts "UH OH!  State didn't match up!"
    puts expected_state.inspect
    puts current_state.inspect
  else
    puts "Your controller should match expectations!"
  end
end

puts "Waiting on you..."
loop do
  if input.buffer.length == 0
    sleep 0.01
    next
  end
  result = input.gets

  puts result.shift.inspect while result.length > 0
end
# puts "Trying again..."
# sleep 0.1
# output.puts(msg1)

input.close
output.close