describe 'Truman', ->
  beforeEach ->
    # No need to simulate waiting -- we want these specs to run fast!
    Truman.delay = 0

    # This will make it easier to keep track of what's saved for each spec.
    Truman.dropTables()

  beforeEach ->
    this.addMatchers
      toHaveBeenCalledWithJson: (data) ->
        actualData = JSON.parse(@actual.mostRecentCall.args[0])
        expect(actualData).toEqual(data)
        true

  testAsyncResponse = (method, route, options) ->
    options ?= {}

    handler = jasmine.createSpy()

    runs ->
      xhr = new XMLHttpRequest()
      xhr.open(method, route)
      xhr.addEventListener 'load', ->
        handler(xhr.responseText)
      xhr.send(options.requestData)

    waitsFor ->
      handler.callCount > 0

    runs ->
      expect(handler).toHaveBeenCalledWithJson(options.expectedJson)

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

    testHandlerInterception = (makeAjaxRequest) ->
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
      testHandlerInterception ->
        xhr = createGetRequest()
        xhr.onload = ->
          if xhr.readyState == 4
            handler(xhr.responseText)
        xhr.send()

    it 'added with the onreadystatechange method', ->
      testHandlerInterception ->
        xhr = createGetRequest()
        xhr.onreadystatechange = ->
          if xhr.readyState == 4
            handler(xhr.responseText)
        xhr.send()

    it 'added with the onprogress method', ->
      testHandlerInterception ->
        xhr = createGetRequest()
        xhr.onprogress = ->
          if xhr.readyState == 4
            handler(xhr.responseText)
        xhr.send()

    it 'added with addEventListener("load")', ->
      testHandlerInterception ->
        xhr = createGetRequest()
        xhr.addEventListener 'load', ->
          handler(xhr.responseText)
        xhr.send()

  describe 'creates fake records when sending POST requests to "create"-like routes', ->
    handler = null

    beforeEach ->
      handler = jasmine.createSpy()

    it 'using form-encoded data', ->
      testAsyncResponse 'POST', '/examples',
        requestData: 'title=Example%20Title&content=Example%20Content'
        expectedJson:
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
      testAsyncResponse 'POST', '/examples',
        requestData: 'values=foo&values=bar'
        expectedJson:
          id: 1
          values: ['foo', 'bar']

    it 'adds the approprate foreign key for nested routes', ->
      testAsyncResponse 'POST', '/categories/1/examples',
        requestData: 'title=Nested%20route%20example'
        expectedJson:
          id: 1
          category_id: 1
          title: 'Nested route example'

  describe 'updates existing records when sending POST requests to resource URLs', ->
    beforeEach ->
      Truman.Table('dishes').insert
        name: 'lasagna'
        rating: 'tasty'

    it 'using form-encoded data', ->
      testAsyncResponse 'POST', '/dishes/1',
        requestData: 'rating=delicious'
        expectedJson:
          id: 1
          name: 'lasagna'
          rating: 'delicious'

      testAsyncResponse 'GET', '/dishes/1',
        expectedJson:
          id: 1
          name: 'lasagna'
          rating: 'delicious'

  describe 'fetching records from subresource routes', ->
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
      testAsyncResponse 'GET', '/categories/2/examples',
        expectedJson: [
          { id: 2, category_id: 2, title: 'Example 2' },
          { id: 3, category_id: 2, title: 'Example 3' }
        ]

  describe 'fetching records with associations', ->
    beforeEach ->
      Truman.Table('directors').insertMany [
        { name: 'Chris Nolan', age: 43 },
        { name: 'Darren Aronofsky', age: 44 }
      ]

      Truman.Table('movies').insertMany [
        { director_id: 1, title: 'Memento', year: 2000 },
        { director_id: 2, title: 'Reqiuem for a Dream', year: 2000 }
      ]

    it 'joins the records with their associations one level deep for "index"-like routes', ->
      testAsyncResponse 'GET', '/movies',
        expectedJson: [
          {
            id: 1,
            title: 'Memento',
            year: 2000,
            director_id: 1,
            director: {
              id: 1,
              name: 'Chris Nolan',
              age: 43
            }
          },
          {
            id: 2,
            title: 'Reqiuem for a Dream',
            year: 2000,
            director_id: 2,
            director: {
              id: 2,
              name: 'Darren Aronofsky',
              age: 44
            }
          }
        ]

    it 'joins a record with its associations one level deep for "show"-like routes', ->
      testAsyncResponse 'GET', '/movies/2',
        expectedJson:
          id: 2
          title: 'Reqiuem for a Dream'
          year: 2000
          director_id: 2
          director:
            id: 2
            name: 'Darren Aronofsky'
            age: 44

  describe 'inferring associations', ->
    beforeEach ->
      Truman.Table('producers').insertMany [
        { name: 'Christopher Nolan' },
        { name: 'Thomas Tull' }
      ]

      Truman.Table('movies').insertMany [
        {
          title: 'Inception',
          producer_id: 1,
          executive_producer_id: 2
        },
        {
          title: 'The Dark Knight Rises',
          imdb_id: 1345836
        }
      ]

    it 'works for fields with identifiable suffixes', ->
      testAsyncResponse 'GET', '/movies/1',
        expectedJson:
          id: 1
          title: 'Inception'
          producer_id: 1
          producer:
            id: 1
            name: 'Christopher Nolan'
          executive_producer_id: 2
          executive_producer:
            id: 2
            name: 'Thomas Tull'

    it "leaves the field alone if it doesn't seem to correspond to a table", ->
      testAsyncResponse 'GET', '/movies/2',
        expectedJson:
          id: 2
          title: 'The Dark Knight Rises'
          imdb_id: 1345836
