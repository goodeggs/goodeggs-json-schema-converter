module.exports.toMongooseSchema = (JSONSchema, mongoose) ->
  types =
    "string": String
    "integer": Number
    "number": Number
    "boolean": Boolean

  formats =
    "objectid": -> mongoose.Schema.ObjectId
    "date-time": -> Date
    "cents": ->
      if mongoose.Schema.Types.Cents?
        return mongoose.Schema.Types.Cents
      else
        throw new Error('schema type "Cents" not available, please extend mongoose if you want to use this schema type')

  propertiesMappings =
    "enum":  "enum"
    "default":  "default"
    "maximum":  "max"
    "minimum":  "min"

  convert = (JSONSchemaConfig, required = false) ->
    if JSONSchemaConfig.type is 'object'
      mongooseConfig = {}
      for property, childJSONSchemaConfig of JSONSchemaConfig.properties
        isRequired = JSONSchemaConfig.required?.length and property in JSONSchemaConfig.required
        mongooseConfig[property] = convert(childJSONSchemaConfig, isRequired)
      return mongooseConfig
    else if JSONSchemaConfig.type is 'array'
      if JSONSchemaConfig.items.type is 'object' and not JSONSchemaConfig.items.properties._id?
        delete JSONSchemaConfig.items.properties._id
        return [new mongoose.Schema(convert(JSONSchemaConfig.items), {_id: false})]
      else if JSONSchemaConfig.items.type is 'object'
        return [new mongoose.Schema(convert(JSONSchemaConfig.items))]
      else
        return [convert(JSONSchemaConfig.items)]
    else
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
