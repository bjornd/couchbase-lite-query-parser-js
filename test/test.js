const assert = require('assert')
const fs = require('fs')
const execSync = require('child_process').execSync
let parser

function fixtureTest(name) {
  const query = fs.readFileSync(`${__dirname}/fixtures/${name}.sql`, 'utf8')
  const queryParsed = parser.parse(query)
  assert.deepStrictEqual(parser.parse(query), require(`./fixtures/${name}.json`))
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

  it('order by expression', () => {
    fixtureTest('order-by')
  })

  it('limit and offset', () => {
    fixtureTest('limit-offset')
  })

  it('distinct', () => {
    fixtureTest('distinct')
  })

  it('join', () => {
    fixtureTest('join')
  })

  it('logical operators', () => {
    fixtureTest('logical-operators')
  })

  it('arithmetic operators', () => {
    fixtureTest('arithmetic-operators')
  })

  it('relational operators', () => {
    fixtureTest('relational-operators')
  })

  it('between operator', () => {
    fixtureTest('between')
  })

  it('match', () => {
    fixtureTest('match')
  })

  it('like', () => {
    fixtureTest('like')
  })

  it('null and missing', () => {
    fixtureTest('null-missing')
  })

  it('array operators', () => {
    fixtureTest('array')
  })

  it('in', () => {
    fixtureTest('in')
  })
})
