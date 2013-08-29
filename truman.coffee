# ----- Our cheapo little REST interface -----

api =
  index: (tableName, options) ->
    options ?= {}
    callback = options.callback || ->

    afterDelay getDelay(), ->
      rows = Table(tableName).rows()
      if options.foreignTableName?
        foreignKeyField = singularize(options.foreignTableName) + '_id'
        rows = filter rows, (row) ->
          String(row[foreignKeyField]) == String(options.foreignKey)
      else
        rows = api.joinRowsWithAssociations(rows)

      callback(rows)

  get: (tableName, recordId, callback) ->
    afterDelay getDelay(), ->
      row = Table(tableName).get(recordId)
      callback(api.joinRowWithAssociations(row))

  update: (tableName, recordId, data, contentType, callback) ->
    data = parseData(data, contentType) if typeof data == 'string'
    afterDelay getDelay(), ->
      callback(Table(tableName).update(recordId, data))

  create: (tableName, data, options) ->
    options ?= {}
    callback = options.callback || ->
    contentType = options.contentType || ''

    data = parseData(data, contentType) if typeof data == 'string'
    afterDelay getDelay(), ->
      if options.foreignTableName?
        foreignKeyField = singularize(options.foreignTableName) + '_id'
        data = clone(data)
        data[foreignKeyField] = Number(options.foreignKey)
      callback(Table(tableName).insert(data))

  delete: (tableName, recordId, callback) ->
    afterDelay getDelay(), ->
      table = Table(tableName)
      record = table.get(recordId)
      table.delete(recordId)
      callback(record)

  joinRowsWithAssociations: (rows) ->
    joined = []
    for row in rows
      joined.push(api.joinRowWithAssociations(row))
    joined

  joinRowWithAssociations: (row) ->
    joined = {}

    for key of row
      if endsWith(key, '_id')
        id = row[key]
        assoc_key = chop(key, 3)
        tableName = api.inferTableName(assoc_key)
        if tableName?
          joined[assoc_key] = Table(tableName).get(id)
          continue

      joined[key] = row[key]

    joined

  inferTableName: (name) ->
    parts = name.split('_')
    while parts.length > 0
      tableName = pluralize(parts.join('_'))
      if Table.exists(tableName)
        return tableName
      parts.shift()

    null

# ----- Equally crappy routing logic -----

class Route
  constructor: (method, url) ->
    @method = method.toUpperCase()

    parts = compact(url.split('/'))
    @tableName = if parts.length > 2 then parts[2] else parts[0]
    @recordId = Number(parts[1]) if parts.length > 1
    @foreignTableName = parts[0] if parts.length > 2

  call: (data, contentType, callback) ->
    switch @method
      when 'GET' then @get(callback)
      when 'POST' then @post(data, contentType, callback)
      when 'DELETE' then @delete(callback)

  get: (callback) ->
    if @foreignTableName
      api.index @tableName,
        foreignTableName: @foreignTableName
        foreignKey: @recordId
        callback: callback

    else if @recordId
      api.get(@tableName, @recordId, callback)

    else
      api.index @tableName,
        callback: callback

  post: (data, contentType, callback) ->
    if @foreignTableName
      api.create @tableName, data,
        foreignTableName: @foreignTableName
        foreignKey: @recordId
        contentType: contentType
        callback: callback

    else if @recordId
      api.update(@tableName, @recordId, data, contentType, callback)

    else
      api.create @tableName, data,
        contentType: contentType
        callback: callback

  delete: (callback) ->
    api.delete(@tableName, @recordId, callback)

# ----- The actual CRUD implementation based on localStorage -----

DB =
  getOrCreateTable: (name) ->
    table = (DB.tables[name] ?= new Table(name))

  tables: {}

class Table
  constructor: (name) ->
    if !(this instanceof Table)
      return DB.getOrCreateTable(name)

    @name = name
    @data = JSON.parse(localStorage[@_prefixedName()] || '{}')
    if !@data.name?
      @data.name = @name
      @data.rows = []
      @save()

  name: ->
    @data.name

  rows: ->
    @data.rows

  get: (id) ->
    @data.rows[id - 1]

  insert: (data) ->
    record = @_addRecord(data)
    @save()
    record

  insertMany: (data) ->
    records = for record in data
      @_addRecord(record)
    @save()
    records

  update: (id, data) ->
    record = @_updateRecord(id, data)
    @save()
    record

  updateMany: (data) ->
    records = for recordId of data
      @_updateRecord(recordId, data[recordId])
    @save()
    records

  delete: (id) ->
    @data.rows[id - 1] = undefined

  save: ->
    localStorage[@_prefixedName()] = JSON.stringify(@data)

  drop: ->
    delete DB.tables[@name]
    delete localStorage[@_prefixedName()]

  @exists: (name) ->
    !!(@_prefixName(name) of localStorage)

  @_prefixName: (name) ->
    "__truman__#{name}"

  _addRecord: (data) ->
    record = merge(data, { id: @_getNextId() })
    @data.rows.push(record)
    record

  _updateRecord: (id, data) ->
    record = merge(@get(id), data)
    @data.rows[id - 1] = record
    record

  _getNextId: ->
    @data.rows.length + 1

  _prefixedName: ->
    Table._prefixName(@name)

