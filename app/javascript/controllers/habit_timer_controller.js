import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["display", "startButton", "cancelButton"]
  static values = {
    duration: Number,
    habitId: Number
  }

  connect() {
    this.remainingSeconds = this.durationValue
    this.isRunning = false
    this.audioContext = null
    this.updateDisplay()
  }

  disconnect() {
    this.cancel()
  }

  start() {
    if (this.isRunning) return

    this.isRunning = true
    this.isCountingDown = true
    this.countdownSeconds = 5
    this.remainingSeconds = this.durationValue
    this.startButtonTarget.classList.add("hidden")
    this.cancelButtonTarget.classList.remove("hidden")

    this.countdownTick()
  }

  countdownTick() {
    if (!this.isRunning) return

    // Show countdown number
    this.displayTarget.textContent = this.countdownSeconds
    this.displayTarget.classList.add("text-orange-600", "text-2xl")
    this.playTick()

    if (this.countdownSeconds <= 0) {
      // Countdown finished, start actual timer
      this.isCountingDown = false
      this.displayTarget.classList.remove("text-orange-600", "text-2xl")
      this.tick()
      return
    }

    this.countdownSeconds--
    this.timeout = setTimeout(() => this.countdownTick(), 1000)
  }

  cancel() {
    this.isRunning = false
    this.isCountingDown = false
    if (this.timeout) {
      clearTimeout(this.timeout)
      this.timeout = null
    }
    this.remainingSeconds = this.durationValue
    this.displayTarget.classList.remove("text-orange-600", "text-2xl")
    this.updateDisplay()
    this.startButtonTarget.classList.remove("hidden")
    this.cancelButtonTarget.classList.add("hidden")
  }

  tick() {
    if (!this.isRunning) return

    this.updateDisplay()

    if (this.remainingSeconds <= 0) {
      this.complete()
      return
    }

    // Play tick sound in last 10 seconds
    if (this.remainingSeconds <= 10) {
      this.playTick()
    }

    this.remainingSeconds--
    this.timeout = setTimeout(() => this.tick(), 1000)
  }

  complete() {
    this.isRunning = false
    this.playComplete()

    // Flash the display
    this.displayTarget.classList.add("text-green-600", "animate-pulse")

    // Auto-increment the habit via API
    if (this.hasHabitIdValue) {
      const csrfToken = document.querySelector('meta[name="csrf-token"]')?.content
      fetch(`/habits/${this.habitIdValue}/increment?date=${this.todayDate()}`, {
        method: "POST",
        headers: {
          "X-CSRF-Token": csrfToken,
          "Accept": "text/vnd.turbo-stream.html"
        }
      }).then(response => response.text())
        .then(html => {
          Turbo.renderStreamMessage(html)
        })
    }

    setTimeout(() => {
      this.displayTarget.classList.remove("text-green-600", "animate-pulse")
      this.remainingSeconds = this.durationValue
      this.updateDisplay()
      this.startButtonTarget.classList.remove("hidden")
      this.cancelButtonTarget.classList.add("hidden")
    }, 3000)
  }

  todayDate() {
    const today = new Date()
    const year = today.getFullYear()
    const month = String(today.getMonth() + 1).padStart(2, "0")
    const day = String(today.getDate()).padStart(2, "0")
    return `${year}-${month}-${day}`
  }

  updateDisplay() {
    const minutes = Math.floor(this.remainingSeconds / 60)
    const seconds = this.remainingSeconds % 60
    this.displayTarget.textContent = `${minutes}:${seconds.toString().padStart(2, "0")}`
  }

  getAudioContext() {
    if (!this.audioContext) {
      this.audioContext = new (window.AudioContext || window.webkitAudioContext)()
    }
    return this.audioContext
  }

  playTick() {
    try {
      const ctx = this.getAudioContext()
      const oscillator = ctx.createOscillator()
      const gainNode = ctx.createGain()

      oscillator.connect(gainNode)
      gainNode.connect(ctx.destination)

      oscillator.frequency.value = 800
      oscillator.type = "sine"

      gainNode.gain.setValueAtTime(0.3, ctx.currentTime)
      gainNode.gain.exponentialRampToValueAtTime(0.01, ctx.currentTime + 0.1)

      oscillator.start(ctx.currentTime)
      oscillator.stop(ctx.currentTime + 0.1)
    } catch (e) {
      console.warn("Could not play tick sound:", e)
    }
  }

  playComplete() {
    try {
      const ctx = this.getAudioContext()

      // Play a pleasant completion sound (three ascending tones)
      const frequencies = [523.25, 659.25, 783.99] // C5, E5, G5

      frequencies.forEach((freq, i) => {
        const oscillator = ctx.createOscillator()
        const gainNode = ctx.createGain()

        oscillator.connect(gainNode)
        gainNode.connect(ctx.destination)

        oscillator.frequency.value = freq
        oscillator.type = "sine"

        const startTime = ctx.currentTime + (i * 0.15)
        gainNode.gain.setValueAtTime(0.4, startTime)
        gainNode.gain.exponentialRampToValueAtTime(0.01, startTime + 0.4)

        oscillator.start(startTime)
        oscillator.stop(startTime + 0.4)
      })
    } catch (e) {
      console.warn("Could not play complete sound:", e)
    }
  }
}
