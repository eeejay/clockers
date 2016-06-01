const hands = require("./hands");
const moment = require('moment-timezone');
const debug = require('debug')('clockers:clock');
const jsonfile = require('jsonfile');
const movementTypes = require('../settings').movements;

const CONFIG_PATH = require('path').resolve(__dirname, "../.config.json");

class Clock {
  constructor() {
    debug("new clock");
    this.hands = [];
    try {
      this.config = jsonfile.readFileSync(CONFIG_PATH);
    } catch (e) {
      if (e.code != "ENOENT") {
        throw e;
      }
      this.config = {
        customOffset: 0,
        timezone: moment.tz.guess(),
        movement: "smooth"
      };
      jsonfile.writeFileSync(CONFIG_PATH, this.config, {spaces: 2});
    }
    this._tickStartTimeout = 0;
    this.setupMovement().then(() => {
      this.start();
    });
  }

  get timezones() {
    return { all: moment.tz.names(), selected: this.config.timezone };
  }

  get movements() {
    return { all: movementTypes, selected: this.config.movement };
  }

  setupMovement() {
    let type = this.config.movement || "smooth";
    if (!movementTypes[type]) {
      throw new Error(`Movement ${type} does not exist.`);
    }
    return Promise.all(this.hands.map(h => h.stop())).then(() => {
      this.hands = movementTypes[type].handTypes.map(cls => new hands[cls]());
    });
  }

  zero() {
    return Promise.all(this.hands.map(h => h.zero()));
  }

  setConfig(config) {
    for (let setting in config) {
      this.config[setting] = config[setting];
    }

    return new Promise((resolve, reject) => {
      jsonfile.writeFile(CONFIG_PATH, this.config, {spaces: 2}, (err)  => {
        if (err) {
          reject(err);
        } else {
          debug("setConfig", JSON.stringify(this.config));
          resolve();
        }
      });
    });
  }

  setTime(time, catchup) {
    debug("Setting time to " + time.format('h:m:s a z'));
    return Promise.all(this.hands.map(h => {
      h.setTime(time, catchup).then(() => h.start());
    }));
  }

  startTicker() {
    clearTimeout(this._tickStartTimeout);
    let isDST = this.getOurMoment().isDST();
    let ticker = () => {
      let now = this.getOurMoment();
      let newDST = now.isDST();
      if (isDST != newDST) {
        this.start();
      } else {
        isDST = newDST;
        this._tickStartTimeout = setTimeout(ticker, 1000 - now.milliseconds());
        this.tick(now);
      }
    };
    this._tickStartTimeout = setTimeout(ticker, 1000 - Date.now() % 1000);
  }

  tick(now) {
    if (now.seconds() == 0) {
      debug(now.format('hh:mm:ss a z'), "actual", Date());
    }
    this.hands.map(h => h.tick(now));
  }

  start() {
    // TODO: Load saved prefs
    debug(Date());
    let now = this.getOurMoment();
    this.setTime(now, true);
    debug("starting ticker", now.format('h:m:s a z'), "actual", Date());
    this.startTicker();
  }

  getOurMoment() {
    return this.config.customOffset ?
      moment.utc().add(this.config.customOffset) :
      moment.tz(this.config.timezone);
  }
}

module.exports = new Clock();
