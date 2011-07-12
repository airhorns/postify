(function() {
  var defaultProductBody, defaultProductTitle, getEmailTemplate, hideAllMessages, hideSpinner, messages, showMessage, showSpinner, spinner, testPosterousCredentials;
  messages = [];
  spinner = false;
  hideAllMessages = function() {
    var height, message, _i, _len, _results;
    _results = [];
    for (_i = 0, _len = messages.length; _i < _len; _i++) {
      message = messages[_i];
      height = $(message).outerHeight();
      _results.push($(message).animate({
        top: -height
      }, 500));
    }
    return _results;
  };
  showMessage = function(options) {
    var message;
    message = $(".message." + options.type);
    message.show();
    $('h3', message).html(options.title);
    $('p', message).html(options.message);
    return message.animate({
      top: "0"
    }, 500).click(function() {
      return hideAllMessages();
    });
  };
  showSpinner = function(element) {
    if (element != null) {
      spinner.detach();
      $(element).after(spinner);
    }
    return spinner.show();
  };
  hideSpinner = function() {
    return spinner.hide();
  };
  testPosterousCredentials = function() {
    var password, posterousForm, setFormElementsDisabled, username;
    posterousForm = $('#posterous_info');
    setFormElementsDisabled = function(state) {
      if (state == null) {
        state = true;
      }
      return $('#posterous_info input, #posterous_info button').attr('disabled', state);
    };
    username = $('#email').val();
    password = $('#password').val();
    return $.ajax({
      url: '/verify/posterous',
      data: {
        username: username,
        password: password
      },
      type: 'POST',
      dataType: 'json',
      beforeSend: function() {
        setFormElementsDisabled(true);
        showSpinner($('#test_credentials'));
        return hideAllMessages();
      },
      complete: function(data) {
        return hideSpinner();
      },
      success: function(data, type, xhr) {
        var option, site, _i, _len;
        if (data.length > 0) {
          $('#sitepicker option').remove();
          for (_i = 0, _len = data.length; _i < _len; _i++) {
            site = data[_i];
            option = "<option value=\"" + site.id + "\">" + site.name + " (" + site.full_hostname + ")</option>";
            $('#sitepicker').append(option);
          }
          $('.sitepicker').show(300).attr('disabled', false);
          return $('#test_credentials', posterousForm).after(" <span class=\"success\">Success! Posts can be made to this account.</span>");
        } else {
          setFormElementsDisabled(false);
          return showMessage({
            type: 'error',
            title: "Posterous Sites Error",
            message: "This account has no sites to work with! Try adding a site with Posterous or using a different account."
          });
        }
      },
      error: function(xhr, status, errorThrown) {
        if (xhr.status === 401) {
          showMessage({
            type: 'error',
            title: "Error authenticating with Posterous",
            message: "Did you type in your email and password properly? Please try again!"
          });
        } else {
          showMessage({
            type: 'error',
            title: 'Error connecting to Posterous',
            message: errorThrown
          });
        }
        return setFormElementsDisabled(false);
      }
    });
  };
  defaultProductBody = "{{product.body_html}}\n\n{% if product.variants %}\n  {% capture titles %}{{product.variants | map 'title' }}{% endcapture %}\n  {% for title in titles %}\n    {% if forloop.last %}\n      and {{title}}.\n    {% else %}\n      {{title}},\n    {% endif %}\n  {% endfor %}\n{% endif %}\n\nBuy this product now <a href=\"http://{{shop.domain}}/products/{{product.handle}}\">here</a>!";
  defaultProductTitle = "New Product: {{product.title}}";
  getEmailTemplate = function() {
    $(".post_template").show();
    $("#default_body_template").click(function(e) {
      e.preventDefault();
      return $("#post_body_template").val(defaultProductBody);
    });
    return $("#default_title_template").click(function(e) {
      e.preventDefault();
      return $("#post_title_template").val(defaultProductTitle);
    });
  };
  $(document).ready(function() {
    messages = $('.message');
    spinner = $('#spinner');
    hideAllMessages();
    $('#test_credentials').click(function(e) {
      e.preventDefault();
      return testPosterousCredentials();
    });
    return $("#select_site").click(function(e) {
      e.preventDefault();
      return getEmailTemplate();
    });
  });
}).call(this);
