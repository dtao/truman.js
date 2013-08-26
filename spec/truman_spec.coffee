describe 'Truman', ->
  beforeEach ->
    # No need to simulate waiting -- we want these specs to run fast!
    Truman.delay = 0

    # This will make it easier to keep track of what's saved for each spec.
    Truman.Table('examples').drop()

  beforeEach ->
    this.addMatchers
      toHaveBeenCalledWithJson: (data) ->
        actualData = JSON.parse(@actual.mostRecentCall.args[0])
        expect(actualData).toEqual(data)
        true

  it 'supports setting request headers', ->
    activity = ->
      xhr = new XMLHttpRequest()
      xhr.open('GET', '/examples')
      xhr.setRequestHeader('X-Requested-With', 'XMLHttpRequest')
    expect(activity).not.toThrow()

  describe 'intercepts handlers', ->
    handler = null

    beforeEach ->
      handler = jasmine.createSpy()

    runAsyncTest = (makeAjaxRequest) ->
      runs(makeAjaxRequest)

      expectation = ->
        handler.callCount > 0

      waitsFor(expectation, 'handler never called', 100)

      runs ->
        expect(handler).toHaveBeenCalledWith('[]')

    createGetRequest = ->
      xhr = new XMLHttpRequest()
      xhr.open('GET', '/examples')
      xhr

    it 'added with the onload method', ->
      runAsyncTest ->
        xhr = createGetRequest()
        xhr.onload = ->
          if xhr.readyState == 4
            handler(xhr.responseText)
        xhr.send()

    it 'added with the onreadystatechange method', ->
      runAsyncTest ->
        xhr = createGetRequest()
        xhr.onreadystatechange = ->
          if xhr.readyState == 4
            handler(xhr.responseText)
        xhr.send()

    it 'added with the onprogress method', ->
      runAsyncTest ->
        xhr = createGetRequest()
        xhr.onprogress = ->
          if xhr.readyState == 4
            handler(xhr.responseText)
        xhr.send()

    it 'added with addEventListener("load")', ->
      runAsyncTest ->
        xhr = createGetRequest()
        xhr.addEventListener 'load', ->
          handler(xhr.responseText)
        xhr.send()

  describe 'creates fake records when sending POST requests to "create"-like routes', ->
    handler = null

    beforeEach ->
      handler = jasmine.createSpy()

    it 'using form-encoded data', ->
      runs ->
        xhr = new XMLHttpRequest()
        xhr.open('POST', '/examples')
        xhr.addEventListener 'load', ->
          handler(xhr.responseText)
        xhr.send('title=Example%20Title&content=Example%20Content')

      waitsFor ->
        handler.callCount > 0

      runs ->
        expect(handler).toHaveBeenCalledWithJson
          id: 1
          title: 'Example Title'
          content: 'Example Content'

    it 'using JSON-encoded data', ->
      runs ->
        xhr = new XMLHttpRequest()
        xhr.open('POST', 'examples')
        xhr.addEventListener 'load', ->
          handler(xhr.responseText)
        xhr.setRequestHeader('Content-type', 'application/json')
        xhr.send('{ "title": "Example Title", "content": "Example Content" }');

      waitsFor ->
        handler.callCount > 0

      runs ->
        expect(handler).toHaveBeenCalledWithJson
          id: 1
          title: 'Example Title'
          content: 'Example Content'

    # Oh dear... this might not be possible at all!
    # http://stackoverflow.com/questions/7752188/formdata-appendkey-value-is-not-working
    #
    # Probably supporting this will require overriding window.FormData itself
    xit 'using FormData', ->
      runs ->
        xhr = new XMLHttpRequest()
        xhr.open('POST', '/examples')
        xhr.addEventListener 'load', ->
          handler(xhr.responseText)
        formData = new FormData()
        formData.append('title', 'Example Title')
        formData.append('content', 'Example Content')
        xhr.send(formData)

      waitsFor ->
        handler.callCount > 0

      runs ->
        expect(handler).toHaveBeenCalledWithJson
          id: 1
          title: 'Example Title'
          content: 'Example Content'

    it 'handles multiple values for a given field', ->
      runs ->
        xhr = new XMLHttpRequest()
        xhr.open('POST', '/examples')
        xhr.addEventListener 'load', ->
          handler(xhr.responseText)
        xhr.send('values=foo&values=bar')

      waitsFor ->
        handler.callCount > 0

      runs ->
        expect(handler).toHaveBeenCalledWithJson
          id: 1
          values: ['foo', 'bar']

    it 'adds the approprate foreign key for nested routes', ->
      runs ->
        xhr = new XMLHttpRequest()
        xhr.open('POST', '/categories/1/examples')
        xhr.addEventListener 'load', ->
          handler(xhr.responseText)
        xhr.send('title=Nested%20route%20example')

      waitsFor ->
        handler.callCount > 0

      runs ->
        expect(handler).toHaveBeenCalledWithJson
          id: 1
          category_id: 1
          title: 'Nested route example'

  describe 'fetching records from subresource routes', ->
    callback = null

    beforeEach ->
      Truman.Table('categories').insertMany [
        { name: 'Category 1' },
        { name: 'Category 2' }
      ]

      Truman.Table('examples').insertMany [
        { category_id: 1, title: 'Example 1' },
        { category_id: 2, title: 'Example 2' },
        { category_id: 2, title: 'Example 3' }
      ]

      callback = jasmine.createSpy()

    it 'fetches only the records with the matching foreign key', ->
      runs ->
        xhr = new XMLHttpRequest()
        xhr.open('GET', '/categories/2/examples')
        xhr.onprogress = ->
          if xhr.readyState == 4
            callback(xhr.responseText)
        xhr.send()

      waitsFor ->
        callback.callCount > 0

      runs ->
        expect(callback).toHaveBeenCalledWithJson [
          { id: 2, category_id: 2, title: 'Example 2' },
          { id: 3, category_id: 2, title: 'Example 3' }
        ]
