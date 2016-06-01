var express = require('express');
var path = require('path');
var logger = require('morgan');
var bodyParser = require('body-parser');
var debug = require('debug')('clockers:app');

var control = require('./routes/control');

var app = express();

// view engine setup
app.set('views', path.join(__dirname, 'views'));
app.set('view engine', 'pug');

app.use(logger('dev'));
app.use(bodyParser.json());
app.use(express.static(path.join(__dirname, 'public')));

app.use('/control', control);

// catch 404 and forward to error handler
app.use(function(req, res, next) {
  var err = new Error('Not Found');
  err.status = 404;
  next(err);
});

// error handlers

app.use(function(err, req, res, next) {
  res.status(err.status || 500).send('<p>something blew up</p>');
});

module.exports = { app: app };
