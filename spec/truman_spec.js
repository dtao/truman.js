// Generated by CoffeeScript 1.6.1
(function() {

  describe('Truman', function() {
    var testAsyncResponse;
    beforeEach(function() {
      Truman.delay = 0;
      return Truman.dropTables();
    });
    beforeEach(function() {
      return this.addMatchers({
        toHaveBeenCalledWithJson: function(data) {
          var actualData;
          actualData = JSON.parse(this.actual.mostRecentCall.args[0]);
          expect(actualData).toEqual(data);
          return true;
        }
      });
    });
    testAsyncResponse = function(method, route, options) {
      var handler;
      if (options == null) {
        options = {};
      }
      handler = jasmine.createSpy();
      runs(function() {
        var xhr;
        xhr = new XMLHttpRequest();
        xhr.open(method, route);
        xhr.addEventListener('load', function() {
          return handler(xhr.responseText);
        });
        return xhr.send(options.requestData);
      });
      waitsFor(function() {
        return handler.callCount > 0;
      });
      return runs(function() {
        return expect(handler).toHaveBeenCalledWithJson(options.expectedJson);
      });
    };
    it('supports setting request headers', function() {
      var activity;
      activity = function() {
        var xhr;
        xhr = new XMLHttpRequest();
        xhr.open('GET', '/examples');
        return xhr.setRequestHeader('X-Requested-With', 'XMLHttpRequest');
      };
      return expect(activity).not.toThrow();
    });
    describe('intercepts handlers', function() {
      var createGetRequest, handler, testHandlerInterception;
      handler = null;
      beforeEach(function() {
        return handler = jasmine.createSpy();
      });
      testHandlerInterception = function(makeAjaxRequest) {
        var expectation;
        runs(makeAjaxRequest);
        expectation = function() {
          return handler.callCount > 0;
        };
        waitsFor(expectation, 'handler never called', 100);
        return runs(function() {
          return expect(handler).toHaveBeenCalledWith('[]');
        });
      };
      createGetRequest = function() {
        var xhr;
        xhr = new XMLHttpRequest();
        xhr.open('GET', '/examples');
        return xhr;
      };
      it('added with the onload method', function() {
        return testHandlerInterception(function() {
          var xhr;
          xhr = createGetRequest();
          xhr.onload = function() {
            if (xhr.readyState === 4) {
              return handler(xhr.responseText);
            }
          };
          return xhr.send();
        });
      });
      it('added with the onreadystatechange method', function() {
        return testHandlerInterception(function() {
          var xhr;
          xhr = createGetRequest();
          xhr.onreadystatechange = function() {
            if (xhr.readyState === 4) {
              return handler(xhr.responseText);
            }
          };
          return xhr.send();
        });
      });
      it('added with the onprogress method', function() {
        return testHandlerInterception(function() {
          var xhr;
          xhr = createGetRequest();
          xhr.onprogress = function() {
            if (xhr.readyState === 4) {
              return handler(xhr.responseText);
            }
          };
          return xhr.send();
        });
      });
      return it('added with addEventListener("load")', function() {
        return testHandlerInterception(function() {
          var xhr;
          xhr = createGetRequest();
          xhr.addEventListener('load', function() {
            return handler(xhr.responseText);
          });
          return xhr.send();
        });
      });
    });
    describe('creates fake records when sending POST requests to "create"-like routes', function() {
      var handler;
      handler = null;
      beforeEach(function() {
        return handler = jasmine.createSpy();
      });
      it('using form-encoded data', function() {
        return testAsyncResponse('POST', '/examples', {
          requestData: 'title=Example%20Title&content=Example%20Content',
          expectedJson: {
            id: 1,
            title: 'Example Title',
            content: 'Example Content'
          }
        });
      });
      it('using JSON-encoded data', function() {
        runs(function() {
          var xhr;
          xhr = new XMLHttpRequest();
          xhr.open('POST', 'examples');
          xhr.addEventListener('load', function() {
            return handler(xhr.responseText);
          });
          xhr.setRequestHeader('Content-type', 'application/json');
          return xhr.send('{ "title": "Example Title", "content": "Example Content" }');
        });
        waitsFor(function() {
          return handler.callCount > 0;
        });
        return runs(function() {
          return expect(handler).toHaveBeenCalledWithJson({
            id: 1,
            title: 'Example Title',
            content: 'Example Content'
          });
        });
      });
      xit('using FormData', function() {
        runs(function() {
          var formData, xhr;
          xhr = new XMLHttpRequest();
          xhr.open('POST', '/examples');
          xhr.addEventListener('load', function() {
            return handler(xhr.responseText);
          });
          formData = new FormData();
          formData.append('title', 'Example Title');
          formData.append('content', 'Example Content');
          return xhr.send(formData);
        });
        waitsFor(function() {
          return handler.callCount > 0;
        });
        return runs(function() {
          return expect(handler).toHaveBeenCalledWithJson({
            id: 1,
            title: 'Example Title',
            content: 'Example Content'
          });
        });
      });
      it('handles multiple values for a given field', function() {
        return testAsyncResponse('POST', '/examples', {
          requestData: 'values=foo&values=bar',
          expectedJson: {
            id: 1,
            values: ['foo', 'bar']
          }
        });
      });
      return it('adds the approprate foreign key for nested routes', function() {
        return testAsyncResponse('POST', '/categories/1/examples', {
          requestData: 'title=Nested%20route%20example',
          expectedJson: {
            id: 1,
            category_id: 1,
            title: 'Nested route example'
          }
        });
      });
    });
    describe('updates existing records when sending POST requests to resource URLs', function() {
      beforeEach(function() {
        return Truman.Table('dishes').insert({
          name: 'lasagna',
          rating: 'tasty'
        });
      });
      return it('using form-encoded data', function() {
        testAsyncResponse('POST', '/dishes/1', {
          requestData: 'rating=delicious',
          expectedJson: {
            id: 1,
            name: 'lasagna',
            rating: 'delicious'
          }
        });
        return testAsyncResponse('GET', '/dishes/1', {
          expectedJson: {
            id: 1,
            name: 'lasagna',
            rating: 'delicious'
          }
        });
      });
    });
    describe('fetching records from subresource routes', function() {
      beforeEach(function() {
        var callback;
        Truman.Table('categories').insertMany([
          {
            name: 'Category 1'
          }, {
            name: 'Category 2'
          }
        ]);
        Truman.Table('examples').insertMany([
          {
            category_id: 1,
            title: 'Example 1'
          }, {
            category_id: 2,
            title: 'Example 2'
          }, {
            category_id: 2,
            title: 'Example 3'
          }
        ]);
        return callback = jasmine.createSpy();
      });
      return it('fetches only the records with the matching foreign key', function() {
        return testAsyncResponse('GET', '/categories/2/examples', {
          expectedJson: [
            {
              id: 2,
              category_id: 2,
              title: 'Example 2'
            }, {
              id: 3,
              category_id: 2,
              title: 'Example 3'
            }
          ]
        });
      });
    });
    describe('fetching records with associations', function() {
      beforeEach(function() {
        Truman.Table('directors').insertMany([
          {
            name: 'Chris Nolan',
            age: 43
          }, {
            name: 'Darren Aronofsky',
            age: 44
          }
        ]);
        return Truman.Table('movies').insertMany([
          {
            director_id: 1,
            title: 'Memento',
            year: 2000
          }, {
            director_id: 2,
            title: 'Reqiuem for a Dream',
            year: 2000
          }
        ]);
      });
      it('joins the records with their associations one level deep for "index"-like routes', function() {
        return testAsyncResponse('GET', '/movies', {
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
            }, {
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
        });
      });
      return it('joins a record with its associations one level deep for "show"-like routes', function() {
        return testAsyncResponse('GET', '/movies/2', {
          expectedJson: {
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
        });
      });
    });
    return describe('inferring associations', function() {
      beforeEach(function() {
        Truman.Table('producers').insertMany([
          {
            name: 'Christopher Nolan'
          }, {
            name: 'Thomas Tull'
          }
        ]);
        return Truman.Table('movies').insertMany([
          {
            title: 'Inception',
            producer_id: 1,
            executive_producer_id: 2
          }, {
            title: 'The Dark Knight Rises',
            imdb_id: 1345836
          }
        ]);
      });
      it('works for fields with identifiable suffixes', function() {
        return testAsyncResponse('GET', '/movies/1', {
          expectedJson: {
            id: 1,
            title: 'Inception',
            producer_id: 1,
            producer: {
              id: 1,
              name: 'Christopher Nolan'
            },
            executive_producer_id: 2,
            executive_producer: {
              id: 2,
              name: 'Thomas Tull'
            }
          }
        });
      });
      return it("leaves the field alone if it doesn't seem to correspond to a table", function() {
        return testAsyncResponse('GET', '/movies/2', {
          expectedJson: {
            id: 2,
            title: 'The Dark Knight Rises',
            imdb_id: 1345836
          }
        });
      });
    });
  });

}).call(this);
