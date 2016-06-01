const express = require('express');
const router = express.Router();
const exec = require('child_process').exec;
const debug = require('debug')('clockers:control');
const movementTypes = require('../settings').movements;

var clock = require('../lib/clock');

router.get('/timezones', function(req, res, next) {
  res.json(clock.timezones);
});

router.get('/movements', function(req, res, next) {
  res.json(clock.movements);
});

router.get('/clocktime', function(req, res, next) {
  let time = clock.tickerTime;
  res.json({
    hours: tickerTime.hours(),
    minutes: tickerTime.minutes(),
    seconds: tickerTime.seconds()});
});

router.get('/zero', function(req, res, next) {
  clock.zero();
  res.json({ status: "ok" });
});

router.get('/adjust', function(req, res, next) {
  clock.start();
  res.json({ status: "ok" });
});

router.post("/adjust", function(req, res) {
  let oldMovement = clock.config.movement;
  clock.setConfig(req.body).then(() => {
    if (oldMovement != clock.config.movement) {
      clock.setupMovement().then(() => {
        clock.start();
        res.json({ status: "ok" });
      });
    } else {
      clock.start();
      res.json({ status: "ok" });
    }
  });
});

router.get('/shutdown', function(req, res, next) {
  exec("shutdown now");
  res.json({ status: "ok" });
});

router.get('/reboot', function(req, res, next) {
  exec("reboot");
  res.json({ status: "ok" });
});

module.exports = router;
