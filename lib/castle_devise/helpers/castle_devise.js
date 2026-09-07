(function () {
  var pk = __CASTLE_DEVISE_PK__;
  if (!window.__castleDevise && window.Castle && typeof Castle.configure === "function") {
    window.__castleDevise = Castle.configure({ pk: pk });
  }

  window.castleDeviseOnFormSubmit = function (event) {
    var client = window.__castleDevise || window.Castle;
    // 2.x exposes injectTokenOnSubmit; 3.x only has createRequestToken on the configured instance.
    if (client && typeof client.injectTokenOnSubmit === "function") {
      return client.injectTokenOnSubmit(event);
    }
    if (!client || typeof client.createRequestToken !== "function") {
      event.preventDefault();
      return false;
    }
    var form = event.target;
    if (form.getAttribute("data-castle-submitting") === "1") {
      return true;
    }
    event.preventDefault();
    client.createRequestToken().then(function (token) {
      var field = form.querySelector('input[name="castle_request_token"]');
      if (!field) {
        field = document.createElement("input");
        field.type = "hidden";
        field.name = "castle_request_token";
        form.appendChild(field);
      }
      field.value = token || "";
      form.setAttribute("data-castle-submitting", "1");
      if (typeof form.requestSubmit === "function") {
        form.requestSubmit();
      } else {
        form.submit();
      }
    }).catch(function () {
      form.setAttribute("data-castle-submitting", "1");
      if (typeof form.requestSubmit === "function") {
        form.requestSubmit();
      } else {
        form.submit();
      }
    });
    return false;
  };
})();
