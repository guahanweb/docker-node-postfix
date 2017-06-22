#!/usr/bin/node --harmony

const path = require('path');
const fs = require('fs');
const config = require('./config');

const logger = require('./lib/logger').getLogger({
  dir: config.LOG_PATH
});

logger.info('Initialized script with env: ' + JSON.stringify(process.env));
logger.info('Called with args: ' + JSON.stringify(process.argv));
