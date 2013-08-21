Truman.js
=========

All Smoke & Mirrors
-------------------

Let's say you're developing a quick prototype. You don't want to implement the entire backend yet,
so you decide to stub it out. You could do it with a simple dummy implementation server-side; but
that would require you to host it somewhere if you want to share it (with anyone\* besides other
developers), not to mention that it would just be some crappy throwaway code. You could implement an
API abstraction layer client-side, with a dummy placeholder implementation to start; but that would
make your application more complex than it needs to be.

The idea behind **Truman.js** is that it lets you build your application the way you would if the
backend already existed--using the browser's native `XMLHttpRequest` object, or any library that
wraps it (e.g., jQuery, Prototype)--*without* an unnecessary abstraction layer. It assumes that
you'll be interacting with a RESTful API and provides CRUD operations that persist data to
`localStorage`, so someone checking out your prototype will actually see data getting saved.

How it works
------------

Yes, this library messes with the `XMLHttpRequest` prototype. (TODO: Explain the multiple steps
involved in making this magic happen.)

Conventions
-----------

By convention\*\*, Truman.js assumes that you're going to interact with a RESTful API. This implies
the following endpoints:

    GET /resources

Fetch all of the records from a "resources" table.

    GET /resources/1

Fetch the "resources" row with an ID of 1.

    POST /resources

Create a new row in the "resources" table. Supply the properties of this row as form-encoded data
(i.e., what you would get from calling `$(form).serializeArray()` using jQuery). The response will
include the row data you included in the request, plus an `id` field.

    POST /resources/1

Update the "resources" row with an ID of 1. This will override the properties currently stored with
whatever you include in the request.

    DELETE /resources/1

Delete the "resources" row with an ID of 1. The response will include the row data of the record you
just deleted.

JavaScript Usage
----------------

For now, Truman.js doesn't offer much in the way of a programmatic API.

You can set the `Truman.delay` property to the number of milliseconds you'd like for your fake AJAX
requests to take. (The default is 1000, or 1 second.)

You can also call `Truman.dropTable("resources")` to delete the table called "resources" (so the
next call you make to "/resources" will return an empty list).

### Footnotes

\* And frankly, even if you're sharing with other developers, it's *much* more convenient to be able
to say, "Here, see the page at this URL" than "Fetch this branch, start up a server on your machine
and go to localhost."

\*\* There's no reason this couldn't change to accomodate some sort of configurable approach.
