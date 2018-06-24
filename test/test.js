const assert = require('assert')
const fs = require('fs')
const execSync = require('child_process').execSync
let parser

function fixtureTest(name) {
  const query = fs.readFileSync(`${__dirname}/fixtures/${name}.sql`, 'utf8')
  const queryParsed = parser.parse(query)
  assert.deepEqual(parser.parse(query), require(`./fixtures/${name}.json`))
}

describe('parser', function() {
  before(() => {
    execSync('jison cblparser.jison')
    parser = require('../parser')
  })

  it('should parse minimal query', () => {
    fixtureTest('minimal')
  })

  it('should parse sample query', () => {
    fixtureTest('sample')
  })

  it('should parse query with * in select', () => {
    fixtureTest('all')
  })

  it('deep nesting', () => {
    fixtureTest('deep-nesting')
  })

  it('group by expression', () => {
    fixtureTest('group-by')
  })

  it('group by expression with having expression', () => {
    fixtureTest('group-by-having')
  })
})
