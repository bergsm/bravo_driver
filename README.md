# Bravo Lite LEDs

X-Plane 12 Lua driver for the [Honeycomb Bravo Lite](https://honeycomb-aerospace.com/) throttle quadrant, controlling its LED indicators based on aircraft gear and battery status.

## Features

- **Gear Position LEDs**: Illuminates LEDs to reflect the position of left, center, and right landing gear (stowed, transitioning, or deployed).
- **Hardware Auto-Discovery**: Automatically scans `/sys/class/hidraw` to find the Bravo Lite on boot.
- **Self-Healing**: Detects when the device is unplugged and re-discovers it automatically.
- **Shutdown Handler**: Turns off all LEDs gracefully when X-Plane exits.

## Requirements

- [X-Plane 12](https://www.x-plane.com/)
- Honeycomb Bravo Lite throttle quadrant
- Lua's `ffi` library (included with X-Plane's Lua environment)
- Linux (uses `hidraw` for HID device access)
- udev rule for device permissions (`99-honeycomb.rules`)

## Installation

### 1. Install the udev rule (Linux)

Copy the udev rule to allow access to the Bravo Lite device:

```bash
sudo cp 99-honeycomb.rules /etc/udev/rules.d/
sudo udevadm control --reload-rules
sudo udevadm trigger
```

### 2. Install the Lua script

Copy `bravo_lite_leds.lua` into your X-Plane `Resources/plugins` directory.

### 3. Start X-Plane

The script will auto-discover the Bravo Lite and begin updating the LEDs.

## How It Works

The script uses FFI to communicate directly with the Bravo Lite via the Linux `hidapi` HID raw interface. It reads X-Plane datarefs for gear and battery status, then sends feature report commands to control the device's LED pattern.

## License

This project is licensed under the [MIT License](LICENSE).
