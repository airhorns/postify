# Global functions and helpers
# ============================

# Queue of message DOM elements.
messages = []
# jQuery pointing to the AJAX spinner image. The value is filled out in the `$(document).ready` handler.
spinner = false

# Define functiosn for managing the sexy flash message framework. `hideAllMessages` animates all the messages out,
# and `showMessage` pops a new message onto the stack.
hideAllMessages = ->
 for message in messages
   height = $(message).outerHeight()
   $(message).animate({top: -height}, 500)

showMessage = (options) ->
  # Available options: `type`, `title`, `message`
  message = $(".message.#{options.type}")
  message.show()
  $('h3', message).html(options.title)
  $('p', message).html(options.message)

  # Attach a click handler to hide all the messages when one is clicked.
  message.animate({top:"0"}, 500).click ->
    hideAllMessages()

# Define simpel functions form managing the simple ajax spinner.
showSpinner = (element) -> 
  # Detach and append the spinner from the dom if we need to move it from
  # where it currently is.
  if element?
    spinner.detach()
    $(element).after(spinner) 
  spinner.show()

hideSpinner = -> spinner.hide()

# Wizard step 1
testPosterousCredentials = () ->
  # Grab a jQuery for the form we're working with.
  posterousForm = $('#posterous_info')

  # Define a handy function for enabling or disabling all the form elements.
  setFormElementsDisabled = (state = true) -> $('#posterous_info input, #posterous_info button').attr('disabled', state)
  
  # Grab the values of the stuff the user has filled it for the ajax request.
  username = $('#email').val()
  password = $('#password').val()

  # Ask the server if the supplied credentials are valid.
  $.ajax
    url: '/verify/posterous'
    data: {username, password}
    type: 'POST'
    dataType: 'json'

    # Disable the form until the request is done, show the spinner to tell the user something is happening, 
    # and hide any messages left over from previous requests before we send this one.
    beforeSend: ->
      setFormElementsDisabled(true)
      showSpinner $('#test_credentials')
      hideAllMessages()
    
    # Hide the spinner when the request is done, regardless of success.
    complete: (data) ->
      hideSpinner()

    success: (data, type, xhr) ->
      if data.length > 0
        # Populate the select with the options for the site by removing the old ones and adding a new
        # option for each site. Store the site's ID in the option's `value` attribute for later reference.
        $('#sitepicker option').remove()
        for site in data
          option = "<option value=\"#{site.id}\">#{site.name} (#{site.full_hostname})</option>"
          $('#sitepicker').append(option)
        
        # Animate our sitepicker select down and add a little message to say the site fetch was successful. Don't use
        # a flash message here because we'd like it to stay around and explain why the form is disabled.
        $('.sitepicker').show(300).attr('disabled', false)
        $('#test_credentials', posterousForm).after(" <span class=\"success\">Success! Posts can be made to this account.</span>")
      else
        setFormElementsDisabled(false)
        # The Posterous account has no sites to choose from! Tell the user and let them retry.
        showMessage
          type: 'error'
          title: "Posterous Sites Error"
          message: "This account has no sites to work with! Try adding a site with Posterous or using a different account."
    
    # Alert the user if there was an error talking to Posterous with an error message. 
    error: (xhr, status, errorThrown) ->
      if xhr.status == 401
        showMessage
          type: 'error'
          title: "Error authenticating with Posterous"
          message: "Did you type in your email and password properly? Please try again!"
      else
        showMessage
          type: 'error'
          title: 'Error connecting to Posterous'
          message: errorThrown
      # Let the user retry submission.
      setFormElementsDisabled(false)
 
# Wizard step 2
#
defaultProductBody = """
  {{product.body_html}}
  
  {% if product.variants %}
    {% capture titles %}{{product.variants | map 'title' }}{% endcapture %}
    {% for title in titles %}
      {% if forloop.last %}
        and {{title}}.
      {% else %}
        {{title}},
      {% endif %}
    {% endfor %}
  {% endif %}

  Buy this product now <a href="http://{{shop.domain}}/products/{{product.handle}}">here</a>!
"""

defaultProductTitle = "New Product: {{product.title}}"

getEmailTemplate = ->
  $(".post_template").show()
  
  # Set up default template click handlers
  $("#default_body_template").click (e) ->
    e.preventDefault()
    $("#post_body_template").val defaultProductBody

  $("#default_title_template").click (e) ->
    e.preventDefault()
    $("#post_title_template").val defaultProductTitle
  
  
$(document).ready ->
  messages = $('.message')
  spinner  = $('#spinner')
  hideAllMessages()

  $('#test_credentials').click (e) ->
    e.preventDefault()
    testPosterousCredentials()

  $("#select_site").click (e) ->
    e.preventDefault()
    getEmailTemplate()

