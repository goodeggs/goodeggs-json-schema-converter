expect = require('chai').expect
mongoose = require 'mongoose'
converter = require '..'

describe 'toMongooseSchema', ->
  it 'throws if setting an array of types', ->
    schema =
      type: 'object'
      properties:
        age: {type: ['number', 'null', 'string']}
    expect(-> converter.toMongooseSchema(schema, mongoose)).to.throw 'Arrays with multiple types'

  it 'converts a schema', ->
    schema =
      type: 'object'
      required: ['name']
      properties:
        name: {type: 'string'}
        # null ignored, b/c any value can be set to null with mongoose
        age: {type: ['number', 'null'], minimum: 1, maximum: 100}
        subscribed: {type: ['null', 'boolean'], default: false}
        role: {type: 'string', enum: ['manager', 'employee']}
        badges:
          type: 'array'
          items:
            type: 'object'
            required: ['number']
            properties:
              number: {type: 'integer'}
        forms:
          type: 'array'
          items:
            type: 'object'
            properties:
              _id: {type: 'string', format: 'objectid'}
              name: {type: 'string'}

    result = converter.toMongooseSchema(schema, mongoose)
    expect(result.tree._id).not.to.be.ok
    expect(result.tree.name).to.deep.equal { required: true, type: String }
    expect(result.tree.age).to.deep.equal { min: 1, max: 100, type: Number }
    expect(result.tree.subscribed).to.deep.equal { default: false, type: Boolean }
    expect(result.tree.role).to.deep.equal { type: String, enum: ['manager', 'employee'] }
    expect(result.tree.badges[0].tree._id).not.to.be.ok
    expect(result.tree.badges[0].tree.number).to.deep.equal { type: Number, required: true }
    expect(result.tree.forms[0].tree._id).to.deep.equal { type: mongoose.Schema.ObjectId }
    expect(result.tree.forms[0].tree.name).to.deep.equal { type: String }
