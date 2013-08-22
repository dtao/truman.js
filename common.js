// See https://github.com/twbs/bootstrap/pull/9171
if (navigator.userAgent.match(/IEMobile\/10\.0/)) {
  var msViewportStyle = document.createElement("style")
  msViewportStyle.appendChild(
    document.createTextNode(
      "@-ms-viewport{width:auto!important}"
    )
  )
  document.getElementsByTagName("head")[0].appendChild(msViewportStyle)
}

function getGravatarUrl(email, size) {
  size = size || 50;

  // Strip away leading/trailing whitespace
  email = email.replace(/^\s*/, '').replace(/\s*$/, '');

  // Convert to lowercase
  email = email.toLowerCase();

  // Compute MD5 hash
  var hash = md5(email);

  return '//www.gravatar.com/avatar/' + hash + '.jpg?s=' + size + '&d=identicon';
}

function getElementFromTemplate(templateId, data) {
  var template = document.getElementById(templateId).textContent;

  // Strip leading & trailing whitespace so that firstChild gives us an Element
  // rather than a TextNode.
  template = template.replace(/^\s*/, '').replace(/\s*$/, '');

  // This is a cheap way of parsing the HTML.
  var wrapper = document.createElement('DIV');
  wrapper.innerHTML = Mustache.render(template, data);
  return wrapper.firstChild;
}
