global.localEnvironment = 'test' 

// default redis url and client
global.redisURL=  process.env.REDIS_URL || process.env.REDISTOGO_URL || 'redis://127.0.0.1:6379/'

global.chai       = require('chai');
global.Charlatan  = require('charlatan');

chaiSpies = require('chai-spies');
chai.use(chaiSpies);

chaiFactories = require('chai-factories')
chai.use(chaiFactories);

global.should = chai.should();
global.expect = chai.expect;
global.assert = chai.assert;
