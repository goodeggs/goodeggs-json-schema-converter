module.exports.toMongooseSchema = (JSONSchema, mongoose) ->
  types =
    "string": String
    "integer": Number
    "number": Number
    "boolean": Boolean

  formats =
    "objectid": -> mongoose.Schema.ObjectId
    "date-time": -> Date

  propertiesMappings =
    "enum":  "enum"
    "default":  "default"
    "maximum":  "max"
    "minimum":  "min"

  convert = (JSONSchemaConfig, required = false) ->
    JSONSchemaConfigType =
      if Array.isArray(JSONSchemaConfig.type) and JSONSchemaConfig.type.length is 2 and 'null' in JSONSchemaConfig.type
        JSONSchemaConfig.type.splice(JSONSchemaConfig.type.indexOf('null'), 1)
        JSONSchemaConfig.type[0]
      else if Array.isArray(JSONSchemaConfig.type)
        throw new Error "Cannot convert type: [#{JSONSchemaConfig.type}]. Arrays with multiple types (except for arrays of 2 with a single 'null') are not supported by json schema converter"
      else
        JSONSchemaConfig.type

    if JSONSchemaConfigType is 'object'
      mongooseConfig = {}
      for property, childJSONSchemaConfig of JSONSchemaConfig.properties
        unless property is '__v'
          isRequired = JSONSchemaConfig.required?.length and property in JSONSchemaConfig.required
          mongooseConfig[property] = convert(childJSONSchemaConfig, isRequired)
      return mongooseConfig

    else if JSONSchemaConfigType is 'array'

      # array of documents w/o _id
      if JSONSchemaConfig.items.type is 'object' and not JSONSchemaConfig.items.properties._id?
        delete JSONSchemaConfig.items.properties._id
        return [new mongoose.Schema(convert(JSONSchemaConfig.items), {_id: false})]

      # array of documents w/ _id
      else if JSONSchemaConfig.items.type is 'object'
        return [new mongoose.Schema(convert(JSONSchemaConfig.items))]

      # array of primitives
      else
        return [convert(JSONSchemaConfig.items)]

    else # primitives
      mongooseConfig = {}
      mongooseConfig.type = types[JSONSchemaConfigType]
      mongooseConfig.type = formats[JSONSchemaConfig.format]() if formats[JSONSchemaConfig.format]?()
      mongooseConfig.required = true if required
      for jsonSchemaProperty, mongooseProperty of propertiesMappings
        mongooseConfig[mongooseProperty] = JSONSchemaConfig[jsonSchemaProperty] if JSONSchemaConfig[jsonSchemaProperty]?
      return mongooseConfig

  if not JSONSchema.properties._id?
    config = {_id: false}

  else
    delete JSONSchema.properties._id
    config = {}

  schema = new mongoose.Schema(convert(JSONSchema), config)