# ----- The teensy weensy little API we'll expose

window.Truman =
  Table: Table

  dropTables: ->
    for tableName of DB.tables
      Table(tableName).drop()

    otherTables = filter Object.keys(localStorage), (key) ->
      startsWith(key, '__truman__')

    for table in otherTables
      tableName = table.substring('__truman__'.length)
      Table(tableName).drop()

  delay: 1000

getDelay = ->
  Truman.delay

# ----- The part where we screw up XMLHttpRequest -----

_open = XMLHttpRequest::open
XMLHttpRequest::open = (method, url) ->
  @route = new Route(method, url)
  @requestHeaders = {}

  # This would give us normal behavior.
  # _open.apply(this, arguments)

_send = XMLHttpRequest::send
XMLHttpRequest::send = (data) ->
  @route.call data, @requestHeaders['content-type'], (result) =>
    clobberProperty(this, 'status', 200)
    clobberProperty(this, 'readyState', 4)
    clobberProperty(this, 'responseText', JSON.stringify(result))

    handler = @onload || @onprogress || @onreadystatechange
    if handler?
      handler()

    else
      listeners = @interceptors && (@interceptors['load'] || @interceptors['progress']) || []
      listener() for listener in listeners

  # This would give us normal behavior.
  # _send.apply(this, arguments)

_addEventListener = XMLHttpRequest::addEventListener
XMLHttpRequest::addEventListener = (name, listener) ->
  @interceptors ?= {}
  @interceptors[name] ?= []
  @interceptors[name].push(listener)

  _addEventListener.apply(this, arguments)

_setRequestHeader = XMLHttpRequest::setRequestHeader
XMLHttpRequest::setRequestHeader = (name, value) ->
  try
    @requestHeaders[name.toLowerCase()] = value
    _setRequestHeader.apply(this, arguments)
  catch e
    # If this throws an exception, it really isn't a big deal since we're not making any actual
    # network calls anyway.

_getAllResponseHeaders = XMLHttpRequest::getAllResponseHeaders
XMLHttpRequest::getAllResponseHeaders = ->
  [
    'Date: ' + new Date().toString(),
    'content-length: ' + @responseText.length,
    'content-type: application/json; charset=UTF-8'
  ].join('\n')

  # This would give us normal behavior.
  # _getAllResponseHeaders.apply(this, arguments)

# ----- Helpers -----

afterDelay = (delay, callback) ->
  setTimeout(callback, delay)

merge = (left, right) ->
  merged = {}
  for key of left
    merged[key] = left[key]
  for key of right
    merged[key] = right[key]
  merged

clone = (object) ->
  merge(object, {})

filter = (array, predicate) ->
  filtered = []
  for value in array
    filtered.push(value) if predicate(value)
  filtered

compact = (array) ->
  filter(array, (value) -> !!value)

singularize = (word) ->
  return chop(word, 3) + 'y' if endsWith(word, 'ies')
  return chop(word, 2) if endsWith(word, 'es')
  return chop(word, 1) if lastChar(word) == 's'
  return word

pluralize = (word) ->
  return chop(word, 1) + 'ies' if lastChar(word) == 'y'
  return "#{word}es" if endsWith(word, 'es')
  return "#{word}s"

lastChar = (word) ->
  word.charAt(word.length - 1)

startsWith = (word, prefix) ->
  word.substring(0, prefix.length) == prefix

endsWith = (word, suffix) ->
  word.substring(word.length - suffix.length) == suffix

chop = (word, length) ->
  word.substring(0, word.length - length)

parseData = (encodedData, contentType) ->
  return JSON.parse(encodedData) if contentType == 'application/json'

  data = {}
  parameters = encodedData.split('&')
  for param in parameters
    [key, value] = param.split('=')
    key = decodeURIComponent(key)
    value = decodeURIComponent(value).replace(/\+/g, ' ')
    if !(key of data)
      data[key] = value
    else if !(data[key] instanceof Array)
      data[key] = [data[key], value]
    else
      data[key].push(value)
  data

clobberProperty = (object, propertyName, value) ->
  # This is the standardized API as of JavaScript 1.8.1.
  # https://developer.mozilla.org/en-US/docs/Web/JavaScript/Guide/Working_with_Objects#Defining_getters_and_setters
  if Object.defineProperty?
    Object.defineProperty(object, propertyName, { get: -> value })

  # Older versions of some browsers might support this legacy interface.
  else if object.__defineGetter__?
    object.__defineGetter__(propertyName, -> value)

  # Not sure if ANY browsers will allow this, but it's worth a shot.
  else
    object[propertyName] = value
