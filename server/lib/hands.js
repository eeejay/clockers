const MAX_MOTOR_RPM = 12;

var debug = require('debug')('clockers:hands');
const { spawn } = require('child_process');
const HandsConfig = require('../settings').hands;

class Hand {
  constructor(name, maxValue, gearRatio, rpm, pins) {
    this.name = name;
    this.debug = require('debug')(`clockers:hands:${name}`);
    this.maxValue = maxValue;
    this.gearRatio = gearRatio;
    this.rpm = rpm * gearRatio;
    this.limitPin = pins.limitPin;
    this.motorPins = pins.motorPins;
    this.maxRpm = MAX_MOTOR_RPM;
  }

  startTask(name, cmd, args) {
    return this.stopTask().then(() => {
      return new Promise((resolve, reject) => {
        this.task = spawn(`./bin/${cmd}`, args.map(e => e + ''));
        this.taskName = name;
        this.debug(`${name}::spawn ${cmd} ${args.join(" ")}`);
        this.task.on('exit', (code, signal) => {
          this.debug(`${name}::exit code=${code} signal=${signal}`);
          this.task = null;
          this.taskName = null;
          if (code == 0) {
            resolve();
          } else {
            reject(code);
          }
        });

        this.task.on('error', err => {
          this.debug(`${name}::error:`, err);
          this.task = null;
          reject();
        });

        this.task.stdout.on('data', (data) => {
          this.debug(`${name}::stdout`, data.toString('ascii'));
        });

        this.task.stderr.on('data', (data) => {
          this.debug(`${name}::stderr`, data.toString('ascii'));
        });

      });
    });
  }

  stopTask() {
    return new Promise(resolve => {
      if (!this.task) {
        resolve();
      } else {
        this.task.on("exit", () => {
          this.debug(`Stopped task ${this.taskName}`);
          this.task = null;
          this.taskName
          resolve();
        });
      }
      this.task.kill();
    });
  }

  signalTask(name, signal) {
    if (this.task && this.taskName == name) {
      this.debug(`Sending ${signal} to ${name}`);
      this.task.kill(signal);
    } else {
      this.debug("signal foiled", name, signal);
    }
  }

  start() {
    this.startTask("start", "smoothticker",
      [...this.motorPins, this.limitPin, this.rpm]);
  }

  stop() {
    return this.stopTask();
  }

  zero() {
    return this.startTask("zero", "step",
      [...this.motorPins, this.limitPin, 0, this.maxRpm]);
  }

  goTo(degrees) {
    return this.startTask("goTo", "step",
      [...this.motorPins, -1, degrees, this.maxRpm]);
  }

  setTime(d, catchup, timeToZero) {
    let now = Date.now();

    return this.zero().then(() => {
      let delta = timeToZero || Date.now() - now;
      let value = this.valueFromDate(catchup ? d.clone().add(delta) : d);
      let degrees = this.valueToAngle(value, catchup);
      return this.goTo(degrees);
    });
  }

  adjustForward(degrees) {
    return (degrees * this.maxRpm) / (this.maxRpm - this.rpm);
  }

  valueFromDate(d) { return 0; }

  angleToValue(angle) {
    return (angle / (this.gearRatio*360)) * this.maxValue;
  }

  valueToAngle(value, catchup) {
    let angle = (value / this.maxValue * 360 * this.gearRatio);
    if (catchup) {
      angle = (angle * this.maxRpm) / (this.maxRpm - this.rpm);
    }

    return angle;
  }

  tick(time) {
    if (!this.task && this.taskName != "start") {
      return false;
    }
  }
}

class SecondSmoothHand extends Hand {
  constructor() {
    super("seconds", 60, 2, 1, HandsConfig.seconds);
  }

  valueFromDate(d) {
    return d % 60000 / 1000
  }

  tick(time) {
    if (time.seconds() == 0) {
      this.signalTask("start", "SIGUSR1");
    }
  }

}

class SecondSwissHand extends SecondSmoothHand {
  valueFromDate(d) {
    let v = super.valueFromDate(d);
    let normalized = Math.min(v * (60/57), 57)
    this.debug("valueFromDate", v, "normalized", normalized);
    return normalized;
  }

  start() {
    this.startTask("start", "swissticker",
      [...this.motorPins, this.limitPin, 3]);
  }

  tick(time) {
    if (time.seconds() == 0) {
      this.signalTask("start", "SIGUSR1");
    }
  }
}


class SecondTickHand extends SecondSmoothHand {
  valueToAngle(value, catchup) {
    let v = this.angleToValue(super.valueToAngle(value, catchup));
    return super.valueToAngle(Math.round(v), false);
  }

  start() {
    this.startTask("start", "ticker",
      [...this.motorPins, this.limitPin, this.maxRpm, 6 * this.gearRatio]);
  }

  tick(time) {
    this.signalTask("start", time.seconds() == 0 ? "SIGUSR2" : "SIGUSR1");
  }
}

class MinuteSmoothHand extends Hand {
  constructor() {
    super("minutes", 60, 2, 1/60, HandsConfig.minutes);
  }

  valueFromDate(d) {
    return d.minutes() + d.seconds()/60 + d.milliseconds()/60000;
  }

  tick(time) {
    if (time.seconds() == 0 && time.minutes() == 0) {
      this.signalTask("start", "SIGUSR1");
    }
  }
}

class MinuteTickHand extends MinuteSmoothHand {
  valueToAngle(value, catchup) {
    let v = this.angleToValue(super.valueToAngle(value, catchup));
    return super.valueToAngle(Math.floor(v), false);
  }

  start() {
    this.startTask("start", "ticker",
      [...this.motorPins, this.limitPin, this.maxRpm, 6 * this.gearRatio]);
  }

  tick(time) {
    if (time.seconds() == 0) {
      this.signalTask("start", time.minutes() == 0 ? "SIGUSR2" : "SIGUSR1");
    }
  }

}

class HourSmoothHand extends Hand {
  constructor() {
    super("hours", 12, 2, 1/720, HandsConfig.hours);
  }

  valueFromDate(d) {
    return d.hours() + d.minutes()/60 + d.seconds()/3600 + d.milliseconds()/3600000;
  }

  tick(time) {
    if (time.seconds() == 0 && time.minutes() == 0 && time.hours() % 12 == 0) {
      this.signalTask("start", "SIGUSR1");
    }
  }
}

class HourTickHand extends HourSmoothHand {
  start() {
    this.startTask("start", "ticker",
      [...this.motorPins, this.limitPin, this.maxRpm, 6 * this.gearRatio]);
  }

  tick(time) {
    if (time.seconds() == 0 && time.minutes() % 12 == 0) {
      if (time.minutes() == 0 && time.hours() % 12 == 0 ) {
        this.signalTask("start", "SIGUSR2");
      } else {
        this.signalTask("start", "SIGUSR1");
      }
    }
  }

}

module.exports = {
  SecondSmoothHand,
  SecondTickHand,
  SecondSwissHand,
  MinuteSmoothHand,
  MinuteTickHand,
  HourSmoothHand,
  HourTickHand };
