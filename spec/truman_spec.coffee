describe 'Truman', ->
  beforeEach ->
    # No need to simulate waiting -- we want these specs to run fast!
    Truman.delay = 0

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
