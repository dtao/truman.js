(function(window) {

  window.addEventListener('load', function() {
    var contactForm     = document.querySelector('#entry-section form'),
        contactList     = document.getElementById('contact-list'),
        contactTemplate = document.getElementById('contact-template').textContent;

    function getAjax(url, callback) {
      var xhr = new XMLHttpRequest();

      xhr.open('GET', url);

      xhr.addEventListener('load', function() {
        var data = JSON.parse(xhr.responseText);
        callback(data);
      });

      xhr.send();
    }

    function getParameterForField(field) {
      var name  = field.getAttribute('name'),
          value = field.value;

      return encodeURIComponent(name) + '=' + encodeURIComponent(value);
    }

    function getDataFromForm(form) {
      var fieldSelectors = [
        'input[type="text"]',
        'input[type="password"]',
        'input[type="checkbox"]',
        'input[type="radio"]',
        'select',
        'textarea'
      ];

      var fields = form.querySelectorAll(fieldSelectors.join(', '));

      var data = [];
      for (var i = 0; i < fields.length; ++i) {
        data.push(getParameterForField(fields[i]));
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

    function postAjax(form, callback) {
      var url = form.getAttribute('action'),
          xhr = new XMLHttpRequest();

      xhr.open('POST', url);

      xhr.addEventListener('load', function() {
        var data = JSON.parse(xhr.responseText);
        callback(data);
      });

      xhr.send(getDataFromForm(form));
    }

    function addContactToList(contact) {
      var wrapper = document.createElement('DIV');

      wrapper.innerHTML = Mustache.render(contactTemplate, {
        name: contact.name,
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
