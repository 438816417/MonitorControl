//
//  Display.swift
//  MonitorControl
//
//  Created by Guillaume BRODER on 02/01/2018.
//  MIT Licensed.
//

import Cocoa

/// A display
class Display {
	let identifier: CGDirectDisplayID
	let name: String
	let serial: String
	var isEnabled: Bool
	var isMuted: Bool = false
	var brightnessSliderHandler: SliderHandler?
	var volumeSliderHandler: SliderHandler?
	var contrastSliderHandler: SliderHandler?

	private let prefs = UserDefaults.standard

	init(_ identifier: CGDirectDisplayID, name: String, serial: String, isEnabled: Bool = true) {
		self.identifier = identifier
		self.name = name
		self.serial = serial
		self.isEnabled = isEnabled
	}

	func mute() {
		var value = 0
		if isMuted {
			value = prefs.integer(forKey: "\(AUDIO_SPEAKER_VOLUME)-\(identifier)")
			isMuted = false
		} else {
			isMuted = true
		}

		Utils.sendCommand(AUDIO_SPEAKER_VOLUME, toMonitor: identifier, withValue: value)
		if let slider = volumeSliderHandler?.slider {
			slider.intValue = Int32(value)
		}
		showOsd(command: AUDIO_SPEAKER_VOLUME, value: value)
	}

	func setVolume(to value: Int) {
		if value > 0 {
			isMuted = false
		}

		Utils.sendCommand(AUDIO_SPEAKER_VOLUME, toMonitor: identifier, withValue: value)
		if let slider = volumeSliderHandler?.slider {
			slider.intValue = Int32(value)
		}
		showOsd(command: AUDIO_SPEAKER_VOLUME, value: value)
		saveValue(value, for: AUDIO_SPEAKER_VOLUME)
	}

	func setBrightness(to value: Int) {
		Utils.sendCommand(BRIGHTNESS, toMonitor: identifier, withValue: value)
		if let slider = brightnessSliderHandler?.slider {
			slider.intValue = Int32(value)
		}
		showOsd(command: BRIGHTNESS, value: value)
		saveValue(value, for: BRIGHTNESS)
	}

    func setContrast(to value: Int) {
        Utils.sendCommand(CONTRAST, toMonitor: identifier, withValue: value)
        if let slider = contrastSliderHandler?.slider {
            slider.intValue = Int32(value)
        }
        saveValue(value, for: CONTRAST)
    }

    func calcNewValue(for command: Int32, withRel rel: Int) -> Int {
        let maxValue = command == CONTRAST ? 70 : 100
		let currentValue = prefs.integer(forKey: "\(command)-\(identifier)")
		return max(0, min(maxValue, currentValue + rel))
	}

	func saveValue(_ value: Int, for command: Int32) {
		prefs.set(value, forKey: "\(command)-\(identifier)")
	}

    func readValue(for command: Int32) -> Int {
        return prefs.integer(forKey: "\(command)-\(identifier)")
    }

	private func showOsd(command: Int32, value: Int) {
		if let manager = OSDManager.sharedManager() as? OSDManager {
			var osdImage: Int64 = 1 // Brightness Image
			if command == AUDIO_SPEAKER_VOLUME {
				osdImage = 3 // Speaker image
				if isMuted {
					osdImage = 4 // Mute speaker
				}
			}
			let step = 100/16
			manager.showImage(osdImage,
							  onDisplayID: identifier,
							  priority: 0x1f4,
							  msecUntilFade: 2000,
							  filledChiclets: UInt32(value/step),
							  totalChiclets: UInt32(100/step),
							  locked: false)
		}
	}
}
