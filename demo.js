$(document).ready(function() {
  var body  = $('body'),
    header  = $('.page-header'),
    table   = $('table');

  function formatEmail(email) {
    return '<a href="mailto:' + email + '">' + email + '</a>';
  }

  function formatAddress(address) {
    return address.replace(/\n/g, '<br />');
  }

  function updateRow(row, data) {
    var fields = [
      'firstName',
      'lastName',
      ['email', formatEmail],
      'phone',
      ['address', formatAddress]
    ];

    var cells = $('td', row);

    $.each(fields, function(i, attr) {
      if ($.isArray(attr)) {
        $(cells[i]).html(attr[1](data[attr[0]]));
      } else {
        $(cells[i]).text(data[attr]);
      }
    });
  }

  function addCellsToRow(row) {
    var columnCount = table.find('tr:first-child > th').length;
    while ($('td', row).length < columnCount) {
      $('<td>').appendTo(row);
    }
  }

  function addButtonsToRow(row) {
    var lastCell = $('td:last-child', row);

    var buttonGroup = $('<div>')
      .addClass('btn-group')
      .appendTo(lastCell);

    var editButton = $('<a>')
      .addClass('edit btn btn-xs btn-warning')
      .html('<span class="glyphicon glyphicon-edit"></span>')
      .appendTo(buttonGroup);

    var deleteButton = $('<a>')
      .addClass('delete btn btn-xs btn-danger')
      .html('<span class="glyphicon glyphicon-trash"></span>')
      .appendTo(buttonGroup);
  }

  function addRowToTable(data) {
    var row = $('<tr>').attr('data-id', data.id).appendTo(table);

    addCellsToRow(row);
    updateRow(row, data);
    addButtonsToRow(row);
  }

  function displayNotice(message) {
    var notice = $('<div>')
      .addClass('alert alert-info')
      .text(message)
      .insertAfter(header);

    setTimeout(function() {
      notice.slideUp(function() { notice.remove(); });
    }, 3000);
  }

  function clearForms() {
    $('input[type="text"], textarea').val('');
  }

  function hideModals() {
    $('.modal').hide();
  }

  function updateFormFromRow(form, row) {
    var id = row.attr('data-id');
    form.attr('action', '/contacts/' + id);

    $('input[name="firstName"]', form).val($('td:nth-child(1)', row).text());
    $('input[name="lastName"]', form).val($('td:nth-child(2)', row).text());
    $('input[name="email"]', form).val($('td:nth-child(3)', row).text());
    $('input[name="phone"]', form).val($('td:nth-child(4)', row).text());
    $('textarea[name="address"]', form).val($('td:nth-child(5)', row).text());
  }

  $(document).ajaxStart(function() {
    body.addClass('loading');
    hideModals();
  });

  $(document).ajaxComplete(function() {
    body.removeClass('loading');
  });

  $.getJSON('/contacts', function(data) {
    $.each(data, function(i, contact) {
      addRowToTable(contact);
    });
  });

  $('form').submit(function(e) {
    e.preventDefault();

    var form   = $(this),
      route  = form.attr('action'),
      method = form.attr('method') || 'POST',
      data   = form.serializeArray();

    $.ajax({
      url: route,
      type: method,
      data: data,
      dataType: 'json',
      success: function(data) {
        var id  = data.id,
          row = table.find('tr[data-id="' + id + '"]');

        if (row.length > 0) {
          updateRow(row, data);
          displayNotice('Updated "' + data.firstName + '"!');

        } else {
          addRowToTable(data);
          displayNotice('Added "' + data.firstName + '" to contacts!');
        }

        clearForms();
      }
    });
  });

  $(document).on('click', 'a.edit', function() {
    var row  = $(this).closest('tr'),
      id   = row.attr('data-id'),
      dialog = $('#edit-page'),
      form   = $('form', dialog);

    updateFormFromRow(form, row);

    dialog.show();
  });

  $(document).on('click', 'a.delete', function() {
    var row  = $(this).closest('tr'),
      name = $('td:first-child', row).text(),
      id   = row.attr('data-id');

    if (!confirm('Are you sure you want to delete "' + name + '" from your contacts?')) {
      return false;
    }

    $.ajax({
      url: '/contacts/' + id,
      type: 'DELETE',
      success: function() {
        row.remove();
        displayNotice('Removed "' + name + '" from contacts!');
      }
    });
  });

  $(document).on('click', 'button.cancel', function(e) {
    e.preventDefault();
    hideModals();
  });
});
