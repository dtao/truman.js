window.addEventListener('load', function() {

  function addContactToList(contact) {
    var element = getElementFromTemplate('contact-template', {
      firstName: contact.firstName,
      lastName: contact.lastName,
      email: contact.email,
      src: getGravatarUrl(contact.email, 128)
    });

    $('contact-list').insert(element);
  }

  function showForm() {
    var dialog = $('entry-dialog'),
        form   = dialog.select('form')[0];

    form.reset();
    dialog.setStyle({ display: 'block' });
  }

  function hideForm() {
    $('entry-dialog').setStyle({ display: null });
  }

  Ajax.Responders.register({
    onCreate: function(){
      document.body.addClassName('loading');
    }, 
    onComplete: function(){
      document.body.removeClassName('loading');
    }
  });

  new Ajax.Request('/contacts', {
    method: 'get',
    onSuccess: function(transport) {
      var contacts = JSON.parse(transport.responseText);
      contacts.each(addContactToList);
    }
  });

  $('add-contact').observe('click', showForm);

  $('clear-contacts').observe('click', function() {
    if (confirm('Are you sure you want to clear all contacts?')) {
      Truman.dropTable('contacts');
      window.location.reload();
    }
  });

  var entryForm = $('entry-dialog').select('form')[0];
  entryForm.observe('submit', function(e) {
    e.preventDefault();

    new Ajax.Request('/contacts', {
      method: 'post',
      parameters: entryForm.serialize(true),
      onSuccess: function(transport) {
        var contact = JSON.parse(transport.responseText);
        addContactToList(contact);
      }
    });

    hideForm();
  });

  $('close-button').observe('click', function(e) {
    e.preventDefault();
    hideForm();
  });
});
