describe 'Truman', ->
  beforeEach ->
    # No need to simulate waiting -- we want these specs to run fast!
    Truman.delay = 0

    # This will make it easier to keep track of what's saved for each spec.
    Truman.dropTable('examples')

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

    prepareAsyncTest = (makeAjaxRequest) ->
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
      prepareAsyncTest ->
        xhr = createGetRequest()
        xhr.onload = ->
          if xhr.readyState == 4
            handler(xhr.responseText)
        xhr.send()

    it 'added with the onreadystatechange method', ->
      prepareAsyncTest ->
        xhr = createGetRequest()
        xhr.onreadystatechange = ->
          if xhr.readyState == 4
            handler(xhr.responseText)
        xhr.send()

    it 'added with the onprogress method', ->
      prepareAsyncTest ->
        xhr = createGetRequest()
        xhr.onprogress = ->
          if xhr.readyState == 4
            handler(xhr.responseText)
        xhr.send()

    it 'added with addEventListener("load")', ->
      prepareAsyncTest ->
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

    # Oh dear... this might not be possible at all!
    # http://stackoverflow.com/questions/7752188/formdata-appendkey-value-is-not-working
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
