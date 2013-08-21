// Generated by CoffeeScript 1.6.1
(function() {
  var Route, afterDelay, api, clobberProperty, compact, createRecord, getDelay, getNextId, getRecord, getTable, merge, parseData, saveTable, _getAllResponseHeaders, _open, _send;

  api = {
    index: function(tableName, callback) {
      return afterDelay(getDelay(), function() {
        var table;
        table = getTable(tableName);
        return callback(compact(table.rows));
      });
    },
    get: function(tableName, recordId, callback) {
      return afterDelay(getDelay(), function() {
        var record;
        record = getRecord(tableName, recordId);
        return callback(record);
      });
    },
    update: function(tableName, recordId, data, callback) {
      if (typeof data === 'string') {
        data = parseData(data);
      }
      return afterDelay(getDelay(), function() {
        var attribute, record, table;
        table = getTable(tableName);
        record = table.rows[recordId - 1] || {};
        for (attribute in data) {
          record[attribute] = data[attribute];
        }
        saveTable(table);
        return callback(record);
      });
    },
    create: function(tableName, data, callback) {
      if (typeof data === 'string') {
        data = parseData(data);
      }
      return afterDelay(getDelay(), function() {
        var record;
        record = createRecord(tableName, data);
        return callback(record);
      });
    },
    "delete": function(tableName, recordId, callback) {
      return afterDelay(getDelay(), function() {
        var record, table;
        table = getTable(tableName);
        record = table.rows[recordId - 1];
        table.rows[recordId - 1] = void 0;
        saveTable(table);
        return callback(record);
      });
    }
  };

  Route = (function() {

    function Route(method, url) {
      var parts;
      this.method = method.toUpperCase();
      parts = compact(url.split('/'));
      this.tableName = parts[0];
      if (parts.length > 1) {
        this.recordId = parts[1];
      }
    }

    Route.prototype.call = function(data, callback) {
      switch (this.method) {
        case 'GET':
          return this.get(callback);
        case 'POST':
          return this.post(data, callback);
        case 'DELETE':
          return this["delete"](callback);
      }
    };

    Route.prototype.get = function(callback) {
      if (this.recordId) {
        return api.get(this.tableName, this.recordId, callback);
      } else {
        return api.index(this.tableName, callback);
      }
    };

    Route.prototype.post = function(data, callback) {
      if (this.recordId) {
        return api.update(this.tableName, this.recordId, data, callback);
      } else {
        return api.create(this.tableName, data, callback);
      }
    };

    Route.prototype["delete"] = function(callback) {
      return api["delete"](this.tableName, this.recordId, callback);
    };

    return Route;

  })();

  getTable = function(name) {
    var table;
    table = JSON.parse(localStorage[name] || '{}');
    if (table.name == null) {
      table.name = name;
      table.rows = [];
      saveTable(table);
    }
    return table;
  };

  getRecord = function(tableName, recordId) {
    var table;
    table = getTable(tableName);
    return table.rows[recordId - 1];
  };

  getNextId = function(table) {
    return table.rows.length + 1;
  };

  saveTable = function(table) {
    return localStorage[table.name] = JSON.stringify(table);
  };

  createRecord = function(tableName, data) {
    var record, table;
    table = getTable(tableName);
    record = merge(data, {
      id: getNextId(table)
    });
    table.rows.push(record);
    saveTable(table);
    return record;
  };

  afterDelay = function(delay, callback) {
    return setTimeout(callback, delay);
  };

  window.Wizard = {
    delay: 1000
  };

  getDelay = function() {
    return Wizard.delay;
  };

  _open = XMLHttpRequest.prototype.open;

  XMLHttpRequest.prototype.open = function(method, url) {
    return this.route = new Route(method, url);
  };

  _send = XMLHttpRequest.prototype.send;

  XMLHttpRequest.prototype.send = function(data) {
    var _this = this;
    return this.route.call(data, function(result) {
      var handler;
      clobberProperty(_this, 'status', 200);
      clobberProperty(_this, 'readyState', 4);
      clobberProperty(_this, 'responseText', JSON.stringify(result));
      handler = _this.onload || _this.onreadystatechange;
      if (handler != null) {
        return handler();
      }
    });
  };

  _getAllResponseHeaders = XMLHttpRequest.prototype.getAllResponseHeaders;

  XMLHttpRequest.prototype.getAllResponseHeaders = function() {
    return ['Date: ' + new Date().toString(), 'content-length: ' + this.responseText.length, 'content-type: application/json; charset=UTF-8'].join('\n');
  };

  merge = function(left, right) {
    var key, merged;
    merged = {};
    for (key in left) {
      merged[key] = left[key];
    }
    for (key in right) {
      merged[key] = right[key];
    }
    return merged;
  };

  compact = function(array) {
    var compacted, value, _i, _len;
    compacted = [];
    for (_i = 0, _len = array.length; _i < _len; _i++) {
      value = array[_i];
      if (!((value == null) || value === '')) {
        compacted.push(value);
      }
    }
    return compacted;
  };

  parseData = function(encodedData) {
    var data, key, param, parameters, value, _i, _len, _ref;
    data = {};
    parameters = encodedData.split('&');
    for (_i = 0, _len = parameters.length; _i < _len; _i++) {
      param = parameters[_i];
      _ref = param.split('='), key = _ref[0], value = _ref[1];
      data[decodeURIComponent(key)] = decodeURIComponent(value).replace(/\+/g, ' ');
    }
    return data;
  };

  clobberProperty = function(object, propertyName, value) {
    if (Object.defineProperty != null) {
      return Object.defineProperty(object, propertyName, {
        get: function() {
          return value;
        }
      });
    } else if (object.__defineGetter__ != null) {
      return object.__defineGetter__(propertyName, function() {
        return value;
      });
    } else {
      return object[propertyName] = value;
    }
  };

}).call(this);
