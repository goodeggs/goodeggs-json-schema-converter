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
    if JSONSchemaConfig.type is 'object'
      mongooseConfig = {}
      for property, childJSONSchemaConfig of JSONSchemaConfig.properties
        unless property is '__v'
          isRequired = JSONSchemaConfig.required?.length and property in JSONSchemaConfig.required
          mongooseConfig[property] = convert(childJSONSchemaConfig, isRequired)
      return mongooseConfig

    else if JSONSchemaConfig.type is 'array'

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
      mongooseConfig.type = types[JSONSchemaConfig.type]
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
