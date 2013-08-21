# ----- Our cheapo little REST interface -----

api =
  index: (tableName, callback) ->
    afterDelay getDelay(), ->
      table = getTable(tableName)
      callback(compact(table.rows))

  get: (tableName, recordId, callback) ->
    afterDelay getDelay(), ->
      record = getRecord(tableName, recordId)
      callback(record)

  update: (tableName, recordId, data, callback) ->
    data = parseData(data) if typeof data == 'string'
    afterDelay getDelay(), ->
      table = getTable(tableName)
      record = table.rows[recordId - 1] || {}
      for attribute of data
        record[attribute] = data[attribute]
      saveTable(table)
      callback(record)

  create: (tableName, data, callback) ->
    data = parseData(data) if typeof data == 'string'
    afterDelay getDelay(), ->
      record = createRecord(tableName, data)
      callback(record)

  delete: (tableName, recordId, callback) ->
    afterDelay getDelay(), ->
      table = getTable(tableName)
      record = table.rows[recordId - 1]
      table.rows[recordId - 1] = undefined
      saveTable(table)
      callback(record)

# ----- Equally crappy routing logic -----

class Route
  constructor: (method, url) ->
    @method = method.toUpperCase()

    parts = compact(url.split('/'))
    @tableName = parts[0]
    @recordId = parts[1] if parts.length > 1

  call: (data, callback) ->
    switch @method
      when 'GET' then @get(callback)
      when 'POST' then @post(data, callback)
      when 'DELETE' then @delete(callback)

  get: (callback) ->
    if @recordId
      api.get(@tableName, @recordId, callback)

    else
      api.index(@tableName, callback)

  post: (data, callback) ->
    if @recordId
      api.update(@tableName, @recordId, data, callback)

    else
      api.create(@tableName, data, callback)

  delete: (callback) ->
    api.delete(@tableName, @recordId, callback)

# ----- The actual CRUD implementation -----

prefixTableName = (name) ->
  "__truman__#{name}"

getTable = (name) ->
  table = JSON.parse(localStorage[prefixTableName(name)] || '{}')
  if !table.name?
    table.name = name
    table.rows = []
    saveTable(table)
  table

getRecord = (tableName, recordId) ->
  table = getTable(tableName)
  table.rows[recordId - 1]

getNextId = (table) ->
  table.rows.length + 1

saveTable = (table) ->
  localStorage[prefixTableName(table.name)] = JSON.stringify(table)

createRecord = (tableName, data) ->
  table = getTable(tableName)
  record = merge(data, { id: getNextId(table) })
  table.rows.push(record)
  saveTable(table)
  record

afterDelay = (delay, callback) ->
  setTimeout(callback, delay)

# ----- The teensy weensy little API we'll expose

window.Truman =
  delay: 1000

  dropTable: (name) ->
    delete localStorage[prefixTableName(name)]

getDelay = ->
  Truman.delay

# ----- The part where we screw up XMLHttpRequest -----

_open = XMLHttpRequest::open
XMLHttpRequest::open = (method, url) ->
  @route = new Route(method, url)

  # This would give us normal behavior.
  # _open.apply(this, arguments)

_send = XMLHttpRequest::send
XMLHttpRequest::send = (data) ->
  @route.call data, (result) =>
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

merge = (left, right) ->
  merged = {}
  for key of left
    merged[key] = left[key]
  for key of right
    merged[key] = right[key]
  merged

compact = (array) ->
  compacted = []
  for value in array
    compacted.push(value) unless !value? or value == ''
  compacted

parseData = (encodedData) ->
  data = {}
  parameters = encodedData.split('&')
  for param in parameters
    [key, value] = param.split('=')
    data[decodeURIComponent(key)] = decodeURIComponent(value).replace(/\+/g, ' ')
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
