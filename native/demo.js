(function(window) {

  window.addEventListener('load', function() {
    var contactForm     = document.querySelector('#entry-section form'),
        contactList     = document.getElementById('contact-list'),
        contactTemplate = document.getElementById('contact-template').textContent;

    function getAjax(url, callback) {
      var xhr = new XMLHttpRequest();

      xhr.open('GET', url);

      xhr.addEventListener('load', function() {
        document.body.removeAttribute('class');
        var data = JSON.parse(xhr.responseText);
        callback(data);
      });

      document.body.className = 'loading';
      xhr.send();
    }

    function postAjax(form, callback) {
      var url = form.getAttribute('action'),
          xhr = new XMLHttpRequest();

      xhr.open('POST', url);

      xhr.addEventListener('load', function() {
        document.body.removeAttribute('class');
        var data = JSON.parse(xhr.responseText);
        callback(data);
      });

      document.body.className = 'loading';
      xhr.send(getDataFromForm(form));
    }

    function getParameter(name, value) {
      return encodeURIComponent(name) + '=' + encodeURIComponent(value);
    }

    function getDataFromForm(form) {
      var fullName  = form.querySelector('input[name="name"]').value,
          separator = fullName.indexOf(' '),
          email     = form.querySelector('input[name="email"]').value;

      var fields = {
        firstName: fullName.substring(0, separator),
        lastName: fullName.substring(separator + 1),
        email: email
      };

      var data = [];
      for (var field in fields) {
        data.push(getParameter(field, fields[field]));
      }

      return data.join('&');
    }

    function getGravatarUrl(email) {
      // Strip away leading/trailing whitespace
      email = email.replace(/^\s*/, '').replace(/\s*$/, '');

      // Convert to lowercase
      email = email.toLowerCase();

      // Compute MD5 hash
      var hash = md5(email);

      return '//www.gravatar.com/avatar/' + hash + '.jpg?s=50&d=identicon';
    }

    function addContactToList(contact) {
      var wrapper = document.createElement('DIV');

      wrapper.innerHTML = Mustache.render(contactTemplate, {
        name: contact.firstName + ' ' + contact.lastName,
        email: contact.email,
        src: getGravatarUrl(contact.email)
      });

      contactList.appendChild(wrapper.querySelector('li:first-child'));
    }

    contactForm.addEventListener('submit', function(e) {
      e.preventDefault();

      postAjax(contactForm, function(data) {
        addContactToList(data);
      });
    });

    getAjax('/contacts', function(data) {
      for (var i = 0; i < data.length; ++i) {
        addContactToList(data[i]);
      }
    });
  });

}(window));
