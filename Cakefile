fs = require 'fs'
{print} = require 'sys'
{spawn} = require 'child_process'

defaultReportFormat = 'spec'
defaultSpecTimeout = 2000 # ms

spawnMocha = ({path, format, timeout, watch}, callback) ->
  format ?= defaultReportFormat
  timeout ?= defaultSpecTimeout
  mochaOpts = ['-t', timeout, '-R', format, 'recursive', '--compilers', 'coffee:coffee-script', '--require', './spec/spec-helper', '--colors', path]
  mochaOpts = ['-w'].concat mochaOpts if watch?
  mochaArgs = { cwd: process.cwd(), env: process.env }
  mocha = spawn './node_modules/.bin/mocha', mochaOpts, mochaArgs
  mocha.stderr.on 'data', (data) -> process.stderr.write data.toString()
  mocha.stdout.on 'data', (data) -> print data.toString()
  mocha.on 'exit', (code) -> callback?() if code is 0

task 'spec', ->  spawnMocha path: 'spec/lib'